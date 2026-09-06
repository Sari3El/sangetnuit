--[[-------------------------------------------------------------------------
    Sang et Nuit — « Symbiose »  (Magie Druidique)
      Le miroir du Drain de Vie : projectile vers un ALLIÉ -> lien vert qui le
      SOIGNE sur la durée (se coupe si trop loin).
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.DruidSymb) or { Mana = 30, Cooldown = 12, Speed = 2600, Duration = 8, MaxLink = 800, Hps = 6 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColDruid) or Color(90, 200, 80)

local Spell = { }
Spell.NodeOffset = Vector(300, 900, 0)
Spell.Description = [[
	Symbiose : un lien vert vers un allié
	le soigne sur la durée, tant qu'il ne
	s'éloigne pas trop.
]]

function Spell:OnFire(wand)
    if not SERVER then return false end
    local ply = self.Owner
    if not IsValid(ply) then return false end

    local b = ents.Create("sang_bolt")
    if not IsValid(b) then return false end
    b:Spawn() b:Activate()
    b:SetupBolt(ply, ply:GetAimVector(), {
        speed = C.Speed, life = 4, color = COL, hitWorld = false,
        onHit = function(tr)
            local e = tr.Entity
            if not (IsValid(e) and (e:IsPlayer() or e:IsNPC())) then return end
            local link = ents.Create("sang_link")
            if IsValid(link) then
                link:SetPos((ply:WorldSpaceCenter() + e:WorldSpaceCenter()) * 0.5)
                link:Spawn() link:Activate()
                link:SetupLink(ply, e, { dur = C.Duration, maxDist = C.MaxLink, mode = "heal", hps = C.Hps, color = COL })
            end
        end,
    })
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Druidique", mana = C.Mana, cooldown = C.Cooldown,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_episkey",
    whatToSay = "Symbiose",
})
HpwRewrite:AddSpell("Symbiose", Spell)
