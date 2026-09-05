--[[-------------------------------------------------------------------------
    Sang et Nuit — Menu admin "!origines" (UI Derma, style commun BLOOD.UI)

    RAPPEL : cette interface n'est qu'un confort. La vraie barrière de sécurité
    est SERVEUR-SIDE (chaque net message est re-vérifié contre la whitelist).
    Le serveur n'envoie "blood_open_admin" qu'aux joueurs autorisés.
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}
local UI = BLOOD.UI
local C = UI.Col
local S = UI.Scale

-- Petit label stylé
local function sectionLabel(parent, text)
    local l = vgui.Create("DPanel", parent)
    l:Dock(TOP)
    l:DockMargin(0, S(6), 0, S(4))
    l:SetTall(S(24))
    l.Paint = function(_, w, h)
        draw.SimpleText(text, "SangUI_Body", 0, h / 2, C.goldLt, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(C.goldDk); surface.DrawRect(0, h - 1, w, 1)
    end
    return l
end

local function fieldLabel(parent, text)
    local l = vgui.Create("DLabel", parent)
    l:Dock(TOP)
    l:DockMargin(0, S(4), 0, S(2))
    l:SetFont("SangUI_Small")
    l:SetTextColor(C.txtDim)
    l:SetText(text)
    return l
end

function BLOOD.OpenAdminMenu(races)
    if IsValid(BLOOD.AdminFrame) then BLOOD.AdminFrame:Remove() end

    local f = UI.MakeFrame(S(560), S(430), "Sang et Nuit — Origines (Admin)")
    BLOOD.AdminFrame = f
    local body = f.Body

    -- Cible SteamID
    fieldLabel(body, "SteamID cible (STEAM_0:... ou 7656...) :")
    local sidEntry = vgui.Create("DTextEntry", body)
    sidEntry:Dock(TOP) sidEntry:DockMargin(0, 0, 0, S(4)) sidEntry:SetTall(S(26))
    UI.SkinEntry(sidEntry)

    local combo = vgui.Create("DComboBox", body)
    combo:Dock(TOP) combo:DockMargin(0, 0, 0, S(8)) combo:SetTall(S(26))
    combo:SetValue("— Choisir un joueur connecté —")
    UI.SkinCombo(combo)
    for _, p in ipairs(player.GetAll()) do
        combo:AddChoice(p:Nick() .. "  (" .. p:SteamID() .. ")", p:SteamID64())
    end
    combo.OnSelect = function(_, _, _, data) sidEntry:SetText(data or "") end

    -- 1) Crédits
    sectionLabel(body, "1)  Donner des crédits de reroll")
    fieldLabel(body, "Nombre de crédits :")
    local amount = vgui.Create("DTextEntry", body)
    amount:Dock(TOP) amount:DockMargin(0, 0, 0, S(4)) amount:SetTall(S(26))
    amount:SetNumeric(true) amount:SetText("1")
    UI.SkinEntry(amount)

    local giveBtn = vgui.Create("DButton", body)
    giveBtn:Dock(TOP) giveBtn:DockMargin(0, 0, 0, S(10)) giveBtn:SetTall(S(30))
    giveBtn:SetText("Donner les crédits")
    UI.SkinButton(giveBtn, "gold")
    giveBtn.DoClick = function()
        net.Start("origines_give_credits")
        net.WriteString(sidEntry:GetValue() or "")
        net.WriteInt(math.floor(tonumber(amount:GetValue()) or 0), 32)
        net.SendToServer()
    end

    -- 2) Définir une race
    sectionLabel(body, "2)  Définir une race sur un slot  (contourne tirage + paiement)")

    local rowsel = vgui.Create("DPanel", body)
    rowsel:Dock(TOP) rowsel:DockMargin(0, S(2), 0, S(8)) rowsel:SetTall(S(26))
    rowsel.Paint = function() end

    local slotCombo = vgui.Create("DComboBox", rowsel)
    slotCombo:Dock(LEFT) slotCombo:SetWide(S(150))
    UI.SkinCombo(slotCombo)
    for i = 1, BLOOD.Config.MaxSlots do slotCombo:AddChoice("Slot " .. i, i) end
    slotCombo:ChooseOptionID(1)

    local raceCombo = vgui.Create("DComboBox", rowsel)
    raceCombo:Dock(FILL) raceCombo:DockMargin(S(8), 0, 0, 0)
    UI.SkinCombo(raceCombo)
    for _, r in ipairs(races or {}) do raceCombo:AddChoice(r.name, r.id) end
    raceCombo:ChooseOptionID(1)

    local setBtn = vgui.Create("DButton", body)
    setBtn:Dock(TOP) setBtn:DockMargin(0, 0, 0, S(4)) setBtn:SetTall(S(30))
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
end
