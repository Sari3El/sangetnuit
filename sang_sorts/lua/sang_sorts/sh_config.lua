--[[-------------------------------------------------------------------------
    Sang et Nuit — Sorts (config, partagé)
      Sorts custom pour l'addon HPW_Rewrite (Harry Potter Wand). Catégorie
      « Sang et Nuit » dans la liste des sorts.
---------------------------------------------------------------------------]]

SANGSPELL = SANGSPELL or {}
SANGSPELL.Config = SANGSPELL.Config or {}
local C = SANGSPELL.Config

C.Category = "Sang et Nuit"     -- catégorie affichée dans « All Spells »

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
