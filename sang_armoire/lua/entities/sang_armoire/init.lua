AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
    local model = (SARM and SARM.ResolveModel and SARM.ResolveModel()) or "models/error.mdl"
    util.PrecacheModel(model)
    self:SetModel(model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false) -- reste en place
        phys:Wake()
    else
        -- Le modèle n'a pas de maillage physique exploitable (ex. pas de
        -- $collisionmodel) : PhysicsInit(SOLID_VPHYSICS) échoue silencieusement
        -- et l'entité devient non solide / non cliquable. On bascule sur une
        -- boîte englobante simple pour qu'elle reste visible ET utilisable.
        self:PhysicsInitBox(self:OBBMins(), self:OBBMaxs())
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_BBOX)
        MsgN("[Sang Armoire][ATTENTION] Le modèle '" .. model .. "' n'a pas de collision physique : "
            .. "bascule sur une boîte englobante simple.")
    end
end

function ENT:Use(activator)
    if IsValid(activator) and activator:IsPlayer() and SARM.OpenArmoire then
        SARM.OpenArmoire(activator, self)
    end
end
