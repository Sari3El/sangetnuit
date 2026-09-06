--[[-------------------------------------------------------------------------
    Sang et Nuit — Chat RP (client) : rendu coloré des messages
---------------------------------------------------------------------------]]

SRP = SRP or {}

local col = {
    ic    = Color(224, 214, 188),  -- parole (parchemin clair)
    name  = Color(210, 176, 108),  -- nom (or)
    me    = Color(196, 132, 232),  -- /me (violet)
    it    = Color(150, 185, 214),  -- /it (bleu)
    roll  = Color(255, 170, 60),   -- /roll (orange)
    ooc   = Color(140, 150, 160),  -- OOC (gris)
    dim   = Color(120, 110, 92),
}

net.Receive("sang_rp_msg", function()
    local kind = net.ReadString()
    local name = net.ReadString()
    local text = net.ReadString()

    if kind == "ic" then
        chat.AddText(col.name, name, col.dim, " : ", col.ic, text)
    elseif kind == "me" then
        chat.AddText(col.me, "✦ " .. name .. " " .. text)
    elseif kind == "it" then
        chat.AddText(col.it, "✦ " .. text)
    elseif kind == "roll" then
        local spec, res = string.match(text, "^([^|]*)|(.*)$")
        chat.AddText(col.roll, "🎲 ", col.name, name, col.roll,
            " lance " .. (spec or "") .. " : ", color_white, tostring(res or ""))
    elseif kind == "ooc" then
        chat.AddText(col.ooc, "(OOC) ", col.name, name, col.ooc, " : " .. text)
    end
end)

-- Rappel discret des commandes à la première ouverture du chat.
local shown = false
hook.Add("StartChat", "SRP_Hint", function()
    if shown then return end
    shown = true
    chat.AddText(Color(176, 141, 74), "[RP] ", Color(146, 130, 100),
        "/me action  ·  /it description  ·  /roll 1d100  ·  // OOC")
end)
