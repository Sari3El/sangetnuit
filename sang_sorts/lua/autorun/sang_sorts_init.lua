--[[-------------------------------------------------------------------------
    Sang et Nuit — Sorts (addon séparé)
    Ajoute des sorts custom à HPW_Rewrite (baguette Harry Potter), dans la
    catégorie « Sang et Nuit ». Dépend de HPW_Rewrite (baguette) et, pour la
    mana, de "sang_et_nuit" (BLOOD.TakeMana).
---------------------------------------------------------------------------]]

SANGSPELL = SANGSPELL or {}
SANGSPELL.Version = "1.0.0"

local MODULES = {
    { "sang_sorts/sh_config.lua",      "sh" },
    { "sang_sorts/sh_base.lua",        "sh" }, -- base commune (mana/cooldown/dégâts)
    -- Sorts (un fichier par sort) :
    { "sang_sorts/sp_renforcement.lua", "sh" }, -- Magie Sacré
    { "sang_sorts/sp_arcanique.lua",    "sh" }, -- Magie Arcanique (téléportation)
    { "sang_sorts/cl_hide.lua",         "cl" }, -- masque les sorts vanilla (client)
}

local function run(path, realm)
    if SERVER and (realm == "sh" or realm == "cl") then AddCSLuaFile(path) end
    local exec = (realm == "sh") or (realm == "sv" and SERVER) or (realm == "cl" and CLIENT)
    if not exec then return end
    if not file.Exists(path, "LUA") then
        MsgN("[Sang Sorts][ERREUR] Fichier manquant : " .. path)
        return
    end
    local fn = CompileFile(path)
    if isfunction(fn) then fn() else include(path) end
end

for _, m in ipairs(MODULES) do run(m[1], m[2]) end

MsgN("[Sang Sorts] Chargé (" .. (SERVER and "serveur" or "client") .. ") v" .. SANGSPELL.Version)
