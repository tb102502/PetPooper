--[[
    Enhanced MiningSystem.server.lua - TIERED CAVE SYSTEM
    Place in: ServerScriptService/Systems/MiningSystem.server.lua
    
    NEW FEATURES:
    ✅ Multiple tiered caves (Cave 1, 2, 3, etc.)
    ✅ Cave-specific ore types and quantities
    ✅ Ore quantity upgrades per cave
    ✅ Progressive cave unlocking system
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
MiningSystem.CaveInstances = {} -- Now stores multiple caves per player
MiningSystem.MiningCooldowns = {}

-- CAVE TIER CONFIGURATION
MiningSystem.CaveTiers = {
	[1] = {
		name = "Copper Mine",
		description = "Basic mining cave with copper deposits",
		oreTypes = {"copper_ore"},
		baseOreCount = 8, -- Base number of ore nodes
		unlockCost = 0, -- Free (cave access pass)
		unlockCurrency = "coins",
		requiredLevel = 1,
		icon = "🟤"
	},
	[2] = {
		name = "Bronze & Silver Mine", 
		description = "Deeper cave with bronze and silver veins",
		oreTypes = {"copper_ore", "bronze_ore", "silver_ore"},
		baseOreCount = 12,
		unlockCost = 1000,
		unlockCurrency = "coins", 
		requiredLevel = 3,
		icon = "⚪"
	},
	[3] = {
		name = "Gold Mine",
		description = "Precious gold deposits in ancient caverns",
		oreTypes = {"silver_ore", "gold_ore"},
		baseOreCount = 10,
		unlockCost = 5000,
		unlockCurrency = "coins",
		requiredLevel = 5,
		icon = "🟡"
	},
	[4] = {
		name = "Platinum Mine",
		description = "Rare platinum veins in deep chambers",
		oreTypes = {"gold_ore", "platinum_ore"},
		baseOreCount = 8,
		unlockCost = 15000,
		unlockCurrency = "coins",
		requiredLevel = 7,
		icon = "⚫"
	},
	[5] = {
		name = "Obsidian Depths",
		description = "Mystical obsidian in the deepest caves",
		oreTypes = {"platinum_ore", "obsidian_ore"},
		baseOreCount = 6,
		unlockCost = 100,
		unlockCurrency = "farmTokens",
		requiredLevel = 10,
		icon = "⬛"
	}
}

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
local UnlockCaveEvent = CreateRemoteEvent("UnlockCave")

-- ========== CORE MINING FUNCTIONS ==========

-- Initialize mining system
function MiningSystem:Initialize()
	print("MiningSystem: Initializing tiered cave system...")

	-- Setup remote event handlers
	self:SetupRemoteEvents()

	-- Setup player connection handlers
	self:SetupPlayerHandlers()

	-- Start system loops
	self:StartSystemLoops()

	print("MiningSystem: ✅ Tiered cave system initialized!")
end

-- Setup remote event handlers
function MiningSystem:SetupRemoteEvents()
	TeleportToCaveEvent.OnServerEvent:Connect(function(player, caveNumber)
		self:TeleportPlayerToCave(player, caveNumber or 1)
	end)

	TeleportToSurfaceEvent.OnServerEvent:Connect(function(player)
		self:TeleportPlayerToSurface(player)
	end)

	SellOreEvent.OnServerEvent:Connect(function(player, oreType, amount)
		self:SellOre(player, oreType, amount)
	end)

	UnlockCaveEvent.OnServerEvent:Connect(function(player, caveNumber)
		self:UnlockCave(player, caveNumber)
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
			unlockedCaves = {1}, -- Start with cave 1 unlocked
			caveUpgrades = {}, -- Ore quantity upgrades per cave
			lastMining = 0
		}
	end

	-- Initialize cave instances storage
	if not self.CaveInstances[userId] then
		self.CaveInstances[userId] = {}
	end

	self.MiningCooldowns[userId] = 0

	print("MiningSystem: Initialized mining data for " .. player.Name)
end

-- Cleanup player mining data
function MiningSystem:CleanupPlayerMining(player)
	local userId = player.UserId

	-- Clean up all cave instances
	if self.CaveInstances[userId] then
		for caveNumber, _ in pairs(self.CaveInstances[userId]) do
			self:DestroyCave(userId, caveNumber)
		end
	end

	-- Clean up mining data
	self.PlayerData[userId] = nil
	self.MiningCooldowns[userId] = nil

	print("MiningSystem: Cleaned up mining data for " .. player.Name)
end

-- ========== CAVE UNLOCK SYSTEM ==========

-- Unlock a new cave tier
function MiningSystem:UnlockCave(player, caveNumber)
	local userId = player.UserId
	local playerMiningData = self.PlayerData[userId]

	if not playerMiningData then
		self:SendNotification(player, "Error", "Mining data not found!", "error")
		return false
	end

	local caveTier = self.CaveTiers[caveNumber]
	if not caveTier then
		self:SendNotification(player, "Invalid Cave", "Cave " .. caveNumber .. " does not exist!", "error")
		return false
	end

	-- Check if already unlocked
	for _, unlockedCave in ipairs(playerMiningData.unlockedCaves) do
		if unlockedCave == caveNumber then
			self:SendNotification(player, "Already Unlocked", "You already have access to " .. caveTier.name .. "!", "warning")
			return false
		end
	end

	-- Check level requirement
	if playerMiningData.level < caveTier.requiredLevel then
		self:SendNotification(player, "Level Too Low", 
			"You need Mining Level " .. caveTier.requiredLevel .. " to unlock " .. caveTier.name .. "!", "error")
		return false
	end

	-- Check previous cave requirement (must unlock in order)
	if caveNumber > 1 then
		local hasPreviousCave = false
		for _, unlockedCave in ipairs(playerMiningData.unlockedCaves) do
			if unlockedCave == (caveNumber - 1) then
				hasPreviousCave = true
				break
			end
		end
		if not hasPreviousCave then
			self:SendNotification(player, "Prerequisites Missing", 
				"You must unlock Cave " .. (caveNumber - 1) .. " first!", "error")
			return false
		end
	end

	-- Check currency requirement
	if GameCore then
		local playerData = GameCore:GetPlayerData(player)
		if not playerData then
			self:SendNotification(player, "Error", "Player data not found!", "error")
			return false
		end

		local playerCurrency = playerData[caveTier.unlockCurrency] or 0
		if playerCurrency < caveTier.unlockCost then
			local currencyName = caveTier.unlockCurrency == "farmTokens" and "Farm Tokens" or "Coins"
			self:SendNotification(player, "Insufficient " .. currencyName, 
				"You need " .. caveTier.unlockCost .. " " .. currencyName .. " to unlock " .. caveTier.name .. "!", "error")
			return false
		end

		-- Deduct currency
		playerData[caveTier.unlockCurrency] = playerData[caveTier.unlockCurrency] - caveTier.unlockCost
		GameCore:SavePlayerData(player)
		GameCore:UpdatePlayerLeaderstats(player)
	end

	-- Unlock the cave
	table.insert(playerMiningData.unlockedCaves, caveNumber)

	-- Initialize cave upgrades
	if not playerMiningData.caveUpgrades[caveNumber] then
		playerMiningData.caveUpgrades[caveNumber] = 0 -- No upgrades initially
	end

	-- Sync with GameCore
	self:SyncWithGameCore(player)

	-- Send success notification
	local currencyName = caveTier.unlockCurrency == "farmTokens" and "Farm Tokens" or "Coins"
	self:SendNotification(player, "🗻 Cave Unlocked!", 
		caveTier.name .. " unlocked for " .. caveTier.unlockCost .. " " .. currencyName .. "!\nAccess it from the Mining menu!", "success")

	print("MiningSystem: " .. player.Name .. " unlocked Cave " .. caveNumber .. " (" .. caveTier.name .. ")")
	return true
end

-- ========== ENHANCED CAVE SYSTEM ==========

-- Create specific cave tier for player
function MiningSystem:CreateCave(player, caveNumber)
	local userId = player.UserId
	caveNumber = caveNumber or 1

	-- Check if cave already exists
	if self.CaveInstances[userId] and self.CaveInstances[userId][caveNumber] then
		return self.CaveInstances[userId][caveNumber]
	end

	local caveTier = self.CaveTiers[caveNumber]
	if not caveTier then
		warn("MiningSystem: Invalid cave number: " .. caveNumber)
		return nil
	end

	print("MiningSystem: Creating " .. caveTier.name .. " for " .. player.Name)

	-- Find or create cave area
	local caveArea = workspace:FindFirstChild("MiningCaves")
	if not caveArea then
		caveArea = Instance.new("Folder")
		caveArea.Name = "MiningCaves"
		caveArea.Parent = workspace
	end

	-- Create cave instance
	local cave = Instance.new("Model")
	cave.Name = player.Name .. "_Cave_" .. caveNumber
	cave.Parent = caveArea

	-- Calculate unique position for this cave
	local basePosition = Vector3.new(
		1000 + userId % 100 * 300, -- X spread based on user ID
		-100 - (caveNumber - 1) * 50, -- Y depth increases per cave tier
		1000 + caveNumber * 200 -- Z offset per cave tier
	)

	-- Generate cave structure
	self:GenerateCaveStructure(cave, basePosition, caveTier, caveNumber)

	-- Generate ore nodes specific to this cave tier
	self:GenerateOreCaveTypeSpecific(cave, basePosition, caveTier, userId, caveNumber)

	-- Initialize cave instance storage
	if not self.CaveInstances[userId] then
		self.CaveInstances[userId] = {}
	end

	-- Store cave instance
	self.CaveInstances[userId][caveNumber] = {
		model = cave,
		position = basePosition,
		tier = caveTier,
		oreNodes = {},
		lastVisit = os.time()
	}

	print("MiningSystem: " .. caveTier.name .. " created for " .. player.Name .. " at " .. tostring(basePosition))
	return cave
end

-- Generate ore nodes specific to cave tier
function MiningSystem:GenerateOreCaveTypeSpecific(cave, basePosition, caveTier, ownerId, caveNumber)
	local playerMiningData = self.PlayerData[ownerId]
	if not playerMiningData then return end

	-- Calculate total ore count (base + upgrades)
	local upgradeLevel = playerMiningData.caveUpgrades[caveNumber] or 0
	local totalOreCount = caveTier.baseOreCount + (upgradeLevel * 4) -- Each upgrade adds 4 more nodes

	local nodesPerOreType = math.ceil(totalOreCount / #caveTier.oreTypes)
	local nodeCount = 0

	-- Initialize ore nodes storage
	if not self.OreNodes then
		self.OreNodes = {}
	end
	if not self.OreNodes[ownerId] then
		self.OreNodes[ownerId] = {}
	end
	if not self.OreNodes[ownerId][caveNumber] then
		self.OreNodes[ownerId][caveNumber] = {}
	end

	-- Generate nodes for each ore type in this cave tier
	for _, oreType in ipairs(caveTier.oreTypes) do
		local oreData = ItemConfig.MiningSystem.ores[oreType]
		if oreData then
			for i = 1, nodesPerOreType do
				if nodeCount < totalOreCount then
					local nodePosition = self:FindValidOrePosition(basePosition, caveNumber)
					if nodePosition then
						local oreNode = self:CreateOreNode(oreType, oreData, nodePosition, ownerId, caveNumber)
						oreNode.Parent = cave
						nodeCount = nodeCount + 1

						-- Store node reference
						table.insert(self.OreNodes[ownerId][caveNumber], oreNode)
					end
				end
			end
		end
	end

	print("MiningSystem: Generated " .. nodeCount .. " ore nodes for " .. caveTier.name .. " (Level " .. upgradeLevel .. " upgrade)")
end

-- Enhanced cave structure generation with tier-specific theming
function MiningSystem:GenerateCaveStructure(cave, basePosition, caveTier, caveNumber)
	local caveSize = 120 + (caveNumber - 1) * 20 -- Caves get bigger as tiers increase
	local caveHeight = 25 + (caveNumber - 1) * 5

	-- Cave floor with tier-specific materials
	local floor = Instance.new("Part")
	floor.Name = "CaveFloor"
	floor.Size = Vector3.new(caveSize, 6, caveSize)
	floor.Position = basePosition
	floor.Anchored = true
	floor.Parent = cave

	-- Set cave appearance based on tier
	if caveNumber == 1 then
		-- Copper cave - earthy browns
		floor.Material = Enum.Material.Ground
		floor.Color = Color3.fromRGB(101, 67, 33)
	elseif caveNumber == 2 then
		-- Bronze/Silver cave - darker with metallic hints
		floor.Material = Enum.Material.Rock
		floor.Color = Color3.fromRGB(60, 55, 50)
	elseif caveNumber == 3 then
		-- Gold cave - warm golden tones
		floor.Material = Enum.Material.Cobblestone
		floor.Color = Color3.fromRGB(80, 70, 40)
	elseif caveNumber == 4 then
		-- Platinum cave - cool metallic grays
		floor.Material = Enum.Material.Concrete
		floor.Color = Color3.fromRGB(50, 50, 60)
	elseif caveNumber >= 5 then
		-- Obsidian cave - dark mystical
		floor.Material = Enum.Material.Obsidian
		floor.Color = Color3.fromRGB(20, 15, 25)
	end

	-- Create walls with matching theme
	local wallConfigs = {
		{name = "WallNorth", size = Vector3.new(caveSize, caveHeight, 6), offset = Vector3.new(0, caveHeight/2, -(caveSize/2 + 3))},
		{name = "WallSouth", size = Vector3.new(caveSize, caveHeight, 6), offset = Vector3.new(0, caveHeight/2, (caveSize/2 + 3))},
		{name = "WallEast", size = Vector3.new(6, caveHeight, caveSize), offset = Vector3.new((caveSize/2 + 3), caveHeight/2, 0)},
		{name = "WallWest", size = Vector3.new(6, caveHeight, caveSize), offset = Vector3.new(-(caveSize/2 + 3), caveHeight/2, 0)}
	}

	for _, config in ipairs(wallConfigs) do
		local wall = Instance.new("Part")
		wall.Name = config.name
		wall.Size = config.size
		wall.Position = basePosition + config.offset
		wall.Material = floor.Material
		wall.Color = Color3.new(floor.Color.R * 0.7, floor.Color.G * 0.7, floor.Color.B * 0.7) -- Darker walls
		wall.Anchored = true
		wall.Parent = cave
	end

	-- Cave ceiling
	local ceiling = Instance.new("Part")
	ceiling.Name = "CaveCeiling"
	ceiling.Size = Vector3.new(caveSize, 6, caveSize)
	ceiling.Position = basePosition + Vector3.new(0, caveHeight, 0)
	ceiling.Material = floor.Material
	ceiling.Color = Color3.new(floor.Color.R * 0.5, floor.Color.G * 0.5, floor.Color.B * 0.5) -- Darkest ceiling
	ceiling.Anchored = true
	ceiling.Parent = cave

	-- Create tier-specific lighting and atmosphere
	self:CreateTierSpecificAtmosphere(cave, basePosition, caveTier, caveNumber)

	-- Create cave portal
	self:CreateCavePortal(cave, basePosition, caveTier, caveNumber)

	-- Create cave information sign
	self:CreateCaveInfoSign(cave, basePosition, caveTier, caveNumber)
end
function MiningSystem:CreateCavePortal(cave, basePosition, caveTier, caveNumber)
	-- Create portal platform
	local portal = Instance.new("Part")
	portal.Name = "CavePortal"
	portal.Size = Vector3.new(8, 2, 8)
	portal.Position = basePosition + Vector3.new(35, 3, 35) -- Corner position
	portal.Material = Enum.Material.Neon
	portal.Color = Color3.fromRGB(100, 200, 255) -- Light blue
	portal.Anchored = true
	portal.Parent = cave

	-- Create portal glow effect
	local portalLight = Instance.new("PointLight")
	portalLight.Color = Color3.fromRGB(100, 200, 255)
	portalLight.Brightness = 2
	portalLight.Range = 15
	portalLight.Parent = portal

	-- Create portal ring
	local ring = Instance.new("Part")
	ring.Name = "PortalRing"
	ring.Size = Vector3.new(10, 0.5, 10)
	ring.Shape = Enum.PartType.Cylinder
	ring.Position = basePosition + Vector3.new(35, 5, 35)
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(150, 220, 255)
	ring.Transparency = 0.3
	ring.Anchored = true
	ring.Orientation = Vector3.new(0, 0, 90) -- Rotate to be horizontal
	ring.Parent = cave

	-- Portal sign
	local sign = Instance.new("Part")
	sign.Name = "PortalSign"
	sign.Size = Vector3.new(4, 3, 0.5)
	sign.Position = basePosition + Vector3.new(35, 6, 40)
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
	signText.Text = "🌞 RETURN TO SURFACE\nClick portal to exit " .. caveTier.name
	signText.TextColor3 = Color3.new(1, 1, 1)
	signText.TextScaled = true
	signText.Font = Enum.Font.GothamBold
	signText.TextStrokeTransparency = 0
	signText.TextStrokeColor3 = Color3.new(0, 0, 0)
	signText.Parent = signGui

	-- Portal click detector
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 12
	clickDetector.Parent = portal

	clickDetector.MouseClick:Connect(function(player)
		-- Teleport player back to surface
		self:TeleportPlayerToSurface(player)
	end)

	-- Portal animation
	spawn(function()
		while portal and portal.Parent do
			local tween = TweenService:Create(ring,
				TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{
					Transparency = 0.7,
					Size = Vector3.new(12, 0.5, 12)
				}
			)
			tween:Play()
			wait(0.1)
		end
	end)

	print("MiningSystem: Created portal for " .. caveTier.name)
end

-- ========== ALTERNATIVE SIMPLER PORTAL (If the above causes issues) ==========

function MiningSystem:CreateSimpleCavePortal(cave, basePosition, caveTier, caveNumber)
	-- Simple portal - just a glowing platform
	local portal = Instance.new("Part")
	portal.Name = "CavePortal"
	portal.Size = Vector3.new(6, 1, 6)
	portal.Position = basePosition + Vector3.new(30, 2, 30)
	portal.Material = Enum.Material.Neon
	portal.Color = Color3.fromRGB(100, 255, 100) -- Green for exit
	portal.Anchored = true
	portal.Parent = cave

	-- Simple click detection
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 10
	clickDetector.Parent = portal

	clickDetector.MouseClick:Connect(function(player)
		self:TeleportPlayerToSurface(player)
	end)

	print("MiningSystem: Created simple portal for " .. caveTier.name)
end

-- ========== MINING SYSTEM HOTFIX ==========

-- Add this to fix the immediate error - place this near the top of your MiningSystem file
if _G.MiningSystem and not _G.MiningSystem.CreateCavePortal then
	_G.MiningSystem.CreateCavePortal = function(self, cave, basePosition, caveTier, caveNumber)
		-- Quick hotfix portal
		local portal = Instance.new("Part")
		portal.Name = "CavePortal"
		portal.Size = Vector3.new(6, 1, 6)
		portal.Position = basePosition + Vector3.new(30, 2, 30)
		portal.Material = Enum.Material.Neon
		portal.Color = Color3.fromRGB(100, 255, 100)
		portal.Anchored = true
		portal.Parent = cave

		local clickDetector = Instance.new("ClickDetector")
		clickDetector.MaxActivationDistance = 10
		clickDetector.Parent = portal

		clickDetector.MouseClick:Connect(function(player)
			self:TeleportPlayerToSurface(player)
		end)
	end

	print("✅ HOTFIX: Added missing CreateCavePortal method")
end

-- ========== EMERGENCY MINING SYSTEM FIX ==========

-- If MiningSystem doesn't exist yet, create basic structure
if not _G.MiningSystem then
	_G.MiningSystem = {
		PlayerData = {},
		CaveInstances = {},
		MiningCooldowns = {}
	}

	-- Add missing methods
	_G.MiningSystem.CreateCavePortal = function(self, cave, basePosition, caveTier, caveNumber)
		local portal = Instance.new("Part")
		portal.Name = "CavePortal"
		portal.Size = Vector3.new(6, 1, 6)
		portal.Position = basePosition + Vector3.new(30, 2, 30)
		portal.Material = Enum.Material.Neon
		portal.Color = Color3.fromRGB(100, 255, 100)
		portal.Anchored = true
		portal.Parent = cave

		local clickDetector = Instance.new("ClickDetector")
		clickDetector.MaxActivationDistance = 10
		clickDetector.Parent = portal

		clickDetector.MouseClick:Connect(function(player)
			if self.TeleportPlayerToSurface then
				self:TeleportPlayerToSurface(player)
			else
				-- Basic teleport fallback
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					player.Character.HumanoidRootPart.CFrame = CFrame.new(0, 10, 0)
				end
			end
		end)
	end

	print("✅ EMERGENCY: Created basic MiningSystem structure")
end

-- ========== DEBUGGING MININGSYSTEM ==========

local function DebugMiningSystem()
	print("=== MININGSYSTEM DEBUG ===")

	if _G.MiningSystem then
		print("✅ MiningSystem exists")

		local requiredMethods = {
			"CreateCavePortal",
			"CreateCave", 
			"GenerateCaveStructure",
			"TeleportPlayerToCave",
			"TeleportPlayerToSurface",
			"Initialize"
		}

		for _, methodName in ipairs(requiredMethods) do
			local exists = type(_G.MiningSystem[methodName]) == "function"
			print((exists and "✅" or "❌") .. " " .. methodName .. ": " .. type(_G.MiningSystem[methodName]))
		end

		-- Check data structures
		print("PlayerData exists:", _G.MiningSystem.PlayerData ~= nil)
		print("CaveInstances exists:", _G.MiningSystem.CaveInstances ~= nil)
		print("CaveTiers exists:", _G.MiningSystem.CaveTiers ~= nil)

	else
		print("❌ MiningSystem not found")
	end

	print("=========================")
end

-- ========== CHECK FOR OTHER MISSING METHODS ==========

local function ValidateMiningSystemMethods()
	if not _G.MiningSystem then
		warn("❌ MiningSystem not found!")
		return false
	end

	local requiredMethods = {
		"CreateCavePortal",
		"CreateTierSpecificAtmosphere", 
		"CreateCaveInfoSign",
		"GenerateCaveStructure",
		"CreateCave",
		"TeleportPlayerToCave",
		"TeleportPlayerToSurface"
	}

	local missingMethods = {}

	for _, methodName in ipairs(requiredMethods) do
		if type(_G.MiningSystem[methodName]) ~= "function" then
			table.insert(missingMethods, methodName)
		end
	end

	if #missingMethods > 0 then
		warn("❌ Missing MiningSystem methods:")
		for _, method in ipairs(missingMethods) do
			warn("  " .. method)
		end
		return false
	else
		print("✅ All MiningSystem methods validated!")
		return true
	end
end

-- Make debug functions available
_G.DebugMiningSystem = DebugMiningSystem
_G.ValidateMiningSystemMethods = ValidateMiningSystemMethods

print("🔧 MiningSystem fixes loaded!")
print("Use _G.DebugMiningSystem() to check method availability")
-- Create tier-specific atmosphere and lighting
function MiningSystem:CreateTierSpecificAtmosphere(cave, basePosition, caveTier, caveNumber)
	-- Central lighting with tier-specific colors
	local lightColors = {
		[1] = Color3.fromRGB(255, 180, 120), -- Warm copper light
		[2] = Color3.fromRGB(200, 200, 220), -- Cool silver light  
		[3] = Color3.fromRGB(255, 215, 100), -- Golden light
		[4] = Color3.fromRGB(180, 180, 200), -- Platinum white
		[5] = Color3.fromRGB(150, 100, 200)  -- Mystical purple
	}

	local lightColor = lightColors[caveNumber] or lightColors[1]

	-- Main light source
	local centralLight = Instance.new("Part")
	centralLight.Name = "CentralLight"
	centralLight.Size = Vector3.new(4, 2, 4)
	centralLight.Position = basePosition + Vector3.new(0, 15, 0)
	centralLight.Material = Enum.Material.Neon
	centralLight.Color = lightColor
	centralLight.Anchored = true
	centralLight.CanCollide = false
	centralLight.Parent = cave

	local mainLight = Instance.new("PointLight")
	mainLight.Brightness = 2 + (caveNumber * 0.3) -- Brighter for deeper caves
	mainLight.Range = 35 + (caveNumber * 5)
	mainLight.Color = lightColor
	mainLight.Parent = centralLight

	-- Tier-specific decorative elements
	if caveNumber >= 3 then
		-- Add crystals for gold+ caves
		for i = 1, 4 + caveNumber do
			local crystal = Instance.new("Part")
			crystal.Name = "Crystal" .. i
			crystal.Size = Vector3.new(
				1 + math.random() * 2,
				3 + math.random() * 4,
				1 + math.random() * 2
			)
			crystal.Position = basePosition + Vector3.new(
				(math.random() - 0.5) * 80,
				4 + math.random() * 6,
				(math.random() - 0.5) * 80
			)
			crystal.Material = Enum.Material.Neon
			crystal.Color = lightColor
			crystal.Transparency = 0.3
			crystal.Anchored = true
			crystal.Parent = cave

			-- Crystal glow
			local crystalLight = Instance.new("PointLight")
			crystalLight.Color = lightColor
			crystalLight.Brightness = 0.5
			crystalLight.Range = 8
			crystalLight.Parent = crystal
		end
	end

	if caveNumber >= 5 then
		-- Add mystical effects for obsidian caves
		local mysticalOrb = Instance.new("Part")
		mysticalOrb.Name = "MysticalOrb"
		mysticalOrb.Size = Vector3.new(6, 6, 6)
		mysticalOrb.Shape = Enum.PartType.Ball
		mysticalOrb.Position = basePosition + Vector3.new(0, 20, 0)
		mysticalOrb.Material = Enum.Material.ForceField
		mysticalOrb.Color = Color3.fromRGB(100, 50, 150)
		mysticalOrb.Anchored = true
		mysticalOrb.CanCollide = false
		mysticalOrb.Parent = cave

		-- Animate mystical orb
		spawn(function()
			while mysticalOrb and mysticalOrb.Parent do
				local tween = TweenService:Create(mysticalOrb,
					TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
					{
						Size = Vector3.new(8, 8, 8),
						Transparency = 0.7
					}
				)
				tween:Play()
				wait(0.1)
			end
		end)
	end
end

-- Create cave information sign
function MiningSystem:CreateCaveInfoSign(cave, basePosition, caveTier, caveNumber)
	local sign = Instance.new("Part")
	sign.Name = "CaveInfoSign"
	sign.Size = Vector3.new(8, 4, 0.5)
	sign.Position = basePosition + Vector3.new(-40, 8, 40)
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
	signText.Text = caveTier.icon .. " " .. caveTier.name .. "\n" .. caveTier.description .. "\n\nOre Types: " .. table.concat(caveTier.oreTypes, ", "):gsub("_ore", ""):gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
	signText.TextColor3 = Color3.new(1, 1, 1)
	signText.TextScaled = true
	signText.Font = Enum.Font.GothamBold
	signText.TextStrokeTransparency = 0
	signText.TextStrokeColor3 = Color3.new(0, 0, 0)
	signText.Parent = signGui
end

-- Enhanced teleportation with cave selection
function MiningSystem:TeleportPlayerToCave(player, caveNumber)
	local userId = player.UserId
	local playerMiningData = self.PlayerData[userId]

	if not playerMiningData then
		self:SendNotification(player, "Error", "Mining data not found!", "error")
		return
	end

	-- Check if player has cave access (any cave)
	if not playerMiningData.unlockedCaves or #playerMiningData.unlockedCaves == 0 then
		self:SendNotification(player, "🔒 No Cave Access", "Purchase Cave Access from the shop first!", "error")
		return
	end

	-- Check if player has access to this specific cave
	local hasAccess = false
	for _, unlockedCave in ipairs(playerMiningData.unlockedCaves) do
		if unlockedCave == caveNumber then
			hasAccess = true
			break
		end
	end

	if not hasAccess then
		local caveTier = self.CaveTiers[caveNumber]
		local caveName = caveTier and caveTier.name or "Cave " .. caveNumber
		self:SendNotification(player, "🔒 Cave Locked", "You don't have access to " .. caveName .. "! Unlock it first.", "error")
		return
	end

	-- Create cave if it doesn't exist
	if not self.CaveInstances[userId] or not self.CaveInstances[userId][caveNumber] then
		self:CreateCave(player, caveNumber)
	end

	local caveInstance = self.CaveInstances[userId][caveNumber]
	if not caveInstance then
		self:SendNotification(player, "Cave Error", "Could not access cave!", "error")
		return
	end

	-- Teleport player
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local teleportPosition = caveInstance.position + Vector3.new(0, 8, 0)
		player.Character.HumanoidRootPart.CFrame = CFrame.new(teleportPosition)

		-- Update last visit time
		caveInstance.lastVisit = os.time()

		local caveName = caveInstance.tier.name
		self:SendNotification(player, "🗻 Entered " .. caveName .. "!", 
			"Start mining " .. table.concat(caveInstance.tier.oreTypes, ", "):gsub("_ore", ""):gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end) .. "!", "success")

		print("MiningSystem: Teleported " .. player.Name .. " to " .. caveName)
	end
end

-- Enhanced ore node creation with cave-specific attributes
function MiningSystem:CreateOreNode(oreType, oreData, position, ownerId, caveNumber)
	-- Validate inputs
	if not oreType or not oreData or not position then
		warn("MiningSystem: Invalid parameters for CreateOreNode")
		return nil
	end

	local oreNode = Instance.new("Model")
	oreNode.Name = oreType .. "_Node_" .. math.random(1000, 9999)

	-- Main ore part
	local orePart = Instance.new("Part")
	orePart.Name = "OreCore"
	orePart.Size = Vector3.new(3 + math.random(), 3 + math.random(), 3 + math.random()) -- Slight size variation
	orePart.Position = position
	orePart.Material = Enum.Material.Rock
	orePart.Color = oreData.color or Color3.fromRGB(100, 100, 100) -- Default gray if no color
	orePart.Anchored = true
	orePart.Parent = oreNode

	-- Apply ore-specific visual effects
	self:ApplyOreEffects(orePart, oreType, oreData)

	-- Set ore attributes
	oreNode:SetAttribute("OreType", oreType)
	oreNode:SetAttribute("Hardness", oreData.hardness or 5)
	oreNode:SetAttribute("IsMineable", true)
	oreNode:SetAttribute("OwnerId", ownerId)
	oreNode:SetAttribute("CaveNumber", caveNumber)
	oreNode:SetAttribute("RespawnTime", oreData.respawnTime or 300)
	oreNode:SetAttribute("LastMined", 0)

	-- Mining click detector
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 10
	clickDetector.Parent = orePart

	clickDetector.MouseClick:Connect(function(player)
		if player.UserId == ownerId then
			self:HandleMining(player, oreNode)
		else
			self:SendNotification(player, "Not Your Cave", "You can only mine in your own caves!", "error")
		end
	end)

	oreNode.PrimaryPart = orePart
	return oreNode
end
-- ========== MINING MECHANICS ==========

-- Enhanced mining with cave-specific logic
function MiningSystem:HandleMining(player, oreNode)
	local userId = player.UserId
	local currentTime = os.time()

	-- Check mining cooldown
	local lastMining = self.MiningCooldowns[userId] or 0
	if currentTime - lastMining < 2 then
		return -- Silent cooldown for spam prevention
	end

	-- Check if ore is available
	local isMineable = oreNode:GetAttribute("IsMineable")
	if not isMineable then
		local lastMined = oreNode:GetAttribute("LastMined")
		local respawnTime = oreNode:GetAttribute("RespawnTime")
		local timeLeft = respawnTime - (currentTime - lastMined)

		self:SendNotification(player, "Ore Depleted", 
			"This ore will respawn in " .. math.ceil(timeLeft) .. " seconds!", "info")
		return
	end

	-- Get mining data
	local playerMiningData = self.PlayerData[userId]
	if not playerMiningData then
		self:InitializePlayerMining(player)
		playerMiningData = self.PlayerData[userId]
	end

	local oreType = oreNode:GetAttribute("OreType")
	local caveNumber = oreNode:GetAttribute("CaveNumber")

	-- Validate tool and requirements (existing logic)
	if not self:ValidateMiningRequirements(player, oreType, playerMiningData) then
		return
	end

	-- Set cooldown
	self.MiningCooldowns[userId] = currentTime

	-- Calculate mining time
	local miningTime = self:CalculateMiningTime(oreType, playerMiningData.currentTool)

	-- Start mining animation
	self:StartMiningAnimation(player, oreNode, miningTime)

	-- Complete mining after delay
	spawn(function()
		wait(miningTime)
		self:CompleteMining(player, oreNode, oreType, caveNumber)
	end)
end

-- Validate mining requirements
function MiningSystem:ValidateMiningRequirements(player, oreType, playerMiningData)
	local oreData = ItemConfig.MiningSystem.ores[oreType]
	if not oreData then return false end

	local requiredLevel = oreData.requiredLevel
	local currentTool = playerMiningData.currentTool

	-- Check player level
	if playerMiningData.level < requiredLevel then
		self:SendNotification(player, "Level Too Low", 
			"You need Mining Level " .. requiredLevel .. " to mine " .. oreType:gsub("_", " ") .. "!", "error")
		return false
	end

	-- Check tool
	if not currentTool then
		self:SendNotification(player, "No Tool", "You need a pickaxe to mine! Purchase one from the shop.", "error")
		return false
	end

	local toolData = ItemConfig.MiningSystem.tools[currentTool]
	if not toolData then
		self:SendNotification(player, "Invalid Tool", "Your mining tool is not recognized!", "error")
		return false
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
		return false
	end

	return true
end

-- Calculate mining time
function MiningSystem:CalculateMiningTime(oreType, currentTool)
	local oreData = ItemConfig.MiningSystem.ores[oreType]
	local toolData = ItemConfig.MiningSystem.tools[currentTool]

	if not oreData or not toolData then return 3 end

	local baseMiningTime = oreData.hardness / toolData.speed
	return math.max(2, baseMiningTime)
end

-- ========== REMAINING FUNCTIONS ==========
-- (Previous functions like StartMiningAnimation, CompleteMining, etc. remain the same)

-- Start mining animation
function MiningSystem:StartMiningAnimation(player, oreNode, duration)
	local orePart = oreNode:FindFirstChild("OreCore")
	if not orePart then return end

	-- Create progress bar
	local progressGui = Instance.new("BillboardGui")
	progressGui.Name = "MiningProgress"
	progressGui.Size = UDim2.new(0, 120, 0, 20)
	progressGui.StudsOffset = Vector3.new(0, 4, 0)
	progressGui.Parent = orePart

	local progressFrame = Instance.new("Frame")
	progressFrame.Size = UDim2.new(1, 0, 1, 0)
	progressFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	progressFrame.BorderSizePixel = 0
	progressFrame.Parent = progressGui

	local progressBar = Instance.new("Frame")
	progressBar.Size = UDim2.new(0, 0, 1, 0)
	progressBar.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	progressBar.BorderSizePixel = 0
	progressBar.Parent = progressFrame

	-- Animate progress
	local tween = TweenService:Create(progressBar,
		TweenInfo.new(duration, Enum.EasingStyle.Linear),
		{Size = UDim2.new(1, 0, 1, 0)}
	)
	tween:Play()

	-- Cleanup
	tween.Completed:Connect(function()
		progressGui:Destroy()
	end)
end

-- Complete mining and give rewards
function MiningSystem:CompleteMining(player, oreNode, oreType, caveNumber)
	local userId = player.UserId
	local playerMiningData = self.PlayerData[userId]
	local oreData = ItemConfig.MiningSystem.ores[oreType]

	if not playerMiningData or not oreData then return end

	-- Calculate rewards based on cave upgrades
	local upgradeLevel = playerMiningData.caveUpgrades[caveNumber] or 0
	local baseAmount = math.random(1, 2)
	local bonusAmount = math.floor(upgradeLevel * 0.5) -- Each upgrade gives 50% chance for bonus
	local totalAmount = baseAmount + bonusAmount

	-- Add ore to inventory
	if not playerMiningData.inventory[oreType] then
		playerMiningData.inventory[oreType] = 0
	end
	playerMiningData.inventory[oreType] = playerMiningData.inventory[oreType] + totalAmount

	-- Calculate XP
	local xpGained = self:CalculateMiningXP(oreType, playerMiningData.level, 1)
	playerMiningData.xp = playerMiningData.xp + xpGained

	-- Check for level up
	local oldLevel = playerMiningData.level
	playerMiningData.level = self:CalculateMiningLevel(playerMiningData.xp)
	local leveledUp = playerMiningData.level > oldLevel

	-- Deplete ore node
	oreNode:SetAttribute("IsMineable", false)
	oreNode:SetAttribute("LastMined", os.time())

	-- Visual feedback
	local orePart = oreNode:FindFirstChild("OreCore")
	if orePart then
		orePart.Transparency = 0.7
		orePart.Color = Color3.fromRGB(80, 80, 80)
	end

	-- Schedule respawn
	spawn(function()
		wait(oreData.respawnTime)
		if oreNode and oreNode.Parent then
			oreNode:SetAttribute("IsMineable", true)
			if orePart then
				orePart.Transparency = 0
				orePart.Color = oreData.color
			end
		end
	end)

	-- Update GameCore
	self:SyncWithGameCore(player)

	-- Send notification
	local message = "⛏️ Mined " .. totalAmount .. "x " .. oreData.name .. "! (+" .. xpGained .. " XP)"
	if bonusAmount > 0 then
		message = message .. "\n🎉 +" .. bonusAmount .. " bonus from cave upgrades!"
	end
	if leveledUp then
		message = message .. "\n🎉 Mining Level Up! Now level " .. playerMiningData.level .. "!"
	end

	self:SendNotification(player, "Mining Success!", message, "success")
end

-- ========== UTILITY FUNCTIONS ==========

-- Sync with GameCore
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
			unlockedCaves = miningData.unlockedCaves,
			caveUpgrades = miningData.caveUpgrades
		}
		GameCore:SavePlayerData(player)
	end
end

-- Send notification
function MiningSystem:SendNotification(player, title, message, type)
	if GameCore and GameCore.SendNotification then
		GameCore:SendNotification(player, title, message, type)
	else
		print("MiningSystem [" .. player.Name .. "]: " .. title .. " - " .. message)
	end
end

-- Calculate mining XP
function MiningSystem:CalculateMiningXP(oreType, playerLevel, toolPower)
	local oreData = ItemConfig.MiningSystem.ores[oreType]
	if not oreData then return 0 end

	local baseXP = oreData.xpReward or 10
	return math.floor(baseXP * (1 + toolPower * 0.1))
end

-- Calculate level from XP
function MiningSystem:CalculateMiningLevel(totalXP)
	local levels = {
		{level = 1, xp = 0},
		{level = 2, xp = 100},
		{level = 3, xp = 300},
		{level = 4, xp = 600},
		{level = 5, xp = 1000},
		{level = 6, xp = 1500},
		{level = 7, xp = 2200},
		{level = 8, xp = 3000},
		{level = 9, xp = 4000},
		{level = 10, xp = 5500}
	}

	for i = #levels, 1, -1 do
		if totalXP >= levels[i].xp then
			return levels[i].level
		end
	end
	return 1
end

-- Find valid position for ore
function MiningSystem:FindValidOrePosition(basePosition, caveNumber)
	local caveSize = 120 + (caveNumber - 1) * 20
	local maxRadius = (caveSize / 2) - 10

	for attempt = 1, 20 do
		local angle = math.random() * math.pi * 2
		local radius = math.random() * maxRadius
		local testPosition = basePosition + Vector3.new(
			math.cos(angle) * radius,
			4 + math.random() * 8,
			math.sin(angle) * radius
		)

		return testPosition -- Simplified for now
	end

	return basePosition + Vector3.new(0, 6, 0) -- Fallback
end

-- Apply ore effects
function MiningSystem:ApplyOreEffects(orePart, oreType, oreData)
	if oreType:find("diamond") or oreType:find("obsidian") then
		orePart.Material = Enum.Material.Neon
		orePart.Transparency = 0.1

		local light = Instance.new("PointLight")
		light.Color = oreData.color
		light.Brightness = 1
		light.Range = 8
		light.Parent = orePart
	elseif oreType:find("gold") or oreType:find("platinum") then
		orePart.Material = Enum.Material.Metal
		orePart.Reflectance = 0.8
	end
end

-- System loops
function MiningSystem:StartSystemLoops()
	spawn(function()
		while true do
			wait(300)
			self:MaintainCaves()
		end
	end)
end

function MiningSystem:MaintainCaves()
	-- Cave maintenance logic
end

-- Cleanup functions
function MiningSystem:DestroyCave(userId, caveNumber)
	if self.CaveInstances[userId] and self.CaveInstances[userId][caveNumber] then
		local caveInstance = self.CaveInstances[userId][caveNumber]
		if caveInstance.model and caveInstance.model.Parent then
			caveInstance.model:Destroy()
		end
		self.CaveInstances[userId][caveNumber] = nil
	end
end

function MiningSystem:TeleportPlayerToSurface(player)
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local spawnPosition = Vector3.new(0, 10, 0)

		if GameCore and GameCore.GetFarmPlotPosition then
			local success, farmPosition = pcall(function()
				return GameCore:GetFarmPlotPosition(player, 1)
			end)
			if success and farmPosition then
				spawnPosition = farmPosition.Position + Vector3.new(10, 5, 10)
			end
		end

		player.Character.HumanoidRootPart.CFrame = CFrame.new(spawnPosition)
		self:SendNotification(player, "🌞 Back to Surface!", "Returned from the mining caves.", "success")
	end
end

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
	if not oreData then return end

	local totalValue = oreData.sellValue * amount
	playerMiningData.inventory[oreType] = playerMiningData.inventory[oreType] - amount

	if GameCore then
		local playerData = GameCore:GetPlayerData(player)
		if playerData then
			playerData.coins = (playerData.coins or 0) + totalValue
			GameCore:SavePlayerData(player)
			GameCore:UpdatePlayerLeaderstats(player)
		end
	end

	self:SyncWithGameCore(player)
	self:SendNotification(player, "💰 Ore Sold!", 
		"Sold " .. amount .. "x " .. oreData.name .. " for " .. totalValue .. " coins!", "success")
end

-- Initialize system
_G.MiningSystem = MiningSystem

spawn(function()
	while not _G.GameCore do
		wait(1)
	end
	MiningSystem:Initialize()
end)

print("MiningSystem: ✅ Tiered cave system loaded!")
print("Features:")
print("  🗻 5 progressive cave tiers")
print("  ⛏️ Cave-specific ore types") 
print("  📈 Ore quantity upgrades per cave")
print("  🔓 Progressive unlocking system")
print("  🎨 Tier-specific themes and atmosphere")

return MiningSystem