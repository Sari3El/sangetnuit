--[[-------------------------------------------------------------------------
    Sang et Nuit — Missives : interface (client)
      1) Bureau des missives -> 3 options (Personnelle / Faction / Inter-
         Faction) + accès à la boîte de réception.
      2) Fenêtre de rédaction (destinataire + objet + texte).
      3) Boîte de réception (liste + lecture).
      Style commun BLOOD.UI (addon principal requis).
---------------------------------------------------------------------------]]

SMISSIVE = SMISSIVE or {}
SMISSIVE.Inbox = SMISSIVE.Inbox or {}
SMISSIVE.UnreadCount = SMISSIVE.UnreadCount or 0

surface.CreateFont("SangMissive_Hint", { font = "Georgia", size = 20, weight = 700, antialias = true, extended = true })
surface.CreateFont("SangMissive_BadgeTitle", { font = "Georgia", size = 17, weight = 700, antialias = true, extended = true })
surface.CreateFont("SangMissive_BadgeHint",  { font = "Georgia", size = 13, weight = 600, antialias = true, extended = true, italic = true })

local function uiReady() return BLOOD and BLOOD.UI end

local KIND_LABEL = { personal = "Personnelle", faction = "de Faction", interfaction = "Inter-Faction" }

local function skinScroll(scroll)
    local UI, C = BLOOD.UI, BLOOD.UI.Col
    local S = UI.Scale
    local sbar = scroll:GetVBar()
    sbar:SetWide(S(8))
    sbar.Paint = function() end
    sbar.btnUp.Paint = function() end
    sbar.btnDown.Paint = function() end
    sbar.btnGrip.Paint = function(_, w, h) surface.SetDrawColor(C.goldDk); surface.DrawRect(0, 0, w, h) end
end

-- Couleur de bandeau selon la faction (réutilise la palette du thème).
local function factionColor(fac)
    local C = BLOOD.UI.Col
    if fac == "empire" then return C.steel end
    if fac == "creatures" then return C.blood end
    if fac == "consortium" then return C.gold end
    return C.txtDim
end

----------------------------------------------------------------------
-- Ouverture du bureau (menu principal)
----------------------------------------------------------------------
net.Receive("sang_missive_open", function()
    local unread = net.ReadUInt(16)
    SMISSIVE.OpenMainMenu(unread)
end)

function SMISSIVE.OpenMainMenu(unread)
    if not uiReady() then
        chat.AddText(Color(255, 80, 80), "[Missives] L'addon principal 'sang_et_nuit' est requis.")
        return
    end
    local UI, C = BLOOD.UI, BLOOD.UI.Col
    local S = UI.Scale
    if IsValid(SMISSIVE.MainFrame) then SMISSIVE.MainFrame:Remove() end

    local f = UI.MakeFrame(S(480), S(430), "Bureau des Missives")
    SMISSIVE.MainFrame = f
    local body = f.Body

    local intro = vgui.Create("DLabel", body)
    intro:Dock(TOP) intro:DockMargin(0, 0, 0, S(14)) intro:SetTall(S(36))
    intro:SetFont("SangUI_Small") intro:SetTextColor(C.txtDim)
    intro:SetWrap(true) intro:SetAutoStretchVertical(true)
    intro:SetText("Confie une missive au messager. Choisis à qui l'adresser :")

    local myFac = LocalPlayer():GetNWString("sang_faction", "none")
    local hasFaction = SMISSIVE.IsRealFaction(myFac)

    local function bigButton(label, sub, enabled, onClick)
        local b = vgui.Create("DButton", body)
        b:Dock(TOP) b:DockMargin(0, 0, 0, S(10)) b:SetTall(S(58)) b:SetText("")
        UI.SkinButton(b, "default")
        b:SetEnabled(enabled)
        local skin = b.Paint
        b.Paint = function(self, w, h)
            skin(self, w, h)
            local tc = enabled and (self:IsHovered() and C.goldLt or C.txt) or C.txtDim
            draw.SimpleText(label, "SangUI_Body", S(14), h / 2 - S(10), tc, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(sub, "SangUI_Tiny", S(14), h / 2 + S(11), C.txtDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        if enabled then b.DoClick = onClick end
        return b
    end

    bigButton("Missive Personnelle", "Écrire à un joueur connecté sur le serveur.", true, function()
        SMISSIVE.OpenCompose("personal")
    end)
    bigButton("Missive de Faction", hasFaction and ("Écrire à ta faction — " .. SMISSIVE.FactionName(myFac) .. ".")
        or "Nécessite d'appartenir à une faction.", hasFaction, function()
        SMISSIVE.OpenCompose("faction")
    end)
    bigButton("Missive Inter-Faction", hasFaction and "Écrire à une autre faction du serveur."
        or "Nécessite d'appartenir à une faction.", hasFaction, function()
        SMISSIVE.OpenCompose("interfaction")
    end)

    local inboxBtn = vgui.Create("DButton", body)
    inboxBtn:Dock(BOTTOM) inboxBtn:SetTall(S(36)) inboxBtn:SetText("")
    UI.SkinButton(inboxBtn, "gold")
    local inboxSkin = inboxBtn.Paint
    inboxBtn.Paint = function(self, w, h)
        inboxSkin(self, w, h)
        local txt = "Ma boîte aux lettres" .. (unread > 0 and ("  (" .. unread .. " non lue" .. (unread > 1 and "s" or "") .. ")") or "")
        draw.SimpleText(txt, "SangUI_Body", w / 2, h / 2, unread > 0 and C.goldLt or C.txt, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    inboxBtn.DoClick = function() SMISSIVE.RequestInbox() end
end

----------------------------------------------------------------------
-- Rédaction
----------------------------------------------------------------------
function SMISSIVE.OpenCompose(kind)
    if not uiReady() then return end
    local UI, C = BLOOD.UI, BLOOD.UI.Col
    local S = UI.Scale
    local titles = { personal = "Missive Personnelle", faction = "Missive de Faction", interfaction = "Missive Inter-Faction" }

    if IsValid(SMISSIVE.ComposeFrame) then SMISSIVE.ComposeFrame:Remove() end
    local f = UI.MakeFrame(S(580), S(540), titles[kind] or "Missive")
    SMISSIVE.ComposeFrame = f
    local body = f.Body

    local targetSid, targetFaction = "", ""
    local myFac = LocalPlayer():GetNWString("sang_faction", "none")

    ------------------------------------------------------------------
    -- Destinataire (selon le type)
    ------------------------------------------------------------------
    if kind == "personal" then
        local lbl = vgui.Create("DLabel", body)
        lbl:Dock(TOP) lbl:DockMargin(0, 0, 0, S(4)) lbl:SetFont("SangUI_Small") lbl:SetTextColor(C.txtDim)
        lbl:SetText("Destinataire (joueur connecté) :")

        local combo = vgui.Create("DComboBox", body)
        combo:Dock(TOP) combo:DockMargin(0, 0, 0, S(12)) combo:SetTall(S(28))
        combo:SetValue("— Choisir un joueur —")
        UI.SkinCombo(combo)
        local me = LocalPlayer()
        for _, pl in ipairs(player.GetAll()) do
            if pl ~= me then combo:AddChoice(pl:Nick(), pl:SteamID64()) end
        end
        combo.OnSelect = function(_, _, _, data) targetSid = data or "" end

    elseif kind == "faction" then
        local lbl = vgui.Create("DLabel", body)
        lbl:Dock(TOP) lbl:DockMargin(0, 0, 0, S(12)) lbl:SetTall(S(20))
        lbl:SetFont("SangUI_Body") lbl:SetTextColor(C.goldLt)
        lbl:SetText("Destinataire : ta faction — " .. SMISSIVE.FactionName(myFac))

    else -- interfaction
        local lbl = vgui.Create("DLabel", body)
        lbl:Dock(TOP) lbl:DockMargin(0, 0, 0, S(4)) lbl:SetFont("SangUI_Small") lbl:SetTextColor(C.txtDim)
        lbl:SetText("Faction destinataire :")

        local combo = vgui.Create("DComboBox", body)
        combo:Dock(TOP) combo:DockMargin(0, 0, 0, S(12)) combo:SetTall(S(28))
        combo:SetValue("— Choisir une faction —")
        UI.SkinCombo(combo)
        for _, fac in ipairs(SMISSIVE.RealFactions()) do
            if fac ~= myFac then combo:AddChoice(SMISSIVE.FactionName(fac), fac) end
        end
        combo.OnSelect = function(_, _, _, data) targetFaction = data or "" end
    end

    ------------------------------------------------------------------
    -- Objet
    ------------------------------------------------------------------
    local subjRow = vgui.Create("DPanel", body)
    subjRow:Dock(TOP) subjRow:DockMargin(0, 0, 0, S(4)) subjRow:SetTall(S(16))
    subjRow.Paint = function() end
    local subjLbl = vgui.Create("DLabel", subjRow)
    subjLbl:Dock(LEFT) subjLbl:SetFont("SangUI_Small") subjLbl:SetTextColor(C.txtDim) subjLbl:SetText("Objet :")
    local subjCount = vgui.Create("DLabel", subjRow)
    subjCount:Dock(RIGHT) subjCount:SetFont("SangUI_Tiny") subjCount:SetTextColor(C.txtDim)
    subjCount:SetContentAlignment(6) subjCount:SetText("0/" .. SMISSIVE.Config.SubjectMax)

    local subjEntry = vgui.Create("DTextEntry", body)
    subjEntry:Dock(TOP) subjEntry:DockMargin(0, 0, 0, S(12)) subjEntry:SetTall(S(28))
    UI.SkinEntry(subjEntry)
    subjEntry:SetPlaceholderText("Objet de la missive…")
    subjEntry:SetMaximumCharCount(SMISSIVE.Config.SubjectMax)
    subjEntry.OnValueChange = function(self)
        subjCount:SetText(string.len(self:GetValue() or "") .. "/" .. SMISSIVE.Config.SubjectMax)
    end

    ------------------------------------------------------------------
    -- Boutons (bas) — ajoutés avant le corps pour que celui-ci prenne le FILL
    ------------------------------------------------------------------
    local btnRow = vgui.Create("DPanel", body)
    btnRow:Dock(BOTTOM) btnRow:DockMargin(0, S(10), 0, 0) btnRow:SetTall(S(34))
    btnRow.Paint = function() end
    local sendBtn = vgui.Create("DButton", btnRow)
    sendBtn:Dock(RIGHT) sendBtn:SetWide(S(150)) sendBtn:SetText("Envoyer")
    UI.SkinButton(sendBtn, "gold")
    local cancelBtn = vgui.Create("DButton", btnRow)
    cancelBtn:Dock(RIGHT) cancelBtn:DockMargin(0, 0, S(8), 0) cancelBtn:SetWide(S(110)) cancelBtn:SetText("Annuler")
    UI.SkinButton(cancelBtn, "default")
    cancelBtn.DoClick = function() if IsValid(f) then f:Close() end end

    ------------------------------------------------------------------
    -- Corps
    ------------------------------------------------------------------
    local bodyRow = vgui.Create("DPanel", body)
    bodyRow:Dock(TOP) bodyRow:DockMargin(0, 0, 0, S(4)) bodyRow:SetTall(S(16))
    bodyRow.Paint = function() end
    local bodyLbl = vgui.Create("DLabel", bodyRow)
    bodyLbl:Dock(LEFT) bodyLbl:SetFont("SangUI_Small") bodyLbl:SetTextColor(C.txtDim) bodyLbl:SetText("Texte :")
    local bodyCount = vgui.Create("DLabel", bodyRow)
    bodyCount:Dock(RIGHT) bodyCount:SetFont("SangUI_Tiny") bodyCount:SetTextColor(C.txtDim)
    bodyCount:SetContentAlignment(6) bodyCount:SetText("0/" .. SMISSIVE.Config.BodyMax)

    local bodyEntry = vgui.Create("DTextEntry", body)
    bodyEntry:Dock(FILL)
    UI.SkinEntry(bodyEntry)
    bodyEntry:SetMultiline(true)
    bodyEntry:SetPlaceholderText("Écris ta missive ici…")
    bodyEntry:SetMaximumCharCount(SMISSIVE.Config.BodyMax)
    bodyEntry.OnValueChange = function(self)
        bodyCount:SetText(string.len(self:GetValue() or "") .. "/" .. SMISSIVE.Config.BodyMax)
    end

    ------------------------------------------------------------------
    -- Envoi
    ------------------------------------------------------------------
    sendBtn.DoClick = function()
        local subject = string.Trim(subjEntry:GetValue() or "")
        local text    = string.Trim(bodyEntry:GetValue() or "")
        if subject == "" or text == "" then return end
        if kind == "personal" and targetSid == "" then return end
        if kind == "interfaction" and targetFaction == "" then return end

        net.Start("sang_missive_send")
            net.WriteString(kind)
            net.WriteString(targetSid)
            net.WriteString(targetFaction)
            net.WriteString(subject)
            net.WriteString(text)
        net.SendToServer()

        surface.PlaySound(SMISSIVE.Config.SendSound)
        if IsValid(f) then f:Close() end
    end
end

----------------------------------------------------------------------
-- Boîte de réception
----------------------------------------------------------------------
function SMISSIVE.RequestInbox()
    net.Start("sang_missive_inbox_req")
    net.SendToServer()
end

net.Receive("sang_missive_inbox_data", function()
    local n = net.ReadUInt(16)
    local list = {}
    for i = 1, n do
        list[i] = {
            id            = net.ReadUInt(32),
            kind          = net.ReadString(),
            subject       = net.ReadString(),
            body          = net.ReadString(),
            senderName    = net.ReadString(),
            senderFaction = net.ReadString(),
            targetFaction = net.ReadString(),
            ts            = net.ReadUInt(32),
            unread        = net.ReadBool(),
        }
    end
    SMISSIVE.Inbox = list
    SMISSIVE.OpenInbox()
end)

function SMISSIVE.OpenInbox()
    if not uiReady() then return end
    local UI, C = BLOOD.UI, BLOOD.UI.Col
    local S = UI.Scale

    if IsValid(SMISSIVE.InboxFrame) then SMISSIVE.InboxFrame:Remove() end
    local f = UI.MakeFrame(S(760), S(560), "Ma boîte aux lettres")
    SMISSIVE.InboxFrame = f
    local body = f.Body

    -- Colonne liste (gauche)
    local listPanel = vgui.Create("DPanel", body)
    listPanel:Dock(LEFT) listPanel:SetWide(S(280)) listPanel:DockMargin(0, 0, S(10), 0)
    listPanel.Paint = function(_, w, h) UI.Panel(0, 0, w, h) end

    local scroll = vgui.Create("DScrollPanel", listPanel)
    scroll:Dock(FILL) scroll:DockMargin(S(6), S(6), S(6), S(6))
    skinScroll(scroll)

    -- Colonne lecture (droite)
    local reader = vgui.Create("DPanel", body)
    reader:Dock(FILL)
    reader.Paint = function(_, w, h) UI.Panel(0, 0, w, h) end
    reader:DockPadding(S(14), S(12), S(14), S(12))

    local readerSubject = vgui.Create("DLabel", reader)
    readerSubject:Dock(TOP) readerSubject:SetTall(S(26))
    readerSubject:SetFont("SangUI_Title") readerSubject:SetTextColor(C.goldLt)

    local readerMeta = vgui.Create("DLabel", reader)
    readerMeta:Dock(TOP) readerMeta:DockMargin(0, S(2), 0, S(10)) readerMeta:SetTall(S(20))
    readerMeta:SetFont("SangUI_Small") readerMeta:SetTextColor(C.txtDim)

    local readerScroll = vgui.Create("DScrollPanel", reader)
    readerScroll:Dock(FILL)
    skinScroll(readerScroll)

    local readerBody = vgui.Create("DLabel", readerScroll)
    readerBody:Dock(TOP)
    readerBody:SetFont("SangUI_Body") readerBody:SetTextColor(C.txt)
    readerBody:SetWrap(true) readerBody:SetAutoStretchVertical(true)
    readerBody:SetText("")

    local function showMissive(m)
        readerSubject:SetText(m.subject)
        local metaParts = { "De : " .. m.senderName, os.date("%d/%m/%Y %H:%M", m.ts) }
        if m.kind ~= "personal" then
            metaParts[#metaParts + 1] = KIND_LABEL[m.kind] .. " — " .. SMISSIVE.FactionName(m.targetFaction)
        end
        readerMeta:SetText(table.concat(metaParts, "   ·   "))
        readerBody:SetText(m.body)
    end

    if #SMISSIVE.Inbox == 0 then
        local lbl = vgui.Create("DLabel", scroll)
        lbl:Dock(TOP) lbl:DockMargin(0, S(10), 0, 0) lbl:SetFont("SangUI_Small") lbl:SetTextColor(C.txtDim)
        lbl:SetText("Aucune missive reçue pour l'instant.")
        readerSubject:SetText("")
        readerMeta:SetText("")
    else
        for i, m in ipairs(SMISSIVE.Inbox) do
            local row = vgui.Create("DButton", scroll)
            row:Dock(TOP) row:DockMargin(0, 0, S(4), S(4)) row:SetTall(S(52)) row:SetText("")
            local fcol = m.kind == "personal" and C.goldDk or factionColor(m.targetFaction)
            row.Paint = function(self, w, h)
                local hovered = self:IsHovered()
                UI.VGradient(0, 0, w, h, UI.Shade(C.bg1, hovered and 10 or 4), C.bg0)
                surface.SetDrawColor(C.goldDk); surface.DrawOutlinedRect(0, 0, w, h, 1)
                surface.SetDrawColor(fcol); surface.DrawRect(0, 0, S(3), h)
                if m.unread then
                    surface.SetDrawColor(C.goldLt)
                    surface.DrawRect(w - S(10), S(6), S(5), S(5))
                end
                draw.SimpleText(m.subject, "SangUI_Small", S(12), S(9), C.txt, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                local sub = KIND_LABEL[m.kind] .. "  ·  " .. m.senderName
                draw.SimpleText(sub, "SangUI_Tiny", S(12), S(29), C.txtDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText(os.date("%d/%m %H:%M", m.ts), "SangUI_Tiny", w - S(12), S(29), C.txtDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
            end
            row.DoClick = function()
                m.unread = false
                showMissive(m)
            end
        end
        showMissive(SMISSIVE.Inbox[1])
        SMISSIVE.Inbox[1].unread = false
    end
end

----------------------------------------------------------------------
-- Indice [E] au survol du bureau des missives
----------------------------------------------------------------------
hook.Add("HUDPaint", "SANGMISSIVE_Hint", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local tr = ply:GetEyeTrace()
    local e = tr.Entity
    if not IsValid(e) or e:GetClass() ~= "sang_missive_box" then return end
    if ply:GetPos():Distance(e:GetPos()) > (SMISSIVE.Config.OpenDist or 140) then return end

    local cx, cy = ScrW() / 2, ScrH() / 2
    local gold = Color(176, 141, 74)
    local sh = Color(0, 0, 0, 200)
    draw.SimpleText("[E] Rédiger une missive", "SangMissive_Hint", cx + 1, cy + 41, sh, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("[E] Rédiger une missive", "SangMissive_Hint", cx, cy + 40, gold, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

----------------------------------------------------------------------
-- Badge HUD persistant : apparaît dès qu'une missive non lue est en
-- attente (reçue en temps réel ou déjà en attente à la connexion), où que
-- soit le joueur. Touche F3 pour ouvrir directement la boîte de réception
-- (la souris n'étant pas disponible en jeu, on ne peut pas "cliquer" un
-- élément de HUD à proprement parler : la touche fait office de clic).
----------------------------------------------------------------------
net.Receive("sang_missive_badge", function()
    SMISSIVE.UnreadCount = net.ReadUInt(16)
end)

hook.Add("HUDPaint", "SANGMISSIVE_Badge", function()
    local n = SMISSIVE.UnreadCount or 0
    if n <= 0 or not uiReady() then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local UI, C = BLOOD.UI, BLOOD.UI.Col
    local S = UI.Scale

    local w, h = S(240), S(50)
    local x, y = ScrW() - w - S(24), S(24)

    -- Léger effet de pulsation pour attirer l'œil sans être criard.
    local pulse = 0.5 + 0.5 * math.sin(CurTime() * 3)

    UI.VGradient(x, y, w, h, UI.Shade(C.bg2, 6), C.bg0)
    surface.SetDrawColor(C.ink); surface.DrawOutlinedRect(x, y, w, h, 1)
    surface.SetDrawColor(Lerp(pulse, C.goldDk.r, C.goldLt.r), Lerp(pulse, C.goldDk.g, C.goldLt.g), Lerp(pulse, C.goldDk.b, C.goldLt.b))
    surface.DrawOutlinedRect(x + 1, y + 1, w - 2, h - 2, 1)
    surface.SetDrawColor(C.blood); surface.DrawRect(x, y, S(3), h)

    local label = n .. " missive" .. (n > 1 and "s" or "") .. " non lue" .. (n > 1 and "s" or "")
    draw.SimpleText(label, "SangMissive_BadgeTitle", x + S(14), y + S(13), C.goldLt, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText("Appuie sur [F3] pour lire", "SangMissive_BadgeHint", x + S(14), y + S(35), C.txtDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end)

local f3Down = false
hook.Add("Think", "SANGMISSIVE_F3Key", function()
    local down = input.IsKeyDown(KEY_F3)
    if down and not f3Down then
        f3Down = true
        if IsValid(SMISSIVE.InboxFrame) then
            SMISSIVE.InboxFrame:Remove()
        elseif not vgui.CursorVisible() and not gui.IsGameUIVisible() then
            SMISSIVE.RequestInbox()
        end
    elseif not down then
        f3Down = false
    end
end)

concommand.Add("sang_missives", function() SMISSIVE.RequestInbox() end)
