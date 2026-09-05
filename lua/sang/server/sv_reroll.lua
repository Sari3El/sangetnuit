--[[-------------------------------------------------------------------------
    Sang et Nuit — Reroll payant & retour Humain gratuit

    Règles (cf. cahier des charges §5) :
      - Reroll = PAYANT. Vérifier >= 1 crédit, DÉBITER AVANT le tirage,
        puis tirer (serveur-side), puis appliquer.
      - Retour Humain = GRATUIT (ne coûte rien, ne rembourse rien).
      - Pas de remboursement (logique gacha).
      - Tout serveur-side, cooldown court anti-spam.
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}
local C = BLOOD.Config

-- Cooldown serveur partagé reroll/humain
local function onCooldown(ply)
    local now = CurTime()
    if ply.BloodNextRoll and now < ply.BloodNextRoll then return true end
    ply.BloodNextRoll = now + C.RerollCooldown
    return false
end

----------------------------------------------------------------------
-- Reroll payant
----------------------------------------------------------------------
net.Receive("blood_reroll", function(_, ply)
    if onCooldown(ply) then return end
    if not BLOOD.HasCharacter(ply) then
        BLOOD.Notify(ply, "Crée d'abord un personnage.", "error")
        return
    end

    local sid = ply:SteamID64()
    local credits = BLOOD.GetCredits(sid)

    -- Vérifier le solde
    if credits < C.RerollCost then
        BLOOD.Notify(ply, "Pas assez de crédits de reroll (" .. credits .. "/" .. C.RerollCost .. ").", "error")
        return
    end

    -- DÉBIT AVANT LE TIRAGE (anti-exploit)
    BLOOD.AddCredits(sid, -C.RerollCost)

    -- Tirage pondéré serveur-side
    local newRace = BLOOD.RollRace()
    BLOOD.SetRace(ply, ply.BloodActiveSlot or 1, newRace)

    -- Roulette côté joueur
    net.Start("blood_reroll_roll")
    net.WriteString(newRace)
    net.Send(ply)

    -- Annonce publique (différée pour ne pas spoiler la roulette)
    local plyName = ply:Nick()
    timer.Simple(BLOOD.Config.RerollAnnounceDelay or 4.6, function()
        net.Start("blood_reroll_announce")
        net.WriteString(plyName)
        net.WriteString(newRace)
        net.Broadcast()
    end)
end)

----------------------------------------------------------------------
-- Retour Humain gratuit
----------------------------------------------------------------------
net.Receive("blood_return_human", function(_, ply)
    if onCooldown(ply) then return end
    if not BLOOD.HasCharacter(ply) then
        BLOOD.Notify(ply, "Crée d'abord un personnage.", "error")
        return
    end
    BLOOD.SetRace(ply, ply.BloodActiveSlot or 1, "human")
    BLOOD.Notify(ply, "Retour en Humain (gratuit).", "info")
end)
