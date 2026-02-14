-- OmniRal

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CustomEnum = require(ReplicatedStorage.Source.SharedModules.Info.CustomEnum)

local ProductInfo = {} :: {[string]: CustomEnum.Product}

ProductInfo["3243902104"] = {Type = "Coins", Detail = 1}
ProductInfo["3244040364"] = {Type = "Coins", Detail = 2}
ProductInfo["3244040458"] = {Type = "Coins", Detail = 3}

ProductInfo["3245916427"] = {Type = "Toy", Name = "Dice"}

return ProductInfo