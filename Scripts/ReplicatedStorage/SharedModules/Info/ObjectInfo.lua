-- OmniRal

local ObjectInfo = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local CustomEnum = require(ReplicatedStorage.Source.SharedModules.Info.CustomEnum)


local RNG = Random.new()
local Sides = {-1, 1}

ObjectInfo.NormalCrate = {
    Name = "NormalCrate",
    DisplayName = "Crate",
    Setup = function(Crate: Model)
        local MaxHealth = 10
        local Base = Crate:FindFirstChild("Base") :: Part
        
        CollectionService:AddTag(Crate, "Breakable")
        CollectionService:AddTag(Crate, "Crate")
        Crate:SetAttribute("Health", MaxHealth)

        Crate:GetAttributeChangedSignal("Health"):Connect(function()
            local CurrentHealth = Crate:GetAttribute("Health") :: number
            if CurrentHealth > 0 then
                Base.AssemblyLinearVelocity = Vector3.new(0, RNG:NextInteger(5, 6), 0)
                Base.AssemblyAngularVelocity = Vector3.new(
                    RNG:NextInteger(5, 10) * Sides[RNG:NextInteger(1, 2)],
                    RNG:NextInteger(5, 10) * Sides[RNG:NextInteger(1, 2)],
                    RNG:NextInteger(5, 10) * Sides[RNG:NextInteger(1, 2)]
                )
            else
                Crate:Destroy()
            end
        end)

        return Crate
    end
} --:: CustomEnum.Crate

return ObjectInfo