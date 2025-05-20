-- CreateRemoteEvents.server.lua
-- Place in ServerScriptService to create required RemoteEvents

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create RemoteEvents folder if it doesn't exist
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not RemoteEvents then
	RemoteEvents = Instance.new("Folder")
	RemoteEvents.Name = "RemoteEvents"
	RemoteEvents.Parent = ReplicatedStorage
	print("Created RemoteEvents folder")
end

-- Create RemoteFunctions folder if it doesn't exist
local RemoteFunctions = ReplicatedStorage:FindFirstChild("RemoteFunctions")
if not RemoteFunctions then
	RemoteFunctions = Instance.new("Folder")
	RemoteFunctions.Name = "RemoteFunctions"
	RemoteFunctions.Parent = ReplicatedStorage
	print("Created RemoteFunctions folder")
end

-- Required RemoteEvents
local requiredEvents = {
	"OpenShop",
	"OpenShopClient", 
	"BuyUpgrade",
	"UnlockArea",
	"BuyPremium",
	"UpdateShopData",
	"UpdatePlayerStats",
	"SendNotification",
	"EnableAutoCollect",
	"CollectPet"
}

-- Create RemoteEvents
for _, eventName in ipairs(requiredEvents) do
	if not RemoteEvents:FindFirstChild(eventName) then
		local remoteEvent = Instance.new("RemoteEvent")
		remoteEvent.Name = eventName
		remoteEvent.Parent = RemoteEvents
		print("Created RemoteEvent:", eventName)
	end
end

-- Required RemoteFunctions
local requiredFunctions = {
	"GetPlayerData",
	"CheckGamePassOwnership"
}

-- Create RemoteFunctions
for _, funcName in ipairs(requiredFunctions) do
	if not RemoteFunctions:FindFirstChild(funcName) then
		local remoteFunction = Instance.new("RemoteFunction")
		remoteFunction.Name = funcName
		remoteFunction.Parent = RemoteFunctions
		print("Created RemoteFunction:", funcName)
	end
end

print("All RemoteEvents and RemoteFunctions created successfully!")