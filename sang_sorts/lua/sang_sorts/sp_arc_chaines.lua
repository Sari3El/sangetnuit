--[[-------------------------------------------------------------------------
    Sang et Nuit — « Chaînes Arcaniques »  (Magie Arcanique)
      Projectile qui, à l'impact d'une cible, repousse d'abord les gens AUTOUR
      d'elle (pour éviter d'enchaîner tout un groupe), PUIS immobilise la cible
      touchée quelques secondes (aucun dégât).
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.ArcChaines) or { Mana = 30, Cooldown = 12, Speed = 2400, RootDur = 3, PushRadius = 190, PushForce = 620 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColArcane) or Color(150, 60, 220)

local Spell = { }
Spell.NodeOffset = Vector(-1200, 450, 0)
Spell.Description = [[
	Chaînes Arcaniques : à l'impact,
	repousse les gens autour de la cible
	puis l'immobilise quelques secondes.
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
            -- 1) repousse les AUTRES autour de la cible (la cible est exclue)
            if SANGSPELL.Repulse then SANGSPELL.Repulse(e:WorldSpaceCenter(), C.PushRadius, C.PushForce, e) end
            -- 2) immobilise la cible
            if SANGSPELL.Root then SANGSPELL.Root(e, C.RootDur) end
            local ed = EffectData() ed:SetOrigin(e:WorldSpaceCenter()) util.Effect("cball_explode", ed)
        end,
    })
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Arcanique", mana = C.Mana, cooldown = C.Cooldown,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_immobulus",
    whatToSay = "Chaînes Arcaniques",
})
HpwRewrite:AddSpell("Chaînes Arcaniques", Spell)
