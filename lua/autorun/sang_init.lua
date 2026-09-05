--[[-------------------------------------------------------------------------
    Sang et Nuit — Point d'entrée / chargeur
    Ce fichier est lu automatiquement par Garry's Mod (dossier lua/autorun).
    Il définit la table globale BLOOD et charge tous les modules dans l'ordre.

    Réalmes :
      "sh" = shared  -> serveur ET client   (AddCSLua + include côté serveur ; include côté client)
      "sv" = server  -> serveur uniquement
      "cl" = client  -> envoyé au client, exécuté côté client
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}
BLOOD.Version = "1.0.0"

local function load(path, realm)
    if realm == "sv" then
        if SERVER then include(path) end
    elseif realm == "cl" then
        if SERVER then AddCSLua(path) else include(path) end
    else -- "sh" (shared)
        if SERVER then AddCSLua(path) end
        include(path)
    end
end

-- 1) Partagé (config + helpers + réseau) — l'ordre compte, la config d'abord.
load("sang/config/sh_config.lua", "sh")
load("sang/core/sh_util.lua",     "sh")
load("sang/core/sh_races.lua",    "sh")
load("sang/core/sh_net.lua",      "sh")

-- 2) Serveur (logique, SQL, tirage, stats, admin)
load("sang/server/sv_sql.lua",     "sv")
load("sang/server/sv_race.lua",    "sv")
load("sang/server/sv_stats.lua",   "sv")
load("sang/server/sv_players.lua", "sv")
load("sang/server/sv_reroll.lua",  "sv")
load("sang/server/sv_admin.lua",   "sv")

-- 3) Client (interfaces Derma + réception réseau)
load("sang/client/cl_net.lua",   "cl")
load("sang/client/cl_menu.lua",  "cl")
load("sang/client/cl_admin.lua", "cl")

MsgN("[Sang et Nuit] Chargé (" .. (SERVER and "serveur" or "client") .. ") v" .. BLOOD.Version)
