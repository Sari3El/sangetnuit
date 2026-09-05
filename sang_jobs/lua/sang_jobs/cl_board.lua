--[[-------------------------------------------------------------------------
    Sang et Nuit — Scoreboard (TAB) au thème, groupé par faction
      Remplace le scoreboard par défaut (Sandbox / DarkRP).
---------------------------------------------------------------------------]]

SJOB = SJOB or {}
local board

local function jobOf(pl)
    return SJOB.JobsById[pl:GetNWString("sang_job", SJOB.Config.DefaultJob)] or SJOB.GetJob(SJOB.Config.DefaultJob)
end

local function buildBoard()
    local UI, C, S = BLOOD.UI, BLOOD.UI.Col, BLOOD.UI.Scale

    local w = math.min(ScrW() - S(80), S(900))
    local h = math.min(ScrH() - S(100), S(760))
    local p = vgui.Create("DPanel")
    p:SetSize(w, h)
    p:Center()
    p:SetMouseInputEnabled(false)
    p.Paint = function(_, pw, ph)
        UI.Panel(0, 0, pw, ph)
        -- en-tête
        UI.VGradient(S(3), S(3), pw - S(6), S(52), UI.Shade(C.bg3, 8), C.bg1)
        draw.SimpleText(GetHostName() or "Serveur", "SangUI_H1", S(16), S(16), C.goldLt, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(#player.GetAll() .. " / " .. game.MaxPlayers() .. " joueurs", "SangUI_Body",
            pw - S(16), S(24), C.txtDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    local scroll = vgui.Create("DScrollPanel", p)
    scroll:SetPos(S(10), S(62))
    scroll:SetSize(w - S(20), h - S(72))
    local sbar = scroll:GetVBar()
    sbar:SetWide(S(8)) sbar.Paint = function() end
    sbar.btnUp.Paint = function() end sbar.btnDown.Paint = function() end
    sbar.btnGrip.Paint = function(_, gw, gh) surface.SetDrawColor(C.goldDk); surface.DrawRect(0, 0, gw, gh) end

    for _, fac in ipairs(SJOB.Config.FactionOrder) do
        -- joueurs de cette faction
        local members = {}
        for _, pl in ipairs(player.GetAll()) do
            if jobOf(pl).faction == fac then members[#members + 1] = pl end
        end
        if #members > 0 then
            local head = vgui.Create("DPanel", scroll)
            head:Dock(TOP) head:DockMargin(0, S(8), S(6), S(4)) head:SetTall(S(26))
            head.Paint = function(_, hw, hh)
                draw.SimpleText((SJOB.Config.FactionNames[fac] or fac) .. "  (" .. #members .. ")",
                    "SangUI_Body", 0, hh / 2, C.goldLt, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                surface.SetDrawColor(C.goldDk); surface.DrawRect(0, hh - 1, hw, 1)
            end

            for _, pl in ipairs(members) do
                local row = vgui.Create("DPanel", scroll)
                row:Dock(TOP) row:DockMargin(0, 0, S(6), S(4)) row:SetTall(S(40))
                row.Paint = function(_, rw, rh)
                    local me = (pl == LocalPlayer())
                    UI.VGradient(0, 0, rw, rh, me and UI.Shade(C.bg3, 4) or C.bg2, C.bg0)
                    surface.SetDrawColor(C.goldDk); surface.DrawOutlinedRect(0, 0, rw, rh, 1)
                    if not IsValid(pl) then return end
                    local job = jobOf(pl)
                    draw.SimpleText(pl:Nick(), "SangUI_Body", S(48), rh / 2, me and C.goldLt or C.txt, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(job.name, "SangUI_Small", rw * 0.5, rh / 2, job.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText("Niv " .. pl:GetNWInt("slvl_level", 1), "SangUI_Small", rw - S(120), rh / 2, C.goldLt, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(pl:Ping() .. " ms", "SangUI_Small", rw - S(14), rh / 2, C.txtDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end

                local av = vgui.Create("AvatarImage", row)
                av:SetSize(S(30), S(30))
                av:SetPos(S(8), S(5))
                av:SetPlayer(pl, 32)
            end
        end
    end

    return p
end

hook.Add("ScoreboardShow", "SJOB_Board", function()
    if not (BLOOD and BLOOD.UI) then return end
    if IsValid(board) then board:Remove() end
    board = buildBoard()
    return true
end)

hook.Add("ScoreboardHide", "SJOB_Board", function()
    if IsValid(board) then board:Remove() board = nil end
    return true
end)
