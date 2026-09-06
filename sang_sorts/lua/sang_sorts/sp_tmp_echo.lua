--[[-------------------------------------------------------------------------
    Sang et Nuit — « Écho Temporel »  (Magie Temporelle)
      Esquive : dash très rapide dans la direction visée + bref instant
      d'invulnérabilité.
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.TmpEcho) or { Mana = 20, Cooldown = 6, DashForce = 700, Invuln = 0.6 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColTemps) or Color(80, 160, 255)

local Spell = { }
Spell.NodeOffset = Vector(1200, 750, 0)
Spell.CanSelfCast = true
Spell.Description = [[
	Écho Temporel : tu te déplaces d'un
	éclair dans la direction visée, bref
	instant d'invulnérabilité.
]]

function Spell:OnFire(wand)
    if not SERVER then return false end
    local ply = self.Owner
    if not IsValid(ply) or not ply:Alive() then return false end

    local d = ply:GetAimVector()
    d.z = math.max(d.z, 0) * 0.25
    d:Normalize()
    ply:SetVelocity(d * C.DashForce)

    -- Bref instant d'invulnérabilité (ne lève pas une stase en cours).
    ply:GodEnable()
    timer.Create("SangEcho_" .. ply:EntIndex(), C.Invuln, 1, function()
        if IsValid(ply) and not timer.Exists("SangStasis_" .. ply:EntIndex()) then
            ply:GodDisable()
        end
    end)

    local ed = EffectData() ed:SetOrigin(ply:WorldSpaceCenter()) util.Effect("cball_explode", ed)
    ply:EmitSound("ambient/levels/labs/electric_explosion4.wav", 68, 135)
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Temporelle", mana = C.Mana, cooldown = C.Cooldown,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_depulso",
    whatToSay = "Écho Temporel",
})
HpwRewrite:AddSpell("Écho Temporel", Spell)
