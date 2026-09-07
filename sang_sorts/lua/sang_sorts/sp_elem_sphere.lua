--[[-------------------------------------------------------------------------
    Sang et Nuit — « Sphère des Éléments »  (Magie Élémentaire)
      T'enferme dans une grande sphère de protection (vent/feu/eau/terre) :
      tu es INVULNÉRABLE dedans et elle repousse les ennemis. Tu la désactives
      toi-même (relance) ou elle s'arrête au bout de la durée (15 s).
      (Gère sa propre mana/cooldown.)
---------------------------------------------------------------------------]]

if not HpwRewrite then return end
SANGSPELL = SANGSPELL or {}
local C = (SANGSPELL.Config and SANGSPELL.Config.ElemSphere) or { Mana = 45, Cooldown = 25, Duration = 15, Radius = 150, PushForce = 650 }
local COL = (SANGSPELL.Config and SANGSPELL.Config.ColElem) or Color(255, 140, 30)
local FX = (SANGSPELL.Config and SANGSPELL.Config.Fx) or {}

local function notify(ply, msg, kind)
    if BLOOD and BLOOD.Notify then BLOOD.Notify(ply, msg, kind or "info") else ply:ChatPrint("[Sang] " .. msg) end
end

if SERVER then
    function SANGSPELL.EndSphere(ply)
        if not IsValid(ply) then return end
        if IsValid(ply.SangSphereEnt) then ply.SangSphereEnt:Remove() end
        ply.SangSphereEnt = nil
        if ply.SangSphereGod then ply:GodDisable() ply.SangSphereGod = nil end
        timer.Remove("SangSphere_" .. ply:EntIndex())
    end

    function SANGSPELL.ToggleSphere(ply)
        if not IsValid(ply) or not ply:Alive() then return end

        -- Déjà active -> on désactive (gratuit).
        if IsValid(ply.SangSphereEnt) then
            SANGSPELL.EndSphere(ply)
            notify(ply, "Sphère des Éléments désactivée.", "info")
            return
        end

        -- Sinon : cooldown propre + mana.
        if ply.SangSphereCD and CurTime() < ply.SangSphereCD then
            notify(ply, "Sphère en recharge (" .. math.ceil(ply.SangSphereCD - CurTime()) .. "s).", "error")
            return
        end
        if (C.Mana or 0) > 0 and BLOOD and BLOOD.TakeMana then
            if not BLOOD.TakeMana(ply, C.Mana) then notify(ply, "Pas assez de mana.", "error") return end
        end
        ply.SangSphereCD = CurTime() + C.Cooldown

        local s = ents.Create("sang_elemsphere")
        if not IsValid(s) then return end
        s:SetPos(ply:WorldSpaceCenter())
        s:Spawn() s:Activate()
        s:SetupSphere(ply, C.Radius, C.PushForce, C.Duration, FX.ElemSphereWind, FX.ElemSphereFire)
        ply.SangSphereEnt = s
        ply:GodEnable() ply.SangSphereGod = true
        ply:EmitSound("ambient/energy/whiteflash.wav", 80, 90)
        notify(ply, "Sphère des Éléments : invulnérable " .. C.Duration .. "s (relance pour arrêter).", "reroll")

        timer.Create("SangSphere_" .. ply:EntIndex(), C.Duration, 1, function()
            if IsValid(ply) then SANGSPELL.EndSphere(ply) end
        end)
    end

    hook.Add("PlayerSpawn", "SangSphere_Clear", function(ply)
        if IsValid(ply.SangSphereEnt) or ply.SangSphereGod then SANGSPELL.EndSphere(ply) end
    end)
end

local Spell = { }
Spell.NodeOffset = Vector(1200, 1200, 0)
Spell.CanSelfCast = true
Spell.Description = [[
	Sphère des Éléments : une bulle de
	protection t'entoure — invulnérable
	et repousse les ennemis. Relance pour
	l'arrêter, ou 15 s max.
]]

function Spell:OnFire(wand)
    if SERVER and IsValid(self.Owner) then SANGSPELL.ToggleSphere(self.Owner) end
    return false
end

SANGSPELL.PrepareSpell(Spell, {
    category = "Magie Élémentaire", mana = 0, cooldown = 0,
    color = COL, icon = "vgui/entities/entity_hpwand_spell_protego",
    whatToSay = "Sphère des Éléments",
})
HpwRewrite:AddSpell("Sphère des Éléments", Spell)
