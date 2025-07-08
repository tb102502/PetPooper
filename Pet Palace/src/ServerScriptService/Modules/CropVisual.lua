--[[
    CropVisual.lua - Enhanced Crop Visual System
    Place in: ServerScriptService/Modules/CropVisual.lua
    
    RESPONSIBILITIES:
    ✅ Crop model creation and management
    ✅ Visual effects and animations
    ✅ Growth stage visual transitions
    ✅ Rarity effects and enhancements
    ✅ Click detection setup
    ✅ Harvest and special effects
]]

local CropVisual = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- Dependencies
local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))

-- Module references (will be injected)
local GameCore = nil
local CropCreation = nil

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
	print("CropVisual: Initializing crop visual system...")

	-- Store module references
	GameCore = gameCoreRef
	CropCreation = cropCreationRef

	-- Initialize model tracking
	self.AvailableModels = {}
	self.ModelCache = {}
	self.ActiveEffects = {}

	-- Scan for available models
	self:UpdateAvailableModels()

	-- Initialize effect cleanup system
	self:InitializeEffectCleanup()

	print("CropVisual: ✅ Crop visual system initialized successfully")
	return true
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

-- ========== MODEL MANAGEMENT ==========

function CropVisual:HasPreMadeModel(cropType)
	return self.AvailableModels[cropType:lower()] ~= nil
end

function CropVisual:GetPreMadeModel(cropType)
	return self.AvailableModels[cropType:lower()]
end

function CropVisual:CreateCropModel(cropType, rarity, growthStage)
	print("🌱 CropVisual: Creating " .. cropType .. " (" .. rarity .. ", " .. growthStage .. ")")

	local success, cropModel = pcall(function()
		if self:HasPreMadeModel(cropType) then
			print("🎨 Using pre-made model for " .. cropType)
			return self:CreatePreMadeCrop(cropType, rarity, growthStage)
		else
			print("🔧 Creating procedural model for " .. cropType)
			return self:CreateProceduralCrop(cropType, rarity, growthStage)
		end
	end)

	if success and cropModel then
		print("✅ Created crop model: " .. cropModel.Name)

		-- Store model reference for cleanup
		self:TrackCropModel(cropModel)

		return cropModel
	else
		warn("❌ Failed to create crop model: " .. tostring(cropModel))
		return self:CreateFallbackCrop(cropType, rarity, growthStage)
	end
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

-- ========== PRE-MADE MODEL CREATION ==========

function CropVisual:CreatePreMadeCrop(cropType, rarity, growthStage)
	local templateModel = self:GetPreMadeModel(cropType)
	if not templateModel then return nil end

	local cropModel = templateModel:Clone()
	cropModel.Name = cropType .. "_" .. rarity .. "_premade"

	-- Ensure model is properly anchored
	self:AnchorModel(cropModel)

	-- Apply scaling for growth stage and rarity
	local rarityScale = self:GetRarityScale(rarity)
	local growthScale = self:GetGrowthScale(growthStage)
	local finalScale = rarityScale * growthScale

	self:ScaleModel(cropModel, finalScale)

	-- Add rarity effects based on growth stage
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

	print("✅ Created pre-made crop: " .. cropModel.Name)
	return cropModel
end

-- ========== PROCEDURAL MODEL CREATION ==========

function CropVisual:CreateProceduralCrop(cropType, rarity, growthStage)
	local cropModel = Instance.new("Model")
	cropModel.Name = cropType .. "_" .. rarity .. "_procedural"

	-- Create main crop part with enhanced design
	local cropPart = Instance.new("Part")
	cropPart.Name = "CropBody"
	cropPart.Size = Vector3.new(2, 2, 2)
	cropPart.Material = Enum.Material.Grass
	cropPart.Color = self:GetCropColor(cropType, rarity)
	cropPart.CanCollide = false
	cropPart.Anchored = true
	cropPart.Parent = cropModel

	-- Add mesh for better shape
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = self:GetCropMeshType(cropType)
	mesh.Scale = Vector3.new(1, 1.2, 1)
	mesh.Parent = cropPart

	-- Create additional visual elements based on crop type
	self:AddProceduralDetails(cropModel, cropType, rarity, growthStage)

	cropModel.PrimaryPart = cropPart

	-- Add rarity effects
	self:AddRarityEffects(cropModel, rarity)

	-- Add attributes
	cropModel:SetAttribute("CropType", cropType)
	cropModel:SetAttribute("Rarity", rarity)
	cropModel:SetAttribute("GrowthStage", growthStage)
	cropModel:SetAttribute("ModelType", "Procedural")

	return cropModel
end

function CropVisual:GetCropMeshType(cropType)
	local meshTypes = {
		carrot = Enum.MeshType.Cylinder,
		corn = Enum.MeshType.Cylinder,
		strawberry = Enum.MeshType.Sphere,
		wheat = Enum.MeshType.Cylinder,
		potato = Enum.MeshType.Sphere,
		cabbage = Enum.MeshType.Sphere,
		radish = Enum.MeshType.Cylinder,
		broccoli = Enum.MeshType.Sphere,
		tomato = Enum.MeshType.Sphere
	}
	return meshTypes[cropType] or Enum.MeshType.Sphere
end

function CropVisual:AddProceduralDetails(cropModel, cropType, rarity, growthStage)
	-- Add crop-specific visual details
	if cropType == "carrot" then
		self:AddCarrotDetails(cropModel, rarity, growthStage)
	elseif cropType == "corn" then
		self:AddCornDetails(cropModel, rarity, growthStage)
	elseif cropType == "strawberry" then
		self:AddStrawberryDetails(cropModel, rarity, growthStage)
	end
end

function CropVisual:AddCarrotDetails(cropModel, rarity, growthStage)
	if growthStage == "flowering" or growthStage == "ready" then
		-- Add green leafy top
		local leaves = Instance.new("Part")
		leaves.Name = "CarrotLeaves"
		leaves.Size = Vector3.new(1.5, 0.5, 1.5)
		leaves.Material = Enum.Material.Grass
		leaves.Color = Color3.fromRGB(34, 139, 34)
		leaves.CanCollide = false
		leaves.Anchored = true
		leaves.CFrame = cropModel.PrimaryPart.CFrame + Vector3.new(0, 1.5, 0)
		leaves.Parent = cropModel

		local leavesMesh = Instance.new("SpecialMesh")
		leavesMesh.MeshType = Enum.MeshType.Sphere
		leavesMesh.Scale = Vector3.new(1, 0.3, 1)
		leavesMesh.Parent = leaves
	end
end

function CropVisual:AddCornDetails(cropModel, rarity, growthStage)
	if growthStage == "ready" then
		-- Add corn kernels texture
		local kernels = Instance.new("Part")
		kernels.Name = "CornKernels"
		kernels.Size = Vector3.new(1.8, 1.8, 1.8)
		kernels.Material = Enum.Material.Neon
		kernels.Color = Color3.fromRGB(255, 255, 100)
		kernels.CanCollide = false
		kernels.Anchored = true
		kernels.CFrame = cropModel.PrimaryPart.CFrame
		kernels.Transparency = 0.3
		kernels.Parent = cropModel
	end
end

function CropVisual:AddStrawberryDetails(cropModel, rarity, growthStage)
	if growthStage == "flowering" or growthStage == "ready" then
		-- Add small seeds on surface
		for i = 1, 5 do
			local seed = Instance.new("Part")
			seed.Name = "StrawberrySeed" .. i
			seed.Size = Vector3.new(0.1, 0.1, 0.1)
			seed.Material = Enum.Material.Neon
			seed.Color = Color3.fromRGB(0, 0, 0)
			seed.CanCollide = false
			seed.Anchored = true
			seed.Shape = Enum.PartType.Ball

			-- Random position on surface
			local angle = (i / 5) * math.pi * 2
			local offset = Vector3.new(math.cos(angle) * 0.8, math.sin(angle * 2) * 0.5, math.sin(angle) * 0.8)
			seed.CFrame = cropModel.PrimaryPart.CFrame + offset
			seed.Parent = cropModel
		end
	end
end

-- ========== FALLBACK MODEL CREATION ==========

function CropVisual:CreateFallbackCrop(cropType, rarity, growthStage)
	print("🔧 Creating fallback crop for " .. cropType)

	local cropModel = Instance.new("Model")
	cropModel.Name = cropType .. "_fallback"

	local cropPart = Instance.new("Part")
	cropPart.Name = "BasicCrop"
	cropPart.Size = Vector3.new(1, 1, 1)
	cropPart.Material = Enum.Material.Grass
	cropPart.Color = self:GetCropColor(cropType, rarity)
	cropPart.CanCollide = false
	cropPart.Anchored = true
	cropPart.Parent = cropModel

	cropModel.PrimaryPart = cropPart

	-- Add basic attributes
	cropModel:SetAttribute("CropType", cropType)
	cropModel:SetAttribute("Rarity", rarity)
	cropModel:SetAttribute("ModelType", "Fallback")

	return cropModel
end

-- ========== POSITIONING AND INTEGRATION ==========

function CropVisual:HandleCropPlanted(plotModel, cropType, rarity)
	print("🌱 CropVisual: HandleCropPlanted - " .. cropType .. " (" .. rarity .. ")")

	if not plotModel then
		warn("❌ No plotModel provided")
		return false
	end

	-- Remove existing crop
	local existingCrop = plotModel:FindFirstChild("CropModel")
	if existingCrop then
		existingCrop:Destroy()
		wait(0.1)
	end

	-- Create new crop
	local cropModel = self:CreateCropModel(cropType, rarity, "planted")
	if cropModel then
		cropModel.Name = "CropModel"
		cropModel.Parent = plotModel

		self:PositionCropModel(cropModel, plotModel, "planted")
		self:SetupCropClickDetection(cropModel, plotModel, cropType, rarity)

		print("✅ Crop visual created successfully with click detection")
		return true
	else
		warn("❌ Failed to create crop visual")
		return false
	end
end

function CropVisual:PositionCropModel(cropModel, plotModel, growthStage)
	if not cropModel or not cropModel.PrimaryPart or not plotModel then
		warn("CropVisual: Invalid parameters for positioning")
		return
	end

	local spotPart = plotModel:FindFirstChild("SpotPart")
	if not spotPart then
		warn("CropVisual: No SpotPart found for positioning")
		return
	end

	-- Position above the plot with growth-based height
	local plotPosition = spotPart.Position
	local heightOffset = self:GetStageHeightOffset(growthStage)
	local cropPosition = plotPosition + Vector3.new(0, 2 + heightOffset, 0)

	cropModel.PrimaryPart.CFrame = CFrame.new(cropPosition)
	cropModel.PrimaryPart.Anchored = true
	cropModel.PrimaryPart.CanCollide = false

	-- Ensure all parts are stable
	self:EnsureModelIsProperlyAnchored(cropModel)

	print("🎯 Positioned crop at: " .. tostring(cropPosition))
end

function CropVisual:EnsureModelIsProperlyAnchored(model)
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		end
	end
	model:SetAttribute("IsStable", true)
end

-- ========== GROWTH STAGE UPDATES ==========

function CropVisual:UpdateCropStage(plotModel, cropType, rarity, stageName, stageIndex)
	print("🎨 CropVisual: Updating " .. cropType .. " to stage " .. stageName)

	local cropModel = plotModel:FindFirstChild("CropModel")
	if not cropModel or not cropModel.PrimaryPart then
		warn("Invalid crop model for stage update")
		return false
	end

	-- Update model attributes
	cropModel:SetAttribute("GrowthStage", stageName)

	-- Method 1: If using pre-made model, create new model for this stage
	local modelType = cropModel:GetAttribute("ModelType")
	if modelType == "PreMade" and self:HasPreMadeModel(cropType) then
		return self:ReplaceWithNewStageModel(cropModel, plotModel, cropType, rarity, stageName)
	end

	-- Method 2: Scale and enhance existing model
	return self:UpdateExistingModel(cropModel, plotModel, cropType, rarity, stageName, stageIndex)
end

function CropVisual:ReplaceWithNewStageModel(oldCropModel, plotModel, cropType, rarity, stageName)
	print("🔄 Replacing crop model for new stage: " .. stageName)

	-- Store position
	local oldPosition = oldCropModel.PrimaryPart.CFrame

	-- Create new model for this stage
	local newCropModel = self:CreateCropModel(cropType, rarity, stageName)
	if not newCropModel then
		return false
	end

	-- Position new model
	newCropModel.Name = "CropModel"
	newCropModel.Parent = plotModel

	if newCropModel.PrimaryPart then
		newCropModel.PrimaryPart.CFrame = oldPosition
	end

	-- Setup click detection for new model
	self:SetupCropClickDetection(newCropModel, plotModel, cropType, rarity)

	-- Create transition effect
	self:CreateStageTransitionEffect(oldCropModel, newCropModel)

	-- Remove old model after effect
	spawn(function()
		wait(1)
		if oldCropModel and oldCropModel.Parent then
			oldCropModel:Destroy()
		end
	end)

	print("✅ Successfully replaced crop model for stage " .. stageName)
	return true
end

function CropVisual:UpdateExistingModel(cropModel, plotModel, cropType, rarity, stageName, stageIndex)
	print("📏 Updating existing model for stage: " .. stageName)

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

	-- Store new scale
	cropModel:SetAttribute("CurrentScale", targetScale)

	-- Ensure click detection remains functional
	spawn(function()
		wait(2) -- Wait for animations to complete
		self:ValidateClickDetection(cropModel, plotModel, cropType, rarity)
	end)

	print("📏 Updated crop to scale " .. targetScale)
	return true
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

function CropVisual:UpdateStageEffects(cropModel, cropType, rarity, stageName)
	-- Remove old stage-specific effects
	self:RemoveStageEffects(cropModel)

	-- Add new stage-specific effects
	if stageName == "flowering" then
		self:CreateFloweringEffect(cropModel)
	elseif stageName == "ready" then
		self:CreateReadyHarvestEffect(cropModel)
		self:UpdateRarityEffects(cropModel, rarity)
	end
end

-- ========== CLICK DETECTION ==========

function CropVisual:SetupCropClickDetection(cropModel, plotModel, cropType, rarity)
	if not cropModel or not cropModel.PrimaryPart then
		warn("CropVisual: Invalid crop model for click detection")
		return false
	end

	print("🖱️ CropVisual: Setting up click detection for " .. cropType)

	-- Remove existing click detectors
	self:RemoveExistingClickDetectors(cropModel)

	-- Find clickable parts
	local clickableParts = self:GetClickableParts(cropModel)

	if #clickableParts == 0 then
		warn("CropVisual: No clickable parts found for " .. cropType)
		return false
	end

	-- Add click detectors
	for _, part in pairs(clickableParts) do
		local clickDetector = Instance.new("ClickDetector")
		clickDetector.Name = "CropClickDetector"
		clickDetector.MaxActivationDistance = 20
		clickDetector.Parent = part

		-- Store references
		clickDetector:SetAttribute("PlotModel", plotModel.Name)
		clickDetector:SetAttribute("CropType", cropType)
		clickDetector:SetAttribute("Rarity", rarity)

		-- Connect click event
		clickDetector.MouseClick:Connect(function(clickingPlayer)
			self:HandleCropClick(clickingPlayer, cropModel, plotModel, cropType, rarity)
		end)
	end

	print("✅ Click detection setup for " .. cropType .. " with " .. #clickableParts .. " parts")
	return true
end

function CropVisual:RemoveExistingClickDetectors(cropModel)
	for _, obj in pairs(cropModel:GetDescendants()) do
		if obj:IsA("ClickDetector") and obj.Name == "CropClickDetector" then
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

function CropVisual:ValidateClickDetection(cropModel, plotModel, cropType, rarity)
	local hasWorkingClickDetector = false
	for _, obj in pairs(cropModel:GetDescendants()) do
		if obj:IsA("ClickDetector") and obj.Name == "CropClickDetector" and obj.Parent then
			hasWorkingClickDetector = true
			break
		end
	end

	if not hasWorkingClickDetector then
		print("🖱️ Re-adding click detection after update")
		self:SetupCropClickDetection(cropModel, plotModel, cropType, rarity)
	end
end

function CropVisual:HandleCropClick(clickingPlayer, cropModel, plotModel, cropType, rarity)
	print("🖱️ CropVisual: Crop clicked by " .. clickingPlayer.Name .. " - " .. cropType)

	-- Delegate to CropCreation module for harvest logic
	if CropCreation then
		-- Check if crop is ready for harvest
		local growthStage = plotModel:GetAttribute("GrowthStage") or 0
		local isMutation = plotModel:GetAttribute("IsMutation") or false

		if growthStage >= 4 then
			print("🌾 Crop is ready - calling harvest")
			CropCreation:HarvestCrop(clickingPlayer, plotModel)
		else
			print("🌱 Crop not ready - showing status")
			self:ShowCropStatus(clickingPlayer, plotModel, cropType, growthStage, isMutation)
		end
	else
		warn("CropVisual: CropCreation module not available for click handling")
	end
end

function CropVisual:ShowCropStatus(player, plotModel, cropType, growthStage, isMutation)
	local stageNames = {"planted", "sprouting", "growing", "flowering", "ready"}
	local currentStageName = stageNames[growthStage + 1] or "unknown"

	local plantedTime = plotModel:GetAttribute("PlantedTime") or os.time()
	local timeElapsed = os.time() - plantedTime

	-- Calculate remaining time
	local totalGrowthTime = isMutation and 240 or 300 -- 4 min for mutations, 5 min for normal
	local timeRemaining = math.max(0, totalGrowthTime - timeElapsed)
	local minutesRemaining = math.ceil(timeRemaining / 60)

	local cropDisplayName = cropType:gsub("^%l", string.upper):gsub("_", " ")
	local statusEmoji = isMutation and "🧬" or "🌱"

	local message
	if growthStage >= 4 then
		message = statusEmoji .. " " .. cropDisplayName .. " is ready to harvest!"
	else
		local progressBar = self:CreateProgressBar(timeElapsed, totalGrowthTime)
		message = statusEmoji .. " " .. cropDisplayName .. " is " .. currentStageName .. 
			"\n⏰ " .. minutesRemaining .. " minutes remaining\n" .. progressBar
	end

	-- Send notification through GameCore
	if GameCore and GameCore.SendNotification then
		GameCore:SendNotification(player, "🌾 Crop Status", message, "info")
	end
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

-- ========== VISUAL EFFECTS ==========

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

	-- Add very subtle glow for rare crops even when small
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

function CropVisual:AddParticleEffect(cropModel, rarity)
	if not cropModel.PrimaryPart then return end

	local attachment = Instance.new("Attachment")
	attachment.Name = "ParticleAttachment"
	attachment.Parent = cropModel.PrimaryPart

	local particles = Instance.new("ParticleEmitter")
	particles.Name = "RarityParticles"
	particles.Parent = attachment
	particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	particles.Rate = rarity == "legendary" and 20 or 15
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Speed = NumberRange.new(1, 3)

	if rarity == "legendary" then
		particles.Color = ColorSequence.new(Color3.fromRGB(255, 100, 100))
	else
		particles.Color = ColorSequence.new(Color3.fromRGB(128, 0, 128))
	end
end

function CropVisual:AddAuraEffect(cropModel, rarity)
	if not cropModel.PrimaryPart then return end

	local aura = Instance.new("Part")
	aura.Name = "RarityAura"
	aura.Size = Vector3.new(4, 4, 4)
	aura.Material = Enum.Material.ForceField
	aura.Color = Color3.fromRGB(255, 100, 100)
	aura.CanCollide = false
	aura.Anchored = true
	aura.Shape = Enum.PartType.Ball
	aura.CFrame = cropModel.PrimaryPart.CFrame
	aura.Transparency = 0.8
	aura.Parent = cropModel

	-- Animate aura
	spawn(function()
		while aura and aura.Parent do
			local expandTween = TweenService:Create(aura,
				TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Size = Vector3.new(5, 5, 5), Transparency = 0.9}
			)
			local contractTween = TweenService:Create(aura,
				TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Size = Vector3.new(4, 4, 4), Transparency = 0.8}
			)

			expandTween:Play()
			expandTween.Completed:Wait()
			contractTween:Play()
			contractTween.Completed:Wait()
		end
	end)
end

function CropVisual:UpdateRarityEffects(cropModel, rarity)
	-- Remove old rarity effects
	self:RemoveRarityEffects(cropModel)

	-- Add new rarity effects
	self:AddRarityEffects(cropModel, rarity)
end

function CropVisual:RemoveRarityEffects(cropModel)
	for _, obj in pairs(cropModel:GetDescendants()) do
		if obj.Name:find("Rarity") then
			obj:Destroy()
		end
	end
end

function CropVisual:CreateFloweringEffect(cropModel)
	if not cropModel.PrimaryPart then return end

	spawn(function()
		for i = 1, 3 do
			local flower = Instance.new("Part")
			flower.Name = "FlowerParticle"
			flower.Size = Vector3.new(0.1, 0.1, 0.1)
			flower.Shape = Enum.PartType.Ball
			flower.Material = Enum.Material.Neon
			flower.Color = Color3.fromRGB(255, 192, 203)
			flower.CanCollide = false
			flower.Anchored = true

			local position = cropModel.PrimaryPart.Position + Vector3.new(
				math.random(-1, 1),
				math.random(1, 3),
				math.random(-1, 1)
			)
			flower.Position = position
			flower.Parent = cropModel

			-- Fade out after 2 seconds
			local tween = TweenService:Create(flower,
				TweenInfo.new(2, Enum.EasingStyle.Quad),
				{Transparency = 1}
			)
			tween:Play()
			tween.Completed:Connect(function()
				flower:Destroy()
			end)

			wait(0.5)
		end
	end)
end

function CropVisual:CreateReadyHarvestEffect(cropModel)
	if not cropModel.PrimaryPart then return end

	-- Add a subtle pulsing effect
	local originalTransparency = cropModel.PrimaryPart.Transparency

	spawn(function()
		while cropModel and cropModel.Parent and cropModel:GetAttribute("GrowthStage") == "ready" do
			local pulseIn = TweenService:Create(cropModel.PrimaryPart,
				TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Transparency = originalTransparency + 0.2}
			)
			local pulseOut = TweenService:Create(cropModel.PrimaryPart,
				TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Transparency = originalTransparency}
			)

			pulseIn:Play()
			pulseIn.Completed:Wait()
			pulseOut:Play()
			pulseOut.Completed:Wait()
		end
	end)
end

function CropVisual:CreateStageTransitionEffect(oldModel, newModel)
	if not oldModel or not newModel then return end

	-- Create sparkle effect during transition
	for i = 1, 10 do
		local sparkle = Instance.new("Part")
		sparkle.Name = "TransitionSparkle"
		sparkle.Size = Vector3.new(0.1, 0.1, 0.1)
		sparkle.Material = Enum.Material.Neon
		sparkle.Color = Color3.fromRGB(255, 255, 100)
		sparkle.CanCollide = false
		sparkle.Anchored = true
		sparkle.Shape = Enum.PartType.Ball

		local position = oldModel.PrimaryPart.Position + Vector3.new(
			math.random(-2, 2),
			math.random(-1, 2),
			math.random(-2, 2)
		)
		sparkle.Position = position
		sparkle.Parent = workspace

		-- Animate sparkle
		spawn(function()
			wait(0.2)
			local tween = TweenService:Create(sparkle,
				TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = sparkle.Position + Vector3.new(0, 3, 0),
					Transparency = 1,
					Size = Vector3.new(0.05, 0.05, 0.05)
				}
			)
			tween:Play()
			tween.Completed:Connect(function()
				sparkle:Destroy()
			end)
		end)

		wait(0.1)
	end
end

function CropVisual:RemoveStageEffects(cropModel)
	for _, obj in pairs(cropModel:GetDescendants()) do
		if obj.Name:find("Effect") or obj.Name:find("Particle") then
			obj:Destroy()
		end
	end
end

-- ========== HARVEST EFFECTS ==========

function CropVisual:OnCropHarvested(plotModel, cropType, rarity)
	print("🌾 CropVisual: OnCropHarvested - " .. tostring(cropType))

	if not plotModel then return false end

	local cropModel = plotModel:FindFirstChild("CropModel")
	if cropModel then
		-- Create harvest effect
		self:CreateHarvestEffect(cropModel, cropType, rarity)

		-- Remove crop after effect
		spawn(function()
			wait(1.5)
			if cropModel and cropModel.Parent then
				cropModel:Destroy()
			end
		end)

		return true
	else
		warn("CropVisual: No crop visual found to harvest")
		return false
	end
end

function CropVisual:CreateHarvestEffect(cropModel, cropType, rarity)
	if not cropModel or not cropModel.PrimaryPart then return end

	local position = cropModel.PrimaryPart.Position
	local particleCount = self:GetRarityParticleCount(rarity)
	local color = self:GetRarityColor(rarity)

	-- Create harvest particles
	for i = 1, particleCount do
		local particle = Instance.new("Part")
		particle.Name = "HarvestParticle"
		particle.Size = Vector3.new(0.2, 0.2, 0.2)
		particle.Color = color
		particle.Material = Enum.Material.Neon
		particle.CanCollide = false
		particle.Anchored = true
		particle.Shape = Enum.PartType.Ball
		particle.Position = position + Vector3.new(
			(math.random() - 0.5) * 4,
			math.random() * 2,
			(math.random() - 0.5) * 4
		)
		particle.Parent = workspace

		-- Animate particle
		local tween = TweenService:Create(particle,
			TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = particle.Position + Vector3.new(0, 8, 0),
				Transparency = 1,
				Size = Vector3.new(0.05, 0.05, 0.05)
			}
		)
		tween:Play()

		-- Clean up particle
		Debris:AddItem(particle, 2.5)
	end

	-- Create special effects for higher rarities
	if rarity == "legendary" then
		self:CreateLegendaryHarvestEffect(position)
	elseif rarity == "epic" then
		self:CreateEpicHarvestEffect(position)
	end
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

function CropVisual:CreateLegendaryHarvestEffect(position)
	-- Create a burst of golden light
	local burst = Instance.new("Part")
	burst.Name = "LegendaryBurst"
	burst.Size = Vector3.new(0.1, 0.1, 0.1)
	burst.Material = Enum.Material.Neon
	burst.Color = Color3.fromRGB(255, 215, 0)
	burst.CanCollide = false
	burst.Anchored = true
	burst.Shape = Enum.PartType.Ball
	burst.Position = position
	burst.Parent = workspace

	local tween = TweenService:Create(burst,
		TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = Vector3.new(8, 8, 8),
			Transparency = 1
		}
	)
	tween:Play()

	Debris:AddItem(burst, 1.5)
end

function CropVisual:CreateEpicHarvestEffect(position)
	-- Create a spiral of purple particles
	spawn(function()
		for i = 1, 20 do
			local particle = Instance.new("Part")
			particle.Name = "EpicSpiral"
			particle.Size = Vector3.new(0.15, 0.15, 0.15)
			particle.Material = Enum.Material.Neon
			particle.Color = Color3.fromRGB(128, 0, 128)
			particle.CanCollide = false
			particle.Anchored = true
			particle.Shape = Enum.PartType.Ball
			particle.Parent = workspace

			local angle = (i / 20) * math.pi * 4
			local radius = 2
			local startPos = position + Vector3.new(
				math.cos(angle) * radius,
				i * 0.2,
				math.sin(angle) * radius
			)
			particle.Position = startPos

			local endPos = position + Vector3.new(0, 5, 0)

			local tween = TweenService:Create(particle,
				TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{
					Position = endPos,
					Transparency = 1
				}
			)
			tween:Play()

			Debris:AddItem(particle, 2)
			wait(0.05)
		end
	end)
end

-- ========== UTILITY FUNCTIONS ==========

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

function CropVisual:GetStageHeightOffset(growthStage)
	local offsets = {
		planted = -1,
		sprouting = -0.5,
		growing = 0,
		flowering = 0.5,
		ready = 1
	}
	return offsets[growthStage] or 0
end

function CropVisual:GetCropColor(cropType, rarity)
	local baseColors = {
		carrot = Color3.fromRGB(255, 140, 0),
		corn = Color3.fromRGB(255, 215, 0),
		strawberry = Color3.fromRGB(220, 20, 60),
		wheat = Color3.fromRGB(218, 165, 32),
		potato = Color3.fromRGB(160, 82, 45),
		cabbage = Color3.fromRGB(124, 252, 0),
		radish = Color3.fromRGB(255, 69, 0),
		broccoli = Color3.fromRGB(34, 139, 34),
		tomato = Color3.fromRGB(255, 99, 71)
	}

	local baseColor = baseColors[cropType] or Color3.fromRGB(100, 200, 100)

	-- Modify based on rarity
	if rarity == "legendary" then
		return baseColor:lerp(Color3.fromRGB(255, 100, 100), 0.3)
	elseif rarity == "epic" then
		return baseColor:lerp(Color3.fromRGB(128, 0, 128), 0.2)
	elseif rarity == "rare" then
		return baseColor:lerp(Color3.fromRGB(255, 215, 0), 0.15)
	elseif rarity == "uncommon" then
		return baseColor:lerp(Color3.fromRGB(0, 255, 0), 0.1)
	else
		return baseColor
	end
end

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

-- ========== STATUS METHODS ==========

function CropVisual:IsAvailable()
	return true
end

function CropVisual:GetStatus()
	return {
		available = true,
		modelsLoaded = self:CountTable(self.AvailableModels),
		initialized = true,
		activeEffects = self:CountTable(self.ActiveEffects)
	}
end

print("CropVisual: ✅ Enhanced crop visual module loaded successfully")

return CropVisual