--[[-------------------------------------------------------------------------
    Sang et Nuit — Tchat custom (client)
      Remplace entièrement le tchat de base par une boîte au thème médiéval :
        - historique des messages avec retour à la ligne (word-wrap)
        - défilement molette quand le tchat est ouvert
        - fondu des lignes récentes quand il est fermé
        - noms colorés par job/faction
        - saisie stylée, flèches HAUT / BAS = message précédent / suivant
        - TAB = auto-complétion du pseudo d'un joueur
      Ne dépend pas de l'ordre de chargement : la palette BLOOD.UI est lue à
      l'exécution (repli intégré si le thème n'est pas encore là).
---------------------------------------------------------------------------]]

if not CLIENT then return end

local S = function(v) return math.floor(v * (ScrH() / 1080) + 0.5) end

----------------------------------------------------------------------
-- Palette (repli si BLOOD.UI absent au moment de l'appel)
----------------------------------------------------------------------
local FALLBACK = {
    bg0 = Color(16, 13, 10, 240), bg1 = Color(26, 21, 16, 245),
    bg3 = Color(48, 39, 29, 250), ink = Color(8, 6, 4, 235),
    gold = Color(176, 141, 74), goldLt = Color(210, 176, 108), goldDk = Color(92, 71, 38),
    blood = Color(150, 42, 38),
    txt = Color(220, 206, 174), txtDim = Color(146, 130, 100),
    shadow = Color(0, 0, 0, 200),
}
local function COL()
    return (BLOOD and BLOOD.UI and BLOOD.UI.Col) or FALLBACK
end

----------------------------------------------------------------------
-- Polices dédiées (indépendantes du thème)
----------------------------------------------------------------------
local FONT = "SangChat_Text"
surface.CreateFont(FONT,          { font = "Georgia", size = S(18), weight = 600, antialias = true, extended = true })
surface.CreateFont("SangChat_Pre", { font = "Georgia", size = S(18), weight = 800, antialias = true, extended = true })

----------------------------------------------------------------------
-- État
----------------------------------------------------------------------
local MAXLINES = 120
local HOLD, FADE = 11, 1.6     -- secondes avant/pendant le fondu (fermé)

local lines   = {}             -- { {rows=..., t=CurTime()}, ... }
local history = {}             -- messages envoyés (le + récent en dernier)
local histIdx = nil
local scroll  = 0              -- décalage en lignes (vers le haut = + ancien)
local isOpen  = false
local curTeam = false
local frame, entry

----------------------------------------------------------------------
-- Géométrie (recalculée chaque frame, très peu coûteux)
----------------------------------------------------------------------
local function geom()
    local g = {}
    g.m    = S(28)
    g.cw   = math.min(S(580), ScrW() - S(56))
    g.inh  = S(30)
    g.pad  = S(8)
    g.bottom     = ScrH() - S(150)          -- bas de la barre de saisie
    g.inputY     = g.bottom - g.inh
    g.logBottom  = g.inputY - S(8)
    g.logTop     = g.logBottom - S(340)
    g.maxw       = g.cw - S(16)
    g.pref       = S(78)
    return g
end

----------------------------------------------------------------------
-- Couleur du nom (job/faction -> équipe -> or)
----------------------------------------------------------------------
local function nameColor(ply)
    if not IsValid(ply) then return COL().goldLt end
    if SJOB and SJOB.JobsById then
        local j = SJOB.JobsById[ply:GetNWString("sang_job", "")]
        if j and j.color then return j.color end
    end
    local t = ply:Team()
    if team and team.Valid and team.Valid(t) then return team.GetColor(t) end
    return COL().goldLt
end

----------------------------------------------------------------------
-- Découpe une suite d'arguments (façon chat.AddText) en lignes de tokens.
--   raw = { Color, "texte", Player, "texte", ... }
--   -> rows = { { {text,color,x}, ... }, ... }
----------------------------------------------------------------------
local function buildRows(raw)
    local C = COL()
    local g = geom()
    surface.SetFont(FONT)

    local rows, row, x = {}, {}, 0
    local function flush()
        rows[#rows + 1] = row
        row, x = {}, 0
    end
    local function put(txt, col)
        local w = surface.GetTextSize(txt)
        if x > 0 and x + w > g.maxw then flush() end
        row[#row + 1] = { text = txt, color = col, x = x }
        x = x + w
    end

    local cur = C.txt
    for _, a in ipairs(raw) do
        if IsColor(a) then
            cur = a
        elseif type(a) == "Player" and IsValid(a) then
            put(a:Nick(), nameColor(a))
        else
            local s = isstring(a) and a or tostring(a)
            local paras = string.Explode("\n", s)
            for pi, para in ipairs(paras) do
                if pi > 1 then flush() end
                for token in string.gmatch(para, "%S+%s*") do
                    put(token, cur)
                end
            end
        end
    end
    flush()
    return rows
end

----------------------------------------------------------------------
-- Ajoute une ligne au journal
----------------------------------------------------------------------
local function pushLine(raw)
    lines[#lines + 1] = { rows = buildRows(raw), t = CurTime() }
    while #lines > MAXLINES do table.remove(lines, 1) end
    scroll = 0
end

----------------------------------------------------------------------
-- Fond médiéval (utilise BLOOD.UI.Panel si dispo, sinon repli sobre)
----------------------------------------------------------------------
local function panelBg(x, y, w, h)
    local C = COL()
    if BLOOD and BLOOD.UI and BLOOD.UI.Panel then
        BLOOD.UI.Panel(x, y, w, h)
    else
        surface.SetDrawColor(C.bg0) surface.DrawRect(x, y, w, h)
        surface.SetDrawColor(C.goldDk) surface.DrawOutlinedRect(x, y, w, h, 1)
    end
end

----------------------------------------------------------------------
-- Rendu du journal (ouvert = fond + défilement ; fermé = fondu)
----------------------------------------------------------------------
local function drawLog()
    local C = COL()
    local g = geom()
    surface.SetFont(FONT)
    local _, th = surface.GetTextSize("Ag")
    local lineH = th + S(2)
    local now = CurTime()

    -- lignes de tokens visibles (avec alpha)
    local disp = {}
    for _, ln in ipairs(lines) do
        local a = 255
        if not isOpen then
            local age = now - ln.t
            if age > HOLD + FADE then a = 0
            elseif age > HOLD then a = 255 * (1 - (age - HOLD) / FADE) end
        end
        if a > 0.5 then
            for _, r in ipairs(ln.rows) do disp[#disp + 1] = { row = r, a = a } end
        end
    end

    -- fond + barre de saisie quand ouvert
    if isOpen then
        panelBg(g.m - g.pad, g.logTop - g.pad, g.cw + g.pad * 2,
                (g.logBottom - g.logTop) + g.pad * 2)
        -- barre de saisie
        surface.SetDrawColor(C.ink) surface.DrawRect(g.m, g.inputY, g.cw, g.inh)
        surface.SetDrawColor(entry and entry:HasFocus() and C.gold or C.goldDk)
        surface.DrawOutlinedRect(g.m, g.inputY, g.cw, g.inh, 1)
        draw.SimpleText(curTeam and "Équipe" or "Dire", "SangChat_Pre",
            g.m + S(8), g.inputY + g.inh / 2, C.goldLt, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(C.goldDk)
        surface.DrawRect(g.m + g.pref - S(6), g.inputY + S(5), 1, g.inh - S(10))
    end

    local total = #disp
    if total == 0 then return lineH end

    local visible = math.max(1, math.floor((g.logBottom - g.logTop) / lineH))
    local maxScroll = math.max(0, total - visible)
    if not isOpen then scroll = 0 end
    scroll = math.Clamp(scroll, 0, maxScroll)

    local endI = total - scroll
    local startI = math.max(1, endI - visible + 1)

    render.SetScissorRect(g.m - g.pad, g.logTop - S(4), g.m + g.cw + g.pad, g.logBottom + S(2), true)
    local y = g.logBottom - lineH
    for i = endI, startI, -1 do
        local d = disp[i]
        surface.SetFont(FONT)
        for _, tok in ipairs(d.row) do
            surface.SetTextColor(0, 0, 0, d.a * 0.75)
            surface.SetTextPos(g.m + tok.x + 1, y + 1) surface.DrawText(tok.text)
            local c = tok.color
            surface.SetTextColor(c.r, c.g, c.b, d.a)
            surface.SetTextPos(g.m + tok.x, y) surface.DrawText(tok.text)
        end
        y = y - lineH
    end
    render.SetScissorRect(0, 0, 0, 0, false)

    -- indicateur « défile vers le haut »
    if isOpen and scroll < maxScroll then
        draw.SimpleText("▲ plus haut", "SangChat_Pre", g.m + g.cw - S(8), g.logTop - S(2),
            C.goldDk, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    end
    return lineH
end

----------------------------------------------------------------------
-- Ouverture / fermeture / envoi
----------------------------------------------------------------------
local function closeChat()
    isOpen = false
    histIdx = nil
    scroll = 0
    if IsValid(entry) then entry:Remove() end
    if IsValid(frame) then frame:Remove() end
    entry, frame = nil, nil
    hook.Run("FinishChat")
    hook.Run("ChatTextChanged", "")
end

local function sendChat()
    local txt = IsValid(entry) and entry:GetValue() or ""
    txt = string.Trim(txt)
    closeChat()
    if txt == "" then return end
    if history[#history] ~= txt then history[#history + 1] = txt end
    while #history > 40 do table.remove(history, 1) end
    if curTeam then
        RunConsoleCommand("say_team", txt)
    else
        RunConsoleCommand("say", txt)
    end
end

local function setEntryText(txt)
    if not IsValid(entry) then return end
    entry:SetText(txt)               -- SetText ne déclenche pas OnValueChange
    entry:SetCaretPos(#txt)
end

local function histPrev()
    if #history == 0 then return end
    histIdx = histIdx and math.max(1, histIdx - 1) or #history
    setEntryText(history[histIdx])
end

local function histNext()
    if not histIdx then return end
    histIdx = histIdx + 1
    if histIdx > #history then histIdx = nil setEntryText("") return end
    setEntryText(history[histIdx])
end

local function autocomplete()
    if not IsValid(entry) then return end
    local txt = entry:GetValue()
    local pre, word = string.match(txt, "^(.-)(%S*)$")
    if not word or word == "" then return end
    local lw = string.lower(word)
    for _, pl in ipairs(player.GetAll()) do
        local nm = pl:Nick()
        if string.sub(string.lower(nm), 1, #lw) == lw then
            setEntryText(pre .. nm .. " ")
            return
        end
    end
end

local function openChat(teamMode)
    if IsValid(frame) then return end
    curTeam = teamMode and true or false
    local g = geom()

    frame = vgui.Create("DPanel")
    frame:SetPos(g.m - g.pad, g.logTop - g.pad)
    frame:SetSize(g.cw + g.pad * 2, (g.inputY + g.inh) - (g.logTop - g.pad) + S(4))
    frame.Paint = function() end
    frame:MakePopup()
    frame.OnMouseWheeled = function(_, d) scroll = scroll + d return true end

    entry = vgui.Create("DTextEntry", frame)
    entry:SetPos(g.m - (g.m - g.pad) + g.pref, (g.inputY) - (g.logTop - g.pad))
    entry:SetSize(g.cw - g.pref - S(6), g.inh)
    entry:SetFont(FONT)
    entry:SetPaintBackground(false)
    entry:SetUpdateOnType(true)
    entry.Paint = function(self, w, h)
        local C = COL()
        self:DrawTextEntryText(C.txt, Color(C.gold.r, C.gold.g, C.gold.b, 120), C.goldLt)
    end
    entry:RequestFocus()

    -- SetText (navigation historique/complétion) ne déclenche pas OnValueChange :
    -- histIdx n'est donc réinitialisé QUE quand le joueur tape lui-même.
    entry.OnValueChange = function() histIdx = nil hook.Run("ChatTextChanged", entry:GetValue()) end
    entry.OnKeyCodeTyped = function(self, key)
        if key == KEY_ESCAPE then closeChat() return true end
        if key == KEY_ENTER or key == KEY_PAD_ENTER then sendChat() return true end
        if key == KEY_UP   then histPrev() return true end
        if key == KEY_DOWN then histNext() return true end
        if key == KEY_TAB  then autocomplete() return true end
    end

    isOpen = true
    hook.Run("StartChat", curTeam)
end

----------------------------------------------------------------------
-- Surcharge de l'API chat (pour que les autres addons restent visibles)
----------------------------------------------------------------------
chat.SangOldAddText = chat.SangOldAddText or chat.AddText
function chat.AddText(...)          pushLine({ ... }) end
function chat.Open(mode)            openChat(mode == 2) end
function chat.Close()               closeChat() end
function chat.GetChatBoxPos()       local g = geom() return g.m, g.logTop end
function chat.GetChatBoxSize()      local g = geom() return g.cw, (g.logBottom - g.logTop) + g.inh end

----------------------------------------------------------------------
-- Hooks
----------------------------------------------------------------------
hook.Add("HUDShouldDraw", "SangChat_HideDefault", function(name)
    if name == "CHudChat" then return false end
end)

hook.Add("HUDPaint", "SangChat_Draw", function()
    drawLog()
end)

hook.Add("PlayerBindPress", "SangChat_Open", function(_, bind, pressed)
    if not pressed then return end
    bind = string.lower(bind)
    if bind == "messagemode"  then openChat(false) return true end
    if bind == "messagemode2" then openChat(true)  return true end
end)

-- Messages des joueurs (nom coloré, préfixes MORT / Équipe)
hook.Add("OnPlayerChat", "SangChat_Player", function(ply, text, teamChat, isDead)
    local C = COL()
    local seg = {}
    if isDead   then seg[#seg + 1] = Color(190, 60, 60) seg[#seg + 1] = "*MORT* " end
    if teamChat then seg[#seg + 1] = C.gold             seg[#seg + 1] = "(Équipe) " end
    if IsValid(ply) then
        seg[#seg + 1] = ply
    else
        seg[#seg + 1] = Color(150, 150, 150) seg[#seg + 1] = "Console"
    end
    seg[#seg + 1] = C.txt
    seg[#seg + 1] = ": " .. text
    pushLine(seg)
    return true
end)

-- Messages moteur (arrivées/départs, serveur...) — hors « chat » (déjà géré)
hook.Add("ChatText", "SangChat_Engine", function(_, _, text, mtype)
    if mtype == "chat" then return end
    pushLine({ COL().txtDim, text })
    return true
end)
