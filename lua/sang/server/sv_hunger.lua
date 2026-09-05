--[[-------------------------------------------------------------------------
    Sang et Nuit — Faim (barre verticale du HUD)
      Valeur 0..HungerMax qui décroît avec le temps. API SetHunger/AddHunger
      à appeler par de futurs systèmes (nourriture, etc.).
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}
local C = BLOOD.Config

--- Écrit une valeur de faim (bornée) et la réseau.
function BLOOD.SetHunger(ply, v)
    if not IsValid(ply) then return end
    v = math.Clamp(math.floor(tonumber(v) or 0), 0, C.HungerMax)
    ply.BloodHunger = v
    ply:SetNWInt("blood_hunger", v)
    return v
end

--- Ajoute (ou retire) de la faim. Renvoie la nouvelle valeur.
function BLOOD.AddHunger(ply, d)
    return BLOOD.SetHunger(ply, (ply.BloodHunger or C.HungerMax) + (tonumber(d) or 0))
end

-- Initialisation à la connexion (faim pleine).
hook.Add("PlayerInitialSpawn", "BLOOD_HungerInit", function(ply)
    ply.BloodHunger = C.HungerMax
    timer.Simple(1, function()
        if IsValid(ply) then ply:SetNWInt("blood_hunger", ply.BloodHunger or C.HungerMax) end
    end)
end)

if C.HungerEnabled then
    -- Décroissance
    timer.Create("BLOOD_HungerDecay", C.HungerDecayInterval, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:Alive() and BLOOD.HasCharacter(ply) then
                BLOOD.SetHunger(ply, (ply.BloodHunger or C.HungerMax) - 1)
            end
        end
    end)

    -- Dégâts de faim (optionnel)
    if C.HungerStarveDamage > 0 then
        timer.Create("BLOOD_Starve", C.HungerStarveInterval, 0, function()
            for _, ply in ipairs(player.GetAll()) do
                if IsValid(ply) and ply:Alive() and (ply.BloodHunger or C.HungerMax) <= 0 then
                    ply:TakeDamage(C.HungerStarveDamage)
                end
            end
        end)
    end
end

----------------------------------------------------------------------
-- Commande de test (admin) : régler la faim
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
