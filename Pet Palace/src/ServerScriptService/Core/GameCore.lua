--[[
    UPDATED GameCore.lua - With FarmPlot Module Integration
    Place in: ServerScriptService/Core/GameCore.lua
    
    UPDATES:
    ✅ Added FarmPlot module loading from Modules folder
    ✅ Added farm plot integration methods
    ✅ Fixed module loading paths for all modules
]]

local GameCore = {}

-- Services
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- Load configuration
local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))

-- UPDATED: Module references - will be loaded from correct locations
local CropCreation = nil
local CropVisual = nil  
local FarmPlot = nil -- Added FarmPlot
local MutationSystem = nil
local CowCreationModule = nil
local CowMilkingModule = nil

-- Core state
GameCore.PlayerData = {}
GameCore.RemoteEvents = {}
GameCore.RemoteFunctions = {}
GameCore.SAVE_COOLDOWN = 30

-- ========== UPDATED MODULE LOADING ==========

function GameCore:LoadModules()
	print("GameCore: Loading modules from correct paths...")

	local modulesLoaded = 0

	-- Load cow modules from root ServerScriptService
	local cowCreationSuccess, cowCreationResult = pcall(function()
		local moduleScript = ServerScriptService:WaitForChild("CowCreationModule", 10)
		if not moduleScript then
			warn("CowCreationModule not found in ServerScriptService")
			return nil
		end
		return require(moduleScript)
	end)

	if cowCreationSuccess and cowCreationResult then
		CowCreationModule = cowCreationResult
		print("GameCore: ✅ CowCreationModule loaded from ServerScriptService")
		modulesLoaded = modulesLoaded + 1
	else
		warn("GameCore: ❌ Failed to load CowCreationModule: " .. tostring(cowCreationResult))
	end

	local cowMilkingSuccess, cowMilkingResult = pcall(function()
		local moduleScript = ServerScriptService:WaitForChild("CowMilkingModule", 10)
		if not moduleScript then
			warn("CowMilkingModule not found in ServerScriptService")
			return nil
		end
		return require(moduleScript)
	end)

	if cowMilkingSuccess and cowMilkingResult then
		CowMilkingModule = cowMilkingResult
		print("GameCore: ✅ CowMilkingModule loaded from ServerScriptService")
		modulesLoaded = modulesLoaded + 1
	else
		warn("GameCore: ❌ Failed to load CowMilkingModule: " .. tostring(cowMilkingResult))
	end

	-- ADDED: Load modules from Modules folder if it exists
	local modulesFolder = ServerScriptService:FindFirstChild("Modules")
	if modulesFolder then
		print("GameCore: Found Modules folder, loading farming modules...")

		-- Load FarmPlot module
		local farmPlotModule = modulesFolder:FindFirstChild("FarmPlot")
		if farmPlotModule then
			local success, result = pcall(function()
				return require(farmPlotModule)
			end)
			if success then
				FarmPlot = result
				print("GameCore: ✅ FarmPlot loaded from Modules folder")
				modulesLoaded = modulesLoaded + 1
			else
				warn("GameCore: ❌ Failed to load FarmPlot: " .. tostring(result))
			end
		else
			print("GameCore: FarmPlot module not found in Modules folder")
		end

		-- Load CropCreation if available
		local cropCreationModule = modulesFolder:FindFirstChild("CropCreation")
		if cropCreationModule then
			local success, result = pcall(function()
				return require(cropCreationModule)
			end)
			if success then
				CropCreation = result
				print("GameCore: ✅ CropCreation loaded from Modules folder")
				modulesLoaded = modulesLoaded + 1
			end
		end

		-- Load CropVisual if available
		local cropVisualModule = modulesFolder:FindFirstChild("CropVisual")
		if cropVisualModule then
			local success, result = pcall(function()
				return require(cropVisualModule)
			end)
			if success then
				CropVisual = result
				print("GameCore: ✅ CropVisual loaded from Modules folder")
				modulesLoaded = modulesLoaded + 1
			end
		end
	else
		print("GameCore: No Modules folder found, using available modules only")
	end

	print("GameCore: Module loading complete - " .. modulesLoaded .. " modules loaded")
	return modulesLoaded >= 1 -- At least one module required
end

-- REPLACE the InitializeLoadedModules method in your GameCore.lua with this enhanced version:

function GameCore:InitializeLoadedModules()
	print("GameCore: Initializing loaded modules with proper dependencies...")

	-- Initialize FarmPlot first (needed by other modules)
	if FarmPlot then
		print("GameCore: Initializing FarmPlot...")
		local success, error = pcall(function()
			return FarmPlot:Initialize(self)
		end)

		if success then
			print("GameCore: ✅ FarmPlot initialized")
			_G.FarmPlot = FarmPlot
			print("GameCore: ✅ FarmPlot set globally")
		else
			warn("GameCore: ❌ FarmPlot initialization failed: " .. tostring(error))
		end
	end

	-- Initialize CropVisual second (needed by CropCreation)
	if CropVisual then
		print("GameCore: Initializing CropVisual...")
		local success, error = pcall(function()
			return CropVisual:Initialize(self, nil) -- CropCreation will be passed later
		end)

		if success then
			print("GameCore: ✅ CropVisual initialized")
			_G.CropVisual = CropVisual
		else
			warn("GameCore: ❌ CropVisual initialization failed: " .. tostring(error))
		end
	end

	-- Initialize CropCreation third (depends on CropVisual)
	if CropCreation then
		print("GameCore: Initializing CropCreation...")
		local success, error = pcall(function()
			return CropCreation:Initialize(self, CropVisual, MutationSystem)
		end)

		if success then
			print("GameCore: ✅ CropCreation initialized")
			_G.CropCreation = CropCreation
		else
			warn("GameCore: ❌ CropCreation initialization failed: " .. tostring(error))
		end
	end

	-- Update CropVisual with CropCreation reference
	if CropVisual and CropCreation then
		print("GameCore: Updating CropVisual with CropCreation reference...")
		local success, error = pcall(function()
			-- Re-initialize CropVisual with CropCreation reference
			return CropVisual:Initialize(self, CropCreation)
		end)

		if success then
			print("GameCore: ✅ CropVisual updated with CropCreation reference")
		else
			warn("GameCore: ❌ CropVisual update failed: " .. tostring(error))
		end
	end

	-- Initialize CowCreationModule
	if CowCreationModule then
		print("GameCore: Initializing CowCreationModule...")
		local success, error = pcall(function()
			return CowCreationModule:Initialize(self, ItemConfig)
		end)

		if success then
			print("GameCore: ✅ CowCreationModule initialized")
			_G.CowCreationModule = CowCreationModule
		else
			warn("GameCore: ❌ CowCreationModule initialization failed: " .. tostring(error))
		end
	end

	-- Initialize CowMilkingModule
	if CowMilkingModule then
		print("GameCore: Initializing CowMilkingModule...")
		local success, error = pcall(function()
			return CowMilkingModule:Initialize(self, CowCreationModule)
		end)

		if success then
			print("GameCore: ✅ CowMilkingModule initialized")
			_G.CowMilkingModule = CowMilkingModule
		else
			warn("GameCore: ❌ CowMilkingModule initialization failed: " .. tostring(error))
		end
	end

	-- Initialize MutationSystem if available
	if MutationSystem and CropCreation and CropVisual then
		print("GameCore: Initializing MutationSystem...")
		local success, error = pcall(function()
			return MutationSystem:Initialize(self, CropCreation, CropVisual)
		end)

		if success then
			print("GameCore: ✅ MutationSystem initialized")
		else
			warn("GameCore: ❌ MutationSystem initialization failed: " .. tostring(error))
		end
	end

	-- Validate all module references are available globally
	print("GameCore: Validating global module references...")
	local moduleStatus = {
		FarmPlot = _G.FarmPlot ~= nil,
		CropCreation = _G.CropCreation ~= nil,
		CropVisual = _G.CropVisual ~= nil,
		CowCreationModule = _G.CowCreationModule ~= nil,
		CowMilkingModule = _G.CowMilkingModule ~= nil,
		GameCore = _G.GameCore ~= nil
	}

	for moduleName, isAvailable in pairs(moduleStatus) do
		print("  " .. moduleName .. ": " .. (isAvailable and "✅" or "❌"))
	end

	print("GameCore: Module initialization complete!")
end

-- ADD this method to verify module connections:
function GameCore:VerifyModuleConnections()
	print("=== MODULE CONNECTION VERIFICATION ===")

	-- Test CropCreation -> CropVisual connection
	if _G.CropCreation and _G.CropVisual then
		print("✅ CropCreation <-> CropVisual: Connected")
	else
		warn("❌ CropCreation <-> CropVisual: Missing connection")
	end

	-- Test FarmPlot -> GameCore connection
	if _G.FarmPlot and _G.GameCore then
		print("✅ FarmPlot <-> GameCore: Connected")
	else
		warn("❌ FarmPlot <-> GameCore: Missing connection")
	end

	-- Test growth timer system
	if _G.CropCreation then
		local cropCreation = _G.CropCreation
		if cropCreation.GrowthTimers then
			print("✅ Growth Timer System: Initialized")
			print("  Active timers: " .. (cropCreation:CountTable(cropCreation.GrowthTimers) or 0))
		else
			warn("❌ Growth Timer System: Not initialized")
		end
	end

	print("=====================================")
end

-- ADD this helper method:
function GameCore:CountTable(t)
	if not t then return 0 end
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end
-- ========== ADDED: FARM PLOT INTEGRATION METHODS ==========

function GameCore:CreateSimpleFarmPlot(player)
	if FarmPlot then
		return FarmPlot:CreateSimpleFarmPlot(player)
	else
		warn("GameCore: FarmPlot module not available")
		return false
	end
end

function GameCore:CreateExpandableFarmPlot(player, level)
	if FarmPlot then
		return FarmPlot:CreateExpandableFarmPlot(player, level)
	else
		warn("GameCore: FarmPlot module not available")
		return false
	end
end

function GameCore:GetPlayerSimpleFarm(player)
	if FarmPlot then
		local farm, farmType = FarmPlot:GetPlayerFarm(player)
		return farm
	else
		warn("GameCore: FarmPlot module not available")
		return nil
	end
end

function GameCore:GetPlayerExpandableFarm(player)
	if FarmPlot then
		local farm, farmType = FarmPlot:GetPlayerFarm(player)
		if farmType == "expandable" then
			return farm
		end
	end
	return nil
end

function GameCore:FindPlotByName(player, plotName)
	if FarmPlot then
		return FarmPlot:FindPlotByName(player, plotName)
	else
		warn("GameCore: FarmPlot module not available")
		return nil
	end
end

function GameCore:GetPlotOwner(plotModel)
	if FarmPlot then
		return FarmPlot:GetPlotOwner(plotModel)
	else
		warn("GameCore: FarmPlot module not available")
		return nil
	end
end

function GameCore:EnsurePlayerHasFarm(player)
	if FarmPlot then
		return FarmPlot:EnsurePlayerHasFarm(player)
	else
		warn("GameCore: FarmPlot module not available")
		return false
	end
end

function GameCore:GetSimpleFarmPosition(player)
	if FarmPlot then
		return FarmPlot:GetSimpleFarmPosition(player)
	else
		warn("GameCore: FarmPlot module not available - using fallback position")
		-- Fallback position calculation
		local playerIndex = 0
		local sortedPlayers = {}
		for _, p in pairs(Players:GetPlayers()) do
			table.insert(sortedPlayers, p)
		end
		table.sort(sortedPlayers, function(a, b) return a.UserId < b.UserId end)

		for i, p in ipairs(sortedPlayers) do
			if p.UserId == player.UserId then
				playerIndex = i - 1
				break
			end
		end

		local basePos = Vector3.new(-366.118, -2.793, 75.731)
		local playerOffset = Vector3.new(150, 0, 0) * playerIndex
		local finalPosition = basePos + playerOffset

		return CFrame.new(finalPosition)
	end
end
-- ADD this method to your existing GameCore.lua (around line 300, after ProcessFarmPlotPurchase)

function GameCore:ProcessWheatFieldPurchase(player, playerData, item, quantity)
	print("🌾 GameCore: Processing wheat field access purchase for " .. player.Name)

	-- Initialize farming data if needed
	if not playerData.farming then
		playerData.farming = {
			plots = 0,
			inventory = {}
		}
	end

	-- Add wheat field access flags
	playerData.farming.wheatFieldAccess = true
	playerData.farming.wheatFieldUnlocked = os.time()

	-- Give bonus wheat seeds
	playerData.farming.inventory = playerData.farming.inventory or {}
	playerData.farming.inventory.wheat_seeds = (playerData.farming.inventory.wheat_seeds or 0) + 10

	-- Create wheat field region if FarmPlot module is available
	local success = false
	if _G.FarmPlot and _G.FarmPlot.CreateWheatField then
		success = _G.FarmPlot:CreateWheatField(player)
	else
		-- Fallback: just mark as having access
		success = true
		print("🌾 GameCore: Wheat field access granted (no physical wheat field module)")
	end

	if success then
		print("🌾 GameCore: Wheat field access successfully granted to " .. player.Name)

		-- Send notification through GameCore's notification system
		self:SendNotification(player, "🌾 Wheat Field Unlocked!", 
			"Advanced farming is now available!\n\n🎁 Bonus: 10 FREE Wheat Seeds!\n\n• Plant wheat for higher profits\n• Buy the scythe tool for efficient harvesting\n• Scale up your farming operation!", "success")

		return true
	else
		print("❌ GameCore: Wheat field creation failed for " .. player.Name)
		return false
	end
end

-- UPDATE the ProcessFarmPlotPurchase method to handle the new progression
-- REPLACE your existing ProcessFarmPlotPurchase with this enhanced version:

function GameCore:ProcessFarmPlotPurchase(player, playerData, item, quantity)
	print("🌾 GameCore: Processing farm plot purchase for " .. player.Name)

	-- Handle different farm plot types
	if item.id == "farm_plot_starter" then
		print("🌱 Processing garden plot starter (100 coins)")

		-- Initialize farming data
		if not playerData.farming then
			playerData.farming = {
				plots = 1,
				inventory = {
					carrot_seeds = 5,
					potato_seeds = 3
				}
			}
		else
			playerData.farming.plots = (playerData.farming.plots or 0) + quantity
		end

		-- Create garden region using FarmPlot module
		local success = false
		if _G.FarmPlot then
			success = _G.FarmPlot:CreateSimpleFarmPlot(player)
		end

		if not success then
			-- Revert farming data if garden creation failed
			if playerData.farming.plots then
				playerData.farming.plots = playerData.farming.plots - quantity
			end
			return false
		end

		print("🌱 Created garden region for " .. player.Name)
		return true

	elseif item.id == "wheat_field_access" then
		print("🌾 Processing wheat field access (10,000 coins)")
		return self:ProcessWheatFieldPurchase(player, playerData, item, quantity)

		-- Handle farm expansions
	elseif item.id:find("farm_expansion") then
		local expansionLevel = tonumber(item.id:match("farm_expansion_(%d+)"))
		if expansionLevel and FarmPlot then
			print("🌾 Processing farm expansion to level " .. expansionLevel)

			playerData.farming = playerData.farming or {plots = 0, inventory = {}}
			playerData.farming.expansionLevel = expansionLevel

			local success = FarmPlot:ExpandFarm(player, expansionLevel)
			if not success then
				return false
			end

			print("🌾 Expanded farm to level " .. expansionLevel .. " for " .. player.Name)
			return true
		end
	end

	-- Regular farm plot purchase (fallback)
	if not playerData.farming then
		playerData.farming = {plots = 0, inventory = {}}
	end

	playerData.farming.plots = (playerData.farming.plots or 0) + quantity

	local success = self:CreateSimpleFarmPlot(player)
	if not success then
		playerData.farming.plots = playerData.farming.plots - quantity
		return false
	end

	print("🌾 Added " .. quantity .. " farm plot(s), total: " .. playerData.farming.plots)
	return true
end

-- ADD this method to handle cave access processing:

function GameCore:ProcessCaveAccessPurchase(player, playerData, item, quantity)
	print("🕳️ GameCore: Processing cave access purchase for " .. player.Name)

	-- Initialize mining data
	if not playerData.mining then
		playerData.mining = {
			inventory = {},
			tools = {},
			level = 1,
			experience = 0
		}
	end

	-- Add cave access flags
	playerData.mining.caveAccess = true
	playerData.mining.caveAccessUnlocked = os.time()

	-- Give starter wooden pickaxe
	playerData.mining.tools.wooden_pickaxe = {
		durability = 50,
		maxDurability = 50,
		acquiredTime = os.time()
	}

	-- Create cave access if mining module is available
	local success = true -- Default to success since cave access is mainly data-driven

	print("🕳️ GameCore: Cave access successfully granted to " .. player.Name)

	-- Send notification
	self:SendNotification(player, "🕳️ Cave Access Granted!", 
		"Mining operations are now available!\n\n🎁 Bonus: FREE Wooden Pickaxe!\n\n• Mine copper and bronze ore in Cave 1\n• Upgrade to better pickaxes for rare ores\n• Diversify your income with mining!", "success")

	return true
end

-- UPDATE the GetDefaultPlayerData to include progression flags:

function GameCore:GetDefaultPlayerData()
	return {
		coins = 100,
		farmTokens = 0,
		trimmings = 0,
		milk = 0,
		upgrades = {},
		purchaseHistory = {},
		farming = {
			plots = 0,
			inventory = {},
			level = 1,
			-- NEW: Progression flags
			wheatFieldAccess = false,
			wheatFieldUnlocked = nil
		},
		mining = {
			inventory = {},
			tools = {},
			level = 1,
			experience = 0,
			-- NEW: Progression flags
			caveAccess = false,
			caveAccessUnlocked = nil
		},
		crafting = {
			inventory = {},
			recipes = {},
			stations = {},
			level = 1
		},
		livestock = {
			cows = {}
		},
		stats = {
			coinsEarned = 100,
			cropsHarvested = 0,
			milkCollected = 0,
			itemsSold = 0,
			oresMined = 0,
			itemsCrafted = 0,
			trimmingsEarned = 0
		},
		firstJoin = os.time(),
		lastSave = os.time()
	}
end

-- ADD helper methods to check player progression:

function GameCore:HasPlayerUnlockedWheatField(player)
	local playerData = self:GetPlayerData(player)
	if not playerData or not playerData.farming then return false end

	return playerData.farming.wheatFieldAccess == true or 
		(playerData.purchaseHistory and playerData.purchaseHistory.wheat_field_access == true)
end

function GameCore:HasPlayerUnlockedCaveAccess(player)
	local playerData = self:GetPlayerData(player)
	if not playerData or not playerData.mining then return false end

	return playerData.mining.caveAccess == true or 
		(playerData.purchaseHistory and playerData.purchaseHistory.cave_access_pass == true)
end

function GameCore:GetPlayerProgressionLevel(player)
	local playerData = self:GetPlayerData(player)
	if not playerData then return 0 end

	local hasGarden = playerData.purchaseHistory and playerData.purchaseHistory.farm_plot_starter
	local hasWheatField = self:HasPlayerUnlockedWheatField(player)
	local hasCaveAccess = self:HasPlayerUnlockedCaveAccess(player)

	if hasCaveAccess then return 3 -- Mining unlocked
	elseif hasWheatField then return 2 -- Wheat farming unlocked
	elseif hasGarden then return 1 -- Basic farming unlocked
	else return 0 -- Just starting (only cow milking)
	end
end

-- ADD debugging functions for the new progression system:

function GameCore:DebugPlayerProgression(player)
	print("=== PLAYER PROGRESSION DEBUG ===")
	print("Player: " .. player.Name)

	local playerData = self:GetPlayerData(player)
	if not playerData then 
		print("❌ No player data found")
		return 
	end

	print("💰 Coins: " .. (playerData.coins or 0))
	print("🎫 Farm Tokens: " .. (playerData.farmTokens or 0))
	print("🥛 Milk: " .. (playerData.milk or 0))

	print("\n📊 PROGRESSION STATUS:")
	local progressionLevel = self:GetPlayerProgressionLevel(player)
	print("Current Level: " .. progressionLevel)

	-- Check each progression step
	local hasGarden = playerData.purchaseHistory and playerData.purchaseHistory.farm_plot_starter
	print("1️⃣ Garden (100 coins): " .. (hasGarden and "✅ UNLOCKED" or "🔒 LOCKED"))

	local hasWheatField = self:HasPlayerUnlockedWheatField(player)
	print("2️⃣ Wheat Field (10,000 coins): " .. (hasWheatField and "✅ UNLOCKED" or "🔒 LOCKED"))

	local hasCaveAccess = self:HasPlayerUnlockedCaveAccess(player)
	print("3️⃣ Cave Access (250,000 coins): " .. (hasCaveAccess and "✅ UNLOCKED" or "🔒 LOCKED"))

	-- Show purchase history
	print("\n🛒 PURCHASE HISTORY:")
	if playerData.purchaseHistory then
		for itemId, purchased in pairs(playerData.purchaseHistory) do
			if purchased then
				print("  ✅ " .. itemId)
			end
		end
	else
		print("  No purchases yet")
	end

	-- Show next goal
	print("\n🎯 NEXT GOAL:")
	if progressionLevel == 0 then
		print("  Buy Garden (100 coins) - Need " .. math.max(0, 100 - (playerData.coins or 0)) .. " more coins")
	elseif progressionLevel == 1 then
		print("  Buy Wheat Field Access (10,000 coins) - Need " .. math.max(0, 10000 - (playerData.coins or 0)) .. " more coins")
	elseif progressionLevel == 2 then
		print("  Buy Cave Access (250,000 coins) - Need " .. math.max(0, 250000 - (playerData.coins or 0)) .. " more coins")
	else
		print("  All major progression unlocked! Focus on upgrades and premium items.")
	end

	print("===============================")
end

-- Global debug function
_G.DebugProgression = function(playerName)
	local player = game.Players:FindFirstChild(playerName)
	if not player then
		print("Player not found: " .. playerName)
		return
	end

	if GameCore and GameCore.DebugPlayerProgression then
		GameCore:DebugPlayerProgression(player)
	else
		print("GameCore not available")
	end
end

print("✅ GAMECORE PROGRESSION SYSTEM UPDATED!")
print("🎯 NEW FEATURES:")
print("  ✅ Wheat field access processing")
print("  ✅ Cave access processing with starter tool")
print("  ✅ Progression level tracking")
print("  ✅ Enhanced default player data structure")
print("  ✅ Helper methods for checking unlock status")
print("  ✅ Debug functions for testing progression")
print("")
print("🧪 DEBUG COMMANDS:")
print("  _G.DebugProgression('PlayerName') - Check player's progression status")
-- ========== CROP SYSTEM INTEGRATION ==========

function GameCore:PlantSeed(player, plotModel, seedId, seedData)
	if CropCreation then
		return CropCreation:PlantSeed(player, plotModel, seedId, seedData)
	else
		warn("GameCore: CropCreation module not available")
		return false
	end
end

function GameCore:HarvestCrop(player, plotModel)
	if CropCreation then
		return CropCreation:HarvestCrop(player, plotModel)
	else
		warn("GameCore: CropCreation module not available")
		return false
	end
end

function GameCore:HarvestAllCrops(player)
	if CropCreation then
		return CropCreation:HarvestAllCrops(player)
	else
		warn("GameCore: CropCreation module not available")
		return false
	end
end

function GameCore:IsPlotActuallyEmpty(plotModel)
	if CropCreation then
		return CropCreation:IsPlotEmpty(plotModel)
	else
		-- Fallback implementation
		for _, child in pairs(plotModel:GetChildren()) do
			if child:IsA("Model") and child.Name == "CropModel" then
				return false
			end
		end
		return plotModel:GetAttribute("IsEmpty") ~= false
	end
end

function GameCore:ClearPlotProperly(plotModel)
	if CropCreation then
		return CropCreation:ClearPlot(plotModel)
	else
		-- Fallback implementation
		for _, child in pairs(plotModel:GetChildren()) do
			if child:IsA("Model") and child.Name == "CropModel" then
				child:Destroy()
			end
		end

		plotModel:SetAttribute("IsEmpty", true)
		plotModel:SetAttribute("PlantType", "")
		plotModel:SetAttribute("SeedType", "")
		plotModel:SetAttribute("GrowthStage", 0)
		plotModel:SetAttribute("PlantedTime", 0)
		plotModel:SetAttribute("Rarity", "common")

		return true
	end
end

-- ========== EXISTING METHODS (keeping the rest of the previous code) ==========

function GameCore:Initialize(shopSystem)
	print("GameCore: Starting UPDATED core initialization...")

	-- Initialize data store first
	self:InitializeDataStore()

	-- Load modules with correct paths
	local modulesSuccess = self:LoadModules()
	if not modulesSuccess then
		warn("GameCore: No modules loaded, but continuing with basic functionality")
	end

	-- Store ShopSystem reference if provided
	if shopSystem then
		self.ShopSystem = shopSystem
		print("GameCore: ShopSystem reference established")
	end

	-- Setup remote connections
	self:SetupRemoteConnections()

	-- Initialize modules in correct order
	self:InitializeLoadedModules()

	-- Setup event handlers
	self:SetupEventHandlers()

	-- Setup player handlers
	self:SetupPlayerHandlers()

	print("GameCore: ✅ UPDATED core initialization complete!")
	return true
end

function GameCore:InitializeDataStore()
	local success, dataStore = pcall(function()
		return DataStoreService:GetDataStore("LivestockFarmData_v2")
	end)

	if success then
		self.PlayerDataStore = dataStore
		print("GameCore: DataStore connected (Live)")
	else
		-- Create mock DataStore for Studio testing
		self.PlayerDataStore = {
			GetAsync = function(self, key)
				warn("GameCore: Using mock DataStore for Studio - GetAsync(" .. key .. ")")
				return nil
			end,
			SetAsync = function(self, key, data)
				print("GameCore: Mock DataStore save for " .. key .. " (Studio mode)")
				return true
			end
		}
		warn("GameCore: Using mock DataStore for Studio testing")
	end
end

-- ========== REMOTE EVENT SETUP ==========

-- REPLACE the SetupRemoteConnections method in your GameCore.lua with this fixed version:

function GameCore:SetupRemoteConnections()
	print("GameCore: Setting up remote connections...")

	local remotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "GameRemotes"
		remotes.Parent = ReplicatedStorage
		print("GameCore: Created GameRemotes folder")
	end

	self.RemoteEvents = {}
	self.RemoteFunctions = {}

	-- FIXED: Removed shop events - let ShopSystem handle these
	local requiredRemoteEvents = {
		-- Core events
		"PlayerDataUpdated", "ShowNotification",
		-- Farm events
		"PlantSeed", "HarvestCrop", "HarvestAllCrops",
		-- Cow milking events
		"ShowChairPrompt", "HideChairPrompt", 
		"StartMilkingSession", "StopMilkingSession", 
		"ContinueMilking", "MilkingSessionUpdate",
		-- Proximity events
		"OpenShop", "CloseShop"
		-- REMOVED: Shop purchase events (handled by ShopSystem)
	}

	-- FIXED: Removed shop functions - let ShopSystem handle these
	local requiredRemoteFunctions = {
		-- Core functions
		"GetPlayerData", "GetFarmingData"
		-- REMOVED: Shop functions (handled by ShopSystem)
	}

	-- Create/connect remote events
	for _, eventName in ipairs(requiredRemoteEvents) do
		local remote = remotes:FindFirstChild(eventName)
		if not remote then
			remote = Instance.new("RemoteEvent")
			remote.Name = eventName
			remote.Parent = remotes
			print("GameCore: Created RemoteEvent: " .. eventName)
		end
		self.RemoteEvents[eventName] = remote
	end

	-- Create/connect remote functions
	for _, funcName in ipairs(requiredRemoteFunctions) do
		local remote = remotes:FindFirstChild(funcName)
		if not remote then
			remote = Instance.new("RemoteFunction")
			remote.Name = funcName
			remote.Parent = remotes
			print("GameCore: Created RemoteFunction: " .. funcName)
		end
		self.RemoteFunctions[funcName] = remote
	end

	print("GameCore: ✅ Remote connections established (shop events handled by ShopSystem)")
	print("  RemoteEvents: " .. #requiredRemoteEvents)
	print("  RemoteFunctions: " .. #requiredRemoteFunctions)
end
function GameCore:SetupEventHandlers()
	print("GameCore: Setting up event handlers...")

	-- Core remote function handlers
	if self.RemoteFunctions.GetPlayerData then
		self.RemoteFunctions.GetPlayerData.OnServerInvoke = function(player)
			return self:GetPlayerData(player)
		end
	end

	if self.RemoteFunctions.GetFarmingData then
		self.RemoteFunctions.GetFarmingData.OnServerInvoke = function(player)
			local playerData = self:GetPlayerData(player)
			return playerData and playerData.farming or {}
		end
	end

	-- Farm system event handlers (delegate to modules)
	if self.RemoteEvents.PlantSeed then
		self.RemoteEvents.PlantSeed.OnServerEvent:Connect(function(player, plotModel, seedId)
			pcall(function()
				self:PlantSeed(player, plotModel, seedId)
			end)
		end)
		print("✅ Connected PlantSeed handler")
	end

	if self.RemoteEvents.HarvestCrop then
		self.RemoteEvents.HarvestCrop.OnServerEvent:Connect(function(player, plotModel)
			pcall(function()
				self:HarvestCrop(player, plotModel)
			end)
		end)
		print("✅ Connected HarvestCrop handler")
	end

	if self.RemoteEvents.HarvestAllCrops then
		self.RemoteEvents.HarvestAllCrops.OnServerEvent:Connect(function(player)
			pcall(function()
				self:HarvestAllCrops(player)
			end)
		end)
		print("✅ Connected HarvestAllCrops handler")
	end

	-- Cow milking event handlers (delegate to modules)
	if self.RemoteEvents.StartMilkingSession then
		self.RemoteEvents.StartMilkingSession.OnServerEvent:Connect(function(player, cowId)
			if CowMilkingModule and CowMilkingModule.HandleStartMilkingSession then
				CowMilkingModule:HandleStartMilkingSession(player, cowId)
			end
		end)
	end

	if self.RemoteEvents.StopMilkingSession then
		self.RemoteEvents.StopMilkingSession.OnServerEvent:Connect(function(player)
			if CowMilkingModule and CowMilkingModule.HandleStopMilkingSession then
				CowMilkingModule:HandleStopMilkingSession(player)
			end
		end)
	end

	if self.RemoteEvents.ContinueMilking then
		self.RemoteEvents.ContinueMilking.OnServerEvent:Connect(function(player)
			if CowMilkingModule and CowMilkingModule.HandleContinueMilking then
				CowMilkingModule:HandleContinueMilking(player)
			end
		end)
	end

	print("GameCore: ✅ Event handlers setup complete")
end

-- ========== PLAYER MANAGEMENT ==========
function GameCore:EnsurePlayerHasGarden(player)
	if not _G.FarmPlot then
		warn("GameCore: FarmPlot module not available for garden check")
		return false
	end

	-- Check if garden exists in workspace
	local garden = workspace:FindFirstChild("Garden")
	if not garden then
		warn("GameCore: Garden model not found in workspace")
		return false
	end

	-- Check if player should have garden access
	local playerData = self:GetPlayerData(player)
	if not playerData then return false end

	local hasFarmStarter = playerData.purchaseHistory and playerData.purchaseHistory.farm_plot_starter
	local hasFarmingData = playerData.farming and playerData.farming.plots and playerData.farming.plots > 0

	if not (hasFarmStarter or hasFarmingData) then
		return false
	end

	-- Use FarmPlot module to ensure garden region exists
	return _G.FarmPlot:EnsurePlayerHasFarm(player)
end
function GameCore:SetupPlayerHandlers()
	Players.PlayerAdded:Connect(function(player)
		self:LoadPlayerData(player)
		self:CreatePlayerLeaderstats(player)

		-- AUTO-CREATE GARDEN FOR ALL PLAYERS
		spawn(function()
			wait(3) -- Wait for data to settle

			-- Give every player a garden automatically
			local playerData = self:GetPlayerData(player)
			if playerData then
				-- Initialize farming data for all players
				if not playerData.farming then
					playerData.farming = {
						plots = 1,
						inventory = {
							carrot_seeds = 5,  -- Give starter seeds
							corn_seeds = 3
						}
					}
				end

				-- Mark as having farm access (without purchase)
				playerData.purchaseHistory = playerData.purchaseHistory or {}
				playerData.purchaseHistory.farm_plot_starter = true

				-- Save the data
				self:SavePlayerData(player)

				-- Create the garden region
				self:EnsurePlayerHasFarm(player)

				print("🌱 Auto-created garden for " .. player.Name)

				-- Welcome notification
				if self.SendNotification then
					self:SendNotification(player, "🌱 Welcome to Your Garden!", 
						"Your personal garden is ready! Press F to see your seeds, then click garden spots to plant.", "success")
				end
			end
		end)

		-- Give starter cow after delay if cow system available
		if CowCreationModule then
			spawn(function()
				wait(8)  -- Increased delay to avoid conflicts
				pcall(function()
					CowCreationModule:GiveStarterCow(player)
				end)
			end)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		if self.PlayerData[player.UserId] then
			self:SavePlayerData(player, true)
		end
	end)

	-- Handle server shutdown
	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			if self.PlayerData[player.UserId] then
				pcall(function()
					self:SavePlayerData(player, true)
				end)
			end
		end
		wait(2)
	end)
end

-- ========== COW SYSTEM INTEGRATION ==========

function GameCore:HandleCowMilkCollection(player, cowId)
	if CowMilkingModule then
		return CowMilkingModule:HandleCowMilkCollection(player, cowId)
	end
	return false
end

function GameCore:CreateNewCowSafely(player, cowType, cowConfig)
	if CowCreationModule then
		return CowCreationModule:CreateNewCow(player, cowType, cowConfig)
	end
	return false
end

function GameCore:CreatePlayerLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local playerData = self.PlayerData[player.UserId]
	if not playerData then return end

	-- Coins leaderstat
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = playerData.coins or 0
	coins.Parent = leaderstats

	-- ADDED: Trimmings leaderstat
	local trimmings = Instance.new("IntValue")
	trimmings.Name = "Trimmings"
	trimmings.Value = playerData.trimmings or 0
	trimmings.Parent = leaderstats

	print("GameCore: Created leaderstats for " .. player.Name .. " (Coins: " .. coins.Value .. ", Trimmings: " .. trimmings.Value .. ")")
end

-- ========== UPDATE LEADERSTATS UPDATING ==========
-- REPLACE your existing UpdatePlayerLeaderstats method:

function GameCore:UpdatePlayerLeaderstats(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then 
		self:CreatePlayerLeaderstats(player)
		return
	end

	local playerData = self.PlayerData[player.UserId]
	if not playerData then return end

	-- Update coins
	local coins = leaderstats:FindFirstChild("Coins")
	if coins then 
		coins.Value = playerData.coins or 0
	end

	-- ADDED: Update trimmings
	local trimmings = leaderstats:FindFirstChild("Trimmings")
	if trimmings then 
		trimmings.Value = playerData.trimmings or 0
	end
end

-- ========== TRIMMINGS MANAGEMENT METHODS ==========
-- ADD these new methods to your GameCore:

function GameCore:AddTrimmings(player, amount)
	local playerData = self:GetPlayerData(player)
	if not playerData then return false end

	amount = amount or 1
	playerData.trimmings = (playerData.trimmings or 0) + amount

	-- Update stats
	playerData.stats = playerData.stats or {}
	playerData.stats.trimmingsEarned = (playerData.stats.trimmingsEarned or 0) + amount

	self:UpdatePlayerData(player, playerData)

	print("GameCore: Added " .. amount .. " trimmings to " .. player.Name .. " (Total: " .. playerData.trimmings .. ")")
	return true
end

function GameCore:RemoveTrimmings(player, amount)
	local playerData = self:GetPlayerData(player)
	if not playerData then return false end

	amount = amount or 1
	local currentTrimmings = playerData.trimmings or 0

	if currentTrimmings < amount then
		print("GameCore: " .. player.Name .. " doesn't have enough trimmings (has " .. currentTrimmings .. ", needs " .. amount .. ")")
		return false
	end

	playerData.trimmings = currentTrimmings - amount
	self:UpdatePlayerData(player, playerData)

	print("GameCore: Removed " .. amount .. " trimmings from " .. player.Name .. " (Remaining: " .. playerData.trimmings .. ")")
	return true
end

function GameCore:GetPlayerTrimmings(player)
	local playerData = self:GetPlayerData(player)
	if not playerData then return 0 end
	return playerData.trimmings or 0
end

function GameCore:SetPlayerTrimmings(player, amount)
	local playerData = self:GetPlayerData(player)
	if not playerData then return false end

	playerData.trimmings = math.max(0, amount)
	self:UpdatePlayerData(player, playerData)

	print("GameCore: Set " .. player.Name .. "'s trimmings to " .. playerData.trimmings)
	return true
end

-- ========== REMOTE FUNCTIONS FOR TRIMMINGS ==========
-- ADD this to your SetupEnhancedRemoteConnections method in the requiredRemoteFunctions table:

local requiredRemoteFunctions = {
	-- Core functions
	"GetPlayerData", "GetFarmingData",
	-- Inventory functions
	"GetInventoryData", "GetMiningData", "GetCraftingData",
	-- Selling function
	"SellInventoryItem",
	-- ADDED: Trimmings functions
	"GetPlayerTrimmings", "AddTrimmings", "RemoveTrimmings"
}

-- ADD this to your SetupEnhancedEventHandlers method:



-- ========== EXAMPLE USAGE ==========
-- You can now use trimmings anywhere in your game:

-- Give trimmings to a player
-- GameCore:AddTrimmings(player, 50)

-- Remove trimmings from a player
-- GameCore:RemoveTrimmings(player, 25)

-- Check how many trimmings a player has
-- local trimmings = GameCore:GetPlayerTrimmings(player)

-- Set exact amount of trimmings
-- GameCore:SetPlayerTrimmings(player, 100)

-- ========== GLOBAL TEST FUNCTIONS ==========
-- ADD these for testing:

_G.GiveTrimmings = function(playerName, amount)
	local player = game.Players:FindFirstChild(playerName)
	if not player then
		print("Player not found: " .. playerName)
		return
	end

	local success = GameCore:AddTrimmings(player, amount or 50)
	if success then
		print("Gave " .. (amount or 50) .. " trimmings to " .. playerName)
	else
		print("Failed to give trimmings to " .. playerName)
	end
end

_G.CheckTrimmings = function(playerName)
	local player = game.Players:FindFirstChild(playerName)
	if not player then
		print("Player not found: " .. playerName)
		return
	end

	local trimmings = GameCore:GetPlayerTrimmings(player)
	print(playerName .. " has " .. trimmings .. " trimmings")
	return trimmings
end

print("✅ TRIMMINGS INTEGRATION LOADED!")
print("🎯 NEW FEATURES:")
print("  ✅ Trimmings currency fully integrated into GameCore")
print("  ✅ Automatic leaderstats creation and updating")
print("  ✅ DataStore integration (saves with all other player data)")
print("  ✅ Trimmings management methods")
print("  ✅ Remote function support")
print("  ✅ Stats tracking")
print("")
print("🧪 Test Commands:")
print("  _G.GiveTrimmings('PlayerName', 100) - Give trimmings")
print("  _G.CheckTrimmings('PlayerName') - Check trimmings balance")

function GameCore:GetPlayerData(player)
	if not self.PlayerData[player.UserId] then
		self:LoadPlayerData(player)
	end
	return self.PlayerData[player.UserId]
end

function GameCore:LoadPlayerData(player)
	local defaultData = self:GetDefaultPlayerData()
	local loadedData = defaultData

	if self.PlayerDataStore then
		local success, data = pcall(function()
			return self.PlayerDataStore:GetAsync("Player_" .. player.UserId)
		end)

		if success and data then
			loadedData = self:DeepMerge(defaultData, data)
			print("GameCore: Loaded data for " .. player.Name)
		end
	end

	self.PlayerData[player.UserId] = loadedData
	self:UpdatePlayerLeaderstats(player)
	return loadedData
end

function GameCore:DeepMerge(default, loaded)
	local result = {}
	for key, value in pairs(default) do
		if type(value) == "table" then
			result[key] = self:DeepMerge(value, loaded[key] or {})
		else
			result[key] = loaded[key] ~= nil and loaded[key] or value
		end
	end
	for key, value in pairs(loaded) do
		if result[key] == nil then
			result[key] = value
		end
	end
	return result
end

function GameCore:SavePlayerData(player, forceImmediate)
	if not player or not player.Parent then return end

	local playerData = self.PlayerData[player.UserId]
	if not playerData then return end

	if self.PlayerDataStore then
		local success, error = pcall(function()
			return self.PlayerDataStore:SetAsync("Player_" .. player.UserId, playerData)
		end)

		if success then
			print("GameCore: Saved data for " .. player.Name)
		else
			warn("GameCore: Failed to save data for " .. player.Name .. ": " .. tostring(error))
		end
	end
end

function GameCore:SendNotification(player, title, message, type)
	if self.RemoteEvents.ShowNotification then
		self.RemoteEvents.ShowNotification:FireClient(player, title, message, type)
	end
end
--[[
    Server-Side Inventory Integration - Add to GameCore.lua
    
    ADDITIONS TO EXISTING GAMECORE.LUA:
    ✅ Enhanced remote functions for inventory data
    ✅ Inventory management methods  
    ✅ Mining and crafting data handling
    ✅ Milk tracking system
    ✅ Real-time inventory updates
]]

-- ========== ADD THESE METHODS TO YOUR EXISTING GAMECORE.LUA ==========

-- ========== ENHANCED REMOTE FUNCTION SETUP ==========


-- ========== INVENTORY MANAGEMENT METHODS ==========

function GameCore:GetInventoryData(player, inventoryType)
	local playerData = self:GetPlayerData(player)
	if not playerData then return {} end

	if inventoryType == "farming" then
		return playerData.farming and playerData.farming.inventory or {}
	elseif inventoryType == "mining" then
		return playerData.mining and playerData.mining.inventory or {}
	elseif inventoryType == "crafting" then
		return playerData.crafting and playerData.crafting.inventory or {}
	elseif inventoryType == "livestock" then
		return playerData.livestock or {}
	elseif inventoryType == "upgrades" then
		return playerData.upgrades or {}
	end

	return {}
end

function GameCore:AddItemToInventory(player, inventoryType, itemId, quantity)
	local playerData = self:GetPlayerData(player)
	if not playerData then return false end

	quantity = quantity or 1

	-- Initialize inventory if it doesn't exist
	if inventoryType == "farming" then
		playerData.farming = playerData.farming or {plots = 0, inventory = {}}
		playerData.farming.inventory = playerData.farming.inventory or {}
		playerData.farming.inventory[itemId] = (playerData.farming.inventory[itemId] or 0) + quantity

	elseif inventoryType == "mining" then
		playerData.mining = playerData.mining or {inventory = {}, tools = {}, level = 1}
		playerData.mining.inventory = playerData.mining.inventory or {}
		playerData.mining.inventory[itemId] = (playerData.mining.inventory[itemId] or 0) + quantity

	elseif inventoryType == "crafting" then
		playerData.crafting = playerData.crafting or {inventory = {}, recipes = {}, stations = {}}
		playerData.crafting.inventory = playerData.crafting.inventory or {}
		playerData.crafting.inventory[itemId] = (playerData.crafting.inventory[itemId] or 0) + quantity

	elseif inventoryType == "milk" then
		playerData.milk = (playerData.milk or 0) + quantity

	else
		warn("GameCore: Unknown inventory type: " .. tostring(inventoryType))
		return false
	end

	-- Update player data and notify client
	self:UpdatePlayerData(player, playerData)
	self:NotifyInventoryUpdate(player, inventoryType)

	print("GameCore: Added " .. quantity .. "x " .. itemId .. " to " .. player.Name .. "'s " .. inventoryType .. " inventory")
	return true
end

function GameCore:RemoveItemFromInventory(player, inventoryType, itemId, quantity)
	local playerData = self:GetPlayerData(player)
	if not playerData then return false end

	quantity = quantity or 1

	local currentQuantity = 0

	-- Get current quantity
	if inventoryType == "farming" then
		currentQuantity = playerData.farming and playerData.farming.inventory and playerData.farming.inventory[itemId] or 0
	elseif inventoryType == "mining" then
		currentQuantity = playerData.mining and playerData.mining.inventory and playerData.mining.inventory[itemId] or 0
	elseif inventoryType == "crafting" then
		currentQuantity = playerData.crafting and playerData.crafting.inventory and playerData.crafting.inventory[itemId] or 0
	elseif inventoryType == "milk" then
		currentQuantity = playerData.milk or 0
	else
		warn("GameCore: Unknown inventory type: " .. tostring(inventoryType))
		return false
	end

	-- Check if player has enough
	if currentQuantity < quantity then
		print("GameCore: " .. player.Name .. " doesn't have enough " .. itemId .. " (has " .. currentQuantity .. ", needs " .. quantity .. ")")
		return false
	end

	-- Remove items
	if inventoryType == "farming" then
		playerData.farming.inventory[itemId] = currentQuantity - quantity
		if playerData.farming.inventory[itemId] <= 0 then
			playerData.farming.inventory[itemId] = nil
		end

	elseif inventoryType == "mining" then
		playerData.mining.inventory[itemId] = currentQuantity - quantity
		if playerData.mining.inventory[itemId] <= 0 then
			playerData.mining.inventory[itemId] = nil
		end

	elseif inventoryType == "crafting" then
		playerData.crafting.inventory[itemId] = currentQuantity - quantity
		if playerData.crafting.inventory[itemId] <= 0 then
			playerData.crafting.inventory[itemId] = nil
		end

	elseif inventoryType == "milk" then
		playerData.milk = math.max(0, currentQuantity - quantity)
	end

	-- Update player data and notify client
	self:UpdatePlayerData(player, playerData)
	self:NotifyInventoryUpdate(player, inventoryType)

	print("GameCore: Removed " .. quantity .. "x " .. itemId .. " from " .. player.Name .. "'s " .. inventoryType .. " inventory")
	return true
end

function GameCore:SellInventoryItem(player, itemId, quantity)
	print("GameCore: Processing sell request - " .. player.Name .. " selling " .. quantity .. "x " .. itemId)

	local playerData = self:GetPlayerData(player)
	if not playerData then 
		self:SendNotification(player, "Sell Error", "Player data not found!", "error")
		return false 
	end

	-- Determine inventory type and sell price
	local inventoryType = self:DetermineInventoryType(itemId)
	local sellPrice = self:GetItemSellPrice(itemId)

	if not inventoryType then
		self:SendNotification(player, "Sell Error", "Item cannot be sold!", "error")
		return false
	end

	if sellPrice <= 0 then
		self:SendNotification(player, "Sell Error", "Item has no sell value!", "error")
		return false
	end

	-- Check if player has the item
	local hasItem = self:CheckInventoryItem(player, inventoryType, itemId, quantity)
	if not hasItem then
		self:SendNotification(player, "Sell Error", "You don't have enough " .. itemId:gsub("_", " ") .. "!", "error")
		return false
	end

	-- Remove item from inventory
	local removeSuccess = self:RemoveItemFromInventory(player, inventoryType, itemId, quantity)
	if not removeSuccess then
		self:SendNotification(player, "Sell Error", "Failed to remove item from inventory!", "error")
		return false
	end

	-- Add coins to player
	local totalValue = sellPrice * quantity
	playerData.coins = (playerData.coins or 0) + totalValue

	-- Update stats
	playerData.stats = playerData.stats or {}
	playerData.stats.itemsSold = (playerData.stats.itemsSold or 0) + quantity
	playerData.stats.coinsEarned = (playerData.stats.coinsEarned or 0) + totalValue

	-- Update player data
	self:UpdatePlayerData(player, playerData)

	-- Notify client of successful sale
	if self.RemoteEvents.ItemSold then
		self.RemoteEvents.ItemSold:FireClient(player, itemId, quantity, totalValue)
	end

	-- Get item name for notification
	local itemName = self:GetItemDisplayName(itemId)
	self:SendNotification(player, "💰 Sale Complete", 
		"Sold " .. quantity .. "x " .. itemName .. " for " .. totalValue .. " coins!", "success")

	print("GameCore: ✅ " .. player.Name .. " sold " .. quantity .. "x " .. itemId .. " for " .. totalValue .. " coins")
	return true
end

-- ========== HELPER METHODS ==========

function GameCore:DetermineInventoryType(itemId)
	-- Check if it's a crop
	if ItemConfig.Crops[itemId] then
		return "farming"
	end

	-- Check if it's milk
	if itemId == "milk" then
		return "milk"
	end

	-- Check if it's an ore
	if ItemConfig.MiningSystem and ItemConfig.MiningSystem.ores and ItemConfig.MiningSystem.ores[itemId] then
		return "mining"
	end

	-- Check if it's in farming inventory (seeds, etc.)
	if itemId:find("_seeds") then
		return "farming"
	end

	-- Check other item types
	if itemId:find("_ore") then
		return "mining"
	end

	-- Default to farming for unknown items
	return "farming"
end

function GameCore:GetItemSellPrice(itemId)
	-- Check crop sell prices
	if ItemConfig.Crops[itemId] then
		return ItemConfig.Crops[itemId].sellValue or 0
	end

	-- Check ore sell prices
	if ItemConfig.MiningSystem and ItemConfig.MiningSystem.ores and ItemConfig.MiningSystem.ores[itemId] then
		return ItemConfig.MiningSystem.ores[itemId].sellValue or 0
	end

	-- Special items
	if itemId == "milk" then
		return 2 -- 2 coins per milk
	end

	-- Default sell prices
	local defaultPrices = {
		-- Animal products
		milk = 2,
		fresh_milk = 3,

		-- Basic materials
		wood = 10,
		stone = 5,
		iron = 15,

		-- Seeds (half of buy price)
		carrot_seeds = 2,
		potato_seeds = 5,
		cabbage_seeds = 7,
		radish_seeds = 10,
		broccoli_seeds = 12,
		tomato_seeds = 15,
		strawberry_seeds = 17,
		wheat_seeds = 20,
		corn_seeds = 25
	}

	return defaultPrices[itemId] or 0
end

function GameCore:GetItemDisplayName(itemId)
	-- Try to get name from ItemConfig
	if ItemConfig.Crops[itemId] then
		return ItemConfig.Crops[itemId].name or itemId:gsub("_", " ")
	end

	if ItemConfig.ShopItems[itemId] then
		return ItemConfig.ShopItems[itemId].name or itemId:gsub("_", " ")
	end

	if ItemConfig.MiningSystem and ItemConfig.MiningSystem.ores and ItemConfig.MiningSystem.ores[itemId] then
		return ItemConfig.MiningSystem.ores[itemId].name or itemId:gsub("_", " ")
	end

	-- Convert underscore to space and capitalize
	return itemId:gsub("_", " "):gsub("^%l", string.upper)
end

function GameCore:CheckInventoryItem(player, inventoryType, itemId, quantity)
	local playerData = self:GetPlayerData(player)
	if not playerData then return false end

	quantity = quantity or 1

	if inventoryType == "farming" then
		local currentQuantity = playerData.farming and playerData.farming.inventory and playerData.farming.inventory[itemId] or 0
		return currentQuantity >= quantity

	elseif inventoryType == "mining" then
		local currentQuantity = playerData.mining and playerData.mining.inventory and playerData.mining.inventory[itemId] or 0
		return currentQuantity >= quantity

	elseif inventoryType == "crafting" then
		local currentQuantity = playerData.crafting and playerData.crafting.inventory and playerData.crafting.inventory[itemId] or 0
		return currentQuantity >= quantity

	elseif inventoryType == "milk" then
		local currentQuantity = playerData.milk or 0
		return currentQuantity >= quantity
	end

	return false
end

function GameCore:NotifyInventoryUpdate(player, inventoryType)
	if self.RemoteEvents.InventoryUpdated then
		local inventoryData = self:GetInventoryData(player, inventoryType)
		self.RemoteEvents.InventoryUpdated:FireClient(player, inventoryType, inventoryData)
	end
end

function GameCore:UpdatePlayerData(player, newData)
	self.PlayerData[player.UserId] = newData
	self:UpdatePlayerLeaderstats(player)

	-- Notify client of data update
	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, newData)
	end
end

-- ========== ENHANCED DEFAULT PLAYER DATA ==========

function GameCore:GetEnhancedDefaultPlayerData()
	return {
		coins = 100,
		farmTokens = 0,
		milk = 0, -- ADDED: Milk tracking
		upgrades = {},
		purchaseHistory = {},
		farming = {
			plots = 0,
			inventory = {},
			level = 1
		},
		mining = { -- ADDED: Mining data structure
			inventory = {},
			tools = {},
			level = 1,
			experience = 0
		},
		crafting = { -- ADDED: Crafting data structure
			inventory = {},
			recipes = {},
			stations = {},
			level = 1
		},
		livestock = {
			cows = {}
		},
		stats = {
			coinsEarned = 100,
			cropsHarvested = 0,
			milkCollected = 0,
			itemsSold = 0, -- ADDED
			oresMined = 0, -- ADDED
			itemsCrafted = 0 -- ADDED
		},
		firstJoin = os.time(),
		lastSave = os.time()
	}
end

-- ========== MILK COLLECTION SYSTEM ==========

function GameCore:CollectMilk(player, amount)
	amount = amount or 1

	local success = self:AddItemToInventory(player, "milk", "milk", amount)
	if success then
		local playerData = self:GetPlayerData(player)

		-- Update stats
		playerData.stats = playerData.stats or {}
		playerData.stats.milkCollected = (playerData.stats.milkCollected or 0) + amount

		self:UpdatePlayerData(player, playerData)

		self:SendNotification(player, "🥛 Milk Collected", 
			"Collected " .. amount .. " milk from your cow!", "success")

		print("GameCore: " .. player.Name .. " collected " .. amount .. " milk")
		return true
	end

	return false
end

-- ========== MINING SYSTEM INTEGRATION ==========

function GameCore:AddMiningTool(player, toolId, toolData)
	local playerData = self:GetPlayerData(player)
	if not playerData then return false end

	playerData.mining = playerData.mining or {inventory = {}, tools = {}, level = 1}
	playerData.mining.tools = playerData.mining.tools or {}

	playerData.mining.tools[toolId] = {
		durability = toolData.durability or 100,
		maxDurability = toolData.durability or 100,
		acquiredTime = os.time()
	}

	self:UpdatePlayerData(player, playerData)
	self:NotifyInventoryUpdate(player, "mining")

	print("GameCore: Added mining tool " .. toolId .. " to " .. player.Name)
	return true
end

function GameCore:AddOreToInventory(player, oreId, quantity)
	quantity = quantity or 1

	local success = self:AddItemToInventory(player, "mining", oreId, quantity)
	if success then
		local playerData = self:GetPlayerData(player)

		-- Update mining stats
		playerData.stats = playerData.stats or {}
		playerData.stats.oresMined = (playerData.stats.oresMined or 0) + quantity

		-- Add mining experience
		playerData.mining = playerData.mining or {inventory = {}, tools = {}, level = 1, experience = 0}
		local oreData = ItemConfig.MiningSystem and ItemConfig.MiningSystem.ores and ItemConfig.MiningSystem.ores[oreId]
		local xpGain = oreData and oreData.xpReward or 10
		playerData.mining.experience = (playerData.mining.experience or 0) + xpGain

		-- Check for level up
		self:CheckMiningLevelUp(player, playerData)

		self:UpdatePlayerData(player, playerData)

		local oreName = oreData and oreData.name or oreId:gsub("_", " ")
		self:SendNotification(player, "⛏️ Ore Mined", 
			"Found " .. quantity .. "x " .. oreName .. "! (+" .. xpGain .. " XP)", "success")

		print("GameCore: " .. player.Name .. " mined " .. quantity .. "x " .. oreId)
		return true
	end

	return false
end

function GameCore:CheckMiningLevelUp(player, playerData)
	local mining = playerData.mining
	if not mining then return end

	local currentLevel = mining.level or 1
	local experience = mining.experience or 0

	-- Simple leveling: 100 XP per level
	local newLevel = math.floor(experience / 100) + 1

	if newLevel > currentLevel then
		mining.level = newLevel
		self:SendNotification(player, "🎉 Level Up!", 
			"Mining level increased to " .. newLevel .. "!", "success")
		print("GameCore: " .. player.Name .. " leveled up mining to level " .. newLevel)
	end
end

-- ========== CRAFTING SYSTEM INTEGRATION ==========

function GameCore:AddCraftingStation(player, stationId)
	local playerData = self:GetPlayerData(player)
	if not playerData then return false end

	playerData.crafting = playerData.crafting or {inventory = {}, recipes = {}, stations = {}}
	playerData.crafting.stations = playerData.crafting.stations or {}

	playerData.crafting.stations[stationId] = {
		acquiredTime = os.time(),
		level = 1
	}

	self:UpdatePlayerData(player, playerData)
	self:NotifyInventoryUpdate(player, "crafting")

	print("GameCore: Added crafting station " .. stationId .. " to " .. player.Name)
	return true
end

function GameCore:AddCraftingRecipe(player, recipeId)
	local playerData = self:GetPlayerData(player)
	if not playerData then return false end

	playerData.crafting = playerData.crafting or {inventory = {}, recipes = {}, stations = {}}
	playerData.crafting.recipes = playerData.crafting.recipes or {}

	playerData.crafting.recipes[recipeId] = {
		learnedTime = os.time()
	}

	self:UpdatePlayerData(player, playerData)
	self:NotifyInventoryUpdate(player, "crafting")

	local recipeName = recipeId:gsub("_", " "):gsub("^%l", string.upper)
	self:SendNotification(player, "📜 Recipe Learned", 
		"You learned how to craft " .. recipeName .. "!", "success")

	print("GameCore: " .. player.Name .. " learned recipe " .. recipeId)
	return true
end

-- ========== ENHANCED DEBUG FUNCTIONS ==========

function GameCore:DebugEnhancedStatus()
	print("=== ENHANCED GAMECORE DEBUG STATUS ===")
	print("Modules loaded:")
	print("  FarmPlot: " .. (FarmPlot and "✅" or "❌"))
	print("  CowCreationModule: " .. (CowCreationModule and "✅" or "❌"))
	print("  CowMilkingModule: " .. (CowMilkingModule and "✅" or "❌"))
	print("  CropCreation: " .. (CropCreation and "✅" or "❌"))
	print("  CropVisual: " .. (CropVisual and "✅" or "❌"))
	print("Players: " .. #Players:GetPlayers())
	print("Data store: " .. (self.PlayerDataStore and "✅" or "❌"))
	print("Enhanced remote events: " .. (self.RemoteEvents and self:CountTable(self.RemoteEvents) or 0))
	print("Enhanced remote functions: " .. (self.RemoteFunctions and self:CountTable(self.RemoteFunctions) or 0))

	-- Check player inventories
	for _, player in ipairs(Players:GetPlayers()) do
		local playerData = self.PlayerData[player.UserId]
		if playerData then
			print("Player " .. player.Name .. ":")
			print("  Coins: " .. (playerData.coins or 0))
			print("  Milk: " .. (playerData.milk or 0))
			print("  Farm items: " .. (playerData.farming and self:CountTable(playerData.farming.inventory or {}) or 0))
			print("  Mining items: " .. (playerData.mining and self:CountTable(playerData.mining.inventory or {}) or 0))
			print("  Crafting items: " .. (playerData.crafting and self:CountTable(playerData.crafting.inventory or {}) or 0))
		end
	end
	print("==============================")
end

-- ========== GLOBAL FUNCTIONS FOR TESTING ==========

_G.AddTestItems = function(playerName)
	local player = Players:FindFirstChild(playerName)
	if not player then
		print("Player not found: " .. playerName)
		return
	end

	-- Add test farming items
	GameCore:AddItemToInventory(player, "farming", "carrot_seeds", 10)
	GameCore:AddItemToInventory(player, "farming", "carrot", 5)
	GameCore:AddItemToInventory(player, "farming", "potato", 3)

	-- Add test mining items
	GameCore:AddOreToInventory(player, "copper_ore", 8)
	GameCore:AddOreToInventory(player, "silver_ore", 3)

	-- Add test milk
	GameCore:CollectMilk(player, 12)

	print("Added test items to " .. playerName)
end

_G.DebugEnhancedGameCore = function()
	if GameCore and GameCore.DebugEnhancedStatus then
		GameCore:DebugEnhancedStatus()
	end
end

print("✅ ENHANCED GAMECORE INVENTORY INTEGRATION LOADED!")
print("🎯 NEW FEATURES:")
print("  ✅ Complete inventory management system")
print("  ✅ Milk tracking and collection")
print("  ✅ Mining system with ores and tools")
print("  ✅ Crafting system with stations and recipes")
print("  ✅ Sell inventory items functionality")
print("  ✅ Real-time inventory updates")
print("  ✅ Experience and leveling systems")
print("  ✅ Enhanced player data structure")
print("")
print("🧪 Test Commands:")
print("  _G.AddTestItems('PlayerName') - Add test items")
print("  _G.DebugEnhancedGameCore() - Show enhanced debug info")
-- ========== DEBUG FUNCTIONS ==========

function GameCore:DebugStatus()
	print("=== UPDATED GAMECORE DEBUG STATUS ===")
	print("Modules loaded:")
	print("  FarmPlot: " .. (FarmPlot and "✅" or "❌"))
	print("  CowCreationModule: " .. (CowCreationModule and "✅" or "❌"))
	print("  CowMilkingModule: " .. (CowMilkingModule and "✅" or "❌"))
	print("  CropCreation: " .. (CropCreation and "✅" or "❌"))
	print("  CropVisual: " .. (CropVisual and "✅" or "❌"))
	print("Players: " .. #Players:GetPlayers())
	print("Data store: " .. (self.PlayerDataStore and "✅" or "❌"))
	print("Remote events: " .. (self.RemoteEvents and #self.RemoteEvents or 0))
	print("==============================")
end

-- Make globally available
_G.GameCore = GameCore

return GameCore