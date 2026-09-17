--[[-------------------------------------------------------------------------
    Sang et Nuit — Missives : logique serveur
      - Ouverture du bureau (entité) -> badge non-lus
      - Envoi : Personnelle (un joueur connecté) / Faction (la tienne) /
        Inter-Faction (une autre faction)
      - Livraison temps réel (BLOOD.Notify) + persistance pour lecture différée
---------------------------------------------------------------------------]]

if not SERVER then return end

SMISSIVE = SMISSIVE or {}
local C = SMISSIVE.Config

local KIND_LABEL = { personal = "Personnelle", faction = "de Faction", interfaction = "Inter-Faction" }

local function notify(ply, msg, kind)
    if BLOOD and BLOOD.Notify then BLOOD.Notify(ply, msg, kind) else ply:ChatPrint("[Missive] " .. msg) end
end

local function charName(ply)
    local slot = ply.BloodActiveSlot or 1
    local s = ply.BloodSlots and ply.BloodSlots[slot]
    return (s and s.name) or ply:Nick()
end

local function myFaction(ply)
    return ply:GetNWString("sang_faction", "none")
end

-- Faction "cible" utilisable pour filtrer une boîte de réception : chaîne
-- vide si le personnage n'appartient à aucune vraie faction (évite de
-- matcher des missives target_faction = "none"/"event", qui ne devraient
-- jamais exister, mais reste défensif).
local function inboxFaction(ply)
    local fac = myFaction(ply)
    return SMISSIVE.IsRealFaction(fac) and fac or ""
end

----------------------------------------------------------------------
-- Nombre de missives non lues pour le personnage actif d'un joueur.
----------------------------------------------------------------------
function SMISSIVE.CountUnread(ply)
    if not IsValid(ply) or not BLOOD or not BLOOD.HasCharacter or not BLOOD.HasCharacter(ply) then return 0 end
    local sid, slot = ply:SteamID64(), ply.BloodActiveSlot or 1
    local rows = SMISSIVE.SQL.GetInbox(sid, slot, inboxFaction(ply), C.InboxLimit)
    local cursor = SMISSIVE.SQL.GetCursor(sid, slot)
    local n = 0
    for _, r in ipairs(rows) do
        if (tonumber(r.id) or 0) > cursor then n = n + 1 end
    end
    return n
end

----------------------------------------------------------------------
-- Ouverture du bureau des missives (appelée par l'entité).
----------------------------------------------------------------------
function SMISSIVE.OpenMenu(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not (BLOOD and BLOOD.HasCharacter and BLOOD.HasCharacter(ply)) then
        notify(ply, "Crée d'abord ton personnage.", "error")
        return
    end
    net.Start("sang_missive_open")
        net.WriteUInt(math.min(SMISSIVE.CountUnread(ply), 999), 16)
    net.Send(ply)
    SMISSIVE.PushBadge(ply) -- resynchronise aussi l'encart persistant
end

----------------------------------------------------------------------
-- Pousse au client le nombre de missives non lues (badge HUD persistant).
----------------------------------------------------------------------
function SMISSIVE.PushBadge(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    net.Start("sang_missive_badge")
        net.WriteUInt(math.min(SMISSIVE.CountUnread(ply), 999), 16)
    net.Send(ply)
end

-- Au spawn (connexion, respawn, changement/création de personnage — tous
-- passent par ply:Spawn()), une fois le job/faction du slot actif recalculé.
hook.Add("PlayerSpawn", "SMISSIVE_BadgeOnSpawn", function(ply)
    local delay = (BLOOD and BLOOD.Config and BLOOD.Config.ApplyDelay or 0.15) + 0.25
    timer.Simple(delay, function()
        if IsValid(ply) then SMISSIVE.PushBadge(ply) end
    end)
end)

-- Resynchro à la demande : le client la déclenche une fois son Lua
-- entièrement chargé (InitPostEntity), au cas où le push fait au spawn
-- serait arrivé AVANT que son "net.Receive" soit enregistré (dans ce cas,
-- GMod jette silencieusement le message réseau — pas de file d'attente).
SMISSIVE.NetReceive("sang_missive_badge_req", 1, function(_, ply)
    SMISSIVE.PushBadge(ply)
end)

----------------------------------------------------------------------
-- Envoi d'une missive
----------------------------------------------------------------------
SMISSIVE.NetReceive("sang_missive_send", 0, function(_, ply)
    local kind          = net.ReadString()
    local targetSid     = net.ReadString()
    local targetFaction = net.ReadString()
    local subject       = string.Trim(string.sub(net.ReadString() or "", 1, C.SubjectMax))
    local body          = string.Trim(string.sub(net.ReadString() or "", 1, C.BodyMax))

    if not (BLOOD and BLOOD.HasCharacter and BLOOD.HasCharacter(ply)) then return end
    if not (kind == "personal" or kind == "faction" or kind == "interfaction") then return end
    if subject == "" or body == "" then
        notify(ply, "Objet et texte de la missive requis.", "error")
        return
    end

    if (ply.SMissiveCD or 0) > CurTime() then
        notify(ply, "Patiente avant d'envoyer une nouvelle missive.", "error")
        return
    end

    local senderSlot = ply.BloodActiveSlot or 1
    local senderName = charName(ply)
    local senderFac  = myFaction(ply)

    local m = {
        kind = kind, senderSid = ply:SteamID64(), senderSlot = senderSlot,
        senderName = senderName, senderFaction = senderFac,
        subject = subject, body = body,
        targetSid = "", targetSlot = 0, targetFaction = "",
    }

    if kind == "personal" then
        if targetSid == ply:SteamID64() then
            notify(ply, "Tu ne peux pas t'écrire à toi-même.", "error")
            return
        end
        local target = BLOOD.GetPlayerBySteamID64(targetSid)
        if not IsValid(target) then
            notify(ply, "Destinataire introuvable (déconnecté ?).", "error")
            return
        end
        m.targetSid  = target:SteamID64()
        m.targetSlot = target.BloodActiveSlot or 1

    elseif kind == "faction" then
        if not SMISSIVE.IsRealFaction(senderFac) then
            notify(ply, "Tu n'appartiens à aucune faction.", "error")
            return
        end
        m.targetFaction = senderFac

    else -- interfaction
        if not SMISSIVE.IsRealFaction(senderFac) then
            notify(ply, "Tu n'appartiens à aucune faction.", "error")
            return
        end
        if not SMISSIVE.IsRealFaction(targetFaction) or targetFaction == senderFac then
            notify(ply, "Choisis une faction destinataire différente de la tienne.", "error")
            return
        end
        m.targetFaction = targetFaction
    end

    ply.SMissiveCD = CurTime() + C.SendCooldown

    SMISSIVE.SQL.Insert(m)

    -- Livraison temps réel
    if kind == "personal" then
        local target = BLOOD.GetPlayerBySteamID64(m.targetSid)
        if IsValid(target) then
            notify(target, "Nouvelle missive personnelle de " .. senderName .. " : « " .. subject .. " ».", "info")
            SMISSIVE.PushBadge(target)
        end
    else
        local facName = SMISSIVE.FactionName(m.targetFaction)
        for _, p in ipairs(player.GetAll()) do
            if p ~= ply and BLOOD.HasCharacter(p) and myFaction(p) == m.targetFaction then
                notify(p, "Nouvelle missive " .. KIND_LABEL[kind] .. " pour " .. facName .. " — « " .. subject .. " ».", "info")
                SMISSIVE.PushBadge(p)
            end
        end
    end

    notify(ply, "Ta missive a été envoyée.", "info")
end)

----------------------------------------------------------------------
-- Boîte de réception
----------------------------------------------------------------------
SMISSIVE.NetReceive("sang_missive_inbox_req", 0.5, function(_, ply)
    if not (BLOOD and BLOOD.HasCharacter and BLOOD.HasCharacter(ply)) then return end
    local sid, slot = ply:SteamID64(), ply.BloodActiveSlot or 1
    local cursor = SMISSIVE.SQL.GetCursor(sid, slot)
    local rows = SMISSIVE.SQL.GetInbox(sid, slot, inboxFaction(ply), C.InboxLimit)

    local maxId = cursor
    net.Start("sang_missive_inbox_data")
        net.WriteUInt(#rows, 16)
        for _, r in ipairs(rows) do
            local id = tonumber(r.id) or 0
            if id > maxId then maxId = id end
            net.WriteUInt(id, 32)
            net.WriteString(r.kind or "personal")
            net.WriteString(r.subject or "")
            net.WriteString(r.body or "")
            net.WriteString(r.sender_name or "?")
            net.WriteString(r.sender_faction or "")
            net.WriteString(r.target_faction or "")
            net.WriteUInt(tonumber(r.ts) or 0, 32)
            net.WriteBool(id > cursor)
        end
    net.Send(ply)

    if maxId > cursor then SMISSIVE.SQL.SetCursor(sid, slot, maxId) end
    SMISSIVE.PushBadge(ply)
end)

----------------------------------------------------------------------
-- Suppression d'une missive (de SA seule boîte — voir sv_sql.lua).
----------------------------------------------------------------------
SMISSIVE.NetReceive("sang_missive_dismiss", 0.2, function(_, ply)
    if not (BLOOD and BLOOD.HasCharacter and BLOOD.HasCharacter(ply)) then return end
    local id = net.ReadUInt(32)
    local sid, slot = ply:SteamID64(), ply.BloodActiveSlot or 1
    if not SMISSIVE.SQL.IsAddressedTo(id, sid, slot, inboxFaction(ply)) then return end
    SMISSIVE.SQL.Dismiss(sid, slot, id)
end)
