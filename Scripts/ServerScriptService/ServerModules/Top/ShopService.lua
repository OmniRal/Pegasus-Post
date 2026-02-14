-- OmniRal

local ShopService = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MarketplaceService = game:GetService("MarketplaceService")

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)
local New = require(ReplicatedStorage.Source.Pronghorn.New)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local DataService = require(ServerScriptService.Source.ServerModules.Top.DataService)

local ShopInfo = require(ReplicatedStorage.Source.SharedModules.Info.ShopInfo)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------
-- Private API --
-----------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------
-- Public API --
----------------

function ShopService:Init()
    Remotes:CreateToServer("RequestToBuyCoins", {"number"}, "Returns", function(Player: Player, Option: number)
        MarketplaceService:PromptProductPurchase(Player, ShopInfo.BuyCoins[Option].DevProductID)
    end)

end

function ShopService:Deferred()

end

return ShopService