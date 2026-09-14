--[[-------------------------------------------------------------------------
    Sang et Nuit — Jobs : configuration (partagé)

    Hiérarchies par faction (grades 1-9 = basse, 10-15 = haute) :
      - Empire (Milice de la Marche)
      - Créatures de la Nuit  (Lycan 1-9 / Vampire 1-9 -> Hybride 10-15)
      - Consortium            (Banquier + Courtier/Intendant + Lames 1-9)
      + Sans Faction (job de départ) et Event (slot event).

    STATS CROISSANTES PAR GRADE : chaque faction a un profil (PV/armure de base
    + un pas par grade). Formule :
        PV     = base + (grade-1) * pas
        armure = base + (grade-1) * pas
    Le staff peut toujours surcharger par (slot+job) via Origines.
    Les jobs ne donnent AUCUNE arme : le loadout (mains/physgun/toolgun/gravgun)
    est commun à tous (voir sv_jobs.lua).
---------------------------------------------------------------------------]]

SJOB = SJOB or {}
SJOB.Config = SJOB.Config or {}
local C = SJOB.Config

C.DefaultJob     = "sansfaction" -- job de départ d'un nouveau personnage
C.ChangeCooldown = 2             -- (inutilisé : le joueur ne change plus de job)
C.EventJob       = "event"       -- job par défaut du slot EVENT

-- Factions (regroupement scoreboard + banques).
C.FactionOrder = { "empire", "creatures", "consortium", "none", "event" }
C.FactionNames = {
    empire     = "Empire",
    creatures  = "Créatures de la Nuit",
    consortium = "Consortium",
    none       = "Sans Faction",
    event      = "Event",
}

local COL = {
    empire     = Color(96, 132, 208),  -- bleu acier
    creatures  = Color(168, 46, 44),   -- rouge sang
    consortium = Color(210, 176, 108), -- or
    none       = Color(170, 170, 170), -- gris
    event      = Color(160, 92, 214),  -- violet
}

-- Profils de croissance des stats par faction combattante.
local PROF = {
    empire     = { hp = 100, hpStep = 8, armor = 25, armorStep = 5, speed = 1.00 },
    creatures  = { hp = 110, hpStep = 9, armor = 10, armorStep = 3, speed = 1.05 },
    consortium = { hp = 100, hpStep = 8, armor = 15, armorStep = 4, speed = 1.00 },
}

C.Jobs = {}
local function add(job) C.Jobs[#C.Jobs + 1] = job end

local function statsFor(faction, grade)
    local p = PROF[faction]
    if not p then return 100, 0, 1.0 end
    return math.Round(p.hp + (grade - 1) * p.hpStep),
           math.Round(p.armor + (grade - 1) * p.armorStep),
           p.speed
end

local function gradeJob(id, name, faction, grade, desc)
    local hp, armor, speed = statsFor(faction, grade)
    add({ id = id, name = name, faction = faction, grade = grade,
          color = COL[faction], hp = hp, armor = armor, speed = speed, desc = desc or "" })
end

----------------------------------------------------------------------
-- Sans Faction (départ) + Event
----------------------------------------------------------------------
add({ id = "sansfaction", name = "Sans Faction", faction = "none", grade = 0,
      color = COL.none, hp = 100, armor = 0, speed = 1.0,
      desc = "Neutre. Aucune appartenance. Rejoins une faction en RP." })

add({ id = "event", name = "Event", faction = "event", grade = 0, event = true,
      color = COL.event, hp = 100, armor = 0, speed = 1.0,
      desc = "Personnage d'évènement (stats équilibrées, niveau figé)." })

----------------------------------------------------------------------
-- EMPIRE (Milice de la Marche)
----------------------------------------------------------------------
local EMPIRE = {
    [1] = "Recrue", [2] = "Milicien", [3] = "Soldat", [4] = "Vétéran",
    [5] = "Chef de file", [6] = "Caporal", [7] = "Caporal-chef",
    [8] = "Sergent", [9] = "Sergent-chef",
    [10] = "Adjudant", [11] = "Adjudant-chef", [12] = "Enseigne",
    [13] = "Lieutenant", [14] = "Second", [15] = "Capitaine de la Milice",
}
for g = 1, 15 do gradeJob("empire_" .. g, EMPIRE[g], "empire", g) end

----------------------------------------------------------------------
-- CRÉATURES DE LA NUIT (Lycan / Vampire -> Hybride)
----------------------------------------------------------------------
local LYCAN = {
    [1] = "Griffé", [2] = "Louveteau", [3] = "Rôdeur", [4] = "Chasseur",
    [5] = "Traqueur", [6] = "Égorgeur", [7] = "Fauve", [8] = "Meneur", [9] = "Alpha",
}
for g = 1, 9 do gradeJob("lycan_" .. g, LYCAN[g], "creatures", g, "Voie de la Lune (Lycan)") end

local VAMPIRE = {
    [1] = "Assoiffé", [2] = "Nouveau-Né", [3] = "Affranchi", [4] = "Nocturne",
    [5] = "Prédateur", [6] = "Vampire", [7] = "Baron", [8] = "Vicomte", [9] = "Comte",
}
for g = 1, 9 do gradeJob("vampire_" .. g, VAMPIRE[g], "creatures", g, "Voie du Sang (Vampire)") end

local HYBRIDE = {
    [10] = "Hybride", [11] = "Margrave", [12] = "Palatin",
    [13] = "Landgrave", [14] = "Burgrave", [15] = "L'Originel",
}
for g = 10, 15 do gradeJob("hybride_" .. g, HYBRIDE[g], "creatures", g, "Hybride (haute hiérarchie)") end

----------------------------------------------------------------------
-- CONSORTIUM (Banquier + Courtier/Intendant + Lames mercenaires)
----------------------------------------------------------------------
-- Non-combattants : stats fixes modestes.
add({ id = "consortium_banquier", name = "Banquier", faction = "consortium", grade = 13,
      color = COL.consortium, hp = 120, armor = 15, speed = 1.0, desc = "Chef local du Consortium." })
add({ id = "consortium_intendant", name = "Intendant", faction = "consortium", grade = 6,
      color = COL.consortium, hp = 110, armor = 10, speed = 1.0, desc = "Supérieur du courtier, gère le comptoir." })
add({ id = "consortium_courtier", name = "Courtier", faction = "consortium", grade = 4,
      color = COL.consortium, hp = 105, armor = 5, speed = 1.0, desc = "Négocie prêts, contrats et location des Lames." })

-- Lames (combattants mercenaires loués aux factions).
local LAMES = {
    [1] = "Lame Commune", [2] = "Lame Inhabituelle", [3] = "Lame Rare",
    [4] = "Lame d'Élite", [5] = "Lame Épique", [6] = "Lame Héroïque",
    [7] = "Lame Légendaire", [8] = "Lame Relique", [9] = "Lame Mythique",
}
for g = 1, 9 do gradeJob("lame_" .. g, LAMES[g], "consortium", g, "Mercenaire loué (Lame)") end

----------------------------------------------------------------------
-- Index par id
----------------------------------------------------------------------
SJOB.JobsById = {}
for _, j in ipairs(C.Jobs) do SJOB.JobsById[j.id] = j end

function SJOB.GetJob(id)
    return SJOB.JobsById[id] or SJOB.JobsById[C.DefaultJob] or C.Jobs[1]
end
function SJOB.JobExists(id) return SJOB.JobsById[id] ~= nil end
