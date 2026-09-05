--[[-------------------------------------------------------------------------
    Sang et Nuit — Backup (addon séparé)
    Chargeur. Sauvegarde périodique + backup SQL (dump JSON des tables Sang).
    Indépendant : n'a besoin d'aucun autre addon pour fonctionner (il découvre
    les tables « Sang » présentes dans sv.db). Fonctionne aussi en solo/écoute.
---------------------------------------------------------------------------]]

SBK = SBK or {}
SBK.Version = "1.0.0"

local MODULES = {
    { "sang_backup/sh_config.lua", "sh" },
    { "sang_backup/sv_backup.lua", "sv" },
}

local function run(path, realm)
    if SERVER and (realm == "sh" or realm == "cl") then AddCSLuaFile(path) end
    local exec = (realm == "sh") or (realm == "sv" and SERVER) or (realm == "cl" and CLIENT)
    if not exec then return end
    if not file.Exists(path, "LUA") then
        MsgN("[Sang Backup][ERREUR] Fichier manquant : " .. path)
        return
    end
    local fn = CompileFile(path)
    if isfunction(fn) then fn() else include(path) end
end

for _, m in ipairs(MODULES) do run(m[1], m[2]) end

MsgN("[Sang Backup] Chargé (" .. (SERVER and "serveur" or "client") .. ") v" .. SBK.Version)
