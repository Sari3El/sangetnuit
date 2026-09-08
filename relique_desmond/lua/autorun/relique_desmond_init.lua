--[[-------------------------------------------------------------------------
    Relique Desmond — cœur (SWEP « Couronne de Lumière »)
      Gère l'animation (jouée UNE fois puis retour pose normale) + les
      particules (couronne sur la tête, puis aura au sol), pilotées par l'état
      réseau du joueur. Position ET échelle pilotées chaque frame.
      Visuel uniquement pour l'instant.
---------------------------------------------------------------------------]]

DESMOND = DESMOND or {}

DESMOND.Config = {
    Anim          = "susanoo_kingsroar",     -- jouée UNE fois au 1er clic

    ParticleFile  = "particles/vampirepcf.pcf",
    CrownParticle = "[8]_light_projectile",  -- sur la tête
    CrownScale    = 0.15,                    -- petit
    AuraParticle  = "[8]_light_aura",        -- au sol, sous le joueur
    AuraScale     = 4.0,                     -- x3 à x4
    AuraFollow    = false,                   -- false = reste au sol (là où tu étais), true = te suit

    Cooldown      = 0.4,
}

if DESMOND.Config.ParticleFile and file.Exists(DESMOND.Config.ParticleFile, "GAME") then
    game.AddParticles(DESMOND.Config.ParticleFile)
    if SERVER then resource.AddFile(DESMOND.Config.ParticleFile) end
end

----------------------------------------------------------------------
-- Résolveur de séquence tolérant (ignore « retarget », sous-chaîne).
----------------------------------------------------------------------
local seqCache = {}
local function ResolveSeq(ply, name)
    local key = ply:GetModel() .. "|" .. name
    local c = seqCache[key]
    if c ~= nil then return c end
    local id = ply:LookupSequence(name)
    if id < 0 then id = ply:LookupSequence(string.Trim(string.Replace(name, "retarget", ""))) end
    if id < 0 then
        local ln = string.lower(name)
        for i = 0, ply:GetSequenceCount() - 1 do
            if string.find(string.lower(ply:GetSequenceName(i)), ln, 1, true) then id = i break end
        end
    end
    seqCache[key] = id
    return id
end
DESMOND.ResolveSeq = ResolveSeq

-- Anim forcée seulement le temps d'UNE lecture (NWFloat = heure de fin).
hook.Add("CalcMainActivity", "Desmond_Anim", function(ply)
    local seq = ply:GetNWString("desmond_seq", "")
    if seq == "" then return end
    if ply:GetNWFloat("desmond_seq_end", 0) <= CurTime() then return end
    local id = ResolveSeq(ply, seq)
    if id and id >= 0 then return ACT_IDLE, id end
end)

if SERVER then
    -- Joue une anim UNE seule fois (durée = longueur de la séquence).
    function DESMOND.PlayAnimOnce(ply, name)
        if not IsValid(ply) or not name or name == "" then return end
        local id = ResolveSeq(ply, name)
        local dur = (id and id >= 0) and ply:SequenceDuration(id) or 2
        if not dur or dur <= 0 then dur = 2 end
        ply:SetNWString("desmond_seq", name)
        ply:SetNWFloat("desmond_seq_end", CurTime() + dur)
        timer.Create("DesmondAnim_" .. ply:EntIndex(), dur, 1, function()
            if IsValid(ply) then ply:SetNWString("desmond_seq", "") end
        end)
    end

    hook.Add("PlayerSpawn", "Desmond_Clear", function(ply)
        ply:SetNWInt("desmond_state", 0)
        ply:SetNWString("desmond_seq", "")
    end)
end

if CLIENT then
    -- Debug : liste les systèmes « [N]_nom » présents dans les .pcf (pour
    -- trouver une variante déjà plus petite/grande d'un effet).
    --   Console : desmond_listparticles light      (filtre sur "light")
    concommand.Add("desmond_listparticles", function(_, _, args)
        local filt = string.lower(args[1] or "")
        local seen, n = {}, 0
        for _, v in ipairs(file.Find("particles/*.pcf", "GAME") or {}) do
            local data = file.Read("particles/" .. v, "GAME")
            if data then
                for nm in string.gmatch(data, "%[%d+%]_[%w_]+") do
                    if not seen[nm] and (filt == "" or string.find(string.lower(nm), filt, 1, true)) then
                        seen[nm] = true
                        MsgN(("  %-40s  <- %s"):format(nm, v))
                        n = n + 1
                    end
                end
            end
        end
        MsgN("Total : " .. n .. (filt ~= "" and (" (filtre: " .. filt .. ")") or ""))
    end)

    local C = DESMOND.Config
    local fx = {} -- [ply] = { state, eff, kind, pos }

    local function stopEff(e)
        if e and e.IsValid and e:IsValid() then e:StopEmissionAndDestroyImmediately() end
    end

    -- Position « tête » (attachement eyes -> os tête -> yeux en secours).
    local function headPos(ply)
        local a = ply:LookupAttachment("eyes")
        if a and a > 0 then
            local at = ply:GetAttachment(a)
            if at then return at.Pos end
        end
        local b = ply:LookupBone("ValveBiped.Bip01_Head1")
        if b then local p = ply:GetBonePosition(b) if p then return p end end
        return ply:EyePos()
    end

    local function make(name, pos)
        if not name or name == "" then return nil end
        return CreateParticleSystemNoEntity(name, pos)
    end

    local function sync(ply, h)
        local st = ply:GetNWInt("desmond_state", 0)
        if h.state == st then return end
        stopEff(h.eff) h.eff = nil h.kind = nil
        if st == 1 then
            h.kind, h.pos = "crown", headPos(ply)
            h.eff = make(C.CrownParticle, h.pos)
        elseif st == 2 then
            h.kind, h.pos = "aura", ply:GetPos()
            h.eff = make(C.AuraParticle, h.pos)
        end
        h.state = st
    end

    hook.Add("Think", "Desmond_Particles", function()
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) then
                local h = fx[ply]
                if not h then h = { state = -1 } fx[ply] = h end
                sync(ply, h)

                if h.eff and h.eff:IsValid() then
                    -- Position pilotée chaque frame.
                    local pos
                    if h.kind == "crown" then
                        pos = headPos(ply)
                    elseif h.kind == "aura" then
                        pos = C.AuraFollow and ply:GetPos() or h.pos
                    end
                    if pos then h.eff:SetControlPoint(0, pos) end
                    -- Échelle ré-appliquée chaque frame (control points courants).
                    local s = (h.kind == "crown") and C.CrownScale or C.AuraScale
                    local v = Vector(s, s, s)
                    h.eff:SetControlPoint(1, v)
                    h.eff:SetControlPoint(2, v)
                end
            end
        end
        for ply, h in pairs(fx) do
            if not IsValid(ply) then stopEff(h.eff) fx[ply] = nil end
        end
    end)
end
