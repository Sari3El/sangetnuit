--[[-------------------------------------------------------------------------
    Sang et Nuit — Jobs : net strings
---------------------------------------------------------------------------]]

if SERVER then
    util.AddNetworkString("sjob_set")             -- C->S : choisir un job (F4)
    -- Admin (Config Perso)
    util.AddNetworkString("sjob_admin_setjob")    -- C->S : forcer le job d'un slot
    util.AddNetworkString("sjob_admin_setoverride") -- C->S : override PV/armure/vitesse
    util.AddNetworkString("sjob_admin_clearoverride")
    util.AddNetworkString("sjob_query")           -- C->S : demander défaut + override
    util.AddNetworkString("sjob_query_result")    -- S->C : défaut + override
end
