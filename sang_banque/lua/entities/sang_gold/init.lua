AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
    local model = (SBANK and SBANK.Config and SBANK.Config.GoldModel) or "models/props_c17/clock01.mdl"
    self:SetModel(model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:SetGold(0)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end
end

--- Ramassage en [E].
function ENT:Use(activator)
    if not (IsValid(activator) and activator:IsPlayer()) then return end
    if activator.SGoldNextUse and CurTime() < activator.SGoldNextUse then return end
    activator.SGoldNextUse = CurTime() + 0.3

    local amt = self:GetGold()
    if amt > 0 and BLOOD and BLOOD.AddCovan then
        BLOOD.AddCovan(activator, amt)
        if SBANK.Config.PickupSound then activator:EmitSound(SBANK.Config.PickupSound) end
        if BLOOD.Notify then
            local cur = (BLOOD.Config and BLOOD.Config.Currency) or "Covan"
            BLOOD.Notify(activator, "Tu as ramassé " .. amt .. " " .. cur .. ".", "info")
        end
    end
    self:Remove()
end
