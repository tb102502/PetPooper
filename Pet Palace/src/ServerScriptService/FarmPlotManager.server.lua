--[[
    Simplified FarmPlotManager.server.lua - No Expansion System
    Replace your existing FarmPlotManager.lua with this version
    
    UPDATED FOR:
    ✅ Single 10x10 farm plot management
    ✅ No expansion levels or unlocking
    ✅ All 100 spots available immediately
    ✅ Simplified validation and repair systems
    ✅ Updated admin commands for simple farms
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

local GameCore = WaitForGameCore("SimpleFarmPlotManager")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("=== SIMPLIFIED FARM PLOT MANAGER STARTING ===")

-- Simple farm plot validation and repair system
local SimpleFarmPlotManager = {}

-- Check if player has simple farm plot
local function PlayerHasSimpleFarm(playerData)
	-- Check if player has purchased farm plot starter
	if playerData and playerData.purchaseHistory and playerData.purchaseHistory.farm_plot_starter then
		return true
	end

	-- Also check if they have farming data
	if playerData and playerData.farming and playerData.farming.plots then
		return true
	end

	return false
end

-- Initialize simple farms for existing players on server start
function SimpleFarmPlotManager:InitializeExistingPlayers()
	print("SimpleFarmPlotManager: Initializing simple farms for existing players...")

	for _, player in pairs(Players:GetPlayers()) do
		spawn(function()
			wait(2) -- Wait for player data to load
			self:ValidatePlayerSimpleFarm(player)
		end)
	end
end

-- Validate and repair player simple farm
function SimpleFarmPlotManager:ValidatePlayerSimpleFarm(player)
	local playerData = GameCore:GetPlayerData(player)
	if not playerData then 
		print("SimpleFarmPlotManager: No player data for " .. player.Name)
		return 
	end

	-- Only proceed if player has purchased farm plots
	if not PlayerHasSimpleFarm(playerData) then
		print("SimpleFarmPlotManager: Player " .. player.Name .. " has no simple farm")
		return
	end

	-- Initialize farming data if needed
	if not playerData.farming then
		playerData.farming = {
			plots = 1,
			inventory = {}
		}
		GameCore:SavePlayerData(player)
	end

	print("SimpleFarmPlotManager: Player " .. player.Name .. " should have a 10x10 farm")

	-- Get existing simple farm
	local existingFarm = self:GetPlayerSimpleFarm(player)

	if not existingFarm then
		-- Create missing simple farm
		print("SimpleFarmPlotManager: Creating missing simple farm for " .. player.Name)
		local success = GameCore:CreateSimpleFarmPlot(player)
		if success then
			print("SimpleFarmPlotManager: Created simple farm for " .. player.Name)
		else
			print("SimpleFarmPlotManager: Failed to create simple farm for " .. player.Name)
		end
	else
		-- Validate existing farm
		self:ValidateSimpleFarmStructure(player, existingFarm)
	end
end

-- Get player's simple farm model
function SimpleFarmPlotManager:GetPlayerSimpleFarm(player)
	local areas = workspace:FindFirstChild("Areas")
	if not areas then return nil end

	local starterMeadow = areas:FindFirstChild("Starter Meadow")
	if not starterMeadow then return nil end

	local farmArea = starterMeadow:FindFirstChild("Farm")
	if not farmArea then return nil end

	return farmArea:FindFirstChild(player.Name .. "_SimpleFarm")
end

-- Validate simple farm structure
function SimpleFarmPlotManager:ValidateSimpleFarmStructure(player, farmModel)
	print("SimpleFarmPlotManager: Validating simple farm structure for " .. player.Name)

	-- Check if farm has correct planting spots
	local plantingSpots = farmModel:FindFirstChild("PlantingSpots")
	if not plantingSpots then
		print("SimpleFarmPlotManager: Missing planting spots folder for " .. player.Name .. ", recreating farm")
		farmModel:Destroy()
		GameCore:CreateSimpleFarmPlot(player)
		return
	end

	-- Count spots (should be 100 for 10x10 grid)
	local totalSpots = 0
	local unlockedSpots = 0

	for _, spot in pairs(plantingSpots:GetChildren()) do
		if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
			totalSpots = totalSpots + 1
			local isUnlocked = spot:GetAttribute("IsUnlocked")
			if isUnlocked then
				unlockedSpots = unlockedSpots + 1
			end
		end
	end

	print("SimpleFarmPlotManager: Found " .. unlockedSpots .. " unlocked spots out of " .. totalSpots .. " total spots")
	print("SimpleFarmPlotManager: Expected 100 unlocked spots for 10x10 farm")

	-- If spot count doesn't match expected, update the farm
	if totalSpots ~= 100 or unlockedSpots ~= 100 then
		print("SimpleFarmPlotManager: Spot count mismatch, updating farm for " .. player.Name)
		GameCore:CreateSimpleFarmPlot(player)
	end

	-- Validate farm position
	self:ValidateSimpleFarmPosition(player, farmModel)
end

-- Validate simple farm position
function SimpleFarmPlotManager:ValidateSimpleFarmPosition(player, farmModel)
	if not GameCore.GetSimpleFarmPosition then
		print("SimpleFarmPlotManager: GetSimpleFarmPosition method not found")
		return
	end

	local expectedCFrame = GameCore:GetSimpleFarmPosition(player)
	local expectedPosition = expectedCFrame.Position

	local currentPosition = farmModel.PrimaryPart and farmModel.PrimaryPart.Position

	if currentPosition and expectedPosition then
		local distance = (currentPosition - expectedPosition).Magnitude

		-- If farm is more than 10 studs away from expected position, move it
		if distance > 10 then
			farmModel:SetPrimaryPartCFrame(expectedCFrame)
			print("SimpleFarmPlotManager: Corrected position for " .. player.Name .. "'s simple farm")
		end
	end
end

-- Clean up abandoned simple farms
function SimpleFarmPlotManager:CleanupAbandonedSimpleFarms()
	print("SimpleFarmPlotManager: Cleaning up abandoned simple farms...")

	local areas = workspace:FindFirstChild("Areas")
	if not areas then return end

	local starterMeadow = areas:FindFirstChild("Starter Meadow")
	if not starterMeadow then return end

	local farmArea = starterMeadow:FindFirstChild("Farm")
	if not farmArea then return end

	local cleanedCount = 0

	for _, simpleFarm in pairs(farmArea:GetChildren()) do
		if simpleFarm:IsA("Model") and (simpleFarm.Name:find("_SimpleFarm") or simpleFarm.Name:find("_ExpandableFarm")) then
			local playerName = simpleFarm.Name:gsub("_SimpleFarm", ""):gsub("_ExpandableFarm", "")
			local player = Players:FindFirstChild(playerName)

			-- If player doesn't exist, clean up their farm
			if not player then
				print("SimpleFarmPlotManager: Cleaning up abandoned farm for " .. playerName)
				simpleFarm:Destroy()
				cleanedCount = cleanedCount + 1
			end
		end
	end

	-- Also clean up old-style disconnected plots
	for _, playerFarm in pairs(farmArea:GetChildren()) do
		if playerFarm:IsA("Folder") and playerFarm.Name:find("_Farm") then
			local playerName = playerFarm.Name:gsub("_Farm", "")
			local player = Players:FindFirstChild(playerName)

			if not player then
				print("SimpleFarmPlotManager: Cleaning up old-style farm for " .. playerName)
				playerFarm:Destroy()
				cleanedCount = cleanedCount + 1
			end
		end
	end

	if cleanedCount > 0 then
		print("SimpleFarmPlotManager: Cleaned up " .. cleanedCount .. " abandoned farms")
	end
end

-- Monitor simple farm system health
function SimpleFarmPlotManager:MonitorSimpleFarmHealth()
	spawn(function()
		while true do
			wait(300) -- Check every 5 minutes

			local totalFarms = 0
			local playersWithFarms = 0
			local totalSpots = 0

			-- Count all simple farms and spots
			for _, player in pairs(Players:GetPlayers()) do
				local playerData = GameCore:GetPlayerData(player)
				if playerData and PlayerHasSimpleFarm(playerData) then
					playersWithFarms = playersWithFarms + 1
					totalFarms = totalFarms + 1
					totalSpots = totalSpots + 100 -- Each farm has 100 spots
				end
			end

			print("SimpleFarmPlotManager: Health Check - " .. playersWithFarms .. " players with simple farms, " .. totalSpots .. " total spots")

			-- Clean up abandoned farms periodically
			self:CleanupAbandonedSimpleFarms()
		end
	end)
end

-- Handle player joining - ensure their simple farm is set up
function SimpleFarmPlotManager:HandlePlayerAdded(player)
	spawn(function()
		wait(3) -- Wait for player data to load
		self:ValidatePlayerSimpleFarm(player)
	end)
end

-- Handle player leaving
function SimpleFarmPlotManager:HandlePlayerRemoving(player)
	print("SimpleFarmPlotManager: Player " .. player.Name .. " left - simple farm marked for cleanup check")
end

-- Setup event connections
Players.PlayerAdded:Connect(function(player)
	SimpleFarmPlotManager:HandlePlayerAdded(player)
end)

Players.PlayerRemoving:Connect(function(player)
	SimpleFarmPlotManager:HandlePlayerRemoving(player)
end)

-- Simplified admin commands for simple farm management
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		-- Replace with your username for admin commands
		if player.Name == "TommySalami311" then
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/validatesimplefarms" then
				print("Admin: Validating all simple farms...")
				for _, p in pairs(Players:GetPlayers()) do
					SimpleFarmPlotManager:ValidatePlayerSimpleFarm(p)
				end
				print("Admin: Simple farm validation complete")

			elseif command == "/cleanupsimplefarms" then
				SimpleFarmPlotManager:CleanupAbandonedSimpleFarms()
				print("Admin: Simple farm cleanup complete")

			elseif command == "/simplefarmstats" then
				local totalFarms = 0
				local playersWithFarms = 0

				for _, p in pairs(Players:GetPlayers()) do
					local playerData = GameCore:GetPlayerData(p)
					if playerData and PlayerHasSimpleFarm(playerData) then
						playersWithFarms = playersWithFarms + 1
						totalFarms = totalFarms + 1
						print("  " .. p.Name .. ": 10x10 Simple Farm (100 spots)")
					else
						print("  " .. p.Name .. ": NO SIMPLE FARM")
					end
				end

				print("Simple Farm Stats:")
				print("  Total farms: " .. totalFarms)
				print("  Players with farms: " .. playersWithFarms)
				print("  Grid size: Always 10x10 (100 spots each)")
				print("  All spots: Always unlocked")

			elseif command == "/givesimplefarm" then
				local targetName = args[2]
				if targetName then
					local targetPlayer = Players:FindFirstChild(targetName)
					if targetPlayer then
						local playerData = GameCore:GetPlayerData(targetPlayer)
						if playerData then
							-- Give them the simple farm
							playerData.purchaseHistory = playerData.purchaseHistory or {}
							playerData.purchaseHistory.farm_plot_starter = true
							playerData.farming = playerData.farming or {
								plots = 1,
								inventory = {
									carrot_seeds = 5, 
									corn_seeds = 3
								}
							}

							-- Create the simple farm
							GameCore:CreateSimpleFarmPlot(targetPlayer)

							if GameCore.SendNotification then
								GameCore:SendNotification(targetPlayer, "Admin Gift", "You received a free 10x10 farm with 100 planting spots!", "success")
							end
							print("Admin: Gave simple farm to " .. targetPlayer.Name)
						end
					else
						print("Admin: Player " .. targetName .. " not found")
					end
				end

			elseif command == "/resetsimplefarm" then
				local targetName = args[2]
				if targetName then
					local targetPlayer = Players:FindFirstChild(targetName)
					if targetPlayer then
						-- Remove their simple farm from workspace
						local farm = SimpleFarmPlotManager:GetPlayerSimpleFarm(targetPlayer)
						if farm then
							farm:Destroy()
							print("Admin: Destroyed " .. targetPlayer.Name .. "'s simple farm")
						end

						-- Reset their farm data
						local playerData = GameCore:GetPlayerData(targetPlayer)
						if playerData then
							playerData.purchaseHistory = playerData.purchaseHistory or {}
							playerData.purchaseHistory.farm_plot_starter = nil
							playerData.farming = nil
						end

						GameCore:SavePlayerData(targetPlayer)
						print("Admin: Reset simple farm data for " .. targetPlayer.Name)

						if GameCore.SendNotification then
							GameCore:SendNotification(targetPlayer, "Admin Action", "Your simple farm has been reset", "info")
						end
					else
						print("Admin: Player " .. targetName .. " not found")
					end
				end

			elseif command == "/teleporttosimplefarm" then
				local targetName = args[2] or player.Name
				local targetPlayer = Players:FindFirstChild(targetName)

				if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
					local farm = SimpleFarmPlotManager:GetPlayerSimpleFarm(targetPlayer)
					if farm and farm.PrimaryPart then
						local farmPosition = farm.PrimaryPart.Position + Vector3.new(0, 5, 20)
						player.Character.HumanoidRootPart.CFrame = CFrame.new(farmPosition)
						print("Admin: Teleported to " .. targetPlayer.Name .. "'s simple farm")
					else
						print("Admin: " .. targetPlayer.Name .. " has no simple farm")
					end
				else
					print("Admin: Player " .. targetName .. " not found or has no character")
				end

			elseif command == "/checksimplefarmdata" then
				local targetName = args[2] or player.Name
				local targetPlayer = Players:FindFirstChild(targetName)

				if targetPlayer then
					local playerData = GameCore:GetPlayerData(targetPlayer)
					print("=== SIMPLE FARM DATA DEBUG FOR " .. targetPlayer.Name .. " ===")
					if playerData then
						print("Has simple farm:", PlayerHasSimpleFarm(playerData))
						print("Purchase history:", playerData.purchaseHistory and "EXISTS" or "NIL")
						if playerData.purchaseHistory then
							print("Farm plot starter:", playerData.purchaseHistory.farm_plot_starter and "TRUE" or "FALSE/NIL")
						end
						print("Farming data:", playerData.farming and "EXISTS" or "NIL")
						if playerData.farming then
							print("Plots:", playerData.farming.plots or "NIL")
							print("Inventory:", playerData.farming.inventory and "EXISTS" or "NIL")
						end
					else
						print("NO PLAYER DATA")
					end

					local farm = SimpleFarmPlotManager:GetPlayerSimpleFarm(targetPlayer)
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
							print("Expected: 100 unlocked / 100 total")
						else
							print("Planting spots: MISSING")
						end
					else
						print("Physical farm found: NO")
					end
					print("=======================================")
				end

			elseif command == "/forcesimpleupdate" then
				local targetName = args[2] or player.Name
				local targetPlayer = Players:FindFirstChild(targetName)

				if targetPlayer then
					print("Admin: Force updating " .. targetPlayer.Name .. "'s simple farm")
					local success = GameCore:CreateSimpleFarmPlot(targetPlayer)
					if success then
						print("Admin: Successfully updated simple farm")
					else
						print("Admin: Failed to update simple farm")
					end
				end

			elseif command == "/converttoesimple" then
				local targetName = args[2] or player.Name
				local targetPlayer = Players:FindFirstChild(targetName)

				if targetPlayer then
					print("Admin: Converting " .. targetPlayer.Name .. " to simple farm system")

					-- Remove old expandable farm
					local areas = workspace:FindFirstChild("Areas")
					if areas then
						local starterMeadow = areas:FindFirstChild("Starter Meadow")
						if starterMeadow then
							local farmArea = starterMeadow:FindFirstChild("Farm")
							if farmArea then
								local oldFarm = farmArea:FindFirstChild(targetPlayer.Name .. "_ExpandableFarm")
								if oldFarm then
									oldFarm:Destroy()
									print("Admin: Removed old expandable farm")
								end
							end
						end
					end

					-- Create new simple farm
					local success = GameCore:CreateSimpleFarmPlot(targetPlayer)
					if success then
						print("Admin: Created new simple farm (10x10, 100 spots)")
					else
						print("Admin: Failed to create simple farm")
					end
				end
			end
		end
	end)
end)

-- Initialize the system
SimpleFarmPlotManager:InitializeExistingPlayers()
SimpleFarmPlotManager:MonitorSimpleFarmHealth()

print("=== SIMPLIFIED FARM PLOT MANAGER ACTIVE ===")
print("Features:")
print("✅ Single 10x10 farm plot management (100 spots)")
print("✅ All spots unlocked immediately")
print("✅ No expansion levels or requirements")
print("✅ Simplified validation and repair")
print("✅ Position correction for misplaced farms")
print("✅ Cleanup of abandoned farms")
print("✅ Health monitoring every 5 minutes")
print("✅ Simplified admin commands")
print("")
print("Admin Commands (TYPE IN CHAT):")
print("  /validatesimplefarms - Check and fix all simple farms")
print("  /cleanupsimplefarms - Remove abandoned farms")
print("  /simplefarmstats - Show simple farm statistics")
print("  /givesimplefarm [player] - Give free 10x10 farm")
print("  /resetsimplefarm [player] - Reset player's farm")
print("  /teleporttosimplefarm [player] - Teleport to simple farm")
print("  /checksimplefarmdata [player] - Debug simple farm data")
print("  /forcesimpleupdate [player] - Force update farm structure")
print("  /converttosimple [player] - Convert expandable farm to simple")

-- Make globally available for other scripts
_G.SimpleFarmPlotManager = SimpleFarmPlotManager

return SimpleFarmPlotManager