--[[
    FIXED CowMilkingModule.lua - Complete Milking System Implementation
    Place in: ServerScriptService/CowMilkingModule.lua
    
    FEATURES:
    ✅ Complete milking session management
    ✅ Chair-based milking system
    ✅ Proximity detection for cows and chairs
    ✅ Click-based milk collection
    ✅ Session timeout handling
    ✅ Multi-cow support
    ✅ Enhanced visual feedback
]]

local CowMilkingModule = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Module State
CowMilkingModule.ActiveSessions = {} -- [userId] = sessionData
CowMilkingModule.ProximityConnections = {} -- [userId] = {connections}
CowMilkingModule.MilkingChairs = {} -- [chairId] = chairModel
CowMilkingModule.CowProximity = {} -- [userId] = {cowsNearby}

-- Configuration
CowMilkingModule.Config = {
	proximityDistance = 15, -- Distance to detect cows/chairs
	milkingDistance = 8,    -- Distance required to start milking
	sessionTimeout = 3,     -- Seconds before session times out
	milkPerClick = 1,       -- Base milk per click
	maxMilkPerSession = 50, -- Maximum milk per session
	chairCheckInterval = 2  -- How often to check chair proximity (seconds)
}

-- References (injected during initialization)
local GameCore = nil
local CowCreationModule = nil

-- Remote Events
local RemoteEvents = {}
local RemoteFunctions = {}

-- ========== INITIALIZATION ==========

function CowMilkingModule:Initialize(gameCore, cowCreationModule)
	print("CowMilkingModule: Initializing complete milking system...")

	GameCore = gameCore
	CowCreationModule = cowCreationModule

	-- Setup remote events
	self:SetupRemoteEvents()

	-- Setup milking chairs
	self:SetupMilkingChairs()

	-- Start proximity monitoring
	self:StartProximityMonitoring()

	-- Setup player handlers
	self:SetupPlayerHandlers()

	print("CowMilkingModule: Complete milking system initialized!")
	return true
end

function CowMilkingModule:SetupRemoteEvents()
	print("CowMilkingModule: Setting up milking remote events...")

	local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "GameRemotes"
		remoteFolder.Parent = ReplicatedStorage
	end

	local milkingEvents = {
		"ShowChairPrompt",
		"HideChairPrompt", 
		"StartMilkingSession",
		"StopMilkingSession",
		"ContinueMilking",
		"MilkingSessionUpdate"
	}

	-- Create remote events
	for _, eventName in ipairs(milkingEvents) do
		local existing = remoteFolder:FindFirstChild(eventName)
		if not existing then
			local remote = Instance.new("RemoteEvent")
			remote.Name = eventName
			remote.Parent = remoteFolder
			print("Created RemoteEvent: " .. eventName)
		end
		RemoteEvents[eventName] = remoteFolder:FindFirstChild(eventName)
	end

	-- Connect handlers
	self:ConnectEventHandlers()

	print("CowMilkingModule: Remote events setup complete")
end

function CowMilkingModule:ConnectEventHandlers()
	-- Handle milking session start requests
	if RemoteEvents.StartMilkingSession then
		RemoteEvents.StartMilkingSession.OnServerEvent:Connect(function(player, cowId)
			pcall(function()
				self:HandleStartMilkingSession(player, cowId)
			end)
		end)
	end

	-- Handle milking session stop requests
	if RemoteEvents.StopMilkingSession then
		RemoteEvents.StopMilkingSession.OnServerEvent:Connect(function(player)
			pcall(function()
				self:HandleStopMilkingSession(player)
			end)
		end)
	end

	-- Handle milk collection clicks
	if RemoteEvents.ContinueMilking then
		RemoteEvents.ContinueMilking.OnServerEvent:Connect(function(player)
			pcall(function()
				self:HandleContinueMilking(player)
			end)
		end)
	end

	print("CowMilkingModule: Event handlers connected")
end

-- ========== CHAIR SETUP ==========

function CowMilkingModule:SetupMilkingChairs()
	print("CowMilkingModule: Setting up milking chairs...")

	-- Find existing milking chairs first
	local existingChairs = self:ScanForExistingChairs()

	if existingChairs > 0 then
		print("✅ CowMilkingModule: Using " .. existingChairs .. " existing MilkingChair(s) from workspace")
		print("CowMilkingModule: Skipping chair creation - using existing chairs")
	else
		print("⚠️ CowMilkingModule: No existing chairs found, creating default chairs...")
		self:CreateDefaultChairs()
	end

	local totalChairs = self:CountTable(self.MilkingChairs)
	print("CowMilkingModule: Total milking chairs available: " .. totalChairs)
end

function CowMilkingModule:ScanForExistingChairs()
	print("CowMilkingModule: Scanning for existing MilkingChair models...")

	local chairsFound = 0

	for _, obj in pairs(workspace:GetChildren()) do
		if obj.Name == "MilkingChair" and obj:IsA("Model") then
			-- This is a MilkingChair model
			self:RegisterExistingChairModel(obj)
			chairsFound = chairsFound + 1
		elseif obj.Name == "MilkingChair" and obj:IsA("Seat") then
			-- This is a simple seat chair
			self:RegisterMilkingChair(obj)
			chairsFound = chairsFound + 1
		elseif obj:GetAttribute("IsMilkingChair") then
			-- This has the milking chair attribute
			if obj:IsA("Model") then
				self:RegisterExistingChairModel(obj)
			else
				self:RegisterMilkingChair(obj)
			end
			chairsFound = chairsFound + 1
		end
	end

	print("CowMilkingModule: Found " .. chairsFound .. " existing MilkingChair(s)")
	return chairsFound
end

function CowMilkingModule:RegisterExistingChairModel(chairModel)
	print("CowMilkingModule: Registering existing MilkingChair model: " .. chairModel.Name)

	-- Find the Seat part within the model
	local seatPart = nil

	-- Look for a Seat in the model
	for _, child in pairs(chairModel:GetDescendants()) do
		if child:IsA("Seat") then
			seatPart = child
			break
		end
	end

	if not seatPart then
		warn("CowMilkingModule: No Seat found in MilkingChair model: " .. chairModel.Name)
		return false
	end

	-- Set up the chair for milking system
	local chairId = chairModel:GetAttribute("ChairId") or ("existing_chair_" .. tick() .. "_" .. math.random(1000, 9999))

	-- Add attributes to both model and seat
	chairModel:SetAttribute("IsMilkingChair", true)
	chairModel:SetAttribute("ChairId", chairId)
	seatPart:SetAttribute("IsMilkingChair", true)
	seatPart:SetAttribute("ChairId", chairId)
	seatPart:SetAttribute("ParentModel", chairModel.Name)

	-- Register the seat part (this is what players will sit on)
	self.MilkingChairs[chairId] = seatPart

	-- Setup chair occupancy detection
	if seatPart:IsA("Seat") then
		local success, connection = pcall(function()
			return seatPart:GetPropertyChangedSignal("Occupant"):Connect(function()
				self:HandleChairOccupancyChange(seatPart)
			end)
		end)

		if success then
			print("✅ Occupancy detection setup for existing chair: " .. chairId)
		else
			warn("⚠️ Failed to setup occupancy detection for existing chair: " .. chairId)
		end
	end

	print("✅ Registered existing MilkingChair model: " .. chairId .. " (Seat: " .. seatPart.Name .. ")")
	return true
end

function CowMilkingModule:CreateDefaultChairs()
	-- Create chairs near cow spawn areas
	local basePosition = Vector3.new(-270, -2, 50) -- Near cow area

	for i = 1, 3 do
		local chair = self:CreateMilkingChair(basePosition + Vector3.new(i * 8, 0, 0))
		if chair then
			print("Created milking chair " .. i .. " at " .. tostring(chair.Position))
		end
	end
end

function CowMilkingModule:CreateMilkingChair(position)
	local success, chair = pcall(function()
		local seat = Instance.new("Seat")
		seat.Name = "MilkingChair"
		seat.Size = Vector3.new(4, 2, 4)
		seat.Position = position
		seat.BrickColor = BrickColor.new("Bright brown")
		seat.Material = Enum.Material.Wood
		seat.Anchored = true
		seat.CanCollide = true

		-- Add chair identifier
		seat:SetAttribute("IsMilkingChair", true)
		seat:SetAttribute("ChairId", "chair_" .. tick() .. "_" .. math.random(1000, 9999))

		-- Ensure it's properly configured as a seat
		seat.Shape = Enum.PartType.Block
		seat.TopSurface = Enum.SurfaceType.Smooth
		seat.BottomSurface = Enum.SurfaceType.Smooth

		return seat
	end)

	if not success or not chair then
		warn("CowMilkingModule: Failed to create milking chair")
		return nil
	end

	-- Add visual elements safely
	pcall(function()
		-- Add backrest
		local backrest = Instance.new("Part")
		backrest.Name = "Backrest"
		backrest.Size = Vector3.new(4, 4, 0.5)
		backrest.Position = position + Vector3.new(0, 2, -1.75)
		backrest.BrickColor = BrickColor.new("Bright brown")
		backrest.Material = Enum.Material.Wood
		backrest.Anchored = true
		backrest.CanCollide = false
		backrest.Shape = Enum.PartType.Block
		backrest.Parent = workspace

		-- Add bucket beside chair
		local bucket = Instance.new("Part")
		bucket.Name = "MilkBucket"
		bucket.Size = Vector3.new(1.5, 2, 1.5)
		bucket.Position = position + Vector3.new(3, 0, 0)
		bucket.BrickColor = BrickColor.new("Light gray")
		bucket.Material = Enum.Material.Metal
		bucket.Shape = Enum.PartType.Cylinder
		bucket.Anchored = true
		bucket.CanCollide = false
		bucket.Parent = workspace
	end)

	-- Parent the chair to workspace
	chair.Parent = workspace

	-- Register the chair
	self:RegisterMilkingChair(chair)

	print("✅ Created milking chair at " .. tostring(position))
	return chair
end

function CowMilkingModule:RegisterMilkingChair(chair)
	local chairId = chair:GetAttribute("ChairId") or ("chair_" .. tick() .. "_" .. math.random(1000, 9999))
	chair:SetAttribute("ChairId", chairId)
	self.MilkingChairs[chairId] = chair

	-- Setup chair occupancy detection (only for Seat objects)
	if chair:IsA("Seat") then
		local success, connection = pcall(function()
			return chair:GetPropertyChangedSignal("Occupant"):Connect(function()
				self:HandleChairOccupancyChange(chair)
			end)
		end)

		if success then
			print("✅ Occupancy detection setup for chair: " .. chairId)
		else
			warn("⚠️ Failed to setup occupancy detection for chair: " .. chairId)
		end
	else
		warn("⚠️ Chair is not a Seat object: " .. chairId .. " (" .. chair.ClassName .. ")")
	end

	print("Registered milking chair: " .. chairId)
end

-- ========== PROXIMITY MONITORING ==========

function CowMilkingModule:StartProximityMonitoring()
	print("CowMilkingModule: Starting proximity monitoring...")

	-- Monitor player proximity to cows and chairs
	spawn(function()
		while true do
			wait(self.Config.chairCheckInterval)
			self:UpdateProximityDetection()
		end
	end)

	print("CowMilkingModule: Proximity monitoring started")
end

function CowMilkingModule:UpdateProximityDetection()
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			self:CheckPlayerProximity(player)
		end
	end
end

function CowMilkingModule:CheckPlayerProximity(player)
	local character = player.Character
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local playerPos = rootPart.Position
	local userId = player.UserId

	-- Skip if player is in active milking session
	if self.ActiveSessions[userId] then return end

	-- Check proximity to cows
	local nearbyObjects = self:GetNearbyMilkableObjects(player, playerPos)

	if #nearbyObjects > 0 then
		-- Player is near milkable objects
		self:ShowProximityPrompt(player, nearbyObjects)
	else
		-- Player is not near anything milkable
		self:HideProximityPrompt(player)
	end
end

function CowMilkingModule:GetNearbyMilkableObjects(player, playerPos)
	local nearby = {}

	-- Check cows
	if CowCreationModule and CowCreationModule.GetActiveCows then
		local activeCows = CowCreationModule:GetActiveCows()
		for cowId, cowModel in pairs(activeCows) do
			if cowModel and cowModel.Parent then
				local owner = cowModel:GetAttribute("Owner")
				if owner == player.Name then
					local cowPos = self:GetModelCenter(cowModel)
					local distance = (playerPos - cowPos).Magnitude

					if distance <= self.Config.proximityDistance then
						table.insert(nearby, {
							type = "cow",
							model = cowModel,
							id = cowId,
							distance = distance
						})
					end
				end
			end
		end
	end

	-- Check chairs (only if near cows)
	if #nearby > 0 then
		for chairId, chair in pairs(self.MilkingChairs) do
			if chair and chair.Parent then
				local distance = (playerPos - chair.Position).Magnitude
				if distance <= self.Config.proximityDistance then
					table.insert(nearby, {
						type = "chair",
						model = chair,
						id = chairId,
						distance = distance
					})
				end
			end
		end
	end

	return nearby
end

function CowMilkingModule:ShowProximityPrompt(player, nearbyObjects)
	local hasCow = false
	local hasChair = false

	for _, obj in ipairs(nearbyObjects) do
		if obj.type == "cow" then hasCow = true end
		if obj.type == "chair" then hasChair = true end
	end

	if hasCow and hasChair then
		-- Show milking prompt
		if RemoteEvents.ShowChairPrompt then
			RemoteEvents.ShowChairPrompt:FireClient(player, "proximity", {
				title = "🥛 Milking Available",
				subtitle = "Sit in the chair to start milking!",
				instruction = "Your cow is ready to be milked",
				canUse = true
			})
		end
	elseif hasCow then
		-- Show "need chair" prompt
		if RemoteEvents.ShowChairPrompt then
			RemoteEvents.ShowChairPrompt:FireClient(player, "proximity", {
				title = "🪑 Chair Needed",
				subtitle = "Find a milking chair to start milking",
				instruction = "Look for a brown wooden chair nearby",
				canUse = false
			})
		end
	end
end

function CowMilkingModule:HideProximityPrompt(player)
	if RemoteEvents.HideChairPrompt then
		RemoteEvents.HideChairPrompt:FireClient(player)
	end
end

-- ========== CHAIR OCCUPANCY HANDLING ==========

function CowMilkingModule:HandleChairOccupancyChange(chair)
	if not chair or not chair.Parent or not chair:IsA("Seat") then
		return
	end

	local success, occupant = pcall(function()
		return chair.Occupant
	end)

	if not success then
		warn("CowMilkingModule: Failed to get chair occupant")
		return
	end

	if occupant then
		-- Player sat down
		local character = occupant.Parent
		local player = Players:GetPlayerFromCharacter(character)

		if player then
			print("🪑 Player " .. player.Name .. " sat in milking chair")
			self:HandlePlayerSatDown(player, chair)
		end
	else
		-- Player left chair - handled by session monitoring
		print("🪑 Chair became empty")
	end
end

function CowMilkingModule:HandlePlayerSatDown(player, chair)
	print("🪑 Player " .. player.Name .. " sat in milking chair")

	-- Check if player has nearby cows
	local character = player.Character
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local nearbyObjects = self:GetNearbyMilkableObjects(player, rootPart.Position)
	local nearbyCow = nil

	for _, obj in ipairs(nearbyObjects) do
		if obj.type == "cow" then
			nearbyCow = obj
			break
		end
	end

	if nearbyCow then
		-- Start milking session
		self:StartMilkingSession(player, nearbyCow.id, chair)
	else
		-- No cow nearby
		self:SendNotification(player, "🐄 No Cow Nearby", 
			"Move closer to your cow before sitting down!", "warning")
	end
end

-- ========== MILKING SESSION MANAGEMENT ==========

function CowMilkingModule:StartMilkingSession(player, cowId, chair)
	local userId = player.UserId

	print("🥛 Starting milking session for " .. player.Name .. " with cow " .. cowId)

	-- Check if already in session
	if self.ActiveSessions[userId] then
		self:HandleStopMilkingSession(player)
		wait(0.1)
	end

	-- Get cow data
	local cowData = nil
	if CowCreationModule and CowCreationModule.GetCowData then
		cowData = CowCreationModule:GetCowData(player, cowId)
	end

	if not cowData then
		self:SendNotification(player, "🐄 Cow Error", "Could not find cow data!", "error")
		return false
	end

	-- Check cooldown
	local currentTime = os.time()
	local lastMilked = cowData.lastMilkCollection or 0
	local cooldown = cowData.cooldown or 60

	if (currentTime - lastMilked) < cooldown then
		local timeLeft = cooldown - (currentTime - lastMilked)
		self:SendNotification(player, "⏰ Cow Not Ready", 
			"Cow needs " .. timeLeft .. " more seconds to produce milk!", "warning")
		return false
	end

	-- Create session
	local session = {
		userId = userId,
		playerId = player.UserId,
		cowId = cowId,
		chairId = chair:GetAttribute("ChairId"),
		startTime = currentTime,
		milkCollected = 0,
		lastClickTime = currentTime,
		isActive = true,
		maxMilk = cowData.milkAmount * 10 -- Allow multiple collections
	}

	self.ActiveSessions[userId] = session

	-- Show milking GUI
	if RemoteEvents.ShowChairPrompt then
		RemoteEvents.ShowChairPrompt:FireClient(player, "milking", {
			title = "🥛 Milking Session Active",
			subtitle = "Click to collect milk!",
			instruction = "Stay seated and click to collect milk. Leave chair to stop.",
			cowId = cowId,
			maxMilk = session.maxMilk
		})
	end

	-- Start session monitoring
	self:StartSessionMonitoring(userId)

	-- Send session update
	self:SendSessionUpdate(player, "started", session)

	self:SendNotification(player, "🥛 Milking Started!", 
		"Click to collect milk! Session will timeout after " .. self.Config.sessionTimeout .. " seconds of inactivity.", "success")

	return true
end

function CowMilkingModule:HandleStartMilkingSession(player, cowId)
	print("🎮 Received start milking request from " .. player.Name .. " for cow " .. (cowId or "unknown"))

	-- Find chair player is sitting in
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then 
		self:SendNotification(player, "🪑 Not Seated", "You must be sitting in a milking chair!", "warning")
		return
	end

	-- Safely check if player is sitting
	local isSeated = false
	local seatPart = nil

	local success, result = pcall(function()
		isSeated = humanoid.Sit
		seatPart = humanoid.SeatPart
		return true
	end)

	if not success or not isSeated then
		self:SendNotification(player, "🪑 Not Seated", "You must be sitting in a milking chair!", "warning")
		return
	end

	-- Check if it's a milking chair
	if not seatPart or not seatPart:GetAttribute("IsMilkingChair") then
		self:SendNotification(player, "🪑 Wrong Chair", "You must be sitting in a milking chair!", "warning")
		return
	end

	-- Start session
	self:StartMilkingSession(player, cowId, seatPart)
end

function CowMilkingModule:HandleStopMilkingSession(player)
	local userId = player.UserId
	local session = self.ActiveSessions[userId]

	if not session then return end

	print("🛑 Stopping milking session for " .. player.Name)

	-- Calculate final rewards
	local totalMilk = session.milkCollected
	local sessionDuration = os.time() - session.startTime

	-- Give rewards
	if totalMilk > 0 then
		self:GiveMilkRewards(player, session.cowId, totalMilk)

		self:SendNotification(player, "🥛 Milking Complete!", 
			"Collected " .. totalMilk .. " milk in " .. sessionDuration .. " seconds!", "success")
	end

	-- Clean up session
	self.ActiveSessions[userId] = nil

	-- Hide GUI
	if RemoteEvents.HideChairPrompt then
		RemoteEvents.HideChairPrompt:FireClient(player)
	end

	-- Send session update
	self:SendSessionUpdate(player, "ended", {
		totalMilk = totalMilk,
		duration = sessionDuration
	})
end

function CowMilkingModule:HandleContinueMilking(player)
	local userId = player.UserId
	local session = self.ActiveSessions[userId]

	if not session or not session.isActive then 
		return 
	end

	print("🖱️ Continue milking click from " .. player.Name)

	-- Check if player is still seated
	local character = player.Character
	if not character then
		self:HandleStopMilkingSession(player)
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		self:HandleStopMilkingSession(player)
		return
	end

	-- Safely check if still seated
	local isSeated = false
	local success = pcall(function()
		isSeated = humanoid.Sit
	end)

	if not success or not isSeated then
		self:HandleStopMilkingSession(player)
		return
	end

	-- Collect milk
	local milkCollected = self.Config.milkPerClick
	session.milkCollected = session.milkCollected + milkCollected
	session.lastClickTime = os.time()

	print("🥛 " .. player.Name .. " collected " .. milkCollected .. " milk (total: " .. session.milkCollected .. ")")

	-- Check limits
	if session.milkCollected >= session.maxMilk then
		self:SendNotification(player, "🥛 Cow Empty!", 
			"This cow has no more milk! Session ending.", "info")
		self:HandleStopMilkingSession(player)
		return
	end

	-- Send progress update
	self:SendSessionUpdate(player, "progress", {
		milkCollected = session.milkCollected,
		maxMilk = session.maxMilk,
		sessionDuration = os.time() - session.startTime
	})
end

-- ========== SESSION MONITORING ==========

function CowMilkingModule:StartSessionMonitoring(userId)
	spawn(function()
		while self.ActiveSessions[userId] do
			wait(1)

			local session = self.ActiveSessions[userId]
			if not session then break end

			local currentTime = os.time()
			local timeSinceLastClick = currentTime - session.lastClickTime

			-- Check timeout
			if timeSinceLastClick >= self.Config.sessionTimeout then
				local player = Players:GetPlayerByUserId(userId)
				if player then
					self:SendNotification(player, "⏰ Session Timeout", 
						"Milking session ended due to inactivity.", "info")
					self:HandleStopMilkingSession(player)
				end
				break
			end
		end
	end)
end

-- ========== REWARD SYSTEM ==========

function CowMilkingModule:GiveMilkRewards(player, cowId, milkAmount)
	print("🎁 Giving " .. milkAmount .. " milk rewards to " .. player.Name)

	if not GameCore then
		warn("CowMilkingModule: GameCore not available for rewards")
		return
	end

	local playerData = GameCore:GetPlayerData(player)
	if not playerData then
		warn("CowMilkingModule: No player data for rewards")
		return
	end

	-- Add milk to inventory
	if not playerData.farming then
		playerData.farming = {inventory = {}}
	end
	if not playerData.farming.inventory then
		playerData.farming.inventory = {}
	end

	playerData.farming.inventory.milk = (playerData.farming.inventory.milk or 0) + milkAmount

	-- Update cow data
	if playerData.livestock and playerData.livestock.cows and playerData.livestock.cows[cowId] then
		local cowData = playerData.livestock.cows[cowId]
		cowData.lastMilkCollection = os.time()
		cowData.totalMilkProduced = (cowData.totalMilkProduced or 0) + milkAmount
	end

	-- Update stats
	if not playerData.stats then
		playerData.stats = {}
	end
	playerData.stats.milkCollected = (playerData.stats.milkCollected or 0) + milkAmount
	playerData.stats.milkingSessions = (playerData.stats.milkingSessions or 0) + 1

	-- Save data
	if GameCore.SavePlayerData then
		GameCore:SavePlayerData(player)
	end

	-- Trigger UI update
	if GameCore.RemoteEvents and GameCore.RemoteEvents.PlayerDataUpdated then
		GameCore.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
	end
end

-- ========== UTILITY FUNCTIONS ==========

function CowMilkingModule:SendSessionUpdate(player, updateType, data)
	if RemoteEvents.MilkingSessionUpdate then
		RemoteEvents.MilkingSessionUpdate:FireClient(player, updateType, data)
	end
end

function CowMilkingModule:SendNotification(player, title, message, notificationType)
	if GameCore and GameCore.SendNotification then
		GameCore:SendNotification(player, title, message, notificationType)
	else
		print("NOTIFICATION for " .. player.Name .. ": [" .. (notificationType or "info"):upper() .. "] " .. title .. " - " .. message)
	end
end

function CowMilkingModule:GetModelCenter(model)
	if model.PrimaryPart then
		return model.PrimaryPart.Position
	end

	local cf, size = model:GetBoundingBox()
	return cf.Position
end

function CowMilkingModule:CountTable(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- ========== PLAYER HANDLERS ==========

function CowMilkingModule:SetupPlayerHandlers()
	-- Handle player leaving
	Players.PlayerRemoving:Connect(function(player)
		local userId = player.UserId

		-- Clean up active session
		if self.ActiveSessions[userId] then
			print("🧹 Cleaning up milking session for leaving player: " .. player.Name)
			self.ActiveSessions[userId] = nil
		end

		-- Clean up proximity connections
		if self.ProximityConnections[userId] then
			for _, connection in pairs(self.ProximityConnections[userId]) do
				if connection and connection.Connected then
					connection:Disconnect()
				end
			end
			self.ProximityConnections[userId] = nil
		end
	end)

	print("CowMilkingModule: Player handlers setup complete")
end

-- ========== PUBLIC API ==========

function CowMilkingModule:GetSystemStatus()
	return {
		activeSessions = {
			count = self:CountTable(self.ActiveSessions),
			sessions = self.ActiveSessions
		},
		chairs = {
			count = self:CountTable(self.MilkingChairs),
			chairs = self.MilkingChairs
		},
		remoteEvents = {
			count = self:CountTable(RemoteEvents),
			events = RemoteEvents
		}
	}
end

function CowMilkingModule:GetPlayerSession(player)
	return self.ActiveSessions[player.UserId]
end

function CowMilkingModule:ForceStartMilkingForDebug(player, cowId)
	print("🔧 DEBUG: Force starting milking session for " .. player.Name)

	-- Create a mock chair for testing
	local mockChair = {
		GetAttribute = function() return "debug_chair" end,
		Position = Vector3.new(0, 0, 0)
	}

	return self:StartMilkingSession(player, cowId, mockChair)
end

-- ========== CLEANUP ==========

function CowMilkingModule:Cleanup()
	-- Stop all active sessions
	for userId, session in pairs(self.ActiveSessions) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			self:HandleStopMilkingSession(player)
		end
	end

	-- Clean up connections
	for userId, connections in pairs(self.ProximityConnections) do
		for _, connection in pairs(connections) do
			if connection and connection.Connected then
				connection:Disconnect()
			end
		end
	end

	self.ActiveSessions = {}
	self.ProximityConnections = {}

	print("CowMilkingModule: Cleanup complete")
end

return CowMilkingModule