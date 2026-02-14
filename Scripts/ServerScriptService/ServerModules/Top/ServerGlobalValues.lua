-- OmniRal

local ServerGlobalValues = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LevelEnum = require(ReplicatedStorage.Source.SharedModules.Info.CustomEnum.LevelEnum)

--------------------------------------------------------------------------------------------

ServerGlobalValues["AdminList"] = {
    {Name = "OmniRal", ID = 267421},
    {Name = "Blotnik", ID = 266280},
    {Name = "bennult", ID = 424583710},
}

ServerGlobalValues["PlayerTestList"] = {
    {Name = "Player1", ID = -1},
    {Name = "Player2", ID = -2},
}

local List_1 = {ServerGlobalValues.AdminList[1]}
local List_2 = {ServerGlobalValues.AdminList[1], ServerGlobalValues.AdminList[2]}
local List_3 = ServerGlobalValues.AdminList
local List_4 = ServerGlobalValues.PlayerTestList

--------------------------------------------------------------------------------------------

ServerGlobalValues["CleanupAssetDump"] = true

ServerGlobalValues["DefaultHistoryEntryCleanTime"] = 30
ServerGlobalValues["RootWalkSpeed"] = 0.01
ServerGlobalValues["SimpleDamage"] = true -- If enabled, there will not be multiple damage types.

--------------------------------------------------------------------------------------------

ServerGlobalValues["StartLevelInfo"] = {
    ID = 1,
    ExpectedPlayers = List_1,
    
    TestingMode = false, -- Test a level in studip; does not load lobby. ID should be set to the desired level
    TestWithoutPlayers = false, -- Test in studio without players; pressing RUN instead of PLAY SOLO,
}
ServerGlobalValues["InLevel"] = false
ServerGlobalValues["LevelPlayers"] = {} :: {}
ServerGlobalValues["PartyLeader"] = nil :: Player?
ServerGlobalValues["CurrentLevel"] = nil :: LevelEnum.Level?
ServerGlobalValues["AllowLevelRespawning"] = true -- If true, players can automatically respawn without needing to be revived (Only when in a level, not the lobby

--------------------------------------------------------------------------------------------

return ServerGlobalValues