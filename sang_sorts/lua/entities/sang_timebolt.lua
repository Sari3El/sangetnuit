--[[-------------------------------------------------------------------------
    Sang et Nuit — Entité « éclair temporel » (Magie Temporelle)
      Phase 1 (fly) : projectile qui avance (particule FlyParticle).
      Phase 2 (zone) : au contact, se fige et STOPPE LE TEMPS dans son rayon
        pendant StunDuration s.

      Technique de gel inspirée de « Quantum Break Time Powers » (étudiée) :
        - Joueurs : Freeze(true) + MOVETYPE_NONE + vitesse remise à zéro chaque
          tick ; vitesse d'origine restaurée à la fin (ils « repartent »).
        - PNJ : on repousse leur NextThink au-delà de la fin du gel → leur IA
          et leur animation se figent réellement (bien mieux que FL_FROZEN) ;
          MOVETYPE d'origine restauré à la fin.
        - Objets physiques / projectiles : on mémorise vitesse + vitesse
          angulaire + état de motion, EnableMotion(false), vitesse à zéro ;
          tout est restauré à la fin (les objets reprennent leur trajectoire).
        - Ré-appliqué chaque tick → les nouveaux entrants sont figés aussi.
        - Le feu est éteint puis rallumé à la fin.
        - Tout est invulnérable tant que c'est figé. Le lanceur n'est jamais figé.
---------------------------------------------------------------------------]]

AddCSLuaFile()

ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Éclair temporel"
ENT.Spawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("Bool",   0, "ZoneActive")
    self:NetworkVar("String", 0, "FlyParticle")
    self:NetworkVar("String", 1, "ZoneParticle")
end

if SERVER then
    function ENT:Initialize()
        self:SetModel("models/hunter/plates/plate.mdl")
        self:SetNoDraw(true)
        self:DrawShadow(false)
        self:SetSolid(SOLID_NONE)
        self:SetNotSolid(true)
        self:SetMoveType(MOVETYPE_NONE)
        self.Phase  = "fly"
        self.Speed  = 2600
        self.Born   = CurTime()
        self.Frozen = {}
        self:NextThink(CurTime())
    end

    function ENT:SetupBolt(owner, dir, radius, stunDur, flyP, zoneP, sound)
        self.SOwner   = owner
        self.Dir      = dir:GetNormalized()
        self.SRadius  = radius or 250
        self.StunDur  = stunDur or 5
        self.Sound    = sound
        self:SetFlyParticle(flyP or "")
        self:SetZoneParticle(zoneP or "")
        self:SetPos(owner:EyePos() + self.Dir * 40)
    end

    function ENT:Think()
        if self.Phase == "fly" then
            local pos = self:GetPos()
            local nxt = pos + self.Dir * self.Speed * FrameTime()
            local tr = util.TraceLine({ start = pos, endpos = nxt, filter = { self, self.SOwner }, mask = MASK_SHOT })
            if tr.Hit then
                self:StartZone(tr.HitPos)
            else
                self:SetPos(nxt)
                if CurTime() - self.Born > 6 then self:Remove() return end
            end
            self:NextThink(CurTime())
            return true
        elseif self.Phase == "zone" then
            self:FreezeZone()
            if CurTime() >= self.ZoneEnd then
                self:Remove()
                return
            end
            self:NextThink(CurTime()) -- chaque tick : gèle en continu
            return true
        end
    end

    function ENT:StartZone(pos)
        self.Phase = "zone"
        self:SetPos(pos)
        self.ZoneEnd = CurTime() + self.StunDur
        self:SetZoneActive(true)
        if self.Sound then self:EmitSound(self.Sound, 80, 100) end

        -- Invulnérabilité de tout ce qui est figé par CETTE zone.
        self.HookID = "SangTimeStop_" .. self:EntIndex()
        local frozen = self.Frozen
        hook.Add("EntityTakeDamage", self.HookID, function(target)
            if IsValid(target) and frozen[target] then return true end
        end)

        self:FreezeZone()
    end

    -- Fige (ou re-fige) une entité. Mémorise son état d'origine une seule fois.
    function ENT:FreezeEntity(e)
        local endt = (self.ZoneEnd or CurTime()) + FrameTime() * 2

        if e:IsPlayer() then
            if not self.Frozen[e] then
                self.Frozen[e] = { type = "ply", vel = e:GetVelocity(),
                    mv = e:GetMoveType(), onfire = e:IsOnFire() }
            end
            e:Freeze(true)
            e:SetMoveType(MOVETYPE_NONE)
            e:SetVelocity(-e:GetVelocity())

        elseif e:IsNPC() then
            if not self.Frozen[e] then
                self.Frozen[e] = { type = "npc", mv = e:GetMoveType(), onfire = e:IsOnFire() }
            end
            e:SetMoveType(MOVETYPE_NONE)
            e:NextThink(endt) -- repousse l'IA au-delà de la fin => figée

        else
            local phys = e:GetPhysicsObject()
            if IsValid(phys) and phys:IsMotionEnabled() then
                if not self.Frozen[e] then
                    self.Frozen[e] = { type = "phys", vel = phys:GetVelocity(),
                        avel = phys:GetAngleVelocity(),
                        health = e.Health and e:Health() or nil, onfire = e:IsOnFire() }
                end
                phys:EnableMotion(false)
                phys:SetVelocity(vector_origin)
                e:SetVelocity(vector_origin)
                e:NextThink(endt)
                if e.SetHealth and self.Frozen[e].health then e:SetHealth(self.Frozen[e].health) end
            else
                return
            end
        end

        -- Le feu est « figé » : éteint puis rallumé à la fin.
        if e:IsOnFire() then e:Extinguish() end
    end

    function ENT:FreezeZone()
        for _, e in ipairs(ents.FindInSphere(self:GetPos(), self.SRadius)) do
            if IsValid(e) and e ~= self and e ~= self.SOwner
               and string.sub(e:GetClass(), 1, 5) ~= "sang_" then
                self:FreezeEntity(e)
            end
        end
    end

    function ENT:Unfreeze()
        for e, data in pairs(self.Frozen or {}) do
            if IsValid(e) then
                if data.type == "ply" then
                    e:Freeze(false)
                    e:SetMoveType(data.mv or MOVETYPE_WALK)
                    if data.vel then e:SetVelocity(data.vel) end
                elseif data.type == "npc" then
                    e:SetMoveType(data.mv or MOVETYPE_STEP)
                    e:NextThink(CurTime()) -- l'IA reprend immédiatement
                elseif data.type == "phys" then
                    local phys = e:GetPhysicsObject()
                    if IsValid(phys) then
                        phys:EnableMotion(true)
                        phys:Wake()
                        if data.vel  then phys:SetVelocity(data.vel) end
                        if data.avel then phys:AddAngleVelocity(data.avel) end
                    end
                end
                if data.onfire and e.Ignite then e:Ignite(6) end
            end
        end
        self.Frozen = {}
    end

    function ENT:OnRemove()
        if self.HookID then hook.Remove("EntityTakeDamage", self.HookID) end
        self:Unfreeze()
    end
end

if CLIENT then
    function ENT:Initialize() end
    function ENT:Draw() end

    function ENT:Think()
        if not self.FlyAtt then
            local p = self:GetFlyParticle()
            if p and p ~= "" then
                if SANGSPELL and SANGSPELL.ResolveParticle then p = SANGSPELL.ResolveParticle(p) end
                ParticleEffectAttach(p, PATTACH_ABSORIGIN_FOLLOW, self, 0)
                self.FlyAtt = true
            end
        end
        if self:GetZoneActive() and not self.ZoneAtt then
            self:StopParticles()
            local p = self:GetZoneParticle()
            if p and p ~= "" then
                if SANGSPELL and SANGSPELL.ResolveParticle then p = SANGSPELL.ResolveParticle(p) end
                ParticleEffectAttach(p, PATTACH_ABSORIGIN_FOLLOW, self, 0)
            end
            self.ZoneAtt = true
        end
    end

    function ENT:OnRemove() self:StopParticles() end
end
