-- OmniRal

local ShopInfo = {}

ShopInfo.BuyCoins = {
    {
        Name = "Small",
        DevProductID = 3243902104,
        Cost = 100,
        Amount = 500,
        Icon = 109114412178425,
    },

    {
        Name = "Medium",
        DevProductID = 3244040364,
        Cost = 200,
        Amount = 3000,
        Icon = 133988870104424,
    },

    {
        Name = "Large",
        DevProductID = 3244040458,
        Cost = 300,
        Amount = 10000,
        Icon = 104957441077194, 
    }
} :: {{Name: string, DevProductID: number, Cost: number, Amount: number, Icon: number}}

return ShopInfo