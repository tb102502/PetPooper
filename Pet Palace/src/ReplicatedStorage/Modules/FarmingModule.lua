-- FarmingModule.lua
-- Place in ReplicatedStorage/Modules/
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local FarmingModule = {}

-- Try to load FarmingSeeds, create it if it doesn't exist
local FarmingSeeds
local success = pcall(function()
	FarmingSeeds = require(ReplicatedStorage:WaitForChild("FarmingSeeds", 5))
end)

if not success then
	-- Create the FarmingSeeds module
	print("Creating FarmingSeeds module...")
	local farmingSeedsModule = Instance.new("ModuleScript")
	farmingSeedsModule.Name = "FarmingSeeds"

	farmingSeedsModule.Source = [[
    -- FarmingSeeds.lua
    return {
        Seeds = {
            {
                ID = "carrot_seeds",
                Name = "Carrot Seeds",
                Price = 20,
                Currency = "Coins",
                Type = "Seed",
                ImageId = "rbxassetid://6686038519",
                Description = "Plant these to grow carrots! Grows in 60 seconds.",
                GrowTime = 60,
                YieldAmount = 1,
                ResultID = "carrot",
                FeedValue = 1
            },
            {
                ID = "corn_seeds",
                Name = "Corn Seeds",
                Price = 50,
                Currency = "Coins",
                Type = "Seed",
                ImageId = "rbxassetid://6686045507",
                Description = "Plant these to grow corn! Grows in 120 seconds.",
                GrowTime = 120,
                YieldAmount = 3,
                ResultID = "corn",
                FeedValue = 2
            }
        ],
        Crops = {
            {
                ID = "carrot",
                Name = "Carrot",
                ImageId = "rbxassetid://6686041557",
                Description = "A freshly grown carrot! Feed it to your pet.",
                FeedValue = 1,
                SellValue = 30
            },
            {
                ID = "corn",
                Name = "Corn",
                ImageId = "rbxassetid://6686047557",
                Description = "Fresh corn! Feed it to your pet.",
                FeedValue = 2,
                SellValue = 75
            }
        }
    }
    ]]

	farmingSeedsModule.Parent = ReplicatedStorage
	FarmingSeeds = require(farmingSeedsModule)
	print("Created and loaded FarmingSeeds module")
end

-- Constants
FarmingModule.MAX_FARM_PLOTS = 10 -- Maximum farm plots per player (can be upgraded)
FarmingModule.PLOT_SIZE = Vector3.new(4, 0.5, 4) -- Size of each farm plot
FarmingModule.PLOT_SPACING = 1 -- Spacing between plots
FarmingModule.BASE_GROWTH_RATE = 1 -- Base rate at which plants grow

-- Set up farming area for the player
function FarmingModule.SetupFarmingArea(player)
	if not player then return end

	-- Create a farming area in the workspace for this player if it doesn't exist
	local farmingAreas = workspace:FindFirstChild("FarmingAreas") or Instance.new("Folder")
	farmingAreas.Name = "FarmingAreas"
	farmingAreas.Parent = workspace

	-- Check if player already has a farming area
	local playerFarmArea = farmingAreas:FindFirstChild(player.Name)
	if playerFarmArea then return playerFarmArea end

	-- Create new farming area for player
	playerFarmArea = Instance.new("Folder")
	playerFarmArea.Name = player.Name
	playerFarmArea.Parent = farmingAreas

	-- Get the player's data to see how many plots they can have
	local playerData = FarmingModule.GetPlayerFarmingData(player)
	local availablePlots = playerData.unlockedPlots or 3 -- Default to 3 plots

	-- Create the plots
	for i = 1, availablePlots do
		local plot = FarmingModule.CreateFarmPlot(i)
		plot.Parent = playerFarmArea
	end

	return playerFarmArea
end

-- Rest of the farming module implementation...
-- Create a single farm plot
function FarmingModule.CreateFarmPlot(plotNumber)
	local plotModel = Instance.new("Model")
	plotModel.Name = "FarmPlot_" .. plotNumber

	-- Create the soil base
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
	soil.Color = Color3.fromRGB(110, 70, 45) -- Brown soil color
	soil.Parent = plotModel

	-- Set as primary part
	plotModel.PrimaryPart = soil

	-- Add plot status attributes
	plotModel:SetAttribute("PlotID", plotNumber)
	plotModel:SetAttribute("IsPlanted", false)
	plotModel:SetAttribute("PlantType", "")
	plotModel:SetAttribute("GrowthStage", 0)
	plotModel:SetAttribute("PlantTime", 0)
	plotModel:SetAttribute("TimeToGrow", 0)

	return plotModel
end

-- Plant a seed in a specific plot
function FarmingModule.PlantSeed(player, plotModel, seedID)
	if not player or not plotModel or not seedID then return false end

	-- Check if the plot is already planted
	if plotModel:GetAttribute("IsPlanted") then
		return false, "Plot already has a plant"
	end

	-- Find the seed data
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

	-- Check if player has the seed in inventory
	local playerData = FarmingModule.GetPlayerFarmingData(player)
	if not playerData.inventory[seedID] or playerData.inventory[seedID] <= 0 then
		return false, "You don't have any " .. seedData.Name
	end

	-- Remove the seed from inventory
	playerData.inventory[seedID] = playerData.inventory[seedID] - 1
	FarmingModule.SavePlayerFarmingData(player, playerData)

	-- Update plot attributes
	plotModel:SetAttribute("IsPlanted", true)
	plotModel:SetAttribute("PlantType", seedID)
	plotModel:SetAttribute("GrowthStage", 0)
	plotModel:SetAttribute("PlantTime", os.time())
	plotModel:SetAttribute("TimeToGrow", seedData.GrowTime)

	-- Create the plant model
	local plantModel = FarmingModule.CreatePlantModel(seedID, 0)
	plantModel.Parent = plotModel

	return true, "Planted " .. seedData.Name .. " successfully!"
end

-- Create a visual plant model for a specific seed at a growth stage
function FarmingModule.CreatePlantModel(seedID, growthStage)
	local plantModel = Instance.new("Model")
	plantModel.Name = "Plant"

	-- Get seed info
	local seedData = nil
	for _, seed in ipairs(FarmingSeeds.Seeds) do
		if seed.ID == seedID then
			seedData = seed
			break
		end
	end

	if not seedData then return plantModel end

	-- Create the stem
	local stem = Instance.new("Part")
	stem.Name = "Stem"
	stem.Size = Vector3.new(0.2, 0.5 + (growthStage * 0.5), 0.2)
	stem.Position = Vector3.new(0, stem.Size.Y/2, 0)
	stem.Anchored = true
	stem.CanCollide = false
	stem.Material = Enum.Material.Plant
	stem.Color = Color3.fromRGB(58, 125, 21) -- Green stem color
	stem.Parent = plantModel

	-- Create leaves based on growth stage
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
			leaf.Color = Color3.fromRGB(86, 171, 47) -- Green leaf color
			leaf.Parent = plantModel
		end
	end

	-- Create fruit/crop when fully grown
	if growthStage >= 3 then
		local cropName = seedID:gsub("_seeds", "")
		local fruit = Instance.new("Part")
		fruit.Name = "Fruit"
		fruit.Shape = Enum.PartType.Ball
		fruit.Size = Vector3.new(0.7, 0.7, 0.7)
		fruit.Position = Vector3.new(0, stem.Size.Y - 0.1, 0)
		fruit.Anchored = true
		fruit.CanCollide = false

		-- Set color based on crop type
		if cropName == "carrot" then
			fruit.Color = Color3.fromRGB(255, 128, 0) -- Orange
			fruit.Shape = Enum.PartType.Cylinder
			fruit.Size = Vector3.new(0.3, 0.8, 0.3)
			fruit.Orientation = Vector3.new(0, 0, 90)
		elseif cropName == "corn" then
			fruit.Color = Color3.fromRGB(255, 240, 0) -- Yellow
			fruit.Shape = Enum.PartType.Cylinder
			fruit.Size = Vector3.new(0.4, 1, 0.4)
		elseif cropName == "strawberry" then
			fruit.Color = Color3.fromRGB(255, 0, 0) -- Red
			fruit.Shape = Enum.PartType.Ball
			fruit.Size = Vector3.new(0.5, 0.5, 0.5)
		elseif cropName == "golden_fruit" then
			fruit.Color = Color3.fromRGB(255, 215, 0) -- Gold
			fruit.Material = Enum.Material.Glass
			fruit.Reflectance = 0.5
			fruit.Shape = Enum.PartType.Ball
			fruit.Size = Vector3.new(0.8, 0.8, 0.8)

			-- Add special effect for golden fruit
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 215, 0)
			light.Range = 5
			light.Brightness = 1
			light.Parent = fruit
		end

		fruit.Parent = plantModel
	end

	-- Set primary part
	plantModel.PrimaryPart = stem

	return plantModel
end

-- Update plant growth
function FarmingModule.UpdatePlantGrowth(plot, currentTime)
	if not plot:GetAttribute("IsPlanted") then return end

	local plantTime = plot:GetAttribute("PlantTime") or 0
	local timeToGrow = plot:GetAttribute("TimeToGrow") or 60
	local currentStage = plot:GetAttribute("GrowthStage") or 0

	-- Calculate elapsed time and expected growth stage
	local elapsedTime = currentTime - plantTime
	local growthProgress = elapsedTime / timeToGrow
	local expectedStage = math.min(math.floor(growthProgress * 4), 4) -- 4 stages total

	-- If growth stage has increased, update the plant model
	if expectedStage > currentStage then
		plot:SetAttribute("GrowthStage", expectedStage)

		-- Update visual model
		local oldPlant = plot:FindFirstChild("Plant")
		if oldPlant then oldPlant:Destroy() end

		local newPlant = FarmingModule.CreatePlantModel(plot:GetAttribute("PlantType"), expectedStage)
		newPlant.Parent = plot

		-- Position the plant on the soil
		local soil = plot:FindFirstChild("Soil")
		if soil and newPlant.PrimaryPart then
			newPlant:SetPrimaryPartCFrame(CFrame.new(soil.Position + Vector3.new(0, soil.Size.Y/2 + 0.1, 0)))
		end
	end
end

-- Harvest a grown plant
function FarmingModule.HarvestPlant(player, plot)
	if not player or not plot then return false end

	-- Check if plot has a fully grown plant
	if not plot:GetAttribute("IsPlanted") then
		return false, "Nothing planted here"
	end

	local growthStage = plot:GetAttribute("GrowthStage") or 0
	if growthStage < 4 then
		return false, "Plant is not ready to harvest yet"
	end

	-- Get the seed type and corresponding crop
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

	-- Add crops to player's inventory
	local playerData = FarmingModule.GetPlayerFarmingData(player)
	playerData.inventory[cropID] = (playerData.inventory[cropID] or 0) + yieldAmount
	FarmingModule.SavePlayerFarmingData(player, playerData)

	-- Reset the plot
	plot:SetAttribute("IsPlanted", false)
	plot:SetAttribute("PlantType", "")
	plot:SetAttribute("GrowthStage", 0)
	plot:SetAttribute("PlantTime", 0)
	plot:SetAttribute("TimeToGrow", 0)

	-- Remove the plant model
	local plant = plot:FindFirstChild("Plant")
	if plant then plant:Destroy() end

	-- Get crop name for message
	local cropName = "crops"
	for _, crop in ipairs(FarmingSeeds.Crops) do
		if crop.ID == cropID then
			cropName = crop.Name
			break
		end
	end

	return true, "Harvested " .. yieldAmount .. " " .. cropName .. "!"
end

-- Feed a crop to a pet
function FarmingModule.FeedPet(player, petId, cropID)
	if not player or not petId or not cropID then return false end

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

	-- Get pet data (assuming you have a pet data module)
	local petData = FarmingModule.GetPetData(player, petId)
	if not petData then
		return false, "Pet not found"
	end

	-- Update pet feeding counter
	petData.feedCount = (petData.feedCount or 0) + 1

	-- Check if pet should grow larger
	if petData.feedCount % 10 == 0 then
		-- Increase pet size
		petData.sizeMultiplier = (petData.sizeMultiplier or 1) + 0.1

		-- Update pet scale if it exists in workspace
		local success = FarmingModule.UpdatePetSize(petId, petData.sizeMultiplier)

		if success then
			-- Remove crop from inventory
			playerData.inventory[cropID] = playerData.inventory[cropID] - 1

			-- Save data
			FarmingModule.SavePlayerFarmingData(player, playerData)
			FarmingModule.SavePetData(player, petId, petData)

			return true, "Your pet grew larger! Fed count: " .. petData.feedCount
		end
	else
		-- Remove crop from inventory
		playerData.inventory[cropID] = playerData.inventory[cropID] - 1

		-- Save data
		FarmingModule.SavePlayerFarmingData(player, playerData)
		FarmingModule.SavePetData(player, petId, petData)

		return true, "Fed your pet! " .. (10 - (petData.feedCount % 10)) .. " more feeds until growth"
	end

	return false, "Could not feed pet"
end

-- Update pet size visually
function FarmingModule.UpdatePetSize(petId, sizeMultiplier)
	-- Find the pet in workspace
	local pet = nil

	-- Check in all areas for the pet
	for _, areaModel in pairs(workspace:FindFirstChild("Areas"):GetChildren()) do
		local petsFolder = areaModel:FindFirstChild("Pets")
		if petsFolder then
			for _, potentialPet in pairs(petsFolder:GetChildren()) do
				if potentialPet:GetAttribute("PetID") == petId then
					pet = potentialPet
					break
				end
			end
		end
		if pet then break end
	end

	-- Also check player inventory if pet is not in world
	if not pet then
		for _, player in pairs(game.Players:GetPlayers()) do
			local backpack = player:FindFirstChild("Backpack")
			if backpack then
				local petsFolder = backpack:FindFirstChild("Pets")
				if petsFolder then
					for _, potentialPet in pairs(petsFolder:GetChildren()) do
						if potentialPet:GetAttribute("PetID") == petId then
							pet = potentialPet
							break
						end
					end
				end
			end
			if pet then break end
		end
	end

	if not pet then return false end

	-- Scale all parts of the pet
	for _, part in pairs(pet:GetDescendants()) do
		if part:IsA("BasePart") then
			-- Scale size while preserving proportions
			part.Size = part.Size * (sizeMultiplier / (pet:GetAttribute("CurrentSize") or 1))
		end
	end

	-- Update current size attribute
	pet:SetAttribute("CurrentSize", sizeMultiplier)

	return true
end

-- Get player farming data
function FarmingModule.GetPlayerFarmingData(player)
	-- This would normally come from your data store
	-- For this example, creating a basic structure
	local playerData = {
		unlockedPlots = 3, -- Start with 3 plots
		inventory = {},
		farmingLevel = 1,
		farmingExp = 0
	}

	-- For the demo, pre-populate with some seeds
	playerData.inventory["carrot_seeds"] = 5
	playerData.inventory["corn_seeds"] = 3

	return playerData
end

-- Save player farming data
function FarmingModule.SavePlayerFarmingData(player, data)
	-- This would save to your data store
	-- For this example, just printing
	print("Saved farming data for player:", player.Name)

	-- You'd connect this to your existing data system
end

-- Get pet data
function FarmingModule.GetPetData(player, petId)
	-- This would normally come from your pet data system
	-- For this example, creating a basic structure
	local petData = {
		id = petId,
		feedCount = 0,
		sizeMultiplier = 1
	}

	return petData
end

-- Save pet data
function FarmingModule.SavePetData(player, petId, petData)
	-- This would save to your data store
	-- For this example, just printing
	print("Saved pet data for pet:", petId)

	-- You'd connect this to your existing pet data system
end

return FarmingModule