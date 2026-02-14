-- OmniRal

-- Server control over a players camera.

local CameraService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Sets the camera type for a single player.
-- @Player: The player to change the camera type for.
-- @To: 0 = "None" / Default, 1 = "ThirdPerson"
function CameraService:SetCameraType(Player: Player, To: number)
    Remotes.CameraService.SetCameraType:Fire(Player, To)
end

-- Sets the camera type for all players.
-- @To: 0 = "None" / Default, 1 = "ThirdPerson"
function CameraService:SetAllCameraType(To: number)
    Remotes.CameraService.SetCameraType:FireAll(To)
end

-- Apply a camera shake to a single player.
function CameraService:ApplyShake(Player: Player, Speed: number, Damper: number, Power: Vector3)
    if not Player then return end
    Remotes.CameraService.CameraShake:Fire(Player, Speed, Damper, Power)
end

-- Apply a camera shake to all players.
function CameraService:ApplyShakeToAllPlayers(Speed: number, Damper: number, Power: Vector3)
    Remotes.CameraService.CameraShake:FireAll(Speed, Damper, Power)
end

function CameraService:Init()
    print("Camera Service Init...")
    Remotes:CreateToClient("SetCameraType", {}, "Reliable")
    Remotes:CreateToClient("CameraShake", {}, "Unreliable")
end

return CameraService