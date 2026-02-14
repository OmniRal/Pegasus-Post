-- OmniRal
--!nocheck

local GeneralUILibrary = {}

local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local New = require(ReplicatedStorage.Source.Pronghorn.New)

local PlayerInfo = require(StarterPlayer.StarterPlayerScripts.Source.Other.PlayerInfo)
local UIBasics = require(ReplicatedStorage.Source.SharedModules.UI.UIBasics)
local ColorPalette = require(ReplicatedStorage.Source.SharedModules.Other.ColorPalette)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local BASE_TWEEN_TIME = UIBasics.BaseTweenTime

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Camera = Workspace.CurrentCamera

local WhiteBarTweens = {}

local Events = ReplicatedStorage.Events
local Assets = ReplicatedStorage.Assets

local RNG = Random.new()

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function UpdateDrag(Input: InputObject)
	
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Closes the windows in teh MainUI.
-- @PlayerGui: The Players Gui folder so it can search for the MainUI object.
-- @Exclude: If there's any windows to exclude from being closed, put the attribute name inside the table. - Example: {"InventoryOpenTo"} = Will not close the Bows / Abilities menu.
function GeneralUILibrary:CloseMainUIWindows(PlayerGui: PlayerGui, Exclude: {}?)
	if not PlayerGui then return end
	if not PlayerGui:FindFirstChild("MainUI") then return end

	-- These are the options you can put in the exclude table.
	local ListOfAttributesAndDefaultValues = {
		InventoryOpenTo = "None",
		BattlePassOpen = false,
		CoinShopOpen = false,
		DailyRewardsOpen = false,
		CreditsOpen = false,
	}

	for Attribute, DefaultValue in pairs(ListOfAttributesAndDefaultValues) do
		if Exclude and table.find(Exclude, Attribute) then continue end
		PlayerGui.MainUI:SetAttribute(Attribute, DefaultValue)
	end
end

-- Updates the Blue size depending on if any major UI elements are enabled.
-- @PlayerGui: The Players Gui folder so it can search for the MainUI object.
function GeneralUILibrary:UpdateUIBlur(PlayerGui: PlayerGui)
	if not Lighting:FindFirstChild("UIBlur") then return end

	local NewSize = 0

	if PlayerGui:FindFirstChild("MainUI") then
		if PlayerGui.MainUI:GetAttribute("InventoryOpenTo") ~= "None" then
			NewSize = 25
		end
		if PlayerGui.MainUI:GetAttribute("CoinShopOpen") then
			NewSize = 25
		end
	end

	if PlayerGui:FindFirstChild("BattlePass") then
		if PlayerGui.BattlePass.Enabled then
			NewSize = 25
		end
	end

	if Lighting.UIBlur.Size == NewSize then return end
	TweenService:Create(Lighting.UIBlur, TweenInfo.new(BASE_TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = NewSize}):Play()
end

function GeneralUILibrary:SpawnSparkle(Parent: any, StartSize: NumberRange, FinishSize: NumberRange?, RaiseAmount: NumberRange?, Lifetime: NumberRange)
	if not Parent then return end

	StartSize = RNG:NextNumber(StartSize.Min, StartSize.Max)
	FinishSize = RNG:NextNumber(FinishSize.Min, FinishSize.Max) or StartSize
	RaiseAmount = RNG:NextNumber(RaiseAmount.Min, RaiseAmount.Max) or 0
	Lifetime = RNG:NextNumber(Lifetime.Min, Lifetime.Max)

	local StartPosition = UDim2.fromScale(0.5 + RNG:NextNumber(-0.45, 0.45), 0.5 + RNG:NextNumber(-0.45, 0.45))

	local NewSparkle = script.Assets.OGSparkle:Clone()
	NewSparkle.Name = "Sparkle"
	NewSparkle.Position = StartPosition
	NewSparkle.Size = UDim2.fromScale(StartSize, StartSize)
	NewSparkle.Parent = Parent

	local Tween1 = TweenService:Create(NewSparkle, TweenInfo.new(Lifetime * 0.25, Enum.EasingStyle.Linear), {Position = StartPosition + UDim2.fromScale(0, RaiseAmount * 0.25), ImageTransparency = 0})
	local Tween2 = TweenService:Create(NewSparkle, TweenInfo.new(Lifetime * 0.75, Enum.EasingStyle.Linear), {Position = StartPosition + UDim2.fromScale(0, RaiseAmount * 0.75), ImageTransparency = 1, Size = UDim2.fromScale(FinishSize, FinishSize)})	
	Tween1.Completed:Connect(function()
		Tween2:Play()
	end)	
	Tween2.Completed:Connect(function()
		NewSparkle:Destroy()
	end)

	Tween1:Play()
end

-- Checks to see if the current dragging element is positioned outside of its original bounding box. Intended to drop items of your inventory
-- @Element : The gui object that was dragged
-- @Box : The gui object that is used as the bounding box
function GeneralUILibrary:CheckDragElementDropped(PlayerGui: PlayerGui, Element: GuiObject, Box: GuiObject, DropPhysically: boolean?): (boolean, GuiObject?, Vector3?)
	if not Element or not Box then return false end

	local Position = Element.AbsolutePosition
	local BoxPosition, BoxSize = Box.AbsolutePosition, Box.AbsoluteSize

	-- Check if Element is out inside the Box
	if Position.X >= BoxPosition.X - (BoxSize.X / 2) and Position.X <= BoxPosition.X + (BoxSize.X / 2) and Position.Y >= BoxPosition.Y - (BoxSize.Y / 2) and Position.Y <= BoxPosition.Y + (BoxSize.Y / 2) then
		return false
	end

	-- Check if the mouse is hovering over another UI element
	local MousePosition = UserInputService:GetMouseLocation()
	local GuiInset = GuiService:GetGuiInset()

	local GuiObjects = PlayerGui:GetGuiObjectsAtPosition(MousePosition.X - GuiInset.X, MousePosition.Y - GuiInset.Y)
	for n, Object in GuiObjects do
		if Object ~= Element then continue end
		table.remove(GuiObjects, n)
	end

	if #GuiObjects > 0 then

		return false, GuiObjects[1]
	end

	if DropPhysically then
		-- Convert the Element's screen position to a 3D world position; for where to drop the item
		local CameraRay = Camera:ViewportPointToRay(Position.X, Position.Y, 1000)
		local NewRay = Workspace:Raycast(CameraRay.Origin, CameraRay.Direction * -1000)
		if NewRay then
			if NewRay.Position then
				return true, nil, NewRay.Position
			end
		end

		return false
	end

	return true
end

-- Adds attributes that are triggered by toggling a button, hovering on it, and pressing it
-- @ButtonFrame : The main GUI object container
-- @Button : The _actual_ button object the player can click / tap
-- @ToggleFromActivation : When true, the ON attribute will toggle when the button is activated. Otherwise, the ON attribute can _only_ be set to true if it's not already
-- @DraggingElement : If set to a GuiObject, this will be allowed to be dragged around
-- @DragDelay : How long the button needs to be held down before being dragging is allowed
-- @StartDrag : What should happen at the start of dragging it
-- @StopDrag : What should happen when the drag is released
function GeneralUILibrary.AddBaseButtonInteractions(
	ButtonFrame: GuiObject, 
	Button: GuiObject, 
	ToggleFromActivation: boolean?, 
	DraggingElement: boolean?,
	DragDelay: number?,
	DragCondition: (() -> (boolean?))?,
	StartDrag: ((GuiObject, GuiObject?) -> ())?,
	StopDrag: ((GuiObject, GuiObject?) -> ())?
)
	if not ButtonFrame or not Button then return end

	ButtonFrame:SetAttribute("On", false) -- For toggle / state of the button.
	ButtonFrame:SetAttribute("Hover", false) -- For mouse hover.
	ButtonFrame:SetAttribute("Pressed", false) -- For clicking down on the button.
	ButtonFrame:SetAttribute("Locked", false)

	if DraggingElement then
		ButtonFrame:SetAttribute("Dragging", false)
	end

	local InputHandler = nil
	local DragDelayThread: thread? = nil

	Button.MouseEnter:Connect(function()
		if Button:GetAttribute("Locked") then return end
		ButtonFrame:SetAttribute("Hover", true)
	end)

	Button.MouseLeave:Connect(function()
		ButtonFrame:SetAttribute("Hover", false)
	end)

	Button.InputBegan:Connect(function(Input)
		if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then return end
		if Button:GetAttribute("Locked") then return end

		if InputHandler then
			InputHandler:Disconnect()
		end

		ButtonFrame:SetAttribute("Pressed", true)

		if DraggingElement then
			if not DragCondition() then return end
			if not DragDelay then
				Button:SetAttribute("Dragging", true)
				Events.UI.StartDraggingUI:Fire(Input.Position, Button, if DraggingElement == Button then Button else DraggingElement, StartDrag)
			
			else
				if DragDelayThread then
					task.cancel(DragDelayThread)
				end

				DragDelayThread = task.delay(DragDelay, function()
					Button:SetAttribute("Dragging", true)
					Events.UI.StartDraggingUI:Fire(Input.Position, Button, if DraggingElement == Button then Button else DraggingElement, StartDrag)
				end)
			end
		end

		InputHandler = Input.Changed:Connect(function()
			if Input.UserInputState ~= Enum.UserInputState.End then return end
			if InputHandler then
				InputHandler:Disconnect()

				if DraggingElement then
					Events.UI.StopDraggingUI:Fire(Button, if DraggingElement == Button then Button else DraggingElement, StopDrag)
				end
			end

			InputHandler = nil
			ButtonFrame:SetAttribute("Pressed", false)
		end)
	end)

	Button.Activated:Connect(function()
		if Button:GetAttribute("Locked") then return end
		if ToggleFromActivation then
			ButtonFrame:SetAttribute("On", not ButtonFrame:GetAttribute("On"))
		else
			if not ButtonFrame:GetAttribute("On") then
				ButtonFrame:SetAttribute("On", true)
			end
		end
	end)

	Button:GetAttributeChangedSignal("Locked"):Connect(function()
		if Button:GetAttribute("Locked") then
			Button:SetAttribute("On", false)
			Button:SetAttribute("Hover", false)
			Button:SetAttribute("Pressed", false)
		end
	end)
end

-- Checks if a Text UI Object has a UI Stroke in it. If it does, whenever the Texts' transparency changes, the UI Stroke transparency will match it.
function GeneralUILibrary:MatchUIStrokeToTextTransparency(Object: TextLabel | TextBox | TextButton)
	if not Object then return end
	if not Object:FindFirstChild("Stroke") then return end
	Object:GetPropertyChangedSignal("TextTransparency"):Connect(function()
		Object.Stroke.Transparency = Object.TextTransparency
	end)
end

function GeneralUILibrary:SetCloseButton(CloseButton: any, CloseAction: () -> ())
	if not CloseButton then return end

	GeneralUILibrary.AddBaseButtonInteractions(CloseButton, CloseButton.Button)

	CloseButton:GetAttributeChangedSignal("On"):Connect(function()
		if PlayerInfo.UILock.Set ~= "None" then return end
		if not CloseButton:GetAttribute("On") then return end

		CloseButton:SetAttribute("On", false)
		
		--UISounds.CloseConfirm:Play()
		TweenService:Create(CloseButton.Main.Stroke, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, true), {Thickness = 6}):Play()
		TweenService:Create(CloseButton.Back.Stroke, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, true), {Thickness = 9}):Play()
		TweenService:Create(CloseButton.Shadow.Stroke, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, true), {Thickness = 9}):Play()

		CloseAction()
	end)

	CloseButton:GetAttributeChangedSignal("Hover"):Connect(function()
		if CloseButton:GetAttribute("Hover") then
			if PlayerInfo.UILock.Set ~= "None" then return end
			TweenService:Create(CloseButton.Main, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = UDim2.fromScale(1.1, 1.1)}):Play()
			TweenService:Create(CloseButton.Back, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = UDim2.fromScale(1.1, 1.1)}):Play()
			TweenService:Create(CloseButton.Shadow, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = UDim2.fromScale(1.1, 1.1)}):Play()
			--UISounds.GeneralHover_2:Play()

		else
			TweenService:Create(CloseButton.Main, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = UDim2.fromScale(1, 1)}):Play()
			TweenService:Create(CloseButton.Back, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = UDim2.fromScale(1, 1)}):Play()
			TweenService:Create(CloseButton.Shadow, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = UDim2.fromScale(1, 1)}):Play()
		end
	end)

	CloseButton:GetAttributeChangedSignal("Pressed"):Connect(function()
		if CloseButton:GetAttribute("Pressed") then
			if PlayerInfo.UILock.Set ~= "None" then return end
			TweenService:Create(CloseButton.Main.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.4, 0.4)}):Play()
			--UISounds.ClosePress:Play()
		else
			TweenService:Create(CloseButton.Main.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.7, 0.7)}):Play()

		end
	end)
end

-- Used for UI elements such as health or mana bars. Smoothly animates the bar to display the players current stat
-- @Current : Current value of the stat (the bar represents this number) (e.g. Current health = 100)
-- @Max : Max this stat can be (e.g. Max health = 150)
-- @Bar : The UI element (frame, imagelabel, etc) the gets tweened
-- @WhiteBar : This is a bar hidden under the main bar (Bar) that shows the difference in the stat change
-- @WhiteBarDelay : How long before the white bar gets resized to be the same as the main bar
-- @Instant : If true, skips the tweening
function GeneralUILibrary:UpdateBar(Current: number, Max: number, Bar: Frame, WhiteBar: Frame?, WhiteBarDelay: number?, Instant: boolean?)
    if not Bar or not WhiteBar then return end

    local LastMax = Bar:GetAttribute("LastMax") or Max
    local LastCurrent = Bar:GetAttribute("LastCurrent") or Max
    WhiteBarDelay = WhiteBarDelay or UIBasics.WhiteBarDelay

	if not Instant then
		TweenService:Create(Bar, TweenInfo.new(BASE_TWEEN_TIME / 2, Enum.EasingStyle.Linear), {Size = UDim2.fromScale(math.clamp(Current / Max, 0, 1), 1)}):Play()

		if LastMax == Max and WhiteBar then
			if Current < LastCurrent then
				TweenService:Create(WhiteBar, TweenInfo.new(BASE_TWEEN_TIME / 2, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, WhiteBarDelay), {Size = UDim2.fromScale(math.clamp(Current / Max, 0, 1), 1)}):Play()
			else
				TweenService:Create(WhiteBar, TweenInfo.new(BASE_TWEEN_TIME / 2, Enum.EasingStyle.Linear), {Size = UDim2.fromScale(math.clamp(Current / Max, 0, 1), 1)}):Play()
			end
		end
	
	else
		Bar.Size = UDim2.fromScale(math.clamp(Current / Max, 0, 1), 1)

		if WhiteBar then
			WhiteBar.Size = UDim2.fromScale(math.clamp(Current / Max, 0, 1), 1)
		end
	end

    Bar:SetAttribute("LastMax", Max)
    Bar:SetAttribute("LastCurrent", Current)
end

function GeneralUILibrary:SetBarGradientTransparency(Gradient: any)
    Gradient.Percent.Changed:Connect(function()
        local Percent = Gradient.Percent.Value

        if Percent == 0 then
            Gradient.Transparency = NumberSequence.new{
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 1)
            }
        elseif Percent == 1 then
            Gradient.Transparency = NumberSequence.new{
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 0)
            }
        else
            Gradient.Transparency = NumberSequence.new{
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(Percent, 0),
                NumberSequenceKeypoint.new(Percent + 0.001, 1),
                NumberSequenceKeypoint.new(1, 1)
            }
        end
    end)
end

function GeneralUILibrary:UpdateBarPercent(Current: number, Max: number, BarPercent: Frame, WhitePercent: Frame, WhiteBarDelay: number?)
    if not BarPercent or not WhitePercent then return end

    local LastMax = BarPercent:GetAttribute("LastMax") or Max
    local LastCurrent = BarPercent:GetAttribute("LastCurrent") or Max
    WhiteBarDelay = WhiteBarDelay or UIBasics.WhiteBarDelay

    TweenService:Create(BarPercent, TweenInfo.new(BASE_TWEEN_TIME / 2, Enum.EasingStyle.Linear), 
	{Value = Current / Max}):Play()

    if LastMax == Max then
        if Current < LastCurrent then
            TweenService:Create(WhitePercent, TweenInfo.new(BASE_TWEEN_TIME / 2, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, WhiteBarDelay), {Value = Current / Max}):Play()
        else
            TweenService:Create(WhitePercent, TweenInfo.new(BASE_TWEEN_TIME / 2, Enum.EasingStyle.Linear), {Value = Current / Max}):Play()
        end
    end

    BarPercent:SetAttribute("LastMax", Max)
    BarPercent:SetAttribute("LastCurrent", Current)
end

function GeneralUILibrary:GetNumberSingleDec(Num: number, Add: number?): string?
    if not Num then return end

    local StringNum = tonumber(Num)
    local DotNum = 0

    for x = 1, string.len(StringNum) do
        if string.sub(StringNum, x, x) ~= "." then continue end
        DotNum = x
    end
    return string.sub(StringNum, 1, DotNum + 1 + Add)
end

function GeneralUILibrary:SetGroupTransparencyForFrame(Frame: Frame, UIObjects: {{Object: any, Properties: {string}}}, IncludeBaseFrame: boolean?, StartTransparency: number?)
	if not Frame or not UIObjects then return end
	if #UIObjects <= 0 then return end

	local GroupTransparency = New.Instance("NumberValue", "GroupTransparency", Frame, {Value = -1})

	GroupTransparency.Changed:Connect(function()
		if IncludeBaseFrame then
			Frame.BackgroundTransparency = GroupTransparency.Value
		end

		for _, Info in UIObjects do
			if not Info then continue end
			if not Info.Object then continue end
			for _, Property in Info.Properties do
				if not Info.Object[Property] then continue end
				local BaseTransparency = Info.Object:FindFirstChild("Base" .. Property)
				if not BaseTransparency then
					BaseTransparency = New.Instance("NumberValue", "Base" .. Property, Info.Object, {Value = Info.Object[Property]})
					BaseTransparency.Changed:Connect(function()
						Info.Object[Property] = math.clamp(BaseTransparency.Value + GroupTransparency.Value, 0, 1)		
					end)
				end
				Info.Object[Property] = math.clamp(BaseTransparency.Value + GroupTransparency.Value, 0, 1)
			end
		end
	end)

	GroupTransparency.Value = StartTransparency or 0
end

function GeneralUILibrary:SetHoppingText(For: TextLabel, OffsetPosition: UDim2?)
    if not For then return end

	if not OffsetPosition then
		OffsetPosition = UDim2.fromScale(0, 0)
	end

    for _, OldChar in pairs(For:GetChildren()) do
        if not string.find(OldChar.Name, "Char") then continue end
        OldChar:Destroy()
    end

    local BaseBounds = For.TextBounds

    local Length = string.len(For.Text)
    local Params = Instance.new("GetTextBoundsParams")
    Params.Font = Font.new("rbxassetid://12187365977", Enum.FontWeight.Heavy, Enum.FontStyle.Italic)
    Params.Size = BaseBounds.Y
    Params.Width = BaseBounds.X

    --print(Params.Width, BaseBounds.Y)

    local AllChars = {}
    for x = 1, Length do
        local Char = string.sub(For.Text, x, x)
        Params.Text = Char
        local Bounds = TextService:GetTextBoundsAsync(Params)

        local NewChar = For:Clone()
        NewChar.Name = "Char" .. x
        NewChar.Text = Char
        NewChar.Size = UDim2.new(0, Bounds.X, 0, Bounds.Y)
        NewChar.Parent = For

        local YScaleDiff = math.clamp((Bounds.Y / For.AbsoluteSize.Y), 0.1, 1)
        NewChar.Size = UDim2.new(0, Bounds.X * math.abs(YScaleDiff), 0, Bounds.Y * math.abs(YScaleDiff))

        --print(Char, Bounds, (Bounds.Y / For.AbsoluteSize.Y), YScaleDiff)

        for _, Junk in pairs(NewChar:GetChildren()) do
            Junk:Destroy()
        end

        local LastChar = AllChars[#AllChars]
        if #AllChars > 0 then
            for _, ThisChar in pairs(AllChars) do
                ThisChar.Position -= UDim2.fromOffset((NewChar.AbsoluteSize.X / 2), 0)
            end
            LastChar = AllChars[#AllChars]
            NewChar.Position = LastChar.Position + UDim2.fromOffset((LastChar.AbsoluteSize.X / 2) + (NewChar.AbsoluteSize.X / 2), 0)
        else
            NewChar.Position = UDim2.fromScale(0.5, 0.5)
        end

        table.insert(AllChars, NewChar)
    end

    local BasePosition, BaseSize = For.AbsolutePosition, For.AbsoluteSize

    for n = 1, #AllChars do
        local Char = AllChars[n]
        local Position, Size = Char.AbsolutePosition, Char.AbsoluteSize
        
        local Pos_DiffX = (Position.X + (Size.X / 2)) - BasePosition.X
        
        Char.Position = UDim2.new((Pos_DiffX / BaseSize.X) + OffsetPosition.X.Scale, 0, 0.5 + OffsetPosition.Y.Scale, 0)
        Char.Size = UDim2.new(Size.X / BaseSize.X, 0, math.clamp(Size.Y / BaseSize.Y, 0.1, 2), 0)

        Char:SetAttribute("OriginalPosition", Char.Position)
    end

    For:SetAttribute("Hop", false)

    local HopThread = nil
    local HopTweens = {}

    For:GetAttributeChangedSignal("Hop"):Connect(function()
        if HopThread then
            task.cancel(HopThread)
        end
        for _, OldTween in pairs(HopTweens) do
            if not OldTween then continue end
            OldTween:Cancel()
        end
        HopTweens = {}

        for n = 1, #AllChars do
            local Char = AllChars[n]
            if not Char then continue end

            Char.Position = Char:GetAttribute("OriginalPosition")
        end

        if For:GetAttribute("Hop") then
            HopThread = task.spawn(function()
                while true do
                    HopTweens = {}
                    for n = 1, #AllChars do
                        local Char = AllChars[n]
                        if not Char then continue end

                        Char.Position = Char:GetAttribute("OriginalPosition")
                        local Tween1 = TweenService:Create(Char, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.In, 0, false, ((n - 1) * 0.15)), {Position = Char.Position + UDim2.fromScale(0, -0.1)})
                        local Tween2 = TweenService:Create(Char, TweenInfo.new(0.8, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {Position = Char:GetAttribute("OriginalPosition")})

                        Tween1.Completed:Connect(function()
                            Tween1 = nil
                            Tween2:Play()
                        end)

                        table.insert(HopTweens, Tween1)
                        table.insert(HopTweens, Tween2)

                        Tween1:Play()
                    end
                    task.wait(1 + #AllChars * (0.15))
                end
            end)
        end
    end)

    For.TextTransparency = 1
end

function GeneralUILibrary:GetTextScaleSize(DummyLabel: TextLabel, Offset: number?): number?
	if not DummyLabel then return end
	DummyLabel.TextSize = 1
	DummyLabel.TextScaled = false
	for x = 2, 100 do
		DummyLabel.TextSize = x
		task.wait()
		if not DummyLabel.TextFits then break end
	end
	return DummyLabel.TextSize + (Offset or -1)
end

function GeneralUILibrary:SetScrollingFrameYSize(Frame: ScrollingFrame)
	if not Frame then return end
	local Grid, Padding = Frame:FindFirstChild("Grid") :: UIGridLayout, Frame:FindFirstChild("Padding") :: UIPadding
	if not Grid or not Padding then return end

	local TotalItems = 0
	for _, Item in Frame:GetChildren() do
		if Item == Grid or Item == Padding then continue end
		if not Item.Visible then continue end
		TotalItems += 1
	end

	Frame.CanvasSize = UDim2.new(0, 0, 0, Grid.AbsoluteContentSize.Y + Padding.PaddingTop.Offset + Padding.PaddingBottom.Offset) 
end

function GeneralUILibrary:SetScrollingFrameEdgeFades(Frame: ScrollingFrame)
	if not Frame then return end
	if not Frame.Parent then return end
	local Gradient = Frame.Parent:FindFirstChild("Gradient") :: UIGradient
	if not Gradient then return end

	local YSize = 0
	local Grid = Frame:FindFirstChild("Grid") :: UIGridLayout
	local List = Frame:FindFirstChild("List") :: UIListLayout

	if Grid then
		YSize = Grid.AbsoluteContentSize.Y - 10
	end
	if List then
		YSize = List.AbsoluteContentSize.Y - 10
	end

	Frame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if Frame.CanvasPosition.Y <= 10 then
			Gradient.Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 0), 
				NumberSequenceKeypoint.new(0.975, 0), 
				NumberSequenceKeypoint.new(1, 1)
			}
		
		elseif Frame.CanvasPosition.Y > 10 and Frame.CanvasPosition.Y < YSize then
			Gradient.Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 1), 
				NumberSequenceKeypoint.new(0.025, 0), 
				NumberSequenceKeypoint.new(0.975, 0), 
				NumberSequenceKeypoint.new(1, 1)
			}

		elseif Frame.CanvasPosition.Y >= YSize then
			Gradient.Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 1), 
				NumberSequenceKeypoint.new(0.025, 0), 
				NumberSequenceKeypoint.new(1, 0)
			}
		end
	end)
end

function GeneralUILibrary:ShowCheck(Check: ImageLabel, SkipAnimation: boolean?, Color: Color3?, StartSize: number?, EndSize: number?)
	if not Check then return end

	Color = Color or ColorPalette.Check
	StartSize = StartSize or 0.75
	EndSize = EndSize or 1

	Check.Visible = true
	Check.ImageColor3 = Color
	
	if SkipAnimation then
		Check.Size = UDim2.fromScale(EndSize, EndSize)
		Check.ImageTransparency = 0
		return
	end

	Check.Size = UDim2.fromScale(StartSize, StartSize)
	TweenService:Create(Check, TweenInfo.new(1.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(EndSize, EndSize), ImageTransparency = 0}):Play()
end

function GeneralUILibrary:CenterNumAndIcon(Base: Frame, Amount: TextLabel, Icon: ImageLabel, Gui: ScreenGui?)
	task.delay(0.25, function()
		local Bounds = Amount.TextBounds

		Icon.Position = UDim2.new(0.5, -Bounds.X / 2, 0, 0)

		local RightEnd = Amount.AbsolutePosition.X + (Bounds.X / 2)
		local LeftEnd = Icon.AbsolutePosition.X - (Icon.AbsoluteSize.X)
		local Center = (LeftEnd + RightEnd) / 2
		local TrueCenter = Amount.AbsolutePosition.X
		local Offset = math.abs(TrueCenter - Center) / 2

		Amount.Position += UDim2.fromOffset(Offset, 0)
		Icon.Position += UDim2.fromOffset(Offset, 0)
	end)
end

-- Finds a ScreenGui that's a copy of the OriginalUI and destroys it
function GeneralUILibrary.CleanSpecificOldGui(Player: Player, OriginalUI: ScreenGui, UIName: string)
	if not Player or not OriginalUI or not UIName then return end
    for _, UI: ScreenGui in Player.PlayerGui:GetChildren() do
        if not UI then continue end
        if UI ~= OriginalUI and UI.Name == UIName then
            UI:Destroy()
            return
        end
    end
end

function GeneralUILibrary.CleanAllOldGuis(Player: Player)
	if not Player then return end
	for _, UI: ScreenGui in Player.PlayerGui:GetChildren() do
		if not UI then continue end
		if not UI:GetAttribute("Keep") then continue end
		UI:Destroy()
	end
end

--[[function GeneralUILibrary:GetTextSize(From: TextLabel | TextButton): Vector2?
	if not From then return end

	local BaseBounds = From.TextBounds
	local Length = string.len(From.Text)
	print("L : ", Length, From.Text)

	print("B: ", BaseBounds)

	local FromFont = From.FontFace
	local Params = Instance.new("GetTextBoundsParams")

	print(FromFont.Family)
	Params.Font = Font.new("rbxasset://fonts/families/Arial.json", FromFont.Weight, FromFont.Style)
	Params.Size = BaseBounds.Y
	Params.Width = BaseBounds.X

	print("W: ", Params.Width)

	local Bounds = TextService:GetTextBoundsAsync(Params)
	print(Bounds)
	return BaseBounds, Bounds
end]]

-- Ethels Sorting methods.
---------------------------------------------------------------------------------------------

function GeneralUILibrary.Alphabetical(A, B)
	return A.Name < B.Name
end

function GeneralUILibrary.ReverseAlphabetical(A, B)
	return B.Name < A.Name
end

function GeneralUILibrary.AlphabeticalAndLowTier(A, B)
	if A.Tier ~= B.Tier then
		if A.Tier == -1 then
			return false
		end
		if B.Tier == -1 then
			return true
		end
		return A.Tier < B.Tier
	end
	return A.Name < B.Name
end

function GeneralUILibrary.AlphabeticalAndHighTier(A, B)
	if A.Tier ~= B.Tier then
		if A.Tier == -1 then
			return true
		end
		if B.Tier == -1 then
			return false
		end
		return A.Tier > B.Tier
	end
	return A.Name < B.Name
end

function GeneralUILibrary.AlphabeticalAndLowPrice(A, B)
	if A.Price ~= B.Price then
		return A.Price < B.Price
	end
	return A.Name < B.Name
end

function GeneralUILibrary.AlphabeticalAndHighPrice(A, B)
	if A.Price ~= B.Price then
		return A.Price > B.Price
	end
	return A.Name < B.Name
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return GeneralUILibrary