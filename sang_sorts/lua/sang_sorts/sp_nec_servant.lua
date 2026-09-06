--[[-------------------------------------------------------------------------
    Sang et Nuit — « Serviteur »  (Magie Nécrotique / Invocation)
      Lancé sur un CADAVRE FRAIS (PNJ ou joueur mort depuis peu) : fait surgir
      un serviteur (drg_roach_ds1_h) qui attaque tes ennemis mais JAMAIS toi.
      Disparaît au bout d'un moment.
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.NecServant) or { Mana = 45, Cooldown = 25, NPC = "drg_roach_ds1_h", CorpseAge = 30, CorpseDist = 160, Life = 25 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColNecro) or Color(150, 20, 30)

local function notify(ply, msg, kind)
    if BLOOD and BLOOD.Notify then BLOOD.Notify(ply, msg, kind or "info") else ply:ChatPrint("[Sang] " .. msg) end
end

if SERVER then
    -- Registre des cadavres récents (position + heure de mort).
    SANGSPELL.Corpses = SANGSPELL.Corpses or {}
    local function addCorpse(pos)
        -- Purge les cadavres périmés (garde la liste bornée).
        local keep = {}
        for _, c in ipairs(SANGSPELL.Corpses) do
            if (CurTime() - c.t) <= C.CorpseAge then keep[#keep + 1] = c end
        end
        keep[#keep + 1] = { pos = pos, t = CurTime() }
        SANGSPELL.Corpses = keep
    end
    hook.Add("OnNPCKilled", "SangCorpse_NPC", function(npc) if IsValid(npc) then addCorpse(npc:GetPos()) end end)
    hook.Add("PlayerDeath",  "SangCorpse_Ply", function(vic) if IsValid(vic) then addCorpse(vic:GetPos()) end end)

    local function findCorpse(hitpos)
        local best, bestI, bestD = nil, nil, C.CorpseDist
        for i, c in ipairs(SANGSPELL.Corpses) do
            if (CurTime() - c.t) <= C.CorpseAge then
                local d = c.pos:Distance(hitpos)
                if d <= bestD then best, bestI, bestD = c, i, d end
            end
        end
        return best, bestI
    end

    function SANGSPELL.RaiseServant(ply)
        if not IsValid(ply) then return end
        local tr = ply:GetEyeTrace()
        local corpse, idx = findCorpse(tr.HitPos)
        if not corpse then
            notify(ply, "Aucun cadavre frais ici.", "error")
            return false
        end

        local npc = ents.Create(C.NPC)
        if not IsValid(npc) then
            notify(ply, "Serviteur introuvable (" .. tostring(C.NPC) .. ") — addon manquant ?", "error")
            return false
        end
        npc:SetPos(corpse.pos + Vector(0, 0, 8))
        npc:Spawn()
        npc:Activate()
        table.remove(SANGSPELL.Corpses, idx)

        -- Hostile à tout le monde SAUF le lanceur.
        if npc.AddRelationship then npc:AddRelationship("player D_HT 99") end
        if npc.AddEntityRelationship then npc:AddEntityRelationship(ply, D_LI, 99) end
        npc.SangMaster = ply

        local ed = EffectData() ed:SetOrigin(npc:GetPos()) ed:SetScale(2) util.Effect("cball_explode", ed)
        sound.Play("ambient/atmosphere/cave_hit3.wav", npc:GetPos(), 80, 90)

        timer.Simple(C.Life, function()
            if IsValid(npc) then
                local e = EffectData() e:SetOrigin(npc:GetPos()) util.Effect("cball_explode", e)
                npc:Remove()
            end
        end)
        notify(ply, "Serviteur relevé.", "reroll")
        return true
    end

    -- Sécurité : un serviteur ne blesse jamais son maître.
    hook.Add("EntityTakeDamage", "SangServant_NoFF", function(target, dmg)
        local att = dmg:GetAttacker()
        if IsValid(att) and att.SangMaster == target then return true end
    end)
end

local Spell = { }
Spell.NodeOffset = Vector(900, 1500, 0)
Spell.Description = [[
	Serviteur : lance sur un cadavre
	frais (PNJ ou joueur) pour relever un
	serviteur qui combat tes ennemis mais
	jamais toi.
]]

function Spell:OnFire(wand)
    if SERVER and IsValid(self.Owner) then SANGSPELL.RaiseServant(self.Owner) end
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Nécrotique", mana = C.Mana, cooldown = C.Cooldown,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_mostro",
    whatToSay = "Serviteur",
})
HpwRewrite:AddSpell("Serviteur", Spell)
