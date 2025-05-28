-- FarmingModule.lua
-- Place in ReplicatedStorage/Modules
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FarmingModule = {}

-- Load FarmingSeeds data
local FarmingSeeds = require(ReplicatedStorage:WaitForChild("FarmingSeeds"))

-- Constants
FarmingModule.MAX_FARM_PLOTS = 10
FarmingModule.PLOT_SIZE = Vector3.new(4, 0.5, 4)
FarmingModule.PLOT_SPACING = 1
FarmingModule.BASE_GROWTH_RATE = 1

-- Set up farming area for the player
function FarmingModule.SetupFarmingArea(player)
	if not player then return end

	local farmingAreas = workspace:FindFirstChild("FarmingAreas") or Instance.new("Folder")
	farmingAreas.Name = "FarmingAreas"
	farmingAreas.Parent = workspace

	local playerFarmArea = farmingAreas:FindFirstChild(player.Name)
	if playerFarmArea then return playerFarmArea end

	playerFarmArea = Instance.new("Folder")
	playerFarmArea.Name = player.Name
	playerFarmArea.Parent = farmingAreas

	-- Get player data to determine plot count
	local playerData = FarmingModule.GetPlayerFarmingData(player)
	local availablePlots = (playerData.upgrades and playerData.upgrades.farmPlots or 0) + 3

	-- Create plots
	for i = 1, availablePlots do
		local plot = FarmingModule.CreateFarmPlot(i)
		plot.Parent = playerFarmArea
	end

	return playerFarmArea
end

-- Create a single farm plot
function FarmingModule.CreateFarmPlot(plotNumber)
	local plotModel = Instance.new("Model")
	plotModel.Name = "FarmPlot_" .. plotNumber

	-- Create soil base
	local soil = Instance.new("Part")
	soil.Name = "Soil"
	soil.Size = FarmingModule.PLOT_SIZE
	soil.Position = Vector3.new(
		(plotNumber - 1) * (FarmingModule.PLOT_SIZE.X + FarmingModule.PLOT_SPACING), 
		0, 
		0
	)
	soil.Anchored = true
	soil.CanCollide = true
	soil.Material = Enum.Material.Sand
	soil.Color = Color3.fromRGB(110, 70, 45)
	soil.Parent = plotModel

	plotModel.PrimaryPart = soil

	-- Plot attributes
	plotModel:SetAttribute("PlotID", plotNumber)
	plotModel:SetAttribute("IsPlanted", false)
	plotModel:SetAttribute("PlantType", "")
	plotModel:SetAttribute("GrowthStage", 0)
	plotModel:SetAttribute("PlantTime", 0)
	plotModel:SetAttribute("TimeToGrow", 0)

	return plotModel
end

-- Plant a seed
function FarmingModule.PlantSeed(player, plotModel, seedID)
	if not player or not plotModel or not seedID then return false, "Invalid parameters" end

	if plotModel:GetAttribute("IsPlanted") then
		return false, "Plot already has a plant"
	end

	-- Find seed data
	local seedData = nil
	for _, seed in ipairs(FarmingSeeds.Seeds) do
		if seed.ID == seedID then
			seedData = seed
			break
		end
	end

	if not seedData then
		return false, "Invalid seed type"
	end

	-- Check player inventory
	local playerData = FarmingModule.GetPlayerFarmingData(player)
	if not playerData.inventory[seedID] or playerData.inventory[seedID] <= 0 then
		return false, "You don't have any " .. seedData.Name
	end

	-- Remove seed from inventory
	playerData.inventory[seedID] = playerData.inventory[seedID] - 1
	FarmingModule.SavePlayerFarmingData(player, playerData)

	-- Update plot
	plotModel:SetAttribute("IsPlanted", true)
	plotModel:SetAttribute("PlantType", seedID)
	plotModel:SetAttribute("GrowthStage", 0)
	plotModel:SetAttribute("PlantTime", os.time())
	plotModel:SetAttribute("TimeToGrow", seedData.GrowTime)

	-- Create plant model
	local plantModel = FarmingModule.CreatePlantModel(seedID, 0)
	plantModel.Parent = plotModel

	return true, "Planted " .. seedData.Name .. " successfully!"
end

-- Create visual plant model
function FarmingModule.CreatePlantModel(seedID, growthStage)
	local plantModel = Instance.new("Model")
	plantModel.Name = "Plant"

	local seedData = nil
	for _, seed in ipairs(FarmingSeeds.Seeds) do
		if seed.ID == seedID then
			seedData = seed
			break
		end
	end

	if not seedData then return plantModel end

	-- Create stem
	local stem = Instance.new("Part")
	stem.Name = "Stem"
	stem.Size = Vector3.new(0.2, 0.5 + (growthStage * 0.5), 0.2)
	stem.Position = Vector3.new(0, stem.Size.Y/2, 0)
	stem.Anchored = true
	stem.CanCollide = false
	stem.Material = Enum.Material.Grass
	stem.Color = Color3.fromRGB(58, 125, 21)
	stem.Parent = plantModel

	-- Add leaves based on growth stage
	if growthStage >= 1 then
		for i = 1, math.min(growthStage, 3) do
			local leaf = Instance.new("Part")
			leaf.Name = "Leaf_" .. i
			leaf.Size = Vector3.new(0.5, 0.05, 0.3)
			leaf.Position = Vector3.new(0, 0.2 + (i * 0.2), 0)
			leaf.Orientation = Vector3.new(0, i * 45, 0)
			leaf.Anchored = true
			leaf.CanCollide = false
			leaf.Material = Enum.Material.Grass
			leaf.Color = Color3.fromRGB(86, 171, 47)
			leaf.Parent = plantModel
		end
	end

	-- Create fruit when fully grown
	if growthStage >= 4 then
		local cropName = seedID:gsub("_seeds", "")
		local fruit = Instance.new("Part")
		fruit.Name = "Fruit"
		fruit.Position = Vector3.new(0, stem.Size.Y - 0.1, 0)
		fruit.Anchored = true
		fruit.CanCollide = false

		-- Set fruit appearance based on type
		if cropName == "carrot" then
			fruit.Color = Color3.fromRGB(255, 128, 0)
			fruit.Shape = Enum.PartType.Cylinder
			fruit.Size = Vector3.new(0.3, 0.8, 0.3)
			fruit.Orientation = Vector3.new(0, 0, 90)
		elseif cropName == "corn" then
			fruit.Color = Color3.fromRGB(255, 240, 0)
			fruit.Shape = Enum.PartType.Cylinder
			fruit.Size = Vector3.new(0.4, 1, 0.4)
		elseif cropName == "strawberry" then
			fruit.Color = Color3.fromRGB(255, 0, 0)
			fruit.Shape = Enum.PartType.Ball
			fruit.Size = Vector3.new(0.5, 0.5, 0.5)
		elseif cropName == "golden_fruit" then
			fruit.Color = Color3.fromRGB(255, 215, 0)
			fruit.Material = Enum.Material.Neon
			fruit.Shape = Enum.PartType.Ball
			fruit.Size = Vector3.new(0.8, 0.8, 0.8)

			-- Add glow effect
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 215, 0)
			light.Range = 5
			light.Brightness = 1
			light.Parent = fruit
		end

		fruit.Parent = plantModel
	end

	plantModel.PrimaryPart = stem
	return plantModel
end

-- Update plant growth
function FarmingModule.UpdatePlantGrowth(plot, currentTime)
	if not plot:GetAttribute("IsPlanted") then return end

	local plantTime = plot:GetAttribute("PlantTime") or 0
	local timeToGrow = plot:GetAttribute("TimeToGrow") or 60
	local currentStage = plot:GetAttribute("GrowthStage") or 0

	local elapsedTime = currentTime - plantTime
	local growthProgress = elapsedTime / timeToGrow
	local expectedStage = math.min(math.floor(growthProgress * 4), 4)

	if expectedStage > currentStage then
		plot:SetAttribute("GrowthStage", expectedStage)

		-- Update visual
		local oldPlant = plot:FindFirstChild("Plant")
		if oldPlant then oldPlant:Destroy() end

		local newPlant = FarmingModule.CreatePlantModel(plot:GetAttribute("PlantType"), expectedStage)
		newPlant.Parent = plot

		-- Position plant on soil
		local soil = plot:FindFirstChild("Soil")
		if soil and newPlant.PrimaryPart then
			newPlant:SetPrimaryPartCFrame(CFrame.new(soil.Position + Vector3.new(0, soil.Size.Y/2 + 0.1, 0)))
		end
	end
end

-- Harvest plant
function FarmingModule.HarvestPlant(player, plot)
	if not player or not plot then return false, "Invalid parameters" end

	if not plot:GetAttribute("IsPlanted") then
		return false, "Nothing planted here"
	end

	local growthStage = plot:GetAttribute("GrowthStage") or 0
	if growthStage < 4 then
		return false, "Plant is not ready to harvest yet"
	end

	local seedID = plot:GetAttribute("PlantType")
	local cropID = nil
	local yieldAmount = 1

	-- Find seed data
	for _, seed in ipairs(FarmingSeeds.Seeds) do
		if seed.ID == seedID then
			cropID = seed.ResultID
			yieldAmount = seed.YieldAmount or 1
			break
		end
	end

	if not cropID then
		return false, "Error determining crop type"
	end

	-- Add crops to inventory
	local playerData = FarmingModule.GetPlayerFarmingData(player)
	playerData.inventory[cropID] = (playerData.inventory[cropID] or 0) + yieldAmount
	FarmingModule.SavePlayerFarmingData(player, playerData)

	-- Reset plot
	plot:SetAttribute("IsPlanted", false)
	plot:SetAttribute("PlantType", "")
	plot:SetAttribute("GrowthStage", 0)
	plot:SetAttribute("PlantTime", 0)
	plot:SetAttribute("TimeToGrow", 0)

	local plant = plot:FindFirstChild("Plant")
	if plant then plant:Destroy() end

	-- Get crop name
	local cropName = "crops"
	for _, crop in ipairs(FarmingSeeds.Crops) do
		if crop.ID == cropID then
			cropName = crop.Name
			break
		end
	end

	return true, "Harvested " .. yieldAmount .. " " .. cropName .. "!"
end

-- Feed crop to pig
function FarmingModule.FeedPig(player, cropID)
	if not player or not cropID then return false, "Invalid parameters" end

	-- Check if player has the crop
	local playerData = FarmingModule.GetPlayerFarmingData(player)
	if not playerData.inventory[cropID] or playerData.inventory[cropID] <= 0 then
		return false, "You don't have this crop"
	end

	-- Find crop data
	local cropData = nil
	for _, crop in ipairs(FarmingSeeds.Crops) do
		if crop.ID == cropID then
			cropData = crop
			break
		end
	end

	if not cropData then
		return false, "Invalid crop type"
	end

	-- Initialize pig data if needed
	if not playerData.pig then
		playerData.pig = {
			feedCount = 0,
			size = 1
		}
	end

	-- Update pig feeding counter
	playerData.pig.feedCount = playerData.pig.feedCount + 1

	-- Check if pig should grow
	local shouldGrow = playerData.pig.feedCount % 10 == 0
	local message = ""

	if shouldGrow then
		playerData.pig.size = playerData.pig.size + 0.2
		message = "Your pig grew larger! Fed count: " .. playerData.pig.feedCount .. " (Size: " .. string.format("%.1f", playerData.pig.size) .. "x)"

		-- Update pig size in world
		FarmingModule.UpdatePigSize(player, playerData.pig.size)
	else
		local remaining = 10 - (playerData.pig.feedCount % 10)
		message = "Fed your pig! " .. remaining .. " more feeds until growth"
	end

	-- Remove crop from inventory
	playerData.inventory[cropID] = playerData.inventory[cropID] - 1

	-- Save data
	FarmingModule.SavePlayerFarmingData(player, playerData)

	return true, message
end

-- Update pig size visually
function FarmingModule.UpdatePigSize(player, sizeMultiplier)
	-- Find the pig in workspace
	local pig = workspace:FindFirstChild("Pigs") and workspace.Pigs:FindFirstChild(player.Name .. "_Pig")

	if not pig then
		-- Create pig if it doesn't exist
		pig = FarmingModule.CreatePig(player)
	end

	if pig then
		-- Scale all parts
		for _, part in pairs(pig:GetDescendants()) do
			if part:IsA("BasePart") then
				local originalSize = part:GetAttribute("OriginalSize")
				if not originalSize then
					part:SetAttribute("OriginalSize", part.Size)
					originalSize = part.Size
				else
					originalSize = Vector3.new(originalSize.X, originalSize.Y, originalSize.Z)
				end

				part.Size = originalSize * sizeMultiplier
			end
		end

		pig:SetAttribute("CurrentSize", sizeMultiplier)
		return true
	end

	return false
end

-- Create a pig for the player
function FarmingModule.CreatePig(player)
	local pigsFolder = workspace:FindFirstChild("Pigs") or Instance.new("Folder")
	pigsFolder.Name = "Pigs"
	pigsFolder.Parent = workspace

	local pig = Instance.new("Model")
	pig.Name = player.Name .. "_Pig"
	pig.Parent = pigsFolder

	-- Create pig body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3, 2, 4)
	body.Position = Vector3.new(20, 2, 0) -- Position away from farm
	body.Shape = Enum.PartType.Ball
	body.Material = Enum.Material.Plastic
	body.Color = Color3.fromRGB(255, 182, 193) -- Pink
	body.Anchored = true
	body.CanCollide = true
	body.Parent = pig

	-- Create head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 1.5, 2)
	head.Position = body.Position + Vector3.new(0, 0, 2.5)
	head.Shape = Enum.PartType.Ball
	head.Material = Enum.Material.Plastic
	head.Color = Color3.fromRGB(255, 182, 193)
	head.Anchored = true
	head.CanCollide = false
	head.Parent = pig

	-- Create snout
	local snout = Instance.new("Part")
	snout.Name = "Snout"
	snout.Size = Vector3.new(0.8, 0.4, 0.6)
	snout.Position = head.Position + Vector3.new(0, -0.2, 0.8)
	snout.Shape = Enum.PartType.Cylinder
	snout.Material = Enum.Material.Plastic
	snout.Color = Color3.fromRGB(255, 160, 160)
	snout.Anchored = true
	snout.CanCollide = false
	snout.Orientation = Vector3.new(90, 0, 0)
	snout.Parent = pig

	-- Create tail
	local tail = Instance.new("Part")
	tail.Name = "Tail"
	tail.Size = Vector3.new(0.3, 0.3, 1)
	tail.Position = body.Position + Vector3.new(0, 0.5, -2.5)
	tail.Shape = Enum.PartType.Cylinder
	tail.Material = Enum.Material.Plastic
	tail.Color = Color3.fromRGB(255, 182, 193)
	tail.Anchored = true
	tail.CanCollide = false
	tail.Orientation = Vector3.new(0, 0, 45)
	tail.Parent = pig

	-- Set attributes for original sizes
	for _, part in pairs(pig:GetChildren()) do
		if part:IsA("BasePart") then
			part:SetAttribute("OriginalSize", part.Size)
		end
	end

	pig.PrimaryPart = body
	pig:SetAttribute("CurrentSize", 1)
	pig:SetAttribute("Owner", player.Name)

	return pig
end

-- Get player farming data (connects to existing PlayerDataService)
function FarmingModule.GetPlayerFarmingData(player)
	local ServerStorage = game:GetService("ServerStorage")
	local success, PlayerDataService = pcall(function()
		return require(ServerStorage:WaitForChild("Modules"):WaitForChild("PlayerDataService"))
	end)

	if success and PlayerDataService then
		local playerData = PlayerDataService.GetPlayerData(player)
		if playerData then
			-- Ensure farming data exists
			if not playerData.farming then
				playerData.farming = {
					unlockedPlots = 3,
					inventory = {
						carrot_seeds = 5,
						corn_seeds = 3,
						strawberry_seeds = 1,
						golden_seeds = 0
					},
					pig = {
						feedCount = 0,
						size = 1
					},
					farmingLevel = 1,
					farmingExp = 0
				}
			end

			-- Merge upgrades into farming data for compatibility
			local farmingData = playerData.farming
			farmingData.upgrades = playerData.upgrades or {}
			farmingData.coins = playerData.coins or 0
			farmingData.gems = playerData.gems or 0

			return farmingData
		end
	end

	-- Fallback data
	return {
		unlockedPlots = 3,
		inventory = {
			carrot_seeds = 5,
			corn_seeds = 3,
			strawberry_seeds = 1,
			golden_seeds = 0
		},
		upgrades = {
			farmPlots = 0
		},
		pig = {
			feedCount = 0,
			size = 1
		},
		farmingLevel = 1,
		farmingExp = 0
	}
end

-- Save player farming data (connects to existing PlayerDataService)
function FarmingModule.SavePlayerFarmingData(player, data)
	local ServerStorage = game:GetService("ServerStorage")
	local success, PlayerDataService = pcall(function()
		return require(ServerStorage:WaitForChild("Modules"):WaitForChild("PlayerDataService"))
	end)

	if success and PlayerDataService then
		local playerData = PlayerDataService.GetPlayerData(player)
		if playerData then
			-- Update farming section
			playerData.farming = {
				unlockedPlots = data.unlockedPlots,
				inventory = data.inventory,
				pig = data.pig,
				farmingLevel = data.farmingLevel,
				farmingExp = data.farmingExp
			}

			-- Update main player data
			if data.coins then playerData.coins = data.coins end
			if data.gems then playerData.gems = data.gems end
			if data.upgrades then playerData.upgrades = data.upgrades end

			PlayerDataService.SavePlayerData(player)
			return
		end
	end

	print("Saved farming data for player:", player.Name, "(fallback mode)")
end

return FarmingModule