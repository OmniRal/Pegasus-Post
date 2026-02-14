--@localscript

local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Pronghorn = require(ReplicatedStorage.Source.Pronghorn)
Pronghorn:SetEnabledChannels({
    Remotes = false
})

Pronghorn:Import({
    StarterPlayer.StarterPlayerScripts.Source,
    ReplicatedStorage.Source.SharedModules
})

print("Pronghorn Client Import Complete.")