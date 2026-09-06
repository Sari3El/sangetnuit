--[[-------------------------------------------------------------------------
    Sang et Nuit — Sphère des Éléments (sang_elemsphere)  [Élémentaire / E9]
      Bulle de protection (vent/feu/eau/terre) qui entoure le lanceur et le
      suit. Le lanceur est invincible (géré côté sort). La sphère repousse les
      ennemis qui tentent d'entrer. Reste jusqu'à désactivation ou fin de durée.
      Visuel : dôme multicolore (placeholder GMod).
---------------------------------------------------------------------------]]

AddCSLuaFile()

ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Sphère des Éléments"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:SetupDataTables()
    self:NetworkVar("Float", 0, "SRadius")
end

if SERVER then
    function ENT:Initialize()
        self:SetModel("models/hunter/plates/plate.mdl")
        self:DrawShadow(false)
        self:SetSolid(SOLID_NONE)
        self:SetNotSolid(true)
        self:SetMoveType(MOVETYPE_NONE)
        self:NextThink(CurTime())
    end

    function ENT:SetupSphere(owner, radius, pushForce, dur)
        self.SOwner  = owner
        self.Push    = pushForce or 650
        self:SetSRadius(radius or 150)
        self.DieTime = CurTime() + (dur or 15)
        self:SetParent(owner)
        self:SetLocalPos(Vector(0, 0, 40))
    end

    function ENT:Think()
        local o = self.SOwner
        if not IsValid(o) or not o:Alive() or CurTime() >= self.DieTime then self:Remove() return end
        -- Repousse doucement les ennemis qui entrent dans la bulle.
        for _, e in ipairs(ents.FindInSphere(self:GetPos(), self:GetSRadius())) do
            if IsValid(e) and e ~= o and (e:IsPlayer() or e:IsNPC())
               and string.sub(e:GetClass(), 1, 5) ~= "sang_" then
                local dir = (e:WorldSpaceCenter() - self:GetPos())
                if dir:LengthSqr() < 1 then dir = VectorRand() end
                dir.z = math.max(dir.z, 0)
                dir:Normalize()
                e:SetVelocity(dir * self.Push)
            end
        end
        self:NextThink(CurTime() + 0.2)
        return true
    end
end

if CLIENT then
    local glow = Material("sprites/light_glow02_add")
    -- 4 éléments : feu, eau, vent, terre.
    local elems = { Color(255, 120, 30), Color(60, 120, 255), Color(150, 230, 255), Color(150, 100, 50) }

    function ENT:Initialize()
        self:SetRenderBounds(-Vector(400, 400, 400), Vector(400, 400, 400))
    end
    function ENT:Draw() end

    function ENT:DrawTranslucent()
        local r = self:GetSRadius()
        if not r or r <= 0 then return end
        local t = CurTime() * 0.6
        local i = math.floor(t) % 4
        local j = (i + 1) % 4
        local f = t - math.floor(t)
        local c = LerpVector(f, elems[i + 1]:ToVector(), elems[j + 1]:ToVector())
        local cr, cg, cb = c.x * 255, c.y * 255, c.z * 255
        local pulse = 0.75 + 0.25 * math.sin(CurTime() * 5)

        render.SetMaterial(glow)
        render.DrawSprite(self:GetPos(), r * 2.6, r * 2.6, Color(cr, cg, cb, 85 * pulse))

        local dl = DynamicLight(self:EntIndex())
        if dl then
            dl.pos = self:GetPos()
            dl.r, dl.g, dl.b = cr, cg, cb
            dl.brightness = 3
            dl.Decay = 1000
            dl.Size = r * 2.4
            dl.DieTime = CurTime() + 0.1
        end
    end
end
