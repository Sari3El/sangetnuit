--[[-------------------------------------------------------------------------
    Sang et Nuit — Armurerie : ranger / récupérer (serveur)
      Coffre PAR PERSONNAGE (steamid64 + slot actif). Persiste même
      déconnecté : c'est de la SQL, pas un état en mémoire du joueur.
---------------------------------------------------------------------------]]

SARM = SARM or {}
local C = SARM.Config

local function notify(ply, msg, kind)
    if BLOOD and BLOOD.Notify then BLOOD.Notify(ply, msg, kind)
    else ply:ChatPrint("[Armurerie] " .. msg) end
end
SARM.Notify = notify

-- Le joueur est-il à portée d'une armurerie ?
function SARM.IsNearArmory(ply)
    if not IsValid(ply) then return false end
    for _, e in ipairs(ents.FindByClass("sang_armory")) do
        if IsValid(e) and ply:GetPos():Distance(e:GetPos()) <= C.OpenDist then
            return true
        end
    end
    return false
end

-- Envoie le contenu du coffre du slot actif au client (ouvre ou rafraîchit).
function SARM.Sync(ply)
    if not IsValid(ply) then return end
    local sid, slot = ply:SteamID64(), (ply.BloodActiveSlot or 1)
    local items = SARM.SQL.GetItems(sid, slot)

    net.Start("sang_armory_open")
        net.WriteUInt(slot, 8)
        net.WriteUInt(#items, 16)
        for _, it in ipairs(items) do
            net.WriteUInt(it.id, 32)
            net.WriteString(it.class)
            net.WriteInt(it.clip1, 32)
            net.WriteInt(it.clip2, 32)
        end
    net.Send(ply)
end

-- Ouvre l'armurerie (depuis l'entité).
function SARM.OpenArmory(ply, ent)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if ply.SArmNextOpen and CurTime() < ply.SArmNextOpen then return end
    ply.SArmNextOpen = CurTime() + 0.6
    ply:EmitSound(C.OpenSound)
    SARM.Sync(ply)
end

-- Redonne une arme stockée au joueur (avec ses munitions de chargeur).
-- S'il porte déjà une arme de cette classe, les munitions rejoignent sa
-- réserve au lieu d'être perdues.
local function giveBack(ply, it)
    local class = it.class
    if not class or class == "" then return false end

    local already = ply:HasWeapon(class)
    local wep = already and ply:GetWeapon(class) or ply:Give(class, false)
    if not IsValid(wep) then return false end

    if already then
        local ammoType = wep:GetPrimaryAmmoType()
        local total = math.max(0, it.clip1) + math.max(0, it.clip2)
        if ammoType and ammoType >= 0 and total > 0 then
            ply:GiveAmmo(total, ammoType, true)
        end
    else
        if it.clip1 and it.clip1 >= 0 then wep:SetClip1(it.clip1) end
        if it.clip2 and it.clip2 >= 0 then wep:SetClip2(it.clip2) end
    end
    return true
end

----------------------------------------------------------------------
-- Ranger UNE arme (celle indiquée par le client, doit être en main)
----------------------------------------------------------------------
SARM.NetReceive("sang_armory_store", 0.25, function(_, ply)
    local class = net.ReadString()
    if not SARM.IsNearArmory(ply) then notify(ply, "Approche-toi de l'armurerie.", "error") return end
    if not SARM.CanStore(class) then notify(ply, "Cette arme ne peut pas être rangée.", "error") return end

    local wep = ply:GetWeapon(class)
    if not IsValid(wep) then notify(ply, "Tu ne portes pas cette arme.", "error") return end

    local sid, slot = ply:SteamID64(), (ply.BloodActiveSlot or 1)
    if SARM.SQL.Count(sid, slot) >= C.MaxItems then
        notify(ply, "Le coffre est plein (" .. C.MaxItems .. " armes max).", "error")
        return
    end

    local clip1 = wep:Clip1()
    local clip2 = wep:Clip2()
    ply:StripWeapon(class)
    SARM.SQL.AddItem(sid, slot, class, clip1, clip2)

    notify(ply, "Arme rangée dans le coffre.", "info")
    SARM.Sync(ply)
end)

----------------------------------------------------------------------
-- Ranger TOUTES les armes portées
----------------------------------------------------------------------
SARM.NetReceive("sang_armory_store_all", 0.5, function(_, ply)
    if not SARM.IsNearArmory(ply) then notify(ply, "Approche-toi de l'armurerie.", "error") return end

    local sid, slot = ply:SteamID64(), (ply.BloodActiveSlot or 1)
    local stored = 0
    for _, wep in ipairs(ply:GetWeapons()) do
        if IsValid(wep) then
            local class = wep:GetClass()
            if SARM.CanStore(class) then
                if SARM.SQL.Count(sid, slot) >= C.MaxItems then break end
                SARM.SQL.AddItem(sid, slot, class, wep:Clip1(), wep:Clip2())
                ply:StripWeapon(class)
                stored = stored + 1
            end
        end
    end

    if stored > 0 then notify(ply, stored .. " arme(s) rangée(s).", "info")
    else notify(ply, "Rien à ranger.", "error") end
    SARM.Sync(ply)
end)

----------------------------------------------------------------------
-- Récupérer UNE arme
----------------------------------------------------------------------
SARM.NetReceive("sang_armory_retrieve", 0.25, function(_, ply)
    local id = net.ReadUInt(32)
    if not SARM.IsNearArmory(ply) then notify(ply, "Approche-toi de l'armurerie.", "error") return end

    local sid, slot = ply:SteamID64(), (ply.BloodActiveSlot or 1)
    local it = SARM.SQL.TakeItem(sid, slot, id)
    if not it then notify(ply, "Cette arme n'est plus dans le coffre.", "error") return end

    if not giveBack(ply, it) then
        SARM.SQL.AddItem(sid, slot, it.class, it.clip1, it.clip2) -- échec -> on la remet dans le coffre
        notify(ply, "Impossible de récupérer cette arme.", "error")
        SARM.Sync(ply)
        return
    end

    notify(ply, "Arme récupérée.", "info")
    SARM.Sync(ply)
end)

----------------------------------------------------------------------
-- Récupérer TOUT le contenu du coffre
----------------------------------------------------------------------
SARM.NetReceive("sang_armory_retrieve_all", 0.5, function(_, ply)
    if not SARM.IsNearArmory(ply) then notify(ply, "Approche-toi de l'armurerie.", "error") return end

    local sid, slot = ply:SteamID64(), (ply.BloodActiveSlot or 1)
    local items = SARM.SQL.TakeAll(sid, slot)
    local given = 0
    for _, it in ipairs(items) do
        if giveBack(ply, it) then
            given = given + 1
        else
            SARM.SQL.AddItem(sid, slot, it.class, it.clip1, it.clip2)
        end
    end

    if given > 0 then notify(ply, given .. " arme(s) récupérée(s).", "info")
    else notify(ply, "Le coffre est vide.", "error") end
    SARM.Sync(ply)
end)

SARM.NetReceive("sang_armory_reqsync", 0.5, function(_, ply)
    SARM.Sync(ply)
end)
