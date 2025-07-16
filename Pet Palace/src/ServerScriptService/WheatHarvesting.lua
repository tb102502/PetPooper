--[[
    WheatHarvesting.lua - Server-side Wheat Harvesting System
    Place in: ServerScriptService/WheatHarvesting.lua
    
    FEATURES:
    ✅ Proximity detection for wheat field
    ✅ Harvesting progress tracking (10 swings = 1 wheat)
    ✅ 6 sections with 1 wheat each
    ✅ Integration with existing inventory system
    ✅ Similar to cow milking system
]]

local WheatHarvesting = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Configuration
local HARVESTING_CONFIG = {
	SWINGS_PER_WHEAT = 10,
	TOTAL_SECTIONS = 6,
	WHEAT_PER_SECTION = 1,
	PROXIMITY_DISTANCE = 15,
	HARVESTING_COOLDOWN = 0.5, -- Seconds between swings
	RESPAWN_TIME = 300 -- 5 minutes in seconds
}

-- Load ItemConfig safely
local ItemConfig = nil
local function loadItemConfig()
	local success, result = pcall(function()
		return require(ReplicatedStorage:WaitForChild("ItemConfig", 10))
	end)
	if success then
		ItemConfig = result
		print("WheatHarvesting: ItemConfig loaded successfully")
	else
		warn("WheatHarvesting: Could not load ItemConfig: " .. tostring(result))
		-- Create fallback ItemConfig
		ItemConfig = {
			ShopItems = {},
			Crops = {},
			MiningSystem = {ores = {}}
		}
	end
end

-- State tracking
WheatHarvesting.GameCore = nil
WheatHarvesting.RemoteEvents = {}
WheatHarvesting.WheatField = nil
WheatHarvesting.WheatSections = {}
WheatHarvesting.PlayerSessions = {}
WheatHarvesting.ProximityConnections = {}
WheatHarvesting.SectionData = {}

-- ========== INITIALIZATION ==========

function WheatHarvesting:Initialize(gameCore)
	print("WheatHarvesting: Initializing wheat harvesting system...")

	self.GameCore = gameCore

	-- Load ItemConfig first
	loadItemConfig()

	-- Setup wheat field reference
	self:SetupWheatField()

	-- Setup remote events
	self:SetupRemoteEvents()

	-- Setup proximity detection
	self:SetupProximityDetection()

	-- Initialize section data
	self:InitializeSectionData()

	-- Setup respawn system
	self:SetupRespawnSystem()

	print("WheatHarvesting: ✅ Wheat harvesting system initialized")
	print("  Wheat field sections: " .. #self.WheatSections)
	print("  Configuration: " .. HARVESTING_CONFIG.SWINGS_PER_WHEAT .. " swings per wheat")

	return true
end

-- ========== WHEAT FIELD SETUP ==========

function WheatHarvesting:SetupWheatField()
	print("WheatHarvesting: Setting up wheat field...")

	-- Find the WheatField model
	self.WheatField = workspace:FindFirstChild("WheatField")
	if not self.WheatField then
		error("WheatHarvesting: WheatField model not found in workspace!")
	end

	-- Find wheat sections (should be models/parts within WheatField)
	self.WheatSections = {}

	-- Look for numbered sections first (Cluster1, Cluster2, etc.)
	for i = 1, HARVESTING_CONFIG.TOTAL_SECTIONS do
		local section = self.WheatField:FindFirstChild("Cluster" .. i)
		if section then
			table.insert(self.WheatSections, section)
			print("WheatHarvesting: Found wheat section: " .. section.Name)
		end
	end

	-- If no numbered sections, look for any child models/parts
	if #self.WheatSections == 0 then
		for _, child in pairs(self.WheatField:GetChildren()) do
			if child:IsA("Model") or child:IsA("BasePart") then
				table.insert(self.WheatSections, child)
				print("WheatHarvesting: Found wheat section: " .. child.Name)
			end
		end
	end

	if #self.WheatSections == 0 then
		error("WheatHarvesting: No wheat sections found in WheatField!")
	end

	print("WheatHarvesting: Found " .. #self.WheatSections .. " wheat sections")
end

-- ========== REMOTE EVENTS SETUP ==========

function WheatHarvesting:SetupRemoteEvents()
	print("WheatHarvesting: Setting up remote events...")

	local remotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not remotes then
		error("WheatHarvesting: GameRemotes folder not found!")
	end

	-- Required remote events
	local requiredEvents = {
		"ShowWheatPrompt",
		"HideWheatPrompt", 
		"StartWheatHarvesting",
		"StopWheatHarvesting",
		"SwingScythe",
		"WheatHarvestUpdate"
	}

	-- Create/connect remote events
	for _, eventName in ipairs(requiredEvents) do
		local event = remotes:FindFirstChild(eventName)
		if not event then
			event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = remotes
			print("WheatHarvesting: Created RemoteEvent: " .. eventName)
		end
		self.RemoteEvents[eventName] = event
	end

	-- Connect event handlers
	self:ConnectEventHandlers()
end

function WheatHarvesting:ConnectEventHandlers()
	print("WheatHarvesting: Connecting event handlers...")

	-- Start harvesting session
	self.RemoteEvents.StartWheatHarvesting.OnServerEvent:Connect(function(player)
		self:StartHarvestingSession(player)
	end)

	-- Stop harvesting session
	self.RemoteEvents.StopWheatHarvesting.OnServerEvent:Connect(function(player)
		self:StopHarvestingSession(player)
	end)

	-- Handle scythe swings
	self.RemoteEvents.SwingScythe.OnServerEvent:Connect(function(player)
		self:HandleScytheSwing(player)
	end)

	print("WheatHarvesting: ✅ Event handlers connected")
end

-- ========== SECTION DATA INITIALIZATION ==========

function WheatHarvesting:InitializeSectionData()
	print("WheatHarvesting: Initializing section data...")

	for i, section in ipairs(self.WheatSections) do
		self.SectionData[i] = {
			section = section,
			isHarvested = false,
			harvestedTime = 0,
			respawnTime = 0
		}
	end

	print("WheatHarvesting: ✅ Section data initialized for " .. #self.WheatSections .. " sections")
end

-- ========== PROXIMITY DETECTION ==========

function WheatHarvesting:SetupProximityDetection()
	print("WheatHarvesting: Setting up proximity detection...")

	-- Create proximity detection for wheat field
	local connection = RunService.Heartbeat:Connect(function()
		self:CheckPlayerProximity()
	end)

	table.insert(self.ProximityConnections, connection)
	print("WheatHarvesting: ✅ Proximity detection active")
end

function WheatHarvesting:CheckPlayerProximity()
	if not self.WheatField then return end

	local wheatCenter = self.WheatField:GetModelCFrame().Position

	for _, player in pairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local playerPos = player.Character.HumanoidRootPart.Position
			local distance = (playerPos - wheatCenter).Magnitude

			local wasNearWheat = self.PlayerSessions[player.UserId] and self.PlayerSessions[player.UserId].nearWheat
			local isNearWheat = distance <= HARVESTING_CONFIG.PROXIMITY_DISTANCE

			if isNearWheat and not wasNearWheat then
				self:PlayerEnteredWheatProximity(player)
			elseif not isNearWheat and wasNearWheat then
				self:PlayerLeftWheatProximity(player)
			end
		end
	end
end

function WheatHarvesting:PlayerEnteredWheatProximity(player)
	print("WheatHarvesting: " .. player.Name .. " entered wheat field proximity")

	-- Initialize session if needed
	if not self.PlayerSessions[player.UserId] then
		self.PlayerSessions[player.UserId] = {
			nearWheat = false,
			harvesting = false,
			currentSection = 1,
			swingProgress = 0,
			lastSwingTime = 0
		}
	end

	self.PlayerSessions[player.UserId].nearWheat = true

	-- Check if player has scythe
	local hasScythe = self:PlayerHasScythe(player)

	-- Show wheat prompt
	self.RemoteEvents.ShowWheatPrompt:FireClient(player, hasScythe, self:GetAvailableWheatCount())
end

function WheatHarvesting:PlayerLeftWheatProximity(player)
	print("WheatHarvesting: " .. player.Name .. " left wheat field proximity")

	if self.PlayerSessions[player.UserId] then
		self.PlayerSessions[player.UserId].nearWheat = false

		-- Stop harvesting if active
		if self.PlayerSessions[player.UserId].harvesting then
			self:StopHarvestingSession(player)
		end
	end

	-- Hide wheat prompt
	self.RemoteEvents.HideWheatPrompt:FireClient(player)
end

-- ========== HARVESTING SESSION MANAGEMENT ==========

function WheatHarvesting:StartHarvestingSession(player)
	print("WheatHarvesting: Starting harvesting session for " .. player.Name)

	-- Validate player state
	if not self.PlayerSessions[player.UserId] or not self.PlayerSessions[player.UserId].nearWheat then
		print("WheatHarvesting: Player not near wheat field")
		return
	end

	-- Check if player has scythe
	if not self:PlayerHasScythe(player) then
		if self.GameCore and self.GameCore.SendNotification then
			self.GameCore:SendNotification(player, "No Scythe", "You need a scythe to harvest wheat! Get one from the Scythe Giver.", "warning")
		end
		return
	end

	-- Check if any wheat is available
	local availableWheat = self:GetAvailableWheatCount()
	if availableWheat <= 0 then
		if self.GameCore and self.GameCore.SendNotification then
			self.GameCore:SendNotification(player, "No Wheat", "All wheat has been harvested! Wait for it to respawn.", "info")
		end
		return
	end

	-- Start harvesting session
	local session = self.PlayerSessions[player.UserId]
	session.harvesting = true
	session.currentSection = self:GetNextAvailableSection()
	session.swingProgress = 0
	session.lastSwingTime = tick()

	-- Notify client
	self.RemoteEvents.WheatHarvestUpdate:FireClient(player, {
		harvesting = true,
		currentSection = session.currentSection,
		swingProgress = session.swingProgress,
		maxSwings = HARVESTING_CONFIG.SWINGS_PER_WHEAT,
		availableWheat = availableWheat
	})

	print("WheatHarvesting: ✅ Harvesting session started for " .. player.Name)
end

function WheatHarvesting:StopHarvestingSession(player)
	print("WheatHarvesting: Stopping harvesting session for " .. player.Name)

	if self.PlayerSessions[player.UserId] then
		self.PlayerSessions[player.UserId].harvesting = false
		self.PlayerSessions[player.UserId].swingProgress = 0

		-- Notify client
		self.RemoteEvents.WheatHarvestUpdate:FireClient(player, {
			harvesting = false,
			currentSection = 0,
			swingProgress = 0,
			maxSwings = HARVESTING_CONFIG.SWINGS_PER_WHEAT,
			availableWheat = self:GetAvailableWheatCount()
		})
	end
end

-- ========== SCYTHE SWING HANDLING ==========

function WheatHarvesting:HandleScytheSwing(player)
	local session = self.PlayerSessions[player.UserId]
	if not session or not session.harvesting then
		return
	end

	-- Check cooldown
	local currentTime = tick()
	if (currentTime - session.lastSwingTime) < HARVESTING_CONFIG.HARVESTING_COOLDOWN then
		return
	end

	session.lastSwingTime = currentTime

	-- Check if player has scythe
	if not self:PlayerHasScythe(player) then
		self:StopHarvestingSession(player)
		return
	end

	-- Increment swing progress
	session.swingProgress = session.swingProgress + 1

	print("WheatHarvesting: " .. player.Name .. " swung scythe (" .. session.swingProgress .. "/" .. HARVESTING_CONFIG.SWINGS_PER_WHEAT .. ")")

	-- Check if section is completed
	if session.swingProgress >= HARVESTING_CONFIG.SWINGS_PER_WHEAT then
		self:CompleteSection(player, session.currentSection)

		-- Move to next section or end harvesting
		local nextSection = self:GetNextAvailableSection()
		if nextSection then
			session.currentSection = nextSection
			session.swingProgress = 0
			print("WheatHarvesting: Moving " .. player.Name .. " to section " .. nextSection)
		else
			-- All sections completed
			self:StopHarvestingSession(player)
			if self.GameCore and self.GameCore.SendNotification then
				self.GameCore:SendNotification(player, "🌾 Harvest Complete", "All wheat has been harvested! Great work!", "success")
			end
			return
		end
	end

	-- Update client
	self.RemoteEvents.WheatHarvestUpdate:FireClient(player, {
		harvesting = true,
		currentSection = session.currentSection,
		swingProgress = session.swingProgress,
		maxSwings = HARVESTING_CONFIG.SWINGS_PER_WHEAT,
		availableWheat = self:GetAvailableWheatCount()
	})
end

function WheatHarvesting:CompleteSection(player, sectionIndex)
	print("WheatHarvesting: " .. player.Name .. " completed section " .. sectionIndex)

	-- Mark section as harvested
	if self.SectionData[sectionIndex] then
		self.SectionData[sectionIndex].isHarvested = true
		self.SectionData[sectionIndex].harvestedTime = tick()
		self.SectionData[sectionIndex].respawnTime = tick() + HARVESTING_CONFIG.RESPAWN_TIME

		-- Visual feedback - hide/fade the section
		self:HideWheatSection(sectionIndex)
	end

	-- Give wheat to player
	if self.GameCore and self.GameCore.AddItemToInventory then
		local success = self.GameCore:AddItemToInventory(player, "farming", "wheat", HARVESTING_CONFIG.WHEAT_PER_SECTION)

		if success then
			if self.GameCore.SendNotification then
				self.GameCore:SendNotification(player, "🌾 Wheat Harvested", 
					"Harvested " .. HARVESTING_CONFIG.WHEAT_PER_SECTION .. " wheat from this section!", "success")
			end

			-- Update player stats
			local playerData = self.GameCore:GetPlayerData(player)
			if playerData then
				playerData.stats = playerData.stats or {}
				playerData.stats.wheatHarvested = (playerData.stats.wheatHarvested or 0) + HARVESTING_CONFIG.WHEAT_PER_SECTION
				self.GameCore:UpdatePlayerData(player, playerData)
			end
		else
			print("WheatHarvesting: Failed to add wheat to " .. player.Name .. "'s inventory")
		end
	end
end

-- ========== UTILITY FUNCTIONS ==========

function WheatHarvesting:PlayerHasScythe(player)
	return player.Backpack:FindFirstChild("Scythe") or 
		(player.Character and player.Character:FindFirstChild("Scythe"))
end

function WheatHarvesting:GetAvailableWheatCount()
	local count = 0
	for _, sectionData in pairs(self.SectionData) do
		if not sectionData.isHarvested then
			count = count + HARVESTING_CONFIG.WHEAT_PER_SECTION
		end
	end
	return count
end

function WheatHarvesting:GetNextAvailableSection()
	for i, sectionData in pairs(self.SectionData) do
		if not sectionData.isHarvested then
			return i
		end
	end
	return nil
end

function WheatHarvesting:HideWheatSection(sectionIndex)
	local sectionData = self.SectionData[sectionIndex]
	if not sectionData or not sectionData.section then return end

	-- Fade out the section
	local function fadeObject(obj)
		if obj:IsA("BasePart") then
			local tween = TweenService:Create(obj, 
				TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Transparency = 1}
			)
			tween:Play()
		end
	end

	-- Apply fade to section and its descendants
	fadeObject(sectionData.section)
	for _, descendant in pairs(sectionData.section:GetDescendants()) do
		fadeObject(descendant)
	end

	print("WheatHarvesting: Hid section " .. sectionIndex)
end

function WheatHarvesting:ShowWheatSection(sectionIndex)
	local sectionData = self.SectionData[sectionIndex]
	if not sectionData or not sectionData.section then return end

	-- Fade in the section
	local function showObject(obj)
		if obj:IsA("BasePart") then
			local tween = TweenService:Create(obj, 
				TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Transparency = 0}
			)
			tween:Play()
		end
	end

	-- Apply fade to section and its descendants
	showObject(sectionData.section)
	for _, descendant in pairs(sectionData.section:GetDescendants()) do
		showObject(descendant)
	end

	print("WheatHarvesting: Showed section " .. sectionIndex)
end

-- ========== RESPAWN SYSTEM ==========

function WheatHarvesting:SetupRespawnSystem()
	print("WheatHarvesting: Setting up respawn system...")

	-- Check for respawns every 30 seconds
	spawn(function()
		while true do
			wait(30)
			self:CheckRespawns()
		end
	end)

	print("WheatHarvesting: ✅ Respawn system active")
end

function WheatHarvesting:CheckRespawns()
	local currentTime = tick()
	local respawnedSections = 0

	for i, sectionData in pairs(self.SectionData) do
		if sectionData.isHarvested and currentTime >= sectionData.respawnTime then
			-- Respawn this section
			sectionData.isHarvested = false
			sectionData.harvestedTime = 0
			sectionData.respawnTime = 0

			-- Show the section again
			self:ShowWheatSection(i)

			respawnedSections = respawnedSections + 1
			print("WheatHarvesting: Respawned section " .. i)
		end
	end

	if respawnedSections > 0 then
		print("WheatHarvesting: Respawned " .. respawnedSections .. " wheat sections")

		-- Notify nearby players
		for _, player in pairs(Players:GetPlayers()) do
			if self.PlayerSessions[player.UserId] and self.PlayerSessions[player.UserId].nearWheat then
				if self.GameCore and self.GameCore.SendNotification then
					self.GameCore:SendNotification(player, "🌾 Wheat Respawned", 
						respawnedSections .. " wheat sections have regrown!", "info")
				end
			end
		end
	end
end

-- ========== PLAYER CLEANUP ==========

function WheatHarvesting:PlayerRemoving(player)
	print("WheatHarvesting: Cleaning up data for " .. player.Name)

	if self.PlayerSessions[player.UserId] then
		self.PlayerSessions[player.UserId] = nil
	end
end

-- ========== DEBUG FUNCTIONS ==========

function WheatHarvesting:DebugStatus()
	print("=== WHEAT HARVESTING DEBUG STATUS ===")
	print("Wheat field: " .. (self.WheatField and self.WheatField.Name or "❌ Not found"))
	print("Sections: " .. #self.WheatSections)
	print("Active sessions: " .. self:CountTable(self.PlayerSessions))
	print("Available wheat: " .. self:GetAvailableWheatCount())
	print("")

	print("Section status:")
	for i, sectionData in pairs(self.SectionData) do
		local status = sectionData.isHarvested and "Harvested" or "Available"
		print("  Section " .. i .. ": " .. status)
	end
	print("")

	print("Player sessions:")
	for userId, session in pairs(self.PlayerSessions) do
		local player = Players:GetPlayerByUserId(userId)
		local playerName = player and player.Name or "Unknown"
		print("  " .. playerName .. ": Near=" .. tostring(session.nearWheat) .. 
			", Harvesting=" .. tostring(session.harvesting) .. 
			", Progress=" .. session.swingProgress .. "/" .. HARVESTING_CONFIG.SWINGS_PER_WHEAT)
	end
	print("=====================================")
end

function WheatHarvesting:CountTable(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- ========== CLEANUP ==========

function WheatHarvesting:Cleanup()
	print("WheatHarvesting: Performing cleanup...")

	-- Disconnect proximity connections
	for _, connection in pairs(self.ProximityConnections) do
		if connection then
			connection:Disconnect()
		end
	end

	-- Clear all data
	self.PlayerSessions = {}
	self.ProximityConnections = {}
	self.SectionData = {}

	print("WheatHarvesting: Cleanup complete")
end

-- Setup player cleanup
Players.PlayerRemoving:Connect(function(player)
	WheatHarvesting:PlayerRemoving(player)
end)

-- Global reference
_G.WheatHarvesting = WheatHarvesting

return WheatHarvesting