--[[-------------------------------------------------------------------------
    Sang et Nuit — « Éclair en Chaîne »  (Magie Élémentaire)
      La foudre frappe la 1re cible visée puis SAUTE vers les ennemis proches
      (quelques rebonds), avec des dégâts décroissants.
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.ElemChain) or { Mana = 25, Cooldown = 8, Damage = 25, Bounces = 3, JumpRange = 360, Falloff = 0.7, Range = 1500 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColElem) or Color(255, 140, 30)

local Spell = { }
Spell.NodeOffset = Vector(300, 1200, 0)
Spell.Description = [[
	Éclair en Chaîne : la foudre frappe
	ta cible puis rebondit sur les
	ennemis proches (dégâts décroissants).
]]

function Spell:OnFire(wand)
    if not SERVER then return false end
    local ply = self.Owner
    if not IsValid(ply) then return false end

    local eyes = ply:GetShootPos()
    local tr = util.TraceLine({ start = eyes, endpos = eyes + ply:GetAimVector() * C.Range, filter = ply, mask = MASK_SHOT })
    local first = tr.Entity
    if not (IsValid(first) and (first:IsPlayer() or first:IsNPC())) then
        -- rien touché : petit éclair dans le vide
        return false
    end

    local hit = {}
    local pts = { eyes, first:WorldSpaceCenter() }
    local cur, dmg = first, C.Damage
    for i = 1, C.Bounces + 1 do
        if not IsValid(cur) then break end
        SANGSPELL.DealDamage(ply, cur, dmg, SANGSPELL.MAGIC, ply)
        hit[cur] = true
        dmg = dmg * C.Falloff

        -- cherche le prochain ennemi le plus proche non encore touché
        local nextE, nextD = nil, C.JumpRange
        for _, e in ipairs(ents.FindInSphere(cur:WorldSpaceCenter(), C.JumpRange)) do
            if IsValid(e) and not hit[e] and e ~= ply and (e:IsPlayer() or e:IsNPC()) and e:Health() > 0 then
                local d = e:WorldSpaceCenter():Distance(cur:WorldSpaceCenter())
                if d < nextD then nextE, nextD = e, d end
            end
        end
        if not nextE then break end
        pts[#pts + 1] = nextE:WorldSpaceCenter()
        cur = nextE
    end

    net.Start("sang_chain")
        net.WriteUInt(#pts, 5)
        for _, p in ipairs(pts) do net.WriteVector(p) end
        net.WriteUInt(COL.r, 8) net.WriteUInt(COL.g, 8) net.WriteUInt(COL.b, 8)
    net.Broadcast()
    ply:EmitSound("ambient/energy/zap" .. math.random(1, 3) .. ".wav", 80, 100)
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Élémentaire", mana = C.Mana, cooldown = C.Cooldown,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_reducto",
    whatToSay = "Éclair en Chaîne",
})
HpwRewrite:AddSpell("Éclair en Chaîne", Spell)
