-- SimpleSpawnLocationsFix.server.lua
-- Alternative approach - modify GameCore directly instead of creating new script
-- Place in ServerScriptService and run AFTER GameCore is loaded

-- Wait a bit for systems to load
wait(10)

local GameCore = _G.GameCore
if not GameCore then
	warn("GameCore still not found after waiting. Check SystemInitializer.")
	return
end

print("=== APPLYING SPAWN LOCATIONS FIX TO GAMECORE ===")

-- Get ItemConfig
local ServerScriptService = game:GetService("ServerScriptService")
local ItemConfig
local success, result = pcall(function()
	return require(ServerScriptService.Config.ItemConfig)
end)

if success then
	ItemConfig = result
else
	error("Failed to load ItemConfig: " .. tostring(result))
end

-- Function to get spawn locations from workspace parts
local function getSpawnLocationsForArea(areaName)
	local workspace = game:GetService("Workspace")
	local areasFolder = workspace:FindFirstChild("Areas")

	if not areasFolder then
		warn("No Areas folder found in workspace")
		return {}
	end

	local area = areasFolder:FindFirstChild(areaName)
	if not area then
		warn("Area not found: " .. areaName)
		return {}
	end

	local spawnLocationsFolder = area:FindFirstChild("SpawnLocations")
	if not spawnLocationsFolder then
		warn("No SpawnLocations folder found in " .. areaName)
		return {}
	end

	local spawnPositions = {}

	-- Get all spawn location parts
	for _, part in pairs(spawnLocationsFolder:GetChildren()) do
		if part:IsA("BasePart") then
			-- Use the part's position, slightly above it for spawning
			local spawnPosition = part.Position + Vector3.new(0, part.Size.Y/2 + 1, 0)
			table.insert(spawnPositions, spawnPosition)
			print("  Found spawn location: " .. part.Name .. " at " .. tostring(spawnPosition))
		end
	end

	print("Area '" .. areaName .. "' has " .. #spawnPositions .. " spawn locations")
	return spawnPositions
end

-- Update ItemConfig spawn areas with dynamic positions
print("Updating spawn areas with workspace positions...")

for i, areaConfig in ipairs(ItemConfig.SpawnAreas) do
	local areaName = areaConfig.name
	local dynamicPositions = getSpawnLocationsForArea(areaName)

	if #dynamicPositions > 0 then
		-- Update the ItemConfig with dynamic positions
		ItemConfig.SpawnAreas[i].spawnPositions = dynamicPositions
		print("✅ Updated " .. areaName .. " with " .. #dynamicPositions .. " spawn positions")
	else
		print("⚠️  No spawn locations found for " .. areaName .. " - keeping defaults")
	end
end

-- Reinitialize GameCore spawn areas with new positions
print("Reinitializing GameCore spawn areas...")

for _, areaConfig in ipairs(ItemConfig.SpawnAreas) do
	local areaName = areaConfig.name
	local areasFolder = workspace:FindFirstChild("Areas")

	if areasFolder then
		local areaFolder = areasFolder:FindFirstChild(areaName)
		if areaFolder then
			local petsContainer = areaFolder:FindFirstChild("Pets")
			if not petsContainer then
				petsContainer = Instance.new("Folder")
				petsContainer.Name = "Pets"
				petsContainer.Parent = areaFolder
			end

			GameCore.Systems.Pets.SpawnAreas[areaName] = {
				container = petsContainer,
				config = areaConfig,
				lastSpawn = 0
			}

			print("✅ Initialized " .. areaName .. " spawn area")
		end
	end
end

-- Test spawn some pets to verify
print("\n=== TESTING SPAWN LOCATIONS ===")
wait(2)

-- Clear existing test pets
for areaName, areaData in pairs(GameCore.Systems.Pets.SpawnAreas) do
	if areaData.container then
		-- Only clear test pets, not regular ones
		for _, child in pairs(areaData.container:GetChildren()) do
			if child.Name:find("TEST_") then
				child:Destroy()
			end
		end
	end
end

-- Spawn test pets in each area
for areaName, areaData in pairs(GameCore.Systems.Pets.SpawnAreas) do
	print("Testing spawn in: " .. areaName)

	local pet = GameCore:SpawnWildPet(areaName)
	if pet then
		pet.Name = "TEST_" .. pet.Name -- Mark as test pet
		print("  ✅ Successfully spawned test pet: " .. pet.Name)
	else
		print("  ❌ Failed to spawn test pet in " .. areaName)
	end

	wait(0.5)
end

print("\n=== SPAWN LOCATIONS FIX COMPLETE ===")
print("✅ Your pets should now spawn at SpawnLocations parts!")
print("🔍 Check workspace/Areas/[AreaName]/Pets/ for test pets")

-- Cleanup function
spawn(function()
	wait(30) -- Remove test pets after 30 seconds
	print("Cleaning up test pets...")

	for areaName, areaData in pairs(GameCore.Systems.Pets.SpawnAreas) do
		if areaData.container then
			for _, child in pairs(areaData.container:GetChildren()) do
				if child.Name:find("TEST_") then
					child:Destroy()
				end
			end
		end
	end

	print("Test pets cleaned up")
end)