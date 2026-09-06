--[[-------------------------------------------------------------------------
    Sang et Nuit — Mana (serveur)
      Réservoir de mana par joueur (max = config « Stats forcées »). API pour
      les sorts (consommation) + régénération passive. Le HUD lit blood_mana /
      blood_mana_max (variables réseau).
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}
local C = BLOOD.Config

--- Réservoir max (posé par BLOOD.ApplyComputedStats depuis la config).
function BLOOD.GetMaxMana(ply)
    if not IsValid(ply) then return 0 end
    return ply:GetNWInt("blood_mana_max", 0)
end

--- Mana courante.
function BLOOD.GetMana(ply)
    if not IsValid(ply) then return 0 end
    return math.Clamp(ply.BloodMana or BLOOD.GetMaxMana(ply), 0, BLOOD.GetMaxMana(ply))
end

--- Écrit une valeur absolue de mana (bornée 0..max) + réseau.
function BLOOD.SetMana(ply, v)
    if not IsValid(ply) then return 0 end
    local mx = BLOOD.GetMaxMana(ply)
    v = math.Clamp(math.floor(tonumber(v) or 0), 0, mx)
    ply.BloodMana = v
    ply:SetNWInt("blood_mana", v)
    return v
end

--- A-t-il au moins `amount` de mana ?
function BLOOD.HasMana(ply, amount)
    return BLOOD.GetMana(ply) >= (tonumber(amount) or 0)
end

--- Consomme `amount` de mana. Renvoie true si débité, false si insuffisant.
function BLOOD.TakeMana(ply, amount)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if BLOOD.GetMana(ply) < amount then return false end
    BLOOD.SetMana(ply, BLOOD.GetMana(ply) - amount)
    return true
end

--- Ajoute de la mana (borné au max). Renvoie le nouveau solde.
function BLOOD.AddMana(ply, amount)
    return BLOOD.SetMana(ply, BLOOD.GetMana(ply) + (tonumber(amount) or 0))
end

----------------------------------------------------------------------
-- Régénération passive
----------------------------------------------------------------------
timer.Create("BLOOD_ManaRegen", math.max(0.5, C.ManaRegenInterval or 2), 0, function()
    local add = math.max(0, C.ManaRegenAmount or 5)
    if add <= 0 then return end
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() then
            local mx = BLOOD.GetMaxMana(ply)
            if mx > 0 and BLOOD.GetMana(ply) < mx then
                BLOOD.AddMana(ply, add)
            end
        end
    end
end)
