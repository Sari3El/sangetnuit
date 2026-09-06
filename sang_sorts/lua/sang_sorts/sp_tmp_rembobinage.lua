--[[-------------------------------------------------------------------------
    Sang et Nuit — « Rembobinage »  (Magie Temporelle)
      Tu déposes une « encre temporelle » à ta position (avec tes PV du moment).
        - 1er lancer : pose l'encre.
        - 2e lancer  : tu RETOURNES à l'encre (position + PV d'alors).
      Règles :
        - l'encre disparaît au bout de InkLife s (fenêtre pour revenir) ;
        - tu ne peux pas revenir avant MinReturn s après l'avoir posée ;
        - reposer une encre = cooldown réel (PlaceCooldown, ex. 60 s).
      (Gère sa propre mana/cooldown : le gate générique est neutralisé.)
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.TmpRembob) or { Mana = 40, PlaceCooldown = 60, InkLife = 30, MinReturn = 15 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColTemps) or Color(80, 160, 255)

local function notify(ply, msg, kind)
    if BLOOD and BLOOD.Notify then BLOOD.Notify(ply, msg, kind or "info") else ply:ChatPrint("[Sang] " .. msg) end
end

if SERVER then
    local function clearInk(ply)
        if ply.SangEncre and IsValid(ply.SangEncre.ent) then ply.SangEncre.ent:Remove() end
        ply.SangEncre = nil
    end

    function SANGSPELL.Rembobinage(ply)
        if not IsValid(ply) or not ply:Alive() then return end
        local now = CurTime()
        local enc = ply.SangEncre

        -- RETOUR à l'encre.
        if enc then
            local age = now - enc.placed
            if age < C.MinReturn then
                notify(ply, "L'encre n'est pas encore stable (" .. math.ceil(C.MinReturn - age) .. "s).", "error")
                return
            end
            local ed = EffectData() ed:SetOrigin(ply:WorldSpaceCenter()) util.Effect("cball_explode", ed)
            ply:SetPos(enc.pos)
            ply:SetVelocity(-ply:GetVelocity())
            ply:SetHealth(math.min(ply:GetMaxHealth(), enc.hp))
            clearInk(ply)
            local ed2 = EffectData() ed2:SetOrigin(ply:WorldSpaceCenter()) util.Effect("cball_explode", ed2)
            ply:EmitSound("ambient/levels/labs/teleport_mechanism_windup1.wav", 72, 130)
            notify(ply, "Tu es revenu à ton encre temporelle.", "reroll")
            return
        end

        -- POSE d'une nouvelle encre (soumise au cooldown réel + mana).
        if ply.SangEncreCD and now < ply.SangEncreCD then
            notify(ply, "Rembobinage en recharge (" .. math.ceil(ply.SangEncreCD - now) .. "s).", "error")
            return
        end
        if (C.Mana or 0) > 0 and BLOOD and BLOOD.TakeMana then
            if not BLOOD.TakeMana(ply, C.Mana) then
                notify(ply, "Pas assez de mana (" .. C.Mana .. " requis).", "error")
                return
            end
        end
        ply.SangEncreCD = now + C.PlaceCooldown

        local ent = ents.Create("sang_zone")
        if IsValid(ent) then
            ent:SetPos(ply:GetPos())
            ent:Spawn() ent:Activate()
            ent:SetupZone(ply, "corrosion", 40, 0, C.InkLife, COL) -- amount 0 = visuel seul
        end
        ply.SangEncre = { pos = ply:GetPos(), hp = ply:Health(), placed = now, ent = ent }
        ply:EmitSound("ambient/levels/labs/teleport_mechanism_windup3.wav", 68, 130)
        notify(ply, "Encre temporelle posée (retour possible dans " .. C.MinReturn .. "s, disparaît dans " .. C.InkLife .. "s).", "info")

        timer.Create("SangEncreExpire_" .. ply:EntIndex(), C.InkLife, 1, function()
            if IsValid(ply) and ply.SangEncre and (CurTime() - ply.SangEncre.placed) >= C.InkLife - 0.1 then
                clearInk(ply)
            end
        end)
    end

    hook.Add("PlayerSpawn", "SangEncre_Clear", function(ply) clearInk(ply) end)
end

local Spell = { }
Spell.NodeOffset = Vector(1200, 450, 0)
Spell.CanSelfCast = true
Spell.Description = [[
	Rembobinage : pose une encre
	temporelle. Relance pour y revenir
	(position + PV d'alors). Retour
	possible après un délai ; l'encre
	disparaît si tu attends trop.
]]

function Spell:OnFire(wand)
    if SERVER and IsValid(self.Owner) then SANGSPELL.Rembobinage(self.Owner) end
    return false
end

-- Mana/cooldown gérés manuellement ci-dessus → on neutralise le gate générique.
SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Temporelle", mana = 0, cooldown = 0,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_timesum",
    whatToSay = "Rembobinage",
})
HpwRewrite:AddSpell("Rembobinage", Spell)
