--[[-------------------------------------------------------------------------
    Sang et Nuit — wiltOS Skin : GARDE-FOU anti-spam (synchro client wiltOS)

      Quand la synchro réseau wiltOS n'est pas (encore) arrivée côté client,
      certaines tables sont nil (wOS.Lightsabers, wOS.Form...) et des hooks
      d'origine de wiltOS plantent à CHAQUE frame -> des milliers d'erreurs :
        - PostPlayerDraw  "wOS.Lightsaber.HolsterDrawing"  (wOS.Lightsabers nil)
        - CalcMainActivity "wOS.ALCS.ClientAnimations"     (wOS.Form nil)

      Ici on « enveloppe » ces hooks : tant que la donnée n'est pas prête, on
      les SAUTE (pas de crash, comportement par défaut) ; dès qu'elle arrive,
      on appelle l'original TEL QUEL -> aucun changement de comportement wiltOS.
      Robuste au re-enregistrement et au chargement tardif du crypt (retries).

      NE TOUCHE À RIEN d'autre : ni animations, ni combat. Toggle : sang_wos_guard.
---------------------------------------------------------------------------]]

if not CLIENT then return end

local cv = CreateClientConVar("sang_wos_guard", "1", true, false)

-- « Prêt » = les tables que le hook d'origine va indexer existent bien.
local function lightsabersReady()
    return istable(wOS) and istable(wOS.Lightsabers) and istable(wOS.Lightsabers.General)
end
local function formReady()
    return istable(wOS) and istable(wOS.Form)
        and istable(wOS.Form.LocalizedForms)
        and istable(wOS.Form.Singles) and istable(wOS.Form.Duals)
end

local ourWrappers = {}

-- Enveloppe le hook (event/name) : si pas prêt -> on saute ; sinon -> original.
local function wrapHook(event, name, readyFn)
    local tbl = hook.GetTable()[event]
    local cur = tbl and tbl[name]
    if not cur then return end                    -- pas encore enregistré (crypt tardif)
    if ourWrappers[name] == cur then return end   -- déjà le nôtre en place
    local orig = cur                              -- (peut être une nouvelle version wiltOS)
    local wrapper = function(...)
        if cv:GetBool() and not readyFn() then return end
        return orig(...)
    end
    ourWrappers[name] = wrapper
    hook.Add(event, name, wrapper)
end

local function tryWrap()
    wrapHook("CalcMainActivity", "wOS.ALCS.ClientAnimations", formReady)
    wrapHook("PostPlayerDraw",   "wOS.Lightsaber.HolsterDrawing", lightsabersReady)
end

-- Le crypt wiltOS (déchiffrement réseau) peut enregistrer ses hooks BIEN
-- après le spawn — parfois au-delà de 45 s au 1er chargement. Un simple lot de
-- timer.Simple() peut donc rater la fenêtre. On installe un timer répétitif
-- permanent : tryWrap() est idempotent (ne ré-enveloppe que si nécessaire) et
-- son coût une fois stable = une lecture de table toutes les 3 s (négligeable).
-- Ça couvre aussi une éventuelle ré-inscription tardive du hook par wiltOS.
timer.Simple(2, tryWrap)
timer.Create("SangWOS_GuardWrap_Repeat", 3, 0, tryWrap)
hook.Add("InitPostEntity", "SangWOS_GuardWrap", function()
    for _, t in ipairs({ 1, 3, 6, 12, 20, 30, 45 }) do timer.Simple(t, tryWrap) end
end)

concommand.Add("sang_wos_guard_now", function()
    tryWrap()
    print("[sang_wos_skin] Garde-fou wiltOS (ré)appliqué.")
end)
