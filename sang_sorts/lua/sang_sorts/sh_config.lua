--[[-------------------------------------------------------------------------
    Sang et Nuit — Sorts (config, partagé)
      Sorts custom pour l'addon HPW_Rewrite (Harry Potter Wand). Catégorie
      « Sang et Nuit » dans la liste des sorts.
---------------------------------------------------------------------------]]

SANGSPELL = SANGSPELL or {}
SANGSPELL.Config = SANGSPELL.Config or {}
local C = SANGSPELL.Config

-- Catégories de magie (affichées dans « All Spells », même vides).
--   Le « Sang » (hémomancie) va dans Nécrotique ; Ombre = Ténèbres.
--   Mental sera ajouté plus tard.
C.Categories = {
    "Magie Sacré",
    "Magie Nécrotique",
    "Magie Druidique",
    "Magie Élémentaire",
    "Magie des Ombres",
    "Magie Arcanique",
    "Magie Temporelle",
}

-- Masquer TOUS les sorts vanilla de HPW dans les menus (Tree + All Spells),
-- côté client uniquement. Les sorts restent enregistrés côté serveur (donc
-- réactivables plus tard : passe ceci à false). Les SKINS de baguette restent.
C.HideVanillaSpells = true

-- Sort « Sang Vif » (buff vitesse + saut, aura dorée)
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
