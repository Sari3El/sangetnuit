--[[-------------------------------------------------------------------------
    Sang et Nuit — Armurerie (addon séparé)
    Chargeur. Dépend de l'addon principal "sang_et_nuit" (slots de personnage
    + thème BLOOD.UI). Les entités (lua/entities) se chargent automatiquement.
---------------------------------------------------------------------------]]

SARM = SARM or {}
SARM.Version = "1.0.0"

local MODULES = {
    { "sang_armory/sh_config.lua", "sh" },
    { "sang_armory/sh_net.lua",    "sh" },
    { "sang_armory/sv_sql.lua",    "sv" },
    { "sang_armory/sv_armory.lua", "sv" },
    { "sang_armory/cl_armory.lua", "cl" },
}

local function run(path, realm)
    if SERVER and (realm == "sh" or realm == "cl") then AddCSLuaFile(path) end
    local exec = (realm == "sh") or (realm == "sv" and SERVER) or (realm == "cl" and CLIENT)
    if not exec then return end
    if not file.Exists(path, "LUA") then
        MsgN("[Sang Armurerie][ERREUR] Fichier manquant : " .. path)
        return
    end
    local fn = CompileFile(path)
    if isfunction(fn) then fn() else include(path) end
end

for _, m in ipairs(MODULES) do run(m[1], m[2]) end

MsgN("[Sang Armurerie] Chargé (" .. (SERVER and "serveur" or "client") .. ") v" .. SARM.Version)
