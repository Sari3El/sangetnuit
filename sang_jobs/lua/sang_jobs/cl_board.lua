--[[-------------------------------------------------------------------------
    Sang et Nuit — Scoreboard (TAB) au thème, groupé par faction
      Remplace le scoreboard par défaut (Sandbox / DarkRP).
      Interactif comme le TAB DarkRP : le curseur est débloqué tant que TAB
      est maintenu, et cliquer sur un joueur ouvre un menu (profil Steam,
      copier SteamID, rendre muet…) — le tout dans notre charte graphique.
---------------------------------------------------------------------------]]

SJOB = SJOB or {}
local board

local function jobOf(pl)
    return SJOB.JobsById[pl:GetNWString("sang_job", SJOB.Config.DefaultJob)] or SJOB.GetJob(SJOB.Config.DefaultJob)
end

----------------------------------------------------------------------
-- Menu contextuel d'un joueur (au clic sur sa ligne)
----------------------------------------------------------------------
local function openPlayerMenu(pl)
    if not IsValid(pl) then return end
    if IsValid(SJOB._plyMenu) then SJOB._plyMenu:Remove() end
    local UI, C, S = BLOOD.UI, BLOOD.UI.Col, BLOOD.UI.Scale

    -- Options (fonctionnalités de base du TAB DarkRP).
    local opts = {}
    opts[#opts + 1] = { txt = "Voir le profil Steam", fn = function() pl:ShowProfile() end }
    opts[#opts + 1] = { txt = "Copier le SteamID", fn = function() SetClipboardText(pl:SteamID()) end }
    opts[#opts + 1] = { txt = "Copier le SteamID64", fn = function() SetClipboardText(pl:SteamID64()) end }
    if pl ~= LocalPlayer() then
        local muted = pl:IsMuted()
        opts[#opts + 1] = {
            txt = muted and "Réactiver la voix" or "Rendre muet",
            fn = function() pl:SetMuted(not muted) end,
        }
    end
    if BLOOD and BLOOD.IsAdmin and BLOOD.IsAdmin(LocalPlayer()) then
        opts[#opts + 1] = {
            txt = "Copier pour Origines (admin)",
            fn = function() SetClipboardText(pl:SteamID64()) end, gold = true,
        }
    end

    local itemH = S(30)
    local mw = S(230)
    local mh = #opts * itemH + S(40)

    -- Fond attrape-clic (ferme le menu si on clique ailleurs).
    local back = vgui.Create("DPanel", board)
    back:SetSize(board:GetWide(), board:GetTall())
    back:SetPos(0, 0)
    back.Paint = function() end
    back:SetMouseInputEnabled(true)
    back.OnMousePressed = function() back:Remove() end
    SJOB._plyMenu = back

    -- Position (relative au board) au niveau du curseur, bornée au cadre.
    local bx, by = board:LocalToScreen(0, 0)
    local mx = math.Clamp(gui.MouseX() - bx, S(6), board:GetWide() - mw - S(6))
    local my = math.Clamp(gui.MouseY() - by, S(6), board:GetTall() - mh - S(6))

    local menu = vgui.Create("DPanel", back)
    menu:SetSize(mw, mh)
    menu:SetPos(mx, my)
    menu:SetMouseInputEnabled(true)
    menu.OnMousePressed = function() end -- avale les clics (ne ferme pas)
    menu.Paint = function(_, w, h)
        UI.Panel(0, 0, w, h)
        draw.SimpleText(pl:Nick(), "SangUI_Body", S(12), S(10), C.goldLt, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        surface.SetDrawColor(C.goldDk); surface.DrawRect(S(10), S(32), w - S(20), 1)
    end

    for i, o in ipairs(opts) do
        local b = vgui.Create("DButton", menu)
        b:SetPos(S(8), S(38) + (i - 1) * itemH)
        b:SetSize(mw - S(16), itemH - S(4))
        b:SetText(o.txt)
        UI.SkinButton(b, o.gold and "gold" or "default")
        b.DoClick = function()
            o.fn()
            if IsValid(back) then back:Remove() end
        end
    end
end

----------------------------------------------------------------------
-- Construction du tableau
----------------------------------------------------------------------
local function buildBoard()
    local UI, C, S = BLOOD.UI, BLOOD.UI.Col, BLOOD.UI.Scale

    local w = math.min(ScrW() - S(80), S(900))
    local h = math.min(ScrH() - S(100), S(760))
    local p = vgui.Create("DPanel")
    p:SetSize(w, h)
    p:Center()
    p:SetMouseInputEnabled(true) -- interactif (curseur débloqué par le clicker)
    p.Paint = function(_, pw, ph)
        UI.Panel(0, 0, pw, ph)
        -- en-tête
        UI.VGradient(S(3), S(3), pw - S(6), S(52), UI.Shade(C.bg3, 8), C.bg1)
        draw.SimpleText(GetHostName() or "Serveur", "SangUI_H1", S(16), S(16), C.goldLt, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(#player.GetAll() .. " / " .. game.MaxPlayers() .. " joueurs", "SangUI_Body",
            pw - S(16), S(24), C.txtDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Clique un joueur pour les options", "SangUI_Tiny",
            pw - S(16), S(44), C.txtDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
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
                local row = vgui.Create("DButton", scroll)
                row:Dock(TOP) row:DockMargin(0, 0, S(6), S(4)) row:SetTall(S(40))
                row:SetText("")
                row.Paint = function(self, rw, rh)
                    local me = (pl == LocalPlayer())
                    local hov = self:IsHovered()
                    UI.VGradient(0, 0, rw, rh, (me or hov) and UI.Shade(C.bg3, hov and 10 or 4) or C.bg2, C.bg0)
                    surface.SetDrawColor(hov and C.gold or C.goldDk); surface.DrawOutlinedRect(0, 0, rw, rh, 1)
                    if not IsValid(pl) then return end
                    local job = jobOf(pl)
                    draw.SimpleText(pl:Nick(), "SangUI_Body", S(48), rh / 2, me and C.goldLt or C.txt, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(job.name, "SangUI_Small", rw * 0.5, rh / 2, job.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText("Niv " .. pl:GetNWInt("slvl_level", 1), "SangUI_Small", rw - S(120), rh / 2, C.goldLt, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    if pl:IsMuted() then
                        draw.SimpleText("muet", "SangUI_Tiny", rw - S(150), rh / 2, C.bloodLt, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                    end
                    draw.SimpleText(pl:Ping() .. " ms", "SangUI_Small", rw - S(14), rh / 2, C.txtDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end
                row.DoClick = function() if IsValid(pl) then openPlayerMenu(pl) end end

                local av = vgui.Create("AvatarImage", row)
                av:SetSize(S(30), S(30))
                av:SetPos(S(8), S(5))
                av:SetPlayer(pl, 32)
                av:SetMouseInputEnabled(false) -- laisse le clic passer au bouton
            end
        end
    end

    return p
end

hook.Add("ScoreboardShow", "SJOB_Board", function()
    if not (BLOOD and BLOOD.UI) then return end
    if IsValid(board) then board:Remove() end
    board = buildBoard()
    gui.EnableScreenClicker(true) -- débloque le curseur pour cliquer
    return true
end)

hook.Add("ScoreboardHide", "SJOB_Board", function()
    gui.EnableScreenClicker(false)
    if IsValid(SJOB._plyMenu) then SJOB._plyMenu:Remove() end
    if IsValid(board) then board:Remove() board = nil end
    return true
end)
