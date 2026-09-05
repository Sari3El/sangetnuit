--[[-------------------------------------------------------------------------
    Sang et Nuit — Réception réseau côté client + notifications
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}

-- État local du joueur (rempli par blood_sync)
BLOOD.MyData = BLOOD.MyData or {
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

    BLOOD.MyData = d
    if IsValid(BLOOD.MenuFrame) and BLOOD.RefreshMenu then
        BLOOD.RefreshMenu()
    end
end)

----------------------------------------------------------------------
-- Notifications (chat coloré)
----------------------------------------------------------------------
net.Receive("blood_notify", function()
    local msg  = net.ReadString()
    local kind = net.ReadString()

    local col = color_white
    if kind == "error" then
        col = Color(255, 80, 80)
    elseif kind == "reroll" then
        col = Color(120, 200, 255)
    elseif kind == "info" then
        col = Color(120, 255, 120)
    end

    chat.AddText(Color(200, 60, 60), "[Sang et Nuit] ", col, msg)
    surface.PlaySound("buttons/button15.wav")
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
