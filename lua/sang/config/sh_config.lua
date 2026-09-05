--[[-------------------------------------------------------------------------
    Sang et Nuit — CONFIGURATION (partagé serveur/client)

    C'est LE fichier à éditer pour équilibrer / configurer le système.
    Tout est ici : réglages généraux, whitelist admin, table des races
    (rareté + multiplicateurs + effets), catégories d'armes.

    Rappels des règles non négociables (cf. cahier des charges) :
      - Vitesse de base de TOUS les joueurs = ×0.9 (déjà incluse dans chaque
        valeur "speed" ci-dessous, Humain compris).
      - Un modificateur de race ne s'écarte jamais de plus de 0.2 de la
        baseline, seule exception : la vitesse de l'Homme-aigle (+0.25 => 1.15).
      - Le SAUT n'est JAMAIS modifié (voir EnforceDefaultJump plus bas).
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}
BLOOD.Config = BLOOD.Config or {}

local C = BLOOD.Config

----------------------------------------------------------------------
-- Réglages généraux
----------------------------------------------------------------------

C.BaseHealth    = 100   -- PV de référence (Humain ×1.0 => 100)
C.BaseWalkSpeed = 200   -- vitesse "marche" moteur (avant multiplicateur de race)
C.BaseRunSpeed  = 400   -- vitesse "course" moteur (avant multiplicateur de race)
-- NB : la valeur "speed" de chaque race est le multiplicateur FINAL appliqué à
-- ces vitesses. L'Humain vaut 0.9 (le ×0.9 global est déjà intégré).

-- Slots de personnage
C.MaxSlots  = 4   -- 4 slots maximum
C.FreeSlots = 3   -- slots 1..3 gratuits ; slot 4 = payant (voir déblocage)

-- Reroll
C.RerollCost     = 1     -- 1 crédit = 1 reroll (coût fixe)
C.RerollCooldown = 1.5   -- anti-spam serveur (secondes) sur les boutons reroll/humain

-- Régénération (races à regen)
C.RegenInterval = 3     -- toutes les X secondes, on applique la regen

-- Saut : RÈGLE = ne jamais modifier le saut.
-- Laisser false pour ne PAS toucher au saut (SetJumpPower jamais appelé).
-- (Optionnel) mettre true pour forcer explicitement tout le monde au défaut.
C.EnforceDefaultJump = false
C.DefaultJumpPower   = 200

-- Délai (s) avant application des stats au spawn : laisse le gamemode (DarkRP,
-- Sandbox...) finir son propre code de spawn avant qu'on écrase PV/vitesse.
C.ApplyDelay = 0.15

-- Bits de dégâts "magiques" (placeholder pour le futur module Sorcier).
-- Le module de sorts devra infliger ses dégâts avec ces types pour que la
-- "résistance magique" du Gnome fonctionne. À ajuster quand le module existe.
C.MagicDamageBits = bit.bor(DMG_SHOCK, DMG_ENERGYBEAM)

----------------------------------------------------------------------
-- Économie & survie
----------------------------------------------------------------------

-- Monnaie de jeu (« l'argent sur soi »), PAR PERSONNAGE, distincte des
-- crédits de reroll et de l'or DarkRP. Stockée en SQL dans le slot.
C.Currency = "Covan"            -- nom affiché de la monnaie
C.StartingCovan = 0             -- Covan de départ d'un nouveau personnage

-- Faim (barre verticale du HUD). Valeur 0..HungerMax, décroît avec le temps.
C.HungerEnabled        = true
C.HungerMax            = 100
C.HungerDecayInterval  = 20     -- secondes entre chaque -1 point de faim
C.HungerStarveDamage   = 0      -- dégâts quand faim = 0 (0 = désactivé)
C.HungerStarveInterval = 5      -- secondes entre chaque tick de dégâts de faim

----------------------------------------------------------------------
-- Administration (!origines)
----------------------------------------------------------------------

-- Whitelist par SteamID64. La VRAIE barrière est ici, vérifiée serveur-side
-- à chaque action. Exemple :
--   C.Admins = { ["76561198000000000"] = true, ["76561198111111111"] = true }
C.Admins = {
    ["76561198300281314"] = true, -- Sariel (Sari3l)
    -- ["76561198XXXXXXXXX"] = true,
}

-- Confort pour tester en SOLO : autorise aussi les superadmins (l'hôte d'un
-- serveur écoute local EST superadmin). En PRODUCTION, mettre false et
-- remplir C.Admins ci-dessus.
C.AllowSuperAdmin = true

----------------------------------------------------------------------
-- Catégories d'armes (pour les bonus/malus de dégâts par race)
--   Tags disponibles :
--     "lightblade"  -> lame légère (dague, épée courte)  [bonus Elfe]
--     "bow"         -> arc / arbalète                    [bonus Elfe, malus Ogre via "ranged"]
--     "heavymelee"  -> mêlée lourde                       [bonus Demi-orc]
--     "melee"       -> mêlée en général                   [bonus Homme-loup]
--     "ranged"      -> arme à distance                    [malus Ogre]
--   Une arme peut avoir plusieurs tags. Complète cette table avec TES armes RP.
----------------------------------------------------------------------

C.WeaponTags = {
    ["weapon_crowbar"]   = { "melee", "heavymelee" },
    ["weapon_stunstick"] = { "melee" },
    ["weapon_physcannon"] = { "melee" },
    ["weapon_pistol"]    = { "ranged" },
    ["weapon_357"]       = { "ranged" },
    ["weapon_smg1"]      = { "ranged" },
    ["weapon_ar2"]       = { "ranged" },
    ["weapon_shotgun"]   = { "ranged" },
    ["weapon_crossbow"]  = { "ranged", "bow" },
    ["weapon_rpg"]       = { "ranged" },
    ["weapon_frag"]      = { "ranged" },
    ["weapon_slam"]      = { "ranged" },
    -- Exemples à adapter à ton contenu RP :
    -- ["tfa_dague"]     = { "melee", "lightblade" },
    -- ["tfa_epeecourte"]= { "melee", "lightblade" },
    -- ["tfa_hache"]     = { "melee", "heavymelee" },
    -- ["tfa_arc"]       = { "ranged", "bow" },
}

----------------------------------------------------------------------
-- TABLE DES RACES (ordre = ordre de tirage sur 10000)
--
--   id           : identifiant interne (stocké en SQL, NE PAS changer après coup)
--   name         : nom affiché
--   rarity       : palier de rareté (affichage)
--   min / max    : plage sur 10000 (math.random(1,10000))
--   hp           : multiplicateur PV      (baseline 1.0)
--   speed        : multiplicateur vitesse (baseline Humain 0.9)
--   dmgReduction : réduction de dégâts subis (0.15 = 15%)
--   dmgBonus     : { { tags = {...}, mult = X } }  bonus/malus de dégâts infligés
--   dodge        : chance d'esquive totale (0.15 = 15%)
--   regen        : PV rendus toutes les C.RegenInterval secondes
--   fireResist   : résistance au feu (0.5 = -50% dégâts de feu subis)
--   magicResist  : résistance "magique" (placeholder module Sorcier)
--   stealth      : true => bruits de pas supprimés
--   weapons      : SWEP(s) donnés au spawn (retirés au changement de race)
--
--   ⚠ Les SWEP dragon/aigle/sorcier ne sont PAS fournis dans cette version
--     (hors périmètre). Les classes restent déclarées pour que le cadre
--     "donner/retirer au spawn" soit prêt : elles sont ignorées tant que la
--     SWEP n'est pas installée (aucune erreur).
----------------------------------------------------------------------

C.Races = {
    {
        id = "human", name = "Humain normal", rarity = "Commun",
        min = 1, max = 3290,
        hp = 1.0, speed = 0.9, dmgReduction = 0.0,
        desc = "Baseline, aucun effet.",
    },
    {
        id = "nain", name = "Nain", rarity = "Fréquent",
        min = 3291, max = 4190,
        hp = 1.15, speed = 0.75, dmgReduction = 0.15,
        desc = "Le tank lent.",
    },
    {
        id = "elfe", name = "Elfe", rarity = "Fréquent",
        min = 4191, max = 4990,
        hp = 0.9, speed = 1.0, dmgReduction = 0.0,
        dmgBonus = { { tags = { "lightblade", "bow" }, mult = 1.20 } },
        desc = "+20% dégâts arc / lame légère.",
    },
    {
        id = "ogre", name = "Ogre", rarity = "Fréquent",
        min = 4991, max = 5690,
        hp = 1.2, speed = 0.7, dmgReduction = 0.20,
        dmgBonus = { { tags = { "ranged" }, mult = 0.80 } },
        desc = "Bruiser extrême, -20% dégâts à distance.",
    },
    {
        id = "demiorc", name = "Demi-orc", rarity = "Fréquent",
        min = 5691, max = 6340,
        hp = 1.1, speed = 0.85, dmgReduction = 0.0,
        dmgBonus = { { tags = { "heavymelee" }, mult = 1.20 } },
        desc = "+20% dégâts mêlée lourde.",
    },
    {
        id = "gobelin", name = "Gobelin", rarity = "Fréquent",
        min = 6341, max = 6940,
        hp = 0.85, speed = 1.05, dmgReduction = 0.0,
        dodge = 0.15,
        desc = "Esquive 15% (négation d'un coup).",
    },
    {
        id = "hommelezard", name = "Homme-lézard", rarity = "Peu commun",
        min = 6941, max = 7490,
        hp = 1.1, speed = 0.9, dmgReduction = 0.10,
        regen = 2,
        desc = "Régénération passive légère.",
    },
    {
        id = "hommerat", name = "Homme-rat", rarity = "Peu commun",
        min = 7491, max = 7990,
        hp = 0.85, speed = 1.0, dmgReduction = 0.0,
        stealth = true,
        desc = "Discrétion (bruits de pas réduits).",
    },
    {
        id = "hommeloup", name = "Homme-loup", rarity = "Peu commun",
        min = 7991, max = 8440,
        hp = 0.95, speed = 1.0, dmgReduction = 0.0,
        dmgBonus = { { tags = { "melee" }, mult = 1.15 } },
        desc = "+15% dégâts mêlée.",
    },
    {
        id = "hommechat", name = "Homme-chat", rarity = "Peu commun",
        min = 8441, max = 8840,
        hp = 0.8, speed = 1.1, dmgReduction = 0.0,
        dodge = 0.20,
        desc = "Esquive 20%.",
    },
    {
        id = "gnome", name = "Gnome", rarity = "Peu commun",
        min = 8841, max = 9240,
        hp = 0.85, speed = 0.9, dmgReduction = 0.0,
        magicResist = 0.5,
        desc = "Résistance magique.",
    },
    {
        id = "hautelignee", name = "Humain haute lignée", rarity = "Rare-ish",
        min = 9241, max = 9540,
        hp = 1.15, speed = 0.9, dmgReduction = 0.0,
        regen = 2,
        desc = "Régénération passive légère (« premium » safe).",
    },
    {
        id = "hommeaigle", name = "Homme-aigle", rarity = "Rare-ish",
        min = 9541, max = 9840,
        hp = 0.8, speed = 1.15, dmgReduction = 0.0,
        weapons = { "sang_swep_vol" }, -- SWEP « Vol » (hors périmètre — à créer)
        desc = "Le plus rapide + SWEP « Vol » (à venir).",
    },
    {
        id = "sangdragon", name = "Sang-dragon", rarity = "Rare",
        min = 9841, max = 9990,
        hp = 1.1, speed = 0.9, dmgReduction = 0.0,
        fireResist = 0.5,
        weapons = { "sang_swep_crachatfeu" }, -- SWEP « Crachat de feu » (hors périmètre)
        desc = "Résistance au feu + SWEP « Crachat de feu » (à venir).",
    },
    {
        id = "sorcier", name = "Sorcier", rarity = "Très rare",
        min = 9991, max = 10000,
        hp = 0.8, speed = 0.9, dmgReduction = 0.0,
        weapons = {}, -- module Sorcier (mana + sorts) hors périmètre
        desc = "Glass cannon : sorts + mana (module à venir).",
    },
}
