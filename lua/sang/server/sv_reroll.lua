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
BLOOD.NetReceive("blood_reroll", 0.3, function(_, ply)
    -- Un reroll déjà en cours (animation) bloque tout nouveau spin.
    if ply.BloodRerolling and CurTime() < ply.BloodRerolling then return end
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
    local slot    = ply.BloodActiveSlot or 1
    local animT   = BLOOD.Config.RerollAnimTime or 4.2

    -- Marque le reroll comme "en cours" : bloque un nouveau spin le temps de l'anim.
    ply.BloodRerolling = CurTime() + animT

    -- Roulette côté joueur (la lignée n'est PAS encore appliquée).
    net.Start("blood_reroll_roll")
    net.WriteString(newRace)
    net.Send(ply)

    -- Application de la lignée UNIQUEMENT à la fin de l'animation.
    timer.Simple(animT, function()
        if not IsValid(ply) then return end
        ply.BloodRerolling = nil
        BLOOD.SetRace(ply, slot, newRace)
    end)

    -- Annonce publique (juste après la révélation).
    local plyName = ply:Nick()
    timer.Simple(BLOOD.Config.RerollAnnounceDelay or 4.6, function()
        net.Start("blood_reroll_announce")
        net.WriteString(plyName)
        net.WriteString(newRace)
        net.Broadcast()
    end)
end)
