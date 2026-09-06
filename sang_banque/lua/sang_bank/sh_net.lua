--[[-------------------------------------------------------------------------
    Sang et Nuit — Banque : net strings
---------------------------------------------------------------------------]]

if SERVER then
    util.AddNetworkString("sang_bank_open")     -- S->C : ouvre/rafraîchit le menu (données)
    util.AddNetworkString("sang_bank_reqsync")  -- C->S : demande une resynchro
    util.AddNetworkString("sang_bank_deposit")  -- C->S : déposer (perso)
    util.AddNetworkString("sang_bank_withdraw") -- C->S : retirer (perso)
    util.AddNetworkString("sang_bank_facdeposit") -- C->S : déposer dans SA banque de faction

    -- Admin (re-vérifié serveur-side)
    util.AddNetworkString("sang_bank_settax")    -- C->S : régler une taxe
    util.AddNetworkString("sang_bank_setfaction") -- C->S : ajouter/retirer sur une banque de faction
    util.AddNetworkString("sang_bank_setplayer")  -- C->S : ajouter/retirer sur la banque d'un joueur
    util.AddNetworkString("sang_bank_query")       -- C->S : demander le solde d'un joueur/slot
    util.AddNetworkString("sang_bank_queryresult") -- S->C : solde d'un joueur/slot
    util.AddNetworkString("sang_bank_queryall")       -- C->S : demander les 4 soldes d'un joueur
    util.AddNetworkString("sang_bank_queryall_result")-- S->C : les 4 soldes (slot 1..4)

    -- Historique (admin uniquement)
    util.AddNetworkString("sang_bank_hist_req")    -- C->S : demander l'historique
    util.AddNetworkString("sang_bank_hist_data")   -- S->C : les 100 dernières actions

    -- Anti-abus réseau générique (même logique que BLOOD.NetReceive du coeur ;
    -- dupliqué ici car sang_banque se charge indépendamment). La fenêtre
    -- anti-spam est stockée sur l'entité joueur, donc partagée entre tous les addons.
    SBANK = SBANK or {}
    SBANK.NetMaxPerSecond = SBANK.NetMaxPerSecond or 40
    function SBANK.NetReceive(name, cooldown, fn)
        net.Receive(name, function(len, ply)
            if not IsValid(ply) or not ply:IsPlayer() then return end
            local now = CurTime()
            local win = ply.SangNetWin
            if not win or now - win.t >= 1 then win = { t = now, n = 0 } ply.SangNetWin = win end
            win.n = win.n + 1
            if win.n > SBANK.NetMaxPerSecond then
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
