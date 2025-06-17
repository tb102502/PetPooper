--[[
    Server Startup Script - Complete Farm Game Integration
    Place in: ServerScriptService/ServerStartup.server.lua
    
    This script initializes all systems in the correct order and ensures
    everything works together properly.
]]

print("=== 🚀 FARM GAME SERVER STARTUP ===")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- ========== STEP 1: LOAD CORE MODULES ==========

print("📦 Step 1: Loading core modules...")

-- Load GameCore
local GameCore = require(ServerScriptService.Core.GameCore)
if not GameCore then
	error("❌ Failed to load GameCore!")
end
print("✅ GameCore loaded")

-- Load ShopSystem
local ShopSystem = require(ServerScriptService.Systems.ShopSystem)
if not ShopSystem then
	error("❌ Failed to load ShopSystem!")
end
print("✅ ShopSystem loaded")

-- Load ItemConfig (verify it's accessible)
local ItemConfig = require(ReplicatedStorage.ItemConfig)
if not ItemConfig then
	error("❌ Failed to load ItemConfig!")
end
print("✅ ItemConfig loaded")

-- ========== STEP 2: INITIALIZE SYSTEMS ==========

print("🔧 Step 2: Initializing systems...")

-- Initialize ShopSystem first
local shopSuccess = ShopSystem:Initialize(GameCore)
if not shopSuccess then
	error("❌ Failed to initialize ShopSystem!")
end
print("✅ ShopSystem initialized")

-- Initialize GameCore with ShopSystem reference
local coreSuccess = GameCore:Initialize(ShopSystem)
if not coreSuccess then
	error("❌ Failed to initialize GameCore!")
end
print("✅ GameCore initialized")

-- ========== STEP 3: VERIFY INTEGRATION ==========

print("🔍 Step 3: Verifying system integration...")

-- Test ItemConfig integration
local testItems = ItemConfig.GetAllShopItems()
if not testItems or not next(testItems) then
	error("❌ ItemConfig has no shop items!")
end
print("✅ ItemConfig has " .. (function() local count = 0; for _ in pairs(testItems) do count = count + 1 end return count end)() .. " shop items")

-- Test remote connections
local remotes = ReplicatedStorage:FindFirstChild("GameRemotes")
if not remotes then
	error("❌ GameRemotes folder not found!")
end

local requiredRemotes = {
	"GetShopItems", "PurchaseItem", "SellItem", "PlantSeed", 
	"HarvestCrop", "CollectMilk", "PlayerDataUpdated"
}

for _, remoteName in ipairs(requiredRemotes) do
	local remote = remotes:FindFirstChild(remoteName)
	if not remote then
		warn("⚠️ Missing remote: " .. remoteName)
	else
		print("✅ Remote found: " .. remoteName)
	end
end

-- ========== STEP 4: SETUP PLAYER MANAGEMENT ==========

print("👥 Step 4: Setting up player management...")

-- Enhanced player join handling
local function handlePlayerAdded(player)
	print("🎮 Player joined: " .. player.Name)

	-- Wait a moment for character to load
	wait(1)

	-- Initialize player data through GameCore
	local playerData = GameCore:GetPlayerData(player)
	if playerData then
		print("✅ Player data initialized for " .. player.Name)

		-- Send welcome message
		wait(2)
		GameCore:SendNotification(player, "🎉 Welcome to Pet Palace Farm!", 
			"Visit the shop to buy your first farm plot and start growing crops!\n\n🌱 Press F to open farming menu\n🛒 Walk to the shop building to buy items", "success")
	else
		warn("❌ Failed to initialize player data for " .. player.Name)
	end
end

-- Connect player events
Players.PlayerAdded:Connect(handlePlayerAdded)

-- Handle existing players
for _, player in pairs(Players:GetPlayers()) do
	spawn(function()
		handlePlayerAdded(player)
	end)
end

-- ========== STEP 5: ADMIN TOOLS SETUP ==========

print("🔧 Step 5: Setting up admin tools...")

-- Global admin functions for easy debugging
_G.AdminTools = {
	-- Quick player setup
	SetupPlayer = function(playerName)
		local player = Players:FindFirstChild(playerName)
		if not player then
			print("❌ Player not found: " .. playerName)
			return false
		end

		local playerData = GameCore:GetPlayerData(player)
		if not playerData then
			print("❌ No player data for: " .. playerName)
			return false
		end

		-- Give starter resources
		playerData.coins = 10000
		playerData.farmTokens = 100

		-- Give farm plot
		playerData.purchaseHistory = playerData.purchaseHistory or {}
		playerData.purchaseHistory.farm_plot_starter = true
		playerData.farming = {
			plots = 1,
			inventory = {
				carrot_seeds = 20,
				corn_seeds = 15,
				strawberry_seeds = 10,
				wheat_seeds = 15,
				potato_seeds = 12,
				tomato_seeds = 8
			}
		}

		-- Create farm plot
		GameCore:CreatePlayerFarmPlot(player, 1)

		-- Save and update
		GameCore:SavePlayerData(player)
		GameCore:UpdatePlayerLeaderstats(player)

		if GameCore.RemoteEvents.PlayerDataUpdated then
			GameCore.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
		end

		GameCore:SendNotification(player, "🎁 Admin Setup Complete!", 
			"You've been given starter resources and a farm plot!", "success")

		print("✅ Player setup complete for: " .. playerName)
		return true
	end,

	-- Test shop system
	TestShop = function(playerName)
		local player = Players:FindFirstChild(playerName or "")
		if not player then
			print("❌ Player not found")
			return
		end

		local items = ShopSystem:HandleGetShopItems(player)
		print("🛒 Shop test results:")
		print("  Total items: " .. #items)

		local categories = {}
		for _, item in ipairs(items) do
			categories[item.category] = (categories[item.category] or 0) + 1
		end

		for category, count in pairs(categories) do
			print("  " .. category .. ": " .. count .. " items")
		end

		return items
	end,

	-- Test farming system
	TestFarming = function(playerName)
		local player = Players:FindFirstChild(playerName or "")
		if not player then
			print("❌ Player not found")
			return
		end

		local playerData = GameCore:GetPlayerData(player)
		if not playerData or not playerData.farming then
			print("❌ No farming data")
			return
		end

		print("🌾 Farming test results:")
		print("  Farm plots: " .. (playerData.farming.plots or 0))
		print("  Inventory items: " .. (function() 
			local count = 0
			for _ in pairs(playerData.farming.inventory or {}) do count = count + 1 end
			return count
		end)())

		for itemId, quantity in pairs(playerData.farming.inventory or {}) do
			print("    " .. itemId .. ": " .. quantity)
		end
	end,

	-- Test rarity system
	TestRarity = function()
		print("🌟 Testing rarity system...")

		local seeds = {"carrot_seeds", "corn_seeds", "strawberry_seeds", "golden_seeds"}
		for _, seedId in ipairs(seeds) do
			print("  " .. seedId .. " rarity chances:")
			for i = 1, 10 do
				local rarity = ItemConfig.GetCropRarity(seedId)
				print("    Roll " .. i .. ": " .. rarity)
			end
		end
	end,

	-- Debug all systems
	DebugAll = function()
		print("=== 🔍 COMPLETE SYSTEM DEBUG ===")

		-- System status
		print("📊 System Status:")
		print("  GameCore: " .. (GameCore and "✅ Active" or "❌ Failed"))
		print("  ShopSystem: " .. (ShopSystem and "✅ Active" or "❌ Failed"))
		print("  ItemConfig: " .. (ItemConfig and "✅ Active" or "❌ Failed"))

		-- ItemConfig stats
		if ItemConfig and ItemConfig.ShopItems then
			local itemCount = 0
			local categories = {}
			for itemId, item in pairs(ItemConfig.ShopItems) do
				itemCount = itemCount + 1
				categories[item.category] = (categories[item.category] or 0) + 1
			end

			print("📦 ItemConfig Stats:")
			print("  Total items: " .. itemCount)
			for category, count in pairs(categories) do
				print("  " .. category .. ": " .. count)
			end
		end

		-- Player count
		print("👥 Players online: " .. #Players:GetPlayers())

		print("================================")
	end
}

-- ========== STEP 6: FINAL VERIFICATION ==========

print("✅ Step 6: Final system verification...")

-- Test critical functions
local testSuccess = pcall(function()
	-- Test ItemConfig functions
	local testRarity = ItemConfig.GetCropRarity("carrot_seeds")
	local testCropData = ItemConfig.GetCropData("carrot")
	local testSeedData = ItemConfig.GetSeedData("carrot_seeds")

	if not testRarity or not testCropData or not testSeedData then
		error("ItemConfig functions failed")
	end

	print("✅ ItemConfig functions working")

	-- Test shop item access
	local allItems = ItemConfig.GetAllShopItems()
	if not allItems or not next(allItems) then
		error("No shop items available")
	end

	print("✅ Shop items accessible")

	return true
end)

if not testSuccess then
	error("❌ System verification failed!")
end

-- ========== STARTUP COMPLETE ==========

print("🎉 =================================")
print("🎉 FARM GAME SERVER STARTUP COMPLETE!")
print("🎉 =================================")
print("")
print("📊 System Summary:")
print("  🎮 GameCore: ACTIVE with enhanced farming & rarity")
print("  🛒 ShopSystem: ACTIVE with complete item catalog")
print("  📦 ItemConfig: " .. (function() local count = 0; for _ in pairs(ItemConfig.ShopItems) do count = count + 1 end return count end)() .. " shop items loaded")
print("  🌟 Rarity System: 5 tiers (Common to Legendary)")
print("  🌱 Farming System: Complete with all seed types")
print("  📍 Farm Plots: Auto-positioning system active")
print("")
print("🧪 Admin Commands (type in chat):")
print("  _G.AdminTools.SetupPlayer('PlayerName') - Give starter resources")
print("  _G.AdminTools.TestShop('PlayerName') - Test shop system")
print("  _G.AdminTools.TestFarming('PlayerName') - Test farming system")
print("  _G.AdminTools.TestRarity() - Test rarity system")
print("  _G.AdminTools.DebugAll() - Complete system debug")
print("")
print("🎯 Ready for testing! Players can:")
print("  🏪 Visit shop to buy farm plots and seeds")
print("  🌱 Plant seeds and watch them grow with rarity")
print("  🌾 Harvest crops with enhanced values")
print("  🥛 Collect milk from the cow")
print("  🐷 Feed crops to the pig for transformations")
print("")
print("🔥 NEW FEATURES ACTIVE:")
print("  ✨ Visual rarity effects on crops")
print("  📏 Size scaling based on rarity")
print("  💰 Value multipliers for rare crops")
print("  🎨 Enhanced crop appearances")
print("  🔍 Better error handling and debugging")

-- Success indicator
_G.FarmGameReady = true

return {
	GameCore = GameCore,
	ShopSystem = ShopSystem,
	ItemConfig = ItemConfig,
	AdminTools = _G.AdminTools
}