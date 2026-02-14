-- OmnIRal
--!nocheck

-- Start history in units; able to track

local UnitManagerService = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)

local UnitEnum = require(ReplicatedStorage.Source.SharedModules.Info.CustomEnum.UnitEnum)
local UnitValuesService = require(ServerScriptService.Source.ServerModules.General.UnitValuesService)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local UPDATE_RATE = 1

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local RunSystem : RBXScriptConnection?

local LastUpdate = os.clock()
local Units = {}

local RNG = Random.new()

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function SetupUnit(Model: any, Player: Player?)
    task.spawn(function()
        local Unit = Player or Model

        local Human, Root, Values = Model:WaitForChild("Humanoid"), Model:WaitForChild("HumanoidRootPart"), Model:WaitForChild("UnitValues")
        if not Human or not Root or not Values then return end

        Model.Parent = Workspace.Units
        local HealthChangeConnection = Values.Current.Health.Changed:Connect(function()
            if Values.States:GetAttribute("Dead") then return end

            if Values.Current.Health.Value <= 0 then
                UnitValuesService:CleanAllEffects(Unit)
                Values.States:SetAttribute("Dead", true)
                Human.Health = 0
                Units[Unit].Dead = true
            end
        end)

        Human.MaxSlopeAngle = 45

        table.insert(Units[Unit].Connections, HealthChangeConnection)
    end)
end

local function UpdateUnits()
    for Unit, Info in Units do
        if not Info then continue end
        if not Info.Model then continue end

        if Info.Dead then
            for _, OldConnection in Info.Connections do
                if not OldConnection then continue end
                OldConnection:Disconnect()
            end

            Info[Unit] = nil
            continue
        end

        local UnitValues = UnitValuesService:GetFull(Unit)
        if not UnitValues then continue end

        if Unit:IsA("Player") then
            if not Players:FindFirstChild(Unit.Name) then
                Units[Unit] = nil
                continue
            end

            if not Info.Model and Unit.Character then
                Info.Model = Unit.Character
            end
        end

        if not Info.Model then continue end

        pcall(function()
            UnitManagerService:ApplyHealthGain("Unit Manager", Unit,
                math.clamp(UnitValues.Base.HealthGain + UnitValues.Offsets.HealthGain, UnitEnum.BaseAttributeLimits.HealthGain.Min, UnitEnum.BaseAttributeLimits.HealthGain.Max)
            )
            UnitManagerService:ApplyManaGain("Unit Manager", Unit,
                math.clamp(UnitValues.Base.ManaGain + UnitValues.Offsets.ManaGain, UnitEnum.BaseAttributeLimits.ManaGain.Min, UnitEnum.BaseAttributeLimits.ManaGain.Max)
            )
        end)
    end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Apply damage to another unit.
-- @Source = damage APPLYER.
-- @Victim = damage RECEIVER.
-- @DamageAmount = how much damage.
-- @DamageName = what the damage is called; e.g. "Thor's Hammer".
-- @DamageType = which kind of damage type it is, based on UnitEnum.DamageTyoes; if enabled in GlobalValues.
-- @CritPossible = if it should calculate potentially applying a crit.
function UnitManagerService:ApplyDamage(Source: Player | Model | string, Victim: Player | Model, DamageAmount: number, DamageName: string, DamageType: string?, CritPossible: boolean?)
    if not Source or not Victim then return end

    local VictimModel = Victim
    if Victim:IsA("Player") then
        VictimModel = Victim.Character
    end

    if Victim.Name == "T1" or Victim.Name == "T2" then
        VictimModel.Humanoid:TakeDamage(DamageAmount)
    end

    if not VictimModel then return end
    if not VictimModel:FindFirstChild("Humanoid") then return end
    local VictimValues = UnitValuesService:GetFull(Victim)
    if not VictimValues then return end

    VictimValues.Folder.Current.Health.Value -= DamageAmount

    if Source:IsA("Player") then
        local SourceHistoryEntry : UnitEnum.HistoryEntry = {
            Source = Source,
            Name = DamageName,
            Type = "DamageDealt",
            TimeAdded = os.time(),
            CleanTime = UnitEnum.DefaultHistoryEntryCleanTime,
            Amount = DamageAmount
        }
        UnitValuesService:AddHistoryEntry(Source, SourceHistoryEntry)
    end

    if Victim:IsA("Player") then
        local VictimHistoryEntry : UnitEnum.HistoryEntry = {
            Source = Source,
            Name = DamageName,
            Type = "DamageDealt",
            TimeAdded = os.time(),
            CleanTime = UnitEnum.DefaultHistoryEntryCleanTime,
            Amount = DamageAmount,
        }
        UnitValuesService:AddHistoryEntry(Victim, VictimHistoryEntry)
    end
end

function UnitManagerService:ApplyHealthGain(Source: Player | Model | string, Receiver: Player | Model, Amount: number, GainName: string?)
    if not Source or not Receiver then return end

    local ReceiverModel = Receiver
    if Receiver:IsA("Player") then
        ReceiverModel = Receiver.Character
    end

    if not ReceiverModel then return end

    local ReceiverAttributes, AttributesFolder = UnitValuesService:Get(Receiver) :: UnitEnum.UnitAttributes, ReceiverModel:FindFirstChild("UnitAttributes")
    if not ReceiverAttributes or not AttributesFolder then return end

    AttributesFolder.Current.Health.Value = math.clamp(AttributesFolder.Current.Health.Value + Amount, 0, ReceiverAttributes.Base.Health + ReceiverAttributes.Offsets.Health)

    if not GainName then return end

    local From, Affects, DisplayType, Position, OtherDetails = Source, Receiver.Name, UnitEnum.TextDisplayType.HealthGain, Vector3.new(0, 0, 0), {Amount = Amount}

    if typeof(Source) ~= "string" then
        From = Source.Name
    end

    local RootPart = ReceiverModel.PrimaryPart
    if not RootPart then return end

    Position = RootPart.Position + Vector3.new(
        math.sign(RNG:NextNumber(-1, 1)) * RNG:NextNumber(0.75, 1.25),
        math.sign(RNG:NextNumber(-1, 1)) * RNG:NextNumber(0.75, 1.25),
        math.sign(RNG:NextNumber(-1, 1)) * RNG:NextNumber(0.75, 1.25)
    )

    local HistoryEntry : UnitEnum.HistoryEntry = {
        Source = Source,
        Name = GainName,
        Type = UnitEnum.HistoryEntryType.HealthGain,
        TimeAdded = os.time(),
        CleanTime = UnitEnum.DefaultHistoryEntryCleanTime,
        Amount = Amount,
    }

    UnitValuesService:AddHistoryEntry(Receiver, HistoryEntry)
    Remotes.VisualService.SpawnTextDisplay:FireAll(From, Affects, DisplayType, Position, OtherDetails)
end

function UnitManagerService:ApplyManaGain(Source: Player | Model | string, Receiver: Player | Model, Amount: number, GainName: string?)
    if not Source or not Receiver then return end

    local ReceiverModel = Receiver
    if Receiver:IsA("Player") then
        ReceiverModel = Receiver.Character
    end

    if not ReceiverModel then return end

    local ReceiverAttributes, AttributesFolder = UnitValuesService:Get(Receiver) :: UnitEnum.UnitAttributes, ReceiverModel:FindFirstChild("UnitAttributes")
    if not ReceiverAttributes or not AttributesFolder then return end

    AttributesFolder.Current.Mana.Value = math.clamp(AttributesFolder.Current.Mana.Value + Amount, 0, ReceiverAttributes.Base.Mana + ReceiverAttributes.Offsets.Mana)
end

function UnitManagerService:RemoveUnit(Unit: Player | Model)
    if not Unit then return end
    if not Units[Unit] then return end
    Units[Unit] = nil
end

function UnitManagerService:AddUnit(Unit: Player | Model)
    print("Attempting to add unit: ", Unit)
    if Unit:IsA("Player") then
        if not Unit:GetAttribute("Team") then
            Unit:SetAttribute("Team", "Blue")
        end
        
        local Char = Unit.Character :: Model
        Units[Unit] = {Model = Char, Dead = false, Connections = {}}
        Char:SetAttribute("Team", Unit:GetAttribute("Team"))

        SetupUnit(Unit.Character, Unit)
        Remotes.UnitManagerService.PlayerUnitAdded:Fire(Unit)

    elseif Unit:IsA("Model") then
        if Units[Unit] then return end
        Units[Unit] = {Model = Unit, Dead = false, Connections = {}}

        SetupUnit(Unit)
    end
end

function UnitManagerService:Run()
    if RunSystem then
        RunSystem:Disconnect()
    end

    RunSystem = RunService.Heartbeat:Connect(function(DeltaTime: number)
        if os.clock() < LastUpdate + UPDATE_RATE then return end

        LastUpdate = os.clock()

        UpdateUnits()
    end)
end

function UnitManagerService:Stop()
    if RunSystem then
        RunSystem:Disconnect()
    end
    RunSystem = nil
end

function UnitManagerService:Init()
    Remotes:CreateToClient("PlayerUnitAdded", {}, "Reliable")
end

function UnitManagerService:Deferred()
    UnitManagerService:Run()
end

return UnitManagerService