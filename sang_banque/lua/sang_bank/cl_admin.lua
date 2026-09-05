--[[-------------------------------------------------------------------------
    Sang et Nuit — Banque : panneau admin (client)
      Deux onglets :
        • Gestion    : taxes, banques de faction, banque d'un joueur.
        • Historique : les 100 dernières actions de banque (persistant).
      Confort visuel — la vraie barrière est serveur-side.
---------------------------------------------------------------------------]]

SBANK = SBANK or {}
SBANK.AdminSel = SBANK.AdminSel or { sid = "", slot = 1 }
SBANK.PlayerBank = SBANK.PlayerBank or { sid = nil, slot = nil, amount = nil }
SBANK.AdminTab = SBANK.AdminTab or "gestion"
SBANK.History = SBANK.History or nil -- liste reçue du serveur (ou nil = pas encore)

local function pbankText()
    local sel, pb = SBANK.AdminSel, SBANK.PlayerBank
    if pb.sid and pb.sid == sel.sid and pb.slot == sel.slot and pb.amount ~= nil then
        return "Solde en banque (slot " .. sel.slot .. ") : " .. string.Comma(pb.amount)
    end
    return "Solde en banque : — (choisis un joueur et un slot)"
end

local function queryPlayerBank()
    local sid = SBANK.AdminSel.sid
    if not sid or sid == "" then return end
    net.Start("sang_bank_query")
    net.WriteString(sid)
    net.WriteUInt(SBANK.AdminSel.slot or 1, 8)
    net.SendToServer()
end
SBANK._queryPlayerBank = queryPlayerBank

net.Receive("sang_bank_queryresult", function()
    local sid = net.ReadString()
    local slot = net.ReadUInt(8)
    local amount = net.ReadUInt(32)
    SBANK.PlayerBank = { sid = sid, slot = slot, amount = amount }
    if IsValid(SBANK._pbankLabel) then SBANK._pbankLabel:SetText(pbankText()) end
end)

local function section(parent, text)
    local UI, C = BLOOD.UI, BLOOD.UI.Col
    local S = UI.Scale
    local l = vgui.Create("DPanel", parent)
    l:Dock(TOP) l:DockMargin(0, S(8), S(6), S(4)) l:SetTall(S(24))
    l.Paint = function(_, w, h)
        draw.SimpleText(text, "SangUI_Body", 0, h / 2, C.goldLt, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(C.goldDk); surface.DrawRect(0, h - 1, w, 1)
    end
    return l
end

-- Barre de défilement stylée (dorée sombre) pour un DScrollPanel.
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

----------------------------------------------------------------------
-- Onglet « Gestion »
----------------------------------------------------------------------
function SBANK.BuildManageTab(parent)
    local UI, C = BLOOD.UI, BLOOD.UI.Col
    local S = UI.Scale
    local d = SBANK.Data

    local scroll = vgui.Create("DScrollPanel", parent)
    scroll:Dock(FILL)
    skinScroll(scroll)
    local p = scroll

    -- 1) Taxes
    section(p, "1)  Taxes  (versées à la Guilde)")
    local function taxRow(kind, label, value)
        local row = vgui.Create("DPanel", p)
        row:Dock(TOP) row:DockMargin(0, S(2), S(6), S(4)) row:SetTall(S(28))
        row.Paint = function() end
        local lbl = vgui.Create("DLabel", row)
        lbl:Dock(LEFT) lbl:SetWide(S(160)) lbl:SetFont("SangUI_Small") lbl:SetTextColor(C.txt)
        lbl:SetText(label)
        local ent = vgui.Create("DTextEntry", row)
        ent:Dock(FILL) ent:SetNumeric(true) ent:SetText(tostring(value))
        UI.SkinEntry(ent)
        local btn = vgui.Create("DButton", row)
        btn:Dock(RIGHT) btn:DockMargin(S(8), 0, 0, 0) btn:SetWide(S(120)) btn:SetText("Régler")
        UI.SkinButton(btn, "gold")
        btn.DoClick = function()
            net.Start("sang_bank_settax")
            net.WriteString(kind)
            net.WriteUInt(math.Clamp(math.floor(tonumber(ent:GetValue()) or 0), 0, 100), 8)
            net.SendToServer()
        end
    end
    taxRow("personal", "Taxe banques perso (%)", d.taxP)
    taxRow("faction", "Taxe banques faction (%)", d.taxF)

    -- 2) Banques de faction
    section(p, "2)  Banques de faction")
    local facs = { { "monstre", "Monstre", d.monstre }, { "humain", "Humain", d.humain }, { "guilde", "Guilde", d.guilde } }
    for _, fr in ipairs(facs) do
        local fac, name, bal = fr[1], fr[2], fr[3]
        local row = vgui.Create("DPanel", p)
        row:Dock(TOP) row:DockMargin(0, S(2), S(6), S(4)) row:SetTall(S(28))
        row.Paint = function(_, w, h)
            draw.SimpleText(name .. " : " .. string.Comma(bal), "SangUI_Small", 0, h / 2, C.goldLt, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        local ent = vgui.Create("DTextEntry", row)
        ent:Dock(LEFT) ent:DockMargin(S(150), S(1), 0, S(1)) ent:SetWide(S(110)) ent:SetNumeric(true) ent:SetText("0")
        UI.SkinEntry(ent)
        local add = vgui.Create("DButton", row)
        add:Dock(RIGHT) add:SetWide(S(90)) add:SetText("Ajouter")
        UI.SkinButton(add, "gold")
        local rem = vgui.Create("DButton", row)
        rem:Dock(RIGHT) rem:DockMargin(0, 0, S(6), 0) rem:SetWide(S(90)) rem:SetText("Retirer")
        UI.SkinButton(rem, "blood")
        local function send(sign)
            local a = math.floor(tonumber(ent:GetValue()) or 0)
            if a <= 0 then return end
            net.Start("sang_bank_setfaction") net.WriteString(fac) net.WriteInt(sign * a, 32) net.SendToServer()
        end
        add.DoClick = function() send(1) end
        rem.DoClick = function() send(-1) end
    end

    -- 3) Banque d'un joueur
    section(p, "3)  Banque d'un joueur (par slot)")
    local sidLbl = vgui.Create("DLabel", p)
    sidLbl:Dock(TOP) sidLbl:DockMargin(0, S(2), 0, S(2)) sidLbl:SetFont("SangUI_Small") sidLbl:SetTextColor(C.txtDim)
    sidLbl:SetText("SteamID cible (STEAM_0:... ou 7656...) :")
    local sidEntry = vgui.Create("DTextEntry", p)
    sidEntry:Dock(TOP) sidEntry:DockMargin(0, 0, S(6), S(4)) sidEntry:SetTall(S(26))
    sidEntry:SetText(SBANK.AdminSel.sid or "")
    UI.SkinEntry(sidEntry)
    sidEntry.OnValueChange = function(_, val)
        SBANK.AdminSel.sid = string.Trim(val or "")
        queryPlayerBank()
    end

    -- Liste déroulante des joueurs connectés (comme le menu origines)
    local plyCombo = vgui.Create("DComboBox", p)
    plyCombo:Dock(TOP) plyCombo:DockMargin(0, 0, S(6), S(4)) plyCombo:SetTall(S(26))
    plyCombo:SetValue("— Choisir un joueur connecté —")
    UI.SkinCombo(plyCombo)
    for _, pl in ipairs(player.GetAll()) do
        plyCombo:AddChoice(pl:Nick() .. "  (" .. pl:SteamID() .. ")", pl:SteamID64())
    end
    plyCombo.OnSelect = function(_, _, _, data)
        sidEntry:SetText(data or "")
        SBANK.AdminSel.sid = data or ""
        queryPlayerBank()
    end

    local prow = vgui.Create("DPanel", p)
    prow:Dock(TOP) prow:DockMargin(0, S(2), S(6), S(4)) prow:SetTall(S(28))
    prow.Paint = function() end
    local slotCombo = vgui.Create("DComboBox", prow)
    slotCombo:Dock(LEFT) slotCombo:SetWide(S(120))
    UI.SkinCombo(slotCombo)
    for i = 1, 4 do slotCombo:AddChoice("Slot " .. i, i) end
    slotCombo:ChooseOptionID(math.Clamp(SBANK.AdminSel.slot or 1, 1, 4))
    slotCombo.OnSelect = function(_, _, val)
        SBANK.AdminSel.slot = tonumber(val) or 1
        queryPlayerBank()
    end
    local pent = vgui.Create("DTextEntry", prow)
    pent:Dock(LEFT) pent:DockMargin(S(8), S(1), 0, S(1)) pent:SetWide(S(110)) pent:SetNumeric(true) pent:SetText("0")
    UI.SkinEntry(pent)
    local padd = vgui.Create("DButton", prow)
    padd:Dock(RIGHT) padd:SetWide(S(90)) padd:SetText("Ajouter")
    UI.SkinButton(padd, "gold")
    local prem = vgui.Create("DButton", prow)
    prem:Dock(RIGHT) prem:DockMargin(0, 0, S(6), 0) prem:SetWide(S(90)) prem:SetText("Retirer")
    UI.SkinButton(prem, "blood")
    local function sendP(sign)
        local a = math.floor(tonumber(pent:GetValue()) or 0)
        if a <= 0 then return end
        local _, slot = slotCombo:GetSelected()
        net.Start("sang_bank_setplayer")
        net.WriteString(sidEntry:GetValue() or "")
        net.WriteUInt(tonumber(slot) or 1, 8)
        net.WriteInt(sign * a, 32)
        net.SendToServer()
    end
    padd.DoClick = function() sendP(1) end
    prem.DoClick = function() sendP(-1) end

    -- Solde en banque du joueur/slot sélectionné
    local pbankLbl = vgui.Create("DLabel", p)
    pbankLbl:Dock(TOP) pbankLbl:DockMargin(0, S(2), S(6), S(6)) pbankLbl:SetTall(S(22))
    pbankLbl:SetFont("SangUI_Body") pbankLbl:SetTextColor(C.goldLt)
    pbankLbl:SetText(pbankText())
    SBANK._pbankLabel = pbankLbl

    queryPlayerBank() -- rafraîchit le solde affiché
end

----------------------------------------------------------------------
-- Onglet « Historique »
----------------------------------------------------------------------
local ACTION_INFO = {
    depot         = { label = "Dépôt",           col = "hungerLt" },
    retrait       = { label = "Retrait",         col = "bloodLt"  },
    admin_joueur  = { label = "Admin · joueur",  col = "goldLt"   },
    admin_faction = { label = "Admin · faction", col = "goldLt"   },
    taxe          = { label = "Taxe",            col = "steelLt"  },
}

-- Nom lisible d'une cible (steamid64 ou faction).
local FACTION_LABEL = { monstre = "Monstre", humain = "Humain", guilde = "Guilde" }
local function targetText(h)
    if h.target == "" then return "" end
    if FACTION_LABEL[h.target] then return "Faction " .. FACTION_LABEL[h.target] end
    -- steamid64 : cible joueur (+ slot le cas échéant)
    local s = h.target
    if h.slot and h.slot > 0 then s = s .. " · slot " .. h.slot end
    return s
end

-- (Re)dessine la liste d'historique dans le conteneur mémorisé.
function SBANK.RenderHistory()
    local list = SBANK._histList
    if not IsValid(list) then return end
    local UI, C = BLOOD.UI, BLOOD.UI.Col
    local S = UI.Scale
    list:Clear()

    local hist = SBANK.History
    if hist == nil then
        local lbl = vgui.Create("DLabel", list)
        lbl:Dock(TOP) lbl:DockMargin(0, S(10), 0, 0) lbl:SetFont("SangUI_Small") lbl:SetTextColor(C.txtDim)
        lbl:SetText("Chargement de l'historique…")
        return
    end
    if #hist == 0 then
        local lbl = vgui.Create("DLabel", list)
        lbl:Dock(TOP) lbl:DockMargin(0, S(10), 0, 0) lbl:SetFont("SangUI_Small") lbl:SetTextColor(C.txtDim)
        lbl:SetText("Aucune action enregistrée pour le moment.")
        return
    end

    local cur = (BLOOD.Config and BLOOD.Config.Currency) or "Covan"
    for _, h in ipairs(hist) do
        local info = ACTION_INFO[h.action] or { label = h.action, col = "txt" }
        local acol = C[info.col] or C.txt
        local when = h.ts > 0 and os.date("%d/%m %H:%M", h.ts) or "—"
        local amtTxt = (h.amount >= 0 and "+" or "") .. string.Comma(h.amount) .. " " .. cur
        local amtCol = h.amount > 0 and C.hungerLt or (h.amount < 0 and C.bloodLt or C.txtDim)
        local tgt = targetText(h)
        local detail = h.detail or ""

        local row = vgui.Create("DPanel", list)
        row:Dock(TOP) row:DockMargin(0, 0, S(6), S(3)) row:SetTall(S(40))
        row.Paint = function(_, w, hh)
            UI.VGradient(0, 0, w, hh, UI.Shade(C.bg1, 4), C.bg0)
            surface.SetDrawColor(C.goldDk); surface.DrawOutlinedRect(0, 0, w, hh, 1)
            -- liseré coloré à gauche selon l'action
            surface.SetDrawColor(acol.r, acol.g, acol.b, 220); surface.DrawRect(0, 0, S(3), hh)

            -- ligne du haut : date · action · acteur
            draw.SimpleText(when, "SangUI_Tiny", S(10), S(7), C.txtDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(info.label, "SangUI_Small", S(78), S(7), acol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            if h.actor_name ~= "" then
                draw.SimpleText("par " .. h.actor_name, "SangUI_Tiny", S(210), S(7), C.txt, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            -- montant à droite
            draw.SimpleText(amtTxt, "SangUI_Bar", w - S(10), S(7), amtCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

            -- ligne du bas : cible + détail
            local sub = tgt
            if detail ~= "" then sub = (sub ~= "" and (sub .. "   —   ") or "") .. detail end
            if sub ~= "" then
                draw.SimpleText(sub, "SangUI_Tiny", S(10), hh - S(12), C.txtDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end
    end
end

function SBANK.RequestHistory()
    SBANK.History = nil
    net.Start("sang_bank_hist_req")
    net.SendToServer()
end

net.Receive("sang_bank_hist_data", function()
    local n = net.ReadUInt(8)
    local out = {}
    for _ = 1, n do
        out[#out + 1] = {
            ts         = net.ReadUInt(32),
            action     = net.ReadString(),
            actor_name = net.ReadString(),
            target     = net.ReadString(),
            slot       = net.ReadUInt(8),
            amount     = net.ReadInt(32),
            detail     = net.ReadString(),
        }
    end
    SBANK.History = out
    if SBANK.AdminTab == "historique" then SBANK.RenderHistory() end
end)

function SBANK.BuildHistoryTab(parent)
    local UI, C = BLOOD.UI, BLOOD.UI.Col
    local S = UI.Scale

    -- Bandeau : intitulé + bouton rafraîchir
    local top = vgui.Create("DPanel", parent)
    top:Dock(TOP) top:DockMargin(0, 0, S(6), S(6)) top:SetTall(S(28))
    top.Paint = function(_, w, h)
        draw.SimpleText("100 dernières actions de banque (conservées au redémarrage)",
            "SangUI_Small", 0, h / 2, C.txtDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    local ref = vgui.Create("DButton", top)
    ref:Dock(RIGHT) ref:SetWide(S(130)) ref:SetText("Rafraîchir")
    UI.SkinButton(ref, "gold")
    ref.DoClick = function() SBANK.RequestHistory() SBANK.RenderHistory() end

    local scroll = vgui.Create("DScrollPanel", parent)
    scroll:Dock(FILL)
    skinScroll(scroll)
    SBANK._histList = scroll

    SBANK.RenderHistory()      -- affiche l'état courant (ou « chargement »)
    SBANK.RequestHistory()     -- demande la version fraîche au serveur
end

----------------------------------------------------------------------
-- Onglets + châssis
----------------------------------------------------------------------
function SBANK.ShowAdminTab(id)
    SBANK.AdminTab = id
    local content = SBANK.AdminContent
    if not IsValid(content) then return end
    content:Clear()
    if IsValid(SBANK._tabBar) then SBANK._tabBar:InvalidateLayout() end
    if id == "historique" then
        SBANK.BuildHistoryTab(content)
    else
        SBANK.BuildManageTab(content)
    end
end

-- Rebuild appelé quand de nouvelles données arrivent (sang_bank_open).
function SBANK.RefreshAdminPanel()
    local f = SBANK.AdminFrame
    if not IsValid(f) or not IsValid(SBANK.AdminContent) then return end
    if SBANK.AdminTab == "gestion" then
        SBANK.AdminContent:Clear()
        SBANK.BuildManageTab(SBANK.AdminContent)
    end
end

local function tabButton(bar, id, label)
    local UI, C = BLOOD.UI, BLOOD.UI.Col
    local S = UI.Scale
    local b = vgui.Create("DButton", bar)
    b:Dock(LEFT) b:DockMargin(0, 0, S(6), 0) b:SetWide(S(160)) b:SetText("")
    b.Paint = function(self, w, h)
        local active = (SBANK.AdminTab == id)
        local hovered = self:IsHovered()
        local base = active and Color(64, 51, 28, 250) or C.bg1
        UI.VGradient(0, 0, w, h, UI.Shade(base, hovered and 16 or 6), UI.Shade(base, -14))
        surface.SetDrawColor(active and C.gold or C.goldDk)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        if active then
            surface.SetDrawColor(C.gold); surface.DrawRect(0, h - S(2), w, S(2))
        end
        draw.SimpleText(label, "SangUI_Body", w / 2, h / 2,
            active and C.goldLt or C.txtDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    b.DoClick = function() SBANK.ShowAdminTab(id) end
    return b
end

function SBANK.OpenAdminPanel()
    if not (BLOOD and BLOOD.UI) then return end
    local UI = BLOOD.UI
    local S = UI.Scale
    if IsValid(SBANK.AdminFrame) then SBANK.AdminFrame:Remove() end
    SBANK.AdminFrame = UI.MakeFrame(S(740), S(720), "Banque — Administration")

    local body = SBANK.AdminFrame.Body

    -- Barre d'onglets
    local bar = vgui.Create("DPanel", body)
    bar:Dock(TOP) bar:DockMargin(0, 0, 0, S(8)) bar:SetTall(S(34))
    bar.Paint = function() end
    SBANK._tabBar = bar
    tabButton(bar, "gestion", "Gestion")
    tabButton(bar, "historique", "Historique")

    -- Conteneur d'onglet
    local content = vgui.Create("DPanel", body)
    content:Dock(FILL)
    content.Paint = function() end
    SBANK.AdminContent = content

    SBANK.ShowAdminTab(SBANK.AdminTab or "gestion")
end
