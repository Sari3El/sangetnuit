--[[-------------------------------------------------------------------------
    Sang et Nuit — « Rocher »  (Magie Élémentaire)
      Gros projectile de pierre : dégâts + FORT RECUL (projette la cible et
      repousse ce qui est autour du point d'impact).
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.ElemRock) or { Mana = 25, Cooldown = 8, Speed = 2200, Damage = 30, Knockback = 950, Radius = 160 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColElem) or Color(255, 140, 30)

local Spell = { }
Spell.NodeOffset = Vector(900, 1200, 0)
Spell.Description = [[
	Rocher : un bloc de pierre percute la
	cible, la projette violemment et
	repousse les alentours.
]]

function Spell:OnFire(wand)
    if not SERVER then return false end
    local ply = self.Owner
    if not IsValid(ply) then return false end
    local dir = ply:GetAimVector()

    local b = ents.Create("sang_bolt")
    if not IsValid(b) then return false end
    b:Spawn() b:Activate()
    b:SetupBolt(ply, dir, {
        speed = C.Speed, life = 4, color = Color(160, 120, 80),
        onHit = function(tr)
            local e = tr.Entity
            if IsValid(e) and (e:IsPlayer() or e:IsNPC()) then
                SANGSPELL.DealDamage(ply, e, C.Damage, SANGSPELL.MAGIC, ply)
                local push = dir * C.Knockback + Vector(0, 0, C.Knockback * 0.3)
                e:SetVelocity(push)
            end
            if SANGSPELL.Repulse then SANGSPELL.Repulse(tr.HitPos, C.Radius, C.Knockback * 0.7, e) end
            local ed = EffectData() ed:SetOrigin(tr.HitPos) ed:SetScale(C.Radius) util.Effect("ThumperDust", ed)
            util.ScreenShake(tr.HitPos, 6, 100, 0.5, C.Radius * 2)
        end,
    })
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Élémentaire", mana = C.Mana, cooldown = C.Cooldown,
    color = Color(170, 130, 90), icon = "vgui/entities/entity_hpwand_spell_depulso",
    whatToSay = "Rocher",
})
HpwRewrite:AddSpell("Rocher", Spell)
