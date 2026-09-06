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

--- Prépare un sort. opts = { category, mana, cooldown, color, icon, whatToSay }
function SANGSPELL.PrepareSpell(Spell, opts)
    opts = opts or {}
    Spell.SangSort    = true
    Spell.AlwaysHave  = true              -- donné auto à tous les joueurs
    Spell.CreateEntity = false            -- pas de livre (nom accentué OK)
    Spell.LearnTime   = 0
    Spell.Category    = opts.category or "Magie Sacré"
    Spell.ForceDelay  = opts.cooldown or 5
    Spell.ManaCost    = opts.mana or 0
    if opts.color then Spell.SpriteColor = opts.color end
    if opts.whatToSay ~= nil then Spell.WhatToSay = opts.whatToSay end
    if opts.icon then Spell.IconMat = Material(opts.icon, "noclamp smooth") end
    if Spell.CanSelfCast == nil then Spell.CanSelfCast = false end

    -- Débit de la mana avant l'effet (serveur). Conserve un PreFire déjà défini.
    local userPre = rawget(Spell, "PreFire")
    function Spell:PreFire(wand)
        if SERVER then
            local ply = self.Owner
            if not IsValid(ply) then return false end
            local cost = self.ManaCost or 0
            if cost > 0 and BLOOD and BLOOD.TakeMana then
                if not BLOOD.TakeMana(ply, cost) then
                    if BLOOD.Notify then BLOOD.Notify(ply, "Pas assez de mana (" .. cost .. " requis).", "error")
                    else ply:ChatPrint("[Sang] Pas assez de mana.") end
                    return false
                end
            end
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
