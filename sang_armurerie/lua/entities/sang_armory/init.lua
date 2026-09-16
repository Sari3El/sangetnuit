AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
    local model = (SARM and SARM.Config and SARM.Config.ArmoryModel) or "models/props_junk/wood_crate001a.mdl"
    self:SetModel(model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false) -- reste en place
        phys:Wake()
    end
end

function ENT:Use(activator)
    if IsValid(activator) and activator:IsPlayer() and SARM.OpenArmory then
        SARM.OpenArmory(activator, self)
    end
end
