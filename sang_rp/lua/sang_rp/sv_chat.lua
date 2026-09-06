--[[-------------------------------------------------------------------------
    Sang et Nuit — Chat RP (serveur)
      Le chat normal devient LOCAL (portée limitée). Commandes :
        /me <action>        -> action RP locale        (violet)
        /it <description>   -> description RP locale    (bleu, sans nom)
        /roll [XdY]         -> lancer de dés (défaut 1d100), local
        // <texte>  ou  /ooc <texte> -> OOC global
        /rphelp             -> rappel des commandes
      Les commandes admin (!origines...) et les autres "/xxx" passent normalement.
---------------------------------------------------------------------------]]

SRP = SRP or {}
local C = SRP.Config

----------------------------------------------------------------------
-- Envoi formaté
----------------------------------------------------------------------
local function send(targets, kind, name, text)
    if not targets or #targets == 0 then return end
    net.Start("sang_rp_msg")
        net.WriteString(kind)
        net.WriteString(name or "")
        net.WriteString(text or "")
    net.Send(targets)
end

local function nearby(ply, range)
    local out, pos = {}, ply:GetPos()
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and (p == ply or p:GetPos():Distance(pos) <= range) then
            out[#out + 1] = p
        end
    end
    return out
end

function SRP.SendLocal(ply, kind, text, range)
    text = string.sub(string.Trim(text or ""), 1, C.MaxLen)
    if text == "" then return end
    send(nearby(ply, range or C.RangeIC), kind, ply:Nick(), text)
end

function SRP.SendOOC(ply, text)
    text = string.sub(string.Trim(text or ""), 1, C.MaxLen)
    if text == "" then return end
    send(player.GetAll(), "ooc", ply:Nick(), text)
end

----------------------------------------------------------------------
-- Lancer de dés
----------------------------------------------------------------------
function SRP.Roll(ply, spec)
    local count, sides = 1, 100
    local c, s = string.match(spec or "", "^(%d*)[dD](%d+)$")
    if s then
        count = math.Clamp(tonumber(c) or 1, 1, 20)
        sides = math.Clamp(tonumber(s), 2, 1000)
    end
    local total, parts = 0, {}
    for _ = 1, count do
        local r = math.random(1, sides)
        total = total + r
        parts[#parts + 1] = tostring(r)
    end
    local detail = (count > 1) and ("  (" .. table.concat(parts, " + ") .. ")") or ""
    -- Format transporté : "1d100|57  (…)"
    send(nearby(ply, C.RangeRoll), "roll", ply:Nick(), count .. "d" .. sides .. "|" .. total .. detail)
end

----------------------------------------------------------------------
-- Interception du chat
----------------------------------------------------------------------
hook.Add("PlayerSay", "SRP_Chat", function(ply, text)
    if not IsValid(ply) then return end
    text = string.Trim(text or "")
    if text == "" then return "" end

    -- Commandes admin / mods : on laisse passer intégralement.
    if string.sub(text, 1, 1) == "!" then return end

    local low = string.lower(text)

    if C.EnableOOC and string.StartWith(text, "//") then
        SRP.SendOOC(ply, string.sub(text, 3))
        return ""
    end
    if C.EnableOOC and string.StartWith(low, "/ooc ") then
        SRP.SendOOC(ply, string.sub(text, 6))
        return ""
    end
    if string.StartWith(low, "/me ") then
        SRP.SendLocal(ply, "me", string.sub(text, 5), C.RangeMe)
        return ""
    end
    if string.StartWith(low, "/it ") then
        SRP.SendLocal(ply, "it", string.sub(text, 5), C.RangeMe)
        return ""
    end
    if low == "/roll" or string.StartWith(low, "/roll ") then
        SRP.Roll(ply, string.Trim(string.sub(text, 6)))
        return ""
    end
    if low == "/rphelp" then
        ply:ChatPrint("[RP]  /me <action>   ·   /it <description>   ·   /roll [1d100]   ·   // <OOC global>")
        return ""
    end

    -- Toute autre commande "/xxx" (ex: /origines) : on laisse passer.
    if string.sub(text, 1, 1) == "/" then return end

    -- Sinon : parole normale => chat IC LOCAL (portée limitée).
    SRP.SendLocal(ply, "ic", text, C.RangeIC)
    return ""
end)

MsgN("[Sang RP] Chat RP local + /me /it /roll prêts.")
