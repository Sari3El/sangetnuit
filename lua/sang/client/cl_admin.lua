--[[-------------------------------------------------------------------------
    Sang et Nuit — Menu admin "!origines" (UI Derma, style commun BLOOD.UI)

    RAPPEL : cette interface n'est qu'un confort. La vraie barrière de sécurité
    est SERVEUR-SIDE (chaque net message est re-vérifié contre la whitelist).
    Le serveur n'envoie "blood_open_admin" qu'aux joueurs autorisés.

    Actions : donner des crédits, définir une race, renommer un slot,
    débloquer/verrouiller le slot payant.
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}
local UI = BLOOD.UI
local C = UI.Col
local S = UI.Scale

local function sectionLabel(parent, text)
    local l = vgui.Create("DPanel", parent)
    l:Dock(TOP) l:DockMargin(0, S(8), S(6), S(4)) l:SetTall(S(24))
    l.Paint = function(_, w, h)
        draw.SimpleText(text, "SangUI_Body", 0, h / 2, C.goldLt, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(C.goldDk); surface.DrawRect(0, h - 1, w, 1)
    end
    return l
end

local function fieldLabel(parent, text)
    local l = vgui.Create("DLabel", parent)
    l:Dock(TOP) l:DockMargin(0, S(4), 0, S(2))
    l:SetFont("SangUI_Small") l:SetTextColor(C.txtDim) l:SetText(text)
    return l
end

function BLOOD.OpenAdminMenu(races)
    if IsValid(BLOOD.AdminFrame) then BLOOD.AdminFrame:Remove() end

    local f = UI.MakeFrame(S(760), S(720), "Sang et Nuit — Origines (Admin)")
    BLOOD.AdminFrame = f

    -- Zone défilante
    local scroll = vgui.Create("DScrollPanel", f.Body)
    scroll:Dock(FILL)
    local sbar = scroll:GetVBar()
    sbar:SetWide(S(8))
    sbar.Paint = function() end
    sbar.btnUp.Paint = function() end
    sbar.btnDown.Paint = function() end
    sbar.btnGrip.Paint = function(_, w, h) surface.SetDrawColor(C.goldDk); surface.DrawRect(0, 0, w, h) end
    local body = scroll

    -- Cible SteamID (commune à toutes les actions)
    fieldLabel(body, "SteamID cible (STEAM_0:... ou 7656...) :")
    local sidEntry = vgui.Create("DTextEntry", body)
    sidEntry:Dock(TOP) sidEntry:DockMargin(0, 0, S(6), S(4)) sidEntry:SetTall(S(26))
    UI.SkinEntry(sidEntry)

    local combo = vgui.Create("DComboBox", body)
    combo:Dock(TOP) combo:DockMargin(0, 0, S(6), S(4)) combo:SetTall(S(26))
    combo:SetValue("— Choisir un joueur connecté —")
    UI.SkinCombo(combo)
    for _, p in ipairs(player.GetAll()) do
        combo:AddChoice(p:Nick() .. "  (" .. p:SteamID() .. ")", p:SteamID64())
    end
    combo.OnSelect = function(_, _, _, data) sidEntry:SetText(data or "") end

    ------------------------------------------------------------------
    -- 1) Crédits
    ------------------------------------------------------------------
    sectionLabel(body, "1)  Donner des crédits de reroll")
    fieldLabel(body, "Nombre de crédits :")
    local amount = vgui.Create("DTextEntry", body)
    amount:Dock(TOP) amount:DockMargin(0, 0, S(6), S(4)) amount:SetTall(S(26))
    amount:SetNumeric(true) amount:SetText("1")
    UI.SkinEntry(amount)

    local giveBtn = vgui.Create("DButton", body)
    giveBtn:Dock(TOP) giveBtn:DockMargin(0, 0, S(6), S(4)) giveBtn:SetTall(S(30))
    giveBtn:SetText("Donner les crédits")
    UI.SkinButton(giveBtn, "gold")
    giveBtn.DoClick = function()
        net.Start("origines_give_credits")
        net.WriteString(sidEntry:GetValue() or "")
        net.WriteInt(math.floor(tonumber(amount:GetValue()) or 0), 32)
        net.SendToServer()
    end

    ------------------------------------------------------------------
    -- 2) Définir une race
    ------------------------------------------------------------------
    sectionLabel(body, "2)  Définir une race sur un slot  (contourne tirage + paiement)")
    local rowRace = vgui.Create("DPanel", body)
    rowRace:Dock(TOP) rowRace:DockMargin(0, S(2), S(6), S(4)) rowRace:SetTall(S(26))
    rowRace.Paint = function() end

    local slotCombo = vgui.Create("DComboBox", rowRace)
    slotCombo:Dock(LEFT) slotCombo:SetWide(S(150))
    UI.SkinCombo(slotCombo)
    for i = 1, BLOOD.Config.MaxSlots do slotCombo:AddChoice("Slot " .. i, i) end
    slotCombo:ChooseOptionID(1)

    local raceCombo = vgui.Create("DComboBox", rowRace)
    raceCombo:Dock(FILL) raceCombo:DockMargin(S(8), 0, 0, 0)
    UI.SkinCombo(raceCombo)
    for _, r in ipairs(races or {}) do raceCombo:AddChoice(r.name, r.id) end
    raceCombo:ChooseOptionID(1)

    local setBtn = vgui.Create("DButton", body)
    setBtn:Dock(TOP) setBtn:DockMargin(0, 0, S(6), S(4)) setBtn:SetTall(S(30))
    setBtn:SetText("Définir la race")
    UI.SkinButton(setBtn, "blood")
    setBtn.DoClick = function()
        local _, slot   = slotCombo:GetSelected()
        local _, raceId = raceCombo:GetSelected()
        net.Start("origines_set_race")
        net.WriteString(sidEntry:GetValue() or "")
        net.WriteUInt(tonumber(slot) or 1, 8)
        net.WriteString(raceId or "human")
        net.SendToServer()
    end

    ------------------------------------------------------------------
    -- 3) Renommer un slot
    ------------------------------------------------------------------
    sectionLabel(body, "3)  Renommer un slot")
    local rowRen = vgui.Create("DPanel", body)
    rowRen:Dock(TOP) rowRen:DockMargin(0, S(2), S(6), S(4)) rowRen:SetTall(S(26))
    rowRen.Paint = function() end

    local slotCombo2 = vgui.Create("DComboBox", rowRen)
    slotCombo2:Dock(LEFT) slotCombo2:SetWide(S(150))
    UI.SkinCombo(slotCombo2)
    for i = 1, BLOOD.Config.MaxSlots do slotCombo2:AddChoice("Slot " .. i, i) end
    slotCombo2:ChooseOptionID(1)

    local nameEntry = vgui.Create("DTextEntry", rowRen)
    nameEntry:Dock(FILL) nameEntry:DockMargin(S(8), 0, 0, 0)
    nameEntry:SetPlaceholderText("Nouveau nom…")
    UI.SkinEntry(nameEntry)

    local renBtn = vgui.Create("DButton", body)
    renBtn:Dock(TOP) renBtn:DockMargin(0, 0, S(6), S(4)) renBtn:SetTall(S(30))
    renBtn:SetText("Renommer le slot")
    UI.SkinButton(renBtn, "gold")
    renBtn.DoClick = function()
        local _, slot = slotCombo2:GetSelected()
        net.Start("origines_rename_slot")
        net.WriteString(sidEntry:GetValue() or "")
        net.WriteUInt(tonumber(slot) or 1, 8)
        net.WriteString(nameEntry:GetValue() or "")
        net.SendToServer()
    end

    ------------------------------------------------------------------
    -- 4) Slot payant (slot 4)
    ------------------------------------------------------------------
    sectionLabel(body, "4)  Slot payant (slot " .. BLOOD.Config.MaxSlots .. ")")
    local rowPaid = vgui.Create("DPanel", body)
    rowPaid:Dock(TOP) rowPaid:DockMargin(0, S(2), S(6), S(6)) rowPaid:SetTall(S(30))
    rowPaid.Paint = function() end

    local unlockBtn = vgui.Create("DButton", rowPaid)
    unlockBtn:Dock(LEFT) unlockBtn:SetWide(S(240))
    unlockBtn:SetText("Débloquer le slot payant")
    UI.SkinButton(unlockBtn, "gold")
    unlockBtn.DoClick = function()
        net.Start("origines_set_paid")
        net.WriteString(sidEntry:GetValue() or "")
        net.WriteBool(true)
        net.SendToServer()
    end

    local lockBtn = vgui.Create("DButton", rowPaid)
    lockBtn:Dock(FILL) lockBtn:DockMargin(S(8), 0, 0, 0)
    lockBtn:SetText("Verrouiller le slot payant")
    UI.SkinButton(lockBtn, "default")
    lockBtn.DoClick = function()
        net.Start("origines_set_paid")
        net.WriteString(sidEntry:GetValue() or "")
        net.WriteBool(false)
        net.SendToServer()
    end

    ------------------------------------------------------------------
    -- 5) Argent (Covan)
    ------------------------------------------------------------------
    sectionLabel(body, "5)  Argent (" .. (BLOOD.Config.Currency or "Covan") .. ")  — par personnage")
    local rowMoney = vgui.Create("DPanel", body)
    rowMoney:Dock(TOP) rowMoney:DockMargin(0, S(2), S(6), S(4)) rowMoney:SetTall(S(26))
    rowMoney.Paint = function() end

    local slotCombo3 = vgui.Create("DComboBox", rowMoney)
    slotCombo3:Dock(LEFT) slotCombo3:SetWide(S(150))
    UI.SkinCombo(slotCombo3)
    for i = 1, BLOOD.Config.MaxSlots do slotCombo3:AddChoice("Slot " .. i, i) end
    slotCombo3:ChooseOptionID(1)

    local covanEntry = vgui.Create("DTextEntry", rowMoney)
    covanEntry:Dock(FILL) covanEntry:DockMargin(S(8), 0, 0, 0)
    covanEntry:SetNumeric(true) covanEntry:SetText("0")
    UI.SkinEntry(covanEntry)

    local rowMoneyBtns = vgui.Create("DPanel", body)
    rowMoneyBtns:Dock(TOP) rowMoneyBtns:DockMargin(0, 0, S(6), S(6)) rowMoneyBtns:SetTall(S(30))
    rowMoneyBtns.Paint = function() end

    local function sendCovan(isAdd)
        local _, slot = slotCombo3:GetSelected()
        net.Start("origines_set_covan")
        net.WriteString(sidEntry:GetValue() or "")
        net.WriteUInt(tonumber(slot) or 1, 8)
        net.WriteInt(math.floor(tonumber(covanEntry:GetValue()) or 0), 32)
        net.WriteBool(isAdd)
        net.SendToServer()
    end

    local setMoney = vgui.Create("DButton", rowMoneyBtns)
    setMoney:Dock(LEFT) setMoney:SetWide(S(240))
    setMoney:SetText("Définir le montant")
    UI.SkinButton(setMoney, "gold")
    setMoney.DoClick = function() sendCovan(false) end

    local addMoney = vgui.Create("DButton", rowMoneyBtns)
    addMoney:Dock(FILL) addMoney:DockMargin(S(8), 0, 0, 0)
    addMoney:SetText("Ajouter / retirer")
    UI.SkinButton(addMoney, "default")
    addMoney.DoClick = function() sendCovan(true) end
end
