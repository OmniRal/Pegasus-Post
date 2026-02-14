-- OmniRal

local PartyService = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

export type Party = {
    Status: "Temporary" | "Full",
    Name: string,
    Icon: number,
    Leader: Player,
    Users: {Player},
    Invites: {[Player]: {Status: "Pending" | "Accepted" | "Declined", Timer: number}},
}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local AllParties: {Party} = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------
-- Private API --
-----------------

local function FindPartyPlayerIsIn(Player: Player): Party?
    if not Player or #AllParties <= 0 then return end

    for _, Party in AllParties do
        if not Party then continue end
        if not table.find(Party.Users, Player) then continue end
        return Party
    end

    return
end

local function IsPlayerLeader(Party: Party, Player: Player): boolean?
    if not Party or not Player then return end
    if not Party.Leader then return end
    if Party.Leader ~= Player then return false end

    return true
end

local function RemovePlayerFromParty(Party: Party, Player: Player)
    if not Party or not Player then return end
    
    -- Try to remove player the party
    local Index = table.find(Party.Users, Player)
    if not Index then return end

    local WasLeader = IsPlayerLeader(Party, Player)

    table.remove(Party.Users, Index)

    -- Check if a new player is available to be the party leader
    if WasLeader and #Party.Users > 0 then
        Party.Leader = Party.Users[1]
    end
end

-- Clean up AllParties table of any party that has ZERO users
local function RunCleanup()
    for Index, Party in ipairs(AllParties) do
        if not Party then continue end
        if #Party.Users <= 0 then
            table.remove(AllParties, Index)
        end
    end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------
-- Public API --
----------------

function PartyService:Init()
    Remotes:CreateToClient("ReceiveInvite", {"Player"}, "Reliable")
    
    Remotes:CreateToServer("InvitePlayer", {"Player"}, "Reliable", function(Player: Player, OtherPlayer: Player)
        
    end)

    Remotes:CreateToServer("AnswerInvite", {"boolean", "Player"}, "Reliable", function(Player: Player, Answer: boolean, FromPlayer: Player)
        
    end)
end

function PartyService:Deferred()

end

function PartyService.PlayerAdded(Player: Player)

end

function PartyService.PlayerRemoving(Player: Player)
    if not Player then return end

    local Party = FindPartyPlayerIsIn(Player)
    if not Party then return end

    RemovePlayerFromParty(Party, Player)
end

return PartyService