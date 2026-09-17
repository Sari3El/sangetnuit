--[[-------------------------------------------------------------------------
    Sang et Nuit — Missives : net strings
---------------------------------------------------------------------------]]

if SERVER then
    util.AddNetworkString("sang_missive_open")       -- S->C : ouvre le menu principal (badge non-lus)
    util.AddNetworkString("sang_missive_send")       -- C->S : envoyer une missive
    util.AddNetworkString("sang_missive_inbox_req")  -- C->S : demander la boîte de réception
    util.AddNetworkString("sang_missive_inbox_data") -- S->C : contenu de la boîte de réception
    util.AddNetworkString("sang_missive_badge")      -- S->C : met à jour le badge HUD (nb de non-lues)
    util.AddNetworkString("sang_missive_badge_req")  -- C->S : redemande le badge (resynchro après chargement)
    util.AddNetworkString("sang_missive_dismiss")    -- C->S : supprimer une missive de SA boîte

    -- Anti-abus réseau générique (même logique que BLOOD.NetReceive du cœur ;
    -- dupliqué ici car sang_missives se charge indépendamment).
    SMISSIVE = SMISSIVE or {}
    SMISSIVE.NetMaxPerSecond = SMISSIVE.NetMaxPerSecond or 40
    function SMISSIVE.NetReceive(name, cooldown, fn)
        net.Receive(name, function(len, ply)
            if not IsValid(ply) or not ply:IsPlayer() then return end
            local now = CurTime()
            local win = ply.SangNetWin
            if not win or now - win.t >= 1 then win = { t = now, n = 0 } ply.SangNetWin = win end
            win.n = win.n + 1
            if win.n > SMISSIVE.NetMaxPerSecond then
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
