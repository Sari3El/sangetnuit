--[[-------------------------------------------------------------------------
    Sang et Nuit — Sorts (config, partagé)
      Sorts custom pour l'addon HPW_Rewrite (Harry Potter Wand). Catégorie
      « Sang et Nuit » dans la liste des sorts.
---------------------------------------------------------------------------]]

SANGSPELL = SANGSPELL or {}
SANGSPELL.Config = SANGSPELL.Config or {}
local C = SANGSPELL.Config

-- Catégories de magie (affichées dans « All Spells », même vides).
--   Nécrotique regroupe le Sang (hémomancie) ET les Ombres/Ténèbres.
--   Mental sera ajouté plus tard.
C.Categories = {
    "Magie Sacré",
    "Magie Nécrotique",
    "Magie Druidique",
    "Magie Élémentaire",
    "Magie Arcanique",
    "Magie Temporelle",
}

-- Masquer TOUS les sorts vanilla de HPW dans les menus (Tree + All Spells),
-- côté client uniquement. Les sorts restent enregistrés côté serveur (donc
-- réactivables plus tard : passe ceci à false). Les SKINS de baguette restent.
C.HideVanillaSpells = true

-- Sort « Renforcement Sacré » (Sacré) : buff vitesse + saut, aura dorée
C.SangVif = {
    ManaCost     = 25,          -- mana prise sur notre système (BLOOD)
    Cooldown     = 5,           -- secondes entre deux lancers (ForceDelay)
    Duration     = 15,          -- durée du buff (s)
    SpeedMul     = 1.5,         -- multiplicateur de vitesse pendant le buff
    JumpMul      = 1.5,         -- multiplicateur de saut pendant le buff
    Aura         = "[4]_golden_energy", -- nom du SYSTÈME de particule (aura)
    AuraPcf      = "particles/cruel_base2.pcf", -- fichier .pcf qui contient l'aura
    CastSound    = "items/suitchargeok1.wav",
    EndSound     = "items/suitchargeno1.wav",
}

-- Sort « Translocation » (Arcanique) : téléportation là où on regarde.
--   Un PORTAIL s'ouvre à l'entrée (ancienne position) ET à la sortie
--   (destination) au moment du lancer, puis se referme 2 s après.
--   Portal = nom (ou base) du système de particule. On accepte :
--     - le nom exact "[N]_strange_portal"
--     - la base "strange_portal" (le préfixe [N] est résolu automatiquement
--       en lisant les .pcf) — pratique si tu ne connais pas le numéro.
C.Translocation = {
    Mana       = 15,
    Cooldown   = 6,
    MaxDist    = 2500,            -- portée max de la téléportation
    Portal     = "strange_portal", -- s'ouvre à l'entrée + à la sortie
    CloseDelay = 2,              -- le portail se referme après X s
    Sound      = "ambient/machines/teleport4.wav",
}

-- Fichiers .pcf supplémentaires à enregistrer (au cas où certaines particules
-- ne seraient pas dans cruel_base*.pcf, auto-découverts). Ajoute ici le(s)
-- fichier(s) manquant(s) si une particule ne s'affiche pas.
C.ParticleFiles = {
    "particles/cruel_base.pcf",   -- strange_portal, flamestrike, ...
    "particles/cruel_base2.pcf",  -- golden_energy, ...
}

-- Sort « Sève Curative » (Druidique) : zone de SOIN au sol
C.Druidique = {
    Mana     = 35, Cooldown = 12,
    Radius   = 250, Amount = 3, Duration = 18, -- +3 PV/s pendant 18 s
    Particle = "[3]_healing_zone",
    Sound    = "items/smallmedkit1.wav",
}

-- Sort « Lac Maudit » (Nécrotique) : zone de DÉGÂTS au sol (inverse du soin)
C.Necrotique = {
    Mana     = 35, Cooldown = 12,
    Radius   = 250, Amount = 3, Duration = 18, -- 3 dégâts/s (respecte Force/Résistance)
    Particle = "[5]_cursed_lake",
    Sound    = "ambient/atmosphere/cave_hit1.wav",
}

-- Sort « Arrêt du Temps » (Temporelle) : projectile -> zone stop-time
C.Temporelle = {
    Mana        = 60, Cooldown = 25,
    Radius      = 250, StunDuration = 5,   -- fige tout dans le rayon pendant 5 s
    FlyParticle = "[2]_fire_aura_blue_bloom",
    ZoneParticle = "[2]_fireball_main_blue",
    Sound       = "ambient/levels/labs/electric_explosion1.wav",
}

-- Sort « Boule de Feu » (Élémentaire) : orbite -> lancée -> explosion
C.Elementaire = {
    Mana        = 45, Cooldown = 10,
    Radius      = 200, Damage = 40,        -- dégâts de zone (feu) + met le feu
    OrbitTime   = 1.5, MaxFly = 10,
    FlyParticle = "[2]_fireball2",
    BoomParticle = "[0]_barrel_blast",     -- explosion
    GroundParticle = "[2]_flamestrike",    -- flammes au sol (cruel_base.pcf)
    Sound       = "ambient/explosions/explode_4.wav",
}
