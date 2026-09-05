--[[-------------------------------------------------------------------------
    Sang et Nuit — Niveaux : configuration (partagé)
---------------------------------------------------------------------------]]

SLVL = SLVL or {}
SLVL.Config = SLVL.Config or {}
local C = SLVL.Config

-- Modèles des entités
C.StatsModel = "models/props_wasteland/controlroom_storagecloset001a.mdl" -- borne de compétences
C.PersoModel = "models/props_wasteland/gaspump001a.mdl"                    -- borne perso (ex-!perso)

-- Portées d'interaction (E)
C.StatsDist = 140
C.PersoDist = 140

-- Niveaux
C.MaxLevel = 250
C.XPBase   = 60      -- XP(L->L+1) = floor(XPBase * L^XPExp)
C.XPExp    = 1.35

-- XP passif (avec le multiplicateur serveur)
C.XPPerTick    = 5   -- XP gagnés par tick
C.TickInterval = 10  -- secondes entre deux ticks

-- Stats : chaque point donne un % (rendements décroissants)
--   1..25   : +1.00 % / point
--   26..75  : +0.50 % / point
--   76..100 : +0.25 % / point   (max 100 points = +56.25 %)
C.MaxPointsPerStat = 100

-- Définition des 4 stats (ordre d'affichage)
C.Stats = {
    { id = "force",  name = "Force",     desc = "Dégâts infligés" },
    { id = "resist", name = "Résistance", desc = "Dégâts subis réduits" },
    { id = "agilite", name = "Agilité",  desc = "Vitesse de déplacement" },
    { id = "vitalite", name = "Vitalité", desc = "Points de vie max" },
}

-- Sons
C.LevelUpSound = "ambient/levels/labs/electric_explosion1.wav"
C.SpendSound   = "buttons/button14.wav"

-- Convertit un nombre de points en pourcentage (0..56.25).
function SLVL.PointsToPct(pts)
    pts = math.Clamp(math.floor(tonumber(pts) or 0), 0, 100)
    local a = math.min(pts, 25)                -- 1..25
    local b = math.Clamp(pts - 25, 0, 50)      -- 26..75
    local d = math.Clamp(pts - 75, 0, 25)      -- 76..100
    return a * 1.0 + b * 0.5 + d * 0.25
end

-- XP nécessaire pour passer du niveau L au niveau L+1 (0 si niveau max).
function SLVL.XPForLevel(L)
    L = math.floor(L)
    if L >= C.MaxLevel then return 0 end
    return math.floor(C.XPBase * (L ^ C.XPExp))
end
