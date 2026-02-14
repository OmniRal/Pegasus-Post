-- OmniRal
--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local CustomEnum = require(ReplicatedStorage.Source.SharedModules.Info.CustomEnum)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Quest = {}
Quest.__index = Quest

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------
-- Private API --
-----------------



------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------
-- Public API --
----------------

function Quest.new(NewQuest: CustomEnum.QuestConstructor) : CustomEnum.Quest
    local QuestModule = ServerScriptService.Source.ServerModules.General.QuestService:FindFirstChild(NewQuest.Name)
    if not QuestModule or #NewQuest.Players <= 0 then return end
    
    local self: CustomEnum.Quest = setmetatable({}, Quest)
    self.Name = NewQuest.Name
    self.Players = NewQuest.Players
    self.Module = QuestModule
    self.Step = 0

    self.Module.Begin(self)

    return self
end

function Quest:Clean()
    local self: CustomEnum.Quest = self
    if not self.Module then return end
    if self.Status ~= "Active" then return end
    if not self.Module.Clean then return end

    self.Module.Clean(self)
end

return Quest