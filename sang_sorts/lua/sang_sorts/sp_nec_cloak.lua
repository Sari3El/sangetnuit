--[[-------------------------------------------------------------------------
    Sang et Nuit — « Manteau d'Ombre »  (Magie Nécrotique / Ténèbres)
      Auto-sort : tu deviens semi-invisible, tu sautes plus haut et tu laisses
      une traînée d'ombre derrière toi pendant la durée.
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.NecCloak) or { Mana = 30, Cooldown = 16, Duration = 6, Alpha = 55, JumpMul = 1.4 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColNecro) or Color(150, 20, 30)

if SERVER then
    function SANGSPELL.EndCloak(ply)
        if not IsValid(ply) or not ply.SangCloak then return end
        ply.SangCloak = nil
        ply:SetRenderMode(RENDERMODE_NORMAL)
        ply:SetColor(Color(255, 255, 255, 255))
        if ply:Alive() then ply:SetJumpPower(ply.SangCloakJump or 200) end
        if IsValid(ply.SangCloakTrail) then ply.SangCloakTrail:Remove() end
        ply.SangCloakTrail = nil
        ply:EmitSound("ambient/levels/labs/electric_explosion1.wav", 55, 150)
    end

    function SANGSPELL.Cloak(ply)
        if not IsValid(ply) then return end
        if not ply.SangCloak then ply.SangCloakJump = ply:GetJumpPower() end
        ply.SangCloak = true
        ply:SetRenderMode(RENDERMODE_TRANSALPHA)
        ply:SetColor(Color(70, 70, 90, C.Alpha))
        ply:SetJumpPower(math.Round((ply.SangCloakJump or 200) * C.JumpMul))
        if IsValid(ply.SangCloakTrail) then ply.SangCloakTrail:Remove() end
        ply.SangCloakTrail = util.SpriteTrail(ply, 0, Color(30, 10, 40), true, 26, 4, C.Duration, 1 / 24, "trails/smoke.vmt")
        ply:EmitSound("ambient/levels/labs/electric_explosion2.wav", 60, 150)
        timer.Create("SangCloak_" .. ply:EntIndex(), C.Duration, 1, function()
            if IsValid(ply) then SANGSPELL.EndCloak(ply) end
        end)
    end

    hook.Add("PlayerSpawn", "SangCloak_Clear", function(ply)
        if ply.SangCloak then SANGSPELL.EndCloak(ply) end
    end)
end

local Spell = { }
Spell.NodeOffset = Vector(600, 1500, 0)
Spell.CanSelfCast = true
Spell.Description = [[
	Manteau d'Ombre : tu deviens
	semi-invisible, sautes plus haut et
	laisses une traînée d'ombre.
]]

function Spell:OnFire(wand)
    if SERVER and IsValid(self.Owner) then SANGSPELL.Cloak(self.Owner) end
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Nécrotique", mana = C.Mana, cooldown = C.Cooldown,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_fumos",
    whatToSay = "Manteau d'Ombre",
})
HpwRewrite:AddSpell("Manteau d'Ombre", Spell)
