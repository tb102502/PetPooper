--[[
    ChickenSystem.server.lua - CHICKEN DEFENSE SYSTEM
    Place in: ServerScriptService/ChickenSystem.server.lua
    
    FEATURES:
    - Multiple chicken types (Basic, Guinea Fowl, Rooster)
    - Chicken patrol and pest elimination
    - Egg production system
    - Chicken feeding and health management
    - Area boost effects from roosters
    - Integration with UFO attack system
    - Chicken visual representation and behavior
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

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- Wait for dependencies
local GameCore = WaitForGameCore("ChickenSystem")
local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))

-- Wait for PestSystem
local function WaitForPestSystem()
	local maxWait = 10
	local start = tick()
	while not _G.PestSystem and (tick() - start) < maxWait do
		wait(0.5)
	end
	return _G.PestSystem
end

local PestSystem = WaitForPestSystem()

print("=== CHICKEN DEFENSE SYSTEM STARTING ===")

local ChickenSystem = {}

-- System State
ChickenSystem.ActiveChickens = {} -- Track all chickens per player
ChickenSystem.ChickenModels = {} -- Visual models in workspace
ChickenSystem.EggProductionTimers = {} -- Track egg production
ChickenSystem.FeedingSchedule = {} -- Track feeding times
ChickenSystem.PatrolRoutes = {} -- Track chicken patrol paths

-- Chicken Configuration (from ItemConfig)
local CHICKEN_CONFIG = ItemConfig.ChickenSystem

-- ========== CORE CHICKEN MANAGEMENT ==========

-- Initialize the chicken system
function ChickenSystem:Initialize()
	print("ChickenSystem: Initializing chicken defense system...")

	-- Initialize system state
	self.ActiveChickens = {}
	self.ChickenModels = {}
	self.EggProductionTimers = {}
	self.FeedingSchedule = {}
	self.PatrolRoutes = {}

	-- Start main update loops
	self:StartChickenBehaviorLoop()
	self:StartEggProductionLoop()
	self:StartFeedingManagementLoop()
	self:StartPestPatrolLoop()

	-- Setup player cleanup
	self:SetupPlayerCleanup()

	-- Setup UFO integration
	self:SetupUFOIntegration()

	print("ChickenSystem: Chicken defense system fully initialized!")
end

-- ========== CHICKEN SPAWNING AND MANAGEMENT ==========

-- Spawn a chicken for a player
function ChickenSystem:SpawnChicken(player, chickenType, position)
	local chickenData = CHICKEN_CONFIG.chickenTypes[chickenType]
	if not chickenData then
		warn("ChickenSystem: Invalid chicken type: " .. chickenType)
		return nil
	end

	print("ChickenSystem: Spawning " .. chickenType .. " for " .. player.Name)

	-- Create chicken instance
	local chickenInstance = {
		chickenType = chickenType,
		player = player,
		spawnTime = os.time(),
		health = 100,
		hunger = chickenData.maxHunger,
		eggsLaid = 0,
		pestsEliminated = 0,
		currentPosition = position,
		homePosition = position,
		patrolTarget = nil,
		isHunting = false,
		chickenId = self:GenerateChickenId(),
		lastFeedTime = 0,
		lastEggTime = 0
	}

	-- Store in active chickens
	if not self.ActiveChickens[player.UserId] then
		self.ActiveChickens[player.UserId] = {}
	end
	self.ActiveChickens[player.UserId][chickenInstance.chickenId] = chickenInstance

	-- Create visual model
	local chickenModel = self:CreateChickenModel(chickenInstance)
	if chickenModel then
		self.ChickenModels[chickenInstance.chickenId] = chickenModel
	end

	-- Setup patrol route
	self:SetupChickenPatrol(chickenInstance)

	-- Notify player
	if GameCore and GameCore.SendNotification then
		GameCore:SendNotification(player, "🐔 Chicken Deployed!", 
			chickenData.name .. " is now protecting your farm from pests!", "success")
	end

	return chickenInstance
end

-- Create visual chicken model
function ChickenSystem:CreateChickenModel(chickenInstance)
	local chickenType = chickenInstance.chickenType
	local chickenData = CHICKEN_CONFIG.chickenTypes[chickenType]
	local position = chickenInstance.currentPosition

	-- Create chicken model
	local chickenModel = Instance.new("Model")
	chickenModel.Name = "Chicken_" .. chickenInstance.chickenId
	chickenModel.Parent = workspace

	-- Main body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(1.5, 1, 2)
	body.Material = Enum.Material.SmoothPlastic
	body.BrickColor = BrickColor.new("White")
	body.Shape = Enum.PartType.Block
	body.CanCollide = false
	body.Anchored = true
	body.CFrame = CFrame.new(position)
	body.Parent = chickenModel

	-- Set as primary part
	chickenModel.PrimaryPart = body

	-- Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(0.8, 0.8, 0.8)
	head.Material = Enum.Material.SmoothPlastic
	head.BrickColor = BrickColor.new("White")
	head.Shape = Enum.PartType.Ball
	head.CanCollide = false
	head.Anchored = true
	head.CFrame = body.CFrame + Vector3.new(0, 0.7, 0.8)
	head.Parent = chickenModel

	-- Beak
	local beak = Instance.new("Part")
	beak.Name = "Beak"
	beak.Size = Vector3.new(0.2, 0.2, 0.4)
	beak.Material = Enum.Material.SmoothPlastic
	beak.BrickColor = BrickColor.new("Bright orange")
	beak.Shape = Enum.PartType.Block
	beak.CanCollide = false
	beak.Anchored = true
	beak.CFrame = head.CFrame + Vector3.new(0, -0.1, 0.5)
	beak.Parent = chickenModel

	-- Tail feathers
	local tail = Instance.new("Part")
	tail.Name = "Tail"
	tail.Size = Vector3.new(0.5, 1.5, 0.2)
	tail.Material = Enum.Material.SmoothPlastic
	tail.BrickColor = BrickColor.new("White")
	tail.Shape = Enum.PartType.Block
	tail.CanCollide = false
	tail.Anchored = true
	tail.CFrame = body.CFrame + Vector3.new(0, 0.5, -1.2)
	tail.Parent = chickenModel

	-- Chicken-specific customization
	if chickenType == "guinea_fowl" then
		body.BrickColor = BrickColor.new("Dark stone grey")
		head.BrickColor = BrickColor.new("Dark stone grey")
		tail.BrickColor = BrickColor.new("Dark stone grey")

		-- Add spots
		for i = 1, 5 do
			local spot = Instance.new("Part")
			spot.Name = "Spot" .. i
			spot.Size = Vector3.new(0.2, 0.2, 0.2)
			spot.Material = Enum.Material.Neon
			spot.BrickColor = BrickColor.new("White")
			spot.Shape = Enum.PartType.Ball
			spot.CanCollide = false
			spot.Anchored = true
			spot.CFrame = body.CFrame + Vector3.new(
				math.random(-0.5, 0.5),
				math.random(-0.3, 0.3),
				math.random(-0.8, 0.8)
			)
			spot.Parent = chickenModel
		end

	elseif chickenType == "rooster" then
		-- Larger and more colorful
		body.Size = Vector3.new(2, 1.3, 2.5)
		body.BrickColor = BrickColor.new("Bright red")
		head.BrickColor = BrickColor.new("Bright red")
		tail.Size = Vector3.new(0.8, 2.5, 0.3)
		tail.BrickColor = BrickColor.new("Dark green")

		-- Crown/comb
		local comb = Instance.new("Part")
		comb.Name = "Comb"
		comb.Size = Vector3.new(0.6, 0.5, 0.2)
		comb.Material = Enum.Material.SmoothPlastic
		comb.BrickColor = BrickColor.new("Really red")
		comb.Shape = Enum.PartType.Block
		comb.CanCollide = false
		comb.Anchored = true
		comb.CFrame = head.CFrame + Vector3.new(0, 0.6, 0)
		comb.Parent = chickenModel
	end

	-- Health bar above chicken
	local healthBar = self:CreateChickenHealthBar(chickenInstance)
	healthBar.Parent = chickenModel

	-- Chicken nameplate
	local nameplate = self:CreateChickenNameplate(chickenInstance)
	nameplate.Parent = chickenModel

	return chickenModel
end

-- Create health bar for chicken
function ChickenSystem:CreateChickenHealthBar(chickenInstance)
	local chickenData = CHICKEN_CONFIG.chickenTypes[chickenInstance.chickenType]

	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "HealthBar"
	billboardGui.Size = UDim2.new(0, 100, 0, 20)
	billboardGui.StudsOffset = Vector3.new(0, 3, 0)

	local healthFrame = Instance.new("Frame")
	healthFrame.Size = UDim2.new(1, 0, 1, 0)
	healthFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	healthFrame.BorderSizePixel = 0
	healthFrame.Parent = billboardGui

	local healthBar = Instance.new("Frame")
	healthBar.Name = "HealthBar"
	healthBar.Size = UDim2.new(chickenInstance.health / 100, 0, 1, 0)
	healthBar.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
	healthBar.BorderSizePixel = 0
	healthBar.Parent = healthFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.2, 0)
	corner.Parent = healthFrame

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0.2, 0)
	barCorner.Parent = healthBar

	return billboardGui
end

-- Create nameplate for chicken
function ChickenSystem:CreateChickenNameplate(chickenInstance)
	local chickenData = CHICKEN_CONFIG.chickenTypes[chickenInstance.chickenType]

	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "Nameplate"
	billboardGui.Size = UDim2.new(0, 120, 0, 30)
	billboardGui.StudsOffset = Vector3.new(0, 4.5, 0)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = chickenData.icon .. " " .. chickenData.name
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	nameLabel.Parent = billboardGui

	return billboardGui
end

-- ========== CHICKEN BEHAVIOR LOOPS ==========

-- Main chicken behavior loop
function ChickenSystem:StartChickenBehaviorLoop()
	spawn(function()
		print("ChickenSystem: Starting chicken behavior loop...")

		while true do
			wait(5) -- Update every 5 seconds

			for userId, playerChickens in pairs(self.ActiveChickens) do
				local player = Players:GetPlayerByUserId(userId)
				if player then
					for chickenId, chickenInstance in pairs(playerChickens) do
						self:UpdateChickenBehavior(chickenInstance)
					end
				end
			end
		end
	end)
end

-- Update individual chicken behavior
function ChickenSystem:UpdateChickenBehavior(chickenInstance)
	if not chickenInstance or not chickenInstance.player then return end

	local chickenModel = self.ChickenModels[chickenInstance.chickenId]
	if not chickenModel or not chickenModel.Parent then
		-- Model was destroyed, recreate it
		chickenModel = self:CreateChickenModel(chickenInstance)
		self.ChickenModels[chickenInstance.chickenId] = chickenModel
	end

	-- Update hunger over time
	local currentTime = os.time()
	local timeSinceLastFeed = currentTime - chickenInstance.lastFeedTime
	chickenInstance.hunger = math.max(0, chickenInstance.hunger - (timeSinceLastFeed / 3600)) -- 1 hunger per hour

	-- Update health based on hunger
	if chickenInstance.hunger <= 0 then
		chickenInstance.health = math.max(0, chickenInstance.health - 5) -- Lose 5 health per update when hungry
	elseif chickenInstance.hunger > CHICKEN_CONFIG.chickenTypes[chickenInstance.chickenType].maxHunger * 0.5 then
		chickenInstance.health = math.min(100, chickenInstance.health + 1) -- Slowly recover health when well fed
	end

	-- Check if chicken dies from poor care
	if chickenInstance.health <= 0 then
		self:RemoveChicken(chickenInstance)
		return
	end

	-- Update visual health bar
	self:UpdateChickenHealthBar(chickenInstance)

	-- Patrol behavior
	if not chickenInstance.isHunting then
		self:UpdateChickenPatrol(chickenInstance)
	end

	-- Check for nearby pests to hunt
	self:CheckPestHunting(chickenInstance)

	-- Apply rooster area effects
	if chickenInstance.chickenType == "rooster" then
		self:ApplyRoosterAreaEffects(chickenInstance)
	end
end

-- ========== PEST HUNTING SYSTEM ==========

-- Start pest patrol loop
function ChickenSystem:StartPestPatrolLoop()
	spawn(function()
		print("ChickenSystem: Starting pest patrol loop...")

		while true do
			wait(10) -- Check for pests every 10 seconds

			for userId, playerChickens in pairs(self.ActiveChickens) do
				for chickenId, chickenInstance in pairs(playerChickens) do
					if chickenInstance.health > 50 and chickenInstance.hunger > 0 then
						self:CheckPestHunting(chickenInstance)
					end
				end
			end
		end
	end)
end

-- Check if chicken can hunt nearby pests
function ChickenSystem:CheckPestHunting(chickenInstance)
	if not PestSystem then return end

	local chickenData = CHICKEN_CONFIG.chickenTypes[chickenInstance.chickenType]
	local huntRange = chickenData.huntRange or 3
	local pestTargets = chickenData.pestTargets or {}

	-- Get pests in range
	local pestsInRange = PestSystem:GetPestsInRange(chickenInstance.currentPosition, huntRange, pestTargets)

	if #pestsInRange > 0 then
		-- Hunt the first available pest
		local targetPest = pestsInRange[1]
		self:HuntPest(chickenInstance, targetPest)
	end
end

-- Hunt a specific pest
function ChickenSystem:HuntPest(chickenInstance, targetPest)
	if not targetPest or not targetPest.cropModel then return end

	local chickenData = CHICKEN_CONFIG.chickenTypes[chickenInstance.chickenType]
	local huntEfficiency = chickenData.huntEfficiency or 0.8

	print("ChickenSystem: " .. chickenInstance.chickenType .. " hunting " .. targetPest.pestType)

	-- Move chicken towards pest
	chickenInstance.isHunting = true
	chickenInstance.patrolTarget = targetPest.cropModel.Crop.Position

	-- Animate chicken movement
	local chickenModel = self.ChickenModels[chickenInstance.chickenId]
	if chickenModel and chickenModel.PrimaryPart then
		local targetPosition = targetPest.cropModel.Crop.Position + Vector3.new(0, 1, 0)

		TweenService:Create(chickenModel.PrimaryPart, TweenInfo.new(2, Enum.EasingStyle.Quad), {
			CFrame = CFrame.new(targetPosition)
		}):Play()

		chickenInstance.currentPosition = targetPosition
	end

	-- After movement, attempt to eliminate pest
	spawn(function()
		wait(2) -- Wait for movement

		-- Check if pest still exists
		if targetPest.cropModel and targetPest.cropModel.Parent then
			-- Success check
			if math.random() < huntEfficiency then
				-- Successfully eliminated pest
				chickenInstance.pestsEliminated = chickenInstance.pestsEliminated + 1

				-- Create success effect
				self:CreateHuntSuccessEffect(targetPest.cropModel.Position)

				-- Tell PestSystem to remove pest
				if PestSystem and PestSystem.RemovePest then
					PestSystem:RemovePest(targetPest)
				end

				-- Notify player
				if GameCore and GameCore.SendNotification then
					GameCore:SendNotification(chickenInstance.player, "🐔 Pest Eliminated!", 
						"Your " .. chickenInstance.chickenType .. " eliminated a " .. targetPest.pestType .. "!", "success")
				end

				print("ChickenSystem: Successfully eliminated " .. targetPest.pestType)
			else
				print("ChickenSystem: Hunt attempt failed")
			end
		end

		-- Return to patrol
		chickenInstance.isHunting = false
	end)
end

-- Create visual effect for successful pest elimination
function ChickenSystem:CreateHuntSuccessEffect(position)
	-- Create feathers flying effect
	for i = 1, 8 do
		local feather = Instance.new("Part")
		feather.Name = "Feather"
		feather.Size = Vector3.new(0.2, 0.1, 0.4)
		feather.Material = Enum.Material.Neon
		feather.Color = Color3.fromRGB(255, 255, 255)
		feather.CanCollide = false
		feather.Anchored = true
		feather.Position = position + Vector3.new(
			math.random(-1, 1),
			math.random(1, 2),
			math.random(-1, 1)
		)
		feather.Parent = workspace

		-- Animate feather
		TweenService:Create(feather, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = feather.Position + Vector3.new(
				math.random(-5, 5),
				math.random(3, 8),
				math.random(-5, 5)
			),
			Transparency = 1,
			Rotation = Vector3.new(math.random(0, 360), math.random(0, 360), math.random(0, 360))
		}):Play()

		-- Clean up
		Debris:AddItem(feather, 3)
	end
end

-- ========== EGG PRODUCTION SYSTEM ==========

-- Start egg production loop
function ChickenSystem:StartEggProductionLoop()
	spawn(function()
		print("ChickenSystem: Starting egg production loop...")

		while true do
			wait(60) -- Check every minute

			for userId, playerChickens in pairs(self.ActiveChickens) do
				local player = Players:GetPlayerByUserId(userId)
				if player then
					for chickenId, chickenInstance in pairs(playerChickens) do
						self:CheckEggProduction(chickenInstance)
					end
				end
			end
		end
	end)
end

-- Check if chicken should produce an egg
function ChickenSystem:CheckEggProduction(chickenInstance)
	if chickenInstance.health < 50 or chickenInstance.hunger < 10 then
		return -- Too unhealthy to lay eggs
	end

	local chickenData = CHICKEN_CONFIG.chickenTypes[chickenInstance.chickenType]
	local productionTime = chickenData.eggProductionTime or 240 -- 4 minutes default

	local currentTime = os.time()
	local timeSinceLastEgg = currentTime - chickenInstance.lastEggTime

	if timeSinceLastEgg >= productionTime then
		self:ProduceEgg(chickenInstance)
		chickenInstance.lastEggTime = currentTime
	end
end

-- Produce an egg from a chicken
function ChickenSystem:ProduceEgg(chickenInstance)
	local chickenData = CHICKEN_CONFIG.chickenTypes[chickenInstance.chickenType]
	local eggValue = chickenData.eggValue or 5

	print("ChickenSystem: " .. chickenInstance.chickenType .. " laid an egg for " .. chickenInstance.player.Name)

	-- Add egg to player's inventory
	local playerData = GameCore:GetPlayerData(chickenInstance.player)
	if playerData then
		if not playerData.farming then
			playerData.farming = {inventory = {}}
		end
		if not playerData.farming.inventory then
			playerData.farming.inventory = {}
		end

		-- Determine egg type
		local eggType = "chicken_egg"
		if chickenInstance.chickenType == "guinea_fowl" then
			eggType = "guinea_egg"
		elseif chickenInstance.chickenType == "rooster" then
			eggType = "rooster_egg"
		end

		-- Add egg to inventory
		playerData.farming.inventory[eggType] = (playerData.farming.inventory[eggType] or 0) + 1

		-- Update player data
		GameCore:SavePlayerData(chickenInstance.player)
		if GameCore.RemoteEvents.PlayerDataUpdated then
			GameCore.RemoteEvents.PlayerDataUpdated:FireClient(chickenInstance.player, playerData)
		end

		-- Create visual egg effect
		self:CreateEggProductionEffect(chickenInstance)

		-- Notify player
		if GameCore and GameCore.SendNotification then
			GameCore:SendNotification(chickenInstance.player, "🥚 Egg Laid!", 
				"Your " .. chickenData.name .. " laid an egg worth " .. eggValue .. " coins!", "success")
		end

		-- Track statistics
		chickenInstance.eggsLaid = chickenInstance.eggsLaid + 1
	end
end

-- Create visual effect for egg production
function ChickenSystem:CreateEggProductionEffect(chickenInstance)
	local chickenModel = self.ChickenModels[chickenInstance.chickenId]
	if not chickenModel or not chickenModel.PrimaryPart then return end

	-- Create egg visual
	local egg = Instance.new("Part")
	egg.Name = "Egg"
	egg.Size = Vector3.new(0.4, 0.6, 0.4)
	egg.Shape = Enum.PartType.Ball
	egg.Material = Enum.Material.SmoothPlastic
	egg.Color = Color3.fromRGB(255, 248, 220) -- Cream white
	egg.CanCollide = false
	egg.Anchored = true
	egg.CFrame = chickenModel.PrimaryPart.CFrame + Vector3.new(0, -1, -1)
	egg.Parent = workspace

	-- Add egg sparkles
	for i = 1, 6 do
		local sparkle = Instance.new("Part")
		sparkle.Size = Vector3.new(0.1, 0.1, 0.1)
		sparkle.Shape = Enum.PartType.Ball
		sparkle.Material = Enum.Material.Neon
		sparkle.Color = Color3.fromRGB(255, 215, 0) -- Gold
		sparkle.CanCollide = false
		sparkle.Anchored = true
		sparkle.Position = egg.Position + Vector3.new(
			math.random(-1, 1),
			math.random(0, 2),
			math.random(-1, 1)
		)
		sparkle.Parent = workspace

		-- Animate sparkle
		TweenService:Create(sparkle, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = sparkle.Position + Vector3.new(0, 3, 0),
			Transparency = 1
		}):Play()

		Debris:AddItem(sparkle, 2)
	end

	-- Make egg disappear after a moment
	spawn(function()
		wait(3)
		if egg and egg.Parent then
			TweenService:Create(egg, TweenInfo.new(1), {
				Transparency = 1,
				Size = Vector3.new(0.1, 0.1, 0.1)
			}):Play()
			Debris:AddItem(egg, 1)
		end
	end)
end

-- ========== FEEDING MANAGEMENT ==========

-- Start feeding management loop
function ChickenSystem:StartFeedingManagementLoop()
	spawn(function()
		print("ChickenSystem: Starting feeding management loop...")

		while true do
			wait(300) -- Check every 5 minutes

			for userId, playerChickens in pairs(self.ActiveChickens) do
				for chickenId, chickenInstance in pairs(playerChickens) do
					self:CheckAutoFeeding(chickenInstance)
				end
			end
		end
	end)
end

-- Check for automatic feeding (if player has feed in inventory)
function ChickenSystem:CheckAutoFeeding(chickenInstance)
	if chickenInstance.hunger > CHICKEN_CONFIG.chickenTypes[chickenInstance.chickenType].maxHunger * 0.5 then
		return -- Not hungry enough
	end

	local playerData = GameCore:GetPlayerData(chickenInstance.player)
	if not playerData or not playerData.farming or not playerData.farming.inventory then
		return
	end

	-- Check for available feed
	local feedTypes = {"basic_feed", "premium_feed", "grain_feed"}
	for _, feedType in ipairs(feedTypes) do
		local feedCount = playerData.farming.inventory[feedType] or 0
		if feedCount > 0 then
			self:FeedChicken(chickenInstance, feedType)
			return
		end
	end
end

-- Feed a chicken with specific feed type
function ChickenSystem:FeedChicken(chickenInstance, feedType)
	local feedData = CHICKEN_CONFIG.feedTypes[feedType]
	if not feedData then return end

	print("ChickenSystem: Feeding " .. chickenInstance.chickenType .. " with " .. feedType)

	-- Remove feed from inventory
	local playerData = GameCore:GetPlayerData(chickenInstance.player)
	if playerData and playerData.farming and playerData.farming.inventory then
		playerData.farming.inventory[feedType] = math.max(0, (playerData.farming.inventory[feedType] or 0) - 1)

		-- Restore hunger
		chickenInstance.hunger = math.min(
			CHICKEN_CONFIG.chickenTypes[chickenInstance.chickenType].maxHunger,
			chickenInstance.hunger + feedData.feedValue
		)
		chickenInstance.lastFeedTime = os.time()

		-- Apply feed bonuses
		if feedData.eggBonus then
			-- Boost next egg production time
			chickenInstance.lastEggTime = chickenInstance.lastEggTime - (60 * (feedData.eggBonus - 1))
		end

		if feedData.healthBonus then
			-- Extend lifespan
			chickenInstance.health = math.min(100, chickenInstance.health + 10)
		end

		-- Update player data
		GameCore:SavePlayerData(chickenInstance.player)
		if GameCore.RemoteEvents.PlayerDataUpdated then
			GameCore.RemoteEvents.PlayerDataUpdated:FireClient(chickenInstance.player, playerData)
		end

		-- Create feeding effect
		self:CreateFeedingEffect(chickenInstance)

		-- Notify player
		if GameCore and GameCore.SendNotification then
			GameCore:SendNotification(chickenInstance.player, "🌾 Chicken Fed!", 
				"Fed your " .. chickenInstance.chickenType .. " with " .. feedData.name .. "!", "success")
		end
	end
end

-- Create visual effect for feeding
function ChickenSystem:CreateFeedingEffect(chickenInstance)
	local chickenModel = self.ChickenModels[chickenInstance.chickenId]
	if not chickenModel or not chickenModel.PrimaryPart then return end

	-- Create feed particles
	for i = 1, 10 do
		local grain = Instance.new("Part")
		grain.Size = Vector3.new(0.1, 0.1, 0.1)
		grain.Shape = Enum.PartType.Ball
		grain.Material = Enum.Material.SmoothPlastic
		grain.Color = Color3.fromRGB(255, 215, 0) -- Golden grain
		grain.CanCollide = false
		grain.Anchored = true
		grain.Position = chickenModel.PrimaryPart.Position + Vector3.new(
			math.random(-2, 2),
			math.random(2, 4),
			math.random(-2, 2)
		)
		grain.Parent = workspace

		-- Animate grain falling
		TweenService:Create(grain, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = chickenModel.PrimaryPart.Position + Vector3.new(
				math.random(-1, 1),
				-0.5,
				math.random(-1, 1)
			),
			Transparency = 1
		}):Play()

		Debris:AddItem(grain, 1.5)
	end
end

-- ========== ROOSTER AREA EFFECTS ==========

-- Apply rooster area boost effects
function ChickenSystem:ApplyRoosterAreaEffects(roosterInstance)
	local roosterData = CHICKEN_CONFIG.chickenTypes.rooster
	local boostRadius = roosterData.boostRadius or 6
	local boostMultiplier = roosterData.boostMultiplier or 1.5

	-- Find other chickens in range
	for userId, playerChickens in pairs(self.ActiveChickens) do
		for chickenId, chickenInstance in pairs(playerChickens) do
			if chickenInstance.chickenId ~= roosterInstance.chickenId then
				local distance = (chickenInstance.currentPosition - roosterInstance.currentPosition).Magnitude
				if distance <= boostRadius * 20 then -- Convert to studs
					-- Apply boost effect
					chickenInstance.roosterBoost = boostMultiplier
				else
					chickenInstance.roosterBoost = nil
				end
			end
		end
	end
end

-- ========== PATROL SYSTEM ==========

-- Setup patrol route for chicken
function ChickenSystem:SetupChickenPatrol(chickenInstance)
	-- Create a patrol route around the chicken's home position
	local homePos = chickenInstance.homePosition
	local patrolPoints = {}

	-- Create 4 patrol points in a square pattern
	local patrolRadius = 15
	for i = 1, 4 do
		local angle = (i - 1) * (math.pi / 2)
		local x = homePos.X + math.cos(angle) * patrolRadius
		local z = homePos.Z + math.sin(angle) * patrolRadius
		table.insert(patrolPoints, Vector3.new(x, homePos.Y, z))
	end

	self.PatrolRoutes[chickenInstance.chickenId] = {
		points = patrolPoints,
		currentPoint = 1,
		lastMoveTime = os.time()
	}
end

-- Update chicken patrol movement
function ChickenSystem:UpdateChickenPatrol(chickenInstance)
	local patrolRoute = self.PatrolRoutes[chickenInstance.chickenId]
	if not patrolRoute then return end

	local currentTime = os.time()
	if currentTime - patrolRoute.lastMoveTime < 10 then return end -- Move every 10 seconds

	-- Get next patrol point
	local targetPoint = patrolRoute.points[patrolRoute.currentPoint]

	-- Move chicken to target point
	local chickenModel = self.ChickenModels[chickenInstance.chickenId]
	if chickenModel and chickenModel.PrimaryPart then
		TweenService:Create(chickenModel.PrimaryPart, TweenInfo.new(3, Enum.EasingStyle.Quad), {
			CFrame = CFrame.new(targetPoint + Vector3.new(0, 2, 0))
		}):Play()

		chickenInstance.currentPosition = targetPoint
	end

	-- Advance to next patrol point
	patrolRoute.currentPoint = (patrolRoute.currentPoint % #patrolRoute.points) + 1
	patrolRoute.lastMoveTime = currentTime
end

-- ========== UFO INTEGRATION ==========

-- Setup UFO attack integration
function ChickenSystem:SetupUFOIntegration()
	-- Listen for UFO attacks to scatter chickens
	local ufoEvent = ReplicatedStorage:FindFirstChild("UFOAttack")
	if ufoEvent then
		ufoEvent.OnServerEvent:Connect(function(player, action)
			if action == "START" then
				self:ScatterChickensFromUFO()
			elseif action == "END" then
				self:ReturnChickensAfterUFO()
			end
		end)
	end
end

-- Scatter chickens when UFO attacks
function ChickenSystem:ScatterChickensFromUFO()
	print("ChickenSystem: UFO attack! Scattering chickens to safety")

	for userId, playerChickens in pairs(self.ActiveChickens) do
		for chickenId, chickenInstance in pairs(playerChickens) do
			-- Move chicken to random safe location
			local scatterPosition = chickenInstance.homePosition + Vector3.new(
				math.random(-30, 30),
				0,
				math.random(-30, 30)
			)

			local chickenModel = self.ChickenModels[chickenId]
			if chickenModel and chickenModel.PrimaryPart then
				-- Quick scatter animation
				TweenService:Create(chickenModel.PrimaryPart, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					CFrame = CFrame.new(scatterPosition + Vector3.new(0, 2, 0))
				}):Play()

				chickenInstance.currentPosition = scatterPosition
			end

			-- Reduce effectiveness temporarily
			chickenInstance.ufoScattered = true
		end
	end
end

-- Return chickens to normal behavior after UFO
function ChickenSystem:ReturnChickensAfterUFO()
	print("ChickenSystem: UFO attack over, chickens returning to normal behavior")

	spawn(function()
		wait(5) -- Wait 5 seconds before returning

		for userId, playerChickens in pairs(self.ActiveChickens) do
			for chickenId, chickenInstance in pairs(playerChickens) do
				if chickenInstance.ufoScattered then
					-- Return to home position
					local chickenModel = self.ChickenModels[chickenId]
					if chickenModel and chickenModel.PrimaryPart then
						TweenService:Create(chickenModel.PrimaryPart, TweenInfo.new(3, Enum.EasingStyle.Quad), {
							CFrame = CFrame.new(chickenInstance.homePosition + Vector3.new(0, 2, 0))
						}):Play()

						chickenInstance.currentPosition = chickenInstance.homePosition
					end

					chickenInstance.ufoScattered = false
				end
			end
		end
	end)
end

-- ========== UTILITY FUNCTIONS ==========

-- Update chicken health bar
function ChickenSystem:UpdateChickenHealthBar(chickenInstance)
	local chickenModel = self.ChickenModels[chickenInstance.chickenId]
	if not chickenModel then return end

	local healthBar = chickenModel:FindFirstChild("HealthBar")
	if healthBar and healthBar:FindFirstChild("HealthBar") then
		local bar = healthBar.HealthBar
		bar.Size = UDim2.new(chickenInstance.health / 100, 0, 1, 0)

		-- Color based on health
		if chickenInstance.health > 70 then
			bar.BackgroundColor3 = Color3.fromRGB(60, 200, 60) -- Green
		elseif chickenInstance.health > 30 then
			bar.BackgroundColor3 = Color3.fromRGB(200, 200, 60) -- Yellow
		else
			bar.BackgroundColor3 = Color3.fromRGB(200, 60, 60) -- Red
		end
	end
end

-- Remove a chicken from the system
function ChickenSystem:RemoveChicken(chickenInstance)
	print("ChickenSystem: Removing " .. chickenInstance.chickenType .. " for " .. chickenInstance.player.Name)

	-- Remove visual model
	local chickenModel = self.ChickenModels[chickenInstance.chickenId]
	if chickenModel then
		-- Death effect
		self:CreateChickenDeathEffect(chickenModel.PrimaryPart.Position)
		chickenModel:Destroy()
		self.ChickenModels[chickenInstance.chickenId] = nil
	end

	-- Remove from tracking
	if self.ActiveChickens[chickenInstance.player.UserId] then
		self.ActiveChickens[chickenInstance.player.UserId][chickenInstance.chickenId] = nil
	end

	-- Clean up patrol route
	self.PatrolRoutes[chickenInstance.chickenId] = nil

	-- Notify player
	if GameCore and GameCore.SendNotification then
		local chickenData = CHICKEN_CONFIG.chickenTypes[chickenInstance.chickenType]
		GameCore:SendNotification(chickenInstance.player, "💀 Chicken Died", 
			"Your " .. chickenData.name .. " died from poor care. Feed your chickens to keep them healthy!", "error")
	end
end

-- Create visual effect for chicken death
function ChickenSystem:CreateChickenDeathEffect(position)
	-- Create sad feather effect
	for i = 1, 12 do
		local feather = Instance.new("Part")
		feather.Size = Vector3.new(0.3, 0.1, 0.5)
		feather.Material = Enum.Material.SmoothPlastic
		feather.Color = Color3.fromRGB(150, 150, 150) -- Gray feathers
		feather.CanCollide = false
		feather.Anchored = true
		feather.Position = position + Vector3.new(
			math.random(-2, 2),
			math.random(1, 3),
			math.random(-2, 2)
		)
		feather.Parent = workspace

		-- Animate feather falling
		TweenService:Create(feather, TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = feather.Position + Vector3.new(
				math.random(-3, 3),
				-5,
				math.random(-3, 3)
			),
			Transparency = 1,
			Rotation = Vector3.new(math.random(0, 360), math.random(0, 360), math.random(0, 360))
		}):Play()

		Debris:AddItem(feather, 4)
	end
end

-- Generate unique chicken ID
function ChickenSystem:GenerateChickenId()
	return "chicken_" .. os.time() .. "_" .. math.random(1000, 9999)
end

-- Setup player cleanup
function ChickenSystem:SetupPlayerCleanup()
	Players.PlayerRemoving:Connect(function(player)
		-- Clean up player's chickens when they leave
		if self.ActiveChickens[player.UserId] then
			for chickenId, chickenInstance in pairs(self.ActiveChickens[player.UserId]) do
				self:RemoveChicken(chickenInstance)
			end
			self.ActiveChickens[player.UserId] = nil
		end
		print("ChickenSystem: Cleaned up chickens for " .. player.Name)
	end)
end

-- ========== PUBLIC API FOR GAMECORE INTEGRATION ==========

-- Function for GameCore to spawn chickens when purchased
function ChickenSystem:HandleChickenPurchase(player, chickenType)
	-- Find suitable spawn position near player's farm
	local spawnPosition = self:FindChickenSpawnPosition(player)
	if spawnPosition then
		return self:SpawnChicken(player, chickenType, spawnPosition)
	else
		return nil
	end
end

-- Find appropriate spawn position for chicken
function ChickenSystem:FindChickenSpawnPosition(player)
	-- Try to find player's farm area
	local areas = workspace:FindFirstChild("Areas")
	if areas then
		local starterMeadow = areas:FindFirstChild("Starter Meadow")
		if starterMeadow then
			local farmArea = starterMeadow:FindFirstChild("Farm")
			if farmArea then
				local playerFarm = farmArea:FindFirstChild(player.Name .. "_Farm")
				if playerFarm then
					-- Find first farm plot
					for _, plot in pairs(playerFarm:GetChildren()) do
						if plot:IsA("Model") and plot.Name:find("FarmPlot") and plot.PrimaryPart then
							return plot.PrimaryPart.Position + Vector3.new(10, 2, 10)
						end
					end
				end
			end
		end
	end

	-- Fallback to spawn area
	return Vector3.new(0, 5, 0)
end

-- Admin commands for testing
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.Name == "TommySalami311" then -- Replace with your username
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/spawnchicken" then
				local chickenType = args[2] or "basic_chicken"
				local position = player.Character and player.Character.HumanoidRootPart and 
					player.Character.HumanoidRootPart.Position + Vector3.new(5, 2, 0) or Vector3.new(0, 5, 0)
				ChickenSystem:SpawnChicken(player, chickenType, position)

			elseif command == "/feedchickens" then
				if ChickenSystem.ActiveChickens[player.UserId] then
					for chickenId, chickenInstance in pairs(ChickenSystem.ActiveChickens[player.UserId]) do
						ChickenSystem:FeedChicken(chickenInstance, "basic_feed")
					end
				end

			elseif command == "/chickenstats" then
				if ChickenSystem.ActiveChickens[player.UserId] then
					print("=== CHICKEN STATS FOR " .. player.Name .. " ===")
					for chickenId, chickenInstance in pairs(ChickenSystem.ActiveChickens[player.UserId]) do
						print("Type: " .. chickenInstance.chickenType)
						print("Health: " .. chickenInstance.health)
						print("Hunger: " .. chickenInstance.hunger)
						print("Eggs Laid: " .. chickenInstance.eggsLaid)
						print("Pests Eliminated: " .. chickenInstance.pestsEliminated)
						print("---")
					end
				else
					print("No chickens found for " .. player.Name)
				end

			elseif command == "/testufoscatter" then
				ChickenSystem:ScatterChickensFromUFO()
				spawn(function()
					wait(5)
					ChickenSystem:ReturnChickensAfterUFO()
				end)
			end
		end
	end)
end)

-- Initialize the system and make it globally available
ChickenSystem:Initialize()
_G.ChickenSystem = ChickenSystem

print("=== CHICKEN DEFENSE SYSTEM ACTIVE ===")
print("Features:")
print("✅ Multiple chicken types with unique abilities")
print("✅ Automated pest hunting and elimination")
print("✅ Egg production system")
print("✅ Chicken health and feeding management")
print("✅ Rooster area boost effects")
print("✅ UFO attack integration")
print("✅ Visual chicken models and animations")
print("")
print("Chicken Types:")
print("  🐔 Basic Chicken - General pest control, regular eggs")
print("  🦃 Guinea Fowl - Anti-locust specialist, alarm system")
print("  🐓 Rooster - Area boosts, premium eggs, intimidation")
print("")
print("Admin Commands:")
print("  /spawnchicken [type] - Spawn chicken near player")
print("  /feedchickens - Feed all player's chickens")
print("  /chickenstats - Show player's chicken statistics")
print("  /testufoscatter - Test UFO scatter effect")

return ChickenSystem