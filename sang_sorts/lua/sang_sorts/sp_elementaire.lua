--[[-------------------------------------------------------------------------
    Sang et Nuit — Sort « Boule de Feu »  (Magie Élémentaire)
      Une boule de feu apparaît, tourne autour du lanceur ~1,5 s, puis se lance
      dans la direction regardée. Elle explose au 1er obstacle ou après 10 s :
      dégâts de zone (feu, respecte la résistance au feu) + met le feu.
---------------------------------------------------------------------------]]

if not HpwRewrite then return end

SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.Elementaire) or {
    Mana = 45, Cooldown = 10, Radius = 200, Damage = 40, OrbitTime = 1.5, MaxFly = 10,
    FlyParticle = "[2]_fireball2", BoomParticle = "[0]_barrel_blast",
    GroundParticle = "[2]_flamestrike",
    Sound = "ambient/explosions/explode_4.wav",
}

if SANGSPELL.ResolveParticle then
    C.FlyParticle    = SANGSPELL.ResolveParticle(C.FlyParticle)
    C.BoomParticle   = SANGSPELL.ResolveParticle(C.BoomParticle)
    if C.GroundParticle then C.GroundParticle = SANGSPELL.ResolveParticle(C.GroundParticle) end
end
PrecacheParticleSystem(C.FlyParticle)
PrecacheParticleSystem(C.BoomParticle)
if C.GroundParticle then PrecacheParticleSystem(C.GroundParticle) end

local Spell = { }
Spell.NodeOffset = Vector(300, 900, 0)
Spell.Description = [[
	Une boule de feu tourne autour de toi
	puis se lance devant toi. Elle explose
	au 1er obstacle (ou après 10 s) :
	dégâts de zone + met le feu.
]]

function Spell:OnFire(wand)
    if not SERVER then return false end
    local ply = self.Owner
    if not IsValid(ply) then return false end

    local fb = ents.Create("sang_fireball")
    if not IsValid(fb) then return false end
    fb:Spawn()
    fb:Activate()
    fb:SetupFireball(ply, C.Radius, C.Damage, C.OrbitTime, C.MaxFly, C.FlyParticle, C.BoomParticle, C.Sound, C.GroundParticle)

    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category  = "Magie Élémentaire",
    mana      = C.Mana, cooldown = C.Cooldown,
    color     = Color(255, 120, 40),
    icon      = "vgui/entities/entity_hpwand_spell_fireball",
    whatToSay = "Boule de Feu",
})

HpwRewrite:AddSpell("Boule de Feu", Spell)
