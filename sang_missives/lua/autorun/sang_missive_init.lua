--[[-------------------------------------------------------------------------
    Sang et Nuit — Missives (addon séparé)
    Chargeur. Dépend de l'addon principal "sang_et_nuit" (thème BLOOD.UI,
    slots de personnage) et de "sang_jobs" (liste des factions). Les entités
    (lua/entities) se chargent automatiquement.
---------------------------------------------------------------------------]]

SMISSIVE = SMISSIVE or {}
SMISSIVE.Version = "1.0.0"

local MODULES = {
    { "sang_missive/sh_config.lua",  "sh" },
    { "sang_missive/sh_net.lua",     "sh" },
    { "sang_missive/sv_sql.lua",     "sv" },
    { "sang_missive/sv_missive.lua", "sv" },
    { "sang_missive/cl_missive.lua", "cl" },
}

local function run(path, realm)
    if SERVER and (realm == "sh" or realm == "cl") then AddCSLuaFile(path) end
    local exec = (realm == "sh") or (realm == "sv" and SERVER) or (realm == "cl" and CLIENT)
    if not exec then return end
    if not file.Exists(path, "LUA") then
        MsgN("[Sang Missives][ERREUR] Fichier manquant : " .. path)
        return
    end
    local fn = CompileFile(path)
    if isfunction(fn) then fn() else include(path) end
end

for _, m in ipairs(MODULES) do run(m[1], m[2]) end

MsgN("[Sang Missives] Chargé (" .. (SERVER and "serveur" or "client") .. ") v" .. SMISSIVE.Version)
