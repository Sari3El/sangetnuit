--[[-------------------------------------------------------------------------
    Relique Desmond — cœur (SWEP « Couronne de Lumière »)
      Gère l'animation forcée sur le porteur + les particules (couronne sur la
      tête, puis aura au sol), pilotées par l'état réseau du joueur.
      Visuel uniquement pour l'instant (effets de gameplay plus tard).
---------------------------------------------------------------------------]]

DESMOND = DESMOND or {}

DESMOND.Config = {
    -- Animation forcée sur l'utilisateur (état COURONNE). ACT id -1 => on
    -- utilise le NOM de séquence.
    Anim          = "susanoo_kingsroar",

    -- Particules (depuis particles/vampirepcf.pcf).
    ParticleFile  = "particles/vampirepcf.pcf",
    CrownParticle = "[8]_light_projectile",  -- sur la tête
    CrownScale    = 0.25,                    -- BEAUCOUP plus petit
    CrownAttach   = "eyes",                  -- attachement tête (sinon origine)
    AuraParticle  = "[8]_light_aura",        -- au sol, autour du joueur
    AuraScale     = 3.5,                     -- x3 à x4

    Cooldown      = 0.4,                      -- anti double-clic
}

-- Enregistre le .pcf.
if DESMOND.Config.ParticleFile and file.Exists(DESMOND.Config.ParticleFile, "GAME") then
    game.AddParticles(DESMOND.Config.ParticleFile)
    if SERVER then resource.AddFile(DESMOND.Config.ParticleFile) end
end

----------------------------------------------------------------------
-- Animation forcée (corps entier) via CalcMainActivity, avec résolveur
-- tolérant (ignore le suffixe « retarget », recherche par sous-chaîne).
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

hook.Add("CalcMainActivity", "Desmond_Anim", function(ply)
    local seq = ply:GetNWString("desmond_seq", "")
    if seq ~= "" then
        local id = ResolveSeq(ply, seq)
        if id and id >= 0 then return ACT_IDLE, id end
    end
end)

if SERVER then
    -- Nettoyage de l'état à la mort/au respawn.
    hook.Add("PlayerSpawn", "Desmond_Clear", function(ply)
        ply:SetNWInt("desmond_state", 0)
        ply:SetNWString("desmond_seq", "")
    end)
end

if CLIENT then
    local C = DESMOND.Config
    local handles = {} -- [ply] = { state, crown, aura }

    local function stopEff(e)
        if e and e.IsValid and e:IsValid() then e:StopEmissionAndDestroyImmediately() end
    end

    -- Crée une particule attachée au joueur, avec une échelle (control point 1).
    local function make(ply, name, attach, scale)
        if not name or name == "" then return nil end
        local patt, aid = PATTACH_ABSORIGIN_FOLLOW, 0
        if attach and attach ~= "" then
            local a = ply:LookupAttachment(attach)
            if a and a > 0 then patt, aid = PATTACH_POINT_FOLLOW, a end
        end
        local eff = CreateParticleSystem(ply, name, patt, aid)
        if eff then
            -- Convention courante : control point 1 = échelle du système.
            eff:SetControlPoint(1, Vector(scale, scale, scale))
        end
        return eff
    end

    local function sync(ply, h)
        local st = ply:GetNWInt("desmond_state", 0)
        if h.state == st then return end
        stopEff(h.crown) h.crown = nil
        stopEff(h.aura)  h.aura  = nil
        if st == 1 then
            h.crown = make(ply, C.CrownParticle, C.CrownAttach, C.CrownScale)
        elseif st == 2 then
            h.aura = make(ply, C.AuraParticle, nil, C.AuraScale)
        end
        h.state = st
    end

    hook.Add("Think", "Desmond_Particles", function()
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) then
                local h = handles[ply]
                if not h then h = { state = -1 } handles[ply] = h end
                sync(ply, h)
            end
        end
        for ply, h in pairs(handles) do
            if not IsValid(ply) then
                stopEff(h.crown) stopEff(h.aura)
                handles[ply] = nil
            end
        end
    end)
end
