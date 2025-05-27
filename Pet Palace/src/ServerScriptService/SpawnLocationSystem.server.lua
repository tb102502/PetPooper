-- SpawnLocationsSystem.server.lua
-- Place in ServerScriptService to use actual SpawnLocations parts
-- This replaces hardcoded positions with dynamic workspace parts

-- Wait for GameCore and ItemConfig to be available
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("=== WAITING FOR GAME SYSTEMS TO LOAD ===")

-- Wait for GameCore
local GameCore = nil
local maxWait = 30
local waitTime = 0

while not GameCore and waitTime < maxWait do
	GameCore = _G.GameCore
	if not GameCore then
		wait(1)
		waitTime = waitTime + 1
		print("Waiting for GameCore... (" .. waitTime .. "/" .. maxWait .. ")")
	end
end

if not GameCore then
	error("GameCore not found after " .. maxWait .. " seconds! Make sure SystemInitializer is running first.")
end

-- Wait for ItemConfig
local ItemConfig = nil
local success, result = pcall(function()
	return require(ServerScriptService:WaitForChild("Config"):WaitForChild("ItemConfig"))
end)

if success then
	ItemConfig = result
	print("✅ ItemConfig loaded successfully")
else
	error("Failed to load ItemConfig: " .. tostring(result))
end

print("✅ GameCore found - Setting up dynamic spawn locations system")
print("=== SETTING UP DYNAMIC SPAWN LOCATIONS SYSTEM ===")

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
	local spawnParts = {}

	-- Get all spawn location parts
	for _, part in pairs(spawnLocationsFolder:GetChildren()) do
		if part:IsA("BasePart") then
			-- Use the part's position, slightly above it for spawning
			local spawnPosition = part.Position + Vector3.new(0, part.Size.Y/2 + 1, 0)
			table.insert(spawnPositions, spawnPosition)
			table.insert(spawnParts, part)

			print("  Found spawn location: " .. part.Name .. " at " .. tostring(spawnPosition))
		end
	end

	print("Area '" .. areaName .. "' has " .. #spawnPositions .. " spawn locations")
	return spawnPositions, spawnParts
end

-- Update ItemConfig to use dynamic spawn locations
local function updateItemConfigWithDynamicLocations()
	print("\n--- UPDATING SPAWN AREAS WITH DYNAMIC LOCATIONS ---")

	-- Areas that should exist in your workspace
	local areaNames = {"Starter Meadow", "Mystic Forest", "Dragon's Lair"}

	for _, areaName in ipairs(areaNames) do
		local spawnPositions, spawnParts = getSpawnLocationsForArea(areaName)

		if #spawnPositions > 0 then
			-- Find the existing area config and update it
			for i, areaConfig in ipairs(ItemConfig.SpawnAreas) do
				if areaConfig.name == areaName then
					-- Update with dynamic positions
					ItemConfig.SpawnAreas[i].spawnPositions = spawnPositions
					ItemConfig.SpawnAreas[i].spawnParts = spawnParts -- Store parts for reference

					print("Updated " .. areaName .. " with " .. #spawnPositions .. " dynamic spawn locations")
					break
				end
			end
		else
			warn("No spawn locations found for " .. areaName .. " - keeping default positions")
		end
	end
end

-- Enhanced SpawnWildPet function that uses the dynamic locations
function GameCore:SpawnWildPet(areaName)
	local areaData = self.Systems.Pets.SpawnAreas[areaName]
	if not areaData then 
		warn("GameCore: Area data not found for " .. areaName)
		return 
	end

	local config = areaData.config
	local currentPetCount = #areaData.container:GetChildren()

	if currentPetCount >= config.maxPets then 
		print("GameCore: Area " .. areaName .. " is full (" .. currentPetCount .. "/" .. config.maxPets .. ")")
		return 
	end

	-- Choose random pet from available types
	local availablePets = config.availablePets
	local selectedPetId = availablePets[math.random(1, #availablePets)]
	local petConfig = ItemConfig.Pets[selectedPetId]

	if not petConfig then 
		warn("GameCore: Pet config not found for " .. selectedPetId)
		return 
	end

	-- Get spawn positions (now dynamic from workspace)
	local spawnPositions = config.spawnPositions
	if not spawnPositions or #spawnPositions == 0 then
		warn("GameCore: No spawn positions found for " .. areaName)
		return
	end

	-- Choose random spawn position
	local basePosition = spawnPositions[math.random(1, #spawnPositions)]

	-- Add small random offset to avoid pets spawning in exact same spot
	local randomOffset = Vector3.new(
		math.random(-2, 2),
		0,
		math.random(-2, 2)
	)
	local finalPosition = basePosition + randomOffset

	-- Create pet model
	local petModel = self:CreatePetModel(petConfig, finalPosition)
	if petModel then
		-- Parent to the correct area's pets folder
		petModel.Parent = areaData.container

		-- Set area attribute for tracking
		petModel:SetAttribute("AreaOrigin", areaName)

		print("GameCore: Spawned " .. selectedPetId .. " in " .. areaName .. " at " .. tostring(finalPosition))
		return petModel
	else
		warn("GameCore: Failed to create pet model for " .. selectedPetId)
	end
end

-- Function to refresh spawn locations (call this if you move/add spawn parts)
function GameCore:RefreshSpawnLocations()
	print("\n=== REFRESHING SPAWN LOCATIONS ===")

	-- Update ItemConfig with current workspace locations
	updateItemConfigWithDynamicLocations()

	-- Re-initialize spawn areas with new locations
	for _, areaConfig in ipairs(ItemConfig.SpawnAreas) do
		local areaName = areaConfig.name
		local areasFolder = workspace:FindFirstChild("Areas")
		if areasFolder then
			local areaFolder = areasFolder:FindFirstChild(areaName)
			if areaFolder then
				local petsContainer = areaFolder:FindFirstChild("Pets")
				if petsContainer then
					self.Systems.Pets.SpawnAreas[areaName] = {
						container = petsContainer,
						config = areaConfig,
						lastSpawn = 0
					}
				end
			end
		end
	end

	print("Spawn locations refreshed!")
end

-- Function to visualize spawn locations (helpful for debugging)
function GameCore:VisualizeSpawnLocations(areaName)
	print("\n=== VISUALIZING SPAWN LOCATIONS FOR " .. (areaName or "ALL AREAS") .. " ===")

	local areasToCheck = {}
	if areaName then
		table.insert(areasToCheck, areaName)
	else
		for name, _ in pairs(self.Systems.Pets.SpawnAreas) do
			table.insert(areasToCheck, name)
		end
	end

	for _, name in ipairs(areasToCheck) do
		local areaData = self.Systems.Pets.SpawnAreas[name]
		if areaData and areaData.config.spawnPositions then
			print("\nArea: " .. name)
			for i, position in ipairs(areaData.config.spawnPositions) do
				print("  Spawn " .. i .. ": " .. tostring(position))

				-- Create a temporary visual marker
				local marker = Instance.new("Part")
				marker.Name = "SpawnMarker_" .. name .. "_" .. i
				marker.Size = Vector3.new(1, 0.5, 1)
				marker.Position = position
				marker.Anchored = true
				marker.CanCollide = false
				marker.Color = Color3.fromRGB(0, 255, 0)
				marker.Material = Enum.Material.Neon
				marker.Shape = Enum.PartType.Cylinder
				marker.Parent = workspace

				-- Remove marker after 10 seconds
				game:GetService("Debris"):AddItem(marker, 10)
			end
		end
	end

	print("Green markers show spawn locations (will disappear in 10 seconds)")
end

-- Apply the updates
updateItemConfigWithDynamicLocations()
GameCore:RefreshSpawnLocations()

-- Test the new system
wait(2)
print("\n=== TESTING DYNAMIC SPAWN LOCATIONS ===")

-- Clear existing pets first
for areaName, areaData in pairs(GameCore.Systems.Pets.SpawnAreas) do
	if areaData.container then
		areaData.container:ClearAllChildren()
		print("Cleared existing pets from " .. areaName)
	end
end

wait(1)

-- Test spawn with new locations
for areaName, _ in pairs(GameCore.Systems.Pets.SpawnAreas) do
	print("Testing spawn in: " .. areaName)

	-- Spawn 2-3 pets in each area
	for i = 1, 3 do
		local pet = GameCore:SpawnWildPet(areaName)
		if pet then
			print("  Spawned: " .. pet.Name)
		end
		wait(0.5)
	end
end

print("\n=== DYNAMIC SPAWN LOCATIONS SYSTEM ACTIVE ===")
print("Your pets should now spawn at the SpawnLocations parts!")
print("Available admin commands:")
print("  /refreshspawns - Reload spawn locations from workspace")
print("  /visualspawns [area] - Show green markers at spawn locations")
print("  /testspawns [area] - Test spawning in specific area")

-- Admin commands
game:GetService("Players").PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.Name == "TommySalami311" then -- Your username
			local args = string.split(message:lower(), " ")

			if args[1] == "/refreshspawns" then
				GameCore:RefreshSpawnLocations()
				player:SendMessage("Spawn locations refreshed!")

			elseif args[1] == "/visualspawns" then
				local areaName = args[2]
				if areaName == "starter" then areaName = "Starter Meadow"
				elseif areaName == "mystic" then areaName = "Mystic Forest"
				elseif areaName == "dragon" then areaName = "Dragon's Lair" end

				GameCore:VisualizeSpawnLocations(areaName)

			elseif args[1] == "/testspawns" then
				local areaName = args[2]
				if areaName == "starter" then areaName = "Starter Meadow"
				elseif areaName == "mystic" then areaName = "Mystic Forest"  
				elseif areaName == "dragon" then areaName = "Dragon's Lair" end

				if areaName then
					for i = 1, 3 do
						GameCore:SpawnWildPet(areaName)
						wait(0.2)
					end
				else
					-- Test all areas
					for name, _ in pairs(GameCore.Systems.Pets.SpawnAreas) do
						GameCore:SpawnWildPet(name)
						wait(0.2)
					end
				end
			end
		end
	end)
end)