--[[-------------------------------------------------------------------------
    Sang et Nuit — Niveaux : HUD (haut de l'écran) + état client
---------------------------------------------------------------------------]]

SLVL = SLVL or {}
SLVL.My = SLVL.My or {
    level = 1, xp = 0, xpNext = 0, avail = 0,
    force = 0, resist = 0, agilite = 0, vitalite = 0, reset = 0,
}

net.Receive("slvl_sync", function()
    local d = {}
    d.level  = net.ReadUInt(16)
    d.xp     = net.ReadUInt(32)
    d.xpNext = net.ReadUInt(32)
    d.avail  = net.ReadUInt(16)
    d.force  = net.ReadUInt(8)
    d.resist = net.ReadUInt(8)
    d.agilite = net.ReadUInt(8)
    d.vitalite = net.ReadUInt(8)
    d.reset  = net.ReadUInt(16)
    SLVL.My = d
    if IsValid(SLVL.StatsFrame) and SLVL.RefreshStats then SLVL.RefreshStats() end
end)

local function uiReady() return BLOOD and BLOOD.UI end
local anim = 0

hook.Add("HUDPaint", "SLVL_HUD", function()
    if not uiReady() then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local UI, C, S = BLOOD.UI, BLOOD.UI.Col, BLOOD.UI.Scale
    local d = SLVL.My

    local w, h = S(320), S(58)
    local x = (ScrW() - w) / 2
    local y = S(10)

    UI.Panel(x, y, w, h)

    -- Bloc niveau (gauche)
    local lvW = S(64)
    draw.SimpleText("NIVEAU", "SangUI_Tiny", x + S(12) + lvW / 2, y + S(8), C.txtDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    draw.SimpleText(tostring(d.level), "SangUI_H1", x + S(12) + lvW / 2 + 1, y + S(22) + 1, C.shadow, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    draw.SimpleText(tostring(d.level), "SangUI_H1", x + S(12) + lvW / 2, y + S(22), C.goldLt, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    -- séparateur
    surface.SetDrawColor(C.goldDk)
    surface.DrawRect(x + S(12) + lvW + S(8), y + S(10), 1, h - S(20))

    -- Barre d'XP (droite)
    local bx = x + S(12) + lvW + S(18)
    local bw = (x + w - S(14)) - bx
    local barY = y + h - S(22)
    local maxLevel = (SLVL.Config and SLVL.Config.MaxLevel) or 250

    local frac, txt
    if d.xpNext <= 0 or d.level >= maxLevel then
        frac, txt = 1, "NIVEAU MAX"
    else
        frac = math.Clamp(d.xp / math.max(1, d.xpNext), 0, 1)
        txt = string.Comma(d.xp) .. " / " .. string.Comma(d.xpNext) .. " XP"
    end
    anim = Lerp(FrameTime() * 8, anim, frac)

    draw.SimpleText(txt, "SangUI_Tiny", bx, y + S(9), C.txt, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    if d.avail > 0 then
        draw.SimpleText("+" .. d.avail .. " point" .. (d.avail > 1 and "s" or ""), "SangUI_Tiny",
            bx + bw, y + S(9), C.goldLt, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    end
    UI.Bar(bx, barY, bw, S(14), anim, C.gold, C.goldLt)

    -- Indices [E] sur les bornes
    local tr = ply:GetEyeTrace()
    local e = tr.Entity
    if IsValid(e) then
        local cx, cy = ScrW() / 2, ScrH() / 2
        local cfg = SLVL.Config or {}
        local hint
        if e:GetClass() == "sang_stats" and ply:GetPos():Distance(e:GetPos()) <= (cfg.StatsDist or 140) then
            hint = "[E] Ouvrir les compétences"
        elseif e:GetClass() == "sang_perso" and ply:GetPos():Distance(e:GetPos()) <= (cfg.PersoDist or 140) then
            hint = "[E] Personnages"
        end
        if hint then
            draw.SimpleText(hint, "SangUI_Title", cx + 1, cy + 41, C.shadow, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(hint, "SangUI_Title", cx, cy + 40, C.goldLt, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end)
