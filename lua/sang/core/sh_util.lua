--[[-------------------------------------------------------------------------
    Sang et Nuit — Utilitaires partagés
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}

--- Normalise une saisie SteamID vers un SteamID64 (chaîne "7656...").
--  Accepte "STEAM_0:1:..." ou déjà un SteamID64. Retourne nil si invalide.
function BLOOD.NormalizeSteamID(input)
    if not input then return nil end
    input = string.Trim(tostring(input))
    if input == "" then return nil end

    -- Format court STEAM_X:Y:Z
    if string.match(input, "^STEAM_%d:%d:%d+$") then
        local sid64 = util.SteamIDTo64(input)
        if sid64 and sid64 ~= "0" then return sid64 end
        return nil
    end

    -- Déjà un SteamID64 (17 chiffres, commence par 7656)
    if string.match(input, "^7656%d%d%d%d%d%d%d%d%d%d%d%d%d$") then
        return input
    end

    return nil
end

--- Retourne la table joueur en ligne correspondant à un SteamID64, ou nil.
function BLOOD.GetPlayerBySteamID64(sid64)
    sid64 = tostring(sid64)
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and p:SteamID64() == sid64 then return p end
    end
    return nil
end

if SERVER then
    -- Anti-abus réseau générique. Partagé entre TOUS les addons Sang :
    --   - valide l'expéditeur (joueur valide) ;
    --   - fenêtre anti-spam GLOBALE par joueur (stockée sur l'entité, donc
    --     commune à tous les addons) ;
    --   - cooldown par message.
    -- Utilisation : BLOOD.NetReceive("nom", cooldown, function(len, ply) ... end)
    BLOOD.NetMaxPerSecond = BLOOD.NetMaxPerSecond or 40

    function BLOOD.NetReceive(name, cooldown, fn)
        net.Receive(name, function(len, ply)
            if not IsValid(ply) or not ply:IsPlayer() then return end
            local now = CurTime()

            -- fenêtre anti-spam globale (1 s)
            local win = ply.SangNetWin
            if not win or now - win.t >= 1 then win = { t = now, n = 0 } ply.SangNetWin = win end
            win.n = win.n + 1
            if win.n > BLOOD.NetMaxPerSecond then
                if not ply.SangNetSpamLog or now - ply.SangNetSpamLog > 5 then
                    ply.SangNetSpamLog = now
                    MsgN("[Sang][ANTISPAM] " .. ply:Nick() .. " (" .. ply:SteamID64()
                        .. ") débit réseau excessif — messages temporairement ignorés")
                end
                return
            end

            -- cooldown par message
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
