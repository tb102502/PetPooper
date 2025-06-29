--[[
    ChairMilkingSystem.server.lua - Chair-Based Milking Integration
    Place in: ServerScriptService/ChairMilkingSystem.server.lua
    
    Features:
    ✅ Chair-based milking initiation
    ✅ GUI prompts for chair interaction
    ✅ Player locking when seated
    ✅ Integration with existing clicker system
    ✅ Automatic cleanup when player leaves chair
]]

local ChairMilkingSystem = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Wait for GameCore
local function WaitForGameCore(maxWaitTime)
	maxWaitTime = maxWaitTime or 15
	local startTime = tick()

	while not _G.GameCore and (tick() - startTime) < maxWaitTime do
		wait(0.5)
	end

	return _G.GameCore
end

local GameCore = WaitForGameCore()
if not GameCore then
	warn("ChairMilkingSystem: GameCore not found! System may not work properly.")
end

-- Configuration
ChairMilkingSystem.Config = {
	chairName = "MilkingChair", -- Name of the chair in workspace
	proximityDistance = 10, -- Distance to show GUI prompt
	lockPlayerWhenSeated = true,
	autoDetectCows = true
}

-- System state
ChairMilkingSystem.State = {
	ActiveSessions = {}, -- [userId] = {chair, cow, startTime}
	ProximityConnections = {}, -- [userId] = connection
	SeatedPlayers = {}, -- [userId] = seatConnection
	ChairGUIs = {} -- [userId] = guiReference
}


-- ========== INITIALIZATION ==========

function ChairMilkingSystem:Initialize()
	print("ChairMilkingSystem: Initializing chair-based milking system...")

	-- Setup remote events
	self:SetupRemoteEvents()

	-- Find and setup chairs
	self:SetupMilkingChairs()

	-- Setup player monitoring
	self:SetupPlayerMonitoring()

	-- Start update loops
	self:StartUpdateLoops()

	print("ChairMilkingSystem: Chair-based milking system initialized!")
end

function ChairMilkingSystem:SetupRemoteEvents()
	local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "GameRemotes"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Create chair-specific remotes
	local requiredRemotes = {
		"ShowChairPrompt",
		"HideChairPrompt",
		"StartChairMilking",
		"StopChairMilking"
	}

	for _, remoteName in ipairs(requiredRemotes) do
		if not remoteFolder:FindFirstChild(remoteName) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = remoteName
			remote.Parent = remoteFolder
		end
	end

	-- Connect handlers
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

	print("ChairMilkingSystem: Remote events setup complete")
end

-- ========== CHAIR SETUP AND DETECTION ==========

function ChairMilkingSystem:SetupMilkingChairs()
	print("ChairMilkingSystem: Setting up milking chairs...")

	-- Find all milking chairs in workspace
	local chairsFound = 0

	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("Model") and obj.Name == self.Config.chairName then
			self:SetupIndividualChair(obj)
			chairsFound = chairsFound + 1
		elseif obj:IsA("Part") and obj.Name == self.Config.chairName then
			self:SetupIndividualChair(obj)
			chairsFound = chairsFound + 1
		end
	end

	-- Also check in any folders
	for _, folder in pairs(workspace:GetChildren()) do
		if folder:IsA("Folder") or folder:IsA("Model") then
			for _, obj in pairs(folder:GetDescendants()) do
				if (obj:IsA("Model") or obj:IsA("Part")) and obj.Name == self.Config.chairName then
					self:SetupIndividualChair(obj)
					chairsFound = chairsFound + 1
				end
			end
		end
	end

	print("ChairMilkingSystem: Found and setup " .. chairsFound .. " milking chairs")

	if chairsFound == 0 then
		warn("ChairMilkingSystem: No chairs found with name '" .. self.Config.chairName .. "'")
		warn("ChairMilkingSystem: Make sure your chair is named exactly '" .. self.Config.chairName .. "'")
	end
end

function ChairMilkingSystem:SetupIndividualChair(chair)
	print("ChairMilkingSystem: Setting up chair: " .. chair.Name)

	-- Find the seat part
	local seat = self:FindSeatInChair(chair)
	if not seat then
		warn("ChairMilkingSystem: No seat found in chair: " .. chair.Name)
		return false
	end

	-- Add chair attributes
	chair:SetAttribute("IsChairSetup", true)
	chair:SetAttribute("ChairType", "MilkingChair")

	-- Find nearby cow
	local nearestCow = self:FindNearestCow(chair)
	if nearestCow then
		chair:SetAttribute("AssignedCow", nearestCow.Name)
		print("ChairMilkingSystem: Chair assigned to cow: " .. nearestCow.Name)
	else
		warn("ChairMilkingSystem: No cow found near chair: " .. chair.Name)
	end

	-- Setup seat connection
	if seat.Occupant then
		-- Someone is already sitting
		local humanoid = seat.Occupant
		local character = humanoid.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			self:HandlePlayerSat(player, chair, seat)
		end
	end

	-- Monitor seat changes
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		self:HandleSeatChange(chair, seat)
	end)

	print("ChairMilkingSystem: Chair setup complete: " .. chair.Name)
	return true
end

function ChairMilkingSystem:FindSeatInChair(chair)
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

function ChairMilkingSystem:FindNearestCow(chair)
	local chairPosition = self:GetChairPosition(chair)
	local nearestCow = nil
	local nearestDistance = math.huge

	-- Look for cows in workspace
	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("Model") and (obj.Name == "cow" or obj.Name:find("cow_")) then
			local cowPosition = self:GetModelCenter(obj)
			local distance = (chairPosition - cowPosition).Magnitude

			if distance < nearestDistance and distance < 20 then -- Within 20 studs
				nearestDistance = distance
				nearestCow = obj
			end
		end
	end

	return nearestCow
end

function ChairMilkingSystem:GetChairPosition(chair)
	if chair:IsA("Part") then
		return chair.Position
	elseif chair:IsA("Model") then
		if chair.PrimaryPart then
			return chair.PrimaryPart.Position
		else
			-- Calculate center
			local cf, size = chair:GetBoundingBox()
			return cf.Position
		end
	end
	return Vector3.new(0, 0, 0)
end

function ChairMilkingSystem:GetModelCenter(model)
	if model.PrimaryPart then
		return model.PrimaryPart.Position
	else
		local cf, size = model:GetBoundingBox()
		return cf.Position
	end
end

-- ========== SEAT CHANGE HANDLING ==========

function ChairMilkingSystem:HandleSeatChange(chair, seat)
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

function ChairMilkingSystem:HandlePlayerSat(player, chair, seat)
	print("ChairMilkingSystem: Player " .. player.Name .. " sat in milking chair")

	local userId = player.UserId

	-- Check if player is already in a milking session
	if self.State.ActiveSessions[userId] then
		self:StopMilkingSession(player)
	end

	-- Find assigned cow
	local cowName = chair:GetAttribute("AssignedCow")
	if not cowName then
		self:SendNotification(player, "No Cow Found", "This chair doesn't have a cow assigned to it!", "error")
		return
	end

	local cow = workspace:FindFirstChild(cowName)
	if not cow then
		self:SendNotification(player, "Cow Missing", "The assigned cow was not found!", "error")
		return
	end

	-- Lock player in place if configured
	if self.Config.lockPlayerWhenSeated then
		self:LockPlayerInSeat(player, seat)
	end

	-- Start milking session
	self:StartMilkingSession(player, chair, cow, seat)
end

function ChairMilkingSystem:HandleSeatEmpty(chair, seat)
	print("ChairMilkingSystem: Seat became empty in chair: " .. chair.Name)

	-- Find which player was sitting here and stop their session
	for userId, session in pairs(self.State.ActiveSessions) do
		if session.chair == chair then
			local player = Players:GetPlayerByUserId(userId)
			if player then
				self:StopMilkingSession(player)
			end
			break
		end
	end
end

-- ========== MILKING SESSION MANAGEMENT ==========

function ChairMilkingSystem:StartMilkingSession(player, chair, cow, seat)
	print("ChairMilkingSystem: Starting milking session for " .. player.Name)

	local userId = player.UserId
	local cowId = cow.Name

	-- Check if cow belongs to player
	local cowOwner = cow:GetAttribute("Owner")
	if cowOwner and cowOwner ~= player.Name then
		self:SendNotification(player, "Not Your Cow", "This cow belongs to " .. cowOwner .. "!", "error")
		-- Force player out of seat
		seat:Sit(nil)
		return false
	end

	-- Store session data
	self.State.ActiveSessions[userId] = {
		chair = chair,
		cow = cow,
		cowId = cowId,
		seat = seat,
		startTime = os.time(),
		locked = true
	}

	-- Start GameCore milking session
	if GameCore and GameCore.HandleStartMilkingSession then
		local success = GameCore:HandleStartMilkingSession(player, cowId)

		if success then
			-- Show milking GUI
			self:ShowMilkingGUI(player)

			-- Create visual effects around chair/cow
			self:CreateChairMilkingEffects(player, chair, cow)

			self:SendNotification(player, "🥛 Milking Started!", 
				"Click to collect milk! Session will end when you leave the chair.", "success")

			print("ChairMilkingSystem: Milking session started successfully for " .. player.Name)
			return true
		else
			-- Failed to start
			self.State.ActiveSessions[userId] = nil
			self:UnlockPlayer(player)
			return false
		end
	else
		self:SendNotification(player, "System Error", "Milking system not available!", "error")
		self.State.ActiveSessions[userId] = nil
		return false
	end
end

function ChairMilkingSystem:StopMilkingSession(player)
	print("ChairMilkingSystem: Stopping milking session for " .. player.Name)

	local userId = player.UserId
	local session = self.State.ActiveSessions[userId]

	if not session then
		return false
	end

	-- Stop GameCore milking session
	if GameCore and GameCore.HandleStopMilkingSession then
		GameCore:HandleStopMilkingSession(player)
	end

	-- Unlock player
	self:UnlockPlayer(player)

	-- Hide milking GUI
	self:HideMilkingGUI(player)

	-- Clean up visual effects
	self:CleanupChairMilkingEffects(userId)

	-- Clear session data
	self.State.ActiveSessions[userId] = nil

	self:SendNotification(player, "🥛 Milking Ended", 
		"Milking session complete! Check your inventory.", "info")

	print("ChairMilkingSystem: Milking session stopped for " .. player.Name)
	return true
end

-- ========== PLAYER LOCKING SYSTEM ==========

function ChairMilkingSystem:LockPlayerInSeat(player, seat)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	-- Store original values
	local userId = player.UserId
	if not self.State.SeatedPlayers[userId] then
		self.State.SeatedPlayers[userId] = {
			originalJumpPower = humanoid.JumpPower,
			originalWalkSpeed = humanoid.WalkSpeed,
			seat = seat
		}
	end

	-- Lock player
	humanoid.JumpPower = 0
	humanoid.WalkSpeed = 0
	humanoid.PlatformStand = false -- Don't use PlatformStand as it can cause issues

	print("ChairMilkingSystem: Locked player " .. player.Name .. " in seat")
end

function ChairMilkingSystem:UnlockPlayer(player)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	local userId = player.UserId
	local seatedData = self.State.SeatedPlayers[userId]

	if seatedData then
		-- Restore original values
		humanoid.JumpPower = seatedData.originalJumpPower or 50
		humanoid.WalkSpeed = seatedData.originalWalkSpeed or 16
		humanoid.PlatformStand = false

		-- Clear data
		self.State.SeatedPlayers[userId] = nil

		print("ChairMilkingSystem: Unlocked player " .. player.Name)
	end
end

-- ========== GUI MANAGEMENT ==========

function ChairMilkingSystem:ShowMilkingGUI(player)
	-- Send to client to create GUI
	local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if remoteFolder and remoteFolder:FindFirstChild("ShowChairPrompt") then
		remoteFolder.ShowChairPrompt:FireClient(player, "milking", {
			title = "🥛 Chair Milking Active",
			subtitle = "Click to collect milk!",
			instruction = "Stay seated to continue milking.\nLeave chair to stop."
		})
	end
end

function ChairMilkingSystem:HideMilkingGUI(player)
	local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if remoteFolder and remoteFolder:FindFirstChild("HideChairPrompt") then
		remoteFolder.HideChairPrompt:FireClient(player)
	end
end

function ChairMilkingSystem:ShowProximityGUI(player, chair)
	local cow = workspace:FindFirstChild(chair:GetAttribute("AssignedCow") or "")
	local cowOwner = cow and cow:GetAttribute("Owner") or "unknown"

	local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if remoteFolder and remoteFolder:FindFirstChild("ShowChairPrompt") then
		remoteFolder.ShowChairPrompt:FireClient(player, "proximity", {
			title = "🪑 Milking Chair",
			subtitle = "Sit down to start milking!",
			instruction = cowOwner == player.Name and "This is your cow - sit to start milking!" 
				or ("This cow belongs to " .. cowOwner),
			canUse = cowOwner == player.Name
		})
	end
end

function ChairMilkingSystem:HideProximityGUI(player)
	local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if remoteFolder and remoteFolder:FindFirstChild("HideChairPrompt") then
		remoteFolder.HideChairPrompt:FireClient(player)
	end
end

-- ========== VISUAL EFFECTS ==========

function ChairMilkingSystem:CreateChairMilkingEffects(player, chair, cow)
	local userId = player.UserId

	-- Create area effect around chair
	local chairPosition = self:GetChairPosition(chair)

	local areaEffect = Instance.new("Part")
	areaEffect.Name = "ChairMilkingArea"
	areaEffect.Size = Vector3.new(8, 0.1, 8)
	areaEffect.Shape = Enum.PartType.Cylinder
	areaEffect.Material = Enum.Material.Neon
	areaEffect.Color = Color3.fromRGB(100, 255, 100)
	areaEffect.Transparency = 0.7
	areaEffect.CanCollide = false
	areaEffect.Anchored = true
	areaEffect.Position = chairPosition + Vector3.new(0, -1, 0)
	areaEffect.Orientation = Vector3.new(0, 0, 90)
	areaEffect.Parent = workspace

	-- Gentle pulsing effect
	spawn(function()
		while self.State.ActiveSessions[userId] do
			local pulse = TweenService:Create(areaEffect,
				TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Transparency = 0.5}
			)
			pulse:Play()
			pulse.Completed:Wait()

			if not self.State.ActiveSessions[userId] then break end

			local pulseBack = TweenService:Create(areaEffect,
				TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Transparency = 0.8}
			)
			pulseBack:Play()
			pulseBack.Completed:Wait()
		end
	end)

	-- Store effect for cleanup
	if not self.State.ActiveSessions[userId].effects then
		self.State.ActiveSessions[userId].effects = {}
	end
	table.insert(self.State.ActiveSessions[userId].effects, areaEffect)
end

function ChairMilkingSystem:CleanupChairMilkingEffects(userId)
	local session = self.State.ActiveSessions[userId]
	if session and session.effects then
		for _, effect in pairs(session.effects) do
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
	end
end

-- ========== PLAYER MONITORING ==========

function ChairMilkingSystem:SetupPlayerMonitoring()
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

function ChairMilkingSystem:SetupPlayerProximityMonitoring(player)
	local userId = player.UserId

	-- Proximity detection for chair GUI prompts
	local connection = RunService.Heartbeat:Connect(function()
		if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
			return
		end

		-- Skip if already in a milking session
		if self.State.ActiveSessions[userId] then
			return
		end

		local playerPosition = player.Character.HumanoidRootPart.Position
		local nearChair = false

		-- Check distance to all chairs
		for _, obj in pairs(workspace:GetChildren()) do
			if (obj:IsA("Model") or obj:IsA("Part")) and obj.Name == self.Config.chairName then
				local chairPosition = self:GetChairPosition(obj)
				local distance = (playerPosition - chairPosition).Magnitude

				if distance <= self.Config.proximityDistance then
					nearChair = true
					-- Show proximity GUI if not already showing
					if not self.State.ChairGUIs[userId] then
						self.State.ChairGUIs[userId] = true
						self:ShowProximityGUI(player, obj)
					end
					break
				end
			end
		end

		-- Hide GUI if not near any chair
		if not nearChair and self.State.ChairGUIs[userId] then
			self.State.ChairGUIs[userId] = nil
			self:HideProximityGUI(player)
		end
	end)

	self.State.ProximityConnections[userId] = connection
end

function ChairMilkingSystem:CleanupPlayer(player)
	local userId = player.UserId

	-- Stop any active milking session
	if self.State.ActiveSessions[userId] then
		self:StopMilkingSession(player)
	end

	-- Disconnect proximity monitoring
	if self.State.ProximityConnections[userId] then
		self.State.ProximityConnections[userId]:Disconnect()
		self.State.ProximityConnections[userId] = nil
	end

	-- Clean up GUI state
	self.State.ChairGUIs[userId] = nil

	-- Clean up seated state
	self.State.SeatedPlayers[userId] = nil

	print("ChairMilkingSystem: Cleaned up player " .. player.Name)
end

-- ========== UPDATE LOOPS ==========

function ChairMilkingSystem:StartUpdateLoops()
	-- Monitor active sessions
	spawn(function()
		while true do
			wait(1)
			self:UpdateActiveSessions()
		end
	end)

	-- Chair status monitoring
	spawn(function()
		while true do
			wait(5)
			self:MonitorChairStatus()
		end
	end)
end

function ChairMilkingSystem:UpdateActiveSessions()
	-- Check all active sessions for problems
	local toRemove = {}

	for userId, session in pairs(self.State.ActiveSessions) do
		local player = Players:GetPlayerByUserId(userId)

		-- Check if player is still in game
		if not player or not player.Parent then
			table.insert(toRemove, userId)
			continue
		end

		-- Check if player is still seated
		local seat = session.seat
		if not seat or not seat.Parent then
			table.insert(toRemove, userId)
			continue
		end

		if not seat.Occupant or seat.Occupant.Parent ~= player.Character then
			-- Player left the seat
			self:StopMilkingSession(player)
			continue
		end

		-- Check if cow still exists
		if not session.cow or not session.cow.Parent then
			self:SendNotification(player, "Cow Missing", "The cow has disappeared!", "error")
			table.insert(toRemove, userId)
			continue
		end
	end

	-- Clean up invalid sessions
	for _, userId in ipairs(toRemove) do
		self.State.ActiveSessions[userId] = nil
	end
end

function ChairMilkingSystem:MonitorChairStatus()
	-- Ensure all chairs are properly setup
	for _, obj in pairs(workspace:GetChildren()) do
		if (obj:IsA("Model") or obj:IsA("Part")) and obj.Name == self.Config.chairName then
			if not obj:GetAttribute("IsChairSetup") then
				self:SetupIndividualChair(obj)
			end
		end
	end
end

-- ========== UTILITY FUNCTIONS ==========

function ChairMilkingSystem:SendNotification(player, title, message, notificationType)
	if GameCore and GameCore.SendNotification then
		GameCore:SendNotification(player, title, message, notificationType)
	else
		print("NOTIFICATION for " .. player.Name .. ": [" .. (notificationType or "info"):upper() .. "] " .. title .. " - " .. message)
	end
end

function ChairMilkingSystem:HandleChairMilkingStart(player, chairName)
	-- This is called from client when they click a button to start milking
	-- For chair system, this should be automatic when they sit
	print("ChairMilkingSystem: Manual start request from " .. player.Name .. " (chair system is automatic)")
end

function ChairMilkingSystem:HandleChairMilkingStop(player)
	-- Force player out of chair to stop milking
	local userId = player.UserId
	local session = self.State.ActiveSessions[userId]

	if session and session.seat then
		session.seat:Sit(nil) -- Remove player from seat
	end
end

-- ========== DEBUG COMMANDS ==========

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.Name == "TommySalami311" then -- Replace with your username
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/chairstatus" then
				print("=== CHAIR MILKING SYSTEM STATUS ===")
				print("Active sessions: " .. ChairMilkingSystem:CountTable(ChairMilkingSystem.State.ActiveSessions))
				print("Proximity connections: " .. ChairMilkingSystem:CountTable(ChairMilkingSystem.State.ProximityConnections))
				print("Seated players: " .. ChairMilkingSystem:CountTable(ChairMilkingSystem.State.SeatedPlayers))

				-- List active sessions
				for userId, session in pairs(ChairMilkingSystem.State.ActiveSessions) do
					local sessionPlayer = Players:GetPlayerByUserId(userId)
					local playerName = sessionPlayer and sessionPlayer.Name or "Unknown"
					print("  " .. playerName .. ": milking " .. session.cowId)
				end

				-- Check chairs
				local chairCount = 0
				for _, obj in pairs(workspace:GetChildren()) do
					if obj.Name == ChairMilkingSystem.Config.chairName then
						chairCount = chairCount + 1
						local assignedCow = obj:GetAttribute("AssignedCow") or "none"
						print("  Chair: " .. obj.Name .. " -> Cow: " .. assignedCow)
					end
				end
				print("Total chairs found: " .. chairCount)
				print("===================================")

			elseif command == "/forceunlock" then
				ChairMilkingSystem:UnlockPlayer(player)
				print("Force unlocked " .. player.Name)

			elseif command == "/resetchair" then
				ChairMilkingSystem:CleanupPlayer(player)
				ChairMilkingSystem:SetupPlayerProximityMonitoring(player)
				print("Reset chair system for " .. player.Name)

			elseif command == "/findchairs" then
				print("=== SEARCHING FOR CHAIRS ===")
				local found = 0
				for _, obj in pairs(workspace:GetDescendants()) do
					if obj.Name == ChairMilkingSystem.Config.chairName then
						found = found + 1
						print("Found chair: " .. obj:GetFullName())

						local seat = ChairMilkingSystem:FindSeatInChair(obj)
						if seat then
							print("  Has seat: " .. seat.Name .. " (Occupant: " .. tostring(seat.Occupant ~= nil) .. ")")
						else
							print("  ❌ No seat found!")
						end
					end
				end
				print("Total found: " .. found)
				print("===========================")
			end
		end
	end)
end)

function ChairMilkingSystem:CountTable(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- ========== INITIALIZATION ==========

ChairMilkingSystem:Initialize()
_G.ChairMilkingSystem = ChairMilkingSystem

print("ChairMilkingSystem: ✅ Chair-based milking system loaded!")
print("🪑 CHAIR SYSTEM FEATURES:")
print("  🪑 Automatic milking when sitting in chair")
print("  🔒 Player locking when seated")
print("  🎯 Proximity GUI prompts")
print("  🐄 Automatic cow assignment")
print("  ✨ Visual effects and feedback")
print("  🧹 Automatic cleanup when leaving chair")
print("")
print("🔧 Debug Commands:")
print("  /chairstatus - Show system status")
print("  /forceunlock - Force unlock player")
print("  /resetchair - Reset chair system for player")
print("  /findchairs - Search for chairs in workspace")
print("")
print("📋 SETUP CHECKLIST:")
print("  1. Make sure your chair is named exactly 'MilkingChair'")
print("  2. Chair should have a Seat object")
print("  3. Place chair within 20 studs of a cow")
print("  4. Add the client GUI script to StarterPlayerScripts")