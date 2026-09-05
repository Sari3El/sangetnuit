--[[-------------------------------------------------------------------------
    Sang et Nuit — Nourriture : entité (serveur)
---------------------------------------------------------------------------]]

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
    local model = (SFOOD and SFOOD.Config and SFOOD.Config.Model) or "models/Gibs/HGIBS.mdl"
    self:SetModel(model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local maxUses = (SFOOD and SFOOD.Config and SFOOD.Config.MaxUses) or 3
    self:SetUsesLeft(maxUses)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
end

--- Consomme un repas ; retire l'entité quand il n'en reste plus.
function ENT:ConsumeOne(ply)
    local left = self:GetUsesLeft() - 1
    self:SetUsesLeft(left)

    local biteSound = (SFOOD and SFOOD.Config and SFOOD.Config.BiteSound)
    if biteSound then self:EmitSound(biteSound) end

    if left <= 0 then
        local ed = EffectData()
        ed:SetOrigin(self:GetPos() + self:OBBCenter())
        util.Effect("BloodImpact", ed)
        self:Remove()
    end
end
