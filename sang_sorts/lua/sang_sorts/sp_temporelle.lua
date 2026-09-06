--[[-------------------------------------------------------------------------
    Sang et Nuit — Sort « Arrêt du Temps »  (Magie Temporelle)
      Tire un projectile ; au contact, fige le temps dans une zone pendant 5 s
      (joueurs/PNJ figés et invulnérables, objets/projectiles physiques figés
      puis relancés à la fin). Le lanceur n'est jamais figé.
---------------------------------------------------------------------------]]

if not HpwRewrite then return end

SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.Temporelle) or {
    Mana = 60, Cooldown = 25, Radius = 250, StunDuration = 5,
    FlyParticle = "[2]_fire_aura_blue_bloom", ZoneParticle = "[2]_fireball_main_blue",
    Sound = "ambient/levels/labs/electric_explosion1.wav",
}

PrecacheParticleSystem(C.FlyParticle)
PrecacheParticleSystem(C.ZoneParticle)

local Spell = { }
Spell.NodeOffset = Vector(-300, -900, 0)
Spell.Description = [[
	Tire un éclair temporel. Au contact,
	le temps s'arrête dans la zone
	pendant 5 secondes : tout est figé
	et invulnérable, puis reprend sa
	course.
]]

function Spell:OnFire(wand)
    if not SERVER then return false end
    local ply = self.Owner
    if not IsValid(ply) then return false end

    local b = ents.Create("sang_timebolt")
    if not IsValid(b) then return false end
    b:Spawn()
    b:Activate()
    b:SetupBolt(ply, ply:GetAimVector(), C.Radius, C.StunDuration, C.FlyParticle, C.ZoneParticle, C.Sound)

    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category  = "Magie Temporelle",
    mana      = C.Mana, cooldown = C.Cooldown,
    color     = Color(90, 170, 255),
    icon      = "vgui/entities/entity_hpwand_spell_timesum",
    whatToSay = "Arrêt du Temps",
})

HpwRewrite:AddSpell("Arrêt du Temps", Spell)
