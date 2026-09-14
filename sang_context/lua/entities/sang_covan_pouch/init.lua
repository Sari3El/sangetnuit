--[[-------------------------------------------------------------------------
    Sang et Nuit — Sac de Covan (serveur)
      Ramassable via USE (E). Disparaît tout seul après un délai.
---------------------------------------------------------------------------]]

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local MODEL   = "models/props_junk/garbage_bag001a.mdl" -- placeholder « sac » (teinté or)
local DESPAWN = 120                                     -- secondes avant disparition

function ENT:Initialize()
    self:SetModel(MODEL)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetColor(Color(232, 200, 96))
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end

    timer.Simple(DESPAWN, function()
        if IsValid(self) then SafeRemoveEntity(self) end
    end)
end

function ENT:Use(activator)
    if not (IsValid(activator) and activator:IsPlayer()) then return end
    if self.SangTaken then return end
    local amt = self:GetAmount()
    if amt <= 0 then SafeRemoveEntity(self) return end

    self.SangTaken = true
    if BLOOD and BLOOD.AddCovan then BLOOD.AddCovan(activator, amt) end
    if BLOOD and BLOOD.Notify then BLOOD.Notify(activator, "Tu as ramassé " .. amt .. " Covan.", "info") end
    SafeRemoveEntity(self)
end
