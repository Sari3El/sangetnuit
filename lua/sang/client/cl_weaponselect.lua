--[[-------------------------------------------------------------------------
    Sang et Nuit — Sélecteur d'arme custom (style médiéval)
      Reprend la base de GMod :
        - molette (invnext/invprev) = arme suivante / précédente
        - touches 1..6 (slotN)      = catégorie, cycle dans la catégorie
        - clic gauche (+attack)      = valider la sélection
      Restylé avec le thème BLOOD.UI. Le cooldown de chaque arme est affiché
      EN GROS EN ROUGE en bas à droite de sa case (via GetNextPrimaryFire ou
      la variable réseau "blood_cooldown_end").
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}
local UI = BLOOD.UI
local C = UI.Col
local S = UI.Scale

surface.CreateFont("SangWep_CD", { font = "Georgia", size = S(26), weight = 800, antialias = true, extended = true })

local COLS = 6            -- catégories 1..6 (GetSlot 0..5)
local FADE = 4            -- secondes d'affichage sans input

local active   = false
local fadeUntil = 0
local selWep   = nil

----------------------------------------------------------------------
-- Masquer le sélecteur d'arme par défaut
----------------------------------------------------------------------
hook.Add("HUDShouldDraw", "BLOOD_HideWepSelect", function(name)
    if name == "CHudWeaponSelection" then return false end
end)

----------------------------------------------------------------------
-- Utilitaires
----------------------------------------------------------------------
local function bump() fadeUntil = CurTime() + FADE end

local function ordered()
    local ply = LocalPlayer()
    if not IsValid(ply) then return {} end
    local ws = ply:GetWeapons()
    table.sort(ws, function(a, b)
        local sa, sb = a:GetSlot(), b:GetSlot()
        if sa ~= sb then return sa < sb end
        return a:GetSlotPos() < b:GetSlotPos()
    end)
    return ws
end

local function remaining(w)
    if not IsValid(w) then return 0 end
    local best = 0
    if w.GetNextPrimaryFire then
        local np = w:GetNextPrimaryFire()
        if np and np > CurTime() then best = math.max(best, np - CurTime()) end
    end
    local cd = w:GetNWFloat("blood_cooldown_end", 0)
    if cd > CurTime() then best = math.max(best, cd - CurTime()) end
    return best
end

local function wepName(w)
    local name = w.GetPrintName and w:GetPrintName() or nil
    if not name or name == "" then name = w:GetClass() end
    if string.sub(name, 1, 1) == "#" then name = language.GetPhrase(string.sub(name, 2)) end
    return name
end

----------------------------------------------------------------------
-- Navigation
----------------------------------------------------------------------
local function move(dir)
    local list = ordered()
    if #list == 0 then return end
    if not active then
        active = true
        selWep = LocalPlayer():GetActiveWeapon()
    end
    bump()
    local idx = 1
    for i, w in ipairs(list) do if w == selWep then idx = i break end end
    idx = idx + dir
    if idx < 1 then idx = #list elseif idx > #list then idx = 1 end
    selWep = list[idx]
    surface.PlaySound("common/wpn_moveselect.wav")
end

local function selectSlot(n)
    local bin = {}
    for _, w in ipairs(ordered()) do
        if (w:GetSlot() + 1) == n then bin[#bin + 1] = w end
    end
    active = true
    bump()
    if #bin == 0 then
        surface.PlaySound("common/wpn_denyselect.wav")
        return
    end
    local cur
    for i, w in ipairs(bin) do if w == selWep then cur = i break end end
    selWep = cur and bin[(cur % #bin) + 1] or bin[1]
    surface.PlaySound("common/wpn_moveselect.wav")
end

local function confirm()
    if IsValid(selWep) then
        input.SelectWeapon(selWep)
        surface.PlaySound("common/wpn_select.wav")
    end
    active = false
end

----------------------------------------------------------------------
-- Interception des touches (base GMod)
----------------------------------------------------------------------
hook.Add("PlayerBindPress", "BLOOD_WeaponSelect", function(ply, bind, pressed)
    if not pressed then return end
    if vgui.CursorVisible() or gui.IsGameUIVisible() then return end

    bind = string.lower(bind)
    if bind == "invnext" then move(1) return true end
    if bind == "invprev" then move(-1) return true end

    local sn = string.match(bind, "^slot(%d+)$")
    if sn then
        local n = tonumber(sn)
        if n >= 1 and n <= COLS then selectSlot(n) return true end
        return
    end

    if active and bind == "+attack" then confirm() return true end
end)

----------------------------------------------------------------------
-- Rendu
----------------------------------------------------------------------
local function wrap(text, font, maxw)
    surface.SetFont(font)
    local lines, cur = {}, ""
    for _, wd in ipairs(string.Explode(" ", text)) do
        local test = (cur == "") and wd or (cur .. " " .. wd)
        if surface.GetTextSize(test) > maxw and cur ~= "" then
            lines[#lines + 1] = cur
            cur = wd
        else
            cur = test
        end
    end
    if cur ~= "" then lines[#lines + 1] = cur end
    return lines
end

local function drawHeader(x, y, w, h, num, sel)
    UI.VGradient(x, y, w, h, sel and UI.Shade(C.bg3, 10) or C.bg2, C.bg0)
    surface.SetDrawColor(sel and C.gold or C.goldDk)
    surface.DrawOutlinedRect(x, y, w, h, sel and 2 or 1)
    UI.CornerBrackets(x, y, w, h, S(10), sel and C.goldLt or C.goldDk)
    draw.SimpleText(num, "SangUI_H1", x + w / 2 + 1, y + h / 2 + 1, C.shadow, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(num, "SangUI_H1", x + w / 2, y + h / 2, sel and C.goldLt or C.txt, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local function drawCell(x, y, w, wep, sel)
    local padX = S(10)
    local font = sel and "SangUI_Body" or "SangUI_Small"
    local lines = wrap(wepName(wep), font, w - padX * 2)
    surface.SetFont(font)
    local _, lineH = surface.GetTextSize("Aj")
    local h = math.max(S(30), #lines * lineH + S(16))

    UI.VGradient(x, y, w, h, sel and UI.Shade(C.bg3, 8) or C.bg2, C.bg0)
    surface.SetDrawColor(sel and C.gold or C.goldDk)
    surface.DrawOutlinedRect(x, y, w, h, sel and 2 or 1)
    if sel then surface.SetDrawColor(C.blood) surface.DrawRect(x, y, S(3), h) end

    local ty = y + S(8)
    local tcol = sel and C.txt or C.txtDim
    for _, ln in ipairs(lines) do
        draw.SimpleText(ln, font, x + padX, ty, tcol, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        ty = ty + lineH
    end

    -- Cooldown en gros rouge, bas-droite
    local rem = remaining(wep)
    if rem > 0.05 then
        local txt = string.format("%.1fs", rem)
        draw.SimpleText(txt, "SangWep_CD", x + w - S(8) + 1, y + h - S(6) + 1, Color(0, 0, 0, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
        draw.SimpleText(txt, "SangWep_CD", x + w - S(8), y + h - S(6), Color(206, 42, 42), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
    end

    return h
end

hook.Add("HUDPaint", "BLOOD_WeaponSelectDraw", function()
    if not active then return end
    if CurTime() > fadeUntil then active = false return end

    local ply = LocalPlayer()
    if not IsValid(ply) then active = false return end

    -- catégories -> listes
    local bins = {}
    for _, w in ipairs(ordered()) do
        local s = w:GetSlot() + 1
        bins[s] = bins[s] or {}
        bins[s][#bins[s] + 1] = w
    end

    if not IsValid(selWep) then selWep = ply:GetActiveWeapon() end
    local selSlot = IsValid(selWep) and (selWep:GetSlot() + 1) or 0

    local colW = S(160)
    local gap  = S(12)
    local totalW = COLS * colW + (COLS - 1) * gap
    local startX = (ScrW() - totalW) / 2
    local topY = S(48)
    local headerH = S(54)

    for c = 1, COLS do
        local x = startX + (c - 1) * (colW + gap)
        drawHeader(x, topY, colW, headerH, tostring(c), c == selSlot)

        local y = topY + headerH + S(10)
        for _, w in ipairs(bins[c] or {}) do
            local ch = drawCell(x, y, colW, w, w == selWep)
            y = y + ch + S(6)
        end
    end
end)
