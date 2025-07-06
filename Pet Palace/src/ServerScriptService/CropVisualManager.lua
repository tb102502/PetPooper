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

	print("CropVisualManager: Module initialized successfully")
	return true
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
		-- Try pre-made model first
		if self:HasPreMadeModel(cropType) and growthStage == "ready" then
			return self:CreatePreMadeCrop(cropType, rarity, growthStage)
		else
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

function CropVisualManager:CreatePreMadeCrop(cropType, rarity, growthStage)
	local templateModel = self:GetPreMadeModel(cropType)
	if not templateModel then return nil end

	local cropModel = templateModel:Clone()
	cropModel.Name = cropType .. "_" .. rarity .. "_premade"

	-- Ensure model is properly anchored
	self:AnchorModel(cropModel)

	-- Scale based on rarity
	local scaleMultiplier = self:GetRarityScale(rarity)
	self:ScaleModel(cropModel, scaleMultiplier)

	-- Add rarity effects
	self:AddRarityEffects(cropModel, rarity)

	-- Add attributes
	cropModel:SetAttribute("CropType", cropType)
	cropModel:SetAttribute("Rarity", rarity)
	cropModel:SetAttribute("GrowthStage", growthStage)
	cropModel:SetAttribute("ModelType", "PreMade")

	return cropModel
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

		print("✅ Crop visual created successfully")
		return true
	else
		warn("❌ Failed to create crop visual")
		return false
	end
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

return CropVisualManager