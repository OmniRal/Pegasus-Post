-- OmniRal

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CustomEnum = require(ReplicatedStorage.Source.SharedModules.Info.CustomEnum)

local WeaponEnum = {}

export type WeaponUseType = "Single" | "Auto"
export type WeaponStyle = "Melee" | "Ranged"

export type Weapon = {
    UnlockedBy: CustomEnum.UnlockedBy,
    Cost: number,

    DisplayName: string,
    Description: string,
    FlavorText: string,
    Icon: number,
    
    UseType: WeaponUseType,
    Style: WeaponStyle,

    MeleeData: {
        CanComboChain: boolean?,
        ComboAmount: number?,
    }?,

    RangedData: {
        Reload: boolean?,
        MaxAmmo: number,
    }?,

    Damage: NumberRange,

    Abilities: {
        Innate: CustomEnum.Ability,
        Awakened: CustomEnum.Ability?,
    }?,

    BaseAnimations: {
        ["idle"]: number?,
        ["walk"]: number?,
        ["run"]: number?,
        ["jump"]: number?,
        ["fall"]: number?,
    }?,
    
    HoldingAnimations: {
        [string]: {[string]: {ID: number, Priority: Enum.AnimationPriority}}
    }?,

    ModelAnimations: {
        [string]: {[string]: {ID: number, Priority: Enum.AnimationPriority}}
    }?,

    Skins: {[string]: {UnlockedBy: CustomEnum.UnlockedBy, Cost: number}},
}

return WeaponEnum