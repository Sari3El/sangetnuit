--[[-------------------------------------------------------------------------
    Sang et Nuit — « Répulsion »  (Magie Arcanique)
      Onde de choc autour du lanceur : repousse violemment joueurs/PNJ/objets
      et inflige de petits dégâts magiques.
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.ArcRepulsion) or { Mana = 25, Cooldown = 8, Radius = 260, Damage = 15, Force = 680 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColArcane) or Color(150, 60, 220)

local Spell = { }
Spell.NodeOffset = Vector(-900, 600, 0)
Spell.Description = [[
	Répulsion : une onde arcanique
	repousse violemment tout autour de
	toi et inflige de légers dégâts.
]]

function Spell:OnFire(wand)
    if not SERVER then return false end
    local ply = self.Owner
    if not IsValid(ply) then return false end
    local pos = ply:WorldSpaceCenter()

    if SANGSPELL.Repulse then SANGSPELL.Repulse(pos, C.Radius, C.Force, ply) end
    for _, e in ipairs(SANGSPELL.LivingInSphere(pos, C.Radius, function(e) return e ~= ply end)) do
        SANGSPELL.DealDamage(ply, e, C.Damage, SANGSPELL.MAGIC)
    end

    local ed = EffectData() ed:SetOrigin(pos) ed:SetScale(C.Radius)
    util.Effect("cball_explode", ed)
    util.ScreenShake(pos, 6, 100, 0.5, C.Radius * 2)
    ply:EmitSound("ambient/energy/whiteflash.wav", 75, 110)
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Arcanique", mana = C.Mana, cooldown = C.Cooldown,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_depulso",
    whatToSay = "Répulsion",
})
HpwRewrite:AddSpell("Répulsion", Spell)
