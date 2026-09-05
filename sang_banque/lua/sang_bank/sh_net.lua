--[[-------------------------------------------------------------------------
    Sang et Nuit — Banque : net strings
---------------------------------------------------------------------------]]

if SERVER then
    util.AddNetworkString("sang_bank_open")     -- S->C : ouvre/rafraîchit le menu (données)
    util.AddNetworkString("sang_bank_reqsync")  -- C->S : demande une resynchro
    util.AddNetworkString("sang_bank_deposit")  -- C->S : déposer
    util.AddNetworkString("sang_bank_withdraw") -- C->S : retirer

    -- Admin (re-vérifié serveur-side)
    util.AddNetworkString("sang_bank_settax")    -- C->S : régler une taxe
    util.AddNetworkString("sang_bank_setfaction") -- C->S : ajouter/retirer sur une banque de faction
    util.AddNetworkString("sang_bank_setplayer")  -- C->S : ajouter/retirer sur la banque d'un joueur
end
