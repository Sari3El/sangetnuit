--[[-------------------------------------------------------------------------
    Sang et Nuit — Armurerie : menu joueur (client)
      Coffre d'armes par personnage (ranger/récupérer). Indice [E] quand on
      vise une armurerie. Style commun BLOOD.UI (addon principal requis).
---------------------------------------------------------------------------]]

SARM = SARM or {}
SARM.Data = SARM.Data or { slot = 1, items = {} }

surface.CreateFont("SangArm_Hint", { font = "Georgia", size = 20, weight = 700, antialias = true, extended = true })

local function uiReady() return BLOOD and BLOOD.UI end

----------------------------------------------------------------------
-- Réception des données
----------------------------------------------------------------------
net.Receive("sang_armory_open", function()
    local d = { items = {} }
    d.slot = net.ReadUInt(8)
    local n = net.ReadUInt(16)
    for i = 1, n do
        d.items[#d.items + 1] = {
            id    = net.ReadUInt(32),
            class = net.ReadString(),
            clip1 = net.ReadInt(32),
            clip2 = net.ReadInt(32),
        }
    end
    SARM.Data = d

    if IsValid(SARM.Frame) then
        SARM.Refresh()
    else
        SARM.Open()
    end
end)

----------------------------------------------------------------------
-- Utilitaires
----------------------------------------------------------------------
local function wepName(class)
    local t = weapons.GetStored(class)
    local name = (t and t.PrintName) or class
    if not name or name == "" then name = class end
    if string.sub(name, 1, 1) == "#" then name = language.GetPhrase(string.sub(name, 2)) end
    return name
end

local function ammoText(it)
    local parts = {}
    if it.clip1 and it.clip1 >= 0 then parts[#parts + 1] = tostring(it.clip1) end
    if it.clip2 and it.clip2 >= 0 then parts[#parts + 1] = tostring(it.clip2) end
    if #parts == 0 then return "Pas de munitions en chargeur" end
    return "Chargeur : " .. table.concat(parts, " / ")
end

-- Ligne générique (nom + sous-texte + bouton d'action)
local function row(parent, UI, C, S, title, sub, btnTxt, btnKind, onClick)
    local r = vgui.Create("DPanel", parent)
    r:Dock(TOP) r:DockMargin(0, 0, S(4), S(6)) r:SetTall(S(38))
    r.Paint = function(_, w, h)
        UI.VGradient(0, 0, w, h, C.bg2, C.bg0)
        surface.SetDrawColor(C.goldDk)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText(title, "SangUI_Body", S(10), h / 2 - S(8), C.txt, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(sub or "", "SangUI_Small", S(10), h / 2 + S(9), C.txtDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local btn = vgui.Create("DButton", r)
    btn:Dock(RIGHT) btn:DockMargin(0, S(4), S(6), S(4)) btn:SetWide(S(110))
    btn:SetText(btnTxt)
    UI.SkinButton(btn, btnKind)
    btn.DoClick = onClick
    return r
end

----------------------------------------------------------------------
-- Rafraîchit le contenu de la fenêtre
----------------------------------------------------------------------
function SARM.Refresh()
    local f = SARM.Frame
    if not IsValid(f) or not IsValid(f.Body) then return end
    local UI, C = BLOOD.UI, BLOOD.UI.Col
    local S = UI.Scale
    local d = SARM.Data
    local body = f.Body
    body:Clear()

    -- Bandeau
    local head = vgui.Create("DPanel", body)
    head:Dock(TOP) head:DockMargin(0, 0, 0, S(8)) head:SetTall(S(40))
    head.Paint = function(_, w, h)
        UI.VGradient(0, 0, w, h, UI.Shade(C.bg2, 6), C.bg1)
        surface.SetDrawColor(C.goldDk); surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("Coffre — Personnage " .. (d.slot or 1), "SangUI_Body", S(12), h / 2, C.txt, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(#d.items .. " / " .. (SARM.Config and SARM.Config.MaxItems or "?"), "SangUI_Body", w - S(12), h / 2, C.goldLt, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    local cols = vgui.Create("DPanel", body)
    cols:Dock(FILL) cols.Paint = function() end
    local colW = math.floor((body:GetWide() - S(12)) / 2)

    ------------------------------------------------------------------
    -- Colonne gauche : équipement porté
    ------------------------------------------------------------------
    local leftWrap = vgui.Create("DPanel", cols)
    leftWrap:Dock(LEFT) leftWrap:SetWide(colW) leftWrap.Paint = function() end

    local leftLbl = vgui.Create("DLabel", leftWrap)
    leftLbl:Dock(TOP) leftLbl:DockMargin(0, 0, 0, S(6)) leftLbl:SetTall(S(18))
    leftLbl:SetFont("SangUI_Small") leftLbl:SetTextColor(C.txtDim)
    leftLbl:SetText("Sur toi")

    local storeAllBtn = vgui.Create("DButton", leftWrap)
    storeAllBtn:Dock(BOTTOM) storeAllBtn:DockMargin(0, S(6), S(4), 0) storeAllBtn:SetTall(S(28))
    storeAllBtn:SetText("Tout ranger")
    UI.SkinButton(storeAllBtn, "gold")
    storeAllBtn.DoClick = function() net.Start("sang_armory_store_all") net.SendToServer() end

    local leftScroll = vgui.Create("DScrollPanel", leftWrap)
    leftScroll:Dock(FILL)
    UI.SkinScroll(leftScroll)

    local ply = LocalPlayer()
    local carried = 0
    if IsValid(ply) then
        for _, wep in ipairs(ply:GetWeapons()) do
            if IsValid(wep) and SARM.CanStore(wep:GetClass()) then
                carried = carried + 1
                local class = wep:GetClass()
                row(leftScroll, UI, C, S, wepName(class), class, "Ranger", "gold", function()
                    net.Start("sang_armory_store") net.WriteString(class) net.SendToServer()
                end)
            end
        end
    end
    if carried == 0 then
        local e = vgui.Create("DLabel", leftScroll)
        e:Dock(TOP) e:SetTall(S(24)) e:SetFont("SangUI_Small") e:SetTextColor(C.txtDim)
        e:SetText("Rien à ranger.")
    end

    ------------------------------------------------------------------
    -- Colonne droite : contenu du coffre
    ------------------------------------------------------------------
    local rightWrap = vgui.Create("DPanel", cols)
    rightWrap:Dock(FILL) rightWrap.Paint = function() end
    rightWrap:DockMargin(S(12), 0, 0, 0)

    local rightLbl = vgui.Create("DLabel", rightWrap)
    rightLbl:Dock(TOP) rightLbl:DockMargin(0, 0, 0, S(6)) rightLbl:SetTall(S(18))
    rightLbl:SetFont("SangUI_Small") rightLbl:SetTextColor(C.txtDim)
    rightLbl:SetText("Dans le coffre")

    local retrieveAllBtn = vgui.Create("DButton", rightWrap)
    retrieveAllBtn:Dock(BOTTOM) retrieveAllBtn:DockMargin(0, S(6), 0, 0) retrieveAllBtn:SetTall(S(28))
    retrieveAllBtn:SetText("Tout récupérer")
    UI.SkinButton(retrieveAllBtn, "blood")
    retrieveAllBtn.DoClick = function() net.Start("sang_armory_retrieve_all") net.SendToServer() end

    local rightScroll = vgui.Create("DScrollPanel", rightWrap)
    rightScroll:Dock(FILL)
    UI.SkinScroll(rightScroll)

    for _, it in ipairs(d.items) do
        row(rightScroll, UI, C, S, wepName(it.class), ammoText(it), "Récupérer", "blood", function()
            net.Start("sang_armory_retrieve") net.WriteUInt(it.id, 32) net.SendToServer()
        end)
    end
    if #d.items == 0 then
        local e = vgui.Create("DLabel", rightScroll)
        e:Dock(TOP) e:SetTall(S(24)) e:SetFont("SangUI_Small") e:SetTextColor(C.txtDim)
        e:SetText("Le coffre est vide.")
    end
end

function SARM.Open()
    if not uiReady() then
        chat.AddText(Color(255, 80, 80), "[Armurerie] L'addon principal 'sang_et_nuit' est requis.")
        return
    end
    local UI = BLOOD.UI
    local S = UI.Scale
    if IsValid(SARM.Frame) then SARM.Frame:Remove() end

    local f = UI.MakeFrame(S(760), S(520), "Armurerie")
    SARM.Frame = f
    SARM.Refresh()
end

----------------------------------------------------------------------
-- Indice [E] (armurerie visée)
----------------------------------------------------------------------
hook.Add("HUDPaint", "SANGARMORY_Hints", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local tr = ply:GetEyeTrace()
    local e = tr.Entity
    if not IsValid(e) or e:GetClass() ~= "sang_armory" then return end
    if ply:GetPos():Distance(e:GetPos()) > ((SARM.Config and SARM.Config.OpenDist) or 140) then return end

    local cx, cy = ScrW() / 2, ScrH() / 2
    local gold = Color(176, 141, 74)
    local sh = Color(0, 0, 0, 200)
    local txt = "[E] Ouvrir l'armurerie"
    draw.SimpleText(txt, "SangArm_Hint", cx + 1, cy + 41, sh, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(txt, "SangArm_Hint", cx, cy + 40, gold, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)
