--[[-------------------------------------------------------------------------
    Sang et Nuit — Bouclier temporel (sang_timeshield)  [Magie Temporelle]
      Posé à la position du lancer, il RESTE sur place jusqu'à sa disparition ;
      le lanceur peut bouger et entrer/sortir librement.
      Effet dans son rayon :
        - protège de tout dégât (venant de l'extérieur) ceux qui sont dedans ;
        - fige les projectiles/objets physiques qui entrent (restaurés à la fin).
      Visuel : dôme bleu (placeholder GMod).
---------------------------------------------------------------------------]]

AddCSLuaFile()

ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Bouclier temporel"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:SetupDataTables()
    self:NetworkVar("Float", 0, "SRadius")
end

if SERVER then
    function ENT:Initialize()
        self:SetModel("models/hunter/plates/plate.mdl")
        -- Pas de SetNoDraw : dôme dessiné via DrawTranslucent (client).
        self:DrawShadow(false)
        self:SetSolid(SOLID_NONE)
        self:SetNotSolid(true)
        self:SetMoveType(MOVETYPE_NONE)
        self.Frozen = {}
        self:NextThink(CurTime())
    end

    function ENT:SetupShield(owner, radius, duration)
        self.SOwner  = owner
        self:SetSRadius(radius or 200)
        self.DieTime = CurTime() + (duration or 8)
        if self.Sound then self:EmitSound(self.Sound) end

        -- Protège tout ce qui se trouve dans la bulle.
        self.HookID = "SangShield_" .. self:EntIndex()
        hook.Add("EntityTakeDamage", self.HookID, function(target)
            if not IsValid(self) then return end
            if IsValid(target) and target:GetPos():Distance(self:GetPos()) <= self:GetSRadius() then
                return true -- dégât bloqué
            end
        end)
    end

    function ENT:Think()
        if CurTime() >= (self.DieTime or 0) then self:Remove() return end
        -- Fige les projectiles/objets physiques présents dans la bulle.
        for _, e in ipairs(ents.FindInSphere(self:GetPos(), self:GetSRadius())) do
            if IsValid(e) and e ~= self and e ~= self.SOwner
               and not e:IsPlayer() and not e:IsNPC()
               and string.sub(e:GetClass(), 1, 5) ~= "sang_" then
                local phys = e:GetPhysicsObject()
                if IsValid(phys) and phys:IsMotionEnabled() then
                    self.Frozen[e] = { vel = phys:GetVelocity(), avel = phys:GetAngleVelocity() }
                    phys:EnableMotion(false)
                    phys:SetVelocity(vector_origin)
                end
            end
        end
        self:NextThink(CurTime() + 0.1)
        return true
    end

    function ENT:OnRemove()
        if self.HookID then hook.Remove("EntityTakeDamage", self.HookID) end
        for e, d in pairs(self.Frozen or {}) do
            if IsValid(e) then
                local phys = e:GetPhysicsObject()
                if IsValid(phys) then
                    phys:EnableMotion(true)
                    phys:Wake()
                    if d.vel  then phys:SetVelocity(d.vel) end
                    if d.avel then phys:AddAngleVelocity(d.avel) end
                end
            end
        end
    end
end

if CLIENT then
    local glow = Material("sprites/light_glow02_add")
    local col = Color(80, 160, 255)

    function ENT:Initialize()
        self:SetRenderBounds(-Vector(512, 512, 512), Vector(512, 512, 512))
    end
    function ENT:Draw() end

    function ENT:DrawTranslucent()
        local r = self:GetSRadius()
        if not r or r <= 0 then return end
        local pulse = 0.7 + 0.3 * math.sin(CurTime() * 4)
        render.SetMaterial(glow)
        render.DrawSprite(self:GetPos() + Vector(0, 0, r * 0.4), r * 2.4, r * 2.4,
            Color(col.r, col.g, col.b, 70 * pulse))

        local dl = DynamicLight(self:EntIndex())
        if dl then
            dl.pos = self:GetPos() + Vector(0, 0, 20)
            dl.r, dl.g, dl.b = col.r, col.g, col.b
            dl.brightness = 3
            dl.Decay = 1000
            dl.Size = r * 2.2
            dl.DieTime = CurTime() + 0.1
        end
    end
end
