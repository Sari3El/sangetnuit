--[[-------------------------------------------------------------------------
    Sang et Nuit — Niveaux : net strings
---------------------------------------------------------------------------]]

if SERVER then
    util.AddNetworkString("slvl_sync")       -- S->C : état (niveau, xp, points...)
    util.AddNetworkString("slvl_open_stats") -- S->C : ouvre la borne de compétences
    util.AddNetworkString("slvl_spend")      -- C->S : mettre 1 point dans une stat
    util.AddNetworkString("slvl_respec")     -- C->S : réinitialiser ses points (jeton)

    -- Admin (via origines) — re-vérifié serveur-side
    util.AddNetworkString("slvl_admin_setlevel")
    util.AddNetworkString("slvl_admin_givepoints")
    util.AddNetworkString("slvl_admin_givereset")
    util.AddNetworkString("slvl_set_xpmult")
    util.AddNetworkString("slvl_xpmult")     -- S->C : valeur courante du multiplicateur
    util.AddNetworkString("slvl_req_xpmult") -- C->S : demander la valeur courante
end
