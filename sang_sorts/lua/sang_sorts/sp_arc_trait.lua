--[[-------------------------------------------------------------------------
    Sang et Nuit — « Trait Arcanique »  (Magie Arcanique)
      Projectile violet qui part TOUT DROIT (pas de tête chercheuse) et inflige
      des dégâts magiques à la cible touchée (respecte la résistance magique et
      les bonus de statistique).
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.ArcTrait) or { Mana = 15, Cooldown = 3, Speed = 2800, Damage = 20 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColArcane) or Color(150, 60, 220)

local Spell = { }
Spell.NodeOffset = Vector(-900, 300, 0)
Spell.Description = [[
	Trait Arcanique : un éclat de magie
	part droit devant et blesse la
	première cible touchée.
]]

function Spell:OnFire(wand)
    if not SERVER then return false end
    local ply = self.Owner
    if not IsValid(ply) then return false end

    local b = ents.Create("sang_bolt")
    if not IsValid(b) then return false end
    b:Spawn() b:Activate()
    b:SetupBolt(ply, ply:GetAimVector(), {
        speed = C.Speed, life = 4, color = COL,
        onHit = function(tr)
            local e = tr.Entity
            if IsValid(e) and (e:IsPlayer() or e:IsNPC()) then
                SANGSPELL.DealDamage(ply, e, C.Damage, SANGSPELL.MAGIC)
            end
            local ed = EffectData() ed:SetOrigin(tr.HitPos) ed:SetNormal(tr.HitNormal)
            util.Effect("cball_explode", ed)
        end,
    })
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Arcanique", mana = C.Mana, cooldown = C.Cooldown,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_reducto",
    whatToSay = "Trait Arcanique",
})
HpwRewrite:AddSpell("Trait Arcanique", Spell)
