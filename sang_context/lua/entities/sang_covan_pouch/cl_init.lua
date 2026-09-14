--[[-------------------------------------------------------------------------
    Sang et Nuit — Sac de Covan (client)
      Modèle teinté or + étiquette flottante « X Covan » face au joueur.
---------------------------------------------------------------------------]]

include("shared.lua")

surface.CreateFont("SangCovan3D", { font = "Georgia", size = 40, weight = 800, antialias = true, extended = true })

function ENT:Draw()
    self:DrawModel()

    local amt = self:GetAmount()
    if amt <= 0 then return end
    local center = self:LocalToWorld(self:OBBCenter())
    if EyePos():DistToSqr(center) > (600 * 600) then return end

    local ang = (EyePos() - center):Angle()
    ang:RotateAroundAxis(ang:Up(), -90)
    ang:RotateAroundAxis(ang:Forward(), 90)

    local pos = center + Vector(0, 0, 16)
    cam.Start3D2D(pos, ang, 0.10)
        draw.SimpleTextOutlined(amt .. " Covan", "SangCovan3D", 0, 0,
            Color(255, 216, 110), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 3, Color(0, 0, 0, 230))
    cam.End3D2D()
end
