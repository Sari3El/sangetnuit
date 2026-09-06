--[[-------------------------------------------------------------------------
    Sang et Nuit — Chat RP : configuration (partagé)
---------------------------------------------------------------------------]]

SRP = SRP or {}
SRP.Config = SRP.Config or {}
local C = SRP.Config

-- Portées (unités source). Au-delà, les autres joueurs ne voient pas le message.
C.RangeIC   = 350   -- chat "in character" local (parole normale)
C.RangeMe   = 420   -- /me et /it
C.RangeRoll = 420   -- /roll

C.MaxLen    = 250   -- longueur max d'un message

-- OOC global (// ou /ooc) : hors-RP, visible par tous.
C.EnableOOC = true
