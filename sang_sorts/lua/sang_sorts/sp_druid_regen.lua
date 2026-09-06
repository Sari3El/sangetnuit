--[[-------------------------------------------------------------------------
    Sang et Nuit — « Régénération »  (Magie Druidique)
      Soin sur la durée (HoT) : sur toi, ou sur l'allié que tu vises.
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.DruidRegen) or { Mana = 25, Cooldown = 12, Hps = 4, Duration = 6, Range = 1300 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColDruid) or Color(90, 200, 80)

local Spell = { }
Spell.NodeOffset = Vector(-300, 1200, 0)
Spell.CanSelfCast = true
Spell.Description = [[
	Régénération : soigne sur la durée
	toi-même, ou l'allié que tu vises.
]]

function Spell:OnFire(wand)
    if not SERVER then return false end
    local ply = self.Owner
    if not IsValid(ply) then return false end

    local target = ply
    local tr = ply:GetEyeTrace()
    local e = tr.Entity
    if IsValid(e) and (e:IsPlayer() or e:IsNPC()) and e:Health() > 0
       and ply:GetPos():Distance(e:GetPos()) <= C.Range then
        target = e
    end

    local id = "SangRegen_" .. target:EntIndex()
    timer.Create(id, 1, math.floor(C.Duration), function()
        if IsValid(target) and target:Health() > 0 and SANGSPELL.Heal then
            SANGSPELL.Heal(target, C.Hps)
        end
    end)
    target:EmitSound("items/smallmedkit1.wav", 70, 110)
    if BLOOD and BLOOD.Notify and target == ply then BLOOD.Notify(ply, "Régénération active.", "info") end
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Druidique", mana = C.Mana, cooldown = C.Cooldown,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_episkey",
    whatToSay = "Régénération",
})
HpwRewrite:AddSpell("Régénération", Spell)
