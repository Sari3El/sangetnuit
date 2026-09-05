--[[-------------------------------------------------------------------------
    Sang et Nuit — Banque : configuration (partagé)
---------------------------------------------------------------------------]]

SBANK = SBANK or {}
SBANK.Config = SBANK.Config or {}

local C = SBANK.Config

C.BankModel = "models/props_wasteland/controlroom_filecabinet001a.mdl"
C.GoldModel = "models/props_c17/clock01.mdl"

C.OpenDist   = 140     -- portée pour ouvrir / opérer la banque
C.PickupDist = 120     -- portée pour ramasser l'or (E)

C.DeathDropNum = 2     -- fraction de l'argent porté lâchée à la mort :
C.DeathDropDen = 3     --   DeathDropNum / DeathDropDen  (2/3)

C.DefaultTaxPersonal = 5   -- taxe % par défaut (banques perso)
C.DefaultTaxFaction  = 5   -- taxe % par défaut (banques faction)
C.MaxTax = 100

-- Factions (les banques de faction). La Guilde reçoit les taxes.
C.Factions     = { "monstre", "humain", "guilde" }
C.FactionNames = { monstre = "Monstre", humain = "Humain", guilde = "Guilde" }
C.TaxBank      = "guilde"

C.OpenSound   = "items/ammocrate_open.wav"
C.PickupSound = "items/ammo_pickup.wav"
C.DropSound   = "physics/metal/metal_box_impact_hard1.wav"

-- Le client peut-il afficher le bouton admin ? (la vraie barrière est
-- serveur-side ; le serveur envoie isAdmin dans la synchro).
function SBANK.ClientIsAdmin()
    if not BLOOD or not BLOOD.Config then return false end
    local ply = LocalPlayer()
    if not IsValid(ply) then return false end
    if BLOOD.Config.Admins and BLOOD.Config.Admins[ply:SteamID64()] then return true end
    if BLOOD.Config.AllowSuperAdmin and ply:IsSuperAdmin() then return true end
    return false
end
