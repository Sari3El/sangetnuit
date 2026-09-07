--[[-------------------------------------------------------------------------
    Sang et Nuit — « Mur de Feu »  (Magie Élémentaire)
      Une ligne de flammes apparaît au sol (perpendiculaire à ton regard) et
      brûle ceux qui la traversent pendant quelques secondes (respecte la
      résistance au feu).
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.ElemWall) or { Mana = 40, Cooldown = 14, Length = 320, Segments = 5, Radius = 75, Dps = 6, Duration = 6 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColElem) or Color(255, 140, 30)
local FX = (SANGSPELL.Config and SANGSPELL.Config.Fx) or {}

local Spell = { }
Spell.NodeOffset = Vector(600, 900, 0)
Spell.Description = [[
	Mur de Feu : une ligne de flammes
	surgit du sol et brûle ceux qui la
	traversent.
]]

function Spell:OnFire(wand)
    if not SERVER then return false end
    local ply = self.Owner
    if not IsValid(ply) then return false end

    local tr = ply:GetEyeTrace()
    local center = tr.HitPos
    local fwd = ply:EyeAngles():Forward() fwd.z = 0 fwd:Normalize()
    local right = fwd:Cross(Vector(0, 0, 1)) right:Normalize()

    local n = math.max(1, C.Segments)
    for i = 0, n - 1 do
        local frac = (i / (n - 1)) - 0.5
        local base = center + right * (frac * C.Length)
        local down = util.TraceLine({ start = base + Vector(0, 0, 60), endpos = base - Vector(0, 0, 120), mask = MASK_SOLID_BRUSHONLY })
        local pos = down.Hit and (down.HitPos + Vector(0, 0, 4)) or base
        local z = ents.Create("sang_zone")
        if IsValid(z) then
            z:SetPos(pos)
            z:Spawn() z:Activate()
            z:SetupZone(ply, "fire", C.Radius, C.Dps, C.Duration, COL, FX.ElemWallZone)
        end
    end
    ply:EmitSound("ambient/fire/mtov_flame2.wav", 80, 100)
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Élémentaire", mana = C.Mana, cooldown = C.Cooldown,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_confringo",
    whatToSay = "Mur de Feu",
})
HpwRewrite:AddSpell("Mur de Feu", Spell)
