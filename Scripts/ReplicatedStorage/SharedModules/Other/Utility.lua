-- OmniRal
--!nocheck

local Utility = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local New = require(ReplicatedStorage.Source.Pronghorn.New)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local UnitParts = {}

local RNG = Random.new()

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function Utility:ChangeModelTransparency(Model: Model, To: number, Ignore: {string}?, GetDescendants: boolean?)
    if not Model then return end
    
    local List
    if not GetDescendants then
        List = Model:GetChildren()
    else
        List = Model:GetDescendants()
    end
    
    for _, Part in List do
        local IgnorePart = false
        if Ignore then
            for _, Name in Ignore do
                if Part.Name ~= Name then continue end
                IgnorePart = true
                break
            end
        end
        if IgnorePart then continue end
        if not Part:IsA("BasePart") then continue end

        if To >= 1 then
            Part:SetAttribute("OriginalTransparency", Part.Transparency)
            Part.Transparency = To
        elseif To <= 0 then
            if Part:GetAttribute("OriginalTransparency") ~= nil then
                Part.Transparency = Part:GetAttribute("OriginalTransparency")
            else
                Part.Transparency = 0
            end
        else
            Part.Transparency = To
        end

        for _, Image in Part:GetChildren() do
            if not Image then continue end
            if not Image:IsA("Decal") and not Image:IsA("Texture") then continue end
            if To >= 1 then
                Image:SetAttribute("OriginalTransparency", Image.Transparency)
                Image.Transparency = To
            elseif To <= 0 then
                if Image:GetAttribute("OriginalTransparency") ~= nil then
                    Image.Transparency = Image:GetAttribute("OriginalTransparency")
                else
                    Image.Transparency = 0
                end
            else
                Image.Transparency = To
            end 
        end
    end
end

function Utility:CreateDot(CF: CFrame, Size: Vector3, Shape: Enum.PartType, Color: Color3?, Duration: number?, Parent: Instance?)
    local Dot = Instance.new("Part")
    Dot.Name = "Dot"
    Dot.Anchored = true
    Dot.CanCollide = false
    Dot.CanQuery = false
    Dot.CanTouch = false
    Dot.CFrame = CF
    Dot.Material = Enum.Material.Neon
    Dot.Size = Size or Vector3.new(2, 2, 2)
    Dot.Shape = Shape
    Dot.Color = Color or Color3.fromRGB(230, 30, 40)
    Dot.Parent = Parent or Workspace

    if Duration then
        Debris:AddItem(Dot, Duration)
    end

    return Dot
end

function Utility:GetAnimationSpeedFromAttackSpeed(AttackSpeed: number)
    return AttackSpeed / 100
end

function Utility.CheckPlayerAlive(Player: Player, GetParts: {string}?): (boolean?, Humanoid?, BasePart?, {}?)
    if not Player then return end
    if not Player.Character then return end
    local Human, Root = Player.Character:FindFirstChild("Humanoid"), Player.Character:FindFirstChild("HumanoidRootPart")
    if not Human or not Root then return end
    if Human.Health <= 0 then return end

    if GetParts then
        local GotParts = {}
        for _, Name in ipairs(GetParts) do
            if not Player.Character:FindFirstChild(Name) then continue end
            table.insert(GotParts, Player.Character[Name])
        end

        return true, Human, Root, unpack(GotParts)
    end

    return true, Human, Root
end

function Utility:BasicUnitCheck(Unit: Model, Player: Player)
    if not Unit then return end
    if Unit == Player.Character or Unit:GetAttribute("Team") == Player:GetAttribute("Team") then return end
    local EnemyHuman, EnemyRoot, EnemyAttributes = Unit:FindFirstChild("Humanoid"), Unit:FindFirstChild("HumanoidRootPart"), Unit:FindFirstChild("UnitAttributes")
    if not EnemyHuman or not EnemyRoot or not EnemyAttributes then return end
    if EnemyHuman.Health <= 0 then return end

    return EnemyHuman, EnemyRoot, EnemyAttributes
end

function Utility:ClearUnitParts()
    table.clear(UnitParts)
end

function Utility:SetUnitTransparency(Unit: Model, To: number)
    if not Unit then
        if UnitParts[Unit] then
            UnitParts[Unit] = nil
        end
        return
    end

    if Unit:GetAttribute("CurrentTransparency") == To then return end

    local List
    if not UnitParts[Unit] then
        UnitParts[Unit] = {}
        for _, BasePart in Unit:GetDescendants() do
            if not BasePart then continue end
            if not BasePart:IsA("BasePart") then continue end
            if BasePart.Name == "HumanoidRootPart" then continue end
            table.insert(UnitParts[Unit], BasePart)
        end
        List = UnitParts[Unit]
    else
        List = UnitParts[Unit]
    end

    for _, BasePart in List do
        if not BasePart then continue end
        if not BasePart:GetAttribute("TrueTransparency") then
            BasePart.Transparency = To
        else
            BasePart.Transparency = BasePart:GetAttribute("TrueTransparency")
        end
    end
end

function Utility:CheckGrounded(Unit: Model, Root: BasePart, Params: RaycastParams): (boolean?, string?)
    if not Unit or not Root then return end

    local Grounded, Surface = false, nil

    local RayDown = Workspace:Raycast(Root.Position, CFrame.new(Root.Position).UpVector * -7, Params)
    if not RayDown then return end
    if not RayDown.Instance then return end
    Grounded = true
    Surface = RayDown.Instance

    return Grounded, Surface
end

function Utility:CheckForUnits(Type: "Players" | "Bots" | "All", List: {}, From: CFrame, Range: number)
    for _, Unit in Workspace.Units:GetChildren() do
        if not Unit then continue end

        local CheckUnit = false
        if Type == "Players" then
            if CollectionService:HasTag(Unit, "Bot") then continue end
            CheckUnit = true
        
        elseif Type == "Bots" then
            if not CollectionService:HasTag(Unit, "Bot") then continue end
            CheckUnit = true

        else
            CheckUnit = true
        end
           
        if not CheckUnit then continue end
        if table.find(List, Unit) then continue end

        local Human, Root = Unit:FindFirstChild("Humanoid") :: Humanoid, Unit:FindFirstChild("HumanoidRootPart") :: BasePart
        if not Human or not Root then continue end
        if Human.Health <= 0 then continue end
        local Distance = (From.Position - Root.Position).Magnitude
        if Distance > Range then continue end

        table.insert(List, Unit)
    end

    return List
end

function Utility:CheckForItems(List: {}, From: CFrame, Range: number)
    for _, Item: Model in Workspace.Items:GetChildren() do
        if not Item then continue end
        if table.find(List, Item) then continue end

        local Root = Item.PrimaryPart
        if not Root then continue end

        local Distance = (From.Position - Root.Position).Magnitude
        if Distance > Range then continue end

        table.insert(List, Item)
    end

    return List
end

function Utility.RollPick(Options: {{Choice: any, Chance: number}}): any?
    if #Options <= 0 then return end
    if #Options == 1 then
        return Options[1].Choice
    end 

    local TotalWeight = 0
    for _, Info in Options do
        TotalWeight += Info.Chance
    end

    local Roll = RNG:NextNumber(0, TotalWeight)
    local Sum = 0
    local ChanceNeeded = 0
    local AvailablePicks: {number} = {}

    for Num, Info in ipairs(Options) do
        Sum += Info.Chance
        if Roll <= Sum then
            ChanceNeeded = Info.Chance
            table.insert(AvailablePicks, Num)
            break
        end
    end

    for Num, Info in ipairs(Options) do
        if math.abs(Info.Chance - ChanceNeeded) > 0.01 then continue end
        if table.find(AvailablePicks, Num) then continue end
        table.insert(AvailablePicks, Num)
    end

    local Picked = Options[AvailablePicks[RNG:NextInteger(1, #AvailablePicks)]].Choice

    return Picked
end

function Utility.CheckFriends(Player_A: Player, Player_B: Player): boolean
    if not Player_A or not Player_B then return false end

    local Success, Result = pcall(function()
        return Player_A:IsFriendsWithAsync(Player_B.UserId)
    end)

    if not Success then
        warn(Result)
        return
    end

    return Result
end

return Utility