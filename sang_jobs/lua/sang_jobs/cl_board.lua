--[[-------------------------------------------------------------------------
    Sang et Nuit — Scoreboard (TAB) style DarkRP, refait à zéro
      Gauche : liste des joueurs groupés par faction (cliquables).
      Droite : fiche détaillée du joueur sélectionné (infos + barres) et, pour
      le staff (BLOOD.IsAdmin), une grille d'actions (noclip, set PV, kick...).
      Curseur débloqué tant que TAB est maintenu.
---------------------------------------------------------------------------]]

SJOB = SJOB or {}
local board

local function jobOf(pl)
    return SJOB.JobsById[pl:GetNWString("sang_job", SJOB.Config.DefaultJob)] or SJOB.GetJob(SJOB.Config.DefaultJob)
end

----------------------------------------------------------------------
-- Actions STAFF (envoyées au serveur, validées côté serveur)
----------------------------------------------------------------------
local STAFF = {
    { l = "Noclip",          a = "noclip" },
    { l = "Mode Dieu",       a = "god" },
    { l = "Geler / Dégeler", a = "freeze" },
    { l = "Enflammer",       a = "ignite" },
    { l = "Éteindre",        a = "extinguish" },
    { l = "Désarmer",        a = "strip" },
    { l = "Réanimer",        a = "respawn" },
    { l = "Amener à moi",    a = "bring" },
    { l = "Me téléporter",   a = "goto" },
    { l = "Définir PV",      a = "sethp",    num = true, t = "Nouveaux PV :" },
    { l = "Définir Armure",  a = "setarmor", num = true, t = "Nouvelle armure :" },
    { l = "Définir Covan",   a = "setcovan", num = true, t = "Nouveau montant de Covan :" },
    { l = "Tuer",            a = "slay",  k = "blood" },
    { l = "Kick",            a = "kick",  k = "blood", str = true, t = "Raison du kick :" },
    { l = "Ban (minutes)",   a = "ban",   k = "blood", num = true, t = "Durée en minutes (0 = permanent) :" },
}

local function sendStaff(pl, a, num, text)
    if not IsValid(pl) then return end
    net.Start("sang_staff")
        net.WriteString(a)
        net.WriteString(pl:SteamID64())
        net.WriteInt(math.floor(num or 0), 32)
        net.WriteString(text or "")
    net.SendToServer()
end

local function doStaff(pl, act)
    if act.num then
        Derma_StringRequest("Staff — " .. act.l, act.t or "Valeur :", "", function(txt)
            sendStaff(pl, act.a, tonumber(txt) or 0, "")
        end)
    elseif act.str then
        Derma_StringRequest("Staff — " .. act.l, act.t or "Texte :", "", function(txt)
            sendStaff(pl, act.a, 0, txt or "")
        end)
    else
        sendStaff(pl, act.a, 0, "")
    end
end

----------------------------------------------------------------------
-- Fiche détaillée (colonne de droite)
----------------------------------------------------------------------
local function fillDetail(d, pl)
    local UI, C, S = BLOOD.UI, BLOOD.UI.Col, BLOOD.UI.Scale
    d.Ply = IsValid(pl) and pl or nil
    d:Clear()
    if not IsValid(pl) then return end
    local DW = d:GetWide()

    -- Avatar
    local av = vgui.Create("AvatarImage", d)
    av:SetSize(S(72), S(72))
    av:SetPos(S(16), S(16))
    av:SetPlayer(pl, 64)
    av:SetMouseInputEnabled(false)

    -- Boutons rapides (profil / copies / voix)
    local bx = S(16)
    local function quick(txt, w, fn, kind)
        local b = vgui.Create("DButton", d)
        b:SetText(txt) b:SetFont("SangUI_Small")
        b:SetPos(bx, S(98)) b:SetSize(w, S(26))
        UI.SkinButton(b, kind or "default")
        b.DoClick = fn
        bx = bx + w + S(6)
    end
    quick("Profil Steam", S(120), function() pl:ShowProfile() end)
    quick("SteamID", S(96), function() SetClipboardText(pl:SteamID()) end)
    quick("ID64", S(80), function() SetClipboardText(pl:SteamID64()) end)
    if pl ~= LocalPlayer() then
        quick(pl:IsMuted() and "Réactiver voix" or "Rendre muet", S(130),
            function() pl:SetMuted(not pl:IsMuted()) fillDetail(d, pl) end, "gold")
    end

    -- Grille d'actions STAFF (admins uniquement)
    if BLOOD.IsAdmin and BLOOD.IsAdmin(LocalPlayer()) then
        local staffY, cols = S(330), 2
        local bw = (DW - S(16) * 2 - S(6) * (cols - 1)) / cols
        for i, act in ipairs(STAFF) do
            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)
            local b = vgui.Create("DButton", d)
            b:SetText(act.l) b:SetFont("SangUI_Small")
            b:SetPos(S(16) + col * (bw + S(6)), staffY + row * S(31))
            b:SetSize(bw, S(27))
            UI.SkinButton(b, act.k or "default")
            b.DoClick = function() if IsValid(d.Ply) then doStaff(d.Ply, act) end end
        end
    end
end

local function paintDetail(d, w, h)
    local UI, C, S = BLOOD.UI, BLOOD.UI.Col, BLOOD.UI.Scale
    UI.Panel(0, 0, w, h)
    local pl = d.Ply
    if not IsValid(pl) then
        draw.SimpleText("Sélectionne un joueur à gauche", "SangUI_Body", w / 2, h / 2, C.txtDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return
    end

    local job = jobOf(pl)
    -- En-tête (nom + ids)
    draw.SimpleText(pl:Nick(), "SangUI_H1", S(100), S(18), C.goldLt, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(pl:SteamID() .. "   •   " .. pl:SteamID64(), "SangUI_Tiny", S(100), S(58), C.txtDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    if pl:IsMuted() then
        draw.SimpleText("VOIX COUPÉE", "SangUI_Tiny", w - S(16), S(20), C.bloodLt, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    end

    -- Bloc d'infos (2 colonnes)
    local race = BLOOD.GetRace and BLOOD.GetRace(pl:GetNWString("blood_race", "human")) or nil
    local fac  = SJOB.Config.FactionNames[job.faction] or job.faction
    local info = {
        { "Job",     job.name,                             job.color or C.txt },
        { "Faction", fac,                                  C.txt },
        { "Race",    race and race.name or "?",            C.txt },
        { "Niveau",  tostring(pl:GetNWInt("slvl_level", 1)), C.goldLt },
        { "Ping",    pl:Ping() .. " ms",                   C.txtDim },
        { "Covan",   tostring(pl:GetNWInt("blood_covan", 0)) .. " or", C.goldLt },
    }
    local iy, colw = S(140), (w - S(32)) / 2
    for i, e in ipairs(info) do
        local cx = S(16) + ((i - 1) % 2) * colw
        local cy = iy + math.floor((i - 1) / 2) * S(26)
        draw.SimpleText(e[1], "SangUI_Small", cx, cy, C.txtDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(e[2], "SangUI_Body",  cx + S(80), cy - S(2), e[3], TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    -- Barres (PV / armure / mana)
    local by, bw = S(228), w - S(32)
    local hp, maxhp = pl:Health(), math.max(1, pl:GetMaxHealth())
    UI.Bar(S(16), by, bw, S(22), hp / maxhp, C.blood, C.bloodLt, "PV", hp .. " / " .. maxhp)
    local ar = pl:Armor()
    UI.Bar(S(16), by + S(28), bw, S(22), math.Clamp(ar / 100, 0, 1), C.steel, C.steelLt, "Armure", tostring(ar))
    local mm = pl:GetNWInt("blood_mana_max", 0)
    if mm > 0 then
        local mn = pl:GetNWInt("blood_mana", 0)
        UI.Bar(S(16), by + S(56), bw, S(22), mn / mm, C.mana, C.manaLt, "Mana", mn .. " / " .. mm)
    end

    -- Séparateur avant la zone staff
    if BLOOD.IsAdmin and BLOOD.IsAdmin(LocalPlayer()) then
        surface.SetDrawColor(C.goldDk) surface.DrawRect(S(16), S(316), w - S(32), 1)
        draw.SimpleText("ACTIONS STAFF", "SangUI_Small", S(16), S(316) - S(2), C.gold, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
    end
end

----------------------------------------------------------------------
-- Construction du scoreboard
----------------------------------------------------------------------
local function buildBoard()
    local UI, C, S = BLOOD.UI, BLOOD.UI.Col, BLOOD.UI.Scale

    local w = math.min(ScrW() - S(100), S(1160))
    local h = math.min(ScrH() - S(110), S(820))
    local p = vgui.Create("DPanel")
    p:SetSize(w, h) p:Center()
    p:SetMouseInputEnabled(true)
    p.Paint = function(_, pw, ph)
        UI.Panel(0, 0, pw, ph)
        UI.VGradient(S(3), S(3), pw - S(6), S(52), UI.Shade(C.bg3, 8), C.bg1)
        draw.SimpleText(GetHostName() or "Serveur", "SangUI_H1", S(16), S(14), C.goldLt, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(#player.GetAll() .. " / " .. game.MaxPlayers() .. " joueurs   —   clique un joueur",
            "SangUI_Small", pw - S(16), S(26), C.txtDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    local bodyY = S(62)
    local listW = math.floor(w * 0.40)

    -- Colonne gauche : liste
    local scroll = vgui.Create("DScrollPanel", p)
    scroll:SetPos(S(10), bodyY)
    scroll:SetSize(listW - S(14), h - bodyY - S(10))
    local sbar = scroll:GetVBar()
    sbar:SetWide(S(8)) sbar.Paint = function() end
    sbar.btnUp.Paint = function() end sbar.btnDown.Paint = function() end
    sbar.btnGrip.Paint = function(_, gw, gh) surface.SetDrawColor(C.goldDk) surface.DrawRect(0, 0, gw, gh) end

    -- Colonne droite : fiche
    local detail = vgui.Create("DPanel", p)
    detail:SetPos(listW + S(6), bodyY)
    detail:SetSize(w - listW - S(16), h - bodyY - S(10))
    detail.Ply = nil
    detail.Paint = paintDetail

    p.Detail = detail

    local function select(pl)
        p.Selected = pl
        fillDetail(detail, pl)
    end

    for _, fac in ipairs(SJOB.Config.FactionOrder) do
        local members = {}
        for _, pl in ipairs(player.GetAll()) do
            if jobOf(pl).faction == fac then members[#members + 1] = pl end
        end
        if #members > 0 then
            local head = vgui.Create("DPanel", scroll)
            head:Dock(TOP) head:DockMargin(0, S(8), S(6), S(4)) head:SetTall(S(24))
            head.Paint = function(_, hw, hh)
                draw.SimpleText((SJOB.Config.FactionNames[fac] or fac) .. "  (" .. #members .. ")",
                    "SangUI_Body", 0, hh / 2, C.goldLt, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                surface.SetDrawColor(C.goldDk) surface.DrawRect(0, hh - 1, hw, 1)
            end

            for _, pl in ipairs(members) do
                local row = vgui.Create("DButton", scroll)
                row:Dock(TOP) row:DockMargin(0, 0, S(6), S(4)) row:SetTall(S(38))
                row:SetText("")
                row.Paint = function(self, rw, rh)
                    local sel = (p.Selected == pl)
                    local hov = self:IsHovered()
                    UI.VGradient(0, 0, rw, rh, (sel or hov) and UI.Shade(C.bg3, sel and 12 or 4) or C.bg2, C.bg0)
                    surface.SetDrawColor((sel or hov) and C.gold or C.goldDk) surface.DrawOutlinedRect(0, 0, rw, rh, sel and 2 or 1)
                    if not IsValid(pl) then return end
                    local job = jobOf(pl)
                    draw.SimpleText(pl:Nick(), "SangUI_Body", S(46), rh / 2 - S(7), pl == LocalPlayer() and C.goldLt or C.txt, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(job.name, "SangUI_Tiny", S(46), rh / 2 + S(9), job.color or C.txtDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(pl:Ping() .. " ms", "SangUI_Tiny", rw - S(10), rh / 2, C.txtDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end
                row.DoClick = function() if IsValid(pl) then select(pl) end end

                local av = vgui.Create("AvatarImage", row)
                av:SetSize(S(28), S(28)) av:SetPos(S(7), S(5)) av:SetPlayer(pl, 32)
                av:SetMouseInputEnabled(false)
            end
        end
    end

    select(LocalPlayer()) -- sélection par défaut
    return p
end

hook.Add("ScoreboardShow", "SJOB_Board", function()
    if not (BLOOD and BLOOD.UI) then return end
    if IsValid(board) then board:Remove() end
    board = buildBoard()
    gui.EnableScreenClicker(true)
    return true
end)

hook.Add("ScoreboardHide", "SJOB_Board", function()
    gui.EnableScreenClicker(false)
    if IsValid(board) then board:Remove() board = nil end
    return true
end)
