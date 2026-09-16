--[[-------------------------------------------------------------------------
    Sang et Nuit — Armurerie : net strings
---------------------------------------------------------------------------]]

if SERVER then
    util.AddNetworkString("sang_armory_open")          -- S->C : ouvre/rafraîchit le menu (contenu du coffre)
    util.AddNetworkString("sang_armory_reqsync")        -- C->S : demande une resynchro
    util.AddNetworkString("sang_armory_store")          -- C->S : ranger une arme précise
    util.AddNetworkString("sang_armory_store_all")      -- C->S : ranger toutes les armes portées
    util.AddNetworkString("sang_armory_retrieve")       -- C->S : récupérer une arme précise
    util.AddNetworkString("sang_armory_retrieve_all")   -- C->S : récupérer tout le contenu du coffre

    -- Anti-abus réseau générique (même logique que BLOOD.NetReceive du coeur ;
    -- dupliqué ici car sang_armurerie se charge indépendamment).
    SARM = SARM or {}
    SARM.NetMaxPerSecond = SARM.NetMaxPerSecond or 40
    function SARM.NetReceive(name, cooldown, fn)
        net.Receive(name, function(len, ply)
            if not IsValid(ply) or not ply:IsPlayer() then return end
            local now = CurTime()
            local win = ply.SangNetWin
            if not win or now - win.t >= 1 then win = { t = now, n = 0 } ply.SangNetWin = win end
            win.n = win.n + 1
            if win.n > SARM.NetMaxPerSecond then
                if not ply.SangNetSpamLog or now - ply.SangNetSpamLog > 5 then
                    ply.SangNetSpamLog = now
                    MsgN("[Sang][ANTISPAM] " .. ply:Nick() .. " (" .. ply:SteamID64()
                        .. ") débit réseau excessif — messages temporairement ignorés")
                end
                return
            end
            if cooldown and cooldown > 0 then
                ply.SangNetCD = ply.SangNetCD or {}
                local nxt = ply.SangNetCD[name]
                if nxt and now < nxt then return end
                ply.SangNetCD[name] = now + cooldown
            end
            fn(len, ply)
        end)
    end
end
