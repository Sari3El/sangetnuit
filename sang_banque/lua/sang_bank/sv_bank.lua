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
net.Receive("sang_bank_deposit", function(_, ply)
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

    notify(ply, "Dépôt : " .. net_ .. " en banque (taxe " .. tax .. ").", "info")
    SBANK.Sync(ply)
end)

----------------------------------------------------------------------
-- Retrait
----------------------------------------------------------------------
net.Receive("sang_bank_withdraw", function(_, ply)
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

    notify(ply, "Retrait : " .. net_ .. " sur toi (taxe " .. tax .. ").", "info")
    SBANK.Sync(ply)
end)

net.Receive("sang_bank_reqsync", function(_, ply)
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
net.Receive("sang_bank_query", function(_, ply)
    if not (BLOOD and BLOOD.IsAdmin and BLOOD.IsAdmin(ply)) then return end
    local rawSid = net.ReadString()
    local slot = net.ReadUInt(8)
    local sid = BLOOD and BLOOD.NormalizeSteamID and BLOOD.NormalizeSteamID(rawSid) or nil
    if not sid or slot < 1 or slot > 4 then return end
    SBANK.SendQuery(ply, sid, slot, SBANK.GetPersonal(sid, slot))
end)
