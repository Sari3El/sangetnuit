--[[-------------------------------------------------------------------------
    Sang et Nuit — « Pic de Glace »  (Magie Élémentaire)
      Projectile de glace : dégâts + gèle/ralentit fortement la cible touchée.
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.ElemIce) or { Mana = 20, Cooldown = 6, Speed = 2600, Damage = 20, SlowFactor = 0.35, SlowDur = 4 }
local FX = (SANGSPELL.Config and SANGSPELL.Config.Fx) or {}

local Spell = { }
Spell.NodeOffset = Vector(300, 900, 0)
Spell.Description = [[
	Pic de Glace : un éclat de givre
	blesse et gèle (ralentit fortement)
	la cible touchée.
]]

function Spell:OnFire(wand)
    if not SERVER then return false end
    local ply = self.Owner
    if not IsValid(ply) then return false end

    local b = ents.Create("sang_bolt")
    if not IsValid(b) then return false end
    b:Spawn() b:Activate()
    b:SetupBolt(ply, ply:GetAimVector(), {
        speed = C.Speed, life = 4, color = Color(140, 210, 255), hitWorld = false,
        onHit = function(tr)
            local e = tr.Entity
            if IsValid(e) and (e:IsPlayer() or e:IsNPC()) then
                SANGSPELL.DealDamage(ply, e, C.Damage, SANGSPELL.MAGIC, ply)
                if SANGSPELL.ApplySlow then SANGSPELL.ApplySlow(e, C.SlowFactor, C.SlowDur) end
                if FX.ElemIceImpact and SANGSPELL.PlayParticle then
                    SANGSPELL.PlayParticle(FX.ElemIceImpact, e:GetPos())
                else
                    local ed = EffectData() ed:SetOrigin(e:WorldSpaceCenter()) util.Effect("GlassImpact", ed)
                end
            end
        end,
    })
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Élémentaire", mana = C.Mana, cooldown = C.Cooldown,
    color = Color(140, 210, 255), icon = "vgui/entities/entity_hpwand_spell_arrestomomentum",
    whatToSay = "Pic de Glace",
})
HpwRewrite:AddSpell("Pic de Glace", Spell)
