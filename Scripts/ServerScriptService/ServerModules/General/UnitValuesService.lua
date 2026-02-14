-- OmniRal
--!nocheck

local UnitValuesService = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)
local New = require(ReplicatedStorage.Source.Pronghorn.New)

local UnitEnum = require(ReplicatedStorage.Source.SharedModules.Info.CustomEnum.UnitEnum)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local BaseAttributes : UnitEnum.BaseAttributes = {
    Health = 100,
    HealthGain = 1,
    Mana = 100,
    ManaGain = 1,
    Armor = 0,
    WalkSpeed = 16,
    AttackSpeed = 0,
    CritChance = 0,
    CritPercent = 0,
    Damage = 0,
    CooldownReduction = 0,
}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local AllValues = {}

local Events = ServerStorage.Events
local Assets = ServerStorage.Assets

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

            if Button.Name ~= "TeamButton" then
                if string.find(Button.Name, "1") then
                    UnitValuesService:AddEffect(Player, 
                        {
                            From = "Bing", 
                            IsBuff = true, 
                            Name = "Test Buff", 
                            Description = "This is a test buff.", 
                            Icon = 0, 
                            Duration = 10, 
                            MaxStacks = 2
                        }, 
                            {Health = 25, Armor = 15, AttackSpeed = 25, WalkSpeed = 4}, 
                            {}
                    )
                elseif string.find(Button.Name, "2") then
                    UnitValuesService:AddEffect(Player, {From = "Bing 2", IsBuff = true, Name = "Test Buff 2", Description = "This is a test buff 2.", Icon = 0, Duration = 15, MaxStacks = 1}, {HealthGain = 7, AttackSpeed = 40, WalkSpeed = 2}, {})
                elseif string.find(Button.Name, "3") then
                    UnitValuesService:AddEffect(Player, {From = "Bing 3", IsBuff = false, Name = "Test Debuff", Description = "This is a test debuff.", Icon = 0, Duration = -1, MaxStacks = 3}, {Health = -25, WalkSpeed = -3, AttackSpeed = -15, HealthGain = -2}, {})
                elseif string.find(Button.Name, "4") then
                    UnitValuesService:CleanAllEffectsWithNames(Player, "Test Debuff")

                elseif string.find(Button.Name, "5") then
                    task.delay(2, function()
                        UnitValuesService:AddEffect(Player, {From = "Bing 4", IsBuff = false, Name = "Test Debuff 2", Description = "This is a test debuff.", Icon = 0, Duration = 4, MaxStacks = 1}, {}, {Break = true})
                    end)

                elseif string.find(Button.Name, "6") then
                    task.delay(2, function()
                        UnitValuesService:AddEffect(Player, {From = "Bing 5", IsBuff = false, Name = "Test Debuff 3", Description = "This is a test debuff.", Icon = 0, Duration = 2, MaxStacks = 1}, {}, {Stunned = true})
                    end)

                elseif string.find(Button.Name, "70") then
                    UnitValuesService:AddEffect(Player, 
                    {
                        From = "Bing 5", 
                        IsBuff = true, 
                        Name = "Test Buff 3", 
                        Description = "This is a test buff.", 
                        Icon = 0, 
                        Duration = -1, 
                        MaxStacks = 1
                    }, {WalkSpeed = 16}, {})
                end
            else
                if Player:GetAttribute("Team") == UnitEnum.Teams.Red.DisplayName then
                    Player:SetAttribute("Team", "Blue")
                else
                    Player:SetAttribute("Team", "Red")
                end
                if Player.Character then
                    Player.Character:SetAttribute("Team", Player:GetAttribute("Team"))
                end
            end

            task.delay(2, function()
                Button:SetAttribute("Debounce", false)
            end)
        end)
    end

    for _, Button in pairs(Workspace:GetChildren()) do
        if not string.find(Button.Name, "TestEffect_") and Button.Name ~= "TeamButton" then continue end
        SetButton(Button)
    end
end

function CreateStateFolder(UnitValues: UnitEnum.UnitValues, Unit: Model)
    if not Unit then return end

    local Folder = Assets.Misc.UnitValues:Clone()
    Folder.Parent = Unit
    
    for Stat, Value in UnitValues.Base do
        Folder.Base:SetAttribute(Stat, Value + (UnitValues.Offsets[Stat]))
    end

    for State, Value in UnitValues.States do
        if typeof(Value) == "boolean" then
            Folder.States:SetAttribute(State, Value)

        elseif typeof(Value) == "table" then
            Folder.States:SetAttribute(State, Value.Active)
            if State == "Taunt" then
                Folder.States.TauntGoal.Value = Value.Goal
            elseif State == "Panc" then
                Folder.States.PanicFrom.Value = Value.From
            end
        end
    end

    Folder.Current.Health.Value = UnitValues.Base.Health + UnitValues.Offsets.Health
    Folder.Current.Health:SetAttribute("Max", UnitValues.Base.Health + UnitValues.Offsets.Health)

    Folder.Current.Mana.Value = UnitValues.Base.Mana + UnitValues.Offsets.Mana
    Folder.Current.Mana:SetAttribute("Max", UnitValues.Base.Mana + UnitValues.Offsets.Mana)

    return Folder
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function UnitValuesService:AddEffect(Unit: Player | Model, EffectDetails: UnitEnum.EffectDetails, EffectAttributes: UnitEnum.BaseAttributes?, EffectStates: UnitEnum.BaseStates): UnitEnum.Effect
    local UnitValues : UnitEnum.UnitValues = AllValues[Unit]
    
    if not UnitValues then return end
    if not UnitValues.Folder then return end
    if not UnitValues.Folder.Parent then return end

    local SpawnTime = os.clock()

    local MaxStacks = EffectDetails.MaxStacks or 1
    local MaxStacksReached, CopyEffectFound = false, false

    if #UnitValues.Effects > 0 then
        local FoundEffects = {}
        for _, Effect in ipairs(UnitValues.Effects) do
            if Effect.Name ~= EffectDetails.Name then continue end
            CopyEffectFound = true

            table.insert(FoundEffects, Effect)
        end
        
        if #FoundEffects >= MaxStacks then
            MaxStacksReached = true

            local Difference = #FoundEffects - EffectDetails.MaxStacks
            if Difference > 0 then
                for x = 1, Difference do
                    UnitValuesService:CleanThisEffect(Unit, FoundEffects[1 + x])
                end
            end
        end
    end
    
    if MaxStacksReached or CopyEffectFound then
        UnitValuesService:SetTimeOfExistingEffects(Unit, EffectDetails.Name, EffectDetails.Duration, SpawnTime)
        if MaxStacksReached then return end
    end

    local NewConfig = New.Instance("Configuration", EffectDetails.Name, UnitValues.Folder.Effects)
    NewConfig:SetAttribute("IsBuff", EffectDetails.IsBuff)
    NewConfig:SetAttribute("Description", EffectDetails.Description)
    NewConfig:SetAttribute("Icon", EffectDetails.Icon)
    NewConfig:SetAttribute("Duration", EffectDetails.Duration)

    for Key, Value in EffectStates do
        NewConfig:SetAttribute(Key, Value or nil)
    end

    local Timer = New.Instance("NumberValue", "Timer", NewConfig, {Value = EffectDetails.Duration})
    local TimerTween = TweenService:Create(Timer, TweenInfo.new(EffectDetails.Duration, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {Value = 0})
    TimerTween:Play()

    local NewEffect: UnitEnum.Effect
    NewEffect = {
        From = EffectDetails.From,
        IsBuff = EffectDetails.IsBuff,
        Name = EffectDetails.Name,
        Icon = EffectDetails.Icon,
        Description = EffectDetails.Description,
        
        SpawnTime = SpawnTime,
        Duration = EffectDetails.Duration,
        MaxStacks = EffectDetails.MaxStacks,

        Offsets = {
            Health = EffectAttributes.Health or 0,
            HealthGain = EffectAttributes.HealthGain or 0,
            Mana = EffectAttributes.Mana or 0,
            ManaGain = EffectAttributes.ManaGain or 0,
            Armor = EffectAttributes.Armor or 0,
            WalkSpeed = EffectAttributes.WalkSpeed or 0,
            AttackSpeed = EffectAttributes.AttackSpeed or 0,
            CritChance = EffectAttributes.CritChance or 0,
            CritPercent = EffectAttributes.CritPercent or 0,
            Damage = EffectAttributes.Damage or 0,
            CooldownReduction = EffectAttributes.CooldownReduction or 0,
        },

        States = {
            Immune = EffectStates.Immune or false,
            Silenced = EffectStates.Silenced or false,
            Disarmed = EffectStates.Disarmed or false,
            Break = EffectStates.Break or false,
            Rooted = EffectStates.Rooted or false,
            Stunned = EffectStates.Stunned or false,
            Tracked = EffectStates.Tracked or false,
            Panic = EffectStates.Panic or false,
            Taunt = EffectStates.Taunt or false,
        },

        CleanFunction = function()
            --print("Cleaning Effect ", EffectDetails.Name, " in ", EffectDetails.Duration, " seconds.")
            if NewEffect.CleanDelay then
                task.cancel(NewEffect.CleanDelay)
            end

            if EffectDetails.Duration > 0 then
                NewEffect.CleanDelay = task.delay(EffectDetails.Duration, function()
                    UnitValuesService:CleanThisEffect(Unit, NewEffect)
                end)

                if TimerTween then
                    TimerTween:Cancel()
                end

                Timer.Value = EffectDetails.Duration
                TimerTween = TweenService:Create(Timer, TweenInfo.new(EffectDetails.Duration, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {Value = 0})
                TimerTween:Play()
            end
        end,

        CleanDelay = nil,

        Config = NewConfig,
    }

    NewEffect.CleanFunction()

    table.insert(UnitValues.Effects, NewEffect)

    --print(Unit.Name, " Updated States: ", UnitValues)
    UnitValuesService:RecalculateAttributes(Unit, BaseAttributes)

    warn("Done applying ", Unit, NewEffect)

    return NewEffect
end

function UnitValuesService:SetTimeOfExistingEffects(Unit: Player | Model, EffectName: string, NewDuration: number, NewSpawnTime: number?)
    local UnitValues : UnitEnum.UnitValues = AllValues[Unit]
    if not UnitValues then return end

    for _, Effect : UnitEnum.Effect in ipairs(UnitValues.Effects) do
        if Effect.Name ~= EffectName then continue end
        Effect.Duration = NewDuration 
        Effect.SpawnTime = NewSpawnTime or Effect.SpawnTime
        Effect.CleanFunction()
    end
end

function UnitValuesService:CleanThisEffect(Unit: Player | Model, ThisEffect: UnitEnum.Effect)
    local UnitValues : UnitEnum.UnitValues = AllValues[Unit]
    if not UnitValues then return end

    for Num, Effect in ipairs(UnitValues.Effects) do
        if Effect ~= ThisEffect then continue end
        if Effect.Folder then
            Effect.Folder:Destroy()
            Effect.Folder = nil
        end
        table.remove(UnitValues.Effects, Num)
    end

    UnitValuesService:RecalculateAttributes(Unit, BaseAttributes)
    --print(Unit.Name, " Updated States: ", UnitValues)
end

function UnitValuesService:CleanAllEffectsWithNames(Unit: Player | Model, EffectName: string)
    local UnitValues : UnitEnum.UnitValues = AllValues[Unit]
    if not UnitValues then return end

    pcall(function()
        local CleanThese = {}
        for Num, Effect in ipairs(UnitValues.Effects) do
            if Effect.Name ~= EffectName then continue end
            if Effect.Folder then
                Effect.Folder:SetAttribute("Clean", true)
                Debris:AddItem(Effect.Folder, 1)
                Effect.Folder = nil
            end
            table.insert(CleanThese, Effect)
        end

        for _, Effect in ipairs(CleanThese) do
            if not Effect then continue end
            local CleanNum = table.find(UnitValues.Effects, Effect)
            if not CleanNum then continue end

            table.remove(UnitValues.Effects, CleanNum)
        end

        UnitValuesService:RecalculateAttributes(Unit, BaseAttributes)
    end)

    --print(Unit.Name, " Updated States: ", UnitValues)
end

function UnitValuesService:CleanAllEffects(Unit: Player | Model, Only: string?)
    local UnitValues : UnitEnum.UnitValues = AllValues[Unit]
    if not UnitValues then return end

    pcall(function()
        local CleanThese = {}
        for Num, Effect : UnitEnum.Effect in ipairs(UnitValues.Effects) do
            if not Effect.Folder then continue end
            if Only == "Buffs" then
                if not Effect.IsBuff then continue end
            elseif Only == "Debuffs" then
                if Effect.IsBuff then continue end
            end
            Effect.Folder:SetAttribute("Clean", true)
            Debris:AddItem(Effect.Folder, 1)
            Effect.Folder = nil
            table.insert(CleanThese, Effect)
        end

        for _, Effect in ipairs(CleanThese) do
            if not Effect then continue end
            local CleanNum = table.find(UnitValues.Effects, Effect)
            if not CleanNum then continue end

            table.remove(UnitValues.Effects, CleanNum)
        end

        UnitValuesService:RecalculateAttributes(Unit, BaseAttributes)
    end)
end

function UnitValuesService:RecalculateAttributes(Unit: Player | Model, NewBaseAttributes: {}?)
    local UnitValues = AllValues[Unit] :: UnitEnum.UnitValues
    if not UnitValues then return end

    local OriginalMaxHealth = UnitValues.Base.Health + UnitValues.Offsets.Health
    local OriginalMaxMana = UnitValues.Base.Mana + UnitValues.Offsets.Mana
    local PercentHealth = 1
    local PercentMana = 1
    if UnitValues.Folder then
        PercentHealth = UnitValues.Folder.Current.Health.Value / OriginalMaxHealth
        PercentMana = UnitValues.Folder.Current.Mana.Value / OriginalMaxMana
        --print("Current Health: ", UnitValues.Folder.Current.Health.Value)
    end

    if NewBaseAttributes then
        for Key, Num in NewBaseAttributes do
            if not UnitValues.Base[Key] then continue end
            UnitValues.Base[Key] = Num
        end
    end

    local Offsets : UnitEnum.BaseAttributes = {
        Health = 0,
        HealthGain = 0,
        Mana = 0,
        ManaGain = 0,
        Armor = 0,
        WalkSpeed = 0,
        AttackSpeed = 0,
        CritPercent = 0,
        CritChance = 0,
        Damage = 0,
        CooldownReduction = 0,
    }

    --local PercentOffsets : UnitEnum.BaseAttributes
    local States : UnitEnum.BaseStates = {
        Immune = false,
        Silenced = false,
        Disarmed = false,
        Break = false,
        Rooted = false,
        Stunned = false,
        Tracked = false,
        Panic = {
            Active = false,
            From = nil,
        },
        Taunt = {
            Active = false,
            Goal = nil,
        },
    }

    for _, Effect : UnitEnum.Effect in UnitValues.Effects do
        if not Effect then continue end
        for Stat, Change in Effect.Offsets :: any do
            Offsets[Stat] += Change
            --[[if typeof(Change) == "number" then
                Offsets[Name] += Change
            elseif typeof(Change) == "string" then
                PercentOffsets[Name] += Change
            end]]
        end

        for State, Value in Effect.States :: any do
            if typeof(Value) == "boolean" then
                if Value then
                    AllValues[State] = true
                end
            
            elseif typeof(Value) == "table" then
                if Value.Active then
                    AllValues[State].Active = true
                    if State == "Taunt" then
                        AllValues[State].Goal = Value.Goal
                    elseif State == "Panic" then
                        AllValues[State].From = Value.From
                    end
                end
            end
        end
    end

    for Stat, Change in Offsets do
        UnitValues.Offsets[Stat] = Change
    end

    if UnitValues.Folder then
        for Stat, Value in UnitValues.Base do
            local Limit = UnitEnum.BaseAttributeLimits[Stat]
            if Limit then
                --print(Stat, " limit is ", Limit)
                UnitValues.Folder.Base:SetAttribute(Stat, math.clamp(Value + UnitValues.Offsets[Stat], Limit.Min, Limit.Max))
            else
                UnitValues.Folder.Base:SetAttribute(Stat, Value + UnitValues.Offsets[Stat])
            end
        end

        for State, Value in States do
            if typeof(Value) == "boolean" then
                UnitValues.Folder.States:SetAttribute(State, Value)

            elseif typeof(Value) == "table" then
                UnitValues.Folder.States:SetAttribute(State, Value.Active)
                if State == "Taunt" then
                    UnitValues.Folder.States.TauntGoal.Value = Value.Goal
                elseif State == "Panc" then
                    UnitValues.Folder.States.PanicFrom.Value = Value.From
                end
            end
        end

        if not NewBaseAttributes then
            if UnitValues.Folder.Base:GetAttribute("Health") ~= OriginalMaxHealth then
                UnitValues.Folder.Current.Health.Value = PercentHealth * (UnitValues.Base.Health + UnitValues.Offsets.Health)
            end
            if UnitValues.Folder.Base:GetAttribute("Mana") ~= OriginalMaxMana then
                UnitValues.Folder.Current.Mana.Value = PercentMana * (UnitValues.Base.Mana + UnitValues.Offsets.Mana)
            end
        else
            UnitValues.Folder.Current.Health.Value = UnitValues.Base.Health + UnitValues.Offsets.Health
            UnitValues.Folder.Current.Mana.Value = UnitValues.Base.Mana + UnitValues.Offsets.Mana
        end

        UnitValues.Folder.Current.Health:SetAttribute("Max", UnitValues.Base.Health + UnitValues.Offsets.Health)
        UnitValues.Folder.Current.Mana:SetAttribute("Max", UnitValues.Base.Mana + UnitValues.Offsets.Mana)
    end
end

function UnitValuesService:AddHistoryEntry(Unit: Player | Model, Entry: UnitEnum.HistoryEntry)
    local UnitValues : UnitEnum.UnitValues = AllValues[Unit]
    if not UnitValues then return end
    if not UnitValues.History then return end

    if not Entry.TimeAdded then
        Entry.TimeAdded = os.clock()
    end

    table.insert(UnitValues.History, Entry)
    --print("History: ", UnitValues.History)

    if Entry.CleanTime then
        task.delay(Entry.CleanTime, function()
            pcall(function()
                for Num, OldEntry in ipairs(UnitValues.History) do
                    if not OldEntry then continue end
                    if OldEntry ~= Entry then continue end
                    table.remove(UnitValues.History, Num)
                end

                --print("History: ", UnitValues.History)
            end)
        end)
    end

    Events.Unit.NewHistoryEntry:Fire(Unit, Entry)
end

function UnitValuesService:CleanHistroy(Unit: Player | Model)
    local UnitValues : UnitEnum.UnitValues = AllValues[Unit]
    if not UnitValues then return end
    if not UnitValues.History then return end

    table.clear(UnitValues.History)
end

-- Returns the entire values table of a unit; attributes, states, effects, etc.
function UnitValuesService:GetFull(Unit: Player | Model | string) : UnitEnum.UnitValues?
    local UnitValues : UnitEnum.UnitValues = AllValues[Unit]
    if not UnitValues then return end

    return UnitValues
end

-- Returns either the whole list of the players current attributes
-- @SingleAttribute = If you only want to know a single attribute
function UnitValuesService:GetAttributes(Unit: Player | Model | string, SinlgeAttribute: string?) : UnitEnum.BaseAttributes | number?
    local UnitValues : UnitEnum.UnitValues = AllValues[Unit]
    if not UnitValues then return end

    local TotalAttributes: UnitEnum.BaseAttributes = {}

    for Key, Value in UnitValues.Base do
        TotalAttributes[Key] = Value + UnitValues.Offsets[Key] -- Adds their base attribute value with the offset amount to get a true current total
    end

    if not TotalAttributes[SinlgeAttribute] then
        return TotalAttributes
    else
        return TotalAttributes[SinlgeAttribute]
    end
end

function UnitValuesService:New(Unit: Player | Model, BaseAttributes: {}?)
    if AllValues[Unit] then
        warn("Attribute Values for ", Unit.Name, " already exists.")
        return
    end

    local Base : UnitEnum.BaseAttributes = {
        Health = 100,
        HealthGain = 1,
        Mana = 50,
        ManaGain = 1,
        Armor = 0,
        WalkSpeed = 16,
        AttackSpeed = 100,
        CritChance = 0,
        CritPercent = 0,
        Damage = 0,
        CooldownReduction = 0,
    }
    
    if BaseAttributes then
        for Key, Num in BaseAttributes do
            if not Base[Key] then continue end
            Base[Key] = Num
        end
    end

    local NewAttributes: UnitEnum.UnitValues = {
        Base = Base,

        Offsets = {
            Health = 0,
            HealthGain = 0,
            Mana = 0,
            ManaGain = 0,
            Armor = 0,
            WalkSpeed = 0,
            AttackSpeed = 0,
            CritChance = 0,
            CritPercent = 0,
            Damage = 0,
            CooldownReduction = 0,
        },

        States = {
            Immune = false,
            Silenced = false,
            Disarmed = false,
            Break = false,
            Rooted = false,
            Stunned = false,
            Tracked = false,
            Taunt = {Active = false},
            Panic = {Active = false},
        },

        Effects = {},
        History = {},
    }

    if Unit:IsA("Player") then
        Unit.CharacterAdded:Connect(function(Character: Model)
            NewAttributes.Folder = CreateStateFolder(NewAttributes, Character)
        end)
    else
        NewAttributes.Folder = CreateStateFolder(NewAttributes, Unit)
    end

    AllValues[Unit] = NewAttributes

    --print(Unit.Name, " States: ", NewAttributes)
end

function UnitValuesService:Remove(Unit: Player | Model)
    if not AllValues[Unit] then return end
    AllValues[Unit] = nil
end

function UnitValuesService:Init()
    TestButtons()

    Remotes:CreateToServer("SetHidden", {"boolean"}, "Reliable", function(Player: Player, Set: boolean)
        if not Player then return end
        if not AllValues[Player] then return end
        if not AllValues[Player].Folder then return end
        if not AllValues[Player].Folder:FindFirstChild("Current") then return end
        AllValues[Player].Folder.Current.Hidden.Value = Set
    end)
end

function UnitValuesService.PlayerAdded(Player: Player)
    UnitValuesService:New(Player)
end

return UnitValuesService