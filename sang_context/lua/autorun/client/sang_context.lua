--[[-------------------------------------------------------------------------
    Sang et Nuit — Menu contextuel (C) : côté client
      - Menu à DROITE avec des boutons joueur (jeter des Covan, vue 1/3e
        personne, faire un ticket, règles & aide).
      - Les icônes d'addons à GAUCHE ne sont visibles QUE par les super admins.
---------------------------------------------------------------------------]]

if not CLIENT then return end

local function amISuper()
    local lp = LocalPlayer()
    return IsValid(lp) and (lp:GetNWBool("sang_is_superadmin", false) or lp:IsSuperAdmin())
end

----------------------------------------------------------------------
-- Vue 1ère / 3ème personne
--   Mode de fonctionnement repris de « Simple ThirdPerson » (FailCake) :
--   lissage de la position (math.Approach + délai lié à la vélocité) et
--   collision caméra (TraceLine, on ressort de 5u sur la normale).
----------------------------------------------------------------------
-- Valeurs par défaut IDENTIQUES à Simple ThirdPerson (caméra pile derrière) :
-- distance 100, right 0, up 0.
local cv_enabled  = CreateClientConVar("sang_tp_enabled",   "0",   true, false) -- persistant
local cv_dist     = CreateClientConVar("sang_tp_distance",  "100", true, false)
local cv_right    = CreateClientConVar("sang_tp_right",     "0",   true, false)
local cv_up       = CreateClientConVar("sang_tp_up",        "0",   true, false)
local cv_smooth   = CreateClientConVar("sang_tp_smooth",    "1",   true, false)
local cv_collide  = CreateClientConVar("sang_tp_collision", "1",   true, false)

-- Remise à zéro UNIQUE des réglages caméra (pour écraser une ancienne valeur
-- déjà sauvegardée, ex. right=20) puis on respecte les réglages du joueur.
local cv_ver = CreateClientConVar("sang_tp_ver", "0", true, false)
if cv_ver:GetInt() < 2 then
    RunConsoleCommand("sang_tp_distance", "100")
    RunConsoleCommand("sang_tp_right", "0")
    RunConsoleCommand("sang_tp_up", "0")
    RunConsoleCommand("sang_tp_ver", "2")
end

local delayPos

local function toggleThirdPerson()
    delayPos = nil -- évite un saut de caméra à l'activation
    RunConsoleCommand("sang_tp_enabled", cv_enabled:GetBool() and "0" or "1")
end

hook.Add("CalcView", "SangCtx_ThirdPerson", function(ply, pos, angles, fov)
    if not cv_enabled:GetBool() then return end
    if not (IsValid(ply) and ply:Alive()) or ply:InVehicle() then return end

    if not delayPos then delayPos = pos end

    local Forward, Right, Up = cv_dist:GetFloat(), cv_right:GetFloat(), cv_up:GetFloat()

    -- lissage
    if cv_smooth:GetBool() then
        delayPos = delayPos + (ply:GetVelocity() * (FrameTime() / 10))
        delayPos.x = math.Approach(delayPos.x, pos.x, math.abs(delayPos.x - pos.x) * 0.3)
        delayPos.y = math.Approach(delayPos.y, pos.y, math.abs(delayPos.y - pos.y) * 0.3)
        delayPos.z = math.Approach(delayPos.z, pos.z, math.abs(delayPos.z - pos.z) * 0.3)
    else
        delayPos = pos
    end

    local view = { angles = angles, fov = fov, drawviewer = true }
    local target = delayPos + angles:Forward() * -Forward + angles:Right() * Right + angles:Up() * Up

    if cv_collide:GetBool() then
        local tr = util.TraceLine({ start = delayPos, endpos = target, filter = ply })
        view.origin = tr.HitPos
        if tr.Fraction < 1.0 then view.origin = view.origin + tr.HitNormal * 5 end
    else
        view.origin = target
    end
    return view
end)

hook.Add("ShouldDrawLocalPlayer", "SangCtx_ThirdPerson", function()
    if cv_enabled:GetBool() then return true end
end)

----------------------------------------------------------------------
-- Boîtes de dialogue / actions
----------------------------------------------------------------------
local function promptDrop()
    Derma_StringRequest("Jeter des Covan", "Montant à jeter :", "", function(txt)
        local n = math.floor(tonumber(txt) or 0)
        if n <= 0 then return end
        net.Start("sang_ctx_drop") net.WriteInt(n, 32) net.SendToServer()
    end)
end

local function promptTicket()
    Derma_StringRequest("Faire un ticket",
        "Décris ton problème (le staff en ligne sera prévenu) :", "", function(txt)
        txt = string.Trim(txt or "")
        if txt == "" then return end
        net.Start("sang_ctx_ticket") net.WriteString(txt) net.SendToServer()
    end)
end

-- Règles : à personnaliser librement.
local RULES = {
    "1.  Respecte tous les joueurs, aucun propos haineux.",
    "2.  Pas de RDM, de powergaming ni de metagaming.",
    "3.  Reste dans ton rôle (RP médiéval) en zone RP.",
    "4.  Le NLR s'applique après ta mort.",
    "5.  Écoute et respecte les décisions du staff.",
    "6.  Un souci ? Ouvre un ticket via le menu (touche C).",
    "7.  Avant tout : amuse-toi et fais vivre le lore.",
}

local function openRules()
    if not (BLOOD and BLOOD.UI and BLOOD.UI.MakeFrame) then return end
    local UI, C, S = BLOOD.UI, BLOOD.UI.Col, BLOOD.UI.Scale
    local f = UI.MakeFrame(S(500), S(400), "Règles & Aide")
    local body = f.Body or f

    local lbl = vgui.Create("DLabel", body)
    lbl:Dock(FILL)
    lbl:DockMargin(S(20), body == f and S(56) or S(6), S(20), S(16))
    lbl:SetFont("SangUI_Body")
    lbl:SetTextColor(C.txt)
    lbl:SetWrap(true)
    lbl:SetContentAlignment(7) -- haut-gauche
    lbl:SetText(table.concat(RULES, "\n\n"))
end

----------------------------------------------------------------------
-- Boutons du menu de droite
----------------------------------------------------------------------
local BUTTONS = {
    { l = "Jeter des Covan",          fn = promptDrop },
    { l = "Vue 1ère / 3ème personne", fn = toggleThirdPerson },
    { l = "Couper les sons",          fn = function() RunConsoleCommand("stopsound") end },
    { l = "Faire un ticket",          fn = promptTicket },
    { l = "Règles & aide",            fn = openRules },
}

local rightMenu

-- Dimensions : bandeau plein-hauteur sur toute la partie droite. Descendu sous
-- la barre du haut du menu C, ne touche pas le bas. Large assez pour recouvrir
-- le panneau d'options du toolgun. Renvoie x, y, w, h.
local function menuGeom()
    local S = BLOOD.UI.Scale
    local w = math.Clamp(math.floor(ScrW() * 0.22), S(320), S(470))
    local topM, botM = S(64), S(14)
    return ScrW() - w - S(12), topM, w, ScrH() - topM - botM
end

local function buildRightMenu(parent)
    local UI, C, S = BLOOD.UI, BLOOD.UI.Col, BLOOD.UI.Scale
    local x, y, w, h = menuGeom()
    local titleH, bh, gap, pad = S(50), S(46), S(12), S(18)

    local pnl = vgui.Create("DPanel", parent)
    pnl.SangMenu = true
    pnl:SetSize(w, h)
    pnl:SetPos(x, y)
    pnl.Paint = function(_, pw, ph)
        -- fond 100 % OPAQUE d'abord (sinon on voit à travers ce qu'il y a dessous)
        surface.SetDrawColor(10, 8, 6, 255) surface.DrawRect(0, 0, pw, ph)
        UI.Panel(0, 0, pw, ph)
        UI.VGradient(S(3), S(3), pw - S(6), titleH, UI.Shade(C.bg3, 8), C.bg1)
        draw.SimpleText("MENU", "SangUI_Title", pw / 2, titleH / 2, C.goldLt, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(C.goldDk) surface.DrawRect(S(14), titleH, pw - S(28), 1)
        draw.SimpleText("Sang et Nuit", "SangUI_Tiny", pw / 2, ph - S(14), C.txtDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local y = titleH + pad
    for _, b in ipairs(BUTTONS) do
        local btn = vgui.Create("DButton", pnl)
        btn:SetText(b.l) btn:SetFont("SangUI_Body")
        btn:SetPos(pad, y) btn:SetSize(w - pad * 2, bh)
        UI.SkinButton(btn, "default")
        btn.DoClick = function() b.fn() end
        y = y + bh + gap
    end
    return pnl
end

----------------------------------------------------------------------
-- Ouverture / fermeture du menu contextuel (C)
----------------------------------------------------------------------
-- Panneau d'options du toolgun (docké à droite dans le menu C) : on le masque
-- tant que C est ouvert, et on le rétablit à la fermeture (pour ne pas casser
-- son affichage dans le menu Q, qui utilise le même panneau).
local function toolPanel()
    return spawnmenu and spawnmenu.ActiveControlPanel and spawnmenu.ActiveControlPanel()
end

hook.Add("OnContextMenuOpen", "SangCtx_Menu", function()
    if not (BLOOD and BLOOD.UI) then return end
    local cm = g_ContextMenu
    if not IsValid(cm) then return end

    if not IsValid(rightMenu) then rightMenu = buildRightMenu(cm) end
    local x, y, w, h = menuGeom()
    rightMenu:SetSize(w, h)
    rightMenu:SetPos(x, y)
    rightMenu:SetVisible(true)
    rightMenu:MoveToFront()

    timer.Simple(0, function()
        if IsValid(rightMenu) then rightMenu:MoveToFront() end
        -- masquer le panneau d'outil pour tout le monde
        local cp = toolPanel()
        if IsValid(cp) then cp:SetVisible(false) end
        -- masquer les icônes de gauche pour les non-super-admins
        if not amISuper() and IsValid(cm) then
            for _, ch in ipairs(cm:GetChildren()) do
                if ch ~= rightMenu and not ch.SangMenu then ch:SetVisible(false) end
            end
        end
    end)
end)

hook.Add("OnContextMenuClose", "SangCtx_Menu", function()
    if IsValid(rightMenu) then rightMenu:SetVisible(false) end
    local cp = toolPanel()
    if IsValid(cp) then cp:SetVisible(true) end -- rétabli pour le menu Q
end)

-- Bind console de secours pour basculer la vue (pratique en test).
concommand.Add("sang_thirdperson", toggleThirdPerson)
