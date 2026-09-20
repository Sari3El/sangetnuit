--[[-------------------------------------------------------------------------
    Sang et Nuit — wiltOS Skin : POLICES
      Phase 1 du reskin médiéval de wiltOS (SWTOR -> médiéval).

      wiltOS écrit tout son texte dans « Roboto Cn » (sci-fi). Ici on rebascule
      TOUTES ses polices nommées sur « Georgia » — la même famille que la charte
      BLOOD.UI (Sang et Nuit) — pour une cohérence totale, SANS toucher aux
      fichiers wiltOS (donc rien ne casse le DRM, rien n'est perdu à la MAJ).

      Technique : on « détourne » surface.CreateFont. Dès que wiltOS (re)crée
      une de ses polices — même tardivement à l'ouverture d'un menu — on force
      la famille Georgia en gardant SA taille/graisse (donc aucune taille à
      maintenir à la main). Un premier passage recrée aussi celles déjà créées
      avant le chargement de cet addon.
---------------------------------------------------------------------------]]

if not CLIENT then return end

SANGWOS = SANGWOS or {}

-- Police médiévale de la charte (identique à BLOOD.UI -> raccord parfait).
-- Georgia est une serif présente sur toutes les machines : aucun TTF à livrer.
SANGWOS.FontFamily = "Georgia"

-- Liste EXHAUSTIVE des polices nommées de wiltOS (advswl). On ne touche pas
-- à la police « dynamique » choisie par le joueur (nom de sabre, etc.).
SANGWOS.Fonts = {
    -- HUD sabre (barres du bas + type de pouvoir sélectionné)
    ["SelectedForceHUD"]        = { size = "ss6",   weight = 500  },
    ["SelectedForceType"]       = { size = "ss16",  weight = 600  },
    -- Descriptions / titres génériques ALCS + formes
    ["wOS.ALCS.DescFont"]       = { size = "h18",   weight = 500  },
    ["wOS.ALCS.Form.TitleFont"] = { size = "h24",   weight = 1000 },
    ["wOS.TitleFont"]           = { size = "h24",   weight = 1000 },
    ["wOS.DescriptionFont"]     = { size = "h18",   weight = 500  },
    -- Compétences (skill tree)
    ["wOS.SkillTreeMain"]       = { size = "h32",   weight = 1000 },
    ["wOS.SkillHelpFont"]       = { size = "h28",   weight = 600  },
    -- Menu admin
    ["wOS.AdminMain"]           = { size = "h32",   weight = 1000 },
    ["wOS.AdminFont"]           = { size = "h28",   weight = 600  },
    -- Duels (HUD)
    ["wOS.MegaDuelFont"]        = { size = "h48",   weight = 1000 },
    ["wOS.MainDuelFont"]        = { size = "h32",   weight = 1000 },
    ["wOS.MinorDuelFont"]       = { size = "h24",   weight = 1000 },
    ["wOS.InfoDuelFont"]        = { size = "h18",   weight = 1000 },
    -- Duels (panneaux 3D2D, tailles fixes chez wiltOS)
    ["wOS.3D2D.MainDuel"]       = { size = 100,     weight = 1000 },
    ["wOS.3D2D.MinorDuel"]      = { size = 80,      weight = 800  },
    ["wOS.3D2D.InfoDuel"]       = { size = 60,      weight = 500  },
    -- Craft (tailles fixes)
    ["wOS.CraftTitles"]         = { size = 100,     weight = 1000 },
    ["wOS.CraftDescriptions"]   = { size = 60,      weight = 1000 },
    ["wOS.CraftMinors"]         = { size = 30,      weight = 1000 },
    -- Items (tailles fixes)
    ["wOS.ItemTitles"]          = { size = 100,     weight = 1000 },
    ["wOS.ItemDescriptions"]    = { size = 90,      weight = 1000 },
}

-- Résout une taille « symbolique » vers des pixels, en reproduisant EXACTEMENT
-- le calcul d'origine de wiltOS :
--   "hXX" -> XX * (ScrH()/1200)   (mise à l'échelle verticale)
--   "ssXX" -> ScreenScale(XX)     ( = XX * ScrW()/640 )
--   nombre -> taille fixe
local function resolveSize(v)
    if isnumber(v) then return v end
    local h = ScrH()
    local n = tonumber(string.match(v, "%d+")) or 16
    if string.sub(v, 1, 2) == "ss" then
        return math.floor(n * (ScrW() / 640))
    end
    return math.floor(n * (h / 1200))
end

-- (Ré)applique toutes nos polices avec des tailles calées sur wiltOS.
-- Sert au tout premier passage (polices déjà créées avant nous).
local function applyFonts()
    for name, d in pairs(SANGWOS.Fonts) do
        surface.CreateFont(name, {
            font      = SANGWOS.FontFamily,
            size      = math.max(1, resolveSize(d.size)),
            weight    = d.weight or 500,
            antialias = true,
            extended  = true,
        })
    end
    SANGWOS._fontsApplied = true
end
SANGWOS.ApplyFonts = applyFonts

----------------------------------------------------------------------
-- Détour de surface.CreateFont : garantit que nos polices gagnent TOUJOURS,
-- même si wiltOS (ou un de ses menus) recrée la police après nous.
--   -> on garde la taille/graisse que wiltOS a calculée, on ne change QUE la
--      famille (+ antialias/extended pour les accents FR).
----------------------------------------------------------------------
if not SANGWOS._detoured then
    SANGWOS._detoured = true
    local realCreateFont = surface.CreateFont
    SANGWOS._realCreateFont = realCreateFont

    function surface.CreateFont(name, data)
        if name and SANGWOS.Fonts[name] and istable(data) then
            data = table.Copy(data)
            data.font      = SANGWOS.FontFamily
            data.antialias = true
            data.extended  = true
        end
        return realCreateFont(name, data)
    end
end

-- Passage initial + filets de sécurité (au cas où wiltOS crée ses polices
-- juste après nous, sans repasser par un menu).
applyFonts()
hook.Add("InitPostEntity", "SangWOS_FontsInit", function()
    applyFonts()
    timer.Simple(1, applyFonts)
    timer.Simple(5, applyFonts)
end)

-- Changement de résolution : wiltOS recrée ses polices « hXX » -> on repasse
-- juste après pour rester maître.
hook.Add("OnScreenSizeChanged", "SangWOS_FontsResize", function()
    timer.Simple(0.2, applyFonts)
end)

-- Commande pratique pour forcer un rafraîchissement en jeu si besoin.
concommand.Add("sang_wos_refont", function()
    applyFonts()
    print("[sang_wos_skin] Polices wiltOS re-basculées en " .. SANGWOS.FontFamily .. ".")
end)
