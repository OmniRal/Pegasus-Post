-- OmniRal

local HighlightService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local New = require(ReplicatedStorage.Source.Pronghorn.New)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local FLASH_COLOR = Color3.fromRGB(255, 50, 50)
local FLASH_TIME = 0.25

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function HighlightService:SetRedFlash(Unit: Model)
    if not Unit then return end
    local Human = Unit:FindFirstChild("Humanoid") :: Humanoid
    if not Human then return end

    local Highlight = New.Instance("Highlight", "RedFlash", {Enabled = true, FillColor = FLASH_COLOR, FillTransparency = 0, OutlineTransparency = 1})
    local LastHealth = Human.Health
    local FlashThread = nil
    Human.HealthChanged:Connect(function()
        if Human.Health < LastHealth then
            if FlashThread then
                task.cancel(FlashThread)
            end
            Highlight.Parent = Unit
            FlashThread = task.delay(FLASH_TIME, function()
                Highlight.Parent = nil
            end)
        end
        LastHealth = Human.Health
    end)
end

return HighlightService