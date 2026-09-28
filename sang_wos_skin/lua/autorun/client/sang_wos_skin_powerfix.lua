--[[-------------------------------------------------------------------------
    Sang et Nuit — wiltOS Skin : RÉPARATION des pouvoirs de Force (course synchro)

      Sur un sabre FIXE (UseSkills = false), wiltOS construit la liste des
      pouvoirs UNE SEULE FOIS, dans SWEP:Initialize(), à partir de
      wOS.AvailablePowers — une table remplie par SYNCHRO RÉSEAU
      (forcesys/cl_net.lua : "wOS.Lightsabers.SendAllForceData").

      Si le sabre s'initialise AVANT l'arrivée de cette synchro (fréquent sur
      ce serveur, cf. wOS.Form / wOS.Lightsabers nil), alors wep.ForcePowers
      reste VIDE -> aucun pouvoir en bas de l'écran, et le menu de Force
      (touche F / Alt+F) refuse de s'ouvrir (OpenForceMenu sort si 0 pouvoir).

      Un sabre PERSO (UseSkills = true) évite ça car le serveur lui renvoie ses
      pouvoirs via "wOS.SkillTree.RefreshWeapon" après la synchro.

      Ici on RECONSTRUIT wep.ForcePowers (et wep.Devestators) dès que les
      données wiltOS sont là mais que la liste construite est vide. On réutilise
      EXACTEMENT la logique de wiltOS (mêmes tables, même ordre) -> les index
      restent alignés avec le serveur, la sélection de pouvoir marche.

      On ne touche à AUCUN fichier wiltOS. Idempotent. Toggle : sang_wos_powerfix.
---------------------------------------------------------------------------]]

if not CLIENT then return end

local cv = CreateClientConVar("sang_wos_powerfix", "1", true, false)

local function count(t) return istable(t) and table.Count(t) or 0 end

-- Reconstruit les listes construites (ForcePowers / Devestators) d'un sabre si
-- elles sont vides alors que la source globale wiltOS est disponible.
local function healSaber(wep)
    if not cv:GetBool() then return end
    if not IsValid(wep) or not wep.IsLightsaber then return end

    -- Pouvoirs de Force
    if istable(wep.ForcePowerList) and #wep.ForcePowerList > 0
        and count(wep.ForcePowers) < 1
        and istable(wOS) and count(wOS.AvailablePowers) > 0 then

        wep.ForcePowers = {}
        wep.AvailablePowers = table.Copy(wOS.AvailablePowers)

        -- Même limite que wiltOS en mode HUD HYBRID (sinon aucune limite).
        local maxSlots
        if istable(wOS.ALCS) and istable(wOS.ALCS.Config) and istable(WOS_ALCS)
            and istable(WOS_ALCS.HUD)
            and wOS.ALCS.Config.LightsaberHUD == WOS_ALCS.HUD.HYBRID then
            maxSlots = wOS.ALCS.Config.MaximumForceSlots
        end

        for _, force in pairs(wep.ForcePowerList) do
            local p = wep.AvailablePowers[force]
            if p then
                wep.ForcePowers[#wep.ForcePowers + 1] = p
                if maxSlots and #wep.ForcePowers >= maxSlots then break end
            end
        end
    end

    -- Devastateurs (même course de synchro)
    if istable(wep.DevestatorList) and #wep.DevestatorList > 0
        and count(wep.Devestators) < 1
        and istable(wOS) and count(wOS.AvailableDevestators) > 0 then

        wep.Devestators = {}
        wep.AvailableDevestators = table.Copy(wOS.AvailableDevestators)
        for _, dev in pairs(wep.DevestatorList) do
            local d = wep.AvailableDevestators[dev]
            if d then wep.Devestators[#wep.Devestators + 1] = d end
        end
    end
end

local function tick()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) then healSaber(wep) end
end

-- À chaque init de sabre : on retente quelques fois (la synchro peut arriver
-- juste après). wiltOS appelle ce hook à la fin de SWEP:Initialize().
hook.Add("wOS.ALCS.Lightsaber.OnInitialize", "SangWOS_PowerHeal_Init", function(wep)
    for _, t in ipairs({ 0.5, 1, 2, 4, 8 }) do
        timer.Simple(t, function() healSaber(wep) end)
    end
end)

-- Filet permanent (léger) : répare l'arme active si besoin. Idempotent : une
-- fois les pouvoirs reconstruits, c'est un simple test toutes les 3 s.
timer.Create("SangWOS_PowerHeal_Repeat", 3, 0, tick)

concommand.Add("sang_wos_powerfix_now", function()
    tick()
    local wep = IsValid(LocalPlayer()) and LocalPlayer():GetActiveWeapon()
    if IsValid(wep) and wep.IsLightsaber then
        print(string.format(
            "[sang_wos_skin] %s : ForcePowers=%d / liste=%d | AvailablePowers(global)=%d | Devestators=%d",
            wep:GetClass(),
            count(wep.ForcePowers),
            istable(wep.ForcePowerList) and #wep.ForcePowerList or 0,
            count(wOS and wOS.AvailablePowers),
            count(wep.Devestators)))
    else
        print("[sang_wos_skin] Aucune arme sabre active.")
    end
end)
