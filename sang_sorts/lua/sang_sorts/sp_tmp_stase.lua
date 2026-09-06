--[[-------------------------------------------------------------------------
    Sang et Nuit — « Stase Temporelle »  (Magie Temporelle)
      Tu te figes toi-même dans le temps : invulnérable et immobile un court
      instant (parade d'urgence).
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.TmpStase) or { Mana = 30, Cooldown = 20, Duration = 3 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColTemps) or Color(80, 160, 255)

local Spell = { }
Spell.NodeOffset = Vector(1500, 600, 0)
Spell.CanSelfCast = true
Spell.Description = [[
	Stase Temporelle : tu te figes,
	invulnérable et immobile pendant un
	court instant.
]]

function Spell:OnFire(wand)
    if SERVER and IsValid(self.Owner) and SANGSPELL.SelfStasis then
        SANGSPELL.SelfStasis(self.Owner, C.Duration, true)
        self.Owner:EmitSound("ambient/levels/labs/teleport_preblast_thunder2.wav", 70, 130)
    end
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Temporelle", mana = C.Mana, cooldown = C.Cooldown,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_protego",
    whatToSay = "Stase Temporelle",
})
HpwRewrite:AddSpell("Stase Temporelle", Spell)
