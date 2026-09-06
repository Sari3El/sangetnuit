--[[-------------------------------------------------------------------------
    Sang et Nuit — « Vol Spectral »  (Magie Nécrotique / Ténèbres)
      Tu t'envoles enveloppé de fumée noire (inspiré de l'Apparition HPW), mais
      pour une durée LIMITÉE. Tu voles là où tu regardes, sans dégâts de chute.
      Le vol s'arrête à la fin de la durée ou dès que tu touches le sol/l'eau.
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.NecFly) or { Mana = 35, Cooldown = 16, Duration = 7, Speed = 2400, SprintSpeed = 4200, Smoke = "hpw_apparation_black" }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColNecro) or Color(150, 20, 30)

if C.Smoke and C.Smoke ~= "" then PrecacheParticleSystem(C.Smoke) end

if SERVER then
    SANGSPELL.Flying = SANGSPELL.Flying or {}

    function SANGSPELL.EndFly(ply)
        if not IsValid(ply) then return end
        SANGSPELL.Flying[ply] = nil
        ply.SangFlying = nil
        ply:SetGravity(1)
        ply:StopParticles()
        if ply:Alive() then
            local ed = EffectData() ed:SetOrigin(ply:GetPos()) util.Effect("cball_explode", ed)
        end
    end

    function SANGSPELL.StartFly(ply)
        if not IsValid(ply) or not ply:Alive() then return end
        SANGSPELL.Flying[ply] = { started = CurTime(), dieAt = CurTime() + C.Duration }
        ply.SangFlying = true
        ply:SetGravity(0.01)
        ply:SetVelocity(Vector(0, 0, 420))
        if C.Smoke and C.Smoke ~= "" then
            ParticleEffectAttach(C.Smoke, PATTACH_ABSORIGIN_FOLLOW, ply, 0)
        end
        ply:EmitSound("ambient/wind/wind_hit3.wav", 78, 100)
    end

    hook.Add("GetFallDamage", "SangFly_NoFall", function(ply)
        if ply.SangFlying then return 0 end
    end)

    hook.Add("PlayerSpawn", "SangFly_Clear", function(ply)
        if ply.SangFlying then SANGSPELL.EndFly(ply) end
    end)

    hook.Add("Tick", "SangFly_Tick", function()
        for ply, d in pairs(SANGSPELL.Flying) do
            if not IsValid(ply) or not ply:Alive() or CurTime() >= d.dieAt then
                SANGSPELL.EndFly(ply)
            elseif (CurTime() - d.started) > 0.4 and (ply:IsOnGround() or ply:WaterLevel() > 2) then
                SANGSPELL.EndFly(ply) -- atterrissage
            else
                local speed = ply:KeyDown(IN_SPEED) and C.SprintSpeed or C.Speed
                ply:SetVelocity((-ply:GetVelocity() + ply:GetAimVector() * speed + VectorRand() * 300) * 0.035)
            end
        end
    end)
end

local Spell = { }
Spell.NodeOffset = Vector(900, 1200, 0)
Spell.CanSelfCast = true
Spell.Description = [[
	Vol Spectral : tu t'envoles dans une
	fumée noire là où tu regardes, pour
	un court instant (pas de dégât de
	chute). S'arrête au sol.
]]

function Spell:OnFire(wand)
    if SERVER and IsValid(self.Owner) then SANGSPELL.StartFly(self.Owner) end
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Nécrotique", mana = C.Mana, cooldown = C.Cooldown,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_apparition",
    whatToSay = "Vol Spectral",
})
HpwRewrite:AddSpell("Vol Spectral", Spell)
