--[[-------------------------------------------------------------------------
    Sang et Nuit — « Ronces »  (Magie Druidique)
      Fait surgir des ronces au sol qui IMMOBILISENT (root) et rongent d'un
      léger DoT les ennemis pris dedans.
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.DruidThorns) or { Mana = 35, Cooldown = 14, Radius = 240, RootDur = 3, Dps = 3, Duration = 5 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColDruid) or Color(90, 200, 80)
local FX = (SANGSPELL.Config and SANGSPELL.Config.Fx) or {}

local Spell = { }
Spell.NodeOffset = Vector(-300, 900, 0)
Spell.Description = [[
	Ronces : des racines surgissent du
	sol, immobilisent et blessent les
	ennemis dans la zone.
]]

function Spell:OnFire(wand)
    if not SERVER then return false end
    local ply = self.Owner
    if not IsValid(ply) then return false end

    local tr = ply:GetEyeTrace()
    local z = ents.Create("sang_zone")
    if not IsValid(z) then return false end
    z:SetPos(tr.HitPos + tr.HitNormal * 4)
    z:Spawn() z:Activate()
    z:SetupZone(ply, "root", C.Radius, C.Dps, C.Duration, COL, FX.DruidThornsZone)
    z:EmitSound("ambient/materials/rustle" .. math.random(1, 5) .. ".wav", 78, 90)
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Druidique", mana = C.Mana, cooldown = C.Cooldown,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_immobulus",
    whatToSay = "Ronces",
})
HpwRewrite:AddSpell("Ronces", Spell)
