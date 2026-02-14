-- finobinos - Original author - 16 October 2021
-- flamenco687 - Modified for personal use - 1 November 2021

--[[
	-- Static methods:

	Maid.new() --> table
	Maid.IsMaid(self : any) --> boolean

	-- Instance methods:

	Maid:GiveTask(task : table | function | RBXScriptConnection | Instance) --> task
	Maid:Cleanup() --> ()
	Maid:EndTask(task: table | function | RBXScriptConnection | Instanceble) --> ()
	Maid:RemoveTask(task: table | function | RBXScriptConnection | Instance) --> ()
	Maid:LinkToInstance(instance: Instance) --> (instance, ManualConnection)
		ManualConnection:Disconnect() --> ()
		ManualConnection:IsConnected() --> boolean
	Maid:Destroy() --> ()
]]

--[=[
	@class Maid
	Maids track tasks and clean them when needed.

	For e.g:
	```lua
	local maid = Maid.new()
	local connection = workspace.ChildAdded:Connect(function()

	end)
	maid:GiveTask(connection)
	maid:Cleanup()

	-- Connections aren't necessarily immediately disconnected when `Disconnect` is called on the.
	-- Much reliable to check in the next engine execution step:
	task.defer(function()
		print(connection.Connected) --> false
	end)
	```
]=]

local Maid = {}
Maid.__index = Maid

local Players = game:GetService("Players")

local LocalConstants = {
	ErrorMessages = {
		InvalidArgument = "Invalid argument#%d to %s: expected %s, got %s",
	},
}

local function IsInstanceDestroyed(instance)
	-- This function call is used to determine if an instance is ALREADY destroyed,
	-- and has been edited to be more reliable but still quite hacky due to Roblox
	-- not giving us a method to determine if an instance is already destroyed
	local _, response = pcall(function()
		instance.Parent = instance
	end)

	return (response:find("locked") and response:find("NULL") or nil) ~= nil
end

local function DisconnectTask(task)
	if typeof(task) == "function" then
		task()
	elseif typeof(task) == "RBXScriptConnection" then
		-- Task was a RBXScriptConneciton or a table with a Disconnect method
		task:Disconnect()
	else
		if task.Destroy then
			task:Destroy()
		else
			task:Disconnect()
		end
	end
end

--[=[
	A constructor method which creates a new maid.

	@return Maid 
]=]

function Maid.new()
	return setmetatable({
		_tasks = {},
	}, Maid)
end

--[=[
	A method which is used to check if the given argument is a maid or not.

	@param self any 
	@return boolean 
]=]

function Maid.IsMaid(self)
	return getmetatable(self) == Maid
end

--[=[
	Adds a task for the maid to cleanup. Note that `table` must have a `Destroy` or `Disconnect` method.

	@tag Maid
	@param task function | RBXScriptConnection | table | Instance
	@return task
]=]

function Maid:GiveTask(task)
	assert(
		typeof(task) == "function"
			or typeof(task) == "RBXScriptConnection"
			or typeof(task) == "table" and (typeof(task.Destroy) == "function" or typeof(task.Disconnect) == "function")
			or typeof(task) == "Instance",

		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Maid:GiveTask()",
			"function or RBXScriptConnection or Instance or table with Destroy or Disconnect method",
			typeof(task)
		)
	)

	self._tasks[task] = task

	return task
end

--[=[
	Removes the task so that it will not be cleaned up. 

	@tag Maid
	@param task function | RBXScriptConnection | table | Instance 
]=]

function Maid:RemoveTask(task)
	self._tasks[task] = nil
end

--[=[
	Cleans up all the added tasks.
	@tag Maid

	| Task      | Type                          |
	| ----------- | ------------------------------------ |
	| `function`  | The function will be called.  |
	| `table`     | Any `Destroy` or `Disconnect` method in the table will be called. |
	| `Instance`    | The instance will be destroyed. |
	| `RBXScriptConnection`    | The connection will be disconnected. |
]=]

function Maid:Cleanup()
	-- Next allows us to easily traverse the table accounting for more values being added. This allows us to clean
	-- up tasks spawned by the cleaning up of current tasks.

	local tasks = self._tasks
	local key, task = next(tasks)

	while task do
		tasks[key] = nil

		DisconnectTask(task)

		key, task = next(tasks)
	end
end

--[=[
	@tag Maid

	Disconnect a specific task

	@param task -- Task to disconnect
]=]

function Maid:EndTask(task)
	self._tasks[task] = nil
	DisconnectTask(task)
end

--[=[
	@tag Maid

	Destroys the maid by first cleaning up all tasks, and then setting all the keys in it to `nil`
	and lastly, sets the metatable of the maid to `nil`.

	:::warning
	Trivial errors will occur if your code unintentionally works on a destroyed maid, only call this method when you're done working with the maid.
	:::
]=]

function Maid:Destroy()
	self:Cleanup()

	for key, _ in pairs(self) do
		self[key] = nil
	end

	setmetatable(self, nil)
end

local ManualConnection = {}
ManualConnection.__index = ManualConnection

do
	function ManualConnection.new()
		return setmetatable({ _isConnected = true }, ManualConnection)
	end

	function ManualConnection:Disconnect()
		self._isConnected = false
	end

	function ManualConnection:IsConnected()
		return self._isConnected
	end
end

--[=[
	Links the given instance to the maid so that the maid will clean up all the tasks once the instance has been destroyed
	via `Instance:Destroy`. The connection returned by this maid contains the following methods:

	| Methods      | Description                          |
	| ----------- | ------------------------------------ |
	| `Disconnect`  | The connection will be disconnected and the maid will unlink to the instance it was linked to.  |
	| `IsConnected` | Returns a boolean indicating if the connection has been disconnected. |

	Note that the maid will still unlink to the given instance if it has been cleaned up!

	@param instance Instance
	@return Connection 
]=]

function Maid:LinkToInstance(instance)
	assert(
		typeof(instance) == "Instance",
		LocalConstants.ErrorMessages.InvalidArgument:format(1, "Maid:LinkToInstance()", "Instance", typeof(instance))
	)

	local manualConnection = ManualConnection.new()
	self:GiveTask(manualConnection)

	local function TrackInstanceConnectionForCleanup(mainConnection)
		while mainConnection.Connected and not instance.Parent and manualConnection:IsConnected() do
			task.wait()
		end

		if not instance.Parent and manualConnection:IsConnected() then
			self:Cleanup()
		end
	end

	local mainConnection
	mainConnection = self:GiveTask(instance:GetPropertyChangedSignal("Parent"):Connect(function()
		if not instance.Parent then
			task.defer(function()
				if not manualConnection:IsConnected() then
					return
				end

				-- If the connection has also been disconnected, then its
				-- guaranteed that the instance has been destroyed through
				-- Destroy():
				if not mainConnection.Connected then
					self:Cleanup()
				else
					-- The instance was just parented to nil:
					TrackInstanceConnectionForCleanup(mainConnection)
				end
			end)
		end
	end))
	self:GiveTask(mainConnection)

	-- Special case for players as they are destroyed late when they leave:
	if instance:IsA("Player") then
		self:GiveTask(Players.PlayerRemoving:Connect(function(playerRemoved)
			if instance == playerRemoved and manualConnection:IsConnected() then
				self:Cleanup()
			end
		end))
	end

	if not instance.Parent then
		task.spawn(TrackInstanceConnectionForCleanup, mainConnection)
	end

	if IsInstanceDestroyed(instance) then
		self:Cleanup()
	end

	return manualConnection
end

return Maid
