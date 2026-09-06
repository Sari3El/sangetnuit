--[[-------------------------------------------------------------------------
    Sang et Nuit — « Nuée d'Ombres »  (Magie Nécrotique / Ténèbres)
      Projectile d'ombre : petits dégâts + ASSOMBRIT l'écran de la cible
      (aveuglement) et la ronge d'un léger DoT.
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.NecShadowBolt) or { Mana = 25, Cooldown = 9, Speed = 2500, Damage = 12, BlindDur = 3, DotDps = 3, DotDur = 4 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColNecro) or Color(150, 20, 30)

local function dot(owner, target, dps, dur)
    if not IsValid(target) then return end
    local id = "SangDot_" .. target:EntIndex()
    local ticks = math.floor(dur)
    timer.Create(id, 1, ticks, function()
        if IsValid(owner) and IsValid(target) and target:Health() > 0 and SANGSPELL.DealDamage then
            SANGSPELL.DealDamage(owner, target, dps, SANGSPELL.MAGIC, owner)
        end
    end)
end

local Spell = { }
Spell.NodeOffset = Vector(600, 1200, 0)
Spell.Description = [[
	Nuée d'Ombres : un trait de ténèbres
	blesse la cible, assombrit sa vue et
	la ronge quelques secondes.
]]

function Spell:OnFire(wand)
    if not SERVER then return false end
    local ply = self.Owner
    if not IsValid(ply) then return false end

    local b = ents.Create("sang_bolt")
    if not IsValid(b) then return false end
    b:Spawn() b:Activate()
    b:SetupBolt(ply, ply:GetAimVector(), {
        speed = C.Speed, life = 4, color = Color(60, 20, 70), hitWorld = false,
        onHit = function(tr)
            local e = tr.Entity
            if not (IsValid(e) and (e:IsPlayer() or e:IsNPC())) then return end
            SANGSPELL.DealDamage(ply, e, C.Damage, SANGSPELL.MAGIC, ply)
            dot(ply, e, C.DotDps, C.DotDur)
            if e:IsPlayer() then
                net.Start("sang_blind") net.WriteFloat(C.BlindDur) net.Send(e)
            end
            local ed = EffectData() ed:SetOrigin(e:WorldSpaceCenter()) util.Effect("cball_explode", ed)
        end,
    })
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Nécrotique", mana = C.Mana, cooldown = C.Cooldown,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_fumos",
    whatToSay = "Nuée d'Ombres",
})
HpwRewrite:AddSpell("Nuée d'Ombres", Spell)
