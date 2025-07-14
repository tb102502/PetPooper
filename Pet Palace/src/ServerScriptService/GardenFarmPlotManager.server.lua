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

local GameCore = WaitForGameCore("GardenFarmPlotManager")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

print("=== GARDEN FARM PLOT MANAGER STARTING ===")

local GardenFarmPlotManager = {}

-- Garden-based farm validation and management
function GardenFarmPlotManager:InitializeExistingPlayers()
	print("GardenFarmPlotManager: Initializing garden regions for existing players...")

	for _, player in pairs(Players:GetPlayers()) do
		spawn(function()
			wait(2) -- Wait for player data to load
			self:ValidatePlayerGardenRegion(player)
		end)
	end
end

function GardenFarmPlotManager:ValidatePlayerGardenRegion(player)
	local playerData = GameCore:GetPlayerData(player)
	if not playerData then 
		print("GardenFarmPlotManager: No player data for " .. player.Name)
		return 
	end

	-- AUTO-GRANT GARDEN TO ALL PLAYERS (remove purchase check)
	print("GardenFarmPlotManager: All players automatically get gardens")

	-- Initialize farming data if needed
	if not playerData.farming then
		playerData.farming = {
			plots = 1,
			inventory = {
				carrot_seeds = 5,
				corn_seeds = 3
			}
		}

		-- Mark as having farm access
		playerData.purchaseHistory = playerData.purchaseHistory or {}
		playerData.purchaseHistory.farm_plot_starter = true

		GameCore:SavePlayerData(player)
	end

	print("GardenFarmPlotManager: Player " .. player.Name .. " should have a garden region")

	-- Check if garden region exists
	local garden = workspace:FindFirstChild("Garden")
	if not garden then
		warn("GardenFarmPlotManager: Garden model not found in workspace")
		return
	end

	local regionName = player.Name .. "_GardenRegion"
	local existingRegion = garden:FindFirstChild(regionName)

	if not existingRegion then
		-- Create missing garden region
		print("GardenFarmPlotManager: Creating automatic garden region for " .. player.Name)
		if _G.FarmPlot then
			local success = _G.FarmPlot:CreateSimpleFarmPlot(player)
			if success then
				print("GardenFarmPlotManager: Created garden region for " .. player.Name)
			else
				print("GardenFarmPlotManager: Failed to create garden region for " .. player.Name)
			end
		end
	else
		-- Validate existing region
		self:ValidateGardenRegionStructure(player, existingRegion)
	end
end


function GardenFarmPlotManager:ValidateGardenRegionStructure(player, region)
	print("GardenFarmPlotManager: Validating garden region structure for " .. player.Name)

	-- Check planting spots
	local plantingSpots = region:FindFirstChild("PlantingSpots")
	if not plantingSpots then
		print("GardenFarmPlotManager: Missing planting spots folder for " .. player.Name .. ", recreating region")
		region:Destroy()
		if _G.FarmPlot then
			_G.FarmPlot:CreateSimpleFarmPlot(player)
		end
		return
	end

	-- Count spots (should be 100 for garden system)
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

	print("GardenFarmPlotManager: Found " .. unlockedSpots .. " unlocked spots out of " .. totalSpots .. " total spots")

	-- Garden system should have 100 unlocked spots
	if totalSpots ~= 100 or unlockedSpots ~= 100 then
		print("GardenFarmPlotManager: Spot count mismatch, recreating garden region for " .. player.Name)
		region:Destroy()
		if _G.FarmPlot then
			_G.FarmPlot:CreateSimpleFarmPlot(player)
		end
	end
end

-- Setup player handlers for garden system
Players.PlayerAdded:Connect(function(player)
	GardenFarmPlotManager:ValidatePlayerGardenRegion(player)
end)

-- Initialize the system
GardenFarmPlotManager:InitializeExistingPlayers()

print("=== GARDEN FARM PLOT MANAGER ACTIVE ===")
_G.GardenFarmPlotManager = GardenFarmPlotManager
