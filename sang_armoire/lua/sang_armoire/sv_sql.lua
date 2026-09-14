--[[-------------------------------------------------------------------------
    Sang et Nuit — Armoire à PM : persistance SQL
      sarm_bodygroup : bodygroup choisi PAR JOUEUR + PAR CLASSE D'ARME,
                       réappliqué automatiquement quand le PM est rééquipé.
---------------------------------------------------------------------------]]

SARM = SARM or {}
SARM.SQL = SARM.SQL or {}

local function E(v) return sql.SQLStr(tostring(v)) end
local function N(v) return math.floor(tonumber(v) or 0) end

function SARM.SQL.Init()
    sql.Query([[CREATE TABLE IF NOT EXISTS sarm_bodygroup (
        steamid64 TEXT NOT NULL,
        class     TEXT NOT NULL,
        bgid      INTEGER NOT NULL,
        value     INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (steamid64, class, bgid)
    );]])
end

--- Bodygroups enregistrés pour (joueur, classe d'arme) -> { [bgid] = value }
function SARM.SQL.Get(sid64, class)
    local rows = sql.Query("SELECT bgid, value FROM sarm_bodygroup WHERE steamid64 = "
        .. E(sid64) .. " AND class = " .. E(class) .. ";")
    local out = {}
    if istable(rows) then
        for _, r in ipairs(rows) do out[N(r.bgid)] = N(r.value) end
    end
    return out
end

function SARM.SQL.Set(sid64, class, bgid, value)
    sql.Query("INSERT OR REPLACE INTO sarm_bodygroup (steamid64, class, bgid, value) VALUES ("
        .. E(sid64) .. ", " .. E(class) .. ", " .. N(bgid) .. ", " .. N(value) .. ");")
end

SARM.SQL.Init()
