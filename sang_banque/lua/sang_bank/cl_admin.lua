--[[-------------------------------------------------------------------------
    Sang et Nuit — Banque : panneau admin (client)
      Réglage des taxes, gestion des banques de faction et des banques
      joueurs. Confort visuel — la vraie barrière est serveur-side.
---------------------------------------------------------------------------]]

SBANK = SBANK or {}

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

function SBANK.RefreshAdminPanel()
    local f = SBANK.AdminFrame
    if not IsValid(f) or not IsValid(f.Body) then return end
    local UI, C = BLOOD.UI, BLOOD.UI.Col
    local S = UI.Scale
    local d = SBANK.Data

    local body = f.Body
    body:Clear()

    local scroll = vgui.Create("DScrollPanel", body)
    scroll:Dock(FILL)
    local sbar = scroll:GetVBar()
    sbar:SetWide(S(8))
    sbar.Paint = function() end
    sbar.btnUp.Paint = function() end
    sbar.btnDown.Paint = function() end
    sbar.btnGrip.Paint = function(_, w, h) surface.SetDrawColor(C.goldDk); surface.DrawRect(0, 0, w, h) end
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
    UI.SkinEntry(sidEntry)

    local prow = vgui.Create("DPanel", p)
    prow:Dock(TOP) prow:DockMargin(0, S(2), S(6), S(6)) prow:SetTall(S(28))
    prow.Paint = function() end
    local slotCombo = vgui.Create("DComboBox", prow)
    slotCombo:Dock(LEFT) slotCombo:SetWide(S(120))
    UI.SkinCombo(slotCombo)
    for i = 1, 4 do slotCombo:AddChoice("Slot " .. i, i) end
    slotCombo:ChooseOptionID(1)
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
end

function SBANK.OpenAdminPanel()
    if not (BLOOD and BLOOD.UI) then return end
    local UI = BLOOD.UI
    local S = UI.Scale
    if IsValid(SBANK.AdminFrame) then SBANK.AdminFrame:Remove() end
    SBANK.AdminFrame = UI.MakeFrame(S(560), S(560), "Banque — Administration")
    SBANK.RefreshAdminPanel()
end
