--[[-------------------------------------------------------------------------
    Sang et Nuit — « Lenteur »  (Magie Temporelle)
      Projectile bleu qui ralentit fortement la cible touchée pendant quelques
      secondes.
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.TmpLenteur) or { Mana = 25, Cooldown = 8, Speed = 2700, SlowFactor = 0.45, SlowDur = 5 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColTemps) or Color(80, 160, 255)

local Spell = { }
Spell.NodeOffset = Vector(900, 600, 0)
Spell.Description = [[
	Lenteur : un trait temporel ralentit
	fortement la cible touchée.
]]

function Spell:OnFire(wand)
    if not SERVER then return false end
    local ply = self.Owner
    if not IsValid(ply) then return false end

    local b = ents.Create("sang_bolt")
    if not IsValid(b) then return false end
    b:Spawn() b:Activate()
    b:SetupBolt(ply, ply:GetAimVector(), {
        speed = C.Speed, life = 4, color = COL, hitWorld = false,
        onHit = function(tr)
            local e = tr.Entity
            if IsValid(e) and (e:IsPlayer() or e:IsNPC()) and SANGSPELL.ApplySlow then
                SANGSPELL.ApplySlow(e, C.SlowFactor, C.SlowDur)
                local ed = EffectData() ed:SetOrigin(e:WorldSpaceCenter()) util.Effect("cball_explode", ed)
            end
        end,
    })
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Temporelle", mana = C.Mana, cooldown = C.Cooldown,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_arrestomomentum",
    whatToSay = "Lenteur",
})
HpwRewrite:AddSpell("Lenteur", Spell)
