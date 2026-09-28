--[[-------------------------------------------------------------------------
    Sang et Nuit — wiltOS Skin : DÉBLOCAGE d'animation d'attaque (retour idle)

      wiltOS force la pose d'une frappe via ply.SeqOverride (cl_forcesequence.lua):
      tant que SeqOverride >= 0, cette séquence écrase TOUT (idle, marche...).

      Or wiltOS ne remet JAMAIS SeqOverride à -1 côté client : il attend un
      message réseau du SERVEUR (fin du "stun"/lock d'attaque) pour le reset.
      Si ce reset n'arrive pas — typiquement quand on a DÉSACTIVÉ le stun
      d'attaque — la pose de frappe reste FIGÉE (pas de retour à l'idle).

      Filet côté client : une fois la séquence d'attaque entièrement jouée
      (sa durée réelle écoulée), on rend la main à l'idle en remettant
      SeqOverride à -1. Aucune régénération du sabre nécessaire, aucun fichier
      wiltOS modifié. S'applique à tous les joueurs visibles (cohérence).

      Si un jour tu remets un vrai reset serveur, ce filet devient un no-op
      (SeqOverride déjà à -1). Toggle : sang_wos_unstick. Marge : sang_wos_unstick_margin.
---------------------------------------------------------------------------]]

if not CLIENT then return end

local cv     = CreateClientConVar("sang_wos_unstick", "1", true, false)
local cvMarg = CreateClientConVar("sang_wos_unstick_margin", "0.15", true, false)

-- Suivi par joueur du début de la séquence forcée courante. Clés faibles :
-- un joueur qui se déconnecte est nettoyé automatiquement par le GC.
local track = setmetatable({}, { __mode = "k" })

hook.Add("Think", "SangWOS_UnstickAttackAnim", function()
    if not cv:GetBool() then return end
    local margin = math.max(0, cvMarg:GetFloat())

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            local so = ply.SeqOverride
            if not so or so < 0 then
                track[ply] = nil
            else
                local t = track[ply]
                if not t or t.seq ~= so then
                    -- Nouvelle séquence forcée : on note l'instant de départ.
                    track[ply] = { seq = so, start = CurTime() }
                else
                    local dur  = ply:SequenceDuration(so) or 0
                    local rate = ply.SeqOverrideRate or 1
                    if rate <= 0 then rate = 1 end
                    -- Séquence entièrement jouée (durée / vitesse) + marge -> idle.
                    if dur > 0 and (CurTime() - t.start) > (dur / rate) + margin then
                        ply.SeqOverride     = -1
                        ply.SeqOverrideRate = nil
                        track[ply]          = nil
                    end
                end
            end
        end
    end
end)

concommand.Add("sang_wos_unstick_now", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    ply.SeqOverride     = -1
    ply.SeqOverrideRate = nil
    print("[sang_wos_skin] Pose d'attaque débloquée (retour à l'idle forcé).")
end)
