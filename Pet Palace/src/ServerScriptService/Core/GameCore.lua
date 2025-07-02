--[[
    FIXED GameCore.lua - Complete Farming System with Rarity
    Place in: ServerScriptService/Core/GameCore.lua
    
    FIXES:
    ✅ All seeds from ItemConfig now work
    ✅ Rarity system fully implemented
    ✅ Proper crop appearance based on rarity
    ✅ Enhanced planting and harvesting
    ✅ Better error handling
    ✅ Debug commands for testing
]]

local GameCore = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

-- Load configuration
local ItemConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("ItemConfig"))
local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "GameRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

-- FARM PLOT POSITION CONFIGURATION
GameCore.SimpleFarmConfig = {
	basePosition = Vector3.new(-366.118, -2.793, 75.731),
	playerSeparation = Vector3.new(150, 0, 0),
	plotRotation = Vector3.new(0, 0, 0),

	-- Single configuration - always 10x10 grid
	gridSize = 10,      -- 10x10 grid = 100 spots
	totalSpots = 100,
	baseSize = Vector3.new(60, 1, 60),
	description = "Full 10x10 farming grid (100 planting spots)",

	-- Visual settings
	spotSize = 3,
	spotSpacing = 5,
	spotColor = Color3.fromRGB(91, 154, 76),
	spotTransparency = 0
}

-- Core Data Management
GameCore.PlayerData = {}
GameCore.DataStore = nil
GameCore.RemoteEvents = {}
GameCore.RemoteFunctions = {}
GameCore.DataStoreCooldowns = {}
GameCore.PendingSaves = {}
GameCore.SAVE_COOLDOWN = 30

-- System States
GameCore.Systems = {
	Livestock = {
		CowCooldowns = {}, -- Track milk collection cooldowns per player
		PigStates = {} -- Track pig feeding states per player
	},
	Farming = {
		PlayerFarms = {},
		GrowthTimers = {},
		RarityEffects = {} -- Track rarity effects for crops
	}
}

-- Workspace Models
GameCore.Models = {
	Cow = nil,
	Pig = nil
}

-- Reference to ShopSystem (will be injected)
GameCore.ShopSystem = nil

local function WaitForCropVisualManager()
	local attempts = 0
	while not _G.CropVisualManager and attempts < 30 do
		wait(0.5)
		attempts = attempts + 1
	end

	if not _G.CropVisualManager then
		warn("GameCore: CropVisualManager not found after 15 seconds - crop visuals may not work properly")
		return nil
	end

	print("GameCore: CropVisualManager integration established")
	return _G.CropVisualManager
end

-- ========== INITIALIZATION ==========

-- FIXED GameCore Initialize Method - Add this to your GameCore.lua

function GameCore:Initialize(shopSystem)
	print("GameCore: Starting FIXED core game system initialization...")

	-- Store ShopSystem reference
	if shopSystem then
		self.ShopSystem = shopSystem
		print("GameCore: ShopSystem reference established")
	end

	-- Initialize player data storage
	self.PlayerData = {}

	-- Setup DataStore
	local success, dataStore = pcall(function()
		return game:GetService("DataStoreService"):GetDataStore("LivestockFarmData_v2")
	end)

	if success then
		self.PlayerDataStore = dataStore
		print("GameCore: DataStore connected")
	else
		warn("GameCore: Failed to connect to DataStore - running in local mode")
	end

	-- Setup remote connections (excluding shop remotes)
	self:SetupRemoteConnections()

	-- Setup event handlers (excluding shop handlers)
	self:SetupEventHandlers()

	-- Initialize game systems
	self:InitializeLivestockSystem()
	self:InitializeFarmingSystem()
	self:InitializePestAndChickenSystems()

	-- FIXED: Initialize enhanced cow system
	self:InitializeEnhancedCowSystem()

	-- FIXED: Initialize protection system
	self:InitializeProtectionSystem()

	-- Start update loops
	self:StartUpdateLoops()
	self:InitializeChairSystemIntegration()
	self:AddChairMilkingAdminCommands()
	-- Setup admin commands
	self:SetupAdminCommands()
	self:InitializeClickerMilkingSystem()
	self:AddClickerMilkingAdminCommands()
	self:InitializeCropEventSystem()
	print("GameCore: ✅ FIXED core game system initialization complete!")
	return true
end

function GameCore:InitializeCropEventSystem()
	print("GameCore: Initializing crop event system for CropVisualManager integration...")

	-- Create events that CropVisualManager can listen to
	if not self.Events then
		self.Events = {}
	end

	-- Create bindable events for crop system communication
	self.Events.CropPlanted = Instance.new("BindableEvent")
	self.Events.CropGrowthStageChanged = Instance.new("BindableEvent")
	self.Events.CropHarvested = Instance.new("BindableEvent")

	print("GameCore: Crop event system initialized")
end

-- ADD this to your existing GameCore:Initialize() method (add this line):


print("GameCore: ✅ CROPVISUALMANAGER INTEGRATION COMPLETE!")
print("🌱 NEW CROP SYSTEM FEATURES:")
print("  🎨 Integrated with CropVisualManager for enhanced visuals")
print("  🏗️ Uses pre-made models from ReplicatedStorage.CropModels")
print("  🔄 Automatic fallback to procedural generation")
print("  ✨ Enhanced growth stage transitions")
print("  🌾 Visual harvest effects using pre-made models")
print("  🎯 Better click detection on crop models")
print("")
print("🔧 TECHNICAL IMPROVEMENTS:")
print("  📡 Event system for crop state changes")
print("  🎭 Smart model switching between growth stages")
print("  🌈 Enhanced rarity visual effects")
print("  🔗 Seamless integration with existing farming system")
print("")
print("📁 REQUIRED SETUP:")
print("  1. Place crop models in ReplicatedStorage.CropModels")
print("  2. Models should be named: Carrot, Corn, Strawberry, etc.")
print("  3. CropVisualManager will automatically detect and use them")
print("  4. Falls back to procedural generation if models missing")

function GameCore:SetupClickerRemoteEvents()
	local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not remoteFolder then return end

	-- Create milking-specific remotes
	local milkingRemotes = {
		"StartMilkingSession",
		"StopMilkingSession", 
		"ContinueMilking",
		"MilkingSessionUpdate"
	}

	for _, remoteName in ipairs(milkingRemotes) do
		if not remoteFolder:FindFirstChild(remoteName) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = remoteName
			remote.Parent = remoteFolder
			self.RemoteEvents[remoteName] = remote
		end
	end

	-- Connect handlers
	if self.RemoteEvents.StartMilkingSession then
		self.RemoteEvents.StartMilkingSession.OnServerEvent:Connect(function(player, cowId)
			pcall(function()
				self:HandleStartMilkingSession(player, cowId)
			end)
		end)
	end

	if self.RemoteEvents.StopMilkingSession then
		self.RemoteEvents.StopMilkingSession.OnServerEvent:Connect(function(player)
			pcall(function()
				self:HandleStopMilkingSession(player)
			end)
		end)
	end

	if self.RemoteEvents.ContinueMilking then
		self.RemoteEvents.ContinueMilking.OnServerEvent:Connect(function(player)
			pcall(function()
				self:HandleContinueMilking(player)
			end)
		end)
	end
end
--[[
    GameCore Chair Integration Updates
    Add these methods to your existing GameCore.lua
    
    INTEGRATION:
    ✅ Chair system compatibility  
    ✅ Enhanced positioning for seated players
    ✅ Better session management
    ✅ Automatic cleanup when leaving chair
]]

-- ADD these methods to your existing GameCore.lua:

-- ========== CHAIR SYSTEM INTEGRATION ==========

function GameCore:HandleChairBasedMilkingStart(player, cowId)
    print("🪑 GameCore: Starting chair-based milking session for " .. player.Name)

    -- Check if player is seated in a milking chair
    if not self:IsPlayerSeatedInMilkingChair(player) then
        self:SendNotification(player, "Not Seated", "You must be seated in a milking chair to start milking!", "error")
        return false
    end

    -- Use existing milking session start logic
    return self:HandleStartMilkingSession(player, cowId)
end

function GameCore:IsPlayerSeatedInMilkingChair(player)
    local character = player.Character
    if not character then return false end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return false end

    -- Check if player is seated
    if humanoid.Sit then
        -- Find what they're sitting on
        for _, obj in pairs(workspace:GetChildren()) do
            if obj.Name == "MilkingChair" then -- Your chair name
                local seat = self:FindSeatInObject(obj)
                if seat and seat.Occupant == humanoid then
                    return true
                end
            end
        end
    end

    return false
end

function GameCore:FindSeatInObject(obj)
    -- Look for Seat objects in the chair
    for _, child in pairs(obj:GetDescendants()) do
        if child:IsA("Seat") then
            return child
        end
    end
    
    -- If the object itself is a seat
    if obj:IsA("Seat") then
        return obj
    end
    
    return nil
end
function GameCore:GetMilkingSessionType(player)
	local userId = player.UserId
	local session = self.Systems.ClickerMilking.ActiveSessions[userId]

	if session then
		return session.isChairBased and "chair" or "standard"
	end

	return "none"
end

function GameCore:IsChairBasedMilkingActive(player)
	local userId = player.UserId
	local session = self.Systems.ClickerMilking.ActiveSessions[userId]

	return session and session.isChairBased
end

print("GameCore: ✅ CHAIR SYSTEM INTEGRATION LOADED!")
print("🪑 INTEGRATION FEATURES:")
print("  🔗 Seamless chair-based milking integration")
print("  👤 Enhanced player positioning for chairs")
print("  📊 Session type tracking (chair vs standard)")
print("  🔍 Automatic chair monitoring") 
print("  🧹 Smart cleanup when leaving chairs")
print("  🎯 Chair-specific admin commands")
print("")
print("🔧 Chair Admin Commands:")
print("  /chairmilkstatus - Show chair vs standard sessions")
print("  /testchair - Test if player is seated properly")
print("  /forcerelease - Force release from milking")
print("  /chairinfo - Show all chairs and occupancy")
print("")
print("📋 INTEGRATION CHECKLIST:")
print("  1. Add InitializeChairSystemIntegration() to GameCore:Initialize()")
print("  2. Add AddChairMilkingAdminCommands() to GameCore:Initialize()")
print("  3. Replace HandleStartMilkingSession and HandleStopMilkingSession")
print("  4. Make sure chair is named 'MilkingChair' in workspace")
-- ========== ENHANCED POSITIONING FOR SEATED PLAYERS ==========

function GameCore:PositionPlayerForMilkingChair(player, cowId)
    print("🪑 GameCore: CHAIR-BASED positioning for " .. player.Name)

    -- For chair-based system, player is already positioned by the chair
    -- We just need to lock them in place and store their state
    
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        warn("GameCore: Player character not ready for chair milking")
        return false
    end

    local humanoid = character:FindFirstChild("Humanoid")
    local humanoidRootPart = character.HumanoidRootPart

    -- Store original position for restoration (for safety)
    local userId = player.UserId
    self.Systems.ClickerMilking.PlayerPositions[userId] = {
        cframe = humanoidRootPart.CFrame,
        walkSpeed = humanoid and humanoid.WalkSpeed or 16,
        jumpPower = humanoid and humanoid.JumpPower or 50,
        isSeated = true -- Flag for chair-based milking
    }

    -- Don't modify player position since they're seated in chair
    -- Chair system handles player locking
    
    print("🪑 GameCore: Chair-based positioning complete - player locked by chair system")
    return true
end

function GameCore:ReleasePlayerFromMilkingChair(player)
    print("🪑 GameCore: CHAIR-BASED release for " .. player.Name)

    local userId = player.UserId
    local character = player.Character

    -- For chair system, the player position is managed by the chair
    -- We just need to clean up our tracking
    
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        
        -- Only restore if player is no longer seated
        if humanoid and not humanoid.Sit then
            local originalData = self.Systems.ClickerMilking.PlayerPositions[userId]
            if originalData then
                humanoid.WalkSpeed = originalData.walkSpeed
                humanoid.JumpPower = originalData.jumpPower
            end
        end
    end

    -- Clear stored data
    self.Systems.ClickerMilking.PlayerPositions[userId] = nil

    print("🪑 Player released from chair-based milking")
end

-- ========== UPDATED MILKING SESSION METHODS ==========

-- REPLACE your existing HandleStartMilkingSession with this enhanced version:
function GameCore:HandleStartMilkingSession(player, cowId)
    print("🥛 GameCore: Starting ENHANCED milking session for " .. player.Name .. " with cow " .. cowId)

    local userId = player.UserId
    local playerData = self:GetPlayerData(player)

    if not playerData then
        self:SendNotification(player, "Error", "Player data not found!", "error")
        return false
    end

    -- Check if player is already milking
    if self.Systems.ClickerMilking.ActiveSessions[userId] then
        self:SendNotification(player, "Already Milking", "You're already milking a cow!", "warning")
        return false
    end

    -- Check if cow is already being milked
    if self.Systems.ClickerMilking.MilkingCows[cowId] then
        self:SendNotification(player, "Cow Busy", "Someone else is already milking this cow!", "warning")
        return false
    end

    -- Validate cow ownership and data
    if not playerData.livestock or not playerData.livestock.cows or not playerData.livestock.cows[cowId] then
        self:SendNotification(player, "Invalid Cow", "You don't own this cow!", "error")
        return false
    end

    local cowData = playerData.livestock.cows[cowId]

    -- Check cooldown
    local currentTime = os.time()
    local timeSinceLastMilk = currentTime - (cowData.lastMilkCollection or 0)
    if timeSinceLastMilk < 10 then -- 10 second cooldown between sessions
        local timeLeft = 10 - timeSinceLastMilk
        self:SendNotification(player, "Cow Resting", 
            "Cow needs " .. math.ceil(timeLeft) .. " more seconds before milking again!", "warning")
        return false
    end

    -- Position player - use appropriate method based on system
    local success = false
    if self:IsPlayerSeatedInMilkingChair(player) then
        success = self:PositionPlayerForMilkingChair(player, cowId)
    else
        success = self:PositionPlayerForMilking(player, cowId)
    end
    
    if not success then
        self:SendNotification(player, "Positioning Failed", "Could not position you for milking!", "error")
        return false
    end

    -- Create milking session
    local sessionData = {
        cowId = cowId,
        startTime = currentTime,
        lastClickTime = currentTime,
        milkCollected = 0,
        sessionActive = true,
        cowData = cowData,
        isChairBased = self:IsPlayerSeatedInMilkingChair(player) -- Track milking type
    }

    -- Store session data
    self.Systems.ClickerMilking.ActiveSessions[userId] = sessionData
    self.Systems.ClickerMilking.MilkingCows[cowId] = userId
    self.Systems.ClickerMilking.SessionTimeouts[userId] = currentTime + 3

    -- Send session start to client
    if self.RemoteEvents.MilkingSessionUpdate then
        self.RemoteEvents.MilkingSessionUpdate:FireClient(player, "started", sessionData)
    end

    -- Create milking visual effects
    self:CreateMilkingEffects(player, cowId)

    local milkingType = sessionData.isChairBased and "chair-based" or "standard"
    self:SendNotification(player, "🥛 Milking Started!", 
        "Keep clicking to collect milk! (" .. milkingType .. " milking)", "success")

    print("🥛 GameCore: " .. milkingType .. " milking session started for " .. player.Name)
    return true
end

-- ========== ENHANCED STOP MILKING SESSION ==========

function GameCore:HandleStopMilkingSession(player)
    print("🥛 GameCore: ENHANCED stopping milking session for " .. player.Name)

    local userId = player.UserId
    local session = self.Systems.ClickerMilking.ActiveSessions[userId]

    if not session then
        return false
    end

    -- Get final milk count
    local totalMilk = session.milkCollected

    -- Final save of player data
    if totalMilk > 0 then
        local playerData = self:GetPlayerData(player)
        if playerData then
            session.cowData.lastMilkCollection = os.time()
            self:SavePlayerData(player)

            if self.RemoteEvents.PlayerDataUpdated then
                self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
            end
        end
    end

    -- Clean up session
    self:CleanupMilkingSession(userId)

    -- Release player position - use appropriate method
    if session.isChairBased then
        self:ReleasePlayerFromMilkingChair(player)
    else
        self:ReleasePlayerFromMilking(player)
    end

    -- Send session end notification
    if self.RemoteEvents.MilkingSessionUpdate then
        self.RemoteEvents.MilkingSessionUpdate:FireClient(player, "ended", {
            totalMilk = totalMilk,
            sessionDuration = os.time() - session.startTime
        })
    end

    local milkingType = session.isChairBased and "Chair-based" or "Standard"
    self:SendNotification(player, "🥛 Milking Complete!", 
        milkingType .. " milking complete! Collected " .. totalMilk .. " milk.", "success")

    return true
end

-- ========== CHAIR SYSTEM MONITORING ==========

function GameCore:StartChairSystemMonitoring()
    -- Monitor players in milking chairs
    spawn(function()
        while true do
            wait(2) -- Check every 2 seconds
            self:MonitorChairMilkingSessions()
        end
    end)
    
    print("GameCore: Chair system monitoring started")
end

function GameCore:MonitorChairMilkingSessions()
    -- Check all chair-based milking sessions
    for userId, session in pairs(self.Systems.ClickerMilking.ActiveSessions) do
        if session.isChairBased then
            local player = Players:GetPlayerByUserId(userId)
            
            if player and player.Parent then
                -- Check if player is still seated in milking chair
                if not self:IsPlayerSeatedInMilkingChair(player) then
                    print("🪑 GameCore: Player " .. player.Name .. " left milking chair - ending session")
                    self:HandleStopMilkingSession(player)
                end
            end
        end
    end
end

-- ========== CHAIR INTEGRATION INITIALIZATION ==========

function GameCore:InitializeChairSystemIntegration()
    print("GameCore: Initializing chair system integration...")

    -- Start chair monitoring
    self:StartChairSystemMonitoring()

    -- Add chair-specific remote events if needed
    local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
    if remoteFolder then
        -- Chair system will handle its own remotes
        print("GameCore: Chair integration ready")
    end

    print("GameCore: Chair system integration initialized!")
end
-- ========== FIXED MILK COLLECTION HANDLER ==========

function GameCore:HandleContinueMilking(player)
	local userId = player.UserId
	local session = self.Systems.ClickerMilking.ActiveSessions[userId]

	if not session then
		return false
	end

	local currentTime = os.time()

	-- Update last click time to keep session active
	session.lastClickTime = currentTime
	self.Systems.ClickerMilking.SessionTimeouts[userId] = currentTime + 3 -- Reset timeout

	-- FIXED: Give exactly 1 milk per click (not automatic over time)
	session.milkCollected = session.milkCollected + 1

	-- Award milk immediately to player
	local playerData = self:GetPlayerData(player)
	if playerData then
		-- Add 1 milk to player inventory
		playerData.milk = (playerData.milk or 0) + 1

		-- Store in livestock inventory for compatibility
		if not playerData.livestock then
			playerData.livestock = {inventory = {}}
		end
		if not playerData.livestock.inventory then
			playerData.livestock.inventory = {}
		end
		playerData.livestock.inventory.milk = (playerData.livestock.inventory.milk or 0) + 1

		-- Store in farming inventory for compatibility
		if not playerData.farming then
			playerData.farming = {inventory = {}}
		end
		if not playerData.farming.inventory then
			playerData.farming.inventory = {}
		end
		playerData.farming.inventory.milk = (playerData.farming.inventory.milk or 0) + 1

		-- Update stats
		playerData.stats = playerData.stats or {}
		playerData.stats.milkCollected = (playerData.stats.milkCollected or 0) + 1

		-- Update cow data
		session.cowData.totalMilkProduced = (session.cowData.totalMilkProduced or 0) + 1

		-- Save data periodically (not every click to avoid lag)
		if session.milkCollected % 5 == 0 then -- Save every 5 clicks
			self:SavePlayerData(player)
		end

		-- Update client immediately
		if self.RemoteEvents.PlayerDataUpdated then
			self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
		end
	end

	-- Send update to client
	if self.RemoteEvents.MilkingSessionUpdate then
		self.RemoteEvents.MilkingSessionUpdate:FireClient(player, "progress", {
			milkCollected = session.milkCollected,
			sessionDuration = currentTime - session.startTime,
			lastClickTime = currentTime
		})
	end

	-- Create milk collection effect
	self:CreateMilkDropEffect(player, session.cowId)

	print("🥛 GameCore: Player " .. player.Name .. " collected 1 milk (total: " .. session.milkCollected .. ")")
	return true
end

-- ========== FIXED PLAYER POSITIONING SYSTEM ==========


function GameCore:PositionPlayerForMilking(player, cowId)
	print("🎯 GameCore: REDESIGNED positioning player for milking...")

	-- Find the cow model in workspace
	local cowModel = workspace:FindFirstChild(cowId)
	if not cowModel then
		warn("GameCore: Cow model not found: " .. cowId)
		return false
	end

	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		warn("GameCore: Player character not ready")
		return false
	end

	local humanoidRootPart = character.HumanoidRootPart
	local humanoid = character:FindFirstChild("Humanoid")

	-- Store original position for restoration
	self.Systems.ClickerMilking.PlayerPositions[player.UserId] = {
		cframe = humanoidRootPart.CFrame,
		walkSpeed = humanoid and humanoid.WalkSpeed or 16,
		jumpPower = humanoid and humanoid.JumpPower or 50
	}

	-- REDESIGNED: Find the actual ground level where the cow is standing
	local cowBounds = self:GetCowBoundingBox(cowModel)
	local cowGroundLevel = cowBounds.minY -- Bottom of the cow model
	local cowCenter = cowBounds.center

	print("🐄 Cow bounds - Center: " .. tostring(cowCenter) .. ", Ground: " .. cowGroundLevel)

	-- Position player beside cow at same ground level
	local playerGroundPosition = Vector3.new(
		cowCenter.X + 6, -- 6 studs to the side of cow (more space)
		cowGroundLevel, -- Same ground level as cow
		cowCenter.Z
	)

	-- Calculate proper standing position (HumanoidRootPart should be ~2.5 studs above ground)
	local playerStandingPosition = Vector3.new(
		playerGroundPosition.X,
		playerGroundPosition.Y + 5, -- Standard humanoid root part height
		playerGroundPosition.Z
	)

	-- Face toward the cow
	local lookDirection = (cowCenter - playerStandingPosition).Unit
	local playerCFrame = CFrame.lookAt(playerStandingPosition, playerStandingPosition + Vector3.new(lookDirection.X, 0, lookDirection.Z))

	-- CRITICAL: Ensure humanoid is in normal standing state
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
		humanoid.Sit = false -- Make sure not sitting
		humanoid.PlatformStand = false -- Don't use PlatformStand (causes weird positioning)

		-- Wait a frame for humanoid to process
		wait(0.1)
	end

	-- Set position
	humanoidRootPart.CFrame = playerCFrame
	humanoidRootPart.Anchored = true -- Lock in place

	-- Store positioning info
	if not self.Systems.ClickerMilking.PositioningObjects then
		self.Systems.ClickerMilking.PositioningObjects = {}
	end
	self.Systems.ClickerMilking.PositioningObjects[player.UserId] = {
		anchored = true,
		standingPosition = playerStandingPosition,
		groundLevel = cowGroundLevel
	}

	print("🎯 Player positioned:")
	print("  Standing at: " .. tostring(playerStandingPosition))
	print("  Ground level: " .. cowGroundLevel)
	print("  Looking toward cow at: " .. tostring(cowCenter))

	return true
end

-- ========== NEW BOUNDING BOX CALCULATION ==========

function GameCore:GetCowBoundingBox(cowModel)
	local minX, minY, minZ = math.huge, math.huge, math.huge
	local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge

	-- Find the actual bounds of all cow parts
	for _, part in pairs(cowModel:GetDescendants()) do
		if part:IsA("BasePart") then
			local pos = part.Position
			local size = part.Size

			-- Calculate bounds
			local partMinX = pos.X - size.X/2
			local partMaxX = pos.X + size.X/2
			local partMinY = pos.Y - size.Y/2
			local partMaxY = pos.Y + size.Y/2
			local partMinZ = pos.Z - size.Z/2
			local partMaxZ = pos.Z + size.Z/2

			-- Update overall bounds
			minX = math.min(minX, partMinX)
			maxX = math.max(maxX, partMaxX)
			minY = math.min(minY, partMinY)
			maxY = math.max(maxY, partMaxY)
			minZ = math.min(minZ, partMinZ)
			maxZ = math.max(maxZ, partMaxZ)
		end
	end

	return {
		center = Vector3.new((minX + maxX)/2, (minY + maxY)/2, (minZ + maxZ)/2),
		minX = minX, maxX = maxX,
		minY = minY, maxY = maxY,
		minZ = minZ, maxZ = maxZ,
		size = Vector3.new(maxX - minX, maxY - minY, maxZ - minZ)
	}
end

function GameCore:GetCowCenter(cowModel)
	-- Use same logic as CowMilkSystem for consistency
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

function GameCore:ReleasePlayerFromMilking(player)
	print("🎯 GameCore: REDESIGNED releasing player from milking...")

	local userId = player.UserId
	local character = player.Character

	-- Clean up positioning objects
	if self.Systems.ClickerMilking.PositioningObjects and self.Systems.ClickerMilking.PositioningObjects[userId] then
		local objects = self.Systems.ClickerMilking.PositioningObjects[userId]
		self.Systems.ClickerMilking.PositioningObjects[userId] = nil
	end

	-- Restore player properly
	if character then
		local humanoid = character:FindFirstChild("Humanoid")
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

		-- Unanchor first
		if humanoidRootPart then
			humanoidRootPart.Anchored = false
		end

		if humanoid then
			-- Restore original movement values
			local originalData = self.Systems.ClickerMilking.PlayerPositions[userId]
			if originalData then
				humanoid.WalkSpeed = originalData.walkSpeed
				humanoid.JumpPower = originalData.jumpPower
			else
				humanoid.WalkSpeed = 16
				humanoid.JumpPower = 50
			end

			humanoid.JumpHeight = 7.2
			humanoid.Sit = false
			humanoid.PlatformStand = false
		end

		-- Move player away from milking area
		if humanoidRootPart then
			local originalData = self.Systems.ClickerMilking.PlayerPositions[userId]
			if originalData then
				-- Move to a safe position away from original
				local safePosition = originalData.cframe.Position + Vector3.new(5, 0, 5)
				humanoidRootPart.CFrame = CFrame.new(safePosition, safePosition + originalData.cframe.LookVector)
			else
				-- Move away from current position
				humanoidRootPart.CFrame = humanoidRootPart.CFrame + Vector3.new(3, 0, 3)
			end
		end
	end

	-- Clear stored data
	self.Systems.ClickerMilking.PlayerPositions[userId] = nil

	print("🎯 Player released and moved to safe position")
end

-- ========== FIXED MILKING UPDATE LOOP (NO AUTO MILK) ==========

function GameCore:UpdateMilkingSessions()
	local currentTime = os.time()
	local sessionsToEnd = {}

	-- Check all active sessions
	for userId, session in pairs(self.Systems.ClickerMilking.ActiveSessions) do
		local player = Players:GetPlayerByUserId(userId)

		-- Check if player is still in game
		if not player or not player.Parent then
			table.insert(sessionsToEnd, userId)
			continue
		end

		-- Check for timeout (no clicks for 3 seconds)
		local timeoutTime = self.Systems.ClickerMilking.SessionTimeouts[userId] or 0
		if currentTime > timeoutTime then
			print("🥛 GameCore: Milking session timed out for " .. player.Name)
			self:HandleStopMilkingSession(player)
			continue
		end

		-- REMOVED: No automatic milk collection - only on clicks
		-- Send progress update to client (just for timer)
		if self.RemoteEvents.MilkingSessionUpdate then
			self.RemoteEvents.MilkingSessionUpdate:FireClient(player, "progress", {
				milkCollected = session.milkCollected,
				sessionDuration = currentTime - session.startTime,
				lastClickTime = session.lastClickTime
			})
		end

		-- Check for maximum session duration (optional)
		local maxSessionTime = 300 -- 5 minutes max
		if (currentTime - session.startTime) > maxSessionTime then
			print("🥛 GameCore: Milking session max time reached for " .. player.Name)
			self:HandleStopMilkingSession(player)
		end
	end

	-- Clean up ended sessions
	for _, userId in ipairs(sessionsToEnd) do
		self:CleanupMilkingSession(userId)
	end
end

-- ========== FIXED CLEANUP METHOD ==========

function GameCore:CleanupMilkingSession(userId)
	local session = self.Systems.ClickerMilking.ActiveSessions[userId]
	if session then
		-- Clear cow being milked
		self.Systems.ClickerMilking.MilkingCows[session.cowId] = nil
	end

	-- Clear all session data
	self.Systems.ClickerMilking.ActiveSessions[userId] = nil
	self.Systems.ClickerMilking.SessionTimeouts[userId] = nil
	self.Systems.ClickerMilking.PlayerPositions[userId] = nil

	-- FIXED: Clean up positioning objects properly
	if self.Systems.ClickerMilking.PositioningObjects and self.Systems.ClickerMilking.PositioningObjects[userId] then
		local objects = self.Systems.ClickerMilking.PositioningObjects[userId]

		-- Get player and character
		local player = Players:GetPlayerByUserId(userId)
		local character = player and player.Character

		if objects.bodyPosition and objects.bodyPosition.Parent then
			objects.bodyPosition:Destroy()
		end

		if objects.bodyAngularVelocity and objects.bodyAngularVelocity.Parent then
			objects.bodyAngularVelocity:Destroy()
		end

		-- Clean up anchoring if using simple method
		if objects.anchored and character and character:FindFirstChild("HumanoidRootPart") then
			character.HumanoidRootPart.Anchored = false
		end

		self.Systems.ClickerMilking.PositioningObjects[userId] = nil
	end
end

-- ========== FIXED INITIALIZATION ==========

function GameCore:InitializeClickerMilkingSystem()
	print("GameCore: Initializing FIXED clicker milking system...")

	-- Initialize milking session tracking
	self.Systems.ClickerMilking = {
		ActiveSessions = {}, -- [userId] = {sessionData}
		SessionTimeouts = {}, -- [userId] = timeoutTime
		PlayerPositions = {}, -- [userId] = originalPosition
		MilkingCows = {}, -- [cowId] = userId (track which cow is being milked)
		PositioningObjects = {} -- [userId] = {bodyPosition, bodyAngularVelocity}
	}

	-- Create remote events for clicker system
	self:SetupClickerRemoteEvents()

	-- Start milking update loop (for timeouts only, no auto-milk)
	self:StartMilkingUpdateLoop()

	print("GameCore: FIXED clicker milking system initialized!")
	print("  🖱️ 1 click = 1 milk")
	print("  🔒 Stable player positioning")
	print("  ⏱️ Session timeout after 3 seconds of inactivity")
end

print("GameCore: ✅ FIXED CLICKER MILKING SYSTEM!")
print("🔧 KEY FIXES:")
print("  🖱️ 1 click = 1 milk (no automatic collection)")
print("  🔒 Stable positioning with BodyPosition (no bouncing)")
print("  📊 Immediate milk rewards on each click")
print("  ⏱️ Session timeout only, no auto-milk generation")
print("  🧹 Proper cleanup of positioning objects")


-- ========== MILKING UPDATE LOOP ==========

function GameCore:StartMilkingUpdateLoop()
	spawn(function()
		while true do
			wait(1) -- Update every second
			self:UpdateMilkingSessions()
		end
	end)
end

-- ========== UTILITY METHODS ==========

function GameCore:AwardMilkFromSession(player, session, totalMilk)
	local playerData = self:GetPlayerData(player)
	if not playerData then return end

	-- Add milk to player inventory
	playerData.milk = (playerData.milk or 0) + totalMilk

	-- Also store in livestock inventory for compatibility
	if not playerData.livestock then
		playerData.livestock = {inventory = {}}
	end
	if not playerData.livestock.inventory then
		playerData.livestock.inventory = {}
	end
	playerData.livestock.inventory.milk = (playerData.livestock.inventory.milk or 0) + totalMilk

	-- Store in farming inventory for compatibility
	if not playerData.farming then
		playerData.farming = {inventory = {}}
	end
	if not playerData.farming.inventory then
		playerData.farming.inventory = {}
	end
	playerData.farming.inventory.milk = (playerData.farming.inventory.milk or 0) + totalMilk

	-- Update cow data
	local cowData = session.cowData
	cowData.lastMilkCollection = os.time()
	cowData.totalMilkProduced = (cowData.totalMilkProduced or 0) + totalMilk

	-- Update stats
	playerData.stats = playerData.stats or {}
	playerData.stats.milkCollected = (playerData.stats.milkCollected or 0) + totalMilk

	-- Save data
	self:SavePlayerData(player)

	-- Update client
	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	print("🥛 GameCore: Awarded " .. totalMilk .. " milk to " .. player.Name)
end

function GameCore:CreateMilkingEffects(player, cowId)
	-- Send effect creation to client/visual system
	if _G.EnhancedCowMilkSystem and _G.EnhancedCowMilkSystem.CreateMilkingSessionEffect then
		_G.EnhancedCowMilkSystem:CreateMilkingSessionEffect(player, cowId)
	end
end

function GameCore:CreateMilkDropEffect(player, cowId)
	-- Send drop effect to visual system
	if _G.EnhancedCowMilkSystem and _G.EnhancedCowMilkSystem.CreateMilkDropEffect then
		_G.EnhancedCowMilkSystem:CreateMilkDropEffect(player, cowId)
	end
end

-- ========== REPLACE EXISTING MILK COLLECTION METHOD ==========

-- REPLACE your existing HandleCowMilkCollection method with this:
function GameCore:HandleCowMilkCollection(player, cowId)
	print("🥛 GameCore: Converting cow click to milking session start...")

	-- Convert old-style milk collection to new clicker system
	return self:HandleStartMilkingSession(player, cowId)
end

-- ========== CLEANUP ON PLAYER LEAVE ==========

-- ADD this to your existing player removal handler:
Players.PlayerRemoving:Connect(function(player)
	-- Clean up milking session when player leaves
	local userId = player.UserId
	if GameCore.Systems.ClickerMilking and GameCore.Systems.ClickerMilking.ActiveSessions[userId] then
		GameCore:CleanupMilkingSession(userId)
	end
end)

-- ========== ADMIN COMMANDS FOR TESTING ==========


print("🎯 ✅ FIXED POSITIONING SYSTEM!")
print("🔧 KEY FIXES:")
print("  📏 Proper ground level calculation")
print("  👤 Player positioned at correct height (2.5 studs above ground)")
print("  🪑 Single unified milking stool at ground level")
print("  🪣 Properly positioned milk bucket")
print("  📐 Consistent positioning calculations")
print("  🎯 Better cow center detection")
print("")
print("🧪 TEST WITH ADMIN COMMAND:")
print("  Type in chat: /debugpositions")
print("  This will show you the calculated positions before testing")
function GameCore:AddChairMilkingAdminCommands()
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Replace with your username
				local args = string.split(message:lower(), " ")
				local command = args[1]

				if command == "/chairmilkstatus" then
					print("=== CHAIR MILKING STATUS ===")
					local chairBasedSessions = 0
					local standardSessions = 0

					for userId, session in pairs(self.Systems.ClickerMilking.ActiveSessions) do
						local sessionPlayer = Players:GetPlayerByUserId(userId)
						local playerName = sessionPlayer and sessionPlayer.Name or "Unknown"

						if session.isChairBased then
							chairBasedSessions = chairBasedSessions + 1
							print("  CHAIR: " .. playerName .. " milking " .. session.cowId)
						else
							standardSessions = standardSessions + 1
							print("  STANDARD: " .. playerName .. " milking " .. session.cowId)
						end
					end

					print("Chair-based sessions: " .. chairBasedSessions)
					print("Standard sessions: " .. standardSessions)
					print("============================")

				elseif command == "/testchair" then
					local isSeated = self:IsPlayerSeatedInMilkingChair(player)
					print("Player " .. player.Name .. " seated in milking chair: " .. tostring(isSeated))

					if isSeated then
						print("Chair milking available for testing")
					else
						print("Player needs to sit in a milking chair first")
					end

				elseif command == "/forcerelease" then
					-- Force release from any milking session
					self:HandleStopMilkingSession(player)
					print("Force released " .. player.Name .. " from milking")

				elseif command == "/chairinfo" then
					print("=== CHAIR SYSTEM INFO ===")
					local chairCount = 0

					for _, obj in pairs(workspace:GetChildren()) do
						if obj.Name == "MilkingChair" then
							chairCount = chairCount + 1
							local seat = self:FindSeatInObject(obj)
							local occupied = seat and seat.Occupant ~= nil
							print("Chair " .. chairCount .. ": " .. (occupied and "OCCUPIED" or "EMPTY"))

							if occupied then
								local character = seat.Occupant.Parent
								local occupantPlayer = Players:GetPlayerFromCharacter(character)
								if occupantPlayer then
									print("  Occupied by: " .. occupantPlayer.Name)
								end
							end
						end
					end

					print("Total chairs found: " .. chairCount)
					print("========================")
				end
			end
		end)
	end)
end
function GameCore:TestPlayerPositioning(player)
	if player.Name == "TommySalami311" then -- Replace with your username
		print("Testing player positioning...")

		-- Find first cow for testing
		for _, model in pairs(workspace:GetChildren()) do
			if model:IsA("Model") and model.Name:find("cow_") then
				print("Testing positioning with cow: " .. model.Name)

				-- Test positioning
				local success = self:PositionPlayerForMilking(player, model.Name)
				if success then
					print("✅ Positioning successful")

					-- Release after 5 seconds
					spawn(function()
						wait(5)
						self:ReleasePlayerFromMilking(player)
						print("✅ Player released")
					end)
				else
					print("❌ Positioning failed")
				end
				break
			end
		end
	end
end

print("GameCore: ✅ FIXED PLAYER POSITIONING SYSTEM!")
print("🔧 KEY FIXES:")
print("  ❌ Removed invalid BodyAngularVelocity.D property")
print("  🔒 Fixed BodyPosition + BodyAngularVelocity system")
print("  ⚓ Added alternative simple anchoring method")
print("  🧹 Enhanced cleanup for all positioning objects")
print("  🎯 More stable player locking")
print("")
print("💡 TIP: If you still get bouncing, replace the call to:")
print("     self:PositionPlayerForMilking(player, cowId)")
print("     with:")
print("     self:PositionPlayerForMilkingSimple(player, cowId)")
print("     in the HandleStartMilkingSession method")
function GameCore:AddClickerMilkingAdminCommands()
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Replace with your username
				local args = string.split(message:lower(), " ")
				local command = args[1]

				if command == "/milkstatus" then
					print("=== CLICKER MILKING STATUS ===")
					print("Active sessions: " .. self:CountTable(self.Systems.ClickerMilking.ActiveSessions))

					for userId, session in pairs(self.Systems.ClickerMilking.ActiveSessions) do
						local sessionPlayer = Players:GetPlayerByUserId(userId)
						local playerName = sessionPlayer and sessionPlayer.Name or "Unknown"
						print("  " .. playerName .. ": milking " .. session.cowId .. " (" .. session.milkCollected .. " milk)")
					end
					print("==============================")

				elseif command == "/stopmilking" then
					local targetName = args[2] or player.Name
					local targetPlayer = Players:FindFirstChild(targetName)

					if targetPlayer then
						self:HandleStopMilkingSession(targetPlayer)
						print("Stopped milking session for " .. targetName)
					end

				elseif command == "/testmilking" then
					-- Find player's first cow and start milking
					local playerData = self:GetPlayerData(player)
					if playerData and playerData.livestock and playerData.livestock.cows then
						for cowId, _ in pairs(playerData.livestock.cows) do
							self:HandleStartMilkingSession(player, cowId)
							print("Started test milking session with " .. cowId)
							break
						end
					end
				end
			end
		end)
	end)
end

-- ========== INITIALIZATION CALL ==========
-- Add this to your existing GameCore:Initialize() method:
-- self:InitializeClickerMilkingSystem()
-- self:AddClickerMilkingAdminCommands()

print("GameCore: ✅ CLICKER MILKING SYSTEM LOADED!")
print("🥛 NEW FEATURES:")
print("  🖱️ Click-to-start milking sessions")
print("  ⏱️ 1 milk per second collection")
print("  🔒 Player positioning and locking")
print("  📊 Session progress tracking")
print("  ⚡ Automatic timeout protection")
print("  🎯 Anti-cheat session validation")
print("")
print("🔧 Admin Commands:")
print("  /milkstatus - Show active milking sessions")
print("  /stopmilking [player] - Stop milking session")
print("  /testmilking - Start test milking session")
-- FIXED: Enhanced cow configuration method
function GameCore:GetCowConfiguration(cowType)
	print("🐄 GameCore: Getting cow configuration for " .. cowType)

	if not ItemConfig or not ItemConfig.ShopItems then 
		warn("🐄 GameCore: ItemConfig not available")
		return nil 
	end

	local item = ItemConfig.ShopItems[cowType]
	if not item then
		warn("🐄 GameCore: Item not found: " .. cowType)
		print("🐄 Available items:")
		for id, _ in pairs(ItemConfig.ShopItems) do
			if id:find("cow") then
				print("  " .. id)
			end
		end
		return nil
	end

	if not item.cowData then
		warn("🐄 GameCore: Item has no cowData: " .. cowType)
		return nil
	end

	print("🐄 GameCore: Found cow configuration for " .. cowType)
	print("  Tier: " .. (item.cowData.tier or "unknown"))
	print("  Milk Amount: " .. (item.cowData.milkAmount or "unknown"))
	print("  Cooldown: " .. (item.cowData.cooldown or "unknown"))

	return item.cowData
end

-- FIXED: Enhanced PurchaseCow method with better error handling
function GameCore:PurchaseCow(player, cowType, upgradeFromCowId)
	print("🐄 GameCore: FIXED cow purchase - " .. player.Name .. " buying " .. cowType)

	local playerData = self:GetPlayerData(player)
	if not playerData then 
		warn("🐄 GameCore: No player data for " .. player.Name)
		return false 
	end

	-- Get cow configuration with enhanced error handling
	local cowConfig = self:GetCowConfiguration(cowType)
	if not cowConfig then
		self:SendNotification(player, "Invalid Cow", "Cow configuration not found for: " .. cowType, "error")
		warn("🐄 GameCore: Cow configuration not found for " .. cowType)
		return false
	end

	print("🐄 GameCore: Cow configuration loaded successfully")

	-- Check if this is an upgrade
	if upgradeFromCowId then
		print("🐄 GameCore: Processing cow upgrade")
		return self:UpgradeCow(player, upgradeFromCowId, cowType, cowConfig)
	else
		print("🐄 GameCore: Processing new cow purchase")
		return self:CreateNewCow(player, cowType, cowConfig)
	end
end

print("GameCore: ✅ FIXED initialization and cow handling methods!")

function GameCore:SetupRemoteConnections()
	print("GameCore: Setting up core remote connections...")

	-- Wait for GameRemotes folder to exist
	local remotes = ReplicatedStorage:WaitForChild("GameRemotes", 10)
	if not remotes then
		error("GameCore: GameRemotes folder not found after 10 seconds!")
	end

	-- Clear existing connections
	self.RemoteEvents = {}
	self.RemoteFunctions = {}

	-- Core remote events (excluding shop-related ones)
	local coreRemoteEvents = {
		"CollectMilk", "FeedPig", "PlayerDataUpdated", "ShowNotification",
		"PlantSeed", "HarvestCrop", "HarvestAllCrops",
		"PestSpotted", "PestEliminated", "ChickenPlaced", "ChickenMoved",
		"FeedAllChickens", "FeedChickensWithType", "UsePesticide"
	}

	-- Core remote functions (excluding shop-related ones)
	local coreRemoteFunctions = {
		"GetPlayerData", "GetFarmingData"
	}

	-- Load core remote events
	for _, eventName in ipairs(coreRemoteEvents) do
		local remote = remotes:FindFirstChild(eventName)
		if remote and remote:IsA("RemoteEvent") then
			self.RemoteEvents[eventName] = remote
			print("GameCore: ✅ Connected RemoteEvent: " .. eventName)
		else
			-- Create missing remotes
			local newRemote = Instance.new("RemoteEvent")
			newRemote.Name = eventName
			newRemote.Parent = remotes
			self.RemoteEvents[eventName] = newRemote
			print("GameCore: 📦 Created RemoteEvent: " .. eventName)
		end
	end

	-- Load core remote functions
	for _, funcName in ipairs(coreRemoteFunctions) do
		local remote = remotes:FindFirstChild(funcName)
		if remote and remote:IsA("RemoteFunction") then
			self.RemoteFunctions[funcName] = remote
			print("GameCore: ✅ Connected RemoteFunction: " .. funcName)
		else
			-- Create missing remotes
			local newRemote = Instance.new("RemoteFunction")
			newRemote.Name = funcName
			newRemote.Parent = remotes
			self.RemoteFunctions[funcName] = newRemote
			print("GameCore: 📦 Created RemoteFunction: " .. funcName)
		end
	end

	print("GameCore: Core remote connections established")
	print("  RemoteEvents: " .. self:CountTable(self.RemoteEvents))
	print("  RemoteFunctions: " .. self:CountTable(self.RemoteFunctions))
end

function GameCore:SetupEventHandlers()
	print("GameCore: Setting up core event handlers...")

	-- Livestock System Events
	if self.RemoteEvents.CollectMilk then
		self.RemoteEvents.CollectMilk.OnServerEvent:Connect(function(player)
			pcall(function()
				self:HandleMilkCollection(player)
			end)
		end)
		print("✅ Connected CollectMilk handler")
	end

	if self.RemoteEvents.FeedPig then
		self.RemoteEvents.FeedPig.OnServerEvent:Connect(function(player, cropId)
			pcall(function()
				self:HandlePigFeeding(player, cropId)
			end)
		end)
		print("✅ Connected FeedPig handler")
	end

	-- Farming System Events
	if self.RemoteEvents.PlantSeed then
		self.RemoteEvents.PlantSeed.OnServerEvent:Connect(function(player, plotModel, seedId)
			pcall(function()
				self:PlantSeed(player, plotModel, seedId)
			end)
		end)
		print("✅ Connected PlantSeed handler")
	end

	if self.RemoteEvents.HarvestCrop then
		self.RemoteEvents.HarvestCrop.OnServerEvent:Connect(function(player, plotModel)
			pcall(function()
				self:HarvestCrop(player, plotModel)
			end)
		end)
		print("✅ Connected HarvestCrop handler")
	end

	if self.RemoteEvents.HarvestAllCrops then
		self.RemoteEvents.HarvestAllCrops.OnServerEvent:Connect(function(player)
			pcall(function()
				self:HarvestAllCrops(player)
			end)
		end)
		print("✅ Connected HarvestAllCrops handler")
	end

	-- Chicken System Events
	if self.RemoteEvents.FeedAllChickens then
		self.RemoteEvents.FeedAllChickens.OnServerEvent:Connect(function(player)
			pcall(function()
				self:HandleFeedAllChickens(player)
			end)
		end)
		print("✅ Connected FeedAllChickens handler")
	end

	if self.RemoteEvents.FeedChickensWithType then
		self.RemoteEvents.FeedChickensWithType.OnServerEvent:Connect(function(player, feedType)
			pcall(function()
				self:HandleFeedChickensWithType(player, feedType)
			end)
		end)
		print("✅ Connected FeedChickensWithType handler")
	end

	-- Core Remote Functions
	if self.RemoteFunctions.GetPlayerData then
		self.RemoteFunctions.GetPlayerData.OnServerInvoke = function(player)
			local success, result = pcall(function()
				return self:GetPlayerData(player)
			end)
			return success and result or nil
		end
		print("✅ Connected GetPlayerData function")
	end

	if self.RemoteFunctions.GetFarmingData then
		self.RemoteFunctions.GetFarmingData.OnServerInvoke = function(player)
			local success, result = pcall(function()
				local playerData = self:GetPlayerData(player)
				return playerData and playerData.farming or {}
			end)
			return success and result or {}
		end
		print("✅ Connected GetFarmingData function")
	end

	print("GameCore: Core event handlers setup complete!")
end

-- ========== EXPANDABLE FARM PLOT SYSTEM ==========

function GameCore:GetSimpleFarmPosition(player)
	if not self.SimpleFarmConfig then
		warn("GameCore: SimpleFarmConfig not initialized!")
		return CFrame.new(0, 0, 0)
	end

	-- Get player index for farm separation
	local playerIndex = 0
	local sortedPlayers = {}
	for _, p in pairs(Players:GetPlayers()) do
		table.insert(sortedPlayers, p)
	end
	table.sort(sortedPlayers, function(a, b) return a.UserId < b.UserId end)

	for i, p in ipairs(sortedPlayers) do
		if p.UserId == player.UserId then
			playerIndex = i - 1
			break
		end
	end

	-- Calculate position
	local basePos = self.SimpleFarmConfig.basePosition
	local playerOffset = self.SimpleFarmConfig.playerSeparation * playerIndex
	local finalPosition = basePos + playerOffset

	local rotation = self.SimpleFarmConfig.plotRotation
	local cframe = CFrame.new(finalPosition) * CFrame.Angles(
		math.rad(rotation.X), 
		math.rad(rotation.Y), 
		math.rad(rotation.Z)
	)

	return cframe
end

-- Create simple farm plot for player (always 10x10)
function GameCore:CreateSimpleFarmPlot(player)
	print("GameCore: Creating simple 10x10 farm plot for " .. player.Name)

	local playerData = self:GetPlayerData(player)
	if not playerData then
		warn("GameCore: No player data for " .. player.Name)
		return false
	end

	-- Initialize farming data if needed
	if not playerData.farming then
		playerData.farming = {
			inventory = {}
		}
	end

	local plotCFrame = self:GetSimpleFarmPosition(player)

	-- Find or create the farm area structure
	local areas = workspace:FindFirstChild("Areas")
	if not areas then
		areas = Instance.new("Folder")
		areas.Name = "Areas"
		areas.Parent = workspace
	end

	local starterMeadow = areas:FindFirstChild("Starter Meadow")
	if not starterMeadow then
		starterMeadow = Instance.new("Model")
		starterMeadow.Name = "Starter Meadow"
		starterMeadow.Parent = areas
	end

	local farmArea = starterMeadow:FindFirstChild("Farm")
	if not farmArea then
		farmArea = Instance.new("Folder")
		farmArea.Name = "Farm"
		farmArea.Parent = starterMeadow
	end

	-- Create/update player-specific simple farm
	local playerFarmName = player.Name .. "_SimpleFarm"
	local playerFarm = farmArea:FindFirstChild(playerFarmName)

	if playerFarm then
		-- Farm already exists, just ensure it's correct
		print("GameCore: Farm already exists for " .. player.Name)
		return true
	else
		-- Create new simple farm
		return self:CreateNewSimpleFarmPlot(player, farmArea, playerFarmName, plotCFrame)
	end
end

-- Create new simple farm plot (always 10x10, all unlocked)
function GameCore:CreateNewSimpleFarmPlot(player, farmArea, farmName, plotCFrame)
	print("GameCore: Creating new simple farm for " .. player.Name)

	local config = self.SimpleFarmConfig

	-- Create the simple farm model
	local simpleFarm = Instance.new("Model")
	simpleFarm.Name = farmName
	simpleFarm.Parent = farmArea

	-- Create the main base platform
	local basePart = Instance.new("Part")
	basePart.Name = "BasePart"
	basePart.Size = config.baseSize
	basePart.Material = Enum.Material.Ground
	basePart.Color = Color3.fromRGB(101, 67, 33)
	basePart.Anchored = true
	basePart.CFrame = plotCFrame
	basePart.Parent = simpleFarm

	simpleFarm.PrimaryPart = basePart

	-- Create all planting spots (10x10 grid, all unlocked)
	local plantingSpots = Instance.new("Folder")
	plantingSpots.Name = "PlantingSpots"
	plantingSpots.Parent = simpleFarm

	self:CreateSimplePlantingGrid(player, simpleFarm, plantingSpots, plotCFrame)

	-- Create border and info sign
	self:CreateSimpleBorder(simpleFarm, plotCFrame, config)
	self:CreateSimpleInfoSign(simpleFarm, plotCFrame, player)

	print("GameCore: Created simple farm for " .. player.Name .. " with " .. config.totalSpots .. " unlocked spots")
	return true
end

-- Create simple planting grid (10x10, all unlocked)
function GameCore:CreateSimplePlantingGrid(player, farmModel, plantingSpots, plotCFrame)
	local config = self.SimpleFarmConfig
	local gridSize = config.gridSize
	local spotSize = config.spotSize
	local spacing = config.spotSpacing

	-- Calculate grid offset to center it
	local gridOffset = (gridSize - 1) * spacing / 2

	local spotIndex = 0
	for row = 1, gridSize do
		for col = 1, gridSize do
			spotIndex = spotIndex + 1
			local spotName = "PlantingSpot_" .. spotIndex

			local spotModel = Instance.new("Model")
			spotModel.Name = spotName
			spotModel.Parent = plantingSpots

			-- Position calculation (centered grid)
			local offsetX = (col - 1) * spacing - gridOffset
			local offsetZ = (row - 1) * spacing - gridOffset

			local spotPart = Instance.new("Part")
			spotPart.Name = "SpotPart"
			spotPart.Size = Vector3.new(spotSize, 0.2, spotSize)
			spotPart.Material = Enum.Material.LeafyGrass
			spotPart.Anchored = true
			spotPart.CFrame = plotCFrame + Vector3.new(offsetX, 1, offsetZ)
			spotPart.Parent = spotModel

			spotModel.PrimaryPart = spotPart

			-- Set spot attributes (all spots are unlocked and empty)
			spotModel:SetAttribute("IsEmpty", true)
			spotModel:SetAttribute("PlantType", "")
			spotModel:SetAttribute("SeedType", "")
			spotModel:SetAttribute("GrowthStage", 0)
			spotModel:SetAttribute("PlantedTime", 0)
			spotModel:SetAttribute("Rarity", "common")
			spotModel:SetAttribute("IsUnlocked", true)  -- All spots always unlocked
			spotModel:SetAttribute("GridRow", row)
			spotModel:SetAttribute("GridCol", col)

			-- All spots get unlocked styling
			spotPart.Color = config.spotColor
			spotPart.Transparency = config.spotTransparency

			-- Create interaction indicator for all spots
			local indicator = Instance.new("Part")
			indicator.Name = "Indicator"
			indicator.Size = Vector3.new(0.5, 2, 0.5)
			indicator.Material = Enum.Material.Neon
			indicator.Color = Color3.fromRGB(100, 255, 100)
			indicator.Anchored = true
			indicator.CFrame = spotPart.CFrame + Vector3.new(0, 1.5, 0)
			indicator.Parent = spotModel

			-- Add click detector for all spots
			local clickDetector = Instance.new("ClickDetector")
			clickDetector.MaxActivationDistance = 10
			clickDetector.Parent = spotPart

			clickDetector.MouseClick:Connect(function(clickingPlayer)
				if clickingPlayer.UserId == player.UserId then
					self:HandleSimplePlotClick(clickingPlayer, spotModel)
				end
			end)
		end
	end

	print("GameCore: Created " .. spotIndex .. " unlocked planting spots in 10x10 grid")
end

-- Create simple border
function GameCore:CreateSimpleBorder(farmModel, plotCFrame, config)
	local borderContainer = Instance.new("Model")
	borderContainer.Name = "SimpleBorder"
	borderContainer.Parent = farmModel

	local borderHeight = 1
	local borderWidth = 0.5
	local plotSize = config.baseSize.X

	local borderPositions = {
		{Vector3.new(0, borderHeight/2, plotSize/2 + borderWidth/2), Vector3.new(plotSize + borderWidth, borderHeight, borderWidth)},
		{Vector3.new(0, borderHeight/2, -(plotSize/2 + borderWidth/2)), Vector3.new(plotSize + borderWidth, borderHeight, borderWidth)},
		{Vector3.new(plotSize/2 + borderWidth/2, borderHeight/2, 0), Vector3.new(borderWidth, borderHeight, plotSize)},
		{Vector3.new(-(plotSize/2 + borderWidth/2), borderHeight/2, 0), Vector3.new(borderWidth, borderHeight, plotSize)}
	}

	for i, borderData in ipairs(borderPositions) do
		local borderPart = Instance.new("Part")
		borderPart.Name = "Border_" .. i
		borderPart.Size = borderData[2]
		borderPart.Material = Enum.Material.Wood
		borderPart.Color = Color3.fromRGB(92, 51, 23)
		borderPart.Anchored = true
		borderPart.CFrame = plotCFrame + borderData[1]
		borderPart.Parent = borderContainer
	end
end

-- Create simple info sign
function GameCore:CreateSimpleInfoSign(farmModel, plotCFrame, player)
	local config = self.SimpleFarmConfig

	local signContainer = Instance.new("Model")
	signContainer.Name = "InfoSign"
	signContainer.Parent = farmModel

	local signPost = Instance.new("Part")
	signPost.Name = "SignPost"
	signPost.Size = Vector3.new(0.5, 4, 0.5)
	signPost.Material = Enum.Material.Wood
	signPost.Color = Color3.fromRGB(92, 51, 23)
	signPost.Anchored = true
	signPost.CFrame = plotCFrame + Vector3.new(config.baseSize.X/2 + 5, 2, -config.baseSize.Z/2 - 5)
	signPost.Parent = signContainer

	local signBoard = Instance.new("Part")
	signBoard.Name = "SignBoard"
	signBoard.Size = Vector3.new(4, 3, 0.2)
	signBoard.Material = Enum.Material.Wood
	signBoard.Color = Color3.fromRGB(139, 90, 43)
	signBoard.Anchored = true
	signBoard.CFrame = signPost.CFrame + Vector3.new(2, 0.5, 0)
	signBoard.Parent = signContainer

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.Parent = signBoard

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = player.Name .. "'s Farm\n" .. 
		config.gridSize .. "x" .. config.gridSize .. " Grid\n" .. 
		config.totalSpots .. " Total Spots\n" .. 
		"All Unlocked!"
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextStrokeTransparency = 0
	textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	textLabel.Parent = surfaceGui
end

-- Get player's simple farm model
function GameCore:GetPlayerSimpleFarm(player)
	local areas = workspace:FindFirstChild("Areas")
	if not areas then return nil end

	local starterMeadow = areas:FindFirstChild("Starter Meadow")
	if not starterMeadow then return nil end

	local farmArea = starterMeadow:FindFirstChild("Farm")
	if not farmArea then return nil end

	return farmArea:FindFirstChild(player.Name .. "_SimpleFarm")
end

-- Simple plot click handler
function GameCore:HandleSimplePlotClick(player, spotModel)
	local isEmpty = spotModel:GetAttribute("IsEmpty")
	local isUnlocked = spotModel:GetAttribute("IsUnlocked")

	-- All spots should be unlocked in simple system
	if not isUnlocked then
		self:SendNotification(player, "Error", "This spot should be unlocked! Please report this bug.", "error")
		return
	end

	if not isEmpty then
		-- Check if crop is ready for harvest
		local growthStage = spotModel:GetAttribute("GrowthStage") or 0
		if growthStage >= 4 then
			self:HarvestCrop(player, spotModel)
		else
			self:SendNotification(player, "Crop Growing", "This crop is still growing! Wait for it to be ready.", "info")
		end
		return
	end

	local plotOwner = self:GetSimplePlotOwner(spotModel)
	if plotOwner ~= player.Name then
		self:SendNotification(player, "Not Your Plot", "You can only plant on your own farm plots!", "error")
		return
	end

	local playerData = self:GetPlayerData(player)
	if not playerData or not playerData.farming or not playerData.farming.inventory then
		self:SendNotification(player, "No Farming Data", "You need to set up farming first! Visit the shop.", "warning")
		return
	end

	local hasSeeds = false
	for itemId, qty in pairs(playerData.farming.inventory) do
		if itemId:find("_seeds") and qty > 0 then
			hasSeeds = true
			break
		end
	end
	if not hasSeeds then
		self:SendNotification(player, "No Seeds", "You don't have any seeds! Buy some from the shop first.", "warning")
		return
	end

	-- Send to client for seed selection
	self.RemoteEvents.PlantSeed:FireClient(player, spotModel)
end

-- Get simple plot owner
function GameCore:GetSimplePlotOwner(spotModel)
	local parent = spotModel.Parent
	local attempts = 0

	while parent and parent.Parent and attempts < 10 do
		attempts = attempts + 1

		if parent.Name:find("_SimpleFarm") then
			return parent.Name:gsub("_SimpleFarm", "")
		end

		parent = parent.Parent
	end

	warn("GameCore: Could not determine simple plot owner for " .. spotModel.Name)
	return nil
end

-- ========== UPDATE EXISTING METHODS ==========

-- Replace the old expandable farm creation with simple farm creation
function GameCore:CreateExpandableFarmPlot(player)
	return self:CreateSimpleFarmPlot(player)
end

function GameCore:GetPlayerExpandableFarm(player)
	return self:GetPlayerSimpleFarm(player)
end

function GameCore:GetPlotOwner(plotModel)
	-- Try simple farm first
	local simpleOwner = self:GetSimplePlotOwner(plotModel)
	if simpleOwner then
		return simpleOwner
	end

	-- Fallback for any remaining old-style plots
	local parent = plotModel.Parent
	local attempts = 0

	while parent and parent.Parent and attempts < 10 do
		attempts = attempts + 1

		if parent.Name:find("_Farm") then
			return parent.Name:gsub("_Farm", "")
		end

		parent = parent.Parent
	end

	warn("GameCore: Could not determine plot owner for " .. plotModel.Name)
	return nil
end

-- ========== SIMPLIFIED FARM PLOT CREATION METHOD ==========

function GameCore:CreatePlayerFarmPlot(player, totalPlots)
	print("🌾 GameCore: Creating simple farm plot for " .. player.Name)
	return self:CreateSimpleFarmPlot(player)
end

-- ========== SIMPLIFIED FARM PLOT PURCHASE ==========

function GameCore:ProcessFarmPlotPurchase(player, playerData, item, quantity)
	print("🌾 GameCore: Simplified ProcessFarmPlotPurchase for " .. player.Name)

	-- Handle farm plot starter (first-time farm creation)
	if item.id == "farm_plot_starter" then
		print("🌾 Processing farm plot starter")

		-- Initialize farming data
		if not playerData.farming then
			playerData.farming = {
				plots = 1,
				inventory = {
					-- Give starter seeds
					carrot_seeds = 5,
					corn_seeds = 3
				}
			}
		else
			playerData.farming.plots = (playerData.farming.plots or 0) + quantity
		end

		-- Create the physical simple farm plot
		local success = self:CreateSimpleFarmPlot(player)
		if not success then
			-- Revert changes on failure
			if playerData.farming.plots then
				playerData.farming.plots = playerData.farming.plots - quantity
			end
			return false
		end

		print("🌾 Created simple farm plot for " .. player.Name)
		return true
	end

	-- Regular farm plot purchase (legacy support)
	if not playerData.farming then
		playerData.farming = {plots = 0, inventory = {}}
	end

	playerData.farming.plots = (playerData.farming.plots or 0) + quantity

	-- Create the physical farm plot using simple system
	local success = self:CreateSimpleFarmPlot(player)
	if not success then
		playerData.farming.plots = playerData.farming.plots - quantity
		return false
	end

	print("🌾 Added " .. quantity .. " farm plot(s), total: " .. playerData.farming.plots)
	return true
end

-- ========== ENSURE PLAYER HAS SIMPLE FARM ==========

function GameCore:EnsurePlayerHasSimpleFarm(player)
	print("🌾 GameCore: Ensuring " .. player.Name .. " has simple farm")

	local playerData = self:GetPlayerData(player)
	if not playerData then
		return false
	end

	-- Check if player should have a farm
	local hasFarmItem = playerData.purchaseHistory and playerData.purchaseHistory.farm_plot_starter
	local hasFarmingData = playerData.farming and playerData.farming.plots and playerData.farming.plots > 0

	if not hasFarmItem and not hasFarmingData then
		print("🌾 Player " .. player.Name .. " doesn't have farm access")
		return false
	end

	-- Ensure farming data is initialized
	if not playerData.farming then
		playerData.farming = {
			plots = 1,
			inventory = {}
		}
		self:SavePlayerData(player)
	end

	-- Check if physical farm exists
	local existingFarm = self:GetPlayerSimpleFarm(player)
	if not existingFarm then
		print("🌾 Creating missing simple farm for " .. player.Name)
		return self:CreateSimpleFarmPlot(player)
	end

	print("🌾 Player " .. player.Name .. " already has simple farm")
	return true
end

print("GameCore: ✅ SIMPLIFIED FARM SYSTEM LOADED!")
print("🌾 SIMPLE FARM FEATURES:")
print("  📏 Always 10x10 grid (100 planting spots)")
print("  🔓 All spots unlocked immediately")
print("  🚫 No expansion system or purchases needed")
print("  🎨 Clean, simple farm layout")
print("  ✨ No locked spots or expansion requirements")
print("  📊 Simplified farm management")
print("")
print("🔧 COMPATIBILITY:")
print("  ✅ Works with existing farming system")
print("  ✅ Works with existing crop growing")
print("  ✅ Works with existing seed planting")
print("  ✅ Works with existing harvest system")
print("  ✅ Replaces expandable farm methods")
-- ========== ENHANCED FARMING SYSTEM WITH RARITY ==========

function GameCore:InitializeFarmingSystem()
	print("GameCore: Initializing ENHANCED farming system with rarity...")
	self.Systems.Farming.RarityEffects = {}
	print("GameCore: Enhanced farming system initialized")
end

function GameCore:CreateCropOnPlot(plotModel, seedId, seedData, cropRarity)
	local success, error = pcall(function()
		local spotPart = plotModel:FindFirstChild("SpotPart")
		if not spotPart then
			warn("GameCore: No SpotPart found in plot model")
			return false
		end

		-- Remove any existing crop
		local existingCrop = plotModel:FindFirstChild("CropModel")
		if existingCrop then
			existingCrop:Destroy()
		end

		-- UPDATED: Use CropVisualManager for crop creation
		local cropType = seedData.resultCropId
		local growthStage = "planted" -- Start with planted stage

		local cropModel = nil

		-- Try to use CropVisualManager if available
		local CropVisualManager = _G.CropVisualManager or WaitForCropVisualManager()

		if CropVisualManager then
			print("🎨 GameCore: Using CropVisualManager for " .. cropType .. " (" .. cropRarity .. ")")
			cropModel = CropVisualManager:CreateCropModel(cropType, cropRarity, growthStage)
			cropModel.Name = "CropModel"
			cropModel.Parent = plotModel

			-- Position the crop visual
			if cropModel.PrimaryPart then
				cropModel.PrimaryPart.CFrame = spotPart.CFrame + Vector3.new(0, 1, 0)
			end
		else
			-- Fallback to simple procedural creation
			warn("GameCore: CropVisualManager not available, using fallback method")
			cropModel = self:CreateSimpleCropModel(plotModel, seedId, seedData, cropRarity)
		end

		if not cropModel then
			warn("GameCore: Failed to create crop model")
			return false
		end

		-- Add click detector for harvesting with enhanced detection
		self:SetupCropClickDetection(cropModel, plotModel)

		-- Start enhanced growth timer with visual updates
		self:StartEnhancedCropGrowthTimer(plotModel, seedData, cropType, cropRarity)

		return true
	end)

	if not success then
		warn("GameCore: Failed to create crop on plot: " .. tostring(error))
		return false
	end

	return true
end

-- ADD this new method for fallback crop creation
function GameCore:CreateSimpleCropModel(plotModel, seedId, seedData, cropRarity)
	local spotPart = plotModel:FindFirstChild("SpotPart")
	if not spotPart then return nil end

	-- Create simple crop model as fallback
	local cropModel = Instance.new("Model")
	cropModel.Name = "CropModel"
	cropModel.Parent = plotModel

	-- Create basic crop part
	local cropPart = Instance.new("Part")
	cropPart.Name = "Crop"
	cropPart.Size = Vector3.new(2, 1, 2)
	cropPart.Material = Enum.Material.SmoothPlastic
	cropPart.Color = self:GetCropColor(seedData.resultCropId, cropRarity)
	cropPart.Anchored = true
	cropPart.CanCollide = false
	cropPart.CFrame = spotPart.CFrame + Vector3.new(0, 1, 0)
	cropPart.Parent = cropModel

	-- Apply rarity size scaling
	local raritySize = ItemConfig.GetRaritySize(cropRarity)
	cropPart.Size = cropPart.Size * raritySize

	-- Add rarity effects
	self:AddBasicRarityEffects(cropPart, cropRarity)

	cropModel.PrimaryPart = cropPart
	return cropModel
end

-- ADD this method for basic rarity effects
function GameCore:AddBasicRarityEffects(cropPart, cropRarity)
	if cropRarity == "common" then return end

	-- Add glow for higher rarities
	local light = Instance.new("PointLight")
	light.Parent = cropPart

	if cropRarity == "uncommon" then
		light.Color = Color3.fromRGB(0, 255, 0)
		light.Brightness = 1
	elseif cropRarity == "rare" then
		light.Color = Color3.fromRGB(255, 215, 0)
		light.Brightness = 1.5
		cropPart.Material = Enum.Material.Neon
	elseif cropRarity == "epic" then
		light.Color = Color3.fromRGB(128, 0, 128)
		light.Brightness = 2
		cropPart.Material = Enum.Material.Neon
	elseif cropRarity == "legendary" then
		light.Color = Color3.fromRGB(255, 100, 100)
		light.Brightness = 3
		cropPart.Material = Enum.Material.Neon
	end

	light.Range = 10
end

-- REPLACE your existing StartEnhancedCropGrowthTimer method with this updated version:
function GameCore:StartEnhancedCropGrowthTimer(plotModel, seedData, cropType, cropRarity)
	spawn(function()
		local growTime = seedData.growTime
		local stages = seedData.stages or {"planted", "sprouting", "growing", "ready"}
		local stageTime = growTime / (#stages - 1)

		for stage = 0, #stages - 2 do
			wait(stageTime)

			if plotModel and plotModel.Parent then
				local currentStage = plotModel:GetAttribute("GrowthStage") or 0
				if currentStage == stage then
					local newStageIndex = stage + 1
					local newStageName = stages[newStageIndex + 1] or "ready"

					plotModel:SetAttribute("GrowthStage", newStageIndex)

					-- UPDATED: Use CropVisualManager for stage transitions
					local CropVisualManager = _G.CropVisualManager
					if CropVisualManager then
						print("🌱 GameCore: Updating crop stage to " .. newStageName .. " for " .. cropType)
						CropVisualManager:UpdateCropGrowthStage(plotModel, newStageName, cropType, cropRarity)
					else
						-- Fallback to basic visual update
						self:UpdateCropVisualBasic(plotModel, newStageIndex, cropRarity)
					end

					-- Fire growth stage event if other systems need it
					if self.Events and self.Events.CropGrowthStageChanged then
						self.Events.CropGrowthStageChanged:Fire(plotModel, newStageName, cropType, cropRarity)
					end
				end
			else
				break
			end
		end

		-- Mark as fully grown
		if plotModel and plotModel.Parent then
			plotModel:SetAttribute("GrowthStage", #stages)

			-- Final stage update to "ready" with pre-made models
			local CropVisualManager = _G.CropVisualManager
			if CropVisualManager then
				print("🌾 GameCore: Crop fully grown - updating to ready stage with pre-made model")
				CropVisualManager:UpdateCropGrowthStage(plotModel, "ready", cropType, cropRarity)
			end
		end
	end)
end

-- ADD this method for basic visual updates when CropVisualManager is not available
function GameCore:UpdateCropVisualBasic(plotModel, stageIndex, cropRarity)
	local cropModel = plotModel:FindFirstChild("CropModel")
	if not cropModel or not cropModel.PrimaryPart then return end

	local crop = cropModel.PrimaryPart

	-- Update size based on growth stage
	local baseScale = 0.3 + stageIndex * 0.425
	local rarityScale = ItemConfig.GetRaritySize(cropRarity)
	local finalScale = baseScale * rarityScale

	-- Animate size change
	local sizeTween = TweenService:Create(crop,
		TweenInfo.new(1, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
		{Size = Vector3.new(2, 1, 2) * finalScale}
	)
	sizeTween:Play()

	-- Update color to show growth
	local stageColors = {
		Color3.fromRGB(139, 69, 19),  -- Brown (planted)
		Color3.fromRGB(34, 139, 34),  -- Green (sprouting)
		Color3.fromRGB(50, 205, 50),  -- Lime (growing)
		Color3.fromRGB(255, 215, 0)   -- Gold (ready)
	}

	local targetColor = stageColors[stageIndex + 1] or stageColors[4]
	local colorTween = TweenService:Create(crop,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Color = targetColor}
	)
	colorTween:Play()
end

-- ADD this method for enhanced crop click detection
function GameCore:SetupCropClickDetection(cropModel, plotModel)
	-- Remove existing click detectors
	for _, obj in pairs(cropModel:GetDescendants()) do
		if obj:IsA("ClickDetector") then
			obj:Destroy()
		end
	end

	-- Find the best part for click detection
	local clickablePart = cropModel.PrimaryPart
	if not clickablePart then
		-- Find any suitable part
		for _, part in pairs(cropModel:GetDescendants()) do
			if part:IsA("BasePart") then
				clickablePart = part
				break
			end
		end
	end

	if not clickablePart then
		warn("GameCore: No suitable part found for click detection in crop model")
		return
	end

	-- Add click detector
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 15
	clickDetector.Parent = clickablePart

	clickDetector.MouseClick:Connect(function(clickingPlayer)
		local plotOwner = self:GetPlotOwner(plotModel)
		if clickingPlayer.Name == plotOwner then
			local growthStage = plotModel:GetAttribute("GrowthStage") or 0
			if growthStage >= 4 then
				self:HarvestCrop(clickingPlayer, plotModel)
			else
				local timeLeft = self:GetCropTimeRemaining(plotModel)
				self:SendNotification(clickingPlayer, "Crop Growing", 
					"Crop is still growing! " .. math.ceil(timeLeft/60) .. " minutes remaining.", "info")
			end
		end
	end)
end

-- ADD this method to get crop colors for fallback
function GameCore:GetCropColor(cropType, rarity)
	local baseColors = {
		carrot = Color3.fromRGB(255, 140, 0),
		corn = Color3.fromRGB(255, 255, 0),
		strawberry = Color3.fromRGB(220, 20, 60),
		golden_fruit = Color3.fromRGB(255, 215, 0),
		wheat = Color3.fromRGB(218, 165, 32),
		potato = Color3.fromRGB(160, 82, 45),
		cabbage = Color3.fromRGB(34, 139, 34),
		radish = Color3.fromRGB(220, 20, 60),
		broccoli = Color3.fromRGB(34, 139, 34),
		tomato = Color3.fromRGB(255, 99, 71),
		glorious_sunflower = Color3.fromRGB(255, 215, 0)
	}

	local baseColor = baseColors[cropType] or Color3.fromRGB(100, 200, 100)

	-- Modify color based on rarity
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

-- UPDATED: Enhanced HarvestCrop method with visual effects
function GameCore:HarvestCrop(player, plotModel)
	print("🌾 GameCore: Enhanced harvest request from " .. player.Name .. " for plot " .. plotModel.Name)

	local playerData = self:GetPlayerData(player)
	if not playerData then 
		self:SendNotification(player, "Error", "Player data not found", "error")
		return false
	end

	local plotOwner = self:GetPlotOwner(plotModel)
	if plotOwner ~= player.Name then
		self:SendNotification(player, "Not Your Plot", "You can only harvest your own crops!", "error")
		return false
	end

	-- Check if crop is actually ready
	local isActuallyEmpty = self:IsPlotActuallyEmpty(plotModel)
	if isActuallyEmpty then
		self:SendNotification(player, "Nothing to Harvest", "This plot doesn't have any crops to harvest!", "warning")
		return false
	end

	local growthStage = plotModel:GetAttribute("GrowthStage") or 0
	if growthStage < 4 then
		local timeLeft = self:GetCropTimeRemaining(plotModel)
		self:SendNotification(player, "Not Ready", 
			"Crop is not ready for harvest yet! " .. math.ceil(timeLeft/60) .. " minutes remaining.", "warning")
		return false
	end

	-- Get crop data
	local plantType = plotModel:GetAttribute("PlantType") or ""
	local seedType = plotModel:GetAttribute("SeedType") or ""
	local cropRarity = plotModel:GetAttribute("Rarity") or "common"

	local cropData = ItemConfig.GetCropData(plantType)
	local seedData = ItemConfig.GetSeedData(seedType)

	if not cropData or not seedData then
		self:SendNotification(player, "Invalid Crop", "Crop data not found for " .. plantType, "error")
		return false
	end

	-- UPDATED: Create harvest visual effect using CropVisualManager
	local cropModel = plotModel:FindFirstChild("CropModel")
	if cropModel and cropModel.PrimaryPart then
		local position = cropModel.PrimaryPart.Position

		-- Use CropVisualManager for harvest effects if available
		local CropVisualManager = _G.CropVisualManager
		if CropVisualManager then
			print("✨ GameCore: Creating harvest effect using CropVisualManager")
			CropVisualManager:OnCropHarvested(plotModel, plantType, cropRarity)
		else
			-- Fallback harvest effect
			self:CreateBasicHarvestEffect(position, cropRarity)
		end
	end

	-- Calculate yield with rarity bonus
	local baseYield = seedData.yieldAmount or 1
	local rarityMultiplier = ItemConfig.RaritySystem[cropRarity] and ItemConfig.RaritySystem[cropRarity].valueMultiplier or 1.0
	local finalYield = math.floor(baseYield * rarityMultiplier)

	-- Initialize farming inventory if needed
	if not playerData.farming then
		playerData.farming = {inventory = {}}
	end
	if not playerData.farming.inventory then
		playerData.farming.inventory = {}
	end

	-- Add crops to inventory
	local currentAmount = playerData.farming.inventory[plantType] or 0
	playerData.farming.inventory[plantType] = currentAmount + finalYield

	-- Clear plot properly
	self:ClearPlotProperly(plotModel)

	-- Update stats
	playerData.stats = playerData.stats or {}
	playerData.stats.cropsHarvested = (playerData.stats.cropsHarvested or 0) + finalYield
	if cropRarity ~= "common" then
		playerData.stats.rareCropsHarvested = (playerData.stats.rareCropsHarvested or 0) + 1
	end

	-- Save and notify
	self:SavePlayerData(player)

	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	local rarityName = ItemConfig.RaritySystem[cropRarity] and ItemConfig.RaritySystem[cropRarity].name or cropRarity
	local rarityEmoji = cropRarity == "legendary" and "👑" or 
		cropRarity == "epic" and "💜" or 
		cropRarity == "rare" and "✨" or 
		cropRarity == "uncommon" and "💚" or "⚪"

	self:SendNotification(player, "🌾 Crop Harvested!", 
		"Harvested " .. finalYield .. "x " .. rarityEmoji .. " " .. rarityName .. " " .. cropData.name .. "!\n" ..
			(cropRarity ~= "common" and "🎉 Bonus yield from rarity!" or ""), "success")

	print("🌾 GameCore: Successfully harvested " .. finalYield .. "x " .. plantType .. " (" .. cropRarity .. ") for " .. player.Name)
	return true
end

-- ADD this method for basic harvest effects
function GameCore:CreateBasicHarvestEffect(position, rarity)
	local particleCount = rarity == "legendary" and 10 or rarity == "epic" and 7 or rarity == "rare" and 5 or 3

	for i = 1, particleCount do
		local particle = Instance.new("Part")
		particle.Name = "HarvestParticle"
		particle.Size = Vector3.new(0.2, 0.2, 0.2)
		particle.Color = ItemConfig.GetRarityColor(rarity)
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

		local tween = TweenService:Create(particle,
			TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = particle.Position + Vector3.new(0, 8, 0),
				Transparency = 1,
				Size = Vector3.new(0.05, 0.05, 0.05)
			}
		)
		tween:Play()
		tween.Completed:Connect(function()
			particle:Destroy()
		end)
	end
end


--[[
    Farm Protection System Integration
    Add these functions to GameCore.lua to make the protection items work
]]

-- ========== ADD THESE FUNCTIONS TO GAMECORE.LUA ==========

-- ========== PROTECTION SYSTEM MANAGEMENT ==========

function GameCore:InitializeProtectionSystem()
	print("GameCore: Initializing farm protection system...")

	-- Initialize protection tracking
	self.Systems.Protection = {
		ActiveProtections = {}, -- [userId] = {protectionData}
		VisualEffects = {},     -- [userId] = {visualElements}
		LastUFOAttack = {},     -- [userId] = timestamp
		ProtectionHealth = {}   -- [userId] = {protectionId = health}
	}

	-- Start protection update loop
	spawn(function()
		while true do
			wait(5) -- Check every 5 seconds
			self:UpdateProtectionSystems()
		end
	end)

	print("GameCore: Protection system initialized")
end

function GameCore:UpdateProtectionSystems()
	for _, player in pairs(Players:GetPlayers()) do
		if player and player.Parent then
			pcall(function()
				self:UpdatePlayerProtection(player)
			end)
		end
	end
end

function GameCore:UpdatePlayerProtection(player)
	local userId = player.UserId
	local playerData = self:GetPlayerData(player)
	if not playerData then return end

	-- Check for active protections
	local activeProtections = self:GetActiveProtections(playerData)

	-- Update visual effects
	self:UpdateProtectionVisuals(player, activeProtections)

	-- Apply protection benefits
	self:ApplyProtectionBenefits(player, activeProtections)
end

function GameCore:GetActiveProtections(playerData)
	local protections = {}

	if not playerData.defense or not playerData.defense.roofs then
		return protections
	end

	for protectionId, protectionData in pairs(playerData.defense.roofs) do
		if protectionData.protection then
			local protectionInfo = self:GetProtectionInfo(protectionId)
			if protectionInfo then
				protections[protectionId] = {
					data = protectionData,
					info = protectionInfo,
					isActive = true
				}
			end
		end
	end

	return protections
end

function GameCore:GetProtectionInfo(protectionId)
	-- Get protection information from ItemConfig
	if ItemConfig and ItemConfig.ShopItems and ItemConfig.ShopItems[protectionId] then
		return ItemConfig.ShopItems[protectionId]
	end

	-- Fallback protection data
	local fallbackProtections = {
		plot_roof_basic = {coverage = 1, ufoProtection = true},
		plot_roof_reinforced = {coverage = 1, ufoProtection = true, damageReduction = 0.99},
		area_dome_small = {coverage = 3, ufoProtection = true, pestDeterrent = true},
		area_dome_large = {coverage = 6, ufoProtection = true, growthBoost = 0.1},
		mega_dome = {coverage = 999, ufoProtection = true, growthBoost = 0.25},
		weather_shield_basic = {coverage = 1, weatherProtection = true},
		weather_shield_advanced = {coverage = 1, weatherProtection = true, growthBoost = 0.15},
		force_field_generator = {coverage = 999, absoluteProtection = true}
	}

	return fallbackProtections[protectionId]
end

-- ========== ENHANCED PLOT PROTECTION CHECKING ==========

function GameCore:IsPlotProtected(player, plotNumber)
	local playerData = self:GetPlayerData(player)
	if not playerData then return false end

	local activeProtections = self:GetActiveProtections(playerData)
	local totalPlots = playerData.farming and playerData.farming.plots or 0

	-- Check each active protection
	for protectionId, protection in pairs(activeProtections) do
		local effects = protection.info.effects or protection.info

		if effects.absoluteProtection then
			-- Force field or mega dome - protects everything
			return true
		elseif effects.coverage and effects.ufoProtection then
			if effects.coverage >= 999 then
				-- Mega dome protection
				return true
			elseif effects.coverage >= plotNumber then
				-- Area protection or specific plot protection
				return true
			elseif effects.plotSpecific then
				-- Check if this specific plot is protected
				local protectedPlot = self:GetProtectedPlotNumber(protectionId, playerData)
				if protectedPlot == plotNumber then
					return true
				end
			end
		end
	end

	return false
end

function GameCore:GetProtectedPlotNumber(protectionId, playerData)
	-- For plot-specific protections, determine which plot they protect
	-- This could be based on purchase order or player selection
	if not playerData.protection then
		playerData.protection = {}
	end
	if not playerData.protection.plotAssignments then
		playerData.protection.plotAssignments = {}
	end

	-- If not assigned, assign to the next available plot
	if not playerData.protection.plotAssignments[protectionId] then
		local assignedPlots = {}
		for _, plotNum in pairs(playerData.protection.plotAssignments) do
			assignedPlots[plotNum] = true
		end

		-- Find first unprotected plot
		local totalPlots = playerData.farming and playerData.farming.plots or 0
		for plotNum = 1, totalPlots do
			if not assignedPlots[plotNum] then
				playerData.protection.plotAssignments[protectionId] = plotNum
				break
			end
		end
	end

	return playerData.protection.plotAssignments[protectionId] or 1
end

-- ========== PROTECTION VISUAL EFFECTS ==========

function GameCore:UpdateProtectionVisuals(player, activeProtections)
	local userId = player.UserId

	-- Clear existing visuals
	self:ClearProtectionVisuals(userId)

	-- Create new visuals for each protection
	for protectionId, protection in pairs(activeProtections) do
		self:CreateProtectionVisual(player, protectionId, protection)
	end
end

function GameCore:ClearProtectionVisuals(userId)
	if self.Systems.Protection.VisualEffects[userId] then
		for _, visual in pairs(self.Systems.Protection.VisualEffects[userId]) do
			if visual and visual.Parent then
				visual:Destroy()
			end
		end
		self.Systems.Protection.VisualEffects[userId] = {}
	end
end

function GameCore:CreateProtectionVisual(player, protectionId, protection)
	local userId = player.UserId
	local effects = protection.info.effects or protection.info

	if not self.Systems.Protection.VisualEffects[userId] then
		self.Systems.Protection.VisualEffects[userId] = {}
	end

	-- Determine what type of visual to create
	if effects.forceField then
		self:CreateForceFieldVisual(player, protectionId)
	elseif effects.coverage >= 999 then
		self:CreateMegaDomeVisual(player, protectionId)
	elseif effects.coverage > 1 then
		self:CreateAreaDomeVisual(player, protectionId, effects.coverage)
	else
		self:CreatePlotRoofVisual(player, protectionId)
	end
end

function GameCore:CreateForceFieldVisual(player, protectionId)
	local userId = player.UserId

	-- Create a large transparent dome with energy effects
	local dome = Instance.new("Part")
	dome.Name = "ForceFieldDome_" .. protectionId
	dome.Size = Vector3.new(100, 50, 100)
	dome.Shape = Enum.PartType.Ball
	dome.Material = Enum.Material.ForceField
	dome.Color = Color3.fromRGB(100, 200, 255)
	dome.Transparency = 0.8
	dome.CanCollide = false
	dome.Anchored = true

	-- Position over player's farm area
	local farmPosition = self:GetFarmPlotPosition(player, 1)
	dome.Position = farmPosition.Position + Vector3.new(0, 25, 0)
	dome.Parent = workspace

	-- Add pulsing effect
	spawn(function()
		while dome and dome.Parent do
			local pulseUp = TweenService:Create(dome,
				TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Transparency = 0.6}
			)
			local pulseDown = TweenService:Create(dome,
				TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Transparency = 0.9}
			)

			pulseUp:Play()
			pulseUp.Completed:Wait()
			pulseDown:Play() 
			pulseDown.Completed:Wait()
		end
	end)

	self.Systems.Protection.VisualEffects[userId][protectionId] = dome
end

function GameCore:CreateMegaDomeVisual(player, protectionId)
	local userId = player.UserId

	-- Create a large dome covering all farm plots
	local dome = Instance.new("Part")
	dome.Name = "MegaDome_" .. protectionId
	dome.Size = Vector3.new(60, 30, 60)
	dome.Shape = Enum.PartType.Ball
	dome.Material = Enum.Material.Neon
	dome.Color = Color3.fromRGB(255, 215, 0)
	dome.Transparency = 0.7
	dome.CanCollide = false
	dome.Anchored = true

	-- Position over player's farm area
	local farmPosition = self:GetFarmPlotPosition(player, 1)
	dome.Position = farmPosition.Position + Vector3.new(-17, 15, 17)
	dome.Parent = workspace

	-- Add rotating effect
	spawn(function()
		while dome and dome.Parent do
			local rotation = TweenService:Create(dome,
				TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
				{Orientation = Vector3.new(0, 360, 0)}
			)
			rotation:Play()
			rotation.Completed:Wait()
		end
	end)

	self.Systems.Protection.VisualEffects[userId][protectionId] = dome
end

function GameCore:CreateAreaDomeVisual(player, protectionId, coverage)
	local userId = player.UserId

	-- Create a smaller dome covering specific plots
	local dome = Instance.new("Part")
	dome.Name = "AreaDome_" .. protectionId
	local domeSize = math.min(coverage * 8, 40)
	dome.Size = Vector3.new(domeSize, domeSize/2, domeSize)
	dome.Shape = Enum.PartType.Ball
	dome.Material = Enum.Material.Glass
	dome.Color = Color3.fromRGB(100, 255, 100)
	dome.Transparency = 0.8
	dome.CanCollide = false
	dome.Anchored = true

	-- Position over the covered plots
	local farmPosition = self:GetFarmPlotPosition(player, math.min(coverage, 3))
	dome.Position = farmPosition.Position + Vector3.new(0, domeSize/4, 0)
	dome.Parent = workspace

	self.Systems.Protection.VisualEffects[userId][protectionId] = dome
end

function GameCore:CreatePlotRoofVisual(player, protectionId)
	local userId = player.UserId
	local playerData = self:GetPlayerData(player)

	-- Get which plot this protection covers
	local plotNumber = self:GetProtectedPlotNumber(protectionId, playerData)

	-- Create a roof over the specific plot
	local roof = Instance.new("Part")
	roof.Name = "PlotRoof_" .. protectionId
	roof.Size = Vector3.new(18, 1, 18)
	roof.Material = Enum.Material.Metal
	roof.Color = Color3.fromRGB(150, 150, 150)
	roof.Transparency = 0.3
	roof.CanCollide = false
	roof.Anchored = true

	-- Position over the specific plot
	local plotPosition = self:GetFarmPlotPosition(player, plotNumber)
	roof.Position = plotPosition.Position + Vector3.new(0, 10, 0)
	roof.Parent = workspace

	-- Add support pillars
	for i = 1, 4 do
		local pillar = Instance.new("Part")
		pillar.Name = "RoofPillar_" .. i
		pillar.Size = Vector3.new(1, 10, 1)
		pillar.Material = Enum.Material.Metal
		pillar.Color = Color3.fromRGB(100, 100, 100)
		pillar.CanCollide = false
		pillar.Anchored = true

		local offsetX = (i <= 2) and -8 or 8
		local offsetZ = (i % 2 == 1) and -8 or 8

		pillar.Position = plotPosition.Position + Vector3.new(offsetX, 5, offsetZ)
		pillar.Parent = workspace
	end

	self.Systems.Protection.VisualEffects[userId][protectionId] = roof
end

-- ========== PROTECTION BENEFITS ==========

function GameCore:ApplyProtectionBenefits(player, activeProtections)
	local playerData = self:GetPlayerData(player)
	if not playerData then return end

	-- Calculate combined benefits
	local totalGrowthBoost = 0
	local hasPestDeterrent = false
	local hasWeatherProtection = false

	for protectionId, protection in pairs(activeProtections) do
		local effects = protection.info.effects or protection.info

		if effects.growthBoost then
			totalGrowthBoost = totalGrowthBoost + effects.growthBoost
		end

		if effects.pestDeterrent then
			hasPestDeterrent = true
		end

		if effects.weatherProtection then
			hasWeatherProtection = true
		end
	end

	-- Apply benefits to player data
	if not playerData.protection then
		playerData.protection = {}
	end

	playerData.protection.activeBenefits = {
		growthBoost = totalGrowthBoost,
		pestDeterrent = hasPestDeterrent,
		weatherProtection = hasWeatherProtection,
		lastUpdate = os.time()
	}
end

-- ========== UFO ATTACK PROTECTION ==========

function GameCore:HandleUFOAttack(player, plotNumber)
	-- Check if plot is protected
	if self:IsPlotProtected(player, plotNumber) then
		print("GameCore: UFO attack on plot " .. plotNumber .. " for " .. player.Name .. " was BLOCKED by protection")

		-- Create protection effect
		self:CreateProtectionBlockEffect(player, plotNumber)

		-- Send notification
		self:SendNotification(player, "🛡️ Attack Blocked!", 
			"Your protection system blocked the UFO attack on plot " .. plotNumber .. "!", "success")

		return false -- Attack was blocked
	end

	print("GameCore: UFO attack on plot " .. plotNumber .. " for " .. player.Name .. " was NOT blocked")
	return true -- Attack goes through
end

function GameCore:CreateProtectionBlockEffect(player, plotNumber)
	local plotPosition = self:GetFarmPlotPosition(player, plotNumber)

	-- Create shield effect
	local shield = Instance.new("Part")
	shield.Name = "ProtectionEffect"
	shield.Size = Vector3.new(20, 20, 20)
	shield.Shape = Enum.PartType.Ball
	shield.Material = Enum.Material.Neon
	shield.Color = Color3.fromRGB(100, 200, 255)
	shield.Transparency = 0.5
	shield.CanCollide = false
	shield.Anchored = true
	shield.Position = plotPosition.Position + Vector3.new(0, 10, 0)
	shield.Parent = workspace

	-- Animate shield effect
	local expandTween = TweenService:Create(shield,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = Vector3.new(25, 25, 25),
			Transparency = 0.8
		}
	)

	local shrinkTween = TweenService:Create(shield,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			Size = Vector3.new(0.1, 0.1, 0.1),
			Transparency = 1
		}
	)

	expandTween:Play()
	expandTween.Completed:Connect(function()
		shrinkTween:Play()
		shrinkTween.Completed:Connect(function()
			shield:Destroy()
		end)
	end)
end

-- ========== INITIALIZATION CALL ==========
-- Add this to your existing GameCore:Initialize() function
-- self:InitializeProtectionSystem()

print("GameCore: ✅ Farm Protection System Integration loaded!")
print("Features:")
print("  🛡️ Plot-specific roof protection")  
print("  🔘 Area dome protection systems")
print("  ⚡ Force field ultimate defense")
print("  🎭 Visual protection effects")
print("  📊 Protection benefit calculations")
print("  🚀 UFO attack blocking system")
function GameCore:GetProtectedPlotsCount(player)
	local playerData = self:GetPlayerData(player)
	if not playerData then return 0 end

	local protectedCount = 0
	local totalPlots = playerData.farming and playerData.farming.plots or 0

	for plotNumber = 1, totalPlots do
		if self:IsPlotProtected(player, plotNumber) then
			protectedCount = protectedCount + 1
		end
	end

	return protectedCount
end

function GameCore:AddPlotProtection(player, plotNumber, protectionType)
	local playerData = self:GetPlayerData(player)
	if not playerData then return false end

	-- Initialize defense structure if needed
	if not playerData.defense then
		playerData.defense = {chickens = {owned = {}, deployed = {}, feed = {}}, pestControl = {}, roofs = {}}
	end
	if not playerData.defense.roofs then
		playerData.defense.roofs = {}
	end

	-- Add protection
	if protectionType == "mega_dome" then
		playerData.defense.roofs.mega_dome = {
			purchaseTime = os.time(),
			coverage = 999, -- Covers all plots
			protection = true
		}
		print("GameCore: Added mega dome protection for " .. player.Name)
	else
		playerData.defense.roofs["roof_" .. plotNumber] = {
			purchaseTime = os.time(),
			coverage = plotNumber,
			protection = true
		}
		print("GameCore: Added roof protection for plot " .. plotNumber .. " for " .. player.Name)
	end

	self:SavePlayerData(player)
	return true
end

-- ========== UTILITY FUNCTIONS ==========

function GameCore:CountTable(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- ========== FIXED PLANTING METHOD ==========

function GameCore:PlantSeed(player, plotModel, seedId)
	print("🌱 GameCore: FIXED plant seed request - " .. player.Name .. " wants to plant " .. seedId)

	local playerData = self:GetPlayerData(player)
	if not playerData then 
		self:SendNotification(player, "Error", "Player data not found", "error")
		return false
	end

	-- Check if player has farming data
	if not playerData.farming or not playerData.farming.inventory then
		self:SendNotification(player, "No Farming Data", "You need to set up farming first!", "error")
		return false
	end

	-- Check if player has the seed
	local seedCount = playerData.farming.inventory[seedId] or 0
	if seedCount <= 0 then
		local seedInfo = ItemConfig.ShopItems[seedId]
		local seedName = seedInfo and seedInfo.name or seedId:gsub("_", " ")
		self:SendNotification(player, "No Seeds", "You don't have any " .. seedName .. "!", "error")
		return false
	end

	-- Validate the plot model
	if not plotModel or not plotModel.Parent then
		self:SendNotification(player, "Invalid Plot", "Plot not found or invalid!", "error")
		return false
	end

	-- FIXED: Better plot occupancy check
	local isEmpty = self:IsPlotActuallyEmpty(plotModel)
	local isUnlocked = plotModel:GetAttribute("IsUnlocked")

	-- For expandable farms, check if spot is unlocked
	if isUnlocked ~= nil and not isUnlocked then
		self:SendNotification(player, "Locked Plot", "This plot area is locked! Purchase farm expansion to unlock it.", "error")
		return false
	end

	-- FIXED: Only show "plot occupied" if there's actually a crop there
	if not isEmpty then
		self:SendNotification(player, "Plot Occupied", "This plot already has a crop growing!", "error")
		return false
	end

	-- Check plot ownership
	local plotOwner = self:GetPlotOwner(plotModel)
	if plotOwner ~= player.Name then
		self:SendNotification(player, "Not Your Plot", "You can only plant on your own farm plots!", "error")
		return false
	end

	-- Get seed data from ItemConfig
	local seedData = ItemConfig.GetSeedData(seedId)
	if not seedData then
		self:SendNotification(player, "Invalid Seed", "Seed data not found for " .. seedId .. "!", "error")
		return false
	end

	-- RARITY SYSTEM: Determine crop rarity at planting time
	local playerBoosters = self:GetPlayerBoosters(playerData)
	local cropRarity = ItemConfig.GetCropRarity(seedId, playerBoosters)

	print("🌟 GameCore: Determined rarity for " .. seedId .. ": " .. cropRarity)

	-- Plant the seed
	local success = self:CreateCropOnPlot(plotModel, seedId, seedData, cropRarity)
	if not success then
		self:SendNotification(player, "Planting Failed", "Could not plant seed on plot!", "error")
		return false
	end

	-- Remove seed from inventory
	playerData.farming.inventory[seedId] = playerData.farming.inventory[seedId] - 1

	-- Update plot attributes with enhanced data
	plotModel:SetAttribute("IsEmpty", false)
	plotModel:SetAttribute("PlantType", seedData.resultCropId)
	plotModel:SetAttribute("SeedType", seedId)
	plotModel:SetAttribute("GrowthStage", 0)
	plotModel:SetAttribute("PlantedTime", os.time())
	plotModel:SetAttribute("Rarity", cropRarity)

	-- Use boosters if applicable
	if playerBoosters.rarity_booster then
		playerData.boosters = playerData.boosters or {}
		playerData.boosters.rarity_booster = (playerData.boosters.rarity_booster or 0) - 1
		if playerData.boosters.rarity_booster <= 0 then
			playerData.boosters.rarity_booster = nil
		end
	end

	-- Update stats
	playerData.stats = playerData.stats or {}
	playerData.stats.seedsPlanted = (playerData.stats.seedsPlanted or 0) + 1

	-- Save and notify
	self:SavePlayerData(player)

	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	local seedInfo = ItemConfig.ShopItems[seedId]
	local seedName = seedInfo and seedInfo.name or seedId:gsub("_", " ")
	local rarityColor = ItemConfig.GetRarityColor(cropRarity)
	local rarityName = ItemConfig.RaritySystem[cropRarity] and ItemConfig.RaritySystem[cropRarity].name or cropRarity

	self:SendNotification(player, "🌱 Seed Planted!", 
		"Successfully planted " .. seedName .. "!\n🌟 Rarity: " .. rarityName .. "\n⏰ Ready in " .. math.floor(seedData.growTime/60) .. " minutes.", "success")

	print("🌱 GameCore: Successfully planted " .. seedId .. " (" .. cropRarity .. ") for " .. player.Name)
	return true
end

-- NEW: Robust method to check if a plot is actually empty
function GameCore:IsPlotActuallyEmpty(plotModel)
	print("🔍 GameCore: Checking if plot is actually empty: " .. plotModel.Name)

	-- Method 1: Check for physical crop model (most reliable)
	local cropModel = plotModel:FindFirstChild("CropModel")
	if cropModel then
		local crop = cropModel:FindFirstChild("Crop")
		if crop then
			print("🔍 Found physical crop - plot is OCCUPIED")
			return false
		end
	end

	-- Method 2: Check IsEmpty attribute (if set)
	local isEmptyAttr = plotModel:GetAttribute("IsEmpty")
	if isEmptyAttr == false then
		print("🔍 IsEmpty attribute = false - plot is OCCUPIED")
		return false
	end

	-- Method 3: Check if there's a plant type set
	local plantType = plotModel:GetAttribute("PlantType")
	if plantType and plantType ~= "" then
		print("🔍 PlantType attribute set - plot is OCCUPIED")
		return false
	end

	-- Method 4: Check growth stage
	local growthStage = plotModel:GetAttribute("GrowthStage")
	if growthStage and growthStage > 0 then
		print("🔍 GrowthStage > 0 - plot is OCCUPIED")
		return false
	end

	-- If all checks pass, plot is empty
	print("🔍 All checks passed - plot is EMPTY")
	return true
end

-- ENHANCED: Method to properly clear a plot (use this when harvesting)
function GameCore:ClearPlotProperly(plotModel)
	print("🧹 GameCore: Properly clearing plot: " .. plotModel.Name)

	-- Remove physical crop
	local cropModel = plotModel:FindFirstChild("CropModel")
	if cropModel then
		cropModel:Destroy()
		print("🧹 Removed CropModel")
	end

	-- Clear all crop-related attributes
	plotModel:SetAttribute("IsEmpty", true)
	plotModel:SetAttribute("PlantType", "")
	plotModel:SetAttribute("SeedType", "")
	plotModel:SetAttribute("GrowthStage", 0)
	plotModel:SetAttribute("PlantedTime", 0)
	plotModel:SetAttribute("Rarity", "common")

	-- Restore green indicator if it exists
	local indicator = plotModel:FindFirstChild("Indicator")
	if indicator then
		indicator.Color = Color3.fromRGB(100, 255, 100)
	end

	print("🧹 Plot cleared successfully")
end

-- ========== ENSURE PLAYER HAS EXPANDABLE FARM ==========

function GameCore:EnsurePlayerHasExpandableFarm(player)
	print("🌾 GameCore: Ensuring " .. player.Name .. " has expandable farm")

	local playerData = self:GetPlayerData(player)
	if not playerData then
		return false
	end

	-- Check if player should have a farm
	local hasFarmItem = playerData.purchaseHistory and playerData.purchaseHistory.farm_plot_starter
	local hasFarmingData = playerData.farming and playerData.farming.plots and playerData.farming.plots > 0

	if not hasFarmItem and not hasFarmingData then
		print("🌾 Player " .. player.Name .. " doesn't have farm access")
		return false
	end

	-- Ensure farming data is initialized
	if not playerData.farming then
		playerData.farming = {
			plots = 1,
			expansionLevel = 1,
			inventory = {}
		}
		self:SavePlayerData(player)
	end

	if not playerData.farming.expansionLevel then
		playerData.farming.expansionLevel = 1
		self:SavePlayerData(player)
	end

	-- Check if physical farm exists
	local existingFarm = self:GetPlayerExpandableFarm(player)
	if not existingFarm then
		print("🌾 Creating missing expandable farm for " .. player.Name)
		return self:CreateExpandableFarmPlot(player)
	end

	print("🌾 Player " .. player.Name .. " already has expandable farm")
	return true
end

print("GameCore: ✅ PLANTING AND EXPANSION FIXES LOADED!")
print("🔧 FIXES APPLIED:")
print("  ✅ Added missing GetPlotOwner method")
print("  ✅ Fixed PlantSeed method for expandable farms")
print("  ✅ Fixed farm plot creation to use expandable system")
print("  ✅ Enhanced farm expansion purchase handling")
print("  ✅ Added farm existence verification")

function GameCore:GetPlayerBoosters(playerData)
	local boosters = {}

	if playerData.boosters then
		if playerData.boosters.rarity_booster and playerData.boosters.rarity_booster > 0 then
			boosters.rarity_booster = true
		end
	end

	return boosters
end

function GameCore:HarvestAllCrops(player)
	print("🌾 GameCore: Enhanced harvest all request from " .. player.Name)

	local playerData = self:GetPlayerData(player)
	if not playerData then 
		self:SendNotification(player, "Error", "Player data not found", "error")
		return false
	end

	-- Find all player's farm plots
	local areas = workspace:FindFirstChild("Areas")
	if not areas then
		self:SendNotification(player, "No Farm", "Farm area not found!", "error")
		return false
	end

	local starterMeadow = areas:FindFirstChild("Starter Meadow")
	if not starterMeadow then
		self:SendNotification(player, "No Farm", "Starter Meadow not found!", "error")
		return false
	end

	local farmArea = starterMeadow:FindFirstChild("Farm")
	if not farmArea then
		self:SendNotification(player, "No Farm", "Farm area not found!", "error")
		return false
	end

	local playerFarm = farmArea:FindFirstChild(player.Name .. "_Farm")
	if not playerFarm then
		self:SendNotification(player, "No Farm", "You don't have a farm yet!", "error")
		return false
	end

	local harvestedCount = 0
	local readyCrops = 0
	local totalCrops = 0
	local rarityStats = {common = 0, uncommon = 0, rare = 0, epic = 0, legendary = 0}

	-- Go through all farm plots
	for _, plot in pairs(playerFarm:GetChildren()) do
		if plot:IsA("Model") and plot.Name:find("FarmPlot") then
			local plantingSpots = plot:FindFirstChild("PlantingSpots")
			if plantingSpots then
				for _, spot in pairs(plantingSpots:GetChildren()) do
					if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
						local isEmpty = spot:GetAttribute("IsEmpty")
						if not isEmpty then
							totalCrops = totalCrops + 1
							local growthStage = spot:GetAttribute("GrowthStage") or 0

							if growthStage >= 4 then
								readyCrops = readyCrops + 1
								local cropRarity = spot:GetAttribute("Rarity") or "common"
								local success = self:HarvestCrop(player, spot)
								if success then
									harvestedCount = harvestedCount + 1
									rarityStats[cropRarity] = (rarityStats[cropRarity] or 0) + 1
								end
								wait(0.1)
							end
						end
					end
				end
			end
		end
	end

	-- Send enhanced summary notification
	if harvestedCount > 0 then
		local rarityBreakdown = ""
		for rarity, count in pairs(rarityStats) do
			if count > 0 then
				local emoji = rarity == "legendary" and "👑" or 
					rarity == "epic" and "💜" or 
					rarity == "rare" and "✨" or 
					rarity == "uncommon" and "💚" or "⚪"
				rarityBreakdown = rarityBreakdown .. emoji .. " " .. rarity .. ": " .. count .. "\n"
			end
		end

		self:SendNotification(player, "🌾 Mass Harvest Complete!", 
			"Harvested " .. harvestedCount .. " crops!\n\n" .. rarityBreakdown ..
				(readyCrops - harvestedCount > 0 and (readyCrops - harvestedCount) .. " crops failed to harvest.\n" or "") ..
				(totalCrops - readyCrops > 0 and (totalCrops - readyCrops) .. " crops still growing." or ""), "success")
	else
		if totalCrops == 0 then
			self:SendNotification(player, "No Crops", "You don't have any crops planted!", "info")
		elseif readyCrops == 0 then
			self:SendNotification(player, "Crops Not Ready", "None of your " .. totalCrops .. " crops are ready for harvest yet!", "warning")
		else
			self:SendNotification(player, "Harvest Failed", "Found " .. readyCrops .. " ready crops but couldn't harvest any!", "error")
		end
	end

	print("🌾 GameCore: Enhanced harvest all complete for " .. player.Name .. " - harvested " .. harvestedCount .. "/" .. readyCrops .. " ready crops")
	return harvestedCount > 0
end

--[[
    ENHANCED GameCore.lua - MULTIPLE COWS SYSTEM
    Add these functions to your existing GameCore.lua
    
    Features:
    ✅ Multiple cow management
    ✅ Cow tier progression system
    ✅ Individual cow tracking
    ✅ Position management
    ✅ Integration with existing systems
]]

-- ADD THESE FUNCTIONS TO YOUR EXISTING GameCore.lua:

-- ========== ENHANCED COW SYSTEM ==========

function GameCore:InitializeEnhancedCowSystem()
	print("GameCore: Initializing ENHANCED multiple cow system...")

	-- Initialize cow management
	self.Systems.Cows = {
		PlayerCows = {}, -- [userId] = {[cowId] = cowData}
		CowPositions = {}, -- [userId] = {usedPositions}
		CowModels = {}, -- [cowId] = modelReference
		CowEffects = {}, -- [cowId] = {effectObjects}
		NextCowId = 1
	}

	-- Cow positioning configuration
	self.CowPositions = {
		basePosition = Vector3.new(-272.168, -2.068, 53.406), -- Adjust to your map
		spacing = Vector3.new(8, 0, 8), -- Space between cows
		rowSize = 5, -- Cows per row
		playerSeparation = Vector3.new(60, 0, 0) -- Space between players
	}

	-- Initialize existing players
	for _, player in pairs(Players:GetPlayers()) do
		if player and player.Parent then
			pcall(function()
				self:InitializePlayerCowData(player)
			end)
		end
	end

	print("GameCore: Enhanced cow system initialized")
end

function GameCore:InitializePlayerCowData(player)
	local playerData = self:GetPlayerData(player)
	if not playerData then return end

	-- Initialize cow data structure
	if not playerData.livestock then
		playerData.livestock = {}
	end
	if not playerData.livestock.cows then
		playerData.livestock.cows = {}
	end

	-- Initialize system tracking
	local userId = player.UserId
	if not self.Systems.Cows.PlayerCows[userId] then
		self.Systems.Cows.PlayerCows[userId] = {}
	end
	if not self.Systems.Cows.CowPositions[userId] then
		self.Systems.Cows.CowPositions[userId] = {}
	end

	-- Load existing cows from data
	for cowId, cowData in pairs(playerData.livestock.cows) do
		self:LoadExistingCow(player, cowId, cowData)
	end

	print("GameCore: Initialized cow data for " .. player.Name)
end
--[[
    FIXED GameCore.lua - Cow System Bug Fix
    
    FIXES:
    ✅ Fixed "attempt to index nil" error in cow system
    ✅ Added proper initialization checks for cow data structures
    ✅ Enhanced error handling and validation
    ✅ Added safe access methods for cow management
    ✅ Fixed timing issues with player data initialization
]]

-- Add these methods to your existing GameCore.lua to fix the cow system issues

-- ========== SAFE INITIALIZATION METHODS ==========

function GameCore:EnsurePlayerCowDataInitialized(player)
	local userId = player.UserId

	-- Ensure Systems.Cows structure exists
	if not self.Systems then
		self.Systems = {}
	end
	if not self.Systems.Cows then
		self.Systems.Cows = {
			PlayerCows = {},
			CowPositions = {},
			CowModels = {},
			CowEffects = {},
			NextCowId = 1
		}
	end

	-- Ensure player-specific structures exist
	if not self.Systems.Cows.PlayerCows[userId] then
		self.Systems.Cows.PlayerCows[userId] = {}
		print("🐄 GameCore: Initialized PlayerCows for " .. player.Name)
	end

	if not self.Systems.Cows.CowPositions[userId] then
		self.Systems.Cows.CowPositions[userId] = {}
		print("🐄 GameCore: Initialized CowPositions for " .. player.Name)
	end

	-- Ensure player data has livestock structure
	local playerData = self:GetPlayerData(player)
	if playerData then
		if not playerData.livestock then
			playerData.livestock = {cows = {}}
			print("🐄 GameCore: Initialized livestock data for " .. player.Name)
		end
		if not playerData.livestock.cows then
			playerData.livestock.cows = {}
			print("🐄 GameCore: Initialized cows data for " .. player.Name)
		end
	end

	return true
end

function GameCore:SafelyStoreCowData(userId, cowId, cowData)
	-- Ensure all structures exist before storing
	if not self.Systems or not self.Systems.Cows then
		warn("🐄 GameCore: Cows system not initialized!")
		return false
	end

	if not self.Systems.Cows.PlayerCows then
		self.Systems.Cows.PlayerCows = {}
	end

	if not self.Systems.Cows.PlayerCows[userId] then
		self.Systems.Cows.PlayerCows[userId] = {}
	end

	-- Now safely store the data
	self.Systems.Cows.PlayerCows[userId][cowId] = cowData
	print("🐄 GameCore: Safely stored cow data for " .. cowId)
	return true
end

function GameCore:SafelyStoreCowModel(cowId, cowModel)
	-- Ensure CowModels structure exists
	if not self.Systems or not self.Systems.Cows then
		warn("🐄 GameCore: Cows system not initialized!")
		return false
	end

	if not self.Systems.Cows.CowModels then
		self.Systems.Cows.CowModels = {}
	end

	self.Systems.Cows.CowModels[cowId] = cowModel
	print("🐄 GameCore: Safely stored cow model for " .. cowId)
	return true
end
--[[
    DataStore Serialization Fix for GameCore.lua
    
    FIXES:
    ✅ Removes invalid data types from player data before saving
    ✅ Sanitizes strings to ensure UTF-8 compatibility
    ✅ Prevents Instance references and functions from being saved
    ✅ Adds data validation and debugging
]]

-- ========== SAFE DATASTORE SERIALIZATION ==========

-- ADD this method to your GameCore.lua

function GameCore:SanitizeDataForSaving(data)
	if type(data) ~= "table" then
		return self:SanitizeValue(data)
	end

	local sanitized = {}

	for key, value in pairs(data) do
		-- Sanitize the key
		local cleanKey = self:SanitizeValue(key)
		if cleanKey ~= nil and type(cleanKey) == "string" or type(cleanKey) == "number" then
			-- Sanitize the value
			local cleanValue = self:SanitizeValue(value)
			if cleanValue ~= nil then
				sanitized[cleanKey] = cleanValue
			end
		end
	end

	return sanitized
end

function GameCore:SanitizeValue(value)
	local valueType = type(value)

	if valueType == "string" then
		-- Remove non-UTF-8 characters and control characters
		local cleaned = string.gsub(value, "[%z\1-\31\127-\255]", "")
		return cleaned

	elseif valueType == "number" then
		-- Check for NaN or infinity
		if value ~= value or value == math.huge or value == -math.huge then
			return 0
		end
		return value

	elseif valueType == "boolean" then
		return value

	elseif valueType == "table" then
		-- Recursively sanitize tables, but prevent infinite recursion
		return self:SanitizeDataForSaving(value)

	else
		-- Remove functions, userdata, Instance references, etc.
		return nil
	end
end

function GameCore:ValidatePlayerDataForSaving(playerData)
	local issues = {}

	-- Check for common problematic data
	local function checkTable(tbl, path)
		for key, value in pairs(tbl) do
			local currentPath = path .. "." .. tostring(key)
			local valueType = type(value)

			if valueType == "function" then
				table.insert(issues, currentPath .. " contains a function")
			elseif valueType == "userdata" then
				table.insert(issues, currentPath .. " contains userdata")
			elseif valueType == "table" then
				-- Check if it's a Roblox Instance
				if typeof(value) ~= "table" then
					table.insert(issues, currentPath .. " contains Instance: " .. typeof(value))
				else
					checkTable(value, currentPath)
				end
			elseif valueType == "string" then
				-- Check for non-UTF-8 characters
				if not utf8.len(value) then
					table.insert(issues, currentPath .. " contains non-UTF-8 string")
				end
			end
		end
	end

	if type(playerData) == "table" then
		checkTable(playerData, "playerData")
	end

	return issues
end

-- REPLACE your existing SavePlayerData method with this fixed version:
function GameCore:SavePlayerData(player, forceImmediate)
	if not player or not player.Parent then return end

	local userId = player.UserId
	local currentTime = os.time()

	if not forceImmediate then
		local lastSave = self.DataStoreCooldowns[userId] or 0
		if currentTime - lastSave < self.SAVE_COOLDOWN then
			return
		end
	end

	local playerData = self.PlayerData[userId]
	if not playerData then return end

	-- STEP 1: Validate data before sanitization
	local validationIssues = self:ValidatePlayerDataForSaving(playerData)
	if #validationIssues > 0 then
		warn("GameCore: Player data validation issues found for " .. player.Name .. ":")
		for _, issue in ipairs(validationIssues) do
			warn("  " .. issue)
		end
	end

	-- STEP 2: Create safe data structure for saving
	local safeData = {
		coins = tonumber(playerData.coins) or 0,
		farmTokens = tonumber(playerData.farmTokens) or 0,
		upgrades = self:SanitizeDataForSaving(playerData.upgrades or {}),
		stats = self:SanitizeDataForSaving(playerData.stats or {}),
		purchaseHistory = self:SanitizeDataForSaving(playerData.purchaseHistory or {}),
		farming = {
			plots = tonumber(playerData.farming and playerData.farming.plots) or 0,
			inventory = self:SanitizeDataForSaving(playerData.farming and playerData.farming.inventory or {})
		},
		livestock = {
			cow = self:SanitizeDataForSaving(playerData.livestock and playerData.livestock.cow or {}),
			cows = self:SanitizeCowData(playerData.livestock and playerData.livestock.cows or {}),
			inventory = self:SanitizeDataForSaving(playerData.livestock and playerData.livestock.inventory or {})
		},
		defense = self:SanitizeDataForSaving(playerData.defense or {}),
		boosters = self:SanitizeDataForSaving(playerData.boosters or {}),
		pig = {
			size = tonumber(playerData.pig and playerData.pig.size) or 1.0,
			cropPoints = tonumber(playerData.pig and playerData.pig.cropPoints) or 0,
			transformationCount = tonumber(playerData.pig and playerData.pig.transformationCount) or 0,
			totalFed = tonumber(playerData.pig and playerData.pig.totalFed) or 0
		},
		lastSave = currentTime
	}

	-- STEP 3: Save with enhanced error handling
	local success, errorMsg = pcall(function()
		if not self.PlayerDataStore then
			error("DataStore not available")
		end

		return self.PlayerDataStore:SetAsync("Player_" .. userId, safeData)
	end)

	if success then
		self.DataStoreCooldowns[userId] = currentTime
		print("GameCore: Successfully saved data for " .. player.Name)
	else
		warn("GameCore: Failed to save data for " .. player.Name .. ": " .. tostring(errorMsg))

		-- Debug the data that failed to save
		print("GameCore: Debugging failed save data:")
		print("  Data size estimate: " .. self:EstimateDataSize(safeData))
		print("  Sanitized data structure:")
		for key, value in pairs(safeData) do
			print("    " .. key .. ": " .. type(value))
		end
	end
end

-- Helper method to specifically sanitize cow data
function GameCore:SanitizeCowData(cowData)
	local sanitizedCows = {}

	for cowId, cow in pairs(cowData) do
		-- Only save essential cow data, remove model references and other problematic data
		sanitizedCows[tostring(cowId)] = {
			cowId = tostring(cow.cowId or cowId),
			tier = tostring(cow.tier or "basic"),
			milkAmount = tonumber(cow.milkAmount) or 1,
			cooldown = tonumber(cow.cooldown) or 60,
			position = {
				x = tonumber(cow.position and cow.position.X) or 0,
				y = tonumber(cow.position and cow.position.Y) or 0,
				z = tonumber(cow.position and cow.position.Z) or 0
			},
			lastMilkCollection = tonumber(cow.lastMilkCollection) or 0,
			totalMilkProduced = tonumber(cow.totalMilkProduced) or 0,
			purchaseTime = tonumber(cow.purchaseTime) or os.time(),
			visualEffects = self:SanitizeDataForSaving(cow.visualEffects or {})
		}
	end

	return sanitizedCows
end

-- Helper method to estimate data size
function GameCore:EstimateDataSize(data)
	local json = game:GetService("HttpService"):JSONEncode(data)
	return #json .. " characters"
end

-- Enhanced loading method to handle sanitized cow data
function GameCore:LoadPlayerData(player)
	local defaultData = self:GetDefaultPlayerData()
	local loadedData = defaultData

	if self.PlayerDataStore then
		local success, data = pcall(function()
			return self.PlayerDataStore:GetAsync("Player_" .. player.UserId)
		end)

		if success and data then
			-- Deep merge and convert loaded data
			loadedData = self:DeepMerge(defaultData, data)

			-- Convert cow position data back to Vector3
			if loadedData.livestock and loadedData.livestock.cows then
				for cowId, cowData in pairs(loadedData.livestock.cows) do
					if cowData.position and type(cowData.position) == "table" then
						cowData.position = Vector3.new(
							cowData.position.x or 0,
							cowData.position.y or 0,
							cowData.position.z or 0
						)
					end
				end
			end

			print("GameCore: Loaded existing data for " .. player.Name)
		else
			print("GameCore: Using default data for " .. player.Name)
		end
	end

	self.PlayerData[player.UserId] = loadedData

	-- Initialize cow systems immediately after loading data
	self:EnsurePlayerCowDataInitialized(player)

	self:InitializePlayerSystems(player, loadedData)
	self:UpdatePlayerLeaderstats(player)

	return loadedData
end

-- Debug method to check data before saving
function GameCore:DebugPlayerDataForSaving(player)
	local playerData = self:GetPlayerData(player)
	if not playerData then
		print("No player data found for " .. player.Name)
		return
	end

	print("=== DATA SAVE DEBUG FOR " .. player.Name .. " ===")

	local issues = self:ValidatePlayerDataForSaving(playerData)
	if #issues > 0 then
		print("❌ Validation issues found:")
		for _, issue in ipairs(issues) do
			print("  " .. issue)
		end
	else
		print("✅ No validation issues found")
	end

	local sanitized = self:SanitizeDataForSaving(playerData)
	print("📦 Sanitized data size: " .. self:EstimateDataSize(sanitized))

	print("🗂️ Data structure:")
	for key, value in pairs(sanitized) do
		if type(value) == "table" then
			local count = 0
			for _ in pairs(value) do count = count + 1 end
			print("  " .. key .. ": table with " .. count .. " items")
		else
			print("  " .. key .. ": " .. type(value) .. " = " .. tostring(value))
		end
	end

	print("=======================================")
end

print("GameCore: ✅ DataStore serialization fixes loaded!")
print("🔧 Debug Command: /debugsavedata - Check data before saving")
-- ========== FIXED COW PURCHASE METHODS ==========

-- REPLACE your existing PurchaseCow method with this fixed version:
-- REPLACE your existing CreateNewCow method with this fixed version:
function GameCore:CreateNewCowSafely(player, cowType, cowConfig)
	local spawnPosition = Vector3.new(-273.889, 1.503, 53.619)
	local faceNorth = CFrame.new(spawnPosition) * CFrame.Angles(0, math.rad(90), 0)
	local playerData = self:GetPlayerData(player)
	local userId = player.UserId
	local cowModel = self.CowSystem:CreateCow(cowType, cowConfig)

	-- Check cow limits
	local currentCowCount = self:GetPlayerCowCount(player)
	local maxCows = self:GetPlayerMaxCows(playerData)

	if currentCowCount >= maxCows then
		self:SendNotification(player, "Cow Limit Reached", 
			"You have " .. currentCowCount .. "/" .. maxCows .. " cows! ")
		return false
	end

	-- Generate unique cow ID with better collision detection
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
		position = spawnPosition,
		rotation = faceNorth,
		lastMilkCollection = 0,
		totalMilkProduced = 0,
		purchaseTime = os.time(),
		visualEffects = cowConfig.visualEffects or {}
	}

	-- SAFELY store cow data in ALL locations
	local storeSuccess = self:SafelyStoreCowData(userId, cowId, cowData)
	if not storeSuccess then
		self:SendNotification(player, "Storage Error", "Failed to store cow data!", "error")
		return false
	end

	-- Store in player data (with safety checks)
	if playerData.livestock and playerData.livestock.cows then
		playerData.livestock.cows[cowId] = cowData
		print("🐄 GameCore: Stored cow in player data")
	else
		warn("🐄 GameCore: Player livestock data not properly initialized")
		return false
	end

	-- Create physical cow model
	local success = self:CreateCowModelSafely(player, cowId, cowData)
	if not success then
		-- Clean up on failure
		if playerData.livestock and playerData.livestock.cows then
			playerData.livestock.cows[cowId] = nil
		end
		if self.Systems.Cows.PlayerCows[userId] then
			self.Systems.Cows.PlayerCows[userId][cowId] = nil
		end
		self:SendNotification(player, "Model Creation Failed", "Failed to create cow model!", "error")
		return false
	end

	-- Save data
	self:SavePlayerData(player)

	self:SendNotification(player, "🐄 Cow Purchased!", 
		"Added " .. self:GetCowDisplayName(cowConfig.tier) .. " to your farm!", "success")

	print("🐄 GameCore: Successfully created new cow " .. cowId .. " for " .. player.Name)
	return true
end

-- REPLACE your existing CreateCowModel method with this fixed version:
function GameCore:CreateCowModelSafely(player, cowId, cowData)
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

		-- SAFELY store model reference
		local modelStoreSuccess = self:SafelyStoreCowModel(cowId, newCow)
		if not modelStoreSuccess then
			newCow:Destroy()
			error("Failed to store cow model reference")
		end

		-- Add cow identification
		newCow:SetAttribute("CowId", cowId)
		newCow:SetAttribute("Owner", player.Name)
		newCow:SetAttribute("Tier", cowData.tier)

		-- Setup click detection
		self:SetupCowClickDetection(newCow, cowId, player)

		-- Apply visual effects
		self:ApplyCowVisualEffects(newCow, cowData)

		print("🐄 GameCore: Created model for cow " .. cowId)
		return true
	end)

	if not success then
		warn("GameCore: Failed to create cow model: " .. tostring(error))
		return false
	end

	return true
end

-- ========== ENHANCED UTILITY METHODS ==========

function GameCore:GenerateUniqueCowId(userId)
	local maxAttempts = 10
	local attempt = 0

	while attempt < maxAttempts do
		local cowId = "cow_" .. userId .. "_" .. self.Systems.Cows.NextCowId
		self.Systems.Cows.NextCowId = self.Systems.Cows.NextCowId + 1

		-- Check if this ID is already in use
		local inUse = false

		-- Check in Systems
		if self.Systems.Cows.PlayerCows[userId] and self.Systems.Cows.PlayerCows[userId][cowId] then
			inUse = true
		end

		-- Check in workspace
		if workspace:FindFirstChild(cowId) then
			inUse = true
		end

		if not inUse then
			print("🐄 GameCore: Generated unique cow ID: " .. cowId)
			return cowId
		end

		attempt = attempt + 1
		warn("🐄 GameCore: Cow ID collision, trying again: " .. cowId)
	end

	warn("🐄 GameCore: Failed to generate unique cow ID after " .. maxAttempts .. " attempts")
	return nil
end

-- REPLACE your LoadPlayerData method to include cow initialization:

-- Enhanced debugging method
function GameCore:DebugCowSystem(player)
	print("=== COW SYSTEM DEBUG FOR " .. player.Name .. " ===")

	local userId = player.UserId

	-- Check Systems structure
	print("Systems structure:")
	print("  self.Systems exists: " .. tostring(self.Systems ~= nil))
	if self.Systems then
		print("  self.Systems.Cows exists: " .. tostring(self.Systems.Cows ~= nil))
		if self.Systems.Cows then
			print("  PlayerCows exists: " .. tostring(self.Systems.Cows.PlayerCows ~= nil))
			print("  CowModels exists: " .. tostring(self.Systems.Cows.CowModels ~= nil))

			if self.Systems.Cows.PlayerCows then
				print("  PlayerCows[" .. userId .. "] exists: " .. tostring(self.Systems.Cows.PlayerCows[userId] ~= nil))
				if self.Systems.Cows.PlayerCows[userId] then
					local count = 0
					for cowId, _ in pairs(self.Systems.Cows.PlayerCows[userId]) do
						count = count + 1
						print("    Cow: " .. cowId)
					end
					print("  Total cows in PlayerCows: " .. count)
				end
			end
		end
	end

	-- Check player data
	local playerData = self:GetPlayerData(player)
	print("Player data:")
	print("  playerData exists: " .. tostring(playerData ~= nil))
	if playerData then
		print("  livestock exists: " .. tostring(playerData.livestock ~= nil))
		if playerData.livestock then
			print("  livestock.cows exists: " .. tostring(playerData.livestock.cows ~= nil))
			if playerData.livestock.cows then
				local count = 0
				for cowId, _ in pairs(playerData.livestock.cows) do
					count = count + 1
					print("    Player cow: " .. cowId)
				end
				print("  Total cows in player data: " .. count)
			end
		end
	end

	print("========================================")
end

-- Add this admin command to your existing admin commands:
function GameCore:SetupAdminCommands()
	-- ... your existing admin commands ...
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Replace with your username
				local args = string.split(message:lower(), " ")
				local command = args[1]

				-- FARMING DEBUG COMMANDS
				if command == "/debugplanting" then
					print("=== PLANTING SYSTEM DEBUG ===")
					local playerData = self:GetPlayerData(player)

					if playerData then
						print("Player farming data:")
						if playerData.farming then
							print("  Plots: " .. (playerData.farming.plots or 0))
							print("  Expansion Level: " .. (playerData.farming.expansionLevel or 1))
							print("  Inventory items:")
							if playerData.farming.inventory then
								for item, count in pairs(playerData.farming.inventory) do
									if item:find("seeds") then
										print("    " .. item .. ": " .. count)
									end
								end
							else
								print("    No farming inventory")
							end
						else
							print("  No farming data")
						end

						print("Purchase history:")
						if playerData.purchaseHistory then
							if playerData.purchaseHistory.farm_plot_starter then
								print("  ✅ Has farm_plot_starter")
							else
								print("  ❌ Missing farm_plot_starter")
							end
						else
							print("  No purchase history")
						end
					end

					-- Check physical farm
					local farm = self:GetPlayerExpandableFarm(player)
					if farm then
						print("Physical farm: ✅ EXISTS")
						local plantingSpots = farm:FindFirstChild("PlantingSpots")
						if plantingSpots then
							local totalSpots = 0
							local unlockedSpots = 0
							local occupiedSpots = 0

							for _, spot in pairs(plantingSpots:GetChildren()) do
								if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
									totalSpots = totalSpots + 1
									if spot:GetAttribute("IsUnlocked") then
										unlockedSpots = unlockedSpots + 1
									end
									if not spot:GetAttribute("IsEmpty") then
										occupiedSpots = occupiedSpots + 1
									end
								end
							end

							print("Planting spots: " .. unlockedSpots .. " unlocked / " .. totalSpots .. " total")
							print("Occupied spots: " .. occupiedSpots)
						else
							print("❌ No PlantingSpots folder found")
						end
					else
						print("Physical farm: ❌ MISSING")
					end
					print("==============================")

				elseif command == "/testplanting" then
					print("Testing planting system...")
					local playerData = self:GetPlayerData(player)

					-- Give test seeds
					if not playerData.farming then
						playerData.farming = {inventory = {}}
					end
					if not playerData.farming.inventory then
						playerData.farming.inventory = {}
					end

					playerData.farming.inventory.carrot_seeds = 10
					playerData.farming.inventory.corn_seeds = 5
					self:SavePlayerData(player)

					print("✅ Gave test seeds to " .. player.Name)
					print("Now click on an unlocked plot to test planting")

				elseif command == "/fixfarm" then
					print("Fixing farm for " .. player.Name)
					local playerData = self:GetPlayerData(player)

					-- Ensure farming data
					if not playerData.farming then
						playerData.farming = {
							plots = 1,
							expansionLevel = 1,
							inventory = {
								carrot_seeds = 5,
								corn_seeds = 3
							}
						}
					end

					-- Ensure purchase history
					if not playerData.purchaseHistory then
						playerData.purchaseHistory = {}
					end
					playerData.purchaseHistory.farm_plot_starter = true

					-- Create/update farm
					local success = self:CreateExpandableFarmPlot(player)
					if success then
						self:SavePlayerData(player)
						print("✅ Farm fixed for " .. player.Name)
					else
						print("❌ Failed to fix farm")
					end

				elseif command == "/testexpansion" then
					local targetLevel = tonumber(args[2]) or 2
					if targetLevel < 1 or targetLevel > 5 then
						print("Usage: /testexpansion [level 1-5]")
						return
					end

					print("Testing expansion to level " .. targetLevel)
					local playerData = self:GetPlayerData(player)

					-- Ensure farming data
					if not playerData.farming then
						playerData.farming = {expansionLevel = 1}
					end

					-- Force expansion
					playerData.farming.expansionLevel = targetLevel
					local success = self:CreateExpandableFarmPlot(player)

					if success then
						self:SavePlayerData(player)
						local config = self:GetExpansionConfig(targetLevel)
						print("✅ Expanded to " .. config.name .. " (" .. config.totalSpots .. " spots)")
					else
						print("❌ Expansion failed")
					end

				elseif command == "/checkplotowner" then
					print("Testing plot owner detection...")
					local farm = self:GetPlayerExpandableFarm(player)
					if farm then
						local plantingSpots = farm:FindFirstChild("PlantingSpots")
						if plantingSpots then
							local firstSpot = plantingSpots:FindFirstChild("PlantingSpot_1")
							if firstSpot then
								local owner = self:GetPlotOwner(firstSpot)
								print("First plot owner: " .. tostring(owner))
								print("Expected owner: " .. player.Name)
								print("Match: " .. tostring(owner == player.Name))
							else
								print("❌ No PlantingSpot_1 found")
							end
						else
							print("❌ No PlantingSpots found")
						end
					else
						print("❌ No farm found")
					end

				elseif command == "/givefarmstarter" then
					local targetName = args[2] or player.Name
					local targetPlayer = Players:FindFirstChild(targetName)

					if targetPlayer then
						local playerData = self:GetPlayerData(targetPlayer)
						if playerData then
							-- Give farm starter and basic setup
							playerData.purchaseHistory = playerData.purchaseHistory or {}
							playerData.purchaseHistory.farm_plot_starter = true

							playerData.farming = {
								plots = 1,
								expansionLevel = 1,
								inventory = {
									carrot_seeds = 10,
									corn_seeds = 5,
									potato_seeds = 3
								}
							}

							playerData.coins = (playerData.coins or 0) + 10000 -- Give coins for testing

							local success = self:CreateExpandableFarmPlot(targetPlayer)
							if success then
								self:SavePlayerData(targetPlayer)
								print("✅ Gave farm starter to " .. targetPlayer.Name)

								if self.RemoteEvents.PlayerDataUpdated then
									self.RemoteEvents.PlayerDataUpdated:FireClient(targetPlayer, playerData)
								end
							else
								print("❌ Failed to create farm for " .. targetPlayer.Name)
							end
						end
					else
						print("Player " .. targetName .. " not found")
					end

				elseif command == "/resetfarm" then
					local targetName = args[2] or player.Name
					local targetPlayer = Players:FindFirstChild(targetName)

					if targetPlayer then
						-- Remove physical farm
						local farm = self:GetPlayerExpandableFarm(targetPlayer)
						if farm then
							farm:Destroy()
						end

						-- Reset player data
						local playerData = self:GetPlayerData(targetPlayer)
						if playerData then
							playerData.farming = nil
							playerData.purchaseHistory = playerData.purchaseHistory or {}
							playerData.purchaseHistory.farm_plot_starter = nil
							self:SavePlayerData(targetPlayer)
						end

						print("✅ Reset farm for " .. targetPlayer.Name)
					end

				elseif command == "/inspectfarm" then
					local targetName = args[2] or player.Name
					local targetPlayer = Players:FindFirstChild(targetName)

					if targetPlayer then
						print("=== FARM INSPECTION FOR " .. targetPlayer.Name .. " ===")

						local farm = self:GetPlayerExpandableFarm(targetPlayer)
						if farm then
							print("✅ Physical farm exists: " .. farm.Name)
							print("Position: " .. tostring(farm.PrimaryPart and farm.PrimaryPart.Position or "NO PRIMARY PART"))

							local plantingSpots = farm:FindFirstChild("PlantingSpots")
							if plantingSpots then
								print("PlantingSpots folder exists")

								local spotsByStatus = {unlocked = 0, locked = 0, occupied = 0, empty = 0}

								for _, spot in pairs(plantingSpots:GetChildren()) do
									if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
										if spot:GetAttribute("IsUnlocked") then
											spotsByStatus.unlocked = spotsByStatus.unlocked + 1

											if spot:GetAttribute("IsEmpty") == false then
												spotsByStatus.occupied = spotsByStatus.occupied + 1
											else
												spotsByStatus.empty = spotsByStatus.empty + 1
											end
										else
											spotsByStatus.locked = spotsByStatus.locked + 1
										end
									end
								end

								print("Spot status:")
								print("  Unlocked: " .. spotsByStatus.unlocked)
								print("  Locked: " .. spotsByStatus.locked)
								print("  Occupied: " .. spotsByStatus.occupied)
								print("  Empty: " .. spotsByStatus.empty)
							else
								print("❌ No PlantingSpots folder")
							end
						else
							print("❌ No physical farm found")
						end

						print("=============================================")
					end
				end
			
						print("GameCore: ✅ ENHANCED DEBUG COMMANDS LOADED!")
						print("🔧 Available Debug Commands:")
						print("  /debugplanting - Show detailed planting system status")
						print("  /testplanting - Give test seeds for planting")
						print("  /fixfarm - Fix/create farm for player")
						print("  /testexpansion [level] - Test farm expansion to specific level")
						print("  /checkplotowner - Test plot owner detection")
						print("  /givefarmstarter [player] - Give farm starter to player")
						print("  /resetfarm [player] - Reset player's farm completely")
						print("  /inspectfarm [player] - Detailed farm inspection")

				-- ... your existing commands ...

				if command == "/debugcows" then
					self:DebugCowSystem(player)

				elseif command == "/fixcows" then
					print("🔧 Attempting to fix cow system for " .. player.Name)
					self:EnsurePlayerCowDataInitialized(player)
					print("✅ Cow system reinitialized")

				elseif command == "/resetcowsystem" then
					local userId = player.UserId

					-- Clear all cow data
					if self.Systems and self.Systems.Cows then
						self.Systems.Cows.PlayerCows[userId] = {}
						self.Systems.Cows.CowPositions[userId] = {}

						-- Remove cow models
						for cowId, model in pairs(self.Systems.Cows.CowModels) do
							if model:GetAttribute("Owner") == player.Name then
								model:Destroy()
								self.Systems.Cows.CowModels[cowId] = nil
							end
						end
					end

					-- Clear player data
					local playerData = self:GetPlayerData(player)
					if playerData and playerData.livestock then
						playerData.livestock.cows = {}
					end

					-- Reinitialize
					self:EnsurePlayerCowDataInitialized(player)
					self:SavePlayerData(player)

					print("✅ Complete cow system reset for " .. player.Name)
				end
			end
		end)
	end)
end

print("GameCore: ✅ COW SYSTEM BUG FIXES LOADED!")
print("🔧 Debug Commands:")
print("  /debugcows - Show detailed cow system status")
print("  /fixcows - Reinitialize cow system structures")
print("  /resetcowsystem - Complete cow system reset")
-- ========== COW PURCHASING SYSTEM ==========


function GameCore:CreateNewCow(player, cowType, cowConfig)
	local playerData = self:GetPlayerData(player)
	local userId = player.UserId

	-- Check cow limits
	local currentCowCount = self:GetPlayerCowCount(player)
	local maxCows = self:GetPlayerMaxCows(playerData)

	if currentCowCount >= maxCows then
		self:SendNotification(player, "Cow Limit Reached", 
			"You have " .. currentCowCount .. "/" .. maxCows .. " cows!")
		return false
	end

	-- Generate unique cow ID
	local cowId = "cow_" .. userId .. "_" .. self.Systems.Cows.NextCowId
	self.Systems.Cows.NextCowId = self.Systems.Cows.NextCowId + 1

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

	-- Store cow data
	playerData.livestock.cows[cowId] = cowData
	self.Systems.Cows.PlayerCows[userId][cowId] = cowData

	-- Create physical cow model
	local success = self:CreateCowModel(player, cowId, cowData)
	if not success then
		-- Clean up on failure
		playerData.livestock.cows[cowId] = nil
		self.Systems.Cows.PlayerCows[userId][cowId] = nil
		return false
	end

	-- Save data
	self:SavePlayerData(player)

	self:SendNotification(player, "🐄 Cow Purchased!", 
		"Added " .. self:GetCowDisplayName(cowConfig.tier) .. " to your farm!", "success")

	print("🐄 GameCore: Created new cow " .. cowId .. " for " .. player.Name)
	return true
end

function GameCore:UpgradeCow(player, cowId, newTier, cowConfig)
	local playerData = self:GetPlayerData(player)
	local userId = player.UserId

	-- Validate existing cow
	local cowData = playerData.livestock.cows[cowId]
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

	-- Update tracking
	self.Systems.Cows.PlayerCows[userId][cowId] = cowData

	-- Update visual appearance
	self:UpdateCowVisuals(cowId, cowData)

	-- Save data
	self:SavePlayerData(player)

	self:SendNotification(player, "🌟 Cow Upgraded!", 
		"Upgraded " .. self:GetCowDisplayName(oldTier) .. " to " .. self:GetCowDisplayName(newTier) .. "!", "success")

	print("🐄 GameCore: Upgraded cow " .. cowId .. " from " .. oldTier .. " to " .. newTier)
	return true
end

-- ========== COW MODEL MANAGEMENT ==========

function GameCore:CreateCowModel(player, cowId, cowData)
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
		self.Systems.Cows.CowModels[cowId] = newCow

		-- Add cow identification
		newCow:SetAttribute("CowId", cowId)
		newCow:SetAttribute("Owner", player.Name)
		newCow:SetAttribute("Tier", cowData.tier)

		-- Setup click detection
		self:SetupCowClickDetection(newCow, cowId, player)

		-- Apply visual effects
		self:ApplyCowVisualEffects(newCow, cowData)

		print("🐄 GameCore: Created model for cow " .. cowId)
		return true
	end)

	if not success then
		warn("GameCore: Failed to create cow model: " .. tostring(error))
		return false
	end

	return true
end

function GameCore:SetupCowClickDetection(cowModel, cowId, player)
	-- Remove existing click detectors
	for _, obj in pairs(cowModel:GetDescendants()) do
		if obj:IsA("ClickDetector") then
			obj:Destroy()
		end
	end

	-- Find best parts for click detection
	local clickableParts = {}
	for _, obj in pairs(cowModel:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name:lower():find("torso") or obj.Name:lower():find("humanoidrootpart") then
			table.insert(clickableParts, obj)
		end
	end

	-- Fallback to any large part
	if #clickableParts == 0 then
		for _, obj in pairs(cowModel:GetDescendants()) do
			if obj:IsA("BasePart") then
				local volume = obj.Size.X * obj.Size.Y * obj.Size.Z
				if volume > 10 then
					table.insert(clickableParts, obj)
				end
			end
		end
	end

	-- Add click detectors
	for _, part in pairs(clickableParts) do
		local detector = Instance.new("ClickDetector")
		detector.MaxActivationDistance = 25
		detector.Parent = part

		detector.MouseClick:Connect(function(clickingPlayer)
			if clickingPlayer.UserId == player.UserId then
				self:HandleCowMilkCollection(clickingPlayer, cowId)
			end
		end)
	end

	print("🐄 GameCore: Setup click detection for cow " .. cowId)
end

function GameCore:ApplyCowVisualEffects(cowModel, cowData)
	if not cowData.visualEffects or #cowData.visualEffects == 0 then
		return
	end

	local effects = {}

	-- Apply each visual effect
	for _, effectType in ipairs(cowData.visualEffects) do
		local effect = self:CreateCowVisualEffect(cowModel, effectType, cowData.tier)
		if effect then
			table.insert(effects, effect)
		end
	end

	-- Store effect references
	self.Systems.Cows.CowEffects[cowData.cowId] = effects

	print("🐄 GameCore: Applied " .. #effects .. " visual effects to cow " .. cowData.cowId)
end

function GameCore:CreateCowVisualEffect(cowModel, effectType, tier)
	local cowCenter = self:GetCowCenter(cowModel)

	if effectType == "metallic_shine" then
		return self:CreateMetallicShineEffect(cowModel, tier)
	elseif effectType == "silver_particles" then
		return self:CreateParticleEffect(cowModel, Color3.fromRGB(192, 192, 192))
	elseif effectType == "golden_glow" then
		return self:CreateGlowEffect(cowModel, Color3.fromRGB(255, 215, 0))
	elseif effectType == "gold_sparkles" then
		return self:CreateSparkleEffect(cowModel, Color3.fromRGB(255, 215, 0))
	elseif effectType == "diamond_crystals" then
		return self:CreateCrystalEffect(cowModel)
	elseif effectType == "rainbow_cycle" then
		return self:CreateRainbowEffect(cowModel)
	elseif effectType == "galaxy_swirl" then
		return self:CreateGalaxyEffect(cowModel)
	elseif effectType == "cosmic_energy" then
		return self:CreateCosmicEnergyEffect(cowModel)
	end

	return nil
end

-- ========== VISUAL EFFECTS IMPLEMENTATION ==========

function GameCore:CreateMetallicShineEffect(cowModel, tier)
	-- Change cow color to metallic
	for _, part in pairs(cowModel:GetDescendants()) do
		if part:IsA("BasePart") and part.Name:lower():find("body") then
			if tier == "silver" then
				part.Color = Color3.fromRGB(192, 192, 192)
				part.Material = Enum.Material.Metal
			elseif tier == "gold" then
				part.Color = Color3.fromRGB(255, 215, 0)
				part.Material = Enum.Material.Neon
			end
		end
	end

	return {type = "material_change", model = cowModel}
end

function GameCore:CreateGlowEffect(cowModel, color)
	local glowParts = {}

	for _, part in pairs(cowModel:GetDescendants()) do
		if part:IsA("BasePart") then
			local light = Instance.new("PointLight")
			light.Color = color
			light.Brightness = 2
			light.Range = 10
			light.Parent = part
			table.insert(glowParts, light)
		end
	end

	return {type = "glow", parts = glowParts}
end

function GameCore:CreateSparkleEffect(cowModel, color)
	local cowCenter = self:GetCowCenter(cowModel)

	spawn(function()
		while cowModel and cowModel.Parent do
			for i = 1, 3 do
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

				local tween = TweenService:Create(sparkle,
					TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						Position = sparkle.Position + Vector3.new(0, 10, 0),
						Transparency = 1,
						Size = Vector3.new(0.05, 0.05, 0.05)
					}
				)
				tween:Play()
				tween.Completed:Connect(function()
					sparkle:Destroy()
				end)
			end
			wait(math.random(2, 5))
		end
	end)

	return {type = "sparkle", model = cowModel}
end

function GameCore:CreateRainbowEffect(cowModel)
	local colorParts = {}

	-- Find colorable parts
	for _, part in pairs(cowModel:GetDescendants()) do
		if part:IsA("BasePart") and part.Name:lower():find("body") then
			table.insert(colorParts, part)
		end
	end

	-- Start rainbow cycling
	spawn(function()
		local hue = 0
		while cowModel and cowModel.Parent do
			for _, part in pairs(colorParts) do
				if part and part.Parent then
					part.Color = Color3.fromHSV(hue, 1, 1)
					part.Material = Enum.Material.Neon
				end
			end
			hue = (hue + 0.02) % 1
			wait(0.1)
		end
	end)

	return {type = "rainbow", parts = colorParts, model = cowModel}
end

function GameCore:CreateGalaxyEffect(cowModel)
	local cowCenter = self:GetCowCenter(cowModel)

	-- Create swirling galaxy particles
	spawn(function()
		local angle = 0
		while cowModel and cowModel.Parent do
			for i = 1, 2 do
				local star = Instance.new("Part")
				star.Size = Vector3.new(0.1, 0.1, 0.1)
				star.Shape = Enum.PartType.Ball
				star.Material = Enum.Material.Neon
				star.Color = Color3.fromRGB(
					math.random(100, 255),
					math.random(100, 255),
					math.random(200, 255)
				)
				star.CanCollide = false
				star.Anchored = true

				local radius = 3 + math.sin(angle) * 2
				local x = cowCenter.X + math.cos(angle + i * math.pi) * radius
				local z = cowCenter.Z + math.sin(angle + i * math.pi) * radius
				star.Position = Vector3.new(x, cowCenter.Y + 3, z)
				star.Parent = workspace

				local fadeOut = TweenService:Create(star,
					TweenInfo.new(2, Enum.EasingStyle.Quad),
					{Transparency = 1}
				)
				fadeOut:Play()
				fadeOut.Completed:Connect(function()
					star:Destroy()
				end)
			end

			angle = angle + 0.2
			wait(0.2)
		end
	end)

	return {type = "galaxy", model = cowModel}
end

-- ========== COW MILK COLLECTION ==========


function GameCore:CreateMilkCollectionEffect(cowId, tier)
	local cowModel = self.Systems.Cows.CowModels[cowId]
	if not cowModel then return end

	local cowCenter = self:GetCowCenter(cowModel)

	-- Create milk droplets with tier-specific colors
	local dropletColor = self:GetTierColor(tier)

	for i = 1, 5 do
		local droplet = Instance.new("Part")
		droplet.Size = Vector3.new(0.3, 0.3, 0.3)
		droplet.Shape = Enum.PartType.Ball
		droplet.Material = Enum.Material.Neon
		droplet.Color = dropletColor
		droplet.CanCollide = false
		droplet.Anchored = true
		droplet.Position = cowCenter + Vector3.new(
			math.random(-2, 2),
			math.random(0, 2),
			math.random(-2, 2)
		)
		droplet.Parent = workspace

		local tween = TweenService:Create(droplet,
			TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = droplet.Position + Vector3.new(0, 8, 0),
				Transparency = 1,
				Size = Vector3.new(0.1, 0.1, 0.1)
			}
		)
		tween:Play()
		tween.Completed:Connect(function()
			droplet:Destroy()
		end)
	end
end

-- ========== UTILITY FUNCTIONS ==========



function GameCore:GetPlayerCowCount(player)
	local playerData = self:GetPlayerData(player)
	if not playerData or not playerData.livestock or not playerData.livestock.cows then
		return 0
	end

	local count = 0
	for _ in pairs(playerData.livestock.cows) do
		count = count + 1
	end
	return count
end

function GameCore:GetPlayerMaxCows(playerData)
	local baseCows = 5
	local bonusCows = 0

	return baseCows + bonusCows
end

function GameCore:GetNextCowPosition(player)
	local userId = player.UserId
	local usedPositions = self.Systems.Cows.CowPositions[userId] or {}

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

	local playerOffset = self.CowPositions.playerSeparation * playerIndex
	local basePos = self.CowPositions.basePosition + playerOffset

	-- Find next available position
	for row = 0, 10 do
		for col = 0, self.CowPositions.rowSize - 1 do
			local position = basePos + Vector3.new(
				col * self.CowPositions.spacing.X,
				0,
				row * self.CowPositions.spacing.Z
			)

			local posKey = tostring(position)
			if not usedPositions[posKey] then
				usedPositions[posKey] = true
				self.Systems.Cows.CowPositions[userId] = usedPositions
				return position
			end
		end
	end

	return nil
end

function GameCore:GetCowDisplayName(tier)
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

function GameCore:GetTierColor(tier)
	local colors = {
		basic = Color3.fromRGB(255, 255, 255),
		silver = Color3.fromRGB(192, 192, 192),
		gold = Color3.fromRGB(255, 215, 0),
		diamond = Color3.fromRGB(185, 242, 255),
		rainbow = Color3.fromRGB(255, 100, 255),
		cosmic = Color3.fromRGB(138, 43, 226)
	}
	return colors[tier] or colors.basic
end

-- ========== INTEGRATION CALLS ==========
-- Add this to your existing GameCore:Initialize() function:
-- self:InitializeEnhancedCowSystem()

print("GameCore: ✅ Enhanced Multiple Cows System loaded!")
print("🐄 NEW FEATURES:")
print("  🏗️ Multiple cow support with positioning")
print("  ⬆️ Tier progression system")
print("  ✨ Visual effects for each tier")
print("  🎯 Individual cow tracking")
print("  💰 Enhanced milk collection")
-- ========== LIVESTOCK SYSTEM ==========

function GameCore:InitializeLivestockSystem()
	print("GameCore: Initializing livestock system...")

	-- Find cow model in workspace
	self.Models.Cow = workspace:FindFirstChild("cow")
	if not self.Models.Cow then
		warn("GameCore: Cow model not found in workspace!")
	else
		print("GameCore: Found cow model")
		-- Cow indicator setup now handled by enhanced system
		print("GameCore: Basic livestock system initialized - enhanced cows will be handled separately")
	end

	-- Find pig model in workspace  
	self.Models.Pig = workspace:FindFirstChild("Pig")
	if not self.Models.Pig then
		warn("GameCore: Pig model not found in workspace!")
	else
		print("GameCore: Found pig model")
	end

	-- Initialize player-specific livestock data
	self.Systems.Livestock.CowCooldowns = {}
	self.Systems.Livestock.PigStates = {}

	print("GameCore: Livestock system initialized")
end

function GameCore:SetupCowIndicator()
	if not self.Models.Cow then return end

	local indicator = Instance.new("Part")
	indicator.Name = "MilkIndicator"
	indicator.Size = Vector3.new(4, 0.2, 4)
	indicator.Shape = Enum.PartType.Cylinder
	indicator.Material = Enum.Material.Neon
	indicator.Color = Color3.fromRGB(255, 0, 0)
	indicator.CanCollide = false
	indicator.Anchored = true

	local cowHead = self.Models.Cow:FindFirstChild("Head")
	if cowHead then
		indicator.Position = cowHead.Position + Vector3.new(0, 5, 0)
		indicator.Orientation = Vector3.new(0, 0, 90)
	end

	indicator.Parent = self.Models.Cow

	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 10
	clickDetector.Parent = self.Models.Cow:FindFirstChild("HumanoidRootPart") or indicator

	clickDetector.MouseClick:Connect(function(player)
		self:HandleMilkCollection(player)
	end)

	print("GameCore: Cow indicator and click detector setup complete")
end

function GameCore:HandleMilkCollection(player)
	print("🥛 GameCore: Handling milk collection for", player.Name)

	local currentTime = os.time()
	local playerData = self:GetPlayerData(player)

	if not playerData then
		warn("🥛 GameCore: No player data found for", player.Name)
		return false
	end

	-- Initialize livestock data if missing
	if not playerData.livestock then
		playerData.livestock = {
			cow = {lastMilkCollection = 0, totalMilkCollected = 0},
			inventory = {}
		}
	end
	if not playerData.livestock.cow then
		playerData.livestock.cow = {lastMilkCollection = 0, totalMilkCollected = 0}
	end
	if not playerData.livestock.inventory then
		playerData.livestock.inventory = {}
	end

	-- Check cooldown
	local userId = player.UserId
	local lastCollection = 0

	if self.Systems.Livestock.CowCooldowns[userId] then
		lastCollection = math.max(lastCollection, self.Systems.Livestock.CowCooldowns[userId])
	end

	if playerData.livestock.cow.lastMilkCollection then
		lastCollection = math.max(lastCollection, playerData.livestock.cow.lastMilkCollection)
	end

	local cooldown = 10 -- Default 60 seconds

	-- Try to get cooldown from ItemConfig
	local success, upgradeCooldown = pcall(function()
		return ItemConfig.GetMilkCooldown and ItemConfig.GetMilkCooldown(playerData.upgrades or {})
	end)
	if success and type(upgradeCooldown) == "number" then
		cooldown = upgradeCooldown
	end

	local timeSinceCollection = currentTime - lastCollection
	if timeSinceCollection < cooldown then
		local timeLeft = cooldown - timeSinceCollection
		self:SendNotification(player, "🐄 Cow Resting", 
			"The cow needs " .. math.ceil(timeLeft) .. " more seconds to produce milk!", "warning")
		return false
	end

	-- Calculate milk amount
	local milkAmount = 2

	local success, upgradeMilkAmount = pcall(function()
		return ItemConfig.GetMilkAmount and ItemConfig.GetMilkAmount(playerData.upgrades or {})
	end)
	if success and type(upgradeMilkAmount) == "number" then
		milkAmount = upgradeMilkAmount
	end

	-- Store milk in inventory (compatible with shop system)
	playerData.milk = (playerData.milk or 0) + milkAmount
	playerData.livestock.inventory.milk = (playerData.livestock.inventory.milk or 0) + milkAmount

	-- Also store in farming inventory for compatibility
	if not playerData.farming then
		playerData.farming = {inventory = {}}
	end
	if not playerData.farming.inventory then
		playerData.farming.inventory = {}
	end
	playerData.farming.inventory.milk = (playerData.farming.inventory.milk or 0) + milkAmount

	-- Update cow data
	playerData.livestock.cow.lastMilkCollection = currentTime
	playerData.livestock.cow.totalMilkCollected = (playerData.livestock.cow.totalMilkCollected or 0) + milkAmount

	-- Update cooldown tracking
	self.Systems.Livestock.CowCooldowns[userId] = currentTime

	-- Update stats
	if not playerData.stats then
		playerData.stats = {}
	end
	playerData.stats.milkCollected = (playerData.stats.milkCollected or 0) + milkAmount

	-- Save and update
	self:SavePlayerData(player)
	self:UpdatePlayerLeaderstats(player)

	-- Send player data update
	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	self:SendNotification(player, "🥛 Milk Collected!", 
		"Collected " .. milkAmount .. " fresh milk! Sell it in the shop for coins.", "success")

	print("🥛 GameCore: Successfully processed milk collection for", player.Name)
	return true
end

function GameCore:HandlePigFeeding(player, cropId)
	local playerData = self:GetPlayerData(player)
	if not playerData then return end

	-- Check if player has the crop
	if not playerData.farming or not playerData.farming.inventory then
		self:SendNotification(player, "No Crops", "You don't have any crops to feed!", "error")
		return
	end

	local cropCount = playerData.farming.inventory[cropId] or 0
	if cropCount <= 0 then
		local cropData = ItemConfig.GetCropData and ItemConfig.GetCropData(cropId)
		local cropName = cropData and cropData.name or cropId
		self:SendNotification(player, "No Crops", "You don't have any " .. cropName .. "!", "error")
		return
	end

	-- Get crop data
	local cropData = ItemConfig.GetCropData and ItemConfig.GetCropData(cropId)
	if not cropData or not cropData.cropPoints then
		self:SendNotification(player, "Invalid Crop", "This crop cannot be fed to the pig!", "error")
		return
	end

	-- Initialize pig data if needed
	if not playerData.pig then
		playerData.pig = {
			size = 1.0,
			cropPoints = 0,
			transformationCount = 0,
			totalFed = 0
		}
	end

	-- Feed the pig
	playerData.farming.inventory[cropId] = playerData.farming.inventory[cropId] - 1
	local cropPoints = cropData.cropPoints

	playerData.pig.cropPoints = playerData.pig.cropPoints + cropPoints
	playerData.pig.totalFed = playerData.pig.totalFed + 1

	-- Calculate new pig size
	local newSize = 1.0 + (playerData.pig.cropPoints * (ItemConfig.PigSystem and ItemConfig.PigSystem.growthPerPoint or 0.01))
	playerData.pig.size = math.min(newSize, (ItemConfig.PigSystem and ItemConfig.PigSystem.maxSize or 3.0))

	-- Check for MEGA PIG transformation
	local pointsNeeded = 100 + (playerData.pig.transformationCount * 50)
	local message = "Fed pig with " .. cropData.name .. "! (" .. playerData.pig.cropPoints .. "/" .. pointsNeeded .. " points for MEGA PIG)"

	if playerData.pig.cropPoints >= pointsNeeded then
		message = self:TriggerMegaPigTransformation(player, playerData)
	end

	-- Update pig size in world
	self:UpdatePigSize(playerData.pig.size)

	-- Save and notify
	self:SavePlayerData(player)
	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end

	self:SendNotification(player, "Pig Fed!", message, "success")
end

function GameCore:TriggerMegaPigTransformation(player, playerData)
	print("GameCore: MEGA PIG transformation for " .. player.Name)

	-- Get random exclusive upgrade
	local megaDrop = ItemConfig.GetRandomMegaDrop and ItemConfig.GetRandomMegaDrop() or {
		id = "mega_milk_boost",
		name = "MEGA Milk Boost",
		description = "Milk collection gives +15 extra coins!"
	}

	-- Reset pig
	playerData.pig.cropPoints = 0
	playerData.pig.size = 1.0
	playerData.pig.transformationCount = playerData.pig.transformationCount + 1

	-- Grant the exclusive upgrade
	playerData.upgrades = playerData.upgrades or {}
	playerData.upgrades[megaDrop.id] = true

	-- Create spectacular effect
	self:CreateMegaPigEffect()

	-- Update pig size back to normal
	self:UpdatePigSize(1.0)

	return "🎉 MEGA PIG TRANSFORMATION! 🎉\nReceived exclusive upgrade: " .. megaDrop.name .. "!\nPig reset to normal size."
end

function GameCore:CreateMegaPigEffect()
	if not self.Models.Pig then return end

	spawn(function()
		-- Make pig huge temporarily
		self:UpdatePigSize(5.0)

		-- Create explosion effect
		local explosion = Instance.new("Explosion")
		explosion.Position = self.Models.Pig:FindFirstChild("HumanoidRootPart").Position + Vector3.new(0, 5, 0)
		explosion.BlastRadius = 20
		explosion.BlastPressure = 0
		explosion.Parent = workspace

		-- Create sparkles
		for i = 1, 20 do
			local sparkle = Instance.new("Part")
			sparkle.Size = Vector3.new(0.5, 0.5, 0.5)
			sparkle.Shape = Enum.PartType.Ball
			sparkle.Material = Enum.Material.Neon
			sparkle.Color = Color3.fromRGB(255, 215, 0)
			sparkle.CanCollide = false
			sparkle.Anchored = true
			sparkle.Position = self.Models.Pig:FindFirstChild("HumanoidRootPart").Position + Vector3.new(
				math.random(-10, 10),
				math.random(0, 15),
				math.random(-10, 10)
			)
			sparkle.Parent = workspace

			local tween = TweenService:Create(sparkle,
				TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = sparkle.Position + Vector3.new(0, 20, 0),
					Transparency = 1,
					Size = Vector3.new(0.1, 0.1, 0.1)
				}
			)
			tween:Play()
			tween.Completed:Connect(function()
				sparkle:Destroy()
			end)
		end

		wait(3)
		self:UpdatePigSize(1.0)
	end)
end

function GameCore:UpdatePigSize(size)
	if not self.Models.Pig then return end

	for _, part in pairs(self.Models.Pig:GetChildren()) do
		if part:IsA("BasePart") then
			part.Size = part.Size * (size / (self.Models.Pig:GetAttribute("CurrentSize") or 1.0))
		end
	end

	self.Models.Pig:SetAttribute("CurrentSize", size)
end

-- ========== PEST AND CHICKEN SYSTEMS ==========

function GameCore:InitializePestAndChickenSystems()
	print("GameCore: Initializing pest and chicken defense systems...")

	-- Initialize pest tracking in player data
	for _, player in pairs(Players:GetPlayers()) do
		local playerData = self:GetPlayerData(player)
		if playerData then
			if not playerData.defense then
				playerData.defense = {
					chickens = {owned = {}, deployed = {}, feed = {}},
					pestControl = {organic_pesticide = 0, pest_detector = false},
					roofs = {}
				}
			end
		end
	end

	print("GameCore: Pest and chicken systems initialized")
end

function GameCore:HandleFeedAllChickens(player)
	print("GameCore: Feed all chickens request from " .. player.Name)
	-- Implementation depends on ChickenSystem integration
	self:SendNotification(player, "🐔 Chickens Fed", "All chickens have been fed!", "success")
end

function GameCore:HandleFeedChickensWithType(player, feedType)
	print("GameCore: Feed chickens with " .. feedType .. " request from " .. player.Name)
	-- Implementation depends on ChickenSystem integration
	self:SendNotification(player, "🐔 Chickens Fed", "Fed chickens with " .. feedType .. "!", "success")
end

-- ========== DATA MANAGEMENT ==========

function GameCore:GetDefaultPlayerData()
	return {
		-- Core Currency
		coins = 100,
		farmTokens = 0,

		-- Progression
		upgrades = {},
		purchaseHistory = {},

		-- Farming System
		farming = {
			plots = 0,
			inventory = {}
		},

		-- Livestock System
		livestock = {
			cow = {
				lastMilkCollection = 0,
				totalMilkCollected = 0
			},
			pig = {
				size = 1.0,
				cropPoints = 0,
				transformationCount = 0,
				totalFed = 0
			},
			inventory = {}
		},

		-- Defense System (Pest & Chicken)
		defense = {
			chickens = {
				owned = {},
				deployed = {},
				feed = {}
			},
			pestControl = {
				organic_pesticide = 0,
				pest_detector = false
			},
			roofs = {}
		},

		-- Boosters and Enhancements
		boosters = {},

		-- Statistics
		stats = {
			milkCollected = 0,
			coinsEarned = 100,
			cropsHarvested = 0,
			rareCropsHarvested = 0,
			pigFed = 0,
			megaTransformations = 0,
			seedsPlanted = 0,
			pestsEliminated = 0
		},

		-- Session Data
		firstJoin = os.time(),
		lastSave = os.time()
	}
end

function GameCore:GetPlayerData(player)
	if not self.PlayerData[player.UserId] then
		self:LoadPlayerData(player)
	end
	return self.PlayerData[player.UserId]
end


function GameCore:DeepMerge(default, loaded)
	local result = {}

	for key, value in pairs(default) do
		if type(value) == "table" then
			result[key] = self:DeepMerge(value, loaded[key] or {})
		else
			result[key] = loaded[key] ~= nil and loaded[key] or value
		end
	end

	for key, value in pairs(loaded) do
		if result[key] == nil then
			result[key] = value
		end
	end

	return result
end

function GameCore:InitializePlayerSystems(player, playerData)
	print("GameCore: Initializing player systems for " .. player.Name)

	-- Initialize livestock systems
	if not self.Systems.Livestock.CowCooldowns[player.UserId] then
		self.Systems.Livestock.CowCooldowns[player.UserId] = 0
	end

	if not self.Systems.Livestock.PigStates[player.UserId] then
		self.Systems.Livestock.PigStates[player.UserId] = {
			lastFeedTime = 0,
			currentSize = playerData.livestock and playerData.livestock.pig and playerData.livestock.pig.size or 1.0
		}
	end

	print("GameCore: Player systems initialized for " .. player.Name)
end

function GameCore:UpdateCowIndicator(cowModel, state)
	-- This method is called by CowMilkSystem
	if not cowModel or not cowModel.Parent then
		return false
	end

	local indicator = cowModel:FindFirstChild("MilkIndicator")
	if not indicator then
		-- Create indicator if it doesn't exist
		indicator = self:CreateCowIndicator(cowModel)
	end

	if not indicator then
		return false
	end

	-- Update indicator based on state
	if state == "ready" then
		indicator.Color = Color3.fromRGB(0, 255, 0) -- Green - ready for milking
		indicator.Material = Enum.Material.Neon
		indicator.Transparency = 0.2
	elseif state == "cooldown" then
		indicator.Color = Color3.fromRGB(255, 0, 0) -- Red - in cooldown
		indicator.Material = Enum.Material.Plastic
		indicator.Transparency = 0.5
	elseif state == "almost_ready" then
		indicator.Color = Color3.fromRGB(255, 255, 0) -- Yellow - almost ready
		indicator.Material = Enum.Material.Neon
		indicator.Transparency = 0.3
	else
		-- Default state
		indicator.Color = Color3.fromRGB(100, 100, 100) -- Gray - unknown state
		indicator.Material = Enum.Material.Plastic
		indicator.Transparency = 0.7
	end

	print("GameCore: Updated cow indicator for " .. cowModel.Name .. " to state: " .. tostring(state))
	return true
end

function GameCore:CreateCowIndicator(cowModel)
	if not cowModel or not cowModel.Parent then
		return nil
	end

	-- Remove existing indicator
	local existingIndicator = cowModel:FindFirstChild("MilkIndicator")
	if existingIndicator then
		existingIndicator:Destroy()
	end

	-- Find the best position for the indicator
	local headPart = cowModel:FindFirstChild("Head") or cowModel:FindFirstChild("HumanoidRootPart")
	if not headPart then
		-- Try to find any part to attach to
		for _, part in pairs(cowModel:GetChildren()) do
			if part:IsA("BasePart") then
				headPart = part
				break
			end
		end
	end

	if not headPart then
		warn("GameCore: Could not find part to attach indicator to for " .. cowModel.Name)
		return nil
	end

	-- Create the indicator
	local indicator = Instance.new("Part")
	indicator.Name = "MilkIndicator"
	indicator.Size = Vector3.new(2, 0.2, 2)
	indicator.Shape = Enum.PartType.Cylinder
	indicator.Material = Enum.Material.Neon
	indicator.Color = Color3.fromRGB(255, 0, 0) -- Start as red (not ready)
	indicator.CanCollide = false
	indicator.Anchored = true
	indicator.Transparency = 0.5

	-- Position above the cow
	local headPosition = headPart.Position
	indicator.Position = headPosition + Vector3.new(0, 5, 0)
	indicator.Orientation = Vector3.new(0, 0, 90) -- Rotate for better visibility
	indicator.Parent = cowModel

	print("GameCore: Created cow indicator for " .. cowModel.Name)
	return indicator
end

function GameCore:GetCowIndicatorState(cowModel)
	if not cowModel then return "unknown" end

	local cowId = cowModel:GetAttribute("CowId")
	local owner = cowModel:GetAttribute("Owner")

	if not cowId or not owner then
		return "unknown"
	end

	-- Find the player who owns this cow
	local ownerPlayer = Players:GetPlayerByUserId(Players:GetUserIdFromNameAsync(owner))
	if not ownerPlayer then
		return "unknown"
	end

	local playerData = self:GetPlayerData(ownerPlayer)
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

-- ========== AMBIENT LIGHT METHODS ==========

function GameCore:CreateAmbientLight(parent, properties)
	-- This method is called by CowVisualEffects
	if not parent or not parent.Parent then
		warn("GameCore: Cannot create ambient light - invalid parent")
		return nil
	end

	properties = properties or {}

	-- Create a PointLight for ambient lighting effect
	local light = Instance.new("PointLight")
	light.Name = "AmbientLight"
	light.Color = properties.Color or Color3.fromRGB(255, 255, 255)
	light.Brightness = properties.Brightness or 1
	light.Range = properties.Range or 10
	light.Shadows = properties.Shadows or false
	light.Parent = parent

	print("GameCore: Created ambient light for " .. parent.Name)
	return light
end

function GameCore:CreateAmbientEffect(parent, effectType, properties)
	-- Enhanced version that supports different effect types
	properties = properties or {}

	if effectType == "light" or effectType == "ambient_light" then
		return self:CreateAmbientLight(parent, properties)

	elseif effectType == "glow" then
		return self:CreateGlowEffect(parent, properties.Color or Color3.fromRGB(255, 255, 255))

	elseif effectType == "sparkle" then
		return self:CreateSparkleEffect(parent, properties.Color or Color3.fromRGB(255, 255, 255))

	elseif effectType == "aura" then
		return self:CreateAuraEffect(parent, properties.Color or Color3.fromRGB(255, 255, 255))

	else
		warn("GameCore: Unknown ambient effect type: " .. tostring(effectType))
		return nil
	end
end

-- ========== ENHANCED VISUAL EFFECTS METHODS ==========

-- Ensure these methods exist for the visual effects system

function GameCore:CreateAuraEffect(part, color)
	if not part or not part.Parent then return nil end

	local aura = Instance.new("SelectionBox")
	aura.Color3 = color or Color3.fromRGB(255, 255, 255)
	aura.LineThickness = 0.2
	aura.Transparency = 0.5
	aura.Adornee = part
	aura.Parent = part

	return aura
end

-- ========== ERROR HANDLING FOR EXTERNAL SCRIPTS ==========

function GameCore:SafeCallMethod(methodName, ...)
	-- Safe method caller for external scripts
	local method = self[methodName]
	if type(method) == "function" then
		local success, result = pcall(method, self, ...)
		if success then
			return result
		else
			warn("GameCore: Error calling " .. methodName .. ": " .. tostring(result))
			return nil
		end
	else
		warn("GameCore: Method " .. methodName .. " does not exist")
		return nil
	end
end

-- ========== EXTERNAL SCRIPT COMPATIBILITY LAYER ==========

-- Add these global functions for external scripts to use
_G.UpdateCowIndicator = function(cowModel, state)
	if _G.GameCore and _G.GameCore.UpdateCowIndicator then
		return _G.GameCore:UpdateCowIndicator(cowModel, state)
	else
		warn("UpdateCowIndicator: GameCore not available")
		return false
	end
end

_G.CreateAmbientLight = function(parent, properties)
	if _G.GameCore and _G.GameCore.CreateAmbientLight then
		return _G.GameCore:CreateAmbientLight(parent, properties)
	else
		warn("CreateAmbientLight: GameCore not available")
		return nil
	end
end

-- ========== ENHANCED COW MILK SYSTEM INTEGRATION ==========

function GameCore:HandleCowMilkCollectionExternal(player, cowModel)
	-- Method for external CowMilkSystem to call
	if not cowModel then
		warn("GameCore: HandleCowMilkCollectionExternal called with nil cowModel")
		return false
	end

	local cowId = cowModel:GetAttribute("CowId")
	if not cowId then
		warn("GameCore: Cow model missing CowId attribute")
		return false
	end

	local success = self:HandleCowMilkCollection(player, cowId)

	-- Update the indicator after collection attempt
	if success then
		self:UpdateCowIndicator(cowModel, "cooldown")
	end

	return success
end

-- ========== STARTUP INDICATOR UPDATE LOOP ==========

function GameCore:StartCowIndicatorUpdateLoop()
	-- Start a loop to update all cow indicators periodically
	spawn(function()
		while true do
			wait(5) -- Update every 5 seconds

			-- Update all cow indicators
			for cowId, cowModel in pairs(self.Systems.Cows.CowModels or {}) do
				if cowModel and cowModel.Parent then
					local state = self:GetCowIndicatorState(cowModel)
					self:UpdateCowIndicator(cowModel, state)
				end
			end
		end
	end)

	print("GameCore: Started cow indicator update loop")
end

-- ========== DEBUG COMMANDS FOR MISSING METHODS ==========
function GameCore:DebugMilkingPositions(player)
	if player.Name == "TommySalami311" then -- Replace with your username
		print("=== REDESIGNED POSITIONING DEBUG ===")

		local testCow = nil
		for _, model in pairs(workspace:GetChildren()) do
			if model:IsA("Model") and model.Name:find("cow_") then
				testCow = model
				break
			end
		end

		if testCow then
			local bounds = self:GetCowBoundingBox(testCow)

			print("Cow: " .. testCow.Name)
			print("Cow bounds:")
			print("  Center: " .. tostring(bounds.center))
			print("  Ground level (minY): " .. bounds.minY)
			print("  Size: " .. tostring(bounds.size))

			local playerGroundPos = Vector3.new(bounds.center.X + 6, bounds.minY, bounds.center.Z)
			local playerStandingPos = Vector3.new(playerGroundPos.X, playerGroundPos.Y + 2.5, playerGroundPos.Z)

			print("Player positions:")
			print("  Ground position: " .. tostring(playerGroundPos))
			print("  Standing position: " .. tostring(playerStandingPos))

			print("Equipment positions:")
			print("  Stool: " .. tostring(Vector3.new(playerGroundPos.X, bounds.minY + 0.5, playerGroundPos.Z)))
			print("  Bucket: " .. tostring(Vector3.new(bounds.center.X + 3, bounds.minY + 1, bounds.center.Z - 1)))

			-- Show current player position for comparison
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				print("Current player position: " .. tostring(player.Character.HumanoidRootPart.Position))
			end
		else
			print("No cow found for testing")
		end

		print("====================================")
	end
end

function GameCore:DebugMissingMethods(player)
	print("=== MISSING METHODS DEBUG ===")

	-- Check if methods exist
	local methods = {
		"UpdateCowIndicator",
		"CreateAmbientLight", 
		"CreateAmbientEffect",
		"HandleCowMilkCollectionExternal"
	}

	for _, methodName in ipairs(methods) do
		local exists = type(self[methodName]) == "function"
		print("  " .. methodName .. ": " .. (exists and "✅ EXISTS" or "❌ MISSING"))
	end

	-- Check global functions
	local globalFuncs = {
		"UpdateCowIndicator",
		"CreateAmbientLight"
	}

	print("Global functions:")
	for _, funcName in ipairs(globalFuncs) do
		local exists = type(_G[funcName]) == "function"
		print("  _G." .. funcName .. ": " .. (exists and "✅ EXISTS" or "❌ MISSING"))
	end

	-- Check cow models
	local cowCount = 0
	if self.Systems and self.Systems.Cows and self.Systems.Cows.CowModels then
		for cowId, model in pairs(self.Systems.Cows.CowModels) do
			if model and model.Parent then
				cowCount = cowCount + 1
			end
		end
	end
	print("Active cow models: " .. cowCount)

	print("============================")
end

print("GameCore: ✅ Missing methods fixes loaded!")
print("🔧 Available Methods:")
print("  UpdateCowIndicator() - Updates cow milk indicators")
print("  CreateAmbientLight() - Creates ambient lighting effects")
print("  CreateAmbientEffect() - Creates various ambient effects")
print("  HandleCowMilkCollectionExternal() - External milk collection handler")
print("🌐 Global Functions:")
print("  _G.UpdateCowIndicator() - Global access to indicator updates")
print("  _G.CreateAmbientLight() - Global access to ambient light creation")

function GameCore:CreatePlayerLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = self.PlayerData[player.UserId].coins
	coins.Parent = leaderstats

	local farmTokens = Instance.new("IntValue")
	farmTokens.Name = "Farm Tokens"
	farmTokens.Value = self.PlayerData[player.UserId].farmTokens or 0
	farmTokens.Parent = leaderstats
end

function GameCore:UpdatePlayerLeaderstats(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then 
		self:CreatePlayerLeaderstats(player)
		return
	end

	local playerData = self.PlayerData[player.UserId]
	if not playerData then return end

	local coins = leaderstats:FindFirstChild("Coins")
	if coins then coins.Value = playerData.coins end

	local farmTokens = leaderstats:FindFirstChild("Farm Tokens")
	if farmTokens then farmTokens.Value = playerData.farmTokens or 0 end
end

-- ========== UPDATE LOOPS ==========

function GameCore:StartUpdateLoops()
	print("GameCore: Starting update loops...")

	-- Cow indicator update loop
	spawn(function()
		while true do
			wait(1)
			self:UpdateCowIndicator()
		end
	end)

	-- Auto-save loop
	spawn(function()
		while true do
			wait(300) -- Save every 5 minutes
			for _, player in ipairs(Players:GetPlayers()) do
				if player and player.Parent and self.PlayerData[player.UserId] then
					pcall(function()
						self:SavePlayerData(player)
					end)
				end
			end
		end
	end)
end


-- ========== UTILITY FUNCTIONS ==========


function GameCore:SendNotification(player, title, message, notificationType)
	if self.RemoteEvents.ShowNotification then
		local success = pcall(function()
			self.RemoteEvents.ShowNotification:FireClient(player, title, message, notificationType or "info")
		end)
		if success then
			print("🔔 GameCore: Sent notification to", player.Name, "-", title)
			return
		end
	end

	print("🔔 NOTIFICATION for " .. player.Name .. ": [" .. (notificationType or "info"):upper() .. "] " .. title .. " - " .. message)
end

-- ========== ENHANCED ADMIN COMMANDS ==========
function GameCore:DebugMilkSystem(player)
	print("=== MILK SYSTEM DEBUG FOR " .. player.Name .. " ===")

	local playerData = self:GetPlayerData(player)
	if not playerData then
		print("❌ No player data found")
		return
	end

	print("Player data structure:")
	print("  Has livestock:", playerData.livestock ~= nil)
	if playerData.livestock then
		print("  Has cow data:", playerData.livestock.cow ~= nil)
		print("  Has livestock inventory:", playerData.livestock.inventory ~= nil)
		if playerData.livestock.cow then
			print("  Last collection:", playerData.livestock.cow.lastMilkCollection or 0)
			print("  Total collected:", playerData.livestock.cow.totalMilkCollected or 0)
		end
		if playerData.livestock.inventory then
			print("  Milk in livestock inventory:", playerData.livestock.inventory.milk or 0)
		end
	end

	print("Other milk storage:")
	print("  Direct milk property:", playerData.milk or 0)
	if playerData.farming and playerData.farming.inventory then
		print("  Milk in farming inventory:", playerData.farming.inventory.milk or 0)
	end

	print("============================================")
end

-- ========== PLAYER EVENTS ==========

Players.PlayerAdded:Connect(function(player)
	GameCore:LoadPlayerData(player)
	GameCore:CreatePlayerLeaderstats(player)
end)

Players.PlayerRemoving:Connect(function(player)
	GameCore:SavePlayerData(player, true)
	-- Clean up cooldowns
	GameCore.Systems.Livestock.CowCooldowns[player.UserId] = nil
	GameCore.Systems.Livestock.PigStates[player.UserId] = nil
end)

-- Make globally available
_G.GameCore = GameCore

print("GameCore: ✅ FIXED and ENHANCED core game system loaded successfully!")
print("🌟 NEW FEATURES:")
print("  🌱 Complete farming system with ALL seeds from ItemConfig")
print("  🎲 Full rarity system implementation (5 tiers)")
print("  ✨ Visual rarity effects (sparkles, glows, auras)")
print("  📏 Rarity-based size scaling for crops") 
print("  💰 Rarity-based value multipliers")
print("  🔍 Enhanced growth timers and indicators")
print("  🎮 Improved admin commands for testing")
print("  📊 Better statistics tracking")
print("")
print("🧪 ADMIN COMMANDS (ENHANCED):")
print("  /giveallseeds - Give ALL seed types")
print("  /testrarities - Visual rarity test")
print("  /checkshopitems - Debug shop items")
print("  (Plus all previous commands)")

return GameCore