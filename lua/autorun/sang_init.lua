--[[-------------------------------------------------------------------------
    Sang et Nuit — Point d'entrée / chargeur
    Lu automatiquement par Garry's Mod (dossier lua/autorun).

    On charge chaque module via CompileFile (chemin relatif à lua/, résolution
    fiable) plutôt que include() dont la résolution de chemin depuis
    lua/autorun/ peut échouer selon les versions. Si un fichier manque
    vraiment sur le disque, un message d'erreur clair l'indique.

    Réalmes :
      "sh" = shared  -> serveur ET client
      "sv" = server  -> serveur uniquement
      "cl" = client  -> envoyé au client, exécuté côté client
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}
BLOOD.Version = "1.0.0"

-- Modules dans l'ordre de chargement (chemins relatifs à lua/). La config
-- DOIT être chargée en premier.
local MODULES = {
    { "sang/config/sh_config.lua", "sh" },
    { "sang/core/sh_util.lua",     "sh" },
    { "sang/core/sh_races.lua",    "sh" },
    { "sang/core/sh_net.lua",      "sh" },

    { "sang/server/sv_sql.lua",     "sv" },
    { "sang/server/sv_race.lua",    "sv" },
    { "sang/server/sv_stats.lua",   "sv" },
    { "sang/server/sv_players.lua", "sv" },
    { "sang/server/sv_reroll.lua",  "sv" },
    { "sang/server/sv_admin.lua",   "sv" },

    { "sang/client/cl_net.lua",   "cl" },
    { "sang/client/cl_menu.lua",  "cl" },
    { "sang/client/cl_admin.lua", "cl" },
    { "sang/client/cl_hud.lua",   "cl" },
}

local loaded, missing = 0, 0

local function run(path, realm)
    -- 1) Envoi des fichiers shared/client au client
    if SERVER and (realm == "sh" or realm == "cl") then
        AddCSLuaFile(path)
    end

    -- 2) Doit-on exécuter ce fichier dans le realm courant ?
    local exec = (realm == "sh")
              or (realm == "sv" and SERVER)
              or (realm == "cl" and CLIENT)
    if not exec then return end

    -- 3) Fichier bien présent dans le chemin LUA ?
    if not file.Exists(path, "LUA") then
        missing = missing + 1
        MsgN("[Sang et Nuit][ERREUR] Fichier manquant : " .. path)
        return
    end

    -- 4) Compilation (relative à lua/) puis exécution ; repli sur include().
    local fn = CompileFile(path)
    if isfunction(fn) then
        fn()
    else
        include(path)
    end
    loaded = loaded + 1
end

for _, m in ipairs(MODULES) do
    run(m[1], m[2])
end

MsgN(("[Sang et Nuit] Chargé (%s) v%s — %d module(s) chargé(s), %d manquant(s)")
    :format(SERVER and "serveur" or "client", BLOOD.Version, loaded, missing))

if missing > 0 then
    MsgN("[Sang et Nuit][ERREUR] Le dossier n'a pas été copié en entier.")
    MsgN("[Sang et Nuit]  Attendu : addons/sang_et_nuit/lua/sang/{config,core,server,client}/")
end

if not (BLOOD.Config and BLOOD.Config.Races) then
    MsgN("[Sang et Nuit][ERREUR] BLOOD.Config absente — sh_config.lua n'a pas été chargé.")
end
