--[[-------------------------------------------------------------------------
    Sang et Nuit — « Foudre Fulgurante »  (Magie Élémentaire)
      Projectile de foudre très rapide : dégâts + bref étourdissement (la cible
      ne peut plus bouger un court instant).
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.ElemBolt) or { Mana = 25, Cooldown = 9, Speed = 3300, Damage = 22, StunDur = 1 }
local FX = (SANGSPELL.Config and SANGSPELL.Config.Fx) or {}

local Spell = { }
Spell.NodeOffset = Vector(900, 900, 0)
Spell.Description = [[
	Foudre Fulgurante : un éclair rapide
	blesse et étourdit brièvement la
	cible touchée.
]]

function Spell:OnFire(wand)
    if not SERVER then return false end
    local ply = self.Owner
    if not IsValid(ply) then return false end

    local b = ents.Create("sang_bolt")
    if not IsValid(b) then return false end
    b:Spawn() b:Activate()
    b:SetupBolt(ply, ply:GetAimVector(), {
        speed = C.Speed, life = 4, color = Color(255, 240, 120), hitWorld = false,
        particle = FX.ElemBoltFly,
        onHit = function(tr)
            local e = tr.Entity
            if IsValid(e) and (e:IsPlayer() or e:IsNPC()) then
                SANGSPELL.DealDamage(ply, e, C.Damage, SANGSPELL.MAGIC, ply)
                if SANGSPELL.Root then SANGSPELL.Root(e, C.StunDur) end
                local ed = EffectData() ed:SetOrigin(e:WorldSpaceCenter()) util.Effect("StunstickImpact", ed)
            end
        end,
    })
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Élémentaire", mana = C.Mana, cooldown = C.Cooldown,
    color = Color(255, 240, 120), icon = "vgui/entities/entity_hpwand_spell_reducto",
    whatToSay = "Foudre Fulgurante",
})
HpwRewrite:AddSpell("Foudre Fulgurante", Spell)
