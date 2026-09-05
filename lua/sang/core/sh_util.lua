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
