--[[-------------------------------------------------------------------------
    Sang et Nuit — Entité « portail » (Magie Arcanique / Translocation)
      Un portail décoratif : il s'ouvre (particule) au lancer, à l'entrée ET
      à la sortie, puis se referme (l'effet est stoppé) après CloseDelay s.
      Purement visuel — aucune collision, aucun dégât.
---------------------------------------------------------------------------]]

AddCSLuaFile()

ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Portail"
ENT.Spawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "PortalParticle")
end

if SERVER then
    function ENT:Initialize()
        self:SetModel("models/hunter/plates/plate.mdl")
        self:SetNoDraw(true)
        self:DrawShadow(false)
        self:SetSolid(SOLID_NONE)
        self:SetNotSolid(true)
        self:SetMoveType(MOVETYPE_NONE)
    end

    --- particle = nom exact du système ; life = durée avant fermeture (s).
    function ENT:SetupPortal(particle, life)
        self:SetPortalParticle(particle or "")
        local t = math.max(0.1, tonumber(life) or 2)
        timer.Simple(t, function() if IsValid(self) then self:Remove() end end)
    end
end

if CLIENT then
    function ENT:Initialize() end
    function ENT:Draw() end

    function ENT:Think()
        if not self.Att then
            local p = self:GetPortalParticle()
            if p and p ~= "" then
                -- Garantit que le .pcf du portail est bien enregistré côté
                -- client (et résout « [N]_ » au cas où).
                if SANGSPELL and SANGSPELL.ResolveParticle then p = SANGSPELL.ResolveParticle(p) end
                ParticleEffectAttach(p, PATTACH_ABSORIGIN_FOLLOW, self, 0)
                self.Att = true
            end
        end
    end

    function ENT:OnRemove()
        self:StopParticles()
    end
end
