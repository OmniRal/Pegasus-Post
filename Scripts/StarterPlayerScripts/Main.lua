--@localscript
-- OmniRal

task.wait()
local UserSettings = UserSettings()
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")

local MainController = require(StarterPlayer.StarterPlayerScripts.Source.General.MainController)

local LocalPlayer = Players.LocalPlayer

function RunMain()

end

function Setup()
    --UserSettings.GameSettings.RotationType = Enum.RotationType.CameraRelative
    LocalPlayer.CharacterAdded:Connect(function()
        MainController:SetCharacter()
    end)
    MainController:SetCharacter()
end

Setup()