--[[-------------------------------------------------------------------------
    Sang et Nuit — Niveaux : persistance SQL (PAR PERSONNAGE)
      slvl_progress : steamid64 + slot -> level, xp, points par stat,
                      bonus_points (admin), reset_tokens (admin).
---------------------------------------------------------------------------]]

SLVL = SLVL or {}
SLVL.SQL = SLVL.SQL or {}

local function E(v) return sql.SQLStr(tostring(v)) end
local function N(v) return math.floor(tonumber(v) or 0) end

function SLVL.SQL.Init()
    sql.Query([[CREATE TABLE IF NOT EXISTS slvl_progress (
        steamid64    TEXT NOT NULL,
        slot         INTEGER NOT NULL,
        level        INTEGER NOT NULL DEFAULT 1,
        xp           INTEGER NOT NULL DEFAULT 0,
        p_force      INTEGER NOT NULL DEFAULT 0,
        p_resist     INTEGER NOT NULL DEFAULT 0,
        p_agilite    INTEGER NOT NULL DEFAULT 0,
        p_vitalite   INTEGER NOT NULL DEFAULT 0,
        bonus_points INTEGER NOT NULL DEFAULT 0,
        reset_tokens INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (steamid64, slot)
    );]])
end

-- Charge (ou crée) la progression d'un (sid, slot).
function SLVL.SQL.Get(sid64, slot)
    slot = N(slot)
    local rows = sql.Query("SELECT * FROM slvl_progress WHERE steamid64 = " .. E(sid64) .. " AND slot = " .. slot .. ";")
    if istable(rows) and rows[1] then
        local r = rows[1]
        return {
            level = tonumber(r.level) or 1,
            xp = tonumber(r.xp) or 0,
            force = tonumber(r.p_force) or 0,
            resist = tonumber(r.p_resist) or 0,
            agilite = tonumber(r.p_agilite) or 0,
            vitalite = tonumber(r.p_vitalite) or 0,
            bonus = tonumber(r.bonus_points) or 0,
            reset = tonumber(r.reset_tokens) or 0,
        }
    end
    return {
        level = 1, xp = 0, force = 0, resist = 0, agilite = 0, vitalite = 0, bonus = 0, reset = 0,
    }
end

-- Écrit la progression d'un (sid, slot).
function SLVL.SQL.Set(sid64, slot, d)
    slot = N(slot)
    sql.Query("INSERT OR REPLACE INTO slvl_progress "
        .. "(steamid64, slot, level, xp, p_force, p_resist, p_agilite, p_vitalite, bonus_points, reset_tokens) VALUES ("
        .. E(sid64) .. ", " .. slot .. ", "
        .. N(d.level) .. ", " .. N(d.xp) .. ", "
        .. N(d.force) .. ", " .. N(d.resist) .. ", " .. N(d.agilite) .. ", " .. N(d.vitalite) .. ", "
        .. N(d.bonus) .. ", " .. N(d.reset) .. ");")
end

SLVL.SQL.Init()
