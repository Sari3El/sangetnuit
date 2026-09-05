--[[-------------------------------------------------------------------------
    Sang et Nuit — Index des races (partagé)
    Construit des tables pratiques à partir de BLOOD.Config.Races et valide
    la cohérence des plages de rareté.
---------------------------------------------------------------------------]]

BLOOD = BLOOD or {}

BLOOD.Races    = {} -- indexé par id
BLOOD.RaceOrder = {} -- liste ordonnée d'ids

for _, r in ipairs(BLOOD.Config.Races) do
    BLOOD.Races[r.id] = r
    BLOOD.RaceOrder[#BLOOD.RaceOrder + 1] = r.id
end

--- Retourne les données d'une race (fallback Humain si id inconnu).
function BLOOD.GetRace(id)
    return BLOOD.Races[id] or BLOOD.Races["human"]
end

--- La race existe-t-elle réellement ?
function BLOOD.RaceExists(id)
    return BLOOD.Races[id] ~= nil
end

--- Tags d'arme (catégories de dégâts) pour une classe d'arme donnée.
function BLOOD.GetWeaponTags(class)
    return BLOOD.Config.WeaponTags[class] or {}
end

--- Palier de rareté (nom + couleur) d'une race, pour l'annonce / la roulette.
function BLOOD.GetTier(id)
    local C = BLOOD.Config
    local key = (C.RaceTiers and C.RaceTiers[id]) or "commun"
    return (C.Tiers and (C.Tiers[key] or C.Tiers.commun)) or { name = "Commun", color = Color(228, 228, 228) }
end

-- Vérification de cohérence (uniquement côté serveur, au chargement) :
-- les plages doivent couvrir 1..10000 sans trou ni chevauchement.
if SERVER then
    local expected = 1
    local ok = true
    for _, r in ipairs(BLOOD.Config.Races) do
        if r.min ~= expected then
            ok = false
            MsgN(("[Sang et Nuit][WARN] Plage de rareté incohérente pour '%s' : min=%d attendu=%d")
                :format(r.id, r.min, expected))
        end
        expected = r.max + 1
    end
    if expected ~= 10001 then
        ok = false
        MsgN(("[Sang et Nuit][WARN] Les plages ne finissent pas à 10000 (fin=%d).")
            :format(expected - 1))
    end
    if ok then
        MsgN("[Sang et Nuit] Table de rareté valide (1..10000).")
    end
end
