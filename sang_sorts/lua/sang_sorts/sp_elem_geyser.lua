--[[-------------------------------------------------------------------------
    Sang et Nuit — « Geyser »  (Magie Élémentaire)
      Un jet jaillit du sol au point visé et PROJETTE EN L'AIR les êtres et
      objets autour (petits dégâts).
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.ElemGeyser) or { Mana = 30, Cooldown = 10, Radius = 170, Damage = 10, Launch = 780 }
local FX = (SANGSPELL.Config and SANGSPELL.Config.Fx) or {}

local Spell = { }
Spell.NodeOffset = Vector(1200, 900, 0)
Spell.Description = [[
	Geyser : un jet jaillit du sol et
	projette en l'air ce qui se trouve
	au-dessus.
]]

function Spell:OnFire(wand)
    if not SERVER then return false end
    local ply = self.Owner
    if not IsValid(ply) then return false end

    local tr = ply:GetEyeTrace()
    local pos = tr.HitPos

    for _, e in ipairs(ents.FindInSphere(pos, C.Radius)) do
        if IsValid(e) and e ~= ply and string.sub(e:GetClass(), 1, 5) ~= "sang_" then
            if e:IsPlayer() or e:IsNPC() then
                e:SetVelocity(Vector(0, 0, C.Launch) + VectorRand() * 60)
                if e:Health() > 0 then SANGSPELL.DealDamage(ply, e, C.Damage, SANGSPELL.MAGIC, ply) end
            else
                local phys = e:GetPhysicsObject()
                if IsValid(phys) then phys:ApplyForceCenter(Vector(0, 0, C.Launch) * phys:GetMass()) end
            end
        end
    end

    if FX.ElemGeyser and SANGSPELL.PlayParticle then
        SANGSPELL.PlayParticle(FX.ElemGeyser, pos)
    end
    local ed = EffectData() ed:SetOrigin(pos) ed:SetScale(2) ed:SetMagnitude(2) util.Effect("watersplash", ed)
    util.ScreenShake(pos, 5, 90, 0.5, C.Radius * 2)
    sound.Play("ambient/water/water_spray" .. math.random(1, 3) .. ".wav", pos, 80, 100)
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Élémentaire", mana = C.Mana, cooldown = C.Cooldown,
    color = Color(90, 160, 255), icon = "vgui/entities/entity_hpwand_spell_depulso",
    whatToSay = "Geyser",
})
HpwRewrite:AddSpell("Geyser", Spell)
