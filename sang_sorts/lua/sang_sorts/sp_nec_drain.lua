--[[-------------------------------------------------------------------------
    Sang et Nuit — « Drain de Vie »  (Magie Nécrotique)
      Projectile de sang : à l'impact d'une cible vivante, un LIEN ROUGE se crée
      entre toi et elle — il draine sa vie et te soigne, tant qu'elle n'est pas
      trop loin (sinon le lien se coupe).
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.NecDrain) or { Mana = 20, Cooldown = 6, Speed = 2600, Duration = 6, MaxLink = 700, Dps = 8, HealRatio = 0.5 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColNecro) or Color(150, 20, 30)

local Spell = { }
Spell.NodeOffset = Vector(0, 1200, 0)
Spell.Description = [[
	Drain de Vie : un trait de sang crée
	un lien avec la cible touchée, draine
	sa vie et te soigne. Le lien se coupe
	si elle s'éloigne trop.
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
                link:SetupLink(ply, e, C.Duration, C.MaxLink, C.Dps, C.HealRatio)
            end
        end,
    })
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Nécrotique", mana = C.Mana, cooldown = C.Cooldown,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_crucio",
    whatToSay = "Drain de Vie",
})
HpwRewrite:AddSpell("Drain de Vie", Spell)
