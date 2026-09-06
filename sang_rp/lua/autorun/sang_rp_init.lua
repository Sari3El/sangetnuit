--[[-------------------------------------------------------------------------
    Sang et Nuit — Chat RP (addon séparé)
    Chargeur. Indépendant (aucune dépendance obligatoire). Ajoute un chat IC
    local + /me, /it, /roll et un OOC global.
---------------------------------------------------------------------------]]

SRP = SRP or {}
SRP.Version = "1.0.0"

local MODULES = {
    { "sang_rp/sh_config.lua", "sh" },
    { "sang_rp/sh_net.lua",    "sh" },
    { "sang_rp/sv_chat.lua",   "sv" },
    { "sang_rp/cl_chat.lua",   "cl" },
}

local function run(path, realm)
    if SERVER and (realm == "sh" or realm == "cl") then AddCSLuaFile(path) end
    local exec = (realm == "sh") or (realm == "sv" and SERVER) or (realm == "cl" and CLIENT)
    if not exec then return end
    if not file.Exists(path, "LUA") then
        MsgN("[Sang RP][ERREUR] Fichier manquant : " .. path)
        return
    end
    local fn = CompileFile(path)
    if isfunction(fn) then fn() else include(path) end
end

for _, m in ipairs(MODULES) do run(m[1], m[2]) end

MsgN("[Sang RP] Chargé (" .. (SERVER and "serveur" or "client") .. ") v" .. SRP.Version)
