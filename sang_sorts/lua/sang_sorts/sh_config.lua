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

----------------------------------------------------------------------
-- NOUVEAUX SORTS (particules GMod temporaires — seront remplacées).
--   Couleurs d'école : Arcanique = VIOLET, Temporelle = BLEU.
----------------------------------------------------------------------
C.ColArcane = Color(150, 60, 220)   -- violet
C.ColTemps  = Color(80, 160, 255)   -- bleu

-- A1 Trait Arcanique : projectile en ligne droite, dégâts magiques.
C.ArcTrait     = { Mana = 15, Cooldown = 3, Speed = 2800, Damage = 20 }
-- A2 Répulsion : onde de choc autour de soi (repousse + petits dégâts).
C.ArcRepulsion = { Mana = 25, Cooldown = 8, Radius = 260, Damage = 15, Force = 680 }
-- A3 Bouclier Arcanique : figé + invulnérable pendant la durée du sort.
C.ArcBouclier  = { Mana = 30, Cooldown = 14, Duration = 5 }
-- A6 Chaînes Arcaniques : à l'impact, repousse les alentours puis root la cible.
C.ArcChaines   = { Mana = 30, Cooldown = 12, Speed = 2400, RootDur = 3,
                   PushRadius = 190, PushForce = 620 }
-- A8 Bond Arcanique : dash court instantané dans la direction visée.
C.ArcBond      = { Mana = 12, Cooldown = 5, Dist = 460 }

-- T1 Célérité : auto-buff vitesse/saut + cooldowns réduits.
C.TmpCelerite  = { Mana = 25, Cooldown = 15, Duration = 10, SpeedMul = 1.4,
                   JumpMul = 1.3, HasteCD = 0.6 }
-- T2 Lenteur : projectile qui ralentit fortement la cible touchée.
C.TmpLenteur   = { Mana = 25, Cooldown = 8, Speed = 2700, SlowFactor = 0.45, SlowDur = 5 }
-- T3 Rembobinage : encre temporelle (pose puis retour ; voir sp_tmp_rembobinage).
C.TmpRembob    = { Mana = 40, PlaceCooldown = 60, InkLife = 30, MinReturn = 15 }
-- T4 Écho Temporel : dash rapide + bref instant d'invulnérabilité.
C.TmpEcho      = { Mana = 20, Cooldown = 6, DashForce = 700, Invuln = 0.6 }
-- T5 Bulle de Lenteur : zone qui ralentit tout ce qui est dedans.
C.TmpBulle     = { Mana = 45, Cooldown = 16, Radius = 260, SlowFactor = 0.4, Duration = 6 }
-- T7 Stase sur soi : figé + invulnérable (clutch), court.
C.TmpStase     = { Mana = 30, Cooldown = 20, Duration = 3 }
-- T8 Bouclier temporel : bulle posée sur place, tu peux bouger, protège dedans.
C.TmpBouclier  = { Mana = 40, Cooldown = 18, Radius = 230, Duration = 8 }
-- T9 Corrosion : gros projectile -> explose en zone de dégâts magiques/s.
C.TmpCorrosion = { Mana = 30, Cooldown = 10, Speed = 2000, Radius = 190,
                   DamagePerSec = 4, Duration = 6 }

----------------------------------------------------------------------
-- SORTS NÉCROTIQUES (Sang + Ombres). Couleur d'école : ROUGE SANG SOMBRE.
----------------------------------------------------------------------
C.ColNecro = Color(150, 20, 30)     -- rouge sang sombre

-- N1 Drain de Vie : projectile -> LIEN rouge (draine + soigne), se coupe si trop loin.
C.NecDrain     = { Mana = 20, Cooldown = 6, Speed = 2600, Duration = 6, MaxLink = 700,
                   Dps = 8, HealRatio = 0.5 }
-- N2 Explosion de Sang : sacrifie des PV -> grosse explosion de zone.
C.NecBlood     = { Mana = 15, Cooldown = 10, HpCost = 15, Radius = 260, Damage = 45 }
-- N4 Bouclier d'Hémoglobine : sacrifie des PV -> bouclier d'absorption (modéré).
C.NecShield    = { Mana = 20, Cooldown = 12, HpCost = 15, Shield = 45, Duration = 8 }
-- N6 Nuée d'Ombres : projectile -> aveugle la cible (écran assombri) + petit DoT.
C.NecShadowBolt= { Mana = 25, Cooldown = 9, Speed = 2500, Damage = 12, BlindDur = 3,
                   DotDps = 3, DotDur = 4 }
-- N7 Manteau d'Ombre : semi-invisible + saut plus haut + traînée d'ombre.
C.NecCloak     = { Mana = 30, Cooldown = 16, Duration = 6, Alpha = 55, JumpMul = 1.4 }
-- N8 Vol Spectral : vol (fumée noire, style Apparition HPW), durée limitée.
C.NecFly       = { Mana = 35, Cooldown = 16, Duration = 7, Speed = 2400, SprintSpeed = 4200,
                   Smoke = "hpw_apparation_black" }
-- N13 Serviteur : sur un cadavre frais -> invoque un serviteur qui n'attaque pas le lanceur.
C.NecServant   = { Mana = 45, Cooldown = 25, NPC = "drg_roach_ds1_h", CorpseAge = 30,
                   CorpseDist = 160, Life = 25 }

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
