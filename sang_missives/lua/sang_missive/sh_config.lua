--[[-------------------------------------------------------------------------
    Sang et Nuit — Missives : configuration (partagé)
---------------------------------------------------------------------------]]

SMISSIVE = SMISSIVE or {}
SMISSIVE.Config = SMISSIVE.Config or {}

local C = SMISSIVE.Config

-- Modèle du bureau à missives (placeholder — remplace par un modèle dédié
-- type écritoire/coffre postal si tu en as un dans ton contenu).
C.Model    = "models/props_junk/wood_crate001a.mdl"
C.OpenDist = 140 -- portée pour ouvrir le bureau des missives

C.SubjectMax   = 60   -- longueur max de l'objet
C.BodyMax      = 900  -- longueur max du corps de la missive
C.SendCooldown = 8    -- secondes anti-spam entre deux envois
C.InboxLimit   = 80   -- nb max de missives conservées par boîte de réception

C.OpenSound = "items/ammocrate_open.wav"
C.SendSound = "buttons/button14.wav"

-- Renvoie la liste ordonnée des factions habilitées à envoyer/recevoir des
-- missives de faction (celles de sang_jobs, hors "Sans Faction" et "Event").
-- Vide si sang_jobs n'est pas chargé.
function SMISSIVE.RealFactions()
    local out = {}
    if not (SJOB and SJOB.Config and SJOB.Config.FactionOrder) then return out end
    for _, fac in ipairs(SJOB.Config.FactionOrder) do
        if fac ~= "none" and fac ~= "event" then out[#out + 1] = fac end
    end
    return out
end

function SMISSIVE.FactionName(fac)
    if SJOB and SJOB.Config and SJOB.Config.FactionNames and SJOB.Config.FactionNames[fac] then
        return SJOB.Config.FactionNames[fac]
    end
    return fac or "?"
end

function SMISSIVE.IsRealFaction(fac)
    for _, f in ipairs(SMISSIVE.RealFactions()) do
        if f == fac then return true end
    end
    return false
end
