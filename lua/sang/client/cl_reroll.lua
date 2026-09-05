--[[-------------------------------------------------------------------------
    Sang et Nuit — Roulette de reroll + annonce publique
      - Roulette horizontale (cases qui défilent, s'arrêtent sur ta race).
      - Annonce dans le chat de tous, colorée selon le palier de rareté.
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}
local function S(v) return BLOOD.UI.Scale(v) end

surface.CreateFont("SangRoul_Title",  { font = "Georgia", size = S(34), weight = 800, antialias = true, extended = true })
surface.CreateFont("SangRoul_Card",   { font = "Georgia", size = S(20), weight = 700, antialias = true, extended = true })
surface.CreateFont("SangRoul_Tier",   { font = "Georgia", size = S(15), weight = 600, antialias = true, extended = true })
surface.CreateFont("SangRoul_Result", { font = "Georgia", size = S(30), weight = 800, antialias = true, extended = true })

local function easeOut(t) t = math.Clamp(t, 0, 1) return 1 - (1 - t) ^ 3 end

local function drawCard(x, y, w, h, id, big)
    local UI, C = BLOOD.UI, BLOOD.UI.Col
    local tier = BLOOD.GetTier(id)
    local r = BLOOD.Races[id]
    local nm = r and (r.short or r.name) or id
    UI.VGradient(x, y, w, h, UI.Shade(C.bg2, big and 14 or 2), C.bg0)
    surface.SetDrawColor(tier.color)
    surface.DrawRect(x, y, w, S(6))
    surface.SetDrawColor(tier.color.r, tier.color.g, tier.color.b, big and 255 or 170)
    surface.DrawOutlinedRect(x, y, w, h, big and 3 or 1)
    draw.SimpleText(nm, "SangRoul_Card", x + w / 2, y + h / 2, C.txt, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(tier.name, "SangRoul_Tier", x + w / 2, y + h - S(14), tier.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

----------------------------------------------------------------------
-- Roulette
----------------------------------------------------------------------
function BLOOD.PlayRerollRoulette(resultId)
    if not (BLOOD.UI and BLOOD.Races) then return end
    if IsValid(BLOOD.MenuFrame) then BLOOD.MenuFrame:Remove() end
    if IsValid(BLOOD.RoulettePanel) then BLOOD.RoulettePanel:Remove() end

    local order = BLOOD.RaceOrder or { "human" }
    local N = 50
    local resultIdx0 = N - 6
    local cards = {}
    for i = 1, N do cards[i] = order[math.random(#order)] or "human" end
    cards[resultIdx0 + 1] = resultId

    local p = vgui.Create("DPanel")
    BLOOD.RoulettePanel = p
    p:SetSize(ScrW(), ScrH())
    p:SetPos(0, 0)
    p:SetMouseInputEnabled(false)
    p:SetKeyboardInputEnabled(false)

    p.Start = SysTime()
    p.Dur = 4.2
    p.Hold = 2.6
    p.Cards = cards
    p.ResultIdx0 = resultIdx0
    p.Result = resultId
    p.LastCenter = -1
    p.Revealed = false

    p.Paint = function(self, w, h)
        local C = BLOOD.UI.Col
        local cw, ch, gap = S(150), S(190), S(12)
        local pit = cw + gap
        local cx = w / 2
        local rowY = h / 2 - ch / 2

        local t = (SysTime() - self.Start) / self.Dur
        local offset = (self.ResultIdx0 * pit) * easeOut(t)

        surface.SetDrawColor(6, 5, 4, math.Clamp(t * 3, 0, 1) * 232)
        surface.DrawRect(0, 0, w, h)

        draw.SimpleText("Réveil du Sang…", "SangRoul_Title", cx + 1, rowY - S(40) + 1, Color(0, 0, 0, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Réveil du Sang…", "SangRoul_Title", cx, rowY - S(40), C.goldLt, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        local stripStartX = cx - cw / 2
        local firstI = math.max(0, math.floor((offset - cw) / pit))
        local lastI  = math.min(#self.Cards - 1, firstI + math.ceil(w / pit) + 2)
        for i = firstI, lastI do
            drawCard(stripStartX + i * pit - offset, rowY, cw, ch, self.Cards[i + 1], false)
        end

        -- marqueur central
        surface.SetDrawColor(C.gold)
        surface.DrawRect(cx - 1, rowY - S(14), 2, ch + S(28))
        draw.NoTexture()
        surface.SetDrawColor(C.goldLt)
        surface.DrawPoly({ { x = cx - S(8), y = rowY - S(16) }, { x = cx + S(8), y = rowY - S(16) }, { x = cx, y = rowY - S(4) } })

        if t >= 1 then
            local tier = BLOOD.GetTier(self.Result)
            local r = BLOOD.Races[self.Result]
            local nm = r and r.name or self.Result
            local txt = nm .. "  —  " .. tier.name .. " !"
            draw.SimpleText(txt, "SangRoul_Result", cx + 1, rowY + ch + S(36) + 1, Color(0, 0, 0, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(txt, "SangRoul_Result", cx, rowY + ch + S(36), tier.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    p.Think = function(self)
        local t = (SysTime() - self.Start) / self.Dur
        if t < 1 then
            local pit = S(150) + S(12)
            local center = math.Round(((self.ResultIdx0 * pit) * easeOut(t)) / pit)
            if center ~= self.LastCenter then
                self.LastCenter = center
                surface.PlaySound("common/wpn_moveselect.wav")
            end
        elseif not self.Revealed then
            self.Revealed = true
            surface.PlaySound("buttons/button3.wav")
        end
        if (SysTime() - self.Start) >= (self.Dur + self.Hold) then
            self:Remove()
        end
    end
end

net.Receive("blood_reroll_roll", function()
    BLOOD.PlayRerollRoulette(net.ReadString())
end)

----------------------------------------------------------------------
-- Annonce publique colorée
----------------------------------------------------------------------
net.Receive("blood_reroll_announce", function()
    local name   = net.ReadString()
    local raceId = net.ReadString()
    local r = BLOOD.Races and BLOOD.Races[raceId]
    local tier = BLOOD.GetTier(raceId)
    local rname = r and r.name or raceId
    chat.AddText(Color(200, 60, 60), "[Sang] ", color_white, name .. " a réveillé son sang : ",
        tier.color, rname .. "  — " .. tier.name .. " !")
    surface.PlaySound("buttons/button17.wav")
end)
