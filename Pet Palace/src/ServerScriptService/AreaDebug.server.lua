--[[
    AreaDebug.server.lua - FIXED VERSION
    Replace your existing AreaDebug script with this fixed version
]]

-- AreaDebugTool.server.lua
-- Place in ServerScriptService to monitor and debug area spawning
-- FIXED: Proper GameCore availability check

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

print("=== AREA DEBUG TOOL ACTIVE (FIXED) ===")

local function checkAreaStructure()
	print("\n--- CHECKING WORKSPACE AREA STRUCTURE ---")

	local areasFolder = workspace:FindFirstChild("Areas")
	if not areasFolder then
		warn("No Areas folder found in workspace!")
		return
	end

	print("Areas folder found with " .. #areasFolder:GetChildren() .. " areas")

	for _, area in pairs(areasFolder:GetChildren()) do
		if area:IsA("Folder") or area:IsA("Model") then
			print("\nArea: " .. area.Name)

			local petsFolder = area:FindFirstChild("Pets")
			if petsFolder then
				local petCount = #petsFolder:GetChildren()
				print("  Pets folder found with " .. petCount .. " pets")

				if petCount > 0 then
					for i, pet in pairs(petsFolder:GetChildren()) do
						if i <= 3 then -- Only show first 3 to avoid spam
							local petType = pet:GetAttribute("PetType") or "Unknown"
							local position = "Unknown"

							if pet:IsA("Model") and pet.PrimaryPart then
								position = tostring(pet.PrimaryPart.Position)
							elseif pet:FindFirstChild("HumanoidRootPart") then
								position = tostring(pet:FindFirstChild("HumanoidRootPart").Position)
							end

							print("    Pet " .. i .. ": " .. pet.Name .. " (Type: " .. petType .. ") at " .. position)
						end
					end

					if petCount > 3 then
						print("    ... and " .. (petCount - 3) .. " more pets")
					end
				end
			else
				warn("  No Pets folder found in " .. area.Name)
			end

			-- Check if area has expected models/parts
			local childrenCount = #area:GetChildren()
			print("  Total children: " .. childrenCount)
		end
	end
end

local function monitorSpawnAreas()
	-- FIXED: Better GameCore availability check
	local GameCore = _G.GameCore
	if not GameCore then
		print("GameCore not yet available, waiting...")

		-- Wait up to 30 seconds for GameCore to become available
		local waitTime = 0
		local maxWait = 30

		while not GameCore and waitTime < maxWait do
			wait(1)
			waitTime = waitTime + 1
			GameCore = _G.GameCore

			if GameCore then
				print("GameCore became available after " .. waitTime .. " seconds")
				break
			end
		end

		if not GameCore then
			warn("GameCore still not available after " .. maxWait .. " seconds!")
			return
		end
	end

	print("\n--- MONITORING SPAWN AREA SYSTEM ---")

	if not GameCore.Systems or not GameCore.Systems.Pets or not GameCore.Systems.Pets.SpawnAreas then
		warn("GameCore spawn area system not initialized!")
		return
	end

	local spawnAreas = GameCore.Systems.Pets.SpawnAreas
	local areaCount = 0
	for _ in pairs(spawnAreas) do
		areaCount = areaCount + 1
	end

	print("Configured spawn areas: " .. areaCount)

	for areaName, areaData in pairs(spawnAreas) do
		print("\nArea: " .. areaName)
		print("  Container: " .. (areaData.container and areaData.container:GetFullName() or "Missing"))
		print("  Last spawn: " .. (areaData.lastSpawn or 0))
		print("  Current pets: " .. (areaData.container and #areaData.container:GetChildren() or 0))

		if areaData.config then
			print("  Max pets: " .. areaData.config.maxPets)
			print("  Spawn interval: " .. areaData.config.spawnInterval .. "s")
			print("  Available pets: " .. table.concat(areaData.config.availablePets, ", "))
			print("  Spawn positions: " .. #areaData.config.spawnPositions)
		else
			warn("  Missing area config!")
		end
	end
end

local function testManualSpawn(areaName)
	local GameCore = _G.GameCore
	if not GameCore then
		warn("GameCore not available")
		return
	end

	print("\n--- TESTING MANUAL SPAWN IN " .. (areaName or "ALL AREAS") .. " ---")

	if areaName then
		-- Spawn in specific area
		local success, result = pcall(function()
			return GameCore:SpawnWildPet(areaName)
		end)

		if success and result then
			print("Successfully spawned pet in " .. areaName .. ": " .. result.Name)
		else
			warn("Failed to spawn pet in " .. areaName .. ": " .. tostring(result))
		end
	else
		-- Spawn in all areas
		if GameCore.Systems and GameCore.Systems.Pets and GameCore.Systems.Pets.SpawnAreas then
			for name, _ in pairs(GameCore.Systems.Pets.SpawnAreas) do
				local success, result = pcall(function()
					return GameCore:SpawnWildPet(name)
				end)

				if success and result then
					print("Spawned in " .. name .. ": " .. result.Name)
				else
					warn("Failed to spawn in " .. name .. ": " .. tostring(result))
				end
				wait(0.5)
			end
		else
			warn("GameCore spawn areas not initialized")
		end
	end
end

-- Initial checks with delay
spawn(function()
	wait(3) -- Wait for systems to initialize
	checkAreaStructure()
	monitorSpawnAreas()
end)

-- Continuous monitoring
spawn(function()
	while true do
		wait(30) -- Check every 30 seconds
		print("\n=== PERIODIC AREA CHECK ===")
		checkAreaStructure()

		-- Only monitor if GameCore is available
		if _G.GameCore then
			monitorSpawnAreas()
		else
			print("GameCore not available for monitoring")
		end
	end
end)

-- Chat commands for testing
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		-- Replace with your username
		if player.Name == "TommySalami311" then -- Your username from the debug output
			local args = string.split(message:lower(), " ")

			if args[1] == "/checkareas" then
				checkAreaStructure()
				monitorSpawnAreas()

			elseif args[1] == "/spawntestall" then
				testManualSpawn()

			elseif args[1] == "/spawntest" then
				local areaName = args[2]
				if areaName then
					-- Convert to proper case
					if areaName == "starter" then
						areaName = "Starter Meadow"
					elseif areaName == "mystic" then
						areaName = "Mystic Forest"
					elseif areaName == "dragon" then
						areaName = "Dragon's Lair"
					end
				end
				testManualSpawn(areaName)

			elseif args[1] == "/cleararea" then
				local areaName = args[2]
				if areaName then
					local areasFolder = workspace:FindFirstChild("Areas")
					if areasFolder then
						local area = areasFolder:FindFirstChild(areaName)
						if not area and areaName == "starter" then
							area = areasFolder:FindFirstChild("Starter Meadow")
						elseif not area and areaName == "mystic" then
							area = areasFolder:FindFirstChild("Mystic Forest")
						elseif not area and areaName == "dragon" then
							area = areasFolder:FindFirstChild("Dragon's Lair")
						end

						if area then
							local petsFolder = area:FindFirstChild("Pets")
							if petsFolder then
								petsFolder:ClearAllChildren()
								print("Cleared all pets from " .. area.Name)
							end
						end
					end
				end
			end
		end
	end)
end)

print("\nDEBUG COMMANDS AVAILABLE:")
print("  /checkareas - Check area structure and monitoring")
print("  /spawntestall - Test spawn in all areas")
print("  /spawntest [area] - Test spawn in specific area (starter/mystic/dragon)")
print("  /cleararea [area] - Clear pets from specific area")
print("=======================================")

-- Also fix the sound ID issue
print("\nNOTE: Sound ID rbxassetid://131961136 may be invalid.")
print("Consider using default Roblox sounds or uploading new audio files.")