-- DataManager.lua (ModuleScript)
-- Handles all player data communication with server
-- Place in StarterGui/MainGui/GuiModules/Utility/DataManager.lua

local DataManager = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remote references
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

local UpdatePlayerStats = RemoteEvents:WaitForChild("UpdatePlayerStats")
local GetPlayerData = RemoteFunctions:WaitForChild("GetPlayerData")

-- Local data cache
local playerData = {}
local updateCallbacks = {}

-- Promise utility for async operations
local function Promise(executor)
	local self = {}
	local state = "pending"
	local value = nil
	local handlers = {}

	local function resolve(val)
		if state == "pending" then
			state = "fulfilled"
			value = val
			for _, handler in ipairs(handlers) do
				handler.onFulfilled(val)
			end
		end
	end

	local function reject(reason)
		if state == "pending" then
			state = "rejected"
			value = reason
			for _, handler in ipairs(handlers) do
				if handler.onRejected then
					handler.onRejected(reason)
				end
			end
		end
	end

	function self:andThen(onFulfilled, onRejected)
		return Promise(function(resolve, reject)
			local function handle()
				if state == "fulfilled" then
					if onFulfilled then
						local ok, result = pcall(onFulfilled, value)
						if ok then resolve(result) else reject(result) end
					else
						resolve(value)
					end
				elseif state == "rejected" then
					if onRejected then
						local ok, result = pcall(onRejected, value)
						if ok then resolve(result) else reject(result) end
					else
						reject(value)
					end
				else
					table.insert(handlers, {onFulfilled = onFulfilled, onRejected = onRejected})
				end
			end

			handle()
		end)
	end

	function self:catch(onRejected)
		return self:andThen(nil, onRejected)
	end

	-- Execute the promise
	spawn(function()
		executor(resolve, reject)
	end)

	return self
end

-- Initialize the data manager
function DataManager.Initialize(updateCallback)
	-- Store the update callback
	if updateCallback then
		table.insert(updateCallbacks, updateCallback)
	end

	-- Listen for server updates
	UpdatePlayerStats.OnClientEvent:Connect(function(newData)
		if newData then
			print("DataManager: Received updated player data")
			playerData = newData

			-- Notify all callbacks
			for _, callback in ipairs(updateCallbacks) do
				callback(newData)
			end
		else
			warn("DataManager: Received nil playerData from server")
		end
	end)

	print("DataManager initialized")
end

-- Get player data from server
function DataManager.GetPlayerData()
	return Promise(function(resolve, reject)
		local success, result = pcall(function()
			return GetPlayerData:InvokeServer()
		end)

		if success and result then
			playerData = result
			resolve(result)
		else
			reject(result or "Failed to get player data")
		end
	end)
end

-- Get cached player data
function DataManager.GetCachedData()
	return playerData
end

-- Add an update callback
function DataManager.AddUpdateCallback(callback)
	table.insert(updateCallbacks, callback)
end

-- Remove an update callback
function DataManager.RemoveUpdateCallback(callback)
	for i, cb in ipairs(updateCallbacks) do
		if cb == callback then
			table.remove(updateCallbacks, i)
			break
		end
	end
end

return DataManager