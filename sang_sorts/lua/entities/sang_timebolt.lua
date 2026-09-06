--[[-------------------------------------------------------------------------
    Sang et Nuit — Entité « éclair temporel » (Magie Temporelle)
      Phase 1 (fly) : projectile qui avance (particule fly).
      Phase 2 (zone) : au contact, se fige sur place et STOP LE TEMPS dans son
        rayon pendant StunDuration s : joueurs/PNJ figés + invulnérables,
        objets/projectiles physiques figés (vitesse mémorisée puis restaurée).
        Les nouveaux entrants sont figés aussi. Le lanceur n'est jamais figé.
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
        self.Speed  = 1400
        self.Born   = CurTime()
        self.Frozen = {}
        self:SetNextThink(CurTime())
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
            self:SetNextThink(CurTime())
            return true
        elseif self.Phase == "zone" then
            self:FreezeZone()
            if CurTime() >= self.ZoneEnd then
                self:Remove()
                return
            end
            self:SetNextThink(CurTime() + 0.1)
            return true
        end
    end

    function ENT:StartZone(pos)
        self.Phase = "zone"
        self:SetPos(pos)
        self.ZoneEnd = CurTime() + self.StunDur
        self:SetZoneActive(true)
        if self.Sound then self:EmitSound(self.Sound, 80, 100) end

        self.HookID = "SangTimeStop_" .. self:EntIndex()
        local frozen = self.Frozen
        hook.Add("EntityTakeDamage", self.HookID, function(target)
            if IsValid(target) and frozen[target] then return true end -- invulnérable
        end)

        self:FreezeZone()
    end

    function ENT:FreezeEntity(e)
        local data = {}
        if e:IsPlayer() then
            data.type = "ply"
            data.vel = e:GetVelocity()
            data.move = e:GetMoveType()
            e:AddFlags(FL_FROZEN)
            e:GodEnable()
            e:SetMoveType(MOVETYPE_NONE)
        elseif e:IsNPC() then
            data.type = "npc"
            e:AddFlags(FL_FROZEN)
        else
            local phys = e:GetPhysicsObject()
            if IsValid(phys) and phys:IsMotionEnabled() then
                data.type = "phys"
                data.vel  = phys:GetVelocity()
                data.avel = phys:GetAngleVelocity()
                phys:EnableMotion(false)
            else
                return
            end
        end
        self.Frozen[e] = data
    end

    function ENT:FreezeZone()
        for _, e in ipairs(ents.FindInSphere(self:GetPos(), self.SRadius)) do
            if IsValid(e) and e ~= self and e ~= self.SOwner and not self.Frozen[e] then
                self:FreezeEntity(e)
            end
        end
    end

    function ENT:Unfreeze()
        for e, data in pairs(self.Frozen or {}) do
            if IsValid(e) then
                if data.type == "ply" then
                    e:RemoveFlags(FL_FROZEN)
                    e:SetMoveType(data.move or MOVETYPE_WALK)
                    e:GodDisable()
                    if data.vel then e:SetVelocity(data.vel) end
                elseif data.type == "npc" then
                    e:RemoveFlags(FL_FROZEN)
                elseif data.type == "phys" then
                    local phys = e:GetPhysicsObject()
                    if IsValid(phys) then
                        phys:EnableMotion(true)
                        phys:Wake()
                        if data.vel  then phys:SetVelocity(data.vel) end
                        if data.avel then phys:SetAngleVelocity(data.avel) end
                    end
                end
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
                ParticleEffectAttach(p, PATTACH_ABSORIGIN_FOLLOW, self, 0)
                self.FlyAtt = true
            end
        end
        if self:GetZoneActive() and not self.ZoneAtt then
            self:StopParticles()
            local p = self:GetZoneParticle()
            if p and p ~= "" then
                ParticleEffectAttach(p, PATTACH_ABSORIGIN_FOLLOW, self, 0)
            end
            self.ZoneAtt = true
        end
    end

    function ENT:OnRemove() self:StopParticles() end
end
