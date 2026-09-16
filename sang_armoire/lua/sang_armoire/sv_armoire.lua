--[[-------------------------------------------------------------------------
    Sang et Nuit — Armoire à PM (playermodel) : logique serveur
      Tout est re-vérifié ici : la liste des playermodels autorisés vient de
      la config (par job/faction), la portée est revérifiée à chaque action,
      et les bodygroups/skin sont bornés à ce que le modèle accepte
      réellement (GetBodygroupCount / SkinCount).
---------------------------------------------------------------------------]]

SARM = SARM or {}
local C = SARM.Config

local function notify(ply, msg, kind)
    if BLOOD and BLOOD.Notify then BLOOD.Notify(ply, msg, kind) else ply:ChatPrint("[Armoire] " .. msg) end
end

-- Le playermodel appartient AU PERSONNAGE (comme la race), pas juste au
-- joueur : on suit le slot actif du coeur (sang_et_nuit), comme sang_jobs.
local function activeSlot(ply)
    return ply.BloodActiveSlot or 1
end

--- Ouvre l'armoire pour `activator` (appelé depuis ENT:Use).
function SARM.OpenArmoire(activator, ent)
    if not IsValid(activator) or not activator:IsPlayer() or not IsValid(ent) then return end
    activator.SangArmoire = ent
    if C.OpenSound and C.OpenSound ~= "" then
        ent:EmitSound(C.OpenSound, 60, 100)
    end
    net.Start("sang_armoire_open")
    net.Send(activator)
end

--- Le joueur est-il toujours à portée de l'armoire qu'il a ouverte ?
local function nearArmoire(ply)
    local ent = ply.SangArmoire
    if not IsValid(ent) or ent:GetClass() ~= "sang_armoire" then return false end
    return ply:GetPos():Distance(ent:GetPos()) <= (C.OpenDist + 40)
end

----------------------------------------------------------------------
-- Équiper un playermodel de la liste autorisée pour le job/faction.
----------------------------------------------------------------------
SARM.NetReceive("sang_armoire_setmodel", 0.5, function(_, ply)
    local model = net.ReadString()
    if not nearArmoire(ply) or not ply:Alive() then return end

    local allowed = SARM.GetAvailableModels(ply)
    local ok = false
    for _, m in ipairs(allowed) do
        if m.model == model then ok = true break end
    end
    if not ok or not util.IsValidModel(model) or not util.IsValidProp(model) then
        notify(ply, "Ce playermodel n'est pas disponible.", "error")
        return
    end

    ply:SetModel(model)
    ply:SetSkin(0)

    local sid, slot = ply:SteamID64(), activeSlot(ply)
    SARM.SQL.SetModel(sid, slot, model, 0)
    SARM.SQL.ClearBodygroups(sid, slot) -- les anciens indices n'ont plus de sens sur ce modèle

    notify(ply, "Apparence changée.", "info")
end)

----------------------------------------------------------------------
-- Modifier un bodygroup du playermodel actuellement porté.
----------------------------------------------------------------------
SARM.NetReceive("sang_armoire_bodygroup", 0.1, function(_, ply)
    local bgid  = net.ReadUInt(8)
    local value = net.ReadUInt(8)
    if not nearArmoire(ply) then return end
    if bgid >= ply:GetNumBodyGroups() then return end
    if value >= ply:GetBodygroupCount(bgid) then return end

    ply:SetBodygroup(bgid, value)
    SARM.SQL.SetBodygroup(ply:SteamID64(), activeSlot(ply), bgid, value)
end)

----------------------------------------------------------------------
-- Modifier le skin du playermodel actuellement porté.
----------------------------------------------------------------------
SARM.NetReceive("sang_armoire_skin", 0.1, function(_, ply)
    local skin = net.ReadUInt(8)
    if not nearArmoire(ply) then return end
    if skin >= ply:SkinCount() then return end

    ply:SetSkin(skin)
    SARM.SQL.SetSkin(ply:SteamID64(), activeSlot(ply), skin)
end)

----------------------------------------------------------------------
-- Réapplique le playermodel / skin / bodygroups sauvegardés au spawn.
-- Délai calé juste après celui du coeur (BLOOD.Config.ApplyDelay), pour
-- laisser le gamemode ET le coeur finir leur propre code de spawn avant
-- qu'on écrase le modèle.
----------------------------------------------------------------------
hook.Add("PlayerSpawn", "SARM_ReapplyPlayermodel", function(ply)
    local delay = ((BLOOD and BLOOD.Config and BLOOD.Config.ApplyDelay) or 0.15) + 0.1
    timer.Simple(delay, function()
        if not (IsValid(ply) and ply:Alive()) then return end

        local sid, slot = ply:SteamID64(), activeSlot(ply)
        local model, skin = SARM.SQL.GetModel(sid, slot)
        if not model or model == "" then return end -- rien de choisi : on laisse le modèle par défaut
        if not util.IsValidModel(model) or not util.IsValidProp(model) then return end

        ply:SetModel(model)
        ply:SetSkin(skin or 0)

        local saved = SARM.SQL.GetBodygroups(sid, slot)
        for bgid, value in pairs(saved) do
            if bgid < ply:GetNumBodyGroups() and value < ply:GetBodygroupCount(bgid) then
                ply:SetBodygroup(bgid, value)
            end
        end
    end)
end)
