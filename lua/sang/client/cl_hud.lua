--[[-------------------------------------------------------------------------
    Sang et Nuit — HUD médiéval (or / noir / rouge)
      - Aperçu 3D du model actuel du joueur
      - Barre de PV, barre d'Armure
      - Barre de Mana (uniquement pour la race Sorcier)
    Le HUD par défaut (santé/armure) est masqué pour éviter le doublon.
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}

----------------------------------------------------------------------
-- Palette & polices
----------------------------------------------------------------------
local COL = {
    frameBlack = Color(12, 9, 7, 245),
    parch      = Color(34, 26, 19, 245),
    parch2     = Color(22, 17, 12, 245),
    gold       = Color(201, 164, 76),
    goldLt     = Color(236, 205, 121),
    goldDk     = Color(110, 84, 34),
    track      = Color(10, 8, 6, 235),
    hp         = Color(168, 34, 30),
    hpLt       = Color(206, 66, 52),
    armor      = Color(150, 152, 168),
    armorLt    = Color(196, 200, 214),
    mana       = Color(96, 74, 168),
    manaLt     = Color(140, 116, 214),
    txt        = Color(234, 216, 172),
    txtDim     = Color(180, 160, 120),
    shadow     = Color(0, 0, 0, 200),
}

local function S(v) return math.floor(v * (ScrH() / 1080)) end

surface.CreateFont("SangHUD_Title", { font = "Georgia", size = S(23), weight = 800, antialias = true, extended = true })
surface.CreateFont("SangHUD_Sub",   { font = "Georgia", size = S(15), weight = 600, italic = true, antialias = true, extended = true })
surface.CreateFont("SangHUD_Bar",   { font = "Georgia", size = S(15), weight = 700, antialias = true, extended = true })

----------------------------------------------------------------------
-- Masquer le HUD par défaut (santé + armure)
----------------------------------------------------------------------
local hideDefault = { CHudHealth = true, CHudBattery = true }
hook.Add("HUDShouldDraw", "BLOOD_HideDefaultHUD", function(name)
    if hideDefault[name] then return false end
end)

----------------------------------------------------------------------
-- Aperçu 3D du model (DModelPanel persistant)
----------------------------------------------------------------------
local modelPanel

local function frameModel(mdl)
    local ent = mdl:GetEntity()
    if not IsValid(ent) then return end
    -- Pose d'idle
    local seq = ent:LookupSequence("idle_all_01")
    if not seq or seq < 0 then seq = ent:SelectWeightedSequence(ACT_HL2MP_IDLE) end
    if seq and seq >= 0 then ent:ResetSequence(seq) end
    -- Cadrage caméra d'après les bounds du model
    local mn, mx = ent:GetRenderBounds()
    local center = (mn + mx) * 0.5
    local dist = mn:Distance(mx)
    mdl:SetLookAt(center)
    mdl:SetCamPos(center + Vector(dist * 0.95, 0, dist * 0.06))
    mdl:SetFOV(40)
end

local function ensureModelPanel()
    if IsValid(modelPanel) then return modelPanel end

    modelPanel = vgui.Create("DModelPanel")
    modelPanel:SetMouseInputEnabled(false)
    modelPanel:SetKeyboardInputEnabled(false)
    modelPanel:SetModel(LocalPlayer():GetModel())
    modelPanel.CurModel = LocalPlayer():GetModel()

    modelPanel.LayoutEntity = function(self, ent)
        ent:SetAngles(Angle(0, RealTime() * 18 % 360, 0))
        self:RunAnimation()
    end
    -- Cadre doré par-dessus le rendu du model
    modelPanel.PaintOver = function(self, w, h)
        surface.SetDrawColor(COL.goldDk)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        surface.SetDrawColor(COL.gold)
        surface.DrawOutlinedRect(1, 1, w - 2, h - 2, 1)
    end

    frameModel(modelPanel)
    return modelPanel
end

----------------------------------------------------------------------
-- Dessin d'une barre "parchemin" médiévale
----------------------------------------------------------------------
local function drawBar(x, y, w, h, frac, colFill, colLt, label, valTxt)
    frac = math.Clamp(frac, 0, 1)

    -- Piste
    draw.RoundedBox(3, x, y, w, h, COL.track)
    -- Remplissage
    local fw = math.floor((w - 4) * frac)
    if fw > 0 then
        draw.RoundedBox(2, x + 2, y + 2, fw, h - 4, colFill)
        -- reflet supérieur
        surface.SetDrawColor(colLt.r, colLt.g, colLt.b, 90)
        surface.DrawRect(x + 2, y + 2, fw, math.max(1, (h - 4) * 0.4))
    end
    -- Bordure dorée
    surface.SetDrawColor(COL.goldDk)
    surface.DrawOutlinedRect(x, y, w, h, 1)

    -- Libellé (gauche) + valeur (droite), avec ombre
    surface.SetFont("SangHUD_Bar")
    local ty = y + (h - select(2, surface.GetTextSize(label))) * 0.5
    draw.SimpleText(label, "SangHUD_Bar", x + 8 + 1, y + h / 2 + 1, COL.shadow, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(label, "SangHUD_Bar", x + 8,     y + h / 2,     COL.txt,    TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    if valTxt then
        draw.SimpleText(valTxt, "SangHUD_Bar", x + w - 8 + 1, y + h / 2 + 1, COL.shadow, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        draw.SimpleText(valTxt, "SangHUD_Bar", x + w - 8,     y + h / 2,     COL.txt,    TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
end

----------------------------------------------------------------------
-- Plaque de fond médiévale
----------------------------------------------------------------------
local function drawPlaque(x, y, w, h)
    -- ombre portée
    draw.RoundedBox(6, x + 4, y + 5, w, h, Color(0, 0, 0, 120))
    -- fond noir + parchemin
    draw.RoundedBox(6, x, y, w, h, COL.frameBlack)
    draw.RoundedBox(6, x + 3, y + 3, w - 6, h - 6, COL.parch)
    -- dégradé sombre en bas
    surface.SetDrawColor(COL.parch2.r, COL.parch2.g, COL.parch2.b, 160)
    surface.DrawRect(x + 3, y + h * 0.55, w - 6, h * 0.45 - 3)

    -- double liseré doré
    surface.SetDrawColor(COL.goldDk)
    surface.DrawOutlinedRect(x, y, w, h, 2)
    surface.SetDrawColor(COL.gold)
    surface.DrawOutlinedRect(x + 4, y + 4, w - 8, h - 8, 1)

    -- ornements d'angle (petits losanges dorés)
    local function corner(cx, cy)
        surface.SetDrawColor(COL.goldLt)
        draw.NoTexture()
        surface.DrawPoly({
            { x = cx,     y = cy - 5 },
            { x = cx + 5, y = cy },
            { x = cx,     y = cy + 5 },
            { x = cx - 5, y = cy },
        })
    end
    corner(x + 10, y + 10); corner(x + w - 10, y + 10)
    corner(x + 10, y + h - 10); corner(x + w - 10, y + h - 10)
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

    -- Masquer le model si mort
    if not ply:Alive() then
        if IsValid(modelPanel) then modelPanel:SetVisible(false) end
        return
    end

    -- Layout (coin bas-gauche)
    local pad = S(14)
    local w   = S(362)
    local h   = S(150)
    local x   = S(24)
    local y   = ScrH() - h - S(24)

    drawPlaque(x, y, w, h)

    -- Zone du model
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

    -- Zone de droite (nom + barres)
    local bx = mX + mW + S(14)
    local bw = (x + w - pad) - bx

    -- Nom du perso + race
    local raceId   = ply:GetNWString("blood_race", "human")
    local raceData = BLOOD.Races and BLOOD.Races[raceId]
    local slotData = BLOOD.MyData and BLOOD.MyData.slots and BLOOD.MyData.slots[BLOOD.MyData.activeSlot]
    local persoName = (slotData and slotData.name) or ply:Nick()

    draw.SimpleText(persoName, "SangHUD_Title", bx + 1, y + pad + 1, COL.shadow, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(persoName, "SangHUD_Title", bx,     y + pad,     COL.txt,    TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(raceData and raceData.name or raceId, "SangHUD_Sub",
        bx, y + pad + S(24), COL.goldLt, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    -- Barres
    local barH = S(21)
    local gap  = S(7)
    local by   = y + pad + S(46)

    -- PV
    local hp, hpMax = ply:Health(), math.max(1, ply:GetMaxHealth())
    anim.hp = Lerp(FrameTime() * 8, anim.hp, math.Clamp(hp / hpMax, 0, 1))
    drawBar(bx, by, bw, barH, anim.hp, COL.hp, COL.hpLt, "PV", math.max(0, hp) .. " / " .. hpMax)
    by = by + barH + gap

    -- Armure
    local ar, arMax = ply:Armor(), math.max(1, ply:GetMaxArmor())
    anim.armor = Lerp(FrameTime() * 8, anim.armor, math.Clamp(ar / arMax, 0, 1))
    drawBar(bx, by, bw, barH, anim.armor, COL.armor, COL.armorLt, "Armure", ar .. " / " .. arMax)
    by = by + barH + gap

    -- Mana (uniquement Sorcier)
    if raceId == "sorcier" then
        local manaMax = ply:GetNWInt("blood_mana_max", 0)
        local manaCur
        if manaMax <= 0 then
            -- Le module Sorcier (mana) n'est pas encore branché : placeholder plein.
            manaMax, manaCur = 100, 100
        else
            manaCur = ply:GetNWInt("blood_mana", 0)
        end
        anim.mana = Lerp(FrameTime() * 8, anim.mana, math.Clamp(manaCur / manaMax, 0, 1))
        drawBar(bx, by, bw, barH, anim.mana, COL.mana, COL.manaLt, "Mana", manaCur .. " / " .. manaMax)
    end
end)

-- Nettoyage à la déconnexion / rechargement
hook.Add("ShutDown", "BLOOD_HUD_Cleanup", function()
    if IsValid(modelPanel) then modelPanel:Remove() end
end)
