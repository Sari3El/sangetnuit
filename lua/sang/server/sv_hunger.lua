--[[-------------------------------------------------------------------------
    Sang et Nuit — Faim (PAR PERSONNAGE / slot)
      Valeur 0..HungerMax stockée dans le slot (comme le Covan). Elle décroît
      avec le temps sur le personnage ACTIF, est sauvegardée en SQL, et
      restaurée quand on revient sur un personnage.
      API SetHunger/AddHunger pour de futurs systèmes (nourriture...).
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}
local C = BLOOD.Config

--- Faim du personnage actif (depuis le cache).
function BLOOD.GetHunger(ply)
    if not IsValid(ply) then return C.HungerMax end
    local slot = ply.BloodActiveSlot or 1
    local sd = ply.BloodSlots and ply.BloodSlots[slot]
    return (sd and sd.hunger) or C.HungerMax
end

--- Écrit la faim du personnage actif (cache + réseau + SQL).
function BLOOD.SetHunger(ply, v)
    if not IsValid(ply) then return end
    local slot = ply.BloodActiveSlot or 1
    local sd = ply.BloodSlots and ply.BloodSlots[slot]
    if not sd then return end -- pas de personnage actif
    v = math.Clamp(math.floor(tonumber(v) or 0), 0, C.HungerMax)
    sd.hunger = v
    ply.BloodHunger = v
    ply:SetNWInt("blood_hunger", v)
    BLOOD.SQL.SetHunger(ply:SteamID64(), slot, v)
    return v
end

--- Ajoute (ou retire) de la faim au personnage actif.
function BLOOD.AddHunger(ply, d)
    return BLOOD.SetHunger(ply, BLOOD.GetHunger(ply) + (tonumber(d) or 0))
end

--- Pousse la faim du slot actif vers le client (spawn / changement de perso).
function BLOOD.SyncHungerNW(ply)
    if not IsValid(ply) then return end
    local v = BLOOD.GetHunger(ply)
    ply.BloodHunger = v
    ply:SetNWInt("blood_hunger", v)
end

if C.HungerEnabled then
    -- Décroissance du personnage actif uniquement (sauvegardée en SQL).
    timer.Create("BLOOD_HungerDecay", C.HungerDecayInterval, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:Alive() and BLOOD.HasCharacter(ply) then
                BLOOD.AddHunger(ply, -1)
            end
        end
    end)

    -- Dégâts de faim (optionnel)
    if C.HungerStarveDamage > 0 then
        timer.Create("BLOOD_Starve", C.HungerStarveInterval, 0, function()
            for _, ply in ipairs(player.GetAll()) do
                if IsValid(ply) and ply:Alive() and BLOOD.HasCharacter(ply)
                   and BLOOD.GetHunger(ply) <= 0 then
                    ply:TakeDamage(C.HungerStarveDamage)
                end
            end
        end)
    end
end

----------------------------------------------------------------------
-- Commande de test (admin) : régler la faim du personnage actif
--   sang_sethunger me <valeur>
--   sang_sethunger <steamid64> <valeur>
----------------------------------------------------------------------
concommand.Add("sang_sethunger", function(ply, _, args)
    if IsValid(ply) and not BLOOD.IsAdmin(ply) then return end

    local targetArg = args[1]
    local value = tonumber(args[2])
    if not value then return end

    local target
    if targetArg == "me" and IsValid(ply) then
        target = ply
    else
        local sid = BLOOD.NormalizeSteamID(targetArg or "")
        target = sid and BLOOD.GetPlayerBySteamID64(sid) or nil
    end
    if IsValid(target) then BLOOD.SetHunger(target, value) end
end)
