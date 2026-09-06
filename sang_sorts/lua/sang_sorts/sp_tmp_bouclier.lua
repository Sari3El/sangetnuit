--[[-------------------------------------------------------------------------
    Sang et Nuit — « Bouclier Temporel »  (Magie Temporelle)
      Pose une bulle temporelle À TA POSITION. Elle RESTE sur place jusqu'à sa
      disparition ; tu peux bouger et entrer/sortir librement. Dans la bulle :
      tout dégât est bloqué et les projectiles/objets physiques sont figés.
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.TmpBouclier) or { Mana = 40, Cooldown = 18, Radius = 230, Duration = 8 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColTemps) or Color(80, 160, 255)

local Spell = { }
Spell.NodeOffset = Vector(1500, 900, 0)
Spell.CanSelfCast = true
Spell.Description = [[
	Bouclier Temporel : pose une bulle
	sur place qui protège ceux qui sont
	dedans et fige les projectiles. Tu
	peux bouger librement.
]]

function Spell:OnFire(wand)
    if not SERVER then return false end
    local ply = self.Owner
    if not IsValid(ply) then return false end

    local s = ents.Create("sang_timeshield")
    if not IsValid(s) then return false end
    s:SetPos(ply:GetPos() + Vector(0, 0, 10))
    s:Spawn() s:Activate()
    s:SetupShield(ply, C.Radius, C.Duration)
    s:EmitSound("ambient/levels/labs/teleport_postblast_thunder1.wav", 75, 125)
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Temporelle", mana = C.Mana, cooldown = C.Cooldown,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_salvio_hexia",
    whatToSay = "Bouclier Temporel",
})
HpwRewrite:AddSpell("Bouclier Temporel", Spell)
