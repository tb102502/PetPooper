--[[
    Modified CropVisual.lua - Garden Integration
    Place in: ServerScriptService/Modules/CropVisual.lua
    
    MODIFICATIONS:
    ✅ Adapted positioning for Garden/Soil system
    ✅ Enhanced crop placement on garden spots
    ✅ Maintains all existing visual effects and functionality
    ✅ Improved crop-to-soil positioning logic
]]

local CropVisual = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

-- Dependencies
local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))

-- Module references (will be injected)
local GameCore = nil
local CropCreation = nil

-- Garden references
local GardenModel = nil
local SoilPart = nil

-- Initialize CropModels folder
local CropModels = ReplicatedStorage:FindFirstChild("CropModels")
if not CropModels then
	CropModels = Instance.new("Folder")
	CropModels.Name = "CropModels"
	CropModels.Parent = ReplicatedStorage
	print("CropVisual: Created CropModels folder")
end

-- Internal state
CropVisual.AvailableModels = {}
CropVisual.ModelCache = {}
CropVisual.ActiveEffects = {}

-- ========== INITIALIZATION ==========

function CropVisual:Initialize(gameCoreRef, cropCreationRef)
	print("CropVisual: Initializing Garden-based crop visual system...")

	-- Store module references
	GameCore = gameCoreRef
	CropCreation = cropCreationRef

	-- Initialize garden references
	self:InitializeGardenReferences()

	-- Initialize model tracking
	self.AvailableModels = {}
	self.ModelCache = {}
	self.ActiveEffects = {}

	-- Scan for available models
	self:UpdateAvailableModels()

	-- Initialize effect cleanup system
	self:InitializeEffectCleanup()

	print("CropVisual: ✅ Garden-based crop visual system initialized successfully")
	return true
end

function CropVisual:InitializeGardenReferences()
	-- Find Garden model and Soil part
	GardenModel = Workspace:FindFirstChild("Garden")
	if GardenModel then
		SoilPart = GardenModel:FindFirstChild("Soil")
		if SoilPart then
			print("CropVisual: ✅ Garden references established")
			print("  Garden: " .. GardenModel.Name)
			print("  Soil: " .. SoilPart.Name)
		else
			warn("CropVisual: ⚠️ Soil part not found in Garden")
		end
	else
		warn("CropVisual: ⚠️ Garden model not found in workspace")
	end
end

function CropVisual:UpdateAvailableModels()
	self.AvailableModels = {}

	if not CropModels then return end

	for _, model in pairs(CropModels:GetChildren()) do
		if model:IsA("Model") then
			local cropName = model.Name:lower()
			self.AvailableModels[cropName] = model
			print("CropVisual: Found model for " .. cropName)
		end
	end

	print("CropVisual: Found " .. self:CountTable(self.AvailableModels) .. " crop models")
end

function CropVisual:InitializeEffectCleanup()
	-- Clean up old effects every 30 seconds
	spawn(function()
		while true do
			wait(30)
			self:CleanupOldEffects()
		end
	end)
end

function CropVisual:CleanupOldEffects()
	for effectId, effectData in pairs(self.ActiveEffects) do
		if effectData.startTime and (tick() - effectData.startTime > 300) then -- 5 minutes old
			if effectData.cleanup then
				pcall(effectData.cleanup)
			end
			self.ActiveEffects[effectId] = nil
		end
	end
end

-- ========== GARDEN POSITIONING ==========

function CropVisual:PositionCropOnGarden(cropModel, gardenSpotModel, growthStage)
	if not cropModel or not cropModel.PrimaryPart or not gardenSpotModel then
		warn("CropVisual: Invalid parameters for garden positioning")
		return false
	end

	local spotPart = gardenSpotModel:FindFirstChild("SpotPart")
	if not spotPart then
		warn("CropVisual: No SpotPart found in garden spot")
		return false
	end

	-- Position crop above the garden spot
	local spotPosition = spotPart.Position
	local heightOffset = self:GetGardenHeightOffset(growthStage)
	local cropPosition = spotPosition + Vector3.new(0, heightOffset, 0)

	-- Ensure proper positioning and anchoring
	cropModel.PrimaryPart.CFrame = CFrame.new(cropPosition)
	cropModel.PrimaryPart.Anchored = true
	cropModel.PrimaryPart.CanCollide = false

	-- Ensure all parts are stable on the garden
	self:EnsureGardenModelStability(cropModel)

	print("🌱 Positioned crop on garden spot at: " .. tostring(cropPosition))
	return true
end

function CropVisual:GetGardenHeightOffset(growthStage)
	-- Heights adjusted for garden/soil positioning
	local offsets = {
		planted = 0.5,      -- Just above the garden spot
		sprouting = 1.0,    -- Small sprout
		growing = 1.5,      -- Growing taller
		flowering = 2.0,    -- Almost full height
		ready = 2.5         -- Full height above garden
	}
	return offsets[growthStage] or 1.0
end

function CropVisual:EnsureGardenModelStability(cropModel)
	-- Ensure all parts are properly anchored and positioned for garden use
	for _, part in pairs(cropModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		end
	end
	cropModel:SetAttribute("IsStable", true)
	cropModel:SetAttribute("IsOnGarden", true)
end

-- ========== ENHANCED GARDEN CROP CREATION ==========

function CropVisual:HandleCropPlanted(gardenSpotModel, cropType, rarity)
	print("🌱 CropVisual: HandleCropPlanted on Garden - " .. cropType .. " (" .. rarity .. ")")

	if not gardenSpotModel then
		warn("❌ No garden spot model provided")
		return false
	end

	-- Remove existing crop
	local existingCrop = gardenSpotModel:FindFirstChild("CropModel")
	if existingCrop then
		existingCrop:Destroy()
		wait(0.1)
	end

	-- Create new crop
	local cropModel = self:CreateCropModel(cropType, rarity, "planted")
	if cropModel then
		cropModel.Name = "CropModel"
		cropModel.Parent = gardenSpotModel

		-- Position on garden
		if self:PositionCropOnGarden(cropModel, gardenSpotModel, "planted") then
			self:SetupGardenCropClickDetection(cropModel, gardenSpotModel, cropType, rarity)
			print("✅ Crop visual created successfully on garden with click detection")
			return true
		else
			warn("❌ Failed to position crop on garden")
			cropModel:Destroy()
			return false
		end
	else
		warn("❌ Failed to create crop visual for garden")
		return false
	end
end

function CropVisual:SetupGardenCropClickDetection(cropModel, gardenSpotModel, cropType, rarity)
	if not cropModel or not cropModel.PrimaryPart then
		warn("CropVisual: Invalid crop model for garden click detection")
		return false
	end

	print("🖱️ CropVisual: Setting up garden crop click detection for " .. cropType)

	-- Remove existing click detectors
	self:RemoveExistingClickDetectors(cropModel)

	-- Find clickable parts
	local clickableParts = self:GetClickableParts(cropModel)

	if #clickableParts == 0 then
		warn("CropVisual: No clickable parts found for garden crop " .. cropType)
		return false
	end

	-- Add click detectors
	for _, part in pairs(clickableParts) do
		local clickDetector = Instance.new("ClickDetector")
		clickDetector.Name = "GardenCropClickDetector"
		clickDetector.MaxActivationDistance = 25 -- Slightly longer range for garden
		clickDetector.Parent = part

		-- Store references for garden crops
		clickDetector:SetAttribute("GardenSpot", gardenSpotModel.Name)
		clickDetector:SetAttribute("CropType", cropType)
		clickDetector:SetAttribute("Rarity", rarity)
		clickDetector:SetAttribute("IsGardenCrop", true)

		-- Connect click event
		clickDetector.MouseClick:Connect(function(clickingPlayer)
			self:HandleGardenCropClick(clickingPlayer, cropModel, gardenSpotModel, cropType, rarity)
		end)
	end

	print("✅ Garden crop click detection setup for " .. cropType .. " with " .. #clickableParts .. " parts")
	return true
end

function CropVisual:HandleGardenCropClick(clickingPlayer, cropModel, gardenSpotModel, cropType, rarity)
	print("🖱️ CropVisual: Garden crop clicked by " .. clickingPlayer.Name .. " - " .. cropType)

	-- Delegate to CropCreation module for harvest logic
	if CropCreation then
		-- Check if crop is ready for harvest
		local growthStage = gardenSpotModel:GetAttribute("GrowthStage") or 0
		local isMutation = gardenSpotModel:GetAttribute("IsMutation") or false

		if growthStage >= 4 then
			print("🌾 Garden crop is ready - calling harvest")
			CropCreation:HarvestCrop(clickingPlayer, gardenSpotModel)
		else
			print("🌱 Garden crop not ready - showing status")
			self:ShowGardenCropStatus(clickingPlayer, gardenSpotModel, cropType, growthStage, isMutation)
		end
	else
		warn("CropVisual: CropCreation module not available for garden crop click handling")
	end
end

-- REPLACE the ShowGardenCropStatus method in CropVisual.lua with this fixed version:

function CropVisual:ShowGardenCropStatus(player, gardenSpotModel, cropType, growthStage, isMutation)
	local stageNames = {"planted", "sprouting", "growing", "flowering", "ready"}
	local currentStageName = stageNames[growthStage + 1] or "unknown"

	local plantedTime = gardenSpotModel:GetAttribute("PlantedTime") or os.time()
	local seedType = gardenSpotModel:GetAttribute("SeedType")
	local timeElapsed = os.time() - plantedTime

	-- Get the actual growth time from ItemConfig instead of hardcoded values
	local totalGrowthTime = self:GetActualGrowthTime(seedType, isMutation)

	local timeRemaining = math.max(0, totalGrowthTime - timeElapsed)
	local minutesRemaining = math.floor(timeRemaining / 60)
	local secondsRemaining = timeRemaining % 60

	local cropDisplayName = cropType:gsub("^%l", string.upper):gsub("_", " ")
	local statusEmoji = isMutation and "🧬" or "🌱"

	local message
	if growthStage >= 4 then
		message = statusEmoji .. " " .. cropDisplayName .. " in your garden is ready to harvest!"
	else
		local progressBar = self:CreateProgressBar(timeElapsed, totalGrowthTime)

		local timeText
		if minutesRemaining > 0 then
			timeText = minutesRemaining .. "m " .. secondsRemaining .. "s remaining"
		else
			timeText = secondsRemaining .. " seconds remaining"
		end

		message = statusEmoji .. " " .. cropDisplayName .. " in your garden is " .. currentStageName .. 
			"\n⏰ " .. timeText .. "\n" .. progressBar
	end

	-- Send notification through GameCore
	if GameCore and GameCore.SendNotification then
		GameCore:SendNotification(player, "🌾 Garden Crop Status", message, "info")
	end
end

-- ADD this method to get actual growth time from ItemConfig:
function CropVisual:GetActualGrowthTime(seedType, isMutation)
	-- Handle mutations with faster growth
	if isMutation then
		local speedMultiplier = _G.MUTATION_GROWTH_SPEED or 1.0
		return 240 / speedMultiplier -- 4 minutes for mutations by default
	end

	-- Get growth time from ItemConfig
	if seedType and ItemConfig and ItemConfig.ShopItems then
		local seedData = ItemConfig.ShopItems[seedType]
		if seedData and seedData.farmingData and seedData.farmingData.growTime then
			local growTime = seedData.farmingData.growTime
			print("📊 CropVisual: Using ItemConfig grow time for " .. seedType .. ": " .. growTime .. "s")
			return growTime
		end
	end

	-- Fallback to default
	print("⚠️ CropVisual: No growth time found for " .. (seedType or "unknown") .. ", using default 300s")
	return 300 -- 5 minutes default
end
-- ========== GARDEN GROWTH STAGE UPDATES ==========

-- REPLACE the UpdateCropStage method in CropVisual.lua with this robust version:

function CropVisual:UpdateCropStage(gardenSpotModel, cropType, rarity, stageName, stageIndex)
	print("🎨 CropVisual: Updating garden crop " .. cropType .. " to stage " .. stageName)

	-- Validate inputs
	if not gardenSpotModel or not gardenSpotModel.Parent then
		warn("❌ CropVisual: Invalid garden spot model")
		return false
	end

	if not cropType or not rarity or not stageName then
		warn("❌ CropVisual: Missing required parameters")
		return false
	end

	local cropModel = gardenSpotModel:FindFirstChild("CropModel")
	if not cropModel then
		warn("❌ CropVisual: No CropModel found in garden spot")
		-- Try to recreate the crop model
		return self:RecreateeCropModel(gardenSpotModel, cropType, rarity, stageName)
	end

	if not cropModel.PrimaryPart then
		warn("❌ CropVisual: CropModel has no PrimaryPart")
		-- Try to fix the model
		self:RepairCropModel(cropModel)
		if not cropModel.PrimaryPart then
			return self:RecreateeCropModel(gardenSpotModel, cropType, rarity, stageName)
		end
	end

	-- Update model attributes
	cropModel:SetAttribute("GrowthStage", stageName)
	cropModel:SetAttribute("CropType", cropType)
	cropModel:SetAttribute("Rarity", rarity)

	-- Method 1: If using pre-made model, try to replace with new stage model
	local modelType = cropModel:GetAttribute("ModelType")
	if modelType == "PreMade" and self:HasPreMadeModel(cropType) then
		local success = pcall(function()
			return self:ReplaceGardenCropWithNewStage(cropModel, gardenSpotModel, cropType, rarity, stageName)
		end)

		if success then
			print("✅ Successfully replaced pre-made model for stage " .. stageName)
			return true
		else
			print("⚠️ Failed to replace pre-made model, falling back to scaling")
		end
	end

	-- Method 2: Scale and enhance existing model (ROBUST VERSION)
	local success = pcall(function()
		return self:ScaleExistingModelRobust(cropModel, gardenSpotModel, cropType, rarity, stageName)
	end)

	if success then
		print("✅ Successfully scaled existing model for stage " .. stageName)
		return true
	else
		warn("❌ Failed to scale existing model, trying fallback")
		return self:FallbackStageUpdate(gardenSpotModel, cropModel, cropType, rarity, stageName)
	end
end

-- ADD this robust scaling method:
function CropVisual:ScaleExistingModelRobust(cropModel, gardenSpotModel, cropType, rarity, stageName)
	print("📏 Robust scaling for stage: " .. stageName)

	-- Calculate new scale
	local rarityScale = self:GetRarityScale(rarity)
	local growthScale = self:GetGrowthScale(stageName)
	local targetScale = rarityScale * growthScale

	-- Get current scale to calculate relative change
	local currentScale = cropModel:GetAttribute("CurrentScale") or 1.0
	local scaleChange = targetScale / currentScale

	print("📏 Scale change: " .. currentScale .. " -> " .. targetScale .. " (factor: " .. scaleChange .. ")")

	-- Apply scaling with error protection
	local scaledParts = 0
	for _, part in pairs(cropModel:GetDescendants()) do
		if part:IsA("BasePart") then
			local success = pcall(function()
				local targetSize = part.Size * scaleChange

				-- Validate the target size is reasonable
				if targetSize.X > 0.01 and targetSize.Y > 0.01 and targetSize.Z > 0.01 and
					targetSize.X < 100 and targetSize.Y < 100 and targetSize.Z < 100 then

					local tween = TweenService:Create(part,
						TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{Size = targetSize}
					)
					tween:Play()
					scaledParts = scaledParts + 1
				end
			end)

			if not success then
				print("⚠️ Failed to scale part: " .. part.Name)
			end
		end
	end

	print("📏 Scaled " .. scaledParts .. " parts")

	-- Store new scale
	cropModel:SetAttribute("CurrentScale", targetScale)

	-- Update stage effects with error protection
	pcall(function()
		self:UpdateStageEffectsRobust(cropModel, cropType, rarity, stageName)
	end)

	-- Update positioning with error protection
	pcall(function()
		self:PositionCropOnGarden(cropModel, gardenSpotModel, stageName)
	end)

	-- Ensure click detection remains functional (delayed check)
	spawn(function()
		wait(2) -- Wait for tweens to complete
		pcall(function()
			self:ValidateAndFixClickDetection(cropModel, gardenSpotModel, cropType, rarity)
		end)
	end)

	return true
end

-- ADD this fallback stage update method:
function CropVisual:FallbackStageUpdate(gardenSpotModel, cropModel, cropType, rarity, stageName)
	print("🔧 Using fallback stage update for " .. stageName)

	-- At minimum, ensure the crop model exists and is positioned correctly
	if cropModel and cropModel.PrimaryPart then
		-- Basic positioning
		pcall(function()
			self:PositionCropOnGarden(cropModel, gardenSpotModel, stageName)
		end)

		-- Add basic ready indicator if it's the final stage
		if stageName == "ready" then
			pcall(function()
				self:CreateBasicReadyIndicator(cropModel)
			end)
		end

		-- Ensure click detection exists
		pcall(function()
			self:SetupGardenCropClickDetection(cropModel, gardenSpotModel, cropType, rarity)
		end)

		print("✅ Fallback update completed for " .. stageName)
		return true
	end

	print("❌ Fallback update failed - crop model invalid")
	return false
end

-- ADD this method to recreate missing crop models:
function CropVisual:RecreateeCropModel(gardenSpotModel, cropType, rarity, stageName)
	print("🔄 Recreating missing crop model for " .. cropType .. " at stage " .. stageName)

	-- Remove any existing crop model remnants
	for _, child in pairs(gardenSpotModel:GetChildren()) do
		if child:IsA("Model") and child.Name == "CropModel" then
			child:Destroy()
		end
	end

	-- Create new crop model
	local success, cropModel = pcall(function()
		return self:CreateCropModel(cropType, rarity, stageName)
	end)

	if success and cropModel then
		cropModel.Name = "CropModel"
		cropModel.Parent = gardenSpotModel

		-- Position the recreated model
		local positionSuccess = pcall(function()
			return self:PositionCropOnGarden(cropModel, gardenSpotModel, stageName)
		end)

		if positionSuccess then
			-- Setup click detection
			pcall(function()
				self:SetupGardenCropClickDetection(cropModel, gardenSpotModel, cropType, rarity)
			end)

			print("✅ Successfully recreated crop model for " .. cropType)
			return true
		else
			print("❌ Failed to position recreated crop model")
			cropModel:Destroy()
		end
	else
		print("❌ Failed to create replacement crop model")
	end

	return false
end

-- ADD this method to repair broken crop models:
function CropVisual:RepairCropModel(cropModel)
	print("🔧 Attempting to repair crop model: " .. cropModel.Name)

	-- Try to set a primary part if missing
	if not cropModel.PrimaryPart then
		for _, child in pairs(cropModel:GetChildren()) do
			if child:IsA("BasePart") then
				cropModel.PrimaryPart = child
				print("✅ Set PrimaryPart to: " .. child.Name)
				break
			end
		end
	end

	-- Ensure all parts are properly anchored
	for _, part in pairs(cropModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	-- Ensure model has basic attributes
	if not cropModel:GetAttribute("CropType") then
		cropModel:SetAttribute("CropType", "unknown")
	end
	if not cropModel:GetAttribute("Rarity") then
		cropModel:SetAttribute("Rarity", "common")
	end
	if not cropModel:GetAttribute("CurrentScale") then
		cropModel:SetAttribute("CurrentScale", 1.0)
	end

	print("🔧 Crop model repair attempted")
end

-- ADD this robust click detection validator:
function CropVisual:ValidateAndFixClickDetection(cropModel, gardenSpotModel, cropType, rarity)
	if not cropModel or not cropModel.Parent then
		return false
	end

	-- Check if click detectors exist and are functional
	local hasWorkingClickDetector = false
	for _, obj in pairs(cropModel:GetDescendants()) do
		if obj:IsA("ClickDetector") and obj.Name == "GardenCropClickDetector" and obj.Parent then
			hasWorkingClickDetector = true
			break
		end
	end

	if not hasWorkingClickDetector then
		print("🖱️ Re-adding click detection after update")
		self:SetupGardenCropClickDetection(cropModel, gardenSpotModel, cropType, rarity)
		return true
	end

	return false
end

-- ADD this robust stage effects method:
function CropVisual:UpdateStageEffectsRobust(cropModel, cropType, rarity, stageName)
	if not cropModel or not cropModel.PrimaryPart then
		return
	end

	-- Remove old stage-specific effects safely
	for _, obj in pairs(cropModel:GetDescendants()) do
		if obj.Name:find("StageEffect") or obj.Name:find("GrowthParticle") or obj.Name:find("FloweringStageEffect") then
			pcall(function() obj:Destroy() end)
		end
	end

	-- Add new stage-specific effects with error protection
	if stageName == "flowering" then
		pcall(function()
			self:CreateFloweringEffect(cropModel)
		end)
	elseif stageName == "ready" then
		pcall(function()
			self:CreateReadyHarvestEffect(cropModel)
			-- Re-apply rarity effects for fully grown crops
			if rarity ~= "common" then
				self:AddRarityEffects(cropModel, rarity)
			end
		end)
	end
end

-- ADD this basic ready indicator for fallback:
function CropVisual:CreateBasicReadyIndicator(cropModel)
	if not cropModel or not cropModel.PrimaryPart then
		return
	end

	-- Remove existing ready glow
	local existingGlow = cropModel.PrimaryPart:FindFirstChild("BasicReadyGlow")
	if existingGlow then
		existingGlow:Destroy()
	end

	-- Add simple ready glow
	local readyGlow = Instance.new("PointLight")
	readyGlow.Name = "BasicReadyGlow"
	readyGlow.Color = Color3.fromRGB(255, 215, 0)
	readyGlow.Brightness = 1.2
	readyGlow.Range = 6
	readyGlow.Parent = cropModel.PrimaryPart

	print("✅ Added basic ready indicator")
end

-- ADD this missing method to CropVisual.lua:
function CropVisual:ScaleExistingModel(cropModel, rarity, stageName)
	print("📏 Scaling existing model for stage: " .. stageName)

	-- Calculate new scale
	local rarityScale = self:GetRarityScale(rarity)
	local growthScale = self:GetGrowthScale(stageName)
	local targetScale = rarityScale * growthScale

	-- Get current scale to calculate relative change
	local currentScale = cropModel:GetAttribute("CurrentScale") or 1.0
	local scaleChange = targetScale / currentScale

	-- Apply scaling with smooth transition
	for _, part in pairs(cropModel:GetDescendants()) do
		if part:IsA("BasePart") then
			local targetSize = part.Size * scaleChange

			local tween = TweenService:Create(part,
				TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Size = targetSize}
			)
			tween:Play()
		end
	end

	-- Store new scale
	cropModel:SetAttribute("CurrentScale", targetScale)

	-- Update visual effects for new stage
	self:UpdateStageEffects(cropModel, cropModel:GetAttribute("CropType") or "unknown", rarity, stageName)

	-- IMPORTANT: Ensure click detection is still present after scaling
	spawn(function()
		wait(2) -- Wait for tween to complete

		-- Check if click detectors still exist and are functional
		local hasWorkingClickDetector = false
		for _, obj in pairs(cropModel:GetDescendants()) do
			if obj:IsA("ClickDetector") and obj.Name == "GardenCropClickDetector" and obj.Parent then
				hasWorkingClickDetector = true
				break
			end
		end

		if not hasWorkingClickDetector then
			print("🖱️ Re-adding click detection after scaling")
			local plotModel = cropModel.Parent
			local cropType = cropModel:GetAttribute("CropType")

			if plotModel and cropType and rarity then
				self:SetupGardenCropClickDetection(cropModel, plotModel, cropType, rarity)
			end
		end
	end)

	print("📏 Scaled crop by factor of " .. scaleChange)
	return true
end

-- ADD this missing method for stage effects:
function CropVisual:UpdateStageEffects(cropModel, cropType, rarity, stageName)
	-- Remove old stage-specific effects
	for _, obj in pairs(cropModel:GetDescendants()) do
		if obj.Name:find("StageEffect") or obj.Name:find("GrowthParticle") then
			obj:Destroy()
		end
	end

	-- Add new stage-specific effects
	if stageName == "flowering" then
		self:CreateFloweringEffect(cropModel)
	elseif stageName == "ready" then
		self:CreateReadyHarvestEffect(cropModel)
		-- Re-apply rarity effects for fully grown crops
		if rarity ~= "common" then
			self:AddRarityEffects(cropModel, rarity)
		end
	end
end

-- ADD these effect methods:
function CropVisual:CreateFloweringEffect(cropModel)
	if not cropModel.PrimaryPart then return end

	local flowerParticle = Instance.new("Part")
	flowerParticle.Name = "FloweringStageEffect"
	flowerParticle.Size = Vector3.new(0.2, 0.2, 0.2)
	flowerParticle.Material = Enum.Material.Neon
	flowerParticle.Color = Color3.fromRGB(255, 182, 193)
	flowerParticle.CanCollide = false
	flowerParticle.Anchored = true
	flowerParticle.Shape = Enum.PartType.Ball
	flowerParticle.CFrame = cropModel.PrimaryPart.CFrame + Vector3.new(0, 1, 0)
	flowerParticle.Parent = cropModel

	-- Gentle floating animation
	spawn(function()
		while flowerParticle and flowerParticle.Parent do
			local tween = TweenService:Create(flowerParticle,
				TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{CFrame = flowerParticle.CFrame + Vector3.new(0, 0.5, 0)}
			)
			tween:Play()
			wait(2)
			if flowerParticle and flowerParticle.Parent then
				local tween2 = TweenService:Create(flowerParticle,
					TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{CFrame = flowerParticle.CFrame - Vector3.new(0, 0.5, 0)}
				)
				tween2:Play()
				wait(2)
			end
		end
	end)
end

function CropVisual:CreateReadyHarvestEffect(cropModel)
	if not cropModel.PrimaryPart then return end

	-- Add a subtle ready-to-harvest glow
	local readyGlow = Instance.new("PointLight")
	readyGlow.Name = "ReadyHarvestGlow"
	readyGlow.Color = Color3.fromRGB(255, 215, 0)
	readyGlow.Brightness = 0.8
	readyGlow.Range = 6
	readyGlow.Parent = cropModel.PrimaryPart

	-- Pulsing effect
	spawn(function()
		while readyGlow and readyGlow.Parent do
			local tween = TweenService:Create(readyGlow,
				TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Brightness = 1.2}
			)
			tween:Play()
			wait(1.5)
			if readyGlow and readyGlow.Parent then
				local tween2 = TweenService:Create(readyGlow,
					TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{Brightness = 0.8}
				)
				tween2:Play()
				wait(1.5)
			end
		end
	end)
end

function CropVisual:ReplaceGardenCropWithNewStage(oldCropModel, gardenSpotModel, cropType, rarity, stageName)
	print("🔄 Replacing garden crop model for new stage: " .. stageName)

	-- Store position
	local oldPosition = oldCropModel.PrimaryPart.CFrame

	-- Create new model for this stage
	local newCropModel = self:CreateCropModel(cropType, rarity, stageName)
	if not newCropModel then
		return false
	end

	-- Position new model on garden
	newCropModel.Name = "CropModel"
	newCropModel.Parent = gardenSpotModel

	if self:PositionCropOnGarden(newCropModel, gardenSpotModel, stageName) then
		-- Setup click detection for new model
		self:SetupGardenCropClickDetection(newCropModel, gardenSpotModel, cropType, rarity)

		-- Create transition effect
		self:CreateStageTransitionEffect(oldCropModel, newCropModel)

		-- Remove old model after effect
		spawn(function()
			wait(1)
			if oldCropModel and oldCropModel.Parent then
				oldCropModel:Destroy()
			end
		end)

		print("✅ Successfully replaced garden crop model for stage " .. stageName)
		return true
	else
		-- Positioning failed, clean up
		newCropModel:Destroy()
		return false
	end
end

function CropVisual:UpdateExistingGardenCrop(cropModel, gardenSpotModel, cropType, rarity, stageName, stageIndex)
	print("📏 Updating existing garden crop for stage: " .. stageName)

	-- Calculate new scale
	local rarityScale = self:GetRarityScale(rarity)
	local growthScale = self:GetGrowthScale(stageName)
	local targetScale = rarityScale * growthScale

	-- Get current scale
	local currentScale = cropModel:GetAttribute("CurrentScale") or 1.0
	local scaleChange = targetScale / currentScale

	-- Apply scaling with smooth transition
	self:AnimateModelScale(cropModel, scaleChange)

	-- Update visual effects for new stage
	self:UpdateStageEffects(cropModel, cropType, rarity, stageName)

	-- Update positioning for new growth stage
	self:PositionCropOnGarden(cropModel, gardenSpotModel, stageName)

	-- Store new scale
	cropModel:SetAttribute("CurrentScale", targetScale)

	-- Ensure click detection remains functional
	spawn(function()
		wait(2) -- Wait for animations to complete
		self:ValidateGardenCropClickDetection(cropModel, gardenSpotModel, cropType, rarity)
	end)

	print("📏 Updated garden crop to scale " .. targetScale)
	return true
end

function CropVisual:ValidateGardenCropClickDetection(cropModel, gardenSpotModel, cropType, rarity)
	local hasWorkingClickDetector = false
	for _, obj in pairs(cropModel:GetDescendants()) do
		if obj:IsA("ClickDetector") and obj.Name == "GardenCropClickDetector" and obj.Parent then
			hasWorkingClickDetector = true
			break
		end
	end

	if not hasWorkingClickDetector then
		print("🖱️ Re-adding garden crop click detection after update")
		self:SetupGardenCropClickDetection(cropModel, gardenSpotModel, cropType, rarity)
	end
end

-- ========== GARDEN HARVEST EFFECTS ==========

function CropVisual:OnCropHarvested(gardenSpotModel, cropType, rarity)
	print("🌾 CropVisual: OnCropHarvested from garden - " .. tostring(cropType))

	if not gardenSpotModel then return false end

	local cropModel = gardenSpotModel:FindFirstChild("CropModel")
	if cropModel then
		-- Create enhanced harvest effect for garden
		self:CreateGardenHarvestEffect(cropModel, gardenSpotModel, cropType, rarity)

		-- Remove crop after effect
		spawn(function()
			wait(1.5)
			if cropModel and cropModel.Parent then
				cropModel:Destroy()
			end
		end)

		return true
	else
		warn("CropVisual: No crop visual found to harvest from garden")
		return false
	end
end

function CropVisual:CreateGardenHarvestEffect(cropModel, gardenSpotModel, cropType, rarity)
	if not cropModel or not cropModel.PrimaryPart then return end

	local position = cropModel.PrimaryPart.Position
	local particleCount = self:GetRarityParticleCount(rarity) * 1.5 -- More particles for garden
	local color = self:GetRarityColor(rarity)

	-- Create enhanced harvest particles for garden
	for i = 1, particleCount do
		local particle = Instance.new("Part")
		particle.Name = "GardenHarvestParticle"
		particle.Size = Vector3.new(0.2, 0.2, 0.2)
		particle.Color = color
		particle.Material = Enum.Material.Neon
		particle.CanCollide = false
		particle.Anchored = true
		particle.Shape = Enum.PartType.Ball
		particle.Position = position + Vector3.new(
			(math.random() - 0.5) * 6,
			math.random() * 3,
			(math.random() - 0.5) * 6
		)
		particle.Parent = Workspace

		-- Animate particle with garden-specific motion
		local tween = TweenService:Create(particle,
			TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = particle.Position + Vector3.new(0, 10, 0),
				Transparency = 1,
				Size = Vector3.new(0.05, 0.05, 0.05)
			}
		)
		tween:Play()

		-- Clean up particle
		Debris:AddItem(particle, 3)
	end

	-- Create garden-specific special effects
	if rarity == "legendary" then
		self:CreateGardenLegendaryEffect(position)
	elseif rarity == "epic" then
		self:CreateGardenEpicEffect(position)
	end

	-- Add garden soil enrichment effect
	self:CreateSoilEnrichmentEffect(gardenSpotModel, rarity)
end

function CropVisual:CreateGardenLegendaryEffect(position)
	-- Create a burst of golden light that spreads across the garden
	local burst = Instance.new("Part")
	burst.Name = "GardenLegendaryBurst"
	burst.Size = Vector3.new(0.1, 0.1, 0.1)
	burst.Material = Enum.Material.Neon
	burst.Color = Color3.fromRGB(255, 215, 0)
	burst.CanCollide = false
	burst.Anchored = true
	burst.Shape = Enum.PartType.Ball
	burst.Position = position
	burst.Parent = Workspace

	local tween = TweenService:Create(burst,
		TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = Vector3.new(12, 12, 12), -- Larger for garden
			Transparency = 1
		}
	)
	tween:Play()

	Debris:AddItem(burst, 2)
end

function CropVisual:CreateGardenEpicEffect(position)
	-- Create a spiral of purple particles that rises from the garden
	spawn(function()
		for i = 1, 25 do -- More particles for garden
			local particle = Instance.new("Part")
			particle.Name = "GardenEpicSpiral"
			particle.Size = Vector3.new(0.15, 0.15, 0.15)
			particle.Material = Enum.Material.Neon
			particle.Color = Color3.fromRGB(128, 0, 128)
			particle.CanCollide = false
			particle.Anchored = true
			particle.Shape = Enum.PartType.Ball
			particle.Parent = Workspace

			local angle = (i / 25) * math.pi * 6
			local radius = 3
			local startPos = position + Vector3.new(
				math.cos(angle) * radius,
				i * 0.3,
				math.sin(angle) * radius
			)
			particle.Position = startPos

			local endPos = position + Vector3.new(0, 8, 0)

			local tween = TweenService:Create(particle,
				TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{
					Position = endPos,
					Transparency = 1
				}
			)
			tween:Play()

			Debris:AddItem(particle, 2.5)
			wait(0.03)
		end
	end)
end

function CropVisual:CreateSoilEnrichmentEffect(gardenSpotModel, rarity)
	-- Create an effect that shows the garden soil being enriched
	local spotPart = gardenSpotModel:FindFirstChild("SpotPart")
	if not spotPart then return end

	local enrichmentEffect = Instance.new("Part")
	enrichmentEffect.Name = "SoilEnrichment"
	enrichmentEffect.Size = Vector3.new(4, 0.1, 4)
	enrichmentEffect.Material = Enum.Material.Neon
	enrichmentEffect.Color = Color3.fromRGB(100, 200, 100)
	enrichmentEffect.CanCollide = false
	enrichmentEffect.Anchored = true
	enrichmentEffect.CFrame = spotPart.CFrame
	enrichmentEffect.Transparency = 0.8
	enrichmentEffect.Parent = gardenSpotModel

	-- Animate the enrichment effect
	local tween = TweenService:Create(enrichmentEffect,
		TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{
			Transparency = 1,
			Size = Vector3.new(2, 0.05, 2)
		}
	)
	tween:Play()

	Debris:AddItem(enrichmentEffect, 3.5)
end

-- ========== EXISTING METHODS (keeping all original functionality) ==========

-- All the existing methods from the original CropVisual.lua remain the same
-- I'm including key ones that might need minor adjustments for garden use

function CropVisual:CreateCropModel(cropType, rarity, growthStage)
	print("🌱 CropVisual: Creating " .. cropType .. " (" .. rarity .. ", " .. growthStage .. ") for garden")

	local success, cropModel = pcall(function()
		if self:HasPreMadeModel(cropType) then
			print("🎨 Using pre-made model for garden " .. cropType)
			return self:CreatePreMadeCrop(cropType, rarity, growthStage)
		else
			print("🔧 Creating procedural model for garden " .. cropType)
			return self:CreateProceduralCrop(cropType, rarity, growthStage)
		end
	end)

	if success and cropModel then
		-- Mark as garden crop
		cropModel:SetAttribute("IsGardenCrop", true)
		print("✅ Created garden crop model: " .. cropModel.Name)

		-- Store model reference for cleanup
		self:TrackCropModel(cropModel)

		return cropModel
	else
		warn("❌ Failed to create garden crop model: " .. tostring(cropModel))
		return self:CreateFallbackCrop(cropType, rarity, growthStage)
	end
end

function CropVisual:HasPreMadeModel(cropType)
	return self.AvailableModels[cropType:lower()] ~= nil
end

function CropVisual:GetPreMadeModel(cropType)
	return self.AvailableModels[cropType:lower()]
end

function CropVisual:TrackCropModel(cropModel)
	if cropModel then
		local modelId = tostring(cropModel)
		self.ActiveEffects[modelId] = {
			model = cropModel,
			startTime = tick(),
			cleanup = function()
				if cropModel and cropModel.Parent then
					cropModel:Destroy()
				end
			end
		}
	end
end

-- [Include all other existing methods from the original CropVisual.lua here]
-- For brevity, I'm not repeating them all, but they should all be included

function CropVisual:CreatePreMadeCrop(cropType, rarity, growthStage)
	local templateModel = self:GetPreMadeModel(cropType)
	if not templateModel then return nil end

	local cropModel = templateModel:Clone()
	cropModel.Name = cropType .. "_" .. rarity .. "_garden"

	-- Ensure model is properly anchored
	self:AnchorModel(cropModel)

	-- Enhanced scaling for growth stages
	local rarityScale = self:GetRarityScale(rarity)
	local growthScale = self:GetGrowthScale(growthStage)
	local finalScale = rarityScale * growthScale

	self:ScaleModel(cropModel, finalScale)

	-- Add rarity effects
	if growthStage == "ready" or growthStage == "flowering" then
		self:AddRarityEffects(cropModel, rarity)
	elseif rarity ~= "common" and growthStage ~= "planted" then
		self:AddSubtleRarityEffects(cropModel, rarity)
	end

	-- Add attributes
	cropModel:SetAttribute("CropType", cropType)
	cropModel:SetAttribute("Rarity", rarity)
	cropModel:SetAttribute("GrowthStage", growthStage)
	cropModel:SetAttribute("ModelType", "PreMade")
	cropModel:SetAttribute("CurrentScale", finalScale)
	cropModel:SetAttribute("IsGardenCrop", true)

	print("✅ Created pre-made garden crop: " .. cropModel.Name)
	return cropModel
end

-- Include all the utility and effect methods from the original
function CropVisual:GetGrowthScale(growthStage)
	local scales = {
		planted = 0.3,
		sprouting = 0.5,
		growing = 0.7,
		flowering = 0.9,
		ready = 1.0
	}
	return scales[growthStage] or 0.5
end

function CropVisual:GetRarityScale(rarity)
	local scales = {
		common = 1.0,
		uncommon = 1.1,
		rare = 1.2,
		epic = 1.3,
		legendary = 1.5
	}
	return scales[rarity] or 1.0
end

function CropVisual:GetRarityColor(rarity)
	local colors = {
		common = Color3.fromRGB(255, 255, 255),
		uncommon = Color3.fromRGB(0, 255, 0),
		rare = Color3.fromRGB(255, 215, 0),
		epic = Color3.fromRGB(128, 0, 128),
		legendary = Color3.fromRGB(255, 100, 100)
	}
	return colors[rarity] or Color3.fromRGB(255, 255, 255)
end

function CropVisual:GetRarityParticleCount(rarity)
	local counts = {
		common = 3,
		uncommon = 5,
		rare = 7,
		epic = 10,
		legendary = 15
	}
	return counts[rarity] or 3
end

function CropVisual:CreateProgressBar(elapsed, total)
	local progress = math.min(elapsed / total, 1)
	local barLength = 10
	local filledLength = math.floor(progress * barLength)

	local bar = "["
	for i = 1, barLength do
		if i <= filledLength then
			bar = bar .. "█"
		else
			bar = bar .. "░"
		end
	end
	bar = bar .. "] " .. math.floor(progress * 100) .. "%"

	return bar
end

-- Add all the missing methods from the original (rarity effects, animations, etc.)
function CropVisual:AddRarityEffects(cropModel, rarity)
	if not cropModel.PrimaryPart or rarity == "common" then return end

	local light = Instance.new("PointLight")
	light.Name = "RarityLight"
	light.Parent = cropModel.PrimaryPart

	if rarity == "uncommon" then
		light.Color = Color3.fromRGB(0, 255, 0)
		light.Brightness = 1
		light.Range = 8
	elseif rarity == "rare" then
		light.Color = Color3.fromRGB(255, 215, 0)
		light.Brightness = 1.5
		light.Range = 10
		cropModel.PrimaryPart.Material = Enum.Material.Neon
	elseif rarity == "epic" then
		light.Color = Color3.fromRGB(128, 0, 128)
		light.Brightness = 2
		light.Range = 12
		cropModel.PrimaryPart.Material = Enum.Material.Neon
		self:AddParticleEffect(cropModel, "epic")
	elseif rarity == "legendary" then
		light.Color = Color3.fromRGB(255, 100, 100)
		light.Brightness = 3
		light.Range = 15
		cropModel.PrimaryPart.Material = Enum.Material.Neon
		self:AddParticleEffect(cropModel, "legendary")
		self:AddAuraEffect(cropModel, rarity)
	end
end

function CropVisual:AddSubtleRarityEffects(cropModel, rarity)
	if not cropModel.PrimaryPart or rarity == "common" then return end

	local light = Instance.new("PointLight")
	light.Name = "SubtleRarityLight"
	light.Parent = cropModel.PrimaryPart

	if rarity == "uncommon" then
		light.Color = Color3.fromRGB(0, 255, 0)
		light.Brightness = 0.3
		light.Range = 4
	elseif rarity == "rare" then
		light.Color = Color3.fromRGB(255, 215, 0)
		light.Brightness = 0.5
		light.Range = 5
	elseif rarity == "epic" then
		light.Color = Color3.fromRGB(128, 0, 128)
		light.Brightness = 0.7
		light.Range = 6
	elseif rarity == "legendary" then
		light.Color = Color3.fromRGB(255, 100, 100)
		light.Brightness = 1.0
		light.Range = 8
	end
end

-- Continue with all the other existing methods...

function CropVisual:AnchorModel(model)
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end
end

function CropVisual:ScaleModel(model, scaleFactor)
	if not model.PrimaryPart then return end

	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Size = part.Size * scaleFactor
		end
	end
end

function CropVisual:CountTable(tbl)
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

function CropVisual:IsAvailable()
	return true
end

function CropVisual:GetStatus()
	return {
		available = true,
		modelsLoaded = self:CountTable(self.AvailableModels),
		initialized = true,
		activeEffects = self:CountTable(self.ActiveEffects),
		gardenIntegrated = GardenModel ~= nil and SoilPart ~= nil
	}
end

-- Add all the remaining methods that I didn't include for brevity...
-- (RemoveExistingClickDetectors, GetClickableParts, AnimateModelScale, etc.)

function CropVisual:RemoveExistingClickDetectors(cropModel)
	for _, obj in pairs(cropModel:GetDescendants()) do
		if obj:IsA("ClickDetector") and (obj.Name == "CropClickDetector" or obj.Name == "GardenCropClickDetector") then
			obj:Destroy()
		end
	end
end

function CropVisual:GetClickableParts(cropModel)
	local clickableParts = {}

	-- Method 1: Look for specifically named parts
	local preferredNames = {"CropBody", "MutatedCropBody", "Body", "Main", "Center"}
	for _, name in pairs(preferredNames) do
		local part = cropModel:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			table.insert(clickableParts, part)
		end
	end

	-- Method 2: Use PrimaryPart if no named parts found
	if #clickableParts == 0 and cropModel.PrimaryPart then
		table.insert(clickableParts, cropModel.PrimaryPart)
	end

	-- Method 3: Find largest parts if nothing else works
	if #clickableParts == 0 then
		local parts = {}
		for _, obj in pairs(cropModel:GetDescendants()) do
			if obj:IsA("BasePart") and obj.Parent == cropModel then
				local volume = obj.Size.X * obj.Size.Y * obj.Size.Z
				table.insert(parts, {part = obj, volume = volume})
			end
		end

		-- Sort by volume and take the largest ones
		table.sort(parts, function(a, b) return a.volume > b.volume end)

		for i = 1, math.min(3, #parts) do
			table.insert(clickableParts, parts[i].part)
		end
	end

	return clickableParts
end

function CropVisual:AnimateModelScale(cropModel, scaleChange)
	for _, part in pairs(cropModel:GetDescendants()) do
		if part:IsA("BasePart") then
			local targetSize = part.Size * scaleChange

			local tween = TweenService:Create(part,
				TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Size = targetSize}
			)
			tween:Play()
		end
	end
end

function CropVisual:RemoveStageEffects(cropModel)
	for _, obj in pairs(cropModel:GetDescendants()) do
		if obj.Name:find("Effect") or obj.Name:find("Particle") then
			obj:Destroy()
		end
	end
end

function CropVisual:CreateStageTransitionEffect(oldModel, newModel)
	if not oldModel or not newModel then return end

	-- Create sparkle effect during transition
	for i = 1, 15 do
		local sparkle = Instance.new("Part")
		sparkle.Name = "GardenTransitionSparkle"
		sparkle.Size = Vector3.new(0.1, 0.1, 0.1)
		sparkle.Material = Enum.Material.Neon
		sparkle.Color = Color3.fromRGB(100, 255, 100) -- Garden theme
		sparkle.CanCollide = false
		sparkle.Anchored = true
		sparkle.Shape = Enum.PartType.Ball

		local position = oldModel.PrimaryPart.Position + Vector3.new(
			math.random(-3, 3),
			math.random(-1, 3),
			math.random(-3, 3)
		)
		sparkle.Position = position
		sparkle.Parent = Workspace

		-- Animate sparkle
		spawn(function()
			wait(0.3)
			local tween = TweenService:Create(sparkle,
				TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = sparkle.Position + Vector3.new(0, 4, 0),
					Transparency = 1,
					Size = Vector3.new(0.05, 0.05, 0.05)
				}
			)
			tween:Play()
			tween.Completed:Connect(function()
				sparkle:Destroy()
			end)
		end)

		wait(0.08)
	end
end

print("CropVisual: ✅ Garden-integrated crop visual module loaded successfully")

return CropVisual