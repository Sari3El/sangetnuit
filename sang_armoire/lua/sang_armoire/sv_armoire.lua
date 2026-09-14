--[[-------------------------------------------------------------------------
    Sang et Nuit — Armoire à PM : logique serveur
      Tout est re-vérifié ici : la liste des PM autorisés vient de la
      config (par job/faction), la portée est revérifiée à chaque action,
      et les bodygroups sont bornés à ce que le modèle de l'arme accepte
      réellement (GetBodygroupCount).
---------------------------------------------------------------------------]]

SARM = SARM or {}
local C = SARM.Config

local function notify(ply, msg, kind)
    if BLOOD and BLOOD.Notify then BLOOD.Notify(ply, msg, kind) else ply:ChatPrint("[Armoire] " .. msg) end
end

--- Applique au PM `wep` de `ply` les bodygroups sauvegardés pour cette classe.
local function reapplySaved(ply, wep)
    if not IsValid(wep) or not wep.GetNumBodyGroups then return end
    local saved = SARM.SQL.Get(ply:SteamID64(), wep:GetClass())
    for bgid, value in pairs(saved) do
        if bgid < wep:GetNumBodyGroups() and value < wep:GetBodygroupCount(bgid) then
            wep:SetBodygroup(bgid, value)
        end
    end
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

--- Retire tous les PM actuellement portés par le joueur (whitelist SARM.IsPM).
local function stripPMs(ply)
    for _, w in ipairs(ply:GetWeapons()) do
        if IsValid(w) and SARM.IsPM(w:GetClass()) then
            ply:StripWeapon(w:GetClass())
        end
    end
end

----------------------------------------------------------------------
-- Équiper un PM de la liste autorisée pour le job/faction du joueur.
----------------------------------------------------------------------
SARM.NetReceive("sang_armoire_equip", 0.5, function(_, ply)
    local class = net.ReadString()
    if not nearArmoire(ply) or not ply:Alive() then return end

    local allowed = SARM.GetAvailableWeapons(ply)
    local ok = false
    for _, w in ipairs(allowed) do
        if w.class == class then ok = true break end
    end
    if not ok then
        notify(ply, "Ce PM n'est pas disponible pour ton job.", "error")
        return
    end

    if IsValid(ply:GetWeapon(class)) then
        ply:SelectWeapon(class)
        return
    end

    stripPMs(ply)
    ply:Give(class)
    ply:SelectWeapon(class)
    reapplySaved(ply, ply:GetWeapon(class))

    notify(ply, "PM équipé.", "info")
end)

----------------------------------------------------------------------
-- Modifier un bodygroup du PM actuellement porté.
----------------------------------------------------------------------
SARM.NetReceive("sang_armoire_bodygroup", 0.1, function(_, ply)
    local bgid  = net.ReadUInt(8)
    local value = net.ReadUInt(8)
    if not nearArmoire(ply) then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or not SARM.IsPM(wep:GetClass()) or not wep.GetNumBodyGroups then return end
    if bgid >= wep:GetNumBodyGroups() then return end
    if value >= wep:GetBodygroupCount(bgid) then return end

    wep:SetBodygroup(bgid, value)
    SARM.SQL.Set(ply:SteamID64(), wep:GetClass(), bgid, value)
end)

----------------------------------------------------------------------
-- Réapplique les bodygroups enregistrés quand un PM est (ré)équipé
-- par un autre biais (respawn, ramassage au sol...).
----------------------------------------------------------------------
hook.Add("WeaponEquip", "SARM_ReapplyBodygroups", function(wep, ply)
    if not IsValid(wep) or not IsValid(ply) or not ply:IsPlayer() then return end
    if not SARM.IsPM(wep:GetClass()) then return end
    reapplySaved(ply, wep)
end)
