--[[-------------------------------------------------------------------------
    Sang et Nuit — Tirage, application des stats, gestion des SWEP de race
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}

----------------------------------------------------------------------
-- Tirage pondéré (SERVEUR UNIQUEMENT)
--   Entier sur plage large (1..10000), jamais de float => 1/1000 exact.
----------------------------------------------------------------------
function BLOOD.RollRace()
    local r = math.random(1, 10000)
    for _, race in ipairs(BLOOD.Config.Races) do
        if r >= race.min and r <= race.max then
            return race.id
        end
    end
    return "human"
end

----------------------------------------------------------------------
-- Race active d'un joueur (depuis le cache mémoire du slot actif)
----------------------------------------------------------------------
function BLOOD.GetActiveRaceId(ply)
    local slot = ply.BloodActiveSlot or 1
    local sd = ply.BloodSlots and ply.BloodSlots[slot]
    return (sd and sd.race) or "human"
end

----------------------------------------------------------------------
-- SWEP de race : donner au spawn / retirer au changement de race
--   Aucun pouvoir déclenché par une touche : c'est une arme normale.
--   Les SWEP non installées (dragon/aigle/sorcier hors périmètre) sont
--   ignorées silencieusement (un seul avertissement console par classe).
----------------------------------------------------------------------
BLOOD._warnedWeapons = BLOOD._warnedWeapons or {}

function BLOOD.GiveRaceWeapons(ply, race)
    ply.BloodRaceWeapons = ply.BloodRaceWeapons or {}

    -- Retirer les SWEP de l'ANCIENNE race
    for _, cls in ipairs(ply.BloodRaceWeapons) do
        ply:StripWeapon(cls)
    end
    ply.BloodRaceWeapons = {}

    -- Donner les SWEP de la NOUVELLE race
    if race.weapons then
        for _, cls in ipairs(race.weapons) do
            if weapons.GetStored(cls) then
                ply:Give(cls)
                ply.BloodRaceWeapons[#ply.BloodRaceWeapons + 1] = cls
            elseif not BLOOD._warnedWeapons[cls] then
                BLOOD._warnedWeapons[cls] = true
                MsgN("[Sang et Nuit] SWEP '" .. cls .. "' non installée (module hors périmètre) — ignorée.")
            end
        end
    end
end

----------------------------------------------------------------------
-- Application des stats de la race active au joueur (spawn / changement)
----------------------------------------------------------------------
function BLOOD.ApplyRaceStats(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    local C = BLOOD.Config
    local race = BLOOD.GetRace(BLOOD.GetActiveRaceId(ply))

    -- PV / PV max
    local maxhp = math.max(1, math.Round(C.BaseHealth * (race.hp or 1)))
    ply:SetMaxHealth(maxhp)
    ply:SetHealth(maxhp)

    -- Vitesse (walk + run)
    ply:SetWalkSpeed(math.max(1, math.Round(C.BaseWalkSpeed * (race.speed or 1))))
    ply:SetRunSpeed(math.max(1, math.Round(C.BaseRunSpeed * (race.speed or 1))))

    -- Saut : RÈGLE = ne jamais modifier (sauf option d'uniformisation explicite)
    if C.EnforceDefaultJump then
        ply:SetJumpPower(C.DefaultJumpPower)
    end

    -- SWEP de race
    BLOOD.GiveRaceWeapons(ply, race)

    -- Variables réseau (HUD / affichage client)
    ply:SetNWString("blood_race", race.id)
    ply:SetNWInt("blood_slot", ply.BloodActiveSlot or 1)
end

----------------------------------------------------------------------
-- Définir la race d'un slot (joueur EN LIGNE)
--   Écrit en SQL + cache, applique les stats si c'est le slot actif.
----------------------------------------------------------------------
function BLOOD.SetRace(ply, slot, raceId)
    if not IsValid(ply) then return end
    raceId = BLOOD.RaceExists(raceId) and raceId or "human"
    slot = tonumber(slot) or ply.BloodActiveSlot or 1

    local sid = ply:SteamID64()

    -- SQL
    if BLOOD.SQL.GetSlot(sid, slot) then
        BLOOD.SQL.SetSlotRace(sid, slot, raceId)
    else
        BLOOD.SQL.CreateSlot(sid, slot, "Personnage " .. slot, raceId)
    end

    -- Cache mémoire
    ply.BloodSlots = ply.BloodSlots or {}
    ply.BloodSlots[slot] = ply.BloodSlots[slot] or { name = "Personnage " .. slot }
    ply.BloodSlots[slot].race = raceId

    -- Application si slot actif
    if (ply.BloodActiveSlot or 1) == slot then
        BLOOD.ApplyRaceStats(ply)
    end

    if BLOOD.SyncPlayer then BLOOD.SyncPlayer(ply) end
end

----------------------------------------------------------------------
-- Renommer un slot (joueur EN LIGNE) : SQL + cache + synchro
----------------------------------------------------------------------
function BLOOD.SetSlotName(ply, slot, name)
    if not IsValid(ply) then return end
    slot = tonumber(slot)
    name = tostring(name)
    if not (ply.BloodSlots and ply.BloodSlots[slot]) then return false end

    BLOOD.SQL.SetSlotName(ply:SteamID64(), slot, name)
    ply.BloodSlots[slot].name = name
    if BLOOD.SyncPlayer then BLOOD.SyncPlayer(ply) end
    return true
end

----------------------------------------------------------------------
-- Définir la race d'un slot (joueur HORS-LIGNE, écriture SQL directe)
----------------------------------------------------------------------
function BLOOD.SetRaceOffline(sid64, slot, raceId)
    sid64 = tostring(sid64)
    raceId = BLOOD.RaceExists(raceId) and raceId or "human"
    slot = tonumber(slot)

    if BLOOD.SQL.GetSlot(sid64, slot) then
        BLOOD.SQL.SetSlotRace(sid64, slot, raceId)
    else
        BLOOD.SQL.CreateSlot(sid64, slot, "Personnage " .. slot, raceId)
    end
end
