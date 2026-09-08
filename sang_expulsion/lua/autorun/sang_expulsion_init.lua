--[[-------------------------------------------------------------------------
    Sang et Nuit — Expulsion (SWEP de coup + envol + PROJECTION)
      Le porteur frappe une cible (clic gauche). La cible :
        1) est étourdie ET invincible du début à la fin ;
        2) s'envole dans le ciel (anim d'envol) ;
        3) est PROJETÉE (pas téléportée) jusqu'à la position fixe, en volant
           (anim de relevé/chute pendant le trajet) ;
        4) arrive à la position, s'y relève, puis reprend le contrôle.

      Animations forcées via CalcMainActivity. Chaque anim est un « spec » :
        - une CHAÎNE  = nom de séquence (LookupSequence) — RECOMMANDÉ (fiable) ;
        - un NOMBRE   = ACT id (SelectWeightedSequence) — peut varier selon le
                        modèle, donc moins fiable.
      Pour trouver les bons noms sur TON modèle, en jeu (console) :
        sang_exp_listseq            -> liste toutes les séquences du modèle
        sang_exp_listseq down       -> filtre celles contenant "down"
        sang_exp_testanim <nom>     -> joue l'anim sur toi 4 s (pour tester)
---------------------------------------------------------------------------]]

EXP = EXP or {}

----------------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------------
EXP.Config = {
    Range         = 300,        -- portée du coup (unités)
    Cooldown      = 3,          -- délai entre deux coups (porteur)

    -- Animations (mets des NOMS de séquence — voir sang_exp_listseq).
    --   Ordre : 1) coup du frappeur  2) envol  3) apex/vol  4) relevé À LA POS.
    StrikeAnim    = "bee_attack_hand_backfiststrike",       -- 1) coup du FRAPPEUR
    FlyAnim       = "exit",                                 -- 2) CIBLE envoyée dans le ciel
    ApexAnim      = "mad_sukuna_as_cp_020_00_downfd_01",    -- 3) CIBLE au max / en vol
    GetupAnim     = "mad_sukuna_as_cp_020_00_downendfu_01", -- 4) CIBLE à la pos qui se relève

    -- Timing (secondes)
    StrikeDelay    = 0.20,      -- petit délai avant l'envol (voir le coup)
    FlyDuration    = 2.0,       -- montée vers le ciel
    ProjectDuration = 2.5,      -- vol du ciel jusqu'à la destination (projection)
    GetupDuration  = 2.0,       -- relevé une fois arrivé

    -- Envol
    SkyHeight     = 2200,       -- hauteur d'envol
    FlyAway       = 500,        -- distance horizontale (expulsion initiale)

    -- Destination (fournie)
    DestPos = Vector(-3226.402100, 1087.258667, -12735.968750),
    DestAng = Angle(4.576567, -175.543274, 3.856075),

    StrikeSound = "physics/body/body_medium_impact_hard5.wav",
    LaunchSound = "ambient/energy/whiteflash.wav",
}

----------------------------------------------------------------------
-- Animation forcée (corps entier) via CalcMainActivity.
--   NWString "sang_exp_seq" (nom de séquence) prioritaire, sinon NWInt
--   "sang_exp_act" (ACT id). Vide/-1 = animation normale.
----------------------------------------------------------------------
hook.Add("CalcMainActivity", "SangExp_Anim", function(ply, vel)
    local seq = ply:GetNWString("sang_exp_seq", "")
    if seq ~= "" then
        local id = ply:LookupSequence(seq)
        if id and id >= 0 then return ACT_IDLE, id end
    end
    local act = ply:GetNWInt("sang_exp_act", -1)
    if act and act >= 0 then
        local s = ply:SelectWeightedSequence(act)
        if s and s >= 0 then return act, s end
    end
end)

----------------------------------------------------------------------
-- Debug client : lister les séquences du modèle / tester une anim.
----------------------------------------------------------------------
if CLIENT then
    concommand.Add("sang_exp_listseq", function(ply, _, args)
        if not IsValid(ply) then return end
        local filt = string.lower(args[1] or "")
        MsgN("=== Séquences de " .. ply:GetModel() .. " ===")
        local n = 0
        for i = 0, ply:GetSequenceCount() - 1 do
            local name = ply:GetSequenceName(i)
            if filt == "" or string.find(string.lower(name), filt, 1, true) then
                MsgN(("  [%d] %s"):format(i, name))
                n = n + 1
            end
        end
        MsgN("Total : " .. n .. (filt ~= "" and (" (filtre: " .. filt .. ")") or ""))
    end)
end

if SERVER then
    util.PrecacheSound(EXP.Config.StrikeSound)

    --- Force une animation (spec = nombre ACT id, chaîne nom de séquence, ou nil).
    function EXP.SetAnim(ent, spec)
        if not IsValid(ent) then return end
        if isstring(spec) then
            ent:SetNWString("sang_exp_seq", spec)
            ent:SetNWInt("sang_exp_act", -1)
        elseif isnumber(spec) then
            ent:SetNWString("sang_exp_seq", "")
            ent:SetNWInt("sang_exp_act", spec)
        else
            ent:SetNWString("sang_exp_seq", "")
            ent:SetNWInt("sang_exp_act", -1)
        end
    end

    -- Test : force une anim sur soi 4 s (console : sang_exp_testanim <nom|actid>)
    concommand.Add("sang_exp_testanim", function(ply, _, args)
        if not IsValid(ply) then return end
        local a = args[1]
        if not a then ply:ChatPrint("[Expulsion] Usage: sang_exp_testanim <nom_de_sequence|act_id>") return end
        EXP.SetAnim(ply, tonumber(a) or a)
        timer.Simple(4, function() if IsValid(ply) then EXP.SetAnim(ply, nil) end end)
        ply:ChatPrint("[Expulsion] Test anim: " .. a .. " (4 s)")
    end)

    -- Étourdissement : plus aucune action tant qu'on est expulsé.
    hook.Add("StartCommand", "SangExp_Stun", function(ply, cmd)
        if ply.SangExpelling then cmd:ClearButtons() cmd:ClearMovement() end
    end)

    -- Invincible tant qu'on est expulsé (joueurs ET pnj).
    hook.Add("EntityTakeDamage", "SangExp_Invuln", function(target)
        if IsValid(target) and target.SangExpelling then return true end
    end)

    -- Nettoyage si la cible respawn en cours de route.
    hook.Add("PlayerSpawn", "SangExp_Clear", function(ply)
        if ply.SangExpelling then EXP.Finish(ply) end
    end)

    local function fid(t) return "SangExpMove_" .. t:EntIndex() end

    ------------------------------------------------------------------
    -- Fin : rend le contrôle et enlève l'invincibilité.
    ------------------------------------------------------------------
    function EXP.Finish(target)
        if not IsValid(target) then return end
        target.SangExpelling = nil
        timer.Remove(fid(target))
        EXP.SetAnim(target, nil)
        target:SetMoveType(target.SangExpOldMove or MOVETYPE_WALK)
        if target:IsPlayer() then target:GodDisable() end
        target.SangExpOldMove = nil
    end

    -- Déplace la cible de `a` vers `b` en `dur` s, puis appelle onDone().
    local function travel(target, a, b, dur, onDone)
        local start = CurTime()
        timer.Create(fid(target), 0, 0, function()
            if not IsValid(target) or not target.SangExpelling then timer.Remove(fid(target)) return end
            local t = (CurTime() - start) / dur
            if t >= 1 then
                timer.Remove(fid(target))
                target:SetPos(b)
                target:SetVelocity(vector_origin)
                if onDone then onDone() end
                return
            end
            target:SetPos(LerpVector(t, a, b))
            target:SetVelocity(vector_origin)
        end)
    end

    ------------------------------------------------------------------
    -- Coup : lance toute la séquence sur `target`.
    ------------------------------------------------------------------
    function EXP.Expel(attacker, target)
        if not (IsValid(target) and (target:IsPlayer() or target:IsNPC())) then return false end
        if target.SangExpelling then return false end
        local C = EXP.Config

        target.SangExpelling  = true
        target.SangExpOldMove = target:GetMoveType()
        target:SetMoveType(MOVETYPE_NONE)
        if target:IsPlayer() then target:GodEnable() end

        -- Anim + son du frappeur
        if IsValid(attacker) then
            EXP.SetAnim(attacker, C.StrikeAnim)
            timer.Simple(0.8, function() if IsValid(attacker) then EXP.SetAnim(attacker, nil) end end)
            attacker:EmitSound(C.StrikeSound, 80, 100)
        end

        -- Point d'envol : au-dessus + expulsé loin du frappeur.
        local away = target:GetPos() - (IsValid(attacker) and attacker:GetPos() or target:GetPos())
        away.z = 0
        if away:LengthSqr() < 1 then away = IsValid(attacker) and attacker:GetForward() or Vector(1, 0, 0) end
        away:Normalize()
        local fromPos = target:GetPos()
        local skyPos  = fromPos + away * C.FlyAway + Vector(0, 0, C.SkyHeight)

        timer.Simple(C.StrikeDelay, function()
            if not IsValid(target) or not target.SangExpelling then return end
            -- Phase 1 : envol vers le ciel.
            EXP.SetAnim(target, C.FlyAnim)
            target:EmitSound(C.LaunchSound, 75, 90)
            travel(target, fromPos, skyPos, C.FlyDuration, function()
                if not IsValid(target) or not target.SangExpelling then return end
                -- Phase 3 : PROJECTION du ciel jusqu'à la destination (anim d'apex/vol).
                EXP.SetAnim(target, C.ApexAnim)
                travel(target, skyPos, C.DestPos, C.ProjectDuration, function()
                    if not IsValid(target) then return end
                    -- Phase 4 : ARRIVÉE à la pos -> relevé (uniquement ici), puis fin.
                    if target:IsPlayer() then target:SetEyeAngles(Angle(0, C.DestAng.y, 0)) end
                    EXP.SetAnim(target, C.GetupAnim)
                    timer.Simple(C.GetupDuration, function()
                        if IsValid(target) then EXP.Finish(target) end
                    end)
                end)
            end)
        end)

        return true
    end
end
