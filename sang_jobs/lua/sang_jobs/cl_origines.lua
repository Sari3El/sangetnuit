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

    -- 2) Override PV / Armure / Vitesse
    sectionLabel(body, "2)  Override PV / Armure / Vitesse  (par joueur + job)")
    local rowJob = vgui.Create("DPanel", body)
    rowJob:Dock(TOP) rowJob:DockMargin(0, S(2), S(6), S(4)) rowJob:SetTall(S(26)) rowJob.Paint = function() end
    fieldLabel(rowJob, "")
    local jobCombo2 = jobCombo(rowJob)
    jobCombo2:Dock(FILL)

    local infoLbl = vgui.Create("DLabel", body)
    infoLbl:Dock(TOP) infoLbl:DockMargin(0, S(2), S(6), S(4)) infoLbl:SetTall(S(20))
    infoLbl:SetFont("SangUI_Small") infoLbl:SetTextColor(C.goldLt)
    infoLbl:SetText("Défaut job : —")
    cfg.infoLbl = infoLbl

    local function field(label)
        local r = vgui.Create("DPanel", body)
        r:Dock(TOP) r:DockMargin(0, 0, S(6), S(4)) r:SetTall(S(26)) r.Paint = function() end
        local l = vgui.Create("DLabel", r)
        l:Dock(LEFT) l:SetWide(S(200)) l:SetFont("SangUI_Small") l:SetTextColor(C.txt) l:SetText(label)
        local e = vgui.Create("DTextEntry", r)
        e:Dock(FILL) UI.SkinEntry(e)
        e:SetPlaceholderText("(vide = défaut du job)")
        return e
    end
    cfg.hp    = field("PV override :")
    cfg.armor = field("Armure override :")
    cfg.speed = field("Vitesse override (ex. 0.95) :")

    local function queryOverride()
        local sid = string.Trim(sidEntry:GetValue() or "")
        if sid == "" then return end
        local _, jobId = jobCombo2:GetSelected()
        net.Start("sjob_query")
        net.WriteString(sid)
        net.WriteString(jobId or "sansfaction")
        net.SendToServer()
    end
    jobCombo2.OnSelect = function() queryOverride() end
    sidEntry.OnValueChange = function() queryOverride() end
    combo.OnSelect = function(_, _, _, data) sidEntry:SetText(data or "") queryOverride() end

    local rowBtns = vgui.Create("DPanel", body)
    rowBtns:Dock(TOP) rowBtns:DockMargin(0, S(2), S(6), S(6)) rowBtns:SetTall(S(30)) rowBtns.Paint = function() end
    local saveBtn = vgui.Create("DButton", rowBtns)
    saveBtn:Dock(LEFT) saveBtn:SetWide(S(240)) saveBtn:SetText("Enregistrer l'override")
    UI.SkinButton(saveBtn, "gold")
    saveBtn.DoClick = function()
        local _, jobId = jobCombo2:GetSelected()
        local function parseInt(e) local v = string.Trim(e:GetValue() or "") if v == "" then return -1 end return math.floor(tonumber(v) or -1) end
        local function parseFloat(e) local v = string.Trim(e:GetValue() or "") if v == "" then return -1 end return tonumber(v) or -1 end
        net.Start("sjob_admin_setoverride")
        net.WriteString(sidEntry:GetValue() or "")
        net.WriteString(jobId or "sansfaction")
        net.WriteInt(parseInt(cfg.hp), 32)
        net.WriteInt(parseInt(cfg.armor), 32)
        net.WriteFloat(parseFloat(cfg.speed))
        net.SendToServer()
        timer.Simple(0.15, queryOverride)
    end
    local clearBtn = vgui.Create("DButton", rowBtns)
    clearBtn:Dock(FILL) clearBtn:DockMargin(S(8), 0, 0, 0) clearBtn:SetText("Effacer l'override")
    UI.SkinButton(clearBtn, "blood")
    clearBtn.DoClick = function()
        local _, jobId = jobCombo2:GetSelected()
        net.Start("sjob_admin_clearoverride")
        net.WriteString(sidEntry:GetValue() or "")
        net.WriteString(jobId or "sansfaction")
        net.SendToServer()
        timer.Simple(0.15, queryOverride)
    end
end

table.insert(BLOOD.Origines.pages, {
    id = "configperso", label = "Config Perso", order = 3, kind = "gold",
    build = buildConfigPerso,
})
