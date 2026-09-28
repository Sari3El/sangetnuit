--[[-------------------------------------------------------------------------
    Sang et Nuit — Sabre : animation SERVEUR (côté client = relais)

      Le client relaie au serveur la séquence d'animation qu'il joue réellement
      pour SON joueur, uniquement quand wiltOS pose vraiment une animation de
      sabre (sabre allumé, ou frappe en cours via SeqOverride). Le serveur
      rejoue cette séquence -> la hitbox suit l'animation.

      Trafic réseau minimal : on n'envoie que sur CHANGEMENT de séquence, plus
      une resynchro ~10x/s UNIQUEMENT pendant une frappe (SeqOverride actif).
---------------------------------------------------------------------------]]

if not CLIENT then return end

local cv = CreateClientConVar("sang_saber_serveranim_relay", "1", true, false)

local lastSeq  = -2
local lastSend = 0
local INTERVAL = 0.1 -- resynchro du cycle pendant une frappe (10x/s)

-- wiltOS pose-t-il réellement une animation là, maintenant ?
local function forcing(ply, wep)
    if not IsValid(wep) or not wep.IsLightsaber then return false end
    if ply.SeqOverride and ply.SeqOverride >= 0 then return true end          -- frappe / séquence forcée
    if wep.GetEnabled and wep:GetEnabled() and wep.GetAnimEnabled
        and wep:GetAnimEnabled() then return true end                        -- sabre allumé -> pose de forme
    return false
end

local function send(seq, cycle, rate)
    net.Start("sang_saber_seq")
        net.WriteInt(seq, 16)
        net.WriteFloat(cycle or 0)
        net.WriteFloat(rate or 1)
    net.SendToServer()
end

hook.Add("Think", "SangSaberServerAnim_Relay", function()
    if not cv:GetBool() then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local wep = ply:GetActiveWeapon()
    local seq = forcing(ply, wep) and (ply:GetSequence() or -1) or -1
    local now = CurTime()
    local swinging = ply.SeqOverride and ply.SeqOverride >= 0

    if seq ~= lastSeq then
        -- changement de séquence : on envoie tout de suite (avec le cycle de départ)
        lastSeq = seq
        lastSend = now
        if seq >= 0 then send(seq, ply:GetCycle(), ply:GetPlaybackRate())
        else send(-1, 0, 1) end                                              -- fin -> le serveur relâche
    elseif seq >= 0 and swinging and (now - lastSend) >= INTERVAL then
        -- pendant une frappe : on resynchronise la progression
        lastSend = now
        send(seq, ply:GetCycle(), ply:GetPlaybackRate())
    end
end)
