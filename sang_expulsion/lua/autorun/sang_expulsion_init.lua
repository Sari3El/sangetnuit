--[[-------------------------------------------------------------------------
    Sang et Nuit — Expulsion (SWEP de coup + envol + téléportation)
      Le porteur frappe une cible (clic gauche). La cible :
        1) est étourdie ET invincible du début à la fin ;
        2) s'envole dans le ciel pendant quelques secondes (anim d'envol) ;
        3) est envoyée à une position fixe (SetPos/SetAngles) ;
        4) s'y relève (anim de relevé), puis reprend le contrôle.
      Les animations sont configurables : un NOMBRE = ACT id, une CHAÎNE = nom
      de séquence (LookupSequence). Réglable dans EXP.Config ci-dessous.
---------------------------------------------------------------------------]]

EXP = EXP or {}

----------------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------------
EXP.Config = {
    Range         = 300,        -- portée du coup (unités)
    Cooldown      = 3,          -- délai entre deux coups (porteur)

    -- Animations. Nombre => ACT id ; chaîne => nom de séquence.
    --   (valeurs de départ = ACT id de tes screenshots — ajuste si besoin)
    StrikeAnim    = 2264,       -- coup du FRAPPEUR (ALD_ANIMATION_175 / backfiststrike)
    FlyAnim       = 2183,       -- la CIBLE qui s'envole (ALD_ANIMATION_93 / "exit")
    GetupAnim     = 2061,       -- la CIBLE qui se relève à l'arrivée (ACT_MAD_1 / downendfu)

    -- Timing (secondes)
    StrikeDelay   = 0.20,       -- petit délai pour voir le coup avant l'envol
    FlyDuration   = 3.0,        -- durée de l'envol vers le ciel
    GetupDuration = 2.5,        -- durée du relevé à l'arrivée

    -- Envol
    SkyHeight     = 2200,       -- hauteur d'envol
    FlyAway       = 500,        -- distance horizontale (expulsion)

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

    -- Étourdissement : plus aucune action tant qu'on est expulsé.
    hook.Add("StartCommand", "SangExp_Stun", function(ply, cmd)
        if ply.SangExpelling then cmd:ClearButtons() cmd:ClearMovement() end
    end)

    -- Invincible tant qu'on est expulsé (joueurs ET pnj).
    hook.Add("EntityTakeDamage", "SangExp_Invuln", function(target)
        if IsValid(target) and target.SangExpelling then return true end
    end)

    -- Nettoyage si la cible meurt/déco/spawn en cours de route.
    hook.Add("PlayerSpawn", "SangExp_Clear", function(ply)
        if ply.SangExpelling then EXP.Finish(ply, true) end
    end)

    ------------------------------------------------------------------
    -- Fin : rend le contrôle et enlève l'invincibilité.
    ------------------------------------------------------------------
    function EXP.Finish(target, silent)
        if not IsValid(target) then return end
        target.SangExpelling = nil
        timer.Remove("SangExpFly_" .. target:EntIndex())
        EXP.SetAnim(target, nil)
        target:SetMoveType(target.SangExpOldMove or MOVETYPE_WALK)
        if target:IsPlayer() then target:GodDisable() end
        target.SangExpOldMove = nil
    end

    ------------------------------------------------------------------
    -- Arrivée : téléportation à la destination + anim de relevé.
    ------------------------------------------------------------------
    function EXP.Arrive(target)
        if not IsValid(target) then return end
        local C = EXP.Config
        timer.Remove("SangExpFly_" .. target:EntIndex())
        target:SetPos(C.DestPos)
        target:SetVelocity(vector_origin)
        if target:IsPlayer() then target:SetEyeAngles(Angle(0, C.DestAng.y, 0)) end
        EXP.SetAnim(target, C.GetupAnim)
        timer.Simple(C.GetupDuration, function()
            if IsValid(target) then EXP.Finish(target) end
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
            timer.Simple(0.7, function() if IsValid(attacker) then EXP.SetAnim(attacker, nil) end end)
            attacker:EmitSound(C.StrikeSound, 80, 100)
        end

        -- Point d'envol : au-dessus + expulsé loin du frappeur.
        local away = target:GetPos() - (IsValid(attacker) and attacker:GetPos() or target:GetPos())
        away.z = 0
        if away:LengthSqr() < 1 then away = IsValid(attacker) and attacker:GetForward() or Vector(1, 0, 0) end
        away:Normalize()
        local fromPos = target:GetPos()
        local skyPos  = fromPos + away * C.FlyAway + Vector(0, 0, C.SkyHeight)

        -- Après un court délai : anim d'envol + montée progressive.
        timer.Simple(C.StrikeDelay, function()
            if not IsValid(target) or not target.SangExpelling then return end
            EXP.SetAnim(target, C.FlyAnim)
            target:EmitSound(C.LaunchSound, 75, 90)
            local start = CurTime()
            local id = "SangExpFly_" .. target:EntIndex()
            timer.Create(id, 0, 0, function()
                if not IsValid(target) or not target.SangExpelling then timer.Remove(id) return end
                local t = (CurTime() - start) / C.FlyDuration
                if t >= 1 then EXP.Arrive(target) return end
                target:SetPos(LerpVector(t, fromPos, skyPos))
                target:SetVelocity(vector_origin)
            end)
        end)

        return true
    end
end
