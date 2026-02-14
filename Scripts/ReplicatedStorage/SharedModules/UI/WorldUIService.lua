-- OmniRal

local WorldUIService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)
local New = require(ReplicatedStorage.Source.Pronghorn.New)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local CustomEnum = require(ReplicatedStorage.Source.SharedModules.Info.CustomEnum)

local GeneralUILibrary = require(ReplicatedStorage.Source.SharedModules.UI.GeneralUILibrary)
local UIBasics = require(ReplicatedStorage.Source.SharedModules.UI.UIBasics)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------
-- Private API --
-----------------

function UpdateHealthLines(Attributes: any, Point: any)
    for _, OldLine in Point.UnitGui.Canvas.Frame.HealthFrame.Back.Lines:GetChildren() do
        OldLine:Destroy()
    end

    local MaxHealth = Attributes.Base:GetAttribute("Health")
    for x = 1, math.round(MaxHealth / 25) - 1  do
        local NewLine = Point.UnitGui.Canvas.Frame.HealthFrame.Back.OGLine:Clone()
        NewLine.Position = UDim2.fromScale( ((25 / MaxHealth) * x), 0.5)
        NewLine.Visible = true
        NewLine.Parent = Point.UnitGui.Canvas.Frame.HealthFrame.Back.Lines
    end
end

function UpdateCurrentDebuff(Attributes: any): any?
    if not Attributes then return end

    local CurrentDebuff = nil
    local DebuffState = "None"
    local DebuffPower = 0
    local LastTime = 0

    for _, Effect in Attributes.Effects:GetChildren() do
        if not Effect then continue end
        if Effect:GetAttribute("IsBuff") or Effect:GetAttribute("Duration") < 0 then continue end
        if not Effect:FindFirstChild("Timer") then continue end
        if Effect.Timer.Value <= 0 --[[or Effect.Timer.Value < LastTime]] then continue end

        local EffectState, EffectPower = "None", 0
        for Key, Value in CustomEnum.DebuffStatePowers do
            if Effect:GetAttribute(Key) == nil then continue end
            if Value < EffectPower then continue end
            EffectState = Key
            EffectPower = Value
        end

        if EffectPower <= 0 then continue end
        if EffectPower < DebuffPower then continue end

        CurrentDebuff = Effect
        DebuffState = EffectState
        DebuffPower = EffectPower
        LastTime = Effect.Timer.Value
    end

    return CurrentDebuff, DebuffState
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------
-- Public API --
----------------

function WorldUIService:AddGradientChangingValues(Gradient: UIGradient, AddForColor: {}?, AddForTransparency: {}?): {}?
    if not Gradient then return end

    local NewValues = {}
    if AddForColor then
        local A = New.Instance("Color3Value", "ColorA", Gradient, {Value = AddForColor[1]})
        local B = New.Instance("Color3Value", "ColorB", Gradient, {Value = AddForColor[2]})
        NewValues["ColorA"] = A
        NewValues["ColorB"] = B

        A.Changed:Connect(function()
            Gradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, A.Value),
                ColorSequenceKeypoint.new(1, B.Value)
            }
        end)

        B.Changed:Connect(function()
            Gradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, A.Value),
                ColorSequenceKeypoint.new(1, B.Value)
            }
        end)

        Gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, A.Value),
            ColorSequenceKeypoint.new(1, B.Value)
        }
    end
        
    if AddForTransparency then
        local A = New.Instance("NumberValue", "TransA", Gradient, {Value = AddForTransparency[1]})
        local B = New.Instance("NumberValue", "TransB", Gradient, {Value = AddForTransparency[2]})
        NewValues["TransA"] = A
        NewValues["TransB"] = B

        A.Changed:Connect(function()
            Gradient.Transparency = NumberSequence.new{
                NumberSequenceKeypoint.new(0, A.Value),
                NumberSequenceKeypoint.new(1, B.Value)
            }
        end)

        B.Changed:Connect(function()
            Gradient.Transparency = NumberSequence.new{
                NumberSequenceKeypoint.new(0, A.Value),
                NumberSequenceKeypoint.new(1, B.Value)
            }
        end)

        Gradient.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, A.Value),
            NumberSequenceKeypoint.new(1, B.Value)
        }
    end

    if not AddForColor and not AddForTransparency then return end
    return NewValues
end

function WorldUIService:GuiPointForUnit(Unit: Model)
    if not Unit then return end
    local Human, Root, Attributes = Unit:FindFirstChild("Humanoid"), Unit:FindFirstChild("HumanoidRootPart"), Unit:FindFirstChild("UnitAttributes")
    if not Human or not Root or not Attributes then return end

    local Connections = {}

    local CurrentDebuff = nil
    local DebuffTimerConnection = nil
    local Events = {"ChildAdded", "ChildRemoved"}

    local Point = Assets.Misc.BillboardGuiContainer.GuiPoint:Clone()
    Point.UnitGui.Canvas.Frame.HealthFrame.Back.OGLine.Visible = false
    Point.UnitGui.Canvas.Frame.HealthFrame.Back.Bar.Size = UDim2.fromScale(1, 1)
    Point.UnitGui.Canvas.Frame.HealthFrame.Back.White.Size = UDim2.fromScale(1, 1)
    Point.StateGui.Canvas.GroupTransparency = 1
    Point.StateGui.SizeOffset = Vector2.new(0, 1.9)

    Point.StateGui:SetAttribute("Hidden", true)
    Point.StateGui:GetAttributeChangedSignal("Hidden"):Connect(function()
        local GoalTransparency, GoalOffset = 1, Vector2.new(0, 1.9)
        if not Point.StateGui:GetAttribute("Hidden") then
            GoalTransparency = 0
            GoalOffset = Vector2.new(0, 2)
        end

        TweenService:Create(Point.StateGui, TweenInfo.new(UIBasics.BaseTweenTime, Enum.EasingStyle.Linear), {SizeOffset = GoalOffset}):Play()
        TweenService:Create(Point.StateGui.Canvas, TweenInfo.new(UIBasics.BaseTweenTime, Enum.EasingStyle.Linear), {GroupTransparency = GoalTransparency}):Play()
    end)

    Point.Parent = Root

    Point.UnitGui.Canvas.Frame.UnitName.Text = Unit.Name

    Attributes.Base:GetAttributeChangedSignal("Health"):Connect(function()
        UpdateHealthLines(Attributes, Point)
    end)

    Attributes.Current.Health.Changed:Connect(function()
        GeneralUILibrary:UpdateHealthBar(Attributes.Current.Health.Value, Attributes.Base:GetAttribute("Health"), Point.UnitGui.Canvas.Frame.HealthFrame.Back.Bar, Point.UnitGui.Canvas.Frame.HealthFrame.Back.White)
        if Attributes.Current.Health.Value <= 0 then
            for _, OldConnection in Connections do
                OldConnection:Disconnect()
            end
        end
    end)

    for _, Event in Events do
        Attributes.Effects[Event]:Connect(function(Effect: any)
            local GotDebuff, GotState = UpdateCurrentDebuff(Attributes)
            if GotDebuff and GotState then
                CurrentDebuff = GotDebuff
                if DebuffTimerConnection then
                    DebuffTimerConnection:Disconnect()
                end
    
                DebuffTimerConnection = CurrentDebuff.Timer.Changed:Connect(function()
                    Point.StateGui.Canvas.Frame.BarFrame.Back.Bar.Size = UDim2.fromScale(CurrentDebuff.Timer.Value / CurrentDebuff:GetAttribute("Duration"), 1)
                end)

                Point.StateGui.Canvas.Frame.StateType.Text = GotState
                Point.StateGui:SetAttribute("Hidden", false)
            else
                Point.StateGui:SetAttribute("Hidden", true)
            end
        end)
    end

    UpdateHealthLines(Attributes, Point)
    --Attributes.States
end

function WorldUIService:SpawnTextDisplay(From: string, Affects: string, DisplayType: string, Position: Vector3, OtherDetails: {[string]: any}?)
    --print("From: ", From, Affects, DisplayType, Position, OtherDetails)
    if not From or not Affects or not DisplayType or not Position then return end

    local Display = Assets.Misc.TextDisplay:Clone()
    Display.Transparency = 1
    Display.CFrame = CFrame.new(Position)
    Display.Parent = Workspace.ClientVisuals

    if DisplayType == CustomEnum.TextDisplayType.HealthGain and OtherDetails then
        Display.Gui.Heal.Text = "+" .. OtherDetails.Amount
        Display.Gui.Heal.Visible = true
        TweenService:Create(Display.Gui.Heal, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0.5), {TextTransparency = 1}):Play()
        TweenService:Create(Display.Gui.Heal.Stroke, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0.5), {Transparency = 1}):Play()
        TweenService:Create(Display.Gui, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = UDim2.new(2, 10, 2, 10)}):Play()

    elseif DisplayType == CustomEnum.TextDisplayType.KillerDamage and OtherDetails then
        Display.Gui.KillerDamage.Text = OtherDetails.Amount
        Display.Gui.KillerDamage.Visible = true
        TweenService:Create(Display.Gui.KillerDamage, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
        TweenService:Create(Display.Gui.KillerDamage.Stroke, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Transparency = 1}):Play()
        TweenService:Create(Display.Gui, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {SizeOffset = Vector2.new(0, -0.1)}):Play()

    elseif DisplayType == CustomEnum.TextDisplayType.Crit and OtherDetails then
        Display.Gui.CritDamage.Text = OtherDetails.Amount
        Display.Gui.CritDamage.Visible = true
        TweenService:Create(Display.Gui.CritDamage, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 1.5), {TextTransparency = 1}):Play()
        TweenService:Create(Display.Gui.CritDamage.Stroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Thickness = 7}):Play()
        TweenService:Create(Display.Gui, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {SizeOffset = Vector2.new(0, 0.5)}):Play()
        task.delay(1.5, function()
            TweenService:Create(Display.Gui.CritDamage.Stroke, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Transparency = 1}):Play()
        end)

    elseif DisplayType == CustomEnum.TextDisplayType.VictimDamage and OtherDetails then
        Display.Gui.VictimDamage.Text = OtherDetails.Amount
        Display.Gui.VictimDamage.Visible = true
        TweenService:Create(Display.Gui.VictimDamage, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
        TweenService:Create(Display.Gui.VictimDamage.Stroke, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()
        TweenService:Create(Display.Gui, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {SizeOffset = Vector2.new(0, -0.1)}):Play()

    elseif DisplayType == CustomEnum.TextDisplayType.Miss or DisplayType == CustomEnum.TextDisplayType.AttackMiss then
        Display.Gui.Miss.Visible = true
        TweenService:Create(Display.Gui.Miss, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
        TweenService:Create(Display.Gui.Miss.Stroke, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Transparency = 1}):Play()
        TweenService:Create(Display.Gui, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {SizeOffset = Vector2.new(0, -0.25)}):Play()

    elseif DisplayType == CustomEnum.TextDisplayType.Evade then
        Display.Gui.Evade.Visible = true
        TweenService:Create(Display.Gui.Evade, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
        TweenService:Create(Display.Gui.Evade.Stroke, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Transparency = 1}):Play()
        TweenService:Create(Display.Gui, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {SizeOffset = Vector2.new(0, -1)}):Play()
    end

    Debris:AddItem(Display, 2)
end

return WorldUIService