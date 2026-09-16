--[[-------------------------------------------------------------------------
    Sang et Nuit — Armoire à PM (playermodel) : menu joueur (client)
      Colonne gauche  : skin + bodygroups du playermodel actuel — générique,
                        lus directement sur le modèle du joueur.
      Colonne droite  : playermodels disponibles pour le job (ou la faction)
                        du joueur, avec bouton "Équiper".
      Style commun BLOOD.UI (addon principal requis).
---------------------------------------------------------------------------]]

SARM = SARM or {}

surface.CreateFont("SangArmoire_Hint", { font = "Georgia", size = 20, weight = 700, antialias = true, extended = true })

local function uiReady() return BLOOD and BLOOD.UI end

----------------------------------------------------------------------
-- Colonne gauche : skin + bodygroups du playermodel porté
----------------------------------------------------------------------
local function buildLeft(panel, UI, C)
    local S = UI.Scale

    local function rebuild()
        panel:Clear()

        local title = vgui.Create("DLabel", panel)
        title:Dock(TOP) title:DockMargin(0, 0, 0, S(8)) title:SetTall(S(22))
        title:SetFont("SangUI_Body") title:SetTextColor(C.txt)
        title:SetText("Apparence de ton personnage")

        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local any = false

        -- Skin (variante de texture globale, très courant sur les playermodels)
        if ply:SkinCount() > 1 then
            any = true
            local count = ply:SkinCount()
            local row = vgui.Create("DPanel", panel)
            row:Dock(TOP) row:DockMargin(0, 0, 0, S(6)) row:SetTall(S(34))
            row.Paint = function(_, w, h)
                UI.VGradient(0, 0, w, h, UI.Shade(C.bg2, 4), C.bg1)
                surface.SetDrawColor(C.goldDk)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end

            local lbl = vgui.Create("DLabel", row)
            lbl:SetPos(S(10), 0) lbl:SetSize(S(128), S(34))
            lbl:SetFont("SangUI_Small") lbl:SetTextColor(C.txt)
            lbl:SetText("Teinte")

            local prev = vgui.Create("DButton", row)
            prev:SetSize(S(26), S(24)) prev:SetPos(S(146), S(5))
            prev:SetText("<")
            UI.SkinButton(prev, "default")

            local valLbl = vgui.Create("DLabel", row)
            valLbl:SetPos(S(178), 0) valLbl:SetSize(S(56), S(34))
            valLbl:SetFont("SangUI_Small") valLbl:SetTextColor(C.goldLt)
            valLbl:SetContentAlignment(5)

            local nxt = vgui.Create("DButton", row)
            nxt:SetSize(S(26), S(24)) nxt:SetPos(S(238), S(5))
            nxt:SetText(">")
            UI.SkinButton(nxt, "default")

            local function send(v)
                net.Start("sang_armoire_skin")
                    net.WriteUInt(v, 8)
                net.SendToServer()
                surface.PlaySound("ui/buttonclick.wav")
            end

            prev.DoClick = function()
                local p2 = LocalPlayer()
                send((p2:GetSkin() - 1 + count) % count)
            end
            nxt.DoClick = function()
                local p2 = LocalPlayer()
                send((p2:GetSkin() + 1) % count)
            end
            row.Think = function()
                valLbl:SetText((LocalPlayer():GetSkin() + 1) .. " / " .. count)
            end
        end

        -- Bodygroups
        for id = 0, ply:GetNumBodyGroups() - 1 do
            local count = ply:GetBodygroupCount(id)
            if count > 1 then
                any = true

                local name = ply:GetBodygroupName(id)
                if not name or name == "" then name = "Groupe " .. id end

                local row = vgui.Create("DPanel", panel)
                row:Dock(TOP) row:DockMargin(0, 0, 0, S(6)) row:SetTall(S(34))
                row.Paint = function(_, w, h)
                    UI.VGradient(0, 0, w, h, UI.Shade(C.bg2, 4), C.bg1)
                    surface.SetDrawColor(C.goldDk)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                end

                local lbl = vgui.Create("DLabel", row)
                lbl:SetPos(S(10), 0) lbl:SetSize(S(128), S(34))
                lbl:SetFont("SangUI_Small") lbl:SetTextColor(C.txt)
                lbl:SetText(name)

                local prev = vgui.Create("DButton", row)
                prev:SetSize(S(26), S(24)) prev:SetPos(S(146), S(5))
                prev:SetText("<")
                UI.SkinButton(prev, "default")

                local valLbl = vgui.Create("DLabel", row)
                valLbl:SetPos(S(178), 0) valLbl:SetSize(S(56), S(34))
                valLbl:SetFont("SangUI_Small") valLbl:SetTextColor(C.goldLt)
                valLbl:SetContentAlignment(5)

                local nxt = vgui.Create("DButton", row)
                nxt:SetSize(S(26), S(24)) nxt:SetPos(S(238), S(5))
                nxt:SetText(">")
                UI.SkinButton(nxt, "default")

                local function send(v)
                    net.Start("sang_armoire_bodygroup")
                        net.WriteUInt(id, 8)
                        net.WriteUInt(v, 8)
                    net.SendToServer()
                    surface.PlaySound("ui/buttonclick.wav")
                end

                prev.DoClick = function()
                    local p2 = LocalPlayer()
                    local cnt = p2:GetBodygroupCount(id)
                    send((p2:GetBodygroup(id) - 1 + cnt) % cnt)
                end
                nxt.DoClick = function()
                    local p2 = LocalPlayer()
                    local cnt = p2:GetBodygroupCount(id)
                    send((p2:GetBodygroup(id) + 1) % cnt)
                end
                row.Think = function()
                    valLbl:SetText((LocalPlayer():GetBodygroup(id) + 1) .. " / " .. count)
                end
            end
        end

        if not any then
            local lbl = vgui.Create("DLabel", panel)
            lbl:Dock(TOP) lbl:SetTall(S(40))
            lbl:SetFont("SangUI_Small") lbl:SetTextColor(C.txtDim)
            lbl:SetWrap(true)
            lbl:SetText("Ce playermodel n'a pas d'apparence personnalisable.")
        end
    end

    rebuild()

    local ply = LocalPlayer()
    panel.LastModel = IsValid(ply) and ply:GetModel() or nil
    panel.Think = function()
        local p = LocalPlayer()
        local model = IsValid(p) and p:GetModel() or nil
        if model ~= panel.LastModel then
            panel.LastModel = model
            rebuild()
        end
    end
end

----------------------------------------------------------------------
-- Colonne droite : playermodels disponibles pour le job / faction
----------------------------------------------------------------------
local function buildRight(panel, UI, C)
    local S = UI.Scale
    panel:Clear()

    local ply = LocalPlayer()
    local facName = SARM.Config.FactionNames[ply:GetNWString("sang_faction", "none")] or "Sans Faction"

    local title = vgui.Create("DLabel", panel)
    title:Dock(TOP) title:DockMargin(0, 0, 0, S(8)) title:SetTall(S(22))
    title:SetFont("SangUI_Body") title:SetTextColor(C.txt)
    title:SetText("Apparences disponibles — " .. facName)

    local list = SARM.GetAvailableModels(ply)

    if #list == 0 then
        local lbl = vgui.Create("DLabel", panel)
        lbl:Dock(TOP) lbl:SetTall(S(40))
        lbl:SetFont("SangUI_Small") lbl:SetTextColor(C.txtDim)
        lbl:SetWrap(true)
        lbl:SetText("Aucune apparence n'est configurée pour ton job actuellement.")
        return
    end

    for _, m in ipairs(list) do
        local model = m.model

        local row = vgui.Create("DPanel", panel)
        row:Dock(TOP) row:DockMargin(0, 0, 0, S(8)) row:SetTall(S(44))
        row.Paint = function(_, rw, rh)
            UI.VGradient(0, 0, rw, rh, UI.Shade(C.bg2, 4), C.bg1)
            surface.SetDrawColor(C.goldDk)
            surface.DrawOutlinedRect(0, 0, rw, rh, 1)
        end

        local lbl = vgui.Create("DLabel", row)
        lbl:SetPos(S(10), 0) lbl:SetSize(S(200), S(44))
        lbl:SetFont("SangUI_Body") lbl:SetTextColor(C.txt)
        lbl:SetContentAlignment(4)
        lbl:SetText(m.name or model)

        local btn = vgui.Create("DButton", row)
        btn:SetSize(S(110), S(30))
        UI.SkinButton(btn, "gold")
        local skinThink = btn.Think -- SkinButton pose déjà un Think (couleur du texte) : on le chaîne
        btn.Think = function(self)
            self:SetPos(row:GetWide() - S(120), S(7))
            local p2 = LocalPlayer()
            local equipped = IsValid(p2) and p2:GetModel() == model
            self:SetText(equipped and "Équipé" or "Équiper")
            self:SetEnabled(not equipped)
            if skinThink then skinThink(self) end
        end
        btn.DoClick = function()
            net.Start("sang_armoire_setmodel")
                net.WriteString(model)
            net.SendToServer()
            surface.PlaySound("ui/buttonclick.wav")
        end
    end
end

----------------------------------------------------------------------
-- Fenêtre
----------------------------------------------------------------------
function SARM.OpenMenu()
    if not uiReady() then
        chat.AddText(Color(255, 80, 80), "[Armoire] L'addon principal 'sang_et_nuit' est requis.")
        return
    end
    local UI, C = BLOOD.UI, BLOOD.UI.Col
    local S = UI.Scale
    if IsValid(SARM.Frame) then SARM.Frame:Remove() end

    local f = UI.MakeFrame(S(840), S(520), "Armoire")
    SARM.Frame = f

    local bw = f.Body:GetWide()
    local bh = f.Body:GetTall()

    local left = vgui.Create("DScrollPanel", f.Body)
    left:SetPos(0, 0)
    left:SetSize(bw * 0.46, bh)

    local sep = vgui.Create("DPanel", f.Body)
    sep:SetPos(bw * 0.48, 0)
    sep:SetSize(1, bh)
    sep.Paint = function(_, w, h) surface.SetDrawColor(C.goldDk) surface.DrawRect(0, 0, w, h) end

    local right = vgui.Create("DScrollPanel", f.Body)
    right:SetPos(bw * 0.5, 0)
    right:SetSize(bw * 0.5, bh)

    buildLeft(left, UI, C)
    buildRight(right, UI, C)
end

net.Receive("sang_armoire_open", function()
    SARM.OpenMenu()
end)

----------------------------------------------------------------------
-- Indice [E] quand on vise une armoire
----------------------------------------------------------------------
hook.Add("HUDPaint", "SARM_Hints", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local tr = ply:GetEyeTrace()
    local e = tr.Entity
    if not IsValid(e) or e:GetClass() ~= "sang_armoire" then return end
    if ply:GetPos():Distance(e:GetPos()) > (SARM.Config.OpenDist or 140) then return end

    local cx, cy = ScrW() / 2, ScrH() / 2
    local gold = Color(176, 141, 74)
    local sh = Color(0, 0, 0, 200)
    local txt = "[E] Ouvrir l'armoire"
    draw.SimpleText(txt, "SangArmoire_Hint", cx + 1, cy + 41, sh, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(txt, "SangArmoire_Hint", cx, cy + 40, gold, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)
