-- OmniRal

local ProjectileService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local New = require(ReplicatedStorage.Source.Pronghorn.New)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Utility = require(ReplicatedStorage.Source.SharedModules.Other.Utility)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local DEFAULT_SPEED = 100
local DEFAULT_MAX_DISTANCE = 500
local DEFAULT_STEPS = 15

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local RNG = Random.new()

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------
-- Private API --
-----------------

local function GetSpreadDirection(Start: Vector3, Goal: Vector3, Spread: number, CameraCF: CFrame): Vector3
    local Forward = (Goal - Start).Unit
    local Right = CameraCF.RightVector
    local Up = CameraCF.UpVector

    local X = math.random() * 2 - 1
    local Y = math.random() * 2 - 1
    local Mag = math.sqrt(X * X + Y * Y)
    if Mag > 1 then
        X /= Mag
        Y /= Mag
    end

    local Radius = math.tan(Spread)
    local Offset = (Right * X + Up * Y) * Radius
    return (Forward + Offset).Unit
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------
-- Public API --
----------------

function ProjectileService:New(Owner: Player | Model, Start: Vector3, Goal: Vector3, Spread: number, AllShots: {BasePart}, CameraCF: CFrame?, Speed: number?, MaxDistance: number?, Steps: number?, Twist: boolean?, TravelComplete: (Player | Model, BasePart, BasePart?, Vector3?) -> ())
    if not Owner or not AllShots or not Start or not Goal then return end

    local TravelDistance = MaxDistance or DEFAULT_MAX_DISTANCE

    local Shots = {}
    local IgnoreList = {Workspace.Projectiles, Workspace.Decor}

    if Owner:IsA("Player") then
        table.insert(IgnoreList, Owner.Character)
    else
        table.insert(IgnoreList, Owner)
    end

    for _, Shot in AllShots do
        local NewShot = Shot:Clone()
        
        if not CameraCF then
            -- To be really used by enemies
            local BaseCFrame = CFrame.new(Start, Goal)

            local SpreadRad = math.rad(Spread or 0)
            local XOffset = RNG:NextNumber(-SpreadRad, SpreadRad)
            local YOffset = RNG:NextNumber(-SpreadRad, SpreadRad)

            local OffsetDirection = (BaseCFrame * CFrame.Angles(YOffset, XOffset, 0)).LookVector
            NewShot.CFrame = CFrame.new(Start, Start + OffsetDirection)

        else
            if math.abs(CameraCF.Position.Magnitude) <= 0.1 then
                NewShot.CFrame = CFrame.new(Start, Goal)
            else
                -- To be used by players
                local OffsetDirection = GetSpreadDirection(Start, Goal, Spread, CameraCF)
                NewShot.CFrame = CFrame.new(Start, Start + OffsetDirection)
            end
        end

        NewShot.Parent = Workspace.Projectiles

        table.insert(Shots, NewShot)
        table.insert(IgnoreList, NewShot)
    end

    for _, Unit in Workspace.Units:GetChildren() do
        if not Unit then continue end
        if Unit:GetAttribute("Team") ~= Owner:GetAttribute("Team") then continue end
        --table.insert(IgnoreList, Unit)
    end

    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = IgnoreList
    Params.RespectCanCollide = false
    Params.IgnoreWater = true

    local TotalSteps = Steps or DEFAULT_STEPS

    if TotalSteps > 1 then
        task.spawn(function()
            --task.wait(2)
            for x = 1, TotalSteps do
                task.wait()

                for _, Shot : BasePart in Shots do
                    local RayForward = Workspace:Raycast(Shot.Position, Shot.CFrame.LookVector * (TravelDistance / TotalSteps), Params)
                    if RayForward then
                        if RayForward.Instance then
                            warn("HIT : ", RayForward.Instance)
                            local Distance = (Shot.Position - RayForward.Position).Magnitude
                            Shot:PivotTo(Shot.CFrame * CFrame.new(0, 0, -Distance))
                            TravelComplete(Owner, Shot, RayForward.Instance, Shot.Position)
                            break        
                        end
                    end

                    Shot.CFrame *= CFrame.new(0, 0, -(TravelDistance / TotalSteps))
                end
            end
            --TravelComplete(Owner, Shot, nil, Shot.Position)
        end)
    else
        --task.wait(0.1)
        for _, Shot in Shots do
            local RayForward = Workspace:Raycast(Shot.Position, Shot.CFrame.LookVector * TravelDistance, Params)
            local ShotTravelDistance = TravelDistance
            local Hit = nil
            if RayForward then
                if RayForward.Instance then
                    ShotTravelDistance = (Shot.Position - RayForward.Position).Magnitude
                    Hit = RayForward.Instance
                end
            end

            local FinalCFrame = Shot.CFrame * CFrame.new(0, 0, -ShotTravelDistance)
            local TravelTime = ShotTravelDistance / (Speed or DEFAULT_SPEED)

            if Twist then
                FinalCFrame *= CFrame.Angles(RNG:NextNumber(-2, 2), RNG:NextNumber(-2, 2), RNG:NextNumber(-2, 2))
            end

            local ProjectileTween = TweenService:Create(Shot, TweenInfo.new(TravelTime, Enum.EasingStyle.Linear), {CFrame = FinalCFrame})
            ProjectileTween:Play()

            task.delay(TravelTime, function()
                TravelComplete(Owner, Shot, Hit) 
            end)
        end
    end
end

function ProjectileService:Init()

end

function ProjectileService:Deferred()

end

return ProjectileService