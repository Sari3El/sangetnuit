--[[-------------------------------------------------------------------------
    Sang et Nuit — Nourriture : configuration (partagé)
---------------------------------------------------------------------------]]

SFOOD = SFOOD or {}
SFOOD.Config = SFOOD.Config or {}

local C = SFOOD.Config

C.Model    = "models/Gibs/HGIBS.mdl" -- modèle de la nourriture
C.FeedTime = 5      -- secondes de maintien de E pour un repas
C.FeedDist = 110    -- portée max du regard (unités)
C.Hunger   = 40     -- faim rendue par repas (via BLOOD.AddHunger)
C.Heal     = 15     -- PV rendus par repas
C.MaxUses  = 3      -- nombre de repas avant disparition

C.EatSound = "npc/barnacle/barnacle_gulp2.wav"  -- son de repas
C.BiteSound = "physics/flesh/flesh_impact_bullet2.wav" -- son de morsure/consommation
