--[[-------------------------------------------------------------------------
    Sang et Nuit — Banque : menu joueur (client)
      Menu de banque perso (dépôt/retrait) + bouton admin (haut-droite).
      Indices [E] quand on vise une banque ou un tas d'or.
      Style commun BLOOD.UI (addon principal requis).
---------------------------------------------------------------------------]]

SBANK = SBANK or {}
SBANK.Data = SBANK.Data or { personal = 0, taxP = 0, taxF = 0, monstre = 0, humain = 0, guilde = 0, isAdmin = false }

surface.CreateFont("SangBank_Hint", { font = "Georgia", size = 20, weight = 700, antialias = true, extended = true })

local function uiReady() return BLOOD and BLOOD.UI end

----------------------------------------------------------------------
-- Réception des données
----------------------------------------------------------------------
net.Receive("sang_bank_open", function()
    local d = {}
    d.personal = net.ReadUInt(32)
    d.taxP     = net.ReadUInt(8)
    d.taxF     = net.ReadUInt(8)
    d.monstre  = net.ReadUInt(32)
    d.humain   = net.ReadUInt(32)
    d.guilde   = net.ReadUInt(32)
    d.isAdmin  = net.ReadBool()
    SBANK.Data = d

    if IsValid(SBANK.BankFrame) then
        SBANK.RefreshBankMenu()
    else
        SBANK.OpenBankMenu()
    end
    if IsValid(SBANK.AdminFrame) and SBANK.RefreshAdminPanel then
        SBANK.RefreshAdminPanel()
    end
end)

----------------------------------------------------------------------
-- Menu banque perso
----------------------------------------------------------------------
function SBANK.RefreshBankMenu()
    local f = SBANK.BankFrame
    if not IsValid(f) or not IsValid(f.Body) then return end
    local UI, C = BLOOD.UI, BLOOD.UI.Col
    local S = UI.Scale
    local d = SBANK.Data
    local body = f.Body
    body:Clear()

    local wallet = LocalPlayer():GetNWInt("blood_covan", 0)
    local cur = (BLOOD.Config and BLOOD.Config.Currency) or "Covan"

    -- Bandeau soldes
    local head = vgui.Create("DPanel", body)
    head:Dock(TOP) head:DockMargin(0, 0, 0, S(8)) head:SetTall(S(64))
    head.Paint = function(_, w, h)
        UI.VGradient(0, 0, w, h, UI.Shade(C.bg2, 6), C.bg1)
        surface.SetDrawColor(C.goldDk); surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("Sur toi", "SangUI_Small", S(12), S(10), C.txtDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(string.Comma(wallet) .. " " .. cur, "SangUI_Title", S(12), S(28), C.txt, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("En banque", "SangUI_Small", w - S(12), S(10), C.txtDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        draw.SimpleText(string.Comma(d.personal) .. " " .. cur, "SangUI_Title", w - S(12), S(28), C.goldLt, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    end

    local taxLbl = vgui.Create("DLabel", body)
    taxLbl:Dock(TOP) taxLbl:DockMargin(0, 0, 0, S(8))
    taxLbl:SetFont("SangUI_Small") taxLbl:SetTextColor(C.txtDim)
    taxLbl:SetText("Taxe appliquée au dépôt et au retrait : " .. d.taxP .. "%  (versée à la Guilde)")

    -- Dépôt
    local depRow = vgui.Create("DPanel", body)
    depRow:Dock(TOP) depRow:DockMargin(0, 0, 0, S(6)) depRow:SetTall(S(30))
    depRow.Paint = function() end
    local depEntry = vgui.Create("DTextEntry", depRow)
    depEntry:Dock(FILL) depEntry:SetNumeric(true) depEntry:SetText("") depEntry:SetPlaceholderText("Montant à déposer…")
    UI.SkinEntry(depEntry)
    local depBtn = vgui.Create("DButton", depRow)
    depBtn:Dock(RIGHT) depBtn:DockMargin(S(8), 0, 0, 0) depBtn:SetWide(S(150)) depBtn:SetText("Déposer")
    UI.SkinButton(depBtn, "gold")
    depBtn.DoClick = function()
        local a = math.floor(tonumber(depEntry:GetValue()) or 0)
        if a > 0 then net.Start("sang_bank_deposit") net.WriteUInt(a, 32) net.SendToServer() end
    end

    -- Retrait
    local witRow = vgui.Create("DPanel", body)
    witRow:Dock(TOP) witRow:DockMargin(0, 0, 0, S(6)) witRow:SetTall(S(30))
    witRow.Paint = function() end
    local witEntry = vgui.Create("DTextEntry", witRow)
    witEntry:Dock(FILL) witEntry:SetNumeric(true) witEntry:SetText("") witEntry:SetPlaceholderText("Montant à retirer…")
    UI.SkinEntry(witEntry)
    local witBtn = vgui.Create("DButton", witRow)
    witBtn:Dock(RIGHT) witBtn:DockMargin(S(8), 0, 0, 0) witBtn:SetWide(S(150)) witBtn:SetText("Retirer")
    UI.SkinButton(witBtn, "blood")
    witBtn.DoClick = function()
        local a = math.floor(tonumber(witEntry:GetValue()) or 0)
        if a > 0 then net.Start("sang_bank_withdraw") net.WriteUInt(a, 32) net.SendToServer() end
    end
end

function SBANK.OpenBankMenu()
    if not uiReady() then
        chat.AddText(Color(255, 80, 80), "[Banque] L'addon principal 'sang_et_nuit' est requis.")
        return
    end
    local UI = BLOOD.UI
    local S = UI.Scale
    if IsValid(SBANK.BankFrame) then SBANK.BankFrame:Remove() end

    local f = UI.MakeFrame(S(720), S(500), "Banque")
    SBANK.BankFrame = f

    -- Bouton admin (haut-droite, à gauche de la croix), visible si autorisé
    if SBANK.Data.isAdmin then
        local hdr = f.HeaderH or S(46)
        local bw = S(160)
        local ab = vgui.Create("DButton", f)
        ab:SetSize(bw, hdr - S(16))
        ab:SetPos(f:GetWide() - hdr - bw - S(8), S(8))
        ab:SetText("Administration")
        UI.SkinButton(ab, "gold")
        ab:MoveToFront()
        ab.DoClick = function()
            if SBANK.OpenAdminPanel then SBANK.OpenAdminPanel() end
        end
    end

    SBANK.RefreshBankMenu()
end

----------------------------------------------------------------------
-- Indices [E] (banque / or au sol)
----------------------------------------------------------------------
hook.Add("HUDPaint", "SANGBANK_Hints", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local tr = ply:GetEyeTrace()
    local e = tr.Entity
    if not IsValid(e) then return end

    local cx, cy = ScrW() / 2, ScrH() / 2
    local cur = (BLOOD and BLOOD.Config and BLOOD.Config.Currency) or "Covan"
    local gold = Color(176, 141, 74)
    local sh = Color(0, 0, 0, 200)

    local function hint(txt)
        draw.SimpleText(txt, "SangBank_Hint", cx + 1, cy + 41, sh, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(txt, "SangBank_Hint", cx, cy + 40, gold, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    if e:GetClass() == "sang_bank" and ply:GetPos():Distance(e:GetPos()) <= (SBANK.Config.OpenDist) then
        hint("[E] Ouvrir la banque")
    elseif e:GetClass() == "sang_gold" and ply:EyePos():Distance(tr.HitPos) <= (SBANK.Config.PickupDist) then
        local amt = (e.GetGold and e:GetGold()) or 0
        hint("[E] Ramasser " .. string.Comma(amt) .. " " .. cur)
    end
end)
