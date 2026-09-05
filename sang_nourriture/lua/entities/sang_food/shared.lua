--[[-------------------------------------------------------------------------
    Sang et Nuit — Nourriture : entité (partagé)
---------------------------------------------------------------------------]]

ENT.Type            = "anim"
ENT.Base            = "base_gmodentity"
ENT.PrintName       = "Nourriture (Sang et Nuit)"
ENT.Author          = "Sang et Nuit"
ENT.Category        = "Sang et Nuit"
ENT.Spawnable       = true
ENT.AdminSpawnable  = true

function ENT:SetupDataTables()
    -- Nombre de repas restants (réseauté, lisible côté client pour l'indice).
    self:NetworkVar("Int", 0, "UsesLeft")
end
