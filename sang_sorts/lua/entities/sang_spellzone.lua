--[[-------------------------------------------------------------------------
    Sang et Nuit — Entité « zone de sort » (soin OU malédiction)
      Reste au sol un certain temps, et chaque seconde soigne (heal) ou blesse
      (curse) les êtres vivants dans son rayon. La particule d'aura est attachée
      côté client (nom réseau "particle").
---------------------------------------------------------------------------]]

AddCSLuaFile()

ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Zone de sort"
ENT.Spawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("Float",  0, "ZRadius")
    self:NetworkVar("String", 0, "ZParticle")
end

if SERVER then
    function ENT:Initialize()
        self:SetModel("models/hunter/plates/plate.mdl")
        self:SetNoDraw(true)
        self:DrawShadow(false)
        self:SetSolid(SOLID_NONE)
        self:SetNotSolid(true)
        self:SetMoveType(MOVETYPE_NONE)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) end
        self.NextTick = 0
        self:NextThink(CurTime())
    end

    -- kind : "heal" | "curse"
    function ENT:SetupZone(owner, kind, radius, amount, duration, particle)
        self.SOwner  = owner
        self.SKind   = kind or "heal"
        self.SAmount = amount or 3
        self.DieTime = CurTime() + (duration or 18)
        self:SetZRadius(radius or 250)
        self:SetZParticle(particle or "")
    end

    local function living(e)
        if not IsValid(e) then return false end
        if e:IsPlayer() then return e:Alive() end
        if e:IsNPC() then return e:Health() > 0 end
        return false
    end

    function ENT:Think()
        if CurTime() >= (self.DieTime or 0) then self:Remove() return end
        if CurTime() >= self.NextTick then
            self.NextTick = CurTime() + 1
            local pos, r = self:GetPos(), self:GetZRadius()
            for _, e in ipairs(ents.FindInSphere(pos, r)) do
                if living(e) then
                    if self.SKind == "heal" then
                        if SANGSPELL and SANGSPELL.Heal then SANGSPELL.Heal(e, self.SAmount) end
                    elseif e ~= self.SOwner then
                        if SANGSPELL and SANGSPELL.DealDamage then
                            SANGSPELL.DealDamage(self.SOwner, e, self.SAmount, DMG_ACID, self)
                        end
                    end
                end
            end
        end
        self:NextThink(CurTime() + 0.1)
        return true
    end
end

if CLIENT then
    function ENT:Initialize() self.Attached = false end
    function ENT:Draw() end

    function ENT:Think()
        if not self.Attached then
            local p = self:GetZParticle()
            if p and p ~= "" then
                ParticleEffectAttach(p, PATTACH_ABSORIGIN_FOLLOW, self, 0)
                self.Attached = true
            end
        end
    end

    function ENT:OnRemove()
        self:StopParticles()
    end
end
