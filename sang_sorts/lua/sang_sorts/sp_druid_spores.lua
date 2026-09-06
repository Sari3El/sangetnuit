--[[-------------------------------------------------------------------------
    Sang et Nuit — « Spores Toxiques »  (Magie Druidique)
      Un nuage de spores empoisonne les ennemis qui restent dedans (dégâts par
      seconde, pas de ralentissement).
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.DruidSpores) or { Mana = 35, Cooldown = 12, Radius = 240, Dps = 4, Duration = 6 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColDruid) or Color(90, 200, 80)

local Spell = { }
Spell.NodeOffset = Vector(0, 1200, 0)
Spell.Description = [[
	Spores Toxiques : un nuage de poison
	ronge les ennemis qui restent dans la
	zone.
]]

function Spell:OnFire(wand)
    if not SERVER then return false end
    local ply = self.Owner
    if not IsValid(ply) then return false end

    local tr = ply:GetEyeTrace()
    local z = ents.Create("sang_zone")
    if not IsValid(z) then return false end
    z:SetPos(tr.HitPos + tr.HitNormal * 6)
    z:Spawn() z:Activate()
    z:SetupZone(ply, "poison", C.Radius, C.Dps, C.Duration, COL)
    z:EmitSound("ambient/gas/steam2.wav", 78, 90)
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Druidique", mana = C.Mana, cooldown = C.Cooldown,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_fumos",
    whatToSay = "Spores Toxiques",
})
HpwRewrite:AddSpell("Spores Toxiques", Spell)
