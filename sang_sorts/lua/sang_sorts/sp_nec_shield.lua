--[[-------------------------------------------------------------------------
    Sang et Nuit — « Bouclier d'Hémoglobine »  (Magie Nécrotique)
      Sacrifie des PV pour créer un bouclier de sang qui ABSORBE des dégâts
      pendant un temps (modéré). Le bouclier fond au fur et à mesure des coups.
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.NecShield) or { Mana = 20, Cooldown = 12, HpCost = 15, Shield = 45, Duration = 8 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColNecro) or Color(150, 20, 30)

if SERVER and not SANGSPELL._HemoHook then
    SANGSPELL._HemoHook = true
    -- Absorbe les dégâts tant qu'il reste du bouclier (avant les autres calculs).
    hook.Add("EntityTakeDamage", "SangHemoShield", function(ply, dmginfo)
        if not (IsValid(ply) and ply:IsPlayer()) then return end
        if not ply.SangHemoShield or ply.SangHemoShield <= 0 then return end
        if (ply.SangHemoUntil or 0) < CurTime() then ply.SangHemoShield = 0 return end
        local dmg = dmginfo:GetDamage()
        if dmg <= 0 then return end
        local absorbed = math.min(ply.SangHemoShield, dmg)
        ply.SangHemoShield = ply.SangHemoShield - absorbed
        dmginfo:SetDamage(dmg - absorbed)
        if absorbed > 0 then ply:EmitSound("physics/flesh/flesh_impact_bullet" .. math.random(1, 5) .. ".wav", 60, 120) end
    end)
end

local Spell = { }
Spell.NodeOffset = Vector(300, 1500, 0)
Spell.CanSelfCast = true
Spell.Description = [[
	Bouclier d'Hémoglobine : sacrifie un
	peu de vie pour un bouclier de sang
	qui absorbe des dégâts un moment.
]]

function Spell:OnFire(wand)
    if not SERVER then return false end
    local ply = self.Owner
    if not IsValid(ply) then return false end
    if not (SANGSPELL.SacrificeHP and SANGSPELL.SacrificeHP(ply, C.HpCost)) then
        if BLOOD and BLOOD.Notify then BLOOD.Notify(ply, "Pas assez de vie pour le sacrifice.", "error") end
        return false
    end
    ply.SangHemoShield = C.Shield
    ply.SangHemoUntil  = CurTime() + C.Duration
    ply:EmitSound("ambient/materials/blob_pop1.wav", 70, 110)
    if BLOOD and BLOOD.Notify then BLOOD.Notify(ply, "Bouclier de sang : " .. C.Shield .. " absorption.", "info") end
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Nécrotique", mana = C.Mana, cooldown = C.Cooldown,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_protego",
    whatToSay = "Bouclier d'Hémoglobine",
})
HpwRewrite:AddSpell("Bouclier d'Hémoglobine", Spell)
