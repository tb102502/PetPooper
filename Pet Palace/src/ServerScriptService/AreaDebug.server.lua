-- AreaDebugTool.server.lua
-- Place in ServerScriptService to monitor and debug area spawning
-- This will help you see exactly what's happening with area spawns

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

print("=== AREA DEBUG TOOL ACTIVE ===")

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
	local GameCore = _G.GameCore
	if not GameCore then
		warn("GameCore not available for monitoring")
		return
	end

	print("\n--- MONITORING SPAWN AREA SYSTEM ---")

	if not GameCore.Systems or not GameCore.Systems.Pets or not GameCore.Systems.Pets.SpawnAreas then
		warn("GameCore spawn area system not initialized!")
		return
	end

	local spawnAreas = GameCore.Systems.Pets.SpawnAreas
	print("Configured spawn areas: " .. tostring(table.maxn and table.maxn(spawnAreas) or "Unknown"))

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
		local pet = GameCore:SpawnWildPet(areaName)
		if pet then
			print("Successfully spawned pet in " .. areaName .. ": " .. pet.Name)
		else
			warn("Failed to spawn pet in " .. areaName)
		end
	else
		-- Spawn in all areas
		for name, _ in pairs(GameCore.Systems.Pets.SpawnAreas or {}) do
			local pet = GameCore:SpawnWildPet(name)
			if pet then
				print("Spawned in " .. name .. ": " .. pet.Name)
			else
				warn("Failed to spawn in " .. name)
			end
			wait(0.5)
		end
	end
end

-- Initial checks
checkAreaStructure()
monitorSpawnAreas()

-- Continuous monitoring
spawn(function()
	while true do
		wait(15) -- Check every 15 seconds
		print("\n=== PERIODIC AREA CHECK ===")
		checkAreaStructure()
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