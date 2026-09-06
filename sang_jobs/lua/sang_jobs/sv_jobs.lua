--[[-------------------------------------------------------------------------
    Sang et Nuit — Jobs : logique serveur
      - Contribution au calcul des stats (le job pose la base PV/armure/vitesse)
      - Choix de job (F4)
      - Actions admin (Config Perso : forcer un job, override, effacer)
---------------------------------------------------------------------------]]

SJOB = SJOB or {}
local C = SJOB.Config

local function notify(ply, msg, kind)
    if BLOOD and BLOOD.Notify then BLOOD.Notify(ply, msg, kind) else ply:ChatPrint("[Job] " .. msg) end
end

--- Données de job appliquées à un joueur (base du job).
--  Les stats forcées PAR PERSO sont gérées côté cœur (BLOOD, par slot),
--  au-dessus de tout — voir Origines > Gestion Joueurs > « Stats forcées ».
function SJOB.GetJobData(ply)
    local base = SJOB.GetJob(ply.SJob or C.DefaultJob)
    return { id = base.id, hp = base.hp, armor = base.armor, speed = base.speed }
end

--- Contribution au point d'assemblage : le job pose la base.
hook.Add("BLOOD_ComputeStats", "SJOB_Compute", function(ply, stats)
    local slot = ply.BloodActiveSlot or 1
    if ply.SJobSlot ~= slot or not ply.SJob then
        ply.SJob = SJOB.SQL.GetCharJob(ply:SteamID64(), slot)
        ply.SJobSlot = slot
        local j = SJOB.GetJob(ply.SJob)
        ply:SetNWString("sang_job", ply.SJob)
        ply:SetNWString("sang_faction", j.faction or "none")
    end
    local job = SJOB.GetJobData(ply)
    stats.baseHP   = job.hp
    stats.armor    = job.armor
    stats.speedMul = stats.speedMul * (job.speed or 1)
end)

-- Changement de personnage : on vide le cache job pour forcer un rechargement
-- du job enregistré du NOUVEAU slot (sinon on garderait le job du slot précédent).
hook.Add("BLOOD_CharacterChanged", "SJOB_CharChange", function(ply, slot)
    ply.SJob = nil
    ply.SJobSlot = nil
end)

--- Change le job du personnage actif (respawn pour appliquer proprement).
function SJOB.SetJob(ply, jobId, silent)
    if not IsValid(ply) or not SJOB.JobExists(jobId) then return end
    local slot = ply.BloodActiveSlot or 1
    SJOB.SQL.SetCharJob(ply:SteamID64(), slot, jobId)
    ply.SJob = jobId
    ply.SJobSlot = slot
    local j = SJOB.GetJob(jobId)
    ply:SetNWString("sang_job", jobId)
    ply:SetNWString("sang_faction", j.faction or "none")

    if ply:Alive() then
        ply:Spawn()
    elseif BLOOD.ApplyComputedStats then
        BLOOD.ApplyComputedStats(ply, true)
    end
    if not silent then notify(ply, "Job : " .. j.name .. ".", "info") end
end

----------------------------------------------------------------------
-- F4 : choix de job
----------------------------------------------------------------------
SJOB.NetReceive("sjob_set", 0.5, function(_, ply)
    local jobId = net.ReadString()
    if BLOOD.HasCharacter and not BLOOD.HasCharacter(ply) then
        notify(ply, "Crée d'abord un personnage.", "error")
        return
    end
    if ply.SJobNext and CurTime() < ply.SJobNext then return end
    ply.SJobNext = CurTime() + (C.ChangeCooldown or 2)
    if not SJOB.JobExists(jobId) then return end
    SJOB.SetJob(ply, jobId)
end)

----------------------------------------------------------------------
-- Admin (Config Perso)
----------------------------------------------------------------------
local function isAdmin(ply) return BLOOD and BLOOD.IsAdmin and BLOOD.IsAdmin(ply) end

local function log(ply, line)
    if BLOOD and BLOOD.LogAdmin then BLOOD.LogAdmin("[JOB] " .. ply:Nick() .. " (" .. ply:SteamID64() .. ") " .. line) end
    MsgN("[Sang Jobs][ADMIN] " .. ply:Nick() .. " " .. line)
end

-- Forcer le job d'un slot d'un joueur.
SJOB.NetReceive("sjob_admin_setjob", 0.3, function(_, ply)
    if not isAdmin(ply) then return end
    local sid = BLOOD.NormalizeSteamID(net.ReadString())
    local slot = net.ReadUInt(8)
    local jobId = net.ReadString()
    if not sid or slot < 1 or slot > 4 or not SJOB.JobExists(jobId) then return end

    SJOB.SQL.SetCharJob(sid, slot, jobId)
    local target = BLOOD.GetPlayerBySteamID64(sid)
    if IsValid(target) and (target.BloodActiveSlot or 1) == slot then
        SJOB.SetJob(target, jobId, true)
    end
    log(ply, "a défini le job de " .. sid .. " slot " .. slot .. " => " .. jobId)
    notify(ply, "Job défini : " .. sid .. " slot " .. slot .. " => " .. jobId .. ".", "info")
end)

-- Override PV/armure/vitesse d'un (joueur, job). -1 = non défini.
SJOB.NetReceive("sjob_admin_setoverride", 0.3, function(_, ply)
    if not isAdmin(ply) then return end
    local sid = BLOOD.NormalizeSteamID(net.ReadString())
    local jobId = net.ReadString()
    local hp = net.ReadInt(32)
    local armor = net.ReadInt(32)
    local speed = net.ReadFloat()
    if not sid or not SJOB.JobExists(jobId) then return end

    SJOB.SQL.SetOverride(sid, jobId, hp, armor, speed)
    -- Réapplique si le joueur est en ligne et joue ce job (max mis à jour,
    -- sans soigner : on garde ses PV/mana courants).
    local target = BLOOD.GetPlayerBySteamID64(sid)
    if IsValid(target) and target.SJob == jobId then
        if BLOOD.RefreshStats then BLOOD.RefreshStats(target)
        elseif BLOOD.ApplyComputedStats then BLOOD.ApplyComputedStats(target, false) end
    end
    log(ply, "override job " .. jobId .. " de " .. sid .. " (hp=" .. hp .. " armor=" .. armor .. " speed=" .. speed .. ")")
    notify(ply, "Override enregistré (" .. sid .. " / " .. jobId .. ").", "info")
end)

SJOB.NetReceive("sjob_admin_clearoverride", 0.3, function(_, ply)
    if not isAdmin(ply) then return end
    local sid = BLOOD.NormalizeSteamID(net.ReadString())
    local jobId = net.ReadString()
    if not sid or not SJOB.JobExists(jobId) then return end
    SJOB.SQL.ClearOverride(sid, jobId)
    local target = BLOOD.GetPlayerBySteamID64(sid)
    if IsValid(target) and target.SJob == jobId then
        if BLOOD.RefreshStats then BLOOD.RefreshStats(target)
        elseif BLOOD.ApplyComputedStats then BLOOD.ApplyComputedStats(target, false) end
    end
    log(ply, "a effacé l'override job " .. jobId .. " de " .. sid)
    notify(ply, "Override effacé (" .. sid .. " / " .. jobId .. ").", "info")
end)

-- Requête : défauts du job + override actuel
SJOB.NetReceive("sjob_query", 0.15, function(_, ply)
    if not isAdmin(ply) then return end
    local sid = BLOOD.NormalizeSteamID(net.ReadString())
    local jobId = net.ReadString()
    if not sid or not SJOB.JobExists(jobId) then return end
    local base = SJOB.GetJob(jobId)
    local ov = SJOB.SQL.GetOverride(sid, jobId)

    net.Start("sjob_query_result")
        net.WriteString(sid)
        net.WriteString(jobId)
        net.WriteInt(base.hp, 32)
        net.WriteInt(base.armor, 32)
        net.WriteFloat(base.speed)
        net.WriteInt(ov.hp or -1, 32)
        net.WriteInt(ov.armor or -1, 32)
        net.WriteFloat(ov.speed or -1)
    net.Send(ply)
end)
