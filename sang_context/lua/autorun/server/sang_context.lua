--[[-------------------------------------------------------------------------
    Sang et Nuit — Menu contextuel (C) : côté serveur
      - Jeter des Covan : retire du solde + fait apparaître un sac ramassable.
      - Faire un ticket : prévient le staff en ligne + log (v1 ; un vrai système
        de tickets viendra remplacer ça, en passant par le même bouton).
---------------------------------------------------------------------------]]

if not SERVER then return end

util.AddNetworkString("sang_ctx_drop")
util.AddNetworkString("sang_ctx_ticket")

local DROP_MIN   = 1
local DROP_CD    = 1       -- secondes entre deux drops
local TICKET_CD  = 20      -- secondes entre deux tickets

----------------------------------------------------------------------
-- Jeter des Covan -> sac ramassable
----------------------------------------------------------------------
net.Receive("sang_ctx_drop", function(_, ply)
    if not (IsValid(ply) and ply:Alive()) then return end
    local amount = math.floor(net.ReadInt(32) or 0)
    if amount < DROP_MIN then return end
    if (ply.SangDropCD or 0) > CurTime() then return end
    if not (BLOOD and BLOOD.GetCovan and BLOOD.AddCovan) then return end

    if amount > BLOOD.GetCovan(ply) then
        if BLOOD.Notify then BLOOD.Notify(ply, "Tu n'as pas assez de Covan.", "error") end
        return
    end
    ply.SangDropCD = CurTime() + DROP_CD

    BLOOD.AddCovan(ply, -amount)

    local pos = ply:GetShootPos() + ply:GetAimVector() * 40 + Vector(0, 0, 8)
    local e = ents.Create("sang_covan_pouch")
    if not IsValid(e) then return end
    e:SetPos(pos)
    e:Spawn()
    e:SetAmount(amount)
    e:SetDropper(ply:SteamID64())
    local phys = e:GetPhysicsObject()
    if IsValid(phys) then phys:SetVelocity(ply:GetAimVector() * 120 + Vector(0, 0, 60)) end

    if BLOOD.Notify then BLOOD.Notify(ply, "Tu as jeté " .. amount .. " Covan.", "info") end
end)

----------------------------------------------------------------------
-- Faire un ticket (v1 : notifie les admins en ligne + log)
----------------------------------------------------------------------
net.Receive("sang_ctx_ticket", function(_, ply)
    if not IsValid(ply) then return end
    if (ply.SangTicketCD or 0) > CurTime() then return end
    local msg = string.Trim(string.sub(net.ReadString() or "", 1, 300))
    if msg == "" then return end
    ply.SangTicketCD = CurTime() + TICKET_CD

    -- Ticket -> tchat des SUPER ADMINS uniquement (canal staff).
    if BLOOD and BLOOD.StaffNotify then
        BLOOD.StaffNotify("Ticket de " .. ply:Nick() .. " : " .. msg)
    end
    if BLOOD and BLOOD.LogAdmin then
        BLOOD.LogAdmin("TICKET " .. ply:Nick() .. " (" .. ply:SteamID64() .. ") : " .. msg)
    end
    -- Confirmation au joueur : HUD (via Notify), pas dans le tchat.
    if BLOOD and BLOOD.Notify then
        BLOOD.Notify(ply, "Ton ticket a été envoyé au staff.", "info")
    end
end)
