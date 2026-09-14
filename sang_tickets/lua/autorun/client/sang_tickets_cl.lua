--[[-------------------------------------------------------------------------
    Sang et Nuit — Tickets : client (UI)
      - Page de création (raison / cible / description)
      - Alerte HUD haut-gauche pour le staff (+ son)
      - Panneau cliquable (touche/menu C) : liste -> détail -> prendre / actions
      - Notation 5 étoiles par le joueur à la fermeture
---------------------------------------------------------------------------]]

if not CLIENT then return end

SANGTICKET = SANGTICKET or {}
SANGTICKET.tickets = SANGTICKET.tickets or {}

local function UIok() return BLOOD and BLOOD.UI and BLOOD.UI.MakeFrame end

-- Petit intitulé de champ (BLOOD.UI n'expose pas FieldLabel).
local function fieldLabel(parent, text)
    local C, S = BLOOD.UI.Col, BLOOD.UI.Scale
    local l = vgui.Create("DLabel", parent)
    l:Dock(TOP) l:DockMargin(0, S(4), 0, S(2)) l:SetTall(S(18))
    l:SetFont("SangUI_Small") l:SetTextColor(C.goldLt) l:SetText(text)
    return l
end
local function isStaffCl()
    local lp = LocalPlayer()
    return IsValid(lp) and lp:IsAdmin()
end
local function mySid() return LocalPlayer():SteamID64() end

-- Un ticket m'est-il « visible » ? (ouvert = tous ; pris = seulement le preneur)
local function relevant(t)
    if not t.claimed then return true end
    return t.claimerSid == mySid()
end

----------------------------------------------------------------------
-- Réception : liste des tickets vivants (staff)
----------------------------------------------------------------------
local seen = {}
net.Receive("sang_ticket_sync", function()
    local n = net.ReadUInt(8)
    local list = {}
    local hasNewOpen = false
    for _ = 1, n do
        local t = {}
        t.id          = net.ReadUInt(16)
        t.reqName     = net.ReadString()
        t.reason      = net.ReadString()
        t.desc        = net.ReadString()
        t.targetName  = net.ReadString()
        t.claimed     = net.ReadBool()
        t.claimerSid  = net.ReadString()
        t.claimerName = net.ReadString()
        list[#list + 1] = t
        if not t.claimed and not seen[t.id] then hasNewOpen = true end
        seen[t.id] = true
    end
    SANGTICKET.tickets = list
    if hasNewOpen then surface.PlaySound("friends/friend_join.wav") end
    if IsValid(SANGTICKET._board) and SANGTICKET._rebuildBoard then SANGTICKET._rebuildBoard() end
end)

----------------------------------------------------------------------
-- Alerte HUD (haut-gauche) — informative (clic impossible sur du HUD)
----------------------------------------------------------------------
hook.Add("HUDPaint", "SangTicket_HUD", function()
    if not isStaffCl() then return end
    local list = SANGTICKET.tickets
    if not list or #list == 0 then return end
    local C = (BLOOD and BLOOD.UI and BLOOD.UI.Col) or nil
    local S = (BLOOD and BLOOD.UI and BLOOD.UI.Scale) or function(v) return math.floor(v * (ScrH() / 1080) + 0.5) end
    local gold = C and C.goldLt or Color(210, 176, 108)
    local red  = C and C.bloodLt or Color(150, 42, 38)
    local txt  = C and C.txt or Color(220, 206, 174)
    local dim  = C and C.txtDim or Color(146, 130, 100)

    local x, y, w = S(16), S(120), S(300)
    local shown = 0
    for _, t in ipairs(list) do
        if relevant(t) and shown < 5 then
            shown = shown + 1
            local mine = t.claimed and t.claimerSid == mySid()
            local h = S(56)
            surface.SetDrawColor(10, 8, 6, 235) surface.DrawRect(x, y, w, h)
            surface.SetDrawColor(mine and gold or red) surface.DrawOutlinedRect(x, y, w, h, 1)
            surface.SetDrawColor((mine and gold or red).r, (mine and gold or red).g, (mine and gold or red).b, 255)
            surface.DrawRect(x, y, S(3), h)
            draw.SimpleText("#" .. t.id .. (mine and "  · EN COURS (toi)" or "  · " .. t.reqName),
                "SangUI_Small", x + S(10), y + S(6), gold, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(SANGTICKET.ReasonName(t.reason), "SangUI_Small", x + S(10), y + S(23), txt, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            local prev = string.sub(t.desc or "", 1, 34)
            if #(t.desc or "") > 34 then prev = prev .. "…" end
            draw.SimpleText(prev, "SangUI_Tiny", x + S(10), y + S(40), dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            y = y + h + S(6)
        end
    end
    if shown > 0 then
        draw.SimpleText("Tickets : touche liée à « sang_tickets » ou menu C", "SangUI_Tiny",
            x, y + S(2), dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
end)

----------------------------------------------------------------------
-- Page de création (joueur)
----------------------------------------------------------------------
function SANGTICKET.OpenCreate()
    if not UIok() then return end
    local UI, C, S = BLOOD.UI, BLOOD.UI.Col, BLOOD.UI.Scale
    if IsValid(SANGTICKET._create) then SANGTICKET._create:Remove() end
    local f = UI.MakeFrame(S(460), S(420), "Nouveau ticket")
    SANGTICKET._create = f
    local body = f.Body or f

    fieldLabel(body, "Raison du ticket :")
    local reason = vgui.Create("DComboBox", body)
    reason:Dock(TOP) reason:DockMargin(0, 0, 0, S(8)) reason:SetTall(S(28))
    UI.SkinCombo(reason)
    for _, r in ipairs(SANGTICKET.Reasons) do reason:AddChoice(r.name, r.id) end
    reason:ChooseOptionID(1)

    fieldLabel(body, "Cible (si « Contre un Joueur ») :")
    local target = vgui.Create("DComboBox", body)
    target:Dock(TOP) target:DockMargin(0, 0, 0, S(8)) target:SetTall(S(28))
    UI.SkinCombo(target)
    target:SetEnabled(false)
    local function fillTargets()
        target:Clear()
        for _, pl in ipairs(player.GetAll()) do
            if pl ~= LocalPlayer() then
                target:AddChoice(pl:Nick() .. "  (" .. pl:SteamID() .. ")", pl:SteamID64())
            end
        end
    end

    reason.OnSelect = function(_, _, _, data)
        local need = SANGTICKET.ReasonNeedsTarget(data)
        target:SetEnabled(need)
        if need then fillTargets() else target:Clear() target:SetValue("") end
    end

    fieldLabel(body, "Description :")
    local desc = vgui.Create("DTextEntry", body)
    desc:Dock(TOP) desc:DockMargin(0, 0, 0, S(8)) desc:SetTall(S(120))
    desc:SetMultiline(true)
    UI.SkinEntry(desc)

    local send = vgui.Create("DButton", body)
    send:Dock(BOTTOM) send:SetTall(S(34)) send:SetText("Valider et envoyer")
    UI.SkinButton(send, "gold")
    send.DoClick = function()
        local _, rid = reason:GetSelected()
        rid = rid or "question"
        local tSid = ""
        if SANGTICKET.ReasonNeedsTarget(rid) then
            local _, ts = target:GetSelected()
            if not ts then
                Derma_Message("Choisis une cible.", "Ticket", "OK") return
            end
            tSid = ts
        end
        net.Start("sang_ticket_create")
            net.WriteString(rid)
            net.WriteString(tSid)
            net.WriteString(string.sub(desc:GetValue() or "", 1, 500))
        net.SendToServer()
        f:Remove()
    end
end

----------------------------------------------------------------------
-- Détail d'un ticket (staff)
----------------------------------------------------------------------
function SANGTICKET.OpenDetail(id)
    if not UIok() then return end
    local UI, C, S = BLOOD.UI, BLOOD.UI.Col, BLOOD.UI.Scale
    local t
    for _, x in ipairs(SANGTICKET.tickets) do if x.id == id then t = x break end end
    if not t then return end

    if IsValid(SANGTICKET._detail) then SANGTICKET._detail:Remove() end
    local f = UI.MakeFrame(S(500), S(400), "Ticket #" .. t.id)
    SANGTICKET._detail = f
    local body = f.Body or f
    local mine = t.claimed and t.claimerSid == mySid()

    local info = vgui.Create("DPanel", body)
    info:Dock(TOP) info:DockMargin(0, 0, 0, S(8)) info:SetTall(S(120))
    info.Paint = function(_, w, h)
        surface.SetDrawColor(C.bg0) surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(C.goldDk) surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("Joueur : " .. t.reqName, "SangUI_Body", S(10), S(8), C.goldLt, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Raison : " .. SANGTICKET.ReasonName(t.reason), "SangUI_Small", S(10), S(32), C.txt, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        if t.targetName ~= "" then
            draw.SimpleText("Cible : " .. t.targetName, "SangUI_Small", S(10), S(52), C.bloodLt, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
        draw.SimpleText(t.claimed and ("Pris par : " .. (t.claimerName or "?")) or "Non pris",
            "SangUI_Small", S(10), S(74), t.claimed and C.steelLt or C.goldLt, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    fieldLabel(body, "Description :")
    local dp = vgui.Create("DScrollPanel", body)
    dp:Dock(FILL) dp:DockMargin(0, 0, 0, S(8))
    local lbl = vgui.Create("DLabel", dp)
    lbl:Dock(TOP) lbl:SetWrap(true) lbl:SetAutoStretchVertical(true)
    lbl:SetFont("SangUI_Body") lbl:SetTextColor(C.txt)
    lbl:SetText(t.desc ~= "" and t.desc or "(aucune description)")

    local btns = vgui.Create("DPanel", body)
    btns:Dock(BOTTOM) btns:SetTall(S(34)) btns.Paint = function() end

    if not t.claimed then
        local take = vgui.Create("DButton", btns)
        take:Dock(RIGHT) take:SetWide(S(160)) take:SetText("Prendre le ticket")
        UI.SkinButton(take, "gold")
        take.DoClick = function()
            net.Start("sang_ticket_claim") net.WriteUInt(t.id, 16) net.SendToServer()
            f:Remove()
        end
    elseif mine then
        local function act(txt, w, action, kind, dock)
            local b = vgui.Create("DButton", btns)
            b:Dock(dock or LEFT) b:SetWide(w) b:DockMargin(0, 0, S(6), 0) b:SetText(txt)
            UI.SkinButton(b, kind or "default")
            b.DoClick = function()
                net.Start("sang_ticket_action") net.WriteUInt(t.id, 16) net.WriteString(action) net.SendToServer()
            end
        end
        act("Aller au joueur", S(120), "goto", "default")
        act("Amener", S(90), "bring", "default")
        act("Spectate", S(90), "spectate", "default")
        local done = vgui.Create("DButton", btns)
        done:Dock(RIGHT) done:SetWide(S(140)) done:SetText("Ticket terminé")
        UI.SkinButton(done, "blood")
        done.DoClick = function()
            net.Start("sang_ticket_close") net.WriteUInt(t.id, 16) net.SendToServer()
            f:Remove()
        end
    end
end

----------------------------------------------------------------------
-- Panneau liste (staff)
----------------------------------------------------------------------
function SANGTICKET.OpenBoard()
    if not UIok() or not isStaffCl() then return end
    local UI, C, S = BLOOD.UI, BLOOD.UI.Col, BLOOD.UI.Scale
    if IsValid(SANGTICKET._board) then SANGTICKET._board:Remove() end
    local f = UI.MakeFrame(S(460), S(520), "Tickets en cours")
    SANGTICKET._board = f
    local body = f.Body or f

    local scroll = vgui.Create("DScrollPanel", body)
    scroll:Dock(FILL)

    SANGTICKET._rebuildBoard = function()
        if not IsValid(scroll) then return end
        scroll:Clear()
        local any = false
        for _, t in ipairs(SANGTICKET.tickets) do
            if relevant(t) then
                any = true
                local mine = t.claimed and t.claimerSid == mySid()
                local row = vgui.Create("DButton", scroll)
                row:Dock(TOP) row:DockMargin(0, 0, S(4), S(6)) row:SetTall(S(48)) row:SetText("")
                row.Paint = function(self, w, h)
                    surface.SetDrawColor(self:IsHovered() and C.bg3 or C.bg2) surface.DrawRect(0, 0, w, h)
                    surface.SetDrawColor(mine and C.gold or C.goldDk) surface.DrawOutlinedRect(0, 0, w, h, 1)
                    draw.SimpleText("#" .. t.id .. " · " .. t.reqName .. (mine and "  (EN COURS)" or ""),
                        "SangUI_Body", S(10), S(6), C.goldLt, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    draw.SimpleText(SANGTICKET.ReasonName(t.reason) .. (t.claimed and (" · pris: " .. (t.claimerName or "?")) or ""),
                        "SangUI_Small", S(10), S(27), C.txtDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                end
                row.DoClick = function() SANGTICKET.OpenDetail(t.id) end
            end
        end
        if not any then
            local l = vgui.Create("DLabel", scroll)
            l:Dock(TOP) l:SetTall(S(40)) l:SetContentAlignment(5)
            l:SetFont("SangUI_Body") l:SetTextColor(C.txtDim) l:SetText("Aucun ticket en cours.")
        end
    end
    SANGTICKET._rebuildBoard()
end

concommand.Add("sang_tickets", function() SANGTICKET.OpenBoard() end)

----------------------------------------------------------------------
-- Notation (joueur) — fortement incitée : reste affichée jusqu'à la note
----------------------------------------------------------------------
net.Receive("sang_ticket_rateprompt", function()
    local id    = net.ReadUInt(16)
    local staff = net.ReadString()
    if not UIok() then return end
    local UI, C, S = BLOOD.UI, BLOOD.UI.Col, BLOOD.UI.Scale
    if IsValid(SANGTICKET._rate) then SANGTICKET._rate:Remove() end

    local f = vgui.Create("DFrame")
    SANGTICKET._rate = f
    f:SetSize(S(320), S(140)) f:SetPos(S(16), S(120))
    f:SetTitle("") f:ShowCloseButton(false) f:SetDraggable(false)
    f:MakePopup()
    f.Paint = function(_, w, h)
        UI.Panel(0, 0, w, h)
        draw.SimpleText("Note ton ticket", "SangUI_Title", w / 2, S(12), C.goldLt, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText("Traité par " .. staff, "SangUI_Small", w / 2, S(40), C.txtDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end

    local stars = vgui.Create("DPanel", f)
    stars:SetPos(S(30), S(66)) stars:SetSize(S(260), S(40)) stars.Paint = function() end
    for i = 1, 5 do
        local b = vgui.Create("DButton", stars)
        b:SetPos((i - 1) * S(52), 0) b:SetSize(S(48), S(40)) b:SetText("")
        b.Paint = function(self, w, h)
            draw.SimpleText("★", "SangUI_H1", w / 2, h / 2, self:IsHovered() and C.goldLt or C.gold, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        b.DoClick = function()
            net.Start("sang_ticket_rate") net.WriteUInt(id, 16) net.WriteUInt(i, 3) net.SendToServer()
            f:Remove()
        end
    end

    local later = vgui.Create("DButton", f)
    later:SetPos(S(120), S(110)) later:SetSize(S(80), S(22)) later:SetText("Plus tard")
    UI.SkinButton(later, "default")
    later.DoClick = function() f:Remove() end
end)
