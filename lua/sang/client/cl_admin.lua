--[[-------------------------------------------------------------------------
    Sang et Nuit — Menu admin "!origines" (UI Derma, style commun BLOOD.UI)

    Page d'accueil à boutons : « Gestion Joueurs » / « Gestion Serveur ».
    D'autres addons peuvent injecter des sections via :
        BLOOD.Origines.AddPlayerSection(function(parent, ctx) ... end)
        BLOOD.Origines.AddServerSection(function(parent) ... end)
    ctx.GetSid() renvoie le SteamID cible saisi dans la page Gestion Joueurs.

    RAPPEL : la vraie barrière de sécurité est SERVEUR-SIDE.
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}
local UI = BLOOD.UI
local C = UI.Col
local S = UI.Scale

-- Registre d'extensions (ordre-indépendant entre addons)
BLOOD.Origines = BLOOD.Origines or { playerSections = {}, serverSections = {} }
function BLOOD.Origines.AddPlayerSection(fn) table.insert(BLOOD.Origines.playerSections, fn) end
function BLOOD.Origines.AddServerSection(fn) table.insert(BLOOD.Origines.serverSections, fn) end

----------------------------------------------------------------------
-- Helpers UI (réutilisables par les extensions)
----------------------------------------------------------------------
function BLOOD.Origines.SectionLabel(parent, text)
    local l = vgui.Create("DPanel", parent)
    l:Dock(TOP) l:DockMargin(0, S(8), S(6), S(4)) l:SetTall(S(24))
    l.Paint = function(_, w, h)
        draw.SimpleText(text, "SangUI_Body", 0, h / 2, C.goldLt, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(C.goldDk); surface.DrawRect(0, h - 1, w, 1)
    end
    return l
end
function BLOOD.Origines.FieldLabel(parent, text)
    local l = vgui.Create("DLabel", parent)
    l:Dock(TOP) l:DockMargin(0, S(4), 0, S(2))
    l:SetFont("SangUI_Small") l:SetTextColor(C.txtDim) l:SetText(text)
    return l
end
local sectionLabel = BLOOD.Origines.SectionLabel
local fieldLabel   = BLOOD.Origines.FieldLabel

local function raceName(id)
    local r = BLOOD.Races and BLOOD.Races[id]
    return r and (r.name or id) or id
end

local function makeScroll(parent)
    local scroll = vgui.Create("DScrollPanel", parent)
    scroll:Dock(FILL)
    local sbar = scroll:GetVBar()
    sbar:SetWide(S(8))
    sbar.Paint = function() end
    sbar.btnUp.Paint = function() end
    sbar.btnDown.Paint = function() end
    sbar.btnGrip.Paint = function(_, w, h) surface.SetDrawColor(C.goldDk); surface.DrawRect(0, 0, w, h) end
    return scroll
end

-- Info live d'un slot (nom / race / covan) — section « Définir une race »
net.Receive("origines_slot_info", function()
    local sid    = net.ReadString()
    local slot   = net.ReadUInt(8)
    local exists = net.ReadBool()
    local name   = net.ReadString()
    local race   = net.ReadString()
    local covan  = net.ReadUInt(32)
    if not IsValid(BLOOD._origInfoLabel) then return end
    local cur = (BLOOD.Config and BLOOD.Config.Currency) or "Covan"
    if exists then
        BLOOD._origInfoLabel:SetText("Actuel — Slot " .. slot .. " : « " .. name .. " »   |   "
            .. raceName(race) .. "   |   " .. string.Comma(covan) .. " " .. cur)
    else
        BLOOD._origInfoLabel:SetText("Actuel — Slot " .. slot .. " : (vide)")
    end
end)

----------------------------------------------------------------------
-- Contrôles "Gestion Joueurs" (sections intégrées) -> renvoie ctx
----------------------------------------------------------------------
local function buildPlayerControls(body, races)
    -- Cible SteamID (commune)
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

    -- 1) Crédits
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

    -- 2) Définir une race (+ info live)
    sectionLabel(body, "2)  Définir une race sur un slot  (contourne tirage + paiement)")
    local rowRace = vgui.Create("DPanel", body)
    rowRace:Dock(TOP) rowRace:DockMargin(0, S(2), S(6), S(4)) rowRace:SetTall(S(26))
    rowRace.Paint = function() end
    local slotCombo = vgui.Create("DComboBox", rowRace)
    slotCombo:Dock(LEFT) slotCombo:SetWide(S(150))
    UI.SkinCombo(slotCombo)
    for i = 1, BLOOD.Config.MaxSlots do slotCombo:AddChoice("Slot " .. i, i) end
    slotCombo:ChooseOptionID(1)

    local function queryInfo()
        local sid = string.Trim(sidEntry:GetValue() or "")
        if sid == "" then return end
        local _, slot = slotCombo:GetSelected()
        net.Start("origines_query_slot")
        net.WriteString(sid)
        net.WriteUInt(tonumber(slot) or 1, 8)
        net.SendToServer()
    end
    slotCombo.OnSelect = function() queryInfo() end
    sidEntry.OnValueChange = function() queryInfo() end
    combo.OnSelect = function(_, _, _, data)
        sidEntry:SetText(data or "")
        queryInfo()
    end

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
        timer.Simple(0.15, queryInfo)
    end

    local infoLbl = vgui.Create("DLabel", body)
    infoLbl:Dock(TOP) infoLbl:DockMargin(0, S(2), S(6), S(4)) infoLbl:SetTall(S(22))
    infoLbl:SetFont("SangUI_Small") infoLbl:SetTextColor(C.goldLt)
    infoLbl:SetText("Actuel — sélectionne un SteamID et un slot")
    BLOOD._origInfoLabel = infoLbl

    -- 3) Renommer un slot
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

    -- 4) Slot payant
    sectionLabel(body, "4)  Slot payant (slot " .. BLOOD.Config.MaxSlots .. ")")
    local rowPaid = vgui.Create("DPanel", body)
    rowPaid:Dock(TOP) rowPaid:DockMargin(0, S(2), S(6), S(6)) rowPaid:SetTall(S(30))
    rowPaid.Paint = function() end
    local unlockBtn = vgui.Create("DButton", rowPaid)
    unlockBtn:Dock(LEFT) unlockBtn:SetWide(S(240))
    unlockBtn:SetText("Débloquer le slot payant")
    UI.SkinButton(unlockBtn, "gold")
    unlockBtn.DoClick = function()
        net.Start("origines_set_paid") net.WriteString(sidEntry:GetValue() or "") net.WriteBool(true) net.SendToServer()
    end
    local lockBtn = vgui.Create("DButton", rowPaid)
    lockBtn:Dock(FILL) lockBtn:DockMargin(S(8), 0, 0, 0)
    lockBtn:SetText("Verrouiller le slot payant")
    UI.SkinButton(lockBtn, "default")
    lockBtn.DoClick = function()
        net.Start("origines_set_paid") net.WriteString(sidEntry:GetValue() or "") net.WriteBool(false) net.SendToServer()
    end

    -- 5) Argent (Covan)
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

    return { GetSid = function() return string.Trim(sidEntry:GetValue() or "") end, sidEntry = sidEntry }
end

----------------------------------------------------------------------
-- Barre supérieure d'une sous-page (retour + titre)
----------------------------------------------------------------------
local function pageHeader(body, title, onBack)
    local bar = vgui.Create("DPanel", body)
    bar:Dock(TOP) bar:DockMargin(0, 0, 0, S(8)) bar:SetTall(S(32))
    bar.Paint = function(_, w, h)
        draw.SimpleText(title, "SangUI_Title", w / 2, h / 2, C.goldLt, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(C.goldDk); surface.DrawRect(0, h - 1, w, 1)
    end
    local back = vgui.Create("DButton", bar)
    back:Dock(LEFT) back:SetWide(S(120)) back:SetText("← Retour")
    UI.SkinButton(back, "default")
    back.DoClick = onBack
end

----------------------------------------------------------------------
-- Pages
----------------------------------------------------------------------
local buildLanding

local function buildPlayerPage(f, races)
    f.Body:Clear()
    pageHeader(f.Body, "Gestion Joueurs", function() buildLanding(f, races) end)
    local scroll = makeScroll(f.Body)
    local ctx = buildPlayerControls(scroll, races)
    for _, fn in ipairs(BLOOD.Origines.playerSections) do
        local ok, err = pcall(fn, scroll, ctx)
        if not ok then MsgN("[Sang et Nuit] Origines player-section error: " .. tostring(err)) end
    end
end

local function buildServerPage(f, races)
    f.Body:Clear()
    pageHeader(f.Body, "Gestion Serveur", function() buildLanding(f, races) end)
    local scroll = makeScroll(f.Body)
    if #BLOOD.Origines.serverSections == 0 then
        local l = vgui.Create("DLabel", scroll)
        l:Dock(TOP) l:DockMargin(0, S(8), 0, 0) l:SetFont("SangUI_Body") l:SetTextColor(C.txtDim)
        l:SetText("Aucun réglage serveur disponible.")
    end
    for _, fn in ipairs(BLOOD.Origines.serverSections) do
        local ok, err = pcall(fn, scroll)
        if not ok then MsgN("[Sang et Nuit] Origines server-section error: " .. tostring(err)) end
    end
end

buildLanding = function(f, races)
    f.Body:Clear()
    local wrap = vgui.Create("DPanel", f.Body)
    wrap:Dock(FILL)
    wrap.Paint = function() end

    local function bigButton(x, label, kind, onClick)
        local b = vgui.Create("DButton", wrap)
        b:SetText(label)
        UI.SkinButton(b, kind)
        b:SetFont("SangUI_Title")
        b.DoClick = onClick
        b.Recompute = function()
            local w, h = wrap:GetWide(), wrap:GetTall()
            local bw, bh = S(260), S(150)
            b:SetSize(bw, bh)
            b:SetPos(w / 2 + x - bw / 2, h / 2 - bh / 2)
        end
        return b
    end

    local b1 = bigButton(-S(150), "Gestion Joueurs", "gold", function() buildPlayerPage(f, races) end)
    local b2 = bigButton(S(150), "Gestion Serveur", "blood", function() buildServerPage(f, races) end)
    wrap.PerformLayout = function()
        b1.Recompute() b2.Recompute()
    end
end

function BLOOD.OpenAdminMenu(races)
    if IsValid(BLOOD.AdminFrame) then BLOOD.AdminFrame:Remove() end
    local f = UI.MakeFrame(S(760), S(720), "Sang et Nuit — Origines (Admin)")
    BLOOD.AdminFrame = f
    buildLanding(f, races)
end
