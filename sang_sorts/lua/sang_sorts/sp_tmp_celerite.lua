--[[-------------------------------------------------------------------------
    Sang et Nuit — « Célérité »  (Magie Temporelle)
      Auto-buff : tu accélères le temps pour toi — cours plus vite, sautes plus
      haut et tes cooldowns sont réduits pendant la durée.
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.TmpCelerite) or { Mana = 25, Cooldown = 15, Duration = 10, SpeedMul = 1.4, JumpMul = 1.3, HasteCD = 0.6 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColTemps) or Color(80, 160, 255)

if SERVER then
    function SANGSPELL.EndCelerite(ply)
        if not IsValid(ply) or not ply.SangCelerite then return end
        ply.SangCelerite = nil
        ply.SangHasteCD = nil
        if not ply:Alive() then return end
        ply:SetWalkSpeed(ply.SangCelBase and ply.SangCelBase.w or 200)
        ply:SetRunSpeed(ply.SangCelBase and ply.SangCelBase.r or 400)
        ply:SetJumpPower(ply.SangCelBase and ply.SangCelBase.j or 200)
        ply:EmitSound("ambient/levels/labs/electric_explosion5.wav", 60, 130)
    end

    function SANGSPELL.Celerite(ply)
        if not IsValid(ply) then return end
        if not ply.SangCelerite then
            ply.SangCelBase = { w = ply:GetWalkSpeed(), r = ply:GetRunSpeed(), j = ply:GetJumpPower() }
        end
        ply.SangCelerite = true
        ply.SangHasteCD  = C.HasteCD
        ply:SetWalkSpeed(math.Round(ply.SangCelBase.w * C.SpeedMul))
        ply:SetRunSpeed(math.Round(ply.SangCelBase.r * C.SpeedMul))
        ply:SetJumpPower(math.Round(ply.SangCelBase.j * C.JumpMul))
        ply:EmitSound("ambient/levels/labs/teleport_preblast_thunder1.wav", 65, 130)
        timer.Create("SangCelerite_" .. ply:EntIndex(), C.Duration, 1, function()
            if IsValid(ply) then SANGSPELL.EndCelerite(ply) end
        end)
    end

    hook.Add("PlayerSpawn", "SangCelerite_Clear", function(ply)
        ply.SangCelerite = nil ply.SangHasteCD = nil
    end)
end

local Spell = { }
Spell.NodeOffset = Vector(900, 300, 0)
Spell.CanSelfCast = true
Spell.Description = [[
	Célérité : le temps accélère pour toi
	— vitesse, saut et cooldowns réduits
	pendant la durée.
]]

function Spell:OnFire(wand)
    if SERVER and IsValid(self.Owner) then SANGSPELL.Celerite(self.Owner) end
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Temporelle", mana = C.Mana, cooldown = C.Cooldown,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_ascendio",
    whatToSay = "Célérité",
})
HpwRewrite:AddSpell("Célérité", Spell)
