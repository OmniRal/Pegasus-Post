-- OmniRal
--!nocheck

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local CustomEnum = require(ReplicatedStorage.Source.SharedModules.Info.CustomEnum.LevelEnum)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local SHOW_ROOM_INFO = false
local SHOW_SLOT_CONNECTIONS = false

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Room = {}
Room.__index = Room

local Assets = ServerStorage.Assets
local RNG = Random.new()

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function CreateRoomUI(Room: CustomEnum.Room)
	if not Room then return end
	if not Room.Build then return end
	if not Room.Build.PrimaryPart then return end
	
	local RoomGui = Assets.Other.RoomGui:Clone()
	RoomGui.Parent = Room.Build.Root
	RoomGui._1.Text = Room.Name
	RoomGui._2.Text = ""
	
	Room.Build:GetAttributeChangedSignal("PlayerCount"):Connect(function()
		if Room.Build:GetAttribute("PlayerCount") > 0 then
			RoomGui._2.Text = Room.Build:GetAttribute("PlayerCount")
		else
			RoomGui._2.Text = ""
		end
	end)
end

local function CreateSlotUI(RoomA: CustomEnum.Room, RoomB: CustomEnum.Room, SlotA: number, SlotB: number)
	local SlotGui = Assets.Other.SlotGui:Clone()
	SlotGui._1.Text = RoomA.Name .. " / " .. SlotA
	SlotGui._3.Text = RoomB.Name .. " / " .. SlotB
	SlotGui.Parent = RoomA.Slots[SlotA].SlotPart
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function Room.new(NewRoom : CustomEnum.RoomConstructor, OpenSlotsNeeded: NumberRange?): CustomEnum.Room?
	local BiomeFolder = Assets.LevelBiomes:FindFirstChild(NewRoom.Biome.Name)
	--assert(BiomeFolder, "Cannot find biome folder: " .. NewRoom.Biome)

	local self: CustomEnum.Room = setmetatable({}, Room)
	
	--------------------------------------------------
	
	self.SystemType = "Room"
	self.Name = NewRoom.Name
	self.Biome = NewRoom.Biome
	self.RoomType = NewRoom.RoomType
	self.Chunk = NewRoom.Chunk
	
	local NewBuild: Model = Instance.new("Model")
	local BaseRoot = NewBuild.PrimaryPart
	NewBuild:SetAttribute("OriginalName", NewBuild.Name)
	NewBuild:SetAttribute("PlayerCount", 0)
	
	local ObjectsFolder = Instance.new("Folder")
	ObjectsFolder.Name = "RoomObjects"
	ObjectsFolder.Parent = NewBuild
	
	self.Build = NewBuild
	self.BuildName = NewBuild.Name
	self.FloorParts = {}
	
	for _, FloorPart: BasePart in NewBuild:GetChildren() do
		if not FloorPart:IsA("BasePart") or FloorPart.Name ~= "Floor" then continue end
		table.insert(self.FloorParts, FloorPart)
	end
	
	NewBuild.Name = NewRoom.Name
	
	if SHOW_ROOM_INFO then
		CreateRoomUI(self)
	end
	
	--------------------------------------------------
	
	self.Slots = {}
	self.OpenSlots = {}
	self.ClosedSlots = {}
	local ChosenSlot: number
	for Index, SlotPart : BasePart in ipairs(NewBuild.HallSlots:GetChildren()) do
		SlotPart.CanCollide = false
		SlotPart.CanQuery = true
		SlotPart.CanTouch = false
		SlotPart.Transparency = 1
		
		if NewRoom.ConnectFromSlot == "Start" and SlotPart.Name == "StartSlot" then
			ChosenSlot = Index
		end
		
		self.Slots[Index] = {Open = true, SlotPart = SlotPart, ConnectTo = nil, Index = Index}
	end
	
	--------------------------------------------------
	
	if NewRoom.ConnectFromSlot == "Any" then
		ChosenSlot = self.Slots[RNG:NextInteger(1, #self.Slots)]
	end
	
	if ChosenSlot and NewRoom.ConnectTo then
		self.Slots[ChosenSlot].Open = false
		self.Slots[ChosenSlot].ConnectTo = NewRoom.ConnectTo
		
		NewBuild.PrimaryPart = self.Slots[ChosenSlot].SlotPart 
		NewBuild:PivotTo(NewRoom.CFrame * CFrame.new(0, 0, 0))
		
		task.defer(function()
			NewBuild.PrimaryPart = BaseRoot
		end)
		
	else
		NewBuild:PivotTo(NewRoom.CFrame)
	end
	
	--------------------------------------------------
	
	self.CFrame = NewBuild:GetPivot()
	self.Size = NewBuild:GetExtentsSize()
	self.Occupied = {}
	self.Players = {}
	self.Values = {}
	
	self.Objects = {}
	self.Zones = {
		Ceiling = {},
		Floor = {},
		Wall = {},
	}
	
	self:UpdateSlots()
	
	return self
end

function Room:ConnectSlot(SlotNumber: number, To: CustomEnum.Hub | CustomEnum.Room, ToSlotNumber: number?)
	local self: CustomEnum.Room = self
	
	self.Slots[SlotNumber].Open = false
	self.Slots[SlotNumber].ConnectTo = To
	
	self:UpdateSlots()
	
	if not SHOW_SLOT_CONNECTIONS or not ToSlotNumber then return end
	
	CreateSlotUI(self, To, SlotNumber, ToSlotNumber)
end

function Room:UpdateSlots()
	local self: CustomEnum.Room = self
	
	local OpenSlots, ClosedSlots = {}, {}
	
	for Num, SlotInfo in ipairs(self.Slots) do
		if SlotInfo.Open then
			table.insert(OpenSlots, Num)
		else
			table.insert(ClosedSlots, Num)
		end
	end
	
	self.OpenSlots = OpenSlots
	self.ClosedSlots = ClosedSlots
end

function Room:ShowUsedSlots()
	local self: CustomEnum.Room = self
	
	for Num, SlotInfo in ipairs(self.Slots) do
		if not SlotInfo.Open then
			SlotInfo.SlotPart.Transparency = 0
		end
	end
end

function Room:AdjustPlayersAndCheckForUpdate(CurrentPlayes: {Player}): boolean?
	local self: CustomEnum.Room = self
	
	local LastCount = #self.Players
	local Count = #CurrentPlayes
	
	self.Players = CurrentPlayes
	self.Build:SetAttribute("PlayerCount", Count)
	
	local Methods = self.Biome.RoomMethods[self.BuildName]
	if not Methods then return end
	
	if LastCount <= 0 and Count > 0 and Methods.Enter then
		warn("Entered ", self.BuildName, "!")
		Methods.Enter(self)
		
	elseif LastCount > 0 and Count <= 0 and Methods.Exit then
		warn("Exited! ", self.BuildName, "!")
		Methods.Exit(self)
	end
	
	if Methods.Update and Count > 0 then
		return true
	end
	
	return false
end

function Room:Cleanup()
	local self: CustomEnum.Room = self
	self.Build:Destroy()
	self = nil
end

return Room