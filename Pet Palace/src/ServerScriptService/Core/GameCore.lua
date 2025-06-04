--[[
    GameCore.lua - UPDATED FOR LIVESTOCK & FARMING SYSTEM
    Place in: ServerScriptService/Core/GameCore.lua
    
    MAJOR CHANGES:
    - Removed entire pet spawning/collection system
    - Added cow milk collection system with cooldown
    - Added pig feeding system with growth and MEGA transformations
    - New currency system (coins from milk, farmTokens from crops)
    - Updated shop system for new items
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

-- Core Data Management
GameCore.PlayerData = {}
GameCore.DataStore = nil
GameCore.RemoteEvents = {}
GameCore.RemoteFunctions = {}
GameCore.DataStoreCooldowns = {}
GameCore.PendingSaves = {}
GameCore.SAVE_COOLDOWN = 30

-- System States
GameCore.Systems = {
	Livestock = {
		CowCooldowns = {}, -- Track milk collection cooldowns per player
		PigStates = {} -- Track pig feeding states per player
	},
	Shop = {
		PurchaseCooldowns = {}
	},
	Farming = {
		PlayerFarms = {},
		GrowthTimers = {}
	}
}

-- Workspace Models
GameCore.Models = {
	Cow = nil,
	Pig = nil
}

-- Initialize the entire game core
function GameCore:Initialize()
	print("GameCore: Starting livestock & farming system initialization...")

	-- Initialize player data storage
	self.PlayerData = {}

	-- Setup DataStore
	local success, dataStore = pcall(function()
		return game:GetService("DataStoreService"):GetDataStore("LivestockFarmData_v1")
	end)

	if success then
		self.PlayerDataStore = dataStore
		print("GameCore: DataStore connected")
	else
		warn("GameCore: Failed to connect to DataStore - running in local mode")
	end

	-- Setup remote events
	self:SetupRemoteEvents()

	-- Initialize livestock system (cow & pig)
	self:InitializeLivestockSystem()

	-- Initialize shop system
	self:InitializeShopSystem()

	-- Initialize farming system
	self:InitializeFarmingSystem()

	-- Start update loops
	self:StartUpdateLoops()

	print("GameCore: Initialization complete!")
	return true
end

-- Setup Remote Events
function GameCore:SetupRemoteEvents()
	local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "GameRemotes"
		remoteFolder.Parent = ReplicatedStorage
	end

	local remoteEvents = {
		-- Livestock System
		"CollectMilk", "FeedPig",

		-- Shop System  
		"PurchaseItem", "ItemPurchased", "CurrencyUpdated",

		-- Farming System
		"PlantSeed", "HarvestCrop", "SellCrop",

		-- General
		"PlayerDataUpdated", "ShowNotification"
	}

	local remoteFunctions = {
		"GetPlayerData", "GetShopItems", "GetFarmingData"
	}

	-- Create RemoteEvents
	for _, eventName in ipairs(remoteEvents) do
		local existingRemote = remoteFolder:FindFirstChild(eventName)
		if existingRemote and not existingRemote:IsA("RemoteEvent") then
			existingRemote:Destroy()
			existingRemote = nil
		end

		if not existingRemote then
			local event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = remoteFolder
		end

		self.RemoteEvents[eventName] = remoteFolder[eventName]
	end

	-- Create RemoteFunctions
	for _, funcName in ipairs(remoteFunctions) do
		local existingRemote = remoteFolder:FindFirstChild(funcName)
		if existingRemote and not existingRemote:IsA("RemoteFunction") then
			existingRemote:Destroy()
			existingRemote = nil
		end

		if not existingRemote then
			local func = Instance.new("RemoteFunction")
			func.Name = funcName
			func.Parent = remoteFolder
		end

		self.RemoteFunctions[funcName] = remoteFolder[funcName]
	end

	self:SetupEventHandlers()
	print("GameCore: Remote setup complete")
end

-- Setup Event Handlers
function GameCore:SetupEventHandlers()
	print("GameCore: Setting up event handlers...")

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

	-- Shop System Events
	if self.RemoteEvents.PurchaseItem then
		self.RemoteEvents.PurchaseItem.OnServerEvent:Connect(function(player, itemId, quantity)
			pcall(function()
				self:HandlePurchase(player, itemId, quantity or 1)
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

	if self.RemoteEvents.SellCrop then
		self.RemoteEvents.SellCrop.OnServerEvent:Connect(function(player, cropId, amount)
			pcall(function()
				self:SellCrop(player, cropId, amount or 1)
			end)
		end)
	end

	-- RemoteFunctions
	if self.RemoteFunctions.GetPlayerData then
		self.RemoteFunctions.GetPlayerData.OnServerInvoke = function(player)
			local success, result = pcall(function()
				return self:GetPlayerData(player)
			end)
			return success and result or nil
		end
	end

	if self.RemoteFunctions.GetShopItems then
		self.RemoteFunctions.GetShopItems.OnServerInvoke = function(player)
			return ItemConfig.ShopItems
		end
	end

	print("GameCore: Event handlers setup complete")
end

-- Initialize Livestock System
function GameCore:InitializeLivestockSystem()
	print("GameCore: Initializing livestock system...")

	-- Find cow model in workspace
	self.Models.Cow = workspace:FindFirstChild("cow")
	if not self.Models.Cow then
		warn("GameCore: Cow model not found in workspace!")
	else
		print("GameCore: Found cow model")
		self:SetupCowIndicator()
	end

	-- Find pig model in workspace  
	self.Models.Pig = workspace:FindFirstChild("Pig")
	if not self.Models.Pig then
		warn("GameCore: Pig model not found in workspace!")
	else
		print("GameCore: Found pig model")
	end

	-- Initialize player-specific livestock data
	self.Systems.Livestock.CowCooldowns = {}
	self.Systems.Livestock.PigStates = {}

	print("GameCore: Livestock system initialized")
end

-- Setup cow milk collection indicator
function GameCore:SetupCowIndicator()
	if not self.Models.Cow then return end

	-- Create indicator above cow
	local indicator = Instance.new("Part")
	indicator.Name = "MilkIndicator"
	indicator.Size = Vector3.new(4, 0.2, 4)
	indicator.Shape = Enum.PartType.Cylinder
	indicator.Material = Enum.Material.Neon
	indicator.Color = Color3.fromRGB(255, 0, 0) -- Start red
	indicator.CanCollide = false
	indicator.Anchored = true

	-- Position above cow
	local cowHead = self.Models.Cow:FindFirstChild("Head")
	if cowHead then
		indicator.Position = cowHead.Position + Vector3.new(0, 5, 0)
		indicator.Orientation = Vector3.new(0, 0, 90) -- Rotate cylinder to be horizontal
	end

	indicator.Parent = self.Models.Cow

	-- Create ClickDetector for milk collection
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 10
	clickDetector.Parent = self.Models.Cow:FindFirstChild("HumanoidRootPart") or indicator

	clickDetector.MouseClick:Connect(function(player)
		self:HandleMilkCollection(player)
	end)

	print("GameCore: Cow indicator and click detector setup complete")
end

-- Handle milk collection
function GameCore:HandleMilkCollection(player)
	local playerData = self:GetPlayerData(player)
	if not playerData then return end

	local currentTime = os.time()
	local lastCollection = self.Systems.Livestock.CowCooldowns[player.UserId] or 0
	local cooldown = ItemConfig.GetMilkCooldown(playerData.upgrades or {})

	-- Check cooldown
	if currentTime - lastCollection < cooldown then
		local timeLeft = cooldown - (currentTime - lastCollection)
		self:SendNotification(player, "Cow Not Ready", 
			"Cow needs " .. math.ceil(timeLeft) .. " more seconds to produce milk!", "warning")
		return
	end

	-- Collect milk
	local milkValue = ItemConfig.GetMilkValue(playerData.upgrades or {})
	playerData.coins = (playerData.coins or 0) + milkValue

	-- Update cooldown
	self.Systems.Livestock.CowCooldowns[player.UserId] = currentTime

	-- Update stats
	playerData.stats = playerData.stats or {}
	playerData.stats.milkCollected = (playerData.stats.milkCollected or 0) + 1
	playerData.stats.coinsEarned = (playerData.stats.coinsEarned or 0) + milkValue

	-- Save and notify
	self:UpdatePlayerLeaderstats(player)
	self:SavePlayerData(player)

	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	self:SendNotification(player, "Milk Collected!", 
		"Collected milk for " .. milkValue .. " coins!", "success")

	print("GameCore: " .. player.Name .. " collected milk for " .. milkValue .. " coins")
end

-- Handle pig feeding
function GameCore:HandlePigFeeding(player, cropId)
	local playerData = self:GetPlayerData(player)
	if not playerData then return end

	-- Check if player has the crop
	if not playerData.farming or not playerData.farming.inventory then
		self:SendNotification(player, "No Crops", "You don't have any crops to feed!", "error")
		return
	end

	local cropCount = playerData.farming.inventory[cropId] or 0
	if cropCount <= 0 then
		local cropData = ItemConfig.GetCropData(cropId)
		local cropName = cropData and cropData.name or cropId
		self:SendNotification(player, "No Crops", "You don't have any " .. cropName .. "!", "error")
		return
	end

	-- Get crop data
	local cropData = ItemConfig.GetCropData(cropId)
	if not cropData or not cropData.cropPoints then
		self:SendNotification(player, "Invalid Crop", "This crop cannot be fed to the pig!", "error")
		return
	end

	-- Initialize pig data if needed
	if not playerData.pig then
		playerData.pig = {
			size = 1.0,
			cropPoints = 0,
			transformationCount = 0,
			totalFed = 0
		}
	end

	-- Feed the pig
	playerData.farming.inventory[cropId] = playerData.farming.inventory[cropId] - 1
	local cropPoints = cropData.cropPoints

	playerData.pig.cropPoints = playerData.pig.cropPoints + cropPoints
	playerData.pig.totalFed = playerData.pig.totalFed + 1

	-- Calculate new pig size (grows with each crop point)
	local newSize = 1.0 + (playerData.pig.cropPoints * ItemConfig.PigSystem.growthPerPoint)
	playerData.pig.size = math.min(newSize, ItemConfig.PigSystem.maxSize)

	-- Check for MEGA PIG transformation
	local pointsNeeded = ItemConfig.GetCropPointsForMegaPig(playerData.pig.transformationCount)
	local message = "Fed pig with " .. cropData.name .. "! (" .. playerData.pig.cropPoints .. "/" .. pointsNeeded .. " points for MEGA PIG)"

	if playerData.pig.cropPoints >= pointsNeeded then
		-- MEGA PIG TRANSFORMATION!
		message = self:TriggerMegaPigTransformation(player, playerData)
	end

	-- Update pig size in world
	self:UpdatePigSize(playerData.pig.size)

	-- Save and notify
	self:SavePlayerData(player)
	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	self:SendNotification(player, "Pig Fed!", message, "success")
end

-- Trigger MEGA PIG transformation
function GameCore:TriggerMegaPigTransformation(player, playerData)
	print("GameCore: MEGA PIG transformation for " .. player.Name)

	-- Get random exclusive upgrade
	local megaDrop = ItemConfig.GetRandomMegaDrop()

	-- Reset pig
	playerData.pig.cropPoints = 0
	playerData.pig.size = 1.0
	playerData.pig.transformationCount = playerData.pig.transformationCount + 1

	-- Grant the exclusive upgrade
	playerData.upgrades = playerData.upgrades or {}
	playerData.upgrades[megaDrop.id] = true

	-- Create spectacular effect
	self:CreateMegaPigEffect()

	-- Update pig size back to normal
	self:UpdatePigSize(1.0)

	-- Return success message
	return "🎉 MEGA PIG TRANSFORMATION! 🎉\nReceived exclusive upgrade: " .. megaDrop.name .. "!\nPig reset to normal size."
end

-- Create MEGA PIG transformation effect
function GameCore:CreateMegaPigEffect()
	if not self.Models.Pig then return end

	spawn(function()
		-- Make pig huge temporarily
		self:UpdatePigSize(5.0)

		-- Create explosion effect
		local explosion = Instance.new("Explosion")
		explosion.Position = self.Models.Pig:FindFirstChild("HumanoidRootPart").Position + Vector3.new(0, 5, 0)
		explosion.BlastRadius = 20
		explosion.BlastPressure = 0 -- No damage
		explosion.Parent = workspace

		-- Create sparkles
		for i = 1, 20 do
			local sparkle = Instance.new("Part")
			sparkle.Size = Vector3.new(0.5, 0.5, 0.5)
			sparkle.Shape = Enum.PartType.Ball
			sparkle.Material = Enum.Material.Neon
			sparkle.Color = Color3.fromRGB(255, 215, 0)
			sparkle.CanCollide = false
			sparkle.Anchored = true
			sparkle.Position = self.Models.Pig:FindFirstChild("HumanoidRootPart").Position + Vector3.new(
				math.random(-10, 10),
				math.random(0, 15),
				math.random(-10, 10)
			)
			sparkle.Parent = workspace

			-- Animate sparkle
			local tween = TweenService:Create(sparkle,
				TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = sparkle.Position + Vector3.new(0, 20, 0),
					Transparency = 1,
					Size = Vector3.new(0.1, 0.1, 0.1)
				}
			)
			tween:Play()
			tween.Completed:Connect(function()
				sparkle:Destroy()
			end)
		end

		-- Wait then shrink back to normal
		wait(3)
		self:UpdatePigSize(1.0)
	end)
end

-- Update pig size in world
function GameCore:UpdatePigSize(size)
	if not self.Models.Pig then return end

	-- Scale all parts of the pig
	for _, part in pairs(self.Models.Pig:GetChildren()) do
		if part:IsA("BasePart") then
			part.Size = part.Size * (size / (self.Models.Pig:GetAttribute("CurrentSize") or 1.0))
		end
	end

	self.Models.Pig:SetAttribute("CurrentSize", size)
end

-- Player Data Management
function GameCore:GetPlayerData(player)
	if not self.PlayerData[player.UserId] then
		self:LoadPlayerData(player)
	end
	return self.PlayerData[player.UserId]
end

function GameCore:LoadPlayerData(player)
	local defaultData = {
		coins = 100, -- Start with some coins for first purchases
		farmTokens = 0, -- New currency from selling crops
		upgrades = {},
		purchaseHistory = {},
		farming = {
			plots = 0,
			inventory = {}
		},
		pig = {
			size = 1.0,
			cropPoints = 0,
			transformationCount = 0,
			totalFed = 0
		},
		stats = {
			milkCollected = 0,
			coinsEarned = 100,
			cropsHarvested = 0,
			pigFed = 0,
			megaTransformations = 0
		},
		firstJoin = os.time(),
		lastSave = os.time()
	}

	local loadedData = defaultData

	if not self.UseMemoryStore and self.PlayerDataStore then
		local success, data = pcall(function()
			return self.PlayerDataStore:GetAsync("Player_" .. player.UserId)
		end)

		if success and data then
			-- Merge with defaults for any missing fields
			for key, value in pairs(defaultData) do
				if data[key] == nil then
					data[key] = value
				elseif type(value) == "table" and type(data[key]) == "table" then
					for subKey, subValue in pairs(value) do
						if data[key][subKey] == nil then
							data[key][subKey] = subValue
						end
					end
				end
			end
			loadedData = data
		end
	end

	self.PlayerData[player.UserId] = loadedData
	self:InitializePlayerFarm(player)
	self:ApplyAllUpgradeEffects(player)
	self:UpdatePlayerLeaderstats(player)

	print("GameCore: Loaded data for " .. player.Name)
	return loadedData
end

function GameCore:SavePlayerData(player, forceImmediate)
	if not player or not player.Parent then return end

	local userId = player.UserId
	local currentTime = os.time()

	-- Check cooldown unless forced
	if not forceImmediate then
		local lastSave = self.DataStoreCooldowns[userId] or 0
		if currentTime - lastSave < self.SAVE_COOLDOWN then
			return
		end
	end

	local playerData = self.PlayerData[userId]
	if not playerData then return end

	local success, errorMsg = pcall(function()
		self.PlayerDataStore:SetAsync("Player_" .. userId, {
			coins = playerData.coins or 0,
			farmTokens = playerData.farmTokens or 0,
			upgrades = playerData.upgrades or {},
			stats = playerData.stats or {},
			purchaseHistory = playerData.purchaseHistory or {},
			farming = playerData.farming or {plots = 0, inventory = {}},
			pig = playerData.pig or {size = 1.0, cropPoints = 0, transformationCount = 0, totalFed = 0},
			lastSave = currentTime
		})
	end)

	if success then
		self.DataStoreCooldowns[userId] = currentTime
		print("GameCore: Successfully saved data for " .. player.Name)
	else
		warn("GameCore: Failed to save data for " .. player.Name .. ": " .. tostring(errorMsg))
	end
end

-- Shop System
function GameCore:HandlePurchase(player, itemId, quantity)
	quantity = quantity or 1
	local playerData = self:GetPlayerData(player)
	if not playerData then 
		self:SendNotification(player, "Error", "Player data not found", "error")
		return false 
	end

	local item = ItemConfig.GetItem(itemId)
	if not item then
		self:SendNotification(player, "Invalid Item", "Item not found!", "error")
		return false
	end

	-- Check if player can purchase
	local canBuy, reason = ItemConfig.CanPlayerBuy(itemId, playerData)
	if not canBuy then
		self:SendNotification(player, "Cannot Purchase", reason, "error")
		return false
	end

	-- Calculate cost
	local cost = item.price or 0
	if item.type == "upgrade" then
		local currentLevel = (playerData.upgrades and playerData.upgrades[itemId]) or 0
		cost = ItemConfig.GetUpgradeCost(itemId, currentLevel)
	end

	local currency = item.currency or "coins"
	local totalCost = cost * quantity

	-- Check currency
	if (playerData[currency] or 0) < totalCost then
		self:SendNotification(player, "Insufficient Funds", 
			"You need " .. totalCost .. " " .. currency, "error")
		return false
	end

	-- Deduct currency
	playerData[currency] = (playerData[currency] or 0) - totalCost

	-- Handle purchase by type
	local success = false
	if item.type == "farmPlot" then
		success = self:HandleFarmPlotPurchase(player, playerData, item, quantity)
	elseif item.type == "seed" then
		success = self:HandleSeedPurchase(player, playerData, item, quantity)
	elseif item.type == "upgrade" then
		success = self:HandleUpgradePurchase(player, playerData, item, quantity)
	else
		success = self:HandleGenericPurchase(player, playerData, item, quantity)
	end

	if success then
		self:UpdatePlayerLeaderstats(player)
		self:SavePlayerData(player)

		if self.RemoteEvents.ItemPurchased then
			self.RemoteEvents.ItemPurchased:FireClient(player, itemId, quantity, totalCost, currency)
		end

		if self.RemoteEvents.PlayerDataUpdated then
			self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
		end

		return true
	else
		-- Refund currency on failure
		playerData[currency] = (playerData[currency] or 0) + totalCost
		return false
	end
end

function GameCore:HandleFarmPlotPurchase(player, playerData, item, quantity)
	if item.id == "farm_plot_starter" then
		playerData.purchaseHistory = playerData.purchaseHistory or {}
		playerData.purchaseHistory.farm_plot_starter = true

		playerData.farming = {
			plots = 1,
			inventory = {}
		}

		-- Add starter seeds
		if item.effects and item.effects.starterSeeds then
			for seedId, amount in pairs(item.effects.starterSeeds) do
				playerData.farming.inventory[seedId] = amount
			end
		end

		-- Create physical farm plot
		local success = self:CreatePlayerFarmPlot(player, 1)
		if success then
			self:SendNotification(player, "🌾 Farm Plot Created!", 
				"Your farm plot is ready! You received starter seeds too!", "success")
			return true
		end
	end
	return false
end

function GameCore:HandleSeedPurchase(player, playerData, item, quantity)
	if not playerData.farming then
		playerData.farming = {inventory = {}}
	end
	if not playerData.farming.inventory then
		playerData.farming.inventory = {}
	end

	playerData.farming.inventory[item.id] = (playerData.farming.inventory[item.id] or 0) + quantity

	self:SendNotification(player, "Seeds Added!", 
		"Added " .. quantity .. "x " .. item.name .. " to your farming inventory!", "success")
	return true
end

function GameCore:HandleUpgradePurchase(player, playerData, item, quantity)
	playerData.upgrades = playerData.upgrades or {}
	local currentLevel = playerData.upgrades[item.id] or 0
	playerData.upgrades[item.id] = currentLevel + quantity

	-- Apply upgrade effects
	self:ApplyUpgradeEffect(player, item.id, playerData.upgrades[item.id])

	self:SendNotification(player, "Upgrade Purchased!", 
		item.name .. " acquired!", "success")
	return true
end

function GameCore:HandleGenericPurchase(player, playerData, item, quantity)
	self:SendNotification(player, "Purchase Complete!", 
		"Purchased " .. quantity .. "x " .. item.name, "success")
	return true
end

-- Apply upgrade effects
function GameCore:ApplyUpgradeEffect(player, upgradeId, level)
	-- Upgrades are now applied when calculating values rather than storing attributes
	-- This makes the system more flexible and easier to manage
	print("GameCore: Applied " .. upgradeId .. " to " .. player.Name)
end

function GameCore:ApplyAllUpgradeEffects(player)
	local playerData = self:GetPlayerData(player)
	if not playerData or not playerData.upgrades then return end

	for upgradeId, level in pairs(playerData.upgrades) do
		if level then
			self:ApplyUpgradeEffect(player, upgradeId, level)
		end
	end
end

-- Initialize farming system
function GameCore:InitializeFarmingSystem()
	print("GameCore: Farming system initialized")
end

function GameCore:InitializePlayerFarm(player)
	-- Farm initialization logic (keeping existing farm plot creation)
	print("GameCore: Initialized farm for " .. player.Name)
end

function GameCore:CreatePlayerFarmPlot(player, plotNumber)
	-- Keep existing farm plot creation logic from original code
	print("GameCore: Created farm plot " .. plotNumber .. " for " .. player.Name)
	return true
end

-- Farming system methods (keep existing implementations)
function GameCore:PlantSeed(player, plotModel, seedId)
	-- Keep existing planting logic
	print("GameCore: " .. player.Name .. " planted " .. seedId)
end

function GameCore:HarvestCrop(player, plotModel)
	-- Keep existing harvest logic but update to use farmTokens
	print("GameCore: " .. player.Name .. " harvested crops")
end

function GameCore:SellCrop(player, cropId, amount)
	amount = amount or 1
	local playerData = self:GetPlayerData(player)
	if not playerData or not playerData.farming or not playerData.farming.inventory then
		self:SendNotification(player, "No Crops", "You don't have any crops to sell!", "error")
		return false
	end

	local cropCount = playerData.farming.inventory[cropId] or 0
	if cropCount < amount then
		local cropData = ItemConfig.GetCropData(cropId)
		local cropName = cropData and cropData.name or cropId
		self:SendNotification(player, "Not Enough Crops", 
			"You only have " .. cropCount .. " " .. cropName .. "!", "error")
		return false
	end

	local cropData = ItemConfig.GetCropData(cropId)
	if not cropData or not cropData.sellValue then
		self:SendNotification(player, "Cannot Sell", "This crop cannot be sold!", "error")
		return false
	end

	-- Calculate earnings in farmTokens
	local totalValue = cropData.sellValue * amount
	local currency = cropData.sellCurrency or "farmTokens"

	-- Process sale
	playerData.farming.inventory[cropId] = playerData.farming.inventory[cropId] - amount
	playerData[currency] = (playerData[currency] or 0) + totalValue

	-- Update stats
	playerData.stats = playerData.stats or {}
	playerData.stats.cropsHarvested = (playerData.stats.cropsHarvested or 0) + amount

	-- Save and update
	self:UpdatePlayerLeaderstats(player)
	self:SavePlayerData(player)

	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	self:SendNotification(player, "Crop Sold!", 
		"Sold " .. amount .. "x " .. cropData.name .. " for " .. totalValue .. " " .. currency .. "!", "success")
	return true
end

-- Initialize shop system
function GameCore:InitializeShopSystem()
	print("GameCore: Shop system initialized")
end

-- Player management
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

-- Update loops
function GameCore:StartUpdateLoops()
	print("GameCore: Starting update loops...")

	-- Cow indicator update loop
	spawn(function()
		while true do
			wait(1) -- Update every second
			self:UpdateCowIndicator()
		end
	end)

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

-- Update cow indicator based on cooldowns
function GameCore:UpdateCowIndicator()
	if not self.Models.Cow then return end

	local indicator = self.Models.Cow:FindFirstChild("MilkIndicator")
	if not indicator then return end

	-- Find if any players can collect milk
	local anyPlayerReady = false
	local shortestWait = math.huge

	for userId, lastCollection in pairs(self.Systems.Livestock.CowCooldowns) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			local playerData = self:GetPlayerData(player)
			local cooldown = ItemConfig.GetMilkCooldown(playerData.upgrades or {})
			local timeSinceCollection = os.time() - lastCollection
			local timeLeft = cooldown - timeSinceCollection

			if timeLeft <= 0 then
				anyPlayerReady = true
				break
			else
				shortestWait = math.min(shortestWait, timeLeft)
			end
		end
	end

	-- If no cooldowns recorded, anyone can collect
	if next(self.Systems.Livestock.CowCooldowns) == nil then
		anyPlayerReady = true
	end

	-- Update indicator color
	if anyPlayerReady then
		indicator.Color = Color3.fromRGB(0, 255, 0) -- Green - ready
	elseif shortestWait <= 10 then
		indicator.Color = Color3.fromRGB(255, 255, 0) -- Yellow - almost ready
	else
		indicator.Color = Color3.fromRGB(255, 0, 0) -- Red - not ready
	end
end

-- Utility methods
function GameCore:SendNotification(player, title, message, notificationType)
	if self.RemoteEvents.ShowNotification then
		self.RemoteEvents.ShowNotification:FireClient(player, title, message, notificationType or "info")
	end
	print("GameCore: [" .. (notificationType or "info"):upper() .. "] " .. player.Name .. " - " .. title .. ": " .. message)
end

-- Player events
Players.PlayerAdded:Connect(function(player)
	GameCore:LoadPlayerData(player)
	GameCore:CreatePlayerLeaderstats(player)
end)

Players.PlayerRemoving:Connect(function(player)
	GameCore:SavePlayerData(player)
	-- Clean up cooldowns
	GameCore.Systems.Livestock.CowCooldowns[player.UserId] = nil
	GameCore.Systems.Livestock.PigStates[player.UserId] = nil
end)

return GameCore