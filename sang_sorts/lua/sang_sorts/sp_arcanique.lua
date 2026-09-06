--[[-------------------------------------------------------------------------
    Sang et Nuit — Sort « Translocation »  (Magie Arcanique)
      Téléportation là où tu regardes (inspiré d'Obscuratio/Apparition).
      Mana + cooldown. Pas de dégâts.
---------------------------------------------------------------------------]]

if not HpwRewrite then
    MsgN("[Sang Sorts] HpwRewrite introuvable — 'Translocation' non chargé.")
    return
end

SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.Translocation) or {
    Mana = 15, Cooldown = 6, MaxDist = 2500,
    Particle = "hpw_apparation_black",
    Sound = "ambient/machines/teleport4.wav",
}

PrecacheParticleSystem(C.Particle)

local Spell = { }
Spell.NodeOffset = Vector(-900, 0, 0)
Spell.Description = [[
	Translocation : tu te téléportes
	instantanément là où tu regardes.
]]

function Spell:OnFire(wand)
    if not SERVER then return false end
    local ply = self.Owner
    if not IsValid(ply) or not ply:Alive() then return false end

    -- Point visé (trace depuis les yeux, bornée à MaxDist).
    local eyes = ply:EyePos()
    local tr = util.TraceLine({
        start  = eyes,
        endpos = eyes + ply:GetAimVector() * (C.MaxDist or 2500),
        filter = ply,
        mask   = MASK_SOLID_BRUSHONLY,
    })

    local dest = tr.HitPos + tr.HitNormal * 20
    -- Vérifie que la destination n'est pas coincée dans un mur/sol.
    local hull = util.TraceHull({
        start  = dest + Vector(0, 0, 8),
        endpos = dest + Vector(0, 0, 8),
        filter = ply,
        mins   = ply:OBBMins(),
        maxs   = ply:OBBMaxs(),
    })
    if hull.Hit then
        dest = dest + tr.HitNormal * 20 + Vector(0, 0, 8)
    end

    local from = ply:GetPos() + Vector(0, 0, 36)
    ParticleEffect(C.Particle, from, Angle(0, 0, 0))
    ply:EmitSound(C.Sound, 70, math.random(95, 108))

    ply:SetPos(dest)
    ply:SetVelocity(-ply:GetVelocity()) -- coupe l'élan pour ne pas glisser

    ParticleEffect(C.Particle, dest + Vector(0, 0, 36), Angle(0, 0, 0))
    ply:EmitSound(C.Sound, 70, math.random(95, 108))

    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category  = "Magie Arcanique",
    mana      = C.Mana or 15,
    cooldown  = C.Cooldown or 6,
    color     = Color(130, 120, 255),
    icon      = "vgui/entities/entity_hpwand_spell_apparition",
    whatToSay = "Translocation",
})

HpwRewrite:AddSpell("Translocation", Spell)
