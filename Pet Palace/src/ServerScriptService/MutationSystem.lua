-- MutationSystem.lua (Module Script)
-- Place in: ServerScriptService/MutationSystem

local MutationSystem = {}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Module references (will be set during initialization)
local ItemConfig = nil
local GameCore = nil
local CropVisualManager = nil

-- ========== INITIALIZATION ==========

function MutationSystem:Initialize(gameCore, cropVisualManager)
	print("MutationSystem: Initializing mutation system...")

	-- Store module references
	GameCore = gameCore
	CropVisualManager = cropVisualManager

	-- Load ItemConfig
	pcall(function()
		ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig", 5))
	end)

	-- Initialize mutation data
	self:InitializeMutationData()

	print("MutationSystem: Mutation system initialized successfully")
	return true
end

function MutationSystem:InitializeMutationData()
	local success, error = pcall(function()
		print("MutationSystem: Initializing SAFE mutation system...")

		-- Mutation configuration
		self.MutationData = {
			-- Define mutation combinations
			Combinations = {
				broccarrot = {
					parents = {"broccoli", "carrot"},
					probability = 0.15, -- 15% chance
					name = "Broccarrot",
					description = "A mysterious hybrid of broccoli and carrot",
					rarity = "rare",
					emoji = "🥦🥕"
				},
				brocmato = {
					parents = {"broccoli", "tomato"},
					probability = 0.12, -- 12% chance
					name = "Brocmato", 
					description = "An unusual fusion of broccoli and tomato",
					rarity = "rare",
					emoji = "🥦🍅"
				},
				broctato = {
					parents = {"broccoli", "potato"},
					probability = 0.10, -- 10% chance
					name = "Broctato",
					description = "A rare blend of broccoli and potato",
					rarity = "epic",
					emoji = "🥦🥔"
				},
				cornmato = {
					parents = {"corn", "tomato"},
					probability = 0.08, -- 8% chance
					name = "Cornmato",
					description = "A golden hybrid of corn and tomato",
					rarity = "epic", 
					emoji = "🌽🍅"
				},
				craddish = {
					parents = {"carrot", "radish"},
					probability = 0.20, -- 20% chance (most common)
					name = "Craddish",
					description = "A spicy cross between carrot and radish",
					rarity = "uncommon",
					emoji = "🥕🌶️"
				}
			},

			-- Track mutation attempts
			MutationAttempts = {},

			-- Store successful mutations
			SuccessfulMutations = {}
		}

		print("MutationSystem: SAFE mutation system initialized with " .. self:CountTable(self.MutationData.Combinations) .. " combinations")
	end)

	if not success then
		warn("MutationSystem: Failed to initialize mutation system: " .. tostring(error))
		-- Create empty system to prevent errors
		self.MutationData = {
			Combinations = {},
			MutationAttempts = {},
			SuccessfulMutations = {}
		}
	end
end

-- ========== IMMEDIATE MUTATION SYSTEM ==========

function MutationSystem:CheckForImmediateMutation(player, newPlotModel, newCropType)
	print("🧬 MutationSystem: Checking for IMMEDIATE mutation with " .. newCropType)

	if not self.MutationData or not self.MutationData.Combinations then
		return false
	end

	local adjacentPlots = self:GetAdjacentPlots(player, newPlotModel)
	print("🧬 Found " .. #adjacentPlots .. " adjacent plots to check")

	for _, adjacentPlot in ipairs(adjacentPlots) do
		local adjacentCropType = adjacentPlot:GetAttribute("PlantType")
		local adjacentGrowthStage = adjacentPlot:GetAttribute("GrowthStage") or 0

		-- Only check plots that have crops planted (any growth stage)
		if adjacentCropType and adjacentCropType ~= "" then
			print("🧬 Checking combination: " .. newCropType .. " + " .. adjacentCropType)

			-- Check all mutation combinations
			for mutationId, mutationData in pairs(self.MutationData.Combinations) do
				local parents = mutationData.parents

				-- Check if these two crops can mutate
				if (parents[1] == newCropType and parents[2] == adjacentCropType) or 
					(parents[2] == newCropType and parents[1] == adjacentCropType) then

					print("🧬 Potential mutation found: " .. mutationId)
					print("🧬 Rolling probability: " .. (mutationData.probability * 100) .. "%")

					-- Roll for mutation chance
					local randomChance = math.random()
					if randomChance <= mutationData.probability then
						print("🎉 MUTATION SUCCESS! Creating " .. mutationId)

						-- Trigger immediate mutation
						return self:CreateImmediateMutation(player, newPlotModel, adjacentPlot, mutationId, mutationData)
					else
						print("🧬 Mutation failed. Rolled " .. (randomChance * 100) .. "% needed " .. (mutationData.probability * 100) .. "%")
					end
				end
			end
		end
	end

	return false
end

function MutationSystem:CreateImmediateMutation(player, plot1, plot2, mutationId, mutationData)
	print("🧬 MutationSystem: Creating immediate mutation " .. mutationId)

	-- Create spectacular combination effect
	self:CreateMutationCombinationEffect(plot1, plot2, mutationData)

	-- Clear both original plots
	self:ClearPlotProperly(plot1)
	self:ClearPlotProperly(plot2)

	-- Choose the primary plot (usually the first one)
	local primaryPlot = plot1
	local secondaryPlot = plot2

	-- Determine mutation rarity (mutations are typically rare or higher)
	local mutationRarity = self:DetermineMutationRarity(mutationData)

	-- Create the mutated crop visual - START AT PLANTED STAGE
	local success = self:CreateMutatedCropVisual(primaryPlot, secondaryPlot, mutationId, mutationRarity, "planted")

	if not success then
		warn("🧬 Failed to create mutated crop visual")
		return false
	end

	-- Update primary plot with mutation data - START AT PLANTED (stage 0)
	primaryPlot:SetAttribute("IsEmpty", false)
	primaryPlot:SetAttribute("PlantType", mutationId)
	primaryPlot:SetAttribute("SeedType", mutationId .. "_mutation")
	primaryPlot:SetAttribute("GrowthStage", 0)  -- Start at planted stage
	primaryPlot:SetAttribute("PlantedTime", os.time())
	primaryPlot:SetAttribute("Rarity", mutationRarity)
	primaryPlot:SetAttribute("IsMutation", true)
	primaryPlot:SetAttribute("MutationType", mutationId)

	-- Ensure secondary plot is marked as empty (will be used for spacing)
	secondaryPlot:SetAttribute("IsEmpty", true)
	secondaryPlot:SetAttribute("PlantType", "")
	secondaryPlot:SetAttribute("GrowthStage", 0)

	-- Start SLOWER growth for mutation (but still slightly faster than normal)
	self:StartMutationGrowthTimer(primaryPlot, mutationId, mutationRarity)

	-- Award player immediately with mutation item
	self:AwardMutationToPlayer(player, mutationId, mutationData)

	-- Update stats
	local playerData = GameCore:GetPlayerData(player)
	if playerData then
		playerData.stats = playerData.stats or {}
		playerData.stats.mutationsCreated = (playerData.stats.mutationsCreated or 0) + 1
		GameCore:SavePlayerData(player)
	end

	-- Send amazing notification
	self:SendMutationNotification(player, mutationData)

	-- Broadcast to other players
	self:BroadcastMutationSuccess(player, mutationData)

	print("🎉 MutationSystem: Successfully created immediate mutation " .. mutationId)
	return true
end

-- ========== MUTATION CROP VISUAL CREATION ==========

function MutationSystem:CreateMutatedCropVisual(primaryPlot, secondaryPlot, mutationId, rarity, growthStage)
	print("🎨 Creating mutated crop visual for " .. mutationId .. " at stage " .. growthStage)

	if CropVisualManager and CropVisualManager.CreateMutatedCrop then
		-- Use CropVisualManager for mutated crop
		local mutatedCrop = CropVisualManager:CreateMutatedCrop(mutationId, rarity, growthStage)

		if mutatedCrop then
			mutatedCrop.Name = "CropModel"
			mutatedCrop.Parent = primaryPlot

			-- Position between the two plots
			if CropVisualManager.PositionMutatedCrop then
				CropVisualManager:PositionMutatedCrop(mutatedCrop, primaryPlot, secondaryPlot)
			end

			-- Setup click detection
			if CropVisualManager.SetupCropClickDetection then
				CropVisualManager:SetupCropClickDetection(mutatedCrop, primaryPlot, mutationId, rarity)
			elseif GameCore and GameCore.SetupCropClickDetection then
				GameCore:SetupCropClickDetection(mutatedCrop, primaryPlot)
			end

			print("✅ Created mutated crop with CropVisualManager and click detection")
			return true
		end
	end

	-- Fallback: Create enhanced mutation crop
	print("🔧 Using fallback for mutated crop creation")
	return self:CreateFallbackMutatedCrop(primaryPlot, mutationId, rarity, growthStage)
end

function MutationSystem:CreateFallbackMutatedCrop(plotModel, mutationId, rarity, growthStage)
	local spotPart = plotModel:FindFirstChild("SpotPart")
	if not spotPart then return false end

	-- Create mutation model appropriate for growth stage
	local mutatedModel = Instance.new("Model")
	mutatedModel.Name = "CropModel"
	mutatedModel.Parent = plotModel

	-- Create crop part sized for the growth stage
	local stageScale = self:GetMutationStageScale(growthStage)
	local baseSize = 2 * stageScale

	local cropPart = Instance.new("Part")
	cropPart.Name = "MutatedCropBody"
	cropPart.Size = Vector3.new(baseSize, baseSize, baseSize)
	cropPart.Material = growthStage == "planted" and Enum.Material.Grass or Enum.Material.Neon
	cropPart.Color = self:GetMutationColor(mutationId)
	cropPart.CanCollide = false
	cropPart.Anchored = true
	cropPart.Position = spotPart.Position + Vector3.new(0, 2 + stageScale, 0)
	cropPart.Parent = mutatedModel

	mutatedModel.PrimaryPart = cropPart

	-- Add effects appropriate for growth stage
	self:AddFallbackMutationEffectsForStage(mutatedModel, mutationId, rarity, growthStage)

	-- Add attributes
	mutatedModel:SetAttribute("CropType", mutationId)
	mutatedModel:SetAttribute("Rarity", rarity)
	mutatedModel:SetAttribute("IsMutation", true)
	mutatedModel:SetAttribute("GrowthStage", growthStage)

	-- Setup click detection
	if GameCore and GameCore.SetupCropClickDetection then
		GameCore:SetupCropClickDetection(mutatedModel, plotModel)
	end

	print("✅ Fallback mutation crop created with click detection")
	return true
end

-- ========== MUTATION GROWTH SYSTEM ==========

function MutationSystem:StartMutationGrowthTimer(plotModel, mutationId, rarity)
	spawn(function()
		-- SLOWER MUTATION GROWTH: 4 minutes total (vs 5 minutes for normal crops)
		local growthTime = 240 -- 4 minutes instead of 2
		local stages = {"planted", "sprouting", "growing", "flowering", "ready"}
		local stageNumbers = {0, 1, 2, 3, 4}
		local stageTime = growthTime / (#stages - 1) -- Divide by 4 stages of growth

		print("🧬 Starting SLOWER mutation growth for " .. mutationId .. " (4 minutes total)")
		print("🧬 Stage time: " .. stageTime .. " seconds per stage")

		for stage = 2, #stages do -- Start from sprouting (index 2)
			wait(stageTime)

			if plotModel and plotModel.Parent then
				local currentStage = plotModel:GetAttribute("GrowthStage") or 0
				local expectedStage = stageNumbers[stage - 1]

				if currentStage == expectedStage then -- Still in expected stage
					local newStageIndex = stageNumbers[stage]
					local newStageName = stages[stage]

					plotModel:SetAttribute("GrowthStage", newStageIndex)

					print("🧬 Mutation " .. mutationId .. " advanced to stage " .. newStageIndex .. " (" .. newStageName .. ")")

					-- Update visual for new stage
					self:UpdateMutationVisualForNewStage(plotModel, mutationId, rarity, newStageName, newStageIndex)

					-- Fire event for CropVisualManager
					if GameCore and GameCore.Events and GameCore.Events.CropGrowthStageChanged then
						GameCore.Events.CropGrowthStageChanged:Fire(plotModel, mutationId, rarity, newStageName, newStageIndex)
					end
				else
					print("🧬 Mutation growth timer stopped - stage mismatch (expected " .. expectedStage .. ", got " .. currentStage .. ")")
					break
				end
			else
				print("🧬 Mutation growth timer stopped - plot no longer exists")
				break
			end
		end

		-- Mark as fully grown
		if plotModel and plotModel.Parent then
			plotModel:SetAttribute("GrowthStage", 4)
			self:UpdateMutationVisualForNewStage(plotModel, mutationId, rarity, "ready", 4)
			print("🧬 Mutation " .. mutationId .. " fully grown and ready for harvest!")

			-- Create final ready effect
			self:CreateMutationReadyEffect(plotModel, mutationId)
		end
	end)
end

function MutationSystem:UpdateMutationVisualForNewStage(plotModel, mutationType, rarity, stageName, stageIndex)
	print("🎨 Updating mutation visual: " .. mutationType .. " to stage " .. stageName)

	local cropModel = plotModel:FindFirstChild("CropModel")
	if not cropModel then
		warn("No CropModel found to update for mutation")
		return false
	end

	-- Method 1: Try CropVisualManager update if available
	if CropVisualManager and CropVisualManager.UpdateMutationStage then
		local success = pcall(function()
			return CropVisualManager:UpdateMutationStage(cropModel, plotModel, mutationType, rarity, stageName, stageIndex)
		end)

		if success then
			print("✅ CropVisualManager updated mutation stage")
			return true
		else
			print("⚠️ CropVisualManager mutation update failed, using fallback")
		end
	end

	-- Method 2: Enhanced fallback visual update for mutations
	local success = self:UpdateMutationVisualFallback(cropModel, mutationType, rarity, stageName, stageIndex)

	-- Re-setup click detection after fallback update
	if success and GameCore and GameCore.SetupCropClickDetection then
		GameCore:SetupCropClickDetection(cropModel, plotModel)
	end

	return success
end

function MutationSystem:UpdateMutationVisualFallback(cropModel, mutationType, rarity, stageName, stageIndex)
	if not cropModel or not cropModel.PrimaryPart then
		warn("Invalid mutation model for visual update")
		return false
	end

	print("🔧 Using fallback visual update for mutation " .. stageName)

	-- Calculate new scale based on mutation growth stage
	local rarityScale = self:GetRaritySizeMultiplier(rarity)
	local stageScale = self:GetMutationStageScale(stageName)
	local mutationBonus = 2.0 -- Mutations are bigger
	local finalScale = rarityScale * stageScale * mutationBonus

	-- Smooth transition to new size
	local currentMesh = cropModel.PrimaryPart:FindFirstChild("SpecialMesh")
	if currentMesh then
		local targetScale = Vector3.new(finalScale, finalScale * 0.8, finalScale)

		local tween = TweenService:Create(currentMesh,
			TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Scale = targetScale}
		)
		tween:Play()
	else
		-- Scale the part directly if no mesh
		local currentSize = cropModel.PrimaryPart.Size
		local targetSize = Vector3.new(
			2 * finalScale,
			2 * finalScale,
			2 * finalScale
		)

		local tween = TweenService:Create(cropModel.PrimaryPart,
			TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = targetSize}
		)
		tween:Play()
	end

	-- Update mutation lighting and effects
	self:UpdateMutationLightingForStage(cropModel, mutationType, rarity, stageName)

	return true
end

-- ========== MUTATION HARVESTING ==========

function MutationSystem:HarvestMatureMutation(player, plotModel, mutationType, rarity)
	print("🧬 MutationSystem: Harvesting mature mutation " .. mutationType .. " (" .. rarity .. ")")

	local playerData = GameCore:GetPlayerData(player)
	if not playerData then 
		GameCore:SendNotification(player, "Error", "Player data not found", "error")
		return false
	end

	-- Get mutation data
	local mutationData = self.MutationData.Combinations[mutationType]
	if not mutationData then
		warn("🧬 Mutation data not found for " .. mutationType)
		mutationData = {
			name = mutationType:gsub("^%l", string.upper),
			description = "A mysterious mutation",
			emoji = "🧬"
		}
	end

	-- Notify CropVisualManager about mutation harvest
	if CropVisualManager and CropVisualManager.OnCropHarvested then
		CropVisualManager:OnCropHarvested(plotModel, mutationType, rarity)
	end

	-- Calculate enhanced yield for mutations
	local baseYield = 2 -- Mutations give more than regular crops
	local rarityMultiplier = ItemConfig and ItemConfig.RaritySystem and ItemConfig.RaritySystem[rarity] and ItemConfig.RaritySystem[rarity].valueMultiplier or 1.5
	local mutationBonus = 1.5 -- Additional bonus for being a mutation
	local finalYield = math.floor(baseYield * rarityMultiplier * mutationBonus)

	-- Add mutations to inventory
	if not playerData.farming then
		playerData.farming = {inventory = {}}
	end
	if not playerData.farming.inventory then
		playerData.farming.inventory = {}
	end

	local currentAmount = playerData.farming.inventory[mutationType] or 0
	playerData.farming.inventory[mutationType] = currentAmount + finalYield

	-- Create spectacular mutation harvest effect
	self:CreateSpectacularMutationHarvestEffect(plotModel, mutationType, rarity)

	-- Clear plot AFTER effects
	spawn(function()
		wait(3) -- Give more time for mutation harvest effects
		self:ClearPlotProperly(plotModel)
	end)

	-- Update stats
	playerData.stats = playerData.stats or {}
	playerData.stats.cropsHarvested = (playerData.stats.cropsHarvested or 0) + finalYield
	playerData.stats.mutationCropsHarvested = (playerData.stats.mutationCropsHarvested or 0) + finalYield
	playerData.stats.rareCropsHarvested = (playerData.stats.rareCropsHarvested or 0) + 1

	-- Track mutation harvest
	local userId = player.UserId
	if not self.MutationData.SuccessfulMutations[userId] then
		self.MutationData.SuccessfulMutations[userId] = {}
	end
	table.insert(self.MutationData.SuccessfulMutations[userId], {
		mutationType = mutationType,
		timestamp = os.time(),
		yield = finalYield,
		harvested = true,
		rarity = rarity
	})

	GameCore:SavePlayerData(player)

	if GameCore.RemoteEvents and GameCore.RemoteEvents.PlayerDataUpdated then
		GameCore.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	-- Send amazing harvest notification
	local rarityEmoji = rarity == "legendary" and "👑" or 
		rarity == "epic" and "💜" or 
		rarity == "rare" and "✨" or 
		rarity == "uncommon" and "💚" or "⚪"

	GameCore:SendNotification(player, "🧬 MUTATION HARVESTED!", 
		"🎉 Harvested " .. finalYield .. "x " .. rarityEmoji .. " " .. rarity .. " " .. mutationData.name .. "!\n" ..
			mutationData.emoji .. " " .. mutationData.description .. "\n" ..
			"💎 Bonus yield from mutation power!", "success")

	-- Broadcast mutation harvest to other players
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			GameCore:SendNotification(otherPlayer, "🧬 Player Achievement!", 
				player.Name .. " harvested a " .. mutationData.name .. " mutation! " .. mutationData.emoji, "info")
		end
	end

	print("🧬 MutationSystem: Successfully harvested " .. finalYield .. "x " .. mutationType .. " (" .. rarity .. ") for " .. player.Name)
	return true
end

-- ========== MUTATION PROCESSING FOR HARVEST ==========

function MutationSystem:ProcessPotentialMutations(player, plotModel)
	local userId = player.UserId
	local plotId = tostring(plotModel)

	local mutationResult = {
		mutated = false,
		mutationType = nil,
		mutationData = nil
	}

	-- Check if this plot has scheduled mutations
	if not self.MutationData.MutationAttempts[userId] or 
		not self.MutationData.MutationAttempts[userId][plotId] then
		return mutationResult
	end

	local mutationAttempt = self.MutationData.MutationAttempts[userId][plotId]

	-- Check each potential mutation
	for _, potentialMutation in ipairs(mutationAttempt.potentialMutations) do
		local mutationData = potentialMutation.mutationData
		local adjacentPlot = potentialMutation.adjacentPlot

		-- Verify adjacent plot still has the required crop and is mature
		if adjacentPlot and adjacentPlot.Parent then
			local adjacentGrowthStage = adjacentPlot:GetAttribute("GrowthStage") or 0
			local adjacentCropType = adjacentPlot:GetAttribute("PlantType") or ""

			-- Both crops must be mature for mutation to occur
			if adjacentGrowthStage >= 4 and 
				(adjacentCropType == potentialMutation.cropTypes[1] or adjacentCropType == potentialMutation.cropTypes[2]) then

				-- Roll for mutation chance
				local randomChance = math.random()
				print("🧬 Mutation roll for " .. potentialMutation.mutationId .. ": " .. randomChance .. " vs " .. mutationData.probability)

				if randomChance <= mutationData.probability then
					-- MUTATION SUCCESSFUL!
					mutationResult.mutated = true
					mutationResult.mutationType = potentialMutation.mutationId
					mutationResult.mutationData = mutationData
					mutationResult.adjacentPlot = adjacentPlot

					print("🧬 MUTATION SUCCESS: " .. potentialMutation.mutationId .. " created!")
					break
				end
			end
		end
	end

	-- Clean up mutation attempt data
	self.MutationData.MutationAttempts[userId][plotId] = nil

	return mutationResult
end

function MutationSystem:HarvestMutatedCrop(player, plotModel, mutationResult)
	print("🧬 MutationSystem: Harvesting MUTATED crop - " .. mutationResult.mutationType)

	local playerData = GameCore:GetPlayerData(player)
	local mutationData = mutationResult.mutationData

	-- Create spectacular mutation harvest effect
	self:CreateMutationHarvestEffect(plotModel, mutationResult)

	-- Clear both plots (original and adjacent)
	self:ClearPlotProperly(plotModel)
	if mutationResult.adjacentPlot then
		self:ClearPlotProperly(mutationResult.adjacentPlot)
	end

	-- Add mutated crop to inventory
	if not playerData.farming then
		playerData.farming = {inventory = {}}
	end
	if not playerData.farming.inventory then
		playerData.farming.inventory = {}
	end

	local mutationId = mutationResult.mutationType
	local currentAmount = playerData.farming.inventory[mutationId] or 0
	local mutationYield = 1 -- Mutations typically give 1 special crop

	-- Bonus yield for higher rarity mutations
	if mutationData.rarity == "epic" then
		mutationYield = math.random(1, 2)
	elseif mutationData.rarity == "legendary" then
		mutationYield = math.random(2, 3)
	end

	playerData.farming.inventory[mutationId] = currentAmount + mutationYield

	-- Update stats
	playerData.stats = playerData.stats or {}
	playerData.stats.cropsHarvested = (playerData.stats.cropsHarvested or 0) + mutationYield
	playerData.stats.mutationsCreated = (playerData.stats.mutationsCreated or 0) + 1
	playerData.stats.rareCropsHarvested = (playerData.stats.rareCropsHarvested or 0) + 1

	-- Track successful mutation
	local userId = player.UserId
	if not self.MutationData.SuccessfulMutations[userId] then
		self.MutationData.SuccessfulMutations[userId] = {}
	end
	table.insert(self.MutationData.SuccessfulMutations[userId], {
		mutationType = mutationId,
		timestamp = os.time(),
		yield = mutationYield
	})

	GameCore:SavePlayerData(player)

	if GameCore.RemoteEvents and GameCore.RemoteEvents.PlayerDataUpdated then
		GameCore.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	-- Send exciting mutation notification
	GameCore:SendNotification(player, "🧬 CROP MUTATION!", 
		mutationData.emoji .. " " .. mutationData.name .. " created!\n" ..
			"Harvested " .. mutationYield .. "x " .. mutationData.name .. "!\n" ..
			mutationData.description, "success")

	-- Broadcast to other players (optional)
	self:BroadcastMutationSuccess(player, mutationData)

	print("🧬 MutationSystem: Successfully created " .. mutationYield .. "x " .. mutationId .. " for " .. player.Name)
	return true
end

-- ========== HELPER METHODS ==========

function MutationSystem:GetAdjacentPlots(player, centerPlot)
	print("🧬 Getting adjacent plots for " .. centerPlot.Name)

	local adjacentPlots = {}

	-- Get plot grid position
	local plotRow = centerPlot:GetAttribute("GridRow")
	local plotCol = centerPlot:GetAttribute("GridCol")

	if not plotRow or not plotCol then
		warn("MutationSystem: Plot missing grid coordinates for " .. centerPlot.Name)
		return {}
	end

	print("🧬 Center plot at grid position: (" .. plotRow .. ", " .. plotCol .. ")")

	-- Find player's farm
	local farm = GameCore:GetPlayerSimpleFarm(player)
	if not farm then 
		warn("MutationSystem: No farm found for " .. player.Name)
		return {} 
	end

	local plantingSpots = farm:FindFirstChild("PlantingSpots")
	if not plantingSpots then 
		warn("MutationSystem: No PlantingSpots folder found")
		return {} 
	end

	-- Check adjacent positions (up, down, left, right)
	local adjacentPositions = {
		{plotRow - 1, plotCol},     -- Up
		{plotRow + 1, plotCol},     -- Down
		{plotRow, plotCol - 1},     -- Left
		{plotRow, plotCol + 1}      -- Right
	}

	print("🧬 Checking " .. #adjacentPositions .. " adjacent positions...")

	for i, pos in ipairs(adjacentPositions) do
		local targetRow, targetCol = pos[1], pos[2]
		print("🧬 Looking for plot at (" .. targetRow .. ", " .. targetCol .. ")")

		-- Find plot at this position
		for _, spot in pairs(plantingSpots:GetChildren()) do
			if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
				local spotRow = spot:GetAttribute("GridRow")
				local spotCol = spot:GetAttribute("GridCol")

				if spotRow == targetRow and spotCol == targetCol then
					table.insert(adjacentPlots, spot)

					local plantType = spot:GetAttribute("PlantType") or "empty"
					local growthStage = spot:GetAttribute("GrowthStage") or 0
					print("🧬 Found adjacent plot: " .. spot.Name .. " with " .. plantType .. " (stage " .. growthStage .. ")")
					break
				end
			end
		end
	end

	print("🧬 Found " .. #adjacentPlots .. " adjacent plots to " .. centerPlot.Name)
	return adjacentPlots
end

function MutationSystem:ClearPlotProperly(plotModel)
	if GameCore and GameCore.ClearPlotProperly then
		return GameCore:ClearPlotProperly(plotModel)
	end

	-- Fallback plot clearing
	if plotModel then
		for _, child in pairs(plotModel:GetChildren()) do
			if child:IsA("Model") and child.Name == "CropModel" then
				child:Destroy()
			end
		end

		plotModel:SetAttribute("IsEmpty", true)
		plotModel:SetAttribute("PlantType", "")
		plotModel:SetAttribute("GrowthStage", 0)
	end
end

-- ========== VISUAL EFFECTS ==========

function MutationSystem:CreateMutationCombinationEffect(plot1, plot2, mutationData)
	-- Get positions of both plots
	local spot1 = plot1:FindFirstChild("SpotPart")
	local spot2 = plot2:FindFirstChild("SpotPart")

	if not spot1 or not spot2 then return end

	local pos1 = spot1.Position
	local pos2 = spot2.Position
	local centerPos = (pos1 + pos2) / 2

	-- Create spectacular combination effect
	spawn(function()
		-- Lightning effect between the two crops
		for i = 1, 5 do
			local lightning = Instance.new("Part")
			lightning.Name = "MutationLightning"
			lightning.Size = Vector3.new(0.2, 0.2, (pos1 - pos2).Magnitude)
			lightning.Material = Enum.Material.Neon
			lightning.Color = Color3.fromRGB(255, 255, 100)
			lightning.CanCollide = false
			lightning.Anchored = true
			lightning.CFrame = CFrame.lookAt(centerPos, pos2)
			lightning.Parent = workspace

			-- Flash effect
			local flashTween = TweenService:Create(lightning,
				TweenInfo.new(0.5, Enum.EasingStyle.Quad),
				{Transparency = 1}
			)
			flashTween:Play()
			flashTween.Completed:Connect(function()
				lightning:Destroy()
			end)

			wait(0.1)
		end

		-- Explosion effect at center
		local explosion = Instance.new("Explosion")
		explosion.Position = centerPos + Vector3.new(0, 5, 0)
		explosion.BlastRadius = 20
		explosion.BlastPressure = 0
		explosion.Parent = workspace

		-- Mutation particles
		for i = 1, 20 do
			local particle = Instance.new("Part")
			particle.Size = Vector3.new(0.5, 0.5, 0.5)
			particle.Shape = Enum.PartType.Ball
			particle.Material = Enum.Material.Neon
			particle.Color = Color3.fromRGB(
				math.random(100, 255),
				math.random(100, 255),
				math.random(100, 255)
			)
			particle.CanCollide = false
			particle.Anchored = true
			particle.Position = centerPos + Vector3.new(
				math.random(-5, 5),
				math.random(0, 10),
				math.random(-5, 5)
			)
			particle.Parent = workspace

			local tween = TweenService:Create(particle,
				TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = particle.Position + Vector3.new(0, 15, 0),
					Transparency = 1,
					Size = Vector3.new(0.1, 0.1, 0.1)
				}
			)
			tween:Play()
			tween.Completed:Connect(function()
				particle:Destroy()
			end)
		end
	end)

	print("🎆 Created spectacular mutation combination effect")
end

function MutationSystem:CreateMutationHarvestEffect(plotModel, mutationResult)
	local cropModel = plotModel:FindFirstChild("CropModel")
	if not cropModel or not cropModel.PrimaryPart then return end

	local position = cropModel.PrimaryPart.Position
	local mutationData = mutationResult.mutationData

	-- Create spectacular mutation effect
	for i = 1, 10 do
		spawn(function()
			wait(i * 0.05)

			local particle = Instance.new("Part")
			particle.Name = "MutationParticle"
			particle.Size = Vector3.new(0.5, 0.5, 0.5)
			particle.Shape = Enum.PartType.Ball
			particle.Material = Enum.Material.Neon
			particle.CanCollide = false
			particle.Anchored = true

			-- Color based on mutation rarity
			if mutationData.rarity == "legendary" then
				particle.Color = Color3.fromRGB(255, 100, 255)
			elseif mutationData.rarity == "epic" then
				particle.Color = Color3.fromRGB(128, 0, 255)
			elseif mutationData.rarity == "rare" then
				particle.Color = Color3.fromRGB(255, 215, 0)
			else
				particle.Color = Color3.fromRGB(0, 255, 100)
			end

			particle.Position = position + Vector3.new(
				(math.random() - 0.5) * 8,
				math.random() * 5,
				(math.random() - 0.5) * 8
			)
			particle.Parent = workspace

			local tween = TweenService:Create(particle,
				TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = particle.Position + Vector3.new(0, 15, 0),
					Transparency = 1,
					Size = Vector3.new(0.1, 0.1, 0.1)
				}
			)
			tween:Play()
			tween.Completed:Connect(function()
				particle:Destroy()
			end)
		end)
	end

	-- Play mutation sound
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://131961136" -- Replace with mutation sound
	sound.Volume = 1
	sound.Parent = cropModel.PrimaryPart
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

function MutationSystem:CreateSpectacularMutationHarvestEffect(plotModel, mutationType, rarity)
	local cropModel = plotModel:FindFirstChild("CropModel")
	if not cropModel or not cropModel.PrimaryPart then return end

	local position = cropModel.PrimaryPart.Position
	local mutationColor = self:GetMutationColor(mutationType)

	print("🎆 Creating spectacular mutation harvest effect for " .. mutationType)

	-- Create enhanced explosion effect
	local explosion = Instance.new("Explosion")
	explosion.Position = position + Vector3.new(0, 3, 0)
	explosion.BlastRadius = 25
	explosion.BlastPressure = 0
	explosion.Parent = workspace

	-- Create swirling mutation energy
	for i = 1, 15 do
		spawn(function()
			wait(i * 0.1)

			local energyOrb = Instance.new("Part")
			energyOrb.Name = "MutationHarvestEnergy"
			energyOrb.Size = Vector3.new(0.8, 0.8, 0.8)
			energyOrb.Shape = Enum.PartType.Ball
			energyOrb.Material = Enum.Material.Neon
			energyOrb.Color = mutationColor
			energyOrb.CanCollide = false
			energyOrb.Anchored = true

			-- Start in a spiral around the mutation
			local angle = (i / 15) * math.pi * 4 -- 2 full rotations
			local radius = 3 + math.sin(angle) * 1
			local startPos = position + Vector3.new(
				math.cos(angle) * radius,
				math.sin(i * 0.5) * 2,
				math.sin(angle) * radius
			)
			energyOrb.Position = startPos
			energyOrb.Parent = workspace

			-- Animate to spiral upward
			local endPos = position + Vector3.new(0, 20, 0)
			local tween = TweenService:Create(energyOrb,
				TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = endPos,
					Transparency = 1,
					Size = Vector3.new(0.2, 0.2, 0.2)
				}
			)
			tween:Play()
			tween.Completed:Connect(function()
				energyOrb:Destroy()
			end)
		end)
	end

	-- Create rarity-specific bonus effects
	if rarity == "epic" or rarity == "legendary" then
		-- Add extra lightning effects for high rarity
		for i = 1, 8 do
			spawn(function()
				wait(i * 0.2)

				local lightning = Instance.new("Part")
				lightning.Name = "RarityLightning"
				lightning.Size = Vector3.new(0.3, 20, 0.3)
				lightning.Material = Enum.Material.Neon
				lightning.Color = rarity == "legendary" and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(128, 0, 128)
				lightning.CanCollide = false
				lightning.Anchored = true
				lightning.Position = position + Vector3.new(
					math.random(-8, 8),
					10,
					math.random(-8, 8)
				)
				lightning.Parent = workspace

				local tween = TweenService:Create(lightning,
					TweenInfo.new(1, Enum.EasingStyle.Quad),
					{Transparency = 1}
				)
				tween:Play()
				tween.Completed:Connect(function()
					lightning:Destroy()
				end)
			end)
		end
	end

	-- Play mutation harvest sound
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://131961136" -- Replace with your preferred sound
	sound.Volume = 0.7
	sound.Parent = cropModel.PrimaryPart
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

function MutationSystem:CreateMutationReadyEffect(plotModel, mutationId)
	local cropModel = plotModel:FindFirstChild("CropModel")
	if not cropModel or not cropModel.PrimaryPart then return end

	local position = cropModel.PrimaryPart.Position

	-- Create ready-to-harvest effect
	for i = 1, 8 do
		local readyParticle = Instance.new("Part")
		readyParticle.Size = Vector3.new(0.4, 0.4, 0.4)
		readyParticle.Shape = Enum.PartType.Ball
		readyParticle.Material = Enum.Material.Neon
		readyParticle.Color = Color3.fromRGB(255, 255, 0) -- Golden ready color
		readyParticle.CanCollide = false
		readyParticle.Anchored = true
		readyParticle.Position = position + Vector3.new(
			math.random(-3, 3),
			math.random(2, 5),
			math.random(-3, 3)
		)
		readyParticle.Parent = workspace

		local tween = TweenService:Create(readyParticle,
			TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = readyParticle.Position + Vector3.new(0, 8, 0),
				Transparency = 1,
				Size = Vector3.new(0.1, 0.1, 0.1)
			}
		)
		tween:Play()
		tween.Completed:Connect(function()
			readyParticle:Destroy()
		end)
	end

	print("✨ Created mutation ready effect for " .. mutationId)
end

-- ========== UTILITY METHODS ==========

function MutationSystem:GetMutationColor(mutationId)
	local colors = {
		broccarrot = Color3.fromRGB(100, 200, 50),
		brocmato = Color3.fromRGB(150, 100, 50),
		broctato = Color3.fromRGB(120, 80, 100),
		cornmato = Color3.fromRGB(200, 150, 50),
		craddish = Color3.fromRGB(200, 100, 50)
	}
	return colors[mutationId] or Color3.fromRGB(150, 150, 150)
end

function MutationSystem:GetMutationStageScale(growthStage)
	local scales = {
		planted = 0.3,
		sprouting = 0.5,
		growing = 0.7,
		flowering = 0.9,
		ready = 1.2  -- Mutations are bigger when ready
	}
	return scales[growthStage] or 0.5
end

function MutationSystem:GetRaritySizeMultiplier(rarity)
	if rarity == "legendary" then
		return 1.5
	elseif rarity == "epic" then
		return 1.3
	elseif rarity == "rare" then
		return 1.2
	elseif rarity == "uncommon" then
		return 1.1
	else
		return 1.0
	end
end

function MutationSystem:UpdateMutationLightingForStage(cropModel, mutationType, rarity, stageName)
	local cropPart = cropModel.PrimaryPart
	if not cropPart then return end

	-- Remove old stage effects
	for _, obj in pairs(cropPart:GetChildren()) do
		if obj:IsA("PointLight") then
			obj:Destroy()
		end
	end

	-- Add new stage-appropriate lighting
	local light = Instance.new("PointLight")
	light.Parent = cropPart
	light.Color = self:GetMutationColor(mutationType)

	if stageName == "planted" then
		light.Brightness = 0.5
		light.Range = 5
		cropPart.Material = Enum.Material.Grass
	elseif stageName == "sprouting" then
		light.Brightness = 1
		light.Range = 8
		cropPart.Material = Enum.Material.Plastic
	elseif stageName == "growing" then
		light.Brightness = 1.5
		light.Range = 12
		cropPart.Material = Enum.Material.SmoothPlastic
	elseif stageName == "flowering" then
		light.Brightness = 2
		light.Range = 15
		cropPart.Material = Enum.Material.Neon
	elseif stageName == "ready" then
		light.Brightness = 3
		light.Range = 20
		cropPart.Material = Enum.Material.Neon
	end
end

function MutationSystem:AddFallbackMutationEffectsForStage(mutatedModel, mutationId, rarity, growthStage)
	local cropPart = mutatedModel.PrimaryPart
	if not cropPart then return end

	-- Stage-appropriate lighting
	local light = Instance.new("PointLight")
	light.Parent = cropPart
	light.Color = self:GetMutationColor(mutationId)

	if growthStage == "planted" then
		light.Brightness = 0.5
		light.Range = 5
	elseif growthStage == "sprouting" then
		light.Brightness = 1
		light.Range = 8
	elseif growthStage == "growing" then
		light.Brightness = 1.5
		light.Range = 12
	elseif growthStage == "flowering" then
		light.Brightness = 2
		light.Range = 15
		cropPart.Material = Enum.Material.Neon
	elseif growthStage == "ready" then
		light.Brightness = 3
		light.Range = 20
		cropPart.Material = Enum.Material.Neon

		-- Add pulsing for ready stage
		spawn(function()
			while cropPart and cropPart.Parent do
				local pulseTween = TweenService:Create(light,
					TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
					{Brightness = 1}
				)
				pulseTween:Play()
				wait(2)
			end
		end)
	end
end

function MutationSystem:DetermineMutationRarity(mutationData)
	-- Mutations are inherently rare
	local baseRarity = mutationData.rarity or "rare"

	-- Small chance for higher rarity
	local rarityRoll = math.random()
	if rarityRoll <= 0.05 then -- 5% chance
		return "legendary"
	elseif rarityRoll <= 0.15 then -- 10% chance
		return "epic"
	else
		return baseRarity
	end
end

function MutationSystem:AwardMutationToPlayer(player, mutationId, mutationData)
	local playerData = GameCore:GetPlayerData(player)
	if not playerData then return end

	-- Add mutation to inventory immediately
	playerData.farming = playerData.farming or {inventory = {}}
	playerData.farming.inventory = playerData.farming.inventory or {}

	local currentAmount = playerData.farming.inventory[mutationId] or 0
	local mutationYield = 1 -- Always give 1 mutation item immediately

	playerData.farming.inventory[mutationId] = currentAmount + mutationYield

	-- Track successful mutation
	local userId = player.UserId
	if not self.MutationData.SuccessfulMutations[userId] then
		self.MutationData.SuccessfulMutations[userId] = {}
	end
	table.insert(self.MutationData.SuccessfulMutations[userId], {
		mutationType = mutationId,
		timestamp = os.time(),
		yield = mutationYield,
		immediate = true
	})

	GameCore:SavePlayerData(player)

	if GameCore.RemoteEvents and GameCore.RemoteEvents.PlayerDataUpdated then
		GameCore.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	print("🧬 Awarded " .. mutationYield .. "x " .. mutationId .. " to " .. player.Name .. " immediately")
end

function MutationSystem:SendMutationNotification(player, mutationData)
	GameCore:SendNotification(player, "🧬 INCREDIBLE MUTATION!", 
		mutationData.emoji .. " " .. mutationData.name .. " CREATED!\n" ..
			mutationData.description .. "\n" ..
			"🎁 Awarded 1x " .. mutationData.name .. " immediately!\n" ..
			"⏱️ Growing slower to show all stages!\n" ..
			"🌱 Watch it grow through all 5 stages!", "success")
end

function MutationSystem:BroadcastMutationSuccess(player, mutationData)
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			GameCore:SendNotification(otherPlayer, "🧬 Player Achievement!", 
				player.Name .. " created a " .. mutationData.name .. " mutation! " .. mutationData.emoji, "info")
		end
	end

	print("🧬 Broadcasted mutation success for " .. player.Name)
end

function MutationSystem:CountTable(tbl)
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

-- ========== ADMIN COMMANDS ==========

function MutationSystem:SetupMutationAdminCommands()
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Replace with your username
				local args = string.split(message:lower(), " ")
				local command = args[1]

				if command == "/testmutation" then
					local mutationType = args[2] or "broccarrot"
					local targetName = args[3] or player.Name
					local targetPlayer = Players:FindFirstChild(targetName)

					if targetPlayer then
						print("Admin: Testing " .. mutationType .. " mutation for " .. targetPlayer.Name)
						self:AwardMutationToPlayer(targetPlayer, mutationType, self.MutationData.Combinations[mutationType])
					end

				elseif command == "/mutationstats" then
					local targetName = args[2] or player.Name
					local targetPlayer = Players:FindFirstChild(targetName)

					if targetPlayer then
						print("=== MUTATION STATS FOR " .. targetPlayer.Name .. " ===")
						local userId = targetPlayer.UserId

						if self.MutationData.SuccessfulMutations[userId] then
							local mutations = self.MutationData.SuccessfulMutations[userId]
							print("Successful mutations: " .. #mutations)

							for i, mutation in ipairs(mutations) do
								local timeAgo = os.time() - mutation.timestamp
								local immediateText = mutation.immediate and " (IMMEDIATE)" or ""
								print("  " .. i .. ": " .. mutation.mutationType .. " - " .. timeAgo .. "s ago" .. immediateText)
							end
						else
							print("No successful mutations")
						end
						print("=====================================")
					end

				elseif command == "/forcemutation" then
					local mutationType = args[2] or "broccarrot"

					print("🧬 Force triggering " .. mutationType .. " mutation...")

					-- Set probability to 100% temporarily
					if self.MutationData.Combinations[mutationType] then
						local originalProb = self.MutationData.Combinations[mutationType].probability
						self.MutationData.Combinations[mutationType].probability = 1.0

						print("🧬 Set " .. mutationType .. " probability to 100%")
						print("🧬 Now harvest one of your crops to trigger mutation")

						-- Reset probability after 30 seconds
						spawn(function()
							wait(30)
							self.MutationData.Combinations[mutationType].probability = originalProb
							print("🧬 Reset " .. mutationType .. " probability to " .. (originalProb * 100) .. "%")
						end)

						GameCore:SendNotification(player, "🧬 Force Mutation", 
							"Set " .. mutationType .. " to 100% chance for 30 seconds!", "success")
					else
						print("❌ Mutation type not found: " .. mutationType)
					end
				end
			end
		end)
	end)
end

print("MutationSystem: ✅ Module loaded successfully!")

return MutationSystem