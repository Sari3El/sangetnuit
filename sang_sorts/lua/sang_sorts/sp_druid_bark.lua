--[[-------------------------------------------------------------------------
    Sang et Nuit — « Épines »  (Magie Druidique)
      Auto-sort : pendant la durée, une partie des dégâts que tu subis est
      RENVOYÉE à l'attaquant (peau d'épines).
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.DruidBark) or { Mana = 30, Cooldown = 14, ReflectPct = 0.4, Duration = 6 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColDruid) or Color(90, 200, 80)

if SERVER and not SANGSPELL._ThornsHook then
    SANGSPELL._ThornsHook = true
    hook.Add("EntityTakeDamage", "SangThorns", function(victim, dmginfo)
        if SANGSPELL._inThorns then return end
        if not (IsValid(victim) and victim:IsPlayer()) then return end
        if not victim.SangThorns or (victim.SangThornsUntil or 0) < CurTime() then return end
        local att = dmginfo:GetAttacker()
        if not (IsValid(att) and att ~= victim and (att:IsPlayer() or att:IsNPC())) then return end
        local dmg = dmginfo:GetDamage()
        if dmg <= 0 then return end
        SANGSPELL._inThorns = true
        SANGSPELL.DealDamage(victim, att, dmg * victim.SangThorns, SANGSPELL.MAGIC, victim)
        SANGSPELL._inThorns = false
    end)
end

local Spell = { }
Spell.NodeOffset = Vector(0, 900, 0)
Spell.CanSelfCast = true
Spell.Description = [[
	Épines : pendant un temps, une partie
	des dégâts que tu subis est renvoyée
	à l'attaquant.
]]

function Spell:OnFire(wand)
    if not SERVER then return false end
    local ply = self.Owner
    if not IsValid(ply) then return false end
    ply.SangThorns = C.ReflectPct
    ply.SangThornsUntil = CurTime() + C.Duration
    ply:EmitSound("ambient/materials/rustle3.wav", 70, 100)
    if BLOOD and BLOOD.Notify then BLOOD.Notify(ply, "Épines : renvoi de dégâts actif.", "info") end
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Druidique", mana = C.Mana, cooldown = C.Cooldown,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_protego",
    whatToSay = "Épines",
})
HpwRewrite:AddSpell("Épines", Spell)
