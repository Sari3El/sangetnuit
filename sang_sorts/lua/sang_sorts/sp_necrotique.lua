--[[-------------------------------------------------------------------------
    Sang et Nuit — Sort « Lac Maudit »  (Magie Nécrotique)
      L'inverse du soin : une flaque maudite au sol qui ronge les êtres vivants
      autour pendant ~18 s (3 dégâts/s ; respecte Force/Résistance et la
      réduction de dégâts de race). Ne blesse pas le lanceur.
---------------------------------------------------------------------------]]

if not HpwRewrite then return end

SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.Necrotique) or {
    Mana = 35, Cooldown = 12, Radius = 250, Amount = 3, Duration = 18,
    Particle = "[5]_cursed_lake", Sound = "ambient/atmosphere/cave_hit1.wav",
}

PrecacheParticleSystem(C.Particle)

local Spell = { }
Spell.NodeOffset = Vector(900, -300, 0)
Spell.Description = [[
	Fait apparaître un lac maudit au sol
	qui inflige des dégâts aux ennemis
	autour pendant ~18 secondes.
]]

function Spell:OnFire(wand)
    if not SERVER then return false end
    local ply = self.Owner
    if not IsValid(ply) then return false end

    local tr = ply:GetEyeTrace()
    local pos = tr.HitPos + tr.HitNormal * 4

    local z = ents.Create("sang_spellzone")
    if not IsValid(z) then return false end
    z:SetPos(pos)
    z:Spawn()
    z:Activate()
    z:SetupZone(ply, "curse", C.Radius, C.Amount, C.Duration, C.Particle)
    if C.Sound then z:EmitSound(C.Sound, 75, 100) end

    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category  = "Magie Nécrotique",
    mana      = C.Mana, cooldown = C.Cooldown,
    color     = Color(120, 40, 160),
    icon      = "vgui/entities/entity_hpwand_spell_crucio",
    whatToSay = "Lac Maudit",
})

HpwRewrite:AddSpell("Lac Maudit", Spell)
