-- OmniRal

local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local LevelEnum = require(ReplicatedStorage.Source.SharedModules.Info.CustomEnum.LevelEnum)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local LevelInfo: {[string]: LevelEnum.LevelDetails} = {}

LevelInfo.Level_1 = {
    ID = 1,
    Name = "They Crawl Within",
    Description = "Spider outbreak",
    Scale = "Routine",

    ModelID = 118181639092449,
}

return LevelInfo
