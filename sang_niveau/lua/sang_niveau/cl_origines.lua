--[[-------------------------------------------------------------------------
    Sang et Nuit — Niveaux : intégration au menu Origines
      Ajoute une section « Niveau & compétences » à Gestion Joueurs et un
      réglage « Multiplicateur d'XP » à Gestion Serveur.
      Enregistrement ordre-indépendant entre addons.
---------------------------------------------------------------------------]]

SLVL = SLVL or {}

BLOOD = BLOOD or {}
BLOOD.Origines = BLOOD.Origines or { playerSections = {}, serverSections = {} }
BLOOD.Origines.playerSections = BLOOD.Origines.playerSections or {}
BLOOD.Origines.serverSections = BLOOD.Origines.serverSections or {}

-- Mise à jour du champ multiplicateur quand le serveur répond
net.Receive("slvl_xpmult", function()
    local v = net.ReadFloat()
    if IsValid(SLVL._xpmultField) then SLVL._xpmultField:SetText(tostring(v)) end
end)

local addPlayer = BLOOD.Origines.AddPlayerSection
    or function(fn) table.insert(BLOOD.Origines.playerSections, fn) end
local addServer = BLOOD.Origines.AddServerSection
    or function(fn) table.insert(BLOOD.Origines.serverSections, fn) end

----------------------------------------------------------------------
-- Gestion Joueurs : Niveau & compétences
----------------------------------------------------------------------
addPlayer(function(p, ctx)
    local UI, C, S = BLOOD.UI, BLOOD.UI.Col, BLOOD.UI.Scale
    BLOOD.Origines.SectionLabel(p, "6)  Niveau & compétences  — par personnage")

    local row = vgui.Create("DPanel", p)
    row:Dock(TOP) row:DockMargin(0, S(2), S(6), S(4)) row:SetTall(S(26))
    row.Paint = function() end
    local slotCombo = vgui.Create("DComboBox", row)
    slotCombo:Dock(LEFT) slotCombo:SetWide(S(150))
    UI.SkinCombo(slotCombo)
    local maxSlots = (BLOOD.Config and BLOOD.Config.MaxSlots) or 4
    for i = 1, maxSlots do slotCombo:AddChoice("Slot " .. i, i) end
    slotCombo:ChooseOptionID(1)

    local function slot() local _, s = slotCombo:GetSelected() return tonumber(s) or 1 end

    -- Ligne d'action générique : champ + bouton
    local function action(label, btnTxt, kind, onClick, default)
        local r = vgui.Create("DPanel", p)
        r:Dock(TOP) r:DockMargin(0, 0, S(6), S(4)) r:SetTall(S(28))
        r.Paint = function() end
        local lbl = vgui.Create("DLabel", r)
        lbl:Dock(LEFT) lbl:SetWide(S(160)) lbl:SetFont("SangUI_Small") lbl:SetTextColor(C.txt) lbl:SetText(label)
        local ent = vgui.Create("DTextEntry", r)
        ent:Dock(FILL) ent:DockMargin(0, S(1), S(8), S(1)) ent:SetNumeric(true) ent:SetText(default or "0")
        UI.SkinEntry(ent)
        local btn = vgui.Create("DButton", r)
        btn:Dock(RIGHT) btn:SetWide(S(150)) btn:SetText(btnTxt)
        UI.SkinButton(btn, kind)
        btn.DoClick = function() onClick(ent, slot()) end
    end

    action("Niveau (1-" .. ((SLVL.Config and SLVL.Config.MaxLevel) or 250) .. ") :", "Régler le niveau", "gold",
        function(ent, s)
            net.Start("slvl_admin_setlevel")
            net.WriteString(ctx.GetSid())
            net.WriteUInt(s, 8)
            net.WriteUInt(math.Clamp(math.floor(tonumber(ent:GetValue()) or 1), 1, (SLVL.Config and SLVL.Config.MaxLevel) or 250), 16)
            net.SendToServer()
        end, "1")

    action("Points bonus :", "Donner des points", "gold",
        function(ent, s)
            net.Start("slvl_admin_givepoints")
            net.WriteString(ctx.GetSid())
            net.WriteUInt(s, 8)
            net.WriteInt(math.floor(tonumber(ent:GetValue()) or 0), 32)
            net.SendToServer()
        end, "1")

    action("Points de reset :", "Donner des reset", "blood",
        function(ent, s)
            net.Start("slvl_admin_givereset")
            net.WriteString(ctx.GetSid())
            net.WriteUInt(s, 8)
            net.WriteInt(math.floor(tonumber(ent:GetValue()) or 0), 32)
            net.SendToServer()
        end, "1")
end, "slvl_levels")

----------------------------------------------------------------------
-- Gestion Serveur : Multiplicateur d'XP
----------------------------------------------------------------------
addServer(function(p)
    local UI, C, S = BLOOD.UI, BLOOD.UI.Col, BLOOD.UI.Scale
    BLOOD.Origines.SectionLabel(p, "Multiplicateur d'XP  (0 = normal ×1 ; décimales OK)")
    BLOOD.Origines.FieldLabel(p, "Valeur (ex. 2 = ×2, 1.5 = ×1.5, 0 = normal) :")

    local row = vgui.Create("DPanel", p)
    row:Dock(TOP) row:DockMargin(0, 0, S(6), S(4)) row:SetTall(S(28))
    row.Paint = function() end
    local ent = vgui.Create("DTextEntry", row)
    ent:Dock(FILL) ent:DockMargin(0, S(1), S(8), S(1)) ent:SetText("0")
    UI.SkinEntry(ent)
    SLVL._xpmultField = ent
    local btn = vgui.Create("DButton", row)
    btn:Dock(RIGHT) btn:SetWide(S(150)) btn:SetText("Régler")
    UI.SkinButton(btn, "gold")
    btn.DoClick = function()
        net.Start("slvl_set_xpmult")
        net.WriteFloat(math.max(0, tonumber(ent:GetValue()) or 0))
        net.SendToServer()
    end

    -- Demander la valeur courante
    net.Start("slvl_req_xpmult") net.SendToServer()
end, "slvl_xpmult")
