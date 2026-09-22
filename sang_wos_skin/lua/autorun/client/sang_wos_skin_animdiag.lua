--[[-------------------------------------------------------------------------
    Sang et Nuit — wiltOS Skin : DIAGNOSTIC ANIMATIONS
      Outil de debug (client). Tape « sang_wos_animdiag » dans ta console
      en TENANT le sabre ALLUMÉ. Il inspecte l'arme active et dit pourquoi
      l'animation wiltOS ne s'applique pas (quelle condition échoue).

      100% lecture seule, ne modifie rien.
---------------------------------------------------------------------------]]

if not CLIENT then return end

local function val(w, name)
    if type(w[name]) == "function" then
        local ok, v = pcall(function() return w[name](w) end)
        return ok and tostring(v) or ("ERREUR(" .. tostring(v) .. ")")
    end
    return "(méthode absente)"
end

concommand.Add("sang_wos_animdiag", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    MsgN("========== SANG WOS — DIAG ANIMATIONS ==========")
    MsgN("Modèle joueur : " .. ply:GetModel())

    local w = ply:GetActiveWeapon()
    if not IsValid(w) then MsgN("!! Aucune arme active."); return end

    MsgN("Arme active   : " .. w:GetClass())
    MsgN("SWEP.Base     : " .. tostring(w.Base))
    MsgN("IsLightsaber  : " .. tostring(w.IsLightsaber) .. "   <- doit être true")
    MsgN("GetEnabled    : " .. val(w, "GetEnabled") .. "   <- doit être true (sabre allumé)")
    MsgN("GetAnimEnabled: " .. val(w, "GetAnimEnabled") .. "   <- doit être true")
    MsgN("GetForm       : " .. val(w, "GetForm"))
    MsgN("GetStance     : " .. val(w, "GetStance"))
    MsgN("GetDualMode   : " .. val(w, "GetDualMode"))
    MsgN("GetMeditate   : " .. val(w, "GetMeditateMode"))

    MsgN("---- Globals wiltOS ----")
    MsgN("wOS          : " .. tostring(wOS ~= nil))
    MsgN("wOS.ALCS     : " .. tostring(wOS and wOS.ALCS ~= nil))
    MsgN("wOS.Form     : " .. tostring(wOS and wOS.Form ~= nil))

    if wOS and wOS.Form then
        local lf = wOS.Form.LocalizedForms
        local si = wOS.Form.Singles
        MsgN("  LocalizedForms : " .. (lf and ("table (" .. table.Count(lf) .. ")") or "nil"))
        MsgN("  Singles        : " .. (si and ("table (" .. table.Count(si) .. ")") or "nil"))

        if type(w.GetForm) == "function" then
            local okf, fid = pcall(function() return w:GetForm() end)
            if okf then
                local form = lf and lf[fid]
                MsgN("  Forme résolue  : " .. tostring(form) .. " (id " .. tostring(fid) .. ")")
                local st = 1
                if type(w.GetStance) == "function" then
                    local oks, sv = pcall(function() return w:GetStance() end)
                    if oks then st = sv end
                end
                local fdata = (form and si and si[form]) and si[form][st] or nil
                MsgN("  formdata[stance " .. tostring(st) .. "] : " .. tostring(fdata))
                if istable(fdata) then
                    local idleSeq = fdata["idle"]
                    MsgN("    idle seq name : " .. tostring(idleSeq))
                    if idleSeq then
                        MsgN("    LookupSequence(idle) : " .. tostring(ply:LookupSequence(idleSeq)) .. "   <- doit être > 0")
                    end
                end
            end
        end
    end

    MsgN("---- Hooks CalcMainActivity ----")
    local ht = hook.GetTable()["CalcMainActivity"]
    if ht then
        for name, _ in pairs(ht) do MsgN("  - " .. tostring(name)) end
    else
        MsgN("  (aucun !)")
    end
    MsgN("================================================")
    MsgN("Copie tout ce bloc et envoie-le.")
end)

MsgN("[sang_wos_skin] Diag prêt : tape 'sang_wos_animdiag' en tenant le sabre allumé.")
