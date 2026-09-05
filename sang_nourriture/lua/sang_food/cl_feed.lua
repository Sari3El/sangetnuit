--[[-------------------------------------------------------------------------
    Sang et Nuit — Nourriture : retour visuel (client)
      - Indice « Maintenir E pour manger » quand on vise l'entité
      - Barre de progression pendant le repas
    Style médiéval (vert/or) autonome (ne dépend pas de l'addon principal).
---------------------------------------------------------------------------]]

SFOOD = SFOOD or {}

surface.CreateFont("SangFood_Hint", { font = "Georgia", size = 20, weight = 700, antialias = true, extended = true })
surface.CreateFont("SangFood_Small", { font = "Georgia", size = 15, weight = 600, antialias = true, extended = true })

local COL = {
    bg    = Color(16, 13, 10, 235),
    track = Color(8, 6, 4, 235),
    green = Color(70, 132, 52),
    greenL= Color(132, 198, 92),
    gold  = Color(176, 141, 74),
    goldD = Color(92, 71, 38),
    txt   = Color(224, 210, 176),
    sh    = Color(0, 0, 0, 200),
}

local channel = { active = false, start = 0, dur = 5 }

net.Receive("sangfood_start", function()
    channel.dur = net.ReadFloat()
    channel.start = CurTime()
    channel.active = true
end)

net.Receive("sangfood_stop", function()
    channel.active = false
end)

local function drawTextShadow(txt, font, x, y, col, ax, ay)
    draw.SimpleText(txt, font, x + 1, y + 1, COL.sh, ax, ay)
    draw.SimpleText(txt, font, x, y, col, ax, ay)
end

hook.Add("HUDPaint", "SANGFOOD_HUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local cx, cy = ScrW() / 2, ScrH() / 2

    if channel.active then
        -- Barre de progression
        local frac = math.Clamp((CurTime() - channel.start) / math.max(0.1, channel.dur), 0, 1)
        local w, h = 240, 24
        local x, y = cx - w / 2, cy + 70

        draw.RoundedBox(4, x - 2, y - 2, w + 4, h + 4, COL.bg)
        draw.RoundedBox(3, x, y, w, h, COL.track)
        local fw = math.floor((w - 4) * frac)
        if fw > 0 then
            draw.RoundedBox(2, x + 2, y + 2, fw, h - 4, COL.green)
            surface.SetDrawColor(COL.greenL.r, COL.greenL.g, COL.greenL.b, 90)
            surface.DrawRect(x + 2, y + 2, fw, 2)
        end
        surface.SetDrawColor(COL.goldD)
        surface.DrawOutlinedRect(x, y, w, h, 1)

        drawTextShadow("Vous vous nourrissez…", "SangFood_Small", cx, y - 14, COL.txt, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        drawTextShadow(math.Round(frac * 100) .. "%", "SangFood_Small", cx, y + h / 2, COL.txt, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        if frac >= 1 then channel.active = false end
        return
    end

    -- Indice quand on vise une nourriture à portée
    local tr = ply:GetEyeTrace()
    local e = tr.Entity
    local dist = SFOOD.Config and SFOOD.Config.FeedDist or 110
    if IsValid(e) and e:GetClass() == "sang_food" and ply:EyePos():Distance(tr.HitPos) <= dist then
        local uses = (e.GetUsesLeft and e:GetUsesLeft()) or 0
        drawTextShadow("Maintenir [E] pour manger", "SangFood_Hint", cx, cy + 40, COL.gold, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        drawTextShadow("Repas restants : " .. uses, "SangFood_Small", cx, cy + 62, COL.txt, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)
