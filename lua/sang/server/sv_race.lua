--[[-------------------------------------------------------------------------
    Sang et Nuit — Tirage, application des stats, gestion des SWEP de race
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}

----------------------------------------------------------------------
-- Tirage pondéré (SERVEUR UNIQUEMENT)
--   Basé sur le "poids" de chaque race (race.weight). Par défaut le poids
--   vaut l'amplitude de sa plage d'origine (max-min+1), mais un admin peut
--   le modifier via l'éditeur de rareté (persistant en SQL).
----------------------------------------------------------------------
function BLOOD.RollRace()
    local total = 0
    for _, race in ipairs(BLOOD.Config.Races) do
        total = total + math.max(0, race.weight or 0)
    end
    if total <= 0 then return "human" end

    local r = math.random(1, total)
    local acc = 0
    for _, race in ipairs(BLOOD.Config.Races) do
        acc = acc + math.max(0, race.weight or 0)
        if r <= acc then return race.id end
    end
    return "human"
end

----------------------------------------------------------------------
-- Rareté : poids de tirage + palier (tier) par race, avec override admin
--   persistant. Recalculé au chargement et à chaque modification.
----------------------------------------------------------------------
--- Chance de tirage (%) d'une race d'après les poids courants.
function BLOOD.RarityChance(raceId)
    local total = 0
    for _, race in ipairs(BLOOD.Config.Races) do
        total = total + math.max(0, race.weight or 0)
    end
    if total <= 0 then return 0 end
    local r = BLOOD.Races[raceId]
    return 100 * math.max(0, (r and r.weight or 0)) / total
end

--- Charge les poids par défaut (depuis min/max) puis applique les overrides SQL.
function BLOOD.LoadRarity()
    -- Poids par défaut = amplitude de la plage d'origine.
    for _, race in ipairs(BLOOD.Config.Races) do
        race.baseWeight = math.max(0, (race.max or 0) - (race.min or 0) + 1)
        race.weight = race.weight or race.baseWeight
    end

    local ov = BLOOD.SQL.GetRarityOverrides and BLOOD.SQL.GetRarityOverrides() or {}
    for id, data in pairs(ov) do
        local race = BLOOD.Races[id]
        if race then
            race.weight = math.max(0, math.floor(data.weight or race.baseWeight))
            if data.tier ~= "" and BLOOD.Config.Tiers[data.tier] then
                BLOOD.Config.RaceTiers[id] = data.tier
            end
        end
    end
end

--- Modifie la rareté d'une race (poids + palier) et persiste.
function BLOOD.SetRarity(raceId, weight, tier)
    local race = BLOOD.Races[raceId]
    if not race then return false end
    weight = math.Clamp(math.floor(tonumber(weight) or 0), 0, 100000)
    if not (tier and BLOOD.Config.Tiers[tier]) then
        tier = BLOOD.Config.RaceTiers[raceId] or "commun"
    end
    race.weight = weight
    BLOOD.Config.RaceTiers[raceId] = tier
    if BLOOD.SQL.SetRarity then BLOOD.SQL.SetRarity(raceId, weight, tier) end
    return true
end

BLOOD.LoadRarity()

----------------------------------------------------------------------
-- Diagnostic : affiche le détail du calcul des stats d'un joueur.
--   Console serveur : sang_debug_stats [me|steamid]
--   En jeu (admin)  : sang_debug_stats            (sur soi)
-- Sert à vérifier que les jobs / niveaux / configs sont bien pris en compte
-- (si "Hooks BLOOD_ComputeStats: AUCUN", c'est que sang_jobs/sang_niveau ne
--  sont pas chargés OU que ce cœur 'sang_et_nuit' n'est pas à jour).
----------------------------------------------------------------------
concommand.Add("sang_debug_stats", function(ply, _, args)
    if IsValid(ply) and not BLOOD.IsAdmin(ply) then return end
    local function out(msg) if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, msg) else print(msg) end end

    local target = ply
    if args[1] and args[1] ~= "me" then
        local sid = BLOOD.NormalizeSteamID(args[1])
        target = sid and BLOOD.GetPlayerBySteamID64(sid) or nil
    end
    if not IsValid(target) then out("[Sang] Cible invalide.") return end

    out("=== Sang debug stats : " .. target:Nick() .. " ===")
    local hks = hook.GetTable()["BLOOD_ComputeStats"] or {}
    local names = {}
    for k in pairs(hks) do names[#names + 1] = tostring(k) end
    out("Hooks BLOOD_ComputeStats: " .. (#names > 0 and table.concat(names, ", ")
        or "AUCUN — sang_jobs/sang_niveau non chargés, ou coeur 'sang_et_nuit' pas à jour"))

    out("Slot actif: " .. (target.BloodActiveSlot or 1) .. "  |  Race: " .. BLOOD.GetActiveRaceId(target))
    out("NW job: " .. target:GetNWString("sang_job", "(aucun)") .. "  |  NW faction: " .. target:GetNWString("sang_faction", "(aucune)"))

    local s = BLOOD.ComputeStats(target)
    out(("baseHP=%s  hpMul=%.3f  =>  maxHP=%d"):format(tostring(s.baseHP), s.hpMul, math.Round(s.baseHP * s.hpMul)))
    out(("armor=%s  |  speedMul=%.3f  =>  walk=%d run=%d"):format(tostring(s.armor), s.speedMul,
        math.Round(s.baseWalk * s.speedMul), math.Round(s.baseRun * s.speedMul)))
    out(("EN JEU: HP=%d/%d  Armure=%d  Walk=%d"):format(target:Health(), target:GetMaxHealth(), target:Armor(), target:GetWalkSpeed()))
end)

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
--- Point d'assemblage des stats. Renvoie une table :
--    baseHP   : PV de base (les jobs la remplacent)
--    armor    : armure (les jobs la posent)
--    baseWalk / baseRun : vitesses moteur de base
--    hpMul    : multiplicateur PV (race puis niveau)
--    speedMul : multiplicateur vitesse (race puis job puis niveau)
--  Modèle : PV = baseHP × hpMul ; vitesse = baseWalk/run × speedMul.
--  Les autres addons écoutent "BLOOD_ComputeStats" pour composer :
--    jobs -> posent baseHP / armor et multiplient speedMul ;
--    niveaux -> multiplient hpMul / speedMul.
function BLOOD.ComputeStats(ply)
    local C = BLOOD.Config
    local race = BLOOD.GetRace(BLOOD.GetActiveRaceId(ply))
    local stats = {
        baseHP   = C.BaseHealth,
        armor    = 0,
        baseWalk = C.BaseWalkSpeed,
        baseRun  = C.BaseRunSpeed,
        hpMul    = race.hp or 1,      -- race (× niveau ensuite)
        speedMul = race.speed or 1,   -- race (× job × niveau ensuite)
    }
    hook.Run("BLOOD_ComputeStats", ply, stats)
    return stats
end

--- Applique les stats calculées. fullHeal=true met les PV au max (spawn/reroll/
--  changement) ; false conserve les PV courants (ajoute juste le delta de max).
function BLOOD.ApplyComputedStats(ply, fullHeal)
    if not IsValid(ply) or not ply:Alive() then return end
    local C = BLOOD.Config
    local s = BLOOD.ComputeStats(ply)

    local maxhp = math.max(1, math.Round(s.baseHP * s.hpMul))
    local armor = math.max(0, math.floor(s.armor))
    local walk  = math.max(1, math.Round(s.baseWalk * s.speedMul))
    local run   = math.max(1, math.Round(s.baseRun * s.speedMul))

    -- Stats FORCÉES par (joueur, slot, JOB courant) : remplacent les valeurs
    -- finales (au-dessus de job/race/niveau). Ne s'appliquent que si le joueur
    -- est sur ce slot ET dans ce job. Vide = automatique.
    local curJob = ply:GetNWString("sang_job", "")
    local ov = BLOOD.SQL.GetStatOverride
        and BLOOD.SQL.GetStatOverride(ply:SteamID64(), ply.BloodActiveSlot or 1, curJob) or {}
    if ov.hp then maxhp = math.max(1, math.floor(ov.hp)) end
    if ov.armor then armor = math.max(0, math.floor(ov.armor)) end
    if ov.speed then
        walk = math.max(1, math.Round(s.baseWalk * ov.speed))
        run  = math.max(1, math.Round(s.baseRun * ov.speed))
    end

    local oldMax, oldHP = ply:GetMaxHealth(), ply:Health()
    ply:SetMaxHealth(maxhp)
    if fullHeal then
        ply:SetHealth(maxhp)
    else
        ply:SetHealth(math.min(maxhp, oldHP + math.max(0, maxhp - oldMax)))
    end

    ply:SetArmor(armor)
    ply:SetMaxArmor(armor > 0 and armor or 100)
    ply:SetWalkSpeed(walk)
    ply:SetRunSpeed(run)

    if C.EnforceDefaultJump then ply:SetJumpPower(C.DefaultJumpPower) end
end

----------------------------------------------------------------------
-- Application des stats de la race active au joueur (spawn / changement)
----------------------------------------------------------------------
function BLOOD.ApplyRaceStats(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    local race = BLOOD.GetRace(BLOOD.GetActiveRaceId(ply))

    -- SWEP de race
    BLOOD.GiveRaceWeapons(ply, race)

    -- Variables réseau (HUD / affichage client)
    ply:SetNWString("blood_race", race.id)
    ply:SetNWInt("blood_slot", ply.BloodActiveSlot or 1)
    if BLOOD.GetCovan then ply:SetNWInt("blood_covan", BLOOD.GetCovan(ply)) end
    if BLOOD.SyncHungerNW then BLOOD.SyncHungerNW(ply) end

    -- Stats (PV / armure / vitesse) via le point d'assemblage
    BLOOD.ApplyComputedStats(ply, true)

    -- Compat : ancien point d'extension (après application).
    hook.Run("BLOOD_PostApplyStats", ply)
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
