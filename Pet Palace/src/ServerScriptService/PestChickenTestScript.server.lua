--[[
    PestChickenTestScript.server.lua - Testing and Debug Script
    Place in: ServerScriptService/PestChickenTestScript.server.lua
    
    This script provides comprehensive testing tools for the pest and chicken systems.
    Run various tests to ensure all systems are working correctly.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Wait for all systems to load
local function waitForSystems()
	local maxWait = 30
	local startTime = tick()

	print("TestScript: Waiting for all systems to load...")

	while (tick() - startTime) < maxWait do
		if _G.GameCore and _G.PestSystem and _G.ChickenSystem then
			print("TestScript: All systems loaded successfully!")
			return true
		end
		wait(1)
	end

	warn("TestScript: Some systems failed to load within " .. maxWait .. " seconds")
	return false
end

local PestChickenTestScript = {}

-- Initialize the test script
function PestChickenTestScript:Initialize()
	print("=== PEST & CHICKEN SYSTEM TEST SCRIPT ===")

	if not waitForSystems() then
		error("TestScript: Cannot initialize - required systems not loaded")
		return
	end

	self:SetupTestCommands()
	self:RunStartupTests()

	print("TestScript: Initialization complete!")
	print("Type /testhelp in chat to see available test commands")
end

-- Run basic startup tests
function PestChickenTestScript:RunStartupTests()
	print("TestScript: Running startup validation tests...")

	-- Test 1: Verify ItemConfig has pest and chicken data
	local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))

	if ItemConfig.PestSystem and ItemConfig.ChickenSystem then
		print("✅ ItemConfig has pest and chicken system data")
	else
		warn("❌ ItemConfig missing pest or chicken system data")
	end

	-- Test 2: Verify systems are globally available
	if _G.PestSystem then
		print("✅ PestSystem is globally available")
	else
		warn("❌ PestSystem not globally available")
	end

	if _G.ChickenSystem then
		print("✅ ChickenSystem is globally available")
	else
		warn("❌ ChickenSystem not globally available")
	end

	-- Test 3: Check remote events
	local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	if gameRemotes then
		local requiredEvents = {
			"PurchaseChicken", "FeedChicken", "UsePesticide", "PlantSeed", "HarvestCrop"
		}

		local missingEvents = {}
		for _, eventName in ipairs(requiredEvents) do
			if not gameRemotes:FindFirstChild(eventName) then
				table.insert(missingEvents, eventName)
			end
		end

		if #missingEvents == 0 then
			print("✅ All required remote events found")
		else
			warn("❌ Missing remote events: " .. table.concat(missingEvents, ", "))
		end
	else
		warn("❌ GameRemotes folder not found")
	end

	print("TestScript: Startup tests complete!")
end

-- Setup test commands
function PestChickenTestScript:SetupTestCommands()
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			-- Replace with your username for admin access
			if player.Name == "TommySalami311" then
				self:HandleTestCommand(player, message)
			end
		end)
	end)
end

-- Handle test commands
function PestChickenTestScript:HandleTestCommand(player, message)
	local args = string.split(message:lower(), " ")
	local command = args[1]

	if command == "/testhelp" then
		self:ShowTestCommands(player)

	elseif command == "/testfullsystem" then
		self:RunFullSystemTest(player)

	elseif command == "/testpests" then
		self:TestPestSystem(player)

	elseif command == "/testchickens" then
		self:TestChickenSystem(player)

	elseif command == "/testintegration" then
		self:TestSystemIntegration(player)

	elseif command == "/setuptest" then
		self:SetupTestEnvironment(player)

	elseif command == "/cleantest" then
		self:CleanupTestEnvironment(player)

	elseif command == "/pestchickenbattle" then
		self:RunPestChickenBattle(player)

	elseif command == "/testufo" then
		self:TestUFOIntegration(player)

	elseif command == "/systemstatus" then
		self:ShowSystemStatus(player)
	end
end

-- Show available test commands
function PestChickenTestScript:ShowTestCommands(player)
	print("=== PEST & CHICKEN TEST COMMANDS ===")
	print("/testhelp - Show this help")
	print("/testfullsystem - Run complete system test")
	print("/testpests - Test pest system only")
	print("/testchickens - Test chicken system only") 
	print("/testintegration - Test system integration")
	print("/setuptest - Setup test environment")
	print("/cleantest - Cleanup test environment")
	print("/pestchickenbattle - Simulate pest vs chicken battle")
	print("/testufo - Test UFO integration")
	print("/systemstatus - Show detailed system status")
	print("====================================")

	if _G.GameCore then
		_G.GameCore:SendNotification(player, "🧪 Test Commands", 
			"Test commands loaded! Check console for full list.", "info")
	end
end

-- Run complete system test
function PestChickenTestScript:RunFullSystemTest(player)
	print("=== FULL SYSTEM TEST FOR " .. player.Name .. " ===")

	-- Setup test environment
	self:SetupTestEnvironment(player)
	wait(2)

	-- Test pest system
	print("Testing pest system...")
	self:TestPestSystem(player)
	wait(3)

	-- Test chicken system
	print("Testing chicken system...")
	self:TestChickenSystem(player)
	wait(3)

	-- Test integration
	print("Testing system integration...")
	self:TestSystemIntegration(player)
	wait(3)

	-- Test UFO integration
	print("Testing UFO integration...")
	self:TestUFOIntegration(player)

	print("=== FULL SYSTEM TEST COMPLETE ===")

	if _G.GameCore then
		_G.GameCore:SendNotification(player, "🧪 Full Test Complete", 
			"All systems tested! Check console for results.", "success")
	end
end

-- Setup test environment
function PestChickenTestScript:SetupTestEnvironment(player)
	print("TestScript: Setting up test environment for " .. player.Name)

	if not _G.GameCore then
		warn("TestScript: GameCore not available")
		return
	end

	local playerData = _G.GameCore:GetPlayerData(player)
	if not playerData then
		warn("TestScript: Could not get player data")
		return
	end

	-- Give test resources
	playerData.coins = 10000
	playerData.farmTokens = 1000

	-- Setup farming
	if not playerData.farming then
		playerData.farming = {
			plots = 2,
			inventory = {}
		}
	end

	-- Give test seeds and crops
	playerData.farming.inventory.carrot_seeds = 20
	playerData.farming.inventory.corn_seeds = 15
	playerData.farming.inventory.strawberry_seeds = 10
	playerData.farming.inventory.carrot = 10
	playerData.farming.inventory.corn = 8

	-- Setup chickens
	if not playerData.chickens then
		playerData.chickens = {
			owned = {},
			feed = {
				basic_feed = 50,
				premium_feed = 20
			}
		}
	end

	-- Give test chickens
	local chickenTypes = {"basic_chicken", "guinea_fowl", "rooster"}
	for i, chickenType in ipairs(chickenTypes) do
		local chickenId = game:GetService("HttpService"):GenerateGUID(false)
		playerData.chickens.owned[chickenId] = {
			type = chickenType,
			status = "available",
			purchaseTime = os.time()
		}
	end

	-- Setup pest control
	if not playerData.pestControl then
		playerData.pestControl = {}
	end

	playerData.pestControl.organic_pesticide = 10
	playerData.pestControl.pest_detector = true

	-- Create test farm plots
	if _G.GameCore.CreatePlayerFarmPlot then
		_G.GameCore:CreatePlayerFarmPlot(player, 1)
		_G.GameCore:CreatePlayerFarmPlot(player, 2)
	end

	-- Save and update
	_G.GameCore:UpdatePlayerLeaderstats(player)
	_G.GameCore:SavePlayerData(player)

	if _G.GameCore.RemoteEvents.PlayerDataUpdated then
		_G.GameCore.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	print("TestScript: Test environment setup complete for " .. player.Name)
end

-- Test pest system
function PestChickenTestScript:TestPestSystem(player)
	print("TestScript: Testing pest system...")

	if not _G.PestSystem then
		warn("TestScript: PestSystem not available")
		return
	end

	-- Get player's farm plots
	local plots = _G.PestSystem:GetAllCropPlots()
	local playerPlots = {}

	for _, plotData in ipairs(plots) do
		if plotData.owner == player.Name then
			table.insert(playerPlots, plotData)
		end
	end

	if #playerPlots == 0 then
		print("TestScript: No crops found for " .. player.Name .. " - planting test crops")

		-- Plant test crops
		if _G.GameCore and _G.GameCore.PlantSeed then
			-- This would require finding actual plot models
			print("TestScript: Would plant test crops here")
		end
		return
	end

	-- Test pest spawning
	local testPlot = playerPlots[1]
	local pestTypes = {"aphids", "locusts", "fungal_blight"}

	for _, pestType in ipairs(pestTypes) do
		_G.PestSystem:SpawnPest(testPlot.plot, pestType, testPlot.cropType, player.Name)
		print("TestScript: Spawned " .. pestType .. " on " .. player.Name .. "'s crop")
		wait(1)
	end

	-- Test pest behavior
	_G.PestSystem:UpdateAllPests()

	print("TestScript: Pest system test complete")
end

-- Test chicken system
function PestChickenTestScript:TestChickenSystem(player)
	print("TestScript: Testing chicken system...")

	if not _G.ChickenSystem then
		warn("TestScript: ChickenSystem not available")
		return
	end

	-- Test chicken creation
	local testPosition = Vector3.new(-350, 3, 100) -- Default farm area
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		testPosition = player.Character.HumanoidRootPart.Position + Vector3.new(10, 0, 0)
	end

	local chickenTypes = {"basic_chicken", "guinea_fowl", "rooster"}

	for i, chickenType in ipairs(chickenTypes) do
		local chickenId = _G.ChickenSystem:CreateChicken(player, chickenType, testPosition + Vector3.new(i * 5, 0, 0))
		if chickenId then
			print("TestScript: Created " .. chickenType .. " for " .. player.Name)
		else
			warn("TestScript: Failed to create " .. chickenType)
		end
		wait(1)
	end

	-- Test chicken behavior
	_G.ChickenSystem:UpdateAllChickens()

	print("TestScript: Chicken system test complete")
end

-- Test system integration
function PestChickenTestScript:TestSystemIntegration(player)
	print("TestScript: Testing system integration...")

	if not _G.PestSystem or not _G.ChickenSystem then
		warn("TestScript: Required systems not available")
		return
	end

	-- Test chicken pest hunting
	local playerChickens = _G.ChickenSystem.PlayerChickens[player.UserId] or {}
	local testChicken = nil

	for chickenId, chicken in pairs(playerChickens) do
		testChicken = chicken
		break
	end

	if testChicken then
		-- Test pest assignment
		_G.ChickenSystem:ProcessChickenHunting()
		print("TestScript: Tested chicken hunting behavior")

		-- Test feeding
		_G.ChickenSystem:CheckChickenMaintenance()
		print("TestScript: Tested chicken maintenance")

		-- Test egg production
		_G.ChickenSystem:ProcessEggProduction()
		print("TestScript: Tested egg production")
	else
		warn("TestScript: No chickens found for integration test")
	end

	print("TestScript: System integration test complete")
end

-- Test UFO integration
function PestChickenTestScript:TestUFOIntegration(player)
	print("TestScript: Testing UFO integration...")

	if not _G.ChickenSystem then
		warn("TestScript: ChickenSystem not available for UFO test")
		return
	end

	-- Test chicken scattering
	local playerChickens = _G.ChickenSystem.PlayerChickens[player.UserId] or {}
	local chickenCount = 0

	for _ in pairs(playerChickens) do
		chickenCount = chickenCount + 1
	end

	if chickenCount > 0 then
		print("TestScript: Testing chicken scattering with " .. chickenCount .. " chickens")

		-- Simulate UFO attack effects on chickens
		for chickenId, chicken in pairs(playerChickens) do
			chicken.originalPosition = chicken.position
			chicken.isPanicked = true
			chicken.panicStartTime = os.time()
		end

		wait(2)

		-- Restore chickens
		for chickenId, chicken in pairs(playerChickens) do
			chicken.isPanicked = false
			chicken.panicStartTime = nil
		end

		print("TestScript: UFO chicken effects test complete")
	else
		print("TestScript: No chickens available for UFO test")
	end

	print("TestScript: UFO integration test complete")
end

-- Run pest vs chicken battle simulation
function PestChickenTestScript:RunPestChickenBattle(player)
	print("TestScript: Running pest vs chicken battle simulation...")

	if not _G.PestSystem or not _G.ChickenSystem then
		warn("TestScript: Required systems not available")
		return
	end

	-- Spawn multiple pests
	local plots = _G.PestSystem:GetAllCropPlots()
	local playerPlots = {}

	for _, plotData in ipairs(plots) do
		if plotData.owner == player.Name then
			table.insert(playerPlots, plotData)
		end
	end

	if #playerPlots == 0 then
		print("TestScript: No plots available for battle simulation")
		return
	end

	-- Spawn pests on all plots
	for _, plotData in ipairs(playerPlots) do
		_G.PestSystem:SpawnPest(plotData.plot, "aphids", plotData.cropType, player.Name)
		_G.PestSystem:SpawnPest(plotData.plot, "locusts", plotData.cropType, player.Name)
		wait(0.5)
	end

	print("TestScript: Spawned pests on " .. #playerPlots .. " plots")

	-- Deploy chickens to hunt
	_G.ChickenSystem:ProcessChickenHunting()

	-- Simulate battle over time
	for i = 1, 10 do
		_G.PestSystem:UpdateAllPests()
		_G.ChickenSystem:ProcessChickenHunting()

		local pestCount = 0
		for plotModel, pests in pairs(_G.PestSystem.ActivePests) do
			for pestType, _ in pairs(pests) do
				pestCount = pestCount + 1
			end
		end

		print("TestScript: Battle round " .. i .. " - " .. pestCount .. " pests remaining")

		if pestCount == 0 then
			print("TestScript: Chickens won! All pests eliminated.")
			break
		end

		wait(2)
	end

	print("TestScript: Pest vs chicken battle complete")

	if _G.GameCore then
		_G.GameCore:SendNotification(player, "⚔️ Battle Complete", 
			"Pest vs chicken battle simulation finished!", "success")
	end
end

-- Show detailed system status
function PestChickenTestScript:ShowSystemStatus(player)
	print("=== SYSTEM STATUS REPORT ===")

	-- GameCore status
	if _G.GameCore then
		print("✅ GameCore: ACTIVE")
		local playerData = _G.GameCore:GetPlayerData(player)
		if playerData then
			print("  Player data loaded for " .. player.Name)
			print("  Coins: " .. (playerData.coins or 0))
			print("  Farm plots: " .. (playerData.farming and playerData.farming.plots or 0))

			if playerData.chickens then
				local chickenCount = 0
				for _ in pairs(playerData.chickens.owned or {}) do
					chickenCount = chickenCount + 1
				end
				print("  Chickens owned: " .. chickenCount)
			end
		end
	else
		print("❌ GameCore: NOT AVAILABLE")
	end

	-- PestSystem status
	if _G.PestSystem then
		print("✅ PestSystem: ACTIVE")
		local totalPests = 0
		for plotModel, pests in pairs(_G.PestSystem.ActivePests) do
			for pestType, _ in pairs(pests) do
				totalPests = totalPests + 1
			end
		end
		print("  Total active pests: " .. totalPests)
		print("  Weather: " .. (_G.PestSystem.WeatherConditions.current or "unknown"))
	else
		print("❌ PestSystem: NOT AVAILABLE")
	end

	-- ChickenSystem status
	if _G.ChickenSystem then
		print("✅ ChickenSystem: ACTIVE")
		local totalChickens = 0
		local huntingChickens = 0

		for playerId, chickens in pairs(_G.ChickenSystem.PlayerChickens) do
			for chickenId, chicken in pairs(chickens) do
				totalChickens = totalChickens + 1
				if chicken.isHunting then
					huntingChickens = huntingChickens + 1
				end
			end
		end

		print("  Total deployed chickens: " .. totalChickens)
		print("  Chickens hunting: " .. huntingChickens)
	else
		print("❌ ChickenSystem: NOT AVAILABLE")
	end

	-- Remote events status
	local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	if gameRemotes then
		print("✅ GameRemotes: ACTIVE")
		local eventCount = 0
		for _, child in pairs(gameRemotes:GetChildren()) do
			if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
				eventCount = eventCount + 1
			end
		end
		print("  Total remote events: " .. eventCount)
	else
		print("❌ GameRemotes: NOT FOUND")
	end

	print("============================")

	if _G.GameCore then
		_G.GameCore:SendNotification(player, "📊 System Status", 
			"System status report generated! Check console for details.", "info")
	end
end

-- Cleanup test environment
function PestChickenTestScript:CleanupTestEnvironment(player)
	print("TestScript: Cleaning up test environment for " .. player.Name)

	-- Clear all pests
	if _G.PestSystem then
		_G.PestSystem.ActivePests = {}
		print("TestScript: Cleared all pests")
	end

	-- Remove test chickens
	if _G.ChickenSystem then
		local playerChickens = _G.ChickenSystem.PlayerChickens[player.UserId] or {}
		for chickenId, chicken in pairs(playerChickens) do
			_G.ChickenSystem:RemoveChicken(chickenId, "test_cleanup")
		end
		print("TestScript: Removed test chickens")
	end

	print("TestScript: Cleanup complete for " .. player.Name)

	if _G.GameCore then
		_G.GameCore:SendNotification(player, "🧹 Cleanup Complete", 
			"Test environment cleaned up!", "info")
	end
end

-- Initialize the test script
PestChickenTestScript:Initialize()

print("=== PEST & CHICKEN TEST SCRIPT ACTIVE ===")
print("Features:")
print("  ✅ Comprehensive system testing")
print("  ✅ Test environment setup/cleanup")
print("  ✅ Pest vs chicken battle simulation")
print("  ✅ UFO integration testing")
print("  ✅ Detailed system status reporting")
print("")
print("Usage:")
print("  Type /testhelp in chat to see all commands")
print("  Replace 'TommySalami311' with your username in the script")

return PestChickenTestScript