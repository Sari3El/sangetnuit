--[[-------------------------------------------------------------------------
    Sang et Nuit — Menu joueur (personnages / reroll / retour Humain)
    Ouvert via !perso (ou console : sang_menu). Style commun BLOOD.UI.
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}
local UI = BLOOD.UI
local C = UI.Col
local S = UI.Scale

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
    if not IsValid(f) or not IsValid(f.Body) then return end

    local body = f.Body
    body:Clear()
    local d = BLOOD.MyData
    local cfg = BLOOD.Config
    local bw = body:GetWide()

    -- Bouton fermer masqué tant qu'aucun perso (création forcée)
    if IsValid(f.btnClose) then f.btnClose:SetVisible(not d.mustCreate) end

    if d.mustCreate then
        -- Bandeau "crée ton premier personnage"
        local head = vgui.Create("DPanel", body)
        head:Dock(TOP) head:DockMargin(0, 0, 0, S(8)) head:SetTall(S(50))
        head.Paint = function(_, w, h)
            UI.VGradient(0, 0, w, h, Color(78, 26, 24), C.bg1)
            surface.SetDrawColor(C.blood); surface.DrawOutlinedRect(0, 0, w, h, 1)
            UI.CornerBrackets(0, 0, w, h, S(10), C.gold)
            draw.SimpleText("Crée ton premier personnage", "SangUI_Title", S(12), S(9), C.goldLt, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText("Choisis un nom — définitif (seul un admin pourra le changer).", "SangUI_Small", S(12), S(30), C.txt, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
    else
        -- Bandeau crédits
        local head = vgui.Create("DPanel", body)
        head:Dock(TOP) head:DockMargin(0, 0, 0, S(8)) head:SetTall(S(40))
        head.Paint = function(_, w, h)
            UI.VGradient(0, 0, w, h, UI.Shade(C.bg2, 6), C.bg1)
            surface.SetDrawColor(C.goldDk); surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText("Crédits de reroll", "SangUI_Body", S(12), h / 2, C.txtDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(tostring(d.credits or 0), "SangUI_H1", w - S(14), h / 2, C.goldLt, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end

        -- Bloc bas : reroll / retour humain
        local bottom = vgui.Create("DPanel", body)
        bottom:Dock(BOTTOM) bottom:DockMargin(0, S(8), 0, 0) bottom:SetTall(S(84))
        bottom.Paint = function(_, w, h)
            surface.SetDrawColor(C.goldDk); surface.DrawRect(0, 0, w, 1)
            local active = d.slots[d.activeSlot]
            local txt = active and (active.name .. "  —  " .. raceName(active.race)) or "aucun perso actif"
            draw.SimpleText("Perso actif : " .. txt, "SangUI_Small", 0, S(6), C.txtDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        local reroll = vgui.Create("DButton", bottom)
        reroll:Dock(LEFT) reroll:DockMargin(0, S(28), S(6), S(4)) reroll:SetWide(S(240))
        reroll:SetText("Reroll  (" .. cfg.RerollCost .. " crédit" .. (cfg.RerollCost > 1 and "s" or "") .. ")")
        UI.SkinButton(reroll, "blood")
        reroll.DoClick = function() net.Start("blood_reroll") net.SendToServer() end

        local human = vgui.Create("DButton", bottom)
        human:Dock(FILL) human:DockMargin(S(6), S(28), 0, S(4))
        human:SetText("Retour Humain  (gratuit)")
        UI.SkinButton(human, "default")
        human.DoClick = function() net.Start("blood_return_human") net.SendToServer() end
    end

    -- Liste des slots
    for i = 1, cfg.MaxSlots do
        local slot   = d.slots[i]
        local isPaid = i > cfg.FreeSlots
        local locked = isPaid and not d.paidUnlocked
        local active = (i == d.activeSlot)

        local row = vgui.Create("DPanel", body)
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, S(6))
        row:SetTall(S(58))
        row.Paint = function(_, w, h)
            UI.VGradient(0, 0, w, h, active and UI.Shade(C.bg3, 4) or C.bg2, C.bg0)
            surface.SetDrawColor(active and C.gold or C.goldDk)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            -- liseré rouge à gauche pour le slot actif
            if active then surface.SetDrawColor(C.blood); surface.DrawRect(0, 0, S(3), h) end

            local title
            if slot then
                title = "Slot " .. i .. (isPaid and "  (payant)" or "") .. "  —  " .. slot.name
            elseif locked then
                title = "Slot " .. i .. "  —  PAYANT (verrouillé)"
            else
                title = "Slot " .. i .. (isPaid and "  (payant)" or "") .. "  —  vide"
            end
            draw.SimpleText(title, "SangUI_Body", S(12), S(12), active and C.goldLt or C.txt, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            if slot then
                draw.SimpleText("Race : " .. raceName(slot.race) .. (active and "     ● ACTIF" or ""),
                    "SangUI_Small", S(12), S(33), C.txtDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end
        end

        if slot then
            local play = vgui.Create("DButton", row)
            play:Dock(RIGHT)
            play:DockMargin(S(6), S(12), S(12), S(12))
            play:SetWide(S(96))
            play:SetText(active and "Actif" or "Jouer")
            play:SetEnabled(not active)
            UI.SkinButton(play, active and "default" or "gold")
            play.DoClick = function()
                net.Start("blood_select_slot") net.WriteUInt(i, 8) net.SendToServer()
            end
        elseif not locked then
            local create = vgui.Create("DButton", row)
            create:Dock(RIGHT)
            create:DockMargin(S(6), S(12), S(12), S(12))
            create:SetWide(S(96))
            create:SetText("Créer")
            UI.SkinButton(create, "gold")
            create.DoClick = function()
                Derma_StringRequest("Nouveau personnage",
                    "Nom du personnage (définitif — seul un admin pourra le changer) :",
                    "",
                    function(txt)
                        txt = string.Trim(txt or "")
                        if #txt < 2 then
                            Derma_Message("Nom trop court (2 caractères minimum).", "Sang et Nuit", "OK")
                            return
                        end
                        net.Start("blood_create_slot")
                        net.WriteUInt(i, 8)
                        net.WriteString(txt)
                        net.SendToServer()
                    end)
            end
        end
    end
end

----------------------------------------------------------------------
-- Ouvre le menu
----------------------------------------------------------------------
function BLOOD.OpenMenu()
    net.Start("blood_request_sync") net.SendToServer()
    if IsValid(BLOOD.MenuFrame) then BLOOD.MenuFrame:Remove() end

    BLOOD.MenuFrame = UI.MakeFrame(S(600), S(500), "Sang et Nuit — Personnages")
    BLOOD.RefreshMenu()
end

-- Création forcée : tant que le joueur n'a aucun perso, on rouvre le menu.
hook.Add("Think", "BLOOD_ForceCreateMenu", function()
    if BLOOD.MyData and BLOOD.MyData.mustCreate and not IsValid(BLOOD.MenuFrame) then
        BLOOD.OpenMenu()
    end
end)
