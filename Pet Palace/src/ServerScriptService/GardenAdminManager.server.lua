--[[
    GardenAdminManager.server.lua
    Place in: ServerScriptService/GardenAdminManager.server.lua
    
    FEATURES:
    ✅ Garden system management and debugging
    ✅ Player region creation and validation
    ✅ Migration tools from old farm system
    ✅ Garden statistics and monitoring
    ✅ Troubleshooting and repair tools
]]

local function WaitForGameCore(scriptName, maxWaitTime)
	maxWaitTime = maxWaitTime or 15
	local startTime = tick()

	print(scriptName .. ": Waiting for GameCore...")

	while not _G.GameCore and (tick() - startTime) < maxWaitTime do
		wait(0.5)
	end

	if not _G.GameCore then
		error(scriptName .. ": GameCore not found after " .. maxWaitTime .. " seconds!")
	end

	print(scriptName .. ": GameCore found successfully!")
	return _G.GameCore
end

local function WaitForFarmPlot()
	local attempts = 0
	while not _G.FarmPlot and attempts < 60 do -- Wait up to 30 seconds
		wait(0.5)
		attempts = attempts + 1

		if attempts % 10 == 0 then -- Every 5 seconds
			print("GardenAdminManager: Still waiting for FarmPlot... (attempt " .. attempts .. "/60)")
		end
	end

	if _G.FarmPlot then
		print("GardenAdminManager: ✅ FarmPlot now available!")
		return _G.FarmPlot
	else
		warn("GardenAdminManager: ❌ FarmPlot never became available")
		return nil
	end
end

local GameCore = WaitForGameCore("GardenAdminManager")
local FarmPlot = WaitForFarmPlot() -- Add this line
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

print("=== GARDEN ADMIN MANAGER STARTING ===")

local GardenAdminManager = {}

-- Garden system references
GardenAdminManager.GardenModel = nil
GardenAdminManager.SoilPart = nil
GardenAdminManager.FarmPlot = nil

-- Configuration
--GardenAdminManager.Config = {
	--gardenModelName = "Garden",
	--soilPartName = "Soil",
	--regionSize = 60,
	--gridSize = 10,
	--spotSpacing = 5
--}

-- Initialize garden references
function GardenAdminManager:Initialize()
	print("GardenAdminManager: Initializing...")

	-- Find Garden and Soil
	self:FindGardenReferences()

	-- Get FarmPlot module reference
	self:GetFarmPlotReference()

	-- Setup monitoring
	self:SetupGardenMonitoring()

	print("GardenAdminManager: ✅ Initialized successfully")
end

function GardenAdminManager:FindGardenReferences()
	self.GardenModel = Workspace:FindFirstChild(self.Config.gardenModelName)
	if self.GardenModel then
		self.SoilPart = self.GardenModel:FindFirstChild(self.Config.soilPartName)
		print("GardenAdminManager: ✅ Garden references found")
		print("  Garden: " .. self.GardenModel.Name)
		print("  Soil: " .. (self.SoilPart and self.SoilPart.Name or "NOT FOUND"))
	else
		warn("GardenAdminManager: ❌ Garden model not found in workspace")
	end
end

function GardenAdminManager:GetFarmPlotReference()
	self.FarmPlot = _G.FarmPlot
	if self.FarmPlot then
		print("GardenAdminManager: ✅ FarmPlot module reference obtained")
	else
		warn("GardenAdminManager: ⚠️ FarmPlot module not found globally")
	end
end

function GardenAdminManager:SetupGardenMonitoring()
	-- Monitor garden health every 5 minutes
	spawn(function()
		while true do
			wait(300) -- 5 minutes
			self:MonitorGardenHealth()
		end
	end)
end

-- ========== GARDEN VALIDATION ==========

function GardenAdminManager:ValidateGardenSetup()
	print("=== GARDEN SETUP VALIDATION ===")

	local issues = {}

	-- Check Garden model
	if not self.GardenModel then
		table.insert(issues, "❌ Garden model not found in workspace")
	else
		print("✅ Garden model found: " .. self.GardenModel.Name)

		-- Check Soil part
		if not self.SoilPart then
			table.insert(issues, "❌ Soil part not found in Garden")
		else
			print("✅ Soil part found: " .. self.SoilPart.Name)

			-- Check if Soil is a BasePart
			if not self.SoilPart:IsA("BasePart") then
				table.insert(issues, "❌ Soil is not a BasePart")
			else
				print("✅ Soil is a valid BasePart")
				print("  Size: " .. tostring(self.SoilPart.Size))
				print("  Position: " .. tostring(self.SoilPart.Position))
			end

			-- Check Garden PrimaryPart
			if self.GardenModel.PrimaryPart ~= self.SoilPart then
				table.insert(issues, "⚠️ Garden PrimaryPart is not set to Soil")
				print("⚠️ Recommendation: Set Garden.PrimaryPart = Soil")
			else
				print("✅ Garden PrimaryPart correctly set to Soil")
			end
		end
	end

	-- Check soil size capacity
	if self.SoilPart then
		local capacity = self:CalculatePlayerCapacity()
		print("📊 Player Capacity Analysis:")
		print("  Soil dimensions: " .. self.SoilPart.Size.X .. " x " .. self.SoilPart.Size.Z)
		print("  Region size: " .. self.Config.regionSize .. " x " .. self.Config.regionSize)
		print("  Estimated capacity: " .. capacity .. " players")

		if capacity < 10 then
			table.insert(issues, "⚠️ Soil may be too small for many players")
		elseif capacity < 30 then
			print("✅ Good capacity for small servers")
		else
			print("✅ Excellent capacity for large servers")
		end
	end

	-- Check FarmPlot module
	if not self.FarmPlot then
		table.insert(issues, "❌ FarmPlot module not accessible")
	else
		print("✅ FarmPlot module accessible")
	end

	-- Summary
	if #issues == 0 then
		print("🎉 Garden setup validation PASSED - Ready for use!")
	else
		print("❌ Garden setup validation FAILED - Issues found:")
		for _, issue in ipairs(issues) do
			print("  " .. issue)
		end
	end

	print("================================")
	return #issues == 0, issues
end

function GardenAdminManager:CalculatePlayerCapacity()
	if not self.SoilPart then return 0 end

	local soilSize = self.SoilPart.Size
	local regionSize = self.Config.regionSize

	local regionsPerRow = math.floor(soilSize.X / regionSize)
	local regionsPerCol = math.floor(soilSize.Z / regionSize)

	return regionsPerRow * regionsPerCol
end

-- ========== GARDEN REGION MANAGEMENT ==========

function GardenAdminManager:CreateGardenRegionForPlayer(player)
	print("🌱 Creating garden region for " .. player.Name)

	if not self.FarmPlot then
		warn("FarmPlot module not available")
		return false
	end

	local success = self.FarmPlot:CreateSimpleFarmPlot(player)
	if success then
		print("✅ Successfully created garden region for " .. player.Name)
	else
		print("❌ Failed to create garden region for " .. player.Name)
	end

	return success
end

function GardenAdminManager:ValidatePlayerGardenRegion(player)
	print("🔍 Validating garden region for " .. player.Name)

	if not self.GardenModel then
		print("❌ Garden model not available")
		return false
	end

	local regionName = player.Name .. "_GardenRegion"
	local region = self.GardenModel:FindFirstChild(regionName)

	if not region then
		print("❌ No garden region found for " .. player.Name)
		return false
	end

	print("✅ Garden region found: " .. region.Name)

	-- Validate region structure
	local plantingSpots = region:FindFirstChild("PlantingSpots")
	if not plantingSpots then
		print("❌ PlantingSpots folder missing")
		return false
	end

	local spotCount = 0
	local unlockedSpots = 0
	local occupiedSpots = 0

	for _, spot in pairs(plantingSpots:GetChildren()) do
		if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
			spotCount = spotCount + 1

			if spot:GetAttribute("IsUnlocked") then
				unlockedSpots = unlockedSpots + 1
			end

			if not spot:GetAttribute("IsEmpty") then
				occupiedSpots = occupiedSpots + 1
			end
		end
	end

	print("📊 Region Statistics:")
	print("  Total spots: " .. spotCount)
	print("  Unlocked spots: " .. unlockedSpots)
	print("  Occupied spots: " .. occupiedSpots)
	print("  Empty spots: " .. (unlockedSpots - occupiedSpots))

	local expectedSpots = self.Config.gridSize * self.Config.gridSize
	if spotCount ~= expectedSpots then
		print("⚠️ Spot count mismatch (expected " .. expectedSpots .. ")")
		return false
	end

	print("✅ Garden region validation passed")
	return true
end

function GardenAdminManager:CleanupAbandonedRegions()
	print("🧹 Cleaning up abandoned garden regions...")

	if not self.GardenModel then
		print("❌ Garden model not available")
		return 0
	end

	local cleanedCount = 0

	for _, region in pairs(self.GardenModel:GetChildren()) do
		if region:IsA("Model") and region.Name:find("_GardenRegion") then
			local playerName = region.Name:gsub("_GardenRegion", "")
			local player = Players:FindFirstChild(playerName)

			if not player then
				print("🗑️ Removing abandoned region for " .. playerName)
				region:Destroy()
				cleanedCount = cleanedCount + 1
			end
		end
	end

	print("✅ Cleaned up " .. cleanedCount .. " abandoned regions")
	return cleanedCount
end

-- ========== GARDEN STATISTICS ==========

function GardenAdminManager:GetGardenStatistics()
	local stats = {
		gardenExists = self.GardenModel ~= nil,
		soilExists = self.SoilPart ~= nil,
		activeRegions = 0,
		totalPlayers = #Players:GetPlayers(),
		playersWithRegions = 0,
		totalSpots = 0,
		occupiedSpots = 0,
		soilCapacity = self:CalculatePlayerCapacity(),
		regionDetails = {}
	}

	if not self.GardenModel then
		return stats
	end

	-- Count regions and analyze them
	for _, region in pairs(self.GardenModel:GetChildren()) do
		if region:IsA("Model") and region.Name:find("_GardenRegion") then
			stats.activeRegions = stats.activeRegions + 1

			local playerName = region.Name:gsub("_GardenRegion", "")
			local player = Players:FindFirstChild(playerName)

			if player then
				stats.playersWithRegions = stats.playersWithRegions + 1
			end

			-- Count spots in this region
			local plantingSpots = region:FindFirstChild("PlantingSpots")
			if plantingSpots then
				local regionSpots = 0
				local regionOccupied = 0

				for _, spot in pairs(plantingSpots:GetChildren()) do
					if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
						regionSpots = regionSpots + 1
						stats.totalSpots = stats.totalSpots + 1

						if not spot:GetAttribute("IsEmpty") then
							regionOccupied = regionOccupied + 1
							stats.occupiedSpots = stats.occupiedSpots + 1
						end
					end
				end

				stats.regionDetails[playerName] = {
					hasPlayer = player ~= nil,
					totalSpots = regionSpots,
					occupiedSpots = regionOccupied,
					emptySpots = regionSpots - regionOccupied
				}
			end
		end
	end

	return stats
end

function GardenAdminManager:PrintGardenStatistics()
	local stats = self:GetGardenStatistics()

	print("=== GARDEN SYSTEM STATISTICS ===")
	print("🌱 Garden Status:")
	print("  Garden exists: " .. (stats.gardenExists and "✅" or "❌"))
	print("  Soil exists: " .. (stats.soilExists and "✅" or "❌"))
	print("  Soil capacity: " .. stats.soilCapacity .. " players")
	print("")
	print("👥 Player Statistics:")
	print("  Total players: " .. stats.totalPlayers)
	print("  Players with regions: " .. stats.playersWithRegions)
	print("  Active regions: " .. stats.activeRegions)
	print("  Coverage: " .. math.round((stats.playersWithRegions / math.max(stats.totalPlayers, 1)) * 100) .. "%")
	print("")
	print("🌾 Farming Statistics:")
	print("  Total planting spots: " .. stats.totalSpots)
	print("  Occupied spots: " .. stats.occupiedSpots)
	print("  Empty spots: " .. (stats.totalSpots - stats.occupiedSpots))
	print("  Usage rate: " .. math.round((stats.occupiedSpots / math.max(stats.totalSpots, 1)) * 100) .. "%")
	print("")

	if stats.totalPlayers > 0 then
		print("📊 Per-Player Details:")
		for _, player in pairs(Players:GetPlayers()) do
			local regionData = stats.regionDetails[player.Name]
			if regionData then
				print("  " .. player.Name .. ": " .. regionData.occupiedSpots .. "/" .. regionData.totalSpots .. " spots used")
			else
				print("  " .. player.Name .. ": NO REGION")
			end
		end
	end

	print("================================")
end

-- ========== MIGRATION TOOLS ==========

function GardenAdminManager:MigratePlayerToGarden(player)
	print("🔄 Migrating " .. player.Name .. " to garden system...")

	local playerData = GameCore:GetPlayerData(player)
	if not playerData then
		print("❌ No player data found")
		return false
	end

	-- Remove old farm plots
	self:RemoveOldFarmPlots(player)

	-- Create new garden region
	local success = self:CreateGardenRegionForPlayer(player)

	if success then
		print("✅ Successfully migrated " .. player.Name .. " to garden system")

		-- Notify player
		if GameCore.SendNotification then
			GameCore:SendNotification(player, "🌱 Garden Migration", 
				"Your farm has been migrated to the new garden system! Check out your new growing area.", "success")
		end
	else
		print("❌ Failed to migrate " .. player.Name)
	end

	return success
end

function GardenAdminManager:RemoveOldFarmPlots(player)
	-- Remove old farm plots from Areas/Starter Meadow/Farm structure
	local areas = Workspace:FindFirstChild("Areas")
	if areas then
		local starterMeadow = areas:FindFirstChild("Starter Meadow")
		if starterMeadow then
			local farmArea = starterMeadow:FindFirstChild("Farm")
			if farmArea then
				-- Remove simple farm
				local simpleFarm = farmArea:FindFirstChild(player.Name .. "_SimpleFarm")
				if simpleFarm then
					simpleFarm:Destroy()
					print("🗑️ Removed old simple farm for " .. player.Name)
				end

				-- Remove expandable farm
				local expandableFarm = farmArea:FindFirstChild(player.Name .. "_ExpandableFarm")
				if expandableFarm then
					expandableFarm:Destroy()
					print("🗑️ Removed old expandable farm for " .. player.Name)
				end

				-- Remove old folder-style farms
				local folderFarm = farmArea:FindFirstChild(player.Name .. "_Farm")
				if folderFarm then
					folderFarm:Destroy()
					print("🗑️ Removed old folder farm for " .. player.Name)
				end
			end
		end
	end
end

function GardenAdminManager:MigrateAllPlayersToGarden()
	print("🔄 Migrating ALL players to garden system...")

	local successCount = 0
	local failCount = 0

	for _, player in pairs(Players:GetPlayers()) do
		local success = self:MigratePlayerToGarden(player)
		if success then
			successCount = successCount + 1
		else
			failCount = failCount + 1
		end
		wait(0.5) -- Small delay between migrations
	end

	print("✅ Migration complete:")
	print("  Successful: " .. successCount)
	print("  Failed: " .. failCount)
	print("  Total: " .. (successCount + failCount))

	return successCount, failCount
end

-- ========== MONITORING ==========

function GardenAdminManager:MonitorGardenHealth()
	if not self.GardenModel or not self.SoilPart then return end

	local stats = self:GetGardenStatistics()

	-- Check for issues
	local issues = {}

	-- Check if any players missing regions
	if stats.playersWithRegions < stats.totalPlayers then
		table.insert(issues, (stats.totalPlayers - stats.playersWithRegions) .. " players missing garden regions")
	end

	-- Check for abandoned regions
	if stats.activeRegions > stats.totalPlayers then
		table.insert(issues, (stats.activeRegions - stats.totalPlayers) .. " abandoned regions detected")
	end

	-- Check capacity issues
	if stats.totalPlayers > stats.soilCapacity then
		table.insert(issues, "Player count exceeds soil capacity")
	end

	if #issues > 0 then
		print("⚠️ GARDEN HEALTH ISSUES DETECTED:")
		for _, issue in ipairs(issues) do
			print("  " .. issue)
		end

		-- Auto-cleanup abandoned regions
		if stats.activeRegions > stats.totalPlayers then
			self:CleanupAbandonedRegions()
		end
	else
		print("✅ Garden system health check passed")
	end
end

-- ========== ADMIN COMMANDS ==========

function GardenAdminManager:SetupAdminCommands()
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			-- Replace with your username for admin commands
			if player.Name == "TommySalami311" then -- CHANGE THIS TO YOUR USERNAME
				local args = string.split(message:lower(), " ")
				local command = args[1]

				if command == "/validategarden" then
					local targetName = args[2]
					if targetName then
						local targetPlayer = Players:FindFirstChild(targetName)
						if targetPlayer then
							self:ValidatePlayerGardenRegion(targetPlayer)
						else
							self:ValidateGardenSetup()
						end
					else
						self:ValidateGardenSetup()
					end

				elseif command == "/gardenstats" then
					self:PrintGardenStatistics()

				elseif command == "/creategarden" then
					local targetName = args[2] or player.Name
					local targetPlayer = Players:FindFirstChild(targetName)
					if targetPlayer then
						self:CreateGardenRegionForPlayer(targetPlayer)
					else
						print("Player not found: " .. targetName)
					end

				elseif command == "/cleangarden" then
					local cleaned = self:CleanupAbandonedRegions()
					print("Cleaned up " .. cleaned .. " abandoned garden regions")

				elseif command == "/migratetogarden" then
					local targetName = args[2]
					if targetName then
						local targetPlayer = Players:FindFirstChild(targetName)
						if targetPlayer then
							self:MigratePlayerToGarden(targetPlayer)
						else
							print("Player not found: " .. targetName)
						end
					else
						-- Migrate all players
						local success, failed = self:MigrateAllPlayersToGarden()
						print("Migration result: " .. success .. " successful, " .. failed .. " failed")
					end

				elseif command == "/fixgarden" then
					local targetName = args[2] or player.Name
					local targetPlayer = Players:FindFirstChild(targetName)
					if targetPlayer then
						-- Remove existing region and recreate
						if self.GardenModel then
							local region = self.GardenModel:FindFirstChild(targetPlayer.Name .. "_GardenRegion")
							if region then
								region:Destroy()
								print("Removed existing garden region for " .. targetPlayer.Name)
							end
						end
						self:CreateGardenRegionForPlayer(targetPlayer)
					else
						print("Player not found: " .. targetName)
					end

				elseif command == "/debuggarden" then
					print("=== DETAILED GARDEN DEBUG ===")
					local isValid, issues = self:ValidateGardenSetup()
					self:PrintGardenStatistics()
					self:MonitorGardenHealth()
					print("============================")

				elseif command == "/gardenbounds" then
					if self.SoilPart then
						local soilSize = self.SoilPart.Size
						local capacity = self:CalculatePlayerCapacity()
						print("=== GARDEN BOUNDARIES ===")
						print("Soil Size: " .. soilSize.X .. " x " .. soilSize.Y .. " x " .. soilSize.Z)
						print("Soil Position: " .. tostring(self.SoilPart.Position))
						print("Region Size: " .. self.Config.regionSize .. " x " .. self.Config.regionSize)
						print("Player Capacity: " .. capacity .. " players")
						print("Regions per row: " .. math.floor(soilSize.X / self.Config.regionSize))
						print("Regions per column: " .. math.floor(soilSize.Z / self.Config.regionSize))
						print("========================")
					else
						print("❌ Soil part not found")
					end

				elseif command == "/testgarden" then
					local targetName = args[2] or player.Name
					local targetPlayer = Players:FindFirstChild(targetName)
					if targetPlayer then
						print("🧪 Testing garden region for " .. targetPlayer.Name)

						-- Test creation
						local createSuccess = self:CreateGardenRegionForPlayer(targetPlayer)
						print("Creation test: " .. (createSuccess and "✅" or "❌"))

						-- Test validation
						wait(1)
						local validateSuccess = self:ValidatePlayerGardenRegion(targetPlayer)
						print("Validation test: " .. (validateSuccess and "✅" or "❌"))
					else
						print("Player not found: " .. targetName)
					end

				elseif command == "/gardenhelp" then
					print("🌱 GARDEN ADMIN COMMANDS:")
					print("  /validategarden [player] - Validate garden setup")
					print("  /gardenstats - Show garden statistics")
					print("  /creategarden [player] - Create garden region")
					print("  /cleangarden - Clean up abandoned regions")
					print("  /migratetogarden [player] - Migrate to garden system")
					print("  /fixgarden [player] - Fix/recreate garden region")
					print("  /debuggarden - Detailed garden debug info")
					print("  /gardenbounds - Show soil boundaries and capacity")
					print("  /testgarden [player] - Test garden region creation")
					print("  /gardenhelp - Show this help")

				end
			end
		end)
	end)
end

-- ========== INITIALIZATION ==========

-- Initialize the admin manager
GardenAdminManager:Initialize()

-- Setup admin commands
GardenAdminManager:SetupAdminCommands()

-- Run initial validation
spawn(function()
	wait(5) -- Wait for everything to load
	GardenAdminManager:ValidateGardenSetup()
end)

-- Make globally available
_G.GardenAdminManager = GardenAdminManager

print("=== GARDEN ADMIN MANAGER ACTIVE ===")
print("🌱 Features Available:")
print("  ✅ Garden setup validation")
print("  ✅ Player region management")
print("  ✅ Migration from old farm system")
print("  ✅ Statistics and monitoring")
print("  ✅ Troubleshooting and repair tools")
print("")
print("🎮 Admin Commands (Type in chat):")
print("  /validategarden - Check garden setup")
print("  /gardenstats - Show statistics")
print("  /gardenhelp - Show all commands")
print("")
print("⚠️ NOTE: Change 'TommySalami311' to your username on line 250!")

return GardenAdminManager