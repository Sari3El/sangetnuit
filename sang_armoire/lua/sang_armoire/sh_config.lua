--[[-------------------------------------------------------------------------
    Sang et Nuit — Armoire à PM (playermodel) : configuration (partagé)

      Une armoire (mobilier) qui permet à un joueur de :
        1) Changer les bodygroups (et le skin) du PLAYERMODEL qu'il porte
           actuellement — c'est GÉNÉRIQUE : on lit les bodygroups RÉELS du
           modèle, rien à maintenir à la main ; ça fonctionne avec
           n'importe quel playermodel.
        2) Voir et équiper les différents playermodels disponibles pour son
           job (ou, à défaut, sa faction).
---------------------------------------------------------------------------]]

SARM = SARM or {}
SARM.Config = SARM.Config or {}
local C = SARM.Config

-- Modèle de l'ARMOIRE ELLE-MÊME (le meuble), pas un playermodel. Essaie
-- controlroom_filecabinet001a, puis se replie automatiquement sur d'autres
-- meubles si celui-ci n'est pas dispo sur ce serveur (contenu HL2 non monté),
-- et en tout dernier recours sur le damier rose/noir "models/error.mdl".
C.ArmoireModel = "models/props_wasteland/controlroom_filecabinet001a.mdl"
C.ArmoireModelFallbacks = {
    "models/props_c17/FurnitureCabinet001a.mdl",
    "models/props_c17/FurnitureShelf001a.mdl",
    "models/props_junk/wood_crate001a.mdl",
}
C.OpenDist  = 140 -- portée (unités) pour ouvrir / utiliser l'armoire
C.OpenSound = "items/ammocrate_open.wav"

--- Renvoie le premier modèle de meuble valide de la liste ci-dessus (ou
--  models/error.mdl si aucun ne l'est), avec un avertissement console.
function SARM.ResolveModel()
    local candidates = { C.ArmoireModel }
    for _, m in ipairs(C.ArmoireModelFallbacks or {}) do candidates[#candidates + 1] = m end

    for _, m in ipairs(candidates) do
        if m and m ~= "" and util.IsValidModel(m) and util.IsValidProp(m) then
            return m
        end
    end

    MsgN("[Sang Armoire][ERREUR] Aucun modèle de meuble valide parmi : " .. table.concat(candidates, ", "))
    MsgN("[Sang Armoire][ERREUR] -> contenu HL2 manquant sur ce serveur, ou faute de frappe dans SARM.Config.ArmoireModel.")
    MsgN("[Sang Armoire][ERREUR] -> Repli sur models/error.mdl (damier rose/noir). Pour corriger : vise un meuble "
        .. "qui s'affiche déjà chez toi (Q > Entités/Props), clic droit dessus > 'Copier vers le presse-papiers' "
        .. "(ou la commande console 'lua_run print(LocalPlayer():GetEyeTrace().Entity:GetModel())' en visant le prop), "
        .. "puis colle ce chemin dans SARM.Config.ArmoireModel.")
    return "models/error.mdl"
end

--- Un chemin de PLAYERMODEL est-il utilisable sur ce serveur ?
--  ATTENTION : util.IsValidProp() sert à valider des physics props
--  (spawnables comme objets) — un playermodel légitime (rigged, sans
--  collision "prop") y échoue quasi systématiquement. On vérifie donc
--  juste que le chemin a une forme correcte ET que le fichier existe
--  réellement dans le contenu monté (GAME = tous les .gma/.vpk montés).
function SARM.IsValidPlayerModel(model)
    return model ~= nil and model ~= "" and util.IsValidModel(model) and file.Exists(model, "GAME")
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
-- PLAYERMODELS disponibles, par JOB en priorité, puis par FACTION en repli,
-- PLUS la liste GlobalModels qui est TOUJOURS proposée en plus (utile pour
-- avoir tout de suite au moins un choix, quel que soit le job).
--   Chaque entrée : { model = "models/...mdl", name = "Nom affiché" }
--
--   Complète C.JobModels["empire_5"] = { ... } pour un job précis (l'id du
--   job vient de sang_jobs). Si rien n'est défini pour ce job, c'est la
--   liste de C.FactionModels[faction] qui sert.
----------------------------------------------------------------------
C.JobModels = {
    -- "sansfaction" = id du job "Sans Faction" dans sang_jobs (job de départ).
    sansfaction = {
        { model = "models/Humans/Group1M/Male_04.mdl", name = "Citoyen (Male 04)" },
        { model = "models/Humans/Group1M/Male_05.mdl", name = "Citoyen (Male 05)" },
        { model = "models/Humans/Group1M/male_06.mdl", name = "Citoyen (Male 06)" },
        { model = "models/Humans/Group1M/male_07.mdl", name = "Citoyen (Male 07)" },
    },
    -- ["empire_5"] = { { model = "models/Combine_Soldier.mdl", name = "Soldat" } },
}

C.FactionModels = {
    -- empire     = { { model = "models/police.mdl", name = "Milicien" } },
    -- creatures  = { { model = "models/zombie/classic.mdl", name = "Créature" } },
    -- consortium = { { model = "models/alyx.mdl", name = "Agent du Consortium" } },
}

-- Toujours proposés, en plus de la liste job/faction (vide par défaut :
-- chaque job a désormais SES propres playermodels via JobModels/FactionModels).
C.GlobalModels = {}

--- Liste des playermodels que CE joueur peut équiper (job en priorité,
--  sinon faction, plus GlobalModels en plus si non vide). Utilisable
--  client ET serveur (ne lit que des NWString déjà répliquées).
function SARM.GetAvailableModels(ply)
    if not IsValid(ply) then return {} end
    local out = {}

    local job = ply:GetNWString("sang_job", "")
    local specific = (job ~= "" and C.JobModels[job])
    if not specific then
        local fac = ply:GetNWString("sang_faction", "none")
        specific = C.FactionModels[fac]
    end
    if specific then
        for _, m in ipairs(specific) do out[#out + 1] = m end
    end
    for _, m in ipairs(C.GlobalModels or {}) do out[#out + 1] = m end

    return out
end
