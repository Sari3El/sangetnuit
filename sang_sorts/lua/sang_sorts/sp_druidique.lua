--[[-------------------------------------------------------------------------
    Sang et Nuit — Sort « Sève Curative »  (Magie Druidique)
      Fait apparaître une zone de verdure au sol qui soigne les êtres vivants
      autour pendant ~18 s (+3 PV/s).
---------------------------------------------------------------------------]]

if not HpwRewrite then return end

SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.Druidique) or {
    Mana = 35, Cooldown = 12, Radius = 250, Amount = 3, Duration = 18,
    Particle = "[3]_healing_zone", Sound = "items/smallmedkit1.wav",
}

PrecacheParticleSystem(C.Particle)

local Spell = { }
Spell.NodeOffset = Vector(0, -900, 0)
Spell.Description = [[
	Fait pousser une zone de verdure au
	sol qui soigne les alliés autour
	pendant ~18 secondes.
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
    z:SetupZone(ply, "heal", C.Radius, C.Amount, C.Duration, C.Particle)
    if C.Sound then z:EmitSound(C.Sound, 75, 100) end

    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category  = "Magie Druidique",
    mana      = C.Mana, cooldown = C.Cooldown,
    color     = Color(90, 210, 90),
    icon      = "vgui/entities/entity_hpwand_spell_episkey",
    whatToSay = "Sève Curative",
})

HpwRewrite:AddSpell("Sève Curative", Spell)
