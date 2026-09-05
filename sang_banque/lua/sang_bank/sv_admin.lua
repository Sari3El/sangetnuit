--[[-------------------------------------------------------------------------
    Sang et Nuit — Banque : actions admin (serveur)
      Réglage des taxes, gestion des banques de faction et des banques
      joueurs. Whitelist re-vérifiée à chaque action (BLOOD.IsAdmin).
---------------------------------------------------------------------------]]

SBANK = SBANK or {}
local C = SBANK.Config

local function isAdmin(ply)
    return BLOOD and BLOOD.IsAdmin and BLOOD.IsAdmin(ply)
end

local function log(ply, line)
    local msg = "[Sang Banque][ADMIN] " .. ply:Nick() .. " (" .. ply:SteamID64() .. ") " .. line
    MsgN(msg)
    if BLOOD and BLOOD.LogAdmin then BLOOD.LogAdmin("[BANQUE] " .. ply:Nick() .. " (" .. ply:SteamID64() .. ") " .. line) end
end

----------------------------------------------------------------------
-- Régler une taxe (personal / faction)
----------------------------------------------------------------------
net.Receive("sang_bank_settax", function(_, ply)
    if not isAdmin(ply) then return end
    local kind = net.ReadString()
    local value = net.ReadUInt(8)
    if kind ~= "personal" and kind ~= "faction" then return end

    local v = SBANK.SetTax(kind, value)
    log(ply, "a réglé la taxe " .. kind .. " à " .. v .. "%")
    SBANK.Notify(ply, "Taxe " .. kind .. " = " .. v .. "%.", "info")
    SBANK.Sync(ply)
end)

----------------------------------------------------------------------
-- Ajouter / retirer sur une banque de faction
----------------------------------------------------------------------
net.Receive("sang_bank_setfaction", function(_, ply)
    if not isAdmin(ply) then return end
    local fac = net.ReadString()
    local delta = net.ReadInt(32)
    if not C.FactionNames[fac] then return end

    local bal = SBANK.AddFaction(fac, delta)
    log(ply, "a modifié la banque " .. fac .. " de " .. delta .. " (solde: " .. bal .. ")")
    SBANK.Notify(ply, "Banque " .. C.FactionNames[fac] .. " = " .. bal .. ".", "info")
    SBANK.Sync(ply)
end)

----------------------------------------------------------------------
-- Ajouter / retirer sur la banque perso d'un joueur (par slot)
----------------------------------------------------------------------
net.Receive("sang_bank_setplayer", function(_, ply)
    if not isAdmin(ply) then return end
    local rawSid = net.ReadString()
    local slot = net.ReadUInt(8)
    local delta = net.ReadInt(32)

    local sid = BLOOD and BLOOD.NormalizeSteamID and BLOOD.NormalizeSteamID(rawSid) or nil
    if not sid then SBANK.Notify(ply, "SteamID invalide.", "error") return end
    if slot < 1 or slot > 4 then SBANK.Notify(ply, "Slot invalide.", "error") return end

    local bal = SBANK.AddPersonal(sid, slot, delta)
    log(ply, "a modifié la banque de " .. sid .. " slot " .. slot .. " de " .. delta .. " (solde: " .. bal .. ")")
    SBANK.Notify(ply, "Banque " .. sid .. " slot " .. slot .. " = " .. bal .. ".", "info")
    SBANK.Sync(ply)
end)
