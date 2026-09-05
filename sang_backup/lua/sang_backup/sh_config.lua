--[[-------------------------------------------------------------------------
    Sang et Nuit — Backup : configuration
---------------------------------------------------------------------------]]

SBK = SBK or {}
SBK.Config = SBK.Config or {}
local C = SBK.Config

-- Intervalle (secondes) entre deux sauvegardes automatiques.
C.Interval = 15 * 60      -- 15 minutes

-- Nombre de backups conservés (les plus anciens sont supprimés).
C.KeepBackups = 20

-- Dossier de destination (dans garrysmod/data/).
C.Dir = "sang/backups"

-- Préfixes des tables SQL « Sang » à sauvegarder (découverte automatique).
C.TablePrefixes = { "blood_", "slvl_", "sjob_", "sbank_", "sfood_" }
