local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
print("🌾 === Chunk-based Wheat System Integration Starting ===")
-- Integration state
local WheatIntegrationState = {
	WheatHarvestingLoaded = false,
	ScytheGiverLoaded = false,
	ItemConfigUpdated = false,
	RemoteEventsSetup = false,
	IntegrationComplete = false
}
-- Module references
local WheatHarvesting = nil
local ScytheGiver = nil
local GameCore = nil
-- ========== STEP 1: LOAD WHEAT MODULES ==========
local function LoadWheatModules()
	print("🌾 Loading chunk-based wheat harvesting modules...")
	-- Load WheatHarvesting module
	local wheatHarvestingModule = ServerScriptService:FindFirstChild("WheatHarvesting")
	if wheatHarvestingModule then
		local success, result = pcall(function()
			return require(wheatHarvestingModule)
		end)

		if success then
			WheatHarvesting = result
			WheatIntegrationState.WheatHarvestingLoaded = true
			print("✅ Chunk-based WheatHarvesting module loaded")
		else
			warn("❌ Failed to load WheatHarvesting: " .. tostring(result))
		end
	else
		warn("❌ WheatHarvesting module not found")
	end

	-- Load ScytheGiver module
	local scytheGiverModule = ServerScriptService:FindFirstChild("ScytheGiver")
	if scytheGiverModule then
		local success, result = pcall(function()
			return require(scytheGiverModule)
		end)

		if success then
			ScytheGiver = result
			WheatIntegrationState.ScytheGiverLoaded = true
			print("✅ ScytheGiver module loaded")
		else
			warn("❌ Failed to load ScytheGiver: " .. tostring(result))
		end
	else
		warn("❌ ScytheGiver module not found")
	end

	return WheatIntegrationState.WheatHarvestingLoaded and WheatIntegrationState.ScytheGiverLoaded
end
-- ========== STEP 2: SETUP WHEAT REMOTE EVENTS ==========
local function SetupWheatRemoteEvents()
	print("🌾 Setting up chunk-based wheat remote events...")
	local remotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "GameRemotes"
		remotes.Parent = ReplicatedStorage
	end

	-- Wheat harvesting remote events
	local wheatRemoteEvents = {
		"ShowWheatPrompt",
		"HideWheatPrompt",
		"StartWheatHarvesting",
		"StopWheatHarvesting",
		"SwingScythe",
		"WheatHarvestUpdate"
	}

	local eventsCreated = 0
	for _, eventName in ipairs(wheatRemoteEvents) do
		if not remotes:FindFirstChild(eventName) then
			local newEvent = Instance.new("RemoteEvent")
			newEvent.Name = eventName
			newEvent.Parent = remotes
			eventsCreated = eventsCreated + 1
			print("Created RemoteEvent: " .. eventName)
		end
	end

	WheatIntegrationState.RemoteEventsSetup = true
	print("✅ Chunk-based wheat remote events setup: " .. eventsCreated .. " events created")
	return true
end
-- ========== STEP 3: UPDATE ITEM CONFIG FOR CHUNKS ==========
local function UpdateItemConfigForWheat()
	print("🌾 Updating ItemConfig for chunk-based wheat...")
	-- Wait for ItemConfig to load
	local ItemConfig = nil
	local success, result = pcall(function()
		return require(ReplicatedStorage:WaitForChild("ItemConfig"))
	end)

	if not success then
		warn("❌ Failed to load ItemConfig: " .. tostring(result))
		return false
	end

	ItemConfig = result

	-- Add wheat to crops if not already present
	if not ItemConfig.Crops then
		ItemConfig.Crops = {}
	end

	if not ItemConfig.Crops.wheat then
		ItemConfig.Crops.wheat = {
			name = "🌾 Wheat",
			icon = "🌾",
			description = "Golden wheat harvested from chunks in the wheat field",
			sellValue = 20, -- Increased value since it's harder to get
			category = "crop",
			rarity = "common",
			harvestTime = 0 -- Instant harvest from field
		}
		print("✅ Added chunk-based wheat to ItemConfig.Crops")
	end

	-- Add wheat to shop items if not already present
	if not ItemConfig.ShopItems then
		ItemConfig.ShopItems = {}
	end

	if not ItemConfig.ShopItems.wheat then
		ItemConfig.ShopItems.wheat = {
			name = "🌾 Wheat",
			icon = "🌾",
			description = "Golden wheat - harvested in chunks from the wheat field",
			price = 20, -- Adjusted for chunk system
			currency = "coins",
			category = "farming",
			sellable = true,
			sellPrice = 20,
			maxQuantity = 999,
			purchaseOrder = 15
		}
		print("✅ Added chunk-based wheat to ItemConfig.ShopItems")
	end

	-- Add scythe to upgrades if not already present
	if not ItemConfig.ShopItems.scythe then
		ItemConfig.ShopItems.scythe = {
			name = "🔪 Scythe",
			icon = "🔪",
			description = "A sharp scythe for harvesting wheat chunks - each swing harvests 5 wheat!",
			price = 0,
			currency = "coins",
			category = "farming",
			sellable = false,
			maxQuantity = 1,
			purchaseOrder = 5
		}
		print("✅ Added scythe to ItemConfig.ShopItems")
	end

	WheatIntegrationState.ItemConfigUpdated = true
	print("✅ ItemConfig updated for chunk-based wheat system")
	return true
end
-- ========== STEP 4: WAIT FOR GAMECORE ==========
local function WaitForGameCore()
	print("🌾 Waiting for GameCore...")
	local attempts = 0
	while not _G.GameCore and attempts < 30 do
		wait(1)
		attempts = attempts + 1
		print("Waiting for GameCore... (attempt " .. attempts .. ")")
	end

	if _G.GameCore then
		GameCore = _G.GameCore
		print("✅ GameCore found")
		return true
	else
		warn("❌ GameCore not found after 30 attempts")
		return false
	end
end
-- ========== STEP 5: INITIALIZE WHEAT SYSTEMS ==========
local function InitializeWheatSystems()
	print("🌾 Initializing chunk-based wheat systems...")
	if not GameCore then
		warn("❌ GameCore not available for wheat system initialization")
		return false
	end

	-- Initialize WheatHarvesting
	if WheatHarvesting then
		local success, error = pcall(function()
			return WheatHarvesting:Initialize(GameCore)
		end)

		if success then
			print("✅ Chunk-based WheatHarvesting initialized")
			_G.WheatHarvesting = WheatHarvesting
		else
			warn("❌ WheatHarvesting initialization failed: " .. tostring(error))
		end
	end

	-- Initialize ScytheGiver
	if ScytheGiver then
		local success, error = pcall(function()
			return ScytheGiver:Initialize(GameCore)
		end)

		if success then
			print("✅ ScytheGiver initialized")
			_G.ScytheGiver = ScytheGiver
		else
			warn("❌ ScytheGiver initialization failed: " .. tostring(error))
		end
	end

	return true
end
-- ========== STEP 6: SETUP WHEAT INVENTORY INTEGRATION ==========
local function SetupWheatInventoryIntegration()
	print("🌾 Setting up chunk-based wheat inventory integration...")
	if not GameCore then
		warn("❌ GameCore not available for inventory integration")
		return false
	end

	-- Extend GameCore's default player data to include wheat stats
	local originalGetDefaultPlayerData = GameCore.GetDefaultPlayerData
	GameCore.GetDefaultPlayerData = function(self)
		local defaultData = originalGetDefaultPlayerData(self)

		-- Add wheat-specific stats
		defaultData.stats = defaultData.stats or {}
		defaultData.stats.wheatHarvested = defaultData.stats.wheatHarvested or 0
		defaultData.stats.wheatChunksHarvested = defaultData.stats.wheatChunksHarvested or 0 -- NEW stat
		defaultData.stats.scythesReceived = defaultData.stats.scythesReceived or 0

		return defaultData
	end

	print("✅ Chunk-based wheat inventory integration setup")
	return true
end
-- ========== STEP 7: VALIDATE CHUNK-BASED WHEAT FIELD SETUP ==========
local function ValidateChunkBasedWheatFieldSetup()
	print("🌾 Validating chunk-based wheat field setup...")
	-- Check for WheatField model
	local wheatField = workspace:FindFirstChild("WheatField")
	if not wheatField then
		warn("⚠️ WheatField model not found in workspace")
		warn("   Please ensure WheatField model exists in workspace")
		return false
	end

	-- Check for wheat sections - UPDATED for 2 sections
	local sectionCount = 0
	for i = 1, 2 do
		local section = wheatField:FindFirstChild("Section" .. i)
		if section then
			local grainCluster = section:FindFirstChild("GrainCluster" .. i)
			if grainCluster then
				-- Count chunks in this section
				local chunkCount = 0
				for _, child in pairs(grainCluster:GetChildren()) do
					if child:IsA("Model") or child:IsA("BasePart") then
						chunkCount = chunkCount + 1
					end
				end

				if chunkCount > 0 then
					sectionCount = sectionCount + 1
					print("✅ Section" .. i .. " has " .. chunkCount .. " wheat chunks")
				else
					warn("⚠️ Section" .. i .. " has no wheat chunks")
				end
			else
				warn("⚠️ GrainCluster" .. i .. " not found in Section" .. i)
			end
		else
			warn("⚠️ Section" .. i .. " not found")
		end
	end

	if sectionCount < 2 then
		warn("⚠️ Found only " .. sectionCount .. " valid wheat sections, expected 2")
		warn("   Please ensure WheatField has 2 sections (Section1-2) with chunks")
	end

	-- Check for ScytheGiver model
	local scytheGiver = workspace:FindFirstChild("ScytheGiver")
	if not scytheGiver then
		warn("⚠️ ScytheGiver model not found in workspace")
		warn("   Please ensure ScytheGiver model exists in workspace")
		return false
	end

	print("✅ Chunk-based wheat field validation passed")
	print("  WheatField: " .. wheatField.Name .. " (" .. sectionCount .. " sections)")
	print("  ScytheGiver: " .. scytheGiver.Name)

	return true
end
-- ========== STEP 8: SETUP DEBUG COMMANDS ==========
local function SetupWheatDebugCommands()
	print("🌾 Setting up chunk-based wheat debug commands...")
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Change to your username
				local command = message:lower()

				if command == "/chunkwheatstatus" then
					print("=== CHUNK-BASED WHEAT SYSTEM STATUS ===")
					print("WheatHarvesting: " .. (WheatIntegrationState.WheatHarvestingLoaded and "✅" or "❌"))
					print("ScytheGiver: " .. (WheatIntegrationState.ScytheGiverLoaded and "✅" or "❌"))
					print("ItemConfig Updated: " .. (WheatIntegrationState.ItemConfigUpdated and "✅" or "❌"))
					print("Remote Events: " .. (WheatIntegrationState.RemoteEventsSetup and "✅" or "❌"))
					print("Integration Complete: " .. (WheatIntegrationState.IntegrationComplete and "✅" or "❌"))
					print("")
					print("CHUNK SYSTEM FEATURES:")
					print("  • 2 sections instead of 6")
					print("  • Each swing harvests 5 wheat")
					print("  • Chunks instead of individual grains")
					print("  • Better performance")
					print("")
					print("Global references:")
					print("  _G.WheatHarvesting: " .. (_G.WheatHarvesting and "✅" or "❌"))
					print("  _G.ScytheGiver: " .. (_G.ScytheGiver and "✅" or "❌"))
					print("==========================================")

				elseif command == "/givewheat5" then
					if GameCore and GameCore.AddItemToInventory then
						GameCore:AddItemToInventory(player, "farming", "wheat", 25) -- Give more since chunks give 5 each
						print("✅ Gave 25 wheat to " .. player.Name .. " (5 chunks worth)")
					end

				elseif command == "/chunkhelp" then
					print("🌾 CHUNK-BASED WHEAT SYSTEM COMMANDS:")
					print("  /chunkwheatstatus - Show chunk system status")
					print("  /wheatdebug - Show debug information")
					print("  /givewheat5 - Give 25 wheat (5 chunks worth)")
					print("  /givescythe - Give scythe to player")
					print("  /resetwheat - Reset all wheat sections")
					print("  /chunkhelp - Show this help")
					print("")
					print("🎯 CHUNK SYSTEM BENEFITS:")
					print("  • Faster harvesting (5 wheat per swing)")
					print("  • Better performance (fewer objects)")
					print("  • More satisfying effects")
					print("  • Only 2 sections to manage")
				end
			end
		end)
	end)

	print("✅ Chunk-based wheat debug commands setup")
end
-- ========== MAIN INTEGRATION FUNCTION ==========
local function IntegrateChunkBasedWheatSystem()
	print("🌾 Starting chunk-based wheat system integration...")
	local success, errorMessage = pcall(function()
		-- Step 1: Validate workspace setup
		ValidateChunkBasedWheatFieldSetup()

		-- Step 2: Setup remote events first
		SetupWheatRemoteEvents()

		-- Step 3: Update ItemConfig for chunks
		UpdateItemConfigForWheat()

		-- Step 4: Load wheat modules
		LoadWheatModules()

		-- Step 5: Wait for GameCore
		if not WaitForGameCore() then
			error("GameCore not available")
		end

		-- Step 6: Setup inventory integration
		SetupWheatInventoryIntegration()

		-- Step 7: Initialize wheat systems
		InitializeWheatSystems()

		-- Step 8: Setup debug commands
		SetupWheatDebugCommands()

		return true
	end)

	if success then
		WheatIntegrationState.IntegrationComplete = true
		print("🎉 Chunk-based wheat system integration completed successfully!")
		print("")
		print("🌾 CHUNK-BASED WHEAT SYSTEM INTEGRATION RESULTS:")
		print("  🌾 WheatHarvesting: " .. (WheatIntegrationState.WheatHarvestingLoaded and "✅" or "❌"))
		print("  🔪 ScytheGiver: " .. (WheatIntegrationState.ScytheGiverLoaded and "✅" or "❌"))
		print("  📦 ItemConfig: " .. (WheatIntegrationState.ItemConfigUpdated and "✅" or "❌"))
		print("  📡 Remote Events: " .. (WheatIntegrationState.RemoteEventsSetup and "✅" or "❌"))
		print("  🔗 Integration: " .. (WheatIntegrationState.IntegrationComplete and "✅" or "❌"))
		print("")
		print("🌾 CHUNK SYSTEM FEATURES:")
		print("  • 2 wheat sections (reduced from 6)")
		print("  • Each swing harvests 5 wheat (chunk-based)")
		print("  • Better performance with fewer objects")
		print("  • Larger, more satisfying harvest effects")
		print("  • Easier management and debugging")
		print("")
		print("🎮 Debug Commands:")
		print("  /chunkwheatstatus - Show chunk system status")
		print("  /chunkhelp - Show all chunk commands")
		return true
	else
		warn("💥 Chunk-based wheat system integration failed: " .. tostring(errorMessage))
		return false
	end
end
-- ========== EXECUTE INTEGRATION ==========
spawn(function()
	wait(5) -- Wait for other systems to initialize
	print("🌾 Starting chunk-based wheat system integration in 5 seconds...")

	local success = IntegrateChunkBasedWheatSystem()

	if success then
		print("✅ Chunk-based wheat system integration complete and ready!")
	else
		warn("❌ Chunk-based wheat system integration incomplete - check debug commands")
	end
end)
-- ========== CLEANUP ON SHUTDOWN ==========
game:BindToClose(function()
	print("🌾 Chunk-based wheat system shutting down...")
	if _G.WheatHarvesting and _G.WheatHarvesting.Cleanup then
		_G.WheatHarvesting:Cleanup()
	end

	if _G.ScytheGiver and _G.ScytheGiver.Cleanup then
		_G.ScytheGiver:Cleanup()
	end

	print("✅ Chunk-based wheat system shutdown complete")
end)
print("🌾 Chunk-based Wheat System Integration loaded - integration will begin in 5 seconds...")