--[[
    WheatHarvesting.lua - Fixed Wheat Harvesting System
    Place in: ServerScriptService/WheatHarvesting.lua
    
    FIXES:
    ✅ Corrected wheat field structure detection
    ✅ Individual grain (Part) removal system
    ✅ Proximity-based grain selection
    ✅ Proper integration with existing systems
]]

local WheatHarvesting = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Configuration
local HARVESTING_CONFIG = {
	PARTS_PER_SECTION = 6, -- Number of individual grain Parts per GrainCluster
	PROXIMITY_DISTANCE = 15,
	HARVESTING_COOLDOWN = 0.5,
	RESPAWN_TIME = 300, -- 5 minutes
	MAX_HARVEST_DISTANCE = 8 -- Maximum distance to harvest a grain
}

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
	print("WheatHarvesting: Initializing FIXED wheat harvesting system...")

	self.GameCore = gameCore

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

	print("WheatHarvesting: ✅ FIXED wheat harvesting system initialized")
	print("  Wheat field sections: " .. #self.WheatSections)

	return true
end

-- ========== WHEAT FIELD SETUP (FIXED) ==========

function WheatHarvesting:SetupWheatField()
	print("WheatHarvesting: Setting up FIXED wheat field structure...")

	-- Find the WheatField model
	self.WheatField = workspace:FindFirstChild("WheatField")
	if not self.WheatField then
		error("WheatHarvesting: WheatField model not found in workspace!")
	end

	-- Find wheat sections with correct structure
	self.WheatSections = {}

	-- Look for Section1, Section2, etc.
	for i = 1, 2 do
		local section = self.WheatField:FindFirstChild("Section" .. i)
		if section then
			-- Look for GrainCluster within the section
			local grainCluster = section:FindFirstChild("GrainCluster" .. i)
			if grainCluster then
				table.insert(self.WheatSections, {
					section = section,
					grainCluster = grainCluster,
					sectionNumber = i
				})
				print("WheatHarvesting: Found Section" .. i .. " with GrainCluster" .. i)
			else
				warn("WheatHarvesting: GrainCluster" .. i .. " not found in Section" .. i)
			end
		else
			warn("WheatHarvesting: Section" .. i .. " not found")
		end
	end

	if #self.WheatSections == 0 then
		error("WheatHarvesting: No valid wheat sections found!")
	end

	print("WheatHarvesting: Found " .. #self.WheatSections .. " valid wheat sections")
end

-- ========== SECTION DATA INITIALIZATION (FIXED) ==========

function WheatHarvesting:InitializeSectionData()
	print("WheatHarvesting: Initializing FIXED section data...")

	for i, sectionInfo in ipairs(self.WheatSections) do
		-- Count actual Parts in the GrainCluster
		local grainParts = {}
		for _, child in pairs(sectionInfo.grainCluster:GetChildren()) do
			if child:IsA("Model") and child.Name == "Part" then
				table.insert(grainParts, child)
			end
		end

		self.SectionData[i] = {
			section = sectionInfo.section,
			grainCluster = sectionInfo.grainCluster,
			grainParts = grainParts,
			availableGrains = #grainParts,
			totalGrains = #grainParts,
			respawnTime = 0,
			sectionNumber = sectionInfo.sectionNumber
		}

		print("WheatHarvesting: Section " .. i .. " has " .. #grainParts .. " grain parts")
	end

	print("WheatHarvesting: ✅ FIXED section data initialized")
end

-- ========== REMOTE EVENTS SETUP ==========

function WheatHarvesting:SetupRemoteEvents()
	print("WheatHarvesting: Setting up remote events...")

	local remotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not remotes then
		error("WheatHarvesting: GameRemotes folder not found!")
	end

	local requiredEvents = {
		"ShowWheatPrompt", "HideWheatPrompt", 
		"StartWheatHarvesting", "StopWheatHarvesting",
		"SwingScythe", "WheatHarvestUpdate"
	}

	for _, eventName in ipairs(requiredEvents) do
		local event = remotes:FindFirstChild(eventName)
		if not event then
			event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = remotes
		end
		self.RemoteEvents[eventName] = event
	end

	self:ConnectEventHandlers()
end

function WheatHarvesting:ConnectEventHandlers()
	self.RemoteEvents.StartWheatHarvesting.OnServerEvent:Connect(function(player)
		self:StartHarvestingSession(player)
	end)

	self.RemoteEvents.StopWheatHarvesting.OnServerEvent:Connect(function(player)
		self:StopHarvestingSession(player)
	end)

	self.RemoteEvents.SwingScythe.OnServerEvent:Connect(function(player)
		self:HandleScytheSwing(player)
	end)
end

-- ========== PROXIMITY DETECTION ==========

function WheatHarvesting:SetupProximityDetection()
	local connection = RunService.Heartbeat:Connect(function()
		self:CheckPlayerProximity()
	end)

	table.insert(self.ProximityConnections, connection)
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

	if not self.PlayerSessions[player.UserId] then
		self.PlayerSessions[player.UserId] = {
			nearWheat = false,
			harvesting = false,
			lastSwingTime = 0
		}
	end

	self.PlayerSessions[player.UserId].nearWheat = true

	local hasScythe = self:PlayerHasScythe(player)
	local availableWheat = self:GetAvailableWheatCount()

	self.RemoteEvents.ShowWheatPrompt:FireClient(player, hasScythe, availableWheat)
end

function WheatHarvesting:PlayerLeftWheatProximity(player)
	if self.PlayerSessions[player.UserId] then
		self.PlayerSessions[player.UserId].nearWheat = false

		if self.PlayerSessions[player.UserId].harvesting then
			self:StopHarvestingSession(player)
		end
	end

	self.RemoteEvents.HideWheatPrompt:FireClient(player)
end

-- ========== HARVESTING SESSION MANAGEMENT ==========

function WheatHarvesting:StartHarvestingSession(player)
	print("WheatHarvesting: Starting harvesting session for " .. player.Name)

	if not self.PlayerSessions[player.UserId] or not self.PlayerSessions[player.UserId].nearWheat then
		return
	end

	if not self:PlayerHasScythe(player) then
		if self.GameCore and self.GameCore.SendNotification then
			self.GameCore:SendNotification(player, "No Scythe", "You need a scythe to harvest wheat!", "warning")
		end
		return
	end

	local availableWheat = self:GetAvailableWheatCount()
	if availableWheat <= 0 then
		if self.GameCore and self.GameCore.SendNotification then
			self.GameCore:SendNotification(player, "No Wheat", "All wheat has been harvested! Wait for respawn.", "info")
		end
		return
	end

	local session = self.PlayerSessions[player.UserId]
	session.harvesting = true
	session.lastSwingTime = tick()

	self.RemoteEvents.WheatHarvestUpdate:FireClient(player, {
		harvesting = true,
		availableWheat = availableWheat,
		message = "Click to swing your scythe and harvest wheat!"
	})
end

function WheatHarvesting:StopHarvestingSession(player)
	if self.PlayerSessions[player.UserId] then
		self.PlayerSessions[player.UserId].harvesting = false

		self.RemoteEvents.WheatHarvestUpdate:FireClient(player, {
			harvesting = false,
			availableWheat = self:GetAvailableWheatCount()
		})
	end
end

-- ========== SCYTHE SWING HANDLING (FIXED) ==========

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

	if not self:PlayerHasScythe(player) then
		self:StopHarvestingSession(player)
		return
	end

	-- Find closest grain to harvest
	local harvestedGrain = self:HarvestClosestGrain(player)

	if harvestedGrain then
		-- Give wheat to player
		if self.GameCore and self.GameCore.AddItemToInventory then
			local success = self.GameCore:AddItemToInventory(player, "farming", "wheat", 1)

			if success then
				if self.GameCore.SendNotification then
					self.GameCore:SendNotification(player, "🌾 Wheat Harvested", 
						"Harvested 1 wheat grain!", "success")
				end

				-- Update player stats
				local playerData = self.GameCore:GetPlayerData(player)
				if playerData then
					playerData.stats = playerData.stats or {}
					playerData.stats.wheatHarvested = (playerData.stats.wheatHarvested or 0) + 1
					self.GameCore:UpdatePlayerData(player, playerData)
				end
			end
		end

		-- Check if all wheat is harvested
		local remainingWheat = self:GetAvailableWheatCount()
		if remainingWheat <= 0 then
			self:StopHarvestingSession(player)
			if self.GameCore and self.GameCore.SendNotification then
				self.GameCore:SendNotification(player, "🌾 Field Cleared", "All wheat harvested! Great work!", "success")
			end
		else
			-- Update client
			self.RemoteEvents.WheatHarvestUpdate:FireClient(player, {
				harvesting = true,
				availableWheat = remainingWheat,
				message = "Keep harvesting! " .. remainingWheat .. " wheat remaining."
			})
		end
	else
		-- No wheat found nearby
		if self.GameCore and self.GameCore.SendNotification then
			self.GameCore:SendNotification(player, "No Wheat Nearby", "Move closer to wheat grains to harvest them!", "warning")
		end
	end
end

-- ========== GRAIN HARVESTING (NEW) ==========

function WheatHarvesting:HarvestClosestGrain(player)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return nil
	end

	local playerPos = character.HumanoidRootPart.Position
	local closestGrain = nil
	local closestDistance = HARVESTING_CONFIG.MAX_HARVEST_DISTANCE
	local closestSectionIndex = nil

	-- Find closest harvestable grain
	for sectionIndex, sectionData in pairs(self.SectionData) do
		if sectionData.availableGrains > 0 then
			for i, grainPart in pairs(sectionData.grainParts) do
				if grainPart and grainPart.Parent then -- Check if grain still exists
					local distance = (grainPart.Position - playerPos).Magnitude
					if distance < closestDistance then
						closestGrain = grainPart
						closestDistance = distance
						closestSectionIndex = sectionIndex
					end
				end
			end
		end
	end

	-- Harvest the closest grain
	if closestGrain and closestSectionIndex then
		self:RemoveGrain(closestSectionIndex, closestGrain)
		return closestGrain
	end

	return nil
end

function WheatHarvesting:RemoveGrain(sectionIndex, grainPart)
	local sectionData = self.SectionData[sectionIndex]
	if not sectionData then return end

	-- Create harvest effect
	self:CreateHarvestEffect(grainPart.Position)

	-- Remove the grain part
	grainPart:Destroy()

	-- Update section data
	for i, part in pairs(sectionData.grainParts) do
		if part == grainPart then
			table.remove(sectionData.grainParts, i)
			break
		end
	end

	sectionData.availableGrains = sectionData.availableGrains - 1

	-- If section is empty, set respawn timer
	if sectionData.availableGrains <= 0 then
		sectionData.respawnTime = tick() + HARVESTING_CONFIG.RESPAWN_TIME
		print("WheatHarvesting: Section " .. sectionIndex .. " is empty, will respawn in " .. HARVESTING_CONFIG.RESPAWN_TIME .. " seconds")
	end
end

function WheatHarvesting:CreateHarvestEffect(position)
	-- Create wheat particles
	for i = 1, 3 do
		local particle = Instance.new("Part")
		particle.Name = "WheatParticle"
		particle.Size = Vector3.new(0.1, 0.1, 0.1)
		particle.Material = Enum.Material.Neon
		particle.BrickColor = BrickColor.new("Bright yellow")
		particle.Anchored = false
		particle.CanCollide = false
		particle.Position = position + Vector3.new(
			math.random(-1, 1),
			math.random(0, 2),
			math.random(-1, 1)
		)
		particle.Parent = workspace

		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
		bodyVelocity.Velocity = Vector3.new(
			math.random(-5, 5),
			math.random(5, 15),
			math.random(-5, 5)
		)
		bodyVelocity.Parent = particle

		game:GetService("Debris"):AddItem(particle, 2)
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
		count = count + sectionData.availableGrains
	end
	return count
end

-- ========== RESPAWN SYSTEM ==========

function WheatHarvesting:SetupRespawnSystem()
	spawn(function()
		while true do
			wait(30)
			self:CheckRespawns()
		end
	end)
end

function WheatHarvesting:CheckRespawns()
	local currentTime = tick()
	local respawnedSections = 0

	for sectionIndex, sectionData in pairs(self.SectionData) do
		if sectionData.availableGrains <= 0 and currentTime >= sectionData.respawnTime and sectionData.respawnTime > 0 then
			self:RespawnSection(sectionIndex)
			respawnedSections = respawnedSections + 1
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

function WheatHarvesting:RespawnSection(sectionIndex)
	local sectionData = self.SectionData[sectionIndex]
	if not sectionData then return end

	-- Clear old grain parts array
	sectionData.grainParts = {}

	-- Find all Parts in the grain cluster and restore them
	for _, child in pairs(sectionData.grainCluster:GetChildren()) do
		if child:IsA("BasePart") and child.Name == "Part" then
			child.Transparency = 0
			child.CanCollide = true
			table.insert(sectionData.grainParts, child)
		end
	end

	-- Reset section data
	sectionData.availableGrains = #sectionData.grainParts
	sectionData.respawnTime = 0

	print("WheatHarvesting: Respawned section " .. sectionIndex .. " with " .. sectionData.availableGrains .. " grains")
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
		print("  Section " .. i .. ": " .. sectionData.availableGrains .. "/" .. sectionData.totalGrains .. " grains")
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
	for _, connection in pairs(self.ProximityConnections) do
		if connection then
			connection:Disconnect()
		end
	end

	self.PlayerSessions = {}
	self.ProximityConnections = {}
end

Players.PlayerRemoving:Connect(function(player)
	if WheatHarvesting.PlayerSessions[player.UserId] then
		WheatHarvesting.PlayerSessions[player.UserId] = nil
	end
end)

_G.WheatHarvesting = WheatHarvesting

return WheatHarvesting