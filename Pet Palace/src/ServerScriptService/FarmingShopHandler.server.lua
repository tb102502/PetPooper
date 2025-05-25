-- Place this script in ServerScriptService
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Load modules with error handling
local PlayerDataService
pcall(function()
	PlayerDataService = require(ServerStorage:WaitForChild("Modules"):WaitForChild("PlayerDataService"))
end)

if not PlayerDataService then
	error("PlayerDataService module not found! Shop functionality will not work.")
	return
end

local ShopData
pcall(function()
	ShopData = require(ReplicatedStorage:WaitForChild("ShopData"))
end)

if not ShopData then
	error("ShopData module not found! Shop functionality will not work.")
	return
end

-- Get RemoteEvents with error handling
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local BuySeed
pcall(function()
	BuySeed = RemoteEvents:WaitForChild("BuySeed", 10)
	if not BuySeed then
		-- Create it if not found
		BuySeed = Instance.new("RemoteEvent")
		BuySeed.Name = "BuySeed"
		BuySeed.Parent = RemoteEvents
		print("Created BuySeed RemoteEvent")
	end
end)

local SendNotification
pcall(function()
	SendNotification = RemoteEvents:WaitForChild("SendNotification", 5)
end)

local UpdatePlayerStats
pcall(function()
	UpdatePlayerStats = RemoteEvents:WaitForChild("UpdatePlayerStats", 5)
end)

-- Player purchase debounce to prevent spam
local purchaseDebounce = {}
local PURCHASE_COOLDOWN = 1 -- seconds

-- Helper function to find item data by ID with error checking
local function findItemById(itemId)
	if not itemId then return nil end

	-- Check Farming category
	if ShopData.Farming then
		for _, item in ipairs(ShopData.Farming) do
			if item and item.ID and item.ID == itemId then
				return item, "Farming"
			end
		end
	end

	-- Check FarmingTools category
	if ShopData.FarmingTools then
		for _, item in ipairs(ShopData.FarmingTools) do
			if item and item.ID and item.ID == itemId then
				return item, "FarmingTools"
			end
		end
	end

	return nil
end

-- Function to send notifications safely
local function notifyPlayer(player, title, message, notificationType)
	if not player or not SendNotification then return end

	pcall(function()
		SendNotification:FireClient(player, title, message, notificationType or "info")
	end)
end

-- Function to update player stats safely
local function updatePlayerStats(player, data)
	if not player or not UpdatePlayerStats then return end

	pcall(function()
		UpdatePlayerStats:FireClient(player, data)
	end)
end

-- Handle seed purchases with error handling
if BuySeed then
	BuySeed.OnServerEvent:Connect(function(player, itemId)
		-- Check debounce
		local userId = player.UserId
		local currentTime = os.time()

		if purchaseDebounce[userId] and currentTime - purchaseDebounce[userId] < PURCHASE_COOLDOWN then
			notifyPlayer(player, "Too Fast", "Please wait before making another purchase", "warning")
			return
		end

		purchaseDebounce[userId] = currentTime

		-- Get the player data with error handling
		local playerData
		local success = pcall(function()
			playerData = PlayerDataService.GetPlayerData(player)
		end)

		if not success or not playerData then
			notifyPlayer(player, "Error", "Could not load player data", "error")
			return
		end

		-- Find the item in the shop data
		local itemData, category = findItemById(itemId)
		if not itemData then
			notifyPlayer(player, "Error", "Item not found: " .. tostring(itemId), "error")
			return
		end

		-- Check if the player has enough currency
		local currencyField = string.lower(itemData.Currency or "coins")
		if not playerData[currencyField] or playerData[currencyField] < itemData.Price then
			notifyPlayer(player, "Not Enough " .. itemData.Currency, 
				"You need " .. itemData.Price .. " " .. itemData.Currency .. " to buy " .. itemData.Name, "error")
			return
		end

		-- Process the purchase based on item type
		success = pcall(function()
			-- Handle different item types
			if itemData.Type == "Seed" then
				-- Add seed to inventory
				if not playerData.inventory then
					playerData.inventory = {}
				end

				-- Increment seed count in inventory
				playerData.inventory[itemId] = (playerData.inventory[itemId] or 0) + 1

				-- Spend the currency
				PlayerDataService.SpendCurrency(player, currencyField, itemData.Price)

				-- Send notification
				notifyPlayer(player, "Purchase Successful", 
					"Bought " .. itemData.Name .. " for " .. itemData.Price .. " " .. itemData.Currency, "success")

			elseif itemData.Type == "Upgrade" and itemId == "farm_plot_upgrade" then
				-- Initialize upgrades if needed
				if not playerData.upgrades then
					playerData.upgrades = {}
				end

				-- Initialize farm plots if needed
				if not playerData.upgrades.farmPlots then
					playerData.upgrades.farmPlots = 1
				end

				-- Check if maxed
				if playerData.upgrades.farmPlots >= itemData.MaxLevel then
					notifyPlayer(player, "Max Level Reached", 
						"You already have the maximum number of farm plots", "error")
					return
				end

				-- Upgrade farm plots
				playerData.upgrades.farmPlots = playerData.upgrades.farmPlots + 1

				-- Spend the currency
				PlayerDataService.SpendCurrency(player, currencyField, itemData.Price)

				-- Send notification
				notifyPlayer(player, "Upgrade Successful", 
					"Unlocked a new farm plot! Total plots: " .. (playerData.upgrades.farmPlots + 3), "success")
			elseif itemData.Type == "Tool" then
				-- Add tool to inventory
				if not playerData.tools then
					playerData.tools = {}
				end

				-- Add tool with timestamp if it has duration
				if itemData.Duration then
					playerData.tools[itemId] = {
						owned = true,
						expiresAt = os.time() + itemData.Duration
					}
				else
					-- Permanent tool
					playerData.tools[itemId] = {
						owned = true
					}
				end

				-- Spend the currency
				PlayerDataService.SpendCurrency(player, currencyField, itemData.Price)

				-- Send notification
				notifyPlayer(player, "Purchase Successful", 
					"Bought " .. itemData.Name .. " for " .. itemData.Price .. " " .. itemData.Currency, "success")
			end

			-- Update player stats
			updatePlayerStats(player, playerData)
		end)

		if not success then
			notifyPlayer(player, "Error", "Failed to process purchase", "error")
			warn("Error processing purchase for " .. player.Name .. ": " .. itemId)
		else
			print(player.Name .. " purchased " .. itemData.Name)
		end
	end)
end

print("Farming Shop Handler initialized with error handling")