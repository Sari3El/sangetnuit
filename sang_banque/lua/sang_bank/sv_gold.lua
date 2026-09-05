--[[-------------------------------------------------------------------------
    Sang et Nuit — Banque : or au sol (serveur)
      - Mort : lâche 2/3 de l'argent porté (entité sang_gold).
      - /dropmoney <montant> : lâche un montant choisi.
      (Le ramassage en [E] est géré par l'entité sang_gold.)
---------------------------------------------------------------------------]]

SBANK = SBANK or {}
local C = SBANK.Config

--- Fait apparaître un tas d'or contenant `amount` Covan.
function SBANK.SpawnGold(pos, amount, ang)
    amount = math.floor(amount)
    if amount <= 0 then return end
    local e = ents.Create("sang_gold")
    if not IsValid(e) then return end
    e:SetPos(pos)
    if ang then e:SetAngles(ang) end
    e:Spawn()
    e:Activate()
    e:SetGold(amount)
    return e
end

----------------------------------------------------------------------
-- Mort : drop 2/3 de l'argent porté
----------------------------------------------------------------------
hook.Add("PlayerDeath", "SANGBANK_DeathDrop", function(ply)
    if not (BLOOD and BLOOD.GetCovan) then return end
    local covan = BLOOD.GetCovan(ply)
    if covan <= 0 then return end

    local drop = math.floor(covan * C.DeathDropNum / C.DeathDropDen)
    if drop <= 0 then return end

    BLOOD.AddCovan(ply, -drop)
    SBANK.SpawnGold(ply:GetPos() + Vector(0, 0, 10), drop)
end)

----------------------------------------------------------------------
-- /dropmoney <montant>
----------------------------------------------------------------------
hook.Add("PlayerSay", "SANGBANK_DropMoney", function(ply, text)
    local args = string.Explode(" ", string.Trim(text))
    local cmd = string.lower(args[1] or "")
    if cmd ~= "/dropmoney" and cmd ~= "!dropmoney" then return end

    if not (BLOOD and BLOOD.GetCovan) then return "" end
    local amount = math.floor(tonumber(args[2]) or 0)
    if amount <= 0 then
        SBANK.Notify(ply, "Usage : /dropmoney <montant>", "error")
        return ""
    end

    if BLOOD.GetCovan(ply) < amount then
        SBANK.Notify(ply, "Pas assez d'argent sur toi.", "error")
        return ""
    end

    BLOOD.AddCovan(ply, -amount)
    local ang = Angle(0, ply:EyeAngles().yaw, 0)
    local pos = ply:GetPos() + ang:Forward() * 40 + Vector(0, 0, 20)
    SBANK.SpawnGold(pos, amount, ang)
    SBANK.Notify(ply, "Tu as lâché " .. amount .. " au sol.", "info")
    return ""
end)
