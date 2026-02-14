-- OmniRal

-- This service handles setting up ragdoll joints inside a traditional rig.

local RagdollService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)
local New = require(ReplicatedStorage.Source.Pronghorn.New)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ModelConstraints = {
    Ankle = New.Instance("BallSocketConstraint", {LimitsEnabled = true, TwistLimitsEnabled = true, UpperAngle = 30, TwistLowerAngle = -45, TwistUpperAngle = 30}),
    Elbow = New.Instance("HingeConstraint", {LimitsEnabled = true, LowerAngle = 0, UpperAngle = 135}),
    Hip = New.Instance("BallSocketConstraint", {LimitsEnabled = true, TwistLimitsEnabled = true, UpperAngle = 50, TwistLowerAngle = 100, TwistUpperAngle = -45}),
    Knee = New.Instance("HingeConstraint", {LimitsEnabled = true, LowerAngle = -140, UpperAngle = 0}),
    Neck = New.Instance("BallSocketConstraint", {LimitsEnabled = true, TwistLimitsEnabled = true, MaxFrictionTorque = 4, UpperAngle = 60, TwistLowerAngle = -75, TwistUpperAngle = 60}),
    Shoulder = New.Instance("BallSocketConstraint", {LimitsEnabled = true, TwistLimitsEnabled = true, UpperAngle = 45, TwistLowerAngle = -90, TwistUpperAngle = 150}),
    Waist = New.Instance("BallSocketConstraint", {LimitsEnabled = true, TwistLimitsEnabled = true, UpperAngle = 30, TwistLowerAngle = -55, TwistUpperAngle = 25}),
    Wrist = New.Instance("BallSocketConstraint", {LimitsEnabled = true, TwistLimitsEnabled = true, UpperAngle = 30, TwistLowerAngle = -45, TwistUpperAngle = 45})
}

local ModelCollisions = {
	{"HeadCollision",   "LeftUpperArm", "LeftUpperLeg", "LowerTorso", "RightUpperArm", "RightUpperLeg", "UpperTorso"},
	{"LeftFoot",    "LowerTorso", "UpperTorso"},
	{"LeftLowerArm",    "LowerTorso", "UpperTorso"},
	{"LeftLowerLeg",    "LowerTorso", "UpperTorso"},
	{"LeftUpperArm",    "LeftUpperLeg", "LowerTorso", "RightUpperArm", "RightUpperLeg", "UpperTorso"},
	{"LeftUpperLeg",    "LowerTorso", "RightUpperLeg", "UpperTorso"},
	{"RightFoot",   "LowerTorso", "UpperTorso"},
	{"RightHand", "UpperTorso"},
	{"RightLowerArm",   "LowerTorso", "UpperTorso"},
	{"RightLowerLeg",   "LowerTorso", "UpperTorso"},
	{"RightUpperArm",   "LeftUpperLeg", "LowerTorso", "LeftUpperArm", "RightUpperLeg", "UpperTorso"},
	{"RightUpperLeg",   "LowerTorso", "LeftUpperLeg", "UpperTorso"}
}

local Sides = {-1, 1}
local RNG = Random.new()

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------
-- Private API --
-----------------

local function GetAccessoryAttachment0(Character: Instance, Name: string)
    for _, Part in pairs(Character:GetChildren()) do
        local Attachment = Part:FindFirstChild(Name)
        if Attachment then
            return Attachment
        end
    end
end

-- Create joints for the accessories.
local function MakeAccessoryJoints(Character: Instance, Folder: Instance)
    for _, Object in pairs(Character:GetChildren()) do
        if Object:IsA("Accessory") then
            local Handle = Object:FindFirstChild("Accessory")
            if Handle then
                Handle.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0.01, 0.01, 0.01, 0.01)
                local Attachment1 = Handle:FindFirstChildOfClass("Attachment")
                local Attachment0 = GetAccessoryAttachment0(Character, Attachment1.Name)
                if Attachment1 and Attachment0 then
                    New.Instance("HingeConstraint", Folder, "Accessory_" .. Object.Name, {
                        Attachment0 = Attachment0,
                        Attachment1 = Attachment1,
                        LimitsEnabled = true, UpperAngle = 0, LowerAngle = 0
                    })
                end
            end
        end
    end
end

-- Creates the ragdoll joints
local function CreateJoint(Part0: Instance, Part1: Instance, AttachmentName: string, Folder: Instance)
    local ConstraintName
    for Key, _ in pairs(ModelConstraints) do
        if string.match(AttachmentName, Key) then
            ConstraintName = Key
            break
        end
    end
    AttachmentName = AttachmentName .. "RigAttachment"
    New.Clone(ModelConstraints[ConstraintName], Folder, "Ragdoll_" .. Part1.Name, {Attachment0 = Part0[AttachmentName], Attachment1 = Part1[AttachmentName]})
end

-- Creates no collision constraint for certain parts.
local function SetCollisions(Model: Instance, Folder: Instance)
    if not Model or not Folder then return end

    for _, Table in pairs(ModelCollisions) do
        local Part0 = Model:FindFirstChild(Table[1])
        if Part0 then
            for n = 2, #Table do
                local Part1 = Model:FindFirstChild(Table[n])
                if Part1 then
                    New.Instance("NoCollisionConstraint", Folder, Table[1] .. "<>" .. Table[n], {Part0 = Part0, Part1 = Part1})
                end
            end
        end
    end
end

local function ToggleMotors(Motors: table, Toggle: boolean)
    for Part, Motor in pairs(Motors) do
        if Part ~= "Root" then
            Motor.Enabled = Toggle
        end
    end
end
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------
-- Public API --
----------------

-- Set up ragdoll stuff for a model.
function RagdollService:SetRagdoll(Model: Model)
    if not Model then return end
    local Human = Model:FindFirstChild("Humanoid")
    if not Human then return end

    Human.BreakJointsOnDeath = false

    local BodyParts = {
        HumanoidRootPart = Model:WaitForChild("HumanoidRootPart"),
        LowerTorso = Model:WaitForChild("LowerTorso"),
        LeftUpperLeg = Model:WaitForChild("LeftUpperLeg"),
        LeftLowerLeg = Model:WaitForChild("LeftLowerLeg"),
        LeftFoot = Model:WaitForChild("LeftFoot"),
        RightUpperLeg = Model:WaitForChild("RightUpperLeg"),
        RightLowerLeg = Model:WaitForChild("RightLowerLeg"),
        RightFoot = Model:WaitForChild("RightFoot"),
        UpperTorso = Model:WaitForChild("UpperTorso"),
        LeftUpperArm = Model:WaitForChild("LeftUpperArm"),
        LeftLowerArm = Model:WaitForChild("LeftLowerArm"),
        LeftHand = Model:WaitForChild("LeftHand"),
        RightUpperArm = Model:WaitForChild("RightUpperArm"),
        RightLowerArm = Model:WaitForChild("RightLowerArm"),
        RightHand = Model:WaitForChild("RightHand"),
        Head = Model:WaitForChild("Head")
    }
    local Motors = {
        Root = BodyParts.LowerTorso:WaitForChild("Root"),
        LeftHip = BodyParts.LeftUpperLeg:WaitForChild("LeftHip"),
        LeftKnee = BodyParts.LeftLowerLeg:WaitForChild("LeftKnee"),
        LeftAnkle = BodyParts.LeftFoot:WaitForChild("LeftAnkle"),
        RightHip = BodyParts.RightUpperLeg:WaitForChild("RightHip"),
        RightKnee = BodyParts.RightLowerLeg:WaitForChild("RightKnee"),
        RightAnkle = BodyParts.RightFoot:WaitForChild("RightAnkle"),
        Waist = BodyParts.UpperTorso:WaitForChild("Waist"),
        LeftShoulder = BodyParts.LeftUpperArm:WaitForChild("LeftShoulder"),
        LeftElbow = BodyParts.LeftLowerArm:WaitForChild("LeftElbow"),
        LeftWrist = BodyParts.LeftHand:WaitForChild("LeftWrist"),
        RightShoulder = BodyParts.RightUpperArm:WaitForChild("RightShoulder"),
        RightElbow = BodyParts.RightLowerArm:WaitForChild("RightElbow"),
        RightWrist = BodyParts.RightHand:WaitForChild("RightWrist"),
        Neck = BodyParts.Head:WaitForChild("Neck")
    }
    local OriginalMotor = Motors.Root
    local OtherMotor = New.Instance("Motor6D", BodyParts.UpperTorso, {Enabled = false, C0 = CFrame.new(0, (BodyParts.LowerTorso.Size.Y) * 0.7, 0), Part0 = BodyParts.HumanoidRootPart, Part1 = BodyParts.UpperTorso})

    local RagdollConstraints = New.Instance("Folder", "RagdollConstraints", Model)
    local RagdollCollisions = New.Instance("Folder", "RagdollCollisions", Model)

    pcall(CreateJoint, BodyParts.LowerTorso, BodyParts.UpperTorso, "Waist", RagdollConstraints)
    pcall(CreateJoint, BodyParts.UpperTorso, BodyParts.Head, "Neck", RagdollConstraints)
    pcall(CreateJoint, BodyParts.UpperTorso, BodyParts.LeftUpperArm, "LeftShoulder", RagdollConstraints)
    pcall(CreateJoint, BodyParts.UpperTorso, BodyParts.RightUpperArm, "RightShoulder", RagdollConstraints)
    pcall(CreateJoint, BodyParts.LeftUpperArm, BodyParts.LeftLowerArm, "LeftElbow", RagdollConstraints)
    pcall(CreateJoint, BodyParts.RightUpperArm, BodyParts.RightLowerArm, "RightElbow", RagdollConstraints)
    pcall(CreateJoint, BodyParts.LeftLowerArm, BodyParts.LeftHand, "LeftWrist", RagdollConstraints)
    pcall(CreateJoint, BodyParts.RightLowerArm, BodyParts.RightHand, "RightWrist", RagdollConstraints)
    pcall(CreateJoint, BodyParts.LowerTorso, BodyParts.LeftUpperLeg, "LeftHip", RagdollConstraints)
    pcall(CreateJoint, BodyParts.LowerTorso, BodyParts.RightUpperLeg, "RightHip", RagdollConstraints)
    pcall(CreateJoint, BodyParts.LeftUpperLeg, BodyParts.LeftLowerLeg, "LeftKnee", RagdollConstraints)
    pcall(CreateJoint, BodyParts.RightUpperLeg, BodyParts.RightLowerLeg, "RightKnee", RagdollConstraints)
    pcall(CreateJoint, BodyParts.LeftLowerLeg, BodyParts.LeftFoot, "LeftAnkle", RagdollConstraints)
    pcall(CreateJoint, BodyParts.RightLowerLeg, BodyParts.RightFoot, "RightAnkle", RagdollConstraints)
    MakeAccessoryJoints(Model, RagdollConstraints)

    BodyParts.HumanoidRootPart.CanCollide = false
    BodyParts.HumanoidRootPart.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0.01, 0.01, 0.01, 0.01)

    local HeadSize = BodyParts.Head.Size
    BodyParts.Head.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0.01, 0.01, 0.01, 0.01)
    --BodyParts.Head.OriginalSize.Value = Vector3.new(1, 1, 1)
    --BodyParts.Head.Size = Vector3.new(HeadSize.Z, HeadSize.Y, HeadSize.Z)

    local HeadCollision = New.Instance("Part", BodyParts.Head, "HeadCollision", {Transparency = 1, Shape = Enum.PartType.Cylinder, Size = Vector3.new(HeadSize.Y, HeadSize.Z, HeadSize.Z), CanCollide = true, CollisionGroup = "NoClip"})
    --[[local HeadCollisionWeld =]] New.Instance("Weld", HeadCollision, {Part0 = BodyParts.Head, Part1 = HeadCollision, C0 = CFrame.new(0, 0, 0) * CFrame.fromOrientation(0, 0, math.rad(-90))})
    local HeadCollisionAttachment = New.Instance("Attachment", HeadCollision, {Orientation = Vector3.new(0, 0, -90)})
    --[[local HeadCollisionConstraint =]] New.Instance("HingeConstraint", RagdollConstraints, "HeadCollision", {Attachment0 = BodyParts.Head.FaceCenterAttachment, Attachment1 = HeadCollisionAttachment, LimitsEnabled = true, UpperAngle = 0, LowerAngle = 0})


    SetCollisions(Model, RagdollCollisions)

    Model:SetAttribute("Ragdoll", false)
    Model:GetAttributeChangedSignal("Ragdoll"):Connect(function()
        local Toggle = Model:GetAttribute("Ragdoll")
        OtherMotor.Enabled = Toggle
        OriginalMotor.Enabled = not Toggle
        ToggleMotors(Motors, not Toggle)
        if Human.Health <= 0 then
            HeadCollision.CollisionGroup = "Default"
        end
        --if Toggle then
        --end
    end)
end

function RagdollService.PlayerAdded(Player: Player)
    if not Player then return end

    Player.CharacterAdded:Connect(function()
        RagdollService:SetRagdoll(Player.Character :: Model)
    end)
end

function RagdollService:Init()
    print("Ragdoll Service Init...")

    Remotes:CreateToServer("ToggleRagdoll", {"boolean"}, "Reliable", function(Player: Player, Toggle: boolean?)
        if not Player then return end
        if not Player.Character then return end
        local NewToggle = Toggle
        if not NewToggle then
            NewToggle = not Player.Character:GetAttribute("Ragdoll")
        end
        Player.Character:SetAttribute("Ragdoll", NewToggle)
    end)
end

return RagdollService