-- OmniRal

local BadgeInfo = {} :: {{BadgeID: number, Name: string, Description: string, Icon: number, TimesToComplete: number, RewardType: "None" | "Coins" | "Toy", Reward: any, DisplayProgress: boolean}}

BadgeInfo.TestBadge = {
    BadgeID = 2208951626055704,
    Name = "Test Badge",
    Description = "Just a test badge",
    Icon = 15669481502,
    TimesToComplete = 3,
    RewardType = "Coins",
    Reward = 1000,
    DisplayProgress = true,
}

return BadgeInfo