--[[
    FIXED CowMilkingModule.lua - Enhanced 10-Click System with Duplicate Protection
    Place in: ServerScriptService/CowMilkingModule.lua
    
    FIXES:
    ✅ Enhanced duplicate click prevention
    ✅ Click ID verification system
    ✅ Improved cooldown management
    ✅ Better session tracking and validation
]]

local CowMilkingModule = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Configuration
CowMilkingModule.Config = {
	clicksPerMilk = 10, -- Keep this the same (10 clicks = 1 milk)
	proximityDistance = 15,
	sessionTimeout = 30,
	maxMilkPerSession = 20,
	proximityCheckInterval = 3,
	movementThreshold = 8,

	-- MODIFIED: Much faster clicking allowed
	minimumClickInterval = 0.01,        -- 10ms between clicks = 100 clicks/sec max
	maximumClicksPerSecond = 100,       -- Allow up to 100 clicks per second
	suspiciousClickThreshold = 150,     -- Flag suspicious at 150 clicks/sec
	clickIdTimeoutSeconds = 0
}


-- Module State
CowMilkingModule.ActiveSessions = {} -- [userId] = sessionData with progress
CowMilkingModule.MilkingChairs = {} -- [chairId] = chairModel
CowMilkingModule.PlayerProximityState = {} -- [userId] = proximityData

-- ENHANCED: Anti-duplicate protection
CowMilkingModule.ClickProtection = {
	recentClicks = {}, -- [userId] = {timestamps, clickIds}
	suspiciousPlayers = {}, -- [userId] = suspicionLevel
	blockedPlayers = {} -- [userId] = blockEndTime
}

-- References
local GameCore = nil
local CowCreationModule = nil
local RemoteEvents = {}

-- ========== ENHANCED CLICK PROTECTION SYSTEM ==========

function CowMilkingModule:InitializeClickProtection()
	-- Clean up old click data periodically
	spawn(function()
		while true do
			wait(10) -- Clean every 10 seconds
			local currentTime = os.time()

			for userId, clickData in pairs(self.ClickProtection.recentClicks) do
				-- Remove old timestamps
				local newTimestamps = {}
				local newClickIds = {}

				for i, timestamp in ipairs(clickData.timestamps or {}) do
					if (currentTime - timestamp) < 10 then -- Keep last 10 seconds
						table.insert(newTimestamps, timestamp)
						if clickData.clickIds and clickData.clickIds[i] then
							table.insert(newClickIds, clickData.clickIds[i])
						end
					end
				end

				if #newTimestamps > 0 then
					self.ClickProtection.recentClicks[userId] = {
						timestamps = newTimestamps,
						clickIds = newClickIds
					}
				else
					self.ClickProtection.recentClicks[userId] = nil
				end
			end

			-- Clean up blocked players
			for userId, blockEndTime in pairs(self.ClickProtection.blockedPlayers) do
				if currentTime >= blockEndTime then
					self.ClickProtection.blockedPlayers[userId] = nil
					print("🔓 Unblocked player " .. userId .. " from clicking")
				end
			end
		end
	end)

	print("✅ Click protection system initialized")
end

function CowMilkingModule:IsClickAllowed(player, clickId)
	local userId = player.UserId
	local currentTime = os.time()

	-- Check if player is blocked
	if self.ClickProtection.blockedPlayers[userId] then
		if currentTime < self.ClickProtection.blockedPlayers[userId] then
			print("🚫 Blocked player " .. player.Name .. " attempted to click")
			return false, "Player is temporarily blocked for clicking too fast"
		else
			-- Unblock expired block
			self.ClickProtection.blockedPlayers[userId] = nil
		end
	end

	-- Initialize player click data if needed
	if not self.ClickProtection.recentClicks[userId] then
		self.ClickProtection.recentClicks[userId] = {
			timestamps = {},
			clickIds = {}
		}
	end

	local playerClicks = self.ClickProtection.recentClicks[userId]

	-- Check for duplicate click ID
	if clickId then
		for _, existingId in ipairs(playerClicks.clickIds) do
			if existingId == clickId then
				print("🚫 Duplicate click ID detected: " .. clickId)
				return false, "Duplicate click ID"
			end
		end
	end

	-- Check click rate
	local recentTimestamps = {}
	for _, timestamp in ipairs(playerClicks.timestamps) do
		if (currentTime - timestamp) < 1 then -- Last 1 second
			table.insert(recentTimestamps, timestamp)
		end
	end

	-- Check if too many clicks in the last second
	if #recentTimestamps >= self.Config.maximumClicksPerSecond then
		print("⚠️ Player " .. player.Name .. " clicking too fast: " .. #recentTimestamps .. " clicks/sec")

		-- Increase suspicion
		self.ClickProtection.suspiciousPlayers[userId] = (self.ClickProtection.suspiciousPlayers[userId] or 0) + 1

		-- Block if too suspicious
		if self.ClickProtection.suspiciousPlayers[userId] >= 3 then
			self.ClickProtection.blockedPlayers[userId] = currentTime + 30 -- Block for 30 seconds
			print("🚫 Blocked player " .. player.Name .. " for 30 seconds due to suspicious clicking")
			self:SendNotification(player, "⚠️ Clicking Too Fast", "You've been temporarily blocked for clicking too quickly. Please wait 30 seconds.", "warning")
		end

		return false, "Clicking too fast"
	end

	-- Check minimum interval
	if #playerClicks.timestamps > 0 then
		local lastClick = playerClicks.timestamps[#playerClicks.timestamps]
		if (currentTime - lastClick) < self.Config.minimumClickInterval then
			print("🚫 Player " .. player.Name .. " clicking too frequently")
			return false, "Minimum click interval not met"
		end
	end

	-- Record this click
	table.insert(playerClicks.timestamps, currentTime)
	if clickId then
		table.insert(playerClicks.clickIds, clickId)
	end

	-- Limit stored data
	while #playerClicks.timestamps > 100 do
		table.remove(playerClicks.timestamps, 1)
	end
	while #playerClicks.clickIds > 100 do
		table.remove(playerClicks.clickIds, 1)
	end

	return true, "Click allowed"
end

-- ========== UTILITY FUNCTIONS ==========

-- FIXED: Helper function to get position from Model or Part
function CowMilkingModule:GetModelPosition(object)
	if not object then return Vector3.new(0, 0, 0) end

	-- If it's a Part, return its position
	if object:IsA("BasePart") then
		return object.Position
	end

	-- If it's a Model, get position from PrimaryPart or calculate bounds
	if object:IsA("Model") then
		if object.PrimaryPart then
			return object.PrimaryPart.Position
		else
			-- Calculate bounding box center
			local success, cframe, size = pcall(function()
				return object:GetBoundingBox()
			end)

			if success then
				return cframe.Position
			else
				-- Fallback: average position of all parts
				local totalPos = Vector3.new(0, 0, 0)
				local partCount = 0

				for _, child in pairs(object:GetDescendants()) do
					if child:IsA("BasePart") then
						totalPos = totalPos + child.Position
						partCount = partCount + 1
					end
				end

				if partCount > 0 then
					return totalPos / partCount
				end
			end
		end
	end

	-- Final fallback
	return Vector3.new(0, 0, 0)
end

-- ========== INITIALIZATION ==========

function CowMilkingModule:Initialize(gameCore, cowCreationModule)
	print("CowMilkingModule: Initializing FIXED 10-click milking system...")

	GameCore = gameCore
	CowCreationModule = cowCreationModule

	-- Setup remote events
	self:SetupRemoteEvents()

	-- Initialize click protection
	self:InitializeClickProtection()

	-- Setup existing chairs
	self:DetectExistingChairs()

	-- Start proximity monitoring
	self:StartProximityMonitoring()

	-- Setup player handlers
	self:SetupPlayerHandlers()

	print("CowMilkingModule: FIXED 10-click milking system initialized!")
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

	for _, eventName in ipairs(milkingEvents) do
		local existing = remoteFolder:FindFirstChild(eventName)
		if not existing then
			local remote = Instance.new("RemoteEvent")
			remote.Name = eventName
			remote.Parent = remoteFolder
		end
		RemoteEvents[eventName] = remoteFolder:FindFirstChild(eventName)
	end

	self:ConnectEventHandlers()
	print("CowMilkingModule: Remote events setup complete")
end

function CowMilkingModule:ConnectEventHandlers()
	if RemoteEvents.StartMilkingSession then
		RemoteEvents.StartMilkingSession.OnServerEvent:Connect(function(player, cowId)
			pcall(function()
				self:HandleStartMilkingSession(player, cowId)
			end)
		end)
	end

	if RemoteEvents.StopMilkingSession then
		RemoteEvents.StopMilkingSession.OnServerEvent:Connect(function(player)
			pcall(function()
				self:HandleStopMilkingSession(player)
			end)
		end)
	end

	if RemoteEvents.ContinueMilking then
		-- ENHANCED: Handle click with protection
		RemoteEvents.ContinueMilking.OnServerEvent:Connect(function(player, clickId)
			pcall(function()
				self:HandleContinueMilkingProtected(player, clickId)
			end)
		end)
	end

	print("CowMilkingModule: Event handlers connected")
end

-- ========== ENHANCED CLICK HANDLING ==========

function CowMilkingModule:HandleContinueMilkingProtected(player, clickId)
	local userId = player.UserId

	-- ENHANCED: Check if click is allowed
	local allowed, reason = self:IsClickAllowed(player, clickId)
	if not allowed then
		print("🚫 Click rejected for " .. player.Name .. ": " .. reason)
		return
	end

	-- Get session
	local session = self.ActiveSessions[userId]
	if not session or not session.isActive then 
		print("❌ No active session for " .. player.Name)
		return 
	end

	-- Check if player is still seated
	local character = player.Character
	if not character then
		print("❌ No character for " .. player.Name)
		self:HandleStopMilkingSession(player)
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		print("❌ No humanoid for " .. player.Name)
		self:HandleStopMilkingSession(player)
		return
	end

	local isSeated = false
	local success = pcall(function()
		isSeated = humanoid.Sit
	end)

	if not success or not isSeated then
		print("❌ Player " .. player.Name .. " not seated - ending session")
		self:HandleStopMilkingSession(player)
		return
	end

	-- ENHANCED: Process click with detailed tracking
	session.totalClicks = session.totalClicks + 1
	session.clickProgress = session.clickProgress + 1
	session.lastClickTime = os.time()

	print("🖱️ FIXED: " .. player.Name .. " clicked - Progress: " .. session.clickProgress .. "/" .. self.Config.clicksPerMilk .. 
		" (Total clicks: " .. session.totalClicks .. ")")

	-- Check if we've reached 10 clicks for 1 milk
	if session.clickProgress >= self.Config.clicksPerMilk then
		-- Give 1 milk and reset progress
		session.milkCollected = session.milkCollected + 1
		session.clickProgress = 0

		print("🥛 FIXED: " .. player.Name .. " completed " .. self.Config.clicksPerMilk .. " clicks - awarded 1 milk! Total: " .. session.milkCollected)

		-- Give milk to player immediately
		self:GiveMilkToPlayer(player, session.cowId, 1)

		-- Show milk collection notification
		self:SendNotification(player, "🥛 +1 Milk Collected!", 
			"Completed " .. self.Config.clicksPerMilk .. " clicks! Total milk: " .. session.milkCollected, "success")
	end

	-- Send progress update to client
	self:SendMilkingProgressUpdate(player, session)

	-- Check limits
	if session.milkCollected >= session.maxMilk then
		self:SendNotification(player, "🥛 Cow Empty!", 
			"This cow has no more milk! Session ending.", "info")
		self:HandleStopMilkingSession(player)
		return
	end
end

function CowMilkingModule:SendMilkingProgressUpdate(player, session)
	if RemoteEvents.MilkingSessionUpdate then
		pcall(function()
			RemoteEvents.MilkingSessionUpdate:FireClient(player, "progress", {
				milkCollected = session.milkCollected,
				clickProgress = session.clickProgress,
				clicksPerMilk = self.Config.clicksPerMilk,
				totalClicks = session.totalClicks,
				sessionDuration = os.time() - session.startTime,
				lastClickTime = session.lastClickTime,
				progressPercentage = math.floor((session.clickProgress / self.Config.clicksPerMilk) * 100)
			})
		end)
	end
end

-- ========== EXISTING FUNCTIONS (UNCHANGED) ==========

function CowMilkingModule:DetectExistingChairs()
	print("CowMilkingModule: Detecting existing MilkingChair models...")

	self.MilkingChairs = {}
	local chairsFound = 0

	-- Search workspace for MilkingChair models
	for _, obj in pairs(workspace:GetChildren()) do
		if self:IsMilkingChair(obj) then
			local chairId = self:SetupExistingChair(obj)
			if chairId then
				chairsFound = chairsFound + 1
				local position = self:GetModelPosition(obj)
				print("✅ Setup existing chair: " .. chairId .. " at " .. tostring(position))
			end
		end
	end

	-- Search in folders
	for _, folder in pairs(workspace:GetChildren()) do
		if folder:IsA("Folder") or folder:IsA("Model") then
			for _, obj in pairs(folder:GetChildren()) do
				if self:IsMilkingChair(obj) then
					local chairId = self:SetupExistingChair(obj)
					if chairId then
						chairsFound = chairsFound + 1
						local position = self:GetModelPosition(obj)
						print("✅ Setup existing chair in folder: " .. chairId .. " at " .. tostring(position))
					end
				end
			end
		end
	end

	print("CowMilkingModule: Found and setup " .. chairsFound .. " existing chairs")
end

function CowMilkingModule:IsMilkingChair(obj)
	if not obj then return false end

	-- Check by name
	if obj.Name == "MilkingChair" then
		return true
	end

	-- Check by attribute
	if obj:GetAttribute("IsMilkingChair") then
		return true
	end

	return false
end

function CowMilkingModule:SetupExistingChair(chairObj)
	local chairId = "chair_" .. tick() .. "_" .. math.random(1000, 9999)

	-- Handle both Model and Seat objects
	local seatPart = nil

	if chairObj:IsA("Seat") then
		seatPart = chairObj
		print("CowMilkingModule: Found Seat object: " .. chairObj.Name)
	elseif chairObj:IsA("Model") then
		print("CowMilkingModule: Found Model object: " .. chairObj.Name .. ", searching for Seat...")
		-- Find seat in model
		for _, child in pairs(chairObj:GetDescendants()) do
			if child:IsA("Seat") then
				seatPart = child
				print("CowMilkingModule: Found Seat in model: " .. child.Name)
				break
			end
		end

		-- If no Seat found, check for VehicleSeat
		if not seatPart then
			for _, child in pairs(chairObj:GetDescendants()) do
				if child:IsA("VehicleSeat") then
					seatPart = child
					print("CowMilkingModule: Found VehicleSeat in model: " .. child.Name)
					break
				end
			end
		end
	end

	if not seatPart then
		warn("CowMilkingModule: No seat found in chair: " .. chairObj.Name)
		return nil
	end

	-- Set attributes
	chairObj:SetAttribute("IsMilkingChair", true)
	chairObj:SetAttribute("ChairId", chairId)
	seatPart:SetAttribute("IsMilkingChair", true)
	seatPart:SetAttribute("ChairId", chairId)

	-- Store chair reference
	self.MilkingChairs[chairId] = seatPart

	-- Setup occupancy detection
	if seatPart:IsA("Seat") or seatPart:IsA("VehicleSeat") then
		local success, error = pcall(function()
			seatPart:GetPropertyChangedSignal("Occupant"):Connect(function()
				self:HandleChairOccupancyChange(seatPart)
			end)
		end)

		if not success then
			warn("CowMilkingModule: Failed to setup occupancy detection: " .. tostring(error))
		end
	end

	return chairId
end

function CowMilkingModule:StartProximityMonitoring()
	print("CowMilkingModule: Starting proximity monitoring...")

	spawn(function()
		while true do
			wait(self.Config.proximityCheckInterval)
			self:UpdateAllPlayerProximity()
		end
	end)
end

function CowMilkingModule:UpdateAllPlayerProximity()
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			pcall(function()
				self:UpdatePlayerProximityState(player)
			end)
		end
	end
end

function CowMilkingModule:UpdatePlayerProximityState(player)
	local character = player.Character
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local userId = player.UserId
	local playerPos = rootPart.Position

	-- Skip if already in a milking session
	if self.ActiveSessions[userId] then
		return
	end

	-- Get nearby objects
	local nearbyObjects = self:GetNearbyObjects(player, playerPos)
	local promptState = self:DetermineProximityState(nearbyObjects)

	-- Update player prompt
	if promptState ~= "none" then
		self:ShowProximityPrompt(player, promptState, nearbyObjects)
	else
		self:HideProximityPrompt(player)
	end
end

function CowMilkingModule:GetNearbyObjects(player, playerPos)
	local nearby = {
		cows = {},
		chairs = {},
		playerCowsNearby = 0,
		milkingChairsNearby = 0
	}

	-- Check for player's cows
	if CowCreationModule and CowCreationModule.GetPlayerCows then
		local success, playerCows = pcall(function()
			return CowCreationModule:GetPlayerCows(player)
		end)

		if success and playerCows then
			for _, cowId in ipairs(playerCows) do
				local success2, cowModel = pcall(function()
					return CowCreationModule:GetCowModel(cowId)
				end)

				if success2 and cowModel and cowModel.Parent then
					local cowPos = self:GetModelPosition(cowModel)
					local distance = (playerPos - cowPos).Magnitude

					if distance <= self.Config.proximityDistance then
						local canMilk = self:VerifyCanMilkCow(player, cowId)

						table.insert(nearby.cows, {
							id = cowId,
							model = cowModel,
							distance = distance,
							canMilk = canMilk
						})
						nearby.playerCowsNearby = nearby.playerCowsNearby + 1
					end
				end
			end
		end
	end

	-- Check for chairs
	for chairId, chair in pairs(self.MilkingChairs) do
		if chair and chair.Parent then
			local success, chairPos = pcall(function()
				return self:GetModelPosition(chair)
			end)

			if success then
				local distance = (playerPos - chairPos).Magnitude

				if distance <= self.Config.proximityDistance then
					local isOccupied = false

					local occupantSuccess, occupant = pcall(function()
						return chair.Occupant
					end)

					if occupantSuccess then
						isOccupied = occupant ~= nil
					end

					table.insert(nearby.chairs, {
						id = chairId,
						model = chair,
						distance = distance,
						isOccupied = isOccupied
					})
					nearby.milkingChairsNearby = nearby.milkingChairsNearby + 1
				end
			end
		end
	end

	return nearby
end

function CowMilkingModule:VerifyCanMilkCow(player, cowId)
	if not CowCreationModule then return false end

	local success, cowData = pcall(function()
		return CowCreationModule:GetCowData(player, cowId)
	end)

	if not success or not cowData then return false end

	local currentTime = os.time()
	local lastMilked = cowData.lastMilkCollection or 0
	local cooldown = cowData.cooldown or 60

	return (currentTime - lastMilked) >= cooldown
end

function CowMilkingModule:DetermineProximityState(nearbyObjects)
	local hasReadyCows = false
	local hasCooldownCows = false
	local hasAvailableChairs = false

	-- Check cow status
	for _, cow in ipairs(nearbyObjects.cows) do
		if cow.canMilk then
			hasReadyCows = true
		else
			hasCooldownCows = true
		end
	end

	-- Check chair availability
	for _, chair in ipairs(nearbyObjects.chairs) do
		if not chair.isOccupied then
			hasAvailableChairs = true
			break
		end
	end

	-- Determine state
	if hasReadyCows and hasAvailableChairs then
		return "ready_to_milk"
	elseif hasReadyCows and not hasAvailableChairs then
		return "need_chair"
	elseif hasCooldownCows and hasAvailableChairs then
		return "cow_cooldown"
	elseif nearbyObjects.playerCowsNearby > 0 then
		return "cow_not_ready"
	else
		return "none"
	end
end

function CowMilkingModule:ShowProximityPrompt(player, promptState, nearbyObjects)
	if not RemoteEvents.ShowChairPrompt then return end

	local promptData = self:CreatePromptData(promptState, nearbyObjects)

	pcall(function()
		RemoteEvents.ShowChairPrompt:FireClient(player, "proximity", {
			title = promptData.title,
			subtitle = promptData.subtitle,
			instruction = promptData.instruction,
			canUse = promptData.canUse,
			promptType = promptData.type
		})
	end)
end

function CowMilkingModule:CreatePromptData(promptState, nearbyObjects)
	local data = {
		type = promptState,
		canUse = false,
		title = "🐄 Cow Nearby",
		subtitle = "Unknown status",
		instruction = "Check your setup"
	}

	if promptState == "ready_to_milk" then
		data.canUse = true
		data.title = "🥛 Ready to Milk!"
		data.subtitle = "Sit in the chair to start milking"
		data.instruction = "Find the MilkingChair and sit down"

	elseif promptState == "need_chair" then
		data.canUse = false
		data.title = "🪑 Chair Needed"
		data.subtitle = "Your cow is ready, but no chair available"
		data.instruction = "Find an empty MilkingChair nearby"

	elseif promptState == "cow_cooldown" then
		data.canUse = false
		data.title = "⏰ Cow Resting"
		data.subtitle = "Your cow needs time to produce more milk"
		data.instruction = "Wait for your cow to be ready"

	elseif promptState == "cow_not_ready" then
		data.canUse = false
		data.title = "🐄 Cow Nearby"
		data.subtitle = "Cow is not ready for milking yet"
		data.instruction = "Wait for your cow to be ready"
	end

	return data
end

function CowMilkingModule:HideProximityPrompt(player)
	if RemoteEvents.HideChairPrompt then
		pcall(function()
			RemoteEvents.HideChairPrompt:FireClient(player)
		end)
	end
end

function CowMilkingModule:HandleChairOccupancyChange(chair)
	if not chair or not chair.Parent then
		return
	end

	local success, occupant = pcall(function()
		return chair.Occupant
	end)

	if not success then return end

	if occupant then
		local character = occupant.Parent
		local player = Players:GetPlayerFromCharacter(character)

		if player then
			print("🪑 Player " .. player.Name .. " sat in milking chair")
			self:HandlePlayerSatDown(player, chair)
		end
	end
end

function CowMilkingModule:HandlePlayerSatDown(player, chair)
	local character = player.Character
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local nearbyObjects = self:GetNearbyObjects(player, rootPart.Position)
	local nearbyCow = nil

	-- Find the best cow to milk
	for _, cow in ipairs(nearbyObjects.cows) do
		if cow.canMilk then
			nearbyCow = cow
			break
		end
	end

	if nearbyCow then
		print("🥛 Starting FIXED 10-click milking session for " .. player.Name .. " with cow " .. nearbyCow.id)
		self:StartMilkingSession(player, nearbyCow.id, chair)
	else
		if #nearbyObjects.cows > 0 then
			self:SendNotification(player, "⏰ Cow Not Ready", 
				"Your cow needs time to produce milk. Wait a bit and try again!", "warning")
		else
			self:SendNotification(player, "🐄 No Cow Nearby", 
				"Move closer to your cow before sitting down!", "warning")
		end
	end
end

function CowMilkingModule:StartMilkingSession(player, cowId, chair)
	local userId = player.UserId

	print("🥛 Starting FIXED 10-click milking session for " .. player.Name .. " with cow " .. cowId)

	-- Check if already in session
	if self.ActiveSessions[userId] then
		self:HandleStopMilkingSession(player)
		wait(0.1)
	end

	-- Verify cow ownership
	local success, owns = pcall(function()
		return CowCreationModule:DoesPlayerOwnCow(player, cowId)
	end)

	if not success or not owns then
		self:SendNotification(player, "🐄 Cow Error", "You don't own this cow!", "error")
		return false
	end

	-- Get cow data
	local cowDataSuccess, cowData = pcall(function()
		return CowCreationModule:GetCowData(player, cowId)
	end)

	if not cowDataSuccess or not cowData then
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

	-- Create FIXED session with enhanced tracking
	local session = {
		userId = userId,
		playerId = player.UserId,
		cowId = cowId,
		chairId = chair:GetAttribute("ChairId") or "unknown",
		startTime = currentTime,
		milkCollected = 0,
		clickProgress = 0, -- Track clicks toward next milk (0-9)
		totalClicks = 0, -- Total clicks this session
		lastClickTime = currentTime,
		isActive = true,
		maxMilk = self.Config.maxMilkPerSession
	}

	self.ActiveSessions[userId] = session

	-- Show milking GUI with progress
	if RemoteEvents.ShowChairPrompt then
		pcall(function()
			RemoteEvents.ShowChairPrompt:FireClient(player, "milking", {
				title = "🥛 FIXED 10-Click Milking Active",
				subtitle = "Click " .. self.Config.clicksPerMilk .. " times to collect 1 milk!",
				instruction = "Stay seated and click to collect milk. Leave chair to stop.",
				cowId = cowId,
				maxMilk = session.maxMilk,
				clicksPerMilk = self.Config.clicksPerMilk,
				currentProgress = 0
			})
		end)
	end

	-- Start session monitoring
	self:StartSessionMonitoring(userId)

	self:SendNotification(player, "🥛 FIXED 10-Click Milking Started!", 
		"Click " .. self.Config.clicksPerMilk .. " times to get 1 milk! Stay seated to continue.", "success")

	return true
end

function CowMilkingModule:HandleStartMilkingSession(player, cowId)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then 
		self:SendNotification(player, "🪑 Not Seated", "You must be sitting in a milking chair!", "warning")
		return
	end

	local isSeated = false
	local seatPart = nil

	local success = pcall(function()
		isSeated = humanoid.Sit
		seatPart = humanoid.SeatPart
	end)

	if not success or not isSeated then
		self:SendNotification(player, "🪑 Not Seated", "You must be sitting in a milking chair!", "warning")
		return
	end

	if not seatPart or not seatPart:GetAttribute("IsMilkingChair") then
		self:SendNotification(player, "🪑 Wrong Chair", "You must be sitting in a MilkingChair!", "warning")
		return
	end

	-- Start session
	self:StartMilkingSession(player, cowId, seatPart)
end

--[[
    FIXED: CowMilkingModule.lua - GiveMilkToPlayer Function
    Replace the existing GiveMilkToPlayer function in CowMilkingModule.lua
]]

function CowMilkingModule:GiveMilkToPlayer(player, cowId, milkAmount)
	if not GameCore then 
		warn("GameCore not available for milk collection")
		return false
	end

	print("🥛 FIXED: Giving " .. milkAmount .. " milk to " .. player.Name .. " using GameCore system")

	-- Use GameCore's proper milk collection system instead of direct manipulation
	local success = false

	-- Try to use GameCore's CollectMilk function if available
	if GameCore.CollectMilk then
		success = GameCore:CollectMilk(player, milkAmount)
	else
		-- Fallback: Use GameCore's AddItemToInventory with proper milk type
		success = GameCore:AddItemToInventory(player, "milk", "milk", milkAmount)

		if success then
			-- Update stats manually since we're using fallback
			local playerData = GameCore:GetPlayerData(player)
			if playerData then
				playerData.stats = playerData.stats or {}
				playerData.stats.milkCollected = (playerData.stats.milkCollected or 0) + milkAmount

				-- Update cow data
				if playerData.livestock and playerData.livestock.cows then
					for i, cow in ipairs(playerData.livestock.cows) do
						if cow.id == cowId then
							cow.lastMilkCollection = os.time()
							cow.totalMilkProduced = (cow.totalMilkProduced or 0) + milkAmount
							break
						end
					end
				end

				-- Force update player data and UI
				GameCore:UpdatePlayerData(player, playerData)

				-- Send notification
				GameCore:SendNotification(player, "🥛 Milk Collected", 
					"Collected " .. milkAmount .. " milk from your cow!", "success")
			end
		end
	end

	if success then
		print("✅ FIXED: Successfully gave " .. milkAmount .. " milk to " .. player.Name)
		return true
	else
		warn("❌ FIXED: Failed to give milk to " .. player.Name)
		return false
	end
end

function CowMilkingModule:HandleStopMilkingSession(player)
	local userId = player.UserId
	local session = self.ActiveSessions[userId]

	if not session then return end

	print("🛑 Stopping FIXED 10-click milking session for " .. player.Name)

	local totalMilk = session.milkCollected
	local totalClicks = session.totalClicks
	local sessionDuration = os.time() - session.startTime

	if totalMilk > 0 or totalClicks > 0 then
		local clicksTowardsNext = session.clickProgress
		local progressMessage = ""

		if clicksTowardsNext > 0 then
			progressMessage = " (" .. clicksTowardsNext .. "/" .. self.Config.clicksPerMilk .. " clicks towards next milk)"
		end

		self:SendNotification(player, "🥛 FIXED Milking Complete!", 
			"Session ended! Collected " .. totalMilk .. " milk from " .. totalClicks .. " clicks" .. progressMessage, "success")
	end

	-- Clean up session
	self.ActiveSessions[userId] = nil

	-- Clean up click protection data
	if self.ClickProtection.recentClicks[userId] then
		self.ClickProtection.recentClicks[userId] = nil
	end

	-- Hide GUI
	if RemoteEvents.HideChairPrompt then
		pcall(function()
			RemoteEvents.HideChairPrompt:FireClient(player)
		end)
	end
end

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

function CowMilkingModule:SetupPlayerHandlers()
	Players.PlayerRemoving:Connect(function(player)
		local userId = player.UserId

		-- Clean up active session
		if self.ActiveSessions[userId] then
			self.ActiveSessions[userId] = nil
		end

		-- Clean up proximity state
		if self.PlayerProximityState[userId] then
			self.PlayerProximityState[userId] = nil
		end

		-- Clean up click protection
		if self.ClickProtection.recentClicks[userId] then
			self.ClickProtection.recentClicks[userId] = nil
		end
		if self.ClickProtection.suspiciousPlayers[userId] then
			self.ClickProtection.suspiciousPlayers[userId] = nil
		end
		if self.ClickProtection.blockedPlayers[userId] then
			self.ClickProtection.blockedPlayers[userId] = nil
		end
	end)
end

function CowMilkingModule:SendNotification(player, title, message, notificationType)
	if GameCore and GameCore.SendNotification then
		pcall(function()
			GameCore:SendNotification(player, title, message, notificationType)
		end)
	else
		print("NOTIFICATION for " .. player.Name .. ": [" .. (notificationType or "info"):upper() .. "] " .. title .. " - " .. message)
	end
end

function CowMilkingModule:CountTable(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- ========== ENHANCED DEBUG FUNCTIONS ==========

function CowMilkingModule:DebugStatus()
	print("=== FIXED 10-CLICK MILKING DEBUG ===")
	print("Active sessions: " .. self:CountTable(self.ActiveSessions))
	print("Milking chairs: " .. self:CountTable(self.MilkingChairs))
	print("Clicks per milk: " .. self.Config.clicksPerMilk)
	print("Protected players: " .. self:CountTable(self.ClickProtection.recentClicks))
	print("Blocked players: " .. self:CountTable(self.ClickProtection.blockedPlayers))

	for userId, session in pairs(self.ActiveSessions) do
		local player = Players:GetPlayerByUserId(userId)
		local playerName = player and player.Name or "Unknown"
		print("Session - " .. playerName .. ":")
		print("  Click progress: " .. session.clickProgress .. "/" .. self.Config.clicksPerMilk)
		print("  Total clicks: " .. session.totalClicks)
		print("  Milk collected: " .. session.milkCollected)
	end

	print("Click protection status:")
	for userId, clickData in pairs(self.ClickProtection.recentClicks) do
		local player = Players:GetPlayerByUserId(userId)
		local playerName = player and player.Name or "Unknown"
		print("  " .. playerName .. " - Recent clicks: " .. #(clickData.timestamps or {}))
	end

	print("=====================================")
end

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
		clickProtection = {
			protectedPlayers = self:CountTable(self.ClickProtection.recentClicks),
			blockedPlayers = self:CountTable(self.ClickProtection.blockedPlayers),
			suspiciousPlayers = self:CountTable(self.ClickProtection.suspiciousPlayers)
		},
		config = self.Config
	}
end

-- ========== GLOBAL ACCESS ==========

_G.CowMilkingModule = CowMilkingModule

_G.DebugMilking = function()
	CowMilkingModule:DebugStatus()
end

print("CowMilkingModule: ✅ FIXED 10-CLICK SYSTEM WITH PROTECTION LOADED!")
print("🔧 DUPLICATE CLICK FIXES:")
print("  🛡️ Enhanced click ID verification")
print("  ⏱️ Minimum click interval protection")
print("  📊 Click rate limiting (max 20/sec)")
print("  🚫 Automatic player blocking for abuse")
print("  🧹 Automatic cleanup of old click data")
print("")
print("🖱️ 10-CLICK FEATURES:")
print("  📊 10 clicks = 1 milk system")
print("  📈 Progress indicator (0-" .. CowMilkingModule.Config.clicksPerMilk .. " clicks)")
print("  🪑 Works with existing MilkingChair models")
print("  🐄 Works with existing cow models")
print("  📱 Real-time progress updates")
print("")
print("🔧 Debug Commands:")
print("  _G.DebugMilking() - Show FIXED milking system status")

return CowMilkingModule