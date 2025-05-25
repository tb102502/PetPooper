-- Pet Collection Simulator
-- Enhanced Monetization System (Script in ServerScriptService)

-- Services
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Setup Developer Products and Game Passes
-- In a real game, you'd create these in the Roblox Developer dashboard and use their IDs
local DeveloperProducts = {
	SmallCoins = {
		id = 0000001, -- Replace with actual ID
		name = "100 Coins",
		coinsAmount = 100
	},
	MediumCoins = {
		id = 0000002, -- Replace with actual ID
		name = "500 Coins",
		coinsAmount = 550 -- 10% bonus
	},
	LargeCoins = {
		id = 0000003, -- Replace with actual ID
		name = "1000 Coins",
		coinsAmount = 1200 -- 20% bonus
	},
	-- NEW: Premium currency
	SmallGems = {
		id = 0000004, -- Replace with actual ID
		name = "50 Gems",
		gemsAmount = 50
	},
	MediumGems = {
		id = 0000005, -- Replace with actual ID
		name = "250 Gems",
		gemsAmount = 275 -- 10% bonus
	},
	LargeGems = {
		id = 0000006, -- Replace with actual ID
		name = "500 Gems",
		gemsAmount = 600 -- 20% bonus
	},
	-- NEW: Boosts
	LuckBoost = {
		id = 0000007, -- Replace with actual ID
		name = "Lucky Collector (30min)",
		boostType = "Luck",
		duration = 1800, -- 30 minutes in seconds
		multiplier = 2 -- Double rare pet chance
	},
	CoinBoost = {
		id = 0000008, -- Replace with actual ID
		name = "2x Coins (1 hour)",
		boostType = "Coins",
		duration = 3600, -- 1 hour in seconds
		multiplier = 2 -- Double coins
	}
}

local GamePasses = {
	VIP = {
		id = 0000001, -- Replace with actual ID
		name = "VIP Pass",
		benefits = {
			coinMultiplier = 2, -- Earn 2x coins
			exclusivePets = true -- Access to VIP-only pets
		}
	},
	AutoCollect = {
		id = 0000002, -- Replace with actual ID
		name = "Auto-Collect Pass",
		benefits = {
			autoCollect = true -- Automatically collect nearby pets
		}
	},
	-- NEW: Additional game passes
	SuperPets = {
		id = 0000003, -- Replace with actual ID
		name = "Super Pets Pass",
		benefits = {
			petLevelBoost = 2, -- Pets level up twice as fast
			petStats = 1.5 -- Pets give 50% more coins
		}
	},
	FastHatch = {
		id = 0000004, -- Replace with actual ID
		name = "Fast Hatch Pass",
		benefits = {
			hatchSpeed = 2, -- Hatch pets twice as fast
			tripleHatch = true -- Hatch 3 pets at once
		}
	},
	UltraLuck = {
		id = 0000005, -- Replace with actual ID
		name = "Ultra Luck Pass",
		benefits = {
			rarityChance = 3, -- Triple chance for rare pets
			legendaryBonus = true -- Chance for bonus legendary pets
		}
	},
	ExtraStorage = {
		id = 0000006, -- Replace with actual ID
		name = "Extra Storage Pass",
		benefits = {
			petStorage = 200, -- +200 pet storage slots
			permanentBoost = true -- Small permanent boost to all stats
		}
	}
}

-- NEW: Premium Pets (only available with gems)
local PremiumPets = {
	GoldenCorgi = {
		name = "Golden Corgi",
		gemCost = 250,
		rarity = "Premium",
		collectValue = 50,
		modelName = "GoldenCorgi", -- Would need to be created
		chance = 0 -- Not obtainable normally
	},
	RobotPanda = {
		name = "Robot Panda",
		gemCost = 500,
		rarity = "Premium",
		collectValue = 150,
		modelName = "RobotPanda", -- Would need to be created
		chance = 0 -- Not obtainable normally
	},
	DiamondDragon = {
		name = "Diamond Dragon",
		gemCost = 1000,
		rarity = "Premium",
		collectValue = 300,
		modelName = "DiamondDragon", -- Would need to be created
		chance = 0 -- Not obtainable normally
	}
}

-- NEW: VIP Exclusive Pets
local VIPPets = {
	RainbowCorgi = {
		name = "Rainbow Corgi",
		rarity = "VIP",
		collectValue = 75,
		modelName = "RainbowCorgi", -- Would need to be created
		chance = 0 -- VIP exclusive
	},
	GalaxyPanda = {
		name = "Galaxy Panda",
		rarity = "VIP",
		collectValue = 200,
		modelName = "GalaxyPanda", -- Would need to be created
		chance = 0 -- VIP exclusive
	}
}

-- NEW: Limited Time Event Pets
local EventPets = {
	-- Easter Event (example)
	EasterBunny = {
		name = "Easter Bunny",
		rarity = "Event",
		collectValue = 150,
		modelName = "EasterBunny", -- Would need to be created
		chance = 0, -- Special drop during event
		eventName = "Easter"
	},
	-- Halloween Event (example)
	SpookyCorgi = {
		name = "Spooky Corgi",
		rarity = "Event",
		collectValue = 150,
		modelName = "SpookyCorgi", -- Would need to be created
		chance = 0, -- Special drop during event
		eventName = "Halloween"
	}
}

-- NEW: Enhanced Upgrades
local EnhancedUpgrades = {
	-- Coin upgrades
	CoinMagnet = {
		name = "Coin Magnet",
		description = "Increase collection radius",
		type = "Permanent", 
		baseCost = 750,
		costMultiplier = 1.8,
		maxLevel = 10,
		effectPerLevel = 0.5, -- +0.5 stud radius per level
		purchaseWith = "Coins"
	},
	-- Pet upgrades
	PetStorage = {
		name = "Pet Storage",
		description = "Increase maximum pets",
		type = "Permanent",
		baseCost = 1000,
		costMultiplier = 2,
		maxLevel = 10,
		effectPerLevel = 10, -- +10 pet slots per level
		purchaseWith = "Coins"
	},
	PetLuck = {
		name = "Pet Luck",
		description = "Increased rare pet chance",
		type = "Permanent",
		baseCost = 100,
		costMultiplier = 2.5,
		maxLevel = 10,
		effectPerLevel = 0.1, -- +10% chance per level
		purchaseWith = "Gems"
	},
	-- Quick boosts
	DoubleCoins = {
		name = "Double Coins",
		description = "2x coins for 10 minutes",
		type = "Temporary",
		duration = 600, -- 10 minutes
		cost = 50,
		effect = 2, -- Double
		purchaseWith = "Gems"
	},
	TripleEXP = {
		name = "Triple EXP",
		description = "3x pet experience for 10 minutes",
		type = "Temporary",
		duration = 600, -- 10 minutes
		cost = 75,
		effect = 3, -- Triple
		purchaseWith = "Gems"
	},
	SuperLuck = {
		name = "Super Luck",
		description = "5x legendary chance for 5 minutes",
		type = "Temporary",
		duration = 300, -- 5 minutes
		cost = 100,
		effect = 5, -- 5x chance
		purchaseWith = "Gems"
	}
}

-- Player data cache
local PlayerDataCache = {}

-- Function to load player data
local function GetPlayerData(player)
	if not PlayerDataCache[player.UserId] then
		-- Would normally load from DataStore in a real game
		-- Default data for this example
		PlayerDataCache[player.UserId] = {
			coins = 0,
			gems = 0,
			pets = {},
			unlockedAreas = {"Starter Meadow"},
			upgrades = {
				["Collection Speed"] = 1,
				["Pet Capacity"] = 1,
				["Collection Value"] = 1,
				-- Add new upgrades
				["Coin Magnet"] = 0,
				["Pet Luck"] = 0,
				["Pet Storage"] = 0
			},
			ownedGamePasses = {},
			activeBoosts = {}, -- Track active boosts and their expiration times
			boostHistory = {}, -- Track all purchased boosts
			stats = {
				totalPetsCollected = 0,
				rareFound = 0,
				epicFound = 0,
				legendaryFound = 0,
				playtime = 0,
				coinsSpent = 0,
				gemsSpent = 0,
				robuxSpent = 0 -- Estimated based on product purchases
			}
		}
	end

	return PlayerDataCache[player.UserId]
end

-- Function to update player data
local function SavePlayerData(player)
	-- Would normally save to DataStore in a real game
	print("Saving data for player: " .. player.Name)
end

-- Function to add coins to a player
local function AddCoins(player, amount)
	local playerData = GetPlayerData(player)

	-- Check if player has VIP for coin multiplier
	if playerData.ownedGamePasses.VIP then
		amount = amount * GamePasses.VIP.benefits.coinMultiplier
	end

	-- Check for active coin boost
	for boostId, boostData in pairs(playerData.activeBoosts) do
		if boostData.type == "Coins" and boostData.expires > os.time() then
			amount = amount * boostData.multiplier
			break -- Only apply one coin boost at a time
		end
	end

	playerData.coins = playerData.coins + amount

	-- Update the client
	ReplicatedStorage.RemoteEvents.UpdatePlayerStats:FireClient(player, playerData)

	return true
end

-- Function to add gems to a player
local function AddGems(player, amount)
	local playerData = GetPlayerData(player)
	playerData.gems = playerData.gems + amount

	-- Update the client
	ReplicatedStorage.RemoteEvents.UpdatePlayerStats:FireClient(player, playerData)

	return true
end

-- NEW: Function to add a boost to a player
local function AddBoost(player, boostType, duration, multiplier, name)
	local playerData = GetPlayerData(player)

	-- Create a unique ID for the boost
	local boostId = boostType .. "_" .. os.time() .. "_" .. math.random(1000, 9999)

	-- Store the boost data
	playerData.activeBoosts[boostId] = {
		id = boostId,
		name = name,
		type = boostType,
		multiplier = multiplier,
		started = os.time(),
		expires = os.time() + duration
	}

	-- Add to boost history
	table.insert(playerData.boostHistory, {
		type = boostType,
		multiplier = multiplier,
		duration = duration,
		purchaseTime = os.time()
	})

	-- Notify the player
	ReplicatedStorage.RemoteEvents.SendNotification:FireClient(
		player, 
		"Boost Activated!", 
		name .. " is now active for " .. math.floor(duration/60) .. " minutes!",
		"boost" -- Icon name
	)

	-- Update the client
	ReplicatedStorage.RemoteEvents.UpdatePlayerStats:FireClient(player, playerData)

	-- Schedule boost expiration
	spawn(function()
		wait(duration)
		if playerData.activeBoosts[boostId] then
			playerData.activeBoosts[boostId] = nil

			ReplicatedStorage.RemoteEvents.SendNotification:FireClient(
				player, 
				"Boost Expired", 
				name .. " has expired.",
				"boost" -- Icon name
			)

			-- Update the client
			ReplicatedStorage.RemoteEvents.UpdatePlayerStats:FireClient(player, playerData)
		end
	end)

	return true
end

-- NEW: Function to check if a player has an active boost
local function HasActiveBoost(player, boostType)
	local playerData = GetPlayerData(player)

	for _, boostData in pairs(playerData.activeBoosts) do
		if boostData.type == boostType and boostData.expires > os.time() then
			return true, boostData
		end
	end

	return false, nil
end

-- Process a developer product purchase
local function ProcessDevProductPurchase(player, productId)
	-- Find which product was purchased
	local productInfo = nil
	for _, product in pairs(DeveloperProducts) do
		if product.id == productId then
			productInfo = product
			break
		end
	end

	if not productInfo then
		warn("Unknown product ID: " .. productId)
		return false
	end

	-- Track estimated Robux spent (in a real game, you'd use a better estimation)
	local playerData = GetPlayerData(player)
	playerData.stats.robuxSpent = playerData.stats.robuxSpent + (productInfo.coinsAmount and productInfo.coinsAmount/10 or productInfo.gemsAmount or 100)

	-- Add the appropriate reward
	if productInfo.coinsAmount then
		AddCoins(player, productInfo.coinsAmount)
		print("Added " .. productInfo.coinsAmount .. " coins to " .. player.Name)
	elseif productInfo.gemsAmount then
		AddGems(player, productInfo.gemsAmount)
		print("Added " .. productInfo.gemsAmount .. " gems to " .. player.Name)
	elseif productInfo.boostType then
		AddBoost(player, productInfo.boostType, productInfo.duration, productInfo.multiplier, productInfo.name)
		print("Added " .. productInfo.name .. " boost to " .. player.Name)
	end

	-- Send a thank you notification
	ReplicatedStorage.RemoteEvents.SendNotification:FireClient(
		player, 
		"Thank You!", 
		"Your purchase of " .. productInfo.name .. " was successful!",
		"purchase" -- Icon name
	)

	return true
end

-- Check if a player owns a game pass
local function OwnsGamePass(player, gamePassId)
	-- First check the cache
	local playerData = GetPlayerData(player)
	if playerData.ownedGamePasses[gamePassId] then
		return true
	end

	-- Then check with MarketplaceService
	local success, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePassId)
	end)

	if success and result then
		-- Update the cache
		playerData.ownedGamePasses[gamePassId] = true
		return true
	end

	return false
end

-- Process a game pass purchase
local function ProcessGamePassPurchase(player, gamePassId)
	-- Find which game pass was purchased
	local gamePassInfo = nil
	for _, gamePass in pairs(GamePasses) do
		if gamePass.id == gamePassId then
			gamePassInfo = gamePass
			break
		end
	end

	if not gamePassInfo then
		warn("Unknown game pass ID: " .. gamePassId)
		return
	end

	-- Update player data
	local playerData = GetPlayerData(player)
	playerData.ownedGamePasses[gamePassInfo.name] = true

	-- Track estimated Robux spent (in a real game, you'd use a better estimation)
	local estimatedRobuxCost = 0
	if gamePassInfo.name == "VIP Pass" then
		estimatedRobuxCost = 399
	elseif gamePassInfo.name == "Auto-Collect Pass" then
		estimatedRobuxCost = 249
	elseif gamePassInfo.name == "Super Pets Pass" then
		estimatedRobuxCost = 349
	elseif gamePassInfo.name == "Fast Hatch Pass" then
		estimatedRobuxCost = 299
	elseif gamePassInfo.name == "Ultra Luck Pass" then
		estimatedRobuxCost = 499
	elseif gamePassInfo.name == "Extra Storage Pass" then
		estimatedRobuxCost = 349
	end
	playerData.stats.robuxSpent = playerData.stats.robuxSpent + estimatedRobuxCost

	-- Apply immediate benefits
	if gamePassInfo.name == "VIP Pass" then
		-- Maybe give a welcome gift of coins/gems
		AddCoins(player, 1000)
		AddGems(player, 50)

		-- Notify the player
		ReplicatedStorage.RemoteEvents.SendNotification:FireClient(
			player, 
			"VIP Activated!", 
			"You now earn 2x coins and have access to exclusive pets!",
			"vip" -- Icon name
		)
	elseif gamePassInfo.name == "Auto-Collect Pass" then
		-- Notify the player
		ReplicatedStorage.RemoteEvents.SendNotification:FireClient(
			player, 
			"Auto-Collect Activated!", 
			"Your character will now automatically collect nearby pets!",
			"autocollect" -- Icon name
		)
	elseif gamePassInfo.name == "Super Pets Pass" then
		-- Notify the player
		ReplicatedStorage.RemoteEvents.SendNotification:FireClient(
			player, 
			"Super Pets Activated!", 
			"Your pets will now level up faster and give more coins!",
			"superpets" -- Icon name
		)
	elseif gamePassInfo.name == "Fast Hatch Pass" then
		-- Notify the player
		ReplicatedStorage.RemoteEvents.SendNotification:FireClient(
			player, 
			"Fast Hatch Activated!", 
			"You can now hatch pets faster and three at once!",
			"fasthatch" -- Icon name
		)
	elseif gamePassInfo.name == "Ultra Luck Pass" then
		-- Notify the player
		ReplicatedStorage.RemoteEvents.SendNotification:FireClient(
			player, 
			"Ultra Luck Activated!", 
			"Your chance for rare and legendary pets is now greatly increased!",
			"ultraluck" -- Icon name
		)
	elseif gamePassInfo.name == "Extra Storage Pass" then
		-- Add the storage capacity
		playerData.maxPets = (playerData.maxPets or 100) + 200

		-- Notify the player
		ReplicatedStorage.RemoteEvents.SendNotification:FireClient(
			player, 
			"Extra Storage Activated!", 
			"You now have 200 more pet storage slots and a permanent stat boost!",
			"storage" -- Icon name
		)
	end

	-- Update the client
	ReplicatedStorage.RemoteEvents.UpdatePlayerStats:FireClient(player, playerData)

	-- For Auto-Collect, tell the client to start the auto-collection
	if gamePassInfo.name == "Auto-Collect Pass" then
		ReplicatedStorage.RemoteEvents.EnableAutoCollect:FireClient(player)
	end

	print(player.Name .. " purchased " .. gamePassInfo.name)
end

-- NEW: Function to purchase a premium pet with gems
local function PurchasePremiumPet(player, petName)
	local playerData = GetPlayerData(player)

	-- Find the pet in the premium pets list
	local petInfo = nil
	for _, pet in pairs(PremiumPets) do
		if pet.name == petName then
			petInfo = pet
			break
		end
	end

	if not petInfo then
		-- Check if it's a VIP pet
		for _, pet in pairs(VIPPets) do
			if pet.name == petName then
				petInfo = pet

				-- Check if player has VIP
				if not playerData.ownedGamePasses.VIP then
					ReplicatedStorage.RemoteEvents.SendNotification:FireClient(
						player, 
						"VIP Required", 
						"You need the VIP Pass to unlock this pet!",
						"vip" -- Icon name
					)
					return false
				end

				break
			end
		end

		if not petInfo then
			warn("Unknown premium pet: " .. petName)
			return false
		end
	end

	-- Check if player has enough gems
	if petInfo.gemCost and playerData.gems < petInfo.gemCost then
		ReplicatedStorage.RemoteEvents.SendNotification:FireClient(
			player, 
			"Not Enough Gems", 
			"You need " .. petInfo.gemCost .. " gems to purchase this pet!",
			"gems" -- Icon name
		)
		return false
	end

	-- Deduct gems if necessary
	if petInfo.gemCost then
		playerData.gems = playerData.gems - petInfo.gemCost
		playerData.stats.gemsSpent = playerData.stats.gemsSpent + petInfo.gemCost
	end

	-- Create the pet entry
	local newPet = {
		id = os.time() .. "-" .. math.random(1000, 9999),
		name = petInfo.name,
		rarity = petInfo.rarity,
		level = 1,
		modelName = petInfo.modelName
	}

	-- Add to collection
	table.insert(playerData.pets, newPet)

	-- Notify the player
	ReplicatedStorage.RemoteEvents.SendNotification:FireClient(
		player, 
		"New Pet!", 
		"You have acquired a " .. petInfo.rarity .. " " .. petInfo.name .. "!",
		"newpet" -- Icon name
	)

	-- Update the client
	ReplicatedStorage.RemoteEvents.UpdatePlayerStats:FireClient(player, playerData)

	print(player.Name .. " purchased a " .. petInfo.name .. " pet")
	return true
end

-- NEW: Function to purchase a temporary boost with gems
local function PurchaseTemporaryBoost(player, boostName)
	local playerData = GetPlayerData(player)

	-- Find the boost in the enhanced upgrades
	local boostInfo = nil
	for _, upgrade in pairs(EnhancedUpgrades) do
		if upgrade.name == boostName and upgrade.type == "Temporary" then
			boostInfo = upgrade
			break
		end
	end

	if not boostInfo then
		warn("Unknown temporary boost: " .. boostName)
		return false
	end

	-- Check if player has enough gems
	if playerData.gems < boostInfo.cost then
		ReplicatedStorage.RemoteEvents.SendNotification:FireClient(
			player, 
			"Not Enough Gems", 
			"You need " .. boostInfo.cost .. " gems to purchase this boost!",
			"gems" -- Icon name
		)
		return false
	end

	-- Deduct gems
	playerData.gems = playerData.gems - boostInfo.cost
	playerData.stats.gemsSpent = playerData.stats.gemsSpent + boostInfo.cost

	-- Add the boost
	local boostType = boostName:gsub(" ", "")
	AddBoost(player, boostType, boostInfo.duration, boostInfo.effect, boostInfo.name)

	-- Update the client
	ReplicatedStorage.RemoteEvents.UpdatePlayerStats:FireClient(player, playerData)

	print(player.Name .. " purchased a " .. boostInfo.name .. " boost")
	return true
end

-- NEW: Function to purchase a permanent upgrade with coins or gems
local function PurchasePermanentUpgrade(player, upgradeName)
	local playerData = GetPlayerData(player)

	-- Find the upgrade
	local upgradeInfo = nil
	for _, upgrade in pairs(EnhancedUpgrades) do
		if upgrade.name == upgradeName and upgrade.type == "Permanent" then
			upgradeInfo = upgrade
			break
		end
	end

	if not upgradeInfo then
		warn("Unknown permanent upgrade: " .. upgradeName)
		return false
	end

	-- Get current level
	local currentLevel = playerData.upgrades[upgradeName] or 0

	-- Check if already at max level
	if currentLevel >= upgradeInfo.maxLevel then
		ReplicatedStorage.RemoteEvents.SendNotification:FireClient(
			player, 
			"Max Level", 
			upgradeName .. " is already at maximum level!",
			"upgrade" -- Icon name
		)
		return false
	end

	-- Calculate cost
	local cost = upgradeInfo.baseCost * (upgradeInfo.costMultiplier ^ currentLevel)

	-- Check if player has enough currency
	if upgradeInfo.purchaseWith == "Coins" and playerData.coins < cost then
		ReplicatedStorage.RemoteEvents.SendNotification:FireClient(
			player, 
			"Not Enough Coins", 
			"You need " .. math.floor(cost) .. " coins to purchase this upgrade!",
			"coins" -- Icon name
		)
		return false
	elseif upgradeInfo.purchaseWith == "Gems" and playerData.gems < cost then
		ReplicatedStorage.RemoteEvents.SendNotification:FireClient(
			player, 
			"Not Enough Gems", 
			"You need " .. math.floor(cost) .. " gems to purchase this upgrade!",
			"gems" -- Icon name
		)
		return false
	end

	-- Deduct currency
	if upgradeInfo.purchaseWith == "Coins" then
		playerData.coins = playerData.coins - cost
		playerData.stats.coinsSpent = playerData.stats.coinsSpent + cost
	else -- Gems
		playerData.gems = playerData.gems - cost
		playerData.stats.gemsSpent = playerData.stats.gemsSpent + cost
	end

	-- Increase upgrade level
	playerData.upgrades[upgradeName] = currentLevel + 1

	-- Notify the player
	ReplicatedStorage.RemoteEvents.SendNotification:FireClient(
		player, 
		"Upgrade Purchased!", 
		upgradeName .. " is now level " .. (currentLevel + 1) .. "!",
		"upgrade" -- Icon name
	)

	-- Update the client
	ReplicatedStorage.RemoteEvents.UpdatePlayerStats:FireClient(player, playerData)

	print(player.Name .. " purchased " .. upgradeName .. " level " .. (currentLevel + 1))
	return true
end

-- Connect MarketplaceService events
MarketplaceService.ProcessReceipt = function(receiptInfo)
	-- Get the player from the receipt
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Player probably left the game
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Process the purchase
	local success = ProcessDevProductPurchase(player, receiptInfo.ProductId)

	if success then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

-- Connect to GamePassPurchased event
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	if wasPurchased then
		ProcessGamePassPurchase(player, gamePassId)
	end
end)

-- Remote function to check if a player owns a game pass
local function HandleCheckGamePassOwnership(player, gamePassName)
	for _, gamePass in pairs(GamePasses) do
		if gamePass.name == gamePassName then
			return OwnsGamePass(player, gamePass.id)
		end
	end
	return false
end

-- Remote function to prompt a purchase
local function HandlePromptPurchase(player, itemType, itemName)
	if itemType == "GamePass" then
		for _, gamePass in pairs(GamePasses) do
			if gamePass.name == itemName then
				MarketplaceService:PromptGamePassPurchase(player, gamePass.id)
				return true
			end
		end
	elseif itemType == "DevProduct" then
		for _, product in pairs(DeveloperProducts) do
			if product.name == itemName then
				MarketplaceService:PromptProductPurchase(player, product.id)
				return true
			end
		end
	elseif itemType == "PremiumPet" then
		return PurchasePremiumPet(player, itemName)
	elseif itemType == "TemporaryBoost" then
		return PurchaseTemporaryBoost(player, itemName)
	elseif itemType == "PermanentUpgrade" then
		return PurchasePermanentUpgrade(player, itemName)
	end
	return false
end

-- Setup remote functions
local CheckGamePassOwnership = ReplicatedStorage.RemoteFunctions:FindFirstChild("CheckGamePassOwnership")
if not CheckGamePassOwnership then
	CheckGamePassOwnership = Instance.new("RemoteFunction")
	CheckGamePassOwnership.Name = "CheckGamePassOwnership"
	CheckGamePassOwnership.Parent = ReplicatedStorage.RemoteFunctions
end
CheckGamePassOwnership.OnServerInvoke = HandleCheckGamePassOwnership

local PromptPurchase = ReplicatedStorage.RemoteFunctions:FindFirstChild("PromptPurchase")
if not PromptPurchase then
	PromptPurchase = Instance.new("RemoteFunction")
	PromptPurchase.Name = "PromptPurchase"
	PromptPurchase.Parent = ReplicatedStorage.RemoteFunctions
end
PromptPurchase.OnServerInvoke = HandlePromptPurchase

-- NEW: Remote function to get available premium pets and boosts
local GetShopItems = ReplicatedStorage.RemoteFunctions:FindFirstChild("GetShopItems")
if not GetShopItems then
	GetShopItems = Instance.new("RemoteFunction")
	GetShopItems.Name = "GetShopItems"
	GetShopItems.Parent = ReplicatedStorage.RemoteFunctions
end

GetShopItems.OnServerInvoke = function(player)
	return {
		DeveloperProducts = DeveloperProducts,
		GamePasses = GamePasses,
		PremiumPets = PremiumPets,
		VIPPets = VIPPets,
		EventPets = EventPets,
		Upgrades = EnhancedUpgrades
	}
end

-- Player added event to check existing game passes
Players.PlayerAdded:Connect(function(player)
	-- Get player data
	local playerData = GetPlayerData(player)

	-- Check for owned game passes
	for _, gamePass in pairs(GamePasses) do
		if OwnsGamePass(player, gamePass.id) then
			playerData.ownedGamePasses[gamePass.name] = true

			-- If the player owns Auto-Collect, enable it
			if gamePass.name == "Auto-Collect Pass" then
				ReplicatedStorage.RemoteEvents.EnableAutoCollect:FireClient(player)
			end

			-- If they own VIP, update UI to show VIP-only content
			if gamePass.name == "VIP Pass" then
				ReplicatedStorage.RemoteEvents.UpdateVIPStatus:FireClient(player, true)
			end
		end
	end

	-- Update player with their data
	ReplicatedStorage.RemoteEvents.UpdatePlayerStats:FireClient(player, playerData)
end)

-- Create necessary remote events if they don't exist yet
local function ensureRemoteEventExists(name)
	if not ReplicatedStorage.RemoteEvents:FindFirstChild(name) then
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = ReplicatedStorage.RemoteEvents
		return event
	end
	return ReplicatedStorage.RemoteEvents:FindFirstChild(name)
end

-- Setup additional remote events
ensureRemoteEventExists("SendNotification")
ensureRemoteEventExists("EnableAutoCollect")
ensureRemoteEventExists("UpdateVIPStatus")
ensureRemoteEventExists("BoostActivated")
ensureRemoteEventExists("BoostExpired")

-- Remove expired boosts
spawn(function()
	while true do
		wait(60) -- Check every minute

		for _, player in pairs(Players:GetPlayers()) do
			local playerData = GetPlayerData(player)
			local needsUpdate = false

			-- Check each boost
			for boostId, boostData in pairs(playerData.activeBoosts) do
				if boostData.expires < os.time() then
					-- Boost has expired
					playerData.activeBoosts[boostId] = nil
					needsUpdate = true

					-- Notify player
					ReplicatedStorage.RemoteEvents.BoostExpired:FireClient(player, boostId, boostData.name)
				end
			end

			-- Update client if any boosts were removed
			if needsUpdate then
				ReplicatedStorage.RemoteEvents.UpdatePlayerStats:FireClient(player, playerData)
			end
		end
	end
end)

print("Enhanced Monetization system initialized!")