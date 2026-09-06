--[[-------------------------------------------------------------------------
    Sang et Nuit — Sorts : base commune
      Prépare un sort HPW avec :
        - coût en MANA (système Sang, débité dans PreFire) ;
        - COOLDOWN (ForceDelay) ;
        - donné automatiquement à tous (AlwaysHave), pas de livre à spawn
          (CreateEntity=false, ce qui autorise aussi les accents dans le nom) ;
        - marque SangSort (jamais masqué par cl_hide).
      + un helper de dégâts qui PASSE par le système de dégâts GMod, donc qui
        prend en compte les bonus de statistique (Force/Résistance de sang_niveau)
        et les défenses de race (réduction, feu, esquive...) automatiquement.
---------------------------------------------------------------------------]]

SANGSPELL = SANGSPELL or {}

----------------------------------------------------------------------
-- Enregistrement des packs de particules (.pcf) utilisés par nos sorts.
--   - fichiers explicites : SANGSPELL.Config.ParticleFiles
--   - auto-découverte : tous les particles/cruel_base*.pcf présents.
--   game.AddParticles doit être appelé avant PrecacheParticleSystem/usage.
----------------------------------------------------------------------
do
    local files = {}
    for _, f in ipairs((SANGSPELL.Config and SANGSPELL.Config.ParticleFiles) or {}) do files[f] = true end
    local found = file.Find("particles/cruel_base*.pcf", "GAME")
    if istable(found) then for _, v in ipairs(found) do files["particles/" .. v] = true end end
    for f in pairs(files) do
        if file.Exists(f, "GAME") then
            game.AddParticles(f)
            if SERVER then resource.AddFile(f) end
        end
    end
end

----------------------------------------------------------------------
-- Résolution + enregistrement d'un système de particule.
--   Beaucoup de packs nomment leurs systèmes « [N]_nom » (N = index).
--   On construit UNE FOIS un index { nom_système -> fichier.pcf } en lisant
--   tous les .pcf (le nom est stocké en clair dedans), puis :
--     - on résout la base « nom » vers le nom exact « [N]_nom » ;
--     - on ENREGISTRE le .pcf qui le contient (game.AddParticles) — sinon
--       la particule ne s'affiche pas même avec le bon nom.
--   Renvoie le nom exact (ou le nom tel quel si introuvable).
----------------------------------------------------------------------
do
    local index                 -- nom_système -> "particles/x.pcf"
    local registered = {}       -- fichiers déjà passés à game.AddParticles
    local resolveCache = {}

    -- Liste des .pcf à lire : les fichiers explicites de la config (chemins
    -- EXACTS, fiables même pour du contenu Workshop) + auto-découverte. On ne
    -- se fie PAS uniquement à file.Find (qui n'énumère pas toujours les .pcf
    -- montés depuis un GMA Workshop).
    local function candidateFiles()
        local set = {}
        for _, f in ipairs((SANGSPELL.Config and SANGSPELL.Config.ParticleFiles) or {}) do
            set[f] = true
        end
        for _, patt in ipairs({ "particles/cruel_base*.pcf", "particles/*.pcf" }) do
            local found = file.Find(patt, "GAME")
            if istable(found) then for _, v in ipairs(found) do set["particles/" .. v] = true end end
        end
        return set
    end

    local function buildIndex()
        index = {}
        for path in pairs(candidateFiles()) do
            if file.Exists(path, "GAME") then
                local data = file.Read(path, "GAME")
                if data then
                    -- Capture tous les noms « [N]_xxx » présents dans le fichier.
                    for nm in string.gmatch(data, "%[%d+%]_[%w_]+") do
                        if not index[nm] then index[nm] = path end
                    end
                end
            end
        end
    end

    local function register(path)
        if path and not registered[path] and file.Exists(path, "GAME") then
            game.AddParticles(path)
            if SERVER then resource.AddFile(path) end
            registered[path] = true
        end
    end
    SANGSPELL.RegisterParticleFile = register

    function SANGSPELL.ResolveParticle(name)
        if not name or name == "" then return name end
        if resolveCache[name] ~= nil then return resolveCache[name] end
        if not index then buildIndex() end

        local exact = name
        if not string.find(name, "^%[") then
            -- Base « nom » → cherche d'abord « [N]_nom » exact, sinon un nom
            -- qui CONTIENT « nom » (au cas où le préfixe ne serait pas [N]_).
            local want  = "^%[%d+%]_" .. string.PatternSafe(name) .. "$"
            local loose = string.PatternSafe(name)
            local fallback
            for k in pairs(index) do
                if string.match(k, want) then exact = k break end
                if not fallback and string.find(k, loose, 1, true) then fallback = k end
            end
            if exact == name and fallback then exact = fallback end
        end

        register(index[exact])          -- charge le .pcf qui le contient
        resolveCache[name] = exact
        return exact
    end

    -- Debug : liste les systèmes de particules indexés qui contiennent <filtre>.
    --   Console : sang_particles strange     (ou vide = tout)
    concommand.Add("sang_particles", function(ply, _, args)
        if not index then buildIndex() end
        local filt = string.lower(args[1] or "")
        local function out(msg) if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, msg) else print(msg) end end
        out("=== Particules indexées (" .. (CLIENT and "client" or "serveur") .. ") ===")
        local n = 0
        for k, path in pairs(index) do
            if filt == "" or string.find(string.lower(k), filt, 1, true) then
                out(("  %-40s  <- %s"):format(k, path))
                n = n + 1
            end
        end
        out("Total : " .. n .. (filt ~= "" and (" (filtre: " .. filt .. ")") or ""))
    end)
end

--- Prépare un sort. opts = { category, mana, cooldown, color, icon, whatToSay }
function SANGSPELL.PrepareSpell(Spell, opts)
    opts = opts or {}
    Spell.SangSort    = true
    Spell.AlwaysHave  = true              -- donné auto à tous les joueurs
    Spell.CreateEntity = false            -- pas de livre (nom accentué OK)
    Spell.LearnTime   = 0
    Spell.Category    = opts.category or "Magie Sacré"
    -- IMPORTANT : on N'UTILISE PAS ForceDelay de HPW car c'est un délai GLOBAL
    -- sur la baguette (il bloque TOUS les sorts). On gère un cooldown PAR SORT
    -- nous-mêmes (ci-dessous, dans PreFire). Il reste juste le petit délai
    -- d'animation de la baguette entre deux lancers.
    Spell.SangCooldown = opts.cooldown or 5
    Spell.ManaCost    = opts.mana or 0
    if opts.color then Spell.SpriteColor = opts.color end
    if opts.whatToSay ~= nil then Spell.WhatToSay = opts.whatToSay end
    if opts.icon then Spell.IconMat = Material(opts.icon, "noclamp smooth") end
    if Spell.CanSelfCast == nil then Spell.CanSelfCast = false end

    -- Gate avant l'effet (serveur) : cooldown PAR SORT puis débit de mana.
    -- Conserve un PreFire déjà défini par le sort.
    local userPre = rawget(Spell, "PreFire")
    function Spell:PreFire(wand)
        if SERVER then
            local ply = self.Owner
            if not IsValid(ply) then return false end

            -- 1) Cooldown propre à CE sort (n'affecte pas les autres sorts).
            ply.SangSpellCD = ply.SangSpellCD or {}
            local ready = ply.SangSpellCD[self.Name] or 0
            if CurTime() < ready then
                local left = math.max(1, math.ceil(ready - CurTime()))
                if BLOOD and BLOOD.Notify then
                    BLOOD.Notify(ply, (self.WhatToSay or self.Name) .. " en recharge (" .. left .. "s).", "error")
                else ply:ChatPrint("[Sang] Sort en recharge (" .. left .. "s).") end
                return false
            end

            -- 2) Mana (débitée seulement si pas en recharge).
            local cost = self.ManaCost or 0
            if cost > 0 and BLOOD and BLOOD.TakeMana then
                if not BLOOD.TakeMana(ply, cost) then
                    if BLOOD.Notify then BLOOD.Notify(ply, "Pas assez de mana (" .. cost .. " requis).", "error")
                    else ply:ChatPrint("[Sang] Pas assez de mana.") end
                    return false
                end
            end

            -- 3) Arme le cooldown de ce sort (le lancer va avoir lieu).
            --    Réduit par la Hâte (T1 Célérité) si active.
            local cd = (self.SangCooldown or 0) * (ply.SangHasteCD or 1)
            ply.SangSpellCD[self.Name] = CurTime() + cd
        end
        if userPre then return userPre(self, wand) end
        return true
    end

    return Spell
end

if SERVER then
    --- Inflige des dégâts EN PASSANT par le système GMod => les hooks de
    --  sang_niveau (Force/Résistance) et de race (réduction, feu, esquive)
    --  s'appliquent tout seuls. dmgtype par défaut = générique.
    function SANGSPELL.DealDamage(attacker, victim, dmg, dmgtype, inflictor)
        if not IsValid(victim) then return end
        if dmg <= 0 then return end
        local att = IsValid(attacker) and attacker or game.GetWorld()
        local inf = IsValid(inflictor) and inflictor or (IsValid(attacker) and attacker or game.GetWorld())

        local d = DamageInfo()
        d:SetDamage(dmg)
        d:SetAttacker(att)
        d:SetInflictor(inf)
        d:SetDamageType(dmgtype or DMG_GENERIC)
        d:SetDamagePosition(victim:WorldSpaceCenter())
        victim:TakeDamageInfo(d)
    end

    --- Soigne un joueur/PNJ sans dépasser ses PV max.
    function SANGSPELL.Heal(ent, amount)
        if not IsValid(ent) or amount <= 0 then return end
        local mx = ent.GetMaxHealth and ent:GetMaxHealth() or ent:Health()
        ent:SetHealth(math.min(mx, ent:Health() + amount))
    end

    --- Cibles vivantes (joueurs + PNJ) dans un rayon.
    function SANGSPELL.LivingInSphere(pos, radius, filter)
        local out = {}
        for _, e in ipairs(ents.FindInSphere(pos, radius)) do
            if IsValid(e) and (e:IsPlayer() or e:IsNPC()) and e:Health() > 0 then
                if not filter or filter(e) then out[#out + 1] = e end
            end
        end
        return out
    end

    ----------------------------------------------------------------------
    -- Type de dégâts « magique » (respecte la résistance magique de race).
    ----------------------------------------------------------------------
    SANGSPELL.MAGIC = DMG_SHOCK

    util.AddNetworkString("sang_blind") -- Nuée d'Ombres : assombrit l'écran

    --- Sacrifie des PV du lanceur (hémomancie). Renvoie false si trop bas.
    function SANGSPELL.SacrificeHP(ply, amount)
        if not IsValid(ply) or not ply:Alive() then return false end
        amount = math.floor(amount or 0)
        if amount <= 0 then return true end
        if ply:Health() <= amount then return false end -- ne se suicide pas
        ply:SetHealth(ply:Health() - amount)
        return true
    end

    ----------------------------------------------------------------------
    -- RALENTISSEMENT : réduit la vitesse d'une cible pendant `dur` s.
    --   Joueurs : on baisse walk/run puis on restaure. PNJ/objets : un timer
    --   bride la vitesse en la multipliant par `factor` à chaque tick.
    ----------------------------------------------------------------------
    function SANGSPELL.ApplySlow(ent, factor, dur)
        if not IsValid(ent) then return end
        factor = math.Clamp(factor or 0.5, 0.05, 1)
        dur = dur or 4
        local id = "SangSlow_" .. ent:EntIndex()

        if ent:IsPlayer() then
            if not ent.SangSlowBase then
                ent.SangSlowBase = { w = ent:GetWalkSpeed(), r = ent:GetRunSpeed() }
            end
            ent:SetWalkSpeed(math.max(1, math.Round(ent.SangSlowBase.w * factor)))
            ent:SetRunSpeed(math.max(1, math.Round(ent.SangSlowBase.r * factor)))
            timer.Create(id, dur, 1, function()
                if IsValid(ent) and ent.SangSlowBase then
                    ent:SetWalkSpeed(ent.SangSlowBase.w)
                    ent:SetRunSpeed(ent.SangSlowBase.r)
                    ent.SangSlowBase = nil
                end
            end)
        else
            local stop = CurTime() + dur
            timer.Create(id, 0.05, 0, function()
                if not IsValid(ent) or CurTime() >= stop then
                    if timer.Exists(id) then timer.Remove(id) end
                    return
                end
                ent:SetVelocity(ent:GetVelocity() * factor) -- bride la vitesse
            end)
        end
    end

    ----------------------------------------------------------------------
    -- IMMOBILISATION (root) : la cible ne peut plus se déplacer `dur` s.
    --   Pas d'invulnérabilité. Joueurs : Freeze + MOVETYPE_NONE. PNJ :
    --   MOVETYPE_NONE + NextThink repoussé (fige l'IA), restauré à la fin.
    ----------------------------------------------------------------------
    function SANGSPELL.Root(ent, dur)
        if not IsValid(ent) then return end
        dur = dur or 3
        local id = "SangRoot_" .. ent:EntIndex()

        if ent:IsPlayer() then
            local mv = ent:GetMoveType()
            ent:Freeze(true)
            ent:SetMoveType(MOVETYPE_NONE)
            timer.Create(id, dur, 1, function()
                if IsValid(ent) then ent:Freeze(false) ent:SetMoveType(mv or MOVETYPE_WALK) end
            end)
        elseif ent:IsNPC() then
            local mv = ent:GetMoveType()
            ent:SetMoveType(MOVETYPE_NONE)
            ent:NextThink(CurTime() + dur + 0.1)
            timer.Create(id, dur, 1, function()
                if IsValid(ent) then ent:SetMoveType(mv or MOVETYPE_STEP) ent:NextThink(CurTime()) end
            end)
        end
    end

    ----------------------------------------------------------------------
    -- STASE SUR SOI : le joueur est figé et (option) invulnérable `dur` s.
    ----------------------------------------------------------------------
    function SANGSPELL.SelfStasis(ply, dur, invuln)
        if not IsValid(ply) or not ply:IsPlayer() then return end
        dur = dur or 3
        local mv = ply:GetMoveType()
        ply:Freeze(true)
        ply:SetMoveType(MOVETYPE_NONE)
        if invuln then ply:GodEnable() end
        local id = "SangStasis_" .. ply:EntIndex()
        timer.Create(id, dur, 1, function()
            if IsValid(ply) then
                ply:Freeze(false)
                ply:SetMoveType(mv or MOVETYPE_WALK)
                if invuln then ply:GodDisable() end
            end
        end)
    end

    ----------------------------------------------------------------------
    -- REPOUSSE : éjecte joueurs/PNJ/objets autour de `pos` (force radiale).
    --   `exclude` = entité à ignorer (souvent le lanceur ou la cible).
    ----------------------------------------------------------------------
    function SANGSPELL.Repulse(pos, radius, force, exclude)
        force = force or 500
        for _, e in ipairs(ents.FindInSphere(pos, radius)) do
            if IsValid(e) and e ~= exclude and string.sub(e:GetClass(), 1, 5) ~= "sang_" then
                local dir = (e:WorldSpaceCenter() - pos)
                if dir:LengthSqr() < 1 then dir = VectorRand() end
                dir:Normalize()
                local push = dir * force + Vector(0, 0, force * 0.35)
                if e:IsPlayer() then
                    e:SetVelocity(push)
                elseif e:IsNPC() then
                    e:SetVelocity(push)
                else
                    local phys = e:GetPhysicsObject()
                    if IsValid(phys) then phys:ApplyForceCenter(push * phys:GetMass()) end
                end
            end
        end
    end
end
