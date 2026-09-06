--[[-------------------------------------------------------------------------
    Sang et Nuit — Jobs : page « Config Perso » dans Origines
      - Forcer le job d'un slot d'un joueur.
      - Override PV / Armure / Vitesse d'un joueur sur un job (remplace la base
        du job pour LUI). Champ vide = valeur par défaut du job.
---------------------------------------------------------------------------]]

SJOB = SJOB or {}
BLOOD = BLOOD or {}
BLOOD.Origines = BLOOD.Origines or {}
BLOOD.Origines.pages = BLOOD.Origines.pages or {}
BLOOD.Origines.playerSections = BLOOD.Origines.playerSections or {}
BLOOD.Origines.serverSections = BLOOD.Origines.serverSections or {}

local cfg = { infoLbl = nil, hp = nil, armor = nil, speed = nil }

local function fmtVal(v) return (v and v >= 0) and tostring(v) or "" end

net.Receive("sjob_query_result", function()
    local sid   = net.ReadString()
    local jobId = net.ReadString()
    local dHp, dArmor, dSpeed = net.ReadInt(32), net.ReadInt(32), net.ReadFloat()
    local oHp, oArmor, oSpeed = net.ReadInt(32), net.ReadInt(32), net.ReadFloat()

    if IsValid(cfg.infoLbl) then
        cfg.infoLbl:SetText(("Défaut job : PV %d · Armure %d · Vitesse ×%.2f"):format(dHp, dArmor, dSpeed))
    end
    if IsValid(cfg.hp) then cfg.hp:SetText(fmtVal(oHp)) end
    if IsValid(cfg.armor) then cfg.armor:SetText(fmtVal(oArmor)) end
    if IsValid(cfg.speed) then cfg.speed:SetText(oSpeed >= 0 and ("%.2f"):format(oSpeed) or "") end
end)

local function buildConfigPerso(f)
    local UI, C, S = BLOOD.UI, BLOOD.UI.Col, BLOOD.UI.Scale
    local sectionLabel = BLOOD.Origines.SectionLabel
    local fieldLabel = BLOOD.Origines.FieldLabel
    local body = BLOOD.Origines.MakePage(f, "Config Perso")

    -- Cible
    fieldLabel(body, "SteamID cible (STEAM_0:... ou 7656...) :")
    local sidEntry = vgui.Create("DTextEntry", body)
    sidEntry:Dock(TOP) sidEntry:DockMargin(0, 0, S(6), S(4)) sidEntry:SetTall(S(26))
    UI.SkinEntry(sidEntry)
    local combo = vgui.Create("DComboBox", body)
    combo:Dock(TOP) combo:DockMargin(0, 0, S(6), S(6)) combo:SetTall(S(26))
    combo:SetValue("— Choisir un joueur connecté —")
    UI.SkinCombo(combo)
    for _, pl in ipairs(player.GetAll()) do
        combo:AddChoice(pl:Nick() .. "  (" .. pl:SteamID() .. ")", pl:SteamID64())
    end

    local function jobCombo(parent)
        local cb = vgui.Create("DComboBox", parent)
        UI.SkinCombo(cb)
        for _, j in ipairs(SJOB.Config.Jobs) do cb:AddChoice(j.name, j.id) end
        cb:ChooseOptionID(1)
        return cb
    end

    -- 1) Forcer le job d'un slot
    sectionLabel(body, "1)  Forcer le job d'un slot")
    local row1 = vgui.Create("DPanel", body)
    row1:Dock(TOP) row1:DockMargin(0, S(2), S(6), S(4)) row1:SetTall(S(28)) row1.Paint = function() end
    local slotCombo = vgui.Create("DComboBox", row1)
    slotCombo:Dock(LEFT) slotCombo:SetWide(S(130)) UI.SkinCombo(slotCombo)
    for i = 1, (BLOOD.Config and BLOOD.Config.MaxSlots or 4) do slotCombo:AddChoice("Slot " .. i, i) end
    slotCombo:ChooseOptionID(1)
    local jobCombo1 = jobCombo(row1)
    jobCombo1:Dock(FILL) jobCombo1:DockMargin(S(8), 0, 0, 0)
    local setJobBtn = vgui.Create("DButton", body)
    setJobBtn:Dock(TOP) setJobBtn:DockMargin(0, 0, S(6), S(6)) setJobBtn:SetTall(S(30))
    setJobBtn:SetText("Définir le job") UI.SkinButton(setJobBtn, "gold")
    setJobBtn.DoClick = function()
        local _, slot = slotCombo:GetSelected()
        local _, jobId = jobCombo1:GetSelected()
        net.Start("sjob_admin_setjob")
        net.WriteString(sidEntry:GetValue() or "")
        net.WriteUInt(tonumber(slot) or 1, 8)
        net.WriteString(jobId or "sansfaction")
        net.SendToServer()
    end

    -- 2) Stats forcées du perso (par slot) — remplacent job / race / niveau,
    --    QUEL QUE SOIT le job (override direct côté cœur, appliqué au-dessus
    --    de tout dans BLOOD.ApplyComputedStats).
    sectionLabel(body, "2)  Stats forcées du perso (par slot)  — remplacent job / race / niveau")
    fieldLabel(body, "Vide = automatique.  PV / Armure = valeurs exactes ;  Vitesse = multiplicateur (ex. 1.3).")
    local rowSO = vgui.Create("DPanel", body)
    rowSO:Dock(TOP) rowSO:DockMargin(0, S(2), S(6), S(4)) rowSO:SetTall(S(26)) rowSO.Paint = function() end
    local soSlot = vgui.Create("DComboBox", rowSO)
    soSlot:Dock(LEFT) soSlot:SetWide(S(150)) UI.SkinCombo(soSlot)
    for i = 1, (BLOOD.Config and BLOOD.Config.MaxSlots or 4) do soSlot:AddChoice("Slot " .. i, i) end
    soSlot:ChooseOptionID(1)
    local soLoad = vgui.Create("DButton", rowSO)
    soLoad:Dock(FILL) soLoad:DockMargin(S(8), 0, 0, 0) soLoad:SetText("Charger les valeurs actuelles")
    UI.SkinButton(soLoad, "default")

    local function soField(label)
        local r = vgui.Create("DPanel", body)
        r:Dock(TOP) r:DockMargin(0, 0, S(6), S(4)) r:SetTall(S(26)) r.Paint = function() end
        local l = vgui.Create("DLabel", r)
        l:Dock(LEFT) l:SetWide(S(220)) l:SetFont("SangUI_Small") l:SetTextColor(C.txt) l:SetText(label)
        local e = vgui.Create("DTextEntry", r)
        e:Dock(FILL) UI.SkinEntry(e) e:SetPlaceholderText("(vide = auto)")
        return e
    end
    local soHp    = soField("PV forcés :")
    local soArmor = soField("Armure forcée :")
    local soSpeed = soField("Vitesse forcée (×, ex. 1.3) :")

    local soInfo = vgui.Create("DLabel", body)
    soInfo:Dock(TOP) soInfo:DockMargin(0, S(2), S(6), S(4)) soInfo:SetTall(S(20))
    soInfo:SetFont("SangUI_Small") soInfo:SetTextColor(C.goldLt) soInfo:SetText("Actuel — sélectionne un joueur et un slot")
    BLOOD._soFields = { hp = soHp, armor = soArmor, speed = soSpeed, info = soInfo }

    local function soQuery()
        local sid = string.Trim(sidEntry:GetValue() or "")
        if sid == "" then return end
        local _, slot = soSlot:GetSelected()
        net.Start("origines_query_statoverride")
        net.WriteString(sid)
        net.WriteUInt(tonumber(slot) or 1, 8)
        net.SendToServer()
    end
    soSlot.OnSelect = function() soQuery() end
    soLoad.DoClick = function() soQuery() end
    -- Le menu déroulant des joueurs connectés remplit le SteamID + recharge.
    combo.OnSelect = function(_, _, _, data) sidEntry:SetText(data or "") soQuery() end
    sidEntry.OnValueChange = function() soQuery() end

    local rowSOBtns = vgui.Create("DPanel", body)
    rowSOBtns:Dock(TOP) rowSOBtns:DockMargin(0, S(2), S(6), S(8)) rowSOBtns:SetTall(S(30)) rowSOBtns.Paint = function() end
    local soSave = vgui.Create("DButton", rowSOBtns)
    soSave:Dock(LEFT) soSave:SetWide(S(240)) soSave:SetText("Enregistrer les stats forcées")
    UI.SkinButton(soSave, "gold")
    soSave.DoClick = function()
        local _, slot = soSlot:GetSelected()
        local function pi(e) local v = string.Trim(e:GetValue() or "") if v == "" then return -1 end return math.floor(tonumber(v) or -1) end
        local function pf(e) local v = string.Trim(e:GetValue() or "") if v == "" then return -1 end return tonumber(v) or -1 end
        net.Start("origines_set_statoverride")
        net.WriteString(sidEntry:GetValue() or "")
        net.WriteUInt(tonumber(slot) or 1, 8)
        net.WriteInt(pi(soHp), 32)
        net.WriteInt(pi(soArmor), 32)
        net.WriteFloat(pf(soSpeed))
        net.SendToServer()
        timer.Simple(0.15, soQuery)
    end
    local soClear = vgui.Create("DButton", rowSOBtns)
    soClear:Dock(FILL) soClear:DockMargin(S(8), 0, 0, 0) soClear:SetText("Effacer (auto)")
    UI.SkinButton(soClear, "blood")
    soClear.DoClick = function()
        local _, slot = soSlot:GetSelected()
        net.Start("origines_clear_statoverride")
        net.WriteString(sidEntry:GetValue() or "")
        net.WriteUInt(tonumber(slot) or 1, 8)
        net.SendToServer()
        soHp:SetText("") soArmor:SetText("") soSpeed:SetText("")
        timer.Simple(0.15, soQuery)
    end
end

-- Enregistrement idempotent (évite un doublon au rechargement du fichier).
local addPage = BLOOD.Origines.AddPage or function(t) table.insert(BLOOD.Origines.pages, t) end
addPage({ id = "configperso", label = "Config Perso", order = 3, kind = "gold", build = buildConfigPerso })
