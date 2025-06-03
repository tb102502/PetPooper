--[[
    RemoteEventsFix.server.lua
    Place this in ServerScriptService to ensure planting remote events exist
    Run this AFTER your main SystemInitializer
]]

local function WaitForGameCore(scriptName, maxWaitTime)
	maxWaitTime = maxWaitTime or 15
	local startTime = tick()

	print(scriptName .. ": Waiting for GameCore...")

	while not _G.GameCore and (tick() - startTime) < maxWaitTime do
		wait(0.5)
	end

	if not _G.GameCore then
		error(scriptName .. ": GameCore not found after " .. maxWaitTime .. " seconds!")
	end

	print(scriptName .. ": GameCore found successfully!")
	return _G.GameCore
end

local GameCore = WaitForGameCore("RemoteEventsFix")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("=== FARMING REMOTE EVENTS FIX ===")
local function EnsureRemoteEvents()
	local gameRemotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not gameRemotes then
		gameRemotes = Instance.new("Folder")
		gameRemotes.Name = "GameRemotes"
		gameRemotes.Parent = ReplicatedStorage
	end

	-- Ensure all required events exist
	local requiredEvents = {
		"PlantSeed", "HarvestCrop", "PurchaseItem", "PlayerDataUpdated", 
		"ItemPurchased", "CurrencyUpdated", "ShowNotification"
	}

	for _, eventName in ipairs(requiredEvents) do
		if not gameRemotes:FindFirstChild(eventName) then
			local event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = gameRemotes
			print("Created missing remote event: " .. eventName)
		end
	end

	local requiredFunctions = {"GetPlayerData", "GetShopItems"}
	for _, funcName in ipairs(requiredFunctions) do
		if not gameRemotes:FindFirstChild(funcName) then
			local func = Instance.new("RemoteFunction")
			func.Name = funcName
			func.Parent = gameRemotes
			print("Created missing remote function: " .. funcName)
		end
	end
end

EnsureRemoteEvents()
-- Ensure GameRemotes folder exists
local gameRemotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not gameRemotes then
	gameRemotes = Instance.new("Folder")
	gameRemotes.Name = "GameRemotes"
	gameRemotes.Parent = ReplicatedStorage
	print("Created GameRemotes folder")
end

-- Create PlantSeed remote event if it doesn't exist
local plantSeedEvent = gameRemotes:FindFirstChild("PlantSeed")
if not plantSeedEvent then
	plantSeedEvent = Instance.new("RemoteEvent")
	plantSeedEvent.Name = "PlantSeed"
	plantSeedEvent.Parent = gameRemotes
	print("Created PlantSeed RemoteEvent")
end

-- Create HarvestCrop remote event if it doesn't exist
local harvestCropEvent = gameRemotes:FindFirstChild("HarvestCrop")
if not harvestCropEvent then
	harvestCropEvent = Instance.new("RemoteEvent")
	harvestCropEvent.Name = "HarvestCrop"
	harvestCropEvent.Parent = gameRemotes
	print("Created HarvestCrop RemoteEvent")
end

-- Store in GameCore
GameCore.RemoteEvents.PlantSeed = plantSeedEvent
GameCore.RemoteEvents.HarvestCrop = harvestCropEvent

-- Connect the planting event handler
plantSeedEvent.OnServerEvent:Connect(function(player, plotModel, seedType)
	print("PlantSeed event received:", player.Name, plotModel and plotModel.Name or "nil", seedType)

	if not plotModel or not plotModel.Parent then
		warn("Invalid plot model provided")
		GameCore:SendNotification(player, "Error", "Invalid farm plot", "error")
		return
	end

	if not seedType or seedType == "" then
		warn("Invalid seed type provided")
		GameCore:SendNotification(player, "Error", "Invalid seed type", "error")
		return
	end

	-- Call the planting function
	local success, result = pcall(function()
		return GameCore:PlantSeed(player, plotModel, seedType)
	end)

	if not success then
		warn("Error in PlantSeed:", result)
		GameCore:SendNotification(player, "Planting Failed", "An error occurred while planting", "error")
	end
end)

-- Connect the harvest event handler
harvestCropEvent.OnServerEvent:Connect(function(player, plotModel)
	print("HarvestCrop event received:", player.Name, plotModel and plotModel.Name or "nil")

	if not plotModel or not plotModel.Parent then
		warn("Invalid plot model provided for harvest")
		GameCore:SendNotification(player, "Error", "Invalid farm plot", "error")
		return
	end

	-- Call the harvest function
	local success, result = pcall(function()
		return GameCore:HarvestCrop(player, plotModel)
	end)

	if not success then
		warn("Error in HarvestCrop:", result)
		GameCore:SendNotification(player, "Harvest Failed", "An error occurred while harvesting", "error")
	end
end)

print("=== FARMING REMOTE EVENTS CONNECTED ===")
print("PlantSeed and HarvestCrop events are now ready!")

-- Test function for admin commands
game.Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.Name == "TommySalami311" then -- Replace with your username
			local args = string.split(message:lower(), " ")

			if args[1] == "/testplanting" then
				print("Testing planting system...")
				local playerData = GameCore:GetPlayerData(player)
				if playerData then
					-- Give them some test seeds
					if not playerData.farming then
						playerData.farming = {inventory = {}}
					end
					if not playerData.farming.inventory then
						playerData.farming.inventory = {}
					end

					playerData.farming.inventory.carrot_seeds = 10
					playerData.farming.inventory.corn_seeds = 5

					GameCore:SavePlayerData(player)
					GameCore:SendNotification(player, "Test Seeds Given", 
						"You now have carrot and corn seeds for testing!", "success")
				end
			elseif args[1] == "/givefarmplot" then
				-- Give them a farm plot for testing
				local playerData = GameCore:GetPlayerData(player)
				if playerData then
					if not playerData.purchaseHistory then
						playerData.purchaseHistory = {}
					end
					playerData.purchaseHistory.farm_plot_starter = true

					if not playerData.farming then
						playerData.farming = {
							plots = 1,
							inventory = {
								carrot_seeds = 5,
								corn_seeds = 3
							}
						}
					end

					GameCore:CreatePlayerFarmPlot(player, 1)
					GameCore:SavePlayerData(player)

					GameCore:SendNotification(player, "Farm Plot Created", 
						"Your test farm plot has been created with seeds!", "success")
				end
			end
		end
	end)
end)

print("Admin commands: /testplanting, /givefarmplot")