-- RemoteManager.lua (ModuleScript)
-- Handles creation and management of RemoteEvents/RemoteFunctions
-- Place in StarterGui/MainGui/GuiModules/Utility/RemoteManager.lua

local RemoteManager = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Cache for remote objects
local remoteCache = {}

-- Ensure remote folders exist
local function ensureRemoteFolders()
	if not ReplicatedStorage:FindFirstChild("RemoteEvents") then
		local folder = Instance.new("Folder")
		folder.Name = "RemoteEvents"
		folder.Parent = ReplicatedStorage
	end

	if not ReplicatedStorage:FindFirstChild("RemoteFunctions") then
		local folder = Instance.new("Folder")
		folder.Name = "RemoteFunctions"
		folder.Parent = ReplicatedStorage
	end
end

-- Get or create a RemoteEvent
function RemoteManager.GetRemoteEvent(name)
	if remoteCache[name] then
		return remoteCache[name]
	end

	ensureRemoteFolders()
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	local remote = remoteEvents:FindFirstChild(name)
	if not remote then
		-- Wait for it to be created by server
		remote = remoteEvents:WaitForChild(name, 10)
		if not remote then
			warn("RemoteManager: RemoteEvent '" .. name .. "' not found after 10 seconds")
			return nil
		end
	end

	remoteCache[name] = remote
	return remote
end

-- Get or create a RemoteFunction
function RemoteManager.GetRemoteFunction(name)
	if remoteCache[name] then
		return remoteCache[name]
	end

	ensureRemoteFolders()
	local remoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

	local remote = remoteFunctions:FindFirstChild(name)
	if not remote then
		-- Wait for it to be created by server
		remote = remoteFunctions:WaitForChild(name, 10)
		if not remote then
			warn("RemoteManager: RemoteFunction '" .. name .. "' not found after 10 seconds")
			return nil
		end
	end

	remoteCache[name] = remote
	return remote
end

-- Pre-load commonly used remotes
function RemoteManager.Initialize()
	-- Pre-load essential remotes
	local essentialEvents = {
		"UpdatePlayerStats",
		"BuyUpgrade",
		"UnlockArea",
		"SellPet",
		"SellPetGroup",
		"SellAllPets",
		"OpenShop",
		"SendNotification"
	}

	local essentialFunctions = {
		"GetPlayerData",
		"GetShopItems",
		"PromptPurchase",
		"CheckGamePassOwnership"
	}

	-- Load remote events
	spawn(function()
		for _, name in ipairs(essentialEvents) do
			RemoteManager.GetRemoteEvent(name)
		end
	end)

	-- Load remote functions
	spawn(function()
		for _, name in ipairs(essentialFunctions) do
			RemoteManager.GetRemoteFunction(name)
		end
	end)

	print("RemoteManager initialized")
end

-- Clear cache (useful for testing)
function RemoteManager.ClearCache()
	remoteCache = {}
end

return RemoteManager