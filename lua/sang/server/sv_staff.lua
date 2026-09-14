--[[-------------------------------------------------------------------------
    Sang et Nuit — Actions STAFF du scoreboard (TAB)
      Reçoit les actions déclenchées depuis le panneau joueur du scoreboard.
      Sécurité : BLOOD.IsAdmin vérifié SERVEUR-SIDE à CHAQUE action + log.
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}

util.AddNetworkString("sang_staff")

----------------------------------------------------------------------
-- Table des actions : action = function(admin, target, num, text)
----------------------------------------------------------------------
local ACTIONS = {
    noclip = function(_, t)
        t:SetMoveType(t:GetMoveType() == MOVETYPE_NOCLIP and MOVETYPE_WALK or MOVETYPE_NOCLIP)
    end,
    god = function(_, t)
        if t:HasGodMode() then t:GodDisable() else t:GodEnable() end
    end,
    freeze = function(_, t)
        t.SangStaffFrozen = not t.SangStaffFrozen
        t:Freeze(t.SangStaffFrozen)
    end,
    ignite     = function(_, t) t:Ignite(15) end,
    extinguish = function(_, t) t:Extinguish() end,
    strip      = function(_, t) t:StripWeapons() end,
    slay       = function(_, t) if t:Alive() then t:Kill() end end,
    respawn    = function(_, t) t:Spawn() end,

    sethp    = function(_, t, n) t:SetHealth(math.Clamp(n, 1, 100000)) end,
    setarmor = function(_, t, n) t:SetArmor(math.Clamp(n, 0, 100000)) end,
    setcovan = function(_, t, n)
        if BLOOD.SetCovan then BLOOD.SetCovan(t, math.Clamp(n, 0, 1000000000)) end
    end,

    bring = function(a, t) t:SetPos(a:GetPos() + a:GetForward() * 60 + Vector(0, 0, 8)) end,
    goto  = function(a, t) a:SetPos(t:GetPos() + t:GetForward() * 60 + Vector(0, 0, 8)) end,

    -- Donner une arme (classe SWEP), ex: weapon_pistol, weapon_crowbar...
    giveitem = function(_, t, _, txt)
        txt = string.Trim(txt or "")
        if txt == "" then return end
        t:Give(txt)
        t:SelectWeapon(txt)
    end,
    -- Donner de l'or (Covan) — ajoute au solde (setcovan, lui, fixe la valeur).
    addcovan = function(_, t, n)
        if BLOOD.AddCovan then BLOOD.AddCovan(t, math.Clamp(n, -1000000000, 1000000000)) end
    end,
    -- Changer le job (id envoyé en texte : sansfaction / humanite / monstre...).
    setjob = function(_, t, _, txt)
        txt = string.Trim(txt or "")
        if SJOB and SJOB.SetJob and SJOB.JobExists and SJOB.JobExists(txt) then
            SJOB.SetJob(t, txt, true)
        end
    end,
    -- Invisible (cloak) : rend le joueur transparent (toggle).
    cloak = function(_, t)
        t.SangCloaked = not t.SangCloaked
        if t.SangCloaked then
            t:SetRenderMode(RENDERMODE_TRANSALPHA)
            t:SetColor(Color(255, 255, 255, 0))
            t:DrawShadow(false)
        else
            t:SetRenderMode(RENDERMODE_NORMAL)
            t:SetColor(Color(255, 255, 255, 255))
            t:DrawShadow(true)
        end
    end,

    kick = function(_, t, _, txt)
        t:Kick(txt ~= "" and txt or "Expulsé par un membre du staff")
    end,
    ban = function(_, t, n, txt)
        local sid = t:SteamID64()
        t:Ban(math.max(0, n), true)
        BLOOD.LogAdmin("BAN " .. sid .. " (" .. n .. " min) : " .. (txt or ""))
    end,
}

----------------------------------------------------------------------
-- Réception
----------------------------------------------------------------------
net.Receive("sang_staff", function(_, admin)
    if not (IsValid(admin) and BLOOD.IsAdmin and BLOOD.IsAdmin(admin)) then return end

    local action = net.ReadString()
    local sid    = net.ReadString()
    local num    = net.ReadInt(32)
    local text   = string.sub(net.ReadString() or "", 1, 200)

    local fn = ACTIONS[action]
    if not fn then return end

    local target = BLOOD.GetPlayerBySteamID64(sid)
    if not IsValid(target) or not target:IsPlayer() then return end

    fn(admin, target, num, text)

    if BLOOD.LogAdmin then
        BLOOD.LogAdmin(admin:Nick() .. " (" .. admin:SteamID64() .. ") -> " .. action ..
            " sur " .. target:Nick() .. " (" .. sid .. ")" ..
            (num ~= 0 and (" [" .. num .. "]") or "") ..
            (text ~= "" and (" \"" .. text .. "\"") or ""))
    end
    -- Retour visible dans le tchat des SUPER ADMINS uniquement.
    if BLOOD.StaffNotify then
        BLOOD.StaffNotify(admin:Nick() .. " → " .. action .. " sur " .. target:Nick() ..
            (num ~= 0 and (" [" .. num .. "]") or "") .. (text ~= "" and (" « " .. text .. " »") or ""))
    end
end)
