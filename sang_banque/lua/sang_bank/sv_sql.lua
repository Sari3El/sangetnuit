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

SBANK.SQL.Init()
