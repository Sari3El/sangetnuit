--[[-------------------------------------------------------------------------
    Sang et Nuit — Jobs : menu F4 (client)
      Ouvre avec la touche F4 (ou console sang_f4). Style commun BLOOD.UI.
---------------------------------------------------------------------------]]

SJOB = SJOB or {}

local function curJob() return LocalPlayer():GetNWString("sang_job", SJOB.Config.DefaultJob) end

function SJOB.OpenF4()
    if not (BLOOD and BLOOD.UI) then
        chat.AddText(Color(255, 80, 80), "[Jobs] L'addon principal est requis.")
        return
    end
    local UI, C, S = BLOOD.UI, BLOOD.UI.Col, BLOOD.UI.Scale
    if IsValid(SJOB.F4Frame) then SJOB.F4Frame:Remove() end

    local f = UI.MakeFrame(S(760), S(560), "Choix du Job")
    SJOB.F4Frame = f

    local scroll = vgui.Create("DScrollPanel", f.Body)
    scroll:Dock(FILL)
    local sbar = scroll:GetVBar()
    sbar:SetWide(S(8)) sbar.Paint = function() end
    sbar.btnUp.Paint = function() end sbar.btnDown.Paint = function() end
    sbar.btnGrip.Paint = function(_, w, h) surface.SetDrawColor(C.goldDk); surface.DrawRect(0, 0, w, h) end

    local now = curJob()
    for _, job in ipairs(SJOB.Config.Jobs) do
        local isCur = (job.id == now)
        local row = vgui.Create("DPanel", scroll)
        row:Dock(TOP) row:DockMargin(0, 0, S(6), S(8)) row:SetTall(S(84))
        row.Paint = function(_, w, h)
            UI.VGradient(0, 0, w, h, isCur and UI.Shade(C.bg3, 6) or C.bg2, C.bg0)
            surface.SetDrawColor(job.color); surface.DrawRect(0, 0, S(5), h)
            surface.SetDrawColor(isCur and C.gold or C.goldDk); surface.DrawOutlinedRect(0, 0, w, h, isCur and 2 or 1)
            draw.SimpleText(job.name, "SangUI_Title", S(16), S(10), job.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(job.desc or "", "SangUI_Small", S(16), S(40), C.txtDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            local fac = SJOB.Config.FactionNames[job.faction] or job.faction
            draw.SimpleText("Faction : " .. fac, "SangUI_Small", S(16), S(60), C.txt, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        local btn = vgui.Create("DButton", row)
        btn:Dock(RIGHT) btn:DockMargin(S(8), S(24), S(14), S(24)) btn:SetWide(S(120))
        btn:SetText(isCur and "Actuel" or "Choisir")
        UI.SkinButton(btn, isCur and "default" or "gold")
        btn:SetEnabled(not isCur)
        btn.DoClick = function()
            net.Start("sjob_set") net.WriteString(job.id) net.SendToServer()
            timer.Simple(0.2, function() if IsValid(f) then f:Remove() end end)
        end
    end
end

function SJOB.ToggleF4()
    if IsValid(SJOB.F4Frame) then SJOB.F4Frame:Remove() return end
    SJOB.OpenF4()
end

-- Ouverture par la touche F4
local f4Down = false
hook.Add("Think", "SJOB_F4Key", function()
    local down = input.IsKeyDown(KEY_F4)
    if down and not f4Down then
        f4Down = true
        if IsValid(SJOB.F4Frame) then
            SJOB.F4Frame:Remove()
        elseif not vgui.CursorVisible() and not gui.IsGameUIVisible() then
            SJOB.OpenF4()
        end
    elseif not down then
        f4Down = false
    end
end)

concommand.Add("sang_f4", function() SJOB.ToggleF4() end)
