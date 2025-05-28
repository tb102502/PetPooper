-- PetRespawnSystem.server.lua
-- Place this in ServerScriptService to ensure pets respawn automatically
-- This runs independently of the main collection system

wait(5) -- Wait for GameCore to load

local GameCore = _G.GameCore
if not GameCore then
	warn("PetRespawnSystem: GameCore not found!")
	return
end

print("=== PET RESPAWN SYSTEM STARTING ===")

-- Enhanced respawn loop
spawn(function()
	while true do
		wait(3) -- Check every 3 seconds for more responsive respawning

		-- Check each spawn area
		for areaName, areaData in pairs(GameCore.Systems.Pets.SpawnAreas) do
			if areaData and areaData.container and areaData.config then
				local currentPetCount = #areaData.container:GetChildren()
				local maxPets = areaData.config.maxPets
				local spawnInterval = areaData.config.spawnInterval or 5

				-- Check if we need more pets and enough time has passed
				local timeSinceLastSpawn = os.time() - (areaData.lastSpawn or 0)

				if currentPetCount < maxPets and timeSinceLastSpawn >= spawnInterval then
					local success, newPet = pcall(function()
						return GameCore:SpawnWildPet(areaName)
					end)

					if success and newPet then
						areaData.lastSpawn = os.time()
						print("PetRespawnSystem: Spawned new pet in " .. areaName .. " (" .. (currentPetCount + 1) .. "/" .. maxPets .. ")")
					end
				end
			end
		end
	end
end)

-- Monitor pet counts and provide status
spawn(function()
	while true do
		wait(30) -- Status report every 30 seconds

		local totalPets = 0
		local totalAreas = 0

		for areaName, areaData in pairs(GameCore.Systems.Pets.SpawnAreas) do
			if areaData and areaData.container then
				local petCount = #areaData.container:GetChildren()
				totalPets = totalPets + petCount
				totalAreas = totalAreas + 1

				-- Individual area status
				local maxPets = areaData.config and areaData.config.maxPets or 10
				print("PetRespawnSystem: " .. areaName .. " has " .. petCount .. "/" .. maxPets .. " pets")
			end
		end

		print("PetRespawnSystem: Total pets across " .. totalAreas .. " areas: " .. totalPets)
	end
end)

-- Initial spawn boost - ensure each area has at least some pets
spawn(function()
	wait(2)
	print("PetRespawnSystem: Initial spawn boost...")

	for areaName, areaData in pairs(GameCore.Systems.Pets.SpawnAreas) do
		if areaData and areaData.container and areaData.config then
			local currentPetCount = #areaData.container:GetChildren()
			local targetCount = math.min(3, areaData.config.maxPets) -- Start with 3 pets per area

			for i = currentPetCount + 1, targetCount do
				local success, newPet = pcall(function()
					return GameCore:SpawnWildPet(areaName)
				end)

				if success and newPet then
					print("PetRespawnSystem: Initial spawn " .. i .. " in " .. areaName)
				end

				wait(0.5) -- Small delay between spawns
			end
		end
	end

	print("PetRespawnSystem: Initial spawn boost complete!")
end)

print("=== PET RESPAWN SYSTEM ACTIVE ===")
print("✅ Pets will now respawn automatically when collected")
print("✅ Each area maintains its target pet count")
print("✅ Status reports every 30 seconds")