--[[-------------------------------------------------------------------------
    Sang et Nuit — Menu joueur (personnages / reroll)
    Ouvert via l'entité borne perso. Style commun BLOOD.UI.
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

        -- Bloc bas : reroll
        local bottom = vgui.Create("DPanel", body)
        bottom:Dock(BOTTOM) bottom:DockMargin(0, S(8), 0, 0) bottom:SetTall(S(84))
        bottom.Paint = function(_, w, h)
            surface.SetDrawColor(C.goldDk); surface.DrawRect(0, 0, w, 1)
            local active = d.slots[d.activeSlot]
            local txt = active and (active.name .. "  —  " .. raceName(active.race)) or "aucun perso actif"
            draw.SimpleText("Perso actif : " .. txt, "SangUI_Small", 0, S(6), C.txtDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        local reroll = vgui.Create("DButton", bottom)
        reroll:Dock(FILL) reroll:DockMargin(0, S(28), 0, S(4))
        reroll:SetText("Reroll  (" .. cfg.RerollCost .. " crédit" .. (cfg.RerollCost > 1 and "s" or "") .. ")")
        UI.SkinButton(reroll, "blood")
        -- Désactivé pendant qu'une roulette est en cours (anti-relance).
        reroll:SetEnabled(not BLOOD.Rerolling)
        reroll.DoClick = function()
            if BLOOD.Rerolling then return end
            net.Start("blood_reroll") net.SendToServer()
        end
    end

    -- Bouton : codex des sangs (raretés ACTUELLES + bonus de chaque sang)
    local codexBtn = vgui.Create("DButton", body)
    codexBtn:Dock(TOP) codexBtn:DockMargin(0, 0, 0, S(8)) codexBtn:SetTall(S(28))
    codexBtn:SetText("Sangs & raretés  —  bonus & % actuels")
    UI.SkinButton(codexBtn, "gold")
    codexBtn.DoClick = function() BLOOD.OpenBloodCodex() end

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
                -- Fermer le menu à la sélection (évite d'enchaîner les changements).
                if IsValid(BLOOD.MenuFrame) then BLOOD.MenuFrame:Remove() end
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

    -- Slot EVENT (spécial) : visible seulement s'il est débloqué pour ce joueur.
    if d.eventUnlocked and not d.mustCreate then
        local es = cfg.EventSlot or 5
        local active = (es == d.activeSlot)
        local purple = Color(160, 92, 214)
        local row = vgui.Create("DPanel", body)
        row:Dock(TOP) row:DockMargin(0, S(4), 0, S(6)) row:SetTall(S(58))
        row.Paint = function(_, w, h)
            UI.VGradient(0, 0, w, h, active and UI.Shade(C.bg3, 4) or C.bg2, C.bg0)
            surface.SetDrawColor(active and purple or C.goldDk)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            if active then surface.SetDrawColor(purple) surface.DrawRect(0, 0, S(3), h) end
            draw.SimpleText("Slot EVENT  —  " .. (d.eventName or "nouveau"), "SangUI_Body",
                S(12), S(12), active and purple or C.txt, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText("Personnage d'évènement (niveau figé)" .. (active and "     ● ACTIF" or ""),
                "SangUI_Small", S(12), S(33), C.txtDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
        local play = vgui.Create("DButton", row)
        play:Dock(RIGHT) play:DockMargin(S(6), S(12), S(12), S(12)) play:SetWide(S(96))
        play:SetText(active and "Actif" or "Jouer")
        play:SetEnabled(not active)
        UI.SkinButton(play, active and "default" or "gold")
        play.DoClick = function()
            net.Start("blood_select_slot") net.WriteUInt(es, 8) net.SendToServer()
            if IsValid(BLOOD.MenuFrame) then BLOOD.MenuFrame:Remove() end
        end
    end
end

----------------------------------------------------------------------
-- Ouvre le menu
----------------------------------------------------------------------
function BLOOD.OpenMenu()
    net.Start("blood_request_sync") net.SendToServer()
    if IsValid(BLOOD.MenuFrame) then BLOOD.MenuFrame:Remove() end

    BLOOD.MenuFrame = UI.MakeFrame(S(820), S(660), "Sang et Nuit — Personnages")
    BLOOD.RefreshMenu()
end

-- Création forcée : tant que le joueur n'a aucun perso, on rouvre le menu.
hook.Add("Think", "BLOOD_ForceCreateMenu", function()
    if BLOOD.MyData and BLOOD.MyData.mustCreate and not IsValid(BLOOD.MenuFrame) then
        BLOOD.OpenMenu()
    end
end)

----------------------------------------------------------------------
-- CODEX DES SANGS : liste tous les sangs, leur rareté ACTUELLE (%) et leurs
-- bonus/perks. Les % viennent du serveur (à jour même après modif admin).
----------------------------------------------------------------------
BLOOD._rarityPub = BLOOD._rarityPub or {}

-- Bonus/perks d'un sang -> lignes lisibles (lues depuis la config partagée).
function BLOOD.FormatRacePerks(r)
    local out = {}
    local function pc(mult) -- 1.15 -> "+15%" ; 0.8 -> "-20%"
        local p = math.Round((mult - 1) * 100)
        return (p >= 0 and "+" or "") .. p .. "%"
    end
    if r.hp and r.hp ~= 1 then out[#out + 1] = "PV " .. pc(r.hp) end
    if r.speed and r.speed ~= 1 then out[#out + 1] = "Vitesse " .. pc(r.speed) end
    if r.dmgReduction and r.dmgReduction > 0 then
        out[#out + 1] = "Réduction de dégâts : " .. math.Round(r.dmgReduction * 100) .. "%"
    end
    if r.dmgBonus then
        for _, b in ipairs(r.dmgBonus) do
            out[#out + 1] = "Dégâts " .. table.concat(b.tags or {}, ", ") .. " " .. pc(b.mult or 1)
        end
    end
    if r.dodge and r.dodge > 0 then out[#out + 1] = "Esquive : " .. math.Round(r.dodge * 100) .. "%" end
    if r.regen and r.regen > 0 then out[#out + 1] = "Régénération : +" .. r.regen .. " PV/s" end
    if r.magicResist and r.magicResist > 0 then out[#out + 1] = "Résistance magique : " .. math.Round(r.magicResist * 100) .. "%" end
    if r.fireResist and r.fireResist > 0 then out[#out + 1] = "Résistance au feu : " .. math.Round(r.fireResist * 100) .. "%" end
    if r.stealth then out[#out + 1] = "Furtivité" end
    if r.mana and r.mana > 0 then out[#out + 1] = "Réserve de mana : " .. r.mana end
    if r.weapons and #r.weapons > 0 then out[#out + 1] = "Arme spéciale de sang" end
    if #out == 0 then out[#out + 1] = "Aucun bonus particulier." end
    return out
end

function BLOOD.RefreshCodex()
    local f = BLOOD.CodexFrame
    if not IsValid(f) or not IsValid(f.CodexScroll) then return end
    local scroll = f.CodexScroll
    scroll:Clear()

    -- Trier : plus RARE (% le plus bas) en haut.
    local list = {}
    for _, r in ipairs(BLOOD.Config.Races) do list[#list + 1] = r end
    local function pctOf(r)
        local pub = BLOOD._rarityPub[r.id]
        if pub then return pub.pct end
        return ((r.max or 0) - (r.min or 0) + 1) / 100 -- fallback config
    end
    table.sort(list, function(a, b) return pctOf(a) < pctOf(b) end)

    for _, r in ipairs(list) do
        local pub = BLOOD._rarityPub[r.id]
        local pctTxt = pub and string.format("%.2f%%", pub.pct) or "…"
        local perks = BLOOD.FormatRacePerks(r)

        local card = vgui.Create("DPanel", scroll)
        card:Dock(TOP) card:DockMargin(0, 0, S(6), S(6))
        card:SetTall(S(34) + #perks * S(16) + S(6))
        card.Paint = function(_, w, h)
            UI.VGradient(0, 0, w, h, C.bg2, C.bg0)
            surface.SetDrawColor(C.goldDk); surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText(r.name .. "  (" .. (r.short or "") .. ")", "SangUI_Body",
                S(10), S(8), C.goldLt, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(pctTxt .. "   " .. (r.rarity or ""), "SangUI_Small",
                w - S(10), S(10), C.txt, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
            local y = S(30)
            for _, line in ipairs(perks) do
                draw.SimpleText("•  " .. line, "SangUI_Small", S(14), y, C.txtDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                y = y + S(16)
            end
        end
    end
end

function BLOOD.OpenBloodCodex()
    if not (BLOOD.UI and BLOOD.Races and BLOOD.Config) then return end
    if IsValid(BLOOD.CodexFrame) then BLOOD.CodexFrame:Remove() end
    BLOOD.CodexFrame = UI.MakeFrame(S(640), S(680), "Sangs & Raretés")
    local scroll = vgui.Create("DScrollPanel", BLOOD.CodexFrame.Body)
    scroll:Dock(FILL)
    BLOOD.CodexFrame.CodexScroll = scroll
    BLOOD.RefreshCodex()
    net.Start("blood_req_rarity_pub") net.SendToServer() -- % à jour
end

net.Receive("blood_rarity_pub", function()
    local n = net.ReadUInt(8)
    BLOOD._rarityPub = {}
    for _ = 1, n do
        local id   = net.ReadString()
        local pct  = net.ReadFloat()
        local tier = net.ReadString()
        BLOOD._rarityPub[id] = { pct = pct, tier = tier }
    end
    if IsValid(BLOOD.CodexFrame) then BLOOD.RefreshCodex() end
end)
