--[[-------------------------------------------------------------------------
    Sang et Nuit — Projectile générique en ligne droite (sang_bolt)
      Avance tout droit dans une direction fixe. À l'impact (monde ou entité),
      appelle self.OnHit(trace) côté serveur (comportement défini par le sort).
      Visuel : traînée colorée (placeholder GMod) + lumière dynamique.
---------------------------------------------------------------------------]]

AddCSLuaFile()

ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Projectile"
ENT.Spawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("Vector", 0, "BoltColor")
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

        -- Traînée colorée (placeholder ; sera remplacée par une particule).
        util.SpriteTrail(self, 0, col, false, 16, 0, 0.55, 1 / 18, "trails/laser.vmt")
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
    function ENT:Initialize() end
    function ENT:Draw() end

    function ENT:Think()
        local c = self:GetBoltColor()
        local dl = DynamicLight(self:EntIndex())
        if dl then
            dl.pos       = self:GetPos()
            dl.r         = c.x * 255
            dl.g         = c.y * 255
            dl.b         = c.z * 255
            dl.brightness = 2
            dl.Decay     = 1000
            dl.Size      = 160
            dl.DieTime   = CurTime() + 0.1
        end
    end
end
