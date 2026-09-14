--[[-------------------------------------------------------------------------
    Sang et Nuit — SWEP « Mains »
      Mains nues : aucune arme visible, bras détendus le long du corps
      (holdtype « normal »). Aucune attaque. C'est l'arme par défaut tenue
      par tous les joueurs.
---------------------------------------------------------------------------]]

AddCSLuaFile()

SWEP.PrintName     = "Mains"
SWEP.Author        = "Sang et Nuit"
SWEP.Instructions  = "Mains nues."
SWEP.Category      = "Sang et Nuit"
SWEP.Spawnable     = true
SWEP.AdminOnly     = false

SWEP.Slot          = 0
SWEP.SlotPos       = 0
SWEP.DrawAmmo      = false
SWEP.DrawCrosshair = false

SWEP.ViewModel     = ""      -- rien en 1re personne
SWEP.WorldModel    = ""      -- rien en 3e personne
SWEP.UseHands      = false
SWEP.HoldType      = "normal" -- bras le long du corps

SWEP.Primary   = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }
SWEP.Secondary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }

function SWEP:Initialize()
    self:SetHoldType("normal")
end

function SWEP:Deploy()
    if IsValid(self:GetOwner()) then self:GetOwner():SetAnimation(PLAYER_IDLE) end
    return true
end

function SWEP:PrimaryAttack() end
function SWEP:SecondaryAttack() end
function SWEP:Reload() end
function SWEP:CanPrimaryAttack() return false end
function SWEP:CanSecondaryAttack() return false end
