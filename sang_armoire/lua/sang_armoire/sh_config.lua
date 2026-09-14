--[[-------------------------------------------------------------------------
    Sang et Nuit — Armoire à PM : configuration (partagé)

      Une armoire (mobilier) qui permet à un joueur de :
        1) Changer les bodygroups du PM (arme à distance) qu'il porte
           actuellement — c'est GÉNÉRIQUE : on lit les bodygroups RÉELS
           du modèle de l'arme, rien à maintenir à la main ; ça fonctionne
           avec n'importe quel PM du moment que son .mdl a des bodygroups.
        2) Voir et équiper les différents PM disponibles pour son job (ou,
           à défaut, pour sa faction).
---------------------------------------------------------------------------]]

SARM = SARM or {}
SARM.Config = SARM.Config or {}
local C = SARM.Config

C.ArmoireModel = "models/props_c17/FurnitureCabinet001a.mdl"
C.OpenDist     = 140 -- portée (unités) pour ouvrir / utiliser l'armoire
C.OpenSound    = "items/ammocrate_open.wav"

----------------------------------------------------------------------
-- PM reconnus par l'armoire (whitelist des classes d'arme éditables).
--   Seules les armes listées ici peuvent voir leurs bodygroups modifiés,
--   et sont automatiquement retirées quand le joueur en équipe une autre
--   depuis l'armoire (un seul PM porté à la fois).
--   weapon_smg1 = le PM de base (HL2). Ajoute ici tes futures SWEP de PM
--   à mesure qu'elles sont créées.
----------------------------------------------------------------------
C.PMClasses = {
    "weapon_smg1",
    -- "sang_pm_empire", "sang_pm_consortium", ... (à venir)
}

SARM.PMSet = {}
for _, class in ipairs(C.PMClasses) do SARM.PMSet[class] = true end

function SARM.IsPM(class)
    return class ~= nil and SARM.PMSet[class] == true
end

----------------------------------------------------------------------
-- Noms de faction (affichage uniquement — doit suivre sang_jobs).
----------------------------------------------------------------------
C.FactionNames = {
    empire     = "Empire",
    creatures  = "Créatures de la Nuit",
    consortium = "Consortium",
    none       = "Sans Faction",
    event      = "Event",
}

----------------------------------------------------------------------
-- PM disponibles, par JOB en priorité, puis par FACTION en repli.
--   Chaque entrée : { class = "classe_arme", name = "Nom affiché" }
--
--   Complète C.JobWeapons["empire_5"] = { ... } pour un job précis (le
--   grade importe, l'id du job vient de sang_jobs). Si rien n'est défini
--   pour ce job, c'est la liste de C.FactionWeapons[faction] qui sert.
----------------------------------------------------------------------
C.JobWeapons = {
    -- ["empire_5"] = { { class = "weapon_smg1", name = "PM d'Officier" } },
}

C.FactionWeapons = {
    empire     = { { class = "weapon_smg1", name = "PM Réglementaire" } },
    consortium = { { class = "weapon_smg1", name = "PM du Consortium" } },
    -- creatures / none / event : rien par défaut — complète au besoin.
}

--- Liste des PM que CE joueur peut équiper (job en priorité, sinon faction).
--  Utilisable client ET serveur (ne lit que des NWString déjà répliquées).
function SARM.GetAvailableWeapons(ply)
    if not IsValid(ply) then return {} end
    local job = ply:GetNWString("sang_job", "")
    if job ~= "" and C.JobWeapons[job] then return C.JobWeapons[job] end
    local fac = ply:GetNWString("sang_faction", "none")
    return C.FactionWeapons[fac] or {}
end
