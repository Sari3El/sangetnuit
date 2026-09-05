--[[-------------------------------------------------------------------------
    Sang et Nuit — Banque : persistance SQL (SQLite)
      sbank_personal : banque PAR PERSONNAGE (steamid64 + slot)
      sbank_faction  : banques de faction (monstre / humain / guilde)
      sbank_settings : taxes (tax_personal, tax_faction)
---------------------------------------------------------------------------]]

SBANK = SBANK or {}
SBANK.SQL = SBANK.SQL or {}
local C = SBANK.Config

local function E(v) return sql.SQLStr(tostring(v)) end
local function N(v) return math.floor(tonumber(v) or 0) end

function SBANK.SQL.Init()
    sql.Query([[CREATE TABLE IF NOT EXISTS sbank_personal (
        steamid64 TEXT NOT NULL,
        slot      INTEGER NOT NULL,
        amount    INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (steamid64, slot)
    );]])

    sql.Query([[CREATE TABLE IF NOT EXISTS sbank_faction (
        faction TEXT PRIMARY KEY,
        amount  INTEGER NOT NULL DEFAULT 0
    );]])

    sql.Query([[CREATE TABLE IF NOT EXISTS sbank_settings (
        skey  TEXT PRIMARY KEY,
        value TEXT
    );]])

    -- Historique des actions de banque (persistant, on ne garde que les 100 dernières)
    sql.Query([[CREATE TABLE IF NOT EXISTS sbank_history (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        ts          INTEGER NOT NULL DEFAULT 0,
        action      TEXT    NOT NULL DEFAULT '',
        actor       TEXT    NOT NULL DEFAULT '',
        actor_name  TEXT    NOT NULL DEFAULT '',
        target      TEXT    NOT NULL DEFAULT '',
        slot        INTEGER NOT NULL DEFAULT 0,
        amount      INTEGER NOT NULL DEFAULT 0,
        detail      TEXT    NOT NULL DEFAULT ''
    );]])

    -- Lignes de faction
    for _, fac in ipairs(C.Factions) do
        if not sql.QueryValue("SELECT 1 FROM sbank_faction WHERE faction = " .. E(fac) .. ";") then
            sql.Query("INSERT INTO sbank_faction (faction, amount) VALUES (" .. E(fac) .. ", 0);")
        end
    end

    -- Taxes par défaut
    SBANK.SQL.EnsureSetting("tax_personal", C.DefaultTaxPersonal)
    SBANK.SQL.EnsureSetting("tax_faction", C.DefaultTaxFaction)
end

function SBANK.SQL.EnsureSetting(key, default)
    if not sql.QueryValue("SELECT 1 FROM sbank_settings WHERE skey = " .. E(key) .. ";") then
        sql.Query("INSERT INTO sbank_settings (skey, value) VALUES (" .. E(key) .. ", " .. E(default) .. ");")
    end
end

----------------------------------------------------------------------
-- Banque perso
----------------------------------------------------------------------
function SBANK.GetPersonal(sid64, slot)
    local v = sql.QueryValue("SELECT amount FROM sbank_personal WHERE steamid64 = " .. E(sid64)
        .. " AND slot = " .. N(slot) .. ";")
    return tonumber(v) or 0
end

function SBANK.SetPersonal(sid64, slot, amount)
    amount = math.max(0, N(amount))
    sql.Query("INSERT OR REPLACE INTO sbank_personal (steamid64, slot, amount) VALUES ("
        .. E(sid64) .. ", " .. N(slot) .. ", " .. amount .. ");")
    return amount
end

function SBANK.AddPersonal(sid64, slot, delta)
    return SBANK.SetPersonal(sid64, slot, SBANK.GetPersonal(sid64, slot) + N(delta))
end

----------------------------------------------------------------------
-- Banques de faction
----------------------------------------------------------------------
function SBANK.GetFaction(fac)
    local v = sql.QueryValue("SELECT amount FROM sbank_faction WHERE faction = " .. E(fac) .. ";")
    return tonumber(v) or 0
end

function SBANK.SetFaction(fac, amount)
    amount = math.max(0, N(amount))
    sql.Query("UPDATE sbank_faction SET amount = " .. amount .. " WHERE faction = " .. E(fac) .. ";")
    return amount
end

function SBANK.AddFaction(fac, delta)
    return SBANK.SetFaction(fac, SBANK.GetFaction(fac) + N(delta))
end

----------------------------------------------------------------------
-- Taxes
----------------------------------------------------------------------
function SBANK.GetTax(kind) -- "personal" | "faction"
    local v = sql.QueryValue("SELECT value FROM sbank_settings WHERE skey = " .. E("tax_" .. kind) .. ";")
    return math.Clamp(tonumber(v) or 0, 0, C.MaxTax)
end

function SBANK.SetTax(kind, value)
    value = math.Clamp(N(value), 0, C.MaxTax)
    SBANK.SQL.EnsureSetting("tax_" .. kind, value)
    sql.Query("UPDATE sbank_settings SET value = " .. E(value) .. " WHERE skey = " .. E("tax_" .. kind) .. ";")
    return value
end

----------------------------------------------------------------------
-- Historique (les 100 dernières actions de banque, persistant au restart)
----------------------------------------------------------------------
SBANK.HistoryMax = SBANK.HistoryMax or 100

-- Ajoute une entrée et élague la table pour ne garder que les N dernières.
function SBANK.SQL.AddHistory(e)
    e = e or {}
    sql.Query("INSERT INTO sbank_history (ts, action, actor, actor_name, target, slot, amount, detail) VALUES ("
        .. N(e.ts or os.time()) .. ", "
        .. E(e.action or "") .. ", "
        .. E(e.actor or "") .. ", "
        .. E(e.actor_name or "") .. ", "
        .. E(e.target or "") .. ", "
        .. N(e.slot or 0) .. ", "
        .. math.floor(tonumber(e.amount) or 0) .. ", "
        .. E(e.detail or "") .. ");")

    -- Élagage : supprime tout ce qui dépasse les N id les plus récents.
    sql.Query("DELETE FROM sbank_history WHERE id NOT IN "
        .. "(SELECT id FROM sbank_history ORDER BY id DESC LIMIT " .. N(SBANK.HistoryMax) .. ");")
end

-- Renvoie une liste { {ts,action,actor,actor_name,target,slot,amount,detail}, ... }
-- de la plus récente à la plus ancienne.
function SBANK.SQL.GetHistory(limit)
    limit = math.Clamp(N(limit or SBANK.HistoryMax), 1, SBANK.HistoryMax)
    local rows = sql.Query("SELECT ts, action, actor, actor_name, target, slot, amount, detail "
        .. "FROM sbank_history ORDER BY id DESC LIMIT " .. limit .. ";")
    local out = {}
    if istable(rows) then
        for _, r in ipairs(rows) do
            out[#out + 1] = {
                ts         = tonumber(r.ts) or 0,
                action     = r.action or "",
                actor      = r.actor or "",
                actor_name = r.actor_name or "",
                target     = r.target or "",
                slot       = tonumber(r.slot) or 0,
                amount     = tonumber(r.amount) or 0,
                detail     = r.detail or "",
            }
        end
    end
    return out
end

SBANK.SQL.Init()
