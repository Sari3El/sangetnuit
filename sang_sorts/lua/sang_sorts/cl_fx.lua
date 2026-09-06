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

----------------------------------------------------------------------
-- Éclair en Chaîne (E1) : tracé de la foudre entre les cibles touchées.
----------------------------------------------------------------------
local chains = {}
local beamMat = Material("trails/laser.vmt")

net.Receive("sang_chain", function()
    local n = net.ReadUInt(5)
    local pts = {}
    for i = 1, n do pts[i] = net.ReadVector() end
    local r, g, b = net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8)
    chains[#chains + 1] = { pts = pts, col = Color(r, g, b), die = CurTime() + 0.25 }
end)

hook.Add("PostDrawTranslucentRenderables", "SangSorts_Chain", function(depth, sky)
    if depth or sky then return end
    if #chains == 0 then return end
    render.SetMaterial(beamMat)
    for i = #chains, 1, -1 do
        local c = chains[i]
        if CurTime() >= c.die then table.remove(chains, i)
        else
            local a = 255 * math.Clamp((c.die - CurTime()) / 0.25, 0, 1)
            local col = Color(c.col.r, c.col.g, c.col.b, a)
            for k = 1, #c.pts - 1 do
                render.DrawBeam(c.pts[k], c.pts[k + 1], 14, 0, c.pts[k]:Distance(c.pts[k + 1]) / 32, col)
            end
        end
    end
end)
