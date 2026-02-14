-- OmniRal

local VisualService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)
local New = require(ReplicatedStorage.Source.Pronghorn.New)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local CustomEnum = require(ReplicatedStorage.Source.SharedModules.Info.CustomEnum)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local SharedAssets = ReplicatedStorage.Assets

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------
-- Private API --
-----------------



------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------
-- Public API --
----------------

function VisualService:Init()
    Remotes:CreateToClient("SpawnTextDisplay", {"string", "string", "string", "Vector3", "table?"}, "Unreliable")
end

function VisualService:Deferred()

end

return VisualService