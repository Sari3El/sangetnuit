--[[-------------------------------------------------------------------------
    Sang et Nuit — Armoire à PM (playermodel) : persistance SQL
      Tout est stocké PAR PERSONNAGE (steamid64 + slot actif), comme la race
      dans le coeur : le playermodel fait partie de l'identité du perso.
        sarm_playermodel : modèle + skin choisis
        sarm_pm_bodygroup : bodygroups choisis (un par ligne)
      Réappliqués automatiquement au spawn (voir sv_armoire.lua).
---------------------------------------------------------------------------]]

SARM = SARM or {}
SARM.SQL = SARM.SQL or {}

local function E(v) return sql.SQLStr(tostring(v)) end
local function N(v) return math.floor(tonumber(v) or 0) end

function SARM.SQL.Init()
    sql.Query([[CREATE TABLE IF NOT EXISTS sarm_playermodel (
        steamid64 TEXT NOT NULL,
        slot      INTEGER NOT NULL,
        model     TEXT NOT NULL,
        skin      INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (steamid64, slot)
    );]])
    sql.Query([[CREATE TABLE IF NOT EXISTS sarm_pm_bodygroup (
        steamid64 TEXT NOT NULL,
        slot      INTEGER NOT NULL,
        bgid      INTEGER NOT NULL,
        value     INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (steamid64, slot, bgid)
    );]])
end

--- Playermodel + skin enregistrés pour (joueur, slot). nil si rien choisi.
function SARM.SQL.GetModel(sid64, slot)
    local rows = sql.Query("SELECT model, skin FROM sarm_playermodel WHERE steamid64 = "
        .. E(sid64) .. " AND slot = " .. N(slot) .. ";")
    if istable(rows) and rows[1] then
        return rows[1].model, N(rows[1].skin)
    end
    return nil, 0
end

function SARM.SQL.SetModel(sid64, slot, model, skin)
    sql.Query("INSERT OR REPLACE INTO sarm_playermodel (steamid64, slot, model, skin) VALUES ("
        .. E(sid64) .. ", " .. N(slot) .. ", " .. E(model) .. ", " .. N(skin) .. ");")
end

function SARM.SQL.SetSkin(sid64, slot, skin)
    sql.Query("UPDATE sarm_playermodel SET skin = " .. N(skin)
        .. " WHERE steamid64 = " .. E(sid64) .. " AND slot = " .. N(slot) .. ";")
end

--- Bodygroups enregistrés pour (joueur, slot) -> { [bgid] = value }
function SARM.SQL.GetBodygroups(sid64, slot)
    local rows = sql.Query("SELECT bgid, value FROM sarm_pm_bodygroup WHERE steamid64 = "
        .. E(sid64) .. " AND slot = " .. N(slot) .. ";")
    local out = {}
    if istable(rows) then
        for _, r in ipairs(rows) do out[N(r.bgid)] = N(r.value) end
    end
    return out
end

function SARM.SQL.SetBodygroup(sid64, slot, bgid, value)
    sql.Query("INSERT OR REPLACE INTO sarm_pm_bodygroup (steamid64, slot, bgid, value) VALUES ("
        .. E(sid64) .. ", " .. N(slot) .. ", " .. N(bgid) .. ", " .. N(value) .. ");")
end

--- Efface les bodygroups enregistrés (utilisé quand le joueur change de
--  playermodel : les anciens indices de bodygroups n'ont plus de sens).
function SARM.SQL.ClearBodygroups(sid64, slot)
    sql.Query("DELETE FROM sarm_pm_bodygroup WHERE steamid64 = " .. E(sid64) .. " AND slot = " .. N(slot) .. ";")
end

SARM.SQL.Init()
