--[[
    FIXED GameCore.lua - Enhanced Inventory Management
    
    FIXES:
    ✅ Consistent item storage in correct inventory locations
    ✅ Proper crop harvesting to farming inventory
    ✅ Enhanced milk collection system
    ✅ Better integration with ShopSystem
    ✅ Robust inventory initialization
    ✅ Improved error handling
]]

local GameCore = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

-- Load configuration
local ItemConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("ItemConfig"))
local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "GameRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

-- FARM PLOT POSITION CONFIGURATION
GameCore.FarmPlotPositions = {
	basePosition = Vector3.new(-366.118, -2.793, 75.731),
	plotOffsets = {
		[1] = Vector3.new(0, 0, 0),
		[2] = Vector3.new(-34.65, 0, 0),
		[3] = Vector3.new(0, 0, 33.8),
		[4] = Vector3.new(-34.65, 0, 33.65),
		[5] = Vector3.new(-34.65, 0, 66.95),
		[6] = Vector3.new(0, 0, 66.95),
		[7] = Vector3.new(0, 0, 100.75),
		[8] = Vector3.new(-34.65, 0, 100.6),
	},
	plotRotation = Vector3.new(0, 0, 0),
	playerSeparation = Vector3.new(120, 0, 0)
}

-- Core Data Management
GameCore.PlayerData = {}
GameCore.RemoteEvents = {}
GameCore.RemoteFunctions = {}
GameCore.DataStoreCooldowns = {}
GameCore.SAVE_COOLDOWN = 60
GameCore.STUDIO_MODE = game:GetService("RunService"):IsStudio()

-- System States
GameCore.Systems = {
	Livestock = {
		CowCooldowns = {},
		PigStates = {}
	},
	Farming = {
		PlayerFarms = {},
		GrowthTimers = {},
		RarityEffects = {}
	}
}

-- Workspace Models
GameCore.Models = {
	Cow = nil,
	Pig = nil
}

-- Reference to ShopSystem (will be injected)
GameCore.ShopSystem = nil

-- ========== INITIALIZATION ==========

function GameCore:Initialize(shopSystem)
	print("GameCore: Starting FIXED initialization with enhanced inventory management...")

	-- Store ShopSystem reference
	if shopSystem then
		self.ShopSystem = shopSystem
		print("GameCore: ShopSystem reference established")
	end

	-- Initialize DataStore
	self:InitializeDataStore()

	-- Initialize player data storage
	self.PlayerData = {}
	self.DataStoreCooldowns = {}

	-- Setup remote connections
	self:SetupRemoteConnections()

	-- Setup event handlers
	self:SetupEventHandlers()

	-- Initialize game systems
	self:InitializeLivestockSystem()
	self:InitializeFarmingSystem()

	-- Start update loops
	self:StartUpdateLoops()

	print("GameCore: ✅ FIXED initialization complete!")
	return true
end

function GameCore:InitializeDataStore()
	local success, dataStore = pcall(function()
		return DataStoreService:GetDataStore("LivestockFarmData_v4")
	end)

	if success then
		self.PlayerDataStore = dataStore
		print("✅ GameCore: DataStore connected successfully")
		return true
	else
		warn("❌ GameCore: Failed to connect to DataStore: " .. tostring(dataStore))
		self.PlayerDataStore = nil
		return false
	end
end

-- ========== REMOTE CONNECTIONS ==========

function GameCore:SetupRemoteConnections()
	print("GameCore: Setting up core remote connections...")

	local remotes = ReplicatedStorage:WaitForChild("GameRemotes", 10)
	if not remotes then
		error("GameCore: GameRemotes folder not found after 10 seconds!")
	end

	-- Core remote events
	local coreRemoteEvents = {
		"CollectMilk", "FeedPig", "PlayerDataUpdated", "ShowNotification",
		"PlantSeed", "HarvestCrop", "HarvestAllCrops"
	}

	-- Core remote functions
	local coreRemoteFunctions = {
		"GetPlayerData", "GetFarmingData"
	}

	-- Load core remote events
	for _, eventName in ipairs(coreRemoteEvents) do
		local remote = remotes:FindFirstChild(eventName)
		if remote and remote:IsA("RemoteEvent") then
			self.RemoteEvents[eventName] = remote
		else
			local newRemote = Instance.new("RemoteEvent")
			newRemote.Name = eventName
			newRemote.Parent = remotes
			self.RemoteEvents[eventName] = newRemote
		end
	end

	-- Load core remote functions
	for _, funcName in ipairs(coreRemoteFunctions) do
		local remote = remotes:FindFirstChild(funcName)
		if remote and remote:IsA("RemoteFunction") then
			self.RemoteFunctions[funcName] = remote
		else
			local newRemote = Instance.new("RemoteFunction")
			newRemote.Name = funcName
			newRemote.Parent = remotes
			self.RemoteFunctions[funcName] = newRemote
		end
	end

	print("GameCore: Remote connections established")
end

function GameCore:SetupEventHandlers()
	print("GameCore: Setting up core event handlers...")

	-- Livestock System Events
	if self.RemoteEvents.CollectMilk then
		self.RemoteEvents.CollectMilk.OnServerEvent:Connect(function(player)
			pcall(function()
				self:HandleMilkCollection(player)
			end)
		end)
	end

	if self.RemoteEvents.FeedPig then
		self.RemoteEvents.FeedPig.OnServerEvent:Connect(function(player, cropId)
			pcall(function()
				self:HandlePigFeeding(player, cropId)
			end)
		end)
	end

	-- Farming System Events
	if self.RemoteEvents.PlantSeed then
		self.RemoteEvents.PlantSeed.OnServerEvent:Connect(function(player, plotModel, seedId)
			pcall(function()
				self:PlantSeed(player, plotModel, seedId)
			end)
		end)
	end

	if self.RemoteEvents.HarvestCrop then
		self.RemoteEvents.HarvestCrop.OnServerEvent:Connect(function(player, plotModel)
			pcall(function()
				self:HarvestCrop(player, plotModel)
			end)
		end)
	end

	if self.RemoteEvents.HarvestAllCrops then
		self.RemoteEvents.HarvestAllCrops.OnServerEvent:Connect(function(player)
			pcall(function()
				self:HarvestAllCrops(player)
			end)
		end)
	end

	-- Core Remote Functions
	if self.RemoteFunctions.GetPlayerData then
		self.RemoteFunctions.GetPlayerData.OnServerInvoke = function(player)
			local success, result = pcall(function()
				return self:GetPlayerData(player)
			end)
			return success and result or nil
		end
	end

	if self.RemoteFunctions.GetFarmingData then
		self.RemoteFunctions.GetFarmingData.OnServerInvoke = function(player)
			local success, result = pcall(function()
				local playerData = self:GetPlayerData(player)
				return playerData and playerData.farming or {}
			end)
			return success and result or {}
		end
	end

	print("GameCore: Event handlers setup complete!")
end

-- ========== ENHANCED INVENTORY MANAGEMENT ==========

function GameCore:InitializePlayerInventories(playerData)
	print("GameCore: Initializing comprehensive inventory system")

	-- Initialize ALL inventory locations with consistent structure
	if not playerData.farming then
		playerData.farming = {
			plots = 0,
			inventory = {} -- Seeds and crops go here
		}
	end
	if not playerData.farming.inventory then
		playerData.farming.inventory = {}
	end

	if not playerData.livestock then
		playerData.livestock = {
			cows = {},
			pig = {
				size = 1.0,
				cropPoints = 0,
				transformationCount = 0,
				totalFed = 0
			},
			inventory = {} -- Milk, eggs, animal products go here
		}
	end
	if not playerData.livestock.inventory then
		playerData.livestock.inventory = {}
	end

	if not playerData.inventory then
		playerData.inventory = {} -- General items, tools go here
	end

	if not playerData.defense then
		playerData.defense = {
			chickens = {
				owned = {},
				deployed = {},
				feed = {} -- Chicken feed goes here
			},
			pestControl = {}, -- Pesticides go here
			roofs = {}
		}
	end

	if not playerData.mining then
		playerData.mining = {
			tools = {},
			inventory = {}, -- Ores go here
			level = 1,
			xp = 0
		}
	end

	if not playerData.buildings then
		playerData.buildings = {}
	end

	if not playerData.upgrades then
		playerData.upgrades = {}
	end

	if not playerData.stats then
		playerData.stats = {
			milkCollected = 0,
			coinsEarned = 100,
			cropsHarvested = 0,
			rareCropsHarvested = 0,
			pigFed = 0,
			megaTransformations = 0,
			seedsPlanted = 0,
			pestsEliminated = 0
		}
	end

	print("GameCore: All inventory locations initialized")
end

function GameCore:AddItemToCorrectInventory(playerData, itemId, quantity, itemType)
	print("📦 GameCore: Adding " .. quantity .. "x " .. itemId .. " to correct inventory (type: " .. (itemType or "auto") .. ")")

	-- Ensure inventories are initialized
	self:InitializePlayerInventories(playerData)

	-- Determine correct inventory location based on item type or ID
	local targetInventory = nil
	local inventoryPath = ""

	if itemType == "seed" or itemId:find("_seeds") then
		-- Seeds go to farming inventory
		targetInventory = playerData.farming.inventory
		inventoryPath = "farming.inventory"

	elseif itemType == "crop" or self:IsCropItem(itemId) then
		-- Crops go to farming inventory
		targetInventory = playerData.farming.inventory
		inventoryPath = "farming.inventory"

	elseif itemId == "milk" or itemId == "fresh_milk" or itemId:find("_egg") then
		-- Animal products go to livestock inventory
		targetInventory = playerData.livestock.inventory
		inventoryPath = "livestock.inventory"

	elseif itemId:find("_ore") or itemType == "ore" then
		-- Ores go to mining inventory
		targetInventory = playerData.mining.inventory
		inventoryPath = "mining.inventory"

	elseif itemId:find("_feed") or itemType == "feed" then
		-- Feed goes to chicken feed inventory
		targetInventory = playerData.defense.chickens.feed
		inventoryPath = "defense.chickens.feed"

	elseif itemId:find("pesticide") or itemId:find("pest_") then
		-- Pest control items go to pest control inventory
		targetInventory = playerData.defense.pestControl
		inventoryPath = "defense.pestControl"

	else
		-- General items go to main inventory
		targetInventory = playerData.inventory
		inventoryPath = "inventory"
	end

	-- Add item to target inventory
	if targetInventory then
		local currentAmount = targetInventory[itemId] or 0
		targetInventory[itemId] = currentAmount + quantity
		print("✅ Added " .. quantity .. "x " .. itemId .. " to " .. inventoryPath)
		return true
	else
		warn("❌ Could not determine inventory location for " .. itemId)
		return false
	end
end

function GameCore:IsCropItem(itemId)
	local knownCrops = {
		"carrot", "corn", "strawberry", "wheat", "potato", 
		"tomato", "cabbage", "radish", "broccoli", "golden_fruit"
	}

	for _, cropId in ipairs(knownCrops) do
		if itemId == cropId then
			return true
		end
	end

	return false
end

-- ========== ENHANCED FARMING SYSTEM ==========

function GameCore:InitializeFarmingSystem()
	print("GameCore: Initializing ENHANCED farming system...")
	self.Systems.Farming.RarityEffects = {}
	print("GameCore: Enhanced farming system initialized")
end

function GameCore:PlantSeed(player, plotModel, seedId)
	print("🌱 GameCore: ENHANCED plant seed request - " .. player.Name .. " wants to plant " .. seedId)

	local playerData = self:GetPlayerData(player)
	if not playerData then 
		self:SendNotification(player, "Error", "Player data not found", "error")
		return false
	end

	-- Initialize inventories
	self:InitializePlayerInventories(playerData)

	-- Check if player has the seed in farming inventory
	local seedCount = playerData.farming.inventory[seedId] or 0
	if seedCount <= 0 then
		local seedInfo = ItemConfig.ShopItems[seedId]
		local seedName = seedInfo and seedInfo.name or seedId:gsub("_", " ")
		self:SendNotification(player, "No Seeds", "You don't have any " .. seedName .. "!", "error")
		return false
	end

	-- Validate the plot model
	if not plotModel or not plotModel.Parent then
		self:SendNotification(player, "Invalid Plot", "Plot not found or invalid!", "error")
		return false
	end

	-- Check if plot is empty
	local isEmpty = plotModel:GetAttribute("IsEmpty")
	if not isEmpty then
		self:SendNotification(player, "Plot Occupied", "This plot already has something planted!", "error")
		return false
	end

	-- Check if this is the player's plot
	local plotOwner = self:GetPlotOwner(plotModel)
	if plotOwner ~= player.Name then
		self:SendNotification(player, "Not Your Plot", "You can only plant on your own farm plots!", "error")
		return false
	end

	-- Get seed data from ItemConfig
	local seedData = ItemConfig.GetSeedData(seedId)
	if not seedData then
		self:SendNotification(player, "Invalid Seed", "Seed data not found for " .. seedId .. "!", "error")
		return false
	end

	-- Determine crop rarity
	local playerBoosters = self:GetPlayerBoosters(playerData)
	local cropRarity = ItemConfig.GetCropRarity(seedId, playerBoosters)

	-- Plant the seed
	local success = self:CreateCropOnPlot(plotModel, seedId, seedData, cropRarity)
	if not success then
		self:SendNotification(player, "Planting Failed", "Could not plant seed on plot!", "error")
		return false
	end

	-- Remove seed from farming inventory
	playerData.farming.inventory[seedId] = playerData.farming.inventory[seedId] - 1
	if playerData.farming.inventory[seedId] <= 0 then
		playerData.farming.inventory[seedId] = nil
	end

	-- Update plot attributes
	plotModel:SetAttribute("IsEmpty", false)
	plotModel:SetAttribute("PlantType", seedData.resultCropId)
	plotModel:SetAttribute("SeedType", seedId)
	plotModel:SetAttribute("GrowthStage", 0)
	plotModel:SetAttribute("PlantedTime", os.time())
	plotModel:SetAttribute("Rarity", cropRarity)

	-- Update stats
	playerData.stats.seedsPlanted = (playerData.stats.seedsPlanted or 0) + 1

	-- Save and notify
	self:SavePlayerData(player)

	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	local seedInfo = ItemConfig.ShopItems[seedId]
	local seedName = seedInfo and seedInfo.name or seedId:gsub("_", " ")
	local rarityColor = ItemConfig.GetRarityColor(cropRarity)
	local rarityName = ItemConfig.RaritySystem[cropRarity] and ItemConfig.RaritySystem[cropRarity].name or cropRarity

	self:SendNotification(player, "🌱 Seed Planted!", 
		"Successfully planted " .. seedName .. "!\n🌟 Rarity: " .. rarityName .. "\n⏰ Ready in " .. math.floor(seedData.growTime/60) .. " minutes.", "success")

	return true
end

function GameCore:HarvestCrop(player, plotModel)
	print("🌾 GameCore: ENHANCED harvest request from " .. player.Name .. " for plot " .. plotModel.Name)

	local playerData = self:GetPlayerData(player)
	if not playerData then 
		self:SendNotification(player, "Error", "Player data not found", "error")
		return false
	end

	-- Initialize inventories
	self:InitializePlayerInventories(playerData)

	local plotOwner = self:GetPlotOwner(plotModel)
	if plotOwner ~= player.Name then
		self:SendNotification(player, "Not Your Plot", "You can only harvest your own crops!", "error")
		return false
	end

	local growthStage = plotModel:GetAttribute("GrowthStage") or 0
	if growthStage < 4 then
		local timeLeft = self:GetCropTimeRemaining(plotModel)
		self:SendNotification(player, "Not Ready", 
			"Crop is not ready for harvest yet! " .. math.ceil(timeLeft/60) .. " minutes remaining.", "warning")
		return false
	end

	-- Get enhanced crop data with rarity
	local plantType = plotModel:GetAttribute("PlantType") or ""
	local seedType = plotModel:GetAttribute("SeedType") or ""
	local cropRarity = plotModel:GetAttribute("Rarity") or "common"

	local cropData = ItemConfig.GetCropData(plantType)
	local seedData = ItemConfig.GetSeedData(seedType)

	if not cropData or not seedData then
		self:SendNotification(player, "Invalid Crop", "Crop data not found for " .. plantType, "error")
		return false
	end

	-- Calculate yield with rarity bonus
	local baseYield = seedData.yieldAmount or 1
	local rarityMultiplier = ItemConfig.RaritySystem[cropRarity] and ItemConfig.RaritySystem[cropRarity].valueMultiplier or 1.0
	local finalYield = math.floor(baseYield * rarityMultiplier)

	-- Add crops to FARMING INVENTORY (this is the key fix!)
	local currentAmount = playerData.farming.inventory[plantType] or 0
	playerData.farming.inventory[plantType] = currentAmount + finalYield

	print("✅ Added " .. finalYield .. "x " .. plantType .. " to farming.inventory")

	-- Reset plot
	plotModel:SetAttribute("IsEmpty", true)
	plotModel:SetAttribute("PlantType", "")
	plotModel:SetAttribute("SeedType", "")
	plotModel:SetAttribute("GrowthStage", 0)
	plotModel:SetAttribute("PlantedTime", 0)
	plotModel:SetAttribute("Rarity", "common")

	-- Remove crop model
	local cropModel = plotModel:FindFirstChild("CropModel")
	if cropModel then
		cropModel:Destroy()
	end

	-- Update stats
	playerData.stats.cropsHarvested = (playerData.stats.cropsHarvested or 0) + finalYield
	if cropRarity ~= "common" then
		playerData.stats.rareCropsHarvested = (playerData.stats.rareCropsHarvested or 0) + 1
	end

	-- Save and notify
	self:SavePlayerData(player)

	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	local rarityName = ItemConfig.RaritySystem[cropRarity] and ItemConfig.RaritySystem[cropRarity].name or cropRarity
	local rarityEmoji = cropRarity == "legendary" and "👑" or 
		cropRarity == "epic" and "💜" or 
		cropRarity == "rare" and "✨" or 
		cropRarity == "uncommon" and "💚" or "⚪"

	self:SendNotification(player, "🌾 Crop Harvested!", 
		"Harvested " .. finalYield .. "x " .. rarityEmoji .. " " .. rarityName .. " " .. cropData.name .. "!\n" ..
			(cropRarity ~= "common" and "🎉 Bonus yield from rarity!" or ""), "success")

	print("🌾 GameCore: Successfully harvested " .. finalYield .. "x " .. plantType .. " (" .. cropRarity .. ") for " .. player.Name)
	return true
end

function GameCore:HarvestAllCrops(player)
	print("🌾 GameCore: Enhanced harvest all request from " .. player.Name)

	local playerData = self:GetPlayerData(player)
	if not playerData then 
		self:SendNotification(player, "Error", "Player data not found", "error")
		return false
	end

	-- Find all player's farm plots
	local areas = workspace:FindFirstChild("Areas")
	if not areas then
		self:SendNotification(player, "No Farm", "Farm area not found!", "error")
		return false
	end

	local starterMeadow = areas:FindFirstChild("Starter Meadow")
	if not starterMeadow then
		self:SendNotification(player, "No Farm", "Starter Meadow not found!", "error")
		return false
	end

	local farmArea = starterMeadow:FindFirstChild("Farm")
	if not farmArea then
		self:SendNotification(player, "No Farm", "Farm area not found!", "error")
		return false
	end

	local playerFarm = farmArea:FindFirstChild(player.Name .. "_Farm")
	if not playerFarm then
		self:SendNotification(player, "No Farm", "You don't have a farm yet!", "error")
		return false
	end

	local harvestedCount = 0
	local readyCrops = 0
	local totalCrops = 0
	local harvestedItems = {}

	-- Go through all farm plots
	for _, plot in pairs(playerFarm:GetChildren()) do
		if plot:IsA("Model") and plot.Name:find("FarmPlot") then
			local plantingSpots = plot:FindFirstChild("PlantingSpots")
			if plantingSpots then
				for _, spot in pairs(plantingSpots:GetChildren()) do
					if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
						local isEmpty = spot:GetAttribute("IsEmpty")
						if not isEmpty then
							totalCrops = totalCrops + 1
							local growthStage = spot:GetAttribute("GrowthStage") or 0

							if growthStage >= 4 then
								readyCrops = readyCrops + 1
								local success = self:HarvestCrop(player, spot)
								if success then
									harvestedCount = harvestedCount + 1

									-- Track what was harvested
									local plantType = spot:GetAttribute("PlantType") or "unknown"
									harvestedItems[plantType] = (harvestedItems[plantType] or 0) + 1
								end
								wait(0.1)
							end
						end
					end
				end
			end
		end
	end

	-- Send enhanced summary notification
	if harvestedCount > 0 then
		local harvestSummary = ""
		for itemId, count in pairs(harvestedItems) do
			local itemName = ItemConfig.Crops[itemId] and ItemConfig.Crops[itemId].name or itemId
			harvestSummary = harvestSummary .. itemName .. ": " .. count .. "\n"
		end

		self:SendNotification(player, "🌾 Mass Harvest Complete!", 
			"Harvested " .. harvestedCount .. " crops!\n\n" .. harvestSummary ..
				(readyCrops - harvestedCount > 0 and (readyCrops - harvestedCount) .. " crops failed to harvest.\n" or "") ..
				(totalCrops - readyCrops > 0 and (totalCrops - readyCrops) .. " crops still growing." or ""), "success")
	else
		if totalCrops == 0 then
			self:SendNotification(player, "No Crops", "You don't have any crops planted!", "info")
		elseif readyCrops == 0 then
			self:SendNotification(player, "Crops Not Ready", "None of your " .. totalCrops .. " crops are ready for harvest yet!", "warning")
		else
			self:SendNotification(player, "Harvest Failed", "Found " .. readyCrops .. " ready crops but couldn't harvest any!", "error")
		end
	end

	return harvestedCount > 0
end

-- ========== ENHANCED LIVESTOCK SYSTEM ==========

function GameCore:InitializeLivestockSystem()
	print("GameCore: Initializing enhanced livestock system...")

	-- Find models in workspace
	self.Models.Cow = workspace:FindFirstChild("cow")
	self.Models.Pig = workspace:FindFirstChild("Pig")

	if self.Models.Cow then
		self:SetupCowInteraction()
	end

	if self.Models.Pig then
		print("GameCore: Found pig model")
	end

	-- Initialize player-specific livestock data
	self.Systems.Livestock.CowCooldowns = {}
	self.Systems.Livestock.PigStates = {}

	print("GameCore: Enhanced livestock system initialized")
end

function GameCore:SetupCowInteraction()
	if not self.Models.Cow then return end

	-- Remove existing click detectors
	for _, obj in pairs(self.Models.Cow:GetDescendants()) do
		if obj:IsA("ClickDetector") then
			obj:Destroy()
		end
	end

	-- Add new click detector
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 15
	clickDetector.Parent = self.Models.Cow:FindFirstChild("HumanoidRootPart") or self.Models.Cow

	clickDetector.MouseClick:Connect(function(player)
		self:HandleMilkCollection(player)
	end)

	print("GameCore: Enhanced cow interaction setup complete")
end

function GameCore:HandleMilkCollection(player)
	print("🥛 GameCore: ENHANCED milk collection for " .. player.Name)

	local currentTime = os.time()
	local playerData = self:GetPlayerData(player)

	if not playerData then
		warn("🥛 GameCore: No player data found for " .. player.Name)
		return false
	end

	-- Initialize inventories
	self:InitializePlayerInventories(playerData)

	-- Check cooldown
	local userId = player.UserId
	local lastCollection = self.Systems.Livestock.CowCooldowns[userId] or 0

	local cooldown = 10 -- 10 seconds default
	local timeSinceCollection = currentTime - lastCollection

	if timeSinceCollection < cooldown then
		local timeLeft = cooldown - timeSinceCollection
		self:SendNotification(player, "🐄 Cow Resting", 
			"The cow needs " .. math.ceil(timeLeft) .. " more seconds to produce milk!", "warning")
		return false
	end

	-- Calculate milk amount (with upgrades if available)
	local milkAmount = 2

	-- Add milk to LIVESTOCK INVENTORY (correct location!)
	local currentMilk = playerData.livestock.inventory.milk or 0
	playerData.livestock.inventory.milk = currentMilk + milkAmount

	-- Also add to direct milk property for compatibility
	playerData.milk = (playerData.milk or 0) + milkAmount

	print("✅ Added " .. milkAmount .. " milk to livestock.inventory and direct property")

	-- Update cooldown tracking
	self.Systems.Livestock.CowCooldowns[userId] = currentTime

	-- Update stats
	playerData.stats.milkCollected = (playerData.stats.milkCollected or 0) + milkAmount

	-- Save and update
	self:SavePlayerData(player)
	self:UpdatePlayerLeaderstats(player)

	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	self:SendNotification(player, "🥛 Milk Collected!", 
		"Collected " .. milkAmount .. " fresh milk! Sell it in the shop for coins.", "success")

	return true
end

function GameCore:HandlePigFeeding(player, cropId)
	local playerData = self:GetPlayerData(player)
	if not playerData then return end

	-- Initialize inventories
	self:InitializePlayerInventories(playerData)

	-- Check if player has the crop in farming inventory
	if not playerData.farming or not playerData.farming.inventory then
		self:SendNotification(player, "No Crops", "You don't have any crops to feed!", "error")
		return
	end

	local cropCount = playerData.farming.inventory[cropId] or 0
	if cropCount <= 0 then
		local cropData = ItemConfig.GetCropData and ItemConfig.GetCropData(cropId)
		local cropName = cropData and cropData.name or cropId
		self:SendNotification(player, "No Crops", "You don't have any " .. cropName .. "!", "error")
		return
	end

	-- Get crop data
	local cropData = ItemConfig.GetCropData and ItemConfig.GetCropData(cropId)
	if not cropData or not cropData.cropPoints then
		self:SendNotification(player, "Invalid Crop", "This crop cannot be fed to the pig!", "error")
		return
	end

	-- Feed the pig
	playerData.farming.inventory[cropId] = playerData.farming.inventory[cropId] - 1
	if playerData.farming.inventory[cropId] <= 0 then
		playerData.farming.inventory[cropId] = nil
	end

	local cropPoints = cropData.cropPoints

	playerData.livestock.pig.cropPoints = playerData.livestock.pig.cropPoints + cropPoints
	playerData.livestock.pig.totalFed = playerData.livestock.pig.totalFed + 1

	-- Calculate new pig size
	local newSize = 1.0 + (playerData.livestock.pig.cropPoints * 0.01)
	playerData.livestock.pig.size = math.min(newSize, 3.0)

	-- Check for MEGA PIG transformation
	local pointsNeeded = 100 + (playerData.livestock.pig.transformationCount * 50)
	local message = "Fed pig with " .. cropData.name .. "! (" .. playerData.livestock.pig.cropPoints .. "/" .. pointsNeeded .. " points for MEGA PIG)"

	if playerData.livestock.pig.cropPoints >= pointsNeeded then
		message = self:TriggerMegaPigTransformation(player, playerData)
	end

	-- Save and notify
	self:SavePlayerData(player)
	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	self:SendNotification(player, "Pig Fed!", message, "success")
end

-- ========== DATA MANAGEMENT ==========

function GameCore:GetDefaultPlayerData()
	return {
		-- Core Currency
		coins = 100,
		farmTokens = 0,

		-- Core Systems
		farming = {
			plots = 0,
			inventory = {} -- Seeds and crops
		},

		livestock = {
			cows = {},
			pig = {
				size = 1.0,
				cropPoints = 0,
				transformationCount = 0,
				totalFed = 0
			},
			inventory = {} -- Milk, eggs, animal products
		},

		inventory = {}, -- General items, tools

		defense = {
			chickens = {
				owned = {},
				deployed = {},
				feed = {} -- Chicken feed
			},
			pestControl = {}, -- Pesticides
			roofs = {}
		},

		mining = {
			tools = {},
			inventory = {}, -- Ores
			level = 1,
			xp = 0
		},

		buildings = {},
		upgrades = {},
		purchaseHistory = {},

		-- Direct milk property for compatibility
		milk = 0,

		-- Boosters and Enhancements
		boosters = {},

		-- Statistics
		stats = {
			milkCollected = 0,
			coinsEarned = 100,
			cropsHarvested = 0,
			rareCropsHarvested = 0,
			pigFed = 0,
			megaTransformations = 0,
			seedsPlanted = 0,
			pestsEliminated = 0
		},

		-- Session Data
		firstJoin = os.time(),
		lastSave = os.time()
	}
end

function GameCore:GetPlayerData(player)
	if not self.PlayerData[player.UserId] then
		self:LoadPlayerData(player)
	end
	return self.PlayerData[player.UserId]
end

function GameCore:LoadPlayerData(player)
	local userId = player.UserId
	local defaultData = self:GetDefaultPlayerData()

	if not self.PlayerDataStore then
		print("⚠️ DataStore not available - using default data for " .. player.Name)
		self.PlayerData[userId] = defaultData
		self:InitializePlayerInventories(defaultData)
		self:UpdatePlayerLeaderstats(player)
		return defaultData
	end

	print("📥 Loading data for " .. player.Name .. "...")

	local success, data = pcall(function()
		return self.PlayerDataStore:GetAsync("Player_" .. userId)
	end)

	local loadedData = defaultData

	if success and data then
		-- Deep merge loaded data with defaults
		loadedData = self:DeepMerge(defaultData, data)
		print("✅ Loaded existing data for " .. player.Name)
	else
		print("📝 Using default data for " .. player.Name .. " (first time or load failed)")
	end

	-- Ensure all inventory structures are properly initialized
	self:InitializePlayerInventories(loadedData)

	self.PlayerData[userId] = loadedData
	self:UpdatePlayerLeaderstats(player)

	return loadedData
end

function GameCore:SavePlayerData(player, forceImmediate)
	if not player or not player.Parent then return end

	local userId = player.UserId
	local currentTime = os.time()

	-- Check cooldown
	if not forceImmediate then
		local lastSave = self.DataStoreCooldowns[userId] or 0
		local timeSinceLastSave = currentTime - lastSave

		if timeSinceLastSave < self.SAVE_COOLDOWN then
			return false
		end
	end

	local playerData = self.PlayerData[userId]
	if not playerData then 
		warn("No player data to save for " .. player.Name)
		return false
	end

	print("💾 Saving data for " .. player.Name)

	local success, result = pcall(function()
		return self.PlayerDataStore:SetAsync("Player_" .. userId, playerData)
	end)

	if success then
		self.DataStoreCooldowns[userId] = currentTime
		print("✅ Successfully saved data for " .. player.Name)
	else
		warn("❌ Failed to save data for " .. player.Name .. ": " .. tostring(result))
	end

	return success
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

-- ========== FARM PLOT MANAGEMENT ==========

function GameCore:CreatePlayerFarmPlot(player, plotNumber)
	plotNumber = plotNumber or 1

	local plotCFrame = self:GetFarmPlotPosition(player, plotNumber)
	if not plotCFrame then
		warn("GameCore: Could not get farm plot position for " .. player.Name .. " plot " .. plotNumber)
		return false
	end

	-- Find or create the farm area structure
	local areas = workspace:FindFirstChild("Areas")
	if not areas then
		areas = Instance.new("Folder")
		areas.Name = "Areas"
		areas.Parent = workspace
	end

	local starterMeadow = areas:FindFirstChild("Starter Meadow")
	if not starterMeadow then
		starterMeadow = Instance.new("Model")
		starterMeadow.Name = "Starter Meadow"
		starterMeadow.Parent = areas
	end

	local farmArea = starterMeadow:FindFirstChild("Farm")
	if not farmArea then
		farmArea = Instance.new("Folder")
		farmArea.Name = "Farm"
		farmArea.Parent = starterMeadow
	end

	-- Create player-specific farm folder
	local playerFarmName = player.Name .. "_Farm"
	local playerFarm = farmArea:FindFirstChild(playerFarmName)
	if not playerFarm then
		playerFarm = Instance.new("Folder")
		playerFarm.Name = playerFarmName
		playerFarm.Parent = farmArea
	end

	-- Check if plot already exists
	local plotName = "FarmPlot_" .. plotNumber
	local existingPlot = playerFarm:FindFirstChild(plotName)
	if existingPlot then
		if existingPlot.PrimaryPart then
			existingPlot:SetPrimaryPartCFrame(plotCFrame)
		end
		print("GameCore: Updated position for existing " .. plotName .. " for " .. player.Name)
		return true
	end

	-- Create the farm plot model with enhanced structure
	local farmPlot = Instance.new("Model")
	farmPlot.Name = plotName
	farmPlot.Parent = playerFarm

	-- Create the base platform
	local basePart = Instance.new("Part")
	basePart.Name = "BasePart"
	basePart.Size = Vector3.new(16, 1, 16)
	basePart.Material = Enum.Material.Ground
	basePart.Color = Color3.fromRGB(101, 67, 33)
	basePart.Anchored = true
	basePart.CFrame = plotCFrame
	basePart.Parent = farmPlot

	farmPlot.PrimaryPart = basePart

	-- Create planting spots (3x3 grid)
	local plantingSpots = Instance.new("Folder")
	plantingSpots.Name = "PlantingSpots"
	plantingSpots.Parent = farmPlot

	local spotSize = 4
	local spacing = 5

	for row = 1, 3 do
		for col = 1, 3 do
			local spotIndex = (row - 1) * 3 + col
			local spotName = "PlantingSpot_" .. spotIndex

			local spotModel = Instance.new("Model")
			spotModel.Name = spotName
			spotModel.Parent = plantingSpots

			local offsetX = (col - 2) * spacing
			local offsetZ = (row - 2) * spacing

			local spotPart = Instance.new("Part")
			spotPart.Name = "SpotPart"
			spotPart.Size = Vector3.new(spotSize, 0.2, spotSize)
			spotPart.Material = Enum.Material.LeafyGrass
			spotPart.Color = Color3.fromRGB(91, 154, 76)
			spotPart.Anchored = true
			spotPart.CFrame = plotCFrame + Vector3.new(offsetX, 1, offsetZ)
			spotPart.Parent = spotModel

			spotModel.PrimaryPart = spotPart

			-- Add attributes for farming system
			spotModel:SetAttribute("IsEmpty", true)
			spotModel:SetAttribute("PlantType", "")
			spotModel:SetAttribute("SeedType", "")
			spotModel:SetAttribute("GrowthStage", 0)
			spotModel:SetAttribute("PlantedTime", 0)
			spotModel:SetAttribute("Rarity", "common")

			-- Create visual indicator
			local indicator = Instance.new("Part")
			indicator.Name = "Indicator"
			indicator.Size = Vector3.new(0.5, 2, 0.5)
			indicator.Material = Enum.Material.Neon
			indicator.Color = Color3.fromRGB(100, 255, 100)
			indicator.Anchored = true
			indicator.CFrame = spotPart.CFrame + Vector3.new(0, 1.5, 0)
			indicator.Parent = spotModel

			-- Add click detector for planting
			local clickDetector = Instance.new("ClickDetector")
			clickDetector.MaxActivationDistance = 10
			clickDetector.Parent = spotPart

			clickDetector.MouseClick:Connect(function(clickingPlayer)
				if clickingPlayer.UserId == player.UserId then
					self:HandlePlotClick(clickingPlayer, spotModel)
				end
			end)
		end
	end

	print("GameCore: Created " .. plotName .. " for " .. player.Name)
	return true
end

function GameCore:GetFarmPlotPosition(player, plotNumber)
	plotNumber = plotNumber or 1

	if plotNumber < 1 or plotNumber > 10 then
		warn("GameCore: Invalid plot number " .. plotNumber .. ". Must be between 1 and 10.")
		plotNumber = 1
	end

	-- Get player index for farm separation
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

	-- Calculate position
	local basePos = self.FarmPlotPositions.basePosition
	local playerOffset = self.FarmPlotPositions.playerSeparation * playerIndex
	local playerBasePosition = basePos + playerOffset
	local plotOffset = self.FarmPlotPositions.plotOffsets[plotNumber] or Vector3.new(0, 0, 0)
	local finalPosition = playerBasePosition + plotOffset

	local rotation = self.FarmPlotPositions.plotRotation
	local cframe = CFrame.new(finalPosition) * CFrame.Angles(
		math.rad(rotation.X), 
		math.rad(rotation.Y), 
		math.rad(rotation.Z)
	)

	return cframe
end

function GameCore:HandlePlotClick(player, spotModel)
	local isEmpty = spotModel:GetAttribute("IsEmpty")
	if not isEmpty then
		-- Check if crop is ready for harvest
		local growthStage = spotModel:GetAttribute("GrowthStage") or 0
		if growthStage >= 4 then
			self:HarvestCrop(player, spotModel)
		else
			self:SendNotification(player, "Crop Growing", "This crop is still growing! Wait for it to be ready.", "info")
		end
		return
	end

	local plotOwner = self:GetPlotOwner(spotModel)
	if plotOwner ~= player.Name then
		self:SendNotification(player, "Not Your Plot", "You can only plant on your own farm plots!", "error")
		return
	end

	local playerData = self:GetPlayerData(player)
	if not playerData or not playerData.farming or not playerData.farming.inventory then
		self:SendNotification(player, "No Farming Data", "You need to set up farming first! Visit the shop.", "warning")
		return
	end

	local hasSeeds = false
	for itemId, qty in pairs(playerData.farming.inventory) do
		if itemId:find("_seeds") and qty > 0 then
			hasSeeds = true
			break
		end
	end
	if not hasSeeds then
		self:SendNotification(player, "No Seeds", "You don't have any seeds! Buy some from the shop first.", "warning")
		return
	end

	-- Send to client for seed selection
	self.RemoteEvents.PlantSeed:FireClient(player, spotModel)
end

function GameCore:GetPlotOwner(plotModel)
	local parent = plotModel.Parent
	local attempts = 0

	while parent and parent.Parent and attempts < 10 do
		attempts = attempts + 1

		if parent.Name:find("_Farm") then
			return parent.Name:gsub("_Farm", "")
		end

		if parent.Name:find("Farm") and parent.Parent and parent.Parent.Name:find("_Farm") then
			return parent.Parent.Name:gsub("_Farm", "")
		end

		parent = parent.Parent
	end

	warn("GameCore: Could not determine plot owner for " .. plotModel.Name)
	return nil
end

-- ========== UTILITY FUNCTIONS ==========

function GameCore:GetPlayerBoosters(playerData)
	local boosters = {}

	if playerData.boosters then
		if playerData.boosters.rarity_booster and playerData.boosters.rarity_booster > 0 then
			boosters.rarity_booster = true
		end
	end

	return boosters
end

function GameCore:CreateCropOnPlot(plotModel, seedId, seedData, cropRarity)
	-- Basic crop creation - simplified for this fixed version
	-- (Keep your existing implementation or use a simplified version)
	return true
end

function GameCore:GetCropTimeRemaining(plotModel)
	local plantedTime = plotModel:GetAttribute("PlantedTime") or 0
	local seedType = plotModel:GetAttribute("SeedType") or ""

	if plantedTime == 0 or seedType == "" then return 0 end

	local seedData = ItemConfig.GetSeedData(seedType)
	if not seedData then return 0 end

	local elapsedTime = os.time() - plantedTime
	local totalGrowTime = seedData.growTime

	return math.max(0, totalGrowTime - elapsedTime)
end

function GameCore:TriggerMegaPigTransformation(player, playerData)
	-- Keep your existing implementation
	return "🎉 MEGA PIG TRANSFORMATION! 🎉"
end

function GameCore:SendNotification(player, title, message, notificationType)
	if self.RemoteEvents.ShowNotification then
		self.RemoteEvents.ShowNotification:FireClient(player, title, message, notificationType or "info")
	else
		print("NOTIFICATION for " .. player.Name .. ": [" .. (notificationType or "info"):upper() .. "] " .. title .. " - " .. message)
	end
end

function GameCore:CreatePlayerLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = self.PlayerData[player.UserId].coins
	coins.Parent = leaderstats

	local farmTokens = Instance.new("IntValue")
	farmTokens.Name = "Farm Tokens"
	farmTokens.Value = self.PlayerData[player.UserId].farmTokens or 0
	farmTokens.Parent = leaderstats
end

function GameCore:UpdatePlayerLeaderstats(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then 
		self:CreatePlayerLeaderstats(player)
		return
	end

	local playerData = self.PlayerData[player.UserId]
	if not playerData then return end

	local coins = leaderstats:FindFirstChild("Coins")
	if coins then coins.Value = playerData.coins end

	local farmTokens = leaderstats:FindFirstChild("Farm Tokens")
	if farmTokens then farmTokens.Value = playerData.farmTokens or 0 end
end

function GameCore:StartUpdateLoops()
	print("GameCore: Starting update loops...")

	-- Auto-save loop
	spawn(function()
		while true do
			wait(300) -- Save every 5 minutes
			for _, player in ipairs(Players:GetPlayers()) do
				if player and player.Parent and self.PlayerData[player.UserId] then
					pcall(function()
						self:SavePlayerData(player)
					end)
				end
			end
		end
	end)
end

-- ========== PLAYER EVENTS ==========

Players.PlayerAdded:Connect(function(player)
	GameCore:LoadPlayerData(player)
	GameCore:CreatePlayerLeaderstats(player)
end)

Players.PlayerRemoving:Connect(function(player)
	GameCore:SavePlayerData(player, true)
	-- Clean up cooldowns
	GameCore.Systems.Livestock.CowCooldowns[player.UserId] = nil
	GameCore.Systems.Livestock.PigStates[player.UserId] = nil
end)

-- ========== DEBUG COMMANDS ==========

game:GetService("Players").PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.Name == "TommySalami311" then -- Replace with your username
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/debuginventory" then
				local playerData = GameCore:GetPlayerData(player)
				if playerData then
					print("=== INVENTORY DEBUG FOR " .. player.Name .. " ===")
					print("Farming inventory:")
					for itemId, amount in pairs(playerData.farming.inventory or {}) do
						print("  " .. itemId .. ": " .. amount)
					end
					print("Livestock inventory:")
					for itemId, amount in pairs(playerData.livestock.inventory or {}) do
						print("  " .. itemId .. ": " .. amount)
					end
					print("General inventory:")
					for itemId, amount in pairs(playerData.inventory or {}) do
						print("  " .. itemId .. ": " .. amount)
					end
					print("Direct milk: " .. (playerData.milk or 0))
					print("===============================")
				end

			elseif command == "/givecrops" then
				local playerData = GameCore:GetPlayerData(player)
				if playerData then
					GameCore:InitializePlayerInventories(playerData)

					local testCrops = {"carrot", "corn", "strawberry", "wheat", "potato"}
					for _, crop in ipairs(testCrops) do
						playerData.farming.inventory[crop] = (playerData.farming.inventory[crop] or 0) + 10
					end

					-- Also give some milk
					playerData.livestock.inventory.milk = (playerData.livestock.inventory.milk or 0) + 5
					playerData.milk = (playerData.milk or 0) + 5

					print("Gave test items to " .. player.Name)
					GameCore:SavePlayerData(player)
				end

			elseif command == "/givemilk" then
				local amount = tonumber(args[2]) or 5
				local playerData = GameCore:GetPlayerData(player)
				if playerData then
					GameCore:InitializePlayerInventories(playerData)
					playerData.livestock.inventory.milk = (playerData.livestock.inventory.milk or 0) + amount
					playerData.milk = (playerData.milk or 0) + amount
					print("Gave " .. amount .. " milk to " .. player.Name)
					GameCore:SavePlayerData(player)
				end
			end
		end
	end)
end)

-- Make globally available
_G.GameCore = GameCore

print("GameCore: ✅ FIXED enhanced inventory management system loaded!")
print("🏪 Features:")
print("  📦 Proper inventory location management")
print("  🌾 Crops stored in farming.inventory")
print("  🥛 Milk stored in livestock.inventory") 
print("  ⛏️ Ores stored in mining.inventory")
print("  🛡️ Defense items in proper locations")
print("  🔍 Enhanced debugging tools")
print("")
print("🔧 Debug Commands:")
print("  /debuginventory - Show all inventory contents")
print("  /givecrops - Give test crops for selling")
print("  /givemilk [amount] - Give milk for testing")

return GameCore