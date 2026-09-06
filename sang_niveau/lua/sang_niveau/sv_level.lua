--[[-------------------------------------------------------------------------
    Sang et Nuit — Niveaux : logique serveur
      XP passif, montées de niveau, points de compétence, effets sur les
      stats (Force/Résistance = dégâts ; Agilité/Vitalité = vitesse/PV).
      Progression PAR PERSONNAGE (chargée pour le slot actif).
---------------------------------------------------------------------------]]

SLVL = SLVL or {}
local C = SLVL.Config

-- Multiplicateur d'XP serveur : 0 = normal (×1). Remis à 0 au démarrage.
SLVL.XPMult = 0

local function notify(ply, msg, kind)
    if BLOOD and BLOOD.Notify then BLOOD.Notify(ply, msg, kind) else ply:ChatPrint("[Niveau] " .. msg) end
end
SLVL.Notify = notify

----------------------------------------------------------------------
-- Points disponibles / sauvegarde
----------------------------------------------------------------------
function SLVL.Available(d)
    local spent = (d.force or 0) + (d.resist or 0) + (d.agilite or 0) + (d.vitalite or 0)
    return math.max(0, (d.level - 1) + (d.bonus or 0) - spent)
end

function SLVL.Save(ply)
    if IsValid(ply) and ply.SLVL and ply.SLVLSlot then
        SLVL.SQL.Set(ply:SteamID64(), ply.SLVLSlot, ply.SLVL)
    end
end

----------------------------------------------------------------------
-- Synchro client
----------------------------------------------------------------------
function SLVL.Sync(ply)
    if not IsValid(ply) or not ply.SLVL then return end
    local d = ply.SLVL
    ply:SetNWInt("slvl_level", d.level) -- lisible par tous (scoreboard)
    net.Start("slvl_sync")
        net.WriteUInt(d.level, 16)
        net.WriteUInt(math.max(0, d.xp), 32)
        net.WriteUInt(SLVL.XPForLevel(d.level), 32)
        net.WriteUInt(SLVL.Available(d), 16)
        net.WriteUInt(d.force, 8)
        net.WriteUInt(d.resist, 8)
        net.WriteUInt(d.agilite, 8)
        net.WriteUInt(d.vitalite, 8)
        net.WriteUInt(d.reset, 16)
    net.Send(ply)
end

----------------------------------------------------------------------
-- Application des effets PV / vitesse (par-dessus la race)
----------------------------------------------------------------------
-- Contribution au calcul des stats : multiplie PV/vitesse selon les points.
--  (Le job pose la base, la race multiplie, le niveau multiplie ici.)
hook.Add("BLOOD_ComputeStats", "SLVL_Compute", function(ply, stats)
    local slot = ply.BloodActiveSlot or 1
    if ply.SLVLSlot ~= slot or not ply.SLVL then
        ply.SLVL = SLVL.SQL.Get(ply:SteamID64(), slot)
        ply.SLVLSlot = slot
    end
    local d = ply.SLVL
    stats.hpMul    = stats.hpMul    * (1 + SLVL.PointsToPct(d.vitalite) / 100)
    stats.speedMul = stats.speedMul * (1 + SLVL.PointsToPct(d.agilite) / 100)
end)

-- Après application des stats : synchro HUD + réseau du niveau.
hook.Add("BLOOD_PostApplyStats", "SLVL_Sync", function(ply)
    SLVL.Sync(ply)
end)

-- Changement de personnage : on vide le cache pour recharger la progression
-- (niveau / points) du NOUVEAU slot au respawn.
hook.Add("BLOOD_CharacterChanged", "SLVL_CharChange", function(ply, slot)
    ply.SLVL = nil
    ply.SLVLSlot = nil
end)

-- Sauvegarde globale (déclenchée par l'addon sang_backup) : flush des
-- progressions des joueurs en ligne vers la SQL avant le dump.
hook.Add("Sang_SaveAll", "SLVL_SaveAll", function()
    for _, ply in ipairs(player.GetAll()) do
        SLVL.Save(ply)
    end
end)

----------------------------------------------------------------------
-- Effets sur les dégâts (Force / Résistance)
----------------------------------------------------------------------
hook.Add("EntityTakeDamage", "SLVL_Damage", function(target, dmginfo)
    local att = dmginfo:GetAttacker()
    if IsValid(att) and att:IsPlayer() and att.SLVL then
        local p = SLVL.PointsToPct(att.SLVL.force) / 100
        if p > 0 then dmginfo:ScaleDamage(1 + p) end
    end
    if IsValid(target) and target:IsPlayer() and target.SLVL then
        local p = SLVL.PointsToPct(target.SLVL.resist) / 100
        if p > 0 then dmginfo:ScaleDamage(1 - p) end
    end
end)

----------------------------------------------------------------------
-- XP / montée de niveau
----------------------------------------------------------------------
function SLVL.AddXP(ply, amount)
    local d = ply.SLVL
    if not d or d.level >= C.MaxLevel then return end
    d.xp = d.xp + math.floor(amount)

    local leveled = false
    while d.level < C.MaxLevel do
        local need = SLVL.XPForLevel(d.level)
        if need <= 0 or d.xp < need then break end
        d.xp = d.xp - need
        d.level = d.level + 1
        leveled = true
    end
    if d.level >= C.MaxLevel then d.xp = 0 end

    SLVL.Save(ply)
    SLVL.Sync(ply)
    if leveled then
        ply:EmitSound(C.LevelUpSound)
        notify(ply, "Niveau " .. d.level .. " atteint !", "reroll")
    end
end

-- Tick passif
timer.Create("SLVL_XPTick", C.TickInterval, 0, function()
    local mult = (SLVL.XPMult and SLVL.XPMult > 0) and SLVL.XPMult or 1
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() and ply.SLVL
           and BLOOD and BLOOD.HasCharacter and BLOOD.HasCharacter(ply) then
            SLVL.AddXP(ply, C.XPPerTick * mult)
        end
    end
end)

----------------------------------------------------------------------
-- Interaction : dépenser un point / réinitialiser
----------------------------------------------------------------------
function SLVL.IsNearStats(ply)
    if not IsValid(ply) then return false end
    for _, e in ipairs(ents.FindByClass("sang_stats")) do
        if IsValid(e) and ply:GetPos():Distance(e:GetPos()) <= C.StatsDist then return true end
    end
    return false
end

local VALID_STATS = { force = true, resist = true, agilite = true, vitalite = true }

SLVL.NetReceive("slvl_spend", 0.15, function(_, ply)
    local key  = net.ReadString()
    local want = math.Clamp(net.ReadUInt(8), 1, 100) -- +1 ou +10 (ou plus)
    if not ply.SLVL or not VALID_STATS[key] then return end
    if not SLVL.IsNearStats(ply) then notify(ply, "Approche-toi d'une borne.", "error") return end

    -- Dépense jusqu'à `want` points, bornée par les points dispo et le max.
    local added = 0
    while added < want and SLVL.Available(ply.SLVL) > 0 and ply.SLVL[key] < C.MaxPointsPerStat do
        ply.SLVL[key] = ply.SLVL[key] + 1
        added = added + 1
    end

    if added == 0 then
        if SLVL.Available(ply.SLVL) <= 0 then
            notify(ply, "Aucun point disponible.", "error")
        else
            notify(ply, "Statistique au maximum.", "error")
        end
        return
    end

    SLVL.Save(ply)
    if BLOOD.ApplyComputedStats then BLOOD.ApplyComputedStats(ply, false) end
    SLVL.Sync(ply)
    ply:EmitSound(C.SpendSound)
end)

SLVL.NetReceive("slvl_respec", 1.0, function(_, ply)
    if not ply.SLVL then return end
    if not SLVL.IsNearStats(ply) then notify(ply, "Approche-toi d'une borne.", "error") return end
    if (ply.SLVL.reset or 0) <= 0 then notify(ply, "Aucun point de reset.", "error") return end
    ply.SLVL.reset = ply.SLVL.reset - 1
    ply.SLVL.force, ply.SLVL.resist, ply.SLVL.agilite, ply.SLVL.vitalite = 0, 0, 0, 0
    SLVL.Save(ply)
    -- RAFRAÎCHISSEMENT (pas de soin) : les max PV/vitesse baissent (points
    -- remis à 0) mais on garde les PV/mana courants (bornés au nouveau max).
    if BLOOD.RefreshStats then BLOOD.RefreshStats(ply)
    elseif BLOOD.ApplyComputedStats then BLOOD.ApplyComputedStats(ply, false) end
    SLVL.Sync(ply)
    notify(ply, "Tes points ont été réinitialisés.", "info")
end)

function SLVL.OpenStats(ply)
    if not IsValid(ply) then return end
    if ply.SLVLNextOpen and CurTime() < ply.SLVLNextOpen then return end
    ply.SLVLNextOpen = CurTime() + 0.5
    SLVL.Sync(ply)
    net.Start("slvl_open_stats") net.Send(ply)
end

----------------------------------------------------------------------
-- Actions admin (utilisées par sv_admin)
----------------------------------------------------------------------
local function adminGet(sid, slot)
    local ply = BLOOD.GetPlayerBySteamID64(sid)
    if IsValid(ply) and (ply.BloodActiveSlot or 1) == slot and ply.SLVL then
        return ply, ply.SLVL
    end
    return ply, SLVL.SQL.Get(sid, slot)
end

local function adminCommit(sid, slot, d)
    local ply = BLOOD.GetPlayerBySteamID64(sid)
    if IsValid(ply) and (ply.BloodActiveSlot or 1) == slot then
        ply.SLVL = d
        ply.SLVLSlot = slot
        SLVL.SQL.Set(sid, slot, d)
        -- Changement admin (niveau/points) : on rafraîchit les max sans soigner.
        if BLOOD.RefreshStats then BLOOD.RefreshStats(ply)
        elseif BLOOD.ApplyComputedStats then BLOOD.ApplyComputedStats(ply, false) end
        SLVL.Sync(ply)
    else
        SLVL.SQL.Set(sid, slot, d)
    end
end

function SLVL.AdminSetLevel(sid, slot, level)
    local _, d = adminGet(sid, slot)
    d.level = math.Clamp(math.floor(level), 1, C.MaxLevel)
    d.xp = 0
    adminCommit(sid, slot, d)
    return d.level
end

function SLVL.AdminGivePoints(sid, slot, n)
    local _, d = adminGet(sid, slot)
    d.bonus = math.max(0, (d.bonus or 0) + math.floor(n))
    adminCommit(sid, slot, d)
    return d.bonus
end

function SLVL.AdminGiveReset(sid, slot, n)
    local _, d = adminGet(sid, slot)
    d.reset = math.max(0, (d.reset or 0) + math.floor(n))
    adminCommit(sid, slot, d)
    return d.reset
end
