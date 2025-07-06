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

-- UPDATE your existing CreatePreMadeMutatedCrop method to include click detection  
function CropVisualManager:CreatePreMadeMutatedCrop(mutationType, rarity, growthStage)
	local templateModel = self:GetPreMadeModel(mutationType)
	if not templateModel then return nil end

	local mutatedModel = templateModel:Clone()
	mutatedModel.Name = mutationType .. "_" .. rarity .. "_mutation"

	-- Ensure model is properly anchored
	self:AnchorModel(mutatedModel)

	-- Special scaling for mutations
	local rarityScale = self:GetRarityScale(rarity)
	local growthScale = self:GetMutationGrowthScale(growthStage)
	local mutationBonus = 1.3 -- 30% larger for mutations
	local finalScale = rarityScale * growthScale * mutationBonus

	self:ScaleModel(mutatedModel, finalScale)

	-- Add enhanced mutation effects
	self:AddMutationEffects(mutatedModel, mutationType, rarity)

	-- Add mutation attributes
	mutatedModel:SetAttribute("CropType", mutationType)
	mutatedModel:SetAttribute("Rarity", rarity)
	mutatedModel:SetAttribute("GrowthStage", growthStage)
	mutatedModel:SetAttribute("ModelType", "MutatedPreMade")
	mutatedModel:SetAttribute("IsMutation", true)

	print("✅ Created pre-made mutation: " .. mutatedModel.Name)
	return mutatedModel
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

-- ADD these methods to your CropVisualManager.lua

-- ========== MUTATION CROP SUPPORT ==========

function CropVisualManager:CreateMutatedCrop(mutationType, rarity, growthStage)
	print("🧬 CropVisualManager: Creating mutated crop " .. mutationType)

	-- Check if we have a pre-made model for this mutation
	if self:HasPreMadeModel(mutationType) then
		print("🎨 Using pre-made model for mutation: " .. mutationType)
		return self:CreatePreMadeMutatedCrop(mutationType, rarity, growthStage)
	else
		print("🔧 No pre-made model for " .. mutationType .. ", using procedural")
		return self:CreateProceduralMutatedCrop(mutationType, rarity, growthStage)
	end
end

function CropVisualManager:CreateProceduralMutatedCrop(mutationType, rarity, growthStage)
	local mutatedModel = Instance.new("Model")
	mutatedModel.Name = mutationType .. "_" .. rarity .. "_mutation_procedural"

	-- Create larger, more impressive crop part for mutations
	local cropPart = Instance.new("Part")
	cropPart.Name = "MutatedCropBody"
	cropPart.Size = Vector3.new(3, 3, 3) -- Larger than normal crops
	cropPart.Material = Enum.Material.Neon -- Mutations glow
	cropPart.Color = self:GetMutationColor(mutationType)
	cropPart.CanCollide = false
	cropPart.Anchored = true
	cropPart.Parent = mutatedModel

	-- Add special mesh for mutations
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(1.2, 1.5, 1.2) -- Unique shape for mutations
	mesh.Parent = cropPart

	mutatedModel.PrimaryPart = cropPart

	-- Add enhanced mutation effects
	self:AddMutationEffects(mutatedModel, mutationType, rarity)

	-- Add attributes
	mutatedModel:SetAttribute("CropType", mutationType)
	mutatedModel:SetAttribute("Rarity", rarity)
	mutatedModel:SetAttribute("GrowthStage", growthStage)
	mutatedModel:SetAttribute("ModelType", "MutatedProcedural")
	mutatedModel:SetAttribute("IsMutation", true)

	return mutatedModel
end

function CropVisualManager:AddMutationEffects(mutatedModel, mutationType, rarity)
	if not mutatedModel.PrimaryPart then return end

	-- Base mutation glow (all mutations get this)
	local mainLight = Instance.new("PointLight")
	mainLight.Name = "MutationGlow"
	mainLight.Parent = mutatedModel.PrimaryPart
	mainLight.Brightness = 2
	mainLight.Range = 15

	-- Color based on mutation type
	local mutationColors = {
		broccarrot = Color3.fromRGB(150, 255, 100), -- Green-orange blend
		brocmato = Color3.fromRGB(255, 150, 100),   -- Red-green blend
		broctato = Color3.fromRGB(200, 150, 255),   -- Purple blend
		cornmato = Color3.fromRGB(255, 200, 100),   -- Yellow-red blend
		craddish = Color3.fromRGB(255, 100, 150)    -- Pink-orange blend
	}

	mainLight.Color = mutationColors[mutationType] or Color3.fromRGB(255, 255, 255)

	-- Add pulsing effect
	self:CreatePulsingEffect(mutatedModel.PrimaryPart, mainLight.Color)

	-- Add particle effects for mutations
	self:CreateMutationParticles(mutatedModel.PrimaryPart, mutationType)

	-- Enhanced effects based on rarity
	if rarity == "rare" or rarity == "epic" or rarity == "legendary" then
		-- Add secondary lighting
		local secondaryLight = Instance.new("PointLight")
		secondaryLight.Name = "RarityGlow"
		secondaryLight.Parent = mutatedModel.PrimaryPart
		secondaryLight.Color = self:GetRarityColor(rarity)
		secondaryLight.Brightness = 1
		secondaryLight.Range = 10
	end
end

function CropVisualManager:GetMutationColor(mutationType)
	local colors = {
		broccarrot = Color3.fromRGB(100, 200, 50),  -- Broccoli-carrot blend
		brocmato = Color3.fromRGB(150, 100, 50),    -- Broccoli-tomato blend
		broctato = Color3.fromRGB(120, 80, 100),    -- Broccoli-potato blend
		cornmato = Color3.fromRGB(200, 150, 50),    -- Corn-tomato blend
		craddish = Color3.fromRGB(200, 100, 50)     -- Carrot-radish blend
	}
	return colors[mutationType] or Color3.fromRGB(150, 150, 150)
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

function CropVisualManager:CreateMutationParticles(part, mutationType)
	-- Create floating particles around the mutation
	spawn(function()
		while part and part.Parent do
			for i = 1, 3 do
				local particle = Instance.new("Part")
				particle.Name = "MutationParticle"
				particle.Size = Vector3.new(0.2, 0.2, 0.2)
				particle.Shape = Enum.PartType.Ball
				particle.Material = Enum.Material.Neon
				particle.Color = self:GetMutationColor(mutationType)
				particle.CanCollide = false
				particle.Anchored = true

				local offset = Vector3.new(
					math.random(-4, 4),
					math.random(2, 6),
					math.random(-4, 4)
				)
				particle.Position = part.Position + offset
				particle.Parent = part.Parent.Parent -- Put in same parent as crop

				-- Animate particle
				local tween = TweenService:Create(particle,
					TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{
						Position = particle.Position + Vector3.new(0, 3, 0),
						Transparency = 1,
						Size = Vector3.new(0.05, 0.05, 0.05)
					}
				)
				tween:Play()
				tween.Completed:Connect(function()
					particle:Destroy()
				end)
			end
			wait(2) -- Create new particles every 2 seconds
		end
	end)
end

-- ========== MUTATION POSITIONING ==========

function CropVisualManager:PositionMutatedCrop(mutatedModel, plot1, plot2)
	if not mutatedModel or not mutatedModel.PrimaryPart then return end

	-- Position the mutation between the two plots
	local spot1 = plot1:FindFirstChild("SpotPart")
	local spot2 = plot2:FindFirstChild("SpotPart")

	if not spot1 or not spot2 then
		warn("CropVisualManager: Could not find SpotParts for mutation positioning")
		return
	end

	-- Calculate center position between the two plots
	local centerPosition = (spot1.Position + spot2.Position) / 2
	local mutationPosition = centerPosition + Vector3.new(0, 3, 0) -- Higher than normal crops

	mutatedModel.PrimaryPart.CFrame = CFrame.new(mutationPosition)
	mutatedModel.PrimaryPart.Anchored = true
	mutatedModel.PrimaryPart.CanCollide = false

	print("🧬 Positioned mutation at center: " .. tostring(mutationPosition))
end

-- ADD these methods to your CropVisualManager.lua for mutation growth stages

-- ========== MUTATION GROWTH STAGE SYSTEM ==========

function CropVisualManager:UpdateMutationStage(cropModel, plotModel, mutationType, rarity, stageName, stageIndex)
	print("🧬 CropVisualManager: Updating mutation " .. mutationType .. " to stage " .. stageName)

	if not cropModel or not cropModel.PrimaryPart then
		warn("Invalid mutation model for stage update")
		return false
	end

	-- Update model attributes
	cropModel:SetAttribute("GrowthStage", stageName)

	-- Method 1: If using pre-made model, create new model for this stage
	local modelType = cropModel:GetAttribute("ModelType")
	if (modelType == "MutatedPreMade" or modelType == "PreMade") and self:HasPreMadeModel(mutationType) then
		return self:ReplaceWithNewMutationStageModel(cropModel, plotModel, mutationType, rarity, stageName)
	end

	-- Method 2: Scale existing mutation model
	return self:ScaleMutationModel(cropModel, mutationType, rarity, stageName)
end

function CropVisualManager:ReplaceWithNewMutationStageModel(oldCropModel, plotModel, mutationType, rarity, stageName)
	print("🔄 Replacing mutation model for new stage: " .. stageName)

	-- Store position
	local oldPosition = oldCropModel.PrimaryPart.CFrame

	-- Create new mutation model for this stage
	local newCropModel = self:CreateMutatedCrop(mutationType, rarity, stageName)
	if not newCropModel then
		return false
	end

	-- Position new model
	newCropModel.Name = "CropModel"
	newCropModel.Parent = plotModel

	if newCropModel.PrimaryPart then
		newCropModel.PrimaryPart.CFrame = oldPosition
	end

	-- IMPORTANT: Setup click detection for new mutation model
	self:SetupCropClickDetection(newCropModel, plotModel, mutationType, rarity)

	-- Remove old model
	oldCropModel:Destroy()

	print("✅ Successfully replaced mutation model for stage " .. stageName .. " with click detection")
	return true
end

function CropVisualManager:ScaleMutationModel(cropModel, mutationType, rarity, stageName)
	print("📏 Scaling mutation model for stage: " .. stageName)

	-- Calculate new scale for mutations (they're bigger than normal crops)
	local rarityScale = self:GetRarityScale(rarity)
	local growthScale = self:GetMutationGrowthScale(stageName)
	local mutationBonus = 1.3 -- Mutations are 30% larger than normal crops
	local targetScale = rarityScale * growthScale * mutationBonus

	-- Get current scale to calculate relative change
	local currentScale = cropModel:GetAttribute("CurrentScale") or 1.0
	local scaleChange = targetScale / currentScale

	-- Apply scaling with smooth transition
	for _, part in pairs(cropModel:GetDescendants()) do
		if part:IsA("BasePart") then
			local targetSize = part.Size * scaleChange

			local tween = TweenService:Create(part,
				TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Size = targetSize}
			)
			tween:Play()
		end
	end

	-- Store new scale
	cropModel:SetAttribute("CurrentScale", targetScale)

	-- Update mutation effects based on stage
	self:UpdateMutationEffectsForStage(cropModel, mutationType, stageName)

	-- IMPORTANT: Ensure click detection is maintained after scaling
	spawn(function()
		wait(2.5) -- Wait for tween to complete

		-- Verify click detection is still working
		local hasWorkingClickDetector = false
		for _, obj in pairs(cropModel:GetDescendants()) do
			if obj:IsA("ClickDetector") and obj.Name == "CropClickDetector" and obj.Parent then
				hasWorkingClickDetector = true
				break
			end
		end

		if not hasWorkingClickDetector then
			print("🖱️ Re-adding click detection to mutation after scaling")
			local plotModel = cropModel.Parent

			if plotModel then
				self:SetupCropClickDetection(cropModel, plotModel, mutationType, rarity)
			end
		end
	end)

	print("📏 Scaled mutation by factor of " .. scaleChange)
	return true
end

function CropVisualManager:GetMutationGrowthScale(growthStage)
	-- Mutations have more dramatic size changes between stages
	local scales = {
		planted = 0.2,     -- Very small start
		sprouting = 0.4,   -- Small but visible
		growing = 0.6,     -- Medium size
		flowering = 0.8,   -- Almost full size
		ready = 1.0        -- Full mutation size
	}
	return scales[growthStage] or 0.5
end

function CropVisualManager:UpdateMutationEffectsForStage(cropModel, mutationType, stageName)
	if not cropModel.PrimaryPart then return end

	-- Remove old stage-specific effects
	for _, obj in pairs(cropModel.PrimaryPart:GetChildren()) do
		if obj.Name:find("StageEffect") then
			obj:Destroy()
		end
	end

	-- Add stage-specific effects for mutations
	if stageName == "planted" then
		self:AddPlantedMutationEffect(cropModel.PrimaryPart, mutationType)
	elseif stageName == "sprouting" then
		self:AddSproutingMutationEffect(cropModel.PrimaryPart, mutationType)
	elseif stageName == "growing" then
		self:AddGrowingMutationEffect(cropModel.PrimaryPart, mutationType)
	elseif stageName == "flowering" then
		self:AddFloweringMutationEffect(cropModel.PrimaryPart, mutationType)
	elseif stageName == "ready" then
		self:AddReadyMutationEffect(cropModel.PrimaryPart, mutationType)
	end
end

function CropVisualManager:AddPlantedMutationEffect(part, mutationType)
	-- Very subtle glow for planted stage
	local light = Instance.new("PointLight")
	light.Name = "StageEffect_Planted"
	light.Parent = part
	light.Color = self:GetMutationColor(mutationType)
	light.Brightness = 0.5
	light.Range = 5
end

function CropVisualManager:AddSproutingMutationEffect(part, mutationType)
	-- Gentle pulsing for sprouting
	local light = Instance.new("PointLight")
	light.Name = "StageEffect_Sprouting"
	light.Parent = part
	light.Color = self:GetMutationColor(mutationType)
	light.Brightness = 1
	light.Range = 8

	-- Add gentle pulsing
	spawn(function()
		while part and part.Parent and light and light.Parent do
			local pulseTween = TweenService:Create(light,
				TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{Brightness = 0.5}
			)
			pulseTween:Play()
			wait(4)
		end
	end)
end

function CropVisualManager:AddGrowingMutationEffect(part, mutationType)
	-- Moderate glow with occasional sparkles
	local light = Instance.new("PointLight")
	light.Name = "StageEffect_Growing"
	light.Parent = part
	light.Color = self:GetMutationColor(mutationType)
	light.Brightness = 1.5
	light.Range = 12

	-- Add occasional sparkles
	spawn(function()
		while part and part.Parent do
			wait(math.random(3, 6))

			if part and part.Parent then
				local sparkle = Instance.new("Part")
				sparkle.Name = "GrowingSparkle"
				sparkle.Size = Vector3.new(0.2, 0.2, 0.2)
				sparkle.Shape = Enum.PartType.Ball
				sparkle.Material = Enum.Material.Neon
				sparkle.Color = self:GetMutationColor(mutationType)
				sparkle.CanCollide = false
				sparkle.Anchored = true
				sparkle.Position = part.Position + Vector3.new(
					math.random(-2, 2),
					math.random(1, 3),
					math.random(-2, 2)
				)
				sparkle.Parent = part.Parent.Parent

				local tween = TweenService:Create(sparkle,
					TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						Position = sparkle.Position + Vector3.new(0, 5, 0),
						Transparency = 1,
						Size = Vector3.new(0.05, 0.05, 0.05)
					}
				)
				tween:Play()
				tween.Completed:Connect(function()
					sparkle:Destroy()
				end)
			end
		end
	end)
end

function CropVisualManager:AddFloweringMutationEffect(part, mutationType)
	-- Bright glow with flowing particles
	local light = Instance.new("PointLight")
	light.Name = "StageEffect_Flowering"
	light.Parent = part
	light.Color = self:GetMutationColor(mutationType)
	light.Brightness = 2
	light.Range = 15

	-- Change material to be more vibrant
	part.Material = Enum.Material.Neon

	-- Add flowing particle stream
	spawn(function()
		while part and part.Parent do
			for i = 1, 2 do
				local particle = Instance.new("Part")
				particle.Name = "FloweringParticle"
				particle.Size = Vector3.new(0.3, 0.3, 0.3)
				particle.Shape = Enum.PartType.Ball
				particle.Material = Enum.Material.Neon
				particle.Color = self:GetMutationColor(mutationType)
				particle.CanCollide = false
				particle.Anchored = true

				local angle = math.random() * math.pi * 2
				local radius = 3
				particle.Position = part.Position + Vector3.new(
					math.cos(angle) * radius,
					math.random(2, 4),
					math.sin(angle) * radius
				)
				particle.Parent = part.Parent.Parent

				local tween = TweenService:Create(particle,
					TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{
						Position = part.Position + Vector3.new(0, 8, 0),
						Transparency = 1,
						Size = Vector3.new(0.1, 0.1, 0.1)
					}
				)
				tween:Play()
				tween.Completed:Connect(function()
					particle:Destroy()
				end)
			end
			wait(1)
		end
	end)
end

function CropVisualManager:AddReadyMutationEffect(part, mutationType)
	-- Maximum glow with continuous particle effects
	local light = Instance.new("PointLight")
	light.Name = "StageEffect_Ready"
	light.Parent = part
	light.Color = self:GetMutationColor(mutationType)
	light.Brightness = 3
	light.Range = 20

	-- Maximum material effect
	part.Material = Enum.Material.Neon

	-- Add continuous particle aura
	spawn(function()
		while part and part.Parent do
			for i = 1, 4 do
				local particle = Instance.new("Part")
				particle.Name = "ReadyParticle"
				particle.Size = Vector3.new(0.4, 0.4, 0.4)
				particle.Shape = Enum.PartType.Ball
				particle.Material = Enum.Material.Neon
				particle.Color = self:GetMutationColor(mutationType)
				particle.CanCollide = false
				particle.Anchored = true

				local offset = Vector3.new(
					math.random(-4, 4),
					math.random(2, 6),
					math.random(-4, 4)
				)
				particle.Position = part.Position + offset
				particle.Parent = part.Parent.Parent

				local tween = TweenService:Create(particle,
					TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						Position = particle.Position + Vector3.new(0, 10, 0),
						Transparency = 1,
						Size = Vector3.new(0.05, 0.05, 0.05)
					}
				)
				tween:Play()
				tween.Completed:Connect(function()
					particle:Destroy()
				end)
			end
			wait(0.5) -- More frequent particles when ready
		end
	end)

	-- Add harvest ready indicator
	local readyIndicator = Instance.new("Part")
	readyIndicator.Name = "HarvestReady"
	readyIndicator.Size = Vector3.new(1, 0.1, 1)
	readyIndicator.Shape = Enum.PartType.Cylinder
	readyIndicator.Material = Enum.Material.Neon
	readyIndicator.Color = Color3.fromRGB(255, 255, 0)
	readyIndicator.CanCollide = false
	readyIndicator.Anchored = true
	readyIndicator.Position = part.Position + Vector3.new(0, 4, 0)
	readyIndicator.Orientation = Vector3.new(0, 0, 90)
	readyIndicator.Parent = part.Parent.Parent

	-- Pulsing ready indicator
	spawn(function()
		while readyIndicator and readyIndicator.Parent do
			local pulse = TweenService:Create(readyIndicator,
				TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{Transparency = 0.8}
			)
			pulse:Play()
			wait(2)
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

	-- Update mutation effects based on stage
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

return CropVisualManager