--[[-------------------------------------------------------------------------
    Sang et Nuit — Thème d'interface commun (client)
    Palette + polices + helpers de dessin partagés par le HUD, le menu
    personnages et le menu admin, pour un style médiéval sobre et cohérent
    (cuir sombre, hairlines dorées, dégradés discrets — pas cartoon).
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}
BLOOD.UI = BLOOD.UI or {}
local UI = BLOOD.UI

----------------------------------------------------------------------
-- Échelle & palette
----------------------------------------------------------------------
function UI.Scale(v) return math.floor(v * (ScrH() / 1080) + 0.5) end
local S = UI.Scale

UI.Col = {
    bg0    = Color(16, 13, 10, 250),   -- cuir presque noir
    bg1    = Color(26, 21, 16, 250),
    bg2    = Color(36, 29, 22, 250),
    bg3    = Color(48, 39, 29, 250),
    ink    = Color(8, 6, 4, 255),
    gold   = Color(176, 141, 74),      -- or vieilli, désaturé
    goldLt = Color(210, 176, 108),
    goldDk = Color(92, 71, 38),
    blood  = Color(116, 27, 24),       -- rouge sang profond
    bloodLt= Color(150, 42, 38),
    steel  = Color(116, 120, 130),     -- acier vieilli (armure)
    steelLt= Color(158, 162, 174),
    mana   = Color(66, 80, 138),
    manaLt = Color(104, 120, 182),
    hunger = Color(150, 100, 44),      -- pain / ambre
    hungerLt = Color(198, 146, 74),
    txt    = Color(220, 206, 174),     -- encre parchemin
    txtDim = Color(146, 130, 100),
    line   = Color(66, 52, 30, 255),
    shadow = Color(0, 0, 0, 200),
}
local C = UI.Col

----------------------------------------------------------------------
-- Polices (serif médiéval)
----------------------------------------------------------------------
surface.CreateFont("SangUI_Title", { font = "Georgia", size = S(24), weight = 700, antialias = true, extended = true })
surface.CreateFont("SangUI_H1",    { font = "Georgia", size = S(27), weight = 800, antialias = true, extended = true })
surface.CreateFont("SangUI_Body",  { font = "Georgia", size = S(18), weight = 600, antialias = true, extended = true })
surface.CreateFont("SangUI_Small", { font = "Georgia", size = S(15), weight = 600, antialias = true, extended = true, italic = true })
surface.CreateFont("SangUI_Bar",   { font = "Georgia", size = S(15), weight = 700, antialias = true, extended = true })
surface.CreateFont("SangUI_Tiny",  { font = "Georgia", size = S(12), weight = 700, antialias = true, extended = true })

----------------------------------------------------------------------
-- Utilitaires couleur
----------------------------------------------------------------------
local function shade(c, d)
    return Color(math.Clamp(c.r + d, 0, 255), math.Clamp(c.g + d, 0, 255),
                 math.Clamp(c.b + d, 0, 255), c.a or 255)
end
UI.Shade = shade

-- Dégradé vertical en bandes (lisse et peu coûteux)
local function vgradient(x, y, w, h, top, bottom, bands)
    bands = bands or 22
    local bh = h / bands
    for i = 0, bands - 1 do
        local t = i / (bands - 1)
        surface.SetDrawColor(
            Lerp(t, top.r, bottom.r), Lerp(t, top.g, bottom.g),
            Lerp(t, top.b, bottom.b), Lerp(t, top.a or 255, bottom.a or 255))
        surface.DrawRect(x, y + i * bh, w, bh + 1)
    end
end
UI.VGradient = vgradient

----------------------------------------------------------------------
-- Équerres d'angle (filigrane discret) au lieu d'ornements criards
----------------------------------------------------------------------
local function cornerBrackets(x, y, w, h, len, col)
    len = len or S(12)
    surface.SetDrawColor(col or C.gold)
    -- haut-gauche
    surface.DrawRect(x, y, len, 1);            surface.DrawRect(x, y, 1, len)
    -- haut-droite
    surface.DrawRect(x + w - len, y, len, 1);  surface.DrawRect(x + w - 1, y, 1, len)
    -- bas-gauche
    surface.DrawRect(x, y + h - 1, len, 1);    surface.DrawRect(x, y + h - len, 1, len)
    -- bas-droite
    surface.DrawRect(x + w - len, y + h - 1, len, 1); surface.DrawRect(x + w - 1, y + h - len, 1, len)
end
UI.CornerBrackets = cornerBrackets

----------------------------------------------------------------------
-- Panneau / plaque médiévale sobre
----------------------------------------------------------------------
function UI.Panel(x, y, w, h, opts)
    opts = opts or {}
    -- ombre portée
    surface.SetDrawColor(0, 0, 0, 130)
    surface.DrawRect(x + S(4), y + S(5), w, h)
    -- fond dégradé cuir
    vgradient(x, y, w, h, C.bg2, C.bg0)
    -- voile plus sombre en bas pour la profondeur
    surface.SetDrawColor(0, 0, 0, 70)
    surface.DrawRect(x, y + h * 0.6, w, h * 0.4)
    -- cadre : liseré encre + hairline dorée intérieure
    surface.SetDrawColor(C.ink)
    surface.DrawOutlinedRect(x, y, w, h, 1)
    surface.SetDrawColor(C.goldDk)
    surface.DrawOutlinedRect(x + 2, y + 2, w - 4, h - 4, 1)
    -- équerres dorées
    cornerBrackets(x + 2, y + 2, w - 4, h - 4, opts.bracket or S(12), C.gold)
end

----------------------------------------------------------------------
-- Barre de statut (PV / armure / mana...)
----------------------------------------------------------------------
function UI.Bar(x, y, w, h, frac, fill, fillLt, label, valTxt)
    frac = math.Clamp(frac, 0, 1)
    -- piste creusée
    vgradient(x, y, w, h, C.ink, shade(C.bg1, -6))
    -- remplissage dégradé
    local fw = math.floor((w - 2) * frac)
    if fw > 0 then
        vgradient(x + 1, y + 1, fw, h - 2, fillLt, shade(fill, -30))
        -- fine ligne de lumière en haut
        surface.SetDrawColor(fillLt.r, fillLt.g, fillLt.b, 70)
        surface.DrawRect(x + 1, y + 1, fw, 1)
    end
    -- bordure
    surface.SetDrawColor(C.ink)
    surface.DrawOutlinedRect(x, y, w, h, 1)
    surface.SetDrawColor(C.goldDk)
    surface.DrawOutlinedRect(x, y, w, h, 1)
    -- texte
    if label then
        draw.SimpleText(label, "SangUI_Bar", x + S(8) + 1, y + h / 2 + 1, C.shadow, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(label, "SangUI_Bar", x + S(8),     y + h / 2,     C.txt,    TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    if valTxt then
        draw.SimpleText(valTxt, "SangUI_Bar", x + w - S(8) + 1, y + h / 2 + 1, C.shadow, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        draw.SimpleText(valTxt, "SangUI_Bar", x + w - S(8),     y + h / 2,     C.txt,    TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
end

----------------------------------------------------------------------
-- Barre VERTICALE (faim...) — remplissage depuis le bas
----------------------------------------------------------------------
function UI.VBar(x, y, w, h, frac, fill, fillLt)
    frac = math.Clamp(frac, 0, 1)
    -- piste
    vgradient(x, y, w, h, C.ink, shade(C.bg1, -6))
    -- remplissage (bas -> haut)
    local fh = math.floor((h - 2) * frac)
    if fh > 0 then
        local fy = y + h - 1 - fh
        vgradient(x + 1, fy, w - 2, fh, fillLt, shade(fill, -30))
        surface.SetDrawColor(fillLt.r, fillLt.g, fillLt.b, 80)
        surface.DrawRect(x + 1, fy, w - 2, 1)
    end
    -- bordures
    surface.SetDrawColor(C.ink);    surface.DrawOutlinedRect(x, y, w, h, 1)
    surface.SetDrawColor(C.goldDk); surface.DrawOutlinedRect(x, y, w, h, 1)
end

----------------------------------------------------------------------
-- Skin d'un DButton
--   kind : "default" | "blood" | "gold"
----------------------------------------------------------------------
function UI.SkinButton(btn, kind)
    kind = kind or "default"
    btn:SetFont("SangUI_Body")
    btn.Think = function(self) self:SetTextColor(self:IsEnabled() and C.txt or C.txtDim) end
    btn.Paint = function(self, w, h)
        local enabled = self:IsEnabled()
        local hovered = enabled and self:IsHovered()
        local base = C.bg2
        if kind == "blood" then base = Color(74, 24, 22, 250)
        elseif kind == "gold" then base = Color(64, 51, 28, 250) end
        if not enabled then base = C.bg1 end
        vgradient(0, 0, w, h, shade(base, hovered and 20 or 6), shade(base, -16))
        surface.SetDrawColor(hovered and C.gold or C.goldDk)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        if hovered then cornerBrackets(0, 0, w, h, S(9), C.goldLt) end
    end
end

----------------------------------------------------------------------
-- Skin d'un DTextEntry
----------------------------------------------------------------------
function UI.SkinEntry(entry)
    entry:SetFont("SangUI_Body")
    entry:SetTextColor(C.txt)
    entry:SetCursorColor(C.goldLt)
    entry:SetHighlightColor(Color(C.gold.r, C.gold.g, C.gold.b, 90))
    entry.Paint = function(self, w, h)
        vgradient(0, 0, w, h, C.ink, shade(C.bg1, -4))
        surface.SetDrawColor(self:HasFocus() and C.gold or C.goldDk)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        self:DrawTextEntryText(C.txt, Color(C.gold.r, C.gold.g, C.gold.b, 120), C.goldLt)
    end
end

----------------------------------------------------------------------
-- Skin d'un DComboBox
----------------------------------------------------------------------
function UI.SkinCombo(combo)
    combo:SetFont("SangUI_Body")
    combo:SetTextColor(C.txt)
    combo.Paint = function(self, w, h)
        vgradient(0, 0, w, h, shade(C.bg2, self:IsHovered() and 14 or 0), shade(C.bg2, -16))
        surface.SetDrawColor(self:IsHovered() and C.gold or C.goldDk)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText(self:GetValue() or "", "SangUI_Body", S(8), h / 2, C.txt, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("▾", "SangUI_Bar", w - S(14), h / 2, C.goldLt, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

----------------------------------------------------------------------
-- Fenêtre stylée (DFrame) — renvoie la frame ; le contenu va dans f.Body
----------------------------------------------------------------------
function UI.MakeFrame(w, h, title)
    local f = vgui.Create("DFrame")
    f:SetSize(w, h)
    f:Center()
    f:SetTitle("")
    f:ShowCloseButton(true)
    f:MakePopup()
    f:SetDraggable(true)

    local hdr = S(46)

    f.Paint = function(self, fw, fh)
        UI.Panel(0, 0, fw, fh)
        -- barre d'en-tête
        vgradient(2, 2, fw - 4, hdr, shade(C.bg3, 6), C.bg1)
        surface.SetDrawColor(C.goldDk)
        surface.DrawRect(S(14), hdr, fw - S(28), 1)
        surface.SetDrawColor(C.gold)
        surface.DrawRect(S(14), hdr + 1, math.min(fw - S(28), S(120)), 1)
        -- titre
        draw.SimpleText(title or "", "SangUI_Title", S(18) + 1, hdr / 2 + 2 + 1, C.shadow, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(title or "", "SangUI_Title", S(18),     hdr / 2 + 2,     C.goldLt, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- bouton fermer reskiné
    if IsValid(f.btnClose) then
        f.btnClose:SetText("")
        f.btnClose:SetSize(hdr, hdr)
        f.btnClose:SetPos(w - hdr, 0)
        f.btnClose.Paint = function(self, bw, bh)
            local c = self:IsHovered() and C.bloodLt or C.txtDim
            local m = math.floor(bw * 0.34)
            surface.SetDrawColor(c)
            surface.DrawLine(m, m, bw - m, bh - m)
            surface.DrawLine(bw - m, m, m, bh - m)
        end
    end

    f.Body = vgui.Create("DPanel", f)
    f.Body:SetPos(S(14), hdr + S(8))
    f.Body:SetSize(w - S(28), h - hdr - S(20))
    f.Body.Paint = function() end
    f.HeaderH = hdr

    return f
end
