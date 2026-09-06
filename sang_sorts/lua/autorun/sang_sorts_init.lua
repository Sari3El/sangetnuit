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
    { "sang_sorts/sp_druidique.lua",    "sh" }, -- Magie Druidique (soin de zone)
    { "sang_sorts/sp_necrotique.lua",   "sh" }, -- Magie Nécrotique (dégâts de zone)
    { "sang_sorts/sp_temporelle.lua",   "sh" }, -- Magie Temporelle (stop-time)
    { "sang_sorts/sp_elementaire.lua",  "sh" }, -- Magie Élémentaire (boule de feu)
    -- Nouveaux sorts Arcaniques (violet) :
    { "sang_sorts/sp_arc_trait.lua",     "sh" }, -- A1 Trait Arcanique
    { "sang_sorts/sp_arc_repulsion.lua", "sh" }, -- A2 Répulsion
    { "sang_sorts/sp_arc_bouclier.lua",  "sh" }, -- A3 Bouclier Arcanique
    { "sang_sorts/sp_arc_chaines.lua",   "sh" }, -- A6 Chaînes Arcaniques
    { "sang_sorts/sp_arc_bond.lua",      "sh" }, -- A8 Bond Arcanique
    -- Nouveaux sorts Temporels (bleu) :
    { "sang_sorts/sp_tmp_celerite.lua",  "sh" }, -- T1 Célérité
    { "sang_sorts/sp_tmp_lenteur.lua",   "sh" }, -- T2 Lenteur
    { "sang_sorts/sp_tmp_rembobinage.lua","sh" },-- T3 Rembobinage
    { "sang_sorts/sp_tmp_echo.lua",      "sh" }, -- T4 Écho Temporel
    { "sang_sorts/sp_tmp_bulle.lua",     "sh" }, -- T5 Bulle de Lenteur
    { "sang_sorts/sp_tmp_stase.lua",     "sh" }, -- T7 Stase Temporelle
    { "sang_sorts/sp_tmp_bouclier.lua",  "sh" }, -- T8 Bouclier Temporel
    { "sang_sorts/sp_tmp_corrosion.lua", "sh" }, -- T9 Corrosion Temporelle
    -- Nouveaux sorts Nécrotiques (rouge sang) :
    { "sang_sorts/sp_nec_drain.lua",      "sh" }, -- N1 Drain de Vie (lien)
    { "sang_sorts/sp_nec_blood.lua",      "sh" }, -- N2 Explosion de Sang
    { "sang_sorts/sp_nec_shield.lua",     "sh" }, -- N4 Bouclier d'Hémoglobine
    { "sang_sorts/sp_nec_shadowbolt.lua", "sh" }, -- N6 Nuée d'Ombres (aveugle)
    { "sang_sorts/sp_nec_cloak.lua",      "sh" }, -- N7 Manteau d'Ombre
    { "sang_sorts/sp_nec_fly.lua",        "sh" }, -- N8 Vol Spectral
    { "sang_sorts/sp_nec_servant.lua",    "sh" }, -- N13 Serviteur
    { "sang_sorts/cl_fx.lua",           "cl" }, -- effets d'écran (aveuglement)
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
