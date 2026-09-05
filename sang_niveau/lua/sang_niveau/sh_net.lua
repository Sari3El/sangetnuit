--[[-------------------------------------------------------------------------
    Sang et Nuit — Niveaux : net strings
---------------------------------------------------------------------------]]

if SERVER then
    util.AddNetworkString("slvl_sync")       -- S->C : état (niveau, xp, points...)
    util.AddNetworkString("slvl_open_stats") -- S->C : ouvre la borne de compétences
    util.AddNetworkString("slvl_spend")      -- C->S : mettre 1 point dans une stat
    util.AddNetworkString("slvl_respec")     -- C->S : réinitialiser ses points (jeton)

    -- Admin (via origines) — re-vérifié serveur-side
    util.AddNetworkString("slvl_admin_setlevel")
    util.AddNetworkString("slvl_admin_givepoints")
    util.AddNetworkString("slvl_admin_givereset")
    util.AddNetworkString("slvl_set_xpmult")
    util.AddNetworkString("slvl_xpmult")     -- S->C : valeur courante du multiplicateur
    util.AddNetworkString("slvl_req_xpmult") -- C->S : demander la valeur courante

    -- Anti-abus réseau générique (même logique que BLOOD.NetReceive du coeur ;
    -- dupliqué ici car sang_niveau se charge AVANT sang_et_nuit). La fenêtre
    -- anti-spam est stockée sur l'entité joueur donc partagée entre tous les addons.
    SLVL = SLVL or {}
    SLVL.NetMaxPerSecond = SLVL.NetMaxPerSecond or 40
    function SLVL.NetReceive(name, cooldown, fn)
        net.Receive(name, function(len, ply)
            if not IsValid(ply) or not ply:IsPlayer() then return end
            local now = CurTime()
            local win = ply.SangNetWin
            if not win or now - win.t >= 1 then win = { t = now, n = 0 } ply.SangNetWin = win end
            win.n = win.n + 1
            if win.n > SLVL.NetMaxPerSecond then
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
