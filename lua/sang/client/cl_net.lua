--[[-------------------------------------------------------------------------
    Sang et Nuit — Réception réseau côté client + notifications
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}

-- État local du joueur (rempli par blood_sync)
BLOOD.MyData = BLOOD.MyData or {
    mustCreate = false,
    credits = 0,
    activeSlot = 1,
    paidUnlocked = false,
    slots = {},
}

----------------------------------------------------------------------
-- Synchro d'état
----------------------------------------------------------------------
net.Receive("blood_sync", function()
    local d = { slots = {} }
    d.mustCreate   = net.ReadBool()
    d.credits      = net.ReadUInt(32)
    d.activeSlot   = net.ReadUInt(8)
    d.paidUnlocked = net.ReadBool()

    local maxSlots = net.ReadUInt(8)
    for i = 1, maxSlots do
        if net.ReadBool() then
            local name = net.ReadString()
            local race = net.ReadString()
            d.slots[i] = { name = name, race = race }
        end
    end

    -- Slot EVENT (spécial)
    d.eventUnlocked = net.ReadBool()
    d.eventExists   = net.ReadBool()
    d.eventName     = d.eventExists and net.ReadString() or nil

    BLOOD.MyData = d
    if IsValid(BLOOD.MenuFrame) and BLOOD.RefreshMenu then
        BLOOD.RefreshMenu()
    end
end)

----------------------------------------------------------------------
-- Notifications : HUD à l'écran (PLUS dans le tchat) — file d'attente
----------------------------------------------------------------------
surface.CreateFont("SangToast", { font = "Georgia", size = 19, weight = 700, antialias = true, extended = true })

local toasts = {}
local TOAST_LIFE = 4.5

local function toastColor(kind)
    if kind == "error"  then return Color(214, 74, 74)   end
    if kind == "reroll" then return Color(110, 170, 255)  end
    return Color(210, 176, 108) -- info / défaut : or
end

net.Receive("blood_notify", function()
    local msg  = net.ReadString()
    local kind = net.ReadString()
    toasts[#toasts + 1] = { text = msg, col = toastColor(kind), born = CurTime() }
    while #toasts > 6 do table.remove(toasts, 1) end
    surface.PlaySound("buttons/button15.wav")
end)

hook.Add("HUDPaint", "BLOOD_Toasts", function()
    local n = #toasts
    if n == 0 then return end
    local now = CurTime()
    for i = n, 1, -1 do
        if now - toasts[i].born > TOAST_LIFE then table.remove(toasts, i) end
    end

    local S = (BLOOD.UI and BLOOD.UI.Scale) or function(v) return math.floor(v * (ScrH() / 1080) + 0.5) end
    surface.SetFont("SangToast")
    local y = S(96)
    for _, t in ipairs(toasts) do
        local age = now - t.born
        local a = 255
        if age < 0.15 then a = 255 * (age / 0.15)
        elseif age > TOAST_LIFE - 0.6 then a = 255 * math.max(0, (TOAST_LIFE - age) / 0.6) end

        local tw, th = surface.GetTextSize(t.text)
        local pad = S(14)
        local w, h = tw + pad * 2, th + S(10)
        local x = (ScrW() - w) / 2

        surface.SetDrawColor(10, 8, 6, a * 0.86) surface.DrawRect(x, y, w, h)
        surface.SetDrawColor(t.col.r, t.col.g, t.col.b, a) surface.DrawOutlinedRect(x, y, w, h, 1)
        surface.SetTextColor(0, 0, 0, a * 0.7) surface.SetTextPos(x + pad + 1, y + S(5) + 1) surface.DrawText(t.text)
        surface.SetTextColor(t.col.r, t.col.g, t.col.b, a) surface.SetTextPos(x + pad, y + S(5)) surface.DrawText(t.text)
        y = y + h + S(6)
    end
end)

----------------------------------------------------------------------
-- Canal STAFF : messages tchat visibles UNIQUEMENT par les super admins
-- (le serveur n'envoie ce net qu'aux SA — un simple admin ne le reçoit pas).
----------------------------------------------------------------------
net.Receive("blood_staff_msg", function()
    local text = net.ReadString()
    chat.AddText(Color(170, 110, 220), "[STAFF] ", Color(220, 206, 174), text)
end)

----------------------------------------------------------------------
-- Ouverture des menus (demandée par le serveur)
----------------------------------------------------------------------
net.Receive("blood_open_menu", function()
    if BLOOD.OpenMenu then BLOOD.OpenMenu() end
end)

net.Receive("blood_open_admin", function()
    local n = net.ReadUInt(8)
    local races = {}
    for _ = 1, n do
        local id   = net.ReadString()
        local name = net.ReadString()
        races[#races + 1] = { id = id, name = name }
    end
    if BLOOD.OpenAdminMenu then BLOOD.OpenAdminMenu(races) end
end)

-- Raccourci console pour ouvrir le menu personnages.
concommand.Add("sang_menu", function()
    if BLOOD.OpenMenu then BLOOD.OpenMenu() end
end)
