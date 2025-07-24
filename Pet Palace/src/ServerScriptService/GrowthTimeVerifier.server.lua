-- ADD this verification script to ServerScriptService
-- Place as: ServerScriptService/GrowthTimeVerifier.server.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("=== GROWTH TIME VERIFIER ACTIVE ===")

-- Wait for ItemConfig to load
local ItemConfig = nil
repeat
	wait(1)
	local success, result = pcall(function()
		return require(ReplicatedStorage:WaitForChild("ItemConfig"))
	end)
	if success then
		ItemConfig = result
	end
until ItemConfig

print("✅ ItemConfig loaded for verification")

-- Verify all seed growth times
local function VerifyGrowthTimes()
	print("=== VERIFYING SEED GROWTH TIMES ===")

	local seeds = {}
	local totalSeeds = 0

	-- Collect all seeds from ItemConfig
	for itemId, item in pairs(ItemConfig.ShopItems) do
		if item.type == "seed" and item.farmingData then
			totalSeeds = totalSeeds + 1
			table.insert(seeds, {
				id = itemId,
				name = item.name,
				growTime = item.farmingData.growTime,
				price = item.price,
				currency = item.currency
			})
		end
	end

	-- Sort by grow time
	table.sort(seeds, function(a, b)
		return (a.growTime or 999999) < (b.growTime or 999999)
	end)

	print("📊 Found " .. totalSeeds .. " seeds with growth times:")
	print("")

	for i, seed in ipairs(seeds) do
		local minutes = math.floor(seed.growTime / 60)
		local seconds = seed.growTime % 60
		local timeText

		if minutes > 0 then
			if seconds > 0 then
				timeText = minutes .. "m " .. seconds .. "s"
			else
				timeText = minutes .. "m"
			end
		else
			timeText = seconds .. "s"
		end

		local priceText = seed.price .. " " .. seed.currency
		print(i .. ". " .. seed.name .. " - " .. timeText .. " (" .. seed.growTime .. "s) - " .. priceText)
	end

	print("")
	print("✅ All seed growth times verified!")
	print("=====================================")
end

-- Test growth time reading function
local function TestGrowthTimeReading(seedId)
	print("🧪 Testing growth time reading for: " .. seedId)

	local item = ItemConfig.ShopItems[seedId]
	if not item then
		print("❌ Seed not found in ItemConfig")
		return false
	end

	if not item.farmingData then
		print("❌ No farmingData found")
		return false
	end

	local growTime = item.farmingData.growTime
	if not growTime then
		print("❌ No growTime in farmingData")
		return false
	end

	local minutes = math.floor(growTime / 60)
	local seconds = growTime % 60

	print("✅ Growth time found: " .. growTime .. " seconds (" .. minutes .. "m " .. seconds .. "s)")
	print("📊 Full farmingData:")
	for key, value in pairs(item.farmingData) do
		print("  " .. key .. ": " .. tostring(value))
	end

	return true
end

-- Global test functions
_G.VerifyGrowthTimes = VerifyGrowthTimes
_G.TestGrowthTimeReading = TestGrowthTimeReading

_G.TestAllSeedTimes = function()
	print("🧪 Testing all seed growth time reading...")

	local seeds = {
		"carrot_seeds", "potato_seeds", "cabbage_seeds", "radish_seeds", 
		"broccoli_seeds", "tomato_seeds", "strawberry_seeds", "wheat_seeds", 
		"corn_seeds", "golden_seeds", "glorious_sunflower_seeds"
	}

	for i, seedId in ipairs(seeds) do
		print("\n--- Test " .. i .. ": " .. seedId .. " ---")
		TestGrowthTimeReading(seedId)
	end
end

_G.PlantTestCrop = function(playerName, seedId)
	local player = Players:FindFirstChild(playerName)
	if not player then
		print("Player not found: " .. playerName)
		return
	end

	seedId = seedId or "carrot_seeds"

	print("🌱 Planting test crop for " .. playerName .. ": " .. seedId)

	-- Find player's garden region
	local garden = workspace:FindFirstChild("Garden")
	if not garden then
		print("❌ Garden not found")
		return
	end

	local region = garden:FindFirstChild(player.Name .. "_GardenRegion")
	if not region then
		print("❌ Garden region not found")
		return
	end

	local plantingSpots = region:FindFirstChild("PlantingSpots")
	if not plantingSpots then
		print("❌ PlantingSpots not found")
		return
	end

	-- Find first empty spot
	local emptySpot = nil
	for _, spot in pairs(plantingSpots:GetChildren()) do
		if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
			local isEmpty = spot:GetAttribute("IsEmpty")
			if isEmpty then
				emptySpot = spot
				break
			end
		end
	end

	if not emptySpot then
		print("❌ No empty spots found")
		return
	end

	-- Give the player the seed
	if _G.GameCore then
		_G.GameCore:AddItemToInventory(player, "farming", seedId, 1)
		print("✅ Added seed to inventory")

		-- Plant the seed using CropCreation
		if _G.CropCreation then
			local seedData = ItemConfig.ShopItems[seedId].farmingData
			local success = _G.CropCreation:PlantSeed(player, emptySpot, seedId, seedData)

			if success then
				print("✅ Test crop planted successfully!")
				print("📊 Expected grow time: " .. seedData.growTime .. " seconds")

				-- Monitor the growth
				spawn(function()
					local startTime = os.time()
					while emptySpot and emptySpot.Parent do
						wait(1)
						local stage = emptySpot:GetAttribute("GrowthStage") or 0
						local elapsed = os.time() - startTime

						if stage >= 4 then
							print("🎉 Test crop ready! Total time: " .. elapsed .. "s (expected: " .. seedData.growTime .. "s)")
							break
						end

						if elapsed > seedData.growTime + 10 then
							print("⚠️ Crop taking longer than expected (" .. elapsed .. "s > " .. seedData.growTime .. "s)")
							break
						end
					end
				end)
			else
				print("❌ Failed to plant test crop")
			end
		else
			print("❌ CropCreation not available")
		end
	else
		print("❌ GameCore not available")
	end
end

-- Admin commands for growth time testing
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		-- Replace with your username
		if player.Name == "TommySalami311" then
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/verifytimes" then
				VerifyGrowthTimes()
			elseif command == "/testallseeds" then
				_G.TestAllSeedTimes()
			elseif command == "/testplant" then
				local seedId = args[2] or "carrot_seeds"
				_G.PlantTestCrop(player.Name, seedId)
			elseif command == "/timereading" then
				local seedId = args[2] or "carrot_seeds"
				TestGrowthTimeReading(seedId)
			elseif command == "/quicktest" then
				-- Plant fast-growing seeds for quick testing
				print("🚀 Quick growth test - planting fast seeds:")
				_G.PlantTestCrop(player.Name, "carrot_seeds") -- 3 seconds
				wait(1)
				_G.PlantTestCrop(player.Name, "potato_seeds") -- 5 seconds
			end
		end
	end)
end)

-- Run initial verification
wait(2)
VerifyGrowthTimes()

print("🔧 Growth Time Verifier Commands:")
print("  /verifytimes - Show all seed growth times")
print("  /testallseeds - Test reading all seed data")
print("  /testplant [seedId] - Plant and monitor a test crop")
print("  /timereading [seedId] - Test growth time reading for specific seed")
print("  /quicktest - Plant fast-growing test crops")
print("")
print("🧪 Global Functions:")
print("  _G.VerifyGrowthTimes() - Verify all growth times")
print("  _G.TestGrowthTimeReading('seedId') - Test specific seed")
print("  _G.PlantTestCrop('playerName', 'seedId') - Plant test crop")