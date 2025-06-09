--[[
    MiningSystem.server.lua - COMPLETE MINING SYSTEM
    Place in: ServerScriptService/Systems/MiningSystem.server.lua
    
    FEATURES:
    ✅ Cave generation and management
    ✅ Ore node spawning and respawning
    ✅ Mining mechanics with tools and durability
    ✅ XP progression and skill levels
    ✅ Cave teleportation system
    ✅ Ore selling and economics
]]

local MiningSystem = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Load dependencies
local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))
local GameCore = _G.GameCore or require(game:GetService("ServerScriptService").Core:WaitForChild("GameCore"))

-- Mining system state
MiningSystem.PlayerData = {}
MiningSystem.OreNodes = {}
MiningSystem.CaveInstances = {}
MiningSystem.MiningCooldowns = {}

-- Remote events
local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "GameRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

-- Create mining remote events
local function CreateRemoteEvent(name)
	local existing = remoteFolder:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	elseif existing then
		existing:Destroy()
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remoteFolder
	return remote
end

local TeleportToCaveEvent = CreateRemoteEvent("TeleportToCave")
local TeleportToSurfaceEvent = CreateRemoteEvent("TeleportToSurface")
local SellOreEvent = CreateRemoteEvent("SellOre")
local UpdateMiningDataEvent = CreateRemoteEvent("UpdateMiningData")

-- ========== CORE MINING FUNCTIONS ==========

-- Initialize mining system
function MiningSystem:Initialize()
	print("MiningSystem: Initializing complete mining system...")

	-- Setup remote event handlers
	self:SetupRemoteEvents()

	-- Setup player connection handlers
	self:SetupPlayerHandlers()

	-- Start system loops
	self:StartSystemLoops()

	print("MiningSystem: ✅ Complete mining system initialized!")
end

-- Setup remote event handlers
function MiningSystem:SetupRemoteEvents()
	TeleportToCaveEvent.OnServerEvent:Connect(function(player)
		self:TeleportPlayerToCave(player)
	end)

	TeleportToSurfaceEvent.OnServerEvent:Connect(function(player)
		self:TeleportPlayerToSurface(player)
	end)

	SellOreEvent.OnServerEvent:Connect(function(player, oreType, amount)
		self:SellOre(player, oreType, amount)
	end)

	print("MiningSystem: Remote events connected")
end

-- Setup player handlers
function MiningSystem:SetupPlayerHandlers()
	Players.PlayerAdded:Connect(function(player)
		self:InitializePlayerMining(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:CleanupPlayerMining(player)
	end)

	-- Initialize existing players
	for _, player in pairs(Players:GetPlayers()) do
		self:InitializePlayerMining(player)
	end
end

-- Initialize mining data for a player
function MiningSystem:InitializePlayerMining(player)
	local userId = player.UserId

	if not self.PlayerData[userId] then
		self.PlayerData[userId] = {
			level = 1,
			xp = 0,
			inventory = {},
			currentTool = nil,
			toolDurability = {},
			caveAccess = false,
			cavePosition = nil,
			lastMining = 0
		}
	end

	self.MiningCooldowns[userId] = 0

	print("MiningSystem: Initialized mining data for " .. player.Name)
end

-- Cleanup player mining data
function MiningSystem:CleanupPlayerMining(player)
	local userId = player.UserId

	-- Clean up cave instance if exists
	if self.CaveInstances[userId] then
		self:DestroyCave(userId)
	end

	-- Clean up mining data
	self.PlayerData[userId] = nil
	self.MiningCooldowns[userId] = nil

	print("MiningSystem: Cleaned up mining data for " .. player.Name)
end

-- ========== CAVE SYSTEM ==========

-- Create cave for player
function MiningSystem:CreateCave(player)
	local userId = player.UserId

	if self.CaveInstances[userId] then
		return self.CaveInstances[userId] -- Already exists
	end

	print("MiningSystem: Creating cave for " .. player.Name)

	-- Find or create cave area
	local caveArea = workspace:FindFirstChild("MiningCaves")
	if not caveArea then
		caveArea = Instance.new("Folder")
		caveArea.Name = "MiningCaves"
		caveArea.Parent = workspace
	end

	-- Create individual cave instance
	local cave = Instance.new("Model")
	cave.Name = player.Name .. "_Cave"
	cave.Parent = caveArea

	-- Calculate cave position (spread caves apart)
	local caveIndex = 0
	for _ in pairs(self.CaveInstances) do
		caveIndex = caveIndex + 1
	end

	local basePosition = Vector3.new(
		1000 + (caveIndex % 10) * 200, -- X spread
		-100, -- Underground
		1000 + math.floor(caveIndex / 10) * 200 -- Z spread
	)

	-- Generate cave structure
	self:GenerateCaveStructure(cave, basePosition)

	-- Generate ore nodes
	self:GenerateOreNodes(cave, basePosition, userId)

	-- Store cave instance
	self.CaveInstances[userId] = {
		model = cave,
		position = basePosition,
		oreNodes = {},
		lastVisit = os.time()
	}

	-- Update player data
	if not self.PlayerData[userId] then
		self:InitializePlayerMining(player)
	end
	self.PlayerData[userId].cavePosition = basePosition

	print("MiningSystem: Cave created for " .. player.Name .. " at " .. tostring(basePosition))
	return cave
end

-- Generate cave structure
function MiningSystem:GenerateCaveStructure(cave, basePosition)
	-- Cave floor
	local floor = Instance.new("Part")
	floor.Name = "CaveFloor"
	floor.Size = Vector3.new(120, 6, 120)
	floor.Position = basePosition
	floor.Material = Enum.Material.Rock
	floor.Color = Color3.fromRGB(45, 40, 35)
	floor.Anchored = true
	floor.Parent = cave

	-- Cave walls (create a box structure)
	local wallConfigs = {
		{name = "WallNorth", size = Vector3.new(120, 25, 6), offset = Vector3.new(0, 12, -63)},
		{name = "WallSouth", size = Vector3.new(120, 25, 6), offset = Vector3.new(0, 12, 63)},
		{name = "WallEast", size = Vector3.new(6, 25, 120), offset = Vector3.new(63, 12, 0)},
		{name = "WallWest", size = Vector3.new(6, 25, 120), offset = Vector3.new(-63, 12, 0)}
	}

	for _, config in ipairs(wallConfigs) do
		local wall = Instance.new("Part")
		wall.Name = config.name
		wall.Size = config.size
		wall.Position = basePosition + config.offset
		wall.Material = Enum.Material.Rock
		wall.Color = Color3.fromRGB(35, 30, 25)
		wall.Anchored = true
		wall.Parent = cave
	end

	-- Cave ceiling
	local ceiling = Instance.new("Part")
	ceiling.Name = "CaveCeiling"
	ceiling.Size = Vector3.new(120, 6, 120)
	ceiling.Position = basePosition + Vector3.new(0, 25, 0)
	ceiling.Material = Enum.Material.Rock
	ceiling.Color = Color3.fromRGB(25, 20, 15)
	ceiling.Anchored = true
	ceiling.Parent = cave

	-- Create atmospheric lighting
	self:CreateCaveLighting(cave, basePosition)

	-- Create entrance/exit portal
	self:CreateCavePortal(cave, basePosition)

	-- Add atmospheric effects
	self:AddCaveAtmosphere(cave, basePosition)
end

-- Create cave lighting system
function MiningSystem:CreateCaveLighting(cave, basePosition)
	-- Main central light
	local centralLight = Instance.new("Part")
	centralLight.Name = "CentralLight"
	centralLight.Size = Vector3.new(4, 2, 4)
	centralLight.Position = basePosition + Vector3.new(0, 15, 0)
	centralLight.Material = Enum.Material.Neon
	centralLight.Color = Color3.fromRGB(255, 220, 150)
	centralLight.Anchored = true
	centralLight.CanCollide = false
	centralLight.Parent = cave

	local mainLight = Instance.new("PointLight")
	mainLight.Brightness = 3
	mainLight.Range = 40
	mainLight.Color = Color3.fromRGB(255, 220, 150)
	mainLight.Parent = centralLight

	-- Corner torches for ambiance
	local torchPositions = {
		Vector3.new(45, 8, 45),
		Vector3.new(-45, 8, 45),
		Vector3.new(45, 8, -45),
		Vector3.new(-45, 8, -45)
	}

	for i, offset in ipairs(torchPositions) do
		local torch = Instance.new("Part")
		torch.Name = "Torch" .. i
		torch.Size = Vector3.new(1, 4, 1)
		torch.Position = basePosition + offset
		torch.Material = Enum.Material.Wood
		torch.Color = Color3.fromRGB(101, 67, 33)
		torch.Anchored = true
		torch.Parent = cave

		-- Torch flame
		local flame = Instance.new("Part")
		flame.Name = "Flame"
		flame.Size = Vector3.new(0.8, 1.5, 0.8)
		flame.Position = torch.Position + Vector3.new(0, 3, 0)
		flame.Material = Enum.Material.Neon
		flame.Color = Color3.fromRGB(255, 150, 0)
		flame.Shape = Enum.PartType.Ball
		flame.Anchored = true
		flame.CanCollide = false
		flame.Parent = cave

		-- Fire effect
		local fire = Instance.new("Fire")
		fire.Size = 3
		fire.Heat = 8
		fire.Parent = flame

		-- Torch light
		local torchLight = Instance.new("PointLight")
		torchLight.Brightness = 1.5
		torchLight.Range = 15
		torchLight.Color = Color3.fromRGB(255, 150, 0)
		torchLight.Parent = flame

		-- Animate flame
		spawn(function()
			while flame and flame.Parent do
				local tween = TweenService:Create(flame,
					TweenInfo.new(1 + math.random(), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
					{Size = flame.Size * (0.8 + math.random() * 0.4)}
				)
				tween:Play()
				wait(0.1)
			end
		end)
	end
end

-- Create cave portal for teleportation
function MiningSystem:CreateCavePortal(cave, basePosition)
	local portal = Instance.new("Part")
	portal.Name = "ExitPortal"
	portal.Size = Vector3.new(8, 12, 3)
	portal.Position = basePosition + Vector3.new(0, 6, 55)
	portal.Material = Enum.Material.Neon
	portal.Color = Color3.fromRGB(100, 200, 255)
	portal.Transparency = 0.3
	portal.Anchored = true
	portal.Parent = cave

	-- Portal frame
	local frame = Instance.new("Part")
	frame.Name = "PortalFrame"
	frame.Size = Vector3.new(10, 14, 1)
	frame.Position = portal.Position + Vector3.new(0, 0, -2)
	frame.Material = Enum.Material.Metal
	frame.Color = Color3.fromRGB(80, 80, 100)
	frame.Anchored = true
	frame.Parent = cave

	-- Portal effects
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = Color3.fromRGB(100, 200, 255)
	sparkles.Parent = portal

	-- Portal click detector
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 12
	clickDetector.Parent = portal

	clickDetector.MouseClick:Connect(function(player)
		self:TeleportPlayerToSurface(player)
	end)

	-- Animate portal
	spawn(function()
		while portal and portal.Parent do
			local tween = TweenService:Create(portal,
				TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{Transparency = 0.6, Color = Color3.fromRGB(150, 150, 255)}
			)
			tween:Play()
			wait(0.1)
		end
	end)

	-- Portal sign
	local sign = Instance.new("Part")
	sign.Name = "PortalSign"
	sign.Size = Vector3.new(6, 3, 0.5)
	sign.Position = portal.Position + Vector3.new(0, 8, -3)
	sign.Material = Enum.Material.Wood
	sign.Color = Color3.fromRGB(139, 90, 43)
	sign.Anchored = true
	sign.Parent = cave

	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = sign

	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.new(1, 0, 1, 0)
	signText.BackgroundTransparency = 1
	signText.Text = "🚀 EXIT TO SURFACE\nClick Portal to Leave"
	signText.TextColor3 = Color3.new(1, 1, 1)
	signText.TextScaled = true
	signText.Font = Enum.Font.GothamBold
	signText.TextStrokeTransparency = 0
	signText.TextStrokeColor3 = Color3.new(0, 0, 0)
	signText.Parent = signGui
end

-- Add atmospheric effects to cave
function MiningSystem:AddCaveAtmosphere(cave, basePosition)
	-- Fog/atmosphere
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.5
	atmosphere.Color = Color3.fromRGB(200, 200, 255)
	atmosphere.Glare = 0.2
	atmosphere.Haze = 1.5
	atmosphere.Parent = game:GetService("Lighting")

	-- Ambient cave sounds (placeholder)
	local sound = Instance.new("Sound")
	sound.Name = "CaveAmbience"
	sound.SoundId = "rbxasset://sounds/impact_water.mp3" -- Placeholder
	sound.Volume = 0.3
	sound.Looped = true
	sound.Parent = cave
	-- sound:Play() -- Uncomment when you have proper cave sounds

	-- Stalactites for decoration
	for i = 1, 15 do
		local stalactite = Instance.new("Part")
		stalactite.Name = "Stalactite" .. i
		stalactite.Size = Vector3.new(
			1 + math.random() * 2,
			3 + math.random() * 4,
			1 + math.random() * 2
		)
		stalactite.Position = basePosition + Vector3.new(
			(math.random() - 0.5) * 100,
			20,
			(math.random() - 0.5) * 100
		)
		stalactite.Material = Enum.Material.Rock
		stalactite.Color = Color3.fromRGB(60, 55, 50)
		stalactite.Anchored = true
		stalactite.Parent = cave
	end
end

-- ========== ORE GENERATION SYSTEM ==========

-- Generate ore nodes in cave
function MiningSystem:GenerateOreNodes(cave, basePosition, ownerId)
	local nodeCount = 0

	-- Generate different ore types with appropriate spawn rates
	for oreType, oreData in pairs(ItemConfig.MiningSystem.ores) do
		local nodesToCreate = math.floor(30 * oreData.spawnChance) -- Up to 30 nodes per type

		for i = 1, nodesToCreate do
			local nodePosition = self:FindValidOrePosition(basePosition)
			if nodePosition then
				local oreNode = self:CreateOreNode(oreType, oreData, nodePosition, ownerId)
				oreNode.Parent = cave
				nodeCount = nodeCount + 1

				-- Store node reference
				if not self.OreNodes[ownerId] then
					self.OreNodes[ownerId] = {}
				end
				table.insert(self.OreNodes[ownerId], oreNode)
			end
		end
	end

	print("MiningSystem: Generated " .. nodeCount .. " ore nodes")
end

-- Find valid position for ore node (avoid overlapping)
function MiningSystem:FindValidOrePosition(basePosition)
	local attempts = 0
	local maxAttempts = 50

	while attempts < maxAttempts do
		attempts = attempts + 1

		local testPosition = basePosition + Vector3.new(
			(math.random() - 0.5) * 100, -- X: -50 to 50
			math.random() * 8 + 4, -- Y: 4 to 12 (above floor)
			(math.random() - 0.5) * 100 -- Z: -50 to 50
		)

		-- Check if position is clear (basic check)
		local region = Region3.new(
			testPosition - Vector3.new(3, 3, 3),
			testPosition + Vector3.new(3, 3, 3)
		)

		local parts = workspace:ReadVoxels(region, 4)
		local isEmpty = true

		-- Simple check - if we can't read voxels or there are too many parts nearby, skip
		pcall(function()
			if parts.Size.X > 0 then
				isEmpty = false
			end
		end)

		if isEmpty then
			return testPosition
		end
	end

	-- Fallback position if no good spot found
	return basePosition + Vector3.new(
		(math.random() - 0.5) * 80,
		6,
		(math.random() - 0.5) * 80
	)
end

-- Create individual ore node
function MiningSystem:CreateOreNode(oreType, oreData, position, ownerId)
	local oreNode = Instance.new("Model")
	oreNode.Name = oreType .. "_Node_" .. math.random(1000, 9999)

	-- Main ore part
	local orePart = Instance.new("Part")
	orePart.Name = "OreCore"
	orePart.Size = Vector3.new(4, 4, 4)
	orePart.Position = position
	orePart.Material = Enum.Material.Rock
	orePart.Color = oreData.color
	orePart.Anchored = true
	orePart.Parent = oreNode

	-- Add ore-specific visual effects
	self:ApplyOreEffects(orePart, oreType, oreData)

	-- Ore indicator
	local indicator = Instance.new("Part")
	indicator.Name = "OreIndicator"
	indicator.Size = Vector3.new(0.8, 6, 0.8)
	indicator.Material = Enum.Material.Neon
	indicator.Color = oreData.color
	indicator.Anchored = true
	indicator.CanCollide = false
	indicator.Position = position + Vector3.new(0, 5, 0)
	indicator.Parent = oreNode

	-- Ore information display
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "OreInfo"
	billboardGui.Size = UDim2.new(0, 120, 0, 60)
	billboardGui.StudsOffset = Vector3.new(0, 7, 0)
	billboardGui.Parent = orePart

	local oreLabel = Instance.new("TextLabel")
	oreLabel.Size = UDim2.new(1, 0, 1, 0)
	oreLabel.BackgroundTransparency = 1
	oreLabel.Text = oreData.icon .. " " .. oreData.name .. "\nLv." .. oreData.requiredLevel .. " | " .. oreData.sellValue .. " coins"
	oreLabel.TextColor3 = Color3.new(1, 1, 1)
	oreLabel.TextScaled = true
	oreLabel.Font = Enum.Font.GothamBold
	oreLabel.TextStrokeTransparency = 0
	oreLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	oreLabel.Parent = billboardGui

	-- Set ore attributes
	oreNode:SetAttribute("OreType", oreType)
	oreNode:SetAttribute("Hardness", oreData.hardness)
	oreNode:SetAttribute("IsMineable", true)
	oreNode:SetAttribute("OwnerId", ownerId)
	oreNode:SetAttribute("RespawnTime", oreData.respawnTime)
	oreNode:SetAttribute("LastMined", 0)
	oreNode:SetAttribute("XPReward", oreData.xpReward)
	oreNode:SetAttribute("SellValue", oreData.sellValue)

	-- Mining click detector
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 10
	clickDetector.Parent = orePart

	clickDetector.MouseClick:Connect(function(player)
		if player.UserId == ownerId then
			self:HandleMining(player, oreNode)
		else
			self:SendNotification(player, "Not Your Cave", "You can only mine in your own cave!", "error")
		end
	end)

	oreNode.PrimaryPart = orePart
	return oreNode
end

-- Apply visual effects to ore based on type
function MiningSystem:ApplyOreEffects(orePart, oreType, oreData)
	if oreType == "diamond_ore" then
		orePart.Material = Enum.Material.Neon
		orePart.Transparency = 0.1

		-- Diamond sparkles
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = oreData.color
		sparkles.Parent = orePart

		-- Point light for glow
		local light = Instance.new("PointLight")
		light.Color = oreData.color
		light.Brightness = 1.5
		light.Range = 12
		light.Parent = orePart

	elseif oreType == "obsidian_ore" then
		orePart.Material = Enum.Material.Obsidian

		-- Dark purple glow
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(100, 0, 100)
		light.Brightness = 0.8
		light.Range = 10
		light.Parent = orePart

		-- Mysterious particles
		local attachment = Instance.new("Attachment")
		attachment.Parent = orePart

		-- Create custom particle effect (simplified)
		spawn(function()
			while orePart and orePart.Parent do
				wait(2 + math.random() * 3)
				local particle = Instance.new("Part")
				particle.Size = Vector3.new(0.3, 0.3, 0.3)
				particle.Material = Enum.Material.Neon
				particle.Color = Color3.fromRGB(80, 0, 80)
				particle.Anchored = true
				particle.CanCollide = false
				particle.Position = orePart.Position + Vector3.new(
					(math.random() - 0.5) * 6,
					math.random() * 6,
					(math.random() - 0.5) * 6
				)
				particle.Parent = workspace

				-- Animate particle
				local tween = TweenService:Create(particle,
					TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						Position = particle.Position + Vector3.new(0, 8, 0),
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

	elseif oreType == "gold_ore" then
		orePart.Material = Enum.Material.Neon
		orePart.Transparency = 0.2

		-- Golden glow
		local light = Instance.new("PointLight")
		light.Color = oreData.color
		light.Brightness = 1.2
		light.Range = 8
		light.Parent = orePart

	elseif oreType == "silver_ore" then
		orePart.Material = Enum.Material.Metal
		orePart.Reflectance = 0.7

	elseif oreType == "iron_ore" then
		orePart.Material = Enum.Material.Metal
		orePart.Reflectance = 0.3

	elseif oreType == "copper_ore" then
		orePart.Material = Enum.Material.Rock
		-- No special effects for basic copper
	end
end

-- ========== MINING MECHANICS ==========

-- Handle mining action
function MiningSystem:HandleMining(player, oreNode)
	local userId = player.UserId
	local currentTime = os.time()

	-- Check mining cooldown (prevent spam)
	local lastMining = self.MiningCooldowns[userId] or 0
	if currentTime - lastMining < 3 then
		self:SendNotification(player, "Mining Cooldown", "Wait " .. (3 - (currentTime - lastMining)) .. " seconds!", "warning")
		return
	end

	-- Check if ore is available
	local isMineable = oreNode:GetAttribute("IsMineable")
	if not isMineable then
		local lastMined = oreNode:GetAttribute("LastMined")
		local respawnTime = oreNode:GetAttribute("RespawnTime")
		local timeLeft = respawnTime - (currentTime - lastMined)

		self:SendNotification(player, "Ore Depleted", 
			oreNode:GetAttribute("OreType"):gsub("_", " ") .. " will respawn in " .. 
				math.ceil(timeLeft) .. " seconds!", "info")
		return
	end

	-- Get player mining data
	local playerMiningData = self.PlayerData[userId]
	if not playerMiningData then
		self:InitializePlayerMining(player)
		playerMiningData = self.PlayerData[userId]
	end

	-- Check tool requirements
	local oreType = oreNode:GetAttribute("OreType")
	local hardness = oreNode:GetAttribute("Hardness")
	local requiredLevel = ItemConfig.MiningSystem.ores[oreType].requiredLevel

	-- Check player level
	if playerMiningData.level < requiredLevel then
		self:SendNotification(player, "Level Too Low", 
			"You need Mining Level " .. requiredLevel .. " to mine " .. oreType:gsub("_", " ") .. "!", "error")
		return
	end

	-- Check tool
	local currentTool = playerMiningData.currentTool
	if not currentTool then
		self:SendNotification(player, "No Tool", "You need a pickaxe to mine! Purchase one from the shop.", "error")
		return
	end

	local toolData = ItemConfig.MiningSystem.tools[currentTool]
	if not toolData then
		self:SendNotification(player, "Invalid Tool", "Your mining tool is not recognized!", "error")
		return
	end

	-- Check if tool can mine this ore type
	local canMine = false
	for _, mineable in ipairs(toolData.canMine) do
		if mineable == oreType then
			canMine = true
			break
		end
	end

	if not canMine then
		self:SendNotification(player, "Tool Insufficient", 
			"Your " .. toolData.name .. " cannot mine " .. oreType:gsub("_", " ") .. "! Upgrade your tool.", "error")
		return
	end

	-- Calculate mining time based on ore hardness and tool power
	local baseMiningTime = hardness / toolData.speed
	local miningTime = math.max(2, baseMiningTime) -- Minimum 2 seconds

	-- Set cooldown
	self.MiningCooldowns[userId] = currentTime

	-- Start mining animation
	self:StartMiningAnimation(player, oreNode, miningTime)

	-- Complete mining after delay
	spawn(function()
		wait(miningTime)
		self:CompleteMining(player, oreNode, oreType)
	end)
end

-- Start mining animation and progress
function MiningSystem:StartMiningAnimation(player, oreNode, duration)
	local orePart = oreNode:FindFirstChild("OreCore")
	if not orePart then return end

	-- Create progress bar
	local progressGui = Instance.new("BillboardGui")
	progressGui.Name = "MiningProgress"
	progressGui.Size = UDim2.new(0, 150, 0, 25)
	progressGui.StudsOffset = Vector3.new(0, 4, 0)
	progressGui.Parent = orePart

	local progressFrame = Instance.new("Frame")
	progressFrame.Size = UDim2.new(1, 0, 1, 0)
	progressFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	progressFrame.BorderSizePixel = 0
	progressFrame.Parent = progressGui

	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0.2, 0)
	progressCorner.Parent = progressFrame

	local progressBar = Instance.new("Frame")
	progressBar.Name = "ProgressBar"
	progressBar.Size = UDim2.new(0, 0, 1, 0)
	progressBar.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	progressBar.BorderSizePixel = 0
	progressBar.Parent = progressFrame

	local progressBarCorner = Instance.new("UICorner")
	progressBarCorner.CornerRadius = UDim.new(0.2, 0)
	progressBarCorner.Parent = progressBar

	-- Progress text
	local progressText = Instance.new("TextLabel")
	progressText.Size = UDim2.new(1, 0, 1, 0)
	progressText.BackgroundTransparency = 1
	progressText.Text = "⛏️ Mining..."
	progressText.TextColor3 = Color3.new(1, 1, 1)
	progressText.TextScaled = true
	progressText.Font = Enum.Font.GothamBold
	progressText.TextStrokeTransparency = 0
	progressText.TextStrokeColor3 = Color3.new(0, 0, 0)
	progressText.Parent = progressFrame

	-- Animate progress bar
	local tween = TweenService:Create(progressBar,
		TweenInfo.new(duration, Enum.EasingStyle.Linear),
		{Size = UDim2.new(1, 0, 1, 0)}
	)
	tween:Play()

	-- Mining particle effects
	spawn(function()
		local startTime = tick()
		while tick() - startTime < duration and orePart.Parent do
			wait(0.3)

			-- Create mining particles
			local particle = Instance.new("Part")
			particle.Size = Vector3.new(0.2, 0.2, 0.2)
			particle.Material = Enum.Material.Neon
			particle.Color = orePart.Color
			particle.Anchored = true
			particle.CanCollide = false
			particle.Position = orePart.Position + Vector3.new(
				(math.random() - 0.5) * 4,
				(math.random() - 0.5) * 4,
				(math.random() - 0.5) * 4
			)
			particle.Parent = workspace

			-- Animate particle
			local particleTween = TweenService:Create(particle,
				TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = particle.Position + Vector3.new(
						(math.random() - 0.5) * 8,
						math.random() * 6 + 2,
						(math.random() - 0.5) * 8
					),
					Transparency = 1,
					Size = Vector3.new(0.05, 0.05, 0.05)
				}
			)
			particleTween:Play()
			particleTween.Completed:Connect(function()
				particle:Destroy()
			end)
		end
	end)

	-- Cleanup progress GUI after completion
	tween.Completed:Connect(function()
		progressGui:Destroy()
	end)
end

-- Complete mining and give rewards
function MiningSystem:CompleteMining(player, oreNode, oreType)
	local userId = player.UserId
	local oreData = ItemConfig.MiningSystem.ores[oreType]

	if not oreData then
		warn("MiningSystem: Invalid ore type: " .. tostring(oreType))
		return
	end

	-- Get player mining data
	local playerMiningData = self.PlayerData[userId]
	if not playerMiningData then
		warn("MiningSystem: No mining data for player " .. player.Name)
		return
	end

	-- Calculate rewards
	local currentTool = playerMiningData.currentTool
	local toolData = ItemConfig.MiningSystem.tools[currentTool]
	local toolPower = toolData and toolData.power or 1

	local xpGained = self:CalculateMiningXP(oreType, playerMiningData.level, toolPower)
	local oreAmount = math.random(1, 2 + toolPower) -- Better tools give more ore

	-- Add ore to inventory
	if not playerMiningData.inventory[oreType] then
		playerMiningData.inventory[oreType] = 0
	end
	playerMiningData.inventory[oreType] = playerMiningData.inventory[oreType] + oreAmount

	-- Add XP and check for level up
	local oldLevel = playerMiningData.level
	playerMiningData.xp = playerMiningData.xp + xpGained
	playerMiningData.level = self:CalculateMiningLevel(playerMiningData.xp)
	local leveledUp = playerMiningData.level > oldLevel

	-- Reduce tool durability
	if currentTool and playerMiningData.toolDurability[currentTool] then
		playerMiningData.toolDurability[currentTool] = playerMiningData.toolDurability[currentTool] - 1

		if playerMiningData.toolDurability[currentTool] <= 0 then
			-- Tool broke
			local toolName = toolData and toolData.name or currentTool
			playerMiningData.currentTool = nil
			playerMiningData.toolDurability[currentTool] = nil

			self:SendNotification(player, "⛏️ Tool Broken!", 
				"Your " .. toolName .. " has broken! Buy a new one from the shop.", "warning")
		elseif playerMiningData.toolDurability[currentTool] <= 10 then
			-- Tool almost broken warning
			self:SendNotification(player, "⚠️ Tool Wearing Out", 
				"Your tool has " .. playerMiningData.toolDurability[currentTool] .. " uses left!", "warning")
		end
	end

	-- Deplete ore node temporarily
	oreNode:SetAttribute("IsMineable", false)
	oreNode:SetAttribute("LastMined", os.time())

	-- Visual feedback for depleted node
	local orePart = oreNode:FindFirstChild("OreCore")
	if orePart then
		orePart.Transparency = 0.8
		orePart.Color = Color3.fromRGB(80, 80, 80) -- Gray out

		-- Dim indicator
		local indicator = oreNode:FindFirstChild("OreIndicator")
		if indicator then
			indicator.Transparency = 0.8
		end
	end

	-- Schedule ore respawn
	spawn(function()
		wait(oreData.respawnTime)
		if oreNode and oreNode.Parent then
			oreNode:SetAttribute("IsMineable", true)
			if orePart then
				orePart.Transparency = 0
				orePart.Color = oreData.color

				local indicator = oreNode:FindFirstChild("OreIndicator")
				if indicator then
					indicator.Transparency = 0
				end
			end
		end
	end)

	-- Update player data in GameCore
	self:SyncWithGameCore(player)

	-- Send success notification
	local message = "⛏️ Mined " .. oreAmount .. "x " .. oreData.name .. "! (+" .. xpGained .. " XP)"
	if leveledUp then
		message = message .. "\n🎉 Mining Level Up! Now level " .. playerMiningData.level .. "!"

		-- Level up bonus
		self:HandleLevelUpRewards(player, playerMiningData.level)
	end

	self:SendNotification(player, "Mining Success!", message, "success")

	-- Update client mining data
	if UpdateMiningDataEvent then
		UpdateMiningDataEvent:FireClient(player, playerMiningData)
	end

	print("MiningSystem: " .. player.Name .. " mined " .. oreAmount .. "x " .. oreType .. " (Level " .. playerMiningData.level .. ")")
end

-- ========== UTILITY FUNCTIONS ==========

-- Calculate mining XP reward
function MiningSystem:CalculateMiningXP(oreType, playerLevel, toolPower)
	local oreData = ItemConfig.MiningSystem.ores[oreType]
	if not oreData then return 0 end

	local baseXP = oreData.xpReward
	local levelPenalty = math.max(0.5, 1 - (playerLevel - oreData.requiredLevel) * 0.1) -- Diminishing returns
	local toolBonus = 1 + (toolPower - 1) * 0.1 -- 10% bonus per tool power level

	return math.floor(baseXP * levelPenalty * toolBonus)
end

-- Calculate mining level from total XP
function MiningSystem:CalculateMiningLevel(totalXP)
	for i = #ItemConfig.MiningSystem.skillLevels, 1, -1 do
		local levelData = ItemConfig.MiningSystem.skillLevels[i]
		if totalXP >= levelData.xpRequired then
			return levelData.level
		end
	end
	return 1
end

-- Handle level up rewards
function MiningSystem:HandleLevelUpRewards(player, newLevel)
	local rewards = {
		[2] = {coins = 100, message = "Unlocked Iron Ore mining!"},
		[3] = {coins = 200, message = "Unlocked Silver Ore mining!"},
		[4] = {coins = 500, message = "Unlocked Gold Ore mining!"},
		[5] = {coins = 1000, message = "Unlocked Diamond Ore mining!"},
		[6] = {coins = 2500, message = "Unlocked Obsidian Ore mining! Master Miner achieved!"}
	}

	local reward = rewards[newLevel]
	if reward then
		-- Give coin reward through GameCore
		if GameCore and GameCore.GetPlayerData then
			local playerData = GameCore:GetPlayerData(player)
			if playerData then
				playerData.coins = (playerData.coins or 0) + reward.coins
				GameCore:SavePlayerData(player)
				GameCore:UpdatePlayerLeaderstats(player)
			end
		end

		self:SendNotification(player, "🎉 Level " .. newLevel .. " Reward!", 
			reward.message .. "\nReceived " .. reward.coins .. " coins!", "success")
	end
end

-- Sync mining data with GameCore
function MiningSystem:SyncWithGameCore(player)
	if not GameCore then return end

	local userId = player.UserId
	local miningData = self.PlayerData[userId]
	local playerData = GameCore:GetPlayerData(player)

	if playerData and miningData then
		playerData.mining = {
			level = miningData.level,
			xp = miningData.xp,
			inventory = miningData.inventory,
			currentTool = miningData.currentTool,
			toolDurability = miningData.toolDurability,
			caveAccess = miningData.caveAccess
		}

		GameCore:SavePlayerData(player)
	end
end

-- ========== TELEPORTATION SYSTEM ==========

-- Teleport player to their cave
function MiningSystem:TeleportPlayerToCave(player)
	local userId = player.UserId
	local playerData = self.PlayerData[userId]

	if not playerData or not playerData.caveAccess then
		self:SendNotification(player, "🔒 Access Denied", "Purchase Cave Access Pass from the shop first!", "error")
		return
	end

	-- Create cave if it doesn't exist
	if not self.CaveInstances[userId] then
		self:CreateCave(player)
	end

	local caveInstance = self.CaveInstances[userId]
	if not caveInstance then
		self:SendNotification(player, "Cave Error", "Could not access your mining cave!", "error")
		return
	end

	-- Teleport player
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local teleportPosition = caveInstance.position + Vector3.new(0, 8, 0)
		player.Character.HumanoidRootPart.CFrame = CFrame.new(teleportPosition)

		-- Update last visit time
		caveInstance.lastVisit = os.time()

		self:SendNotification(player, "🕳️ Welcome to Your Cave!", 
			"Start mining ores! Use the portal to return to surface.", "success")

		print("MiningSystem: Teleported " .. player.Name .. " to their cave")
	end
end

-- Teleport player back to surface
function MiningSystem:TeleportPlayerToSurface(player)
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		-- Teleport to spawn or farm area
		local spawnPosition = Vector3.new(0, 10, 0) -- Default spawn

		-- Try to teleport to their farm if available
		if GameCore and GameCore.GetFarmPlotPosition then
			local success, farmPosition = pcall(function()
				return GameCore:GetFarmPlotPosition(player, 1)
			end)

			if success and farmPosition then
				spawnPosition = farmPosition.Position + Vector3.new(10, 5, 10)
			end
		end

		player.Character.HumanoidRootPart.CFrame = CFrame.new(spawnPosition)

		self:SendNotification(player, "🌞 Back to Surface!", 
			"Returned from the mining caves. Check your ore inventory!", "success")

		print("MiningSystem: Teleported " .. player.Name .. " back to surface")
	end
end

-- ========== ORE SELLING SYSTEM ==========

-- Sell ore for coins
function MiningSystem:SellOre(player, oreType, amount)
	local userId = player.UserId
	local playerMiningData = self.PlayerData[userId]

	if not playerMiningData or not playerMiningData.inventory[oreType] then
		self:SendNotification(player, "No Ore", "You don't have any " .. oreType:gsub("_", " ") .. "!", "error")
		return
	end

	local oreCount = playerMiningData.inventory[oreType]
	if oreCount < amount then
		self:SendNotification(player, "Insufficient Ore", 
			"You only have " .. oreCount .. " " .. oreType:gsub("_", " ") .. "!", "error")
		return
	end

	local oreData = ItemConfig.MiningSystem.ores[oreType]
	if not oreData then
		self:SendNotification(player, "Invalid Ore", "Cannot sell this ore type!", "error")
		return
	end

	-- Calculate total value
	local totalValue = oreData.sellValue * amount

	-- Remove ore from inventory
	playerMiningData.inventory[oreType] = playerMiningData.inventory[oreType] - amount

	-- Give coins through GameCore
	if GameCore then
		local playerData = GameCore:GetPlayerData(player)
		if playerData then
			playerData.coins = (playerData.coins or 0) + totalValue
			GameCore:SavePlayerData(player)
			GameCore:UpdatePlayerLeaderstats(player)
		end
	end

	-- Sync data
	self:SyncWithGameCore(player)

	-- Update client
	if UpdateMiningDataEvent then
		UpdateMiningDataEvent:FireClient(player, playerMiningData)
	end

	self:SendNotification(player, "💰 Ore Sold!", 
		"Sold " .. amount .. "x " .. oreData.name .. " for " .. totalValue .. " coins!", "success")

	print("MiningSystem: " .. player.Name .. " sold " .. amount .. "x " .. oreType .. " for " .. totalValue .. " coins")
end

-- ========== SYSTEM LOOPS ==========

-- Start system update loops
function MiningSystem:StartSystemLoops()
	-- Cave maintenance loop
	spawn(function()
		while true do
			wait(300) -- Check every 5 minutes
			self:MaintainCaves()
		end
	end)

	-- Data sync loop
	spawn(function()
		while true do
			wait(60) -- Sync every minute
			self:SyncAllPlayerData()
		end
	end)

	print("MiningSystem: System loops started")
end

-- Maintain caves (cleanup, regeneration, etc.)
function MiningSystem:MaintainCaves()
	local currentTime = os.time()

	for userId, caveInstance in pairs(self.CaveInstances) do
		-- Clean up caves that haven't been visited in a while
		if currentTime - caveInstance.lastVisit > 3600 then -- 1 hour
			local player = Players:GetPlayerByUserId(userId)
			if not player then
				-- Player left, clean up their cave
				self:DestroyCave(userId)
			end
		end
	end
end

-- Sync all player mining data with GameCore
function MiningSystem:SyncAllPlayerData()
	for _, player in pairs(Players:GetPlayers()) do
		if self.PlayerData[player.UserId] then
			self:SyncWithGameCore(player)
		end
	end
end

-- Destroy cave instance
function MiningSystem:DestroyCave(userId)
	local caveInstance = self.CaveInstances[userId]
	if caveInstance then
		if caveInstance.model and caveInstance.model.Parent then
			caveInstance.model:Destroy()
		end
		self.CaveInstances[userId] = nil
		self.OreNodes[userId] = nil
		print("MiningSystem: Destroyed cave for user " .. userId)
	end
end

-- Send notification to player
function MiningSystem:SendNotification(player, title, message, type)
	if GameCore and GameCore.SendNotification then
		GameCore:SendNotification(player, title, message, type)
	else
		print("MiningSystem Notification [" .. player.Name .. "]: " .. title .. " - " .. message)
	end
end

-- ========== INITIALIZE SYSTEM ==========

-- Global registration
_G.MiningSystem = MiningSystem

-- Auto-initialize when GameCore is available
spawn(function()
	-- Wait for GameCore to be available
	while not _G.GameCore do
		wait(1)
	end

	-- Initialize mining system
	MiningSystem:Initialize()
end)

print("MiningSystem: ✅ Complete mining system loaded and ready!")
print("Features included:")
print("  ⛏️ Procedural cave generation with atmospheric effects")
print("  💎 6 ore types with unique visual effects")
print("  🔧 Tool progression and durability system")
print("  📈 XP and skill level progression")
print("  🚀 Cave teleportation system")
print("  💰 Ore selling economics")
print("  🎮 Complete mining mechanics with animations")

return MiningSystem