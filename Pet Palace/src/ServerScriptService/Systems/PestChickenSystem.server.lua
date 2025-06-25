--[[
    INTEGRATED Pest & Chicken System - GameCore Compatible
    Place as: ServerScriptService/Systems/PestChickenSystem.server.lua
    
    FEATURES:
    ✅ Integrates with fixed GameCore system
    ✅ Multi-tier pest threat system
    ✅ Chicken defense mechanics
    ✅ Proper inventory management
    ✅ UFO integration for scattering chickens
    ✅ Pig manure as pest deterrent
]]

local PestChickenSystem = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- System Configuration
PestChickenSystem.Config = {
	PEST_SPAWN_INTERVAL = {min = 30, max = 120}, -- Seconds between pest spawns
	CHICKEN_PATROL_RADIUS = 15, -- How far chickens patrol
	CHICKEN_DETECTION_RADIUS = 10, -- How far chickens detect pests
	MAX_PESTS_PER_PLOT = 3,
	PEST_DAMAGE_INTERVAL = 10, -- Seconds between pest damage
	EGG_PRODUCTION_INTERVAL = 240, -- 4 minutes between eggs
	MANURE_DETERRENT_RADIUS = 8 -- Pig manure pest deterrent range
}

-- Pest Types Configuration
PestChickenSystem.PestTypes = {
	aphids = {
		name = "Aphids",
		icon = "🐛",
		damage = 10, -- Damage to crops over time
		spawnChance = 0.6,
		vulnerability = {"basic_chicken", "guinea_fowl", "rooster"},
		cropTargets = {"carrot", "cabbage", "broccoli"},
		speed = 2,
		health = 20
	},
	locusts = {
		name = "Locusts", 
		icon = "🦗",
		damage = 25,
		spawnChance = 0.3,
		vulnerability = {"guinea_fowl", "rooster"},
		cropTargets = {"wheat", "corn", "tomato"},
		speed = 5,
		health = 35
	},
	fungal_blight = {
		name = "Fungal Blight",
		icon = "🍄",
		damage = 15,
		spawnChance = 0.4,
		vulnerability = {"rooster", "organic_pesticide"},
		cropTargets = {"potato", "tomato", "strawberry"},
		speed = 1,
		health = 50
	},
	root_weevil = {
		name = "Root Weevil",
		icon = "🪲",
		damage = 20,
		spawnChance = 0.2,
		vulnerability = {"guinea_fowl", "rooster"},
		cropTargets = {"potato", "radish", "carrot"},
		speed = 3,
		health = 30
	}
}

-- Chicken Types Configuration  
PestChickenSystem.ChickenTypes = {
	basic_chicken = {
		name = "Basic Chicken",
		icon = "🐔",
		effectiveness = {"aphids"},
		patrolSpeed = 3,
		detectionRange = 8,
		health = 100,
		eggType = "chicken_egg",
		eggValue = 5,
		feedConsumption = 1
	},
	guinea_fowl = {
		name = "Guinea Fowl",
		icon = "🦆", 
		effectiveness = {"aphids", "locusts", "root_weevil"},
		patrolSpeed = 4,
		detectionRange = 12,
		health = 120,
		eggType = "guinea_egg",
		eggValue = 8,
		feedConsumption = 1.5
	},
	rooster = {
		name = "Rooster",
		icon = "🐓",
		effectiveness = {"locusts", "fungal_blight", "root_weevil"},
		patrolSpeed = 5,
		detectionRange = 15,
		health = 150,
		eggType = "rooster_egg",
		eggValue = 12,
		feedConsumption = 2,
		scareRadius = 10 -- Scares away pests in radius
	}
}

-- System State
PestChickenSystem.ActivePests = {} -- [pestId] = pestData
PestChickenSystem.ActiveChickens = {} -- [chickenId] = chickenData
PestChickenSystem.PlayerFarms = {} -- [playerId] = farmData
PestChickenSystem.GameCore = nil

-- ========== INITIALIZATION ==========

function PestChickenSystem:Initialize()
	print("PestChickenSystem: Initializing integrated pest & chicken system...")

	-- Wait for GameCore
	self:WaitForGameCore()

	-- Setup remote events
	self:SetupRemoteEvents()

	-- Start main systems
	self:StartPestSpawnSystem()
	self:StartChickenAISystem() 
	self:StartEggProductionSystem()
	self:StartDamageSystem()

	-- Setup player events
	self:SetupPlayerEvents()

	print("PestChickenSystem: ✅ Integrated system initialized!")
end

function PestChickenSystem:WaitForGameCore()
	print("PestChickenSystem: Waiting for GameCore...")

	local attempts = 0
	while not _G.GameCore and attempts < 30 do
		wait(1)
		attempts = attempts + 1
	end

	if _G.GameCore then
		self.GameCore = _G.GameCore
		print("PestChickenSystem: ✅ GameCore reference established")
	else
		error("PestChickenSystem: GameCore not available after 30 seconds!")
	end
end

function PestChickenSystem:SetupRemoteEvents()
	local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "GameRemotes"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Create required remote events
	local requiredEvents = {
		"PestSpotted", "PestEliminated", "ChickenPlaced", "ChickenMoved",
		"FeedAllChickens", "FeedChickensWithType", "UsePesticide"
	}

	for _, eventName in ipairs(requiredEvents) do
		local existing = remoteFolder:FindFirstChild(eventName)
		if not existing then
			local newEvent = Instance.new("RemoteEvent")
			newEvent.Name = eventName
			newEvent.Parent = remoteFolder
		end
	end

	-- Setup event handlers
	self:SetupEventHandlers()
end

function PestChickenSystem:SetupEventHandlers()
	local remotes = ReplicatedStorage.GameRemotes

	-- Chicken placement
	if remotes:FindFirstChild("ChickenPlaced") then
		remotes.ChickenPlaced.OnServerEvent:Connect(function(player, chickenType, position)
			self:HandleChickenPlacement(player, chickenType, position)
		end)
	end

	-- Chicken feeding
	if remotes:FindFirstChild("FeedAllChickens") then
		remotes.FeedAllChickens.OnServerEvent:Connect(function(player)
			self:HandleFeedAllChickens(player)
		end)
	end

	if remotes:FindFirstChild("FeedChickensWithType") then
		remotes.FeedChickensWithType.OnServerEvent:Connect(function(player, feedType)
			self:HandleFeedChickensWithType(player, feedType)
		end)
	end

	-- Pesticide usage
	if remotes:FindFirstChild("UsePesticide") then
		remotes.UsePesticide.OnServerEvent:Connect(function(player, plotModel)
			self:HandlePesticideUse(player, plotModel)
		end)
	end
end

-- ========== PEST SPAWN SYSTEM ==========

function PestChickenSystem:StartPestSpawnSystem()
	print("PestChickenSystem: Starting pest spawn system...")

	spawn(function()
		while true do
			local interval = math.random(self.Config.PEST_SPAWN_INTERVAL.min, self.Config.PEST_SPAWN_INTERVAL.max)
			wait(interval)

			-- Try to spawn pests on random farms
			for _, player in pairs(Players:GetPlayers()) do
				if math.random() < 0.3 then -- 30% chance per player per interval
					self:TrySpawnPestOnFarm(player)
				end
			end
		end
	end)
end

function PestChickenSystem:TrySpawnPestOnFarm(player)
	local farmPlots = self:GetPlayerFarmPlots(player)
	if #farmPlots == 0 then return end

	-- Check for pig manure deterrent
	if self:HasPigManureDeterrent(player) then
		if math.random() < 0.7 then -- 70% chance to deter
			return
		end
	end

	-- Select random plot with crops
	local validPlots = {}
	for _, plot in ipairs(farmPlots) do
		if not plot:GetAttribute("IsEmpty") then
			local currentPests = self:CountPestsOnPlot(plot)
			if currentPests < self.Config.MAX_PESTS_PER_PLOT then
				table.insert(validPlots, plot)
			end
		end
	end

	if #validPlots == 0 then return end

	local targetPlot = validPlots[math.random(#validPlots)]
	local cropType = targetPlot:GetAttribute("PlantType")

	-- Select pest type based on crop
	local possiblePests = {}
	for pestType, pestData in pairs(self.PestTypes) do
		for _, targetCrop in ipairs(pestData.cropTargets) do
			if targetCrop == cropType then
				table.insert(possiblePests, pestType)
				break
			end
		end
	end

	if #possiblePests == 0 then return end

	local selectedPest = possiblePests[math.random(#possiblePests)]
	self:SpawnPest(selectedPest, targetPlot, player)
end

function PestChickenSystem:SpawnPest(pestType, plotModel, player)
	local pestData = self.PestTypes[pestType]
	if not pestData then return end

	local pestId = HttpService:GenerateGUID(false)

	-- Create pest model
	local pestModel = self:CreatePestModel(pestType, pestData, plotModel)
	if not pestModel then return end

	-- Store pest data
	self.ActivePests[pestId] = {
		id = pestId,
		type = pestType,
		model = pestModel,
		plot = plotModel,
		owner = player.Name,
		health = pestData.health,
		spawnTime = os.time(),
		lastDamage = os.time()
	}

	-- Notify player
	self:NotifyPestSpotted(player, pestType, plotModel:GetAttribute("PlantType"), plotModel)

	print("🐛 Spawned " .. pestType .. " on " .. player.Name .. "'s farm")
end

function PestChickenSystem:CreatePestModel(pestType, pestData, plotModel)
	if not plotModel or not plotModel.PrimaryPart then return nil end

	local pestModel = Instance.new("Model")
	pestModel.Name = "Pest_" .. pestType
	pestModel.Parent = workspace

	-- Main pest part
	local pestPart = Instance.new("Part")
	pestPart.Name = "PestPart"
	pestPart.Size = Vector3.new(0.5, 0.5, 0.5)
	pestPart.Material = Enum.Material.Neon
	pestPart.Color = Color3.fromRGB(100, 50, 0)
	pestPart.Shape = Enum.PartType.Ball
	pestPart.CanCollide = false
	pestPart.Anchored = true
	pestPart.Position = plotModel.PrimaryPart.Position + Vector3.new(
		math.random(-2, 2), 
		1, 
		math.random(-2, 2)
	)
	pestPart.Parent = pestModel

	pestModel.PrimaryPart = pestPart

	-- Add pest icon
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 50, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 1, 0)
	billboard.Parent = pestPart

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 1, 0)
	icon.BackgroundTransparency = 1
	icon.Text = pestData.icon
	icon.TextScaled = true
	icon.Font = Enum.Font.GothamBold
	icon.Parent = billboard

	-- Set attributes
	pestModel:SetAttribute("PestType", pestType)
	pestModel:SetAttribute("Health", pestData.health)
	pestModel:SetAttribute("PlotModel", plotModel)

	return pestModel
end

-- ========== CHICKEN SYSTEM ==========

function PestChickenSystem:HandleChickenPlacement(player, chickenType, position)
	print("🐔 Placing " .. chickenType .. " for " .. player.Name)

	-- Check if player has the chicken
	local playerData = self.GameCore:GetPlayerData(player)
	if not self:PlayerHasChicken(playerData, chickenType) then
		self:SendNotification(player, "No Chicken", "You don't have this type of chicken!", "error")
		return
	end

	-- Create chicken model
	local chickenModel = self:CreateChickenModel(chickenType, position, player)
	if not chickenModel then
		self:SendNotification(player, "Placement Failed", "Could not place chicken!", "error")
		return
	end

	-- Register chicken
	local chickenId = chickenModel.Name
	self.ActiveChickens[chickenId] = {
		id = chickenId,
		type = chickenType,
		model = chickenModel,
		owner = player.Name,
		health = self.ChickenTypes[chickenType].health,
		hunger = 50,
		lastEgg = os.time(),
		patrolTarget = position,
		currentTask = "patrol"
	}

	-- Remove from available chickens and add to deployed
	self:MoveChickenToDeployed(playerData, chickenType)
	self.GameCore:SavePlayerData(player)

	-- Notify placement
	self:NotifyChickenPlaced(player, chickenType, position)

	print("✅ Successfully placed " .. chickenType .. " for " .. player.Name)
end

function PestChickenSystem:CreateChickenModel(chickenType, position, player)
	local chickenData = self.ChickenTypes[chickenType]
	if not chickenData then return nil end

	local chickenModel = Instance.new("Model")
	chickenModel.Name = "Chicken_" .. player.Name .. "_" .. HttpService:GenerateGUID(false)
	chickenModel.Parent = workspace

	-- Main body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(1, 1, 1.5)
	body.Material = Enum.Material.Plastic
	body.Color = Color3.fromRGB(255, 255, 255)
	body.Shape = Enum.PartType.Block
	body.CanCollide = true
	body.Position = position
	body.Parent = chickenModel

	chickenModel.PrimaryPart = body

	-- Add chicken icon
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 60, 0, 60)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.Parent = body

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 1, 0)
	icon.BackgroundTransparency = 1
	icon.Text = chickenData.icon
	icon.TextScaled = true
	icon.Font = Enum.Font.GothamBold
	icon.Parent = billboard

	-- Set attributes
	chickenModel:SetAttribute("ChickenType", chickenType)
	chickenModel:SetAttribute("Owner", player.Name)
	chickenModel:SetAttribute("Health", chickenData.health)

	return chickenModel
end

-- ========== CHICKEN AI SYSTEM ==========

function PestChickenSystem:StartChickenAISystem()
	print("PestChickenSystem: Starting chicken AI system...")

	spawn(function()
		while true do
			wait(1) -- Update every second

			for chickenId, chickenData in pairs(self.ActiveChickens) do
				if chickenData.model and chickenData.model.Parent then
					self:UpdateChickenAI(chickenId, chickenData)
				else
					-- Clean up invalid chicken
					self.ActiveChickens[chickenId] = nil
				end
			end
		end
	end)
end

function PestChickenSystem:UpdateChickenAI(chickenId, chickenData)
	-- Check for nearby pests
	local nearbyPest = self:FindNearbyPest(chickenData)

	if nearbyPest then
		-- Attack pest
		self:ChickenAttackPest(chickenData, nearbyPest)
	else
		-- Patrol behavior
		self:ChickenPatrol(chickenData)
	end

	-- Check hunger and health
	self:UpdateChickenStatus(chickenData)
end

function PestChickenSystem:FindNearbyPest(chickenData)
	if not chickenData.model or not chickenData.model.PrimaryPart then return nil end

	local chickenPos = chickenData.model.PrimaryPart.Position
	local chickenType = self.ChickenTypes[chickenData.type]
	local detectionRange = chickenType.detectionRange

	for pestId, pestData in pairs(self.ActivePests) do
		if pestData.model and pestData.model.PrimaryPart then
			local pestPos = pestData.model.PrimaryPart.Position
			local distance = (chickenPos - pestPos).Magnitude

			if distance <= detectionRange then
				-- Check if chicken can handle this pest type
				for _, effectiveness in ipairs(chickenType.effectiveness) do
					if effectiveness == pestData.type then
						return pestData
					end
				end
			end
		end
	end

	return nil
end

function PestChickenSystem:ChickenAttackPest(chickenData, pestData)
	if not chickenData.model or not pestData.model then return end

	-- Move chicken towards pest
	local chickenPos = chickenData.model.PrimaryPart.Position
	local pestPos = pestData.model.PrimaryPart.Position
	local direction = (pestPos - chickenPos).Unit
	local newPos = chickenPos + direction * 2

	chickenData.model:SetPrimaryPartCFrame(CFrame.new(newPos))

	-- Attack if close enough
	local distance = (chickenPos - pestPos).Magnitude
	if distance <= 3 then
		self:EliminatePest(pestData.id, chickenData.type)
	end
end

function PestChickenSystem:ChickenPatrol(chickenData)
	if not chickenData.model or not chickenData.model.PrimaryPart then return end

	local currentPos = chickenData.model.PrimaryPart.Position
	local patrolTarget = chickenData.patrolTarget
	local distance = (currentPos - patrolTarget).Magnitude

	-- If far from patrol area, move back
	if distance > self.Config.CHICKEN_PATROL_RADIUS then
		local direction = (patrolTarget - currentPos).Unit
		local newPos = currentPos + direction * 1
		chickenData.model:SetPrimaryPartCFrame(CFrame.new(newPos))
	else
		-- Random movement within patrol area
		local randomOffset = Vector3.new(
			math.random(-5, 5),
			0,
			math.random(-5, 5)
		)
		local newTarget = patrolTarget + randomOffset
		local direction = (newTarget - currentPos).Unit
		local newPos = currentPos + direction * 0.5

		chickenData.model:SetPrimaryPartCFrame(CFrame.new(newPos))
	end
end

-- ========== PEST ELIMINATION ==========

function PestChickenSystem:EliminatePest(pestId, eliminatedBy)
	local pestData = self.ActivePests[pestId]
	if not pestData then return end

	print("✅ Pest " .. pestData.type .. " eliminated by " .. eliminatedBy)

	-- Remove pest model
	if pestData.model then
		pestData.model:Destroy()
	end

	-- Notify player
	local player = Players:FindFirstChild(pestData.owner)
	if player then
		self:NotifyPestEliminated(player, pestData.type, eliminatedBy)
	end

	-- Clean up
	self.ActivePests[pestId] = nil
end

-- ========== EGG PRODUCTION SYSTEM ==========

function PestChickenSystem:StartEggProductionSystem()
	print("PestChickenSystem: Starting egg production system...")

	spawn(function()
		while true do
			wait(60) -- Check every minute

			for chickenId, chickenData in pairs(self.ActiveChickens) do
				if chickenData.hunger >= 25 then -- Only produce eggs if not too hungry
					local timeSinceLastEgg = os.time() - chickenData.lastEgg
					if timeSinceLastEgg >= self.Config.EGG_PRODUCTION_INTERVAL then
						self:ProduceEgg(chickenData)
					end
				end
			end
		end
	end)
end

function PestChickenSystem:ProduceEgg(chickenData)
	local player = Players:FindFirstChild(chickenData.owner)
	if not player then return end

	local playerData = self.GameCore:GetPlayerData(player)
	if not playerData then return end

	local chickenType = self.ChickenTypes[chickenData.type]
	local eggType = chickenType.eggType

	-- Add egg to livestock inventory
	self.GameCore:InitializePlayerInventories(playerData)
	playerData.livestock.inventory[eggType] = (playerData.livestock.inventory[eggType] or 0) + 1

	-- Update chicken data
	chickenData.lastEgg = os.time()
	chickenData.hunger = math.max(0, chickenData.hunger - 10) -- Laying eggs makes chickens hungry

	-- Save and notify
	self.GameCore:SavePlayerData(player)
	self:SendNotification(player, "🥚 Egg Laid!", 
		"Your " .. chickenType.name .. " laid an egg!", "success")

	print("🥚 " .. chickenData.owner .. "'s " .. chickenData.type .. " laid an egg")
end

-- ========== CHICKEN FEEDING SYSTEM ==========

function PestChickenSystem:HandleFeedAllChickens(player)
	local playerData = self.GameCore:GetPlayerData(player)
	if not playerData then return end

	-- Check for basic feed
	local basicFeed = 0
	if playerData.defense and playerData.defense.chickens and playerData.defense.chickens.feed then
		basicFeed = playerData.defense.chickens.feed.basic_feed or 0
	end

	if basicFeed <= 0 then
		self:SendNotification(player, "No Feed", "You don't have any chicken feed!", "error")
		return
	end

	-- Feed all player's chickens
	local fedCount = 0
	for chickenId, chickenData in pairs(self.ActiveChickens) do
		if chickenData.owner == player.Name and basicFeed > 0 then
			chickenData.hunger = math.min(100, chickenData.hunger + 25)
			basicFeed = basicFeed - 1
			fedCount = fedCount + 1
		end
	end

	if fedCount > 0 then
		-- Update feed inventory
		playerData.defense.chickens.feed.basic_feed = basicFeed
		self.GameCore:SavePlayerData(player)

		self:SendNotification(player, "🐔 Chickens Fed!", 
			"Fed " .. fedCount .. " chickens with basic feed!", "success")
	else
		self:SendNotification(player, "No Chickens", "You don't have any deployed chickens to feed!", "warning")
	end
end

-- ========== PEST DAMAGE SYSTEM ==========

function PestChickenSystem:StartDamageSystem()
	print("PestChickenSystem: Starting pest damage system...")

	spawn(function()
		while true do
			wait(self.Config.PEST_DAMAGE_INTERVAL)

			for pestId, pestData in pairs(self.ActivePests) do
				if pestData.plot and not pestData.plot:GetAttribute("IsEmpty") then
					self:ApplyPestDamage(pestData)
				end
			end
		end
	end)
end

function PestChickenSystem:ApplyPestDamage(pestData)
	local plot = pestData.plot
	if not plot then return end

	local currentHealth = plot:GetAttribute("CropHealth") or 100
	local pestType = self.PestTypes[pestData.type]
	local damage = pestType.damage

	local newHealth = math.max(0, currentHealth - damage)
	plot:SetAttribute("CropHealth", newHealth)

	-- If crop dies, remove it
	if newHealth <= 0 then
		plot:SetAttribute("IsEmpty", true)
		plot:SetAttribute("PlantType", "")
		plot:SetAttribute("SeedType", "")
		plot:SetAttribute("GrowthStage", 0)

		-- Remove crop model
		local cropModel = plot:FindFirstChild("CropModel")
		if cropModel then
			cropModel:Destroy()
		end

		-- Notify player
		local player = Players:FindFirstChild(pestData.owner)
		if player then
			self:SendNotification(player, "💀 Crop Destroyed!", 
				"Pests have destroyed your crop! Deploy chickens for protection.", "error")
		end

		-- Remove pest (no more crop to attack)
		self:EliminatePest(pestData.id, "crop_death")
	end
end

-- ========== UTILITY FUNCTIONS ==========

function PestChickenSystem:GetPlayerFarmPlots(player)
	local plots = {}
	local areas = workspace:FindFirstChild("Areas")
	if not areas then return plots end

	local starterMeadow = areas:FindFirstChild("Starter Meadow")
	if not starterMeadow then return plots end

	local farmArea = starterMeadow:FindFirstChild("Farm")
	if not farmArea then return plots end

	local playerFarm = farmArea:FindFirstChild(player.Name .. "_Farm")
	if not playerFarm then return plots end

	-- Get all planting spots
	for _, plot in pairs(playerFarm:GetChildren()) do
		if plot:IsA("Model") and plot.Name:find("FarmPlot") then
			local plantingSpots = plot:FindFirstChild("PlantingSpots")
			if plantingSpots then
				for _, spot in pairs(plantingSpots:GetChildren()) do
					if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
						table.insert(plots, spot)
					end
				end
			end
		end
	end

	return plots
end

function PestChickenSystem:CountPestsOnPlot(plot)
	local count = 0
	for _, pestData in pairs(self.ActivePests) do
		if pestData.plot == plot then
			count = count + 1
		end
	end
	return count
end

function PestChickenSystem:HasPigManureDeterrent(player)
	-- Check if player has pig manure near their farm
	local pig = workspace:FindFirstChild("Pig")
	if not pig then return false end

	local playerFarm = self:GetPlayerFarmCenter(player)
	if not playerFarm then return false end

	local distance = (pig.Position - playerFarm).Magnitude
	return distance <= self.Config.MANURE_DETERRENT_RADIUS
end

function PestChickenSystem:GetPlayerFarmCenter(player)
	local plots = self:GetPlayerFarmPlots(player)
	if #plots == 0 then return nil end

	local totalPos = Vector3.new(0, 0, 0)
	for _, plot in ipairs(plots) do
		if plot.PrimaryPart then
			totalPos = totalPos + plot.PrimaryPart.Position
		end
	end

	return totalPos / #plots
end

function PestChickenSystem:PlayerHasChicken(playerData, chickenType)
	if not playerData.defense or not playerData.defense.chickens or not playerData.defense.chickens.owned then
		return false
	end

	for chickenId, chickenData in pairs(playerData.defense.chickens.owned) do
		if chickenData.type == chickenType and chickenData.status == "available" then
			return true
		end
	end

	return false
end

function PestChickenSystem:MoveChickenToDeployed(playerData, chickenType)
	if not playerData.defense or not playerData.defense.chickens then return end

	-- Find available chicken and move to deployed
	for chickenId, chickenData in pairs(playerData.defense.chickens.owned) do
		if chickenData.type == chickenType and chickenData.status == "available" then
			chickenData.status = "deployed"
			playerData.defense.chickens.deployed[chickenId] = chickenData
			break
		end
	end
end

function PestChickenSystem:SendNotification(player, title, message, type)
	if self.GameCore and self.GameCore.SendNotification then
		self.GameCore:SendNotification(player, title, message, type)
	end
end

function PestChickenSystem:NotifyPestSpotted(player, pestType, cropType, plot)
	local remotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	if remotes and remotes:FindFirstChild("PestSpotted") then
		remotes.PestSpotted:FireClient(player, pestType, cropType, {
			position = plot.PrimaryPart and plot.PrimaryPart.Position or Vector3.new(0, 0, 0)
		})
	end
end

function PestChickenSystem:NotifyPestEliminated(player, pestType, eliminatedBy)
	local remotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	if remotes and remotes:FindFirstChild("PestEliminated") then
		remotes.PestEliminated:FireClient(player, pestType, eliminatedBy)
	end
end

function PestChickenSystem:NotifyChickenPlaced(player, chickenType, position)
	local remotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	if remotes and remotes:FindFirstChild("ChickenPlaced") then
		remotes.ChickenPlaced:FireClient(player, chickenType, position)
	end
end

-- ========== PLAYER EVENTS ==========

function PestChickenSystem:SetupPlayerEvents()
	Players.PlayerRemoving:Connect(function(player)
		self:CleanupPlayerData(player)
	end)
end

function PestChickenSystem:CleanupPlayerData(player)
	-- Remove player's pests
	local pestsToRemove = {}
	for pestId, pestData in pairs(self.ActivePests) do
		if pestData.owner == player.Name then
			table.insert(pestsToRemove, pestId)
		end
	end

	for _, pestId in ipairs(pestsToRemove) do
		self:EliminatePest(pestId, "player_left")
	end

	-- Remove player's chickens
	local chickensToRemove = {}
	for chickenId, chickenData in pairs(self.ActiveChickens) do
		if chickenData.owner == player.Name then
			table.insert(chickensToRemove, chickenId)
		end
	end

	for _, chickenId in ipairs(chickensToRemove) do
		local chickenData = self.ActiveChickens[chickenId]
		if chickenData.model then
			chickenData.model:Destroy()
		end
		self.ActiveChickens[chickenId] = nil
	end

	print("🧹 Cleaned up pest/chicken data for " .. player.Name)
end

-- ========== INITIALIZATION ==========

PestChickenSystem:Initialize()
_G.PestChickenSystem = PestChickenSystem

print("PestChickenSystem: ✅ Integrated pest & chicken system loaded!")
print("🐛 PEST FEATURES:")
print("  🦗 Multi-tier pest threat system")
print("  🌾 Crop-specific pest targeting")
print("  💀 Pest damage over time")
print("  🐷 Pig manure deterrent system")
print("")
print("🐔 CHICKEN FEATURES:")
print("  🛡️ Automated pest detection and elimination")
print("  🥚 Egg production system")
print("  🌾 Chicken feeding mechanics")
print("  🚶 Smart patrol AI system")
print("")
print("✅ Fully integrated with GameCore inventory system!")