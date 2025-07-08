--[[
    FIXED CowMilkingModule.lua - Chair Detection and Nil Model Fixes
    Place in: ServerScriptService/CowMilkingModule.lua
    
    FIXES:
    ✅ Fixed chair detection to recognize existing MilkingChair properly
    ✅ Fixed nil cowModel error in VerifyCowOwnership
    ✅ Improved chair registration and scanning
    ✅ Better proximity detection for chairs
]]

local CowMilkingModule = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Module State
CowMilkingModule.ActiveSessions = {} -- [userId] = sessionData
CowMilkingModule.MilkingChairs = {} -- [chairId] = chairModel
CowMilkingModule.PlayerProximityState = {} -- [userId] = {lastPrompt, lastUpdate, currentState}

-- Configuration
CowMilkingModule.Config = {
	proximityDistance = 15,
	milkingDistance = 8,
	sessionTimeout = 30,
	milkPerClick = 1,
	maxMilkPerSession = 50,
	proximityCheckInterval = 3,
	promptDebounceTime = 5,
	stateChangeDelay = 2,
	movementThreshold = 8
}

-- References
local GameCore = nil
local CowCreationModule = nil
local RemoteEvents = {}

-- ========== INITIALIZATION ==========

function CowMilkingModule:Initialize(gameCore, cowCreationModule)
	print("CowMilkingModule: Initializing FIXED milking system...")

	GameCore = gameCore
	CowCreationModule = cowCreationModule

	-- Setup remote events
	self:SetupRemoteEvents()

	-- FIXED: Enhanced chair setup
	self:SetupMilkingChairs()

	-- Start proximity monitoring
	self:StartConsolidatedProximityMonitoring()

	-- Setup player handlers
	self:SetupPlayerHandlers()

	print("CowMilkingModule: FIXED milking system initialized!")
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
		RemoteEvents.ContinueMilking.OnServerEvent:Connect(function(player)
			pcall(function()
				self:HandleContinueMilking(player)
			end)
		end)
	end

	print("CowMilkingModule: Event handlers connected")
end

-- ========== FIXED: ENHANCED CHAIR SETUP ==========

function CowMilkingModule:SetupMilkingChairs()
	print("CowMilkingModule: Setting up ENHANCED milking chairs...")

	-- Clear existing chairs first
	self.MilkingChairs = {}

	-- FIXED: More comprehensive chair scanning
	local existingChairs = self:ScanForAllChairs()

	if existingChairs > 0 then
		print("✅ CowMilkingModule: Found and registered " .. existingChairs .. " existing chairs")
	else
		print("⚠️ CowMilkingModule: No existing chairs found, creating default chairs...")
		self:CreateDefaultChairs()
	end

	-- Force register any MilkingChair objects
	self:ForceRegisterMilkingChairs()

	local totalChairs = self:CountTable(self.MilkingChairs)
	print("CowMilkingModule: Total milking chairs available: " .. totalChairs)

	-- Debug: List all chairs
	for chairId, chair in pairs(self.MilkingChairs) do
		print("  Chair: " .. chairId .. " at " .. tostring(chair.Position))
	end
end

-- FIXED: Enhanced chair scanning
function CowMilkingModule:ScanForAllChairs()
	print("CowMilkingModule: Scanning for ALL possible chair types...")
	local chairsFound = 0

	for _, obj in pairs(workspace:GetChildren()) do
		local registered = false

		-- Method 1: Check by name "MilkingChair"
		if obj.Name == "MilkingChair" then
			if obj:IsA("Model") then
				if self:RegisterExistingChairModel(obj) then
					chairsFound = chairsFound + 1
					registered = true
					print("✅ Registered MilkingChair model: " .. obj.Name)
				end
			elseif obj:IsA("Seat") then
				self:RegisterMilkingChair(obj)
				chairsFound = chairsFound + 1
				registered = true
				print("✅ Registered MilkingChair seat: " .. obj.Name)
			end
		end

		-- Method 2: Check by attribute
		if not registered and obj:GetAttribute("IsMilkingChair") then
			if obj:IsA("Model") then
				if self:RegisterExistingChairModel(obj) then
					chairsFound = chairsFound + 1
					registered = true
					print("✅ Registered attributed chair model: " .. obj.Name)
				end
			elseif obj:IsA("Seat") then
				self:RegisterMilkingChair(obj)
				chairsFound = chairsFound + 1
				registered = true
				print("✅ Registered attributed chair seat: " .. obj.Name)
			end
		end

		-- Method 3: Check for wooden chairs near cows (auto-detect)
		if not registered and obj:IsA("Seat") and obj.Material == Enum.Material.Wood then
			-- Check if there are cows nearby
			local nearbyCows = 0
			for _, otherObj in pairs(workspace:GetChildren()) do
				if (otherObj.Name == "cow" or otherObj.Name:find("cow_")) and otherObj ~= obj then
					local distance = (obj.Position - otherObj:GetPivot().Position).Magnitude
					if distance < 20 then -- Within 20 studs of a cow
						nearbyCows = nearbyCows + 1
					end
				end
			end

			if nearbyCows > 0 then
				print("🔍 Auto-detected potential milking chair: " .. obj.Name .. " (near " .. nearbyCows .. " cows)")
				obj:SetAttribute("IsMilkingChair", true)
				obj.Name = "MilkingChair" -- Rename for clarity
				self:RegisterMilkingChair(obj)
				chairsFound = chairsFound + 1
				print("✅ Auto-registered chair: " .. obj.Name)
			end
		end
	end

	return chairsFound
end

-- FIXED: Force register any MilkingChair objects
function CowMilkingModule:ForceRegisterMilkingChairs()
	print("CowMilkingModule: Force registering any missed MilkingChair objects...")

	for _, obj in pairs(workspace:GetChildren()) do
		if obj.Name == "MilkingChair" then
			local alreadyRegistered = false

			-- Check if already registered
			for chairId, chair in pairs(self.MilkingChairs) do
				if chair == obj then
					alreadyRegistered = true
					break
				end
			end

			if not alreadyRegistered then
				print("🔧 Force registering missed chair: " .. obj.Name)
				if obj:IsA("Model") then
					self:RegisterExistingChairModel(obj)
				elseif obj:IsA("Seat") then
					self:RegisterMilkingChair(obj)
				end
			end
		end
	end
end

function CowMilkingModule:RegisterExistingChairModel(chairModel)
	print("CowMilkingModule: Registering chair model: " .. chairModel.Name)

	local seatPart = nil

	-- Find the seat in the model
	for _, child in pairs(chairModel:GetDescendants()) do
		if child:IsA("Seat") then
			seatPart = child
			break
		end
	end

	if not seatPart then
		warn("CowMilkingModule: No Seat found in chair model: " .. chairModel.Name)
		return false
	end

	local chairId = chairModel:GetAttribute("ChairId") or ("chair_model_" .. tick() .. "_" .. math.random(1000, 9999))

	-- Set attributes on both model and seat
	chairModel:SetAttribute("IsMilkingChair", true)
	chairModel:SetAttribute("ChairId", chairId)
	seatPart:SetAttribute("IsMilkingChair", true)
	seatPart:SetAttribute("ChairId", chairId)
	seatPart:SetAttribute("ParentModel", chairModel.Name)

	self.MilkingChairs[chairId] = seatPart

	-- Setup occupancy detection
	if seatPart:IsA("Seat") then
		local success = pcall(function()
			seatPart:GetPropertyChangedSignal("Occupant"):Connect(function()
				self:HandleChairOccupancyChange(seatPart)
			end)
		end)

		if success then
			print("✅ Occupancy detection setup for chair: " .. chairId)
		else
			warn("⚠️ Failed to setup occupancy detection for chair: " .. chairId)
		end
	end

	print("✅ Registered chair model: " .. chairId)
	return true
end

function CowMilkingModule:CreateDefaultChairs()
	local basePosition = Vector3.new(-270, -2, 50)

	for i = 1, 3 do
		local position = basePosition + Vector3.new(i * 8, 0, 0)
		local chair = self:CreateMilkingChair(position)
		if chair then
			print("Created default milking chair " .. i .. " at " .. tostring(position))
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
		seat:SetAttribute("IsMilkingChair", true)
		seat:SetAttribute("ChairId", "created_chair_" .. tick() .. "_" .. math.random(1000, 9999))
		return seat
	end)

	if success and chair then
		chair.Parent = workspace
		self:RegisterMilkingChair(chair)
		return chair
	end

	return nil
end

function CowMilkingModule:RegisterMilkingChair(chair)
	local chairId = chair:GetAttribute("ChairId") or ("seat_" .. tick() .. "_" .. math.random(1000, 9999))
	chair:SetAttribute("ChairId", chairId)
	chair:SetAttribute("IsMilkingChair", true)

	self.MilkingChairs[chairId] = chair

	if chair:IsA("Seat") then
		local success = pcall(function()
			chair:GetPropertyChangedSignal("Occupant"):Connect(function()
				self:HandleChairOccupancyChange(chair)
			end)
		end)

		if success then
			print("✅ Occupancy detection setup for seat: " .. chairId)
		else
			warn("⚠️ Failed to setup occupancy detection for seat: " .. chairId)
		end
	end

	print("✅ Registered milking chair: " .. chairId .. " at " .. tostring(chair.Position))
end

-- ========== PROXIMITY MONITORING ==========

function CowMilkingModule:StartConsolidatedProximityMonitoring()
	print("CowMilkingModule: Starting consolidated proximity monitoring...")

	spawn(function()
		while true do
			wait(self.Config.proximityCheckInterval)
			self:UpdateAllPlayerProximity()
		end
	end)

	print("✅ CowMilkingModule: Proximity monitoring started")
end

function CowMilkingModule:UpdateAllPlayerProximity()
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			self:UpdatePlayerProximityState(player)
		end
	end
end

function CowMilkingModule:UpdatePlayerProximityState(player)
	local character = player.Character
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local userId = player.UserId
	local playerPos = rootPart.Position
	local currentTime = tick()

	-- Initialize player proximity state
	if not self.PlayerProximityState[userId] then
		self.PlayerProximityState[userId] = {
			lastPrompt = "none",
			lastUpdate = 0,
			currentState = "none",
			lastPosition = playerPos,
			lastStateChange = 0
		}
	end

	local proximityState = self.PlayerProximityState[userId]

	-- Skip if player is already in a milking session
	if self.ActiveSessions[userId] then
		if proximityState.currentState ~= "milking" then
			proximityState.currentState = "milking"
			self:HideProximityPrompt(player)
		end
		return
	end

	-- Check if enough time has passed since last state change
	local timeSinceLastChange = currentTime - proximityState.lastStateChange
	if timeSinceLastChange < self.Config.stateChangeDelay then
		return
	end

	-- Check if player moved significantly
	local distanceMoved = (playerPos - proximityState.lastPosition).Magnitude
	local movedEnough = distanceMoved > self.Config.movementThreshold

	-- Get current nearby objects with enhanced chair detection
	local nearbyObjects = self:GetVerifiedNearbyObjects(player, playerPos)
	local newState = self:DetermineProximityState(nearbyObjects)

	-- Only update if state changed OR player moved significantly OR enough time passed
	local timeSinceLastPrompt = currentTime - proximityState.lastUpdate
	local shouldUpdate = (newState ~= proximityState.currentState) or 
		(movedEnough and timeSinceLastPrompt >= self.Config.promptDebounceTime)

	if shouldUpdate then
		print("🔄 Proximity state change for " .. player.Name .. ": " .. proximityState.currentState .. " -> " .. newState)

		self:UpdatePlayerPrompt(player, newState, nearbyObjects)
		proximityState.currentState = newState
		proximityState.lastUpdate = currentTime
		proximityState.lastStateChange = currentTime
		proximityState.lastPosition = playerPos
	end
end

-- FIXED: Enhanced nearby object detection
function CowMilkingModule:GetVerifiedNearbyObjects(player, playerPos)
	local nearby = {
		cows = {},
		chairs = {},
		playerCowsNearby = 0,
		milkingChairsNearby = 0
	}

	-- Check for player's cows
	if CowCreationModule and CowCreationModule.GetActiveCows then
		local activeCows = CowCreationModule:GetActiveCows()

		for cowId, cowModel in pairs(activeCows) do
			if cowModel and cowModel.Parent and cowModel:IsDescendantOf(workspace) then
				local isOwned = self:VerifyCowOwnership(player, cowId, cowModel)

				if isOwned then
					local cowPos = self:GetModelCenter(cowModel)
					local distance = (playerPos - cowPos).Magnitude

					if distance <= self.Config.proximityDistance then
						local canMilk = self:VerifyCanMilkCow(player, cowId)

						table.insert(nearby.cows, {
							id = cowId,
							model = cowModel,
							distance = distance,
							canMilk = canMilk,
							owner = cowModel:GetAttribute("Owner")
						})
						nearby.playerCowsNearby = nearby.playerCowsNearby + 1
					end
				end
			end
		end
	end

	-- FIXED: Enhanced chair detection
	for chairId, chair in pairs(self.MilkingChairs) do
		if chair and chair.Parent and chair:IsDescendantOf(workspace) then
			local distance = (playerPos - chair.Position).Magnitude

			if distance <= self.Config.proximityDistance then
				local isOccupied = false
				if chair:IsA("Seat") then
					local success, occupant = pcall(function()
						return chair.Occupant
					end)
					if success then
						isOccupied = occupant ~= nil
					end
				end

				table.insert(nearby.chairs, {
					id = chairId,
					model = chair,
					distance = distance,
					isOccupied = isOccupied
				})
				nearby.milkingChairsNearby = nearby.milkingChairsNearby + 1

				print("🪑 Found nearby chair: " .. chairId .. " (occupied: " .. tostring(isOccupied) .. ", distance: " .. math.floor(distance) .. ")")
			end
		end
	end

	-- DEBUG: Print nearby objects
	print("📊 " .. player.Name .. " - Nearby: " .. nearby.playerCowsNearby .. " cows, " .. nearby.milkingChairsNearby .. " chairs")

	return nearby
end

-- FIXED: Better cow ownership verification with nil check
function CowMilkingModule:VerifyCowOwnership(player, cowId, cowModel)
	-- Method 1: Check model attribute (only if cowModel is provided)
	if cowModel then
		local modelOwner = cowModel:GetAttribute("Owner")
		if modelOwner == player.Name then
			return true
		end
	end

	-- Method 2: Check if cow is in player data
	if GameCore then
		local playerData = GameCore:GetPlayerData(player)
		if playerData and playerData.livestock and playerData.livestock.cows then
			if playerData.livestock.cows[cowId] then
				return true
			end
		end
	end

	-- Method 3: Check if cowId contains player's UserId (for starter cows)
	if cowId:find(tostring(player.UserId)) then
		return true
	end

	-- Method 4: If no cowModel provided, try to find it
	if not cowModel and CowCreationModule and CowCreationModule.GetActiveCows then
		local activeCows = CowCreationModule:GetActiveCows()
		local foundModel = activeCows[cowId]
		if foundModel then
			local modelOwner = foundModel:GetAttribute("Owner")
			if modelOwner == player.Name then
				return true
			end
		end
	end

	return false
end

function CowMilkingModule:VerifyCanMilkCow(player, cowId)
	if not CowCreationModule or not CowCreationModule.GetCowData then
		return false
	end

	local cowData = CowCreationModule:GetCowData(player, cowId)
	if not cowData then 
		return false 
	end

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

function CowMilkingModule:UpdatePlayerPrompt(player, promptState, nearbyObjects)
	if promptState == "none" then
		self:HideProximityPrompt(player)
		return
	end

	local promptData = self:CreatePromptData(promptState, nearbyObjects)
	self:ShowProximityPrompt(player, promptData)
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
		data.instruction = "Find the brown wooden chair and sit down"

	elseif promptState == "need_chair" then
		data.canUse = false
		data.title = "🪑 Chair Needed"
		data.subtitle = "Your cow is ready, but no chair available"
		data.instruction = "Find an empty milking chair nearby"

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

function CowMilkingModule:ShowProximityPrompt(player, promptData)
	if not RemoteEvents.ShowChairPrompt then return end

	print("📢 Showing proximity prompt to " .. player.Name .. ": " .. promptData.type)

	RemoteEvents.ShowChairPrompt:FireClient(player, "proximity", {
		title = promptData.title,
		subtitle = promptData.subtitle,
		instruction = promptData.instruction,
		canUse = promptData.canUse,
		promptType = promptData.type
	})
end

function CowMilkingModule:HideProximityPrompt(player)
	if not RemoteEvents.HideChairPrompt then return end

	local userId = player.UserId
	local proximityState = self.PlayerProximityState[userId]

	if proximityState and proximityState.currentState ~= "none" then
		print("🚫 Hiding proximity prompt for " .. player.Name)
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
		return
	end

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
	print("🪑 " .. player.Name .. " sat in chair: " .. (chair:GetAttribute("ChairId") or "unknown"))

	-- Check if player has nearby cows
	local character = player.Character
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local nearbyObjects = self:GetVerifiedNearbyObjects(player, rootPart.Position)
	local nearbyCow = nil

	-- Find the best cow to milk
	for _, cow in ipairs(nearbyObjects.cows) do
		if cow.canMilk then
			nearbyCow = cow
			break
		end
	end

	if nearbyCow then
		print("🥛 Starting milking session for " .. player.Name .. " with cow " .. nearbyCow.id)
		self:StartMilkingSession(player, nearbyCow.id, chair)
	else
		-- Check if there are any cows nearby (even if not ready)
		if #nearbyObjects.cows > 0 then
			self:SendNotification(player, "⏰ Cow Not Ready", 
				"Your cow needs time to produce milk. Wait a bit and try again!", "warning")
		else
			self:SendNotification(player, "🐄 No Cow Nearby", 
				"Move closer to your cow before sitting down!", "warning")
		end
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

	-- FIXED: Get cow model for verification
	local cowModel = nil
	if CowCreationModule and CowCreationModule.GetActiveCows then
		local activeCows = CowCreationModule:GetActiveCows()
		cowModel = activeCows[cowId]
	end

	-- Verify cow ownership with the model
	if not self:VerifyCowOwnership(player, cowId, cowModel) then
		self:SendNotification(player, "🐄 Cow Error", "You don't own this cow!", "error")
		return false
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
		maxMilk = cowData.milkAmount * 10
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

	local totalMilk = session.milkCollected
	local sessionDuration = os.time() - session.startTime

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
end

function CowMilkingModule:HandleContinueMilking(player)
	local userId = player.UserId
	local session = self.ActiveSessions[userId]

	if not session or not session.isActive then 
		return 
	end

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

-- ========== PLAYER HANDLERS ==========

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
	end)

	print("CowMilkingModule: Player handlers setup complete")
end

-- ========== UTILITY FUNCTIONS ==========

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

-- ========== DEBUG FUNCTIONS ==========

function CowMilkingModule:DebugChairs()
	print("=== CHAIR DEBUG ===")
	print("Total registered chairs: " .. self:CountTable(self.MilkingChairs))

	for chairId, chair in pairs(self.MilkingChairs) do
		if chair and chair.Parent then
			local isOccupied = false
			if chair:IsA("Seat") then
				local success, occupant = pcall(function()
					return chair.Occupant
				end)
				if success then
					isOccupied = occupant ~= nil
				end
			end

			print("Chair: " .. chairId)
			print("  Position: " .. tostring(chair.Position))
			print("  Occupied: " .. tostring(isOccupied))
			print("  Name: " .. chair.Name)
			print("  IsMilkingChair: " .. tostring(chair:GetAttribute("IsMilkingChair")))
		else
			print("Chair: " .. chairId .. " - INVALID (nil or no parent)")
		end
	end

	-- Check workspace for any missed chairs
	print("\nWorkspace scan:")
	for _, obj in pairs(workspace:GetChildren()) do
		if obj.Name == "MilkingChair" then
			local registered = false
			for chairId, chair in pairs(self.MilkingChairs) do
				if chair == obj then
					registered = true
					break
				end
			end
			print("Workspace MilkingChair: " .. obj.Name .. " - Registered: " .. tostring(registered))
		end
	end

	print("===================")
end

function CowMilkingModule:ForceRescanChairs()
	print("🔄 Force rescanning chairs...")
	self.MilkingChairs = {}
	local found = self:ScanForAllChairs()
	self:ForceRegisterMilkingChairs()
	local total = self:CountTable(self.MilkingChairs)
	print("✅ Rescan complete - found: " .. found .. ", total: " .. total)
	return total
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
		proximityStates = {
			count = self:CountTable(self.PlayerProximityState),
			states = self.PlayerProximityState
		}
	}
end

function CowMilkingModule:GetPlayerSession(player)
	return self.ActiveSessions[player.UserId]
end

function CowMilkingModule:ResetPlayerProximity(player)
	local userId = player.UserId
	print("🔄 Resetting proximity state for " .. player.Name)

	self:HideProximityPrompt(player)
	self.PlayerProximityState[userId] = nil

	print("✅ Proximity state reset for " .. player.Name)
end

function CowMilkingModule:DebugPlayerProximity(player)
	local userId = player.UserId
	local proximityState = self.PlayerProximityState[userId]
	local character = player.Character

	print("=== COW MILKING DEBUG FOR " .. player.Name .. " ===")

	if proximityState then
		print("Last prompt: " .. proximityState.lastPrompt)
		print("Current state: " .. proximityState.currentState)
		print("Last update: " .. proximityState.lastUpdate)
		print("Last state change: " .. proximityState.lastStateChange)
	else
		print("No proximity state found")
	end

	if character and character:FindFirstChild("HumanoidRootPart") then
		local nearbyObjects = self:GetVerifiedNearbyObjects(player, character.HumanoidRootPart.Position)
		print("Nearby cows: " .. nearbyObjects.playerCowsNearby)
		print("Nearby chairs: " .. nearbyObjects.milkingChairsNearby)

		for i, cow in ipairs(nearbyObjects.cows) do
			print("  Cow " .. i .. ": " .. cow.id .. " (owner: " .. tostring(cow.owner) .. ", can milk: " .. tostring(cow.canMilk) .. ")")
		end

		for i, chair in ipairs(nearbyObjects.chairs) do
			print("  Chair " .. i .. ": " .. chair.id .. " (occupied: " .. tostring(chair.isOccupied) .. ", distance: " .. math.floor(chair.distance) .. ")")
		end
	end

	-- Check if player has cows in data
	if GameCore then
		local playerData = GameCore:GetPlayerData(player)
		if playerData and playerData.livestock and playerData.livestock.cows then
			local cowCount = 0
			for cowId, cowData in pairs(playerData.livestock.cows) do
				cowCount = cowCount + 1
				print("  Data cow " .. cowCount .. ": " .. cowId .. " (tier: " .. (cowData.tier or "unknown") .. ")")
			end
			print("Total cows in data: " .. cowCount)
		else
			print("No cow data found")
		end
	end

	print("=======================================")
end

function CowMilkingModule:Cleanup()
	-- Stop all active sessions
	for userId, session in pairs(self.ActiveSessions) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			self:HandleStopMilkingSession(player)
		end
	end

	self.ActiveSessions = {}
	self.PlayerProximityState = {}

	print("CowMilkingModule: Cleanup complete")
end

return CowMilkingModule