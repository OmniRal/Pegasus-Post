-- OmniRal

local CoreGameService = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local PhysicsService = game:GetService("PhysicsService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)
local New = require(ReplicatedStorage.Source.Pronghorn.New)

local ServerGlobalValues = require(ServerScriptService.Source.ServerModules.Top.ServerGlobalValues)
local CustomEnum = require(ReplicatedStorage.Source.SharedModules.Info.CustomEnum)

local SignalService = require(ServerScriptService.Source.ServerModules.General.SignalService)
local CharacterService = require(ServerScriptService.Source.ServerModules.Player.CharacterService)
local Utility = require(ReplicatedStorage.Source.SharedModules.Other.Utility)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local PlayerDied = SignalService.PlayerDied

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local PlayerOrder: {Player} = {}
local PlayerValues: {
    [Player]: {
        RespawnTime: number,
        LastDiedLocation: CFrame?,
    }
} = {}
local HandlingPlayerLeaving = false

local Assets = ServerStorage.Assets
local SharedAssets = ReplicatedStorage.Assets

local RNG = Random.new()

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function SpawnCharacter(Player: Player)
    if not Player then return end
    --Player:LoadCharacter()
    Player:LoadCharacterAsync()
end

local function SpawnAllPlayers()
    for _, Player in Players:GetPlayers() do
        if not Player then continue end
        if Player.Character then continue end
        Player:LoadCharacter()
    end
end

local function SetupRespawning(Player: Player, Character: any)
    if Players.CharacterAutoLoads then return end

    local PValues = PlayerValues[Player]
    if not PValues then return end

    local Human = Character:WaitForChild("Humanoid")

    -- CHeck for when the player dies in order to respawn them
    PValues.DeathConnection = Human.Died:Connect(function()
        task.spawn(function()
            if ServerGlobalValues.InLevel and not ServerGlobalValues.AllowLevelRespawning then return end

            PValues.RespawnTime = Players.RespawnTime

            for x = Players.RespawnTime, 0, -1 do
                task.wait(1)
                PValues.RespawnTime -= 1
            end

            SpawnCharacter(Player)

            PValues.DeathConnection:Disconnect()
            PValues.DeathConnection = nil
        end)

        PlayerDied:Fire(Player)
    end)
end

local function SetupCollisions()
    PhysicsService:RegisterCollisionGroup("Players")
    PhysicsService:RegisterCollisionGroup("NoClip")
    PhysicsService:CollisionGroupSetCollidable("Default", "Players", true)
    PhysicsService:CollisionGroupSetCollidable("Players", "Players", false)
    PhysicsService:CollisionGroupSetCollidable("Default", "NoClip", false)
end

local function ToggleParticles(Player: Player, Parts: {BasePart}, Particles: {{Name: string, Set: boolean}})
    if not Player then return end

    for _, Part in pairs(Parts) do
        if not Part then continue end
            
        for _, Info in pairs(Particles) do
            if not Part:FindFirstChild(Info.Name) then continue end
            Part[Info.Name].Enabled = Info.Set
        end
    end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Handle when the player requests to the server to respawn
function CoreGameService:RequestSpawning(Player: Player, Delay: number): boolean
    if not Player then return false end

    local PValues = PlayerValues[Player]
    if not PValues then return false end

    if PValues.RespawnTime > 0 then return false end -- If there's time left in respawning, deny request

    if Player.Character then
        local Human = Player.Character:FindFirstChild("Humanoid")
        if Human and Human.Health > 0 then
           return false -- If the player is alive, deny request
        end
    end

    task.delay(Delay, function()
        SpawnCharacter(Player)
    end)

    return true
end

function CoreGameService:Init()
    print("Core Game Service Init...")

    SetupCollisions()
    
    Remotes:CreateToClient("DropObject", {})

    Remotes:CreateToServer("RequestSpawning", {}, "Returns", function(Player: Player, Delay: number)
        return CoreGameService:RequestSpawning(Player, Delay)
    end)

    Remotes:CreateToServer("RequestResetCharacter", {}, "Unreliable", function(Player: Player)
        if not Player or not Player.Character then return end
        local Human = Player.Character:FindFirstChild("Humanoid")
        if not Human then return end

        Human.Health = 0
    end)

    Remotes:CreateToServer("ToggleParticles", {"any", "any"}, "Unreliable", function(Player: Player, Parts: {BasePart}, Particles: {{Name: string, Set: boolean}})
        ToggleParticles(Player, Parts, Particles)
    end)
end

function CoreGameService:Deferred()
    print("Core Game Service Deferred...")

    local PlaceId = game.PlaceId

    if PlaceId == 15353246109 then
        return
    end

    if ServerGlobalValues.CleanupAssetDump then
        New.Clean(Workspace, "AssetDump")
    end

    --RandomFunction()
end

function CoreGameService.PlayerAdded(Player: Player)
    table.insert(PlayerOrder, Player)

    local Order_ID = table.find(PlayerOrder, Player) -- Incase two players enter at the same time
    Player:SetAttribute("Order_ID", Order_ID)

    PlayerValues[Player] = {
        RespawnTime = 0,
        LastDiedLocation = nil,
    }
    
    Player.CharacterAdded:Connect(function(Character: any)
        CharacterService:SetupCharacter(Player)

        SetupRespawning(Player, Character)
    end)

    if ServerGlobalValues.InLevel then return end

    if not Players.CharacterAutoLoads then
        SpawnCharacter(Player)
    end
    
    -- Sometimes Player.CharacterAdded doesn't fire when the player first enters the server
    -- Defer this to make sure LoadCharacter doesn't run twice
    task.defer(function()
        CharacterService:SetupCharacter(Player)
        SetupRespawning(Player, Player.Character)
    end)
end

function CoreGameService.PlayerRemoving(Player: Player)
    task.spawn(function()
        while HandlingPlayerLeaving do task.wait() end -- Prevent player order from getting messed up when two players may leave at the same time
        HandlingPlayerLeaving = true

        local Index = table.find(PlayerOrder, Player)
        if Index then
            table.remove(PlayerOrder, Index)
        end

        if PlayerValues[Player] then
            PlayerValues[Player] = nil
        end

        HandlingPlayerLeaving = false
    end)
end

return CoreGameService