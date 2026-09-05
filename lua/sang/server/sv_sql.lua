--[[-------------------------------------------------------------------------
    Sang et Nuit — Persistance SQL (SQLite intégré à GMod)

    Deux niveaux de persistance (cf. cahier des charges §3) :
      - blood_players : PAR JOUEUR (clé SteamID64) -> crédits de reroll,
        slot actif, déblocage du slot payant. Partagé entre tous les slots,
        totalement dissocié de l'or DarkRP.
      - blood_slots   : PAR SLOT (SteamID64 + slot) -> nom du perso + race.

    La base SQLite vit dans garrysmod/sv.db (aucune installation requise :
    fonctionne aussi en serveur écoute/solo).
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}
BLOOD.SQL = BLOOD.SQL or {}

-- sql.SQLStr renvoie la valeur DÉJÀ entre quotes et échappée : ne pas rajouter de quotes.
local function E(v) return sql.SQLStr(tostring(v)) end
local function N(v) return math.floor(tonumber(v) or 0) end

----------------------------------------------------------------------
-- Création des tables
----------------------------------------------------------------------
function BLOOD.SQL.Init()
    sql.Query([[CREATE TABLE IF NOT EXISTS blood_players (
        steamid64     TEXT PRIMARY KEY,
        credits       INTEGER NOT NULL DEFAULT 0,
        active_slot   INTEGER NOT NULL DEFAULT 1,
        paid_unlocked INTEGER NOT NULL DEFAULT 0
    );]])

    sql.Query([[CREATE TABLE IF NOT EXISTS blood_slots (
        steamid64 TEXT NOT NULL,
        slot      INTEGER NOT NULL,
        name      TEXT,
        race      TEXT NOT NULL DEFAULT 'human',
        covan     INTEGER NOT NULL DEFAULT 0,
        created   INTEGER,
        PRIMARY KEY (steamid64, slot)
    );]])

    -- Migration : ajoute la colonne covan aux bases existantes.
    local cols = sql.Query("PRAGMA table_info(blood_slots);")
    local hasCovan = false
    if istable(cols) then
        for _, c in ipairs(cols) do if c.name == "covan" then hasCovan = true break end end
    end
    if not hasCovan then
        sql.Query("ALTER TABLE blood_slots ADD COLUMN covan INTEGER NOT NULL DEFAULT 0;")
    end
end

--- Crée la ligne joueur si elle n'existe pas.
function BLOOD.SQL.EnsurePlayerRow(sid64)
    local exists = sql.QueryValue("SELECT 1 FROM blood_players WHERE steamid64 = " .. E(sid64) .. ";")
    if not exists then
        sql.Query("INSERT INTO blood_players (steamid64, credits, active_slot, paid_unlocked) VALUES ("
            .. E(sid64) .. ", 0, 1, 0);")
    end
end

----------------------------------------------------------------------
-- Crédits de reroll (par joueur, offline-safe)
----------------------------------------------------------------------

--- Lit le solde de crédits (SQL, fonctionne hors-ligne).
function BLOOD.GetCredits(sid64)
    local v = sql.QueryValue("SELECT credits FROM blood_players WHERE steamid64 = " .. E(sid64) .. ";")
    return tonumber(v) or 0
end

--- Écrit un solde absolu (borné à >= 0). Met à jour l'affichage si en ligne.
function BLOOD.SetCredits(sid64, amount)
    sid64 = tostring(sid64)
    BLOOD.SQL.EnsurePlayerRow(sid64)
    local val = math.max(0, N(amount))
    sql.Query("UPDATE blood_players SET credits = " .. val .. " WHERE steamid64 = " .. E(sid64) .. ";")

    local ply = BLOOD.GetPlayerBySteamID64(sid64)
    if IsValid(ply) then
        ply.BloodCredits = val
        ply:SetNWInt("blood_credits", val)
        if BLOOD.SyncPlayer then BLOOD.SyncPlayer(ply) end
    end
    return val
end

--- Ajoute (ou retire) des crédits. Renvoie le nouveau solde.
--  Fonctionne même si la cible est hors-ligne (pur SQL par SteamID64).
function BLOOD.AddCredits(sid64, delta)
    sid64 = tostring(sid64)
    BLOOD.SQL.EnsurePlayerRow(sid64)
    local new = math.max(0, BLOOD.GetCredits(sid64) + N(delta))
    return BLOOD.SetCredits(sid64, new)
end

----------------------------------------------------------------------
-- Slot payant
----------------------------------------------------------------------
function BLOOD.SQL.GetPaidUnlocked(sid64)
    local v = sql.QueryValue("SELECT paid_unlocked FROM blood_players WHERE steamid64 = " .. E(sid64) .. ";")
    return tonumber(v) == 1
end

--- À appeler depuis le système d'achat réel / premium (hors de ce système).
function BLOOD.SetPaidSlotUnlocked(sid64, unlocked)
    sid64 = tostring(sid64)
    BLOOD.SQL.EnsurePlayerRow(sid64)
    sql.Query("UPDATE blood_players SET paid_unlocked = " .. (unlocked and 1 or 0)
        .. " WHERE steamid64 = " .. E(sid64) .. ";")
    local ply = BLOOD.GetPlayerBySteamID64(sid64)
    if IsValid(ply) then
        ply.BloodPaidUnlocked = unlocked and true or false
        if BLOOD.SyncPlayer then BLOOD.SyncPlayer(ply) end
    end
end

----------------------------------------------------------------------
-- Slot actif (par joueur)
----------------------------------------------------------------------
function BLOOD.SQL.GetActiveSlot(sid64)
    local v = sql.QueryValue("SELECT active_slot FROM blood_players WHERE steamid64 = " .. E(sid64) .. ";")
    return tonumber(v) or 1
end

function BLOOD.SQL.SetActiveSlot(sid64, slot)
    sid64 = tostring(sid64)
    BLOOD.SQL.EnsurePlayerRow(sid64)
    sql.Query("UPDATE blood_players SET active_slot = " .. N(slot) .. " WHERE steamid64 = " .. E(sid64) .. ";")
end

----------------------------------------------------------------------
-- Slots de personnage (nom + race)
----------------------------------------------------------------------

--- Retourne { [slot] = { name=, race=, covan= } } pour un joueur.
function BLOOD.SQL.GetSlots(sid64)
    local rows = sql.Query("SELECT slot, name, race, covan FROM blood_slots WHERE steamid64 = " .. E(sid64) .. " ORDER BY slot;")
    local out = {}
    if istable(rows) then
        for _, row in ipairs(rows) do
            out[tonumber(row.slot)] = { name = row.name, race = row.race, covan = tonumber(row.covan) or 0 }
        end
    end
    return out
end

--- Retourne { name=, race=, covan= } d'un slot précis, ou nil.
function BLOOD.SQL.GetSlot(sid64, slot)
    local rows = sql.Query("SELECT name, race, covan FROM blood_slots WHERE steamid64 = " .. E(sid64)
        .. " AND slot = " .. N(slot) .. ";")
    if istable(rows) and rows[1] then
        return { name = rows[1].name, race = rows[1].race, covan = tonumber(rows[1].covan) or 0 }
    end
    return nil
end

--- Covan d'un slot (SQL, offline-safe).
function BLOOD.SQL.GetCovan(sid64, slot)
    local v = sql.QueryValue("SELECT covan FROM blood_slots WHERE steamid64 = " .. E(sid64)
        .. " AND slot = " .. N(slot) .. ";")
    return tonumber(v) or 0
end

function BLOOD.SQL.SetCovan(sid64, slot, amount)
    sql.Query("UPDATE blood_slots SET covan = " .. math.max(0, N(amount)) .. " WHERE steamid64 = " .. E(sid64)
        .. " AND slot = " .. N(slot) .. ";")
end

--- Crée (ou remplace) un slot. Un perso spawn TOUJOURS en Humain par défaut.
function BLOOD.SQL.CreateSlot(sid64, slot, name, race)
    race = BLOOD.RaceExists(race) and race or "human"
    name = tostring(name or ("Personnage " .. N(slot)))
    local startCovan = math.max(0, math.floor(BLOOD.Config.StartingCovan or 0))
    sql.Query("INSERT OR REPLACE INTO blood_slots (steamid64, slot, name, race, covan, created) VALUES ("
        .. E(sid64) .. ", " .. N(slot) .. ", " .. E(name) .. ", " .. E(race) .. ", " .. startCovan .. ", " .. os.time() .. ");")
end

--- Change uniquement la race d'un slot existant.
function BLOOD.SQL.SetSlotRace(sid64, slot, race)
    race = BLOOD.RaceExists(race) and race or "human"
    sql.Query("UPDATE blood_slots SET race = " .. E(race) .. " WHERE steamid64 = " .. E(sid64)
        .. " AND slot = " .. N(slot) .. ";")
end

--- Change uniquement le nom d'un slot existant.
function BLOOD.SQL.SetSlotName(sid64, slot, name)
    sql.Query("UPDATE blood_slots SET name = " .. E(tostring(name)) .. " WHERE steamid64 = " .. E(sid64)
        .. " AND slot = " .. N(slot) .. ";")
end

-- Initialisation immédiate.
BLOOD.SQL.Init()
