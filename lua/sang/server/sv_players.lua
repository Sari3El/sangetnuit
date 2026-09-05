--[[-------------------------------------------------------------------------
    Sang et Nuit — Cycle de vie joueur, slots, synchro client
      - Chargement des données à la connexion (SANS auto-créer de perso)
      - À la 1re connexion (0 perso) : joueur VERROUILLÉ (figé + invincible)
        et menu forcé, jusqu'à ce qu'il crée et nomme son perso.
      - Application des stats au spawn
      - Sélection / création de slot
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}
local C = BLOOD.Config

----------------------------------------------------------------------
-- Notification vers un joueur
----------------------------------------------------------------------
function BLOOD.Notify(ply, msg, kind)
    if not IsValid(ply) then return end
    net.Start("blood_notify")
    net.WriteString(msg)
    net.WriteString(kind or "info")
    net.Send(ply)
end

----------------------------------------------------------------------
-- Le joueur possède-t-il au moins un personnage ?
----------------------------------------------------------------------
function BLOOD.HasCharacter(ply)
    if not ply.BloodSlots then return false end
    for i = 1, C.MaxSlots do
        if ply.BloodSlots[i] then return true end
    end
    return false
end

----------------------------------------------------------------------
-- Verrouillage (figé + invincible) tant qu'aucun perso n'est créé
----------------------------------------------------------------------
function BLOOD.SetLocked(ply, locked)
    if not IsValid(ply) then return end
    if locked then
        ply.BloodLocked = true
        ply:Lock()       -- bloque déplacement / armes
        ply:GodEnable()  -- invincible
    elseif ply.BloodLocked then
        ply.BloodLocked = false
        ply:UnLock()
        ply:GodDisable()
    end
end

----------------------------------------------------------------------
-- Synchro de l'état du joueur vers son client (menu / HUD)
----------------------------------------------------------------------
function BLOOD.SyncPlayer(ply)
    if not IsValid(ply) then return end
    net.Start("blood_sync")
        net.WriteBool(not BLOOD.HasCharacter(ply)) -- mustCreate
        net.WriteUInt(ply.BloodCredits or 0, 32)
        net.WriteUInt(ply.BloodActiveSlot or 1, 8)
        net.WriteBool(ply.BloodPaidUnlocked and true or false)

        local slots = ply.BloodSlots or {}
        net.WriteUInt(C.MaxSlots, 8)
        for i = 1, C.MaxSlots do
            local s = slots[i]
            net.WriteBool(s ~= nil)
            if s then
                net.WriteString(s.name or ("Personnage " .. i))
                net.WriteString(s.race or "human")
            end
        end
    net.Send(ply)
end

----------------------------------------------------------------------
-- Chargement des données du joueur (connexion) — SANS auto-créer de slot
----------------------------------------------------------------------
function BLOOD.LoadPlayer(ply)
    if not IsValid(ply) then return end
    local sid = ply:SteamID64()
    BLOOD.SQL.EnsurePlayerRow(sid)

    ply.BloodSlots        = BLOOD.SQL.GetSlots(sid) -- peut être vide (1re fois)
    ply.BloodCredits      = BLOOD.GetCredits(sid)
    ply.BloodActiveSlot   = BLOOD.SQL.GetActiveSlot(sid)
    ply.BloodPaidUnlocked = BLOOD.SQL.GetPaidUnlocked(sid)

    ply:SetNWInt("blood_credits", ply.BloodCredits)
end

----------------------------------------------------------------------
-- Connexion : charge, synchronise, verrouille + ouvre le menu si 0 perso
----------------------------------------------------------------------
hook.Add("PlayerInitialSpawn", "BLOOD_Init", function(ply)
    BLOOD.LoadPlayer(ply)
    timer.Simple(1, function()
        if not IsValid(ply) then return end
        BLOOD.SyncPlayer(ply)
        if not BLOOD.HasCharacter(ply) then
            BLOOD.SetLocked(ply, true)
            net.Start("blood_open_menu")
            net.Send(ply)
        end
    end)
end)

----------------------------------------------------------------------
-- Spawn : applique les stats, (dé)verrouille selon la présence d'un perso
----------------------------------------------------------------------
hook.Add("PlayerSpawn", "BLOOD_Spawn", function(ply)
    if not ply.BloodSlots then BLOOD.LoadPlayer(ply) end
    timer.Simple(C.ApplyDelay, function()
        if not (IsValid(ply) and ply:Alive()) then return end
        BLOOD.ApplyRaceStats(ply)
        BLOOD.SetLocked(ply, not BLOOD.HasCharacter(ply))
    end)
end)

----------------------------------------------------------------------
-- Sélection d'un slot (le "jouer")
----------------------------------------------------------------------
net.Receive("blood_select_slot", function(_, ply)
    local slot = net.ReadUInt(8)
    if slot < 1 or slot > C.MaxSlots then return end

    if slot > C.FreeSlots and not ply.BloodPaidUnlocked then
        BLOOD.Notify(ply, "Ce slot est payant et n'est pas débloqué.", "error")
        return
    end
    if not (ply.BloodSlots and ply.BloodSlots[slot]) then
        BLOOD.Notify(ply, "Ce personnage n'existe pas encore.", "error")
        return
    end

    ply.BloodActiveSlot = slot
    BLOOD.SQL.SetActiveSlot(ply:SteamID64(), slot)
    BLOOD.SetLocked(ply, false)
    ply:Spawn() -- respawn => ApplyRaceStats via le hook PlayerSpawn
    BLOOD.SyncPlayer(ply)
    BLOOD.Notify(ply, "Personnage " .. slot .. " sélectionné.", "info")
end)

----------------------------------------------------------------------
-- Création d'un slot (le joueur choisit le NOM ; spawn en Humain)
--   Le nom est définitif côté joueur (seul un admin peut renommer).
--   Le premier perso créé devient actif et déverrouille le joueur.
----------------------------------------------------------------------
net.Receive("blood_create_slot", function(_, ply)
    local slot = net.ReadUInt(8)
    local name = string.Trim(string.sub(net.ReadString() or "", 1, 32))
    if slot < 1 or slot > C.MaxSlots then return end

    if slot > C.FreeSlots and not ply.BloodPaidUnlocked then
        BLOOD.Notify(ply, "Slot payant verrouillé.", "error")
        return
    end
    if ply.BloodSlots and ply.BloodSlots[slot] then
        BLOOD.Notify(ply, "Ce slot existe déjà.", "error")
        return
    end
    if string.len(name) < 2 then
        BLOOD.Notify(ply, "Nom trop court (2 caractères minimum).", "error")
        return
    end

    local hadChar = BLOOD.HasCharacter(ply)

    BLOOD.SQL.CreateSlot(ply:SteamID64(), slot, name, "human")
    ply.BloodSlots = ply.BloodSlots or {}
    ply.BloodSlots[slot] = { name = name, race = "human" }

    if not hadChar then
        -- Premier personnage : devient actif, on déverrouille et on (re)spawn.
        ply.BloodActiveSlot = slot
        BLOOD.SQL.SetActiveSlot(ply:SteamID64(), slot)
        BLOOD.SetLocked(ply, false)
        ply:Spawn()
    end

    BLOOD.SyncPlayer(ply)
    BLOOD.Notify(ply, "Personnage « " .. name .. " » créé.", "info")
end)

----------------------------------------------------------------------
-- Le client redemande son état
----------------------------------------------------------------------
net.Receive("blood_request_sync", function(_, ply)
    BLOOD.SyncPlayer(ply)
end)

----------------------------------------------------------------------
-- Commandes chat : ouvrir le menu personnages (+ masquer du chat public)
----------------------------------------------------------------------
local playerMenuCmds = {
    ["!perso"] = true, ["/perso"] = true,
    ["!personnages"] = true, ["/personnages"] = true,
    ["!races"] = true, ["/races"] = true,
}

hook.Add("PlayerSay", "BLOOD_PlayerMenuCmd", function(ply, text)
    local cmd = string.lower(string.Trim(text))
    if playerMenuCmds[cmd] then
        BLOOD.SyncPlayer(ply)
        net.Start("blood_open_menu")
        net.Send(ply)
        return ""
    end
end)
