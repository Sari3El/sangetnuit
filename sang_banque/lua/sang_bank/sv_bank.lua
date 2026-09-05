--[[-------------------------------------------------------------------------
    Sang et Nuit — Banque : dépôt / retrait (serveur)
      Banque perso par personnage. Taxe au dépôt ET au retrait -> Guilde.
---------------------------------------------------------------------------]]

SBANK = SBANK or {}
local C = SBANK.Config

local function notify(ply, msg, kind)
    if BLOOD and BLOOD.Notify then BLOOD.Notify(ply, msg, kind)
    else ply:ChatPrint("[Banque] " .. msg) end
end
SBANK.Notify = notify

-- Enregistre une action dans l'historique persistant (100 dernières).
function SBANK.LogHistory(e)
    if SBANK.SQL and SBANK.SQL.AddHistory then SBANK.SQL.AddHistory(e) end
end

-- Le joueur est-il à portée d'une banque ?
function SBANK.IsNearBank(ply)
    if not IsValid(ply) then return false end
    for _, e in ipairs(ents.FindByClass("sang_bank")) do
        if IsValid(e) and ply:GetPos():Distance(e:GetPos()) <= C.OpenDist then
            return true
        end
    end
    return false
end

-- Envoie l'état de la banque au client (ouvre ou rafraîchit le menu).
function SBANK.Sync(ply)
    if not IsValid(ply) then return end
    local sid = ply:SteamID64()
    local slot = ply.BloodActiveSlot or 1
    net.Start("sang_bank_open")
        net.WriteUInt(SBANK.GetPersonal(sid, slot), 32)
        net.WriteUInt(SBANK.GetTax("personal"), 8)
        net.WriteUInt(SBANK.GetTax("faction"), 8)
        net.WriteUInt(SBANK.GetFaction("monstre"), 32)
        net.WriteUInt(SBANK.GetFaction("humain"), 32)
        net.WriteUInt(SBANK.GetFaction("guilde"), 32)
        net.WriteBool((BLOOD and BLOOD.IsAdmin and BLOOD.IsAdmin(ply)) or false)
    net.Send(ply)
end

-- Ouvre la banque (depuis l'entité).
function SBANK.OpenBank(ply, ent)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if ply.SBankNextOpen and CurTime() < ply.SBankNextOpen then return end
    ply.SBankNextOpen = CurTime() + 0.6
    ply:EmitSound(C.OpenSound)
    SBANK.Sync(ply)
end

----------------------------------------------------------------------
-- Dépôt
----------------------------------------------------------------------
SBANK.NetReceive("sang_bank_deposit", 0.4, function(_, ply)
    local amount = net.ReadUInt(32)
    if amount <= 0 then return end
    if not SBANK.IsNearBank(ply) then notify(ply, "Approche-toi d'une banque.", "error") return end
    if not (BLOOD and BLOOD.GetCovan) then return end

    local wallet = BLOOD.GetCovan(ply)
    if wallet < amount then
        notify(ply, "Pas assez d'argent sur toi.", "error")
        return
    end

    local sid, slot = ply:SteamID64(), (ply.BloodActiveSlot or 1)
    local tax = math.floor(amount * SBANK.GetTax("personal") / 100)
    local net_ = amount - tax

    BLOOD.AddCovan(ply, -amount)
    SBANK.AddPersonal(sid, slot, net_)
    if tax > 0 then SBANK.AddFaction(C.TaxBank, tax) end

    SBANK.LogHistory({
        action = "depot", actor = sid, actor_name = ply:Nick(),
        target = sid, slot = slot, amount = net_,
        detail = (tax > 0 and ("taxe " .. tax) or ""),
    })

    notify(ply, "Dépôt : " .. net_ .. " en banque (taxe " .. tax .. ").", "info")
    SBANK.Sync(ply)
end)

----------------------------------------------------------------------
-- Retrait
----------------------------------------------------------------------
SBANK.NetReceive("sang_bank_withdraw", 0.4, function(_, ply)
    local amount = net.ReadUInt(32)
    if amount <= 0 then return end
    if not SBANK.IsNearBank(ply) then notify(ply, "Approche-toi d'une banque.", "error") return end
    if not (BLOOD and BLOOD.AddCovan) then return end

    local sid, slot = ply:SteamID64(), (ply.BloodActiveSlot or 1)
    local bal = SBANK.GetPersonal(sid, slot)
    if bal < amount then
        notify(ply, "Pas assez en banque.", "error")
        return
    end

    local tax = math.floor(amount * SBANK.GetTax("personal") / 100)
    local net_ = amount - tax

    SBANK.AddPersonal(sid, slot, -amount)
    BLOOD.AddCovan(ply, net_)
    if tax > 0 then SBANK.AddFaction(C.TaxBank, tax) end

    SBANK.LogHistory({
        action = "retrait", actor = sid, actor_name = ply:Nick(),
        target = sid, slot = slot, amount = -amount,
        detail = (tax > 0 and ("net " .. net_ .. ", taxe " .. tax) or ""),
    })

    notify(ply, "Retrait : " .. net_ .. " sur toi (taxe " .. tax .. ").", "info")
    SBANK.Sync(ply)
end)

----------------------------------------------------------------------
-- Dépôt dans SA banque de faction (les membres Guilde/Monstre/Humanité
-- peuvent voir le solde et DÉPOSER, mais jamais retirer).
----------------------------------------------------------------------
SBANK.NetReceive("sang_bank_facdeposit", 0.4, function(_, ply)
    local amount = net.ReadUInt(32)
    if amount <= 0 then return end
    if not SBANK.IsNearBank(ply) then notify(ply, "Approche-toi d'une banque.", "error") return end
    if not (BLOOD and BLOOD.GetCovan) then return end

    -- Faction du joueur (posée par sang_jobs) ; doit être une vraie faction.
    local fac = ply:GetNWString("sang_faction", "none")
    if not C.FactionNames[fac] then
        notify(ply, "Tu n'appartiens à aucune faction.", "error")
        return
    end

    local wallet = BLOOD.GetCovan(ply)
    if wallet < amount then
        notify(ply, "Pas assez d'argent sur toi.", "error")
        return
    end

    local tax = math.floor(amount * SBANK.GetTax("faction") / 100)
    local net_ = amount - tax

    BLOOD.AddCovan(ply, -amount)
    SBANK.AddFaction(fac, net_)
    if tax > 0 then SBANK.AddFaction(C.TaxBank, tax) end
    local bal = SBANK.GetFaction(fac)

    SBANK.LogHistory({
        action = "depot_faction", actor = ply:SteamID64(), actor_name = ply:Nick(),
        target = fac, slot = 0, amount = net_,
        detail = (tax > 0 and ("taxe " .. tax) or ""),
    })

    notify(ply, "Déposé " .. net_ .. " dans la banque " .. C.FactionNames[fac] .. " (taxe " .. tax .. ").", "info")
    SBANK.Sync(ply)
end)

SBANK.NetReceive("sang_bank_reqsync", 0.5, function(_, ply)
    SBANK.Sync(ply)
end)

-- Envoie le solde bancaire d'un (sid, slot) à un admin.
function SBANK.SendQuery(ply, sid, slot, amount)
    if not IsValid(ply) then return end
    if amount == nil then amount = SBANK.GetPersonal(sid, slot) end
    net.Start("sang_bank_queryresult")
        net.WriteString(tostring(sid))
        net.WriteUInt(tonumber(slot) or 1, 8)
        net.WriteUInt(math.max(0, math.floor(amount)), 32)
    net.Send(ply)
end

-- L'admin demande le solde d'un joueur/slot.
SBANK.NetReceive("sang_bank_query", 0.15, function(_, ply)
    if not (BLOOD and BLOOD.IsAdmin and BLOOD.IsAdmin(ply)) then return end
    local rawSid = net.ReadString()
    local slot = net.ReadUInt(8)
    local sid = BLOOD and BLOOD.NormalizeSteamID and BLOOD.NormalizeSteamID(rawSid) or nil
    if not sid or slot < 1 or slot > 4 then return end
    SBANK.SendQuery(ply, sid, slot, SBANK.GetPersonal(sid, slot))
end)

----------------------------------------------------------------------
-- Historique (admin uniquement) : envoie les 100 dernières actions
----------------------------------------------------------------------
SBANK.NetReceive("sang_bank_hist_req", 0.5, function(_, ply)
    if not (BLOOD and BLOOD.IsAdmin and BLOOD.IsAdmin(ply)) then return end
    local list = (SBANK.SQL and SBANK.SQL.GetHistory) and SBANK.SQL.GetHistory() or {}

    net.Start("sang_bank_hist_data")
        net.WriteUInt(#list, 8) -- <= 100
        for _, h in ipairs(list) do
            net.WriteUInt(math.max(0, h.ts or 0), 32)
            net.WriteString(h.action or "")
            net.WriteString(h.actor_name or "")
            net.WriteString(h.target or "")
            net.WriteUInt(math.Clamp(h.slot or 0, 0, 255), 8)
            net.WriteInt(math.Clamp(h.amount or 0, -2147483647, 2147483647), 32)
            net.WriteString(string.sub(h.detail or "", 1, 64))
        end
    net.Send(ply)
end)
