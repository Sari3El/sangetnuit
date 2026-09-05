--[[-------------------------------------------------------------------------
    Sang et Nuit — Cycle de vie joueur, slots, synchro client
      - Chargement des données à la connexion
      - Application des stats au spawn
      - Sélection / création de slot
      - Commandes chat pour ouvrir le menu personnages
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
-- Synchro de l'état du joueur vers son client (pour le menu / HUD)
----------------------------------------------------------------------
function BLOOD.SyncPlayer(ply)
    if not IsValid(ply) then return end
    net.Start("blood_sync")
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
-- Chargement des données du joueur (connexion)
----------------------------------------------------------------------
function BLOOD.LoadPlayer(ply)
    if not IsValid(ply) then return end
    local sid = ply:SteamID64()
    BLOOD.SQL.EnsurePlayerRow(sid)

    -- Au moins un slot 1 (Humain par défaut)
    local slots = BLOOD.SQL.GetSlots(sid)
    if not slots[1] then
        BLOOD.SQL.CreateSlot(sid, 1, "Personnage 1", "human")
        slots = BLOOD.SQL.GetSlots(sid)
    end

    ply.BloodSlots        = slots
    ply.BloodCredits      = BLOOD.GetCredits(sid)
    ply.BloodActiveSlot   = BLOOD.SQL.GetActiveSlot(sid)
    ply.BloodPaidUnlocked = BLOOD.SQL.GetPaidUnlocked(sid)

    -- Slot actif incohérent => on retombe sur 1
    if not slots[ply.BloodActiveSlot] then
        ply.BloodActiveSlot = 1
        BLOOD.SQL.SetActiveSlot(sid, 1)
    end

    ply:SetNWInt("blood_credits", ply.BloodCredits)
end

hook.Add("PlayerInitialSpawn", "BLOOD_Init", function(ply)
    BLOOD.LoadPlayer(ply)
    -- Petit délai pour laisser le client se préparer avant la synchro.
    timer.Simple(1, function()
        if IsValid(ply) then BLOOD.SyncPlayer(ply) end
    end)
end)

hook.Add("PlayerSpawn", "BLOOD_Spawn", function(ply)
    if not ply.BloodSlots then BLOOD.LoadPlayer(ply) end
    -- Appliquer après le code de spawn du gamemode (DarkRP/Sandbox).
    timer.Simple(C.ApplyDelay, function()
        if IsValid(ply) and ply:Alive() then
            BLOOD.ApplyRaceStats(ply)
        end
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
    ply:Spawn() -- respawn => ApplyRaceStats via le hook PlayerSpawn
    BLOOD.SyncPlayer(ply)
    BLOOD.Notify(ply, "Personnage " .. slot .. " sélectionné.", "info")
end)

----------------------------------------------------------------------
-- Création d'un slot (spawn toujours en Humain)
----------------------------------------------------------------------
net.Receive("blood_create_slot", function(_, ply)
    local slot = net.ReadUInt(8)
    local name = string.sub(net.ReadString() or "", 1, 32)
    if slot < 1 or slot > C.MaxSlots then return end

    if slot > C.FreeSlots and not ply.BloodPaidUnlocked then
        BLOOD.Notify(ply, "Slot payant verrouillé.", "error")
        return
    end
    if ply.BloodSlots and ply.BloodSlots[slot] then
        BLOOD.Notify(ply, "Ce slot existe déjà.", "error")
        return
    end
    if string.Trim(name) == "" then name = "Personnage " .. slot end

    BLOOD.SQL.CreateSlot(ply:SteamID64(), slot, name, "human")
    ply.BloodSlots = ply.BloodSlots or {}
    ply.BloodSlots[slot] = { name = name, race = "human" }
    BLOOD.SyncPlayer(ply)
    BLOOD.Notify(ply, "Personnage créé (slot " .. slot .. ").", "info")
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
        return "" -- ne pas afficher dans le chat public
    end
end)
