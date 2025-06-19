--[[
    FIXED Server Startup Script with Enhanced ItemConfig Debugging
    Place in: ServerScriptService/ServerStartup.server.lua
]]

print("🚀 FIXED Server Startup: Initializing game systems...")

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Wait for critical dependencies
local function waitForDependency(name, parent, timeout)
	timeout = timeout or 10
	local startTime = tick()

	while not parent:FindFirstChild(name) and (tick() - startTime) < timeout do
		wait(0.1)
	end

	if parent:FindFirstChild(name) then
		print("✅ Found dependency: " .. name)
		return parent:FindFirstChild(name)
	else
		error("❌ Failed to find dependency: " .. name .. " after " .. timeout .. " seconds")
	end
end

-- Step 1: Wait for and test ItemConfig
print("📦 Waiting for ItemConfig...")
local itemConfigModule = waitForDependency("ItemConfig", ReplicatedStorage, 15)

-- Enhanced ItemConfig testing
print("🔍 Testing ItemConfig structure...")
local itemConfigSuccess, itemConfig = pcall(function()
	return require(itemConfigModule)
end)

if not itemConfigSuccess then
	error("❌ Failed to require ItemConfig: " .. tostring(itemConfig))
end

print("✅ ItemConfig required successfully")

-- Debug ItemConfig structure
print("🔍 ItemConfig structure debug:")
print("  Type of itemConfig: " .. type(itemConfig))
print("  ItemConfig keys:")
for key, value in pairs(itemConfig) do
	print("    " .. key .. ": " .. type(value))
end

-- Check for ShopItems specifically
if not itemConfig.ShopItems then
	print("❌ ItemConfig.ShopItems not found!")
	print("📋 Available properties in ItemConfig:")
	for key, value in pairs(itemConfig) do
		if type(value) == "table" then
			local count = 0
			for _ in pairs(value) do count = count + 1 end
			print("  " .. key .. ": table with " .. count .. " items")
		else
			print("  " .. key .. ": " .. type(value))
		end
	end
	error("❌ ItemConfig missing ShopItems table")
end

local itemCount = 0
for _ in pairs(itemConfig.ShopItems) do 
	itemCount = itemCount + 1 
end
print("✅ ItemConfig.ShopItems found with " .. itemCount .. " items")

-- Test basic cow item specifically
if itemConfig.ShopItems.basic_cow then
	print("✅ basic_cow item found in ItemConfig")
	local basicCow = itemConfig.ShopItems.basic_cow
	print("  Name: " .. (basicCow.name or "MISSING"))
	print("  Price: " .. (basicCow.price or "MISSING"))
	print("  Currency: " .. (basicCow.currency or "MISSING"))
	print("  Has cowData: " .. tostring(basicCow.cowData ~= nil))
else
	print("❌ basic_cow item NOT found in ItemConfig.ShopItems")
	print("Available items with 'cow' in name:")
	for itemId, item in pairs(itemConfig.ShopItems) do
		if itemId:find("cow") then
			print("  " .. itemId)
		end
	end
end

-- Step 2: Load GameCore
print("🎮 Loading GameCore...")
local gameCorePath = ServerScriptService:FindFirstChild("Core")
if not gameCorePath then
	error("❌ Core folder not found in ServerScriptService")
end

local gameCoreModule = gameCorePath:FindFirstChild("GameCore")
if not gameCoreModule then
	error("❌ GameCore not found in ServerScriptService/Core/")
end

local GameCore = require(gameCoreModule)

-- Step 3: Load ShopSystem
print("🛒 Loading ShopSystem...")
local systemsFolder = ServerScriptService:FindFirstChild("Systems")
if not systemsFolder then
	error("❌ Systems folder not found in ServerScriptService")
end

local shopSystemModule = systemsFolder:FindFirstChild("ShopSystem")
if not shopSystemModule then
	error("❌ ShopSystem not found in ServerScriptService/Systems/")
end

local ShopSystem = require(shopSystemModule)

-- Step 4: Initialize systems in correct order
print("⚙️ Initializing game systems...")

-- Initialize GameCore first
local gameCoreSuccess, gameCoreError = pcall(function()
	return GameCore:Initialize(nil) -- ShopSystem will be linked later
end)

if not gameCoreSuccess then
	error("❌ GameCore initialization failed: " .. tostring(gameCoreError))
end

print("✅ GameCore initialized successfully")

-- Initialize ShopSystem with GameCore reference
local shopSystemSuccess, shopSystemError = pcall(function()
	return ShopSystem:Initialize(GameCore)
end)

if not shopSystemSuccess then
	error("❌ ShopSystem initialization failed: " .. tostring(shopSystemError))
end

print("✅ ShopSystem initialized successfully")

-- Link systems together
GameCore.ShopSystem = ShopSystem

-- Step 5: Enhanced validation with better error handling
print("🔍 Running enhanced system validation...")

local validationSuccess, validationError = pcall(function()
	-- Test ItemConfig structure
	if not itemConfig then
		error("ItemConfig is nil")
	end

	if type(itemConfig) ~= "table" then
		error("ItemConfig is not a table, got: " .. type(itemConfig))
	end

	if not itemConfig.ShopItems then
		error("ItemConfig.ShopItems is missing")
	end

	if type(itemConfig.ShopItems) ~= "table" then
		error("ItemConfig.ShopItems is not a table, got: " .. type(itemConfig.ShopItems))
	end

	-- Test basic cow item
	local basicCow = itemConfig.ShopItems.basic_cow
	if not basicCow then
		-- List available cow items for debugging
		local cowItems = {}
		for itemId, item in pairs(itemConfig.ShopItems) do
			if itemId:find("cow") then
				table.insert(cowItems, itemId)
			end
		end
		error("basic_cow item not found. Available cow items: " .. table.concat(cowItems, ", "))
	end

	if not basicCow.cowData then
		error("basic_cow missing cowData property")
	end

	-- Test GameCore cow config method
	local cowConfig = GameCore:GetCowConfiguration("basic_cow")
	if not cowConfig then
		error("GameCore:GetCowConfiguration failed for basic_cow")
	end

	-- Test ShopSystem item retrieval
	local shopItem = ShopSystem:GetShopItemById("basic_cow")
	if not shopItem then
		error("ShopSystem:GetShopItemById failed for basic_cow")
	end

	print("✅ All validation checks passed")
	print("  ItemConfig: ✅ Loaded with " .. (function() local count = 0; for _ in pairs(itemConfig.ShopItems) do count = count + 1 end return count end)() .. " items")
	print("  GameCore: ✅ Cow configuration working")
	print("  ShopSystem: ✅ Item retrieval working")
end)

if not validationSuccess then
	error("❌ System validation failed: " .. tostring(validationError))
end

-- Step 6: Setup player connection handling
print("👥 Setting up player connection handling...")

Players.PlayerAdded:Connect(function(player)
	print("👋 Player joined: " .. player.Name)

	spawn(function()
		wait(1)

		local success, error = pcall(function()
			GameCore:LoadPlayerData(player)
			GameCore:CreatePlayerLeaderstats(player)
		end)

		if not success then
			warn("❌ Failed to setup player " .. player.Name .. ": " .. tostring(error))
		else
			print("✅ Player " .. player.Name .. " setup complete")
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	print("👋 Player leaving: " .. player.Name)

	local success, error = pcall(function()
		GameCore:SavePlayerData(player, true)
	end)

	if not success then
		warn("❌ Failed to save data for " .. player.Name .. ": " .. tostring(error))
	else
		print("✅ Saved data for " .. player.Name)
	end
end)

-- Step 7: Setup enhanced admin commands
print("🔧 Setting up enhanced admin commands...")

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		-- Replace "TommySalami311" with your actual username
		if player.Name == "TommySalami311" then
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/debug" then
				print("=== ENHANCED SYSTEM DEBUG STATUS ===")
				print("GameCore available: " .. tostring(_G.GameCore ~= nil))
				print("ShopSystem available: " .. tostring(_G.ShopSystem ~= nil))
				print("ItemConfig available: " .. tostring(itemConfig ~= nil))

				if itemConfig then
					print("ItemConfig.ShopItems available: " .. tostring(itemConfig.ShopItems ~= nil))
					if itemConfig.ShopItems then
						local itemCount = 0
						local cowCount = 0
						for itemId, item in pairs(itemConfig.ShopItems) do
							itemCount = itemCount + 1
							if itemId:find("cow") then
								cowCount = cowCount + 1
							end
						end
						print("Total items: " .. itemCount)
						print("Cow items: " .. cowCount)
					end
				end

				if _G.GameCore then
					local playerData = _G.GameCore:GetPlayerData(player)
					print("Player data loaded: " .. tostring(playerData ~= nil))
					if playerData then
						print("  Coins: " .. (playerData.coins or 0))
						print("  Farm plots: " .. ((playerData.farming and playerData.farming.plots) or 0))
						local cowCount = 0
						if playerData.livestock and playerData.livestock.cows then
							for _ in pairs(playerData.livestock.cows) do 
								cowCount = cowCount + 1 
							end
						end
						print("  Cows: " .. cowCount)
					end
				end

				print("====================================")

			elseif command == "/testcow" then
				print("🐄 Testing enhanced cow purchase for " .. player.Name)

				-- Test ItemConfig first
				local basicCow = itemConfig.ShopItems.basic_cow
				if not basicCow then
					print("❌ basic_cow not found in ItemConfig")
					return
				end

				print("✅ basic_cow found in ItemConfig")
				print("  Price: " .. basicCow.price .. " " .. basicCow.currency)
				print("  Has cowData: " .. tostring(basicCow.cowData ~= nil))

				-- Test GameCore
				if _G.GameCore then
					local playerData = _G.GameCore:GetPlayerData(player)
					if playerData then
						-- Ensure they have basic requirements
						playerData.farming = playerData.farming or {plots = 1, inventory = {}}
						_G.GameCore:SavePlayerData(player)

						-- Try to purchase basic cow
						print("🐄 Attempting cow purchase...")
						local success = _G.GameCore:PurchaseCow(player, "basic_cow", nil)
						print("🐄 Test cow purchase result: " .. tostring(success))

						if success then
							print("✅ Cow purchase successful!")
						else
							print("❌ Cow purchase failed - check console for errors")
						end
					else
						print("❌ Could not get player data")
					end
				else
					print("❌ GameCore not available")
				end

			elseif command == "/freecow" then
				if _G.GameCore then
					local playerData = _G.GameCore:GetPlayerData(player)
					if playerData then
						-- Give free farm plot if needed
						if not playerData.farming or not playerData.farming.plots or playerData.farming.plots <= 0 then
							playerData.farming = {plots = 1, inventory = {}}
							_G.GameCore:CreatePlayerFarmPlot(player, 1)
							print("🌾 Created farm plot for " .. player.Name)
						end

						-- Give basic cow for free
						local success = _G.GameCore:PurchaseCow(player, "basic_cow", nil)
						if success then
							print("🐄 Successfully gave free cow to " .. player.Name)
						else
							print("❌ Failed to give cow to " .. player.Name)
						end

						_G.GameCore:SavePlayerData(player)
					end
				end

			elseif command == "/listcows" then
				print("🐄 Available cow items in ItemConfig:")
				for itemId, item in pairs(itemConfig.ShopItems) do
					if itemId:find("cow") then
						print("  " .. itemId .. ": " .. item.name .. " (" .. item.price .. " " .. item.currency .. ")")
					end
				end
			end
		end
	end)
end)

-- Step 8: Make systems globally available
_G.GameCore = GameCore
_G.ShopSystem = ShopSystem
_G.ItemConfig = itemConfig

-- Step 9: Start background tasks
print("🔄 Starting background tasks...")

-- Auto-save task
spawn(function()
	while true do
		wait(300) -- Save every 5 minutes

		for _, player in pairs(Players:GetPlayers()) do
			if player and player.Parent then
				pcall(function()
					GameCore:SavePlayerData(player)
				end)
			end
		end
	end
end)

print("🎉 FIXED Server Startup complete! All systems operational.")
print("")
print("🔧 Admin Commands (for TommySalami311):")
print("  /debug - Show enhanced system status")
print("  /testcow - Test cow purchase system with detailed logging")
print("  /freecow - Get a free cow and farm plot")
print("  /listcows - List all available cow items")
print("")
print("✨ Game ready for players!")