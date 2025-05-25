-- FarmingServer.server.lua
-- Place in ServerScriptService
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Load PlayerDataService
local PlayerDataService
local success = pcall(function()
	PlayerDataService = require(ServerStorage:WaitForChild("Modules"):WaitForChild("PlayerDataService"))
end)

if not success then
	warn("PlayerDataService not found - farming purchases won't work with currency system")
end

-- Load ShopData
local ShopData
local shopSuccess = pcall(function()
	ShopData = require(ReplicatedStorage:WaitForChild("ShopData"))
end)

if not shopSuccess then
	warn("ShopData not found - some features may not work")
end

-- Ensure modules exist
if not ReplicatedStorage:FindFirstChild("Modules") then
	local modulesFolder = Instance.new("Folder")
	modulesFolder.Name = "Modules"
	modulesFolder.Parent = ReplicatedStorage
end

-- Load FarmingModule
local FarmingModule = require(ReplicatedStorage.Modules:WaitForChild("FarmingModule"))

-- Ensure RemoteEvents exist
if not ReplicatedStorage:FindFirstChild("RemoteEvents") then
	local remoteEvents = Instance.new("Folder")
	remoteEvents.Name = "RemoteEvents"
	remoteEvents.Parent = ReplicatedStorage
end

local RemoteEvents = ReplicatedStorage.RemoteEvents

local function createRemoteEvent(name)
	if not RemoteEvents:FindFirstChild(name) then
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = RemoteEvents
	end
	return RemoteEvents:FindFirstChild(name)
end

-- Create remote events
local BuySeed = createRemoteEvent("BuySeed")
local PlantSeed = createRemoteEvent("PlantSeed")
local HarvestPlant = createRemoteEvent("HarvestPlant")
local FeedPig = createRemoteEvent("FeedPig")
local GetFarmingData = createRemoteEvent("GetFarmingData")
local SendNotification = createRemoteEvent("SendNotification")

-- Helper function to find item in shop data
local function findShopItem(itemId)
	if not ShopData or not ShopData.Farming then return nil end

	for _, item in ipairs(ShopData.Farming) do
		if item.ID == itemId then
			return item
		end
	end
	return nil
end

-- Handle player joining
Players.PlayerAdded:Connect(function(player)
	-- Create farming area
	FarmingModule.SetupFarmingArea(player)

	-- Create pig
	FarmingModule.CreatePig(player)

	-- Send initial data
	wait(2) -- Give time for other systems to load
	local playerData = FarmingModule.GetPlayerFarmingData(player)
	GetFarmingData:FireClient(player, playerData)
end)

-- Handle buying seeds (integrated with existing shop system)
BuySeed.OnServerEvent:Connect(function(player, seedID, quantity)
	quantity = quantity or 1

	-- Find item in shop data
	local itemData = findShopItem(seedID)
	if not itemData then
		SendNotification:FireClient(player, "Error", "Item not found: " .. seedID, "error")
		return
	end

	-- Check if player has enough currency
	if PlayerDataService then
		local playerData = PlayerDataService.GetPlayerData(player)
		if not playerData then
			SendNotification:FireClient(player, "Error", "Could not load player data", "error")
			return
		end

		local currencyField = string.lower(itemData.Currency or "coins")
		local totalCost = itemData.Price * quantity

		if not playerData[currencyField] or playerData[currencyField] < totalCost then
			SendNotification:FireClient(player, "Not Enough " .. itemData.Currency, 
				"You need " .. totalCost .. " " .. itemData.Currency, "error")
			return
		end

		-- Spend currency
		PlayerDataService.SpendCurrency(player, currencyField, totalCost)
	end

	-- Add seeds to farming inventory
	local farmingData = FarmingModule.GetPlayerFarmingData(player)
	farmingData.inventory[seedID] = (farmingData.inventory[seedID] or 0) + quantity
	FarmingModule.SavePlayerFarmingData(player, farmingData)

	GetFarmingData:FireClient(player, farmingData)
	SendNotification:FireClient(player, "Seeds Purchased!", "You bought " .. quantity .. " " .. itemData.Name, "success")
end)

-- Handle planting seeds
PlantSeed.OnServerEvent:Connect(function(player, plotID, seedID)
	local farmingAreas = workspace:FindFirstChild("FarmingAreas")
	if not farmingAreas then return end

	local playerFarmArea = farmingAreas:FindFirstChild(player.Name)
	if not playerFarmArea then return end

	local plot = playerFarmArea:FindFirstChild("FarmPlot_" .. plotID)
	if not plot then return end

	local success, message = FarmingModule.PlantSeed(player, plot, seedID)

	local playerData = FarmingModule.GetPlayerFarmingData(player)
	GetFarmingData:FireClient(player, playerData)

	SendNotification:FireClient(
		player,
		success and "Seed Planted!" or "Planting Failed",
		message,
		success and "plant" or "error"
	)
end)

-- Handle harvesting
HarvestPlant.OnServerEvent:Connect(function(player, plotID)
	local farmingAreas = workspace:FindFirstChild("FarmingAreas")
	if not farmingAreas then return end

	local playerFarmArea = farmingAreas:FindFirstChild(player.Name)
	if not playerFarmArea then return end

	local plot = playerFarmArea:FindFirstChild("FarmPlot_" .. plotID)
	if not plot then return end

	local success, message = FarmingModule.HarvestPlant(player, plot)

	local playerData = FarmingModule.GetPlayerFarmingData(player)
	GetFarmingData:FireClient(player, playerData)

	SendNotification:FireClient(
		player,
		success and "Harvest Success!" or "Harvest Failed",
		message,
		success and "harvest" or "error"
	)
end)

-- Handle feeding pig
FeedPig.OnServerEvent:Connect(function(player, cropID)
	local success, message = FarmingModule.FeedPig(player, cropID)

	local playerData = FarmingModule.GetPlayerFarmingData(player)
	GetFarmingData:FireClient(player, playerData)

	SendNotification:FireClient(
		player,
		success and "Pig Fed!" or "Feeding Failed",
		message,
		success and "feed" or "error"
	)
end)

-- Handle data requests
GetFarmingData.OnServerEvent:Connect(function(player)
	local playerData = FarmingModule.GetPlayerFarmingData(player)
	GetFarmingData:FireClient(player, playerData)
end)

-- Update plant growth loop
spawn(function()
	while true do
		wait(1)
		local currentTime = os.time()
		local farmingAreas = workspace:FindFirstChild("FarmingAreas")

		if farmingAreas then
			for _, playerArea in pairs(farmingAreas:GetChildren()) do
				for _, plot in pairs(playerArea:GetChildren()) do
					if plot:IsA("Model") and plot:GetAttribute("IsPlanted") then
						FarmingModule.UpdatePlantGrowth(plot, currentTime)
					end
				end
			end
		end
	end
end)

print("Farming Server System Initialized!")