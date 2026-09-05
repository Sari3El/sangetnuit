--[[-------------------------------------------------------------------------
    Sang et Nuit — Jobs : persistance SQL
      sjob_char     : job PAR PERSONNAGE (steamid64 + slot)
      sjob_override : override PV/armure/vitesse PAR JOUEUR + PAR JOB
                      (-1 = non défini => on utilise la valeur du job)
---------------------------------------------------------------------------]]

SJOB = SJOB or {}
SJOB.SQL = SJOB.SQL or {}

local function E(v) return sql.SQLStr(tostring(v)) end
local function N(v) return math.floor(tonumber(v) or 0) end
local function R(v) return tonumber(v) or -1 end

function SJOB.SQL.Init()
    sql.Query([[CREATE TABLE IF NOT EXISTS sjob_char (
        steamid64 TEXT NOT NULL,
        slot      INTEGER NOT NULL,
        job       TEXT NOT NULL,
        PRIMARY KEY (steamid64, slot)
    );]])
    sql.Query([[CREATE TABLE IF NOT EXISTS sjob_override (
        steamid64 TEXT NOT NULL,
        job       TEXT NOT NULL,
        hp        INTEGER NOT NULL DEFAULT -1,
        armor     INTEGER NOT NULL DEFAULT -1,
        speed     REAL    NOT NULL DEFAULT -1,
        PRIMARY KEY (steamid64, job)
    );]])
end

-- Job d'un personnage
function SJOB.SQL.GetCharJob(sid64, slot)
    local v = sql.QueryValue("SELECT job FROM sjob_char WHERE steamid64 = " .. E(sid64) .. " AND slot = " .. N(slot) .. ";")
    if v and SJOB.JobExists(v) then return v end
    return SJOB.Config.DefaultJob
end

function SJOB.SQL.SetCharJob(sid64, slot, job)
    sql.Query("INSERT OR REPLACE INTO sjob_char (steamid64, slot, job) VALUES ("
        .. E(sid64) .. ", " .. N(slot) .. ", " .. E(job) .. ");")
end

-- Override PV/armure/vitesse d'un (joueur, job) ; renvoie {hp,armor,speed}
-- avec nil quand non défini.
function SJOB.SQL.GetOverride(sid64, job)
    local rows = sql.Query("SELECT hp, armor, speed FROM sjob_override WHERE steamid64 = " .. E(sid64)
        .. " AND job = " .. E(job) .. ";")
    if istable(rows) and rows[1] then
        local r = rows[1]
        local hp, armor, speed = tonumber(r.hp), tonumber(r.armor), tonumber(r.speed)
        return {
            hp    = (hp    and hp    >= 0) and hp or nil,
            armor = (armor and armor >= 0) and armor or nil,
            speed = (speed and speed >= 0) and speed or nil,
        }
    end
    return {}
end

function SJOB.SQL.SetOverride(sid64, job, hp, armor, speed)
    sql.Query("INSERT OR REPLACE INTO sjob_override (steamid64, job, hp, armor, speed) VALUES ("
        .. E(sid64) .. ", " .. E(job) .. ", " .. N(hp) .. ", " .. N(armor) .. ", " .. R(speed) .. ");")
end

function SJOB.SQL.ClearOverride(sid64, job)
    sql.Query("DELETE FROM sjob_override WHERE steamid64 = " .. E(sid64) .. " AND job = " .. E(job) .. ";")
end

SJOB.SQL.Init()
