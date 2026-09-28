--[[-------------------------------------------------------------------------
    Sang et Nuit — Sabre : animation SERVEUR (la hitbox suit l'animation)

      PROBLÈME wiltOS : l'animation du sabre (formes + frappes) est appliquée
      UNIQUEMENT côté client (hook CalcMainActivity dans un fichier cl_, et
      ply.SeqOverride posé par le net "wOS.ALCS.RecievePlayerSeq" côté client).
      Le SERVEUR, lui, garde le perso en pose par défaut. Or le trace des dégâts
      du sabre est calculé CÔTÉ SERVEUR à partir de l'os de la main
      (ValveBiped.Bip01_R_Hand) -> la lame reste « droite » -> la hitbox ne suit
      pas l'animation visible.

      SOLUTION : chaque client relaie la séquence qu'il joue réellement ; le
      serveur rejoue cette même séquence sur le joueur (CalcMainActivity serveur)
      -> l'os de la main bouge côté serveur -> le trace suit l'animation.

      Ne modifie AUCUN fichier wiltOS. Toggle : sang_saber_serveranim.
      Le modèle doit posséder les séquences (c'est déjà le cas si tu les vois
      côté client) ; sinon le serveur ne peut pas les jouer (mais aucun crash).
---------------------------------------------------------------------------]]

if not SERVER then return end

util.AddNetworkString("sang_saber_seq")

local cv = CreateConVar("sang_saber_serveranim", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY },
    "1 = rejoue l'animation du sabre cote serveur pour que la hitbox suive l'animation")

-- Réception de la séquence relayée par le client (sa propre animation).
net.Receive("sang_saber_seq", function(_, ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    local seq   = net.ReadInt(16)
    local cycle = net.ReadFloat()
    local rate  = net.ReadFloat()
    if seq and seq >= 0 then
        ply.SangSaberSeq  = seq
        ply.SangSaberRate = (rate and rate > 0) and rate or 1
        -- Resynchronise la progression de l'animation avec le client.
        ply:SetCycle(cycle or 0)
        ply:SetPlaybackRate(ply.SangSaberRate)
    else
        ply.SangSaberSeq  = nil
        ply.SangSaberRate = nil
    end
end)

-- Pose la séquence relayée CÔTÉ SERVEUR -> les os (donc la lame) bougent.
hook.Add("CalcMainActivity", "SangSaberServerAnim", function(ply, vel)
    if not cv:GetBool() then return end
    if not IsValid(ply) then return end
    local seq = ply.SangSaberSeq
    if not seq or seq < 0 then return end
    if ply:InVehicle() or not ply:Alive() then return end
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or not wep.IsLightsaber then return end
    return -1, seq
end)

-- Maintient la vitesse de lecture côté serveur (sinon l'anim se rejoue à 1.0).
hook.Add("UpdateAnimation", "SangSaberServerAnimRate", function(ply, vel, maxseq)
    if not cv:GetBool() then return end
    if not IsValid(ply) or not ply.SangSaberSeq then return end
    if ply.SangSaberRate then ply:SetPlaybackRate(ply.SangSaberRate) end
end)

-- Nettoyage
hook.Add("PlayerDeath", "SangSaberServerAnim_Clear", function(ply)
    ply.SangSaberSeq = nil ply.SangSaberRate = nil
end)
