AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
    local model = (SLVL and SLVL.Config and SLVL.Config.PersoModel) or "models/props_wasteland/gaspump001a.mdl"
    self:SetModel(model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) phys:Wake() end
end

function ENT:Use(activator)
    if not (IsValid(activator) and activator:IsPlayer()) then return end
    if activator.SPersoNextUse and CurTime() < activator.SPersoNextUse then return end
    activator.SPersoNextUse = CurTime() + 0.5
    if BLOOD and BLOOD.OpenCharacterMenu then
        BLOOD.OpenCharacterMenu(activator)
    end
end
