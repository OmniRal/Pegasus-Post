-- OmniRal

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RelicEnum = require(ReplicatedStorage.Source.SharedModules.Info.CustomEnum.RelicEnum)

local RelicInfo: {[string]: RelicEnum.Relic} = {}

RelicInfo.Echo = {
    Name = "Echo",
    Description = "",
    FlavorText = "",
    Icon = 77310075815750,

    StoneColor = Color3.fromRGB(255, 39, 133),
}

RelicInfo.Blast = {
    Name = "Blast",
    Description = "",
    FlavorText = "",
    Icon = 123228184913688,

    StoneColor = Color3.fromRGB(255, 118, 39)
}

return RelicInfo