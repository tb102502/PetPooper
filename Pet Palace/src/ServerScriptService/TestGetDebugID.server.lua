-- ADD this test script to verify the GetDebugId fix works
-- Place as: ServerScriptService/TestGetDebugIdFix.server.lua

print("=== TESTING GETDEBUGID FIX ===")

-- Test the safe ID generation
local function TestSafeIdGeneration()
	print("🧪 Testing safe ID generation...")

	-- Find a garden spot to test with
	local garden = workspace:FindFirstChild("Garden")
	if not garden then
		print("❌ No Garden found for testing")
		return
	end

	local testSpot = nil
	for _, region in pairs(garden:GetChildren()) do
		if region:IsA("Model") and region.Name:find("_GardenRegion") then
			local plantingSpots = region:FindFirstChild("PlantingSpots")
			if plantingSpots then
				testSpot = plantingSpots:FindFirstChild("PlantingSpot_1")
				if testSpot then
					break
				end
			end
		end
	end

	if not testSpot then
		print("❌ No test spot found")
		return
	end

	-- Test the safe ID generation
	if _G.CropCreation and _G.CropCreation.GenerateSafeSpotId then
		local success, safeId = pcall(function()
			return _G.CropCreation:GenerateSafeSpotId(testSpot)
		end)

		if success then
			print("✅ Safe ID generation works!")
			print("  Test spot: " .. testSpot.Name)
			print("  Generated ID: " .. safeId)

			-- Test that it's consistent
			local safeId2 = _G.CropCreation:GenerateSafeSpotId(testSpot)
			if safeId == safeId2 then
				print("✅ ID generation is consistent")
			else
				print("⚠️ ID generation is not consistent")
				print("  First ID: " .. safeId)
				print("  Second ID: " .. safeId2)
			end
		else
			print("❌ Safe ID generation failed: " .. tostring(safeId))
		end
	else
		print("❌ CropCreation.GenerateSafeSpotId not available")
	end
end

-- Test the growth timer cleanup
local function TestTimerCleanup()
	print("🧪 Testing timer cleanup...")

	-- Find a garden spot to test with
	local garden = workspace:FindFirstChild("Garden")
	if not garden then
		print("❌ No Garden found for testing")
		return
	end

	local testSpot = nil
	for _, region in pairs(garden:GetChildren()) do
		if region:IsA("Model") and region.Name:find("_GardenRegion") then
			local plantingSpots = region:FindFirstChild("PlantingSpots")
			if plantingSpots then
				testSpot = plantingSpots:FindFirstChild("PlantingSpot_1")
				if testSpot then
					break
				end
			end
		end
	end

	if not testSpot then
		print("❌ No test spot found")
		return
	end

	-- Test the cleanup method
	if _G.CropCreation and _G.CropCreation.CleanupGrowthTimer then
		local success, error = pcall(function()
			_G.CropCreation:CleanupGrowthTimer(testSpot)
		end)

		if success then
			print("✅ Timer cleanup works without errors!")
		else
			print("❌ Timer cleanup failed: " .. tostring(error))
		end
	else
		print("❌ CropCreation.CleanupGrowthTimer not available")
	end
end

-- Test debugging a crop without errors
local function TestCropDebugging()
	print("🧪 Testing crop debugging...")

	if _G.DebugGameClient then
		local success, error = pcall(function()
			_G.DebugGameClient()
		end)

		if success then
			print("✅ DebugGameClient works without errors!")
		else
			print("❌ DebugGameClient failed: " .. tostring(error))
		end
	end

	if _G.AnalyzeCrop then
		-- Find first player to test with
		local testPlayer = nil
		for _, player in pairs(game.Players:GetPlayers()) do
			testPlayer = player.Name
			break
		end

		if testPlayer then
			local success, error = pcall(function()
				_G.AnalyzeCrop(testPlayer)
			end)

			if success then
				print("✅ AnalyzeCrop works without errors!")
			else
				print("❌ AnalyzeCrop failed: " .. tostring(error))
			end
		end
	end
end

-- Run all tests
spawn(function()
	wait(5) -- Wait for everything to load

	print("\n🧪 RUNNING GETDEBUGID FIX TESTS...")

	TestSafeIdGeneration()
	wait(1)
	TestTimerCleanup()
	wait(1)
	TestCropDebugging()

	print("\n✅ GetDebugId fix testing complete!")
	print("If you see ✅ messages above, the fix is working correctly.")
	print("================================")
end)

-- Global test function
_G.TestGetDebugIdFix = function()
	TestSafeIdGeneration()
	TestTimerCleanup()
	TestCropDebugging()
end

print("🧪 GetDebugId Fix Test Script loaded!")
print("Run _G.TestGetDebugIdFix() to test the fix manually")