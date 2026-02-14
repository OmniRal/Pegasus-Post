--OmniRal

local CharacterService = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)
local New = require(ReplicatedStorage.Source.Pronghorn.New)

local ServerGlobalValues = require(ServerScriptService.Source.ServerModules.Top.ServerGlobalValues)

local UnitManagerService = require(ServerScriptService.Source.ServerModules.General.UnitManagerService)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Sides = {-1, 1}
local RNG = Random.new()

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function TestButtons()
    local function SetButton(Button: any)
        if not Button then return end
        Button:SetAttribute("Debounce", false)

        Button.Touched:Connect(function(Hit: any)
            if Button:GetAttribute("Debounce") or not Hit.Parent then return end
            local Player = Players:FindFirstChild(Hit.Parent.Name)
            if not Player then return end

            Button:SetAttribute("Debounce", true)

            --[[if Button.Name == "DamageButton" then
                --CharacterService:ApplyDamage("Test Damage", Player, Button:GetAttribute("Amount"), Button:GetAttribute("DamageName"), Button:GetAttribute("Type"))
            else
                --CharacterService:ApplyHealthGain("Test Heal", Player, Button:GetAttribute("Amount"), "Jizz")
            end]]

            task.delay(2, function()
                Button:SetAttribute("Debounce", false)
            end)
        end)
    end

    for _, Button in pairs(Workspace:GetChildren()) do
        if Button.Name ~= "DamageButton" and Button.Name ~= "HealButton" then continue end
        SetButton(Button)
    end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function CharacterService:SetupCharacter(Player: Player, SpawnHere: CFrame?)
    task.spawn(function()
        while Player.Character == nil do task.wait() end

        local Character = Player.Character
        if Character:GetAttribute("Loaded") then return end

        warn("Loading", Player, "'s character!")
        Character:SetAttribute("Loaded", true)

        local Human, Root = Character:WaitForChild("Humanoid"), Character:WaitForChild("HumanoidRootPart")

        if SpawnHere then
            Character:PivotTo(SpawnHere)
        end

        for _, Part in pairs(Character:GetDescendants()) do
            if not Part:IsA("BasePart") then continue end
            Part.CollisionGroup = "Players"
        end

        task.delay(0.25, function()
            if not ServerGlobalValues.InLevel then return end
            UnitManagerService:AddUnit(Player)
        end)

        --[[for _, Sound in pairs(Assets.Misc.CharacterSounds:GetChildren()) do
            print(Sound.Name, " added to ", Player.Name)
            Sound:Clone().Parent = Root
        end]]

        --AddNewAnimateScript(Character)
    end)
end

-- Plainly adds or subtracts to a units attribute; e.g. players passively gaining health over time.
function CharacterService:IncrementAttribute(Source: Player | Model | string, Receiver: Player | Model, Amount: number)
    if not Source or not Receiver then return end

    local ReceiverModel = Receiver
    if Receiver:IsA("Player") then
        ReceiverModel = Receiver.Character
    end

    if not ReceiverModel then return end
end

function CharacterService:Init()
    --TestButtons()
end

return CharacterService