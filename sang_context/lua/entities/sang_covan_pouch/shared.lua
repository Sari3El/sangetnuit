--[[-------------------------------------------------------------------------
    Sang et Nuit — Sac de Covan (entité ramassable, partagé)
---------------------------------------------------------------------------]]

ENT.Type      = "anim"
ENT.Base      = "base_gmodentity"
ENT.PrintName = "Sac de Covan"
ENT.Spawnable = false
ENT.AdminOnly = false

function ENT:SetAmount(n)  self:SetNWInt("sang_covan", math.floor(n or 0)) end
function ENT:GetAmount()   return self:GetNWInt("sang_covan", 0) end
function ENT:SetDropper(s) self:SetNWString("sang_dropper", s or "") end
function ENT:GetDropper()  return self:GetNWString("sang_dropper", "") end
