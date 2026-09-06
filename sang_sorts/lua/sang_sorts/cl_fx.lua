--[[-------------------------------------------------------------------------
    Sang et Nuit — Sorts : effets d'écran (client)
      « Nuée d'Ombres » (N6) : assombrit l'écran de la cible quelques secondes.
---------------------------------------------------------------------------]]

if not CLIENT then return end
SANGSPELL = SANGSPELL or {}

net.Receive("sang_blind", function()
    local dur = net.ReadFloat()
    SANGSPELL.BlindUntil = CurTime() + math.max(0.1, dur or 3)
    SANGSPELL.BlindDur   = dur or 3
end)

hook.Add("HUDPaint", "SangSorts_Blind", function()
    local until_ = SANGSPELL.BlindUntil
    if not until_ or CurTime() >= until_ then return end
    local left = until_ - CurTime()
    -- Opaque au début, se dissipe sur la dernière seconde.
    local a = 255 * math.Clamp(left / math.min(1, SANGSPELL.BlindDur or 3), 0, 1)
    a = math.max(a, 200 * math.Clamp(left / (SANGSPELL.BlindDur or 3), 0, 1))
    surface.SetDrawColor(8, 0, 10, math.Clamp(a, 0, 245))
    surface.DrawRect(0, 0, ScrW(), ScrH())
end)
