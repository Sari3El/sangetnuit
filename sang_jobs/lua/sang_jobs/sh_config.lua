--[[-------------------------------------------------------------------------
    Sang et Nuit — Jobs : configuration (partagé)

    Chaque job pose la BASE de PV / armure / vitesse. Ensuite la race
    multiplie (ses effets restent aussi), puis le niveau applique son %.
      PV      = job.hp   × race.hp × (1 + vitalité)
      vitesse = base_moteur × race.speed × job.speed × (1 + agilité)
      armure  = job.armor (statique)
    Une « Config Perso » (Origines) peut remplacer hp/armor/speed pour UN
    joueur sur UN job.
---------------------------------------------------------------------------]]

SJOB = SJOB or {}
SJOB.Config = SJOB.Config or {}
local C = SJOB.Config

C.DefaultJob   = "sansfaction" -- job de départ d'un nouveau personnage
C.ChangeCooldown = 2           -- anti-spam (s) sur le changement de job

-- Factions (pour le regroupement scoreboard + les banques de faction).
--   Le champ faction correspond à la clé banque : monstre / humain / guilde.
C.FactionOrder = { "humain", "monstre", "guilde", "none" }
C.FactionNames = { humain = "Humanité", monstre = "Monstre", guilde = "Guilde", none = "Sans faction" }

-- Les 4 jobs (ordre d'affichage F4).
C.Jobs = {
    {
        id = "sansfaction", name = "Sans Faction", faction = "none",
        color = Color(180, 180, 180),
        hp = 100, armor = 0, speed = 1.0,
        desc = "Neutre. Aucune appartenance.",
    },
    {
        id = "humanite", name = "Humanité", faction = "humain",
        color = Color(90, 160, 255),
        hp = 100, armor = 25, speed = 1.0,
        desc = "Les survivants humains.",
    },
    {
        id = "monstre", name = "Monstre", faction = "monstre",
        color = Color(200, 70, 70),
        hp = 120, armor = 50, speed = 0.95,
        desc = "Créatures de la nuit.",
    },
    {
        id = "guilde", name = "Guilde", faction = "guilde",
        color = Color(210, 176, 108),
        hp = 110, armor = 25, speed = 1.0,
        desc = "L'ordre de la Guilde.",
    },
}

-- Index par id.
SJOB.JobsById = {}
for _, j in ipairs(C.Jobs) do SJOB.JobsById[j.id] = j end

function SJOB.GetJob(id)
    return SJOB.JobsById[id] or SJOB.JobsById[C.DefaultJob] or C.Jobs[1]
end
function SJOB.JobExists(id) return SJOB.JobsById[id] ~= nil end
