--[[-------------------------------------------------------------------------
    Sang et Nuit — Lien de sang (sang_link)  [Magie Nécrotique / N1]
      Lien rouge visible entre le lanceur et la cible : draine la vie de la
      cible et soigne le lanceur, tant que la distance reste sous MaxLink.
      Se coupe si trop loin, si l'un meurt, ou à la fin de la durée.
---------------------------------------------------------------------------]]

AddCSLuaFile()

ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Lien de sang"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "LinkOwner")
    self:NetworkVar("Entity", 1, "LinkTarget")
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

    function ENT:SetupLink(owner, target, dur, maxDist, dps, healRatio)
        self.SOwner    = owner
        self.STarget   = target
        self.DieTime   = CurTime() + (dur or 6)
        self.MaxDist   = maxDist or 700
        self.Dps       = dps or 8
        self.HealRatio = healRatio or 0.5
        self:SetLinkOwner(owner)
        self:SetLinkTarget(target)
    end

    local function alive(e)
        return IsValid(e) and (e:IsPlayer() and e:Alive() or (e:IsNPC() and e:Health() > 0))
    end

    function ENT:Think()
        local o, t = self.SOwner, self.STarget
        if not alive(o) or not alive(t) or CurTime() >= self.DieTime then self:Remove() return end
        if o:GetPos():Distance(t:GetPos()) > self.MaxDist then self:Remove() return end -- lien coupé

        local dt = 0.2
        local dmg = self.Dps * dt
        SANGSPELL.DealDamage(o, t, dmg, SANGSPELL.MAGIC or DMG_SHOCK, self)
        if SANGSPELL.Heal then SANGSPELL.Heal(o, dmg * self.HealRatio) end

        self:SetPos((o:WorldSpaceCenter() + t:WorldSpaceCenter()) * 0.5)
        self:NextThink(CurTime() + dt)
        return true
    end
end

if CLIENT then
    local beam = Material("trails/laser.vmt")
    local col  = Color(200, 20, 30)

    function ENT:Initialize()
        self:SetRenderBounds(-Vector(1024, 1024, 1024), Vector(1024, 1024, 1024))
    end
    function ENT:Draw() end

    function ENT:DrawTranslucent()
        local o, t = self:GetLinkOwner(), self:GetLinkTarget()
        if not (IsValid(o) and IsValid(t)) then return end
        local a, b = o:WorldSpaceCenter(), t:WorldSpaceCenter()
        render.SetMaterial(beam)
        render.DrawBeam(a, b, 10, 0, a:Distance(b) / 40,
            Color(col.r, col.g, col.b, 200 + 40 * math.sin(CurTime() * 12)))
    end
end
