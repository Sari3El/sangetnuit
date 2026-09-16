--[[-------------------------------------------------------------------------
    Sang et Nuit — Armurerie : persistance SQL (SQLite)
      sarmory_items : armes stockées PAR PERSONNAGE (steamid64 + slot)
                      Chaque ligne = une arme (classe + munitions en chargeur).
---------------------------------------------------------------------------]]

SARM = SARM or {}
SARM.SQL = SARM.SQL or {}

local function E(v) return sql.SQLStr(tostring(v)) end
local function N(v) return math.floor(tonumber(v) or 0) end

function SARM.SQL.Init()
    sql.Query([[CREATE TABLE IF NOT EXISTS sarmory_items (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        steamid64  TEXT    NOT NULL,
        slot       INTEGER NOT NULL,
        class      TEXT    NOT NULL,
        clip1      INTEGER NOT NULL DEFAULT -1,
        clip2      INTEGER NOT NULL DEFAULT -1,
        stored_at  INTEGER NOT NULL DEFAULT 0
    );]])
    sql.Query("CREATE INDEX IF NOT EXISTS sarmory_items_owner ON sarmory_items (steamid64, slot);")
end

-- Toutes les armes d'un (sid64, slot), de la plus ancienne à la plus récente.
function SARM.SQL.GetItems(sid64, slot)
    local rows = sql.Query("SELECT id, class, clip1, clip2 FROM sarmory_items WHERE steamid64 = "
        .. E(sid64) .. " AND slot = " .. N(slot) .. " ORDER BY id ASC;")
    local out = {}
    if istable(rows) then
        for _, r in ipairs(rows) do
            out[#out + 1] = {
                id    = tonumber(r.id) or 0,
                class = r.class or "",
                clip1 = tonumber(r.clip1) or -1,
                clip2 = tonumber(r.clip2) or -1,
            }
        end
    end
    return out
end

function SARM.SQL.Count(sid64, slot)
    local v = sql.QueryValue("SELECT COUNT(*) FROM sarmory_items WHERE steamid64 = "
        .. E(sid64) .. " AND slot = " .. N(slot) .. ";")
    return tonumber(v) or 0
end

function SARM.SQL.AddItem(sid64, slot, class, clip1, clip2)
    sql.Query("INSERT INTO sarmory_items (steamid64, slot, class, clip1, clip2, stored_at) VALUES ("
        .. E(sid64) .. ", " .. N(slot) .. ", " .. E(class) .. ", "
        .. N(clip1) .. ", " .. N(clip2) .. ", " .. N(os.time()) .. ");")
end

-- Retire un item du coffre et le renvoie, à condition qu'il appartienne bien
-- au (sid64, slot) demandé (empêche de piocher dans le coffre d'un autre perso).
function SARM.SQL.TakeItem(sid64, slot, id)
    local rows = sql.Query("SELECT id, class, clip1, clip2 FROM sarmory_items WHERE id = " .. N(id)
        .. " AND steamid64 = " .. E(sid64) .. " AND slot = " .. N(slot) .. " LIMIT 1;")
    if not istable(rows) or not rows[1] then return nil end
    local r = rows[1]
    sql.Query("DELETE FROM sarmory_items WHERE id = " .. N(id) .. ";")
    return { id = tonumber(r.id), class = r.class, clip1 = tonumber(r.clip1) or -1, clip2 = tonumber(r.clip2) or -1 }
end

-- Vide entièrement le coffre d'un (sid64, slot) et renvoie ce qu'il contenait.
function SARM.SQL.TakeAll(sid64, slot)
    local items = SARM.SQL.GetItems(sid64, slot)
    if #items > 0 then
        sql.Query("DELETE FROM sarmory_items WHERE steamid64 = " .. E(sid64) .. " AND slot = " .. N(slot) .. ";")
    end
    return items
end

SARM.SQL.Init()
