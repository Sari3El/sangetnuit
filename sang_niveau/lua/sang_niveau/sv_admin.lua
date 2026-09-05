--[[-------------------------------------------------------------------------
    Sang et Nuit — Niveaux : actions admin (serveur)
      Reçoit les nets envoyés par les sections origines. Whitelist
      re-vérifiée à chaque action (BLOOD.IsAdmin).
---------------------------------------------------------------------------]]

SLVL = SLVL or {}

local function isAdmin(ply) return BLOOD and BLOOD.IsAdmin and BLOOD.IsAdmin(ply) end

local function readTarget()
    local rawSid = net.ReadString()
    local slot = net.ReadUInt(8)
    local sid = BLOOD and BLOOD.NormalizeSteamID and BLOOD.NormalizeSteamID(rawSid) or nil
    if not sid or slot < 1 or slot > 4 then return nil end
    return sid, slot
end

local function log(ply, line)
    if BLOOD and BLOOD.LogAdmin then
        BLOOD.LogAdmin("[NIVEAU] " .. ply:Nick() .. " (" .. ply:SteamID64() .. ") " .. line)
    end
    MsgN("[Sang Niveau][ADMIN] " .. ply:Nick() .. " " .. line)
end

net.Receive("slvl_admin_setlevel", function(_, ply)
    if not isAdmin(ply) then return end
    local sid, slot = readTarget()
    local level = net.ReadUInt(16)
    if not sid then SLVL.Notify(ply, "Cible invalide.", "error") return end
    local v = SLVL.AdminSetLevel(sid, slot, level)
    log(ply, "a réglé le niveau de " .. sid .. " slot " .. slot .. " à " .. v)
    SLVL.Notify(ply, "Niveau de " .. sid .. " slot " .. slot .. " = " .. v .. ".", "info")
end)

net.Receive("slvl_admin_givepoints", function(_, ply)
    if not isAdmin(ply) then return end
    local sid, slot = readTarget()
    local n = net.ReadInt(32)
    if not sid then SLVL.Notify(ply, "Cible invalide.", "error") return end
    local bonus = SLVL.AdminGivePoints(sid, slot, n)
    log(ply, "a donné " .. n .. " point(s) bonus à " .. sid .. " slot " .. slot .. " (bonus total: " .. bonus .. ")")
    SLVL.Notify(ply, "Points bonus de " .. sid .. " slot " .. slot .. " = " .. bonus .. ".", "info")
end)

net.Receive("slvl_admin_givereset", function(_, ply)
    if not isAdmin(ply) then return end
    local sid, slot = readTarget()
    local n = net.ReadInt(32)
    if not sid then SLVL.Notify(ply, "Cible invalide.", "error") return end
    local tok = SLVL.AdminGiveReset(sid, slot, n)
    log(ply, "a donné " .. n .. " point(s) de reset à " .. sid .. " slot " .. slot .. " (total: " .. tok .. ")")
    SLVL.Notify(ply, "Points de reset de " .. sid .. " slot " .. slot .. " = " .. tok .. ".", "info")
end)

----------------------------------------------------------------------
-- Multiplicateur d'XP (serveur)
----------------------------------------------------------------------
local function sendXPMult(ply)
    net.Start("slvl_xpmult")
    net.WriteFloat(SLVL.XPMult or 0)
    net.Send(ply)
end

net.Receive("slvl_set_xpmult", function(_, ply)
    if not isAdmin(ply) then return end
    local v = net.ReadFloat()
    v = math.Clamp(v or 0, 0, 1000)
    SLVL.XPMult = v
    log(ply, "a réglé le multiplicateur d'XP à " .. v)
    local eff = (v > 0) and v or 1
    SLVL.Notify(ply, "Multiplicateur XP = " .. v .. "  (effectif ×" .. eff .. ").", "info")
    sendXPMult(ply)
end)

net.Receive("slvl_req_xpmult", function(_, ply)
    if not isAdmin(ply) then return end
    sendXPMult(ply)
end)
