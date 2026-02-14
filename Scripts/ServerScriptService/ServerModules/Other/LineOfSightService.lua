-- OmniRal

local LineOfSightService = {}

local Workspace = game:GetService("Workspace")

function LineOfSightService:CheckInSight(Level: any, From: any, Target: any, Range: number, Ignore: {}, ToleranceRange: number?)
    if not Level or not From or not Target or not Range or not Ignore then return end

	local InSight = false
	
    local StartPos = From.Position
    local FinishPos
    if Target.ClassName == "Model" then
        FinishPos = Target.PrimaryPart.Position
    elseif Target:IsA("BasePart") then
        FinishPos = Target.Position
    end
    local Distance = (StartPos - FinishPos).Magnitude
    local Direction = CFrame.new(StartPos, FinishPos).LookVector

    if not ToleranceRange then
        ToleranceRange = 5
    end

    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = Ignore
    Params.IgnoreWater = true

    local RayResult = Workspace:Raycast(StartPos, Direction * Distance, Params)

    if RayResult then
        if RayResult.Instance then
            if RayResult.Instance == Target or RayResult.Instance:IsDescendantOf(Target) then
                InSight = true
                table.insert(Ignore, Target)
            else
                local ToleranceDistance = (FinishPos - RayResult.Position).Magnitude
                if ToleranceDistance <= ToleranceDistance then
                   InSight = true
                   table.insert(Ignore, Target) 
                end
            end
        else
            local ToleranceDistance = (FinishPos - RayResult.Position).Magnitude
            if ToleranceDistance <= ToleranceRange then
               InSight = true
               table.insert(Ignore, Target) 
            end
        end
        --[[if ( ((Target.Parent.ClassName ~= "Model") or ((Target.Parent.ClassName == "Model") and (Target.Parent:GetAttribute("IsLevel"))) ) and (RayResult.Instance == Target) ) 
            or 
            ((Target.Parent.ClassName == "Model") and (not Target.Parent:GetAttribute("IsLevel")) and ((RayResult.Instance == Target) or (RayResult.Instance == Target.Parent) or (RayResult.Instance.Parent == Target.Parent))) 
            or
            ((RayResult.Instance.Parent.ClassName == "Accessory") and (RayResult.Instance.Parent.Parent == Target.Parent)) 
        then
            InSight = true

            if Target.Parent.ClassName == "Model" and not Target.Parent:GetAttribute("IsLevel") then
                table.insert(Ignore, Target.Parent)
            elseif Target.Parent.ClassName ~= "Model" or Target.Parent:GetAttribute("IsLevel") then
                table.insert(Ignore, Target)
            end
        end]]

    else
        if (From.Position - FinishPos).Magnitude <= ToleranceRange then
            InSight = true
            table.insert(Ignore, Target)			
        end
    end
	
	return InSight
end

return LineOfSightService