-- OmniRal

local MainController = {}

local UserGameSettings = UserSettings().GameSettings

local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local DataService = Remotes.DataService
local RelicService = Remotes.RelicService
local ItemService = Remotes.ItemService
local RagdollService = Remotes.RagdollService

local CameraController = require(StarterPlayer.StarterPlayerScripts.Source.General.CameraController)
local MainUIController = require(StarterPlayer.StarterPlayerScripts.Source.General.MainUIController)

local CustomEnum = require(ReplicatedStorage.Source.SharedModules.Info.CustomEnum)
local PlayerInfo = require(StarterPlayer.StarterPlayerScripts.Source.Other.PlayerInfo)

local ControlModule

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

local CharacterSetup = false

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local AnimationsList : {[string]: {ID: number, Priority: Enum.AnimationPriority}} = {
	["_"] = {ID = 0, Priority = Enum.AnimationPriority.Action},
}

local GroundParams = RaycastParams.new()
GroundParams.FilterType = Enum.RaycastFilterType.Include
GroundParams.FilterDescendantsInstances = {Workspace}
GroundParams.IgnoreWater = true

local PickupDebounce = false

local Assets = ReplicatedStorage.Assets

local RNG = Random.new()

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------
-- Private API --
-----------------

-- Check if the player is touching the ground
local function CheckGrounded()
    if PlayerInfo.Dead or not PlayerInfo.Root then 
        if PlayerInfo.Grounded.State then
            PlayerInfo.Grounded.State = false
        end
        return 
    end
    if not GroundParams then 
        PlayerInfo.Grounded.State = false 
        return 
    end

    local SurfaceType = "None"

    local RayDown = Workspace:Raycast(PlayerInfo.Root.Position, Vector3.new(0, -4, 0), GroundParams)
    if RayDown then
        if RayDown.Instance then
            PlayerInfo.Grounded.State = true
            PlayerInfo.Grounded.Surface = RayDown.Instance
            PlayerInfo.Grounded.Position = RayDown.Position
            PlayerInfo.Grounded.Normal = RayDown.Normal

            SurfaceType = RayDown.Instance:GetAttribute("SurfaceType") -- Get the kind of ground the player is standing on

        else
            PlayerInfo.Grounded.State = false
        end
    else
        PlayerInfo.Grounded.State = false
    end

    if LocalPlayer.Character then
        LocalPlayer.Character:SetAttribute("CurrentSurface", SurfaceType)
    end
end

local function UpdateWalkSpeed()
    if not LocalPlayer.Character or PlayerInfo.Dead then return end
    if not PlayerInfo.Human or not PlayerInfo.Root or not PlayerInfo.UnitValues then return end

    local TotalWalkSpeed = PlayerInfo.UnitValues.Base:GetAttribute("WalkSpeed")

    if ControlModule then
         PlayerInfo.MoveVector = ControlModule:GetMoveVector()
    end

    if PlayerInfo.UnitValues.States:GetAttribute("Rooted") then
        TotalWalkSpeed = CustomEnum.RootWalkSpeed
    end

    if PlayerInfo.UnitValues.States:GetAttribute("Stunned") then
        TotalWalkSpeed = 0
    end

    PlayerInfo.Human.WalkSpeed = TotalWalkSpeed
end

local function CheckPickupItems()
    if PickupDebounce then return end

    local Target = Mouse.Target
    if not Target then return end

    -- Try to pick up a relic
    if Target.Parent:HasTag("Relic") then
        PickupDebounce = true
        RelicService:RequestPickupRelic(Target.Parent)

    elseif Target.Parent:HasTag("Item") then
        PickupDebounce = true
        ItemService:RequestPickupItem(Target.Parent)
    end 

    if not PickupDebounce then return end

    task.delay(1, function()
        PickupDebounce = false
    end)
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------
-- Public API --
----------------

function MainController:SetCharacter()
    print("Main - Setting character started.")
    if CharacterSetup then
        return
    end
    CharacterSetup = true

    while LocalPlayer.Character == nil do task.wait() end

    LocalPlayer.Character = LocalPlayer.Character
    PlayerInfo.Human = LocalPlayer.Character:WaitForChild("Humanoid")
    PlayerInfo.Root = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
    PlayerInfo.Dead = false
    PlayerInfo.IsRunning = false

    local NewGroundParams = RaycastParams.new()
    NewGroundParams.FilterType = Enum.RaycastFilterType.Exclude
    NewGroundParams.FilterDescendantsInstances = {LocalPlayer.Character}
    NewGroundParams.IgnoreWater = true
    GroundParams = NewGroundParams

    PlayerInfo.Human.Died:Connect(function()
        if not PlayerInfo.Dead then
            PlayerInfo.Dead = true
            CharacterSetup = false
            Camera.CameraSubject = PlayerInfo.Root
            RagdollService:ToggleRagdoll(true)

        end
    end)

    PlayerInfo.Human.Running:Connect(function(Speed: number)
        if Speed > 0 then
            PlayerInfo.IsRunning = true
        else
            PlayerInfo.IsRunning = false
        end
    end)

    PlayerInfo.Human.StateChanged:Connect(function(Old: Enum.HumanoidStateType, New: Enum.HumanoidStateType)
        if New == Enum.HumanoidStateType.Jumping or New == Enum.HumanoidStateType.Freefall then
            return
        end
    end)

    LocalPlayer.Character:GetAttributeChangedSignal("Ragdoll"):Connect(function()
        local Toggle = LocalPlayer.Character:GetAttribute("Ragdoll")
        --Human.AutoRotate = not Toggle
        if Toggle then
            PlayerInfo.Human.AutoRotate = false
            PlayerInfo.Human:ChangeState(Enum.HumanoidStateType.Physics)
        else
            PlayerInfo.Human.AutoRotate = true
            PlayerInfo.Human:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)

    CameraController.SetCharacter()
    MainUIController.SetCharacter()

    PlayerInfo.UnitValues = LocalPlayer.Character:WaitForChild("UnitValues")

    PlayerInfo.UnitValues.States:GetAttributeChangedSignal("Stunned"):Connect(function()
        
    end)

    print("Main - Setting character complete.")
end

--[[function MainController:RunControls(DeltaTime: number)
end]]

function MainController:RunHeartbeat()
    CheckGrounded()
    UpdateWalkSpeed()
end

function MainController:Init()
    print("Main Controller Init...")

    UserGameSettings.RotationType = Enum.RotationType.MovementRelative

    UserInputService.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            CheckPickupItems()
        end

        if Input.KeyCode == Enum.KeyCode.K then
            local CameraType = CameraController.CameraType:Get()

            if CameraType == "None" then
                CameraController.SetCameraType("FirstPerson")
            
            elseif CameraType == "ThirdPerson" then
                CameraController.SetCameraType("None")
            end
        end
    end)

    RunService.Heartbeat:Connect(function(DeltaTime: number)
        MainController:RunHeartbeat()
    end)
end

function MainController:Deferred()
    print("Main Controller Deferred...")

    local GotControlModule = LocalPlayer:FindFirstChild("PlayerScripts"):FindFirstChild("PlayerModule"):FindFirstChild("ControlModule") :: ModuleScript
    if GotControlModule then
        ControlModule = require(GotControlModule)
    end

    DataService.DataUpdate:Connect(function(Data: {Coins: number})
        PlayerInfo.Data = Data
        print("Recieved Data: ", PlayerInfo.Data)
    end)
end

return MainController