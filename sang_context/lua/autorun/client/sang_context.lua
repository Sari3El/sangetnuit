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
-- Vue 1ère / 3ème personne (simple, côté client)
----------------------------------------------------------------------
local thirdPerson = false

local function toggleThirdPerson()
    thirdPerson = not thirdPerson
end

hook.Add("CalcView", "SangCtx_ThirdPerson", function(ply, pos, ang, fov)
    if not thirdPerson then return end
    if not (IsValid(ply) and ply:Alive()) or ply:InVehicle() then return end

    local desired = pos - ang:Forward() * 110 + ang:Right() * 20 + ang:Up() * 4
    local tr = util.TraceHull({
        start  = pos,
        endpos = desired,
        filter = ply,
        mins   = Vector(-4, -4, -4),
        maxs   = Vector(4, 4, 4),
        mask   = MASK_SOLID,
    })
    return {
        origin     = tr.Hit and (tr.HitPos + tr.HitNormal * 4) or desired,
        angles     = ang,
        fov        = fov,
        drawviewer = true,
    }
end)

hook.Add("ShouldDrawLocalPlayer", "SangCtx_ThirdPerson", function()
    if thirdPerson then return true end
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
    { l = "Faire un ticket",          fn = promptTicket },
    { l = "Règles & aide",            fn = openRules },
}

local rightMenu

local function buildRightMenu(parent)
    local UI, C, S = BLOOD.UI, BLOOD.UI.Col, BLOOD.UI.Scale
    local w, bh, gap, pad, titleH = S(252), S(46), S(10), S(12), S(46)
    local n = #BUTTONS
    local h = titleH + pad + n * bh + (n - 1) * gap + pad

    local pnl = vgui.Create("DPanel", parent)
    pnl.SangMenu = true
    pnl:SetSize(w, h)
    pnl:SetPos(ScrW() - w - S(40), (ScrH() - h) / 2)
    pnl.Paint = function(_, pw, ph)
        UI.Panel(0, 0, pw, ph)
        UI.VGradient(S(3), S(3), pw - S(6), titleH, UI.Shade(C.bg3, 8), C.bg1)
        draw.SimpleText("MENU", "SangUI_Title", pw / 2, titleH / 2, C.goldLt, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(C.goldDk) surface.DrawRect(S(12), titleH, pw - S(24), 1)
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
hook.Add("OnContextMenuOpen", "SangCtx_Menu", function()
    if not (BLOOD and BLOOD.UI) then return end
    local cm = g_ContextMenu
    if not IsValid(cm) then return end

    if not IsValid(rightMenu) then rightMenu = buildRightMenu(cm) end
    rightMenu:SetPos(ScrW() - rightMenu:GetWide() - (BLOOD.UI.Scale(40)), (ScrH() - rightMenu:GetTall()) / 2)
    rightMenu:SetVisible(true)
    rightMenu:MoveToFront()

    -- Icônes de gauche : masquées pour les non-super-admins. On le fait à la
    -- frame suivante (après que les addons aient ajouté leurs boutons).
    if not amISuper() then
        timer.Simple(0, function()
            if not IsValid(cm) then return end
            for _, ch in ipairs(cm:GetChildren()) do
                if ch ~= rightMenu and not ch.SangMenu then ch:SetVisible(false) end
            end
        end)
    end
end)

hook.Add("OnContextMenuClose", "SangCtx_Menu", function()
    if IsValid(rightMenu) then rightMenu:SetVisible(false) end
end)

-- Bind console de secours pour basculer la vue (pratique en test).
concommand.Add("sang_thirdperson", toggleThirdPerson)
