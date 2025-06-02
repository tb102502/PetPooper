--[[
    GameCore.lua - FIXED VERSION - CRITICAL BUG FIXES
    Place in: ServerScriptService/Core/GameCore.lua
    
    FIXES APPLIED:
    1. ✅ Fixed pet selling values (Common = 25 coins, not 75)
    2. ✅ Removed coin rewards from collecting pets (only selling gives coins)
    3. ✅ Fixed ItemConfig shop items population
    4. ✅ Reduced memory usage by limiting pet spawning
    5. ✅ Only use Starter Meadow area (removed others)
]]

local GameCore = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

-- Load configuration
local ItemConfig = require(script.Parent.Parent:WaitForChild("Config"):WaitForChild("ItemConfig"))

-- Core Data Management
GameCore.PlayerData = {}
GameCore.DataStore = nil
GameCore.RemoteEvents = {}
GameCore.RemoteFunctions = {}

-- System States
GameCore.Systems = {
	Pets = {
		ActivePets = {},
		SpawnAreas = {},
		SpawnTimers = {},
		BehaviorConnections = {},
		NextBehaviorId = 1
	},
	Shop = {
		ActiveBoosters = {},
		PurchaseCooldowns = {}
	},
	Farming = {
		PlayerFarms = {},
		GrowthTimers = {}
	}
}

-- Initialize the entire game core
function GameCore:Initialize()
	print("GameCore: Starting initialization...")

	self:SetupDataStore()
	self:SetupRemoteEvents()
	self:InitializePetSystem()
	self:InitializeShopSystem()
	self:InitializeFarmingSystem()
	self:SetupPlayerEvents()
	self:StartUpdateLoops()
	self:ValidateCustomPetsOnly()

	print("GameCore: All systems initialized successfully!")
	return true
end

-- Data Store Setup
function GameCore:SetupDataStore()
	local success, dataStore = pcall(function()
		return DataStoreService:GetDataStore("PetPalaceData_v4")
	end)

	if success then
		self.DataStore = dataStore
		print("GameCore: DataStore connected")
	else
		warn("GameCore: DataStore failed, using memory storage")
		self.UseMemoryStore = true
	end
end

-- Remote Events Setup
function GameCore:SetupRemoteEvents()
	local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "GameRemotes"
		remoteFolder.Parent = ReplicatedStorage
	end

	local events = {
		"PetCollected", "PetEquipped", "PetUnequipped", "CollectWildPet",
		"PurchaseItem", "CurrencyUpdated", "ItemPurchased",
		"PlantSeed", "HarvestCrop", "FeedPet", "GetFarmingData", "BuySeed",
		"PlayerDataUpdated", "NotificationSent", "UpdatePlayerStats",
		"CollectPet", "SendNotification", "EnableAutoCollect", "UpdateVIPStatus",
		"OpenShopClient", "UpdateShopData", "ShowNotification",
		"SellPet", "SellMultiplePets", "PetSold"
	}

	local functions = {
		"GetPlayerData", "GetShopItems", "GetPetCollection"
	}

	for _, eventName in ipairs(events) do
		local event = remoteFolder:FindFirstChild(eventName)
		if not event then
			event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = remoteFolder
		end
		self.RemoteEvents[eventName] = event
	end

	for _, funcName in ipairs(functions) do
		local func = remoteFolder:FindFirstChild(funcName)
		if not func then
			func = Instance.new("RemoteFunction")
			func.Name = funcName
			func.Parent = remoteFolder
		end
		self.RemoteFunctions[funcName] = func
	end

	self:SetupEventHandlers()
	print("GameCore: Remote events setup complete")
end

-- Event Handlers
function GameCore:SetupEventHandlers()
	-- Pet System Handlers
	self.RemoteEvents.CollectWildPet.OnServerEvent:Connect(function(player, petModel)
		self:HandleWildPetCollection(player, petModel)
	end)

	self.RemoteEvents.SellPet.OnServerEvent:Connect(function(player, petId)
		self:SellPet(player, petId)
	end)

	self.RemoteEvents.SellMultiplePets.OnServerEvent:Connect(function(player, petIds)
		self:SellMultiplePets(player, petIds)
	end)

	-- Shop System Handlers
	self.RemoteEvents.PurchaseItem.OnServerEvent:Connect(function(player, itemId, quantity)
		self:HandlePurchase(player, itemId, quantity or 1)
	end)

	-- Remote Functions
	self.RemoteFunctions.GetPlayerData.OnServerInvoke = function(player)
		return self:GetPlayerData(player)
	end

	-- FIXED: Return actual shop items from ItemConfig
	self.RemoteFunctions.GetShopItems.OnServerInvoke = function(player)
		return ItemConfig.ShopItems
	end

	print("GameCore: Event handlers setup complete")
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
		coins = 500,
		gems = 25,
		pets = {
			owned = {},
			equipped = {}
		},
		upgrades = {},
		purchaseHistory = {},
		farming = {
			plots = 3,
			inventory = {
				carrot_seeds = 10,
				corn_seeds = 5,
				strawberry_seeds = 2
			},
			pig = {
				feedCount = 0,
				size = 1.0
			}
		},
		stats = {
			totalPetsCollected = 0,
			coinsEarned = 500,
			itemsPurchased = 0,
			cropsHarvested = 0,
			petsSold = 0,
			legendaryPetsFound = 0
		},
		firstJoin = os.time(),
		lastSave = os.time()
	}

	local loadedData = defaultData

	if not self.UseMemoryStore then
		local success, data = pcall(function()
			return self.DataStore:GetAsync("Player_" .. player.UserId)
		end)

		if success and data then
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

function GameCore:SavePlayerData(player)
	local data = self.PlayerData[player.UserId]
	if not data then return end

	data.lastSave = os.time()

	if not self.UseMemoryStore then
		spawn(function()
			local success, err = pcall(function()
				self.DataStore:SetAsync("Player_" .. player.UserId, data)
			end)
			if not success then
				warn("GameCore: Save failed for " .. player.Name .. ": " .. tostring(err))
			end
		end)
	end
end

-- FIXED: Pet selling with correct values
function GameCore:SellPet(player, petId)
	local playerData = self:GetPlayerData(player)
	if not playerData or not playerData.pets or not playerData.pets.owned then
		self:SendNotification(player, "Error", "Player data not found", "error")
		return false
	end

	local petToSell = nil
	local petIndex = nil

	for i, pet in ipairs(playerData.pets.owned) do
		if pet.id == petId then
			petToSell = pet
			petIndex = i
			break
		end
	end

	if not petToSell then
		self:SendNotification(player, "Pet Not Found", "Could not find that pet to sell", "error")
		return false
	end

	-- FIXED: Use correct pet sell values from ItemConfig
	local sellValue = self:CalculatePetSellValue(petToSell)

	-- Remove pet from collection
	table.remove(playerData.pets.owned, petIndex)

	-- Add coins to player
	playerData.coins = playerData.coins + sellValue
	playerData.stats.coinsEarned = playerData.stats.coinsEarned + sellValue
	playerData.stats.petsSold = (playerData.stats.petsSold or 0) + 1

	-- Update leaderstats immediately
	self:UpdatePlayerLeaderstats(player)

	-- Fire events
	if self.RemoteEvents.PetSold then
		self.RemoteEvents.PetSold:FireClient(player, petToSell, sellValue)
	end

	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	if self.RemoteEvents.CurrencyUpdated then
		self.RemoteEvents.CurrencyUpdated:FireClient(player, {
			coins = playerData.coins
		})
	end

	-- Send notification
	self:SendNotification(player, "Pet Sold!", 
		"Sold " .. (petToSell.name or "Pet") .. " for " .. sellValue .. " coins", "success")

	-- Save data
	self:SavePlayerData(player)

	print("GameCore: " .. player.Name .. " sold " .. (petToSell.name or petToSell.type) .. " for " .. sellValue .. " coins")
	return true
end

-- FIXED: Calculate correct pet sell values
function GameCore:CalculatePetSellValue(petData)
	-- Use values from ItemConfig.Pets
	local petConfig = ItemConfig.Pets[petData.type]
	if petConfig and petConfig.sellValue then
		local baseValue = petConfig.sellValue
		local level = petData.level or 1
		local levelMultiplier = 1 + ((level - 1) * 0.1)
		return math.floor(baseValue * levelMultiplier)
	end

	-- Fallback to hardcoded values if not in config
	local baseValues = {
		Common = 25,     -- FIXED: Common pets sell for 25 coins
		Uncommon = 75,   
		Rare = 150,      
		Epic = 300,      
		Legendary = 750  
	}

	local baseValue = baseValues[petData.rarity] or baseValues.Common
	local level = petData.level or 1
	local levelMultiplier = 1 + ((level - 1) * 0.1)

	return math.floor(baseValue * levelMultiplier)
end

-- Shop purchase handling
function GameCore:HandlePurchase(player, itemId, quantity)
	local playerData = self:GetPlayerData(player)
	local item = ItemConfig.ShopItems[itemId]

	if not item then
		warn("GameCore: Invalid item ID: " .. itemId)
		self:SendNotification(player, "Error", "Item not found", "error")
		return false
	end

	quantity = quantity or 1
	local totalCost = item.price * quantity
	local currency = item.currency:lower()

	-- Check if player has enough currency
	if not playerData[currency] or playerData[currency] < totalCost then
		self:SendNotification(player, "Insufficient " .. item.currency, 
			"You need " .. totalCost .. " " .. item.currency .. " but only have " .. (playerData[currency] or 0), "error")
		return false
	end

	-- Deduct currency
	playerData[currency] = playerData[currency] - totalCost

	-- Apply item effects
	local success = self:ApplyItemEffects(player, item, quantity)
	if not success then
		-- Refund if item effect failed
		playerData[currency] = playerData[currency] + totalCost
		self:SendNotification(player, "Purchase Failed", "Could not apply item effects", "error")
		return false
	end

	-- Update stats
	playerData.stats.itemsPurchased = (playerData.stats.itemsPurchased or 0) + 1

	-- Update leaderstats immediately
	self:UpdatePlayerLeaderstats(player)

	-- Fire all relevant events
	if self.RemoteEvents.ItemPurchased then
		self.RemoteEvents.ItemPurchased:FireClient(player, itemId, quantity, totalCost, currency)
	end

	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	if self.RemoteEvents.CurrencyUpdated then
		self.RemoteEvents.CurrencyUpdated:FireClient(player, {
			[currency] = playerData[currency]
		})
	end

	-- Send success notification
	self:SendNotification(player, "Purchase Successful!", 
		"Bought " .. quantity .. "x " .. item.name .. " for " .. totalCost .. " " .. currency, "success")

	-- Save data immediately
	self:SavePlayerData(player)

	print("GameCore: " .. player.Name .. " successfully purchased " .. quantity .. "x " .. item.name .. " for " .. totalCost .. " " .. currency)
	return true
end

-- Apply item effects
function GameCore:ApplyItemEffects(player, item, quantity)
	local playerData = self:GetPlayerData(player)
	if not playerData then return false end

	if item.type == "farm_plot" then
		-- Handle farm plot purchase
		if item.id == "farm_plot_starter" then
			-- Check if they already have a farm plot
			if not playerData.purchaseHistory then
				playerData.purchaseHistory = {}
			end

			if playerData.purchaseHistory.farm_plot_starter then
				self:SendNotification(player, "Already Owned", "You already have a farm plot!", "warning")
				return false
			end

			-- Deduct coins (100 coins for starter plot)
			if playerData.coins < 100 then
				self:SendNotification(player, "Insufficient Coins", "You need 100 coins to purchase your first farm plot!", "error")
				return false
			end

			playerData.coins = playerData.coins - 100

			-- Create the farm plot
			local success = self:CreatePlayerFarmPlot(player, 1)
			if success then
				playerData.purchaseHistory.farm_plot_starter = true

				-- Initialize farming data
				if not playerData.farming then
					playerData.farming = {
						plots = 1,
						inventory = {
							carrot_seeds = 5, -- Give starter seeds
							corn_seeds = 3
						},
						pig = { feedCount = 0, size = 1.0 }
					}
				end
				playerData.farming.plots = 1

				-- Update leaderstats
				self:UpdatePlayerLeaderstats(player)

				self:SendNotification(player, "Farm Plot Created!", 
					"Your first farm plot has been placed in Starter Meadow! You received starter seeds too!", "success")

				return true
			else
				-- Refund coins if creation failed
				playerData.coins = playerData.coins + 100
				self:SendNotification(player, "Error", "Failed to create farm plot. Coins refunded.", "error")
				return false
			end
		end

	elseif item.type == "seed" or item.type == "egg" then
		-- Check if player has farm plot first
		if item.requiresFarmPlot and not self:PlayerHasFarmPlot(playerData) then
			self:SendNotification(player, "Farm Plot Required", 
				"You need to purchase a farm plot first before buying seeds!", "warning")
			return false
		end

		-- Handle seeds normally
		if item.type == "seed" then
			if not playerData.farming then
				playerData.farming = {inventory = {}}
			end
			if not playerData.farming.inventory then
				playerData.farming.inventory = {}
			end

			playerData.farming.inventory[item.id] = (playerData.farming.inventory[item.id] or 0) + quantity

		elseif item.type == "egg" then
			-- Hatch eggs to get seeds
			for i = 1, quantity do
				local hatchResults = ItemConfig.HatchEgg(item.id)

				if not playerData.farming then
					playerData.farming = {inventory = {}}
				end
				if not playerData.farming.inventory then
					playerData.farming.inventory = {}
				end

				for seedId, seedAmount in pairs(hatchResults) do
					playerData.farming.inventory[seedId] = (playerData.farming.inventory[seedId] or 0) + seedAmount
				end

				local hatchedItems = {}
				for seedId, seedAmount in pairs(hatchResults) do
					local seedConfig = ItemConfig.Seeds[seedId]
					local seedName = seedConfig and seedConfig.name or seedId
					table.insert(hatchedItems, seedAmount .. "x " .. seedName)
				end

				if #hatchedItems > 0 then
					self:SendNotification(player, "Seed Pack Opened!", 
						"Received: " .. table.concat(hatchedItems, ", "), "success")
				end
			end
		end

	elseif item.type == "upgrade" then
		-- Handle upgrades normally
		if not playerData.upgrades then
			playerData.upgrades = {}
		end

		-- Check farm plot requirement for additional plots
		if item.id == "farm_plot_upgrade" and not self:PlayerHasFarmPlot(playerData) then
			self:SendNotification(player, "Farm Plot Required", 
				"You need to purchase your first farm plot before buying additional ones!", "warning")
			return false
		end

		local currentLevel = playerData.upgrades[item.id] or 0
		local maxLevel = item.maxLevel or 10

		if currentLevel >= maxLevel then
			self:SendNotification(player, "Max Level", "This upgrade is already at maximum level", "warning")
			return false
		end

		playerData.upgrades[item.id] = currentLevel + quantity

		-- Handle farm plot upgrades (additional plots)
		if item.id == "farm_plot_upgrade" then
			local newPlotNumber = (playerData.farming.plots or 1) + 1
			local success = self:CreatePlayerFarmPlot(player, newPlotNumber)
			if success then
				playerData.farming.plots = newPlotNumber
				self:SendNotification(player, "New Farm Plot!", 
					"Additional farm plot created! You now have " .. newPlotNumber .. " plots.", "success")
			else
				-- Refund the upgrade if creation failed
				playerData.upgrades[item.id] = currentLevel
				return false
			end
		else
			-- Apply other upgrade effects
			self:ApplyUpgradeEffects(player, item.id, playerData.upgrades[item.id])
		end

	else
		warn("GameCore: Unknown item type: " .. tostring(item.type))
		return false
	end

	return true
end

-- NEW: Check if player has farm plot
function GameCore:PlayerHasFarmPlot(playerData)
	if not playerData then return false end

	-- Check if they bought the starter plot
	local purchaseHistory = playerData.purchaseHistory or {}
	return purchaseHistory.farm_plot_starter == true
end

-- UPDATED: Create farm plot for player with automatic positioning
--[[
    Enhanced Farming System - FIXES & FEATURES
    This combines fixes for both server and client code
]]

-- ========== SERVER-SIDE FIXES (Add to GameCore.lua) ==========

-- FIXED: Enhanced farm plot creation with highlighting
function GameCore:CreatePlayerFarmPlot(player, plotNumber)
	-- Calculate plot position in Starter Meadow
	local plotPosition = self:GetFarmPlotPosition(player, plotNumber)

	-- Create the plot model
	local plotModel = Instance.new("Model")
	plotModel.Name = player.Name .. "_FarmPlot_" .. plotNumber

	-- Create soil base
	local soil = Instance.new("Part")
	soil.Name = "Soil"
	soil.Size = Vector3.new(8, 1, 8)
	soil.Position = plotPosition
	soil.Anchored = true
	soil.CanCollide = true
	soil.Material = Enum.Material.Ground
	soil.Color = Color3.fromRGB(101, 67, 33)
	soil.Parent = plotModel

	-- Add plot border
	local border = Instance.new("Part")
	border.Name = "Border"
	border.Size = Vector3.new(8.5, 0.2, 8.5)
	border.Position = soil.Position + Vector3.new(0, 0.6, 0)
	border.Anchored = true
	border.CanCollide = false
	border.Material = Enum.Material.Wood
	border.Color = Color3.fromRGB(160, 100, 50)
	border.Parent = plotModel

	-- NEW: Add tutorial highlighting for first plot
	if plotNumber == 1 then
		self:AddTutorialHighlight(plotModel, player)
	end

	-- Add plot sign
	local sign = Instance.new("Part")
	sign.Name = "Sign"
	sign.Size = Vector3.new(2, 3, 0.2)
	sign.Position = soil.Position + Vector3.new(4.5, 1.5, 4.5)
	sign.Anchored = true
	sign.CanCollide = false
	sign.Material = Enum.Material.Wood
	sign.Color = Color3.fromRGB(139, 69, 19)
	sign.Parent = plotModel

	-- Add sign text
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = sign

	local signLabel = Instance.new("TextLabel")
	signLabel.Size = UDim2.new(1, 0, 1, 0)
	signLabel.BackgroundTransparency = 1
	signLabel.Text = player.Name .. "'s\nFarm Plot " .. plotNumber
	signLabel.TextColor3 = Color3.new(1, 1, 1)
	signLabel.TextScaled = true
	signLabel.Font = Enum.Font.GothamBold
	signLabel.TextStrokeTransparency = 0
	signLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	signLabel.Parent = signGui

	plotModel.PrimaryPart = soil

	-- Set plot attributes
	plotModel:SetAttribute("PlotID", plotNumber)
	plotModel:SetAttribute("Owner", player.Name)
	plotModel:SetAttribute("IsPlanted", false)
	plotModel:SetAttribute("PlantType", "")
	plotModel:SetAttribute("GrowthStage", 0)
	plotModel:SetAttribute("PlantTime", 0)
	plotModel:SetAttribute("TimeToGrow", 0)
	plotModel:SetAttribute("HasTutorialHighlight", plotNumber == 1)

	-- Place in Starter Meadow
	local starterMeadow = workspace:FindFirstChild("Areas"):FindFirstChild("Starter Meadow")
	if starterMeadow then
		local farmArea = starterMeadow:FindFirstChild("Farm")
		if not farmArea then
			farmArea = Instance.new("Folder")
			farmArea.Name = "Farm"
			farmArea.Parent = starterMeadow
		end

		local playerFarm = farmArea:FindFirstChild(player.Name .. "_Farm")
		if not playerFarm then
			playerFarm = Instance.new("Folder")
			playerFarm.Name = player.Name .. "_Farm"
			playerFarm.Parent = farmArea
		end

		plotModel.Parent = playerFarm
	else
		plotModel.Parent = workspace
	end

	print("GameCore: Created farm plot " .. plotNumber .. " for " .. player.Name .. " at " .. tostring(plotPosition))
	return true
end

-- NEW: Add tutorial highlighting to farm plot
function GameCore:AddTutorialHighlight(plotModel, player)
	local soil = plotModel:FindFirstChild("Soil")
	if not soil then return end

	-- Create highlight effect
	local highlight = Instance.new("SelectionBox")
	highlight.Name = "TutorialHighlight"
	highlight.Adornee = soil
	highlight.Color3 = Color3.fromRGB(100, 255, 100)
	highlight.LineThickness = 0.3
	highlight.Transparency = 0.5
	highlight.Parent = soil

	-- Create pulsing glow effect
	local glowPart = Instance.new("Part")
	glowPart.Name = "TutorialGlow"
	glowPart.Size = Vector3.new(10, 0.1, 10)
	glowPart.Position = soil.Position + Vector3.new(0, 0.6, 0)
	glowPart.Anchored = true
	glowPart.CanCollide = false
	glowPart.Material = Enum.Material.Neon
	glowPart.Color = Color3.fromRGB(100, 255, 100)
	glowPart.Transparency = 0.8
	glowPart.Shape = Enum.PartType.Cylinder
	glowPart.Parent = plotModel

	-- Animate the glow
	local TweenService = game:GetService("TweenService")
	local glowTween = TweenService:Create(glowPart,
		TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{Transparency = 0.9}
	)
	glowTween:Play()

	-- Create floating text hint
	local hintPart = Instance.new("Part")
	hintPart.Name = "TutorialHint"
	hintPart.Size = Vector3.new(0.1, 0.1, 0.1)
	hintPart.Position = soil.Position + Vector3.new(0, 4, 0)
	hintPart.Anchored = true
	hintPart.CanCollide = false
	hintPart.Transparency = 1
	hintPart.Parent = plotModel

	local hintGui = Instance.new("BillboardGui")
	hintGui.Size = UDim2.new(0, 200, 0, 100)
	hintGui.StudsOffset = Vector3.new(0, 2, 0)
	hintGui.Parent = hintPart

	local hintLabel = Instance.new("TextLabel")
	hintLabel.Size = UDim2.new(1, 0, 1, 0)
	hintLabel.BackgroundTransparency = 1
	hintLabel.Text = "🌱 Your First Farm Plot!\nPress F to open farming menu"
	hintLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	hintLabel.TextScaled = true
	hintLabel.Font = Enum.Font.GothamBold
	hintLabel.TextStrokeTransparency = 0
	hintLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	hintLabel.Parent = hintGui

	-- Bounce animation for hint
	local bounceTween = TweenService:Create(hintGui,
		TweenInfo.new(1.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.InOut, -1, true),
		{StudsOffset = Vector3.new(0, 3, 0)}
	)
	bounceTween:Play()

	-- Send notification to player
	spawn(function()
		wait(2)
		self:SendNotification(player, "Farm Plot Ready!", 
			"Your farm plot is highlighted! Press F to open the farming menu and start planting.", "info")
	end)

	print("GameCore: Added tutorial highlight to farm plot for " .. player.Name)
end

-- NEW: Remove tutorial highlighting when first seed is planted
function GameCore:RemoveTutorialHighlight(plotModel)
	local soil = plotModel:FindFirstChild("Soil")
	if soil then
		local highlight = soil:FindFirstChild("TutorialHighlight")
		if highlight then
			highlight:Destroy()
		end
	end

	local tutorialGlow = plotModel:FindFirstChild("TutorialGlow")
	if tutorialGlow then
		tutorialGlow:Destroy()
	end

	local tutorialHint = plotModel:FindFirstChild("TutorialHint")
	if tutorialHint then
		tutorialHint:Destroy()
	end

	plotModel:SetAttribute("HasTutorialHighlight", false)
	print("GameCore: Removed tutorial highlight from farm plot")
end
-- NEW: Calculate farm plot position with smart placement
function GameCore:GetFarmPlotPosition(player, plotNumber)
	-- Base position in Starter Meadow (away from spawn and pet areas)
	local baseFarmPosition = Vector3.new(-30, 1, 50) -- Corner of Starter Meadow

	-- Plot spacing
	local plotSize = 8
	local plotSpacing = 2
	local totalPlotSize = plotSize + plotSpacing

	if plotNumber == 1 then
		-- First plot at base position
		return baseFarmPosition
	else
		-- Additional plots placed in a grid pattern next to existing plots
		local plotsPerRow = 3 -- 3 plots per row before starting new row

		local row = math.floor((plotNumber - 1) / plotsPerRow)
		local col = (plotNumber - 1) % plotsPerRow

		local xOffset = col * totalPlotSize
		local zOffset = row * totalPlotSize

		return baseFarmPosition + Vector3.new(xOffset, 0, zOffset)
	end
end

-- NEW: Get all farm plots for a player
function GameCore:GetPlayerFarmPlots(player)
	local plots = {}
	local starterMeadow = workspace:FindFirstChild("Areas"):FindFirstChild("Starter Meadow")

	if starterMeadow then
		local farmArea = starterMeadow:FindFirstChild("Farm")
		if farmArea then
			local playerFarm = farmArea:FindFirstChild(player.Name .. "_Farm")
			if playerFarm then
				for _, plot in pairs(playerFarm:GetChildren()) do
					if plot:IsA("Model") and plot.Name:find("FarmPlot") then
						table.insert(plots, plot)
					end
				end
			end
		end
	end

	return plots
end



-- Apply upgrade effects
function GameCore:ApplyUpgradeEffects(player, upgradeId, level)
	if upgradeId == "speed_upgrade" then
		local newSpeed = 16 + (level * 2)
		player:SetAttribute("WalkSpeedLevel", level)
		player:SetAttribute("CurrentWalkSpeed", newSpeed)

		if player.Character and player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.WalkSpeed = newSpeed
		end

	elseif upgradeId == "collection_radius_upgrade" then
		local newRadius = 5 + (level * 1)
		player:SetAttribute("CollectionRadius", newRadius)

	elseif upgradeId == "pet_magnet_upgrade" then
		local newMagnetRange = 8 + (level * 2)
		local newMagnetStrength = 1.0 + (level * 0.3)
		player:SetAttribute("MagnetRange", newMagnetRange)
		player:SetAttribute("MagnetStrength", newMagnetStrength)

	elseif upgradeId == "farm_plot_upgrade" then
		player:SetAttribute("FarmPlots", 3 + level)
		self:UpdatePlayerFarm(player)

	elseif upgradeId == "pet_storage_upgrade" then
		local newCapacity = 100 + (level * 25)
		player:SetAttribute("PetCapacity", newCapacity)
	end

	print("GameCore: Applied " .. upgradeId .. " level " .. level .. " to " .. player.Name)
end

-- Apply all existing upgrades when player joins
function GameCore:ApplyAllUpgradeEffects(player)
	local playerData = self:GetPlayerData(player)
	if not playerData or not playerData.upgrades then return end

	for upgradeId, level in pairs(playerData.upgrades) do
		self:ApplyUpgradeEffects(player, upgradeId, level)
	end
end

-- FIXED: Pet System - Only Starter Meadow
function GameCore:InitializePetSystem()
	local workspace = game:GetService("Workspace")
	local areasFolder = workspace:FindFirstChild("Areas") or Instance.new("Folder")
	areasFolder.Name = "Areas"
	areasFolder.Parent = workspace

	-- FIXED: Only create Starter Meadow area
	local starterConfig = {
		name = "Starter Meadow",
		maxPets = 8, -- Reduced from 15 to 8 for memory
		spawnInterval = 12, -- Increased from 8 to 12 seconds
		availablePets = {"Corgi", "RedPanda", "Cat", "Hamster"},
		spawnPositions = {
			Vector3.new(0, 1, 0),
			Vector3.new(10, 1, 10),
			Vector3.new(-10, 1, 10),
			Vector3.new(10, 1, -10),
			Vector3.new(-10, 1, -10),
			Vector3.new(15, 1, 0),
			Vector3.new(-15, 1, 0),
			Vector3.new(0, 1, 15)
		}
	}

	local areaFolder = areasFolder:FindFirstChild(starterConfig.name)
	if not areaFolder then
		areaFolder = Instance.new("Folder")
		areaFolder.Name = starterConfig.name
		areaFolder.Parent = areasFolder
	end

	local petsContainer = areaFolder:FindFirstChild("Pets")
	if not petsContainer then
		petsContainer = Instance.new("Folder")
		petsContainer.Name = "Pets"
		petsContainer.Parent = areaFolder
	end

	self.Systems.Pets.SpawnAreas[starterConfig.name] = {
		container = petsContainer,
		config = starterConfig,
		lastSpawn = 0
	}

	print("GameCore: Pet system initialized with only Starter Meadow")
end

-- FIXED: Enhanced wild pet collection - NO COIN REWARDS
function GameCore:HandleWildPetCollection(player, petModel)
	if not player or not petModel or not petModel.Parent then 
		return false 
	end

	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return false
	end

	local playerRoot = character.HumanoidRootPart
	local petPosition

	if petModel:IsA("Model") and petModel.PrimaryPart then
		petPosition = petModel.PrimaryPart.Position
	elseif petModel:IsA("BasePart") then
		petPosition = petModel.Position
	else
		for _, part in pairs(petModel:GetDescendants()) do
			if part:IsA("BasePart") then
				petPosition = part.Position
				break
			end
		end
	end

	if not petPosition then return false end

	local distance = (playerRoot.Position - petPosition).Magnitude
	local playerCollectionRadius = player:GetAttribute("CollectionRadius") or 8

	if distance > playerCollectionRadius then
		return false
	end

	local petType = petModel:GetAttribute("PetType")
	local petRarity = petModel:GetAttribute("Rarity") or "Common"

	if not petType then
		warn("Pet model missing PetType attribute")
		return false
	end

	local petConfig = ItemConfig.Pets[petType]
	if not petConfig then
		warn("Unknown pet type: " .. tostring(petType))
		return false
	end

	local petData = {
		id = HttpService:GenerateGUID(false),
		type = petType,
		name = petConfig.name,
		displayName = petConfig.displayName,
		rarity = petRarity,
		level = 1,
		experience = 0,
		acquired = os.time(),
		source = "wild_catch",
		stats = {}
	}

	if petConfig.baseStats then
		for k, v in pairs(petConfig.baseStats) do
			petData.stats[k] = v
		end
	end

	local playerData = self:GetPlayerData(player)
	if not playerData then return false end

	local currentPetCount = #(playerData.pets and playerData.pets.owned or {})
	local maxPets = player:GetAttribute("PetCapacity") or 100

	if currentPetCount >= maxPets then
		if self.RemoteEvents.ShowNotification then
			self.RemoteEvents.ShowNotification:FireClient(player, 
				"Inventory Full!", 
				"You can't collect more pets. Sell some pets or upgrade your storage!", 
				"warning"
			)
		end
		return false
	end

	-- Clean up behavior connection
	local behaviorId = petModel:GetAttribute("BehaviorId")
	if behaviorId then
		local connection = self.Systems.Pets.BehaviorConnections[behaviorId]
		if connection then
			connection:Disconnect()
			self.Systems.Pets.BehaviorConnections[behaviorId] = nil
		end
	end

	-- Immediately destroy the pet to prevent double collection
	petModel:Destroy()

	-- Add pet to player's collection
	local success = self:AddPetToPlayer(player.UserId, petData)
	if not success then
		warn("Failed to add pet to player " .. player.UserId)
		return false
	end

	-- FIXED: NO COIN REWARDS FOR COLLECTING - Only update stats
	playerData.stats.totalPetsCollected = playerData.stats.totalPetsCollected + 1
	if petRarity == "Legendary" then
		playerData.stats.legendaryPetsFound = (playerData.stats.legendaryPetsFound or 0) + 1
	end

	self:UpdatePlayerLeaderstats(player)

	-- FIXED: Send notification without coin reward
	if self.RemoteEvents.ShowNotification then
		self.RemoteEvents.ShowNotification:FireClient(player,
			"Pet Collected!", 
			"Caught " .. petData.name .. "! (Sell in Pets menu for coins)",
			"success"
		)
	end

	if self.RemoteEvents.PetCollected then
		-- FIXED: Send 0 coins awarded
		self.RemoteEvents.PetCollected:FireClient(player, petData, 0)
	end

	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	-- Save data
	self:SavePlayerData(player)

	print("GameCore: " .. player.Name .. " collected " .. petData.name .. " (no coins awarded)")
	return true
end

-- Create pet model (only custom models)
function GameCore:CreatePetModel(petConfig, position)
	local petModelsFolder = ReplicatedStorage:FindFirstChild("PetModels")
	if not petModelsFolder then
		warn("GameCore: PetModels folder not found in ReplicatedStorage")
		return nil
	end

	local template = petModelsFolder:FindFirstChild(petConfig.modelName or petConfig.name)
	if not template then
		warn("GameCore: Custom pet model not found: " .. (petConfig.modelName or petConfig.name))
		return nil
	end

	-- Clone the custom model
	local petModel = template:Clone()

	-- Ensure proper configuration
	for _, part in pairs(petModel:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Anchored = false
			part.CanCollide = false
		end
	end

	-- Ensure required components
	local humanoid = petModel:FindFirstChild("Humanoid")
	if not humanoid then
		humanoid = Instance.new("Humanoid")
		humanoid.WalkSpeed = math.random(4, 8)
		humanoid.JumpPower = math.random(30, 50)
		humanoid.MaxHealth = 100
		humanoid.Health = 100
		humanoid.PlatformStand = false
		humanoid.Parent = petModel
	end

	local rootPart = petModel:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		rootPart = petModel.PrimaryPart
		if rootPart then
			rootPart.Name = "HumanoidRootPart"
		else
			for _, part in pairs(petModel:GetChildren()) do
				if part:IsA("BasePart") then
					part.Name = "HumanoidRootPart"
					rootPart = part
					break
				end
			end
		end
	end

	if not rootPart then
		warn("GameCore: Could not find suitable root part for " .. petConfig.name)
		petModel:Destroy()
		return nil
	end

	petModel.PrimaryPart = rootPart
	petModel.Name = petConfig.name .. "_" .. tick()
	petModel:SetAttribute("PetType", petConfig.id or petConfig.name)
	petModel:SetAttribute("Rarity", petConfig.rarity)
	petModel:SetAttribute("SpawnTime", os.time())

	-- Position the pet
	local success = self:PositionPet(petModel, position)
	if not success then
		petModel:Destroy()
		return nil
	end

	-- Start behavior
	self:StartPetBehavior(petModel, petConfig)

	return petModel
end

-- Pet behavior system
function GameCore:StartPetBehavior(petModel, petConfig)
	local humanoid = petModel:FindFirstChild("Humanoid")
	local rootPart = petModel.PrimaryPart or petModel:FindFirstChild("HumanoidRootPart")

	if not humanoid or not rootPart then return end

	local behaviorId = self.Systems.Pets.NextBehaviorId
	self.Systems.Pets.NextBehaviorId = self.Systems.Pets.NextBehaviorId + 1

	petModel:SetAttribute("BehaviorId", behaviorId)

	local originalPosition = rootPart.Position
	local wanderRadius = 15
	local moveTime = 0
	local jumpTime = 0
	local targetPosition = originalPosition
	local isCollected = false
	local glowEffect = nil

	local function getRandomTarget()
		local angle = math.random() * math.pi * 2
		local distance = math.random(5, wanderRadius)
		local offset = Vector3.new(
			math.cos(angle) * distance,
			0,
			math.sin(angle) * distance
		)
		return originalPosition + offset
	end

	local function createGlow()
		if glowEffect or isCollected then return end

		glowEffect = Instance.new("Part")
		glowEffect.Name = "GlowEffect"
		glowEffect.Size = Vector3.new(6, 6, 6)
		glowEffect.Shape = Enum.PartType.Ball
		glowEffect.Material = Enum.Material.ForceField
		glowEffect.Color = Color3.fromRGB(255, 255, 0)
		glowEffect.Transparency = 0.7
		glowEffect.CanCollide = false
		glowEffect.Anchored = true
		glowEffect.Parent = petModel

		petModel:SetAttribute("HasGlow", true)
	end

	local function removeGlow()
		if glowEffect then
			glowEffect:Destroy()
			glowEffect = nil
			petModel:SetAttribute("HasGlow", false)
		end
	end

	local behaviorConnection = RunService.Heartbeat:Connect(function(deltaTime)
		if not petModel or not petModel.Parent or not humanoid or not humanoid.Parent or 
			not rootPart or not rootPart.Parent or isCollected then
			if behaviorConnection then
				behaviorConnection:Disconnect()
				behaviorConnection = nil
			end
			if self.Systems.Pets.BehaviorConnections[behaviorId] then
				self.Systems.Pets.BehaviorConnections[behaviorId] = nil
			end
			removeGlow()
			return
		end

		moveTime = moveTime + deltaTime
		jumpTime = jumpTime + deltaTime

		-- Random jumping
		if jumpTime > math.random(3, 8) then
			jumpTime = 0
			if humanoid.FloorMaterial ~= Enum.Material.Air then
				humanoid.Jump = true
			end
		end

		-- Random movement
		if moveTime > math.random(2, 5) then
			moveTime = 0
			targetPosition = getRandomTarget()
		end

		-- Move towards target
		local currentPosition = rootPart.Position
		local direction = (targetPosition - currentPosition)

		if direction.Magnitude > 2 then
			direction = direction.Unit
			humanoid:MoveTo(currentPosition + direction * 10)
		else
			targetPosition = getRandomTarget()
		end

		-- Enhanced proximity detection
		local playerNearby = false
		local glowRadius = 12
		local collectRadius = 8

		for _, player in pairs(Players:GetPlayers()) do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local playerRoot = player.Character.HumanoidRootPart
				local distance = (rootPart.Position - playerRoot.Position).Magnitude

				local playerCollectionRadius = player:GetAttribute("CollectionRadius") or collectRadius

				if distance <= playerCollectionRadius and not isCollected then
					isCollected = true
					if behaviorConnection then
						behaviorConnection:Disconnect()
						behaviorConnection = nil
					end
					if self.Systems.Pets.BehaviorConnections[behaviorId] then
						self.Systems.Pets.BehaviorConnections[behaviorId] = nil
					end
					spawn(function()
						self:HandleWildPetCollection(player, petModel)
					end)
					return
				elseif distance <= glowRadius then
					playerNearby = true
				end
			end
		end

		-- Manage glow effect
		if playerNearby and not petModel:GetAttribute("HasGlow") then
			createGlow()
		elseif not playerNearby and petModel:GetAttribute("HasGlow") then
			removeGlow()
		end

		-- Update glow position
		if glowEffect then
			glowEffect.CFrame = rootPart.CFrame
		end
	end)

	self.Systems.Pets.BehaviorConnections[behaviorId] = behaviorConnection
end

-- Enhanced pet spawning - Only Starter Meadow
function GameCore:SpawnWildPet(areaName)
	-- FIXED: Only allow Starter Meadow
	if areaName ~= "Starter Meadow" then
		return nil
	end

	local areaData = self.Systems.Pets.SpawnAreas[areaName]
	if not areaData then 
		warn("GameCore: Area data not found for " .. areaName)
		return 
	end

	local config = areaData.config
	local currentPetCount = #areaData.container:GetChildren()

	if currentPetCount >= config.maxPets then 
		return 
	end

	-- Choose pet based on weighted random from available pets
	local availablePets = config.availablePets
	local selectedPetId = availablePets[math.random(1, #availablePets)]
	local petConfig = ItemConfig.Pets[selectedPetId]

	if not petConfig then 
		warn("GameCore: Pet config not found for " .. selectedPetId)
		return 
	end

	-- Choose spawn position
	local spawnPositions = config.spawnPositions
	if not spawnPositions or #spawnPositions == 0 then
		warn("GameCore: No spawn positions found for " .. areaName)
		return
	end

	local basePosition = spawnPositions[math.random(1, #spawnPositions)]
	local randomOffset = Vector3.new(
		math.random(-3, 3),
		0,
		math.random(-3, 3)
	)
	local finalPosition = basePosition + randomOffset

	-- Create pet model (only custom models)
	local petModel = self:CreatePetModel(petConfig, finalPosition)
	if petModel then
		petModel.Parent = areaData.container
		petModel:SetAttribute("AreaOrigin", areaName)

		-- Set automatic despawn timer (15 minutes)
		spawn(function()
			wait(900) -- 15 minutes
			if petModel and petModel.Parent then
				local behaviorId = petModel:GetAttribute("BehaviorId")
				if behaviorId then
					local connection = self.Systems.Pets.BehaviorConnections[behaviorId]
					if connection then
						connection:Disconnect()
						self.Systems.Pets.BehaviorConnections[behaviorId] = nil
					end
				end
				petModel:Destroy()
			end
		end)

		print("GameCore: Spawned " .. selectedPetId .. " in " .. areaName)
		return petModel
	end
end

-- Pet positioning
function GameCore:PositionPet(petModel, position)
	if petModel.PrimaryPart then
		petModel.PrimaryPart.CFrame = CFrame.new(position + Vector3.new(0, 2, 0))
		return true
	end

	local rootPart = petModel:FindFirstChild("HumanoidRootPart")
	if rootPart then
		rootPart.CFrame = CFrame.new(position + Vector3.new(0, 2, 0))
		return true
	end

	return false
end

-- Shop System Implementation
function GameCore:InitializeShopSystem()
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		return self:ProcessDevProductPurchase(receiptInfo)
	end
	print("GameCore: Shop system initialized")
end

-- Farming System Implementation
function GameCore:InitializeFarmingSystem()
	local farmingArea = workspace:FindFirstChild("FarmingArea")
	if not farmingArea then
		farmingArea = Instance.new("Model")
		farmingArea.Name = "FarmingArea"
		farmingArea.Parent = workspace

		local ground = Instance.new("Part")
		ground.Name = "FarmGround"
		ground.Size = Vector3.new(33.425, 1.65, 32.575)
		ground.Position = Vector3.new(-362.98, -2.142, 76.55)
		ground.Anchored = true
		ground.CanCollide = true
		ground.Material = Enum.Material.Ground
		ground.Color = Color3.fromRGB(120, 60, 0)
		ground.Parent = farmingArea

		print("GameCore: Created basic farming area at (-362.98, -2.142, 76.55)")
	end

	print("GameCore: Farming system initialized")
end

function GameCore:InitializePlayerFarm(player)
	local playerData = self:GetPlayerData(player)
	local farmPlotsLevel = playerData.upgrades.farm_plot_upgrade or 0
	local totalPlots = 3 + farmPlotsLevel

	local workspace = game:GetService("Workspace")
	local farmingAreas = workspace:FindFirstChild("FarmingAreas") or Instance.new("Folder")
	farmingAreas.Name = "FarmingAreas"
	farmingAreas.Parent = workspace

	local playerFarm = farmingAreas:FindFirstChild(player.Name)
	if not playerFarm then
		playerFarm = Instance.new("Folder")
		playerFarm.Name = player.Name
		playerFarm.Parent = farmingAreas
	end

	-- Count existing plots
	local existingPlots = 0
	for _, child in pairs(playerFarm:GetChildren()) do
		if child.Name:match("FarmPlot_") then
			existingPlots = existingPlots + 1
		end
	end

	-- Create additional plots if needed
	for i = existingPlots + 1, totalPlots do
		local plot = self:CreateFarmPlot(i)
		plot.Parent = playerFarm
	end

	self.Systems.Farming.PlayerFarms[player.UserId] = {
		folder = playerFarm,
		plots = totalPlots
	}
end

function GameCore:CreateFarmPlot(plotNumber)
	local plotModel = Instance.new("Model")
	plotModel.Name = "FarmPlot_" .. plotNumber

	-- Create soil base
	local soil = Instance.new("Part")
	soil.Name = "Soil"
	soil.Size = Vector3.new(8, 1, 8)

	-- Position plots in a grid
	local row = math.floor((plotNumber - 1) / 5)
	local col = (plotNumber - 1) % 5
	soil.Position = Vector3.new(col * 12, 0.5, row * 12)

	soil.Anchored = true
	soil.CanCollide = true
	soil.Material = Enum.Material.Ground
	soil.Color = Color3.fromRGB(101, 67, 33)
	soil.Parent = plotModel

	-- Add plot border
	local border = Instance.new("Part")
	border.Name = "Border"
	border.Size = Vector3.new(8.5, 0.2, 8.5)
	border.Position = soil.Position + Vector3.new(0, 0.6, 0)
	border.Anchored = true
	border.CanCollide = false
	border.Material = Enum.Material.Wood
	border.Color = Color3.fromRGB(160, 100, 50)
	border.Parent = plotModel

	plotModel.PrimaryPart = soil

	-- Set plot attributes
	plotModel:SetAttribute("PlotID", plotNumber)
	plotModel:SetAttribute("IsPlanted", false)
	plotModel:SetAttribute("PlantType", "")
	plotModel:SetAttribute("GrowthStage", 0)
	plotModel:SetAttribute("PlantTime", 0)
	plotModel:SetAttribute("TimeToGrow", 0)

	return plotModel
end

function GameCore:UpdatePlayerFarm(player)
	local playerData = self:GetPlayerData(player)
	if not playerData then return end

	local farmPlotsLevel = playerData.upgrades.farm_plot_upgrade or 0
	local totalPlots = 3 + farmPlotsLevel

	local farmingAreas = workspace:FindFirstChild("FarmingAreas")
	if not farmingAreas then
		self:InitializePlayerFarm(player)
		return
	end

	local playerFarm = farmingAreas:FindFirstChild(player.Name)
	if not playerFarm then
		self:InitializePlayerFarm(player)
		return
	end

	-- Count existing plots
	local existingPlots = 0
	for _, child in pairs(playerFarm:GetChildren()) do
		if child.Name:match("FarmPlot_") then
			existingPlots = existingPlots + 1
		end
	end

	-- Create additional plots if needed
	for i = existingPlots + 1, totalPlots do
		local plot = self:CreateFarmPlot(i)
		plot.Parent = playerFarm
		print("GameCore: Created additional farm plot " .. i .. " for " .. player.Name)
	end
end

-- Player Management
function GameCore:SetupPlayerEvents()
	Players.PlayerAdded:Connect(function(player)
		self:LoadPlayerData(player)
		self:CreatePlayerLeaderstats(player)

		player.CharacterAdded:Connect(function(character)
			wait(1)
			self:ApplyAllUpgradeEffects(player)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:SavePlayerData(player)
		self:CleanupPlayer(player)
	end)
end

function GameCore:CreatePlayerLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = self.PlayerData[player.UserId].coins
	coins.Parent = leaderstats

	local gems = Instance.new("IntValue")
	gems.Name = "Gems"
	gems.Value = self.PlayerData[player.UserId].gems
	gems.Parent = leaderstats

	local pets = Instance.new("IntValue")
	pets.Name = "Pets"
	pets.Value = #self.PlayerData[player.UserId].pets.owned
	pets.Parent = leaderstats
end

function GameCore:UpdatePlayerLeaderstats(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local playerData = self.PlayerData[player.UserId]
	if not playerData then return end

	local coins = leaderstats:FindFirstChild("Coins")
	if coins then coins.Value = playerData.coins end

	local gems = leaderstats:FindFirstChild("Gems")
	if gems then gems.Value = playerData.gems end

	local pets = leaderstats:FindFirstChild("Pets")
	if pets then pets.Value = #playerData.pets.owned end
end

function GameCore:CleanupPlayer(player)
	self.PlayerData[player.UserId] = nil

	if self.Systems.Farming.PlayerFarms[player.UserId] then
		self.Systems.Farming.PlayerFarms[player.UserId] = nil
	end
end

-- FIXED: Update Loops - Reduced frequency for memory
function GameCore:StartUpdateLoops()
	print("GameCore: Starting update loops with performance optimizations...")

	-- FIXED: Pet spawning loop - ONLY for Starter Meadow with reduced frequency
	spawn(function()
		while true do
			wait(25) -- Increased from 20 to 25 seconds to reduce memory usage

			-- Only spawn in Starter Meadow
			local areaData = self.Systems.Pets.SpawnAreas["Starter Meadow"]
			if areaData then
				local currentPetCount = #areaData.container:GetChildren()
				local maxPets = areaData.config.maxPets
				local timeSinceLastSpawn = os.time() - (areaData.lastSpawn or 0)
				local minSpawnInterval = areaData.config.spawnInterval or 15

				-- Only spawn if we need more pets and enough time has passed
				if currentPetCount < maxPets and timeSinceLastSpawn >= minSpawnInterval then
					local success, newPet = pcall(function()
						return self:SpawnWildPet("Starter Meadow")
					end)

					if success and newPet then
						areaData.lastSpawn = os.time()
						print("GameCore: Spawned pet in Starter Meadow (" .. (currentPetCount + 1) .. "/" .. maxPets .. ")")
					else
						warn("GameCore: Failed to spawn pet in Starter Meadow: " .. tostring(newPet))
					end
				end
			end
		end
	end)

	-- Auto-save loop with player validation
	spawn(function()
		while true do
			wait(300) -- Save every 5 minutes

			local playerCount = 0
			for _, player in ipairs(Players:GetPlayers()) do
				if player and player.Parent and self.PlayerData[player.UserId] then
					pcall(function()
						self:SavePlayerData(player)
					end)
					playerCount = playerCount + 1
				end
			end

			if playerCount > 0 then
				print("GameCore: Auto-saved data for " .. playerCount .. " players")
			end
		end
	end)

	-- FIXED: Enhanced memory cleanup loop with better performance monitoring
	spawn(function()
		while true do
			wait(60) -- Every minute

			local success, errorMsg = pcall(function()
				self:CleanupMemory()
			end)

			if not success then
				warn("GameCore: Memory cleanup failed: " .. tostring(errorMsg))
			end
		end
	end)

	-- FIXED: Performance monitoring loop
	spawn(function()
		while true do
			wait(120) -- Every 2 minutes

			local memoryUsage = game:GetService("Stats"):GetTotalMemoryUsageMb()
			local playerCount = #Players:GetPlayers()

			-- Count active pets across all areas
			local totalPets = 0
			for areaName, areaData in pairs(self.Systems.Pets.SpawnAreas) do
				if areaData and areaData.container then
					totalPets = totalPets + #areaData.container:GetChildren()
				end
			end

			-- Count active behavior connections
			local totalConnections = 0
			for behaviorId, connection in pairs(self.Systems.Pets.BehaviorConnections) do
				if connection and connection.Connected then
					totalConnections = totalConnections + 1
				end
			end

			print(string.format("GameCore: Performance Monitor - Memory: %.1fMB, Players: %d, Pets: %d, Connections: %d", 
				memoryUsage, playerCount, totalPets, totalConnections))

			-- Warning thresholds
			if memoryUsage > 800 then
				warn("GameCore: High memory usage detected: " .. math.floor(memoryUsage) .. "MB")

				-- Trigger aggressive cleanup
				if memoryUsage > 1000 then
					warn("GameCore: Critical memory usage - triggering aggressive cleanup")
					self:CleanupMemory()
				end
			end

			if totalPets > 15 then
				warn("GameCore: Too many pets detected: " .. totalPets .. " - consider cleanup")
			end

			if totalConnections > 20 then
				warn("GameCore: Too many connections detected: " .. totalConnections .. " - cleaning up")
				self:CleanupMemory()
			end
		end
	end)
	function GameCore:UpdatePlayerFarmGrowth(playerId)
		local playerData = self.PlayerData[playerId]
		if not playerData or not playerData.farming then return end

		-- This would integrate with your farming system
		-- For now, it's a placeholder for future farm growth mechanics
		print("GameCore: Updated farm growth for player " .. playerId)
	end

	-- FIXED: Farming system growth loop (if farming is enabled)
	spawn(function()
		while true do
			wait(30) -- Check every 30 seconds

			-- Update crop growth for all players
			for playerId, playerData in pairs(self.PlayerData) do
				if playerData.farming and playerData.farming.plots then
					pcall(function()
						self:UpdatePlayerFarmGrowth(playerId)
					end)
				end
			end
		end
	end)

	-- FIXED: Connection cleanup loop
	spawn(function()
		while true do
			wait(180) -- Every 3 minutes

			local cleanedConnections = 0

			-- Clean up broken behavior connections
			for behaviorId, connection in pairs(self.Systems.Pets.BehaviorConnections) do
				if not connection or not connection.Connected then
					self.Systems.Pets.BehaviorConnections[behaviorId] = nil
					cleanedConnections = cleanedConnections + 1
				end
			end

			if cleanedConnections > 0 then
				print("GameCore: Cleaned up " .. cleanedConnections .. " broken connections")
			end
		end
	end)

	-- FIXED: Player data validation loop
	function GameCore:ValidatePlayerData(player)
		local playerData = self.PlayerData[player.UserId]
		if not playerData then return end

		-- Ensure required fields exist
		if not playerData.coins then playerData.coins = 0 end
		if not playerData.gems then playerData.gems = 0 end
		if not playerData.pets then playerData.pets = {owned = {}, equipped = {}} end
		if not playerData.upgrades then playerData.upgrades = {} end
		if not playerData.stats then 
			playerData.stats = {
				totalPetsCollected = 0,
				coinsEarned = 0,
				itemsPurchased = 0,
				cropsHarvested = 0,
				petsSold = 0,
				legendaryPetsFound = 0
			}
		end

		-- Validate pets array
		if playerData.pets.owned then
			for i = #playerData.pets.owned, 1, -1 do
				local pet = playerData.pets.owned[i]
				if not pet or not pet.id or not pet.type then
					table.remove(playerData.pets.owned, i)
				end
			end
		end

		-- Validate numeric values
		if playerData.coins < 0 then playerData.coins = 0 end
		if playerData.gems < 0 then playerData.gems = 0 end
	end
	spawn(function()
		while true do
			wait(600) -- Every 10 minutes

			-- Validate player data integrity
			for playerId, playerData in pairs(self.PlayerData) do
				local player = Players:GetPlayerByUserId(playerId)

				-- Remove data for players who left
				if not player then
					self.PlayerData[playerId] = nil
					print("GameCore: Cleaned up data for disconnected player: " .. playerId)
				else
					-- Validate data structure
					pcall(function()
						self:ValidatePlayerData(player)
					end)
				end
			end
		end
	end)

	print("GameCore: All update loops started successfully")
end

-- FIXED: Enhanced memory cleanup
function GameCore:CleanupMemory()
	local totalPets = 0
	local oldPets = {}
	local totalConnections = 0

	-- Only check Starter Meadow
	local areaData = self.Systems.Pets.SpawnAreas["Starter Meadow"]
	if areaData and areaData.container then
		for _, pet in pairs(areaData.container:GetChildren()) do
			totalPets = totalPets + 1

			local spawnTime = pet:GetAttribute("SpawnTime")
			if spawnTime and os.time() - spawnTime > 600 then -- 10 minutes old
				table.insert(oldPets, pet)
			end
		end
	end

	-- Count active connections
	for _, connection in pairs(self.Systems.Pets.BehaviorConnections) do
		if connection then
			totalConnections = totalConnections + 1
		end
	end

	-- Clean up if too many pets or connections
	if totalPets > 12 or totalConnections > 15 then
		local cleanupCount = math.min(#oldPets, 5)
		for i = 1, cleanupCount do
			if oldPets[i] and oldPets[i].Parent then
				local behaviorId = oldPets[i]:GetAttribute("BehaviorId")
				if behaviorId then
					local connection = self.Systems.Pets.BehaviorConnections[behaviorId]
					if connection then
						connection:Disconnect()
						self.Systems.Pets.BehaviorConnections[behaviorId] = nil
					end
				end
				oldPets[i]:Destroy()
			end
		end
		print("GameCore: Cleaned up " .. cleanupCount .. " old pets - Memory optimization")
	end

	-- Clean up broken connections
	for behaviorId, connection in pairs(self.Systems.Pets.BehaviorConnections) do
		if not connection or not connection.Connected then
			self.Systems.Pets.BehaviorConnections[behaviorId] = nil
		end
	end

	-- Force garbage collection if memory usage is high
	local memoryUsage = game:GetService("Stats"):GetTotalMemoryUsageMb()
	if memoryUsage > 1000 then
		gcinfo("collect")
		print("GameCore: Force garbage collection - Memory was " .. math.floor(memoryUsage) .. "MB")
	end
end

-- Utility Methods
function GameCore:SendNotification(player, title, message, type)
	if self.RemoteEvents.ShowNotification then
		self.RemoteEvents.ShowNotification:FireClient(player, title, message, type or "info")
	end
end

function GameCore:AddPetToPlayer(userId, petData)
	local playerData = self.PlayerData[userId]
	if not playerData then return false end

	if not playerData.pets then
		playerData.pets = { owned = {}, equipped = {} }
	end

	if not playerData.pets.owned then
		playerData.pets.owned = {}
	end

	table.insert(playerData.pets.owned, petData)
	return true
end

-- Validation function
function GameCore:ValidateCustomPetsOnly()
	print("GameCore: Validating custom pet models...")

	local petModelsFolder = ReplicatedStorage:FindFirstChild("PetModels")
	if not petModelsFolder then
		warn("GameCore: PetModels folder not found in ReplicatedStorage!")
		self:CreateBasicPetModels()
		return true
	end

	local requiredModels = {"Corgi", "RedPanda", "Cat", "Hamster"}
	local foundModels = {}
	local missingModels = {}

	for _, modelName in ipairs(requiredModels) do
		local model = petModelsFolder:FindFirstChild(modelName)
		if model then
			table.insert(foundModels, modelName)
			print("✅ Found custom model: " .. modelName)
		else
			table.insert(missingModels, modelName)
			warn("❌ Missing custom model: " .. modelName)
		end
	end

	if #missingModels > 0 then
		print("GameCore: Creating missing pet models...")
		self:CreateBasicPetModels(missingModels)
	end

	print("GameCore: Pet model validation complete!")
	return true
end

function GameCore:CreateBasicPetModels(specificModels)
	local petModelsFolder = ReplicatedStorage:FindFirstChild("PetModels")
	if not petModelsFolder then
		petModelsFolder = Instance.new("Folder")
		petModelsFolder.Name = "PetModels"
		petModelsFolder.Parent = ReplicatedStorage
	end

	local modelsToCreate = specificModels or {"Corgi", "RedPanda", "Cat", "Hamster"}

	for _, petName in ipairs(modelsToCreate) do
		local existingModel = petModelsFolder:FindFirstChild(petName)
		if existingModel then continue end

		-- Create a basic pet model
		local petModel = Instance.new("Model")
		petModel.Name = petName

		-- Create body part
		local body = Instance.new("Part")
		body.Name = "HumanoidRootPart"
		body.Size = Vector3.new(2, 2, 3)
		body.Shape = Enum.PartType.Block
		body.Anchored = false
		body.CanCollide = false
		body.Parent = petModel

		-- Create head
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Size = Vector3.new(1.5, 1.5, 1.5)
		head.Shape = Enum.PartType.Ball
		head.Anchored = false
		head.CanCollide = false
		head.Parent = petModel

		-- Position head
		local headWeld = Instance.new("WeldConstraint")
		headWeld.Part0 = body
		headWeld.Part1 = head
		headWeld.Parent = body
		head.CFrame = body.CFrame * CFrame.new(0, 2, 0)

		-- Set colors based on pet type
		if petName == "Corgi" then
			body.Color = Color3.fromRGB(255, 200, 150)
			head.Color = Color3.fromRGB(255, 200, 150)
		elseif petName == "RedPanda" then
			body.Color = Color3.fromRGB(194, 144, 90)
			head.Color = Color3.fromRGB(194, 144, 90)
		elseif petName == "Cat" then
			body.Color = Color3.fromRGB(110, 110, 110)
			head.Color = Color3.fromRGB(110, 110, 110)
		elseif petName == "Hamster" then
			body.Color = Color3.fromRGB(255, 215, 0)
			head.Color = Color3.fromRGB(255, 215, 0)
		end

		-- Add humanoid
		local humanoid = Instance.new("Humanoid")
		humanoid.WalkSpeed = math.random(4, 8)
		humanoid.JumpPower = math.random(30, 50)
		humanoid.MaxHealth = 100
		humanoid.Health = 100
		humanoid.Parent = petModel

		-- Set primary part
		petModel.PrimaryPart = body

		-- Parent to folder
		petModel.Parent = petModelsFolder

		print("GameCore: Created basic " .. petName .. " model")
	end
end

-- Stub functions for completeness
--[[
    Complete Seed Planting System
    Add these functions to your GameCore.lua for the server-side planting logic
]]

-- SERVER-SIDE: Enhanced planting system for GameCore.lua

-- Plant a seed in a specific plot
function GameCore:PlantSeed(player, plotModel, seedType)
	if not player or not plotModel or not seedType then 
		return false, "Invalid parameters" 
	end

	-- Validate plot ownership
	local plotOwner = plotModel:GetAttribute("Owner")
	if plotOwner ~= player.Name then
		self:SendNotification(player, "Not Your Plot", "You can only plant on your own farm plots!", "error")
		return false
	end

	-- Check if plot is already planted
	if plotModel:GetAttribute("IsPlanted") then
		local plantType = plotModel:GetAttribute("PlantType") or "something"
		local growthStage = plotModel:GetAttribute("GrowthStage") or 0
		local progress = math.floor((growthStage / 4) * 100)

		self:SendNotification(player, "Plot Occupied", 
			"This plot already has " .. plantType .. " growing (" .. progress .. "% complete)", "warning")
		return false
	end

	-- Check if player has the seed
	local playerData = self:GetPlayerData(player)
	local farmingData = playerData.farming or {}
	local inventory = farmingData.inventory or {}
	local seedCount = inventory[seedType] or 0

	if seedCount <= 0 then
		local seedName = seedType:gsub("_", " "):gsub("seeds", "Seeds")
		self:SendNotification(player, "No Seeds", 
			"You don't have any " .. seedName .. "!", "error")
		return false
	end

	-- Get seed configuration from ItemConfig
	local ServerScriptService = game:GetService("ServerScriptService")
	local ItemConfig = require(ServerScriptService.Config.ItemConfig)
	local seedConfig = ItemConfig.ShopItems[seedType]

	if not seedConfig then
		self:SendNotification(player, "Invalid Seed", "Unknown seed type: " .. seedType, "error")
		return false
	end

	-- Consume the seed
	inventory[seedType] = seedCount - 1
	playerData.farming.inventory = inventory

	-- Plant the seed
	plotModel:SetAttribute("IsPlanted", true)
	plotModel:SetAttribute("PlantType", seedType)
	plotModel:SetAttribute("GrowthStage", 1)
	plotModel:SetAttribute("PlantTime", os.time())
	plotModel:SetAttribute("TimeToGrow", seedConfig.growTime or 60)
	plotModel:SetAttribute("YieldAmount", seedConfig.yieldAmount or 1)
	plotModel:SetAttribute("ResultCrop", seedConfig.resultId or "unknown")

	-- NEW: Remove tutorial highlighting if this is the first planting
	if plotModel:GetAttribute("HasTutorialHighlight") then
		self:RemoveTutorialHighlight(plotModel)
		self:SendNotification(player, "Great Start!", 
			"You've planted your first seed! Watch it grow over time.", "success")
	end

	-- Create initial plant model
	self:CreatePlantModel(plotModel, seedType, 1)

	-- Start growth timer
	self:StartPlantGrowth(plotModel, seedConfig.growTime or 60)

	-- Save player data
	self:SavePlayerData(player)

	-- Send success notification
	self:SendNotification(player, "Seed Planted!", 
		"Planted " .. (seedConfig.name or seedType) .. "! It will be ready in " .. 
			math.floor((seedConfig.growTime or 60) / 60) .. " minutes.", "success")

	-- Update client
	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	print("GameCore: " .. player.Name .. " planted " .. seedType .. " in plot " .. (plotModel:GetAttribute("PlotID") or "unknown"))
	return true
end
-- Create visual plant model based on growth stage
function GameCore:CreatePlantModel(plotModel, seedType, growthStage)
    -- Remove existing plant
    local existingPlant = plotModel:FindFirstChild("PlantModel")
    if existingPlant then
        existingPlant:Destroy()
    end

    -- Create new plant model
    local plantModel = Instance.new("Model")
    plantModel.Name = "PlantModel"
    plantModel.Parent = plotModel

    -- Get plot center position
    local plotCenter = plotModel.PrimaryPart.Position + Vector3.new(0, 0.5, 0)

    -- Create plant based on seed type and growth stage
    local seedConfig = ItemConfig.Seeds[seedType]
    local cropConfig = ItemConfig.Crops[seedConfig.resultId]

    -- Create stem/base
    local stem = Instance.new("Part")
    stem.Name = "Stem"
    stem.Size = Vector3.new(0.3, 0.5 * growthStage, 0.3)
    stem.Position = plotCenter + Vector3.new(0, stem.Size.Y/2, 0)
    stem.Anchored = true
    stem.CanCollide = false
    stem.Material = Enum.Material.Grass
    stem.Color = Color3.fromRGB(58, 125, 21)
    stem.Parent = plantModel

    -- Add leaves based on growth stage
    if growthStage >= 2 then
        for i = 1, math.min(growthStage - 1, 3) do
            local leaf = Instance.new("Part")
            leaf.Name = "Leaf_" .. i
            leaf.Size = Vector3.new(0.8, 0.1, 0.4)
            leaf.Position = stem.Position + Vector3.new(
                math.cos(i * math.pi / 2) * 0.5,
                0.2 * i,
                math.sin(i * math.pi / 2) * 0.5
            )
            leaf.Anchored = true
            leaf.CanCollide = false
            leaf.Material = Enum.Material.Grass
            leaf.Color = Color3.fromRGB(86, 171, 47)
            leaf.Parent = plantModel
        end
    end

    -- Create fruit/crop when fully grown (stage 4)
    if growthStage >= 4 then
        local crop = Instance.new("Part")
        crop.Name = "Crop"
        crop.Position = stem.Position + Vector3.new(0, stem.Size.Y/2 + 0.3, 0)
        crop.Anchored = true
        crop.CanCollide = false

        -- Set crop appearance based on type
        if seedType == "carrot_seeds" then
            crop.Color = Color3.fromRGB(255, 165, 0) -- Orange
            crop.Shape = Enum.PartType.Cylinder
            crop.Size = Vector3.new(0.4, 1, 0.4)
            crop.Orientation = Vector3.new(0, 0, 90)
        elseif seedType == "corn_seeds" then
            crop.Color = Color3.fromRGB(255, 255, 0) -- Yellow
            crop.Shape = Enum.PartType.Cylinder
            crop.Size = Vector3.new(0.5, 1.2, 0.5)
        elseif seedType == "strawberry_seeds" then
            crop.Color = Color3.fromRGB(255, 0, 100) -- Red-pink
            crop.Shape = Enum.PartType.Ball
            crop.Size = Vector3.new(0.6, 0.6, 0.6)
        elseif seedType == "golden_seeds" then
            crop.Color = Color3.fromRGB(255, 215, 0) -- Gold
            crop.Material = Enum.Material.Neon
            crop.Shape = Enum.PartType.Ball
            crop.Size = Vector3.new(0.8, 0.8, 0.8)

            -- Add golden glow effect
            local light = Instance.new("PointLight")
            light.Color = Color3.fromRGB(255, 215, 0)
            light.Range = 10
            light.Brightness = 1
            light.Parent = crop
        end

        crop.Parent = plantModel

        -- Add harvest indicator
        local harvestGui = Instance.new("BillboardGui")
        harvestGui.Size = UDim2.new(0, 100, 0, 50)
        harvestGui.StudsOffset = Vector3.new(0, 2, 0)
        harvestGui.Parent = crop

        local harvestLabel = Instance.new("TextLabel")
        harvestLabel.Size = UDim2.new(1, 0, 1, 0)
        harvestLabel.BackgroundTransparency = 1
        harvestLabel.Text = "🌾 Ready!"
        harvestLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        harvestLabel.TextScaled = true
        harvestLabel.Font = Enum.Font.GothamBold
        harvestLabel.TextStrokeTransparency = 0
        harvestLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        harvestLabel.Parent = harvestGui

        -- Pulsing effect
        local tween = game:GetService("TweenService"):Create(harvestLabel,
            TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {TextTransparency = 0.3}
        )
        tween:Play()
    end

    -- Set primary part
    plantModel.PrimaryPart = stem
end

-- Start plant growth process
function GameCore:StartPlantGrowth(plotModel, totalGrowTime)
    local plotId = plotModel:GetAttribute("PlotID")
    local seedType = plotModel:GetAttribute("PlantType")
    local stageTime = totalGrowTime / 4 -- 4 growth stages

    spawn(function()
        for stage = 2, 4 do
            wait(stageTime)

            -- Check if plot still exists and has the same crop
            if plotModel and plotModel.Parent and 
               plotModel:GetAttribute("IsPlanted") and 
               plotModel:GetAttribute("PlantType") == seedType then

                plotModel:SetAttribute("GrowthStage", stage)
                self:CreatePlantModel(plotModel, seedType, stage)

                print("GameCore: Plot " .. (plotId or "unknown") .. " " .. seedType .. " reached stage " .. stage)
            else
                print("GameCore: Growth cancelled for plot " .. (plotId or "unknown"))
                break
            end
        end
    end)
end

-- Harvest a fully grown crop
function GameCore:HarvestCrop(player, plotModel)
    local playerData = self:GetPlayerData(player)
    if not playerData then return false end

    -- Validate plot ownership
    local plotOwner = plotModel:GetAttribute("Owner")
    if plotOwner ~= player.Name then
        self:SendNotification(player, "Not Your Plot", "You can only harvest your own crops!", "error")
        return false
    end

    -- Check if plot has a crop
    if not plotModel:GetAttribute("IsPlanted") then
        self:SendNotification(player, "Empty Plot", "This plot doesn't have any crops to harvest!", "warning")
        return false
    end

    -- Check if crop is ready
    local growthStage = plotModel:GetAttribute("GrowthStage") or 0
    if growthStage < 4 then
        local progress = math.floor((growthStage / 4) * 100)
        self:SendNotification(player, "Not Ready", "Crop is only " .. progress .. "% grown. Wait a bit longer!", "warning")
        return false
    end

    -- Get crop info
    local seedType = plotModel:GetAttribute("PlantType")
    local yieldAmount = plotModel:GetAttribute("YieldAmount") or 1
    local resultCrop = plotModel:GetAttribute("ResultCrop")

    -- Get configurations
    local seedConfig = ItemConfig.Seeds[seedType]
    local cropConfig = ItemConfig.Crops[resultCrop]

    if not seedConfig or not cropConfig then
        self:SendNotification(player, "Error", "Invalid crop configuration", "error")
        return false
    end

    -- Add crops to player inventory
    local farmingData = playerData.farming or {inventory = {}}
    if not farmingData.inventory then
        farmingData.inventory = {}
    end

    farmingData.inventory[resultCrop] = (farmingData.inventory[resultCrop] or 0) + yieldAmount

    -- Calculate coin reward
    local coinReward = cropConfig.sellValue and (cropConfig.sellValue * yieldAmount) or 0
    if coinReward > 0 then
        playerData.coins = playerData.coins + coinReward
    end

    -- Update stats
    playerData.stats.cropsHarvested = (playerData.stats.cropsHarvested or 0) + yieldAmount
    if coinReward > 0 then
        playerData.stats.coinsEarned = playerData.stats.coinsEarned + coinReward
    end

    -- Clear the plot
    plotModel:SetAttribute("IsPlanted", false)
    plotModel:SetAttribute("PlantType", "")
    plotModel:SetAttribute("GrowthStage", 0)
    plotModel:SetAttribute("PlantTime", 0)
    plotModel:SetAttribute("TimeToGrow", 0)
    plotModel:SetAttribute("YieldAmount", 0)
    plotModel:SetAttribute("ResultCrop", "")

    -- Remove plant model
    local plantModel = plotModel:FindFirstChild("PlantModel")
    if plantModel then
        plantModel:Destroy()
    end

    -- Save data
    self:SavePlayerData(player)

    -- Update leaderstats and client
    self:UpdatePlayerLeaderstats(player)
    if self.RemoteEvents.PlayerDataUpdated then
        self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
    end

    -- Send success notification
    local message = "Harvested " .. yieldAmount .. "x " .. (cropConfig.name or resultCrop) .. "!"
    if coinReward > 0 then
        message = message .. " (+" .. coinReward .. " coins)"
    end
    self:SendNotification(player, "Harvest Complete!", message, "success")

    print("GameCore: " .. player.Name .. " harvested " .. yieldAmount .. "x " .. resultCrop .. " from plot")
    return true
end

-- Setup remote events for planting system
function GameCore:SetupPlantingRemoteEvents()
	-- Plant seed event
	if not self.RemoteEvents.PlantSeed then
		local plantSeedEvent = Instance.new("RemoteEvent")
		plantSeedEvent.Name = "PlantSeed"
		plantSeedEvent.Parent = game:GetService("ReplicatedStorage"):FindFirstChild("GameRemotes")
		self.RemoteEvents.PlantSeed = plantSeedEvent
	end

	-- Harvest crop event  
	if not self.RemoteEvents.HarvestCrop then
		local harvestCropEvent = Instance.new("RemoteEvent")
		harvestCropEvent.Name = "HarvestCrop"
		harvestCropEvent.Parent = game:GetService("ReplicatedStorage"):FindFirstChild("GameRemotes")
		self.RemoteEvents.HarvestCrop = harvestCropEvent
	end

	-- Connect events
	self.RemoteEvents.PlantSeed.OnServerEvent:Connect(function(player, plotModel, seedType)
		self:PlantSeed(player, plotModel, seedType)
	end)

	self.RemoteEvents.HarvestCrop.OnServerEvent:Connect(function(player, plotModel)
		self:HarvestPlot(plotModel, player)
	end)

	print("GameCore: Planting remote events setup complete")
end


-- Call this in your GameCore:Initialize() function
-- Add this line to your GameCore:Initialize():
-- self:SetupPlantingRemoteEvents()

function GameCore:FeedPig(player, cropId)
	print("GameCore: FeedPig called - implement farming system")
end

function GameCore:SellMultiplePets(player, petIds)
	for _, petId in ipairs(petIds) do
		self:SellPet(player, petId)
		wait(0.1)
	end
end

return GameCore