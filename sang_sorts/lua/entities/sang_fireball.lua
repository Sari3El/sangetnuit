--[[-------------------------------------------------------------------------
    Sang et Nuit — Entité « boule de feu » (Magie Élémentaire)
      Orbite autour du lanceur (OrbitTime), puis se lance dans la direction
      regardée. Explose au 1er obstacle OU après MaxFly secondes : particule
      d'explosion + dégâts de zone (DMG_BURN => respecte la résistance au feu)
      + met le feu aux êtres proches.
---------------------------------------------------------------------------]]

AddCSLuaFile()

ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Boule de feu"
ENT.Spawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "FlyParticle")
end

if SERVER then
    function ENT:Initialize()
        self:SetModel("models/hunter/plates/plate.mdl")
        self:SetNoDraw(true)
        self:DrawShadow(false)
        self:SetSolid(SOLID_NONE)
        self:SetNotSolid(true)
        self:SetMoveType(MOVETYPE_NONE)
        self.Phase = "orbit"
        self.Born  = CurTime()
        self:NextThink(CurTime())
    end

    function ENT:SetupFireball(owner, radius, dmg, orbitTime, maxFly, flyP, boomP, sound)
        self.SOwner    = owner
        self.SRadius   = radius or 200
        self.SDmg      = dmg or 40
        self.OrbitTime = orbitTime or 1.5
        self.MaxFly    = maxFly or 10
        self.BoomP     = boomP
        self.Sound     = sound
        self.Speed     = 2000
        self:SetFlyParticle(flyP or "")
    end

    local function living(e)
        if not IsValid(e) then return false end
        if e:IsPlayer() then return e:Alive() end
        if e:IsNPC() then return e:Health() > 0 end
        return false
    end

    function ENT:Think()
        if not IsValid(self.SOwner) then self:Remove() return end

        if self.Phase == "orbit" then
            local t = CurTime() - self.Born
            local ang = t * 8
            local r = 55
            local center = self.SOwner:GetPos() + Vector(0, 0, 42)
            self:SetPos(center + Vector(math.cos(ang) * r, math.sin(ang) * r, 0))
            if t >= self.OrbitTime then
                self.Phase   = "fly"
                self.Dir     = self.SOwner:GetAimVector():GetNormalized()
                self.FlyStart = CurTime()
            end
            self:NextThink(CurTime())
            return true
        elseif self.Phase == "fly" then
            local pos = self:GetPos()
            local nxt = pos + self.Dir * self.Speed * FrameTime()
            local tr = util.TraceLine({ start = pos, endpos = nxt, filter = { self, self.SOwner }, mask = MASK_SHOT })
            if tr.Hit then self:Explode(tr.HitPos) return end
            self:SetPos(nxt)
            if CurTime() - self.FlyStart > self.MaxFly then self:Explode(self:GetPos()) return end
            self:NextThink(CurTime())
            return true
        end
    end

    function ENT:Explode(pos)
        self:SetPos(pos)
        if self.BoomP then ParticleEffect(self.BoomP, pos, Angle(0, 0, 0)) end
        if self.Sound then sound.Play(self.Sound, pos, 90, math.random(95, 105)) end
        util.ScreenShake(pos, 8, 120, 0.7, (self.SRadius or 200) * 2)

        for _, e in ipairs(ents.FindInSphere(pos, self.SRadius)) do
            if living(e) then
                if SANGSPELL and SANGSPELL.DealDamage then
                    SANGSPELL.DealDamage(self.SOwner, e, self.SDmg, DMG_BURN, self)
                end
                if e.Ignite then e:Ignite(4) end
            end
        end
        self:Remove()
    end
end

if CLIENT then
    function ENT:Initialize() self.Att = false end
    function ENT:Draw() end
    function ENT:Think()
        if not self.Att then
            local p = self:GetFlyParticle()
            if p and p ~= "" then
                ParticleEffectAttach(p, PATTACH_ABSORIGIN_FOLLOW, self, 0)
                self.Att = true
            end
        end
    end
    function ENT:OnRemove() self:StopParticles() end
end
