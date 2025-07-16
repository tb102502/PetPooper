--[[
    WheatSystemIntegration.server.lua - Wheat Harvesting System Integration
    Place in: ServerScriptService/WheatSystemIntegration.server.lua
    
    FEATURES:
    ✅ Integrates WheatHarvesting with existing GameCore
    ✅ Integrates ScytheGiver with existing systems
    ✅ Adds wheat to inventory and shop systems
    ✅ Coordinates with existing framework
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("🌾 === Wheat System Integration Starting ===")

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
	print("🌾 Loading wheat harvesting modules...")

	-- Load WheatHarvesting module
	local wheatHarvestingModule = ServerScriptService:FindFirstChild("WheatHarvesting")
	if wheatHarvestingModule then
		local success, result = pcall(function()
			return require(wheatHarvestingModule)
		end)

		if success then
			WheatHarvesting = result
			WheatIntegrationState.WheatHarvestingLoaded = true
			print("✅ WheatHarvesting module loaded")
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
	print("🌾 Setting up wheat remote events...")

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
	print("✅ Wheat remote events setup: " .. eventsCreated .. " events created")
	return true
end

-- ========== STEP 3: UPDATE ITEM CONFIG ==========

local function UpdateItemConfigForWheat()
	print("🌾 Updating ItemConfig for wheat...")

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
			description = "Golden wheat harvested from the wheat field",
			sellValue = 15,
			category = "crop",
			rarity = "common",
			harvestTime = 0 -- Instant harvest from field
		}
		print("✅ Added wheat to ItemConfig.Crops")
	end

	-- Add wheat to shop items if not already present
	if not ItemConfig.ShopItems then
		ItemConfig.ShopItems = {}
	end

	if not ItemConfig.ShopItems.wheat then
		ItemConfig.ShopItems.wheat = {
			name = "🌾 Wheat",
			icon = "🌾",
			description = "Golden wheat - great for selling or crafting",
			price = 15,
			currency = "coins",
			category = "farming",
			sellable = true,
			sellPrice = 15,
			maxQuantity = 999,
			purchaseOrder = 15
		}
		print("✅ Added wheat to ItemConfig.ShopItems")
	end

	-- Add scythe to upgrades if not already present
	if not ItemConfig.ShopItems.scythe then
		ItemConfig.ShopItems.scythe = {
			name = "🔪 Scythe",
			icon = "🔪",
			description = "A sharp scythe for harvesting wheat",
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
	print("✅ ItemConfig updated for wheat system")
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
	print("🌾 Initializing wheat systems...")

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
			print("✅ WheatHarvesting initialized")
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
	print("🌾 Setting up wheat inventory integration...")

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
		defaultData.stats.scythesReceived = defaultData.stats.scythesReceived or 0

		return defaultData
	end

	print("✅ Wheat inventory integration setup")
	return true
end

-- ========== STEP 7: SETUP DEBUG COMMANDS ==========

local function SetupWheatDebugCommands()
	print("🌾 Setting up wheat debug commands...")

	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Change to your username
				local command = message:lower()

				if command == "/wheatstatus" then
					print("=== WHEAT SYSTEM STATUS ===")
					print("WheatHarvesting: " .. (WheatIntegrationState.WheatHarvestingLoaded and "✅" or "❌"))
					print("ScytheGiver: " .. (WheatIntegrationState.ScytheGiverLoaded and "✅" or "❌"))
					print("ItemConfig Updated: " .. (WheatIntegrationState.ItemConfigUpdated and "✅" or "❌"))
					print("Remote Events: " .. (WheatIntegrationState.RemoteEventsSetup and "✅" or "❌"))
					print("Integration Complete: " .. (WheatIntegrationState.IntegrationComplete and "✅" or "❌"))
					print("")
					print("Global references:")
					print("  _G.WheatHarvesting: " .. (_G.WheatHarvesting and "✅" or "❌"))
					print("  _G.ScytheGiver: " .. (_G.ScytheGiver and "✅" or "❌"))
					print("============================")

				elseif command == "/wheatdebug" then
					if _G.WheatHarvesting and _G.WheatHarvesting.DebugStatus then
						_G.WheatHarvesting:DebugStatus()
					end
					if _G.ScytheGiver and _G.ScytheGiver.DebugStatus then
						_G.ScytheGiver:DebugStatus()
					end

				elseif command == "/givewheat" then
					if GameCore and GameCore.AddItemToInventory then
						GameCore:AddItemToInventory(player, "farming", "wheat", 10)
						print("✅ Gave 10 wheat to " .. player.Name)
					end

				elseif command == "/givescythe" then
					if _G.ScytheGiver and _G.ScytheGiver.GiveScytheToPlayer then
						_G.ScytheGiver:GiveScytheToPlayer(player)
						print("✅ Gave scythe to " .. player.Name)
					end

				elseif command == "/resetwheat" then
					if _G.WheatHarvesting and _G.WheatHarvesting.SectionData then
						-- Reset all sections
						for i, sectionData in pairs(_G.WheatHarvesting.SectionData) do
							sectionData.isHarvested = false
							sectionData.harvestedTime = 0
							sectionData.respawnTime = 0
							_G.WheatHarvesting:ShowWheatSection(i)
						end
						print("✅ Reset all wheat sections")
					end

				elseif command == "/wheathelp" then
					print("🌾 WHEAT SYSTEM COMMANDS:")
					print("  /wheatstatus - Show system status")
					print("  /wheatdebug - Show debug information")
					print("  /givewheat - Give 10 wheat to player")
					print("  /givescythe - Give scythe to player")
					print("  /resetwheat - Reset all wheat sections")
					print("  /wheathelp - Show this help")
				end
			end
		end)
	end)

	print("✅ Wheat debug commands setup")
end

-- ========== STEP 8: VALIDATE WHEAT FIELD SETUP ==========

local function ValidateWheatFieldSetup()
	print("🌾 Validating wheat field setup...")

	-- Check for WheatField model
	local wheatField = workspace:FindFirstChild("WheatField")
	if not wheatField then
		warn("⚠️ WheatField model not found in workspace")
		warn("   Please ensure WheatField model exists in workspace")
		return false
	end

	-- Check for wheat sections
	local sectionCount = 0
	for i = 1, 6 do
		local section = wheatField:FindFirstChild("Cluster" .. i)
		if section then
			sectionCount = sectionCount + 1
		end
	end

	if sectionCount == 0 then
		-- Check for any child models/parts
		for _, child in pairs(wheatField:GetChildren()) do
			if child:IsA("Model") or child:IsA("BasePart") then
				sectionCount = sectionCount + 1
			end
		end
	end

	if sectionCount < 6 then
		warn("⚠️ Found only " .. sectionCount .. " wheat sections, expected 6")
		warn("   Please ensure WheatField has 6 sections (Cluster1-Cluster6)")
	end

	-- Check for ScytheGiver model
	local scytheGiver = workspace:FindFirstChild("ScytheGiver")
	if not scytheGiver then
		warn("⚠️ ScytheGiver model not found in workspace")
		warn("   Please ensure ScytheGiver model exists in workspace")
		return false
	end

	print("✅ Wheat field validation passed")
	print("  WheatField: " .. wheatField.Name .. " (" .. sectionCount .. " sections)")
	print("  ScytheGiver: " .. scytheGiver.Name)

	return true
end

-- ========== MAIN INTEGRATION FUNCTION ==========

local function IntegrateWheatSystem()
	print("🌾 Starting wheat system integration...")

	local success, errorMessage = pcall(function()
		-- Step 1: Validate workspace setup
		ValidateWheatFieldSetup()

		-- Step 2: Setup remote events first
		SetupWheatRemoteEvents()

		-- Step 3: Update ItemConfig
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
		print("🎉 Wheat system integration completed successfully!")
		print("")
		print("🌾 WHEAT SYSTEM INTEGRATION RESULTS:")
		print("  🌾 WheatHarvesting: " .. (WheatIntegrationState.WheatHarvestingLoaded and "✅" or "❌"))
		print("  🔪 ScytheGiver: " .. (WheatIntegrationState.ScytheGiverLoaded and "✅" or "❌"))
		print("  📦 ItemConfig: " .. (WheatIntegrationState.ItemConfigUpdated and "✅" or "❌"))
		print("  📡 Remote Events: " .. (WheatIntegrationState.RemoteEventsSetup and "✅" or "❌"))
		print("  🔗 Integration: " .. (WheatIntegrationState.IntegrationComplete and "✅" or "❌"))
		print("")
		print("🌾 Wheat System Features:")
		print("  • Get scythe from ScytheGiver model")
		print("  • Approach wheat field to see proximity prompt")
		print("  • Click to swing scythe and harvest wheat")
		print("  • 10 swings = 1 wheat per section")
		print("  • 6 sections = 6 wheat total")
		print("  • Wheat automatically respawns after 5 minutes")
		print("")
		print("🎮 Debug Commands:")
		print("  /wheatstatus - Show system status")
		print("  /wheatdebug - Show debug information")
		print("  /wheathelp - Show all commands")
		return true
	else
		warn("💥 Wheat system integration failed: " .. tostring(errorMessage))
		return false
	end
end

-- ========== EXECUTE INTEGRATION ==========

spawn(function()
	wait(5) -- Wait for other systems to initialize

	print("🌾 Starting wheat system integration in 5 seconds...")

	local success = IntegrateWheatSystem()

	if success then
		print("✅ Wheat system integration complete and ready!")
	else
		warn("❌ Wheat system integration incomplete - check debug commands")
	end
end)

-- ========== CLEANUP ON SHUTDOWN ==========

game:BindToClose(function()
	print("🌾 Wheat system shutting down...")

	if _G.WheatHarvesting and _G.WheatHarvesting.Cleanup then
		_G.WheatHarvesting:Cleanup()
	end

	if _G.ScytheGiver and _G.ScytheGiver.Cleanup then
		_G.ScytheGiver:Cleanup()
	end

	print("✅ Wheat system shutdown complete")
end)

print("🌾 Wheat System Integration loaded - integration will begin in 5 seconds...")