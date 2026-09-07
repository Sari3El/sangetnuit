--[[-------------------------------------------------------------------------
    Sang et Nuit — SWEP « Coup d'Expulsion »
      Clic gauche sur quelqu'un : le frappe, l'envoie dans le ciel puis le
      téléporte à la position fixe (voir sang_expulsion_init.lua).
---------------------------------------------------------------------------]]

AddCSLuaFile()

SWEP.PrintName   = "Coup d'Expulsion"
SWEP.Author      = "Sang et Nuit"
SWEP.Instructions = "Clic gauche sur une cible pour l'expulser."
SWEP.Category    = "Sang et Nuit"
SWEP.Spawnable   = true
SWEP.AdminOnly   = true

SWEP.Slot        = 1
SWEP.SlotPos     = 0
SWEP.DrawAmmo    = false
SWEP.DrawCrosshair = true

SWEP.ViewModel   = "models/weapons/c_arms.mdl"
SWEP.WorldModel  = ""
SWEP.UseHands    = true

SWEP.Primary   = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }
SWEP.Secondary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }

function SWEP:Initialize()
    self:SetHoldType("fist")
end

function SWEP:PrimaryAttack()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local cd = (EXP and EXP.Config and EXP.Config.Cooldown) or 3
    self:SetNextPrimaryFire(CurTime() + cd)

    self:SendWeaponAnim(ACT_VM_HITCENTER)
    owner:SetAnimation(PLAYER_ATTACK1)

    if not SERVER then return end
    if not EXP or not EXP.Expel then return end

    local range = (EXP.Config and EXP.Config.Range) or 300
    local tr = util.TraceLine({
        start  = owner:GetShootPos(),
        endpos = owner:GetShootPos() + owner:GetAimVector() * range,
        filter = owner,
        mask   = MASK_SHOT,
    })

    local ent = tr.Entity
    if IsValid(ent) and (ent:IsPlayer() or ent:IsNPC()) then
        if EXP.Expel(owner, ent) then
            return
        end
    end
    -- Rien touché : coup dans le vide.
    owner:EmitSound("physics/body/body_medium_impact_soft" .. math.random(1, 7) .. ".wav", 65, 110)
end

function SWEP:SecondaryAttack()
end

function SWEP:Deploy()
    self:SendWeaponAnim(ACT_VM_DRAW)
    return true
end
