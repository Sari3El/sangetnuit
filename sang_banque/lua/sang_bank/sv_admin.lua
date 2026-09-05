--[[-------------------------------------------------------------------------
    Sang et Nuit — Banque : actions admin (serveur)
      Réglage des taxes, gestion des banques de faction et des banques
      joueurs. Whitelist re-vérifiée à chaque action (BLOOD.IsAdmin).
---------------------------------------------------------------------------]]

SBANK = SBANK or {}
local C = SBANK.Config

local function isAdmin(ply)
    return BLOOD and BLOOD.IsAdmin and BLOOD.IsAdmin(ply)
end

local function log(ply, line)
    local msg = "[Sang Banque][ADMIN] " .. ply:Nick() .. " (" .. ply:SteamID64() .. ") " .. line
    MsgN(msg)
    if BLOOD and BLOOD.LogAdmin then BLOOD.LogAdmin("[BANQUE] " .. ply:Nick() .. " (" .. ply:SteamID64() .. ") " .. line) end
end

----------------------------------------------------------------------
-- Régler une taxe (personal / faction)
----------------------------------------------------------------------
SBANK.NetReceive("sang_bank_settax", 0.3, function(_, ply)
    if not isAdmin(ply) then return end
    local kind = net.ReadString()
    local value = net.ReadUInt(8)
    if kind ~= "personal" and kind ~= "faction" then return end

    local v = SBANK.SetTax(kind, value)
    log(ply, "a réglé la taxe " .. kind .. " à " .. v .. "%")
    if SBANK.LogHistory then
        SBANK.LogHistory({
            action = "taxe", actor = ply:SteamID64(), actor_name = ply:Nick(),
            target = "", slot = 0, amount = 0,
            detail = "taxe " .. kind .. " = " .. v .. "%",
        })
    end
    SBANK.Notify(ply, "Taxe " .. kind .. " = " .. v .. "%.", "info")
    SBANK.Sync(ply)
end)

----------------------------------------------------------------------
-- Ajouter / retirer sur une banque de faction
--   L'argent est LIÉ au Covan de l'admin qui agit :
--     - déposer (delta > 0) prend l'or SUR L'ADMIN (refus si fonds insuffisants) ;
--     - retirer (delta < 0) met l'or SUR L'ADMIN (borné au solde de la banque).
----------------------------------------------------------------------
local cur = (BLOOD and BLOOD.Config and BLOOD.Config.Currency) or "Covan"

SBANK.NetReceive("sang_bank_setfaction", 0.3, function(_, ply)
    if not isAdmin(ply) then return end
    local fac = net.ReadString()
    local delta = net.ReadInt(32)
    if not C.FactionNames[fac] then return end
    if delta == 0 then return end

    local applied, bal
    if delta > 0 then
        -- DÉPÔT : prend l'or sur l'admin.
        local wallet = (BLOOD and BLOOD.GetCovan) and BLOOD.GetCovan(ply) or 0
        if wallet < delta then
            SBANK.Notify(ply, "Fonds insuffisants : il te faut " .. string.Comma(delta) .. " " .. cur
                .. " sur toi (tu as " .. string.Comma(wallet) .. ").", "error")
            return
        end
        BLOOD.AddCovan(ply, -delta)
        bal = SBANK.AddFaction(fac, delta)
        applied = delta
        SBANK.Notify(ply, "Déposé " .. string.Comma(delta) .. " (depuis ton or). Banque "
            .. C.FactionNames[fac] .. " = " .. string.Comma(bal) .. ".", "info")
    else
        -- RETRAIT : met l'or sur l'admin (borné au solde).
        local take = math.min(-delta, SBANK.GetFaction(fac))
        if take <= 0 then
            SBANK.Notify(ply, "Banque " .. C.FactionNames[fac] .. " vide.", "error")
            return
        end
        SBANK.AddFaction(fac, -take)
        if BLOOD and BLOOD.AddCovan then BLOOD.AddCovan(ply, take) end
        bal = SBANK.GetFaction(fac)
        applied = -take
        SBANK.Notify(ply, "Retiré " .. string.Comma(take) .. " (mis sur toi). Banque "
            .. C.FactionNames[fac] .. " = " .. string.Comma(bal) .. ".", "info")
    end

    log(ply, "a modifié la banque " .. fac .. " de " .. applied .. " (solde: " .. bal .. ", or lié à son perso)")
    if SBANK.LogHistory then
        SBANK.LogHistory({
            action = "admin_faction", actor = ply:SteamID64(), actor_name = ply:Nick(),
            target = fac, slot = 0, amount = applied,
            detail = "solde " .. bal,
        })
    end
    SBANK.Sync(ply)
end)

----------------------------------------------------------------------
-- Ajouter / retirer sur la banque perso d'un joueur (par slot)
----------------------------------------------------------------------
SBANK.NetReceive("sang_bank_setplayer", 0.3, function(_, ply)
    if not isAdmin(ply) then return end
    local rawSid = net.ReadString()
    local slot = net.ReadUInt(8)
    local delta = net.ReadInt(32)

    local sid = BLOOD and BLOOD.NormalizeSteamID and BLOOD.NormalizeSteamID(rawSid) or nil
    if not sid then SBANK.Notify(ply, "SteamID invalide.", "error") return end
    if slot < 1 or slot > 4 then SBANK.Notify(ply, "Slot invalide.", "error") return end

    if delta == 0 then return end

    local bal
    local applied = 0
    if delta < 0 then
        -- RETRAIT : borné au solde dispo, et l'argent est mis SUR TOI (admin).
        local take = math.min(-delta, SBANK.GetPersonal(sid, slot))
        if take <= 0 then
            SBANK.Notify(ply, "Cette banque est vide.", "error")
            return
        end
        SBANK.AddPersonal(sid, slot, -take)
        if BLOOD and BLOOD.AddCovan then BLOOD.AddCovan(ply, take) end
        applied = -take
        bal = SBANK.GetPersonal(sid, slot)
        log(ply, "a retiré " .. take .. " de la banque de " .. sid .. " slot " .. slot .. " (mis sur lui ; solde: " .. bal .. ")")
        SBANK.Notify(ply, "Retiré " .. string.Comma(take) .. " (mis sur toi). Banque " .. sid .. " slot " .. slot .. " = " .. string.Comma(bal) .. ".", "info")
    else
        -- AJOUT : l'or est PRIS SUR L'ADMIN (refus si fonds insuffisants).
        local wallet = (BLOOD and BLOOD.GetCovan) and BLOOD.GetCovan(ply) or 0
        if wallet < delta then
            SBANK.Notify(ply, "Fonds insuffisants : il te faut " .. string.Comma(delta) .. " " .. cur
                .. " sur toi (tu as " .. string.Comma(wallet) .. ").", "error")
            return
        end
        BLOOD.AddCovan(ply, -delta)
        bal = SBANK.AddPersonal(sid, slot, delta)
        applied = delta
        log(ply, "a ajouté " .. delta .. " sur la banque de " .. sid .. " slot " .. slot .. " (depuis son or ; solde: " .. bal .. ")")
        SBANK.Notify(ply, "Déposé " .. string.Comma(delta) .. " (depuis ton or). Banque " .. sid .. " slot " .. slot .. " = " .. string.Comma(bal) .. ".", "info")
    end

    if SBANK.LogHistory and applied ~= 0 then
        SBANK.LogHistory({
            action = "admin_joueur", actor = ply:SteamID64(), actor_name = ply:Nick(),
            target = sid, slot = slot, amount = applied,
            detail = "solde " .. bal,
        })
    end

    SBANK.SendQuery(ply, sid, slot, bal)
    SBANK.Sync(ply)
end)
