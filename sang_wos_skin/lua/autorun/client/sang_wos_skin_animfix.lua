--[[-------------------------------------------------------------------------
    Sang et Nuit — wiltOS Skin : CORRECTIF ANIMATIONS (fallback)
      Certains modèles ont les anims wiltOS de BASE (idle_melee, walk_melee,
      run_melee, *_dual...) mais PAS le jeu Blade Symphony (phalanx_*).
      wiltOS, lui, essaie de jouer les séquences de la FORME (ex. phalanx_b_idle)
      -> LookupSequence = -1 -> il abandonne -> pose figée.

      Ici : quand le joueur tient un sabre wiltOS ALLUMÉ ET que le modèle n'a
      PAS les anims Blade Symphony, on force à la place les anims de BASE que le
      modèle POSSÈDE (posture de combat + marche/course/saut/accroupi).

      Gated : si le modèle a bien phalanx_b_idle (donc Blade Symphony), on ne
      touche à rien et on laisse wiltOS faire. Indépendant de wOS.Form (marche
      même si la synchro wiltOS déconne).

      Réglage : sang_wos_animfix 1/0
---------------------------------------------------------------------------]]

if not CLIENT then return end

SANGWOS = SANGWOS or {}
local cv = CreateClientConVar("sang_wos_animfix", "1", true, false)

-- Cache par modèle : le modèle a-t-il les anims Blade Symphony ? (évite de
-- relancer LookupSequence chaque frame)
local hasBSCache = {}
local function modelHasBladeSymphony(ply)
    local mdl = ply:GetModel() or ""
    local c = hasBSCache[mdl]
    if c ~= nil then return c end
    c = (ply:LookupSequence("phalanx_b_idle") or -1) > 0
    hasBSCache[mdl] = c
    return c
end

-- Cache LookupSequence par (modèle, nom).
local seqCache = {}
local function seqOf(ply, name)
    local key = (ply:GetModel() or "") .. "|" .. name
    local c = seqCache[key]
    if c ~= nil then return c end
    c = ply:LookupSequence(name) or -1
    seqCache[key] = c
    return c
end

-- Choisit le nom d'anim de base selon l'état du joueur.
local function baseAnimName(ply, vel, dual)
    local suffix = dual and "dual" or "melee"
    local moving = vel:Length2DSqr() > 0.25
    local crouch = ply:Crouching()
    local air    = not ply:IsOnGround()

    if air    then return "jump_" .. suffix end
    if crouch then return moving and ("cwalk_" .. suffix) or ("cidle_" .. suffix) end
    if moving then return "run_"  .. suffix end
    return "idle_" .. suffix
end

-- Résout un nom -> séquence en essayant des replis raisonnables.
local function resolve(ply, name, dual)
    local s = seqOf(ply, name)
    if s > 0 then return s end
    -- replis : run->walk, cidle->idle, cwalk->walk
    local alt = { run = "walk", cidle = "idle", cwalk = "walk" }
    for pre, rep in pairs(alt) do
        if string.StartWith(name, pre .. "_") then
            s = seqOf(ply, rep .. "_" .. (dual and "dual" or "melee"))
            if s > 0 then return s end
        end
    end
    -- ultime repli : idle
    s = seqOf(ply, dual and "idle_dual" or "idle_melee")
    return s
end

hook.Add("CalcMainActivity", "SangWOS_MeleeAnimFix", function(ply, vel)
    if not cv:GetBool() then return end
    if not IsValid(ply) then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or not wep.IsLightsaber then return end

    -- Uniquement sabre ALLUMÉ (comme wiltOS : posture de combat).
    if wep.GetEnabled and not wep:GetEnabled() then return end

    -- Si le modèle a Blade Symphony, wiltOS gère très bien -> on ne touche pas.
    if modelHasBladeSymphony(ply) then return end

    local dual = wep.GetDualMode and wep:GetDualMode() or false
    local seq  = resolve(ply, baseAnimName(ply, vel, dual), dual)
    if seq and seq > 0 then
        return -1, seq
    end
end)

-- Vide les caches au changement d'écran (rechargements) — sécurité.
hook.Add("OnScreenSizeChanged", "SangWOS_AnimFixFlush", function()
    hasBSCache = {}
    seqCache = {}
end)

concommand.Add("sang_wos_animfix_flush", function()
    hasBSCache = {}
    seqCache = {}
    print("[sang_wos_skin] Caches d'anim vidés.")
end)
