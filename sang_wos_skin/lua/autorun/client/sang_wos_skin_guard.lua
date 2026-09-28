--[[-------------------------------------------------------------------------
    Sang et Nuit — wiltOS Skin : GARDE-FOU anti-spam (wOS.Lightsabers nil)

      Quand la synchro réseau wiltOS n'est pas (encore) arrivée côté client,
      « wOS.Lightsabers » est nil. Le hook PostPlayerDraw d'origine de wiltOS
      (combat/cl_saberbase_hook.lua:270) fait alors « pairs(wOS.Lightsabers.General) »
      sur un nil et SPAMME des milliers d'erreurs par seconde (perf + console).

      Ici on fournit JUSTE une table vide par défaut, juste avant le dessin des
      joueurs : le hook itère sur du vide (no-op) au lieu de planter. Dès que le
      serveur envoie les vraies données (net.ReadTable), elles écrasent cette
      table -> aucun impact sur le comportement wiltOS.

      NE TOUCHE À RIEN d'autre : ni animations, ni combat, ni gameplay.
      Désactivable : convar « sang_wos_guard 0 ».
---------------------------------------------------------------------------]]

if not CLIENT then return end

local cv = CreateClientConVar("sang_wos_guard", "1", true, false)

hook.Add("PrePlayerDraw", "SangWOS_LightsabersGuard", function()
    if not cv:GetBool() then return end
    -- Uniquement si wiltOS est là mais que la table n'est pas (encore) synchro.
    if wOS and not (istable(wOS.Lightsabers) and istable(wOS.Lightsabers.General)) then
        wOS.Lightsabers = istable(wOS.Lightsabers) and wOS.Lightsabers or {}
        wOS.Lightsabers.General = wOS.Lightsabers.General or {}
    end
end)
