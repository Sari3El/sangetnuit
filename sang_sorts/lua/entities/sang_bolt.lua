--[[-------------------------------------------------------------------------
    Sang et Nuit — Projectile générique en ligne droite (sang_bolt)
      Avance tout droit dans une direction fixe. À l'impact (monde ou entité),
      appelle self.OnHit(trace) côté serveur (comportement défini par le sort).
      Visuel : particule attachée (opts.particle), OU modèle visible qui tourne
      (opts.model), sinon une traînée colorée (placeholder). + lumière dynamique.
---------------------------------------------------------------------------]]

AddCSLuaFile()

ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Projectile"
ENT.Spawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("Vector", 0, "BoltColor")
    self:NetworkVar("String", 0, "FlyPart")
    self:NetworkVar("Bool",   0, "HasModel")
end

if SERVER then
    function ENT:Initialize()
        self:SetModel("models/hunter/plates/plate.mdl")
        self:SetNoDraw(true)
        self:DrawShadow(false)
        self:SetSolid(SOLID_NONE)
        self:SetNotSolid(true)
        self:SetMoveType(MOVETYPE_NONE)
        self.Born  = CurTime()
        self.Speed = 2400
        self.Life  = 4
        self:NextThink(CurTime())
    end

    -- onHit(trace) : appelé au 1er contact. onExpire() : à la fin de vie (option).
    --   opts.particle : système attaché au projectile. opts.model : modèle visible.
    function ENT:SetupBolt(owner, dir, opts)
        opts = opts or {}
        self.SOwner   = owner
        self.Dir      = dir:GetNormalized()
        self.Speed    = opts.speed or 2400
        self.Life     = opts.life or 4
        self.OnHit    = opts.onHit
        self.OnExpire = opts.onExpire
        self.HitWorld = opts.hitWorld ~= false -- explose aussi sur le décor
        local col = opts.color or Color(150, 60, 220)
        self:SetBoltColor(Vector(col.r / 255, col.g / 255, col.b / 255))
        self:SetPos((IsValid(owner) and owner:EyePos() or self:GetPos()) + self.Dir * 40)

        if opts.model then
            -- Modèle visible qui tourne (ex. rocher).
            self:SetModel(opts.model)
            self:SetNoDraw(false)
            self:SetHasModel(true)
            self:SetAngles(dir:Angle())
        elseif opts.particle and opts.particle ~= "" then
            self:SetFlyPart(opts.particle) -- particule attachée (client)
        else
            -- Placeholder : traînée colorée.
            util.SpriteTrail(self, 0, col, false, 16, 0, 0.55, 1 / 18, "trails/laser.vmt")
        end
    end

    function ENT:Detonate(tr)
        if self._done then return end
        self._done = true
        if isfunction(self.OnHit) then self.OnHit(tr) end
        self:Remove()
    end

    function ENT:Think()
        local pos = self:GetPos()
        local nxt = pos + self.Dir * self.Speed * FrameTime()
        local tr = util.TraceLine({ start = pos, endpos = nxt,
            filter = { self, self.SOwner }, mask = MASK_SHOT })

        if tr.Hit then
            self:SetPos(tr.HitPos)
            if IsValid(tr.Entity) or self.HitWorld then
                self:Detonate(tr)   -- effet à l'impact
            else
                self:Remove()       -- touche un mur mais n'agit pas dessus
            end
            return
        end

        self:SetPos(nxt)
        if self:GetHasModel() then self:SetAngles(self:GetAngles() + Angle(0, 0, 720 * FrameTime())) end
        if CurTime() - self.Born > self.Life then
            if isfunction(self.OnExpire) then self.OnExpire(self:GetPos()) end
            self:Remove()
            return
        end
        self:NextThink(CurTime())
        return true
    end
end

if CLIENT then
    function ENT:Initialize()
        self:SetRenderBounds(-Vector(256, 256, 256), Vector(256, 256, 256))
    end

    function ENT:Draw()
        if self:GetHasModel() then self:DrawModel() end -- modèle visible (rocher)
    end

    function ENT:Think()
        if not self.Att then
            local p = self:GetFlyPart()
            if p and p ~= "" then
                if SANGSPELL and SANGSPELL.ResolveParticle then p = SANGSPELL.ResolveParticle(p) end
                ParticleEffectAttach(p, PATTACH_ABSORIGIN_FOLLOW, self, 0)
            end
            self.Att = true
        end
        local c = self:GetBoltColor()
        local dl = DynamicLight(self:EntIndex())
        if dl then
            dl.pos = self:GetPos()
            dl.r, dl.g, dl.b = c.x * 255, c.y * 255, c.z * 255
            dl.brightness = 2
            dl.Decay = 1000
            dl.Size = 160
            dl.DieTime = CurTime() + 0.1
        end
    end

    function ENT:OnRemove() self:StopParticles() end
end
