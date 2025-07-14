--[[
    Modified FarmPlot.lua - Garden Model Integration
    Place in: ServerScriptService/Modules/FarmPlot.lua
    
    MODIFICATIONS:
    ✅ Uses existing Garden model instead of creating new farms
    ✅ Creates virtual planting grid on Soil part
    ✅ Maintains existing module structure and functionality
    ✅ Supports multiple players with region allocation
]]

local FarmPlot = {}

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Module references (will be injected)
local GameCore = nil

-- Garden Configuration
FarmPlot.GardenConfig = {
	-- Grid settings for planting spots on Soil
	gridSize = 10,          -- 10x10 grid = 100 spots per player
	totalSpots = 100,
	spotSize = 3,           -- Size of each virtual planting spot
	spotSpacing = 5,        -- Distance between spots
	playerSeparation = 60,  -- Distance between player regions

	-- Garden detection
	gardenModelName = "Garden",
	soilPartName = "Soil",

	-- Visual settings for planting spots
	spotColor = Color3.fromRGB(91, 154, 76),
	spotTransparency = 0.7,
	lockedSpotColor = Color3.fromRGB(80, 80, 80),
	lockedSpotTransparency = 0.8
}

-- Internal state
FarmPlot.ActiveGardenRegions = {}
FarmPlot.GardenModel = nil
FarmPlot.SoilPart = nil

-- ========== INITIALIZATION ==========

function FarmPlot:Initialize(gameCoreRef)
	print("FarmPlot: Initializing Garden-based farm plot system...")

	-- Store module references
	GameCore = gameCoreRef

	-- Initialize garden system
	self.ActiveGardenRegions = {}

	-- Find and validate Garden model
	if not self:FindAndValidateGarden() then
		error("FarmPlot: Garden model not found or invalid!")
	end

	-- Initialize region tracking
	self:InitializeRegionTracking()

	print("FarmPlot: ✅ Garden-based farm plot system initialized successfully")
	return true
end

function FarmPlot:FindAndValidateGarden()
	print("FarmPlot: Looking for Garden model in workspace...")

	-- Find Garden model
	local garden = Workspace:FindFirstChild(self.GardenConfig.gardenModelName)
	if not garden then
		warn("FarmPlot: Garden model '" .. self.GardenConfig.gardenModelName .. "' not found in workspace")
		return false
	end

	-- Find Soil part
	local soil = garden:FindFirstChild(self.GardenConfig.soilPartName)
	if not soil or not soil:IsA("BasePart") then
		warn("FarmPlot: Soil part '" .. self.GardenConfig.soilPartName .. "' not found in Garden or is not a BasePart")
		return false
	end

	-- Validate Garden setup
	if garden.PrimaryPart ~= soil then
		print("FarmPlot: Setting Soil as Garden's PrimaryPart")
		garden.PrimaryPart = soil
	end

	self.GardenModel = garden
	self.SoilPart = soil

	print("FarmPlot: ✅ Garden model validated:")
	print("  Garden: " .. garden.Name)
	print("  Soil: " .. soil.Name .. " (Size: " .. tostring(soil.Size) .. ")")
	print("  Position: " .. tostring(soil.Position))

	return true
end

function FarmPlot:InitializeRegionTracking()
	-- Initialize tracking for player regions on the soil
	spawn(function()
		while true do
			wait(60) -- Check every minute
			self:CleanupAbandonedRegions()
		end
	end)
end

-- ========== GARDEN REGION CREATION ==========

function FarmPlot:CreateSimpleFarmPlot(player)
	print("FarmPlot: Creating Garden region for " .. player.Name)

	if not self.GardenModel or not self.SoilPart then
		warn("FarmPlot: Garden not available")
		return false
	end

	local playerData = GameCore:GetPlayerData(player)
	if not playerData then
		warn("FarmPlot: No player data for " .. player.Name)
		return false
	end

	-- Initialize farming data if needed
	if not playerData.farming then
		playerData.farming = {
			plots = 1,
			inventory = {}
		}
	end

	-- Get player's region position on the soil
	local regionCFrame = self:GetPlayerRegionPosition(player)

	-- Create player's farming region
	return self:CreatePlayerGardenRegion(player, regionCFrame)
end

function FarmPlot:GetPlayerRegionPosition(player)
	-- Calculate player's allocated region on the Soil part
	local playerIndex = self:GetPlayerIndex(player)

	-- Get soil dimensions
	local soilSize = self.SoilPart.Size
	local soilCFrame = self.SoilPart.CFrame

	-- Calculate regions per row based on soil size
	local regionSize = self.GardenConfig.playerSeparation
	local regionsPerRow = math.floor(soilSize.X / regionSize)

	-- Calculate position within the soil bounds
	local row = math.floor(playerIndex / regionsPerRow)
	local col = playerIndex % regionsPerRow

	-- Offset from soil center
	local offsetX = (col - regionsPerRow/2) * regionSize + regionSize/2
	local offsetZ = (row * regionSize) - soilSize.Z/2 + regionSize/2

	-- Ensure we stay within soil bounds
	offsetX = math.max(-soilSize.X/2 + regionSize/2, math.min(soilSize.X/2 - regionSize/2, offsetX))
	offsetZ = math.max(-soilSize.Z/2 + regionSize/2, math.min(soilSize.Z/2 - regionSize/2, offsetZ))

	-- Calculate world position
	local regionPosition = soilCFrame:PointToWorldSpace(Vector3.new(offsetX, 0.1, offsetZ))

	return CFrame.new(regionPosition, regionPosition + soilCFrame.LookVector)
end

function FarmPlot:GetPlayerIndex(player)
	-- Get consistent player index for region allocation
	local allPlayers = {}
	for _, p in pairs(Players:GetPlayers()) do
		table.insert(allPlayers, p)
	end
	table.sort(allPlayers, function(a, b) return a.UserId < b.UserId end)

	for i, p in ipairs(allPlayers) do
		if p.UserId == player.UserId then
			return i - 1
		end
	end

	return 0
end

function FarmPlot:CreatePlayerGardenRegion(player, regionCFrame)
	print("FarmPlot: Creating garden region for " .. player.Name)

	local config = self.GardenConfig

	-- Create player's region container
	local regionContainer = Instance.new("Model")
	regionContainer.Name = player.Name .. "_GardenRegion"
	regionContainer.Parent = self.GardenModel

	-- Create region base (invisible marker)
	local regionBase = Instance.new("Part")
	regionBase.Name = "RegionBase"
	regionBase.Size = Vector3.new(config.playerSeparation, 0.1, config.playerSeparation)
	regionBase.Material = Enum.Material.ForceField
	regionBase.Color = Color3.fromRGB(100, 200, 100)
	regionBase.Anchored = true
	regionBase.CanCollide = false
	regionBase.Transparency = 0.9
	regionBase.CFrame = regionCFrame
	regionBase.Parent = regionContainer

	regionContainer.PrimaryPart = regionBase

	-- Create planting spots grid
	local plantingSpots = Instance.new("Folder")
	plantingSpots.Name = "PlantingSpots"
	plantingSpots.Parent = regionContainer

	self:CreateGardenPlantingGrid(player, regionContainer, plantingSpots, regionCFrame)

	-- Create region info display
	self:CreateRegionInfoSign(regionContainer, regionCFrame, player)

	-- Track the region
	self:TrackPlayerRegion(player, regionContainer)

	print("FarmPlot: Created garden region for " .. player.Name .. " with " .. config.totalSpots .. " spots")
	return true
end

function FarmPlot:CreateGardenPlantingGrid(player, regionContainer, plantingSpots, regionCFrame)
	local config = self.GardenConfig
	local gridSize = config.gridSize
	local spotSize = config.spotSize
	local spacing = config.spotSpacing

	-- Calculate grid offset to center it within the region
	local gridOffset = (gridSize - 1) * spacing / 2

	local spotIndex = 0
	for row = 1, gridSize do
		for col = 1, gridSize do
			spotIndex = spotIndex + 1
			local spotName = "PlantingSpot_" .. spotIndex

			local spotModel = self:CreateGardenPlantingSpot(
				spotName,
				regionCFrame,
				row, col,
				spacing,
				gridOffset,
				config,
				true -- All spots unlocked in garden system
			)

			spotModel.Parent = plantingSpots

			-- Setup click detection
			self:SetupGardenPlotClickDetection(spotModel, player)
		end
	end

	print("FarmPlot: Created " .. spotIndex .. " planting spots in garden region")
end

function FarmPlot:CreateGardenPlantingSpot(spotName, regionCFrame, row, col, spacing, gridOffset, config, isUnlocked)
	local spotModel = Instance.new("Model")
	spotModel.Name = spotName

	-- Position calculation (centered within region)
	local offsetX = (col - 1) * spacing - gridOffset
	local offsetZ = (row - 1) * spacing - gridOffset

	-- Create the planting spot part
	local spotPart = Instance.new("Part")
	spotPart.Name = "SpotPart"
	spotPart.Size = Vector3.new(config.spotSize, 0.2, config.spotSize)
	spotPart.Material = Enum.Material.LeafyGrass
	spotPart.Anchored = true
	spotPart.CanCollide = false
	spotPart.CFrame = regionCFrame + Vector3.new(offsetX, 0.5, offsetZ)
	spotPart.Parent = spotModel

	spotModel.PrimaryPart = spotPart

	-- Set spot attributes
	spotModel:SetAttribute("IsEmpty", true)
	spotModel:SetAttribute("PlantType", "")
	spotModel:SetAttribute("SeedType", "")
	spotModel:SetAttribute("GrowthStage", 0)
	spotModel:SetAttribute("PlantedTime", 0)
	spotModel:SetAttribute("Rarity", "common")
	spotModel:SetAttribute("IsUnlocked", isUnlocked)
	spotModel:SetAttribute("GridRow", row)
	spotModel:SetAttribute("GridCol", col)
	spotModel:SetAttribute("IsGardenSpot", true) -- Mark as garden spot

	-- Visual styling based on unlock status
	if isUnlocked then
		spotPart.Color = config.spotColor
		spotPart.Transparency = config.spotTransparency

		-- Create subtle interaction indicator
		local indicator = Instance.new("Part")
		indicator.Name = "Indicator"
		indicator.Size = Vector3.new(0.3, 1, 0.3)
		indicator.Material = Enum.Material.Neon
		indicator.Color = Color3.fromRGB(150, 255, 150)
		indicator.Anchored = true
		indicator.CanCollide = false
		indicator.Transparency = 0.8
		indicator.CFrame = spotPart.CFrame + Vector3.new(0, 0.8, 0)
		indicator.Parent = spotModel
	else
		spotPart.Color = config.lockedSpotColor
		spotPart.Transparency = config.lockedSpotTransparency

		-- Create lock indicator
		local lockIndicator = Instance.new("Part")
		lockIndicator.Name = "LockIndicator"
		lockIndicator.Size = Vector3.new(0.5, 0.5, 0.5)
		lockIndicator.Material = Enum.Material.Neon
		lockIndicator.Color = Color3.fromRGB(255, 100, 100)
		lockIndicator.Anchored = true
		lockIndicator.CanCollide = false
		lockIndicator.CFrame = spotPart.CFrame + Vector3.new(0, 0.5, 0)
		lockIndicator.Parent = spotModel
	end

	return spotModel
end

function FarmPlot:SetupGardenPlotClickDetection(spotModel, player)
	local spotPart = spotModel:FindFirstChild("SpotPart")
	if not spotPart then return end

	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 15
	clickDetector.Parent = spotPart

	clickDetector.MouseClick:Connect(function(clickingPlayer)
		if clickingPlayer.UserId == player.UserId then
			self:HandleGardenPlotClick(clickingPlayer, spotModel)
		end
	end)
end

function FarmPlot:CreateRegionInfoSign(regionContainer, regionCFrame, player)
	local config = self.GardenConfig

	local signContainer = Instance.new("Model")
	signContainer.Name = "RegionInfoSign"
	signContainer.Parent = regionContainer

	local signPost = Instance.new("Part")
	signPost.Name = "SignPost"
	signPost.Size = Vector3.new(0.3, 3, 0.3)
	signPost.Material = Enum.Material.Wood
	signPost.Color = Color3.fromRGB(92, 51, 23)
	signPost.Anchored = true
	signPost.CanCollide = false
	signPost.CFrame = regionCFrame + Vector3.new(config.playerSeparation/2 - 5, 1.5, -config.playerSeparation/2 + 3)
	signPost.Parent = signContainer

	local signBoard = Instance.new("Part")
	signBoard.Name = "SignBoard"
	signBoard.Size = Vector3.new(3, 2, 0.2)
	signBoard.Material = Enum.Material.Wood
	signBoard.Color = Color3.fromRGB(139, 90, 43)
	signBoard.Anchored = true
	signBoard.CanCollide = false
	signBoard.CFrame = signPost.CFrame + Vector3.new(1.5, 0.3, 0)
	signBoard.Parent = signContainer

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.Parent = signBoard

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = player.Name .. "'s Garden\n" .. 
		config.gridSize .. "x" .. config.gridSize .. " Grid\n" .. 
		config.totalSpots .. " Planting Spots"
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextStrokeTransparency = 0
	textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	textLabel.Parent = surfaceGui
end

-- ========== GARDEN MANAGEMENT ==========

function FarmPlot:GetPlayerFarm(player)
	-- Return player's garden region
	if not self.GardenModel then return nil end

	local regionName = player.Name .. "_GardenRegion"
	local region = self.GardenModel:FindFirstChild(regionName)

	if region then
		return region, "garden"
	end

	return nil, nil
end

function FarmPlot:GetPlotOwner(plotModel)
	-- Traverse up to find the garden region
	local parent = plotModel.Parent
	local attempts = 0

	while parent and parent.Parent and attempts < 10 do
		attempts = attempts + 1

		if parent.Name:find("_GardenRegion") then
			return parent.Name:gsub("_GardenRegion", "")
		end

		parent = parent.Parent
	end

	return nil
end

function FarmPlot:FindPlotByName(player, plotName)
	local region, regionType = self:GetPlayerFarm(player)
	if not region then
		warn("FarmPlot: No garden region found for player: " .. player.Name)
		return nil
	end

	local plantingSpots = region:FindFirstChild("PlantingSpots")
	if not plantingSpots then
		warn("FarmPlot: No PlantingSpots folder found in garden region")
		return nil
	end

	-- Try exact match first
	local exactMatch = plantingSpots:FindFirstChild(plotName)
	if exactMatch then
		return exactMatch
	end

	-- Try case-insensitive search
	local lowerPlotName = plotName:lower()
	for _, spot in pairs(plantingSpots:GetChildren()) do
		if spot:IsA("Model") and spot.Name:lower() == lowerPlotName then
			return spot
		end
	end

	-- Try pattern matching for PlantingSpot_X format
	local plotNumber = plotName:match("(%d+)")
	if plotNumber then
		local standardName = "PlantingSpot_" .. plotNumber
		local standardMatch = plantingSpots:FindFirstChild(standardName)
		if standardMatch then
			return standardMatch
		end
	end

	warn("FarmPlot: Plot not found in garden region: " .. plotName)
	return nil
end

-- ========== GARDEN PLOT INTERACTION ==========

function FarmPlot:HandleGardenPlotClick(player, spotModel)
	-- Check if plot is empty - if so, handle planting
	local isEmpty = spotModel:GetAttribute("IsEmpty")
	local isUnlocked = spotModel:GetAttribute("IsUnlocked")

	if not isUnlocked then
		self:SendNotification(player, "Locked Plot", "This garden spot is locked! Purchase upgrades to unlock it.", "error")
		return
	end

	if not isEmpty then
		-- Plot has a crop - tell player to click the crop instead
		self:SendNotification(player, "Click the Crop", "Click on the crop itself to harvest it, not the garden spot!", "info")
		return
	end

	-- Plot is empty - handle seed planting
	local plotOwner = self:GetPlotOwner(spotModel)
	if plotOwner ~= player.Name then
		self:SendNotification(player, "Not Your Garden", "You can only plant in your own garden region!", "error")
		return
	end

	local playerData = GameCore:GetPlayerData(player)
	if not playerData or not playerData.farming or not playerData.farming.inventory then
		self:SendNotification(player, "No Farming Data", "You need to set up farming first! Visit the shop.", "warning")
		return
	end

	local hasSeeds = false
	for itemId, qty in pairs(playerData.farming.inventory) do
		if itemId:find("_seeds") and qty > 0 then
			hasSeeds = true
			break
		end
	end

	if not hasSeeds then
		self:SendNotification(player, "No Seeds", "You don't have any seeds! Buy some from the shop first.", "warning")
		return
	end

	-- Trigger planting interface
	if GameCore and GameCore.RemoteEvents and GameCore.RemoteEvents.PlantSeed then
		GameCore.RemoteEvents.PlantSeed:FireClient(player, spotModel)
	end
end

-- ========== REGION TRACKING ==========

function FarmPlot:TrackPlayerRegion(player, region)
	self.ActiveGardenRegions[player.UserId] = {
		player = player,
		region = region,
		created = tick(),
		lastValidated = tick()
	}
end

function FarmPlot:CleanupAbandonedRegions()
	print("FarmPlot: Cleaning up abandoned garden regions...")

	if not self.GardenModel then return end

	local cleanedCount = 0

	for _, region in pairs(self.GardenModel:GetChildren()) do
		if region:IsA("Model") and region.Name:find("_GardenRegion") then
			local playerName = region.Name:gsub("_GardenRegion", "")
			local player = Players:FindFirstChild(playerName)

			-- If player doesn't exist, clean up their region
			if not player then
				print("FarmPlot: Cleaning up abandoned garden region for " .. playerName)
				region:Destroy()
				cleanedCount = cleanedCount + 1
			end
		end
	end

	-- Clean up tracking data
	for userId, regionData in pairs(self.ActiveGardenRegions) do
		local player = regionData.player
		if not player or not player.Parent then
			self.ActiveGardenRegions[userId] = nil
		end
	end

	if cleanedCount > 0 then
		print("FarmPlot: Cleaned up " .. cleanedCount .. " abandoned garden regions")
	end
end

-- ========== GARDEN VALIDATION ==========

function FarmPlot:ValidatePlayerGardenRegion(player)
	local playerData = GameCore:GetPlayerData(player)
	if not playerData then return end

	-- Check if player should have a garden region
	local shouldHaveRegion = (playerData.purchaseHistory and playerData.purchaseHistory.farm_plot_starter) or
		(playerData.farming and playerData.farming.plots and playerData.farming.plots > 0)

	if not shouldHaveRegion then
		return
	end

	-- Check if region exists
	local region, regionType = self:GetPlayerFarm(player)
	if not region then
		print("FarmPlot: Creating missing garden region for " .. player.Name)
		self:CreateSimpleFarmPlot(player)
	else
		print("FarmPlot: Garden region exists for " .. player.Name)
	end
end

function FarmPlot:EnsurePlayerHasFarm(player)
	if not self.GardenModel or not self.SoilPart then
		warn("FarmPlot: Garden not available")
		return false
	end

	local playerData = GameCore:GetPlayerData(player)
	if not playerData then return false end

	-- AUTO-GRANT FARM ACCESS TO ALL PLAYERS (no purchase required)
	-- Initialize farming data if missing
	if not playerData.farming then
		playerData.farming = {
			plots = 1,
			inventory = {
				carrot_seeds = 5,
				corn_seeds = 3
			}
		}
		GameCore:SavePlayerData(player)
	end

	-- Check if garden region already exists
	local region, regionType = self:GetPlayerFarm(player)
	if not region then
		print("FarmPlot: Creating automatic garden region for " .. player.Name)
		return self:CreateSimpleFarmPlot(player)
	end

	print("FarmPlot: Garden already exists for " .. player.Name)
	return true
end

-- ========== UTILITY FUNCTIONS ==========

function FarmPlot:SendNotification(player, title, message, type)
	if GameCore and GameCore.SendNotification then
		GameCore:SendNotification(player, title, message, type)
	else
		print("[" .. title .. "] " .. message .. " (to " .. player.Name .. ")")
	end
end

function FarmPlot:GetPlayerFarmStatistics(player)
	local region, regionType = self:GetPlayerFarm(player)
	if not region then
		return {
			exists = false,
			type = "none",
			totalSpots = 0,
			unlockedSpots = 0,
			occupiedSpots = 0
		}
	end

	local plantingSpots = region:FindFirstChild("PlantingSpots")
	if not plantingSpots then
		return {
			exists = true,
			type = regionType,
			totalSpots = 0,
			unlockedSpots = 0,
			occupiedSpots = 0,
			error = "No planting spots folder"
		}
	end

	local totalSpots = 0
	local unlockedSpots = 0
	local occupiedSpots = 0

	for _, spot in pairs(plantingSpots:GetChildren()) do
		if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
			totalSpots = totalSpots + 1

			if spot:GetAttribute("IsUnlocked") then
				unlockedSpots = unlockedSpots + 1
			end

			if not spot:GetAttribute("IsEmpty") then
				occupiedSpots = occupiedSpots + 1
			end
		end
	end

	return {
		exists = true,
		type = regionType,
		totalSpots = totalSpots,
		unlockedSpots = unlockedSpots,
		occupiedSpots = occupiedSpots,
		emptySpots = unlockedSpots - occupiedSpots,
		gardenModel = self.GardenModel and self.GardenModel.Name,
		soilPart = self.SoilPart and self.SoilPart.Name
	}
end

-- ========== LEGACY COMPATIBILITY ==========

-- These functions maintain compatibility with existing code
function FarmPlot:CreateExpandableFarmPlot(player, level)
	-- For now, just create a garden region (can be expanded later)
	return self:CreateSimpleFarmPlot(player)
end

function FarmPlot:GetSimpleFarmPosition(player)
	-- Return the region position within the garden
	return self:GetPlayerRegionPosition(player)
end

print("FarmPlot: ✅ Garden-based farm plot module loaded successfully")

return FarmPlot