--[[-------------------------------------------------------------------------
    Sang et Nuit — Armurerie : configuration (partagé)
---------------------------------------------------------------------------]]

SARM = SARM or {}
SARM.Config = SARM.Config or {}

local C = SARM.Config

C.ArmoryModel = "models/props_junk/wood_crate001a.mdl"

C.OpenDist = 140  -- portée pour ouvrir l'armurerie
C.MaxItems = 40   -- nombre max d'armes stockables PAR personnage (slot)

C.OpenSound = "items/ammocrate_open.wav"

-- Armes qu'on ne peut JAMAIS ranger (mains nues, outils sandbox...).
C.Blacklist = {
    ["weapon_sang_mains"] = true,
    ["gmod_tool"]         = true,
    ["gmod_camera"]       = true,
    ["weapon_physgun"]    = true,
}

-- Une arme peut-elle être rangée dans l'armurerie ?
function SARM.CanStore(class)
    return class ~= nil and class ~= "" and not C.Blacklist[class]
end
