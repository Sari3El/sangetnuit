--[[-------------------------------------------------------------------------
    Sang et Nuit — wiltOS Skin : TRADUCTION FR + RECOLORISATION
      Phase 2 du reskin médiéval.

      100% overlay : on n'édite AUCUN fichier wiltOS (DRM intact, rien perdu
      aux mises à jour). On « détourne » les fonctions de dessin de GMod :
        - draw.SimpleText : traduit le texte (EN -> FR médiéval) et remappe
          les couleurs signature Star Wars.
        - draw.RoundedBox / surface.SetDrawColor : remappent le bleu (0,128,255)
          et le violet (225,0,225) vers l'or / le rouge sang de la charte.
      + override des phrases language.Add de wiltOS en français.

      Réglages (console) :
        sang_wos_translate  1/0  — activer la traduction FR
        sang_wos_recolor    1/0  — activer la recolorisation or/sang
---------------------------------------------------------------------------]]

if not CLIENT then return end

SANGWOS = SANGWOS or {}

local cv_translate = CreateClientConVar("sang_wos_translate", "1", true, false)
local cv_recolor   = CreateClientConVar("sang_wos_recolor",   "1", true, false)

----------------------------------------------------------------------
-- Palette médiévale (identique à BLOOD.UI)
----------------------------------------------------------------------
local GOLD  = { r = 210, g = 176, b = 108 } -- goldLt : remplace le bleu SW
local BLOOD = { r = 150, g = 42,  b = 38  } -- bloodLt : remplace le violet SW

----------------------------------------------------------------------
-- 1) TRADUCTION — correspondances exactes (chaînes autonomes)
----------------------------------------------------------------------
SANGWOS.TR = {
    -- Titres de menus
    ["Force Select Menu"] = "Menu des Pouvoirs",
    ["Form Select Menu"]  = "Menu des Postures",
    ["Artifact Menu"]     = "Menu des Artéfacts",
    ["Inventory Menu"]    = "Menu d'Inventaire",
    ["Item Spawn Menu"]   = "Menu d'apparition d'objets",
    ["Material Menu"]     = "Menu des Matériaux",
    ["Prestige Menu"]     = "Menu de Prestige",
    ["Proficiency Menu"]  = "Menu de Maîtrise",
    ["Skills Menu"]       = "Menu des Compétences",
    ["Spirit Menu"]       = "Menu des Esprits",
    ["Storage Menu"]      = "Menu du Coffre",
    ["Executions Menu"]   = "Menu des Exécutions",
    ["Devestators Menu"]  = "Menu des Dévastateurs",
    ["Whitelist Menu"]    = "Menu des Autorisations",
    ["Duel Station Roster"] = "Liste des duellistes",
    -- Boutons génériques
    ["CANCEL"]            = "ANNULER",
    ["CANCEL CREATION"]  = "ANNULER LA CRÉATION",
    ["GO BACK"]          = "RETOUR",
    ["CLOSE MENU"]       = "FERMER LE MENU",
    ["RESET ALL"]        = "TOUT RÉINITIALISER",
    ["REJECT"]           = "REFUSER",
    ["EQUIPPED"]         = "ÉQUIPÉ",
    ["MASTERED"]         = "MAÎTRISÉ",
    ["ERROR"]            = "ERREUR",
    ["UNAVAILABLE"]      = "INDISPONIBLE",
    ["ID"]               = "ID",
    -- Ajouts / réglages admin
    ["ADD EXECUTION"]    = "AJOUTER EXÉCUTION",
    ["ADD LEVEL"]        = "AJOUTER NIVEAU",
    ["ADD MASTERY"]      = "AJOUTER MAÎTRISE",
    ["ADD POINTS"]       = "AJOUTER POINTS",
    ["ADD TOKENS"]       = "AJOUTER JETONS",
    ["ADD TREE"]         = "AJOUTER ARBRE",
    ["ADD XP"]           = "AJOUTER XP",
    ["ADD SELECTED ARTIFACT"]    = "AJOUTER L'ARTÉFACT",
    ["ADD SELECTED ITEM TO SLOT"]= "AJOUTER L'OBJET AU SLOT",
    ["ADD SELECTED ITEM"]        = "AJOUTER L'OBJET",
    ["ADD SELECTED SPIRIT"]      = "AJOUTER L'ESPRIT",
    ["SET ENERGY"]       = "DÉFINIR ÉNERGIE",
    ["SET LEVEL"]        = "DÉFINIR NIVEAU",
    ["SET POINTS"]       = "DÉFINIR POINTS",
    ["SET XP"]           = "DÉFINIR XP",
    ["CLEAR SELECTED SLOT"]        = "VIDER LE SLOT",
    ["REMOVE SELECTED EXECUTION"]  = "RETIRER L'EXÉCUTION",
    ["REMOVE SELECTED ITEM"]       = "RETIRER L'OBJET",
    ["REMOVE SELECTED MASTERY"]    = "RETIRER LA MAÎTRISE",
    ["REMOVE SELECTED SPIRIT"]     = "RETIRER L'ESPRIT",
    ["REMOVE SELECTED TREE"]       = "RETIRER L'ARBRE",
    ["REMOVE THIS LISTING"]        = "RETIRER CETTE ANNONCE",
    ["SPAWN SELECTED ITEM"]        = "FAIRE APPARAÎTRE L'OBJET",
    -- Duels
    ["ACCEPT CHALLENGE"] = "ACCEPTER LE DÉFI",
    ["CHALLENGE"]        = "DÉFIER",
    ["CHALLENGES YOU"]   = "VOUS DÉFIE",
    ["CHOOSE YOUR ARENA"]= "CHOISISSEZ VOTRE ARÈNE",
    ["SELECTED ARENA"]   = "ARÈNE SÉLECTIONNÉE",
    ["ARENA CAM UNAVAILABLE"] = "CAMÉRA D'ARÈNE INDISPONIBLE",
    ["NO ARENAS AVAILABLE"]   = "AUCUNE ARÈNE DISPONIBLE",
    ["NO DUELISTS IN YOUR AREA"] = "AUCUN DUELLISTE À PROXIMITÉ",
    ["DUEL TIME"]        = "TEMPS DE DUEL",
    ["FIGHTING SPIRIT"]  = "ESPRIT COMBATIF",
    ["HONOR BOUND"]      = "LIÉ PAR L'HONNEUR",
    ["CREDIT WAGER"]     = "MISE EN OR",
    ["Refresh Roster"]   = "Actualiser la liste",
    ["DUEL LOST! Your wager has been deducted."] = "DUEL PERDU ! Votre mise a été retirée.",
    ["DUEL WON! You have been awarded your wager."] = "DUEL GAGNÉ ! Votre mise vous a été remise.",
    ["NOBODY WINS! The duel was a draw."] = "MATCH NUL ! Le duel n'a pas de vainqueur.",
    ["HOW LONG BEFORE THE DUEL ENDS IN STALEMATE? ( IN SECONDS )"] = "COMBIEN DE TEMPS AVANT MATCH NUL ? ( EN SECONDES )",
    ["HOW MUCH CREDITS ARE YOU WILLING TO LOSE?"] = "COMBIEN D'OR ÊTES-VOUS PRÊT À PERDRE ?",
    ["THE DUEL WILL LAST THIS MANY SECONDS"] = "DURÉE DU DUEL EN SECONDES",
    ["YOU WILL BE GAMBLING THIS MANY CREDITS"] = "VOUS MISEZ CETTE QUANTITÉ D'OR",
    -- Marché / enchères / échanges
    ["ACCEPT TRADE"]     = "ACCEPTER L'ÉCHANGE",
    ["BID AMOUNT"]       = "MONTANT DE L'ENCHÈRE",
    ["BUY IT NOW"]       = "ACHETER MAINTENANT",
    ["Buy Now Price"]    = "Prix immédiat",
    ["Current Bid"]      = "Enchère actuelle",
    ["Auction Ends"]     = "Fin de l'enchère",
    ["CREATE AUCTION LISTING"] = "CRÉER UNE ENCHÈRE",
    ["CREATE LISTING"]   = "CRÉER UNE ANNONCE",
    ["CREATE TRADE LISTING"] = "CRÉER UN ÉCHANGE",
    ["REFRESH LISTINGS"] = "ACTUALISER LES ANNONCES",
    ["SHOW AUCTIONS"]    = "VOIR LES ENCHÈRES",
    ["SHOW TRADES"]      = "VOIR LES ÉCHANGES",
    ["NO LISTING SELECTED"] = "AUCUNE ANNONCE SÉLECTIONNÉE",
    ["Item Name"]        = "Nom de l'objet",
    ["Offered Item Name"]= "Nom de l'objet offert",
    ["Offered Item"]     = "Objet offert",
    ["Requested Item Name"] = "Nom de l'objet demandé",
    ["Requested Item"]   = "Objet demandé",
    -- Lames
    ["Primary Lightsaber"]  = "Lame principale",
    ["Off Hand Lightsaber"] = "Lame secondaire",
    -- Crédit / mention
    ["Powered by wiltOS Technologies"] = "Forgé pour Sang et Nuit",
}

----------------------------------------------------------------------
-- 2) TRADUCTION — préfixes concaténés (texte + valeur dynamique)
--    Ordre IMPORTANT : du plus spécifique au plus général.
----------------------------------------------------------------------
SANGWOS.TR_SUB = {
    { "Combat Level: ",      "Niveau de Combat : "     },
    { "Proficiency Level: ", "Niveau de Maîtrise : "   },
    { "Skill Points: ",      "Points de Compétence : " },
    { "CURRENT BID: ",       "ENCHÈRE ACTUELLE : "     },
    { "BUY NOW PRICE: ",     "PRIX IMMÉDIAT : "        },
    { "BIDDER ID: ",         "ID ENCHÉRISSEUR : "      },
    { "TIME LEFT: ",         "TEMPS RESTANT : "        },
    { "STAMINA: ",           "SOUFFLE : "              },
    { "RADIUS: ",            "RAYON : "                },
    { "WON: ",               "GAGNÉ : "                },
    { "Requires ",           "Requiert "               },
    { "Level ",              "Niveau "                 },
    { "Slot ",               "Touche "                 },
    { "ENDS ",               "FIN "                    },
    { "FOR ",                "POUR "                   },
}

----------------------------------------------------------------------
-- 3) TRADUCTION — phrases language.Add (menu de forge des lames)
----------------------------------------------------------------------
local LANG = {
    advert_wiltos     = "Forgé pour Sang et Nuit",
    dual_saber        = "DOUBLE",
    info_bladel       = "Longueur de lame :",
    info_bladew       = "Largeur de lame :",
    info_constructor  = "Module de forge",
    info_dark         = "Lame interne sombre",
    info_forgem       = "Routine de forge",
    info_humsound     = "Son au repos :",
    info_igniter      = "Activateur de gemme :",
    info_miscitem     = "Mods de maîtrise",
    info_primcrystal  = "Gemme principale",
    info_seccrystal   = "Gemme secondaire",
    info_smeltm       = "Routine de recyclage",
    info_swingsound   = "Son de frappe :",
    option_blade      = "Lame",
    option_color      = "Gemme",
    option_hilt       = "Poignée",
    option_misc       = "Enchantements",
    primary_blade     = "Lame principale",
    primary_saber     = "PRINCIPALE",
    secondary_blade   = "Lame secondaire",
    secondary_saber   = "SECONDAIRE",
    select_primaryhilt   = "Définir comme poignée principale",
    select_secondaryhilt = "Définir comme poignée secondaire",
}

local function applyLang()
    for suffix, fr in pairs(LANG) do
        language.Add("wos_" .. suffix, fr)   -- variante interface
        language.Add("wos_l_" .. suffix, fr) -- variante « legacy »
    end
end

----------------------------------------------------------------------
-- Helpers de traduction / recolorisation
----------------------------------------------------------------------
local Replace = string.Replace

-- La traduction ne s'applique QU'au texte dessiné dans une police wiltOS
-- (wOS.* / SelectedForce*). Ça évite de toucher notre propre UI (SangUI_*)
-- et le reste du jeu, et ça allège le traitement.
local function isWosFont(font)
    if not isstring(font) then return false end
    return font == "SelectedForceHUD" or font == "SelectedForceType"
        or string.sub(font, 1, 3) == "wOS"
end
SANGWOS.IsWosFont = isWosFont

local function translate(text)
    if not cv_translate:GetBool() then return text end
    local exact = SANGWOS.TR[text]
    if exact then return exact end
    -- préfixes dynamiques
    local sub = SANGWOS.TR_SUB
    for i = 1, #sub do
        local e = sub[i]
        if string.find(text, e[1], 1, true) then
            text = Replace(text, e[1], e[2])
        end
    end
    return text
end
SANGWOS.Translate = translate

-- Remappe une Color signature Star Wars -> or/sang (en gardant l'alpha).
local function remap(c)
    if not cv_recolor:GetBool() or not istable(c) then return c end
    local r, g, b = c.r, c.g, c.b
    if r == 0 and g == 128 and b == 255 then
        return Color(GOLD.r, GOLD.g, GOLD.b, c.a or 255)
    elseif r == 225 and g == 0 and b == 225 then
        return Color(BLOOD.r, BLOOD.g, BLOOD.b, c.a or 255)
    end
    return c
end
SANGWOS.Remap = remap

----------------------------------------------------------------------
-- Détours (installés une seule fois)
----------------------------------------------------------------------
if not SANGWOS._textDetoured then
    SANGWOS._textDetoured = true

    -- draw.SimpleText : traduction + couleur
    local realSimpleText = draw.SimpleText
    SANGWOS._realSimpleText = realSimpleText
    function draw.SimpleText(text, font, x, y, color, ...)
        if isstring(text) and isWosFont(font) then text = translate(text) end
        return realSimpleText(text, font, x, y, remap(color), ...)
    end

    -- draw.Text : traduction + couleur (structure { text=, color= })
    local realDrawText = draw.Text
    SANGWOS._realDrawText = realDrawText
    function draw.Text(tab)
        if istable(tab) then
            if isstring(tab.text) and isWosFont(tab.font) then tab.text = translate(tab.text) end
            if tab.color ~= nil then tab.color = remap(tab.color) end
        end
        return realDrawText(tab)
    end

    -- draw.RoundedBox : couleur (barres)
    local realRoundedBox = draw.RoundedBox
    SANGWOS._realRoundedBox = realRoundedBox
    function draw.RoundedBox(bs, x, y, w, h, color)
        return realRoundedBox(bs, x, y, w, h, remap(color))
    end

    -- surface.SetDrawColor : couleur (rectangles/matériaux)
    local realSetDrawColor = surface.SetDrawColor
    SANGWOS._realSetDrawColor = realSetDrawColor
    function surface.SetDrawColor(r, g, b, a)
        if istable(r) then return realSetDrawColor(remap(r)) end
        if cv_recolor:GetBool() then
            if r == 0 and g == 128 and b == 255 then
                return realSetDrawColor(GOLD.r, GOLD.g, GOLD.b, a or 255)
            elseif r == 225 and g == 0 and b == 225 then
                return realSetDrawColor(BLOOD.r, BLOOD.g, BLOOD.b, a or 255)
            end
        end
        return realSetDrawColor(r, g, b, a)
    end
end

----------------------------------------------------------------------
-- Application des phrases (au chargement + filets après wiltOS)
----------------------------------------------------------------------
applyLang()
hook.Add("InitPostEntity", "SangWOS_LangInit", function()
    applyLang()
    timer.Simple(2, applyLang)
    timer.Simple(6, applyLang)
end)

concommand.Add("sang_wos_relang", function()
    applyLang()
    print("[sang_wos_skin] Phrases wiltOS re-traduites en FR.")
end)
