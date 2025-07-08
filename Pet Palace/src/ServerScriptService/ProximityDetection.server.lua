--[[
    ProximityDetection.server.lua - Cow and Chair Proximity Detection System
    Place in: ServerScriptService/ProximityDetection.server.lua
    
    This script handles proximity detection for cows and milking chairs,
    triggering the appropriate GUI messages for players.
]]

local ProximityDetection = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- State
ProximityDetection.PlayerProximity = {} -- [userId] = {nearbyObjects, lastUpdate, currentState, lastStateChange}
ProximityDetection.ActivePrompts = {} -- [userId] = {promptType, showTime, isVisible}
ProximityDetection.Connections = {}
ProximityDetection.PlayerStates = {} -- [userId] = {currentPrompt, lastPromptTime, promptVisible}

-- Configuration
ProximityDetection.Config = {
	updateInterval = 2,        -- How often to check proximity (seconds) - increased from 1
	proximityDistance = 15,    -- Distance to show proximity prompts
	milkingDistance = 8,       -- Distance required for milking
	promptCooldown = 3,        -- Minimum time between prompt changes (seconds)
	stateChangeDelay = 1       -- Delay before state changes (seconds)
}

-- References
local CowMilkingModule = nil
local CowCreationModule = nil
local RemoteEvents = {}

-- ========== INITIALIZATION ==========

function ProximityDetection:Initialize()
	print("ProximityDetection: Initializing cow proximity system...")

	-- Wait for required modules
	self:WaitForModules()

	-- Setup remote events
	self:SetupRemoteEvents()

	-- Start proximity monitoring
	self:StartProximityMonitoring()

	-- Setup player handlers
	self:SetupPlayerHandlers()

	print("ProximityDetection: Cow proximity system initialized!")
end

function ProximityDetection:WaitForModules()
	print("ProximityDetection: Waiting for required modules...")

	local maxWait = 30
	local startTime = tick()

	while (tick() - startTime) < maxWait do
		if _G.CowMilkingModule and _G.CowCreationModule then
			CowMilkingModule = _G.CowMilkingModule
			CowCreationModule = _G.CowCreationModule
			print("✅ ProximityDetection: Required modules found!")
			return true
		end
		wait(1)
	end

	warn("❌ ProximityDetection: Required modules not found after " .. maxWait .. " seconds")
	return false
end

function ProximityDetection:SetupRemoteEvents()
	local remoteFolder = ReplicatedStorage:WaitForChild("GameRemotes", 10)
	if not remoteFolder then
		warn("ProximityDetection: GameRemotes folder not found!")
		return
	end

	RemoteEvents.ShowChairPrompt = remoteFolder:FindFirstChild("ShowChairPrompt")
	RemoteEvents.HideChairPrompt = remoteFolder:FindFirstChild("HideChairPrompt")

	if RemoteEvents.ShowChairPrompt and RemoteEvents.HideChairPrompt then
		print("✅ ProximityDetection: Remote events connected")
	else
		warn("❌ ProximityDetection: Required remote events not found")
	end
end

-- ========== PROXIMITY MONITORING ==========

function ProximityDetection:StartProximityMonitoring()
	print("ProximityDetection: Starting proximity monitoring...")

	-- Main proximity check loop
	spawn(function()
		while true do
			wait(self.Config.updateInterval)
			self:UpdateAllPlayerProximity()
		end
	end)

	print("✅ ProximityDetection: Monitoring started")
end

function ProximityDetection:UpdateAllPlayerProximity()
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			self:UpdatePlayerProximity(player)
		end
	end
end

function ProximityDetection:UpdatePlayerProximity(player)
	local character = player.Character
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local userId = player.UserId
	local playerPos = rootPart.Position
	local currentTime = tick()

	-- Initialize player state if needed
	if not self.PlayerStates[userId] then
		self.PlayerStates[userId] = {
			currentPrompt = "none",
			lastPromptTime = 0,
			promptVisible = false,
			lastPosition = playerPos,
			lastCheckTime = 0
		}
	end

	local playerState = self.PlayerStates[userId]

	-- Check if enough time has passed since last update
	if (currentTime - playerState.lastCheckTime) < self.Config.stateChangeDelay then
		return
	end

	playerState.lastCheckTime = currentTime

	-- Skip if player is already in a milking session
	if CowMilkingModule and CowMilkingModule.GetPlayerSession then
		local session = CowMilkingModule:GetPlayerSession(player)
		if session and session.isActive then
			-- Player is milking, hide any proximity prompts
			if playerState.promptVisible then
				self:HideProximityPrompt(player)
				playerState.promptVisible = false
				playerState.currentPrompt = "milking"
			end
			return
		end
	end

	-- Check if player moved significantly
	local distanceMoved = (playerPos - playerState.lastPosition).Magnitude
	if distanceMoved < 3 and playerState.promptVisible then
		-- Player hasn't moved much and prompt is already visible, don't update
		return
	end

	playerState.lastPosition = playerPos

	-- Check what's nearby
	local nearbyObjects = self:GetNearbyMilkingObjects(player, playerPos)

	-- Determine what prompt to show
	local promptType = self:DeterminePromptType(nearbyObjects)

	-- Check if prompt type changed and enough time has passed
	local timeSinceLastPrompt = currentTime - playerState.lastPromptTime

	if promptType ~= playerState.currentPrompt and timeSinceLastPrompt >= self.Config.promptCooldown then
		print("🔄 Proximity state change for " .. player.Name .. ": " .. playerState.currentPrompt .. " -> " .. promptType)

		self:UpdatePlayerPrompt(player, promptType, nearbyObjects)
		playerState.currentPrompt = promptType
		playerState.lastPromptTime = currentTime
		playerState.promptVisible = (promptType ~= "none")
	end
end

function ProximityDetection:GetNearbyMilkingObjects(player, playerPos)
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
			if cowModel and cowModel.Parent then
				local owner = cowModel:GetAttribute("Owner")
				if owner == player.Name then
					local cowPos = self:GetModelCenter(cowModel)
					local distance = (playerPos - cowPos).Magnitude

					if distance <= self.Config.proximityDistance then
						table.insert(nearby.cows, {
							id = cowId,
							model = cowModel,
							distance = distance,
							canMilk = self:CanMilkCow(player, cowId)
						})
						nearby.playerCowsNearby = nearby.playerCowsNearby + 1
					end
				end
			end
		end
	end

	-- Check for milking chairs
	if CowMilkingModule and CowMilkingModule.MilkingChairs then
		for chairId, chair in pairs(CowMilkingModule.MilkingChairs) do
			if chair and chair.Parent then
				local distance = (playerPos - chair.Position).Magnitude

				if distance <= self.Config.proximityDistance then
					table.insert(nearby.chairs, {
						id = chairId,
						model = chair,
						distance = distance,
						isOccupied = chair.Occupant ~= nil
					})
					nearby.milkingChairsNearby = nearby.milkingChairsNearby + 1
				end
			end
		end
	end

	return nearby
end

function ProximityDetection:CanMilkCow(player, cowId)
	if not CowCreationModule or not CowCreationModule.GetCowData then
		return false
	end

	local cowData = CowCreationModule:GetCowData(player, cowId)
	if not cowData then return false end

	-- Check cooldown
	local currentTime = os.time()
	local lastMilked = cowData.lastMilkCollection or 0
	local cooldown = cowData.cooldown or 60

	return (currentTime - lastMilked) >= cooldown
end

function ProximityDetection:DeterminePromptType(nearbyObjects)
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

	-- Determine prompt type based on what's available
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

function ProximityDetection:UpdatePlayerPrompt(player, promptType, nearbyObjects)
	if promptType == "none" then
		self:HideProximityPrompt(player)
		return
	end

	local promptData = self:CreatePromptData(promptType, nearbyObjects)
	self:ShowProximityPrompt(player, promptData)
end

function ProximityDetection:CreatePromptData(promptType, nearbyObjects)
	local data = {
		type = promptType,
		canUse = false,
		title = "🐄 Cow Nearby",
		subtitle = "Unknown status",
		instruction = "Check your setup"
	}

	if promptType == "ready_to_milk" then
		data.canUse = true
		data.title = "🥛 Ready to Milk!"
		data.subtitle = "Sit in the chair to start milking"
		data.instruction = "Find the brown wooden chair and sit down"

	elseif promptType == "need_chair" then
		data.canUse = false
		data.title = "🪑 Chair Needed"
		data.subtitle = "Your cow is ready, but no chair available"
		data.instruction = "Find an empty milking chair or wait for one"

	elseif promptType == "cow_cooldown" then
		data.canUse = false
		data.title = "⏰ Cow Resting"
		data.subtitle = "Your cow needs time to produce more milk"

		-- Calculate time remaining
		local cow = nearbyObjects.cows[1]
		if cow and CowCreationModule and CowCreationModule.GetCowData then
			local cowData = CowCreationModule:GetCowData(Players:GetPlayerFromCharacter(cow.model.Parent), cow.id)
			if cowData then
				local currentTime = os.time()
				local lastMilked = cowData.lastMilkCollection or 0
				local cooldown = cowData.cooldown or 60
				local timeLeft = cooldown - (currentTime - lastMilked)

				if timeLeft > 0 then
					data.instruction = "Wait " .. math.ceil(timeLeft) .. " more seconds"
				else
					data.instruction = "Cow should be ready now!"
				end
			end
		end

	elseif promptType == "cow_not_ready" then
		data.canUse = false
		data.title = "🐄 Cow Nearby"
		data.subtitle = "Cow is not ready for milking yet"
		data.instruction = "Wait for your cow to be ready"
	end

	return data
end

function ProximityDetection:ShowProximityPrompt(player, promptData)
	if not RemoteEvents.ShowChairPrompt then return end

	local userId = player.UserId
	local playerState = self.PlayerStates[userId]

	if not playerState then
		playerState = {
			currentPrompt = "none",
			lastPromptTime = 0,
			promptVisible = false
		}
		self.PlayerStates[userId] = playerState
	end

	-- Only show if not already visible with same type
	if playerState.promptVisible and playerState.currentPrompt == promptData.type then
		return -- Already showing this prompt, don't recreate
	end

	print("📢 Showing proximity prompt to " .. player.Name .. ": " .. promptData.type)

	RemoteEvents.ShowChairPrompt:FireClient(player, "proximity", {
		title = promptData.title,
		subtitle = promptData.subtitle,
		instruction = promptData.instruction,
		canUse = promptData.canUse,
		promptType = promptData.type
	})

	playerState.promptVisible = true
	playerState.currentPrompt = promptData.type
end

function ProximityDetection:HideProximityPrompt(player)
	if not RemoteEvents.HideChairPrompt then return end

	local userId = player.UserId
	local playerState = self.PlayerStates[userId]

	if playerState and playerState.promptVisible then
		print("🚫 Hiding proximity prompt for " .. player.Name)
		RemoteEvents.HideChairPrompt:FireClient(player)
		playerState.promptVisible = false
		playerState.currentPrompt = "none"
	end
end

-- ========== PLAYER HANDLERS ==========

function ProximityDetection:SetupPlayerHandlers()
	-- Handle new players
	Players.PlayerAdded:Connect(function(player)
		local userId = player.UserId

		self.PlayerProximity[userId] = {
			nearbyObjects = {},
			lastUpdate = 0,
			currentState = "none",
			lastStateChange = 0
		}

		self.PlayerStates[userId] = {
			currentPrompt = "none",
			lastPromptTime = 0,
			promptVisible = false,
			lastPosition = Vector3.new(0, 0, 0),
			lastCheckTime = 0
		}

		print("👋 ProximityDetection: Setup for " .. player.Name)
	end)

	-- Handle leaving players
	Players.PlayerRemoving:Connect(function(player)
		local userId = player.UserId

		-- Clean up all state
		self.PlayerProximity[userId] = nil
		self.ActivePrompts[userId] = nil
		self.PlayerStates[userId] = nil

		print("👋 ProximityDetection: Cleanup for " .. player.Name)
	end)

	-- Setup for existing players
	for _, player in pairs(Players:GetPlayers()) do
		local userId = player.UserId

		self.PlayerProximity[userId] = {
			nearbyObjects = {},
			lastUpdate = 0,
			currentState = "none",
			lastStateChange = 0
		}

		self.PlayerStates[userId] = {
			currentPrompt = "none",
			lastPromptTime = 0,
			promptVisible = false,
			lastPosition = Vector3.new(0, 0, 0),
			lastCheckTime = 0
		}
	end
end

-- ========== UTILITY FUNCTIONS ==========

function ProximityDetection:GetModelCenter(model)
	if model.PrimaryPart then
		return model.PrimaryPart.Position
	end

	local cf, size = model:GetBoundingBox()
	return cf.Position
end

-- ========== DEBUG FUNCTIONS ==========

function ProximityDetection:DebugPlayerProximity(player)
	local userId = player.UserId
	local proximityData = self.PlayerProximity[userId]
	local playerState = self.PlayerStates[userId]

	print("=== PROXIMITY DEBUG FOR " .. player.Name .. " ===")

	if playerState then
		print("Current prompt: " .. playerState.currentPrompt)
		print("Prompt visible: " .. tostring(playerState.promptVisible))
		print("Last prompt time: " .. playerState.lastPromptTime)
		print("Last check time: " .. playerState.lastCheckTime)

		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local currentPos = player.Character.HumanoidRootPart.Position
			local distance = (currentPos - playerState.lastPosition).Magnitude
			print("Distance since last check: " .. math.floor(distance * 100) / 100)
		end
	end

	if proximityData then
		print("Last update: " .. proximityData.lastUpdate)
		print("Current state: " .. proximityData.currentState)
	end

	-- Get current proximity
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local nearbyObjects = self:GetNearbyMilkingObjects(player, player.Character.HumanoidRootPart.Position)
		print("Current nearby cows: " .. nearbyObjects.playerCowsNearby)
		print("Current nearby chairs: " .. nearbyObjects.milkingChairsNearby)

		for i, cow in ipairs(nearbyObjects.cows) do
			print("  Cow " .. i .. ": " .. cow.id .. " (can milk: " .. tostring(cow.canMilk) .. ")")
		end

		for i, chair in ipairs(nearbyObjects.chairs) do
			print("  Chair " .. i .. ": " .. chair.id .. " (occupied: " .. tostring(chair.isOccupied) .. ")")
		end
	end

	print("=======================================")
end

function ProximityDetection:ResetPlayerProximity(player)
	local userId = player.UserId

	print("🔄 Resetting proximity state for " .. player.Name)

	-- Hide any active prompts
	self:HideProximityPrompt(player)

	-- Reset state
	self.PlayerStates[userId] = {
		currentPrompt = "none",
		lastPromptTime = 0,
		promptVisible = false,
		lastPosition = Vector3.new(0, 0, 0),
		lastCheckTime = 0
	}

	self.PlayerProximity[userId] = {
		nearbyObjects = {},
		lastUpdate = 0,
		currentState = "none",
		lastStateChange = 0
	}

	print("✅ Proximity state reset for " .. player.Name)
end

function ProximityDetection:ForceUpdatePlayer(player)
	local userId = player.UserId
	local playerState = self.PlayerStates[userId]

	if playerState then
		-- Reset timing to force update
		playerState.lastPromptTime = 0
		playerState.lastCheckTime = 0
		playerState.currentPrompt = "none"
		playerState.promptVisible = false

		-- Force immediate update
		self:UpdatePlayerProximity(player)

		print("🔄 Forced proximity update for " .. player.Name)
	end
end

-- Make debug function global
_G.DebugProximity = function(playerName)
	local player = Players:FindFirstChild(playerName)
	if player and ProximityDetection.DebugPlayerProximity then
		ProximityDetection:DebugPlayerProximity(player)
	else
		print("Player not found or proximity system not loaded")
	end
end

-- ========== INITIALIZATION ==========

-- Wait for server to load then initialize
spawn(function()
	wait(3) -- Give time for other systems to load

	local success, error = pcall(function()
		ProximityDetection:Initialize()
	end)

	if success then
		print("✅ ProximityDetection: System ready!")

		-- Make globally available
		_G.ProximityDetection = ProximityDetection

		-- Setup debug commands
		Players.PlayerAdded:Connect(function(player)
			player.Chatted:Connect(function(message)
				if player.Name == "TommySalami311" then -- Replace with your username
					local command = message:lower()

					if command == "/proximitytest" then
						ProximityDetection:DebugPlayerProximity(player)
					elseif command == "/forceprompt" then
						ProximityDetection:ShowProximityPrompt(player, {
							title = "🧪 Test Prompt",
							subtitle = "This is a test proximity prompt",
							instruction = "If you see this, the proximity system works!",
							canUse = true,
							type = "test"
						})
					elseif command == "/hideprompt" then
						ProximityDetection:HideProximityPrompt(player)
					elseif command == "/resetproximity" then
						ProximityDetection:ResetPlayerProximity(player)
					elseif command == "/forceupdate" then
						ProximityDetection:ForceUpdatePlayer(player)
					elseif command == "/proximitystate" then
						local userId = player.UserId
						local state = ProximityDetection.PlayerStates[userId]
						if state then
							print("🔍 Proximity state for " .. player.Name .. ":")
							print("  Current prompt: " .. state.currentPrompt)
							print("  Prompt visible: " .. tostring(state.promptVisible))
							print("  Last prompt time: " .. state.lastPromptTime)
							print("  Time since last prompt: " .. (tick() - state.lastPromptTime))
						else
							print("❌ No proximity state found for " .. player.Name)
						end
					end
				end
			end)
		end)
	else
		warn("❌ ProximityDetection: Failed to initialize: " .. tostring(error))
	end
end)

print("🔍 ProximityDetection: Script loaded, waiting for initialization...")