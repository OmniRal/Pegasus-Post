-- OmniRal

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CustomEnum = require(ReplicatedStorage.Source.SharedModules.Info.CustomEnum)
local UnitEnum = require(ReplicatedStorage.Source.SharedModules.Info.CustomEnum.UnitEnum)

local ItemEnum = {}

export type Item = {
    Name: string,
    DisplayName: string,
    Description: string,
    FlavorText: string,
    Icon: number,

    Attributes: UnitEnum.BaseAttributes,
    
    Ability: CustomEnum.Ability?,
    MaxStacks: number?,
}

return ItemEnum