--[[
    Farming System Debug Script
    Place this in ServerScriptService as a standalone script for testing
    
    This script helps debug farming issues and provides test functions
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for GameCore
local function waitForGameCore()
	local maxWait = 30
	local startTime = tick()

	while not _G.GameCore and (tick() - startTime) < maxWait do
		wait(0.5)
	end

	return _G.GameCore
end

local GameCore = waitForGameCore()

if not GameCore then
	error("FarmingDebug: GameCore not found!")
end

print("=== FARMING SYSTEM DEBUG SCRIPT ACTIVE ===")

-- Test function to give a player everything they need for farming
local function setupPlayerForFarmingTest(player)
	local playerData = GameCore:GetPlayerData(player)
	if not playerData then
		print("FarmingDebug: No player data for " .. player.Name)
		return false
	end

	-- Give them a farm plot if they don't have one
	if not playerData.purchaseHistory then
		playerData.purchaseHistory = {}
	end
	playerData.purchaseHistory.farm_plot_starter = true

	-- Set up farming data
	if not playerData.farming then
		playerData.farming = {
			plots = 1,
			inventory = {}
		}
	end

	-- Give them some coins and farm tokens
	playerData.coins = (playerData.coins or 0) + 1000
	playerData.farmTokens = (playerData.farmTokens or 0) + 100

	-- Give them a variety of seeds
	playerData.farming.inventory = playerData.farming.inventory or {}
	playerData.farming.inventory.carrot_seeds = 10
	playerData.farming.inventory.corn_seeds = 8
	playerData.farming.inventory.strawberry_seeds = 5
	playerData.farming.inventory.golden_seeds = 2

	-- Save the data
	GameCore:SavePlayerData(player)
	GameCore:UpdatePlayerLeaderstats(player)

	-- Create their farm plot if it doesn't exist
	if GameCore.CreatePlayerFarmPlot then
		GameCore:CreatePlayerFarmPlot(player, 1)
	end

	-- Update client
	if GameCore.RemoteEvents and GameCore.RemoteEvents.PlayerDataUpdated then
		GameCore.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	print("FarmingDebug: Set up " .. player.Name .. " with farming essentials")
	return true
end

-- Test function to check if farming system is working
local function testFarmingSystem(player)
	print("=== FARMING SYSTEM TEST FOR " .. player.Name .. " ===")

	-- Check GameCore
	print("GameCore available:", _G.GameCore ~= nil)

	-- Check player data
	local playerData = GameCore:GetPlayerData(player)
	print("Player data exists:", playerData ~= nil)

	if playerData then
		print("Has purchase history:", playerData.purchaseHistory ~= nil)
		print("Has farm plot:", playerData.purchaseHistory and playerData.purchaseHistory.farm_plot_starter or false)
		print("Has farming data:", playerData.farming ~= nil)

		if playerData.farming then
			print("Plots:", playerData.farming.plots or 0)
			print("Has inventory:", playerData.farming.inventory ~= nil)

			if playerData.farming.inventory then
				print("Inventory items:")
				for itemId, quantity in pairs(playerData.farming.inventory) do
					print("  " .. itemId .. ": " .. quantity)
				end
			end
		end
	end

	-- Check remote events
	print("Remote events exist:", GameCore.RemoteEvents ~= nil)
	if GameCore.RemoteEvents then
		local events = {"PlantSeed", "HarvestCrop", "SellCrop", "PlayerDataUpdated"}
		for _, eventName in ipairs(events) do
			print("  " .. eventName .. ":", GameCore.RemoteEvents[eventName] ~= nil)
		end
	end

	-- Check farm plots in workspace
	local areas = workspace:FindFirstChild("Areas")
	if areas then
		local starterMeadow = areas:FindFirstChild("Starter Meadow")
		if starterMeadow then
			local farmArea = starterMeadow:FindFirstChild("Farm")
			if farmArea then
				local playerFarm = farmArea:FindFirstChild(player.Name .. "_Farm")
				print("Player farm exists in workspace:", playerFarm ~= nil)
				if playerFarm then
					local plotCount = 0
					for _, child in pairs(playerFarm:GetChildren()) do
						if child:IsA("Model") and child.Name:find("FarmPlot") then
							plotCount = plotCount + 1
						end
					end
					print("Physical plots found:", plotCount)
				end
			else
				print("Farm area not found in workspace")
			end
		else
			print("Starter Meadow not found")
		end
	else
		print("Areas folder not found")
	end

	-- Check ItemConfig
	local success, ItemConfig = pcall(function()
		return require(ReplicatedStorage:WaitForChild("ItemConfig"))
	end)
	print("ItemConfig loadable:", success)

	if success and ItemConfig then
		print("ItemConfig has seed data:", ItemConfig.GetSeedData ~= nil)
		if ItemConfig.GetSeedData then
			local carrotData = ItemConfig.GetSeedData("carrot_seeds")
			print("Carrot seed data exists:", carrotData ~= nil)
		end
	end

	print("=== END FARMING SYSTEM TEST ===")
end

-- Chat commands for testing
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		-- Replace with your username for admin commands
		if player.Name == "TommySalami311" then
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/farmtest" then
				testFarmingSystem(player)

			elseif command == "/setupfarming" then
				local success = setupPlayerForFarmingTest(player)
				if success then
					GameCore:SendNotification(player, "Debug: Farming Setup", 
						"You now have seeds, coins, and a farm plot!", "success")
				end

			elseif command == "/testpurchase" then
				-- Test seed purchase
				print("Testing seed purchase for " .. player.Name)
				local success = GameCore:HandlePurchase(player, "carrot_seeds", 5)
				print("Purchase result:", success)

			elseif command == "/testplant" then
				-- Find a plot and test planting
				local areas = workspace:FindFirstChild("Areas")
				if areas then
					local starterMeadow = areas:FindFirstChild("Starter Meadow")
					if starterMeadow then
						local farmArea = starterMeadow:FindFirstChild("Farm")
						if farmArea then
							local playerFarm = farmArea:FindFirstChild(player.Name .. "_Farm")
							if playerFarm then
								local plot = playerFarm:FindFirstChild("FarmPlot_1")
								if plot then
									local plantingSpots = plot:FindFirstChild("PlantingSpots")
									if plantingSpots then
										local spot = plantingSpots:FindFirstChild("PlantingSpot_1")
										if spot then
											print("Testing plant on spot for " .. player.Name)
											local success = GameCore:PlantSeed(player, spot, "carrot_seeds")
											print("Plant result:", success)
										else
											print("No planting spot found")
										end
									else
										print("No planting spots found")
									end
								else
									print("No farm plot found")
								end
							else
								print("No player farm found")
							end
						end
					end
				end

			elseif command == "/clientdebug" then
				-- Tell client to run debug
				local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
				if remoteFolder then
					local debugEvent = remoteFolder:FindFirstChild("ShowNotification")
					if debugEvent then
						debugEvent:FireClient(player, "Debug Command", 
							"Run _G.DebugFarming() in your console!", "info")
					end
				end
				print("Told " .. player.Name .. " to run client debug")

			elseif command == "/forceclientupdate" then
				-- Force update client with fresh data
				local playerData = GameCore:GetPlayerData(player)
				if playerData and GameCore.RemoteEvents.PlayerDataUpdated then
					GameCore.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
					print("Forced client update for " .. player.Name)
				end

			elseif command == "/checkremotes" then
				-- Check if remote events are working
				print("=== REMOTE EVENTS CHECK ===")
				local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
				if remoteFolder then
					print("GameRemotes folder exists")
					local remoteCount = 0
					for _, remote in pairs(remoteFolder:GetChildren()) do
						if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
							remoteCount = remoteCount + 1
							print("  " .. remote.Name .. " (" .. remote.ClassName .. ")")
						end
					end
					print("Total remotes:", remoteCount)
				else
					print("GameRemotes folder not found!")
				end
				print("=========================")
			end
		end
	end)
end)

-- Periodic health check
spawn(function()
	while true do
		wait(60) -- Every minute

		local playerCount = #Players:GetPlayers()
		local gameCoreActive = _G.GameCore ~= nil

		print("FarmingDebug: Health Check - Players: " .. playerCount .. ", GameCore: " .. (gameCoreActive and "OK" or "MISSING"))

		if gameCoreActive and playerCount > 0 then
			-- Check if any players have farming issues
			for _, player in pairs(Players:GetPlayers()) do
				local playerData = _G.GameCore:GetPlayerData(player)
				if playerData and playerData.purchaseHistory and playerData.purchaseHistory.farm_plot_starter then
					-- Player should have farming - check if they have inventory issues
					if not playerData.farming or not playerData.farming.inventory then
						print("FarmingDebug: WARNING - " .. player.Name .. " has farm plot but no farming inventory!")
					end
				end
			end
		end
	end
end)

print("Farming Debug Commands (CHAT):")
print("  /farmtest - Run complete farming system test")
print("  /setupfarming - Give player everything needed for farming")
print("  /testpurchase - Test seed purchase")
print("  /testplant - Test planting on first plot")
print("  /clientdebug - Tell client to run debug")
print("  /forceclientupdate - Force client data update")
print("  /checkremotes - Check remote events")
print("")
print("Client Debug Command (Console): _G.DebugFarming()")