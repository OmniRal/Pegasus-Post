-- OmniRal

local DeviceController = {}

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local New = require(ReplicatedStorage.Source.Pronghorn.New)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

DeviceController.CurrentDevice = New.Var("KeyboardMouse")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function DeviceController:Init()
    print("Device Controller Init...")
    UserInputService.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.Keyboard or Input.UserInputType == Enum.UserInputType.MouseButton1 then
            if self.CurrentDevice:Get() ~= "KeyboardMouse" then
                self.CurrentDevice:Set("KeyboardMouse")
            end
        elseif Input.KeyCode == Enum.KeyCode.Thumbstick1 or Input.KeyCode == Enum.KeyCode.Thumbstick2 then
            if self.CurrentDevice:Get() ~= "Gamepad" then
                self.CurrentDevice:Set("Gamepad")
            end
        end
    end)
    UserInputService.TouchStarted:Connect(function()
        if self.CurrentDevice:Get() ~= "Mobile" then
            self.CurrentDevice:Set("Mobile")
        end
    end)
end

return DeviceController