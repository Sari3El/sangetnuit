--[[-------------------------------------------------------------------------
    Sang et Nuit — Jobs : page « Config Perso » dans Origines
      Stats forcées PAR (slot + job) : PV / Armure exacts + Vitesse (×mult)
      qui REMPLACENT tout (job/race/niveau). Elles ne s'appliquent QUE si le
      joueur est sur CE slot ET dans CE job (sinon : valeurs normales).
      Le moteur est côté cœur (BLOOD, net origines_*_statoverride) ; ici c'est
      juste l'interface.
---------------------------------------------------------------------------]]

SJOB = SJOB or {}
BLOOD = BLOOD or {}
BLOOD.Origines = BLOOD.Origines or {}
BLOOD.Origines.pages = BLOOD.Origines.pages or {}

local function buildConfigPerso(f)
    local UI, C, S = BLOOD.UI, BLOOD.UI.Col, BLOOD.UI.Scale
    local sectionLabel = BLOOD.Origines.SectionLabel
    local fieldLabel   = BLOOD.Origines.FieldLabel
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

    -- 1) Stats forcées par (slot + job)
    sectionLabel(body, "1)  Stats forcées du perso  (par slot + job)")
    fieldLabel(body, "S'applique quand le joueur est sur CE slot ET dans CE job. "
        .. "Vide = auto.  PV / Armure = valeurs exactes ;  Vitesse = multiplicateur (ex. 1.3).")

    -- Ligne slot + job
    local rowSel = vgui.Create("DPanel", body)
    rowSel:Dock(TOP) rowSel:DockMargin(0, S(2), S(6), S(4)) rowSel:SetTall(S(26)) rowSel.Paint = function() end
    local soSlot = vgui.Create("DComboBox", rowSel)
    soSlot:Dock(LEFT) soSlot:SetWide(S(150)) UI.SkinCombo(soSlot)
    for i = 1, (BLOOD.Config and BLOOD.Config.MaxSlots or 4) do soSlot:AddChoice("Slot " .. i, i) end
    soSlot:ChooseOptionID(1)
    local soJob = vgui.Create("DComboBox", rowSel)
    soJob:Dock(FILL) soJob:DockMargin(S(8), 0, 0, 0) UI.SkinCombo(soJob)
    for _, j in ipairs(SJOB.Config.Jobs) do soJob:AddChoice(j.name, j.id) end
    soJob:ChooseOptionID(1)

    local soLoad = vgui.Create("DButton", body)
    soLoad:Dock(TOP) soLoad:DockMargin(0, 0, S(6), S(6)) soLoad:SetTall(S(26))
    soLoad:SetText("Charger les valeurs actuelles")
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
    soInfo:SetFont("SangUI_Small") soInfo:SetTextColor(C.goldLt)
    soInfo:SetText("Actuel — sélectionne un joueur, un slot et un job")
    BLOOD._soFields = { hp = soHp, armor = soArmor, speed = soSpeed, info = soInfo }

    local function selSlot() local _, s = soSlot:GetSelected() return tonumber(s) or 1 end
    local function selJob()
        local _, j = soJob:GetSelected()
        return j or (SJOB.Config.Jobs[1] and SJOB.Config.Jobs[1].id) or "sansfaction"
    end

    local function soQuery()
        local sid = string.Trim(sidEntry:GetValue() or "")
        if sid == "" then return end
        net.Start("origines_query_statoverride")
        net.WriteString(sid)
        net.WriteUInt(selSlot(), 8)
        net.WriteString(selJob())
        net.SendToServer()
    end
    soSlot.OnSelect = function() soQuery() end
    soJob.OnSelect  = function() soQuery() end
    soLoad.DoClick  = function() soQuery() end
    combo.OnSelect  = function(_, _, _, data) sidEntry:SetText(data or "") soQuery() end
    sidEntry.OnValueChange = function() soQuery() end

    -- Boutons enregistrer / effacer
    local rowBtns = vgui.Create("DPanel", body)
    rowBtns:Dock(TOP) rowBtns:DockMargin(0, S(2), S(6), S(8)) rowBtns:SetTall(S(30)) rowBtns.Paint = function() end
    local soSave = vgui.Create("DButton", rowBtns)
    soSave:Dock(LEFT) soSave:SetWide(S(240)) soSave:SetText("Enregistrer les stats forcées")
    UI.SkinButton(soSave, "gold")
    soSave.DoClick = function()
        local function pi(e) local v = string.Trim(e:GetValue() or "") if v == "" then return -1 end return math.floor(tonumber(v) or -1) end
        local function pf(e) local v = string.Trim(e:GetValue() or "") if v == "" then return -1 end return tonumber(v) or -1 end
        net.Start("origines_set_statoverride")
        net.WriteString(sidEntry:GetValue() or "")
        net.WriteUInt(selSlot(), 8)
        net.WriteString(selJob())
        net.WriteInt(pi(soHp), 32)
        net.WriteInt(pi(soArmor), 32)
        net.WriteFloat(pf(soSpeed))
        net.SendToServer()
        timer.Simple(0.15, soQuery)
    end
    local soClear = vgui.Create("DButton", rowBtns)
    soClear:Dock(FILL) soClear:DockMargin(S(8), 0, 0, 0) soClear:SetText("Effacer (auto)")
    UI.SkinButton(soClear, "blood")
    soClear.DoClick = function()
        net.Start("origines_clear_statoverride")
        net.WriteString(sidEntry:GetValue() or "")
        net.WriteUInt(selSlot(), 8)
        net.WriteString(selJob())
        net.SendToServer()
        soHp:SetText("") soArmor:SetText("") soSpeed:SetText("")
        timer.Simple(0.15, soQuery)
    end
end

-- Enregistrement idempotent (évite un doublon au rechargement du fichier).
local addPage = BLOOD.Origines.AddPage or function(t) table.insert(BLOOD.Origines.pages, t) end
addPage({ id = "configperso", label = "Config Perso", order = 3, kind = "gold", build = buildConfigPerso })
