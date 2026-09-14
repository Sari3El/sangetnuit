--[[-------------------------------------------------------------------------
    Sang et Nuit — Armoire à PM (addon séparé)
    Chargeur. Dépend de l'addon principal "sang_et_nuit" (thème BLOOD.UI) et,
    pour l'affichage du job/faction, de "sang_jobs". Les entités (lua/entities)
    se chargent automatiquement.
---------------------------------------------------------------------------]]

SARM = SARM or {}
SARM.Version = "1.0.0"

local MODULES = {
    { "sang_armoire/sh_config.lua",  "sh" },
    { "sang_armoire/sh_net.lua",     "sh" },
    { "sang_armoire/sv_sql.lua",     "sv" },
    { "sang_armoire/sv_armoire.lua", "sv" },
    { "sang_armoire/cl_armoire.lua", "cl" },
}

local function run(path, realm)
    if SERVER and (realm == "sh" or realm == "cl") then AddCSLuaFile(path) end
    local exec = (realm == "sh") or (realm == "sv" and SERVER) or (realm == "cl" and CLIENT)
    if not exec then return end
    if not file.Exists(path, "LUA") then
        MsgN("[Sang Armoire][ERREUR] Fichier manquant : " .. path)
        return
    end
    local fn = CompileFile(path)
    if isfunction(fn) then fn() else include(path) end
end

for _, m in ipairs(MODULES) do run(m[1], m[2]) end

MsgN("[Sang Armoire] Chargé (" .. (SERVER and "serveur" or "client") .. ") v" .. SARM.Version)
