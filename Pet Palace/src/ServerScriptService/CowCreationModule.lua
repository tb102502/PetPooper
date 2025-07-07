--[[
    CowCreationModule.lua - Handles all cow creation, spawning, and management
    Place in: ServerScriptService/CowCreationModule.lua
    
    Features:
    ✅ Multiple cow creation and positioning
    ✅ Cow tier progression system  
    ✅ Visual effects and tier management
    ✅ Cow data management and validation
    ✅ Integration with GameCore data system
]]

local CowCreationModule = {}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Module State
CowCreationModule.ActiveCows = {} -- [cowId] = cowModel
CowCreationModule.CowEffects = {} -- [cowId] = {effectObjects}
CowCreationModule.NextCowId = 1
CowCreationModule.PlayerCowPositions = {} -- [userId] = {usedPositions}

-- Configuration
CowCreationModule.Config = {
	basePosition = Vector3.new(-272.168, -2.068, 53.406),
	spacing = Vector3.new(8, 0, 8),
	rowSize = 5,
	playerSeparation = Vector3.new(60, 0, 0),
	maxCowsPerPlayer = 10
}

-- References (injected on initialize)
local GameCore = nil
local ItemConfig = nil

-- ========== INITIALIZATION ==========

function CowCreationModule:Initialize(gameCore, itemConfig)
	print("CowCreationModule: Initializing cow creation system...")

	GameCore = gameCore
	ItemConfig = itemConfig

	-- Initialize tracking systems
	self:InitializeCowTracking()

	-- Scan for existing cows
	self:ScanForExistingCows()

	-- Start monitoring
	self:StartCowMonitoring()

	print("CowCreationModule: Cow creation system initialized!")
	return true
end

function CowCreationModule:InitializeCowTracking()
	self.ActiveCows = {}
	self.CowEffects = {}
	self.PlayerCowPositions = {}
	self.NextCowId = 1

	print("CowCreationModule: Tracking systems initialized")
end

function CowCreationModule:ScanForExistingCows()
	print("CowCreationModule: Scanning for existing cows...")

	local cowCount = 0
	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("Model") and obj.Name:find("cow_") then
			local cowId = obj.Name
			local owner = obj:GetAttribute("Owner")

			if owner then
				self:RegisterExistingCow(obj, cowId, owner)
				cowCount = cowCount + 1
			end
		end
	end

	print("CowCreationModule: Found " .. cowCount .. " existing cows")
end

function CowCreationModule:RegisterExistingCow(cowModel, cowId, ownerName)
	-- Store cow reference
	self.ActiveCows[cowId] = cowModel

	-- Apply tier effects if cow has tier
	local tier = cowModel:GetAttribute("Tier") or "basic"
	self:ApplyTierEffects(cowModel, tier)

	print("CowCreationModule: Registered existing cow " .. cowId .. " (tier: " .. tier .. ")")
end

-- ========== COW CREATION SYSTEM ==========

function CowCreationModule:GetCowConfiguration(cowType)
	print("🐄 CowCreationModule: Getting cow configuration for " .. cowType)

	if not ItemConfig or not ItemConfig.ShopItems then 
		warn("🐄 CowCreationModule: ItemConfig not available")
		return nil 
	end

	local item = ItemConfig.ShopItems[cowType]
	if not item then
		warn("🐄 CowCreationModule: Item not found: " .. cowType)
		return nil
	end

	if not item.cowData then
		warn("🐄 CowCreationModule: Item has no cowData: " .. cowType)
		return nil
	end

	print("🐄 CowCreationModule: Found cow configuration for " .. cowType)
	return item.cowData
end

function CowCreationModule:PurchaseCow(player, cowType, upgradeFromCowId)
	print("🐄 CowCreationModule: Processing cow purchase - " .. player.Name .. " buying " .. cowType)

	if not GameCore then
		warn("CowCreationModule: GameCore not available")
		return false
	end

	local playerData = GameCore:GetPlayerData(player)
	if not playerData then 
		warn("🐄 CowCreationModule: No player data for " .. player.Name)
		return false 
	end

	-- Get cow configuration
	local cowConfig = self:GetCowConfiguration(cowType)
	if not cowConfig then
		self:SendNotification(player, "Invalid Cow", "Cow configuration not found for: " .. cowType, "error")
		return false
	end

	-- Check if this is an upgrade
	if upgradeFromCowId then
		return self:UpgradeCow(player, upgradeFromCowId, cowType, cowConfig)
	else
		return self:CreateNewCow(player, cowType, cowConfig)
	end
end

function CowCreationModule:CreateNewCow(player, cowType, cowConfig)
	local userId = player.UserId

	-- Check cow limits
	local currentCowCount = self:GetPlayerCowCount(player)
	local maxCows = self.Config.maxCowsPerPlayer

	if currentCowCount >= maxCows then
		self:SendNotification(player, "Cow Limit Reached", 
			"You have " .. currentCowCount .. "/" .. maxCows .. " cows!")
		return false
	end

	-- Generate unique cow ID
	local cowId = self:GenerateUniqueCowId(userId)
	if not cowId then
		self:SendNotification(player, "ID Generation Failed", "Could not generate unique cow ID!", "error")
		return false
	end

	-- Find position for new cow
	local position = self:GetNextCowPosition(player)
	if not position then
		self:SendNotification(player, "No Space", "Cannot find space for new cow!", "error")
		return false
	end

	-- Create cow data
	local cowData = {
		cowId = cowId,
		tier = cowConfig.tier,
		milkAmount = cowConfig.milkAmount,
		cooldown = cowConfig.cooldown,
		position = position,
		lastMilkCollection = 0,
		totalMilkProduced = 0,
		purchaseTime = os.time(),
		visualEffects = cowConfig.visualEffects or {}
	}
	local playerData = self:GetPlayerData(player)
	-- Store in player data
	if not playerData.livestock then
		playerData.livestock = {cows = {}}
	end
	if not playerData.livestock.cows then
		playerData.livestock.cows = {}
	end
	playerData.livestock.cows[cowId] = cowData

	-- Create physical cow model
	local success = self:CreateCowModel(player, cowId, cowData)
	if not success then
		-- Clean up on failure
		playerData.livestock.cows[cowId] = nil
		return false
	end

	-- Save data
	if GameCore.SavePlayerData then
		GameCore:SavePlayerData(player)
	end

	self:SendNotification(player, "🐄 Cow Purchased!", 
		"Added " .. self:GetCowDisplayName(cowConfig.tier) .. " to your farm!", "success")

	print("🐄 CowCreationModule: Successfully created new cow " .. cowId .. " for " .. player.Name)
	return true
end

function CowCreationModule:UpgradeCow(player, cowId, newTier, cowConfig)
	if not GameCore then return false end

	local playerData = GameCore:GetPlayerData(player)
	local userId = player.UserId

	-- Validate existing cow
	local cowData = playerData.livestock and playerData.livestock.cows and playerData.livestock.cows[cowId]
	if not cowData then
		self:SendNotification(player, "Cow Not Found", "Cannot find cow to upgrade!", "error")
		return false
	end

	-- Check upgrade path
	if cowConfig.upgradeFrom and cowData.tier ~= cowConfig.upgradeFrom then
		self:SendNotification(player, "Invalid Upgrade", 
			"Can only upgrade " .. cowConfig.upgradeFrom .. " cows to " .. newTier .. "!", "error")
		return false
	end

	local oldTier = cowData.tier

	-- Update cow data
	cowData.tier = cowConfig.tier
	cowData.milkAmount = cowConfig.milkAmount
	cowData.cooldown = cowConfig.cooldown
	cowData.visualEffects = cowConfig.visualEffects or {}
	cowData.upgradeTime = os.time()

	-- Update visual appearance
	self:UpdateCowVisuals(cowId, cowData)

	-- Save data
	if GameCore.SavePlayerData then
		GameCore:SavePlayerData(player)
	end

	self:SendNotification(player, "🌟 Cow Upgraded!", 
		"Upgraded " .. self:GetCowDisplayName(oldTier) .. " to " .. self:GetCowDisplayName(newTier) .. "!", "success")

	print("🐄 CowCreationModule: Upgraded cow " .. cowId .. " from " .. oldTier .. " to " .. newTier)
	return true
end

-- ========== COW MODEL CREATION ==========

function CowCreationModule:CreateCowModel(player, cowId, cowData)
	local success, error = pcall(function()
		-- Find original cow model to clone
		local originalCow = workspace:FindFirstChild("cow")
		if not originalCow then
			error("Original cow model not found in workspace")
		end

		-- Clone the cow model
		local newCow = originalCow:Clone()
		newCow.Name = cowId
		newCow.Parent = workspace

		-- Position the cow
		if newCow.PrimaryPart then
			newCow:PivotTo(CFrame.new(cowData.position))
		else
			-- Fallback positioning
			for _, part in pairs(newCow:GetChildren()) do
				if part:IsA("BasePart") then
					part.Position = cowData.position
					break
				end
			end
		end

		-- Store model reference
		self.ActiveCows[cowId] = newCow

		-- Add cow identification
		newCow:SetAttribute("CowId", cowId)
		newCow:SetAttribute("Owner", player.Name)
		newCow:SetAttribute("Tier", cowData.tier)

		-- Apply visual effects
		self:ApplyTierEffects(newCow, cowData.tier)

		print("🐄 CowCreationModule: Created model for cow " .. cowId)
		return true
	end)

	if not success then
		warn("CowCreationModule: Failed to create cow model: " .. tostring(error))
		return false
	end

	return true
end

function CowCreationModule:UpdateCowVisuals(cowId, cowData)
	local cowModel = self.ActiveCows[cowId]
	if not cowModel then return end

	-- Update tier attributes
	cowModel:SetAttribute("Tier", cowData.tier)

	-- Reapply visual effects
	self:ApplyTierEffects(cowModel, cowData.tier)

	print("CowCreationModule: Updated visuals for cow " .. cowId)
end

-- ========== VISUAL EFFECTS SYSTEM ==========

function CowCreationModule:ApplyTierEffects(cowModel, tier)
	print("CowCreationModule: Applying " .. tier .. " tier effects")

	-- Remove existing effects
	self:ClearCowEffects(cowModel)

	-- Apply tier-specific effects
	if tier == "silver" then
		self:ApplySilverEffects(cowModel)
	elseif tier == "gold" then
		self:ApplyGoldEffects(cowModel)
	elseif tier == "diamond" then
		self:ApplyDiamondEffects(cowModel)
	elseif tier == "rainbow" then
		self:ApplyRainbowEffects(cowModel)
	elseif tier == "cosmic" then
		self:ApplyCosmicEffects(cowModel)
	end
end

function CowCreationModule:ApplySilverEffects(cowModel)
	-- Change material and color
	for _, part in pairs(cowModel:GetDescendants()) do
		if part:IsA("BasePart") and self:IsCowBodyPart(part) then
			part.Material = Enum.Material.Metal
			part.Color = Color3.fromRGB(192, 192, 192)
		end
	end

	-- Add subtle particle effect
	self:CreateParticleEffect(cowModel, Color3.fromRGB(220, 220, 220), 2)
end

function CowCreationModule:ApplyGoldEffects(cowModel)
	-- Change to gold appearance
	for _, part in pairs(cowModel:GetDescendants()) do
		if part:IsA("BasePart") and self:IsCowBodyPart(part) then
			part.Material = Enum.Material.Neon
			part.Color = Color3.fromRGB(255, 215, 0)

			-- Add point light
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 215, 0)
			light.Brightness = 1.5
			light.Range = 15
			light.Parent = part
		end
	end

	-- Add sparkle effect
	self:CreateSparkleEffect(cowModel, Color3.fromRGB(255, 215, 0))
end

function CowCreationModule:ApplyDiamondEffects(cowModel)
	-- Diamond appearance
	for _, part in pairs(cowModel:GetDescendants()) do
		if part:IsA("BasePart") and self:IsCowBodyPart(part) then
			part.Material = Enum.Material.Glass
			part.Color = Color3.fromRGB(225, 245, 255)
			part.Transparency = 0.1

			-- Prismatic light
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(200, 200, 255)
			light.Brightness = 2
			light.Range = 20
			light.Parent = part
		end
	end

	-- Create crystal formations
	self:CreateCrystalFormations(cowModel)

	-- Rainbow sparkles
	self:CreateRainbowSparkles(cowModel)
end

function CowCreationModule:ApplyRainbowEffects(cowModel)
	local bodyParts = {}

	-- Collect body parts
	for _, part in pairs(cowModel:GetDescendants()) do
		if part:IsA("BasePart") and self:IsCowBodyPart(part) then
			part.Material = Enum.Material.Neon
			table.insert(bodyParts, part)
		end
	end

	-- Start rainbow animation
	spawn(function()
		local hue = 0
		while cowModel and cowModel.Parent do
			for _, part in pairs(bodyParts) do
				if part and part.Parent then
					part.Color = Color3.fromHSV(hue, 1, 1)
				end
			end
			hue = (hue + 0.02) % 1
			wait(0.1)
		end
	end)

	-- Magical aura
	self:CreateMagicalAura(cowModel)
end

function CowCreationModule:ApplyCosmicEffects(cowModel)
	-- Dark cosmic base
	for _, part in pairs(cowModel:GetDescendants()) do
		if part:IsA("BasePart") and self:IsCowBodyPart(part) then
			part.Material = Enum.Material.Neon
			part.Color = Color3.fromRGB(25, 25, 50)
		end
	end

	-- Galaxy swirl effect
	self:CreateGalaxySwirl(cowModel)

	-- Cosmic energy
	self:CreateCosmicEnergy(cowModel)

	-- Nebula clouds
	self:CreateNebulaEffect(cowModel)
end

-- ========== ENHANCED VISUAL EFFECTS ==========

function CowCreationModule:CreateParticleEffect(cowModel, color, intensity)
	local cowCenter = self:GetCowCenter(cowModel)

	spawn(function()
		while cowModel and cowModel.Parent do
			for i = 1, intensity do
				local particle = Instance.new("Part")
				particle.Size = Vector3.new(0.1, 0.1, 0.1)
				particle.Shape = Enum.PartType.Ball
				particle.Material = Enum.Material.Neon
				particle.Color = color
				particle.CanCollide = false
				particle.Anchored = true
				particle.Position = cowCenter + Vector3.new(
					math.random(-3, 3),
					math.random(0, 4),
					math.random(-3, 3)
				)
				particle.Parent = workspace

				local tween = TweenService:Create(particle,
					TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						Position = particle.Position + Vector3.new(0, 8, 0),
						Transparency = 1
					}
				)
				tween:Play()
				tween.Completed:Connect(function()
					particle:Destroy()
				end)
			end
			wait(math.random(2, 4))
		end
	end)
end

function CowCreationModule:CreateSparkleEffect(cowModel, color)
	local cowCenter = self:GetCowCenter(cowModel)

	spawn(function()
		while cowModel and cowModel.Parent do
			for i = 1, 4 do
				local sparkle = Instance.new("Part")
				sparkle.Size = Vector3.new(0.2, 0.2, 0.2)
				sparkle.Shape = Enum.PartType.Ball
				sparkle.Material = Enum.Material.Neon
				sparkle.Color = color
				sparkle.CanCollide = false
				sparkle.Anchored = true
				sparkle.Position = cowCenter + Vector3.new(
					math.random(-4, 4),
					math.random(0, 6),
					math.random(-4, 4)
				)
				sparkle.Parent = workspace

				-- Twinkle effect
				local twinkle = TweenService:Create(sparkle,
					TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true),
					{Transparency = 0.8}
				)
				twinkle:Play()

				-- Float up and fade
				local float = TweenService:Create(sparkle,
					TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						Position = sparkle.Position + Vector3.new(0, 10, 0),
						Size = Vector3.new(0.05, 0.05, 0.05)
					}
				)
				float:Play()

				float.Completed:Connect(function()
					twinkle:Cancel()
					sparkle:Destroy()
				end)
			end
			wait(math.random(1, 3))
		end
	end)
end

function CowCreationModule:CreateGalaxySwirl(cowModel)
	local cowCenter = self:GetCowCenter(cowModel)

	spawn(function()
		local angle = 0
		while cowModel and cowModel.Parent do
			for arm = 0, 2 do
				for i = 1, 3 do
					local star = Instance.new("Part")
					star.Size = Vector3.new(0.05, 0.05, 0.05)
					star.Shape = Enum.PartType.Ball
					star.Material = Enum.Material.Neon
					star.Color = Color3.fromRGB(
						math.random(150, 255),
						math.random(100, 200),
						math.random(200, 255)
					)
					star.CanCollide = false
					star.Anchored = true

					local armAngle = angle + arm * (math.pi * 2 / 3)
					local distance = 2 + i * 0.8
					local x = cowCenter.X + math.cos(armAngle) * distance
					local z = cowCenter.Z + math.sin(armAngle) * distance
					local y = cowCenter.Y + 2 + math.sin(angle * 3) * 1

					star.Position = Vector3.new(x, y, z)
					star.Parent = workspace

					local fade = TweenService:Create(star,
						TweenInfo.new(1, Enum.EasingStyle.Quad),
						{Transparency = 1}
					)
					fade:Play()
					fade.Completed:Connect(function()
						star:Destroy()
					end)
				end
			end

			angle = angle + 0.1
			wait(0.1)
		end
	end)
end

function CowCreationModule:CreateMagicalAura(cowModel)
	-- Create magical sparkles around cow
	local cowCenter = self:GetCowCenter(cowModel)

	spawn(function()
		while cowModel and cowModel.Parent do
			local aura = Instance.new("Part")
			aura.Size = Vector3.new(0.3, 0.3, 0.3)
			aura.Shape = Enum.PartType.Ball
			aura.Material = Enum.Material.Neon
			aura.Color = Color3.fromHSV(math.random(), 1, 1)
			aura.CanCollide = false
			aura.Anchored = true
			aura.Position = cowCenter + Vector3.new(
				math.random(-5, 5),
				math.random(0, 8),
				math.random(-5, 5)
			)
			aura.Parent = workspace

			local float = TweenService:Create(aura,
				TweenInfo.new(2, Enum.EasingStyle.Sine),
				{
					Position = aura.Position + Vector3.new(0, 3, 0),
					Transparency = 1,
					Size = Vector3.new(0.1, 0.1, 0.1)
				}
			)
			float:Play()
			float.Completed:Connect(function()
				aura:Destroy()
			end)

			wait(0.3)
		end
	end)
end

function CowCreationModule:CreateCrystalFormations(cowModel)
	-- Create floating crystal formations around diamond cows
	local cowCenter = self:GetCowCenter(cowModel)

	for i = 1, 6 do
		local crystal = Instance.new("Part")
		crystal.Size = Vector3.new(0.5, 1.5, 0.5)
		crystal.Shape = Enum.PartType.Block
		crystal.Material = Enum.Material.Glass
		crystal.Color = Color3.fromRGB(185, 242, 255)
		crystal.CanCollide = false
		crystal.Anchored = true

		local angle = (i - 1) * (math.pi * 2 / 6)
		local distance = 4
		local x = cowCenter.X + math.cos(angle) * distance
		local z = cowCenter.Z + math.sin(angle) * distance
		crystal.Position = Vector3.new(x, cowCenter.Y + 2, z)
		crystal.Orientation = Vector3.new(0, math.deg(angle), 15)
		crystal.Parent = workspace

		-- Store crystal for cleanup
		local cowId = cowModel:GetAttribute("CowId")
		if cowId then
			if not self.CowEffects[cowId] then
				self.CowEffects[cowId] = {}
			end
			table.insert(self.CowEffects[cowId], crystal)
		end

		-- Add gentle rotation
		spawn(function()
			while crystal.Parent do
				local rotate = TweenService:Create(crystal,
					TweenInfo.new(4, Enum.EasingStyle.Linear),
					{Orientation = crystal.Orientation + Vector3.new(0, 360, 0)}
				)
				rotate:Play()
				rotate.Completed:Wait()
			end
		end)
	end
end

function CowCreationModule:CreateRainbowSparkles(cowModel)
	-- Create rainbow sparkles for diamond cows
	local cowCenter = self:GetCowCenter(cowModel)

	spawn(function()
		while cowModel and cowModel.Parent do
			for i = 1, 8 do
				local sparkle = Instance.new("Part")
				sparkle.Size = Vector3.new(0.1, 0.1, 0.1)
				sparkle.Shape = Enum.PartType.Ball
				sparkle.Material = Enum.Material.Neon
				sparkle.Color = Color3.fromHSV(i / 8, 1, 1)
				sparkle.CanCollide = false
				sparkle.Anchored = true
				sparkle.Position = cowCenter + Vector3.new(
					math.random(-3, 3),
					math.random(0, 5),
					math.random(-3, 3)
				)
				sparkle.Parent = workspace

				local rise = TweenService:Create(sparkle,
					TweenInfo.new(2, Enum.EasingStyle.Quad),
					{
						Position = sparkle.Position + Vector3.new(0, 8, 0),
						Transparency = 1
					}
				)
				rise:Play()
				rise.Completed:Connect(function()
					sparkle:Destroy()
				end)
			end
			wait(1)
		end
	end)
end

function CowCreationModule:CreateCosmicEnergy(cowModel)
	-- Create cosmic energy bolts
	local cowCenter = self:GetCowCenter(cowModel)

	spawn(function()
		while cowModel and cowModel.Parent do
			local bolt = Instance.new("Part")
			bolt.Size = Vector3.new(0.1, 3, 0.1)
			bolt.Shape = Enum.PartType.Cylinder
			bolt.Material = Enum.Material.Neon
			bolt.Color = Color3.fromRGB(138, 43, 226)
			bolt.CanCollide = false
			bolt.Anchored = true
			bolt.Position = cowCenter + Vector3.new(
				math.random(-2, 2),
				math.random(2, 6),
				math.random(-2, 2)
			)
			bolt.Orientation = Vector3.new(0, 0, math.random(0, 360))
			bolt.Parent = workspace

			local flash = TweenService:Create(bolt,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad),
				{Transparency = 1}
			)
			flash:Play()
			flash.Completed:Connect(function()
				bolt:Destroy()
			end)

			wait(math.random(1, 3))
		end
	end)
end

function CowCreationModule:CreateNebulaEffect(cowModel)
	-- Create nebula clouds around cosmic cows
	local cowCenter = self:GetCowCenter(cowModel)

	spawn(function()
		while cowModel and cowModel.Parent do
			local cloud = Instance.new("Part")
			cloud.Size = Vector3.new(2, 1, 2)
			cloud.Shape = Enum.PartType.Block
			cloud.Material = Enum.Material.Neon
			cloud.Color = Color3.fromRGB(75, 0, 130)
			cloud.Transparency = 0.7
			cloud.CanCollide = false
			cloud.Anchored = true
			cloud.Position = cowCenter + Vector3.new(
				math.random(-6, 6),
				math.random(1, 4),
				math.random(-6, 6)
			)
			cloud.Parent = workspace

			local drift = TweenService:Create(cloud,
				TweenInfo.new(8, Enum.EasingStyle.Sine),
				{
					Position = cloud.Position + Vector3.new(math.random(-3, 3), 2, math.random(-3, 3)),
					Transparency = 1,
					Size = Vector3.new(4, 2, 4)
				}
			)
			drift:Play()
			drift.Completed:Connect(function()
				cloud:Destroy()
			end)

			wait(2)
		end
	end)
end

-- ========== COW POSITIONING SYSTEM ==========

function CowCreationModule:GenerateUniqueCowId(userId)
	local maxAttempts = 10
	local attempt = 0

	while attempt < maxAttempts do
		local cowId = "cow_" .. userId .. "_" .. self.NextCowId
		self.NextCowId = self.NextCowId + 1

		-- Check if this ID is already in use
		local inUse = false

		-- Check in active cows
		if self.ActiveCows[cowId] then
			inUse = true
		end

		-- Check in workspace
		if workspace:FindFirstChild(cowId) then
			inUse = true
		end

		if not inUse then
			print("🐄 CowCreationModule: Generated unique cow ID: " .. cowId)
			return cowId
		end

		attempt = attempt + 1
		warn("🐄 CowCreationModule: Cow ID collision, trying again: " .. cowId)
	end

	warn("🐄 CowCreationModule: Failed to generate unique cow ID after " .. maxAttempts .. " attempts")
	return nil
end

function CowCreationModule:GetNextCowPosition(player)
	local userId = player.UserId
	local usedPositions = self.PlayerCowPositions[userId] or {}

	-- Calculate player offset
	local players = Players:GetPlayers()
	table.sort(players, function(a, b) return a.UserId < b.UserId end)

	local playerIndex = 0
	for i, p in ipairs(players) do
		if p.UserId == userId then
			playerIndex = i - 1
			break
		end
	end

	local playerOffset = self.Config.playerSeparation * playerIndex
	local basePos = self.Config.basePosition + playerOffset

	-- Find next available position
	for row = 0, 10 do
		for col = 0, self.Config.rowSize - 1 do
			local position = basePos + Vector3.new(
				col * self.Config.spacing.X,
				0,
				row * self.Config.spacing.Z
			)

			local posKey = tostring(position)
			if not usedPositions[posKey] then
				usedPositions[posKey] = true
				self.PlayerCowPositions[userId] = usedPositions
				return position
			end
		end
	end

	return nil
end

-- ========== UTILITY FUNCTIONS ==========

function CowCreationModule:GetPlayerCowCount(player)
	if not GameCore then return 0 end

	local playerData = GameCore:GetPlayerData(player)
	if not playerData or not playerData.livestock or not playerData.livestock.cows then
		return 0
	end

	local count = 0
	for _ in pairs(playerData.livestock.cows) do
		count = count + 1
	end
	return count
end

function CowCreationModule:GetCowDisplayName(tier)
	local names = {
		basic = "🐄 Basic Cow",
		silver = "🥈 Silver Cow", 
		gold = "🥇 Gold Cow",
		diamond = "💎 Diamond Cow",
		rainbow = "🌈 Rainbow Cow",
		cosmic = "🌌 Cosmic Cow"
	}
	return names[tier] or tier
end

function CowCreationModule:GetCowCenter(cowModel)
	-- Try to find the main body part first
	local bodyPart = nil
	local possibleBodyParts = {"HumanoidRootPart", "Torso", "UpperTorso", "Body", "Middle"}

	for _, partName in ipairs(possibleBodyParts) do
		bodyPart = cowModel:FindFirstChild(partName)
		if bodyPart then break end
	end

	if bodyPart then
		return bodyPart.Position
	end

	-- Fallback: calculate center of all parts
	local totalPosition = Vector3.new(0, 0, 0)
	local partCount = 0

	for _, part in pairs(cowModel:GetDescendants()) do
		if part:IsA("BasePart") then
			totalPosition = totalPosition + part.Position
			partCount = partCount + 1
		end
	end

	if partCount > 0 then
		return totalPosition / partCount
	end

	-- Final fallback
	return cowModel.PrimaryPart and cowModel.PrimaryPart.Position or Vector3.new(0, 0, 0)
end

function CowCreationModule:IsCowBodyPart(part)
	local bodyNames = {"body", "torso", "head", "humanoidrootpart"}
	local partName = part.Name:lower()

	for _, name in ipairs(bodyNames) do
		if partName:find(name) then
			return true
		end
	end

	return false
end

function CowCreationModule:ClearCowEffects(cowModel)
	local cowId = cowModel:GetAttribute("CowId")
	if not cowId then return end

	-- Remove existing lighting effects
	for _, obj in pairs(cowModel:GetDescendants()) do
		if obj:IsA("PointLight") or obj:IsA("SpotLight") then
			obj:Destroy()
		end
	end

	-- Clear stored effects
	local effects = self.CowEffects[cowId]
	if effects then
		for _, effect in pairs(effects) do
			if effect and effect.Parent then
				effect:Destroy()
			end
		end
		self.CowEffects[cowId] = nil
	end
end

function CowCreationModule:SendNotification(player, title, message, notificationType)
	if GameCore and GameCore.SendNotification then
		GameCore:SendNotification(player, title, message, notificationType)
	else
		print("NOTIFICATION for " .. player.Name .. ": [" .. (notificationType or "info"):upper() .. "] " .. title .. " - " .. message)
	end
end

-- ========== MONITORING SYSTEM ==========

function CowCreationModule:StartCowMonitoring()
	spawn(function()
		while true do
			wait(10) -- Check every 10 seconds
			self:MonitorCows()
		end
	end)

	print("CowCreationModule: Started cow monitoring system")
end

function CowCreationModule:MonitorCows()
	-- Check for new cows that weren't registered
	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("Model") and obj.Name:find("cow_") and not self.ActiveCows[obj.Name] then
			local owner = obj:GetAttribute("Owner")
			if owner then
				self:RegisterExistingCow(obj, obj.Name, owner)
			end
		end
	end

	-- Check for deleted cows
	local toRemove = {}
	for cowId, cowModel in pairs(self.ActiveCows) do
		if not cowModel or not cowModel.Parent then
			table.insert(toRemove, cowId)
		end
	end

	for _, cowId in ipairs(toRemove) do
		self:UnregisterCow(cowId)
	end
end

function CowCreationModule:UnregisterCow(cowId)
	-- Clear effects
	self:ClearCowEffects(self.ActiveCows[cowId] or {GetAttribute = function() return cowId end})

	-- Remove from tracking
	self.ActiveCows[cowId] = nil
	self.CowEffects[cowId] = nil

	print("CowCreationModule: Unregistered cow " .. cowId)
end

-- ========== PUBLIC API ==========

function CowCreationModule:GetActiveCows()
	return self.ActiveCows
end

function CowCreationModule:GetCowModel(cowId)
	return self.ActiveCows[cowId]
end

function CowCreationModule:GetCowData(player, cowId)
	if not GameCore then return nil end

	local playerData = GameCore:GetPlayerData(player)
	if not playerData or not playerData.livestock or not playerData.livestock.cows then
		return nil
	end

	return playerData.livestock.cows[cowId]
end

function CowCreationModule:DeleteCow(player, cowId)
	if not GameCore then return false end

	local playerData = GameCore:GetPlayerData(player)
	if not playerData or not playerData.livestock or not playerData.livestock.cows then
		return false
	end

	-- Remove from player data
	playerData.livestock.cows[cowId] = nil

	-- Remove model from workspace
	local cowModel = self.ActiveCows[cowId]
	if cowModel and cowModel.Parent then
		cowModel:Destroy()
	end

	-- Unregister from tracking
	self:UnregisterCow(cowId)

	-- Save data
	if GameCore.SavePlayerData then
		GameCore:SavePlayerData(player)
	end

	return true
end

return CowCreationModule