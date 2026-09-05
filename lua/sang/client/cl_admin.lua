--[[-------------------------------------------------------------------------
    Sang et Nuit — Menu admin "!origines" (UI Derma)

    RAPPEL : cette interface n'est qu'un confort. La vraie barrière de sécurité
    est SERVEUR-SIDE (chaque net message est re-vérifié contre la whitelist).
    Le serveur n'envoie "blood_open_admin" qu'aux joueurs autorisés.
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}

function BLOOD.OpenAdminMenu(races)
    if IsValid(BLOOD.AdminFrame) then BLOOD.AdminFrame:Remove() end

    local f = vgui.Create("DFrame")
    BLOOD.AdminFrame = f
    f:SetSize(540, 380)
    f:Center()
    f:SetTitle("Sang et Nuit — Menu Admin (!origines)")
    f:MakePopup()

    -- SteamID cible
    local sidLbl = vgui.Create("DLabel", f)
    sidLbl:Dock(TOP) sidLbl:DockMargin(12, 8, 12, 0)
    sidLbl:SetText("SteamID cible (STEAM_0:... ou 7656...) :")

    local sidEntry = vgui.Create("DTextEntry", f)
    sidEntry:Dock(TOP) sidEntry:DockMargin(12, 2, 12, 4) sidEntry:SetTall(24)

    -- Liste des joueurs connectés (confort)
    local combo = vgui.Create("DComboBox", f)
    combo:Dock(TOP) combo:DockMargin(12, 0, 12, 8) combo:SetTall(24)
    combo:SetValue("— Choisir un joueur connecté —")
    for _, p in ipairs(player.GetAll()) do
        combo:AddChoice(p:Nick() .. " (" .. p:SteamID() .. ")", p:SteamID64())
    end
    combo.OnSelect = function(_, _, _, data)
        sidEntry:SetText(data or "")
    end

    -- --- Donner des crédits ---
    local gLbl = vgui.Create("DLabel", f)
    gLbl:Dock(TOP) gLbl:DockMargin(12, 4, 12, 0)
    gLbl:SetText("1) Donner des crédits de reroll :")

    local amount = vgui.Create("DTextEntry", f)
    amount:Dock(TOP) amount:DockMargin(12, 2, 12, 2) amount:SetTall(24)
    amount:SetNumeric(true) amount:SetText("1")

    local giveBtn = vgui.Create("DButton", f)
    giveBtn:Dock(TOP) giveBtn:DockMargin(12, 2, 12, 10) giveBtn:SetTall(28)
    giveBtn:SetText("Donner les crédits")
    giveBtn.DoClick = function()
        net.Start("origines_give_credits")
        net.WriteString(sidEntry:GetValue() or "")
        net.WriteInt(math.floor(tonumber(amount:GetValue()) or 0), 32)
        net.SendToServer()
    end

    -- --- Définir une race sur un slot ---
    local rLbl = vgui.Create("DLabel", f)
    rLbl:Dock(TOP) rLbl:DockMargin(12, 4, 12, 0)
    rLbl:SetText("2) Définir une race sur un slot (contourne tirage + paiement) :")

    local slotCombo = vgui.Create("DComboBox", f)
    slotCombo:Dock(TOP) slotCombo:DockMargin(12, 2, 12, 2) slotCombo:SetTall(24)
    for i = 1, BLOOD.Config.MaxSlots do slotCombo:AddChoice("Slot " .. i, i) end
    slotCombo:ChooseOptionID(1)

    local raceCombo = vgui.Create("DComboBox", f)
    raceCombo:Dock(TOP) raceCombo:DockMargin(12, 2, 12, 2) raceCombo:SetTall(24)
    for _, r in ipairs(races or {}) do raceCombo:AddChoice(r.name, r.id) end
    raceCombo:ChooseOptionID(1)

    local setBtn = vgui.Create("DButton", f)
    setBtn:Dock(TOP) setBtn:DockMargin(12, 2, 12, 10) setBtn:SetTall(28)
    setBtn:SetText("Définir la race")
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
