--[[-------------------------------------------------------------------------
    Sang et Nuit — HUD médiéval (or / noir / rouge, style sobre)
      - Aperçu 3D du model actuel, DE FACE (pas de rotation)
      - Barre de PV, barre d'Armure
      - Barre de Mana (uniquement race Sorcier)
    Utilise le thème commun BLOOD.UI. Masque le HUD santé/armure par défaut.
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}
local UI = BLOOD.UI
local C = UI.Col
local S = UI.Scale

----------------------------------------------------------------------
-- Masquer le HUD par défaut (santé + armure)
----------------------------------------------------------------------
local hideDefault = { CHudHealth = true, CHudBattery = true }
hook.Add("HUDShouldDraw", "BLOOD_HideDefaultHUD", function(name)
    if hideDefault[name] then return false end
end)

----------------------------------------------------------------------
-- Aperçu 3D du model (DModelPanel persistant, DE FACE)
----------------------------------------------------------------------
local modelPanel

local function frameModel(mdl)
    local ent = mdl:GetEntity()
    if not IsValid(ent) then return end
    -- pose d'idle
    local seq = ent:LookupSequence("idle_all_01")
    if not seq or seq < 0 then seq = ent:SelectWeightedSequence(ACT_HL2MP_IDLE) end
    if seq and seq >= 0 then ent:ResetSequence(seq) end
    -- cadrage caméra face au model
    local mn, mx = ent:GetRenderBounds()
    local center = (mn + mx) * 0.5
    local dist = mn:Distance(mx)
    mdl:SetLookAt(center)
    mdl:SetCamPos(center + Vector(dist * 0.92, 0, dist * 0.04))
    mdl:SetFOV(38)
end

local function ensureModelPanel()
    if IsValid(modelPanel) then return modelPanel end

    modelPanel = vgui.Create("DModelPanel")
    modelPanel:SetMouseInputEnabled(false)
    modelPanel:SetKeyboardInputEnabled(false)
    modelPanel:SetModel(LocalPlayer():GetModel())
    modelPanel.CurModel = LocalPlayer():GetModel()

    -- DE FACE, sans rotation ; seulement l'animation d'idle (respiration)
    modelPanel.LayoutEntity = function(self, ent)
        ent:SetAngles(Angle(0, 0, 0))
        self:RunAnimation()
    end

    -- fond sombre dégradé derrière le model (portrait réaliste)
    local basePaint = modelPanel.Paint
    modelPanel.Paint = function(self, w, h)
        UI.VGradient(0, 0, w, h, UI.Shade(C.bg2, -6), C.ink)
        basePaint(self, w, h)
    end
    -- léger vignettage + cadre
    modelPanel.PaintOver = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 90)
        surface.DrawOutlinedRect(0, 0, w, h, S(6))
        surface.SetDrawColor(C.goldDk)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        UI.CornerBrackets(0, 0, w, h, S(10), C.gold)
    end

    frameModel(modelPanel)
    return modelPanel
end

----------------------------------------------------------------------
-- Valeurs animées (lissage)
----------------------------------------------------------------------
local anim = { hp = 1, armor = 0, mana = 1 }

----------------------------------------------------------------------
-- Rendu du HUD
----------------------------------------------------------------------
hook.Add("HUDPaint", "BLOOD_HUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    if not ply:Alive() then
        if IsValid(modelPanel) then modelPanel:SetVisible(false) end
        return
    end

    -- Race active (détermine le nombre de barres)
    local raceId   = ply:GetNWString("blood_race", "human")
    local raceData = BLOOD.Races and BLOOD.Races[raceId]
    local slotData = BLOOD.MyData and BLOOD.MyData.slots and BLOOD.MyData.slots[BLOOD.MyData.activeSlot]
    local persoName = (slotData and slotData.name) or ply:Nick()
    local isSorcier = (raceId == "sorcier")
    local nBars = isSorcier and 3 or 2

    -- Layout (coin bas-gauche), hauteur adaptée au nombre de barres
    local pad  = S(14)
    local barH = S(22)
    local gap  = S(8)
    local topH = S(54) -- nom + race + filet
    local w    = S(366)
    local h    = pad + topH + (nBars * barH + (nBars - 1) * gap) + pad
    local x    = S(24)
    local y    = ScrH() - h - S(24)

    UI.Panel(x, y, w, h)

    -- Model (à gauche, pleine hauteur)
    local mW = S(98)
    local mH = h - pad * 2
    local mX = x + pad
    local mY = y + pad

    local mdl = ensureModelPanel()
    if mdl.CurModel ~= ply:GetModel() then
        mdl:SetModel(ply:GetModel())
        mdl.CurModel = ply:GetModel()
        frameModel(mdl)
    end
    mdl:SetVisible(true)
    mdl:SetPos(mX, mY)
    mdl:SetSize(mW, mH)

    -- Colonne de droite
    local bx = mX + mW + S(14)
    local bw = (x + w - pad) - bx

    draw.SimpleText(persoName, "SangUI_Title", bx + 1, y + pad + 1, C.shadow, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(persoName, "SangUI_Title", bx,     y + pad,     C.txt,    TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(raceData and raceData.name or raceId, "SangUI_Small",
        bx, y + pad + S(26), C.goldLt, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    surface.SetDrawColor(C.goldDk)
    surface.DrawRect(bx, y + pad + S(46), bw, 1)

    local by = y + pad + topH

    -- PV
    local hp, hpMax = ply:Health(), math.max(1, ply:GetMaxHealth())
    anim.hp = Lerp(FrameTime() * 8, anim.hp, math.Clamp(hp / hpMax, 0, 1))
    UI.Bar(bx, by, bw, barH, anim.hp, C.blood, C.bloodLt, "PV", math.max(0, hp) .. " / " .. hpMax)
    by = by + barH + gap

    -- Armure
    local ar, arMax = ply:Armor(), math.max(1, ply:GetMaxArmor())
    anim.armor = Lerp(FrameTime() * 8, anim.armor, math.Clamp(ar / arMax, 0, 1))
    UI.Bar(bx, by, bw, barH, anim.armor, C.steel, C.steelLt, "Armure", ar .. " / " .. arMax)
    by = by + barH + gap

    -- Mana (Sorcier uniquement)
    if isSorcier then
        local manaMax = ply:GetNWInt("blood_mana_max", 0)
        local manaCur
        if manaMax <= 0 then
            manaMax, manaCur = 100, 100 -- placeholder tant que le module Sorcier n'est pas branché
        else
            manaCur = ply:GetNWInt("blood_mana", 0)
        end
        anim.mana = Lerp(FrameTime() * 8, anim.mana, math.Clamp(manaCur / manaMax, 0, 1))
        UI.Bar(bx, by, bw, barH, anim.mana, C.mana, C.manaLt, "Mana", manaCur .. " / " .. manaMax)
    end
end)

hook.Add("ShutDown", "BLOOD_HUD_Cleanup", function()
    if IsValid(modelPanel) then modelPanel:Remove() end
end)
