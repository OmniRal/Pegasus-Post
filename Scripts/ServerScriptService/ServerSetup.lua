--@script

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Pronghorn = require(ReplicatedStorage.Source.Pronghorn)
Pronghorn:SetEnabledChannels({
    Remotes = false
})

Pronghorn:Import({
    ReplicatedStorage.Source.SharedModules,
    ServerScriptService.Source.ServerModules
})

print("Pronghorn Server Import Complete.")