-- CropVisualManager.lua (Module Script)
-- Place in: ServerScriptService/CropVisualManager

local CropVisualManager = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Load ItemConfig
local ItemConfig = nil
pcall(function()
	ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig", 5))
end)

-- Initialize CropModels folder
local CropModels = ReplicatedStorage:FindFirstChild("CropModels")
if not CropModels then
	CropModels = Instance.new("Folder")
	CropModels.Name = "CropModels"
	CropModels.Parent = ReplicatedStorage
	print("CropVisualManager: Created CropModels folder")
end

print("CropVisualManager: Module loading...")

-- ========== MODULE INITIALIZATION ==========

function CropVisualManager:Initialize()
	print("CropVisualManager: Initializing as module...")

	-- Initialize model tracking
	self.AvailableModels = {}
	self.ModelCache = {}

	-- Scan for available models
	self:UpdateAvailableModels()
	self:InitializeForGarden()
	print("CropVisualManager: Module initialized successfully")
	return true
end
function CropVisualManager:InitializeForGarden()
	print("CropVisualManager: Initializing for Garden system...")

	-- Find Garden references
	self.GardenModel = workspace:FindFirstChild("Garden")
	self.SoilPart = self.GardenModel and self.GardenModel:FindFirstChild("Soil")

	if self.GardenModel and self.SoilPart then
		print("CropVisualManager: ✅ Garden references established")
		print("  Garden: " .. self.GardenModel.Name)
		print("  Soil: " .. self.SoilPart.Name)
		return true
	else
		warn("CropVisualManager: ❌ Garden references not found")
		return false
	end
end

-- ========== MODEL MANAGEMENT ==========

function CropVisualManager:UpdateAvailableModels()
	self.AvailableModels = {}

	if not CropModels then return end

	for _, model in pairs(CropModels:GetChildren()) do
		if model:IsA("Model") then
			local cropName = model.Name:lower()
			self.AvailableModels[cropName] = model
			print("CropVisualManager: Found model for " .. cropName)
		end
	end

	print("CropVisualManager: Found " .. self:CountTable(self.AvailableModels) .. " crop models")
end

function CropVisualManager:HasPreMadeModel(cropType)
	return self.AvailableModels[cropType:lower()] ~= nil
end

function CropVisualManager:GetPreMadeModel(cropType)
	return self.AvailableModels[cropType:lower()]
end

-- ========== CROP CREATION ==========

function CropVisualManager:CreateCropModel(cropType, rarity, growthStage)
	print("🌱 CropVisualManager: Creating " .. cropType .. " (" .. rarity .. ", " .. growthStage .. ")")

	local success, cropModel = pcall(function()
		-- FIXED: Try pre-made model for ALL growth stages, not just "ready"
		if self:HasPreMadeModel(cropType) then
			print("🎨 Using pre-made model for " .. cropType)
			return self:CreatePreMadeCrop(cropType, rarity, growthStage)
		else
			print("🔧 No pre-made model found, using procedural for " .. cropType)
			return self:CreateProceduralCrop(cropType, rarity, growthStage)
		end
	end)

	if success and cropModel then
		print("✅ Created crop model: " .. cropModel.Name)
		return cropModel
	else
		warn("❌ Failed to create crop model: " .. tostring(cropModel))
		return self:CreateFallbackCrop(cropType, rarity, growthStage)
	end
end

function CropVisualManager:GetGrowthScale(growthStage)
	local scales = {
		planted = 0.3,     -- Small sprout
		sprouting = 0.5,   -- Growing
		growing = 0.7,     -- Getting bigger
		flowering = 0.9,   -- Almost full size
		ready = 1.0        -- Full size
	}
	return scales[growthStage] or 0.5
end

-- Add subtle rarity effects for early growth stages
function CropVisualManager:AddSubtleRarityEffects(cropModel, rarity)
	if not cropModel.PrimaryPart or rarity == "common" then return end

	-- Add very subtle glow for rare crops even when small
	local light = Instance.new("PointLight")
	light.Parent = cropModel.PrimaryPart

	if rarity == "uncommon" then
		light.Color = Color3.fromRGB(0, 255, 0)
		light.Brightness = 0.3  -- Much dimmer for early stages
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

function CropVisualManager:CreateProceduralCrop(cropType, rarity, growthStage)
	local cropModel = Instance.new("Model")
	cropModel.Name = cropType .. "_" .. rarity .. "_procedural"

	-- Create main crop part
	local cropPart = Instance.new("Part")
	cropPart.Name = "CropBody"
	cropPart.Size = Vector3.new(2, 2, 2)
	cropPart.Material = Enum.Material.Grass
	cropPart.Color = self:GetCropColor(cropType, rarity)
	cropPart.CanCollide = false
	cropPart.Anchored = true
	cropPart.Parent = cropModel

	-- Add mesh
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(1, 1.2, 1)
	mesh.Parent = cropPart

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

function CropVisualManager:CreateFallbackCrop(cropType, rarity, growthStage)
	print("🔧 Creating fallback crop for " .. cropType)

	local cropModel = Instance.new("Model")
	cropModel.Name = cropType .. "_fallback"

	local cropPart = Instance.new("Part")
	cropPart.Name = "BasicCrop"
	cropPart.Size = Vector3.new(1, 1, 1)
	cropPart.Material = Enum.Material.Grass
	cropPart.Color = Color3.fromRGB(100, 200, 100)
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

-- ========== POSITIONING ==========

function CropVisualManager:PositionCropModel(cropModel, plotModel, growthStage)
	if not cropModel or not cropModel.PrimaryPart or not plotModel then
		warn("CropVisualManager: Invalid parameters for positioning")
		return
	end

	local spotPart = plotModel:FindFirstChild("SpotPart")
	if not spotPart then
		warn("CropVisualManager: No SpotPart found for positioning")
		return
	end

	-- Position above the plot
	local plotPosition = spotPart.Position
	local heightOffset = self:GetStageHeightOffset(growthStage)
	local cropPosition = plotPosition + Vector3.new(0, 2 + heightOffset, 0)

	cropModel.PrimaryPart.CFrame = CFrame.new(cropPosition)
	cropModel.PrimaryPart.Anchored = true
	cropModel.PrimaryPart.CanCollide = false

	print("🎯 Positioned crop at: " .. tostring(cropPosition))
end

-- ========== INTEGRATION METHODS ==========
function CropVisualManager:SetupCropClickDetection(cropModel, plotModel, cropType, rarity)
	if not cropModel or not cropModel.PrimaryPart then
		warn("CropVisualManager: Invalid crop model for click detection")
		return false
	end

	print("🖱️ CropVisualManager: Setting up click detection for " .. cropType)

	-- Remove any existing click detectors first
	self:RemoveExistingClickDetectors(cropModel)

	-- Find the best parts for clicking
	local clickableParts = self:GetClickableParts(cropModel)

	if #clickableParts == 0 then
		warn("CropVisualManager: No clickable parts found for " .. cropType)
		return false
	end

	-- Add click detectors to all clickable parts
	for _, part in pairs(clickableParts) do
		local clickDetector = Instance.new("ClickDetector")
		clickDetector.Name = "CropClickDetector"
		clickDetector.MaxActivationDistance = 20
		clickDetector.Parent = part

		-- Store plot reference in the click detector for easy access
		clickDetector:SetAttribute("PlotModel", plotModel.Name)
		clickDetector:SetAttribute("CropType", cropType)
		clickDetector:SetAttribute("Rarity", rarity)

		-- Connect the click event
		clickDetector.MouseClick:Connect(function(clickingPlayer)
			self:HandleCropClick(clickingPlayer, cropModel, plotModel, cropType, rarity)
		end)

		print("🖱️ Added click detector to " .. part.Name)
	end

	print("✅ Click detection setup complete for " .. cropType .. " with " .. #clickableParts .. " clickable parts")
	return true
end

function CropVisualManager:RemoveExistingClickDetectors(cropModel)
	for _, obj in pairs(cropModel:GetDescendants()) do
		if obj:IsA("ClickDetector") and obj.Name == "CropClickDetector" then
			obj:Destroy()
		end
	end
end

function CropVisualManager:GetClickableParts(cropModel)
	local clickableParts = {}

	-- Method 1: Look for specifically named parts (best option)
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

		for i = 1, math.min(3, #parts) do -- Take up to 3 largest parts
			table.insert(clickableParts, parts[i].part)
		end
	end

	return clickableParts
end

function CropVisualManager:HandleCropClick(clickingPlayer, cropModel, plotModel, cropType, rarity)
	print("🖱️ CropVisualManager: Crop clicked by " .. clickingPlayer.Name .. " - " .. cropType)

	-- Get GameCore reference
	local gameCore = _G.GameCore
	if not gameCore then
		warn("CropVisualManager: GameCore not available for click handling")
		return
	end

	-- Check if crop is ready for harvest
	local growthStage = plotModel:GetAttribute("GrowthStage") or 0
	local isMutation = plotModel:GetAttribute("IsMutation") or false

	if growthStage >= 4 then
		print("🌾 Crop is ready - calling harvest")

		-- Call the appropriate harvest method
		if isMutation then
			local mutationType = plotModel:GetAttribute("MutationType")
			gameCore:HarvestMatureMutation(clickingPlayer, plotModel, mutationType, rarity)
		else
			gameCore:HarvestCrop(clickingPlayer, plotModel)
		end
	else
		-- Crop not ready - show status
		print("🌱 Crop not ready - showing status")
		self:ShowCropStatus(clickingPlayer, plotModel, cropType, growthStage, isMutation)
	end
end

function CropVisualManager:ShowCropStatus(player, plotModel, cropType, growthStage, isMutation)
	local stageNames = {"planted", "sprouting", "growing", "flowering", "ready"}
	local currentStageName = stageNames[growthStage + 1] or "unknown"

	local plantedTime = plotModel:GetAttribute("PlantedTime") or os.time()
	local timeElapsed = os.time() - plantedTime

	-- Calculate remaining time based on crop type
	local totalGrowthTime
	if isMutation then
		local speedMultiplier = _G.MUTATION_GROWTH_SPEED or 1.0
		totalGrowthTime = 240 / speedMultiplier -- 4 minutes for mutations
	else
		totalGrowthTime = 300 -- 5 minutes for normal crops
	end

	local timeRemaining = math.max(0, totalGrowthTime - timeElapsed)
	local minutesRemaining = math.ceil(timeRemaining / 60)

	local cropDisplayName = cropType:gsub("^%l", string.upper):gsub("_", " ")
	local statusEmoji = isMutation and "🧬" or "🌱"

	local message
	if growthStage >= 4 then
		message = statusEmoji .. " " .. cropDisplayName .. " is ready to harvest!"
	else
		message = statusEmoji .. " " .. cropDisplayName .. " is " .. currentStageName .. 
			"\n⏰ " .. minutesRemaining .. " minutes remaining"
	end

	-- Get GameCore reference to send notification
	local gameCore = _G.GameCore
	if gameCore and gameCore.SendNotification then
		gameCore:SendNotification(player, "🌾 Crop Status", message, "info")
	else
		print("🌾 " .. player.Name .. " - " .. message)
	end
end

-- ========== UPDATE EXISTING METHODS ==========

-- UPDATE your existing CreatePreMadeCrop method to include click detection
function CropVisualManager:CreatePreMadeCrop(cropType, rarity, growthStage)
	local templateModel = self:GetPreMadeModel(cropType)
	if not templateModel then return nil end

	local cropModel = templateModel:Clone()
	cropModel.Name = cropType .. "_" .. rarity .. "_premade"

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

	print("✅ Created pre-made crop: " .. cropModel.Name)
	return cropModel
end


-- UPDATE your HandleCropPlanted method to setup click detection
function CropVisualManager:HandleCropPlanted(plotModel, cropType, rarity)
	print("🌱 CropVisualManager: HandleCropPlanted - " .. cropType .. " (" .. rarity .. ")")

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

		-- IMPORTANT: Setup click detection for the new crop
		self:SetupCropClickDetection(cropModel, plotModel, cropType, rarity)

		print("✅ Crop visual created successfully with click detection")
		return true
	else
		warn("❌ Failed to create crop visual")
		return false
	end
end

function CropVisualManager:GetRarityColor(rarity)
	local colors = {
		uncommon = Color3.fromRGB(0, 255, 0),
		rare = Color3.fromRGB(255, 215, 0),
		epic = Color3.fromRGB(128, 0, 128),
		legendary = Color3.fromRGB(255, 100, 100)
	}
	return colors[rarity] or Color3.fromRGB(255, 255, 255)
end

function CropVisualManager:CreatePulsingEffect(part, color)
	spawn(function()
		while part and part.Parent do
			-- Pulse the material between Neon and Glass
			part.Material = Enum.Material.Neon
			wait(1)
			if part and part.Parent then
				part.Material = Enum.Material.Glass
				wait(1)
			end
		end
	end)
end


-- Add this new function to CropVisualManager.lua
function CropVisualManager:UpdateCropStage(cropModel, plotModel, cropType, rarity, stageName, stageIndex)
	print("🎨 CropVisualManager: Updating " .. cropType .. " to stage " .. stageName)

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

	-- Method 2: Scale existing model
	return self:ScaleExistingModel(cropModel, rarity, stageName)
end

function CropVisualManager:ReplaceWithNewStageModel(oldCropModel, plotModel, cropType, rarity, stageName)
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

	-- IMPORTANT: Setup click detection for new model
	self:SetupCropClickDetection(newCropModel, plotModel, cropType, rarity)

	-- Remove old model
	oldCropModel:Destroy()

	print("✅ Successfully replaced crop model for stage " .. stageName .. " with click detection")
	return true
end

function CropVisualManager:ScaleExistingModel(cropModel, rarity, stageName)
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

	self:UpdateMutationEffectsForStage(cropModel, cropModel:GetAttribute("CropType"), stageName)

	-- IMPORTANT: Ensure click detection is still present after scaling
	spawn(function()
		wait(2) -- Wait for tween to complete

		-- Check if click detectors still exist and are functional
		local hasWorkingClickDetector = false
		for _, obj in pairs(cropModel:GetDescendants()) do
			if obj:IsA("ClickDetector") and obj.Name == "CropClickDetector" and obj.Parent then
				hasWorkingClickDetector = true
				break
			end
		end

		if not hasWorkingClickDetector then
			print("🖱️ Re-adding click detection after scaling")
			local plotModel = cropModel.Parent
			local cropType = cropModel:GetAttribute("CropType")
			local rarity = cropModel:GetAttribute("Rarity")

			if plotModel and cropType and rarity then
				self:SetupCropClickDetection(cropModel, plotModel, cropType, rarity)
			end
		end
	end)

	print("📏 Scaled crop by factor of " .. scaleChange)
	return true
end

function CropVisualManager:OnCropHarvested(plotModel, cropType, rarity)
	print("🌾 CropVisualManager: OnCropHarvested - " .. tostring(cropType))

	if not plotModel then return false end

	local cropModel = plotModel:FindFirstChild("CropModel")
	if cropModel then
		-- Create harvest effect
		self:CreateHarvestEffect(cropModel, cropType, rarity)

		-- Remove crop after effect
		spawn(function()
			wait(1)
			if cropModel and cropModel.Parent then
				cropModel:Destroy()
			end
		end)

		return true
	else
		warn("CropVisualManager: No crop visual found to harvest")
		return false
	end
end

-- ========== HELPER METHODS ==========

function CropVisualManager:AnchorModel(model)
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end
end

function CropVisualManager:ScaleModel(model, scaleFactor)
	if not model.PrimaryPart then return end

	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Size = part.Size * scaleFactor
		end
	end
end

function CropVisualManager:GetRarityScale(rarity)
	local scales = {
		common = 1.0,
		uncommon = 1.1,
		rare = 1.2,
		epic = 1.3,
		legendary = 1.5
	}
	return scales[rarity] or 1.0
end

function CropVisualManager:GetCropColor(cropType, rarity)
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

function CropVisualManager:AddRarityEffects(cropModel, rarity)
	if not cropModel.PrimaryPart or rarity == "common" then return end

	local light = Instance.new("PointLight")
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
	elseif rarity == "legendary" then
		light.Color = Color3.fromRGB(255, 100, 100)
		light.Brightness = 3
		light.Range = 15
		cropModel.PrimaryPart.Material = Enum.Material.Neon
	end
end

function CropVisualManager:GetStageHeightOffset(growthStage)
	local offsets = {
		planted = -1,
		sprouting = -0.5,
		growing = 0,
		flowering = 0.5,
		ready = 1
	}
	return offsets[growthStage] or 0
end

function CropVisualManager:CreateHarvestEffect(cropModel, cropType, rarity)
	if not cropModel or not cropModel.PrimaryPart then return end

	local position = cropModel.PrimaryPart.Position

	-- Create simple particle effect
	for i = 1, 5 do
		local particle = Instance.new("Part")
		particle.Size = Vector3.new(0.2, 0.2, 0.2)
		particle.Color = Color3.fromRGB(255, 215, 0)
		particle.Material = Enum.Material.Neon
		particle.CanCollide = false
		particle.Anchored = true
		particle.Position = position + Vector3.new(
			math.random(-2, 2),
			math.random(0, 3),
			math.random(-2, 2)
		)
		particle.Parent = workspace

		-- Animate particle
		spawn(function()
			wait(0.5)
			local tween = TweenService:Create(particle,
				TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = particle.Position + Vector3.new(0, 5, 0),
					Transparency = 1
				}
			)
			tween:Play()
			tween.Completed:Connect(function()
				particle:Destroy()
			end)
		end)
	end
end

function CropVisualManager:CountTable(tbl)
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

-- ========== STATUS METHODS ==========

function CropVisualManager:IsAvailable()
	return true
end

function CropVisualManager:GetStatus()
	return {
		available = true,
		modelsLoaded = self:CountTable(self.AvailableModels),
		initialized = true
	}
end

print("CropVisualManager: ✅ Module loaded successfully")
_G.CheckGardenStatus = function()
	print("=== GARDEN SYSTEM STATUS CHECK ===")

	-- Check workspace references
	local garden = workspace:FindFirstChild("Garden")
	local soil = garden and garden:FindFirstChild("Soil")

	print("Workspace References:")
	print("  Garden model: " .. (garden and "✅ " .. garden.Name or "❌ Not found"))
	print("  Soil part: " .. (soil and "✅ " .. soil.Name or "❌ Not found"))

	if soil then
		print("  Soil size: " .. tostring(soil.Size))
		print("  Soil position: " .. tostring(soil.Position))
	end

	-- Check module references
	print("Module References:")
	print("  _G.FarmPlot: " .. (_G.FarmPlot and "✅" or "❌"))
	print("  _G.GameCore: " .. (_G.GameCore and "✅" or "❌"))
	print("  _G.GardenAdminManager: " .. (_G.GardenAdminManager and "✅" or "❌"))

	-- Check active garden regions
	if garden then
		local regionCount = 0
		for _, child in pairs(garden:GetChildren()) do
			if child:IsA("Model") and child.Name:find("_GardenRegion") then
				regionCount = regionCount + 1
			end
		end
		print("Active garden regions: " .. regionCount)
	end

	print("=================================")
end

-- Global function to create garden region for a player
_G.CreateGardenRegion = function(playerName)
	local player = game.Players:FindFirstChild(playerName)
	if not player then
		print("Player not found: " .. playerName)
		return false
	end

	if _G.FarmPlot then
		return _G.FarmPlot:CreateSimpleFarmPlot(player)
	else
		print("FarmPlot module not available")
		return false
	end
end

-- Global function to validate all garden regions
_G.ValidateAllGardens = function()
	print("Validating all garden regions...")

	if not _G.GardenAdminManager then
		print("GardenAdminManager not available")
		return
	end

	for _, player in pairs(game.Players:GetPlayers()) do
		print("Checking " .. player.Name .. "...")
		_G.GardenAdminManager:ValidatePlayerGardenRegion(player)
	end

	print("Validation complete!")
end

print("✅ Garden Integration Updates loaded!")
print("🔧 Global Debug Functions Available:")
print("  _G.CheckGardenStatus() - Check garden system status")
print("  _G.CreateGardenRegion('PlayerName') - Create garden region")
print("  _G.ValidateAllGardens() - Validate all garden regions")
return CropVisualManager