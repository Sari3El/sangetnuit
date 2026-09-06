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

    local function buildIndex()
        index = {}
        for _, v in ipairs(file.Find("particles/*.pcf", "GAME") or {}) do
            local path = "particles/" .. v
            local data = file.Read(path, "GAME")
            if data then
                -- Capture tous les noms « [N]_xxx » présents dans le fichier.
                for nm in string.gmatch(data, "%[%d+%]_[%w_]+") do
                    if not index[nm] then index[nm] = path end
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

    function SANGSPELL.ResolveParticle(name)
        if not name or name == "" then return name end
        if resolveCache[name] ~= nil then return resolveCache[name] end
        if not index then buildIndex() end

        local exact = name
        if not string.find(name, "^%[") then
            -- Base « nom » → cherche « [N]_nom » exact dans l'index.
            local want = "^%[%d+%]_" .. string.PatternSafe(name) .. "$"
            for k in pairs(index) do
                if string.match(k, want) then exact = k break end
            end
        end

        register(index[exact])          -- charge le .pcf qui le contient
        resolveCache[name] = exact
        return exact
    end
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
            ply.SangSpellCD[self.Name] = CurTime() + (self.SangCooldown or 0)
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
end
