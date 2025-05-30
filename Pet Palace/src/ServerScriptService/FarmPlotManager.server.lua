--[[
    FarmPlotManager.server.lua
    Place in ServerScriptService
    Handles farm plot creation, management, and validation
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

local GameCore = WaitForGameCore("FarmPlotManager")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("=== FARM PLOT MANAGER STARTING ===")

-- Farm plot validation and repair system
local FarmPlotManager = {}

-- Initialize farm plots for existing players on server start
function FarmPlotManager:InitializeExistingPlayers()
	print("FarmPlotManager: Initializing farm plots for existing players...")

	for _, player in pairs(Players:GetPlayers()) do
		spawn(function()
			wait(2) -- Wait for player data to load
			self:ValidatePlayerFarm(player)
		end)
	end
end

-- Validate and repair player farm plots
function FarmPlotManager:ValidatePlayerFarm(player)
	local playerData = GameCore:GetPlayerData(player)
	if not playerData then return end

	-- Only proceed if player has purchased farm plots
	if not GameCore:PlayerHasFarmPlot(playerData) then
		return
	end

	local farmingData = playerData.farming or {}
	local expectedPlots = farmingData.plots or 1

	-- Get existing plots
	local existingPlots = self:GetPlayerFarmPlots(player)
	local existingCount = #existingPlots

	print("FarmPlotManager: Player " .. player.Name .. " should have " .. expectedPlots .. " plots, found " .. existingCount)

	-- Create missing plots
	if existingCount < expectedPlots then
		for plotNumber = existingCount + 1, expectedPlots do
			local success = GameCore:CreatePlayerFarmPlot(player, plotNumber)
			if success then
				print("FarmPlotManager: Created missing plot " .. plotNumber .. " for " .. player.Name)
			end
			wait(0.1)
		end
	end

	-- Remove excess plots (shouldn't happen, but just in case)
	if existingCount > expectedPlots then
		for i = expectedPlots + 1, existingCount do
			local plot = existingPlots[i]
			if plot then
				plot:Destroy()
				print("FarmPlotManager: Removed excess plot " .. i .. " for " .. player.Name)
			end
		end
	end

	-- Validate plot positions
	self:ValidatePlotPositions(player, expectedPlots)
end

-- Get all farm plots for a player
function FarmPlotManager:GetPlayerFarmPlots(player)
	local plots = {}
	local starterMeadow = workspace:FindFirstChild("Areas"):FindFirstChild("Starter Meadow")

	if starterMeadow then
		local farmArea = starterMeadow:FindFirstChild("Farm")
		if farmArea then
			local playerFarm = farmArea:FindFirstChild(player.Name .. "_Farm")
			if playerFarm then
				for _, plot in pairs(playerFarm:GetChildren()) do
					if plot:IsA("Model") and plot.Name:find("FarmPlot") then
						-- Sort by plot number
						local plotNumber = tonumber(plot.Name:match("FarmPlot_(%d+)"))
						if plotNumber then
							plots[plotNumber] = plot
						end
					end
				end
			end
		end
	end

	-- Convert to array format
	local plotArray = {}
	for i = 1, 10 do -- Max 10 plots
		if plots[i] then
			table.insert(plotArray, plots[i])
		end
	end

	return plotArray
end

-- Validate plot positions and fix if needed
function FarmPlotManager:ValidatePlotPositions(player, expectedPlots)
	local plots = self:GetPlayerFarmPlots(player)

	for i, plot in ipairs(plots) do
		if plot then
			local expectedPosition = GameCore:GetFarmPlotPosition(player, i)
			local currentPosition = plot.PrimaryPart and plot.PrimaryPart.Position

			if currentPosition and expectedPosition then
				local distance = (currentPosition - expectedPosition).Magnitude

				-- If plot is more than 5 studs away from expected position, move it
				if distance > 5 then
					plot:SetPrimaryPartCFrame(CFrame.new(expectedPosition))
					print("FarmPlotManager: Corrected position for plot " .. i .. " of " .. player.Name)
				end
			end
		end
	end
end

-- Clean up abandoned farm plots
function FarmPlotManager:CleanupAbandonedPlots()
	print("FarmPlotManager: Cleaning up abandoned farm plots...")

	local starterMeadow = workspace:FindFirstChild("Areas"):FindFirstChild("Starter Meadow")
	if not starterMeadow then return end

	local farmArea = starterMeadow:FindFirstChild("Farm")
	if not farmArea then return end

	local cleanedCount = 0

	for _, playerFarm in pairs(farmArea:GetChildren()) do
		if playerFarm:IsA("Folder") and playerFarm.Name:find("_Farm") then
			local playerName = playerFarm.Name:gsub("_Farm", "")
			local player = Players:FindFirstChild(playerName)

			-- If player doesn't exist, clean up their farm
			if not player then
				print("FarmPlotManager: Cleaning up abandoned farm for " .. playerName)
				playerFarm:Destroy()
				cleanedCount = cleanedCount + 1
			end
		end
	end

	if cleanedCount > 0 then
		print("FarmPlotManager: Cleaned up " .. cleanedCount .. " abandoned farms")
	end
end

-- Monitor farm plot system health
function FarmPlotManager:MonitorFarmHealth()
	spawn(function()
		while true do
			wait(300) -- Check every 5 minutes

			local totalPlots = 0
			local playersWithFarms = 0

			-- Count all farm plots and players
			for _, player in pairs(Players:GetPlayers()) do
				local playerData = GameCore:GetPlayerData(player)
				if playerData and GameCore:PlayerHasFarmPlot(playerData) then
					playersWithFarms = playersWithFarms + 1
					local plots = self:GetPlayerFarmPlots(player)
					totalPlots = totalPlots + #plots
				end
			end

			print("FarmPlotManager: Health Check - " .. playersWithFarms .. " players with farms, " .. totalPlots .. " total plots")

			-- Clean up abandoned plots periodically
			self:CleanupAbandonedPlots()
		end
	end)
end

-- Handle player joining - ensure their farm is set up
function FarmPlotManager:HandlePlayerAdded(player)
	-- Wait for player data to load
	spawn(function()
		wait(3)
		self:ValidatePlayerFarm(player)
	end)
end

-- Handle player leaving - mark for cleanup
function FarmPlotManager:HandlePlayerRemoving(player)
	-- Farm cleanup will be handled by the monitoring system
	print("FarmPlotManager: Player " .. player.Name .. " left - farm marked for cleanup check")
end

-- Setup event connections
Players.PlayerAdded:Connect(function(player)
	FarmPlotManager:HandlePlayerAdded(player)
end)

Players.PlayerRemoving:Connect(function(player)
	FarmPlotManager:HandlePlayerRemoving(player)
end)

-- Admin commands for farm plot management
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		-- Replace with your username for admin commands
		if player.Name == "TommySalami311" then
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/validatefarms" then
				print("Admin: Validating all player farms...")
				for _, p in pairs(Players:GetPlayers()) do
					FarmPlotManager:ValidatePlayerFarm(p)
				end
				print("Admin: Farm validation complete")

			elseif command == "/cleanupfarms" then
				FarmPlotManager:CleanupAbandonedPlots()
				print("Admin: Farm cleanup complete")

			elseif command == "/farmstats" then
				local totalPlots = 0
				local playersWithFarms = 0

				for _, p in pairs(Players:GetPlayers()) do
					local playerData = GameCore:GetPlayerData(p)
					if playerData and GameCore:PlayerHasFarmPlot(playerData) then
						playersWithFarms = playersWithFarms + 1
						local plots = FarmPlotManager:GetPlayerFarmPlots(p)
						totalPlots = totalPlots + #plots
						print("  " .. p.Name .. ": " .. #plots .. " plots")
					end
				end

				print("Farm Stats: " .. playersWithFarms .. " players with farms, " .. totalPlots .. " total plots")

			elseif command == "/givefarmplot" then
				local targetName = args[2]
				if targetName then
					local targetPlayer = Players:FindFirstChild(targetName)
					if targetPlayer then
						local playerData = GameCore:GetPlayerData(targetPlayer)
						if playerData then
							-- Give them the farm plot
							playerData.purchaseHistory = playerData.purchaseHistory or {}
							playerData.purchaseHistory.farm_plot_starter = true
							playerData.farming = playerData.farming or {plots = 1, inventory = {carrot_seeds = 5, corn_seeds = 3}, pig = {feedCount = 0, size = 1.0}}

							-- Create the plot
							GameCore:CreatePlayerFarmPlot(targetPlayer, 1)
							GameCore:SendNotification(targetPlayer, "Admin Gift", "You received a free farm plot!", "success")
							print("Admin: Gave farm plot to " .. targetPlayer.Name)
						end
					else
						print("Admin: Player " .. targetName .. " not found")
					end
				end

			elseif command == "/resetfarm" then
				local targetName = args[2]
				if targetName then
					local targetPlayer = Players:FindFirstChild(targetName)
					if targetPlayer then
						-- Remove their farm plots from workspace
						local plots = FarmPlotManager:GetPlayerFarmPlots(targetPlayer)
						for _, plot in pairs(plots) do
							plot:Destroy()
						end

						-- Reset their farm data
						local playerData = GameCore:GetPlayerData(targetPlayer)
						if playerData then
							playerData.purchaseHistory = playerData.purchaseHistory or {}
							playerData.purchaseHistory.farm_plot_starter = nil
							playerData.farming = nil
						end

						print("Admin: Reset farm for " .. targetPlayer.Name)
						GameCore:SendNotification(targetPlayer, "Admin Action", "Your farm has been reset", "info")
					end
				end

			elseif command == "/teleporttofarm" then
				local targetName = args[2] or player.Name
				local targetPlayer = Players:FindFirstChild(targetName)

				if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
					local plots = FarmPlotManager:GetPlayerFarmPlots(targetPlayer)
					if #plots > 0 and plots[1].PrimaryPart then
						local farmPosition = plots[1].PrimaryPart.Position + Vector3.new(0, 5, 10)
						player.Character.HumanoidRootPart.CFrame = CFrame.new(farmPosition)
						print("Admin: Teleported to " .. targetPlayer.Name .. "'s farm")
					else
						print("Admin: " .. targetPlayer.Name .. " has no farm plots")
					end
				end
			end
		end
	end)
end)

-- Initialize the system
FarmPlotManager:InitializeExistingPlayers()
FarmPlotManager:MonitorFarmHealth()

print("=== FARM PLOT MANAGER ACTIVE ===")
print("Features:")
print("✅ Automatic farm plot validation and repair")
print("✅ Position correction for misplaced plots")
print("✅ Cleanup of abandoned farms")
print("✅ Health monitoring every 5 minutes")
print("✅ Admin commands for farm management")
print("")
print("Admin Commands (replace username in script):")
print("  /validatefarms - Check and fix all player farms")
print("  /cleanupfarms - Remove abandoned farms")
print("  /farmstats - Show farm statistics")
print("  /givefarmplot [player] - Give free farm plot")
print("  /resetfarm [player] - Reset player's farm")
print("  /teleporttofarm [player] - Teleport to player's farm")

-- Make globally available for other scripts
_G.FarmPlotManager = FarmPlotManager

return FarmPlotManager