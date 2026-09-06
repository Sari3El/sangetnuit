--[[-------------------------------------------------------------------------
    Sang et Nuit — « Bulle de Lenteur »  (Magie Temporelle)
      Zone au sol : tout ce qui s'y trouve (ennemis, etc.) est fortement
      ralenti tant qu'il reste dedans (plus doux que l'Arrêt du Temps).
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.TmpBulle) or { Mana = 45, Cooldown = 16, Radius = 260, SlowFactor = 0.4, Duration = 6 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColTemps) or Color(80, 160, 255)

local Spell = { }
Spell.NodeOffset = Vector(1500, 300, 0)
Spell.Description = [[
	Bulle de Lenteur : une zone où le
	temps se traîne — tout ralentit
	fortement tant qu'on est dedans.
]]

function Spell:OnFire(wand)
    if not SERVER then return false end
    local ply = self.Owner
    if not IsValid(ply) then return false end

    local tr = ply:GetEyeTrace()
    local pos = tr.HitPos + tr.HitNormal * 4

    local z = ents.Create("sang_zone")
    if not IsValid(z) then return false end
    z:SetPos(pos)
    z:Spawn() z:Activate()
    z:SetupZone(ply, "slow", C.Radius, C.SlowFactor, C.Duration, COL)
    z:EmitSound("ambient/levels/labs/electric_explosion6.wav", 75, 120)
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Temporelle", mana = C.Mana, cooldown = C.Cooldown,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_immobulus",
    whatToSay = "Bulle de Lenteur",
})
HpwRewrite:AddSpell("Bulle de Lenteur", Spell)
