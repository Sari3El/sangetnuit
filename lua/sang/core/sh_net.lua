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
    util.AddNetworkString("blood_return_human")  -- retour Humain gratuit

    -- Admin (Client -> Serveur, tout re-vérifié serveur-side)
    util.AddNetworkString("origines_give_credits")
    util.AddNetworkString("origines_set_race")
    util.AddNetworkString("origines_rename_slot")
    util.AddNetworkString("origines_set_paid")
end
