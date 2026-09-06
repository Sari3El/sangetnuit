--[[-------------------------------------------------------------------------
    Sang et Nuit — « Bouclier Arcanique »  (Magie Arcanique)
      Auto-sort : tu deviens INVULNÉRABLE mais tu ne peux plus te déplacer
      pendant la durée du sort (défense/temporisation).
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.ArcBouclier) or { Mana = 30, Cooldown = 14, Duration = 5 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColArcane) or Color(150, 60, 220)

local Spell = { }
Spell.NodeOffset = Vector(-900, 900, 0)
Spell.CanSelfCast = true
Spell.Description = [[
	Bouclier Arcanique : tu es
	invulnérable mais figé sur place
	pendant la durée du sort.
]]

function Spell:OnFire(wand)
    if SERVER and IsValid(self.Owner) and SANGSPELL.SelfStasis then
        SANGSPELL.SelfStasis(self.Owner, C.Duration, true)
        self.Owner:EmitSound("ambient/energy/weld1.wav", 70, 120)
    end
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Arcanique", mana = C.Mana, cooldown = C.Cooldown,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_protego",
    whatToSay = "Bouclier Arcanique",
})
HpwRewrite:AddSpell("Bouclier Arcanique", Spell)
