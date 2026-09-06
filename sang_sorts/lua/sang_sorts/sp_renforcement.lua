--[[-------------------------------------------------------------------------
    Sang et Nuit — Sort « Renforcement Sacré »  (Magie Sacré)
      Aura dorée (golden_energy) + court plus vite et saute plus haut ~15 s.
      25 mana, cooldown 5 s. Auto-buff (aucun projectile).
---------------------------------------------------------------------------]]

if not HpwRewrite then
    MsgN("[Sang Sorts] HpwRewrite introuvable — 'Renforcement Sacré' non chargé.")
    return
end

SANGSPELL = SANGSPELL or {}
local CFG = (SANGSPELL.Config and SANGSPELL.Config.SangVif) or {
    ManaCost = 25, Cooldown = 5, Duration = 15, SpeedMul = 1.5, JumpMul = 1.5,
    Aura = "[4]_golden_energy", AuraPcf = "particles/cruel_base2.pcf",
    CastSound = "items/suitchargeok1.wav", EndSound = "items/suitchargeno1.wav",
}
local AURA = CFG.Aura or "[4]_golden_energy"
local AURA_PCF = CFG.AuraPcf or "particles/cruel_base2.pcf"

if AURA_PCF and file.Exists(AURA_PCF, "GAME") then
    game.AddParticles(AURA_PCF)
    if SERVER then resource.AddFile(AURA_PCF) end
end
PrecacheParticleSystem(AURA)

if SERVER then
    local function stopAura(ply)
        if not IsValid(ply) then return end
        if ply.StopParticlesNamed then ply:StopParticlesNamed(AURA)
        elseif ply.StopParticles then ply:StopParticles() end
    end

    function SANGSPELL.EndRenfort(ply)
        if not IsValid(ply) or not ply.SangRenfortActive then return end
        ply.SangRenfortActive = false
        stopAura(ply)
        if not ply:Alive() then return end
        if BLOOD and BLOOD.ApplyComputedStats then
            BLOOD.ApplyComputedStats(ply, false)
        else
            ply:SetWalkSpeed(ply.SangRenfortBaseWalk or 200)
            ply:SetRunSpeed(ply.SangRenfortBaseRun or 400)
        end
        ply:SetJumpPower(ply.SangRenfortBaseJump or 200)
        if CFG.EndSound then ply:EmitSound(CFG.EndSound) end
    end

    function SANGSPELL.ApplyRenfort(ply)
        if not IsValid(ply) then return end
        if not ply.SangRenfortActive then
            ply.SangRenfortBaseWalk = ply:GetWalkSpeed()
            ply.SangRenfortBaseRun  = ply:GetRunSpeed()
            ply.SangRenfortBaseJump = ply:GetJumpPower()
        end
        ply.SangRenfortActive = true

        ply:SetWalkSpeed(math.Round((ply.SangRenfortBaseWalk or 200) * (CFG.SpeedMul or 1.5)))
        ply:SetRunSpeed(math.Round((ply.SangRenfortBaseRun or 400) * (CFG.SpeedMul or 1.5)))
        ply:SetJumpPower(math.Round((ply.SangRenfortBaseJump or 200) * (CFG.JumpMul or 1.5)))

        stopAura(ply)
        ParticleEffectAttach(AURA, PATTACH_ABSORIGIN_FOLLOW, ply, 0)
        if CFG.CastSound then ply:EmitSound(CFG.CastSound) end

        timer.Create("sangrenfort_" .. ply:EntIndex(), CFG.Duration or 15, 1, function()
            if IsValid(ply) then SANGSPELL.EndRenfort(ply) end
        end)
    end

    hook.Add("PlayerSpawn", "SangRenfort_ClearOnSpawn", function(ply)
        if ply.SangRenfortActive then
            ply.SangRenfortActive = false
            timer.Remove("sangrenfort_" .. ply:EntIndex())
        end
        if ply.StopParticlesNamed then ply:StopParticlesNamed(AURA)
        elseif ply.StopParticles then ply:StopParticles() end
    end)
end

local Spell = { }
Spell.NodeOffset  = Vector(0, 900, 0)
Spell.Description  = [[
	Réveille ton sang : une aura dorée
	t'entoure, tu cours plus vite et
	sautes plus haut pendant 15 secondes.

	Coûte 25 de mana.
]]

function Spell:OnFire(wand)
    if SERVER and IsValid(self.Owner) then
        SANGSPELL.ApplyRenfort(self.Owner)
    end
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category  = "Magie Sacré",
    mana      = CFG.ManaCost or 25,
    cooldown  = CFG.Cooldown or 5,
    color     = Color(255, 200, 60),
    icon      = "vgui/entities/entity_hpwand_spell_ascendio",
    whatToSay = "Renforcement Sacré",
})

HpwRewrite:AddSpell("Renforcement Sacré", Spell)
