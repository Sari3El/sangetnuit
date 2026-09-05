--[[-------------------------------------------------------------------------
    Sang et Nuit — Niveaux : borne de compétences (menu client)
      Ouverte en faisant E sur l'entité sang_stats. Style commun BLOOD.UI.
---------------------------------------------------------------------------]]

SLVL = SLVL or {}

net.Receive("slvl_open_stats", function()
    if SLVL.OpenStatsMenu then SLVL.OpenStatsMenu() end
end)

function SLVL.RefreshStats()
    local f = SLVL.StatsFrame
    if not IsValid(f) or not IsValid(f.Body) then return end
    local UI, C, S = BLOOD.UI, BLOOD.UI.Col, BLOOD.UI.Scale
    local d = SLVL.My
    local body = f.Body
    body:Clear()

    -- En-tête : points disponibles
    local head = vgui.Create("DPanel", body)
    head:Dock(TOP) head:DockMargin(0, 0, 0, S(8)) head:SetTall(S(44))
    head.Paint = function(_, w, h)
        UI.VGradient(0, 0, w, h, UI.Shade(C.bg2, 6), C.bg1)
        surface.SetDrawColor(C.goldDk); surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("Niveau " .. d.level, "SangUI_Body", S(12), h / 2, C.txt, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Points disponibles : " .. d.avail, "SangUI_Title", w - S(14), h / 2, C.goldLt, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    local maxPts = (SLVL.Config and SLVL.Config.MaxPointsPerStat) or 100
    for _, st in ipairs(SLVL.Config.Stats) do
        local pts = d[st.id] or 0
        local pct = SLVL.PointsToPct(pts)

        local row = vgui.Create("DPanel", body)
        row:Dock(TOP) row:DockMargin(0, 0, 0, S(6)) row:SetTall(S(52))
        row.Paint = function(_, w, h)
            UI.VGradient(0, 0, w, h, C.bg2, C.bg0)
            surface.SetDrawColor(C.goldDk); surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText(st.name, "SangUI_Body", S(12), S(8), C.goldLt, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(st.desc, "SangUI_Small", S(12), S(30), C.txtDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            -- points + %
            draw.SimpleText(pts .. " / " .. maxPts, "SangUI_Body", w - S(120), h / 2, C.txt, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            draw.SimpleText("+" .. string.format("%.2f", pct) .. "%", "SangUI_Small", w - S(120), h / 2 + S(14), C.goldLt, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end

        local plus = vgui.Create("DButton", row)
        plus:Dock(RIGHT) plus:DockMargin(S(6), S(10), S(10), S(10)) plus:SetWide(S(90))
        plus:SetText("+ 1 point")
        UI.SkinButton(plus, "gold")
        plus:SetEnabled(d.avail > 0 and pts < maxPts)
        plus.DoClick = function()
            net.Start("slvl_spend") net.WriteString(st.id) net.SendToServer()
        end
    end

    -- Réinitialisation (points de reset)
    local bottom = vgui.Create("DPanel", body)
    bottom:Dock(BOTTOM) bottom:DockMargin(0, S(8), 0, 0) bottom:SetTall(S(56))
    bottom.Paint = function(_, w, h)
        surface.SetDrawColor(C.goldDk); surface.DrawRect(0, 0, w, 1)
        draw.SimpleText("Points de reset : " .. d.reset, "SangUI_Body", 0, S(8), C.txtDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    local respec = vgui.Create("DButton", bottom)
    respec:Dock(BOTTOM) respec:DockMargin(0, S(4), 0, 0) respec:SetTall(S(32))
    respec:SetText("Réinitialiser mes points  (consomme 1 point de reset)")
    UI.SkinButton(respec, "blood")
    respec:SetEnabled(d.reset > 0)
    respec.DoClick = function()
        Derma_Query("Réinitialiser tous tes points de compétence ?\n(1 point de reset sera consommé)",
            "Sang et Nuit",
            "Oui", function() net.Start("slvl_respec") net.SendToServer() end,
            "Non", function() end)
    end
end

function SLVL.OpenStatsMenu()
    if not (BLOOD and BLOOD.UI) then
        chat.AddText(Color(255, 80, 80), "[Compétences] L'addon principal est requis.")
        return
    end
    local S = BLOOD.UI.Scale
    if IsValid(SLVL.StatsFrame) then SLVL.StatsFrame:Remove() end
    SLVL.StatsFrame = BLOOD.UI.MakeFrame(S(560), S(560), "Compétences")
    SLVL.RefreshStats()
end
