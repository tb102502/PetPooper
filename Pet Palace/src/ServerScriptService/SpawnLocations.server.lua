-- SpawnLocationsDiagnostic.server.lua
-- Run this first to check your current SpawnLocations setup
-- Place in ServerScriptService

print("=== SPAWN LOCATIONS DIAGNOSTIC ===")

local function checkSpawnLocations()
	local workspace = game:GetService("Workspace")
	local areasFolder = workspace:FindFirstChild("Areas")

	if not areasFolder then
		warn("❌ No Areas folder found in workspace!")
		return false
	end

	print("✅ Areas folder found")

	local expectedAreas = {"Starter Meadow", "Mystic Forest", "Dragon's Lair"}
	local foundAreas = {}

	for _, areaName in ipairs(expectedAreas) do
		local area = areasFolder:FindFirstChild(areaName)
		if area then
			print("\n📍 Checking area: " .. areaName)
			foundAreas[areaName] = true

			local spawnLocationsFolder = area:FindFirstChild("SpawnLocations")
			if spawnLocationsFolder then
				print("  ✅ SpawnLocations folder found")

				local spawnParts = {}
				for _, child in pairs(spawnLocationsFolder:GetChildren()) do
					if child:IsA("BasePart") then
						table.insert(spawnParts, child)
						print("    📌 Spawn part: " .. child.Name .. " at " .. tostring(child.Position))
					end
				end

				if #spawnParts > 0 then
					print("  ✅ Found " .. #spawnParts .. " spawn location parts")
				else
					warn("  ❌ No BaseParts found in SpawnLocations folder!")
				end
			else
				warn("  ❌ No SpawnLocations folder found in " .. areaName)
				print("    💡 Expected: Workspace/Areas/" .. areaName .. "/SpawnLocations/")
			end

			-- Check for Pets folder too
			local petsFolder = area:FindFirstChild("Pets")
			if petsFolder then
				print("  ✅ Pets folder found with " .. #petsFolder:GetChildren() .. " pets")
			else
				print("  ⚠️  No Pets folder (will be created automatically)")
			end
		else
			warn("❌ Area not found: " .. areaName)
			print("   💡 Expected: Workspace/Areas/" .. areaName)
		end
	end

	return next(foundAreas) ~= nil
end

local function createMissingStructure()
	print("\n=== CREATING MISSING STRUCTURE ===")

	local workspace = game:GetService("Workspace")
	local areasFolder = workspace:FindFirstChild("Areas")

	if not areasFolder then
		print("Creating Areas folder...")
		areasFolder = Instance.new("Folder")
		areasFolder.Name = "Areas"
		areasFolder.Parent = workspace
	end

	local expectedAreas = {
		{
			name = "Starter Meadow",
			positions = {
				Vector3.new(0, 1, 0),
				Vector3.new(10, 1, 10),
				Vector3.new(-10, 1, 10),
				Vector3.new(10, 1, -10),
				Vector3.new(-10, 1, -10)
			}
		},
		{
			name = "Mystic Forest", 
			positions = {
				Vector3.new(50, 1, 0),
				Vector3.new(60, 1, 10),
				Vector3.new(40, 1, 10)
			}
		},
		{
			name = "Dragon's Lair",
			positions = {
				Vector3.new(100, 1, 0),
				Vector3.new(110, 1, 10)
			}
		}
	}

	for _, areaInfo in ipairs(expectedAreas) do
		local area = areasFolder:FindFirstChild(areaInfo.name)
		if not area then
			print("Creating area: " .. areaInfo.name)
			area = Instance.new("Folder")
			area.Name = areaInfo.name
			area.Parent = areasFolder
		end

		local spawnLocationsFolder = area:FindFirstChild("SpawnLocations")
		if not spawnLocationsFolder then
			print("Creating SpawnLocations folder for " .. areaInfo.name)
			spawnLocationsFolder = Instance.new("Folder")
			spawnLocationsFolder.Name = "SpawnLocations"
			spawnLocationsFolder.Parent = area

			-- Create spawn location parts
			for i, position in ipairs(areaInfo.positions) do
				local spawnPart = Instance.new("Part")
				spawnPart.Name = "SpawnLocation" .. i
				spawnPart.Size = Vector3.new(2, 0.5, 2)
				spawnPart.Position = position
				spawnPart.Anchored = true
				spawnPart.CanCollide = false
				spawnPart.Color = Color3.fromRGB(0, 255, 0)
				spawnPart.Material = Enum.Material.Neon
				spawnPart.Transparency = 0.5
				spawnPart.Parent = spawnLocationsFolder

				print("  Created spawn location " .. i .. " at " .. tostring(position))
			end
		end

		local petsFolder = area:FindFirstChild("Pets")
		if not petsFolder then
			print("Creating Pets folder for " .. areaInfo.name)
			petsFolder = Instance.new("Folder")
			petsFolder.Name = "Pets"
			petsFolder.Parent = area
		end
	end

	print("✅ Structure creation complete!")
end

-- Run diagnostic
local hasValidSetup = checkSpawnLocations()

if not hasValidSetup then
	print("\n❓ Would you like me to create the missing structure?")
	print("💡 This will create default spawn locations if none exist")

	-- Auto-create if nothing found
	wait(2)
	createMissingStructure()

	print("\n=== RE-CHECKING AFTER CREATION ===")
	checkSpawnLocations()
end

print("\n=== DIAGNOSTIC COMPLETE ===")
print("✅ Your spawn locations are ready!")
print("🚀 Now run the Dynamic Spawn Locations System script")

-- Show current setup summary
print("\n📋 CURRENT SETUP SUMMARY:")
local workspace = game:GetService("Workspace")
local areasFolder = workspace:FindFirstChild("Areas")
if areasFolder then
	for _, area in pairs(areasFolder:GetChildren()) do
		local spawnLocations = area:FindFirstChild("SpawnLocations")
		if spawnLocations then
			local partCount = 0
			for _, child in pairs(spawnLocations:GetChildren()) do
				if child:IsA("BasePart") then
					partCount = partCount + 1
				end
			end
			print("  " .. area.Name .. ": " .. partCount .. " spawn locations")
		end
	end
end