-- OmniRal

local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local WeaponEnum = require(ReplicatedStorage.Source.SharedModules.Info.CustomEnum.WeaponEnum)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local WeaponInfo: {
    [string]: WeaponEnum.Weapon
} = {}

WeaponInfo.BasicSword = {
    UnlockedBy = "Default",
    Cost = 0,

    DisplayName = "Basic Sword",
    Description = "",
    FlavorText = "",
    Icon = 0,

    UseType = "Single",
    Style = "Melee",

    MeleeData = {
        CanComboChain = true,
        ComboAmount = 3,
    },

    Damage = NumberRange.new(10, 11),

    Abilities = {
        Innate = {
            Name = "Jizz",
            DisplayName = "Jizz",
            Description = "",
            FlavorText = "",
            Icon = "",

            Type = "Active",
            Damage = NumberRange.new(45, 50),
            Cooldown = 3,
        },

        Awakened = {
            Name = "SuperJizz",
            DisplayName = "Super Jizz",
            Description = "",
            FlavorText = "",
            Icon = 0,

            Type = "Passive",
            Damage = NumberRange.new(45, 50),
            Cooldown = 10,
        }
    },

    BaseAnimations = {
		["idle"] = 15493944783, 
		["walk"] = 15493945869,
		["run"] = 15493946987, 
		["jump"] = 15493949484, 
		["fall"] = 15493951085
    },

    HoldingAnimations = {
        Using = {
            ["Swing_1_A"] = {ID = 15502657876, Priority = Enum.AnimationPriority.Action}, -- Starting combo
            ["Swing_1_B"] = {ID = 15502661852, Priority = Enum.AnimationPriority.Action}, -- Looping combo
            ["Swing_2"] = {ID = 15502658851, Priority = Enum.AnimationPriority.Action},
            ["Swing_3"] = {ID = 15502660636, Priority = Enum.AnimationPriority.Action},
            ["Innate"] = {ID = 117985989016321, Priority = Enum.AnimationPriority.Action2},
        }
    },

    ModelAnimations = {
        Using = {
            ["Innate"] = {ID = 130472834160922, Priority = Enum.AnimationPriority.Action}
        }
    },

    Skins = {
        ["Default"] = {UnlockedBy = "Default", Cost = 0},
    }
}

--[[
WeaponInfo.Cruncher = {
    DisplayName = "Cruncher",
    Description = "Grinds bolts, metals and various other debris to use as fire power!",
    FlavorText = "They won't know what hit 'em! Literally.",
    Icon = 136509376539536,

    Type = "Primary",
    UseType = "Auto",
    Reload = true,

    ReloadTime = 2,
    UseRate = 0.25,
    MaxClips = 30,
    MaxMags = 3,

    Damage = NumberRange.new(1, 1),

    HoldingAnimations = {
        Base = {
            ["Idle"] = {ID = 70991446529659, Priority = Enum.AnimationPriority.Action}
        }, 
        Using = {
            ["StartFire"] = {ID = 111271078408107, Priority = Enum.AnimationPriority.Action2}, 
            ["Firing"] = {ID = 105064106391976, Priority = Enum.AnimationPriority.Action2},
            ["StopFire"] = {ID = 76608737715824, Priority = Enum.AnimationPriority.Action2},
            ["Reloading"] = {ID = 93639917370633, Priority = Enum.AnimationPriority.Action3},
        }
    },
    ModelAnimations = {
        Base = {
            ["Grinding"] = {ID = 87569697764574, Priority = Enum.AnimationPriority.Idle},
        },
        Using = {
            ["Reloading"] = {ID = 73447210844421, Priority = Enum.AnimationPriority.Action},
        }
    },

    UnlockedBy = "Default",
    Cost = 0,

    Skins = {
        ["Default"] = {UnlockedBy = "Default", Cost = 0},
        ["Greenmark"] = {UnlockedBy = "Default", Cost = 0}
    },
}

WeaponInfo.Rusty = {
    DisplayName = "Rusty",
    Description = "",
    FlavorText = "",
    Icon = 101320814584009,

    Type = "Melee",
    UseType = "Single",

    ReloadTime = 0,
    UseRate = 0.25,
    MaxClips = -2,
    MaxMags = -2,

    Damage = NumberRange.new(1, 1),

    HoldingAnimations = {
        Base = {
            ["Idle"] = {ID = 125915672325737, Priority = Enum.AnimationPriority.Action}
        }, 
        Using = {
            ["Swing1"] = {ID = 117025060129870, Priority = Enum.AnimationPriority.Action2}, 
            ["Swing2"] = {ID = 102691627815800, Priority = Enum.AnimationPriority.Action2},
            ["Swing1B"] = {ID = 96544824870356, Priority = Enum.AnimationPriority.Action2},
        }
    },
    ModelAnimations = {},

    UnlockedBy = "Default",
    Cost = 0,

    Skins = {
        ["Default"] = {UnlockedBy = "Default", Cost = 0},
        ["Mannys"] = {UnlockedBy = "Default", Cost = 0}
    },
}

WeaponInfo.Brighton = {
    UnlockedBy = "Default",
    Cost = 0,

    DisplayName = "Brighton",
    Description = "Description",
    FlavorText = "Flavor text",
    Icon = 10,

    Type = "Primary",
    UseType = "Auto",
    Reload = true,
    
    UseRate = 0.1,
    ReloadTime = 1,
    MaxMags = 20,
    MaxClips = 100,

    Damage = NumberRange.new(3, 4),

    HoldingAnimations = {
        Base = {
            ["Idle"] = {ID = 77779427517639, Priority = Enum.AnimationPriority.Action},
            ["StillIdle"] = {ID = 88035369296667, Priority = Enum.AnimationPriority.Action}
            
        }, 
        Using = {
            ["StartFire"] = {ID = 124955372594934, Priority = Enum.AnimationPriority.Action2}, 
            ["Firing"] = {ID = 79319678215722, Priority = Enum.AnimationPriority.Action2},
            ["StopFire"] = {ID = 122545310874552, Priority = Enum.AnimationPriority.Action2},
            ["Reloading"] = {ID = 111652523060184, Priority = Enum.AnimationPriority.Action3}, -- GrabMag, PullMag, ThrowMag, CheckPocket, NewMag, InsertMag
        }},
    ModelAnimations = {
        Base = {
            --["Grinding"] = {ID = 87569697764574, Priority = Enum.AnimationPriority.Idle},
        },
        Using = {
            ["Reloading"] = {ID = 139007808851580, Priority = Enum.AnimationPriority.Action},
        }
    },

    Skins = {
        ["Default"] = {UnlockedBy = "Default", Cost = 0},
    },
}
]]

return WeaponInfo