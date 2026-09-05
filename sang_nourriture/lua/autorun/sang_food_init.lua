--[[-------------------------------------------------------------------------
    Sang et Nuit — Nourriture (addon séparé)
    Chargeur. Se branche sur la faim de l'addon principal via BLOOD.AddHunger
    (si présent). L'entité (lua/entities/sang_food) est chargée automatiquement
    par GMod ; ici on charge la config + la logique de repas.
---------------------------------------------------------------------------]]

SFOOD = SFOOD or {}
SFOOD.Version = "1.0.0"

local MODULES = {
    { "sang_food/sh_config.lua", "sh" },
    { "sang_food/sv_feed.lua",   "sv" },
    { "sang_food/cl_feed.lua",   "cl" },
}

local function run(path, realm)
    if SERVER and (realm == "sh" or realm == "cl") then AddCSLuaFile(path) end
    local exec = (realm == "sh") or (realm == "sv" and SERVER) or (realm == "cl" and CLIENT)
    if not exec then return end
    if not file.Exists(path, "LUA") then
        MsgN("[Sang Nourriture][ERREUR] Fichier manquant : " .. path)
        return
    end
    local fn = CompileFile(path)
    if isfunction(fn) then fn() else include(path) end
end

for _, m in ipairs(MODULES) do run(m[1], m[2]) end

MsgN("[Sang Nourriture] Chargé (" .. (SERVER and "serveur" or "client") .. ") v" .. SFOOD.Version)
