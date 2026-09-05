--[[-------------------------------------------------------------------------
    Sang et Nuit — Jobs / F4 / Scoreboard (addon séparé)
    Dépend de sang_et_nuit (thème, hook BLOOD_ComputeStats, origines) et,
    pour le niveau au scoreboard, de sang_niveau (facultatif).
---------------------------------------------------------------------------]]

SJOB = SJOB or {}
SJOB.Version = "1.0.0"

local MODULES = {
    { "sang_jobs/sh_config.lua",  "sh" },
    { "sang_jobs/sh_net.lua",     "sh" },
    { "sang_jobs/sv_sql.lua",     "sv" },
    { "sang_jobs/sv_jobs.lua",    "sv" },
    { "sang_jobs/cl_f4.lua",      "cl" },
    { "sang_jobs/cl_board.lua",   "cl" },
    { "sang_jobs/cl_origines.lua","cl" },
}

local function run(path, realm)
    if SERVER and (realm == "sh" or realm == "cl") then AddCSLuaFile(path) end
    local exec = (realm == "sh") or (realm == "sv" and SERVER) or (realm == "cl" and CLIENT)
    if not exec then return end
    if not file.Exists(path, "LUA") then
        MsgN("[Sang Jobs][ERREUR] Fichier manquant : " .. path)
        return
    end
    local fn = CompileFile(path)
    if isfunction(fn) then fn() else include(path) end
end

for _, m in ipairs(MODULES) do run(m[1], m[2]) end

MsgN("[Sang Jobs] Chargé (" .. (SERVER and "serveur" or "client") .. ") v" .. SJOB.Version)
