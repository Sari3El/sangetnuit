ENT.Type           = "anim"
ENT.Base           = "base_gmodentity"
ENT.PrintName      = "Or au sol (Sang et Nuit)"
ENT.Author         = "Sang et Nuit"
ENT.Category       = "Sang et Nuit"
ENT.Spawnable      = false
ENT.AdminSpawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "Gold")
end
