--[[-------------------------------------------------------------------------
    Sang et Nuit — Origines : boutons du slot EVENT
      - Gestion Joueurs : « Débloquer EVENT pour ce joueur »
      - Gestion Serveur : « Débloquer EVENT pour tout le monde » + « Forcer
        tous les joueurs sur le slot EVENT »
---------------------------------------------------------------------------]]

if not CLIENT then return end

BLOOD = BLOOD or {}
BLOOD.Origines = BLOOD.Origines or { playerSections = {}, serverSections = {} }

-- Inscription idempotente par id (anti-doublon, quel que soit l'ordre/chargements).
local function addPlayer(fn, id)
    if BLOOD.Origines.AddPlayerSection then return BLOOD.Origines.AddPlayerSection(fn, id) end
    BLOOD.Origines.playerSections = BLOOD.Origines.playerSections or {}
    BLOOD.Origines._playerIds = BLOOD.Origines._playerIds or {}
    local ids = BLOOD.Origines._playerIds
    if id and ids[id] then BLOOD.Origines.playerSections[ids[id]] = fn return end
    table.insert(BLOOD.Origines.playerSections, fn)
    if id then ids[id] = #BLOOD.Origines.playerSections end
end
local function addServer(fn, id)
    if BLOOD.Origines.AddServerSection then return BLOOD.Origines.AddServerSection(fn, id) end
    BLOOD.Origines.serverSections = BLOOD.Origines.serverSections or {}
    BLOOD.Origines._serverIds = BLOOD.Origines._serverIds or {}
    local ids = BLOOD.Origines._serverIds
    if id and ids[id] then BLOOD.Origines.serverSections[ids[id]] = fn return end
    table.insert(BLOOD.Origines.serverSections, fn)
    if id then ids[id] = #BLOOD.Origines.serverSections end
end

----------------------------------------------------------------------
-- Gestion Joueurs : débloquer EVENT pour LE joueur ciblé
----------------------------------------------------------------------
addPlayer(function(p, ctx)
    local UI, S = BLOOD.UI, BLOOD.UI.Scale
    BLOOD.Origines.SectionLabel(p, "Slot EVENT — ce joueur")

    local row = vgui.Create("DPanel", p)
    row:Dock(TOP) row:DockMargin(0, 0, S(6), S(6)) row:SetTall(S(30)) row.Paint = function() end
    local btn = vgui.Create("DButton", row)
    btn:Dock(FILL) btn:SetText("Débloquer EVENT pour ce joueur")
    UI.SkinButton(btn, "gold")
    btn.DoClick = function()
        net.Start("origines_event_unlock")
            net.WriteString("one")
            net.WriteString(ctx.GetSid() or "")
        net.SendToServer()
    end
end, "event_player")

----------------------------------------------------------------------
-- Gestion Serveur : débloquer pour tous + forcer tous sur EVENT
----------------------------------------------------------------------
addServer(function(p)
    local UI, S = BLOOD.UI, BLOOD.UI.Scale
    BLOOD.Origines.SectionLabel(p, "Slot EVENT — serveur")

    local function bigBtn(txt, kind, fn)
        local row = vgui.Create("DPanel", p)
        row:Dock(TOP) row:DockMargin(0, 0, S(6), S(6)) row:SetTall(S(32)) row.Paint = function() end
        local b = vgui.Create("DButton", row)
        b:Dock(FILL) b:SetText(txt)
        UI.SkinButton(b, kind)
        b.DoClick = fn
    end

    bigBtn("Débloquer EVENT pour tout le monde", "gold", function()
        net.Start("origines_event_unlock")
            net.WriteString("all")
            net.WriteString("")
        net.SendToServer()
    end)

    bigBtn("Forcer TOUS les joueurs sur le slot EVENT", "blood", function()
        Derma_Query("Forcer TOUS les joueurs connectés sur leur slot EVENT ?\n(débloque + crée le perso EVENT au besoin)",
            "Slot EVENT",
            "Oui, forcer", function()
                net.Start("origines_event_forceall") net.SendToServer()
            end,
            "Annuler", function() end)
    end)
end, "event_server")
