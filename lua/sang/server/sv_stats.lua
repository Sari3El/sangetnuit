--[[-------------------------------------------------------------------------
    Sang et Nuit — Effets de combat & passifs
      - Réduction / bonus / malus de dégâts
      - Esquive
      - Résistances (feu, magie)
      - Régénération passive
      - Discrétion (bruits de pas)
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}
local C = BLOOD.Config

-- Race active d'un joueur (nil si non joueur / invalide)
local function raceOf(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return nil end
    return BLOOD.GetRace(BLOOD.GetActiveRaceId(ply))
end
BLOOD.RaceOfPlayer = raceOf

-- Un des tags de l'arme correspond-il à un des tags de la règle ?
local function tagsMatch(weaponTags, ruleTags)
    for _, rt in ipairs(ruleTags) do
        for _, wt in ipairs(weaponTags) do
            if wt == rt then return true end
        end
    end
    return false
end

----------------------------------------------------------------------
-- EntityTakeDamage : bonus attaquant + défenses victime
----------------------------------------------------------------------
hook.Add("EntityTakeDamage", "BLOOD_Damage", function(target, dmginfo)
    -- 1) Bonus / malus de dégâts de l'ATTAQUANT (selon l'arme tenue)
    local att = dmginfo:GetAttacker()
    if IsValid(att) and att:IsPlayer() then
        local ar = raceOf(att)
        if ar and ar.dmgBonus then
            local wep = att:GetActiveWeapon()
            local cls = IsValid(wep) and wep:GetClass() or ""
            local wtags = BLOOD.GetWeaponTags(cls)
            if #wtags > 0 then
                for _, rule in ipairs(ar.dmgBonus) do
                    if tagsMatch(wtags, rule.tags) then
                        dmginfo:ScaleDamage(rule.mult)
                    end
                end
            end
        end
    end

    -- 2) Défenses de la VICTIME
    if IsValid(target) and target:IsPlayer() then
        local vr = raceOf(target)
        if not vr then return end

        -- Esquive : négation totale d'un coup
        if vr.dodge and vr.dodge > 0 and math.Rand(0, 1) < vr.dodge then
            dmginfo:SetDamage(0)
            dmginfo:ScaleDamage(0)
            return
        end

        -- Résistance au feu (Sang-dragon)
        if vr.fireResist and vr.fireResist > 0
           and dmginfo:IsDamageType(bit.bor(DMG_BURN, DMG_SLOWBURN)) then
            dmginfo:ScaleDamage(1 - vr.fireResist)
        end

        -- Résistance magique (Gnome — placeholder futur module Sorcier)
        if vr.magicResist and vr.magicResist > 0
           and dmginfo:IsDamageType(C.MagicDamageBits) then
            dmginfo:ScaleDamage(1 - vr.magicResist)
        end

        -- Réduction générale de dégâts (Nain, Ogre, Homme-lézard...)
        if vr.dmgReduction and vr.dmgReduction > 0 then
            dmginfo:ScaleDamage(1 - vr.dmgReduction)
        end
    end
end)

----------------------------------------------------------------------
-- Régénération passive (timer serveur unique)
----------------------------------------------------------------------
timer.Create("BLOOD_Regen", C.RegenInterval, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() then
            local r = raceOf(ply)
            if r and r.regen and r.regen > 0 then
                local hp, mx = ply:Health(), ply:GetMaxHealth()
                if hp < mx then
                    ply:SetHealth(math.min(mx, hp + r.regen))
                end
            end
        end
    end
end)

----------------------------------------------------------------------
-- Discrétion (Homme-rat) : supprime les bruits de pas
----------------------------------------------------------------------
hook.Add("PlayerFootstep", "BLOOD_Stealth", function(ply)
    local r = raceOf(ply)
    if r and r.stealth then
        return true -- true = on gère le son => aucun son joué
    end
end)
