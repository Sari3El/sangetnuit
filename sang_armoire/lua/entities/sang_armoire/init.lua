AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
    local model = (SARM and SARM.Config and SARM.Config.ArmoireModel) or "models/props_c17/FurnitureCabinet001a.mdl"
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
    if IsValid(activator) and activator:IsPlayer() and SARM.OpenArmoire then
        SARM.OpenArmoire(activator, self)
    end
end
