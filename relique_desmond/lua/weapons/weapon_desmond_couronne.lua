--[[-------------------------------------------------------------------------
    Relique Desmond — SWEP « Couronne de Lumière »
      Clic gauche = cycle visuel :
        état 0 (rien) -> 1 (couronne sur la tête + anim) -> 2 (aura au sol) -> 0
      (Effets de gameplay à venir ; pour l'instant, visuel seulement.)
---------------------------------------------------------------------------]]

AddCSLuaFile()

SWEP.PrintName    = "Couronne de Lumière"
SWEP.Author       = "Sang et Nuit"
SWEP.Instructions = "Clic gauche : couronne -> aura -> rien."
SWEP.Category     = "Sang et Nuit"
SWEP.Spawnable    = true
SWEP.AdminOnly    = true

SWEP.Slot         = 2
SWEP.SlotPos      = 0
SWEP.DrawAmmo     = false
SWEP.DrawCrosshair = true

SWEP.ViewModel    = "models/weapons/c_arms.mdl"
SWEP.WorldModel   = ""
SWEP.UseHands     = true

SWEP.Primary   = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }
SWEP.Secondary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }

function SWEP:Initialize()
    self:SetHoldType("normal")
end

function SWEP:PrimaryAttack()
    local o = self:GetOwner()
    if not IsValid(o) then return end

    local cd = (DESMOND and DESMOND.Config and DESMOND.Config.Cooldown) or 0.4
    self:SetNextPrimaryFire(CurTime() + cd)
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

    if not SERVER then return end

    local st = o:GetNWInt("desmond_state", 0)
    local nx = (st + 1) % 3            -- 0 -> 1 -> 2 -> 0
    o:SetNWInt("desmond_state", nx)

    -- Anim forcée uniquement sur l'état « couronne ».
    if nx == 1 and DESMOND and DESMOND.Config then
        o:SetNWString("desmond_seq", DESMOND.Config.Anim or "")
    else
        o:SetNWString("desmond_seq", "")
    end
end

function SWEP:SecondaryAttack()
end

-- Enlève l'état/les particules quand on range ou lâche l'arme.
local function clear(o)
    if IsValid(o) and o:IsPlayer() then
        o:SetNWInt("desmond_state", 0)
        o:SetNWString("desmond_seq", "")
    end
end

function SWEP:Holster() clear(self:GetOwner()) return true end
function SWEP:OnRemove() clear(self:GetOwner()) end
function SWEP:OwnerChanged() clear(self:GetOwner()) end

function SWEP:Deploy()
    self:SendWeaponAnim(ACT_VM_DRAW)
    return true
end
