--[[-------------------------------------------------------------------------
    Sang et Nuit — « Météore »  (Magie Élémentaire)
      Un météore s'écrase au point visé : grosse explosion de zone (feu) +
      met le feu aux êtres proches.
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.ElemMeteor) or { Mana = 45, Cooldown = 16, Radius = 230, Damage = 55, Height = 1400, Speed = 2800 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColElem) or Color(255, 140, 30)

local Spell = { }
Spell.NodeOffset = Vector(600, 1200, 0)
Spell.Description = [[
	Météore : une roche enflammée
	s'écrase là où tu vises — grosse
	explosion de zone + met le feu.
]]

function Spell:OnFire(wand)
    if not SERVER then return false end
    local ply = self.Owner
    if not IsValid(ply) then return false end

    local tr = ply:GetEyeTrace()
    local ground = tr.HitPos

    local function impact(pos)
        local ed = EffectData() ed:SetOrigin(pos) ed:SetScale(C.Radius) ed:SetMagnitude(2) util.Effect("cball_explode", ed)
        util.ScreenShake(pos, 10, 130, 1, C.Radius * 3)
        sound.Play("ambient/explosions/explode_7.wav", pos, 95, 95)
        for _, e in ipairs(SANGSPELL.LivingInSphere(pos, C.Radius, function(e) return e ~= ply end)) do
            SANGSPELL.DealDamage(ply, e, C.Damage, DMG_BURN, ply)
            if e.Ignite then e:Ignite(4) end
        end
    end

    -- Météore qui tombe (réutilise le projectile droit, vers le bas).
    local mb = ents.Create("sang_bolt")
    if IsValid(mb) then
        mb:SetPos(ground + Vector(0, 0, C.Height))
        mb:Spawn() mb:Activate()
        mb:SetupBolt(nil, Vector(0, 0, -1), {
            speed = C.Speed, life = 3, color = COL,
            onHit = function(t) impact(t.HitPos) end,
            onExpire = function(p) impact(p) end,
        })
        mb:SetPos(ground + Vector(0, 0, C.Height))
    else
        impact(ground)
    end
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Élémentaire", mana = C.Mana, cooldown = C.Cooldown,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_bombarda_maxima",
    whatToSay = "Météore",
})
HpwRewrite:AddSpell("Météore", Spell)
