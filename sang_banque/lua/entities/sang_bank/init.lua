AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
    local model = (SBANK and SBANK.Config and SBANK.Config.BankModel) or "models/props_wasteland/controlroom_filecabinet001a.mdl"
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
    if IsValid(activator) and activator:IsPlayer() and SBANK.OpenBank then
        SBANK.OpenBank(activator, self)
    end
end
