--[[-------------------------------------------------------------------------
    Sang et Nuit — Déclaration des net strings
    (les chaînes réseau doivent être enregistrées côté serveur)
---------------------------------------------------------------------------]]

if SERVER then
    -- Serveur -> Client
    util.AddNetworkString("blood_sync")        -- pousse l'état du joueur (crédits, slots...)
    util.AddNetworkString("blood_open_menu")   -- ouvre le menu personnages
    util.AddNetworkString("blood_open_admin")  -- ouvre le menu admin (+ liste des races)
    util.AddNetworkString("blood_notify")      -- message/notification

    -- Client -> Serveur
    util.AddNetworkString("blood_request_sync")  -- le client demande une resynchro
    util.AddNetworkString("blood_select_slot")   -- jouer un slot
    util.AddNetworkString("blood_create_slot")   -- créer un slot
    util.AddNetworkString("blood_reroll")        -- reroll payant
    util.AddNetworkString("blood_reroll_roll")     -- S->C (joueur) : lance la roulette
    util.AddNetworkString("blood_reroll_announce") -- S->C (tous) : annonce colorée

    -- Admin (Client -> Serveur, tout re-vérifié serveur-side)
    util.AddNetworkString("origines_give_credits")
    util.AddNetworkString("origines_set_race")
    util.AddNetworkString("origines_rename_slot")
    util.AddNetworkString("origines_set_paid")
    util.AddNetworkString("origines_set_covan")
    util.AddNetworkString("origines_query_slot")  -- C->S : infos d'un slot
    util.AddNetworkString("origines_slot_info")   -- S->C : nom/race/covan d'un slot

    -- Admin : édition de la rareté des sangs (Gestion serveur)
    util.AddNetworkString("origines_req_rarity")   -- C->S : demander la table de rareté
    util.AddNetworkString("origines_rarity_data")  -- S->C : poids + palier de chaque sang
    util.AddNetworkString("origines_set_rarity")   -- C->S : régler poids + palier d'un sang

    -- Admin : stats forcées par (joueur, slot)
    util.AddNetworkString("origines_set_statoverride")   -- C->S : régler PV/Armure/Vitesse forcés
    util.AddNetworkString("origines_clear_statoverride") -- C->S : effacer (auto)
    util.AddNetworkString("origines_query_statoverride") -- C->S : demander les valeurs actuelles
    util.AddNetworkString("origines_statoverride_info")  -- S->C : valeurs actuelles
end
