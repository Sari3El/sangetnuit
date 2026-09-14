--[[-------------------------------------------------------------------------
    Sang et Nuit — Tickets : serveur
      - Création par le joueur (raison / cible / description)
      - Diffusion aux STAFF (ULX : admin + super admin + whitelist)
      - Prise / fermeture, actions staff (aller au joueur / amener / spectate)
      - Notation 5 étoiles par le joueur, logs + stats staff (SQL)
---------------------------------------------------------------------------]]

if not SERVER then return end

SANGTICKET = SANGTICKET or {}

util.AddNetworkString("sang_ticket_create")
util.AddNetworkString("sang_ticket_claim")
util.AddNetworkString("sang_ticket_close")
util.AddNetworkString("sang_ticket_action")
util.AddNetworkString("sang_ticket_rate")
util.AddNetworkString("sang_ticket_reqlogs")
util.AddNetworkString("sang_ticket_sync")       -- S->C (staff) : liste des tickets vivants
util.AddNetworkString("sang_ticket_rateprompt") -- S->C (joueur) : demande de note
util.AddNetworkString("sang_ticket_logs")       -- S->C (staff) : logs + stats

local CREATE_CD = 20 -- secondes entre deux créations (anti-spam)

----------------------------------------------------------------------
-- SQL
----------------------------------------------------------------------
sql.Query([[CREATE TABLE IF NOT EXISTS sang_tickets_log (
    id           INTEGER PRIMARY KEY,
    req_sid      TEXT,
    req_name     TEXT,
    reason       TEXT,
    target_sid   TEXT,
    descr        TEXT,
    claimer_sid  TEXT,
    claimer_name TEXT,
    created      INTEGER,
    closed       INTEGER,
    rating       INTEGER DEFAULT -1
);]])

local function E(s) return sql.SQLStr(tostring(s == nil and "" or s)) end

local NextId = 1
do
    local v = sql.QueryValue("SELECT MAX(id) FROM sang_tickets_log;")
    NextId = (tonumber(v) or 0) + 1
end

----------------------------------------------------------------------
-- Staff (ULX : IsAdmin() couvre admin + super admin + rangs héritant d'admin)
----------------------------------------------------------------------
function SANGTICKET.IsStaff(ply)
    if not IsValid(ply) then return false end
    if ply:IsAdmin() then return true end
    if BLOOD and BLOOD.IsAdmin and BLOOD.IsAdmin(ply) then return true end
    return false
end

----------------------------------------------------------------------
-- Tickets vivants (en mémoire)
----------------------------------------------------------------------
SANGTICKET.Open = SANGTICKET.Open or {} -- [id] = ticket

local function findByRequester(sid)
    for _, t in pairs(SANGTICKET.Open) do
        if t.reqSid == sid then return t end
    end
end

-- Diffuse la liste des tickets vivants à tout le staff.
function SANGTICKET.Sync()
    local list = {}
    for _, t in pairs(SANGTICKET.Open) do list[#list + 1] = t end

    for _, ply in ipairs(player.GetAll()) do
        if SANGTICKET.IsStaff(ply) then
            net.Start("sang_ticket_sync")
            net.WriteUInt(#list, 8)
            for _, t in ipairs(list) do
                net.WriteUInt(t.id, 16)
                net.WriteString(t.reqName)
                net.WriteString(t.reason)
                net.WriteString(t.desc)
                net.WriteString(t.targetName or "")
                net.WriteBool(t.status == "claimed")
                net.WriteString(t.claimerSid or "")
                net.WriteString(t.claimerName or "")
            end
            net.Send(ply)
        end
    end
end

----------------------------------------------------------------------
-- Création
----------------------------------------------------------------------
net.Receive("sang_ticket_create", function(_, ply)
    if not IsValid(ply) then return end
    if (ply.TkCreateCD or 0) > CurTime() then
        if BLOOD and BLOOD.Notify then BLOOD.Notify(ply, "Patiente avant de refaire un ticket.", "error") end
        return
    end
    if findByRequester(ply:SteamID64()) then
        if BLOOD and BLOOD.Notify then BLOOD.Notify(ply, "Tu as déjà un ticket en cours.", "error") end
        return
    end

    local reason = net.ReadString()
    local tgtSid = net.ReadString()
    local desc   = string.sub(net.ReadString() or "", 1, 500)

    -- Validation raison
    local ok = false
    for _, r in ipairs(SANGTICKET.Reasons) do if r.id == reason then ok = true break end end
    if not ok then return end

    local targetName, targetSid = nil, ""
    if SANGTICKET.ReasonNeedsTarget(reason) then
        local tgt = BLOOD and BLOOD.GetPlayerBySteamID64 and BLOOD.GetPlayerBySteamID64(tgtSid)
        if not IsValid(tgt) then
            if BLOOD and BLOOD.Notify then BLOOD.Notify(ply, "Cible invalide (joueur déconnecté ?).", "error") end
            return
        end
        targetName, targetSid = tgt:Nick(), tgt:SteamID64()
    end

    ply.TkCreateCD = CurTime() + CREATE_CD

    local t = {
        id = NextId, reqSid = ply:SteamID64(), reqName = ply:Nick(),
        reason = reason, targetSid = targetSid, targetName = targetName,
        desc = desc, status = "open", created = os.time(),
    }
    NextId = NextId + 1
    SANGTICKET.Open[t.id] = t

    SANGTICKET.Sync()
    if BLOOD and BLOOD.Notify then BLOOD.Notify(ply, "Ton ticket a été envoyé au staff.", "info") end
end)

----------------------------------------------------------------------
-- Prise
----------------------------------------------------------------------
net.Receive("sang_ticket_claim", function(_, ply)
    if not SANGTICKET.IsStaff(ply) then return end
    local id = net.ReadUInt(16)
    local t = SANGTICKET.Open[id]
    if not t or t.status == "claimed" then return end
    t.status = "claimed"
    t.claimerSid = ply:SteamID64()
    t.claimerName = ply:Nick()
    SANGTICKET.Sync()
    if BLOOD and BLOOD.Notify then BLOOD.Notify(ply, "Ticket #" .. id .. " pris.", "info") end
end)

----------------------------------------------------------------------
-- Fermeture (par le preneur) -> log + demande de note
----------------------------------------------------------------------
local function closeTicket(t, claimer)
    if not t then return end
    SANGTICKET.Open[t.id] = nil

    sql.Query(("INSERT OR REPLACE INTO sang_tickets_log "
        .. "(id, req_sid, req_name, reason, target_sid, descr, claimer_sid, claimer_name, created, closed, rating) "
        .. "VALUES (%d, %s, %s, %s, %s, %s, %s, %s, %d, %d, -1);")
        :format(t.id, E(t.reqSid), E(t.reqName), E(t.reason), E(t.targetSid), E(t.desc),
                E(t.claimerSid or ""), E(t.claimerName or ""), t.created or os.time(), os.time()))

    SANGTICKET.Sync()

    -- Demande de note au joueur (s'il est connecté)
    local req = BLOOD and BLOOD.GetPlayerBySteamID64 and BLOOD.GetPlayerBySteamID64(t.reqSid)
    if IsValid(req) then
        net.Start("sang_ticket_rateprompt")
        net.WriteUInt(t.id, 16)
        net.WriteString(t.claimerName or "Staff")
        net.Send(req)
    end
end

net.Receive("sang_ticket_close", function(_, ply)
    if not SANGTICKET.IsStaff(ply) then return end
    local id = net.ReadUInt(16)
    local t = SANGTICKET.Open[id]
    if not t then return end
    -- Seul le preneur peut fermer.
    if t.status ~= "claimed" or t.claimerSid ~= ply:SteamID64() then return end
    closeTicket(t, ply)
    if BLOOD and BLOOD.Notify then BLOOD.Notify(ply, "Ticket #" .. id .. " terminé.", "info") end
end)

----------------------------------------------------------------------
-- Actions staff : aller au joueur / amener / spectate
----------------------------------------------------------------------
local function stopSpectate(staff)
    if not IsValid(staff) then return end
    local r = staff.TkSpecReturn
    staff:UnSpectate()
    staff:SetMoveType(MOVETYPE_WALK)
    staff.TkSpectating = nil
    staff.TkSpecReturn = nil
    if r then
        timer.Simple(0, function()
            if IsValid(staff) then staff:SetPos(r.pos) staff:SetEyeAngles(r.ang) end
        end)
    end
end
SANGTICKET.StopSpectate = stopSpectate

net.Receive("sang_ticket_action", function(_, ply)
    if not SANGTICKET.IsStaff(ply) then return end
    local id     = net.ReadUInt(16)
    local action = net.ReadString()

    if action == "unspectate" then stopSpectate(ply) return end

    local t = SANGTICKET.Open[id]
    if not t or t.claimerSid ~= ply:SteamID64() then return end
    local req = BLOOD and BLOOD.GetPlayerBySteamID64 and BLOOD.GetPlayerBySteamID64(t.reqSid)
    if not IsValid(req) then
        if BLOOD and BLOOD.Notify then BLOOD.Notify(ply, "Le joueur n'est plus connecté.", "error") end
        return
    end

    if action == "goto" then
        if ply.TkSpectating then stopSpectate(ply) end
        ply:SetPos(req:GetPos() + req:GetForward() * 50 + Vector(0, 0, 8))
        if BLOOD and BLOOD.Notify then BLOOD.Notify(ply, "Téléporté au joueur.", "info") end
    elseif action == "bring" then
        req:SetPos(ply:GetPos() + ply:GetForward() * 60 + Vector(0, 0, 8))
        if BLOOD and BLOOD.Notify then BLOOD.Notify(ply, "Joueur amené.", "info") end
    elseif action == "spectate" then
        if ply.TkSpectating then stopSpectate(ply) end
        ply.TkSpecReturn = { pos = ply:GetPos(), ang = ply:EyeAngles() }
        ply:Spectate(OBS_MODE_CHASE)
        ply:SpectateEntity(req)
        ply:SetMoveType(MOVETYPE_NONE)
        ply.TkSpectating = req
        if BLOOD and BLOOD.Notify then BLOOD.Notify(ply, "Spectate — SAUT pour arrêter.", "info") end
    end
end)

-- Sortie du spectate au saut ; auto-stop si la cible s'en va.
hook.Add("KeyPress", "SangTicket_SpecExit", function(ply, key)
    if key == IN_JUMP and ply.TkSpectating then stopSpectate(ply) end
end)
hook.Add("Think", "SangTicket_SpecWatch", function()
    for _, ply in ipairs(player.GetAll()) do
        if ply.TkSpectating and not IsValid(ply.TkSpectating) then stopSpectate(ply) end
    end
end)

----------------------------------------------------------------------
-- Notation
----------------------------------------------------------------------
net.Receive("sang_ticket_rate", function(_, ply)
    if not IsValid(ply) then return end
    local id    = net.ReadUInt(16)
    local stars = math.Clamp(net.ReadUInt(3), 1, 5)
    -- Le noteur doit être le demandeur du ticket + pas déjà noté.
    local row = sql.QueryRow("SELECT req_sid, rating FROM sang_tickets_log WHERE id = " .. id .. ";")
    if not row or row.req_sid ~= ply:SteamID64() then return end
    if tonumber(row.rating) and tonumber(row.rating) >= 1 then return end
    sql.Query("UPDATE sang_tickets_log SET rating = " .. stars .. " WHERE id = " .. id .. ";")
    if BLOOD and BLOOD.Notify then BLOOD.Notify(ply, "Merci pour ta note !", "info") end
end)

----------------------------------------------------------------------
-- Logs + stats staff (pour le menu Origines)
----------------------------------------------------------------------
net.Receive("sang_ticket_reqlogs", function(_, ply)
    if not SANGTICKET.IsStaff(ply) then return end

    -- Stats par staff
    local stats = sql.Query([[SELECT claimer_sid, claimer_name, COUNT(*) AS total,
        AVG(CASE WHEN rating >= 1 THEN rating END) AS avgr,
        SUM(CASE WHEN rating >= 1 THEN 1 ELSE 0 END) AS rated
        FROM sang_tickets_log WHERE claimer_sid != '' GROUP BY claimer_sid ORDER BY total DESC;]]) or {}

    -- Derniers tickets
    local logs = sql.Query("SELECT id, req_name, reason, claimer_name, rating, closed "
        .. "FROM sang_tickets_log ORDER BY id DESC LIMIT 60;") or {}

    net.Start("sang_ticket_logs")
        net.WriteUInt(#stats, 16)
        for _, s in ipairs(stats) do
            net.WriteString(s.claimer_name or "?")
            net.WriteUInt(tonumber(s.total) or 0, 16)
            net.WriteUInt(tonumber(s.rated) or 0, 16)
            net.WriteFloat(tonumber(s.avgr) or 0)
        end
        net.WriteUInt(#logs, 16)
        for _, l in ipairs(logs) do
            net.WriteUInt(tonumber(l.id) or 0, 16)
            net.WriteString(l.req_name or "?")
            net.WriteString(SANGTICKET.ReasonName(l.reason))
            net.WriteString(l.claimer_name or "-")
            net.WriteInt(tonumber(l.rating) or -1, 8)
        end
    net.Send(ply)
end)

----------------------------------------------------------------------
-- Déconnexions
----------------------------------------------------------------------
hook.Add("PlayerDisconnected", "SangTicket_DC", function(ply)
    local sid = ply:SteamID64()
    -- Le demandeur part : son ticket ouvert est retiré.
    local mine = findByRequester(sid)
    if mine then SANGTICKET.Open[mine.id] = nil end
    -- Le preneur part : son ticket repart dans la file.
    for _, t in pairs(SANGTICKET.Open) do
        if t.status == "claimed" and t.claimerSid == sid then
            t.status = "open" t.claimerSid = nil t.claimerName = nil
        end
    end
    timer.Simple(0.1, function() SANGTICKET.Sync() end)
end)

-- Un staff qui (re)spawn reçoit l'état courant.
hook.Add("PlayerInitialSpawn", "SangTicket_StaffSync", function(ply)
    timer.Simple(2, function()
        if IsValid(ply) and SANGTICKET.IsStaff(ply) then SANGTICKET.Sync() end
    end)
end)
