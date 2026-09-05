--[[-------------------------------------------------------------------------
    Sang et Nuit — Argent « Covan » (PAR PERSONNAGE / slot)
      Monnaie de jeu distincte des crédits de reroll et de l'or DarkRP.
      API à appeler depuis les futurs systèmes (boutiques, métiers, etc.).
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}

--- Covan du personnage actif (depuis le cache).
function BLOOD.GetCovan(ply)
    if not IsValid(ply) then return 0 end
    local slot = ply.BloodActiveSlot or 1
    local sd = ply.BloodSlots and ply.BloodSlots[slot]
    return (sd and sd.covan) or 0
end

--- Écrit un montant absolu sur le personnage actif.
function BLOOD.SetCovan(ply, amount)
    if not IsValid(ply) then return end
    local slot = ply.BloodActiveSlot or 1
    if not (ply.BloodSlots and ply.BloodSlots[slot]) then return end
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    ply.BloodSlots[slot].covan = amount
    BLOOD.SQL.SetCovan(ply:SteamID64(), slot, amount)
    ply:SetNWInt("blood_covan", amount)
    return amount
end

--- Ajoute (ou retire) des Covan au personnage actif. Renvoie le nouveau solde.
function BLOOD.AddCovan(ply, delta)
    return BLOOD.SetCovan(ply, BLOOD.GetCovan(ply) + (tonumber(delta) or 0))
end

--- Le joueur a-t-il au moins `amount` Covan (perso actif) ?
function BLOOD.CanAfford(ply, amount)
    return BLOOD.GetCovan(ply) >= (tonumber(amount) or 0)
end

--- Ajoute des Covan à un slot précis (marche hors-ligne). Renvoie le solde.
function BLOOD.AddCovanSlot(sid64, slot, delta)
    sid64 = tostring(sid64)
    slot = tonumber(slot)
    delta = math.floor(tonumber(delta) or 0)

    local ply = BLOOD.GetPlayerBySteamID64(sid64)
    if IsValid(ply) and (ply.BloodActiveSlot or 1) == slot then
        return BLOOD.AddCovan(ply, delta)
    end

    local new = math.max(0, BLOOD.SQL.GetCovan(sid64, slot) + delta)
    BLOOD.SQL.SetCovan(sid64, slot, new)
    if IsValid(ply) and ply.BloodSlots and ply.BloodSlots[slot] then
        ply.BloodSlots[slot].covan = new
        if (ply.BloodActiveSlot or 1) == slot then ply:SetNWInt("blood_covan", new) end
    end
    return new
end

--- Définit un montant absolu de Covan sur un slot (marche hors-ligne).
--  Renvoie le nouveau solde, ou nil si le slot n'existe pas.
function BLOOD.SetCovanSlot(sid64, slot, amount)
    sid64 = tostring(sid64)
    slot = tonumber(slot)
    amount = math.max(0, math.floor(tonumber(amount) or 0))

    local ply = BLOOD.GetPlayerBySteamID64(sid64)
    if IsValid(ply) and (ply.BloodActiveSlot or 1) == slot
       and ply.BloodSlots and ply.BloodSlots[slot] then
        return BLOOD.SetCovan(ply, amount)
    end

    if not BLOOD.SQL.GetSlot(sid64, slot) then return nil end
    BLOOD.SQL.SetCovan(sid64, slot, amount)
    if IsValid(ply) and ply.BloodSlots and ply.BloodSlots[slot] then
        ply.BloodSlots[slot].covan = amount
        if (ply.BloodActiveSlot or 1) == slot then ply:SetNWInt("blood_covan", amount) end
    end
    return amount
end

----------------------------------------------------------------------
-- Commande de test (admin) : donner des Covan
--   sang_givecovan me <montant>
--   sang_givecovan <steamid64> <montant> [slot]
----------------------------------------------------------------------
concommand.Add("sang_givecovan", function(ply, _, args)
    if IsValid(ply) and not BLOOD.IsAdmin(ply) then return end -- console serveur = autorisé

    local targetArg = args[1]
    local amount = math.floor(tonumber(args[2]) or 0)
    local slot = tonumber(args[3])

    local sid
    if targetArg == "me" and IsValid(ply) then
        sid = ply:SteamID64()
    else
        sid = BLOOD.NormalizeSteamID(targetArg or "")
    end
    if not sid then
        if IsValid(ply) then ply:ChatPrint("[Sang et Nuit] SteamID invalide.") else print("SteamID invalide.") end
        return
    end

    local target = BLOOD.GetPlayerBySteamID64(sid)
    local bal
    if IsValid(target) and not slot then
        bal = BLOOD.AddCovan(target, amount)
    else
        bal = BLOOD.AddCovanSlot(sid, slot or 1, amount)
    end

    local msg = "[Sang et Nuit] " .. amount .. " " .. BLOOD.Config.Currency .. " => " .. sid .. " (solde: " .. bal .. ")"
    if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end
end)
