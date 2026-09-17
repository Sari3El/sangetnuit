--[[-------------------------------------------------------------------------
    Sang et Nuit — Missives : persistance SQL (SQLite)
      sang_missive           : toutes les missives envoyées
      sang_missive_cursor    : dernier id lu, PAR PERSONNAGE (steamid64 + slot)
      sang_missive_dismissed : missives supprimées PAR PERSONNAGE (une missive
        de faction reste visible aux autres membres tant qu'ils ne l'ont pas
        supprimée eux-mêmes — la ligne n'est jamais effacée de sang_missive).
---------------------------------------------------------------------------]]

SMISSIVE = SMISSIVE or {}
SMISSIVE.SQL = SMISSIVE.SQL or {}

local function E(v) return sql.SQLStr(tostring(v == nil and "" or v)) end
local function N(v) return math.floor(tonumber(v) or 0) end

function SMISSIVE.SQL.Init()
    sql.Query([[CREATE TABLE IF NOT EXISTS sang_missive (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        ts             INTEGER NOT NULL DEFAULT 0,
        kind           TEXT    NOT NULL,
        sender_sid     TEXT    NOT NULL,
        sender_slot    INTEGER NOT NULL DEFAULT 0,
        sender_name    TEXT    NOT NULL DEFAULT '',
        sender_faction TEXT    NOT NULL DEFAULT '',
        target_sid     TEXT    NOT NULL DEFAULT '',
        target_slot    INTEGER NOT NULL DEFAULT 0,
        target_faction TEXT    NOT NULL DEFAULT '',
        subject        TEXT    NOT NULL DEFAULT '',
        body           TEXT    NOT NULL DEFAULT ''
    );]])

    sql.Query([[CREATE TABLE IF NOT EXISTS sang_missive_cursor (
        steamid64 TEXT    NOT NULL,
        slot      INTEGER NOT NULL,
        last_id   INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (steamid64, slot)
    );]])

    sql.Query([[CREATE TABLE IF NOT EXISTS sang_missive_dismissed (
        steamid64  TEXT    NOT NULL,
        slot       INTEGER NOT NULL,
        missive_id INTEGER NOT NULL,
        PRIMARY KEY (steamid64, slot, missive_id)
    );]])
end

----------------------------------------------------------------------
-- Écriture
----------------------------------------------------------------------
function SMISSIVE.SQL.Insert(m)
    sql.Query("INSERT INTO sang_missive "
        .. "(ts, kind, sender_sid, sender_slot, sender_name, sender_faction, target_sid, target_slot, target_faction, subject, body) VALUES ("
        .. N(m.ts or os.time()) .. ", "
        .. E(m.kind) .. ", "
        .. E(m.senderSid) .. ", " .. N(m.senderSlot) .. ", " .. E(m.senderName) .. ", " .. E(m.senderFaction) .. ", "
        .. E(m.targetSid) .. ", " .. N(m.targetSlot) .. ", " .. E(m.targetFaction) .. ", "
        .. E(m.subject) .. ", " .. E(m.body) .. ");")
    return tonumber(sql.QueryValue("SELECT last_insert_rowid();")) or 0
end

----------------------------------------------------------------------
-- Lecture : boîte de réception d'un PERSONNAGE (steamid64 + slot + faction
-- actuelle de ce personnage), missives supprimées par ce personnage exclues.
-- Les plus récentes en premier.
----------------------------------------------------------------------
function SMISSIVE.SQL.GetInbox(sid64, slot, faction, limit)
    limit = math.Clamp(N(limit or 50), 1, 200)
    local mine = "(target_sid = " .. E(sid64) .. " AND target_slot = " .. N(slot) .. ")"
    if faction and faction ~= "" then
        mine = mine .. " OR (target_faction = " .. E(faction) .. ")"
    end
    local notDismissed = "id NOT IN (SELECT missive_id FROM sang_missive_dismissed WHERE steamid64 = "
        .. E(sid64) .. " AND slot = " .. N(slot) .. ")"
    local rows = sql.Query("SELECT id, ts, kind, sender_name, sender_faction, target_faction, subject, body "
        .. "FROM sang_missive WHERE (" .. mine .. ") AND " .. notDismissed
        .. " ORDER BY id DESC LIMIT " .. limit .. ";")
    return istable(rows) and rows or {}
end

-- Vérifie qu'une missive s'adresse bien à ce personnage (perso ou faction),
-- avant de la laisser la supprimer de sa propre boîte.
function SMISSIVE.SQL.IsAddressedTo(id, sid64, slot, faction)
    local row = sql.QueryRow("SELECT target_sid, target_slot, target_faction FROM sang_missive WHERE id = " .. N(id) .. ";")
    if not row then return false end
    if row.target_sid == tostring(sid64) and tonumber(row.target_slot) == N(slot) then return true end
    if faction and faction ~= "" and row.target_faction == faction then return true end
    return false
end

function SMISSIVE.SQL.Dismiss(sid64, slot, id)
    sql.Query("INSERT OR IGNORE INTO sang_missive_dismissed (steamid64, slot, missive_id) VALUES ("
        .. E(sid64) .. ", " .. N(slot) .. ", " .. N(id) .. ");")
end

function SMISSIVE.SQL.GetCursor(sid64, slot)
    local v = sql.QueryValue("SELECT last_id FROM sang_missive_cursor WHERE steamid64 = " .. E(sid64)
        .. " AND slot = " .. N(slot) .. ";")
    return tonumber(v) or 0
end

function SMISSIVE.SQL.SetCursor(sid64, slot, lastId)
    sql.Query("INSERT OR REPLACE INTO sang_missive_cursor (steamid64, slot, last_id) VALUES ("
        .. E(sid64) .. ", " .. N(slot) .. ", " .. N(lastId) .. ");")
end

SMISSIVE.SQL.Init()
