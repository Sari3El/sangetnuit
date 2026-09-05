--[[-------------------------------------------------------------------------
    Sang et Nuit — Jobs : net strings
---------------------------------------------------------------------------]]

if SERVER then
    util.AddNetworkString("sjob_set")             -- C->S : choisir un job (F4)
    -- Admin (Config Perso)
    util.AddNetworkString("sjob_admin_setjob")    -- C->S : forcer le job d'un slot
    util.AddNetworkString("sjob_admin_setoverride") -- C->S : override PV/armure/vitesse
    util.AddNetworkString("sjob_admin_clearoverride")
    util.AddNetworkString("sjob_query")           -- C->S : demander défaut + override
    util.AddNetworkString("sjob_query_result")    -- S->C : défaut + override

    -- Anti-abus réseau générique (même logique que BLOOD.NetReceive du coeur ;
    -- dupliqué ici car sang_jobs se charge indépendamment). La fenêtre anti-spam
    -- est stockée sur l'entité joueur, donc partagée entre tous les addons Sang.
    SJOB = SJOB or {}
    SJOB.NetMaxPerSecond = SJOB.NetMaxPerSecond or 40
    function SJOB.NetReceive(name, cooldown, fn)
        net.Receive(name, function(len, ply)
            if not IsValid(ply) or not ply:IsPlayer() then return end
            local now = CurTime()
            local win = ply.SangNetWin
            if not win or now - win.t >= 1 then win = { t = now, n = 0 } ply.SangNetWin = win end
            win.n = win.n + 1
            if win.n > SJOB.NetMaxPerSecond then
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
