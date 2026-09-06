--[[-------------------------------------------------------------------------
    Sang et Nuit — « Corrosion Temporelle »  (Magie Temporelle)
      Gros projectile : quand il touche un ennemi (ou le décor), il explose en
      ZONE — tous ceux qui sont autour subissent des dégâts magiques par
      seconde pendant quelques secondes (respecte résistances + statistiques).
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.TmpCorrosion) or { Mana = 30, Cooldown = 10, Speed = 2000, Radius = 190, DamagePerSec = 4, Duration = 6 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColTemps) or Color(80, 160, 255)

local Spell = { }
Spell.NodeOffset = Vector(1800, 450, 0)
Spell.Description = [[
	Corrosion Temporelle : un gros
	projectile explose en zone et ronge
	tous les ennemis autour pendant
	quelques secondes.
]]

function Spell:OnFire(wand)
    if not SERVER then return false end
    local ply = self.Owner
    if not IsValid(ply) then return false end

    local function boom(pos)
        local z = ents.Create("sang_zone")
        if IsValid(z) then
            z:SetPos(pos)
            z:Spawn() z:Activate()
            z:SetupZone(ply, "corrosion", C.Radius, C.DamagePerSec, C.Duration, COL)
        end
        local ed = EffectData() ed:SetOrigin(pos) ed:SetScale(C.Radius)
        util.Effect("cball_explode", ed)
        util.ScreenShake(pos, 5, 100, 0.6, C.Radius * 2)
        sound.Play("ambient/levels/labs/electric_explosion3.wav", pos, 80, 100)
    end

    local b = ents.Create("sang_bolt")
    if not IsValid(b) then return false end
    b:Spawn() b:Activate()
    b:SetupBolt(ply, ply:GetAimVector(), {
        speed = C.Speed, life = 5, color = COL,
        onHit    = function(tr) boom(tr.HitPos) end,
        onExpire = function(pos) boom(pos) end,
    })
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Temporelle", mana = C.Mana, cooldown = C.Cooldown,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_crucio",
    whatToSay = "Corrosion Temporelle",
})
HpwRewrite:AddSpell("Corrosion Temporelle", Spell)
