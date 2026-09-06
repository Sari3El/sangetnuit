--[[-------------------------------------------------------------------------
    Sang et Nuit — Sorts : masque les sorts vanilla de HPW (client)
      But : n'afficher QUE nos sorts (nos catégories de magie) + les SKINS de
      baguette, dans « Tree of spells and skins » ET « All spells ».

      Méthode (client uniquement, réversible) :
        - on retire du registre CLIENT (HpwRewrite.Spells) tous les sorts qui
          ne sont PAS à nous et PAS des skins → ils disparaissent des menus ;
        - on les garde de côté (HpwRewrite._SangHidden) et le SERVEUR garde son
          registre complet → réactivable (C.HideVanillaSpells = false) ;
        - la liste des catégories devient : Favoris + nos magies (même vides).

      Note : GetSpell(name) lit HpwRewrite.Spells[name] directement, donc lancer
      un sort n'est pas cassé pour ce qui reste ; les skins ne sont pas touchés.
---------------------------------------------------------------------------]]

if not CLIENT then return end
if not HpwRewrite then
    MsgN("[Sang Sorts] HpwRewrite introuvable — masquage des sorts ignoré.")
    return
end

SANGSPELL = SANGSPELL or {}
local C = SANGSPELL.Config or {}
if not C.HideVanillaSpells then return end

-- Ensemble de nos catégories.
local ourCats = {}
for _, c in ipairs(C.Categories or {}) do ourCats[c] = true end

local function isOurs(spell)
    if not spell then return false end
    if spell.SangSort then return true end
    local cat = spell.Category
    if istable(cat) then
        for _, c in ipairs(cat) do if ourCats[c] then return true end end
    elseif cat and ourCats[cat] then
        return true
    end
    return false
end

local function applyHide()
    local spells = HpwRewrite.Spells
    if not istable(spells) then return end
    HpwRewrite._SangHidden = HpwRewrite._SangHidden or {}

    -- 1) Retire du registre client tout ce qui n'est ni à nous ni un skin.
    for name, spell in pairs(spells) do
        if not spell.IsSkin and not isOurs(spell) then
            HpwRewrite._SangHidden[name] = spell
            spells[name] = nil
        end
    end

    -- 2) Purge la liste des sorts « appris » côté client (sinon le tableau
    --    "Tree" et l'onglet des appris ré-afficheraient les sorts vanilla).
    if istable(HpwRewrite.PlayerSpellsInfo) then
        for name in pairs(HpwRewrite.PlayerSpellsInfo) do
            if HpwRewrite._SangHidden[name] then
                HpwRewrite.PlayerSpellsInfo[name] = nil
            end
        end
    end

    -- 3) Catégories affichées : Favoris + nos 4 magies (même vides).
    local cats = {}
    local fav = HpwRewrite.Language and HpwRewrite.Language.GetWord
        and HpwRewrite.Language:GetWord("#favcategory")
    if fav then cats[fav] = true end
    for _, c in ipairs(C.Categories or {}) do cats[c] = true end
    HpwRewrite.Categories = cats
end

applyHide()
-- Ré-applique périodiquement : le serveur peut resynchroniser la liste des
-- sorts appris (ce qui les ferait réapparaître) — on nettoie à nouveau.
timer.Create("SangSorts_Hide", 3, 0, applyHide)

MsgN("[Sang Sorts] Sorts vanilla masqués (client) — seules nos magies + skins restent.")
