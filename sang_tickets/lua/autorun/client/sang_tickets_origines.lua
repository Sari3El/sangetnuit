--[[-------------------------------------------------------------------------
    Sang et Nuit — Tickets : section « Notes & stats staff » dans Origines
      (Gestion Serveur). Affiche par staff : nb de tickets + moyenne des notes,
      et la liste des derniers tickets.
---------------------------------------------------------------------------]]

if not CLIENT then return end

SANGTICKET = SANGTICKET or {}
BLOOD = BLOOD or {}
BLOOD.Origines = BLOOD.Origines or { playerSections = {}, serverSections = {} }
-- Inscription idempotente par id (dédoublonne même si le cœur n'est pas encore
-- chargé au moment de l'appel, ou si un fichier est chargé deux fois).
local function addServer(fn, id)
    if BLOOD.Origines.AddServerSection then return BLOOD.Origines.AddServerSection(fn, id) end
    BLOOD.Origines.serverSections = BLOOD.Origines.serverSections or {}
    BLOOD.Origines._serverIds = BLOOD.Origines._serverIds or {}
    local ids = BLOOD.Origines._serverIds
    if id and ids[id] then BLOOD.Origines.serverSections[ids[id]] = fn return end
    table.insert(BLOOD.Origines.serverSections, fn)
    if id then ids[id] = #BLOOD.Origines.serverSections end
end

local statsData, logsData = {}, {}

net.Receive("sang_ticket_logs", function()
    local ns = net.ReadUInt(16); statsData = {}
    for i = 1, ns do
        statsData[i] = { name = net.ReadString(), total = net.ReadUInt(16),
                         rated = net.ReadUInt(16), avg = net.ReadFloat() }
    end
    local nl = net.ReadUInt(16); logsData = {}
    for i = 1, nl do
        logsData[i] = { id = net.ReadUInt(16), req = net.ReadString(),
                        reason = net.ReadString(), staff = net.ReadString(), rating = net.ReadInt(8) }
    end
    if SANGTICKET._refreshLogs then SANGTICKET._refreshLogs() end
end)

addServer(function(p)
    local UI, C, S = BLOOD.UI, BLOOD.UI.Col, BLOOD.UI.Scale
    BLOOD.Origines.SectionLabel(p, "Tickets — notes & stats du staff")

    local refresh = vgui.Create("DButton", p)
    refresh:Dock(TOP) refresh:SetTall(S(28)) refresh:SetText("Rafraîchir")
    UI.SkinButton(refresh, "gold")
    refresh.DoClick = function() net.Start("sang_ticket_reqlogs") net.SendToServer() end

    local box = vgui.Create("DScrollPanel", p)
    box:Dock(TOP) box:SetTall(S(320)) box:DockMargin(0, S(6), 0, 0)

    local function line(parent, text, col, font, tall)
        local l = vgui.Create("DLabel", parent)
        l:Dock(TOP) l:DockMargin(0, 0, 0, S(2)) l:SetTall(tall or S(20))
        l:SetFont(font or "SangUI_Small") l:SetTextColor(col or C.txt) l:SetText(text)
        return l
    end

    SANGTICKET._refreshLogs = function()
        if not IsValid(box) then return end
        box:Clear()

        line(box, "Staff", C.goldLt, "SangUI_Body", S(24))
        if #statsData == 0 then line(box, "(aucune donnée)", C.txtDim) end
        for _, s in ipairs(statsData) do
            local moy = s.rated > 0 and string.format("%.2f ★ (%d notés)", s.avg, s.rated) or "pas encore noté"
            line(box, s.name .. "  —  " .. s.total .. " ticket(s)  ·  " .. moy, C.txt)
        end

        line(box, "Derniers tickets", C.goldLt, "SangUI_Body", S(28))
        for _, l in ipairs(logsData) do
            local note = (l.rating and l.rating >= 1) and (l.rating .. " ★") or "—"
            line(box, "#" .. l.id .. "  " .. l.req .. "  ·  " .. l.reason ..
                "  ·  " .. l.staff .. "  ·  " .. note, C.txtDim)
        end
    end
    SANGTICKET._refreshLogs()

    net.Start("sang_ticket_reqlogs") net.SendToServer() -- charge à l'ouverture
end, "tickets_logs")
