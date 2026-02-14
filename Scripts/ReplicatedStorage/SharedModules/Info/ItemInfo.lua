-- OmniRal

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemEnum = require(ReplicatedStorage.Source.SharedModules.Info.CustomEnum.ItemEnum)

local ItemInfo: {
    [string]: ItemEnum.Item
} = {}

ItemInfo.Chungus = {
    Name = "Chungus",
    DisplayName = "Chungus",
    Description = "Chungus",
    FlavorText = "Chungus",
    Icon = 70759788824615,

    Attributes = {
        Health = 25,
        Mana = 10,
        WalkSpeed = 25,
    },

    Ability = {
        Name = "Test Passive",
        DisplayName = "Test Passive Display",
        Description = "Test Passive Description",
        FlavorText = "Test Passive Flavor Test",
        Icon = 0,

        Type = "Passive",
        Damage = NumberRange.new(0, 0),
        Cooldown = 7,

        Details = {},
    }
}

ItemInfo.Dingus = {
    Name = "Dingus",
    DisplayName = "Dingus",
    Description = "Dingus",
    FlavorText = "Dingus",
    Icon = 128112961203002,
    
    Attributes = {
        Damage = 0,
        WalkSpeed = 10,
    },

    Ability = {
        Name = "Test Active",
        DisplayName = "Test Active Display",
        Description = "Test Active Description",
        FlavorText = "Test Active Flavor Text",
        Icon = 0,

        Type = "Active",
        Damage = NumberRange.new(10, 10),
        Cooldown = 5,

        Details = {},
    }
}

return ItemInfo