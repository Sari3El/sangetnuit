--[[-------------------------------------------------------------------------
    Sang et Nuit — Sort « Translocation »  (Magie Arcanique)
      Téléportation là où tu regardes (inspiré d'Obscuratio/Apparition).
      Un PORTAIL s'ouvre à l'entrée (ancienne position) ET à la sortie
      (destination) au moment du lancer, puis se referme après CloseDelay s.
      Mana + cooldown. Pas de dégâts.
---------------------------------------------------------------------------]]

if not HpwRewrite then
    MsgN("[Sang Sorts] HpwRewrite introuvable — 'Translocation' non chargé.")
    return
end

SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.Translocation) or {
    Mana = 15, Cooldown = 6, MaxDist = 2500,
    Portal = "strange_portal", CloseDelay = 2,
    Sound = "ambient/machines/teleport4.wav",
}

-- Résout « strange_portal » -> « [N]_strange_portal » ET enregistre le .pcf
-- qui le contient (sur le serveur ET le client, car chargé en "sh").
if SANGSPELL.ResolveParticle then
    C.Portal = SANGSPELL.ResolveParticle(C.Portal or "strange_portal")
end

local Spell = { }
Spell.NodeOffset = Vector(-900, 0, 0)
Spell.Description = [[
	Translocation : tu te téléportes là où
	tu regardes. Un portail s'ouvre à
	l'entrée et à la sortie, puis se
	referme.
]]

-- Fait apparaître un portail (visuel) à pos, refermé après CloseDelay s.
local function SpawnPortal(pos, ang, particle, life)
    local p = ents.Create("sang_portal")
    if not IsValid(p) then return end
    p:SetPos(pos)
    p:SetAngles(ang or Angle(0, 0, 0))
    p:Spawn()
    p:Activate()
    p:SetupPortal(particle, life)
    return p
end

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

    -- Nom exact du système de particule du portail (déjà résolu au chargement).
    local part = C.Portal or "strange_portal"
    local life = C.CloseDelay or 2
    local yaw  = ply:EyeAngles().y
    local pang = Angle(0, yaw, 0)

    local from = ply:GetPos()
    -- Portail d'ENTRÉE (là où le joueur était) + portail de SORTIE.
    SpawnPortal(from + Vector(0, 0, 36), pang, part, life)
    SpawnPortal(dest + Vector(0, 0, 36), pang, part, life)

    if C.Sound then ply:EmitSound(C.Sound, 72, math.random(96, 106)) end

    ply:SetPos(dest)
    ply:SetVelocity(-ply:GetVelocity()) -- coupe l'élan pour ne pas glisser

    if C.Sound then
        timer.Simple(0, function()
            if IsValid(ply) then ply:EmitSound(C.Sound, 72, math.random(96, 106)) end
        end)
    end

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
