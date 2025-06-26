--[[
    Enhanced FarmPlotManager.server.lua - Expandable Farm System Support
    Replace your existing FarmPlotManager.lua with this version
    
    UPDATED FOR:
    ✅ Single expandable plot management
    ✅ Expansion level validation
    ✅ New validation and repair systems
    ✅ Enhanced admin commands for expandable farms
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

local GameCore = WaitForGameCore("ExpandableFarmPlotManager")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("=== ENHANCED EXPANDABLE FARM PLOT MANAGER STARTING ===")

-- Expandable farm plot validation and repair system
local ExpandableFarmPlotManager = {}

-- Check if player has expandable farm plot
local function PlayerHasExpandableFarm(playerData)
	-- Check if player has purchased farm plot starter
	if playerData and playerData.purchaseHistory and playerData.purchaseHistory.farm_plot_starter then
		return true
	end

	-- Also check if they have farming data with expansion level
	if playerData and playerData.farming and playerData.farming.expansionLevel then
		return true
	end

	return false
end

-- Initialize expandable farms for existing players on server start
function ExpandableFarmPlotManager:InitializeExistingPlayers()
	print("ExpandableFarmPlotManager: Initializing expandable farms for existing players...")

	for _, player in pairs(Players:GetPlayers()) do
		spawn(function()
			wait(2) -- Wait for player data to load
			self:ValidatePlayerExpandableFarm(player)
		end)
	end
end

-- Validate and repair player expandable farm
function ExpandableFarmPlotManager:ValidatePlayerExpandableFarm(player)
	local playerData = GameCore:GetPlayerData(player)
	if not playerData then 
		print("ExpandableFarmPlotManager: No player data for " .. player.Name)
		return 
	end

	-- Only proceed if player has purchased farm plots
	if not PlayerHasExpandableFarm(playerData) then
		print("ExpandableFarmPlotManager: Player " .. player.Name .. " has no expandable farm")
		return
	end

	-- Initialize farming data if needed
	if not playerData.farming then
		playerData.farming = {
			expansionLevel = 1,
			inventory = {}
		}
		GameCore:SavePlayerData(player)
	end

	if not playerData.farming.expansionLevel then
		playerData.farming.expansionLevel = 1
		GameCore:SavePlayerData(player)
	end

	local expectedLevel = playerData.farming.expansionLevel
	local expectedConfig = GameCore:GetExpansionConfig(expectedLevel)

	print("ExpandableFarmPlotManager: Player " .. player.Name .. " should have expansion level " .. expectedLevel)

	-- Get existing expandable farm
	local existingFarm = self:GetPlayerExpandableFarm(player)

	if not existingFarm then
		-- Create missing expandable farm
		print("ExpandableFarmPlotManager: Creating missing expandable farm for " .. player.Name)
		local success = GameCore:CreateExpandableFarmPlot(player)
		if success then
			print("ExpandableFarmPlotManager: Created expandable farm for " .. player.Name)
		else
			print("ExpandableFarmPlotManager: Failed to create expandable farm for " .. player.Name)
		end
	else
		-- Validate existing farm
		self:ValidateExpandableFarmStructure(player, existingFarm, expectedLevel)
	end
end

-- Get player's expandable farm model
function ExpandableFarmPlotManager:GetPlayerExpandableFarm(player)
	local areas = workspace:FindFirstChild("Areas")
	if not areas then return nil end

	local starterMeadow = areas:FindFirstChild("Starter Meadow")
	if not starterMeadow then return nil end

	local farmArea = starterMeadow:FindFirstChild("Farm")
	if not farmArea then return nil end

	return farmArea:FindFirstChild(player.Name .. "_ExpandableFarm")
end

-- Validate expandable farm structure
function ExpandableFarmPlotManager:ValidateExpandableFarmStructure(player, farmModel, expectedLevel)
	print("ExpandableFarmPlotManager: Validating expandable farm structure for " .. player.Name)

	local expectedConfig = GameCore:GetExpansionConfig(expectedLevel)
	if not expectedConfig then
		print("ExpandableFarmPlotManager: Invalid expansion level " .. expectedLevel .. " for " .. player.Name)
		return
	end

	-- Check if farm has correct planting spots
	local plantingSpots = farmModel:FindFirstChild("PlantingSpots")
	if not plantingSpots then
		print("ExpandableFarmPlotManager: Missing planting spots folder for " .. player.Name .. ", recreating farm")
		farmModel:Destroy()
		GameCore:CreateExpandableFarmPlot(player)
		return
	end

	-- Count unlocked spots
	local unlockedSpots = 0
	local totalSpots = 0

	for _, spot in pairs(plantingSpots:GetChildren()) do
		if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
			totalSpots = totalSpots + 1
			local isUnlocked = spot:GetAttribute("IsUnlocked")
			if isUnlocked then
				unlockedSpots = unlockedSpots + 1
			end
		end
	end

	print("ExpandableFarmPlotManager: Found " .. unlockedSpots .. " unlocked spots out of " .. totalSpots .. " total spots")
	print("ExpandableFarmPlotManager: Expected " .. expectedConfig.totalSpots .. " unlocked spots for level " .. expectedLevel)

	-- If unlocked spots don't match expected, update the farm
	if unlockedSpots ~= expectedConfig.totalSpots then
		print("ExpandableFarmPlotManager: Spot count mismatch, updating farm for " .. player.Name)
		GameCore:CreateExpandableFarmPlot(player)
	end

	-- Validate farm position
	self:ValidateExpandableFarmPosition(player, farmModel)
end

-- Validate expandable farm position
function ExpandableFarmPlotManager:ValidateExpandableFarmPosition(player, farmModel)
	if not GameCore.GetExpandableFarmPosition then
		print("ExpandableFarmPlotManager: GetExpandableFarmPosition method not found")
		return
	end

	local expectedCFrame = GameCore:GetExpandableFarmPosition(player)
	local expectedPosition = expectedCFrame.Position

	local currentPosition = farmModel.PrimaryPart and farmModel.PrimaryPart.Position

	if currentPosition and expectedPosition then
		local distance = (currentPosition - expectedPosition).Magnitude

		-- If farm is more than 10 studs away from expected position, move it
		if distance > 10 then
			farmModel:SetPrimaryPartCFrame(expectedCFrame)
			print("ExpandableFarmPlotManager: Corrected position for " .. player.Name .. "'s expandable farm")
		end
	end
end

-- Clean up abandoned expandable farms
function ExpandableFarmPlotManager:CleanupAbandonedExpandableFarms()
	print("ExpandableFarmPlotManager: Cleaning up abandoned expandable farms...")

	local areas = workspace:FindFirstChild("Areas")
	if not areas then return end

	local starterMeadow = areas:FindFirstChild("Starter Meadow")
	if not starterMeadow then return end

	local farmArea = starterMeadow:FindFirstChild("Farm")
	if not farmArea then return end

	local cleanedCount = 0

	for _, expandableFarm in pairs(farmArea:GetChildren()) do
		if expandableFarm:IsA("Model") and expandableFarm.Name:find("_ExpandableFarm") then
			local playerName = expandableFarm.Name:gsub("_ExpandableFarm", "")
			local player = Players:FindFirstChild(playerName)

			-- If player doesn't exist, clean up their farm
			if not player then
				print("ExpandableFarmPlotManager: Cleaning up abandoned expandable farm for " .. playerName)
				expandableFarm:Destroy()
				cleanedCount = cleanedCount + 1
			end
		end
	end

	-- Also clean up old-style disconnected plots
	for _, playerFarm in pairs(farmArea:GetChildren()) do
		if playerFarm:IsA("Folder") and playerFarm.Name:find("_Farm") and not playerFarm.Name:find("_ExpandableFarm") then
			local playerName = playerFarm.Name:gsub("_Farm", "")
			local player = Players:FindFirstChild(playerName)

			if not player then
				print("ExpandableFarmPlotManager: Cleaning up old-style farm for " .. playerName)
				playerFarm:Destroy()
				cleanedCount = cleanedCount + 1
			end
		end
	end

	if cleanedCount > 0 then
		print("ExpandableFarmPlotManager: Cleaned up " .. cleanedCount .. " abandoned farms")
	end
end

-- Monitor expandable farm system health
function ExpandableFarmPlotManager:MonitorExpandableFarmHealth()
	spawn(function()
		while true do
			wait(300) -- Check every 5 minutes

			local totalFarms = 0
			local playersWithFarms = 0
			local totalUnlockedSpots = 0

			-- Count all expandable farms and spots
			for _, player in pairs(Players:GetPlayers()) do
				local playerData = GameCore:GetPlayerData(player)
				if playerData and PlayerHasExpandableFarm(playerData) then
					playersWithFarms = playersWithFarms + 1
					totalFarms = totalFarms + 1

					local expansionLevel = playerData.farming and playerData.farming.expansionLevel or 1
					local config = GameCore:GetExpansionConfig(expansionLevel)
					totalUnlockedSpots = totalUnlockedSpots + config.totalSpots
				end
			end

			print("ExpandableFarmPlotManager: Health Check - " .. playersWithFarms .. " players with expandable farms, " .. totalUnlockedSpots .. " total unlocked spots")

			-- Clean up abandoned farms periodically
			self:CleanupAbandonedExpandableFarms()
		end
	end)
end

-- Handle player joining - ensure their expandable farm is set up
function ExpandableFarmPlotManager:HandlePlayerAdded(player)
	spawn(function()
		wait(3) -- Wait for player data to load
		self:ValidatePlayerExpandableFarm(player)
	end)
end

-- Handle player leaving
function ExpandableFarmPlotManager:HandlePlayerRemoving(player)
	print("ExpandableFarmPlotManager: Player " .. player.Name .. " left - expandable farm marked for cleanup check")
end

-- Setup event connections
Players.PlayerAdded:Connect(function(player)
	ExpandableFarmPlotManager:HandlePlayerAdded(player)
end)

Players.PlayerRemoving:Connect(function(player)
	ExpandableFarmPlotManager:HandlePlayerRemoving(player)
end)

-- Enhanced admin commands for expandable farm management
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		-- Replace with your username for admin commands
		if player.Name == "TommySalami311" then
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/validateexpandablefarms" then
				print("Admin: Validating all expandable farms...")
				for _, p in pairs(Players:GetPlayers()) do
					ExpandableFarmPlotManager:ValidatePlayerExpandableFarm(p)
				end
				print("Admin: Expandable farm validation complete")

			elseif command == "/cleanupexpandablefarms" then
				ExpandableFarmPlotManager:CleanupAbandonedExpandableFarms()
				print("Admin: Expandable farm cleanup complete")

			elseif command == "/expandablefarmstats" then
				local totalFarms = 0
				local playersWithFarms = 0
				local levelCounts = {}

				for _, p in pairs(Players:GetPlayers()) do
					local playerData = GameCore:GetPlayerData(p)
					if playerData and PlayerHasExpandableFarm(playerData) then
						playersWithFarms = playersWithFarms + 1
						totalFarms = totalFarms + 1

						local level = playerData.farming and playerData.farming.expansionLevel or 1
						levelCounts[level] = (levelCounts[level] or 0) + 1

						local config = GameCore:GetExpansionConfig(level)
						print("  " .. p.Name .. ": Level " .. level .. " (" .. config.name .. ") - " .. config.totalSpots .. " spots")
					else
						print("  " .. p.Name .. ": NO EXPANDABLE FARM")
					end
				end

				print("Expandable Farm Stats:")
				print("  Total farms: " .. totalFarms)
				print("  Players with farms: " .. playersWithFarms)
				print("  Level distribution:")
				for level = 1, 5 do
					local count = levelCounts[level] or 0
					local config = GameCore:GetExpansionConfig(level)
					print("    Level " .. level .. " (" .. config.name .. "): " .. count .. " farms")
				end

			elseif command == "/giveexpandablefarm" then
				local targetName = args[2]
				if targetName then
					local targetPlayer = Players:FindFirstChild(targetName)
					if targetPlayer then
						local playerData = GameCore:GetPlayerData(targetPlayer)
						if playerData then
							-- Give them the expandable farm
							playerData.purchaseHistory = playerData.purchaseHistory or {}
							playerData.purchaseHistory.farm_plot_starter = true
							playerData.farming = playerData.farming or {
								expansionLevel = 1,
								inventory = {
									carrot_seeds = 5, 
									corn_seeds = 3
								}
							}

							-- Create the expandable farm
							GameCore:CreateExpandableFarmPlot(targetPlayer)

							if GameCore.SendNotification then
								GameCore:SendNotification(targetPlayer, "Admin Gift", "You received a free expandable farm!", "success")
							end
							print("Admin: Gave expandable farm to " .. targetPlayer.Name)
						end
					else
						print("Admin: Player " .. targetName .. " not found")
					end
				end

			elseif command == "/setexpansionlevel" then
				local targetName = args[2]
				local newLevel = tonumber(args[3])

				if targetName and newLevel and newLevel >= 1 and newLevel <= 5 then
					local targetPlayer = Players:FindFirstChild(targetName)
					if targetPlayer then
						local playerData = GameCore:GetPlayerData(targetPlayer)
						if playerData and playerData.farming then
							local oldLevel = playerData.farming.expansionLevel or 1
							playerData.farming.expansionLevel = newLevel

							-- Update the farm
							GameCore:CreateExpandableFarmPlot(targetPlayer)
							GameCore:SavePlayerData(targetPlayer)

							local newConfig = GameCore:GetExpansionConfig(newLevel)
							print("Admin: Set " .. targetPlayer.Name .. "'s farm to level " .. newLevel .. " (" .. newConfig.name .. ")")

							if GameCore.SendNotification then
								GameCore:SendNotification(targetPlayer, "Admin Action", 
									"Your farm expansion level has been set to " .. newLevel .. " (" .. newConfig.name .. ")!", "info")
							end
						else
							print("Admin: " .. targetPlayer.Name .. " has no farming data")
						end
					else
						print("Admin: Player " .. targetName .. " not found")
					end
				else
					print("Admin: Usage: /setexpansionlevel [player] [level 1-5]")
				end

			elseif command == "/expandfarm" then
				local targetName = args[2] or player.Name
				local targetPlayer = Players:FindFirstChild(targetName)

				if targetPlayer then
					local success, message = GameCore:ExpandFarmToNextLevel(targetPlayer)
					if success then
						print("Admin: Successfully expanded " .. targetPlayer.Name .. "'s farm")
					else
						print("Admin: Failed to expand " .. targetPlayer.Name .. "'s farm: " .. message)
					end
				else
					print("Admin: Player " .. targetName .. " not found")
				end

			elseif command == "/resetexpandablefarm" then
				local targetName = args[2]
				if targetName then
					local targetPlayer = Players:FindFirstChild(targetName)
					if targetPlayer then
						-- Remove their expandable farm from workspace
						local farm = ExpandableFarmPlotManager:GetPlayerExpandableFarm(targetPlayer)
						if farm then
							farm:Destroy()
							print("Admin: Destroyed " .. targetPlayer.Name .. "'s expandable farm")
						end

						-- Reset their farm data
						local playerData = GameCore:GetPlayerData(targetPlayer)
						if playerData then
							playerData.purchaseHistory = playerData.purchaseHistory or {}
							playerData.purchaseHistory.farm_plot_starter = nil
							playerData.farming = nil
						end

						GameCore:SavePlayerData(targetPlayer)
						print("Admin: Reset expandable farm data for " .. targetPlayer.Name)

						if GameCore.SendNotification then
							GameCore:SendNotification(targetPlayer, "Admin Action", "Your expandable farm has been reset", "info")
						end
					else
						print("Admin: Player " .. targetName .. " not found")
					end
				end

			elseif command == "/teleporttoexpandablefarm" then
				local targetName = args[2] or player.Name
				local targetPlayer = Players:FindFirstChild(targetName)

				if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
					local farm = ExpandableFarmPlotManager:GetPlayerExpandableFarm(targetPlayer)
					if farm and farm.PrimaryPart then
						local farmPosition = farm.PrimaryPart.Position + Vector3.new(0, 5, 20)
						player.Character.HumanoidRootPart.CFrame = CFrame.new(farmPosition)
						print("Admin: Teleported to " .. targetPlayer.Name .. "'s expandable farm")
					else
						print("Admin: " .. targetPlayer.Name .. " has no expandable farm")
					end
				else
					print("Admin: Player " .. targetName .. " not found or has no character")
				end

			elseif command == "/checkexpandablefarmdata" then
				local targetName = args[2] or player.Name
				local targetPlayer = Players:FindFirstChild(targetName)

				if targetPlayer then
					local playerData = GameCore:GetPlayerData(targetPlayer)
					print("=== EXPANDABLE FARM DATA DEBUG FOR " .. targetPlayer.Name .. " ===")
					if playerData then
						print("Has expandable farm:", PlayerHasExpandableFarm(playerData))
						print("Purchase history:", playerData.purchaseHistory and "EXISTS" or "NIL")
						if playerData.purchaseHistory then
							print("Farm plot starter:", playerData.purchaseHistory.farm_plot_starter and "TRUE" or "FALSE/NIL")
						end
						print("Farming data:", playerData.farming and "EXISTS" or "NIL")
						if playerData.farming then
							print("Expansion level:", playerData.farming.expansionLevel or "NIL")
							local level = playerData.farming.expansionLevel or 1
							local config = GameCore:GetExpansionConfig(level)
							print("Level config:", config and config.name or "NIL")
							print("Expected spots:", config and config.totalSpots or "NIL")
							print("Inventory:", playerData.farming.inventory and "EXISTS" or "NIL")
						end
					else
						print("NO PLAYER DATA")
					end

					local farm = ExpandableFarmPlotManager:GetPlayerExpandableFarm(targetPlayer)
					if farm then
						print("Physical farm found: YES")
						print("Farm position:", farm.PrimaryPart and tostring(farm.PrimaryPart.Position) or "NO PRIMARY PART")

						local plantingSpots = farm:FindFirstChild("PlantingSpots")
						if plantingSpots then
							local totalSpots = 0
							local unlockedSpots = 0
							for _, spot in pairs(plantingSpots:GetChildren()) do
								if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
									totalSpots = totalSpots + 1
									if spot:GetAttribute("IsUnlocked") then
										unlockedSpots = unlockedSpots + 1
									end
								end
							end
							print("Planting spots: " .. unlockedSpots .. " unlocked / " .. totalSpots .. " total")
						else
							print("Planting spots: MISSING")
						end
					else
						print("Physical farm found: NO")
					end
					print("=======================================")
				end

			elseif command == "/testexpansionconfig" then
				print("=== EXPANSION LEVEL CONFIGURATION ===")
				for level = 1, 5 do
					local config = GameCore:GetExpansionConfig(level)
					if config then
						print("Level " .. level .. ":")
						print("  Name: " .. config.name)
						print("  Grid Size: " .. config.gridSize .. "x" .. config.gridSize)
						print("  Total Spots: " .. config.totalSpots)
						print("  Cost: " .. config.cost .. " coins")
						print("  Base Size: " .. tostring(config.baseSize))
					else
						print("Level " .. level .. ": CONFIG MISSING")
					end
				end
				print("=====================================")

			elseif command == "/forceexpansionupdate" then
				local targetName = args[2] or player.Name
				local targetPlayer = Players:FindFirstChild(targetName)

				if targetPlayer then
					print("Admin: Force updating " .. targetPlayer.Name .. "'s expandable farm")
					local success = GameCore:CreateExpandableFarmPlot(targetPlayer)
					if success then
						print("Admin: Successfully updated expandable farm")
					else
						print("Admin: Failed to update expandable farm")
					end
				end
			end
		end
	end)
end)

-- Initialize the system
ExpandableFarmPlotManager:InitializeExistingPlayers()
ExpandableFarmPlotManager:MonitorExpandableFarmHealth()

print("=== ENHANCED EXPANDABLE FARM PLOT MANAGER ACTIVE ===")
print("Features:")
print("✅ Single expandable farm plot management")
print("✅ Expansion level validation and repair")
print("✅ Progressive spot unlocking verification")
print("✅ Position correction for misplaced farms")
print("✅ Cleanup of abandoned and old-style farms")
print("✅ Health monitoring every 5 minutes")
print("✅ Enhanced admin commands for expandable farms")
print("")
print("Admin Commands (TYPE IN CHAT):")
print("  /validateexpandablefarms - Check and fix all expandable farms")
print("  /cleanupexpandablefarms - Remove abandoned farms")
print("  /expandablefarmstats - Show detailed farm statistics")
print("  /giveexpandablefarm [player] - Give free expandable farm")
print("  /setexpansionlevel [player] [1-5] - Set specific expansion level")
print("  /expandfarm [player] - Expand farm to next level")
print("  /resetexpandablefarm [player] - Reset player's expandable farm")
print("  /teleporttoexpandablefarm [player] - Teleport to expandable farm")
print("  /checkexpandablefarmdata [player] - Debug expandable farm data")
print("  /testexpansionconfig - Show all expansion level configs")
print("  /forceexpansionupdate [player] - Force update farm structure")

-- Make globally available for other scripts
_G.ExpandableFarmPlotManager = ExpandableFarmPlotManager

return ExpandableFarmPlotManager