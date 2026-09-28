--[[-------------------------------------------------------------------------
    Sang et Nuit — Griffe de l'Originel
      Sabre wiltOS (ALCS / AdvSWL) dérivé de la base « personal ».

      TEMPORAIRE : réutilise les modèles placeholder du sabre personnel
      (pas encore de visuel dédié). Plus tard ce sera de vraies griffes.

      Cette arme est DONNÉE AUTOMATIQUEMENT au job « L'Originel » (hybride_15)
      par le loadout de sang_jobs (voir sang_jobs/sv_jobs.lua). Elle reste
      spawnable côté admin pour les tests.

      Stats / hilt / couleur / dégâts se règlent dans le fichier wiltOS :
        wos/advswl/config/crafting/sh_craftwos.lua

    Base technique wiltOS : Copyright David "King David" Wiltos / Robotboy655.
---------------------------------------------------------------------------]]

AddCSLuaFile()

SWEP.Base     = "wos_adv_single_lightsaber_base" -- sabre simple (non dual)

SWEP.Author   = "Sang et Nuit (base wiltOS — Robotboy655 + King David)"
SWEP.Category = "Lightsabers"
SWEP.Contact  = ""
SWEP.RenderGroup = RENDERGROUP_BOTH
SWEP.Slot     = 0
SWEP.SlotPos  = 4

SWEP.Spawnable  = true
SWEP.AdminOnly  = true -- donné par le job ; spawnable seulement par le staff

SWEP.DrawAmmo   = false
SWEP.DrawCrosshair = false
SWEP.AutoSwitchTo   = false
SWEP.AutoSwitchFrom = false
SWEP.DrawWeaponInfoBox = false

-- Modèles placeholder (repris du sabre personnel, en attendant les griffes).
SWEP.ViewModel   = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel  = "models/sgg/starwars/weapons/w_anakin_ep2_saber_hilt.mdl"
SWEP.ViewModelFOV = 55

SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic   = false
SWEP.Primary.Ammo        = "none"
SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = true
SWEP.Secondary.Ammo        = "none"

------------------------------------------------------------------------
-- Paramètres du sabre (équivalents à ceux du « personal »)
------------------------------------------------------------------------
SWEP.PrintName = "Griffe de l'Originel" -- nom affiché
SWEP.Class     = "weapon_griffe_originel" -- doit correspondre au nom de fichier
SWEP.DualWielded = false -- sabre simple
SWEP.CanMoveWhileAttacking = false
SWEP.MaxForce   = 100 -- jauge de force max
SWEP.RegenSpeed = 1   -- multiplicateur de régénération
SWEP.CanKnockback = true -- repousse les cibles touchées
SWEP.ForcePowerList = { "Force Leap" } -- pouvoirs (à définir plus tard)

SWEP.UseSkills = true
SWEP.PersonalLightsaber = false -- sabre FIXE (pas lié au perso wiltOS)
