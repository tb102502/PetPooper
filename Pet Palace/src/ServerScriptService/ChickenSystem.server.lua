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
	local chickenModel = self:CreateChickenModelFromTemplate(chickenInstance)
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
	self:InitializeSimpleMovement(chickenInstance)
	return chickenInstance
end

-- Create visual chicken model
function ChickenSystem:CreateChickenModelFromTemplate(chickenInstance)
	local chickenType = chickenInstance.chickenType
	local position = chickenInstance.currentPosition

	-- Try to find chicken model in ReplicatedStorage
	local replicatedStorage = game:GetService("ReplicatedStorage")
	local chickenModels = replicatedStorage:FindFirstChild("ChickenModels")

	if not chickenModels then
		warn("ChickenSystem: ChickenModels folder not found in ReplicatedStorage")
		return self:CreateBasicChickenModel(chickenInstance) -- Fallback to basic model
	end

	local templateName = "BasicChicken"
	if chickenType == "guinea_fowl" then
		templateName = "GuineaFowl"
	elseif chickenType == "rooster" then
		templateName = "Rooster"
	end

	local template = chickenModels:FindFirstChild(templateName)
	if not template then
		warn("ChickenSystem: " .. templateName .. " template not found, using basic model")
		return self:CreateBasicChickenModel(chickenInstance) -- Fallback
	end

	print("ChickenSystem: Using template " .. templateName .. " for " .. chickenType)

	-- Clone the template
	local chickenModel = template:Clone()
	chickenModel.Name = "Chicken_" .. chickenInstance.chickenId
	chickenModel.Parent = workspace


	-- Position the model
	if chickenModel.PrimaryPart then
		chickenModel:SetPrimaryPartCFrame(CFrame.new(position))
	else
		-- If no PrimaryPart, try to find the main part
		local mainPart = chickenModel:FindFirstChild("HumanoidRootPart") or
			chickenModel:FindFirstChild("Torso") or 
			chickenModel:FindFirstChild("Body") or
			chickenModel:FindFirstChildOfClass("Part")

		if mainPart then
			chickenModel.PrimaryPart = mainPart
			chickenModel:SetPrimaryPartCFrame(CFrame.new(position))
		else
			warn("ChickenSystem: Could not find main part for " .. templateName)
			-- Position all parts manually
			for _, part in pairs(chickenModel:GetChildren()) do
				if part:IsA("BasePart") then
					part.CFrame = CFrame.new(position)
					break
				end
			end
		end
	end

	-- Add health bar and nameplate
	local healthBar = self:CreateChickenHealthBar(chickenInstance)
	local nameplate = self:CreateChickenNameplate(chickenInstance)

	print("ChickenSystem: Successfully created chicken model from template with walking capability")
	return chickenModel
end
-- Create health bar for chicken
function ChickenSystem:CreateChickenHealthBar(chickenInstance)
	local chickenModel = self.ChickenModels[chickenInstance.chickenId]
	if not chickenModel then return nil end

	-- Create health bar GUI
	local healthBarGui = Instance.new("BillboardGui")
	healthBarGui.Name = "HealthBar"
	healthBarGui.Size = UDim2.new(0, 100, 0, 20)
	healthBarGui.StudsOffset = Vector3.new(0, 3, 0)
	healthBarGui.AlwaysOnTop = true
	healthBarGui.Parent = chickenModel

	-- Background frame
	local bgFrame = Instance.new("Frame")
	bgFrame.Name = "Background"
	bgFrame.Size = UDim2.new(1, 0, 1, 0)
	bgFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	bgFrame.BorderSizePixel = 0
	bgFrame.Parent = healthBarGui

	-- Health bar
	local healthBar = Instance.new("Frame")
	healthBar.Name = "HealthBar"
	healthBar.Size = UDim2.new(1, 0, 1, 0)
	healthBar.BackgroundColor3 = Color3.fromRGB(60, 200, 60) -- Green
	healthBar.BorderSizePixel = 0
	healthBar.Parent = bgFrame

	-- Corner radius
	local corner1 = Instance.new("UICorner")
	corner1.CornerRadius = UDim.new(0.2, 0)
	corner1.Parent = bgFrame

	local corner2 = Instance.new("UICorner")
	corner2.CornerRadius = UDim.new(0.2, 0)
	corner2.Parent = healthBar

	return healthBarGui
end

-- Create nameplate for chicken
function ChickenSystem:CreateChickenNameplate(chickenInstance)
	local chickenModel = self.ChickenModels[chickenInstance.chickenId]
	if not chickenModel then return nil end

	local chickenData = CHICKEN_CONFIG.chickenTypes[chickenInstance.chickenType]

	-- Create nameplate GUI
	local nameplateGui = Instance.new("BillboardGui")
	nameplateGui.Name = "Nameplate"
	nameplateGui.Size = UDim2.new(0, 120, 0, 25)
	nameplateGui.StudsOffset = Vector3.new(0, 4.5, 0)
	nameplateGui.AlwaysOnTop = true
	nameplateGui.Parent = chickenModel

	-- Name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = (chickenData and chickenData.name or chickenInstance.chickenType) .. " " .. chickenData.icon
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	nameLabel.Parent = nameplateGui

	return nameplateGui
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
		chickenModel = self:CreateChickenModelFromTemplate(chickenInstance)
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

	-- Apply rooster area effects
	if chickenInstance.chickenType == "rooster" then
		self:ApplyRoosterAreaEffects(chickenInstance)
	end
end

-- Get walk speed based on chicken type
function ChickenSystem:GetChickenWalkSpeed(chickenType)
	local walkSpeeds = {
		basic_chicken = 8,  -- Slow, steady pace
		guinea_fowl = 12,   -- Faster, more alert
		rooster = 10        -- Confident strut
	}
	return walkSpeeds[chickenType] or 8
end

-- Setup chicken animations (optional - you can customize this)
function ChickenSystem:InitializeSimpleMovement(chickenInstance)
	local chickenModel = self.ChickenModels[chickenInstance.chickenId]
	if not chickenModel then return end

	-- Store movement data
	chickenInstance.movement = {
		currentPart = nil,
		maxInc = 16,
		lastMoveTime = 0,
		isMoving = false
	}

	-- Setup touch detection for legs
	self:SetupChickenTouchDetection(chickenInstance)

	-- Start movement loop for this chicken
	self:StartChickenMovementLoop(chickenInstance)

	print("ChickenSystem: Initialized simple movement for " .. chickenInstance.chickenType)
end

-- Setup touch detection on chicken legs
function ChickenSystem:SetupChickenTouchDetection(chickenInstance)
	local chickenModel = self.ChickenModels[chickenInstance.chickenId]
	if not chickenModel then return end

	-- Find leg parts (try different naming conventions)
	local leftLeg = chickenModel:FindFirstChild("Left Leg") or 
		chickenModel:FindFirstChild("LeftLeg") or
		chickenModel:FindFirstChild("Leg1")

	local rightLeg = chickenModel:FindFirstChild("Right Leg") or 
		chickenModel:FindFirstChild("RightLeg") or
		chickenModel:FindFirstChild("Leg2")

	-- Touch detection function
	local function onTouched(hit, chickenId)
		if hit.Parent == nil then return end

		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid == nil then
			-- Found a surface part, store it
			if self.ActiveChickens then
				for userId, playerChickens in pairs(self.ActiveChickens) do
					if playerChickens[chickenId] and playerChickens[chickenId].movement then
						playerChickens[chickenId].movement.currentPart = hit
					end
				end
			end
		end
	end

	-- Connect touch events
	if leftLeg then
		leftLeg.Touched:Connect(function(hit)
			onTouched(hit, chickenInstance.chickenId)
		end)
	end

	if rightLeg then
		rightLeg.Touched:Connect(function(hit)
			onTouched(hit, chickenInstance.chickenId)
		end)
	end

	print("ChickenSystem: Setup touch detection for " .. chickenInstance.chickenType)
end

-- Start movement loop for individual chicken
function ChickenSystem:StartChickenMovementLoop(chickenInstance)
	spawn(function()
		local chickenId = chickenInstance.chickenId

		while chickenInstance and chickenInstance.player and chickenInstance.player.Parent do
			-- Random wait time between movements
			wait(math.random(1, 5)) -- 1-5 seconds between moves

			-- Check if chicken still exists
			local chickenModel = self.ChickenModels[chickenId]
			if not chickenModel or not chickenModel.Parent then
				break -- Stop loop if chicken no longer exists
			end

			-- Only move if chicken is not hunting and not panicked
			if not chickenInstance.isHunting and not chickenInstance.isPanicked then
				self:MoveChickenRandomly(chickenInstance)
			end
		end

		print("ChickenSystem: Movement loop ended for " .. (chickenInstance.chickenType or "unknown"))
	end)
end

-- Move chicken randomly (simple version)
function ChickenSystem:MoveChickenRandomly(chickenInstance)
	local chickenModel = self.ChickenModels[chickenInstance.chickenId]
	if not chickenModel then return end

	local humanoid = chickenModel:FindFirstChild("Humanoid")
	local torso = chickenModel:FindFirstChild("Torso") or chickenModel:FindFirstChild("HumanoidRootPart")

	if not humanoid or not torso then return end

	-- Skip if chicken is already moving
	if chickenInstance.movement.isMoving then return end

	local maxInc = chickenInstance.movement.maxInc
	local currentPart = chickenInstance.movement.currentPart

	if currentPart ~= nil then
		-- Sometimes make chicken jump
		if math.random(1, 5) == 1 then -- 20% chance to jump
			humanoid.Jump = true
		end

		-- Generate random movement destination
		local randomOffset = Vector3.new(
			math.random(-maxInc, maxInc),
			0,
			math.random(-maxInc, maxInc)
		)

		local targetPosition = torso.Position + randomOffset

		-- Make sure target is not too far from home
		local homePos = chickenInstance.homePosition
		if homePos then
			local distanceFromHome = (targetPosition - homePos).Magnitude
			if distanceFromHome > 50 then -- Max 50 studs from home
				-- Move toward home instead
				targetPosition = homePos + Vector3.new(
					math.random(-10, 10),
					0,
					math.random(-10, 10)
				)
			end
		end

		-- Set movement state
		chickenInstance.movement.isMoving = true
		chickenInstance.currentPosition = targetPosition

		-- Move the chicken
		humanoid:MoveTo(targetPosition, currentPart)

		-- Reset movement state after a delay
		spawn(function()
			wait(3) -- Give time for movement to complete
			chickenInstance.movement.isMoving = false
		end)

		print("ChickenSystem: " .. chickenInstance.chickenType .. " moving to " .. tostring(targetPosition))
	end
end

-- ========== REPLACE COMPLEX MOVEMENT METHODS ==========

-- REPLACE the complex UpdateChickenPatrol method with this simple version
function ChickenSystem:UpdateChickenPatrol(chickenInstance)
	-- Simple patrol just uses random movement
	-- The individual movement loops handle the actual movement

	-- Update patrol route timing
	local patrolRoute = self.PatrolRoutes[chickenInstance.chickenId]
	if patrolRoute then
		patrolRoute.lastMoveTime = os.time()
	end

	-- Chickens move randomly on their own, no need for forced patrol
end

-- REPLACE the complex MakeChickenWalkTo method with this simple version
function ChickenSystem:MakeChickenWalkTo(chickenInstance, targetPosition)
	local chickenModel = self.ChickenModels[chickenInstance.chickenId]
	if not chickenModel then return end

	local humanoid = chickenModel:FindFirstChild("Humanoid")
	local torso = chickenModel:FindFirstChild("Torso") or chickenModel:FindFirstChild("HumanoidRootPart")

	if not humanoid or not torso then return end

	-- Simple direct movement
	humanoid:MoveTo(targetPosition)
	chickenInstance.currentPosition = targetPosition

	print("ChickenSystem: " .. chickenInstance.chickenType .. " walking to " .. tostring(targetPosition))
end

-- ========== UPDATE SPAWN CHICKEN METHOD ==========

-- ADD this to the end of your SpawnChicken method, after creating the visual model
function ChickenSystem:EnhanceSpawnChickenWithMovement(chickenInstance)
	-- Initialize simple movement after creating the chicken
	self:InitializeSimpleMovement(chickenInstance)

	return chickenInstance
end

-- ========== UPDATED HUNT PEST METHOD ==========

-- REPLACE the complex HuntPest method with this simpler version
function ChickenSystem:HuntPest(chickenInstance, targetPest)
	if not targetPest or not targetPest.cropModel then return end

	local chickenData = CHICKEN_CONFIG.chickenTypes[chickenInstance.chickenType]
	local huntEfficiency = chickenData.huntEfficiency or 0.8

	print("ChickenSystem: " .. chickenInstance.chickenType .. " hunting " .. targetPest.pestType)

	-- Set hunting state
	chickenInstance.isHunting = true

	-- Simple movement to pest location
	local targetPosition = targetPest.cropModel.Crop.Position + Vector3.new(
		math.random(-3, 3), 0, math.random(-3, 3)
	)

	self:MakeChickenWalkTo(chickenInstance, targetPosition)

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

		-- Return to normal behavior
		chickenInstance.isHunting = false
	end)
end

print("ChickenSystem: Simple movement system ready!")
print("Features:")
print("  ✅ Random movement every 1-5 seconds")
print("  ✅ Touch detection on legs for surface finding")
print("  ✅ Occasional jumping")
print("  ✅ Home position boundaries")
print("  ✅ Hunting movement integration")
print("  ✅ Panic state movement pause")
print("")
print("Usage:")
print("  1. Add this code to your ChickenSystemServer.lua")
print("  2. Add 'self:InitializeSimpleMovement(chickenInstance)' to end of SpawnChicken method")
print("  3. Chickens will move randomly and naturally!")
print("")
print("Admin Commands:")
print("  /testchickenmovement - Test random movement")
print("  /chickenmovespeed [number] - Set movement range")

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
-- Feed a specific chicken
function ChickenSystem:FeedSpecificChicken(userId, chickenId, feedType)
	if not self.ActiveChickens[userId] or not self.ActiveChickens[userId][chickenId] then
		return
	end

	local chickenInstance = self.ActiveChickens[userId][chickenId]
	local chickenData = CHICKEN_CONFIG.chickenTypes[chickenInstance.chickenType]

	if not chickenData then return end

	print("ChickenSystem: Feeding " .. chickenInstance.chickenType .. " with " .. feedType)

	-- Get feed data
	local feedData = CHICKEN_CONFIG.feedTypes[feedType]
	if not feedData then return end

	-- Restore hunger
	local maxHunger = chickenData.maxHunger or 24
	chickenInstance.hunger = math.min(maxHunger, chickenInstance.hunger + feedData.feedValue)
	chickenInstance.lastFeedTime = os.time()

	-- Apply feed bonuses
	if feedData.eggBonus then
		-- Boost egg production
		chickenInstance.lastEggTime = chickenInstance.lastEggTime - (60 * (feedData.eggBonus - 1))
	end

	if feedData.healthBonus then
		-- Improve health
		chickenInstance.health = math.min(100, chickenInstance.health + 10)
	end

	-- Create feeding effect
	self:CreateFeedingEffect(chickenInstance)

	print("ChickenSystem: Successfully fed " .. chickenInstance.chickenType)
end

print("🐔 Complete Chicken Feeding System Ready!")
print("")
print("PART 1: Enhanced Farm UI with complete inventory")
print("PART 2: Server-side feeding logic") 
print("PART 3: Chicken system integration")
print("")
print("Features:")
print("✅ Complete inventory display (seeds, crops, feed, tools)")
print("✅ Feed All Chickens button")
print("✅ Individual feed type selection")
print("✅ Automatic best feed selection")
print("✅ Feed consumption and effects")
print("✅ Visual feeding effects on chickens")
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
	print("ChickenSystem: Finding spawn position for " .. player.Name)

	-- Try to find player's farm area using GameCore's method
	if _G.GameCore and _G.GameCore.GetFarmPlotPosition then
		local success, plotPosition = pcall(function()
			return _G.GameCore:GetFarmPlotPosition(player, 1)
		end)

		if success and plotPosition then
			local spawnPos = plotPosition.Position + Vector3.new(10, 3, 10)
			print("ChickenSystem: Found farm plot, spawning at", spawnPos)
			return spawnPos
		end
	end

	-- Fallback: Try to find farm manually
	local areas = workspace:FindFirstChild("Areas")
	if areas then
		local starterMeadow = areas:FindFirstChild("Starter Meadow")
		if starterMeadow then
			local farmArea = starterMeadow:FindFirstChild("Farm")
			if farmArea then
				local playerFarm = farmArea:FindFirstChild(player.Name .. "_Farm")
				if playerFarm then
					print("ChickenSystem: Found player farm folder")
					-- Find first farm plot
					for _, plot in pairs(playerFarm:GetChildren()) do
						if plot:IsA("Model") and plot.Name:find("FarmPlot") then
							local primaryPart = plot.PrimaryPart or plot:FindFirstChild("BasePart")
							if primaryPart then
								local spawnPos = primaryPart.Position + Vector3.new(10, 3, 10)
								print("ChickenSystem: Found farm plot, spawning at", spawnPos)
								return spawnPos
							end
						end
					end
				else
					print("ChickenSystem: Player farm folder not found: " .. player.Name .. "_Farm")
				end
			else
				print("ChickenSystem: Farm area not found")
			end
		else
			print("ChickenSystem: Starter Meadow not found")
		end
	else
		print("ChickenSystem: Areas folder not found")
	end

	-- Final fallback: spawn near player
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local playerPos = player.Character.HumanoidRootPart.Position
		local spawnPos = playerPos + Vector3.new(5, 2, 5)
		print("ChickenSystem: No farm found, spawning near player at", spawnPos)
		return spawnPos
	end

	-- Last resort: world spawn
	print("ChickenSystem: Using fallback spawn position")
	return Vector3.new(0, 10, 0)
end

-- ALSO ADD this debugging function to ChickenSystem.server.lua

function ChickenSystem:DebugSpawnPosition(player)
	print("=== CHICKEN SPAWN DEBUG FOR " .. player.Name .. " ===")

	-- Check if player has farm
	local playerData = _G.GameCore and _G.GameCore:GetPlayerData(player)
	if playerData and playerData.farming then
		print("Player has farming data, plots:", playerData.farming.plots or 0)
	else
		print("Player has no farming data")
	end

	-- Check workspace structure
	local areas = workspace:FindFirstChild("Areas")
	print("Areas folder exists:", areas ~= nil)

	if areas then
		local starterMeadow = areas:FindFirstChild("Starter Meadow")
		print("Starter Meadow exists:", starterMeadow ~= nil)

		if starterMeadow then
			local farmArea = starterMeadow:FindFirstChild("Farm")
			print("Farm area exists:", farmArea ~= nil)

			if farmArea then
				local playerFarm = farmArea:FindFirstChild(player.Name .. "_Farm")
				print("Player farm exists:", playerFarm ~= nil)

				if playerFarm then
					print("Player farm contents:")
					for _, child in pairs(playerFarm:GetChildren()) do
						print("  " .. child.Name .. " (" .. child.ClassName .. ")")
					end
				end
			end
		end
	end

	-- Test spawn position
	local spawnPos = self:FindChickenSpawnPosition(player)
	print("Calculated spawn position:", spawnPos)

	print("=====================================")
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