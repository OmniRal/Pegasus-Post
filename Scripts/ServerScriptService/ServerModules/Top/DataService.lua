--!nocheck

local DataService = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local ServerScriptService = game:GetService('ServerScriptService')
local MarketplaceService = game:GetService("MarketplaceService")

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)

local ProfileService = require(ServerScriptService.Source.ProfileService)

local ProductInfo = require(ReplicatedStorage.Source.SharedModules.Info.ProductInfo)
local ShopInfo = require(ReplicatedStorage.Source.SharedModules.Info.ShopInfo)
local BadgeInfo = require(ReplicatedStorage.Source.SharedModules.Info.BadgeInfo)
local WeaponInfo = require(ReplicatedStorage.Source.SharedModules.Info.WeaponInfo)

local RelicEnum = require(ReplicatedStorage.Source.SharedModules.Info.CustomEnum.RelicEnum)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

DataService.ProfileReady = false
DataService.ServiceReady = false

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ProfileTemplate = {
	LogInTimes = 0,
	LoggedInDuration = 0,
	LastLoggedIn = 0,

    Stats = {
        TimePlayed = {Seconds = 0, Minutes = 0, Hours = 0, Days = 0},
        Weapons = {},
    },

    Level = 1,
    XP = 0,
}

local ProfileStore = ProfileService.GetProfileStore('OmniBlot_PegasusPost_Alpha_1', ProfileTemplate)

local Profiles = {}

local RNG = Random.new()

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------
-- Private API --
-----------------

function PlayerAdded(Player)
    while not DataService.ProfileReady or not DataService.ServiceReady do
        task.wait()
    end

	Player:SetAttribute("Joined", os.time())

	local profile = ProfileStore:LoadProfileAsync("Player_" .. Player.UserId)
    print("Loaded profile : ", profile)
    if profile ~= nil then
        profile:AddUserId(Player.UserId) -- GDPR compliance
        profile:Reconcile() -- Fill in missing variables from ProfileTemplate (optional)
        --print("R: ", profile)
        profile:ListenToRelease(function()
            Profiles[Player] = nil
            -- The profile could"ve been loaded on another Roblox server:
            Player:Kick("Could not load player data (1)")
        end)

        if Player:IsDescendantOf(Players) == true then
            Profiles[Player] = profile
            -- A profile has been successfully loaded:
			profile.Data.LogInTimes += 1
			profile.Data.LastLoggedIn = os.time()

			Player:SetAttribute("DataLoaded", true)
            Remotes.DataService.DataUpdate:Fire(Player, Profiles[Player].Data)
        else
            -- Player left before the profile loaded:
            profile:Release()
        end
    else
        -- The profile couldn"t be loaded possibly due to other
        --   Roblox servers trying to load this profile at the same time:
        Player:Kick("Could not load player data (2)")
    end
end

function PlayerRemoving(Player)
    task.wait(0.25)
	local profile = Profiles[Player]
    if profile ~= nil then
		profile.Data.LoggedInDuration += os.time() - Player:GetAttribute("Joined")
        profile:Release()
    end
end

--[[function DataService.Client:GetIndex(...)
	return DataService:GetIndex(...)
end]]

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------
-- Public API --
----------------

function DataService:GetProfileTable(Player: Player)
    while not self.ServiceReady do
        task.wait()
    end
    while Profiles[Player] == nil do
        task.wait()
    end
    return Profiles[Player].Data
end

function DataService:GetIndex(Player, Index)
	self:WaitForPlayerDataLoaded(Player)
	return Profiles[Player].Data[Index]
end

function DataService:SetIndex(Player: Player, Index: string | {}, Value: string? | number? | boolean? | {}?)
	self:WaitForPlayerDataLoaded(Player)

    if typeof(Index) == "string" then
        Profiles[Player].Data[Index] = Value
    else
        local ThisData = Profiles[Player].Data
        for _, Key in ipairs(Index) do
            ThisData = ThisData[Key]
        end
        ThisData = Value
    end

    Remotes.DataService.DataUpdate:Fire(Player, Profiles[Player].Data)
end

function DataService:IncrementIndex(Player, Index, Increment)
	self:WaitForPlayerDataLoaded(Player)
	Profiles[Player].Data[Index] += Increment
    Remotes.DataService.DataUpdate:Fire(Player, Profiles[Player].Data)
end

function DataService:WaitForPlayerDataLoaded(Player)
	if not Player:GetAttribute("DataLoaded") then
		Player:GetAttributeChangedSignal("DataLoaded"):Wait()
	end
end

function DataService:Init()
    print("Data Service Init...")

    Remotes:CreateToClient("DataUpdate", {"table"}, "Reliable")

    --[[for WeaponName, W_Info in pairs(WeaponInfo) do
        local WeaponUnlocked = false
        if W_Info.UnlockedBy == "Default" then
            WeaponUnlocked = true
        end 

        local Skins = {}
        for SkinName, S_Info in pairs(W_Info.Skins) do
            local SkinUnlocked = false
            if S_Info.UnlockedBy == "Default" then
                SkinUnlocked = true
            end
            Skins[SkinName] = {Unlocked = SkinUnlocked, Date = "2023:" .. RNG:NextInteger(1, 12) .. ":30:" .. RNG:NextInteger(1, 23) .. ":00", IsNew = true}
        end

        ProfileTemplate.Weapons[WeaponName] = {Unlocked = WeaponUnlocked, Date = "2024:" .. RNG:NextInteger(1, 12) .. ":30:" .. RNG:NextInteger(1, 23) .. ":00", IsNew = true, Skins = Skins, EquippedSuit = "Default"}

        ProfileTemplate.Stats.Weapons[WeaponName] = {
            TimePlayed = {Seconds = 0, Minutes = 0, Hours = 0, Days = 0},
            Kills = 0,
            Assists = 0,
        }
    end]]

    self.ProfileReady = true

    ------------------------------------------------------------------------------------------------------------------

    print("Template Ready : ", ProfileTemplate)
end

function DataService:Deferred()
    print("Data Service Deferred...")
    self.ServiceReady = true
end

function DataService.PlayerAdded(Player: Player)
    task.spawn(function()
        PlayerAdded(Player)
    end)
end

function DataService.PlayerRemoving(Player: Player)
    task.spawn(function()
        PlayerRemoving(Player)
    end)
end

return DataService
