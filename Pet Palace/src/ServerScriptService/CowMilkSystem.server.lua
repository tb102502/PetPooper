--[[
    ENHANCED CowMilkSystem.server.lua - MULTIPLE COWS WITH PROGRESSION
    Replace your existing CowMilkSystem.server.lua with this enhanced version
    
    Features:
    ✅ Multiple cow support
    ✅ Cow tier progression with visual effects
    ✅ Individual cow management
    ✅ Auto-milker system
    ✅ Enhanced debugging and admin commands
]]

local function WaitForGameCore(scriptName, maxWaitTime)
	maxWaitTime = maxWaitTime or 15
	local startTime = tick()

	print(scriptName .. ": Waiting for GameCore...")

	while not _G.GameCore and (tick() - startTime) < maxWaitTime do
		wait(0.5)
	end

	if not _G.GameCore then
		warn(scriptName .. ": GameCore not found after " .. maxWaitTime .. " seconds! Running in standalone mode.")
		return nil
	end

	print(scriptName .. ": GameCore found successfully!")
	return _G.GameCore
end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- Try to get GameCore
local GameCore = WaitForGameCore("EnhancedCowMilkSystem")

print("=== ENHANCED COW MILK SYSTEM STARTING ===")

local EnhancedCowMilkSystem = {}

-- Configuration
local AUTO_MILK_INTERVAL = 30 -- seconds
local MILK_INDICATOR_HEIGHT = 8

-- State tracking
EnhancedCowMilkSystem.ActiveCows = {} -- [cowId] = cowModel
EnhancedCowMilkSystem.CowIndicators = {} -- [cowId] = indicatorModel
EnhancedCowMilkSystem.AutoMilkers = {} -- [userId] = true
EnhancedCowMilkSystem.PlayerCooldowns = {} -- [userId][cowId] = lastCollection

-- ========== INITIALIZATION ==========

function EnhancedCowMilkSystem:Initialize()
	print("EnhancedCowMilkSystem: Initializing advanced cow management...")

	-- Setup remote events
	self:SetupRemoteEvents()

	-- Start monitoring systems
	self:StartCowMonitoring()
	self:StartAutoMilking()
	self:StartIndicatorUpdates()

	-- Setup existing cows
	self:ScanForExistingCows()

	print("EnhancedCowMilkSystem: Advanced cow system initialized!")
end

function EnhancedCowMilkSystem:SetupRemoteEvents()
	local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "GameRemotes"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Create cow-specific remotes if needed
	local requiredRemotes = {
		"CollectCowMilk",
		"RelocateCow",
		"FeedCow",
		"UpgradeCow"
	}

	for _, remoteName in ipairs(requiredRemotes) do
		if not remoteFolder:FindFirstChild(remoteName) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = remoteName
			remote.Parent = remoteFolder
		end
	end

	-- Connect handlers if GameCore is available
	if GameCore then
		if remoteFolder:FindFirstChild("CollectCowMilk") then
			remoteFolder.CollectCowMilk.OnServerEvent:Connect(function(player, cowId)
				pcall(function()
					self:HandleCowMilkCollection(player, cowId)
				end)
			end)
		end
	end

	print("EnhancedCowMilkSystem: Remote events setup complete")
end

function EnhancedCowMilkSystem:ScanForExistingCows()
	print("EnhancedCowMilkSystem: Scanning for existing cows...")

	local cowCount = 0
	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("Model") and obj.Name:find("cow_") then
			local cowId = obj.Name
			local owner = obj:GetAttribute("Owner")

			if owner then
				self:RegisterCow(obj, cowId, owner)
				cowCount = cowCount + 1
			end
		end
	end

	print("EnhancedCowMilkSystem: Registered " .. cowCount .. " existing cows")
end

-- ========== COW REGISTRATION AND MANAGEMENT ==========

function EnhancedCowMilkSystem:RegisterCow(cowModel, cowId, ownerName)
	print("EnhancedCowMilkSystem: Registering cow " .. cowId .. " for " .. ownerName)

	-- Store cow reference
	self.ActiveCows[cowId] = cowModel

	-- Setup enhanced click detection
	self:SetupEnhancedClickDetection(cowModel, cowId, ownerName)

	-- Create milk indicator
	self:CreateMilkIndicator(cowModel, cowId)

	-- Apply visual effects based on tier
	local tier = cowModel:GetAttribute("Tier") or "basic"
	self:ApplyTierEffects(cowModel, tier)

	print("EnhancedCowMilkSystem: Successfully registered cow " .. cowId)
end

function EnhancedCowMilkSystem:SetupEnhancedClickDetection(cowModel, cowId, ownerName)
	-- Remove existing detectors
	for _, obj in pairs(cowModel:GetDescendants()) do
		if obj:IsA("ClickDetector") then
			obj:Destroy()
		end
	end

	-- Find all clickable parts
	local clickableParts = {}

	-- Priority parts
	local priorityNames = {"humanoidrootpart", "torso", "body", "middle"}
	for _, name in ipairs(priorityNames) do
		for _, part in pairs(cowModel:GetDescendants()) do
			if part:IsA("BasePart") and part.Name:lower() == name then
				table.insert(clickableParts, {part = part, priority = 10})
			end
		end
	end

	-- Large parts as backup
	if #clickableParts < 2 then
		for _, part in pairs(cowModel:GetDescendants()) do
			if part:IsA("BasePart") then
				local volume = part.Size.X * part.Size.Y * part.Size.Z
				if volume > 8 then
					table.insert(clickableParts, {part = part, priority = 5})
				end
			end
		end
	end

	-- Add click detectors
	for _, entry in ipairs(clickableParts) do
		local detector = Instance.new("ClickDetector")
		detector.MaxActivationDistance = 30
		detector.Parent = entry.part

		detector.MouseClick:Connect(function(player)
			if player.Name == ownerName then
				self:HandleCowMilkCollection(player, cowId)
			else
				self:SendNotification(player, "Not Your Cow", "This cow belongs to " .. ownerName .. "!", "warning")
			end
		end)

		-- Visual feedback
		detector.MouseHoverEnter:Connect(function(player)
			if player.Name == ownerName then
				self:HighlightCow(cowModel, true)
			end
		end)

		detector.MouseHoverLeave:Connect(function(player)
			self:HighlightCow(cowModel, false)
		end)
	end

	print("EnhancedCowMilkSystem: Setup click detection for cow " .. cowId .. " with " .. #clickableParts .. " clickable parts")
end

function EnhancedCowMilkSystem:CreateMilkIndicator(cowModel, cowId)
	-- Remove existing indicator
	local existing = cowModel:FindFirstChild("MilkIndicator")
	if existing then existing:Destroy() end

	-- Calculate cow bounds
	local cowCenter, cowSize = self:GetCowBounds(cowModel)

	-- Create indicator
	local indicator = Instance.new("Part")
	indicator.Name = "MilkIndicator"
	indicator.Size = Vector3.new(4, 0.3, 4)
	indicator.Shape = Enum.PartType.Cylinder
	indicator.Material = Enum.Material.Neon
	indicator.Color = Color3.fromRGB(255, 0, 0)
	indicator.CanCollide = false
	indicator.Anchored = true
	indicator.CFrame = CFrame.new(cowCenter.X, cowCenter.Y + cowSize.Y/2 + MILK_INDICATOR_HEIGHT, cowCenter.Z)
	indicator.Orientation = Vector3.new(0, 0, 90)
	indicator.Parent = cowModel

	-- Add text display
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 300, 0, 80)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.Parent = indicator

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "🥛 CLICK TO COLLECT MILK"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Parent = gui

	-- Store indicator reference
	self.CowIndicators[cowId] = {
		part = indicator,
		gui = gui,
		label = label
	}

	print("EnhancedCowMilkSystem: Created milk indicator for cow " .. cowId)
end

-- ========== VISUAL EFFECTS SYSTEM ==========

function EnhancedCowMilkSystem:ApplyTierEffects(cowModel, tier)
	print("EnhancedCowMilkSystem: Applying " .. tier .. " tier effects to cow")

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

function EnhancedCowMilkSystem:ApplySilverEffects(cowModel)
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

function EnhancedCowMilkSystem:ApplyGoldEffects(cowModel)
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

function EnhancedCowMilkSystem:ApplyDiamondEffects(cowModel)
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

function EnhancedCowMilkSystem:ApplyRainbowEffects(cowModel)
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

function EnhancedCowMilkSystem:ApplyCosmicEffects(cowModel)
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

function EnhancedCowMilkSystem:CreateParticleEffect(cowModel, color, intensity)
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

function EnhancedCowMilkSystem:CreateSparkleEffect(cowModel, color)
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

function EnhancedCowMilkSystem:CreateGalaxySwirl(cowModel)
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

-- ========== MISSING METHODS FOR COW ADMIN PANEL ==========
-- Add these methods to your EnhancedCowMilkSystem

function EnhancedCowMilkSystem:GetPlayerCowInfo(player)
	print("EnhancedCowMilkSystem: Getting cow info for " .. player.Name)

	local cowInfo = {
		playerName = player.Name,
		totalCows = 0,
		cowsByTier = {},
		activeCows = {},
		totalMilkProduced = 0,
		averageCooldown = 0,
		lastUpdate = os.time()
	}

	-- Get data from GameCore if available
	if GameCore then
		local playerData = GameCore:GetPlayerData(player)
		if playerData and playerData.livestock and playerData.livestock.cows then

			local totalCooldown = 0
			local totalMilk = 0

			for cowId, cowData in pairs(playerData.livestock.cows) do
				cowInfo.totalCows = cowInfo.totalCows + 1

				-- Count by tier
				local tier = cowData.tier or "basic"
				cowInfo.cowsByTier[tier] = (cowInfo.cowsByTier[tier] or 0) + 1

				-- Add to active cows list
				table.insert(cowInfo.activeCows, {
					id = cowId,
					tier = tier,
					milkAmount = cowData.milkAmount or 2,
					cooldown = cowData.cooldown or 60,
					lastCollection = cowData.lastMilkCollection or 0,
					totalProduced = cowData.totalMilkProduced or 0,
					position = cowData.position or Vector3.new(0, 0, 0)
				})

				-- Accumulate stats
				totalCooldown = totalCooldown + (cowData.cooldown or 60)
				totalMilk = totalMilk + (cowData.totalMilkProduced or 0)
			end

			-- Calculate averages
			if cowInfo.totalCows > 0 then
				cowInfo.averageCooldown = totalCooldown / cowInfo.totalCows
				cowInfo.totalMilkProduced = totalMilk
			end
		end
	end

	-- Get visual cow models from workspace
	cowInfo.visualCows = {}
	for cowId, cowModel in pairs(self.ActiveCows or {}) do
		if cowModel and cowModel.Parent then
			local owner = cowModel:GetAttribute("Owner")
			if owner == player.Name then
				table.insert(cowInfo.visualCows, {
					id = cowId,
					modelName = cowModel.Name,
					position = self:GetCowCenter(cowModel),
					tier = cowModel:GetAttribute("Tier") or "basic",
					hasIndicator = self.CowIndicators[cowId] ~= nil
				})
			end
		end
	end

	-- Add capacity info
	if GameCore then
		local playerData = GameCore:GetPlayerData(player)
		if playerData then
			cowInfo.maxCows = GameCore:GetPlayerMaxCows(playerData) or 5
			cowInfo.hasAutoMilker = playerData.upgrades and playerData.upgrades.auto_milker or false
		end
	end

	print("EnhancedCowMilkSystem: Cow info compiled - " .. cowInfo.totalCows .. " cows found")
	return cowInfo
end

function EnhancedCowMilkSystem:GetPerformanceData()
	print("EnhancedCowMilkSystem: Gathering performance data...")

	local performanceData = {
		timestamp = os.time(),
		systemStatus = "running",

		-- Cow tracking
		totalActiveCows = 0,
		cowsByPlayer = {},

		-- Visual effects
		activeEffects = 0,
		effectsByType = {},

		-- Memory and performance
		activeConnections = 0,
		indicatorCount = 0,

		-- Player statistics
		playersWithCows = 0,
		playersWithAutoMilker = 0,

		-- System health
		errors = {},
		warnings = {},

		-- Detailed metrics
		detailedMetrics = {}
	}

	-- Count active cows
	for cowId, cowModel in pairs(self.ActiveCows or {}) do
		if cowModel and cowModel.Parent then
			performanceData.totalActiveCows = performanceData.totalActiveCows + 1

			local owner = cowModel:GetAttribute("Owner") or "unknown"
			performanceData.cowsByPlayer[owner] = (performanceData.cowsByPlayer[owner] or 0) + 1
		else
			table.insert(performanceData.warnings, "Inactive cow model found: " .. tostring(cowId))
		end
	end

	-- Count visual effects
	if _G.CowVisualEffects and _G.CowVisualEffects.ActiveEffects then
		for cowId, effects in pairs(_G.CowVisualEffects.ActiveEffects) do
			performanceData.activeEffects = performanceData.activeEffects + 1

			local effectType = effects.tier or "unknown"
			performanceData.effectsByType[effectType] = (performanceData.effectsByType[effectType] or 0) + 1
		end
	end

	-- Count indicators
	for cowId, indicator in pairs(self.CowIndicators or {}) do
		if indicator and indicator.part and indicator.part.Parent then
			performanceData.indicatorCount = performanceData.indicatorCount + 1
		end
	end

	-- Player statistics
	if GameCore then
		for _, player in pairs(game.Players:GetPlayers()) do
			local playerData = GameCore:GetPlayerData(player)
			if playerData then
				-- Check if player has cows
				if playerData.livestock and playerData.livestock.cows then
					local cowCount = 0
					for _ in pairs(playerData.livestock.cows) do
						cowCount = cowCount + 1
					end
					if cowCount > 0 then
						performanceData.playersWithCows = performanceData.playersWithCows + 1
					end
				end

				-- Check for auto milker
				if playerData.upgrades and playerData.upgrades.auto_milker then
					performanceData.playersWithAutoMilker = performanceData.playersWithAutoMilker + 1
				end
			end
		end
	end

	-- Performance settings
	performanceData.performanceSettings = self.PerformanceSettings or {
		particleCount = 15,
		updateRate = 0.1,
		lightRange = 20
	}

	-- System health checks
	if performanceData.totalActiveCows == 0 then
		table.insert(performanceData.warnings, "No active cows found in system")
	end

	if performanceData.totalActiveCows ~= performanceData.indicatorCount then
		table.insert(performanceData.warnings, "Mismatch between cow count and indicator count")
	end

	-- Detailed metrics
	performanceData.detailedMetrics = {
		cowModelRatio = performanceData.indicatorCount > 0 and (performanceData.totalActiveCows / performanceData.indicatorCount) or 0,
		averageCowsPerPlayer = performanceData.playersWithCows > 0 and (performanceData.totalActiveCows / performanceData.playersWithCows) or 0,
		autoMilkerAdoptionRate = performanceData.playersWithCows > 0 and (performanceData.playersWithAutoMilker / performanceData.playersWithCows) or 0,
		systemEfficiency = (performanceData.totalActiveCows > 0 and #performanceData.errors == 0) and "optimal" or "degraded"
	}

	print("EnhancedCowMilkSystem: Performance data compiled")
	print("  Active cows: " .. performanceData.totalActiveCows)
	print("  Players with cows: " .. performanceData.playersWithCows)
	print("  Active effects: " .. performanceData.activeEffects)
	print("  Warnings: " .. #performanceData.warnings)

	return performanceData
end

-- ========== ADDITIONAL UTILITY METHODS ==========
--[[
    FIXED CowMilkSystem.server.lua - Missing UpdateCowIndicator Method
    
    FIXES:
    ✅ Added missing UpdateCowIndicator method
    ✅ Enhanced indicator management system
    ✅ Better integration with GameCore
    ✅ Improved error handling
]]

-- Add these missing methods to your EnhancedCowMilkSystem class:

-- ========== MISSING INDICATOR METHODS - ADD TO ENHANCEDCOWMILKSYSTEM ==========

function EnhancedCowMilkSystem:UpdateCowIndicator(cowId, player)
	print("EnhancedCowMilkSystem: Updating cow indicator for " .. cowId)

	local cowModel = self.ActiveCows[cowId]
	if not cowModel then
		warn("EnhancedCowMilkSystem: Cow model not found for " .. cowId)
		return false
	end

	-- Try to use GameCore's method first
	if GameCore and GameCore.UpdateCowIndicator then
		local success = pcall(function()
			return GameCore:UpdateCowIndicator(cowModel, "cooldown")
		end)
		if success then
			print("EnhancedCowMilkSystem: Updated indicator via GameCore")
			return true
		end
	end

	-- Fallback to local indicator update
	return self:UpdateCowIndicatorLocal(cowId, "cooldown")
end

function EnhancedCowMilkSystem:UpdateCowIndicatorLocal(cowId, state)
	print("EnhancedCowMilkSystem: Updating local cow indicator for " .. cowId .. " to state: " .. state)

	local indicator = self.CowIndicators[cowId]
	if not indicator or not indicator.part or not indicator.part.Parent then
		warn("EnhancedCowMilkSystem: Indicator not found for cow " .. cowId)
		return false
	end

	-- Update indicator based on state
	if state == "ready" then
		indicator.part.Color = Color3.fromRGB(0, 255, 0) -- Green
		indicator.part.Material = Enum.Material.Neon
		indicator.part.Transparency = 0.2
		indicator.label.Text = "🥛 READY TO COLLECT!"
		indicator.label.TextColor3 = Color3.fromRGB(0, 255, 0)

	elseif state == "cooldown" then
		indicator.part.Color = Color3.fromRGB(255, 0, 0) -- Red
		indicator.part.Material = Enum.Material.Plastic
		indicator.part.Transparency = 0.5
		indicator.label.Text = "🥛 COW RESTING..."
		indicator.label.TextColor3 = Color3.fromRGB(255, 100, 100)

	elseif state == "almost_ready" then
		indicator.part.Color = Color3.fromRGB(255, 255, 0) -- Yellow
		indicator.part.Material = Enum.Material.Neon
		indicator.part.Transparency = 0.3
		indicator.label.Text = "🥛 ALMOST READY!"
		indicator.label.TextColor3 = Color3.fromRGB(255, 255, 0)

	else
		-- Default state
		indicator.part.Color = Color3.fromRGB(100, 100, 100) -- Gray
		indicator.part.Material = Enum.Material.Plastic
		indicator.part.Transparency = 0.7
		indicator.label.Text = "🥛 CLICK TO COLLECT MILK"
		indicator.label.TextColor3 = Color3.fromRGB(255, 255, 255)
	end

	print("EnhancedCowMilkSystem: Successfully updated indicator for " .. cowId)
	return true
end

function EnhancedCowMilkSystem:GetCowIndicatorState(cowId)
	print("EnhancedCowMilkSystem: Getting indicator state for " .. cowId)

	local cowModel = self.ActiveCows[cowId]
	if not cowModel then
		return "unknown"
	end

	local owner = cowModel:GetAttribute("Owner")
	if not owner then
		return "unknown"
	end

	-- Find the player who owns this cow
	local ownerPlayer = nil
	for _, player in pairs(game:GetService("Players"):GetPlayers()) do
		if player.Name == owner then
			ownerPlayer = player
			break
		end
	end

	if not ownerPlayer or not GameCore then
		return "unknown"
	end

	local playerData = GameCore:GetPlayerData(ownerPlayer)
	if not playerData or not playerData.livestock or not playerData.livestock.cows then
		return "unknown"
	end

	local cowData = playerData.livestock.cows[cowId]
	if not cowData then
		return "unknown"
	end

	-- Calculate state based on cooldown
	local currentTime = os.time()
	local timeSinceCollection = currentTime - (cowData.lastMilkCollection or 0)
	local cooldown = cowData.cooldown or 60

	if timeSinceCollection >= cooldown then
		return "ready"
	elseif timeSinceCollection >= (cooldown * 0.8) then
		return "almost_ready"
	else
		return "cooldown"
	end
end

function EnhancedCowMilkSystem:UpdateIndicatorWithCooldown(cowId, timeLeft)
	print("EnhancedCowMilkSystem: Updating indicator with cooldown time for " .. cowId)

	local indicator = self.CowIndicators[cowId]
	if not indicator or not indicator.part or not indicator.part.Parent then
		return false
	end

	if timeLeft <= 0 then
		self:UpdateCowIndicatorLocal(cowId, "ready")
	elseif timeLeft <= 10 then
		self:UpdateCowIndicatorLocal(cowId, "almost_ready")
		indicator.label.Text = "🥛 ALMOST READY (" .. math.ceil(timeLeft) .. "s)"
	else
		self:UpdateCowIndicatorLocal(cowId, "cooldown")
		indicator.label.Text = "🥛 RESTING (" .. math.ceil(timeLeft) .. "s)"
	end

	return true
end

-- ========== ENHANCED INDICATOR CREATION ==========

function EnhancedCowMilkSystem:CreateEnhancedMilkIndicator(cowModel, cowId)
	print("EnhancedCowMilkSystem: Creating enhanced milk indicator for " .. cowId)

	-- Remove existing indicator
	local existing = cowModel:FindFirstChild("MilkIndicator")
	if existing then existing:Destroy() end

	-- Calculate cow bounds
	local cowCenter, cowSize = self:GetCowBounds(cowModel)

	-- Create main indicator part
	local indicator = Instance.new("Part")
	indicator.Name = "MilkIndicator"
	indicator.Size = Vector3.new(4, 0.3, 4)
	indicator.Shape = Enum.PartType.Cylinder
	indicator.Material = Enum.Material.Neon
	indicator.Color = Color3.fromRGB(255, 0, 0)
	indicator.CanCollide = false
	indicator.Anchored = true
	indicator.CFrame = CFrame.new(cowCenter.X, cowCenter.Y + cowSize.Y/2 + 8, cowCenter.Z)
	indicator.Orientation = Vector3.new(0, 0, 90)
	indicator.Parent = cowModel

	-- Create billboard GUI for text
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 400, 0, 100)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.Parent = indicator

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 0.3
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BorderSizePixel = 0
	frame.Parent = gui

	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "🥛 CLICK TO COLLECT MILK"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Parent = frame

	-- Create cooldown timer display
	local timerLabel = Instance.new("TextLabel")
	timerLabel.Size = UDim2.new(1, 0, 0.4, 0)
	timerLabel.Position = UDim2.new(0, 0, 0.6, 0)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Text = ""
	timerLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
	timerLabel.TextScaled = true
	timerLabel.Font = Enum.Font.Gotham
	timerLabel.TextStrokeTransparency = 0
	timerLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	timerLabel.Parent = frame

	-- Store enhanced indicator reference
	self.CowIndicators[cowId] = {
		part = indicator,
		gui = gui,
		frame = frame,
		label = label,
		timerLabel = timerLabel
	}

	print("EnhancedCowMilkSystem: Created enhanced milk indicator for cow " .. cowId)
	return indicator
end

-- ========== ENHANCED INDICATOR UPDATE SYSTEM ==========

function EnhancedCowMilkSystem:StartEnhancedIndicatorUpdates()
	spawn(function()
		while true do
			wait(1) -- Update every second for accurate timers
			self:UpdateAllCowIndicators()
		end
	end)

	print("EnhancedCowMilkSystem: Started enhanced indicator update system")
end

function EnhancedCowMilkSystem:UpdateAllCowIndicators()
	for cowId, indicator in pairs(self.CowIndicators) do
		if indicator.part and indicator.part.Parent then
			local state = self:GetCowIndicatorState(cowId)

			-- Get detailed timing info
			if GameCore then
				local cowModel = self.ActiveCows[cowId]
				if cowModel then
					local owner = cowModel:GetAttribute("Owner")
					if owner then
						local ownerPlayer = game:GetService("Players"):FindFirstChild(owner)
						if ownerPlayer then
							local playerData = GameCore:GetPlayerData(ownerPlayer)
							if playerData and playerData.livestock and playerData.livestock.cows then
								local cowData = playerData.livestock.cows[cowId]
								if cowData then
									local currentTime = os.time()
									local timeSinceCollection = currentTime - (cowData.lastMilkCollection or 0)
									local timeLeft = (cowData.cooldown or 60) - timeSinceCollection

									self:UpdateIndicatorWithCooldown(cowId, timeLeft)
									continue
								end
							end
						end
					end
				end
			end

			-- Fallback to simple state update
			self:UpdateCowIndicatorLocal(cowId, state)
		end
	end
end

-- ========== ENHANCED MILK COLLECTION WITH PROPER INDICATOR UPDATES ==========

function EnhancedCowMilkSystem:HandleEnhancedCowMilkCollection(player, cowId)
	print("🥛 EnhancedCowMilkSystem: Processing enhanced milk collection from cow " .. cowId)

	-- Use GameCore if available
	if GameCore and GameCore.HandleCowMilkCollection then
		local success, result = pcall(function()
			return GameCore:HandleCowMilkCollection(player, cowId)
		end)

		if success and result then
			-- Create enhanced collection effects
			self:CreateEnhancedMilkEffect(cowId)

			-- Update indicator to cooldown state
			self:UpdateCowIndicator(cowId, player)

			print("🥛 EnhancedCowMilkSystem: Milk collection successful via GameCore")
			return true
		else
			warn("🥛 EnhancedCowMilkSystem: GameCore milk collection failed: " .. tostring(result))
		end
	end

	-- Fallback handling if GameCore isn't available
	return self:HandleMilkCollectionFallback(player, cowId)
end

function EnhancedCowMilkSystem:HandleMilkCollectionFallback(player, cowId)
	print("🥛 EnhancedCowMilkSystem: Using fallback milk collection for " .. cowId)

	local cowModel = self.ActiveCows[cowId]
	if not cowModel then
		self:SendNotification(player, "Cow Error", "Cow not found!", "error")
		return false
	end

	-- Basic cooldown check (fallback implementation)
	local lastCollection = self.PlayerCooldowns[player.UserId] and self.PlayerCooldowns[player.UserId][cowId] or 0
	local currentTime = os.time()
	local cooldown = 60 -- Default cooldown

	if currentTime - lastCollection < cooldown then
		local timeLeft = cooldown - (currentTime - lastCollection)
		self:SendNotification(player, "🐄 Cow Resting", 
			"Cow needs " .. math.ceil(timeLeft) .. " more seconds!", "warning")
		return false
	end

	-- Update cooldown
	if not self.PlayerCooldowns[player.UserId] then
		self.PlayerCooldowns[player.UserId] = {}
	end
	self.PlayerCooldowns[player.UserId][cowId] = currentTime

	-- Update indicator
	self:UpdateCowIndicatorLocal(cowId, "cooldown")

	-- Create effect
	self:CreateEnhancedMilkEffect(cowId)

	self:SendNotification(player, "🥛 Milk Collected!", "Collected milk from your cow!", "success")
	return true
end

-- ========== REPLACE EXISTING MILK COLLECTION HANDLER ==========

-- REPLACE your existing HandleCowMilkCollection method with this:
function EnhancedCowMilkSystem:HandleCowMilkCollection(player, cowId)
	return self:HandleEnhancedCowMilkCollection(player, cowId)
end

-- ========== UPDATE THE INITIALIZATION TO USE ENHANCED INDICATORS ==========

-- UPDATE your existing CreateMilkIndicator method to use the enhanced version:

-- ========== ADD TO YOUR INITIALIZATION ==========

-- Add this to your Initialize method after existing initialization:
function EnhancedCowMilkSystem:InitializeEnhancedFeatures()
	print("EnhancedCowMilkSystem: Initializing enhanced features...")

	-- Start enhanced indicator updates
	self:StartEnhancedIndicatorUpdates()

	-- Initialize player cooldown tracking
	self.PlayerCooldowns = {}

	print("EnhancedCowMilkSystem: Enhanced features initialized!")
end

-- Call this in your main Initialize method:
-- self:InitializeEnhancedFeatures()

print("EnhancedCowMilkSystem: ✅ Missing UpdateCowIndicator method added!")
print("🔧 FIXED METHODS:")
print("  📊 UpdateCowIndicator - Updates cow milk indicators")
print("  🎯 UpdateCowIndicatorLocal - Local indicator management") 
print("  ⏱️ UpdateIndicatorWithCooldown - Timer-based updates")
print("  📈 GetCowIndicatorState - State calculation")
print("  🎨 CreateEnhancedMilkIndicator - Better visual indicators")
print("  🔄 Enhanced milk collection with proper indicator updates")
function EnhancedCowMilkSystem:GetCowStats()
	-- Quick stats for debugging
	local stats = {
		activeCows = self:CountTable(self.ActiveCows or {}),
		indicators = self:CountTable(self.CowIndicators or {}),
		effects = _G.CowVisualEffects and self:CountTable(_G.CowVisualEffects.ActiveEffects or {}) or 0,
		gameCore = GameCore ~= nil
	}
	return stats
end

function EnhancedCowMilkSystem:GetPlayerCowList(playerName)
	-- Get a simple list of player's cows
	local cows = {}

	for cowId, cowModel in pairs(self.ActiveCows or {}) do
		if cowModel and cowModel.Parent then
			local owner = cowModel:GetAttribute("Owner")
			if owner == playerName then
				table.insert(cows, {
					id = cowId,
					tier = cowModel:GetAttribute("Tier") or "basic",
					position = self:GetCowCenter(cowModel)
				})
			end
		end
	end

	return cows
end

function EnhancedCowMilkSystem:ValidateSystemIntegrity()
	-- Check system health
	local issues = {}

	-- Check for orphaned indicators
	for cowId, indicator in pairs(self.CowIndicators or {}) do
		if not self.ActiveCows[cowId] then
			table.insert(issues, "Orphaned indicator for cow: " .. cowId)
		end
	end

	-- Check for cows without indicators
	for cowId, cowModel in pairs(self.ActiveCows or {}) do
		if not self.CowIndicators[cowId] then
			table.insert(issues, "Cow missing indicator: " .. cowId)
		end
	end

	return issues
end

print("EnhancedCowMilkSystem: ✅ Missing methods added!")
print("  📊 GetPlayerCowInfo - Returns detailed player cow data")
print("  📈 GetPerformanceData - Returns system performance metrics")
print("  🔧 Additional utility methods for admin panel")
-- ========== MILK COLLECTION ENHANCEMENT ==========


function EnhancedCowMilkSystem:CreateEnhancedMilkEffect(cowId)
	local cowModel = self.ActiveCows[cowId]
	if not cowModel then return end

	local tier = cowModel:GetAttribute("Tier") or "basic"
	local cowCenter = self:GetCowCenter(cowModel)

	-- Tier-specific milk effects
	local effectColors = {
		basic = Color3.fromRGB(255, 255, 255),
		silver = Color3.fromRGB(220, 220, 220),
		gold = Color3.fromRGB(255, 215, 0),
		diamond = Color3.fromRGB(185, 242, 255),
		rainbow = Color3.fromRGB(255, 100, 255),
		cosmic = Color3.fromRGB(138, 43, 226)
	}

	local dropletColor = effectColors[tier] or effectColors.basic
	local dropletCount = tier == "cosmic" and 15 or tier == "rainbow" and 12 or tier == "diamond" and 10 or tier == "gold" and 8 or 6

	-- Create enhanced milk droplets
	for i = 1, dropletCount do
		local droplet = Instance.new("Part")
		droplet.Size = Vector3.new(0.4, 0.4, 0.4)
		droplet.Shape = Enum.PartType.Ball
		droplet.Material = tier == "cosmic" and Enum.Material.Neon or Enum.Material.Plastic
		droplet.Color = dropletColor
		droplet.CanCollide = false
		droplet.Anchored = true
		droplet.Position = cowCenter + Vector3.new(
			math.random(-3, 3),
			math.random(0, 3),
			math.random(-3, 3)
		)
		droplet.Parent = workspace

		-- Special effects for higher tiers
		if tier == "rainbow" then
			local hue = math.random()
			droplet.Color = Color3.fromHSV(hue, 1, 1)
		end

		if tier == "cosmic" then
			-- Add cosmic trail
			spawn(function()
				local trail = Instance.new("Part")
				trail.Size = Vector3.new(0.1, 0.1, 0.1)
				trail.Material = Enum.Material.Neon
				trail.Color = Color3.fromRGB(100, 50, 200)
				trail.CanCollide = false
				trail.Anchored = true
				trail.Parent = workspace

				for t = 0, 1, 0.1 do
					if droplet and droplet.Parent then
						trail.Position = droplet.Position - Vector3.new(0, t * 2, 0)
						trail.Transparency = t
						wait(0.05)
					end
				end
				trail:Destroy()
			end)
		end

		-- Animate droplet
		local tween = TweenService:Create(droplet,
			TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = droplet.Position + Vector3.new(0, 12, 0),
				Transparency = 1,
				Size = Vector3.new(0.1, 0.1, 0.1)
			}
		)
		tween:Play()
		tween.Completed:Connect(function()
			droplet:Destroy()
		end)
	end

	-- Flash the cow indicator
	self:FlashCowIndicator(cowId, tier)
end

function EnhancedCowMilkSystem:FlashCowIndicator(cowId, tier)
	local indicator = self.CowIndicators[cowId]
	if not indicator then return end

	local colors = {
		basic = Color3.fromRGB(0, 255, 0),
		silver = Color3.fromRGB(192, 192, 192),
		gold = Color3.fromRGB(255, 215, 0),
		diamond = Color3.fromRGB(185, 242, 255),
		rainbow = Color3.fromRGB(255, 100, 255),
		cosmic = Color3.fromRGB(138, 43, 226)
	}

	local flashColor = colors[tier] or colors.basic
	local originalColor = indicator.part.Color

	-- Flash effect
	indicator.part.Color = flashColor
	indicator.label.Text = "🥛 MILK COLLECTED!"
	indicator.label.TextColor3 = flashColor

	-- For rainbow tier, add color cycling
	if tier == "rainbow" then
		spawn(function()
			local hue = 0
			for i = 1, 20 do
				if indicator.part and indicator.part.Parent then
					indicator.part.Color = Color3.fromHSV(hue, 1, 1)
					indicator.label.TextColor3 = Color3.fromHSV(hue, 1, 1)
					hue = (hue + 0.1) % 1
					wait(0.1)
				end
			end
		end)
	end

	-- Return to normal after delay
	spawn(function()
		wait(3)
		if indicator.part and indicator.part.Parent then
			indicator.part.Color = originalColor
			indicator.label.Text = "🥛 CLICK TO COLLECT MILK"
			indicator.label.TextColor3 = Color3.new(1, 1, 1)
		end
	end)
end

-- ========== AUTO-MILKING SYSTEM ==========

function EnhancedCowMilkSystem:StartAutoMilking()
	spawn(function()
		while true do
			wait(AUTO_MILK_INTERVAL)
			self:ProcessAutoMilking()
		end
	end)
end

function EnhancedCowMilkSystem:ProcessAutoMilking()
	for _, player in pairs(Players:GetPlayers()) do
		if self:PlayerHasAutoMilker(player) then
			self:AutoMilkPlayerCows(player)
		end
	end
end

function EnhancedCowMilkSystem:PlayerHasAutoMilker(player)
	if not GameCore then return false end

	local playerData = GameCore:GetPlayerData(player)
	if not playerData or not playerData.upgrades then return false end

	return playerData.upgrades.auto_milker == true
end

function EnhancedCowMilkSystem:AutoMilkPlayerCows(player)
	if not GameCore then return end

	local playerData = GameCore:GetPlayerData(player)
	if not playerData or not playerData.livestock or not playerData.livestock.cows then return end

	local milkedCount = 0

	for cowId, cowData in pairs(playerData.livestock.cows) do
		local currentTime = os.time()
		local timeSinceCollection = currentTime - cowData.lastMilkCollection

		if timeSinceCollection >= cowData.cooldown then
			local success = GameCore:HandleCowMilkCollection(player, cowId)
			if success then
				milkedCount = milkedCount + 1
				self:CreateEnhancedMilkEffect(cowId)
			end
		end
	end

	if milkedCount > 0 then
		self:SendNotification(player, "🤖 Auto Milker", 
			"Automatically collected milk from " .. milkedCount .. " cows!", "success")
	end
end

-- ========== MONITORING AND UPDATES ==========

function EnhancedCowMilkSystem:StartCowMonitoring()
	spawn(function()
		while true do
			wait(5)
			self:UpdateAllCows()
		end
	end)
end

function EnhancedCowMilkSystem:StartIndicatorUpdates()
	spawn(function()
		while true do
			wait(2)
			self:UpdateAllIndicators()
		end
	end)
end

function EnhancedCowMilkSystem:UpdateAllCows()
	-- Check for new cows
	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("Model") and obj.Name:find("cow_") and not self.ActiveCows[obj.Name] then
			local owner = obj:GetAttribute("Owner")
			if owner then
				self:RegisterCow(obj, obj.Name, owner)
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

function EnhancedCowMilkSystem:UpdateAllIndicators()
	for cowId, indicator in pairs(self.CowIndicators) do
		if indicator.part and indicator.part.Parent then
			self:UpdateCowIndicatorStatus(cowId)
		end
	end
end

function EnhancedCowMilkSystem:UpdateCowIndicatorStatus(cowId)
	local indicator = self.CowIndicators[cowId]
	local cowModel = self.ActiveCows[cowId]

	if not indicator or not cowModel then return end

	local owner = cowModel:GetAttribute("Owner")
	if not owner then return end

	local player = Players:FindFirstChild(owner)
	if not player or not GameCore then return end

	local playerData = GameCore:GetPlayerData(player)
	if not playerData or not playerData.livestock or not playerData.livestock.cows then return end

	local cowData = playerData.livestock.cows[cowId]
	if not cowData then return end

	-- Calculate status
	local currentTime = os.time()
	local timeSinceCollection = currentTime - cowData.lastMilkCollection
	local timeLeft = cowData.cooldown - timeSinceCollection

	if timeLeft <= 0 then
		-- Ready
		indicator.part.Color = Color3.fromRGB(0, 255, 0)
		indicator.label.Text = "🥛 READY TO COLLECT!"
		indicator.label.TextColor3 = Color3.fromRGB(0, 255, 0)
	elseif timeLeft <= 10 then
		-- Almost ready
		indicator.part.Color = Color3.fromRGB(255, 255, 0)
		indicator.label.Text = "🥛 ALMOST READY (" .. math.ceil(timeLeft) .. "s)"
		indicator.label.TextColor3 = Color3.fromRGB(255, 255, 0)
	else
		-- Waiting
		indicator.part.Color = Color3.fromRGB(255, 0, 0)
		indicator.label.Text = "🥛 RESTING (" .. math.ceil(timeLeft) .. "s)"
		indicator.label.TextColor3 = Color3.fromRGB(255, 100, 100)
	end
end

-- ========== UTILITY FUNCTIONS ==========

function EnhancedCowMilkSystem:GetCowBounds(cowModel)
	if cowModel.PrimaryPart then
		return cowModel.PrimaryPart.Position, cowModel.PrimaryPart.Size
	end

	local cframe, size = cowModel:GetBoundingBox()
	return cframe.Position, size
end

function EnhancedCowMilkSystem:GetCowCenter(cowModel)
	local position, _ = self:GetCowBounds(cowModel)
	return position
end

function EnhancedCowMilkSystem:IsCowBodyPart(part)
	local bodyNames = {"body", "torso", "head", "humanoidrootpart"}
	local partName = part.Name:lower()

	for _, name in ipairs(bodyNames) do
		if partName:find(name) then
			return true
		end
	end

	return false
end

function EnhancedCowMilkSystem:HighlightCow(cowModel, highlight)
	for _, part in pairs(cowModel:GetDescendants()) do
		if part:IsA("BasePart") then
			if highlight then
				if not part:FindFirstChild("Highlight") then
					local selection = Instance.new("SelectionBox")
					selection.Name = "Highlight"
					selection.Color3 = Color3.fromRGB(0, 255, 0)
					selection.Transparency = 0.7
					selection.Adornee = part
					selection.Parent = part
				end
			else
				local highlight = part:FindFirstChild("Highlight")
				if highlight then
					highlight:Destroy()
				end
			end
		end
	end
end

function EnhancedCowMilkSystem:SendNotification(player, title, message, notificationType)
	if GameCore and GameCore.SendNotification then
		GameCore:SendNotification(player, title, message, notificationType)
	else
		print("NOTIFICATION for " .. player.Name .. ": [" .. (notificationType or "info"):upper() .. "] " .. title .. " - " .. message)
	end
end

function EnhancedCowMilkSystem:UnregisterCow(cowId)
	self.ActiveCows[cowId] = nil
	self.CowIndicators[cowId] = nil
	print("EnhancedCowMilkSystem: Unregistered cow " .. cowId)
end

function EnhancedCowMilkSystem:ClearCowEffects(cowModel)
	-- Remove existing lighting effects
	for _, obj in pairs(cowModel:GetDescendants()) do
		if obj:IsA("PointLight") or obj:IsA("SpotLight") then
			obj:Destroy()
		end
	end
end

-- ========== ADMIN COMMANDS ==========

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.Name == "TommySalami311" then -- Replace with your username
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/cowstatus" then
				print("=== ENHANCED COW SYSTEM STATUS ===")
				print("Active cows: " .. EnhancedCowMilkSystem:CountTable(EnhancedCowMilkSystem.ActiveCows))
				print("Cow indicators: " .. EnhancedCowMilkSystem:CountTable(EnhancedCowMilkSystem.CowIndicators))
				print("GameCore available: " .. tostring(GameCore ~= nil))

				for cowId, cowModel in pairs(EnhancedCowMilkSystem.ActiveCows) do
					local tier = cowModel:GetAttribute("Tier") or "basic"
					local owner = cowModel:GetAttribute("Owner") or "unknown"
					print("  " .. cowId .. ": " .. tier .. " tier (owner: " .. owner .. ")")
				end
				print("===================================")

			elseif command == "/testeffects" then
				local tier = args[2] or "gold"
				for cowId, cowModel in pairs(EnhancedCowMilkSystem.ActiveCows) do
					local owner = cowModel:GetAttribute("Owner")
					if owner == player.Name then
						EnhancedCowMilkSystem:ApplyTierEffects(cowModel, tier)
						cowModel:SetAttribute("Tier", tier)
						print("Applied " .. tier .. " effects to cow " .. cowId)
						break
					end
				end

			elseif command == "/giveautomilker" then
				if GameCore then
					local playerData = GameCore:GetPlayerData(player)
					if playerData then
						playerData.upgrades = playerData.upgrades or {}
						playerData.upgrades.auto_milker = true
						GameCore:SavePlayerData(player)
						print("Admin: Gave auto milker to " .. player.Name)
					end
				end

			elseif command == "/clearcoweffects" then
				for cowId, cowModel in pairs(EnhancedCowMilkSystem.ActiveCows) do
					EnhancedCowMilkSystem:ClearCowEffects(cowModel)
				end
				print("Admin: Cleared all cow effects")
			end
		end
	end)
end)

function EnhancedCowMilkSystem:CountTable(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- ========== INITIALIZATION ==========

EnhancedCowMilkSystem:Initialize()
_G.EnhancedCowMilkSystem = EnhancedCowMilkSystem

print("=== ENHANCED COW MILK SYSTEM ACTIVE ===")
print("✅ Multiple cow support with tier progression")
print("✅ Visual effects for each cow tier")
print("✅ Individual cow management and tracking")
print("✅ Auto-milking system for premium users")
print("✅ Enhanced visual feedback and effects")
print("")
print("Admin Commands:")
print("  /cowstatus - Show all active cows")
print("  /testeffects [tier] - Apply tier effects to your cow")
print("  /giveautomilker - Give yourself auto milker")
print("  /clearcoweffects - Clear all visual effects")