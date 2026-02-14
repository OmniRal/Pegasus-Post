-- OmniRal
--!nocheck

local CameraController = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)
local New = require(ReplicatedStorage.Source.Pronghorn.New)
local PlayerInfo = require(StarterPlayer.StarterPlayerScripts.Source.Other.PlayerInfo)
local DeviceController = require(StarterPlayer.StarterPlayerScripts.Source.General.DeviceController)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Spring = require(ReplicatedStorage.Packages.Spring)

local CameraService = Remotes.CameraService

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local TOP_DOWN_VECTOR_BASE = Vector3.new(0, 35, 15)
local FIRST_PERSON_POSITION = Vector3.new(0, -0.5, 0)
local THIRD_PERSON_POSITION = Vector3.new(0, 2, 7)

-- Camera angle limits
local MAX_SIDE_ANGLE = 15
local MAX_VERTICAL_ANGLE_UP = 45
local MAX_VERTICAL_ANGLE_DOWN = 65

-- Input sensitivity
local MOUSE_SENSITIVITY_X = 0.1
local MOUSE_SENSITIVITY_Y = 0.15
local GAMEPAD_SENSITIVITY = 7
local GAMEPAD_DEADZONE = 0.25

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Core references
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Controller state
CameraController.Janitor = Janitor.new()
CameraController.CameraType = New.Var("Empty") -- "None", "TopDown", "FirstPerson", "ThirdPerson"
CameraController.RotateCharacter = false

-- Camera angles and input
local CameraAngleX = 0
local CameraAngleY = 0
local MouseDeltaX = 0
local MouseDeltaY = 0
local PreviousMouseDeltaX = 0
local PreviousMouseDeltaY = 0

-- Gamepad input
local GamepadX = 0
local GamepadY = 0

-- Shoulder positioning
local ShoulderPosition = THIRD_PERSON_POSITION
local ShoulderOffsetX = 0
local ShoulderOffsetY = 0

-- Camera transitions
local CameraLerp = {Start = nil, State = false, T = 0}
local CameraOrigin = {Focus = nil, RelativeOffset = nil, Distance = 0}

-- Character waist manipulation
local OriginWaistC0 = nil
local WaistOffset = {X = 0, Y = 0, Z = 0, XAngle = 0, ZAngle = 0}

-- Camera shake system
local CameraShake = Spring.new(Vector3.new(0, 0, 0))
CameraShake.Damper = 0.1
CameraShake.Speed = 25

local RNG = Random.new()

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Handle character transparency for different camera modes
local function AdjustCharacterTransparency(transparency: number)
	for _, part in pairs(LocalPlayer.Character:GetChildren()) do
		if part:IsA("BasePart") then
			if part.Name == "Head" then
				-- Hide head and face in first person
				part.LocalTransparencyModifier = transparency
				if part:FindFirstChild("face") then
					part.face.LocalTransparencyModifier = transparency
				end
			else
				-- Handle arms differently for first person view
				if not string.find(part.Name, "Arm") and not string.find(part.Name, "Hand") then
					part.LocalTransparencyModifier = transparency
				elseif string.find(part.Name, "Arm") or string.find(part.Name, "Hand") then
					--print(part.Name, " ! ! !")
					local ySize, goalSize = part.Size.Y, 1
					if transparency == 1 then
						goalSize = 0.5
					end
					-- Note: This size change can cause character death - needs fixing
					part.Size = Vector3.new(goalSize, ySize, goalSize)
				end
			end
		elseif part:IsA("Hat") or part:IsA("Accessory") then
			part:FindFirstChild("Handle").LocalTransparencyModifier = transparency
		end
	end
end

-- Restore mouse behavior when window regains focus
local function WindowFocus()
	local cameraType = CameraController.CameraType:Get()
	if cameraType == "FirstPerson" or cameraType == "ThirdPerson" then
		if DeviceController.CurrentDevice:Get() ~= "Mobile" then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			UserInputService.MouseIconEnabled = false
		end
	end
end

-- Update camera angles based on input delta
local function UpdateCameraAngles(deltaVector: Vector2)
	CameraAngleX -= (deltaVector.X * MOUSE_SENSITIVITY_X)
	CameraAngleY = math.clamp(CameraAngleY - deltaVector.Y * MOUSE_SENSITIVITY_Y, -MAX_VERTICAL_ANGLE_DOWN, MAX_VERTICAL_ANGLE_UP)

	-- Store deltas for shoulder offset calculations
	MouseDeltaX = deltaVector.X
	MouseDeltaY = deltaVector.Y
	PreviousMouseDeltaX = deltaVector.X
	PreviousMouseDeltaY = deltaVector.Y
end

-- Handle all input types (mouse, gamepad, touch)
local function HandleInput(action, state, inputObject)
	local cameraType = CameraController.CameraType:Get()
	if state == Enum.UserInputState.Change and (cameraType == "FirstPerson" or cameraType == "ThirdPerson") then
		local deltaX = inputObject.Delta.X
		local deltaY = inputObject.Delta.Y

		if inputObject.UserInputType == Enum.UserInputType.Gamepad1 then
			if inputObject.KeyCode == Enum.KeyCode.Thumbstick2 then
				-- Process gamepad right stick input
				GamepadX = inputObject.Position.X
				GamepadY = -inputObject.Position.Y
				
				-- Apply deadzone
				if math.abs(GamepadX) <= GAMEPAD_DEADZONE then
					GamepadX = 0
				end
				if math.abs(GamepadY) <= GAMEPAD_DEADZONE then
					GamepadY = 0
				end

				-- Apply sensitivity
				GamepadX *= GAMEPAD_SENSITIVITY
				GamepadY *= GAMEPAD_SENSITIVITY
			end
		else
			-- Handle mouse/touch input
			UpdateCameraAngles(Vector2.new(deltaX, deltaY))
		end
	end
end

-- Calculate shoulder offset based on camera movement for dynamic feel
local function CalculateShoulderOffset(cameraType: string)
	local xOffsetLimits = NumberRange.new(0, 0)
	local yOffsetLimits = NumberRange.new(-0.25, 0.25)
	local yAdd = 1.5

	if cameraType == "ThirdPerson" then
		xOffsetLimits = NumberRange.new(-3, 3)
		yOffsetLimits = NumberRange.new(-0.5, 0.5)
		yAdd = 0
	end
	
	-- Smooth shoulder X offset based on mouse movement
	local diffX = ((MouseDeltaX / 7) - ShoulderOffsetX)
	ShoulderOffsetX = math.clamp((diffX / 10), -xOffsetLimits.Min, xOffsetLimits.Max)
	
	-- Limit Y offset near angle boundaries
	if CameraAngleY + yOffsetLimits.Max >= MAX_VERTICAL_ANGLE_UP then
		yOffsetLimits = NumberRange.new(0, yOffsetLimits.Max)
	elseif CameraAngleY - yOffsetLimits.Max <= -MAX_VERTICAL_ANGLE_DOWN then
		yOffsetLimits = NumberRange.new(yOffsetLimits.Min, 0)
	end

	-- Smooth shoulder Y offset based on mouse movement
	local diffY = ((MouseDeltaY / 7) - ShoulderOffsetY)
	ShoulderOffsetY = math.clamp(ShoulderOffsetY + (diffY / 10), yOffsetLimits.Min, yOffsetLimits.Max)
	
	return yAdd
end

-- Apply camera wobble when character is moving
local function ApplyCameraWobble(cameraType: string, human: Humanoid, rootPart: BasePart)
	local shakeMultiplier = 1
	
	if (human.MoveDirection.Magnitude > 0) and (human:GetState() == Enum.HumanoidStateType.Running) then
		local offset
		
		if cameraType == "FirstPerson" then
			local xSpeed = human.WalkSpeed / 1.5
			local zSpeed = human.WalkSpeed
			local chargeSlow = 0
			
			offset = Vector3.new(
				math.cos(os.clock() * xSpeed) * (PlayerInfo.MoveVector.X / (10 + chargeSlow)),
				math.sin(os.clock() * zSpeed) * (PlayerInfo.MoveVector.Z / (10 + chargeSlow))
			) * 1
			
		elseif cameraType == "ThirdPerson" then
			local velocity = rootPart.Velocity
			offset = Vector3.new(
				math.cos(os.clock() * 8) * 0.1,
				math.sin(os.clock() * 8) * 0.1,
				0
			) * math.clamp(velocity.Magnitude / human.WalkSpeed, 1, 16)
		end

		human.CameraOffset = human.CameraOffset:Lerp(offset, 0.25)
		shakeMultiplier = 2 -- Increase shake when moving
	else
		human.CameraOffset *= 0.9
	end
	
	return shakeMultiplier
end

-- Calculate the main camera CFrame for first/third person modes
local function CalculateCameraCFrame()
	local cameraType = CameraController.CameraType:Get()
	local human = PlayerInfo.Human
	local rootPart = PlayerInfo.Root

	if not human or not rootPart then 
		return CFrame.new(0, 0, 0) 
	end

	-- Base camera rotation
	local baseCFrame = CFrame.new(rootPart.CFrame.Position) 
		* CFrame.Angles(0, math.rad(CameraAngleX), 0) 
		* CFrame.Angles(math.rad(CameraAngleY), 0, 0)
	
	-- Calculate shoulder offset
	local yAdd = CalculateShoulderOffset(cameraType)
	
	-- Position camera at shoulder + offset
	local fromCFrame = baseCFrame * CFrame.new(ShoulderPosition + Vector3.new(ShoulderOffsetX, ShoulderOffsetY + yAdd, 0))
	local toCFrame = baseCFrame * CFrame.new(Vector3.new(ShoulderPosition.X, ShoulderPosition.Y, -1000000))
	
	-- Apply camera wobble
	local shakeMultiplier = ApplyCameraWobble(cameraType, human, rootPart)

	-- Final camera calculations
	local cameraCFrame = CFrame.new(fromCFrame.Position, toCFrame.Position)
	
	-- Apply camera shake
	cameraCFrame *= CFrame.new(
		math.cos(CameraShake.Position.X * 20) * (CameraShake.Position.X * 2) * shakeMultiplier,
		math.sin(CameraShake.Position.Y * 20) * (CameraShake.Position.Y * 2) * shakeMultiplier,
		0
	)
	
	-- Apply character wobble
	cameraCFrame *= CFrame.new(human.CameraOffset.X, human.CameraOffset.Y, human.CameraOffset.Z)

	-- Decay mouse deltas
	MouseDeltaX *= 0.25
	MouseDeltaY *= 0.25

	return cameraCFrame
end

-- Start camera transition with smooth lerping
local function StartCameraTransition()
	CameraLerp.T = 0
	CameraLerp.Start = Camera.CFrame
	CameraLerp.State = true
end

-- Update character waist rotation based on camera angles
local function UpdateCharacterWaist()
	if not CameraController.RotateCharacter then
		if LocalPlayer.Character.UpperTorso:FindFirstChild("Waist") then
			LocalPlayer.Character.UpperTorso.Waist.C0 = OriginWaistC0
		end
		return
	end

	-- Smoothly angle the character's torso based on camera Y angle
	local goalAngleX = math.rad(math.clamp(CameraAngleY, -MAX_VERTICAL_ANGLE_DOWN, MAX_VERTICAL_ANGLE_UP) / 1)
	local diffX = (goalAngleX - WaistOffset.XAngle)
	WaistOffset.XAngle += (diffX / 5)

	-- Add side lean based on mouse movement
	local goalAngleZ = -math.rad(math.clamp(PreviousMouseDeltaX, -MAX_SIDE_ANGLE, MAX_SIDE_ANGLE) / 2)
	local diffZ = (goalAngleZ - WaistOffset.ZAngle)
	WaistOffset.ZAngle += (diffZ / 10)

	-- Apply waist rotation
	LocalPlayer.Character.UpperTorso.Waist.C0 = CFrame.new(WaistOffset.X, WaistOffset.Y, WaistOffset.Z) 
		* CFrame.Angles(WaistOffset.XAngle, 0, WaistOffset.ZAngle)
end

-- Rotate character to face camera direction
local function UpdateCharacterRotation()
	if not CameraController.RotateCharacter or LocalPlayer.Character:GetAttribute("Ragdoll") then 
		return 
	end

	local cameraType = CameraController.CameraType:Get()
	
	if cameraType == "None" then
		-- Face mouse position in free camera mode
		if not PlayerInfo.Dead then
			LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(
				LocalPlayer.Character.HumanoidRootPart.Position,
				Vector3.new(Mouse.Hit.Position.X, LocalPlayer.Character.HumanoidRootPart.Position.Y, Mouse.Hit.Position.Z)
			)
		end
	elseif cameraType == "FirstPerson" or cameraType == "ThirdPerson" then
		-- Face camera direction in first/third person
		LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(
			LocalPlayer.Character.HumanoidRootPart.Position,
			LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z)
		)
	end
end

-- Main heartbeat function - handles all camera updates
local function RunHeartbeat(deltaTime: number)
	local cameraType = CameraController.CameraType:Get()
	
	-- Update camera position for first/third person modes
	if cameraType == "FirstPerson" or cameraType == "ThirdPerson" then
		if not CameraLerp.State then
			Camera.CFrame = CalculateCameraCFrame()
		end

		-- Handle gamepad input
		if DeviceController.CurrentDevice:Get() == "Gamepad" then
			UpdateCameraAngles(Vector2.new(GamepadX, GamepadY))
		end

		UpdateCharacterWaist()
		
		-- Decay previous mouse deltas
		PreviousMouseDeltaX *= 0.99
		PreviousMouseDeltaY *= 0.99
	end

	-- Update character rotation for all modes
	UpdateCharacterRotation()

	-- Handle camera transitions
	if CameraLerp.State then
		CameraLerp.T = math.clamp(CameraLerp.T + deltaTime * 4, 0, 1)

		local goalCFrame
		if cameraType == "FirstPerson" or cameraType == "ThirdPerson" then
			goalCFrame = CalculateCameraCFrame()
			Camera.CFrame = CameraLerp.Start:Lerp(CFrame.new(goalCFrame.Position, (goalCFrame * CFrame.new(0, 0, -10)).Position), CameraLerp.T)
		else
			-- Default camera position
			goalCFrame = CFrame.new(
				(LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 7, 28)).Position,
				LocalPlayer.Character.HumanoidRootPart.Position
			)
			Camera.CFrame = CameraLerp.Start:Lerp(goalCFrame, CameraLerp.T)
		end

		-- Finish transition
		if CameraLerp.T >= 1 then
			if cameraType == "FirstPerson" or cameraType == "ThirdPerson" then
				LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(
					LocalPlayer.Character.HumanoidRootPart.Position,
					Vector3.new(Camera.CFrame.Position.X, LocalPlayer.Character.HumanoidRootPart.Position.Y, Camera.CFrame.Position.Z)
				) * CFrame.Angles(0, math.pi / 1.2, 0)
			else
				Camera.CameraType = Enum.CameraType.Custom
			end
			CameraLerp.State = false
		end
	end
end

-- Setup base camera for non-first/third person modes
local function SetupBaseCamera()
	RunService:UnbindFromRenderStep("BaseCamera")
	Camera.Focus = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 7, 21)
	
	RunService:BindToRenderStep("BaseCamera", Enum.RenderPriority.Camera.Value, function()
		local shakeMultiplier = 1
		local shakeCFrame = CFrame.new(
			math.cos(CameraShake.Position.X * 20) * (CameraShake.Position.X * 2) * shakeMultiplier,
			math.sin(CameraShake.Position.Y * 20) * (CameraShake.Position.Y * 2) * shakeMultiplier,
			0
		)
		Camera.CFrame = Camera.CFrame * shakeCFrame
	end)
end

-- Clean up first/third person camera mode
local function CleanupFPSCamera()
	ContextActionService:UnbindAction("WindowFocus", WindowFocus, false, Enum.UserInputType.Focus)
	ContextActionService:UnbindAction("UpdateInput", HandleInput, false, Enum.UserInputType.MouseMovement, Enum.UserInputType.Touch)
	
	CameraController:SetMouse("Normal")
	StartCameraTransition()
	
	LocalPlayer.Character.Humanoid.AutoRotate = true
	if LocalPlayer.Character.UpperTorso:FindFirstChild("Waist") then
		LocalPlayer.Character.UpperTorso.Waist.C0 = OriginWaistC0
	end
end

-- Setup first/third person camera mode
local function SetupFPSCamera()
	ContextActionService:BindAction("WindowFocus", WindowFocus, false, Enum.UserInputType.Focus)
	ContextActionService:BindAction("UpdateInput", HandleInput, false, Enum.UserInputType.MouseMovement, Enum.UserInputType.Touch, Enum.UserInputType.Gamepad1)

	if DeviceController.CurrentDevice:Get() ~= "Mobile" then
		CameraController:SetMouse("Lock")
	end

	Camera.CameraType = Enum.CameraType.Scriptable

	-- Save camera origin for transitions
	CameraOrigin.Focus = PlayerInfo.Root.CFrame:PointToObjectSpace(Camera.Focus.Position)
	CameraOrigin.RelativeOffset = Camera.Focus:PointToObjectSpace(Camera.CFrame.Position)
	CameraOrigin.Distance = (Camera.Focus.Position - Camera.CFrame.Position).Magnitude
	
	StartCameraTransition()
	LocalPlayer.Character.Humanoid.AutoRotate = false
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Change camera field of view with smooth transition
function CameraController:ChangeFOV(targetFOV: number, tweenTime: number, tweenStyle: Enum.EasingStyle, tweenDirection: Enum.EasingDirection)
	TweenService:Create(Camera, TweenInfo.new(tweenTime, tweenStyle, tweenDirection), {FieldOfView = targetFOV}):Play()
end

-- Set mouse behavior and visibility
function CameraController:SetMouse(state: string)
	if state == "Normal" then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true		
	elseif state == "Lock" then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	end
end

-- Trigger camera shake effect
function CameraController:Shake(speed: number, damper: number, power: Vector3)
	CameraShake.Speed = speed
	CameraShake.Damper = damper
	CameraShake:Impulse(power)
end

-- Update camera settings from data
function CameraController:DataUpdate(data: {})
	if not data then return end
	-- Future: Handle camera side preference, sensitivity settings, etc.
end

-- Initialize camera for new character
function CameraController.SetCharacter()
	print("Camera - Setting character started.")
	if LocalPlayer.Character then
		local waist = LocalPlayer.Character:WaitForChild("UpperTorso"):WaitForChild("Waist")
		OriginWaistC0 = waist.C0
		
		CameraController.SetCameraType("None")
		print("Camera - Setting character complete.")
	end
end

-- Change camera mode (None, FirstPerson, ThirdPerson, FallDeath)
function CameraController.SetCameraType(cameraType: string?)
	local lastType = CameraController.CameraType:Get()
	
	CameraController.CameraType:Set(cameraType)
	RunService:UnbindFromRenderStep("BaseCamera")

	-- Setup heartbeat connection
	CameraController.Janitor:Add(RunService.Heartbeat:Connect(RunHeartbeat), "Disconnect", "CameraHeartbeat")
	
	if cameraType == "None" then
		CameraController.RotateCharacter = false
		Camera.CameraSubject = LocalPlayer.Character.Humanoid

		-- Clean up first/third person if coming from those modes
		if lastType == "FirstPerson" or lastType == "ThirdPerson" then
			CleanupFPSCamera()
		end

		SetupBaseCamera()
		AdjustCharacterTransparency(0)

	elseif cameraType == "FirstPerson" then
		CameraController.RotateCharacter = true
		ShoulderPosition = FIRST_PERSON_POSITION
		Camera.CameraSubject = PlayerInfo.Human

		SetupFPSCamera()
		AdjustCharacterTransparency(1) -- Hide character body

	elseif cameraType == "ThirdPerson" then
		CameraController.RotateCharacter = true
		ShoulderPosition = THIRD_PERSON_POSITION
		Camera.CameraSubject = PlayerInfo.Human

		SetupFPSCamera()
		AdjustCharacterTransparency(0) -- Show character body

	elseif cameraType == "FallDeath" then
		CameraController.RotateCharacter = false

		-- Clean up first/third person if coming from those modes
		if lastType == "FirstPerson" or lastType == "ThirdPerson" then
			CleanupFPSCamera()
		end

		SetupBaseCamera()
		Camera.CameraSubject = nil
		AdjustCharacterTransparency(0)
	end
end

-- Initialize the camera controller
function CameraController:Init()
	print("Camera Controller Init...")
end

-- Setup remote connections
function CameraController:Deferred()
	CameraService.SetCameraType:Connect(function(CameraType: string?)
		if PlayerInfo.Dead and CameraType ~= "None" then return end 
		self:SetCameraType(CameraType)
	end)
	
	CameraService.CameraShake:Connect(function(Speed: number, Damper: number, Power: Vector3)
		self:Shake(Speed, Damper, Power)
	end)
end

return CameraController