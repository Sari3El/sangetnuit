--[[-------------------------------------------------------------------------
    Sang et Nuit — Sort « Sang Vif »  (HPW_Rewrite)
      - Aura dorée (golden_energy) autour du lanceur.
      - Pendant ~15 s : court plus vite et saute plus haut.
      - Coûte 25 de mana (système Sang) et a 5 s de cooldown.
    Auto-buff : pas de projectile (OnFire renvoie false).
---------------------------------------------------------------------------]]

if not HpwRewrite then
    MsgN("[Sang Sorts] HpwRewrite introuvable — sort 'Sang Vif' non chargé.")
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

-- Enregistre le pack de particules qui contient l'aura (les 2 réalmes) puis
-- précharge le système. game.AddParticles doit être appelé avant l'usage.
if AURA_PCF and file.Exists(AURA_PCF, "GAME") then
    game.AddParticles(AURA_PCF)
    if SERVER then resource.AddFile(AURA_PCF) end -- au cas où c'est du contenu serveur
else
    MsgN("[Sang Sorts] Fichier de particule introuvable : " .. tostring(AURA_PCF)
        .. " (abonne-toi à l'addon workshop qui le contient).")
end
PrecacheParticleSystem(AURA)

----------------------------------------------------------------------
-- Application / fin du buff (serveur)
----------------------------------------------------------------------
if SERVER then
    -- Stoppe l'aura de façon robuste (StopParticlesNamed n'existe pas partout).
    local function stopAura(ply)
        if not IsValid(ply) then return end
        if ply.StopParticlesNamed then
            ply:StopParticlesNamed(AURA)
        elseif ply.StopParticles then
            ply:StopParticles() -- repli : stoppe toutes les particules du joueur
        end
    end
    SANGSPELL.StopAura = stopAura

    function SANGSPELL.EndSangVif(ply)
        if not IsValid(ply) or not ply.SangVifActive then return end
        ply.SangVifActive = false
        stopAura(ply)
        if not ply:Alive() then return end
        -- Restaure les vitesses/saut d'avant le buff.
        if BLOOD and BLOOD.ApplyComputedStats then
            BLOOD.ApplyComputedStats(ply, false) -- vitesse « normale » recalculée
        else
            ply:SetWalkSpeed(ply.SangVifBaseWalk or 200)
            ply:SetRunSpeed(ply.SangVifBaseRun or 400)
        end
        ply:SetJumpPower(ply.SangVifBaseJump or 200)
        if CFG.EndSound then ply:EmitSound(CFG.EndSound) end
    end

    function SANGSPELL.ApplySangVif(ply)
        if not IsValid(ply) then return end

        -- Mémorise les valeurs d'origine (seulement au 1er lancer, pas au refresh).
        if not ply.SangVifActive then
            ply.SangVifBaseWalk = ply:GetWalkSpeed()
            ply.SangVifBaseRun  = ply:GetRunSpeed()
            ply.SangVifBaseJump = ply:GetJumpPower()
        end
        ply.SangVifActive = true

        ply:SetWalkSpeed(math.Round((ply.SangVifBaseWalk or 200) * (CFG.SpeedMul or 1.5)))
        ply:SetRunSpeed(math.Round((ply.SangVifBaseRun or 400) * (CFG.SpeedMul or 1.5)))
        ply:SetJumpPower(math.Round((ply.SangVifBaseJump or 200) * (CFG.JumpMul or 1.5)))

        -- Aura dorée autour du joueur (réseau auto vers les clients).
        stopAura(ply)
        ParticleEffectAttach(AURA, PATTACH_ABSORIGIN_FOLLOW, ply, 0)
        if CFG.CastSound then ply:EmitSound(CFG.CastSound) end

        -- Fin (rafraîchit le timer si on relance pendant le buff).
        timer.Create("sangvif_" .. ply:EntIndex(), CFG.Duration or 15, 1, function()
            if IsValid(ply) then SANGSPELL.EndSangVif(ply) end
        end)
    end

    -- Un respawn annule proprement le buff (les stats sont réappliquées au spawn).
    hook.Add("PlayerSpawn", "SangVif_ClearOnSpawn", function(ply)
        if ply.SangVifActive then
            ply.SangVifActive = false
            timer.Remove("sangvif_" .. ply:EntIndex())
        end
        stopAura(ply)
    end)
end

----------------------------------------------------------------------
-- Définition du sort
----------------------------------------------------------------------
local Spell = { }
Spell.LearnTime   = 0                      -- appris instantanément (livre => utilisable)
Spell.Category    = (SANGSPELL.Config and SANGSPELL.Config.Category) or "Sang et Nuit"
Spell.CanSelfCast = false                  -- se lance toujours sur soi
Spell.ForceDelay  = CFG.Cooldown or 5      -- cooldown 5 s (client + serveur)
Spell.SpriteColor = Color(255, 200, 60)    -- lueur dorée au bout de la baguette
Spell.WhatToSay   = "Sang Vif"
Spell.NodeOffset  = Vector(0, 900, 0)
Spell.IconMat     = Material("vgui/entities/entity_hpwand_spell_ascendio", "noclamp smooth")
Spell.Description  = [[
	Réveille ton sang : une aura dorée
	t'entoure, tu cours plus vite et
	sautes plus haut pendant 15 secondes.

	Coûte 25 de mana.
]]

-- PreFire : contrôle + débit de la mana (serveur). Renvoyer false annule le sort.
function Spell:PreFire(wand)
    if CLIENT then return true end
    local ply = self.Owner
    if not IsValid(ply) then return false end

    if BLOOD and BLOOD.TakeMana then
        if not BLOOD.TakeMana(ply, CFG.ManaCost or 25) then
            if BLOOD.Notify then
                BLOOD.Notify(ply, "Pas assez de mana (" .. (CFG.ManaCost or 25) .. " requis).", "error")
            else
                ply:ChatPrint("[Sang] Pas assez de mana.")
            end
            return false
        end
    end
    return true
end

-- OnFire : applique le buff sur soi. Renvoie false => aucun projectile.
function Spell:OnFire(wand)
    if SERVER and IsValid(self.Owner) then
        SANGSPELL.ApplySangVif(self.Owner)
    end
    return false
end

HpwRewrite:AddSpell("Sang Vif", Spell)
