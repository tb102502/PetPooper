--[[
    CowMilkingModule.lua - Handles all cow milking functionality
    Place in: ServerScriptService/CowMilkingModule.lua
    
    Features:
    ✅ Clicker-based milking system
    ✅ Chair-based milking integration
    ✅ Auto-milking system
    ✅ Enhanced visual effects and indicators
    ✅ Session management and player positioning
    ✅ Tier-based milking effects
]]

local CowMilkingModule = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Configuration
local AUTO_MILK_INTERVAL = 1 -- seconds
local MILK_INDICATOR_HEIGHT = 8

-- Module State
CowMilkingModule.CowIndicators = {} -- [cowId] = indicatorModel
CowMilkingModule.AutoMilkers = {} -- [userId] = true
CowMilkingModule.PlayerCooldowns = {} -- [userId][cowId] = lastCollection

-- Clicker System State
CowMilkingModule.ClickerMilking = {
	ActiveSessions = {}, -- [userId] = {sessionData}
	SessionTimeouts = {}, -- [userId] = timeoutTime
	PlayerPositions = {}, -- [userId] = originalPosition
	MilkingCows = {}, -- [cowId] = userId (track which cow is being milked)
	PositioningObjects = {} -- [userId] = {bodyPosition/anchoring objects}
}

-- Chair System State
CowMilkingModule.ChairMilking = {
	ActiveSessions = {}, -- [userId] = {chair, cow, startTime}
	ProximityConnections = {}, -- [userId] = connection
	SeatedPlayers = {}, -- [userId] = seatConnection
	ChairGUIs = {} -- [userId] = guiReference
}

-- Visual Effects State
CowMilkingModule.MilkingEffects = {
	ActiveMilkingSessions = {}, -- [cowId] = {player, startTime, effects}
	SessionEffects = {} -- [cowId] = effectObjects
}

-- References (injected on initialize)
local GameCore = nil
local CowCreationModule = nil

-- ========== INITIALIZATION ==========

function CowMilkingModule:Initialize(gameCore, cowCreationModule)
	print("CowMilkingModule: Initializing comprehensive milking system...")

	GameCore = gameCore
	CowCreationModule = cowCreationModule

	-- Setup remote events
	self:SetupRemoteEvents()

	-- Initialize subsystems
	self:InitializeClickerMilking()
	self:InitializeChairMilking()
	self:InitializeAutoMilking()
	self:InitializeIndicators()

	-- Start monitoring and update loops
	self:StartUpdateLoops()

	-- Setup existing cows
	self:SetupExistingCows()

	print("CowMilkingModule: Comprehensive milking system initialized!")
	return true
end

function CowMilkingModule:SetupRemoteEvents()
	local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "GameRemotes"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Create milking-specific remotes
	local milkingRemotes = {
		"CollectCowMilk",
		"StartMilkingSession",
		"StopMilkingSession", 
		"ContinueMilking",
		"MilkingSessionUpdate",
		"ShowChairPrompt",
		"HideChairPrompt",
		"StartChairMilking",
		"StopChairMilking"
	}

	for _, remoteName in ipairs(milkingRemotes) do
		if not remoteFolder:FindFirstChild(remoteName) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = remoteName
			remote.Parent = remoteFolder
		end
	end

	-- Connect handlers
	self:ConnectRemoteHandlers(remoteFolder)

	print("CowMilkingModule: Remote events setup complete")
end

function CowMilkingModule:ConnectRemoteHandlers(remoteFolder)
	-- Clicker milking handlers
	if remoteFolder:FindFirstChild("StartMilkingSession") then
		remoteFolder.StartMilkingSession.OnServerEvent:Connect(function(player, cowId)
			pcall(function()
				self:HandleStartMilkingSession(player, cowId)
			end)
		end)
	end

	if remoteFolder:FindFirstChild("StopMilkingSession") then
		remoteFolder.StopMilkingSession.OnServerEvent:Connect(function(player)
			pcall(function()
				self:HandleStopMilkingSession(player)
			end)
		end)
	end

	if remoteFolder:FindFirstChild("ContinueMilking") then
		remoteFolder.ContinueMilking.OnServerEvent:Connect(function(player)
			pcall(function()
				self:HandleContinueMilking(player)
			end)
		end)
	end

	-- Chair milking handlers
	if remoteFolder:FindFirstChild("StartChairMilking") then
		remoteFolder.StartChairMilking.OnServerEvent:Connect(function(player, chairName)
			pcall(function()
				self:HandleChairMilkingStart(player, chairName)
			end)
		end)
	end

	if remoteFolder:FindFirstChild("StopChairMilking") then
		remoteFolder.StopChairMilking.OnServerEvent:Connect(function(player)
			pcall(function()
				self:HandleChairMilkingStop(player)
			end)
		end)
	end

	-- Direct cow milking (legacy compatibility)
	if remoteFolder:FindFirstChild("CollectCowMilk") then
		remoteFolder.CollectCowMilk.OnServerEvent:Connect(function(player, cowId)
			pcall(function()
				self:HandleCowMilkCollection(player, cowId)
			end)
		end)
	end
end

-- ========== CLICKER MILKING SYSTEM ==========

function CowMilkingModule:InitializeClickerMilking()
	print("CowMilkingModule: Initializing clicker milking system...")

	-- Initialize session tracking
	self.ClickerMilking = {
		ActiveSessions = {},
		SessionTimeouts = {},
		PlayerPositions = {},
		MilkingCows = {},
		PositioningObjects = {}
	}

	print("CowMilkingModule: Clicker milking system initialized!")
end

function CowMilkingModule:HandleStartMilkingSession(player, cowId)
	print("🥛 CowMilkingModule: Starting milking session for " .. player.Name .. " with cow " .. cowId)

	local userId = player.UserId

	if not GameCore then
		self:SendNotification(player, "System Error", "Game system not available!", "error")
		return false
	end

	local playerData = GameCore:GetPlayerData(player)
	if not playerData then
		self:SendNotification(player, "Error", "Player data not found!", "error")
		return false
	end

	-- Check if player is already milking
	if self.ClickerMilking.ActiveSessions[userId] then
		self:SendNotification(player, "Already Milking", "You're already milking a cow!", "warning")
		return false
	end

	-- Check if cow is already being milked
	if self.ClickerMilking.MilkingCows[cowId] then
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

	-- Position player - check if seated in chair first
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
		isChairBased = self:IsPlayerSeatedInMilkingChair(player)
	}

	-- Store session data
	self.ClickerMilking.ActiveSessions[userId] = sessionData
	self.ClickerMilking.MilkingCows[cowId] = userId
	self.ClickerMilking.SessionTimeouts[userId] = currentTime + 3

	-- Send session start to client
	self:SendMilkingSessionUpdate(player, "started", sessionData)

	-- Create milking visual effects
	self:CreateMilkingSessionVisuals(player, cowId)

	local milkingType = sessionData.isChairBased and "chair-based" or "standard"
	self:SendNotification(player, "🥛 Milking Started!", 
		"Keep clicking to collect milk! (" .. milkingType .. " milking)", "success")

	print("🥛 CowMilkingModule: " .. milkingType .. " milking session started for " .. player.Name)
	return true
end

function CowMilkingModule:HandleStopMilkingSession(player)
	print("🥛 CowMilkingModule: Stopping milking session for " .. player.Name)

	local userId = player.UserId
	local session = self.ClickerMilking.ActiveSessions[userId]

	if not session then
		return false
	end

	-- Get final milk count
	local totalMilk = session.milkCollected

	-- Final save of player data
	if totalMilk > 0 and GameCore then
		local playerData = GameCore:GetPlayerData(player)
		if playerData then
			session.cowData.lastMilkCollection = os.time()
			GameCore:SavePlayerData(player)

			-- Send data update
			self:SendPlayerDataUpdate(player, playerData)
		end
	end

	-- Clean up session
	self:CleanupMilkingSession(userId)

	-- Release player position
	if session.isChairBased then
		self:ReleasePlayerFromMilkingChair(player)
	else
		self:ReleasePlayerFromMilking(player)
	end

	-- Send session end notification
	self:SendMilkingSessionUpdate(player, "ended", {
		totalMilk = totalMilk,
		sessionDuration = os.time() - session.startTime
	})

	local milkingType = session.isChairBased and "Chair-based" or "Standard"
	self:SendNotification(player, "🥛 Milking Complete!", 
		milkingType .. " milking complete! Collected " .. totalMilk .. " milk.", "success")

	return true
end

function CowMilkingModule:HandleContinueMilking(player)
	local userId = player.UserId
	local session = self.ClickerMilking.ActiveSessions[userId]

	if not session then
		return false
	end

	local currentTime = os.time()

	-- Update last click time to keep session active
	session.lastClickTime = currentTime
	self.ClickerMilking.SessionTimeouts[userId] = currentTime + 3

	-- Give exactly 1 milk per click
	session.milkCollected = session.milkCollected + 1

	-- Award milk immediately to player
	if GameCore then
		local playerData = GameCore:GetPlayerData(player)
		if playerData then
			-- Add 1 milk to player inventory (multiple locations for compatibility)
			playerData.milk = (playerData.milk or 0) + 1

			if not playerData.livestock then playerData.livestock = {inventory = {}} end
			if not playerData.livestock.inventory then playerData.livestock.inventory = {} end
			playerData.livestock.inventory.milk = (playerData.livestock.inventory.milk or 0) + 1

			if not playerData.farming then playerData.farming = {inventory = {}} end
			if not playerData.farming.inventory then playerData.farming.inventory = {} end
			playerData.farming.inventory.milk = (playerData.farming.inventory.milk or 0) + 1

			-- Update stats
			playerData.stats = playerData.stats or {}
			playerData.stats.milkCollected = (playerData.stats.milkCollected or 0) + 1

			-- Update cow data
			session.cowData.totalMilkProduced = (session.cowData.totalMilkProduced or 0) + 1

			-- Save data periodically (every 5 clicks to avoid lag)
			if session.milkCollected % 5 == 0 then
				GameCore:SavePlayerData(player)
			end

			-- Update client immediately
			self:SendPlayerDataUpdate(player, playerData)
		end
	end

	-- Send progress update to client
	self:SendMilkingSessionUpdate(player, "progress", {
		milkCollected = session.milkCollected,
		sessionDuration = currentTime - session.startTime,
		lastClickTime = currentTime
	})

	-- Create visual effects
	self:CreateMilkDropEffect(player, session.cowId)
	self:UpdateMilkingSessionVisuals(player, session.cowId)

	print("🥛 CowMilkingModule: Player " .. player.Name .. " collected 1 milk (total: " .. session.milkCollected .. ")")
	return true
end

-- ========== CHAIR MILKING SYSTEM ==========

function CowMilkingModule:InitializeChairMilking()
	print("CowMilkingModule: Initializing chair milking system...")

	-- Initialize chair system state
	self.ChairMilking = {
		ActiveSessions = {},
		ProximityConnections = {},
		SeatedPlayers = {},
		ChairGUIs = {}
	}

	-- Setup existing chairs
	self:SetupMilkingChairs()

	-- Setup player monitoring for chair proximity
	self:SetupChairPlayerMonitoring()

	print("CowMilkingModule: Chair milking system initialized!")
end

function CowMilkingModule:SetupMilkingChairs()
	local chairName = "MilkingChair"
	local chairsFound = 0

	-- Find all milking chairs in workspace
	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("Model") and obj.Name == chairName then
			self:SetupIndividualChair(obj)
			chairsFound = chairsFound + 1
		elseif obj:IsA("Part") and obj.Name == chairName then
			self:SetupIndividualChair(obj)
			chairsFound = chairsFound + 1
		end
	end

	-- Also check in folders
	for _, folder in pairs(workspace:GetChildren()) do
		if folder:IsA("Folder") or folder:IsA("Model") then
			for _, obj in pairs(folder:GetDescendants()) do
				if (obj:IsA("Model") or obj:IsA("Part")) and obj.Name == chairName then
					self:SetupIndividualChair(obj)
					chairsFound = chairsFound + 1
				end
			end
		end
	end

	print("CowMilkingModule: Found and setup " .. chairsFound .. " milking chairs")
end

function CowMilkingModule:SetupIndividualChair(chair)
	-- Find the seat part
	local seat = self:FindSeatInChair(chair)
	if not seat then
		warn("CowMilkingModule: No seat found in chair: " .. chair.Name)
		return false
	end

	-- Add chair attributes
	chair:SetAttribute("IsChairSetup", true)
	chair:SetAttribute("ChairType", "MilkingChair")

	-- Setup seat connection for when players sit/leave
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		self:HandleSeatChange(chair, seat)
	end)

	-- Handle existing occupant
	if seat.Occupant then
		local humanoid = seat.Occupant
		local character = humanoid.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			self:HandlePlayerSat(player, chair, seat)
		end
	end

	print("CowMilkingModule: Chair setup complete: " .. chair.Name)
	return true
end

function CowMilkingModule:HandleSeatChange(chair, seat)
	local occupant = seat.Occupant

	if occupant then
		-- Someone sat down
		local character = occupant.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			self:HandlePlayerSat(player, chair, seat)
		end
	else
		-- Someone left the seat
		self:HandleSeatEmpty(chair, seat)
	end
end

function CowMilkingModule:HandlePlayerSat(player, chair, seat)
	print("CowMilkingModule: Player " .. player.Name .. " sat in milking chair")

	local userId = player.UserId

	-- Check if player is already in a milking session
	if self.ChairMilking.ActiveSessions[userId] then
		self:StopChairMilkingSession(player)
	end

	-- Find cow dynamically when player sits
	local cow = self:FindPlayerCowNearChair(player, chair)
	if not cow then
		self:SendNotification(player, "No Cow Found", 
			"You don't have any cows near this chair! Make sure you own a cow and it's within 50 studs of the chair.", "error")
		return
	end

	-- Get cow ID for the milking system
	local cowId = self:GetCowIdFromModel(cow)

	-- Verify ownership
	if not self:DoesPlayerOwnCow(player, cow) then
		self:SendNotification(player, "Not Your Cow", "This cow doesn't belong to you!", "error")
		return
	end

	-- Lock player in place
	self:LockPlayerInSeat(player, seat)

	-- Start milking session through the clicker system
	self:StartChairMilkingSession(player, chair, cow, cowId, seat)
end

function CowMilkingModule:StartChairMilkingSession(player, chair, cow, cowId, seat)
	local userId = player.UserId

	-- Store chair session data
	self.ChairMilking.ActiveSessions[userId] = {
		chair = chair,
		cow = cow,
		cowId = cowId,
		seat = seat,
		startTime = os.time(),
		locked = true
	}

	-- Start the actual milking session through clicker system
	local success = self:HandleStartMilkingSession(player, cowId)

	if success then
		self:SendNotification(player, "🪑 Chair Milking Started!", 
			"Click to collect milk! Session will end when you leave the chair.\nCow: " .. cowId, "success")
		return true
	else
		-- Failed to start
		self.ChairMilking.ActiveSessions[userId] = nil
		self:UnlockPlayer(player)
		return false
	end
end

function CowMilkingModule:HandleSeatEmpty(chair, seat)
	-- Find which player was sitting here and stop their session
	for userId, session in pairs(self.ChairMilking.ActiveSessions) do
		if session.chair == chair then
			local player = Players:GetPlayerByUserId(userId)
			if player then
				self:StopChairMilkingSession(player)
			end
			break
		end
	end
end

function CowMilkingModule:StopChairMilkingSession(player)
	local userId = player.UserId
	local session = self.ChairMilking.ActiveSessions[userId]

	if not session then return false end

	-- Stop the clicker milking session first
	self:HandleStopMilkingSession(player)

	-- Unlock player
	self:UnlockPlayer(player)

	-- Clear chair session data
	self.ChairMilking.ActiveSessions[userId] = nil

	return true
end

-- ========== AUTO-MILKING SYSTEM ==========

function CowMilkingModule:InitializeAutoMilking()
	print("CowMilkingModule: Initializing auto-milking system...")

	self.AutoMilkers = {}

	-- Start auto-milking loop
	self:StartAutoMilkingLoop()

	print("CowMilkingModule: Auto-milking system initialized!")
end

function CowMilkingModule:StartAutoMilkingLoop()
	spawn(function()
		while true do
			wait(AUTO_MILK_INTERVAL)
			self:ProcessAutoMilking()
		end
	end)
end

function CowMilkingModule:ProcessAutoMilking()
	for _, player in pairs(Players:GetPlayers()) do
		if self:PlayerHasAutoMilker(player) then
			self:AutoMilkPlayerCows(player)
		end
	end
end

function CowMilkingModule:PlayerHasAutoMilker(player)
	if not GameCore then return false end

	local playerData = GameCore:GetPlayerData(player)
	if not playerData or not playerData.upgrades then return false end

	return playerData.upgrades.auto_milker == true
end

function CowMilkingModule:AutoMilkPlayerCows(player)
	if not GameCore then return end

	local playerData = GameCore:GetPlayerData(player)
	if not playerData or not playerData.livestock or not playerData.livestock.cows then return end

	local milkedCount = 0

	for cowId, cowData in pairs(playerData.livestock.cows) do
		local currentTime = os.time()
		local timeSinceCollection = currentTime - (cowData.lastMilkCollection or 0)

		if timeSinceCollection >= (cowData.cooldown or 60) then
			-- Simulate milk collection
			local milkAmount = cowData.milkAmount or 1

			-- Add milk to inventory
			playerData.milk = (playerData.milk or 0) + milkAmount

			-- Update cow data
			cowData.lastMilkCollection = currentTime
			cowData.totalMilkProduced = (cowData.totalMilkProduced or 0) + milkAmount

			milkedCount = milkedCount + 1

			-- Create visual effect
			self:CreateEnhancedMilkEffect(cowId)
		end
	end

	if milkedCount > 0 then
		-- Save data
		GameCore:SavePlayerData(player)

		-- Update client
		self:SendPlayerDataUpdate(player, playerData)

		self:SendNotification(player, "🤖 Auto Milker", 
			"Automatically collected milk from " .. milkedCount .. " cows!", "success")
	end
end

-- ========== INDICATOR SYSTEM ==========

function CowMilkingModule:InitializeIndicators()
	print("CowMilkingModule: Initializing indicator system...")

	self.CowIndicators = {}

	-- Setup indicators for existing cows
	if CowCreationModule then
		local activeCows = CowCreationModule:GetActiveCows()
		for cowId, cowModel in pairs(activeCows) do
			self:CreateMilkIndicator(cowModel, cowId)
		end
	end

	-- Start indicator update loop
	self:StartIndicatorUpdates()

	print("CowMilkingModule: Indicator system initialized!")
end

function CowMilkingModule:CreateMilkIndicator(cowModel, cowId)
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

	print("CowMilkingModule: Created milk indicator for cow " .. cowId)
end

function CowMilkingModule:UpdateCowIndicator(cowId, state)
	local indicator = self.CowIndicators[cowId]
	if not indicator or not indicator.part or not indicator.part.Parent then
		return false
	end

	-- Update indicator based on state
	if state == "ready" then
		indicator.part.Color = Color3.fromRGB(0, 255, 0)
		indicator.part.Material = Enum.Material.Neon
		indicator.part.Transparency = 0.2
		indicator.label.Text = "🥛 READY TO COLLECT!"
		indicator.label.TextColor3 = Color3.fromRGB(0, 255, 0)

	elseif state == "cooldown" then
		indicator.part.Color = Color3.fromRGB(255, 0, 0)
		indicator.part.Material = Enum.Material.Plastic
		indicator.part.Transparency = 0.5
		indicator.label.Text = "🥛 COW RESTING..."
		indicator.label.TextColor3 = Color3.fromRGB(255, 100, 100)

	elseif state == "almost_ready" then
		indicator.part.Color = Color3.fromRGB(255, 255, 0)
		indicator.part.Material = Enum.Material.Neon
		indicator.part.Transparency = 0.3
		indicator.label.Text = "🥛 ALMOST READY!"
		indicator.label.TextColor3 = Color3.fromRGB(255, 255, 0)

	elseif state == "active_milking" then
		indicator.part.Color = Color3.fromRGB(100, 255, 100)
		indicator.part.Material = Enum.Material.Neon
		indicator.part.Transparency = 0.1
		indicator.label.Text = "🥛 MILKING IN PROGRESS!"
		indicator.label.TextColor3 = Color3.fromRGB(100, 255, 100)

	else
		-- Default state
		indicator.part.Color = Color3.fromRGB(100, 100, 100)
		indicator.part.Material = Enum.Material.Plastic
		indicator.part.Transparency = 0.7
		indicator.label.Text = "🥛 CLICK TO COLLECT MILK"
		indicator.label.TextColor3 = Color3.fromRGB(255, 255, 255)
	end

	return true
end

function CowMilkingModule:StartIndicatorUpdates()
	spawn(function()
		while true do
			wait(2) -- Update every 2 seconds
			self:UpdateAllIndicators()
		end
	end)
end

function CowMilkingModule:UpdateAllIndicators()
	if not CowCreationModule then return end

	local activeCows = CowCreationModule:GetActiveCows()
	for cowId, cowModel in pairs(activeCows) do
		if cowModel and cowModel.Parent then
			local state = self:GetCowIndicatorState(cowId)
			self:UpdateCowIndicator(cowId, state)
		end
	end
end

function CowMilkingModule:GetCowIndicatorState(cowId)
	if not CowCreationModule then return "unknown" end

	local cowModel = CowCreationModule:GetCowModel(cowId)
	if not cowModel then return "unknown" end

	local owner = cowModel:GetAttribute("Owner")
	if not owner then return "unknown" end

	-- Check if cow is being milked
	if self.ClickerMilking.MilkingCows[cowId] then
		return "active_milking"
	end

	-- Find the owner player
	local ownerPlayer = Players:FindFirstChild(owner)
	if not ownerPlayer or not GameCore then return "unknown" end

	local playerData = GameCore:GetPlayerData(ownerPlayer)
	if not playerData or not playerData.livestock or not playerData.livestock.cows then return "unknown" end

	local cowData = playerData.livestock.cows[cowId]
	if not cowData then return "unknown" end

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

-- ========== VISUAL EFFECTS SYSTEM ==========

function CowMilkingModule:CreateMilkingSessionVisuals(player, cowId)
	if not CowCreationModule then return end

	local cowModel = CowCreationModule:GetCowModel(cowId)
	if not cowModel then return end

	print("🎨 CowMilkingModule: Creating milking session visuals for " .. cowId)

	-- Store session data
	self.MilkingEffects.ActiveMilkingSessions[cowId] = {
		player = player,
		startTime = os.time(),
		effects = {}
	}

	-- Create milking area effect
	self:CreateMilkingAreaEffect(cowModel, cowId)

	-- Update indicator for active milking
	self:UpdateCowIndicator(cowId, "active_milking")
end

function CowMilkingModule:CreateMilkingAreaEffect(cowModel, cowId)
	local bounds = self:GetCowBoundingBox(cowModel)
	local cowCenter = bounds.center
	local groundLevel = bounds.minY

	-- Create milking area indicator
	local milkingArea = Instance.new("Part")
	milkingArea.Name = "MilkingArea"
	milkingArea.Size = Vector3.new(12, 0.1, 8)
	milkingArea.Shape = Enum.PartType.Cylinder
	milkingArea.Material = Enum.Material.Neon
	milkingArea.Color = Color3.fromRGB(200, 255, 200)
	milkingArea.Transparency = 0.8
	milkingArea.CanCollide = false
	milkingArea.Anchored = true
	milkingArea.Position = Vector3.new(cowCenter.X, groundLevel + 0.05, cowCenter.Z)
	milkingArea.Orientation = Vector3.new(0, 0, 90)
	milkingArea.Parent = workspace

	-- Store effect for cleanup
	if not self.MilkingEffects.SessionEffects[cowId] then
		self.MilkingEffects.SessionEffects[cowId] = {}
	end
	table.insert(self.MilkingEffects.SessionEffects[cowId], milkingArea)

	-- Add pulsing effect
	spawn(function()
		while milkingArea.Parent and self.MilkingEffects.ActiveMilkingSessions[cowId] do
			local pulse = TweenService:Create(milkingArea,
				TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Transparency = 0.6}
			)
			pulse:Play()
			pulse.Completed:Wait()

			if not milkingArea.Parent then break end

			local pulseBack = TweenService:Create(milkingArea,
				TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Transparency = 0.9}
			)
			pulseBack:Play()
			pulseBack.Completed:Wait()
		end
	end)
end

function CowMilkingModule:CreateMilkDropEffect(player, cowId)
	if not CowCreationModule then return end

	local cowModel = CowCreationModule:GetCowModel(cowId)
	if not cowModel then return end

	local cowCenter = self:GetCowCenter(cowModel)

	print("✨ CowMilkingModule: Creating click milk effect for " .. cowId)

	-- Create milk drops
	for i = 1, 3 do
		local milkDrop = Instance.new("Part")
		milkDrop.Size = Vector3.new(0.2, 0.3, 0.2)
		milkDrop.Shape = Enum.PartType.Ball
		milkDrop.Material = Enum.Material.Neon
		milkDrop.Color = Color3.fromRGB(255, 255, 255)
		milkDrop.CanCollide = false
		milkDrop.Anchored = true
		milkDrop.Position = cowCenter + Vector3.new(
			math.random(-1, 1), 
			-0.5, 
			math.random(-1, 1)
		)
		milkDrop.Parent = workspace

		-- Animate milk drop falling
		local groundPosition = milkDrop.Position - Vector3.new(0, 3, 0)

		local fall = TweenService:Create(milkDrop,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{
				Position = groundPosition,
				Size = Vector3.new(0.1, 0.1, 0.1)
			}
		)
		fall:Play()

		fall.Completed:Connect(function()
			self:CreateGroundSplashEffect(groundPosition)
			milkDrop:Destroy()
		end)

		wait(0.1)
	end

	-- Create sparkle effect
	self:CreateMilkSparkles(cowCenter)
end

function CowMilkingModule:CreateGroundSplashEffect(groundPosition)
	-- Create ground splash particles
	for i = 1, 6 do
		local splash = Instance.new("Part")
		splash.Size = Vector3.new(0.05, 0.05, 0.05)
		splash.Shape = Enum.PartType.Ball
		splash.Material = Enum.Material.Neon
		splash.Color = Color3.fromRGB(255, 255, 255)
		splash.CanCollide = false
		splash.Anchored = true
		splash.Position = groundPosition
		splash.Parent = workspace

		local splashDirection = Vector3.new(
			math.random(-2, 2),
			math.random(0, 1),
			math.random(-2, 2)
		)

		local splash_tween = TweenService:Create(splash,
			TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = groundPosition + splashDirection,
				Transparency = 1
			}
		)
		splash_tween:Play()
		splash_tween.Completed:Connect(function()
			splash:Destroy()
		end)
	end
end

function CowMilkingModule:CreateMilkSparkles(cowCenter)
	for i = 1, 5 do
		local sparkle = Instance.new("Part")
		sparkle.Size = Vector3.new(0.1, 0.1, 0.1)
		sparkle.Shape = Enum.PartType.Ball
		sparkle.Material = Enum.Material.Neon
		sparkle.Color = Color3.fromRGB(255, 255, 100)
		sparkle.CanCollide = false
		sparkle.Anchored = true
		sparkle.Position = cowCenter + Vector3.new(
			math.random(-2, 2),
			math.random(-1, 1),
			math.random(-2, 2)
		)
		sparkle.Parent = workspace

		local tween = TweenService:Create(sparkle,
			TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
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
	end
end

function CowMilkingModule:CreateEnhancedMilkEffect(cowId)
	if not CowCreationModule then return end

	local cowModel = CowCreationModule:GetCowModel(cowId)
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
end

function CowMilkingModule:UpdateMilkingSessionVisuals(player, cowId)
	-- Update visual effects based on successful click
	local effects = self.MilkingEffects.SessionEffects[cowId]
	if effects then
		for _, effect in pairs(effects) do
			if effect and effect.Name == "MilkingArea" then
				-- Quick flash to show click registered
				local flash = TweenService:Create(effect,
					TweenInfo.new(0.1, Enum.EasingStyle.Quad),
					{Color = Color3.fromRGB(100, 255, 100)}
				)
				flash:Play()
				flash.Completed:Connect(function()
					local restore = TweenService:Create(effect,
						TweenInfo.new(0.3, Enum.EasingStyle.Quad),
						{Color = Color3.fromRGB(200, 255, 200)}
					)
					restore:Play()
				end)
				break
			end
		end
	end
end

-- ========== PLAYER POSITIONING SYSTEM ==========

function CowMilkingModule:PositionPlayerForMilking(player, cowId)
	if not CowCreationModule then return false end

	local cowModel = CowCreationModule:GetCowModel(cowId)
	if not cowModel then return false end

	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return false
	end

	local humanoidRootPart = character.HumanoidRootPart
	local humanoid = character:FindFirstChild("Humanoid")

	-- Store original position for restoration
	self.ClickerMilking.PlayerPositions[player.UserId] = {
		cframe = humanoidRootPart.CFrame,
		walkSpeed = humanoid and humanoid.WalkSpeed or 16,
		jumpPower = humanoid and humanoid.JumpPower or 50
	}

	-- Calculate positioning
	local cowBounds = self:GetCowBoundingBox(cowModel)
	local cowCenter = cowBounds.center
	local cowGroundLevel = cowBounds.minY

	-- Position player beside cow at ground level
	local playerStandingPosition = Vector3.new(
		cowCenter.X + 6,
		cowGroundLevel + 5,
		cowCenter.Z
	)

	-- Face toward the cow
	local lookDirection = (cowCenter - playerStandingPosition).Unit
	local playerCFrame = CFrame.lookAt(playerStandingPosition, playerStandingPosition + Vector3.new(lookDirection.X, 0, lookDirection.Z))

	-- Lock player in place
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
		humanoid.Sit = false
		humanoid.PlatformStand = false
		wait(0.1)
	end

	humanoidRootPart.CFrame = playerCFrame
	humanoidRootPart.Anchored = true

	self.ClickerMilking.PositioningObjects[player.UserId] = {
		anchored = true,
		standingPosition = playerStandingPosition,
		groundLevel = cowGroundLevel
	}

	return true
end

function CowMilkingModule:PositionPlayerForMilkingChair(player, cowId)
	-- For chair-based system, player is already positioned by the chair
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return false
	end

	local humanoid = character:FindFirstChild("Humanoid")
	local humanoidRootPart = character.HumanoidRootPart

	-- Store original values for restoration
	local userId = player.UserId
	self.ClickerMilking.PlayerPositions[userId] = {
		cframe = humanoidRootPart.CFrame,
		walkSpeed = humanoid and humanoid.WalkSpeed or 16,
		jumpPower = humanoid and humanoid.JumpPower or 50,
		isSeated = true
	}

	return true
end

function CowMilkingModule:ReleasePlayerFromMilking(player)
	local userId = player.UserId
	local character = player.Character

	-- Clean up positioning objects
	if self.ClickerMilking.PositioningObjects and self.ClickerMilking.PositioningObjects[userId] then
		self.ClickerMilking.PositioningObjects[userId] = nil
	end

	if character then
		local humanoid = character:FindFirstChild("Humanoid")
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

		-- Unanchor first
		if humanoidRootPart then
			humanoidRootPart.Anchored = false
		end

		if humanoid then
			-- Restore original movement values
			local originalData = self.ClickerMilking.PlayerPositions[userId]
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
			local originalData = self.ClickerMilking.PlayerPositions[userId]
			if originalData then
				local safePosition = originalData.cframe.Position + Vector3.new(5, 0, 5)
				humanoidRootPart.CFrame = CFrame.new(safePosition, safePosition + originalData.cframe.LookVector)
			else
				humanoidRootPart.CFrame = humanoidRootPart.CFrame + Vector3.new(3, 0, 3)
			end
		end
	end

	-- Clear stored data
	self.ClickerMilking.PlayerPositions[userId] = nil
end

function CowMilkingModule:ReleasePlayerFromMilkingChair(player)
	local userId = player.UserId
	local character = player.Character

	-- For chair system, the player position is managed by the chair
	if character then
		local humanoid = character:FindFirstChild("Humanoid")

		-- Only restore if player is no longer seated
		if humanoid and not humanoid.Sit then
			local originalData = self.ClickerMilking.PlayerPositions[userId]
			if originalData then
				humanoid.WalkSpeed = originalData.walkSpeed
				humanoid.JumpPower = originalData.jumpPower
			end
		end
	end

	-- Clear stored data
	self.ClickerMilking.PlayerPositions[userId] = nil
end

-- ========== CHAIR SYSTEM HELPERS ==========

function CowMilkingModule:SetupChairPlayerMonitoring()
	-- Monitor players for proximity to chairs
	Players.PlayerAdded:Connect(function(player)
		self:SetupPlayerProximityMonitoring(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:CleanupPlayer(player)
	end)

	-- Setup existing players
	for _, player in pairs(Players:GetPlayers()) do
		self:SetupPlayerProximityMonitoring(player)
	end
end

function CowMilkingModule:SetupPlayerProximityMonitoring(player)
	local userId = player.UserId

	-- Proximity detection for chair GUI prompts
	local connection = RunService.Heartbeat:Connect(function()
		if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
			return
		end

		-- Skip if already in a milking session
		if self.ClickerMilking.ActiveSessions[userId] then
			return
		end

		local playerPosition = player.Character.HumanoidRootPart.Position
		local nearChair = false
		local proximityDistance = 10

		-- Check distance to all chairs
		for _, obj in pairs(workspace:GetChildren()) do
			if (obj:IsA("Model") or obj:IsA("Part")) and obj.Name == "MilkingChair" then
				local chairPosition = self:GetChairPosition(obj)
				local distance = (playerPosition - chairPosition).Magnitude

				if distance <= proximityDistance then
					nearChair = true
					-- Show proximity GUI if not already showing
					if not self.ChairMilking.ChairGUIs[userId] then
						self.ChairMilking.ChairGUIs[userId] = true
						self:ShowChairProximityGUI(player, obj)
					end
					break
				end
			end
		end

		-- Hide GUI if not near any chair
		if not nearChair and self.ChairMilking.ChairGUIs[userId] then
			self.ChairMilking.ChairGUIs[userId] = nil
			self:HideChairProximityGUI(player)
		end
	end)

	self.ChairMilking.ProximityConnections[userId] = connection
end

function CowMilkingModule:IsPlayerSeatedInMilkingChair(player)
	local character = player.Character
	if not character then return false end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return false end

	-- Check if player is seated
	if humanoid.Sit then
		-- Find what they're sitting on
		for _, obj in pairs(workspace:GetChildren()) do
			if obj.Name == "MilkingChair" then
				local seat = self:FindSeatInChair(obj)
				if seat and seat.Occupant == humanoid then
					return true
				end
			end
		end
	end

	return false
end

function CowMilkingModule:LockPlayerInSeat(player, seat)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	local userId = player.UserId
	if not self.ChairMilking.SeatedPlayers[userId] then
		self.ChairMilking.SeatedPlayers[userId] = {
			originalJumpPower = humanoid.JumpPower,
			originalWalkSpeed = humanoid.WalkSpeed,
			seat = seat
		}
	end

	-- Lock player
	humanoid.JumpPower = 0
	humanoid.WalkSpeed = 0
	humanoid.PlatformStand = false
end

function CowMilkingModule:UnlockPlayer(player)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	local userId = player.UserId
	local seatedData = self.ChairMilking.SeatedPlayers[userId]

	if seatedData then
		humanoid.JumpPower = seatedData.originalJumpPower or 50
		humanoid.WalkSpeed = seatedData.originalWalkSpeed or 16
		humanoid.PlatformStand = false

		self.ChairMilking.SeatedPlayers[userId] = nil
	end
end

function CowMilkingModule:FindPlayerCowNearChair(player, chair)
	local chairPosition = self:GetChairPosition(chair)
	local nearestCow = nil
	local nearestDistance = math.huge
	local searchRadius = 50

	if not GameCore then return nil end

	local playerData = GameCore:GetPlayerData(player)
	if not playerData or not playerData.livestock or not playerData.livestock.cows then
		return nil
	end

	-- Check player's cows
	for cowId, cowData in pairs(playerData.livestock.cows) do
		if CowCreationModule then
			local cowModel = CowCreationModule:GetCowModel(cowId)
			if cowModel and cowModel.Parent then
				local cowPosition = self:GetCowCenter(cowModel)
				local distance = (chairPosition - cowPosition).Magnitude

				if distance < nearestDistance and distance < searchRadius then
					nearestDistance = distance
					nearestCow = cowModel
				end
			end
		end
	end

	return nearestCow
end

function CowMilkingModule:DoesPlayerOwnCow(player, cowModel)
	if not GameCore then return false end

	local playerData = GameCore:GetPlayerData(player)
	if not playerData or not playerData.livestock or not playerData.livestock.cows then
		return false
	end

	local cowId = self:GetCowIdFromModel(cowModel)
	return playerData.livestock.cows[cowId] ~= nil
end

function CowMilkingModule:GetCowIdFromModel(cowModel)
	local cowId = cowModel:GetAttribute("CowId")
	if cowId then
		return cowId
	end
	return cowModel.Name
end

function CowMilkingModule:FindSeatInChair(chair)
	-- Look for Seat objects
	for _, obj in pairs(chair:GetDescendants()) do
		if obj:IsA("Seat") then
			return obj
		end
	end

	-- If chair is a single part with Seat class
	if chair:IsA("Seat") then
		return chair
	end

	return nil
end

function CowMilkingModule:GetChairPosition(chair)
	if chair:IsA("Part") then
		return chair.Position
	elseif chair:IsA("Model") then
		if chair.PrimaryPart then
			return chair.PrimaryPart.Position
		else
			local cf, size = chair:GetBoundingBox()
			return cf.Position
		end
	end
	return Vector3.new(0, 0, 0)
end

function CowMilkingModule:ShowChairProximityGUI(player, chair)
	-- Implementation for showing chair proximity GUI
	self:SendRemoteEvent("ShowChairPrompt", player, "proximity", {
		title = "🪑 Milking Chair",
		subtitle = "Sit down to start milking!",
		instruction = "Ready to milk your cow!"
	})
end

function CowMilkingModule:HideChairProximityGUI(player)
	self:SendRemoteEvent("HideChairPrompt", player)
end

-- ========== UPDATE LOOPS ==========

function CowMilkingModule:StartUpdateLoops()
	-- Milking session updates
	spawn(function()
		while true do
			wait(1)
			self:UpdateMilkingSessions()
		end
	end)

	-- Chair system monitoring
	spawn(function()
		while true do
			wait(2)
			self:MonitorChairMilkingSessions()
		end
	end)
end

function CowMilkingModule:UpdateMilkingSessions()
	local currentTime = os.time()
	local sessionsToEnd = {}

	-- Check all active sessions
	for userId, session in pairs(self.ClickerMilking.ActiveSessions) do
		local player = Players:GetPlayerByUserId(userId)

		-- Check if player is still in game
		if not player or not player.Parent then
			table.insert(sessionsToEnd, userId)
			continue
		end

		-- Check for timeout (no clicks for 3 seconds)
		local timeoutTime = self.ClickerMilking.SessionTimeouts[userId] or 0
		if currentTime > timeoutTime then
			self:HandleStopMilkingSession(player)
			continue
		end

		-- Send progress update to client
		self:SendMilkingSessionUpdate(player, "progress", {
			milkCollected = session.milkCollected,
			sessionDuration = currentTime - session.startTime,
			lastClickTime = session.lastClickTime
		})

		-- Check for maximum session duration
		local maxSessionTime = 300 -- 5 minutes max
		if (currentTime - session.startTime) > maxSessionTime then
			self:HandleStopMilkingSession(player)
		end
	end

	-- Clean up ended sessions
	for _, userId in ipairs(sessionsToEnd) do
		self:CleanupMilkingSession(userId)
	end
end

function CowMilkingModule:MonitorChairMilkingSessions()
	-- Check all chair-based milking sessions
	for userId, session in pairs(self.ChairMilking.ActiveSessions) do
		local player = Players:GetPlayerByUserId(userId)

		if player and player.Parent then
			-- Check if player is still seated in milking chair
			if not self:IsPlayerSeatedInMilkingChair(player) then
				self:StopChairMilkingSession(player)
			end
		else
			-- Player left, clean up
			self.ChairMilking.ActiveSessions[userId] = nil
		end
	end
end

-- ========== CLEANUP METHODS ==========

function CowMilkingModule:CleanupMilkingSession(userId)
	local session = self.ClickerMilking.ActiveSessions[userId]
	if session then
		-- Clear cow being milked
		self.ClickerMilking.MilkingCows[session.cowId] = nil

		-- Clean up visual effects
		self:CleanupMilkingSessionVisuals(session.cowId)
	end

	-- Clear all session data
	self.ClickerMilking.ActiveSessions[userId] = nil
	self.ClickerMilking.SessionTimeouts[userId] = nil
	self.ClickerMilking.PlayerPositions[userId] = nil
	self.ClickerMilking.PositioningObjects[userId] = nil
end

function CowMilkingModule:CleanupMilkingSessionVisuals(cowId)
	-- Clean up visual effects
	local effects = self.MilkingEffects.SessionEffects[cowId]
	if effects then
		for _, effect in pairs(effects) do
			if effect and effect.Parent then
				local fadeOut = TweenService:Create(effect,
					TweenInfo.new(0.5, Enum.EasingStyle.Quad),
					{Transparency = 1}
				)
				fadeOut:Play()
				fadeOut.Completed:Connect(function()
					effect:Destroy()
				end)
			end
		end
		self.MilkingEffects.SessionEffects[cowId] = nil
	end

	-- Clear session data
	self.MilkingEffects.ActiveMilkingSessions[cowId] = nil

	-- Update indicator back to normal
	self:UpdateCowIndicator(cowId, "ready")
end

function CowMilkingModule:CleanupPlayer(player)
	local userId = player.UserId

	-- Stop any active milking sessions
	if self.ClickerMilking.ActiveSessions[userId] then
		self:HandleStopMilkingSession(player)
	end

	if self.ChairMilking.ActiveSessions[userId] then
		self:StopChairMilkingSession(player)
	end

	-- Disconnect proximity monitoring
	if self.ChairMilking.ProximityConnections[userId] then
		self.ChairMilking.ProximityConnections[userId]:Disconnect()
		self.ChairMilking.ProximityConnections[userId] = nil
	end

	-- Clean up GUI state
	self.ChairMilking.ChairGUIs[userId] = nil
	self.ChairMilking.SeatedPlayers[userId] = nil
end

-- ========== UTILITY FUNCTIONS ==========

function CowMilkingModule:GetCowBounds(cowModel)
	if cowModel.PrimaryPart then
		return cowModel.PrimaryPart.Position, cowModel.PrimaryPart.Size
	end

	local cframe, size = cowModel:GetBoundingBox()
	return cframe.Position, size
end

function CowMilkingModule:GetCowBoundingBox(cowModel)
	local minX, minY, minZ = math.huge, math.huge, math.huge
	local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge

	for _, part in pairs(cowModel:GetDescendants()) do
		if part:IsA("BasePart") then
			local pos = part.Position
			local size = part.Size

			local partMinX = pos.X - size.X/2
			local partMaxX = pos.X + size.X/2
			local partMinY = pos.Y - size.Y/2
			local partMaxY = pos.Y + size.Y/2
			local partMinZ = pos.Z - size.Z/2
			local partMaxZ = pos.Z + size.Z/2

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

function CowMilkingModule:GetCowCenter(cowModel)
	local bodyPart = nil
	local possibleBodyParts = {"HumanoidRootPart", "Torso", "UpperTorso", "Body", "Middle"}

	for _, partName in ipairs(possibleBodyParts) do
		bodyPart = cowModel:FindFirstChild(partName)
		if bodyPart then break end
	end

	if bodyPart then
		return bodyPart.Position
	end

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

	return cowModel.PrimaryPart and cowModel.PrimaryPart.Position or Vector3.new(0, 0, 0)
end

function CowMilkingModule:SendNotification(player, title, message, notificationType)
	if GameCore and GameCore.SendNotification then
		GameCore:SendNotification(player, title, message, notificationType)
	else
		print("NOTIFICATION for " .. player.Name .. ": [" .. (notificationType or "info"):upper() .. "] " .. title .. " - " .. message)
	end
end

function CowMilkingModule:SendMilkingSessionUpdate(player, updateType, data)
	self:SendRemoteEvent("MilkingSessionUpdate", player, updateType, data)
end

function CowMilkingModule:SendPlayerDataUpdate(player, playerData)
	self:SendRemoteEvent("PlayerDataUpdated", player, playerData)
end

function CowMilkingModule:SendRemoteEvent(eventName, player, ...)
	local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if remoteFolder then
		local remoteEvent = remoteFolder:FindFirstChild(eventName)
		if remoteEvent then
			pcall(function()
				remoteEvent:FireClient(player)
			end)
		end
	end
end

-- ========== LEGACY COMPATIBILITY ==========

function CowMilkingModule:HandleCowMilkCollection(player, cowId)
	-- Legacy compatibility - redirect to clicker system
	return self:HandleStartMilkingSession(player, cowId)
end

function CowMilkingModule:HandleChairMilkingStart(player, chairName)
	-- Chair system compatibility
	return true -- Chair system handles this automatically when player sits
end

function CowMilkingModule:HandleChairMilkingStop(player)
	-- Force player out of chair to stop milking
	local userId = player.UserId
	local session = self.ChairMilking.ActiveSessions[userId]

	if session and session.seat then
		session.seat:Sit(nil) -- Remove player from seat
	end

	return true
end

-- ========== PUBLIC API ==========

function CowMilkingModule:SetupExistingCows()
	-- Setup click detection for existing cows
	if CowCreationModule then
		local activeCows = CowCreationModule:GetActiveCows()
		for cowId, cowModel in pairs(activeCows) do
			self:SetupCowClickDetection(cowModel, cowId)
			if not self.CowIndicators[cowId] then
				self:CreateMilkIndicator(cowModel, cowId)
			end
		end
	end
end

function CowMilkingModule:SetupCowClickDetection(cowModel, cowId)
	-- Remove existing click detectors
	for _, obj in pairs(cowModel:GetDescendants()) do
		if obj:IsA("ClickDetector") then
			obj:Destroy()
		end
	end

	-- Find clickable parts
	local clickableParts = {}
	local priorityNames = {"humanoidrootpart", "torso", "body", "middle"}

	for _, name in ipairs(priorityNames) do
		for _, part in pairs(cowModel:GetDescendants()) do
			if part:IsA("BasePart") and part.Name:lower():find(name) then
				table.insert(clickableParts, part)
			end
		end
	end

	-- Fallback to large parts
	if #clickableParts < 2 then
		for _, part in pairs(cowModel:GetDescendants()) do
			if part:IsA("BasePart") then
				local volume = part.Size.X * part.Size.Y * part.Size.Z
				if volume > 6 then
					table.insert(clickableParts, part)
				end
			end
		end
	end

	-- Add click detectors
	for _, part in ipairs(clickableParts) do
		local detector = Instance.new("ClickDetector")
		detector.MaxActivationDistance = 25
		detector.Parent = part

		detector.MouseClick:Connect(function(player)
			local owner = cowModel:GetAttribute("Owner")
			if player.Name == owner then
				self:HandleCowMilkCollection(player, cowId)
			else
				self:SendNotification(player, "Not Your Cow", "This cow belongs to " .. owner .. "!", "warning")
			end
		end)
	end
end

function CowMilkingModule:RegisterNewCow(cowModel, cowId)
	-- Called when a new cow is created
	self:SetupCowClickDetection(cowModel, cowId)
	self:CreateMilkIndicator(cowModel, cowId)
end

function CowMilkingModule:UnregisterCow(cowId)
	-- Clean up when cow is removed
	if self.CowIndicators[cowId] then
		local indicator = self.CowIndicators[cowId]
		if indicator.part and indicator.part.Parent then
			indicator.part:Destroy()
		end
		self.CowIndicators[cowId] = nil
	end

	-- Clean up any active sessions
	if self.ClickerMilking.MilkingCows[cowId] then
		local userId = self.ClickerMilking.MilkingCows[cowId]
		local player = Players:GetPlayerByUserId(userId)
		if player then
			self:HandleStopMilkingSession(player)
		end
	end

	-- Clean up visual effects
	self:CleanupMilkingSessionVisuals(cowId)
end

return CowMilkingModule