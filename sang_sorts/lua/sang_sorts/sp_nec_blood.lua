--[[-------------------------------------------------------------------------
    Sang et Nuit — « Explosion de Sang »  (Magie Nécrotique)
      Tu sacrifies une partie de tes PV pour déclencher une explosion de sang à
      l'endroit visé : gros dégâts de zone (respecte résistances + statistiques).
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.NecBlood) or { Mana = 15, Cooldown = 10, HpCost = 15, Radius = 260, Damage = 45 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColNecro) or Color(150, 20, 30)

local Spell = { }
Spell.NodeOffset = Vector(0, 1500, 0)
Spell.Description = [[
	Explosion de Sang : sacrifie un peu
	de ta vie pour une explosion de zone
	dévastatrice là où tu vises.
]]

function Spell:OnFire(wand)
    if not SERVER then return false end
    local ply = self.Owner
    if not IsValid(ply) then return false end

    if not (SANGSPELL.SacrificeHP and SANGSPELL.SacrificeHP(ply, C.HpCost)) then
        if BLOOD and BLOOD.Notify then BLOOD.Notify(ply, "Pas assez de vie pour le sacrifice.", "error") end
        return false
    end

    local tr = ply:GetEyeTrace()
    local pos = tr.HitPos + tr.HitNormal * 8

    for _, e in ipairs(SANGSPELL.LivingInSphere(pos, C.Radius)) do
        SANGSPELL.DealDamage(ply, e, C.Damage, SANGSPELL.MAGIC, ply)
    end

    local ed = EffectData() ed:SetOrigin(pos) ed:SetScale(C.Radius) util.Effect("cball_explode", ed)
    local ed2 = EffectData() ed2:SetOrigin(pos) ed2:SetMagnitude(2) ed2:SetScale(2) ed2:SetRadius(C.Radius) util.Effect("BloodImpact", ed2)
    util.ScreenShake(pos, 8, 120, 0.8, C.Radius * 2.5)
    sound.Play("ambient/materials/blob_pop2.wav", pos, 85, 90)
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Nécrotique", mana = C.Mana, cooldown = C.Cooldown,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_confringo",
    whatToSay = "Explosion de Sang",
})
HpwRewrite:AddSpell("Explosion de Sang", Spell)
