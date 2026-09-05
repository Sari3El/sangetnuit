--[[-------------------------------------------------------------------------
    Sang et Nuit — Menu admin "!origines"

    Sécurité (cf. cahier des charges §8) :
      - Whitelist SteamID64 vérifiée SERVEUR-SIDE à CHAQUE action (pas juste
        à l'ouverture du menu).
      - Commande "!origines" (et "/origines") avalée silencieusement : jamais
        affichée dans le chat, aucun message d'erreur pour les non-autorisés.
      - Chaque action loggée (qui / quoi / sur qui / quand).
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}
local C = BLOOD.Config

----------------------------------------------------------------------
-- Whitelist
----------------------------------------------------------------------
function BLOOD.IsAdmin(ply)
    if not IsValid(ply) then return false end
    if C.Admins[ply:SteamID64()] then return true end
    if C.AllowSuperAdmin and ply:IsSuperAdmin() then return true end
    return false
end

----------------------------------------------------------------------
-- Log admin (console + fichier data/sang/admin_log.txt)
----------------------------------------------------------------------
local function logAdmin(line)
    local full = "[" .. os.date("%Y-%m-%d %H:%M:%S") .. "] " .. line
    MsgN("[Sang et Nuit][ADMIN] " .. line)
    if not file.IsDir("sang", "DATA") then file.CreateDir("sang") end
    file.Append("sang/admin_log.txt", full .. "\n")
end
BLOOD.LogAdmin = logAdmin

----------------------------------------------------------------------
-- Commande "!origines"
----------------------------------------------------------------------
hook.Add("PlayerSay", "BLOOD_Origines", function(ply, text)
    local cmd = string.lower(string.Trim(text))
    if cmd == "!origines" or cmd == "/origines" then
        if BLOOD.IsAdmin(ply) then
            net.Start("blood_open_admin")
                net.WriteUInt(#BLOOD.Config.Races, 8)
                for _, r in ipairs(BLOOD.Config.Races) do
                    net.WriteString(r.id)
                    net.WriteString(r.name)
                end
            net.Send(ply)
        end
        -- Toujours avaler la commande (aucun message public, aucun retour).
        return ""
    end
end)

----------------------------------------------------------------------
-- Action : donner des crédits (fonctionne hors-ligne)
----------------------------------------------------------------------
net.Receive("origines_give_credits", function(_, ply)
    if not BLOOD.IsAdmin(ply) then
        logAdmin("REFUS give_credits de " .. ply:Nick() .. " (" .. ply:SteamID64() .. ") — non autorisé")
        return
    end

    local rawSid = net.ReadString()
    local amount = net.ReadInt(32)
    local sid = BLOOD.NormalizeSteamID(rawSid)

    if not sid then
        BLOOD.Notify(ply, "SteamID cible invalide.", "error")
        return
    end
    amount = math.Clamp(math.floor(amount or 0), -100000, 100000)

    local newBal = BLOOD.AddCredits(sid, amount)
    logAdmin(ply:Nick() .. " (" .. ply:SteamID64() .. ") a donné " .. amount
        .. " crédit(s) à " .. sid .. " (nouveau solde: " .. newBal .. ")")
    BLOOD.Notify(ply, "Crédits mis à jour : " .. sid .. " => " .. newBal .. ".", "info")
end)

----------------------------------------------------------------------
-- Action : définir une race sur un slot (contourne tirage + paiement)
--   Fonctionne aussi hors-ligne (écriture SQL directe).
----------------------------------------------------------------------
net.Receive("origines_set_race", function(_, ply)
    if not BLOOD.IsAdmin(ply) then
        logAdmin("REFUS set_race de " .. ply:Nick() .. " (" .. ply:SteamID64() .. ") — non autorisé")
        return
    end

    local rawSid = net.ReadString()
    local slot   = net.ReadUInt(8)
    local raceId = net.ReadString()
    local sid = BLOOD.NormalizeSteamID(rawSid)

    if not sid then
        BLOOD.Notify(ply, "SteamID cible invalide.", "error")
        return
    end
    if slot < 1 or slot > C.MaxSlots then
        BLOOD.Notify(ply, "Slot invalide (1-" .. C.MaxSlots .. ").", "error")
        return
    end
    if not BLOOD.RaceExists(raceId) then
        BLOOD.Notify(ply, "Race invalide.", "error")
        return
    end

    local target = BLOOD.GetPlayerBySteamID64(sid)
    if IsValid(target) then
        target.BloodSlots = target.BloodSlots or {}
        if not target.BloodSlots[slot] then
            BLOOD.SQL.CreateSlot(sid, slot, "Personnage " .. slot, raceId)
            target.BloodSlots[slot] = { name = "Personnage " .. slot, race = raceId }
        end
        BLOOD.SetRace(target, slot, raceId) -- applique si c'est son slot actif
    else
        BLOOD.SetRaceOffline(sid, slot, raceId)
    end

    logAdmin(ply:Nick() .. " (" .. ply:SteamID64() .. ") a défini la race '" .. raceId
        .. "' sur le slot " .. slot .. " de " .. sid)
    BLOOD.Notify(ply, "Race définie : " .. sid .. " slot " .. slot .. " => " .. raceId .. ".", "info")
end)

----------------------------------------------------------------------
-- Action : renommer un slot (marche hors-ligne ; slot existant uniquement)
----------------------------------------------------------------------
net.Receive("origines_rename_slot", function(_, ply)
    if not BLOOD.IsAdmin(ply) then
        logAdmin("REFUS rename_slot de " .. ply:Nick() .. " (" .. ply:SteamID64() .. ") — non autorisé")
        return
    end

    local rawSid = net.ReadString()
    local slot   = net.ReadUInt(8)
    local name   = string.Trim(string.sub(net.ReadString() or "", 1, 32))
    local sid = BLOOD.NormalizeSteamID(rawSid)

    if not sid then BLOOD.Notify(ply, "SteamID cible invalide.", "error") return end
    if slot < 1 or slot > C.MaxSlots then BLOOD.Notify(ply, "Slot invalide.", "error") return end
    if string.len(name) < 2 then BLOOD.Notify(ply, "Nom trop court (2 caractères min).", "error") return end

    local target = BLOOD.GetPlayerBySteamID64(sid)
    local ok
    if IsValid(target) then
        ok = BLOOD.SetSlotName(target, slot, name)
    else
        if BLOOD.SQL.GetSlot(sid, slot) then
            BLOOD.SQL.SetSlotName(sid, slot, name)
            ok = true
        end
    end

    if not ok then
        BLOOD.Notify(ply, "Ce slot est vide (rien à renommer).", "error")
        return
    end

    logAdmin(ply:Nick() .. " (" .. ply:SteamID64() .. ") a renommé le slot " .. slot
        .. " de " .. sid .. " en « " .. name .. " »")
    BLOOD.Notify(ply, "Slot renommé : " .. sid .. " slot " .. slot .. " => « " .. name .. " ».", "info")
end)

----------------------------------------------------------------------
-- Action : débloquer / verrouiller le slot payant (marche hors-ligne)
----------------------------------------------------------------------
net.Receive("origines_set_paid", function(_, ply)
    if not BLOOD.IsAdmin(ply) then
        logAdmin("REFUS set_paid de " .. ply:Nick() .. " (" .. ply:SteamID64() .. ") — non autorisé")
        return
    end

    local rawSid   = net.ReadString()
    local unlocked = net.ReadBool()
    local sid = BLOOD.NormalizeSteamID(rawSid)

    if not sid then BLOOD.Notify(ply, "SteamID cible invalide.", "error") return end

    BLOOD.SetPaidSlotUnlocked(sid, unlocked)
    logAdmin(ply:Nick() .. " (" .. ply:SteamID64() .. ") a "
        .. (unlocked and "débloqué" or "verrouillé") .. " le slot payant de " .. sid)
    BLOOD.Notify(ply, "Slot payant " .. (unlocked and "débloqué" or "verrouillé")
        .. " pour " .. sid .. ".", "info")
end)

----------------------------------------------------------------------
-- Action : définir / ajouter des Covan sur un slot (marche hors-ligne)
----------------------------------------------------------------------
net.Receive("origines_set_covan", function(_, ply)
    if not BLOOD.IsAdmin(ply) then
        logAdmin("REFUS set_covan de " .. ply:Nick() .. " (" .. ply:SteamID64() .. ") — non autorisé")
        return
    end

    local rawSid = net.ReadString()
    local slot   = net.ReadUInt(8)
    local amount = net.ReadInt(32)
    local isAdd  = net.ReadBool()
    local sid = BLOOD.NormalizeSteamID(rawSid)

    if not sid then BLOOD.Notify(ply, "SteamID cible invalide.", "error") return end
    if slot < 1 or slot > C.MaxSlots then BLOOD.Notify(ply, "Slot invalide.", "error") return end

    -- Le slot doit exister
    local target = BLOOD.GetPlayerBySteamID64(sid)
    local exists
    if IsValid(target) then
        exists = target.BloodSlots and target.BloodSlots[slot] ~= nil
    else
        exists = BLOOD.SQL.GetSlot(sid, slot) ~= nil
    end
    if not exists then
        BLOOD.Notify(ply, "Ce slot est vide.", "error")
        return
    end

    local bal
    if isAdd then
        bal = BLOOD.AddCovanSlot(sid, slot, amount)
    else
        bal = BLOOD.SetCovanSlot(sid, slot, amount)
    end

    logAdmin(ply:Nick() .. " (" .. ply:SteamID64() .. ") a "
        .. (isAdd and ("ajouté " .. amount) or ("défini à " .. amount))
        .. " " .. BLOOD.Config.Currency .. " sur le slot " .. slot .. " de " .. sid
        .. " (solde: " .. tostring(bal) .. ")")
    BLOOD.Notify(ply, "Covan " .. (isAdd and "ajoutés" or "définis") .. " : "
        .. sid .. " slot " .. slot .. " => " .. tostring(bal) .. ".", "info")
end)
