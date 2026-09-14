--[[-------------------------------------------------------------------------
    Sang et Nuit — Tickets : config partagée
---------------------------------------------------------------------------]]

SANGTICKET = SANGTICKET or {}

-- Raisons de ticket. « target = true » => nécessite une cible (joueur connecté).
SANGTICKET.Reasons = {
    { id = "bloque",   name = "Bloqué" },
    { id = "wl",       name = "Demande de WL" },
    { id = "question", name = "Question" },
    { id = "joueur",   name = "Contre un Joueur", target = true },
}

function SANGTICKET.ReasonName(id)
    for _, r in ipairs(SANGTICKET.Reasons) do
        if r.id == id then return r.name end
    end
    return id or "?"
end

function SANGTICKET.ReasonNeedsTarget(id)
    for _, r in ipairs(SANGTICKET.Reasons) do
        if r.id == id then return r.target == true end
    end
    return false
end
