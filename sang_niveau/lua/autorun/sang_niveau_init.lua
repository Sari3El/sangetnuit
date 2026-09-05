--[[-------------------------------------------------------------------------
    Sang et Nuit — Niveaux & Compétences (addon séparé)
    Chargeur. Dépend de sang_et_nuit (Covan, thème BLOOD.UI, hook
    BLOOD_PostApplyStats, BLOOD.OpenCharacterMenu). Entités auto-chargées.
---------------------------------------------------------------------------]]

SLVL = SLVL or {}
SLVL.Version = "1.0.0"

local MODULES = {
    { "sang_niveau/sh_config.lua", "sh" },
    { "sang_niveau/sh_net.lua",    "sh" },
    { "sang_niveau/sv_sql.lua",    "sv" },
    { "sang_niveau/sv_level.lua",  "sv" },
    { "sang_niveau/sv_admin.lua",  "sv" },
    { "sang_niveau/cl_hud.lua",    "cl" },
    { "sang_niveau/cl_stats.lua",  "cl" },
    { "sang_niveau/cl_origines.lua", "cl" },
}

local function run(path, realm)
    if SERVER and (realm == "sh" or realm == "cl") then AddCSLuaFile(path) end
    local exec = (realm == "sh") or (realm == "sv" and SERVER) or (realm == "cl" and CLIENT)
    if not exec then return end
    if not file.Exists(path, "LUA") then
        MsgN("[Sang Niveau][ERREUR] Fichier manquant : " .. path)
        return
    end
    local fn = CompileFile(path)
    if isfunction(fn) then fn() else include(path) end
end

for _, m in ipairs(MODULES) do run(m[1], m[2]) end

MsgN("[Sang Niveau] Chargé (" .. (SERVER and "serveur" or "client") .. ") v" .. SLVL.Version)
