--[[-------------------------------------------------------------------------
    Sang et Nuit — Nourriture : logique de repas (serveur)
      Maintien de E en visant l'entité pendant FeedTime secondes -> repas.
      Un repas : remonte la faim (BLOOD.AddHunger si présent) + soigne un peu.
      3 repas max par entité, puis disparition.
---------------------------------------------------------------------------]]

SFOOD = SFOOD or {}
local C = SFOOD.Config

util.AddNetworkString("sangfood_start") -- serveur -> client : début du canal (durée)
util.AddNetworkString("sangfood_stop")  -- serveur -> client : fin/annulation

-- Annule le canal en cours d'un joueur.
local function cancel(ply)
    if ply.SFChannelEnt then
        ply.SFChannelEnt = nil
        ply.SFChannelStart = nil
        net.Start("sangfood_stop") net.Send(ply)
    end
end

-- Applique un repas au joueur.
local function feed(ply, ent)
    -- Faim (addon principal) si disponible
    if BLOOD and BLOOD.AddHunger then
        BLOOD.AddHunger(ply, C.Hunger)
    end
    -- Soin
    local hp, mx = ply:Health(), ply:GetMaxHealth()
    if hp < mx then ply:SetHealth(math.min(mx, hp + C.Heal)) end

    ply:EmitSound(C.EatSound)
    if BLOOD and BLOOD.Notify then
        BLOOD.Notify(ply, "Vous vous êtes nourri.", "info")
    end

    if ent.ConsumeOne then ent:ConsumeOne(ply) end
end

hook.Add("Think", "SANGFOOD_Channel", function()
    for _, ply in ipairs(player.GetAll()) do
        local ok = IsValid(ply) and ply:Alive() and ply:KeyDown(IN_USE)
        local ent

        if ok then
            local tr = ply:GetEyeTrace()
            ent = tr.Entity
            if not (IsValid(ent) and ent:GetClass() == "sang_food"
                    and ent.GetUsesLeft and ent:GetUsesLeft() > 0
                    and ply:EyePos():Distance(tr.HitPos) <= C.FeedDist) then
                ok = false
            end
        end

        if not ok then
            cancel(ply)
        elseif ply.SFChannelEnt ~= ent then
            -- (re)démarrage du canal
            ply.SFChannelEnt = ent
            ply.SFChannelStart = CurTime()
            net.Start("sangfood_start")
            net.WriteFloat(C.FeedTime)
            net.Send(ply)
        elseif CurTime() - ply.SFChannelStart >= C.FeedTime then
            feed(ply, ent)
            ply.SFChannelEnt = nil
            ply.SFChannelStart = nil
            net.Start("sangfood_stop") net.Send(ply)
        end
    end
end)

-- Nettoyage à la déconnexion
hook.Add("PlayerDisconnected", "SANGFOOD_Cleanup", function(ply)
    ply.SFChannelEnt = nil
    ply.SFChannelStart = nil
end)

----------------------------------------------------------------------
-- Commande de test / spawn admin : sang_food_spawn
----------------------------------------------------------------------
concommand.Add("sang_food_spawn", function(ply)
    local allowed = not IsValid(ply) -- console serveur
        or ply:IsSuperAdmin()
        or (BLOOD and BLOOD.IsAdmin and BLOOD.IsAdmin(ply))
    if not allowed then return end

    local pos
    if IsValid(ply) then
        local tr = ply:GetEyeTrace()
        pos = tr.HitPos + tr.HitNormal * 8
    else
        pos = Vector(0, 0, 0)
    end

    local e = ents.Create("sang_food")
    if not IsValid(e) then return end
    e:SetPos(pos)
    e:Spawn()
    e:Activate()
end)
