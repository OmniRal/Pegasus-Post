-- OmniRal

local BadgeService = {}

local Players = game:GetService("Players")
local CoreBadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local BadgeInfo = require(ReplicatedStorage.Source.SharedModules.Info.BadgeInfo)

local DataService = require(ServerScriptService.Source.ServerModules.Top.DataService)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------
-- Private API --
-----------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------
-- Public API --
----------------

function BadgeService:CheckPlayerHasBadge(Player: Player, BadgeName: string): boolean?
    if not Player or not BadgeName then return end
    local Info = BadgeInfo[BadgeName]
    if not Info then return end
    
    local Success, Result = pcall(function()
        return CoreBadgeService:UserHasBadgeAsync(Player.UserId, Info.BadgeID)
    end)

    if not Success then return end
    if not Result then return end
    return true
end

function BadgeService:CheckPlayerHasMultipleBadges(Player: Player, BadgeNames: {string})
    if not Player or not BadgeNames then return end
end

function BadgeService:Init()
    Remotes:CreateToServer("RequestClaimBadgeReward", {"string"}, "Returns", function(Player: Player, BadgeName: string)
        local PlayerData = DataService:GetProfileTable(Player)
        if not PlayerData then return end
        if not PlayerData.Badges then return end
        local Info = PlayerData.Badges[BadgeName]
        if not Info or not BadgeInfo[BadgeName] then return end
        if not Info.Complete or BadgeInfo[BadgeName].RewardType == "None" then return end
        if Info.RewardClaimed then return end

        DataService:UpdateBadgeProgress(Player, BadgeName, 0, true)

        return 1
    end)
end

function BadgeService:Deferred()
    --[[workspace.BadgeTester.Touched:Connect(function(Hit: any)
        if workspace.BadgeTester:GetAttribute("Debounce") then return end
        if not Hit then return end
        if not Hit.Parent then return end
        if not Hit.Parent:FindFirstChild("Humanoid") then return end
        local Player = Players:FindFirstChild(Hit.Parent.Name)
        if not Player then return end

        workspace.BadgeTester:SetAttribute("Debounce", true)
        
        DataService:UpdateBadgeProgress(Player, "TestBadge", 1)

        task.wait(2)

        workspace.BadgeTester:SetAttribute("Debounce", false)
    end)]]
end

return BadgeService