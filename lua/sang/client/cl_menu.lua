--[[-------------------------------------------------------------------------
    Sang et Nuit — Menu joueur (personnages / reroll / retour Humain)
    Ouvert via la commande chat !perso (ou console : sang_menu).
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}

local function raceName(id)
    local r = BLOOD.Races and BLOOD.Races[id]
    return r and r.name or id
end

local function raceDesc(id)
    local r = BLOOD.Races and BLOOD.Races[id]
    return r and r.desc or ""
end

----------------------------------------------------------------------
-- (Re)construit le contenu du menu depuis BLOOD.MyData
----------------------------------------------------------------------
function BLOOD.RefreshMenu()
    local f = BLOOD.MenuFrame
    if not IsValid(f) or not IsValid(f.Content) then return end

    local C = BLOOD.Config
    local d = BLOOD.MyData
    local content = f.Content
    content:Clear()

    -- En-tête : crédits
    local head = vgui.Create("DLabel", content)
    head:Dock(TOP)
    head:DockMargin(10, 10, 10, 4)
    head:SetFont("DermaLarge")
    head:SetText("Crédits de reroll : " .. (d.credits or 0))
    head:SizeToContents()

    -- Bloc bas (reroll / humain) docké en premier pour rester en bas
    local bottom = vgui.Create("DPanel", content)
    bottom:Dock(BOTTOM)
    bottom:DockMargin(10, 6, 10, 10)
    bottom:SetTall(78)
    bottom.Paint = function() end

    local active = d.slots[d.activeSlot]
    local info = vgui.Create("DLabel", bottom)
    info:Dock(TOP)
    info:SetText("Perso actif : " .. (active
        and (active.name .. " — " .. raceName(active.race) .. "  (" .. raceDesc(active.race) .. ")")
        or "aucun"))
    info:SizeToContents()

    local btnRow = vgui.Create("DPanel", bottom)
    btnRow:Dock(FILL)
    btnRow:DockMargin(0, 6, 0, 0)
    btnRow.Paint = function() end

    local reroll = vgui.Create("DButton", btnRow)
    reroll:Dock(LEFT)
    reroll:DockMargin(0, 0, 4, 0)
    reroll:SetWide(255)
    reroll:SetText("Reroll (" .. C.RerollCost .. " crédit" .. (C.RerollCost > 1 and "s" or "") .. ")")
    reroll.DoClick = function()
        net.Start("blood_reroll") net.SendToServer()
    end

    local human = vgui.Create("DButton", btnRow)
    human:Dock(FILL)
    human:DockMargin(4, 0, 0, 0)
    human:SetText("Retour Humain (gratuit)")
    human.DoClick = function()
        net.Start("blood_return_human") net.SendToServer()
    end

    -- Liste des slots
    for i = 1, C.MaxSlots do
        local slot   = d.slots[i]
        local isPaid = i > C.FreeSlots
        local locked = isPaid and not d.paidUnlocked

        local row = vgui.Create("DPanel", content)
        row:Dock(TOP)
        row:DockMargin(10, 4, 10, 0)
        row:SetTall(58)
        row.Paint = function(_, w, h)
            local col = (i == d.activeSlot) and Color(40, 70, 40) or Color(45, 45, 45)
            draw.RoundedBox(6, 0, 0, w, h, col)
        end

        local lbl = vgui.Create("DLabel", row)
        lbl:Dock(LEFT)
        lbl:DockMargin(12, 0, 0, 0)
        lbl:SetWide(300)
        lbl:SetContentAlignment(4)
        if slot then
            lbl:SetText("Slot " .. i .. (isPaid and " (payant)" or "") .. " — " .. slot.name
                .. "\nRace : " .. raceName(slot.race) .. (i == d.activeSlot and "   [ACTIF]" or ""))
        elseif locked then
            lbl:SetText("Slot " .. i .. " — PAYANT (verrouillé)")
        else
            lbl:SetText("Slot " .. i .. (isPaid and " (payant)" or "") .. " — vide")
        end

        if slot then
            local play = vgui.Create("DButton", row)
            play:Dock(RIGHT)
            play:DockMargin(4, 11, 12, 11)
            play:SetWide(96)
            play:SetText(i == d.activeSlot and "Actif" or "Jouer")
            play:SetEnabled(i ~= d.activeSlot)
            play.DoClick = function()
                net.Start("blood_select_slot") net.WriteUInt(i, 8) net.SendToServer()
            end
        elseif not locked then
            local create = vgui.Create("DButton", row)
            create:Dock(RIGHT)
            create:DockMargin(4, 11, 12, 11)
            create:SetWide(96)
            create:SetText("Créer")
            create.DoClick = function()
                Derma_StringRequest("Nouveau personnage", "Nom du personnage :",
                    "Personnage " .. i,
                    function(txt)
                        net.Start("blood_create_slot")
                        net.WriteUInt(i, 8)
                        net.WriteString(txt or "")
                        net.SendToServer()
                    end)
            end
        end
    end
end

----------------------------------------------------------------------
-- Ouvre le menu (demande une synchro fraîche au serveur)
----------------------------------------------------------------------
function BLOOD.OpenMenu()
    net.Start("blood_request_sync") net.SendToServer()

    if IsValid(BLOOD.MenuFrame) then BLOOD.MenuFrame:Remove() end

    local f = vgui.Create("DFrame")
    BLOOD.MenuFrame = f
    f:SetSize(600, 470)
    f:Center()
    f:SetTitle("Sang et Nuit — Personnages")
    f:MakePopup()

    f.Content = vgui.Create("DPanel", f)
    f.Content:Dock(FILL)
    f.Content.Paint = function() end

    BLOOD.RefreshMenu()
end
