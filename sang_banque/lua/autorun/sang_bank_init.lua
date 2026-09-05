--[[-------------------------------------------------------------------------
    Sang et Nuit — Banque (addon séparé)
    Chargeur. Dépend de l'addon principal "sang_et_nuit" (Covan + thème
    BLOOD.UI). Les entités (lua/entities) se chargent automatiquement.
---------------------------------------------------------------------------]]

SBANK = SBANK or {}
SBANK.Version = "1.0.0"

local MODULES = {
    { "sang_bank/sh_config.lua", "sh" },
    { "sang_bank/sh_net.lua",    "sh" },
    { "sang_bank/sv_sql.lua",    "sv" },
    { "sang_bank/sv_bank.lua",   "sv" },
    { "sang_bank/sv_gold.lua",   "sv" },
    { "sang_bank/sv_admin.lua",  "sv" },
    { "sang_bank/cl_bank.lua",   "cl" },
    { "sang_bank/cl_admin.lua",  "cl" },
}

local function run(path, realm)
    if SERVER and (realm == "sh" or realm == "cl") then AddCSLuaFile(path) end
    local exec = (realm == "sh") or (realm == "sv" and SERVER) or (realm == "cl" and CLIENT)
    if not exec then return end
    if not file.Exists(path, "LUA") then
        MsgN("[Sang Banque][ERREUR] Fichier manquant : " .. path)
        return
    end
    local fn = CompileFile(path)
    if isfunction(fn) then fn() else include(path) end
end

for _, m in ipairs(MODULES) do run(m[1], m[2]) end

MsgN("[Sang Banque] Chargé (" .. (SERVER and "serveur" or "client") .. ") v" .. SBANK.Version)
