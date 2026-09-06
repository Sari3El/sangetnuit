--[[-------------------------------------------------------------------------
    Sang et Nuit — « Bond Arcanique »  (Magie Arcanique)
      Dash instantané (téléportation courte) dans la direction visée. Plus
      court que Translocation et sans avoir à viser une surface.
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.ArcBond) or { Mana = 12, Cooldown = 5, Dist = 460 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColArcane) or Color(150, 60, 220)

local Spell = { }
Spell.NodeOffset = Vector(-1200, 750, 0)
Spell.CanSelfCast = true
Spell.Description = [[
	Bond Arcanique : tu bondis d'un
	trait dans la direction que tu vises.
]]

function Spell:OnFire(wand)
    if not SERVER then return false end
    local ply = self.Owner
    if not IsValid(ply) or not ply:Alive() then return false end

    local from = ply:GetPos()
    local tr = util.TraceHull({
        start = from, endpos = from + ply:GetAimVector() * C.Dist,
        filter = ply, mins = ply:OBBMins(), maxs = ply:OBBMaxs(),
        mask = MASK_PLAYERSOLID,
    })
    local dest = tr.HitPos

    local ed = EffectData() ed:SetOrigin(from + Vector(0, 0, 30)) util.Effect("cball_explode", ed)
    ply:SetPos(dest)
    ply:SetVelocity(-ply:GetVelocity())
    local ed2 = EffectData() ed2:SetOrigin(dest + Vector(0, 0, 30)) util.Effect("cball_explode", ed2)
    ply:EmitSound("ambient/energy/newspark04.wav", 70, 120)
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Arcanique", mana = C.Mana, cooldown = C.Cooldown,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_apparition",
    whatToSay = "Bond Arcanique",
})
HpwRewrite:AddSpell("Bond Arcanique", Spell)
