--[[-------------------------------------------------------------------------
    Sang et Nuit — Zone d'effet générique (sang_zone)
      Reste au sol un temps donné et applique un effet aux êtres vivants dans
      son rayon :
        - "slow"      : ralentit tout le monde tant qu'ils sont dedans.
        - "corrosion" : dégâts magiques par seconde (respecte les résistances).
      Visuel : dôme lumineux coloré (placeholder GMod) — sera remplacé par une
      particule plus tard.
---------------------------------------------------------------------------]]

AddCSLuaFile()

ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Zone temporelle"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:SetupDataTables()
    self:NetworkVar("Float",  0, "ZRadius")
    self:NetworkVar("Vector", 0, "ZColor")
end

if SERVER then
    function ENT:Initialize()
        self:SetModel("models/hunter/plates/plate.mdl")
        -- Pas de SetNoDraw : on dessine un dôme via DrawTranslucent (client).
        self:DrawShadow(false)
        self:SetSolid(SOLID_NONE)
        self:SetNotSolid(true)
        self:SetMoveType(MOVETYPE_NONE)
        self.NextTick = 0
        self:NextThink(CurTime())
    end

    -- kind : "slow" | "corrosion". amount = dégâts/s (corrosion) ou facteur de
    -- ralentissement 0..1 (slow). color = teinte du dôme.
    function ENT:SetupZone(owner, kind, radius, amount, duration, color)
        self.SOwner  = owner
        self.SKind   = kind or "corrosion"
        self.SAmount = amount or 3
        self.DieTime = CurTime() + (duration or 6)
        self:SetZRadius(radius or 200)
        color = color or Color(120, 60, 220)
        self:SetZColor(Vector(color.r / 255, color.g / 255, color.b / 255))
    end

    local function living(e)
        if not IsValid(e) then return false end
        if e:IsPlayer() then return e:Alive() end
        if e:IsNPC() then return e:Health() > 0 end
        return false
    end

    function ENT:Think()
        if CurTime() >= (self.DieTime or 0) then self:Remove() return end
        local pos, r = self:GetPos(), self:GetZRadius()

        if self.SKind == "slow" then
            -- Ré-applique un ralentissement court en continu (sortir = ça expire).
            if CurTime() >= self.NextTick then
                self.NextTick = CurTime() + 0.25
                for _, e in ipairs(ents.FindInSphere(pos, r)) do
                    if living(e) and e ~= self.SOwner and SANGSPELL.ApplySlow then
                        SANGSPELL.ApplySlow(e, self.SAmount, 0.45)
                    end
                end
            end
            self:NextThink(CurTime() + 0.1)
            return true
        end

        -- corrosion : dégâts magiques chaque seconde.
        if CurTime() >= self.NextTick then
            self.NextTick = CurTime() + 1
            for _, e in ipairs(ents.FindInSphere(pos, r)) do
                if living(e) and e ~= self.SOwner and SANGSPELL.DealDamage then
                    SANGSPELL.DealDamage(self.SOwner, e, self.SAmount, SANGSPELL.MAGIC or DMG_SHOCK, self)
                end
            end
        end
        self:NextThink(CurTime() + 0.1)
        return true
    end
end

if CLIENT then
    local glow = Material("sprites/light_glow02_add")

    function ENT:Initialize()
        self:SetRenderBounds(-Vector(512, 512, 512), Vector(512, 512, 512))
    end

    function ENT:Draw() end -- on ne dessine pas le modèle (plaque)

    -- Dôme lumineux additif (placeholder).
    function ENT:DrawTranslucent()
        local r = self:GetZRadius()
        if not r or r <= 0 then return end
        local c = self:GetZColor()
        local pulse = 0.75 + 0.25 * math.sin(CurTime() * 3)
        render.SetMaterial(glow)
        render.DrawSprite(self:GetPos() + Vector(0, 0, 10),
            r * 2.2, r * 2.2, Color(c.x * 255, c.y * 255, c.z * 255, 90 * pulse))

        local dl = DynamicLight(self:EntIndex())
        if dl then
            dl.pos = self:GetPos() + Vector(0, 0, 20)
            dl.r, dl.g, dl.b = c.x * 255, c.y * 255, c.z * 255
            dl.brightness = 2
            dl.Decay = 1000
            dl.Size = r * 2
            dl.DieTime = CurTime() + 0.1
        end
    end
end
