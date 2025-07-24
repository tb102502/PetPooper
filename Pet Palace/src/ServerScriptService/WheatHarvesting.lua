local WheatHarvesting = {}
-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
-- Configuration - UPDATED for chunk system
local HARVESTING_CONFIG = {
	CHUNKS_PER_SECTION = 10, -- Number of wheat chunks per section
	PROXIMITY_DISTANCE = 15,
	HARVESTING_COOLDOWN = 0.5,
	RESPAWN_TIME = 300, -- 5 minutes
	MAX_HARVEST_DISTANCE = 12, -- Increased for larger chunks
	WHEAT_PER_CHUNK = 5 -- Amount of wheat harvested per chunk
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
	print("WheatHarvesting: Initializing CHUNK-BASED wheat harvesting system...")
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

	print("WheatHarvesting: ✅ CHUNK-BASED wheat harvesting system initialized")
	print("  Wheat field sections: " .. #self.WheatSections)

	return true
end
-- ========== WHEAT FIELD SETUP (UPDATED) ==========
function WheatHarvesting:SetupWheatField()
	print("WheatHarvesting: Setting up CHUNK-BASED wheat field structure...")
	-- Find the WheatField model
	self.WheatField = workspace:FindFirstChild("WheatField")
	if not self.WheatField then
		error("WheatHarvesting: WheatField model not found in workspace!")
	end

	-- Find wheat sections - UPDATED for 2 sections
	self.WheatSections = {}

	-- Look for Section1, Section2 (reduced from 6 to 2)
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
-- ========== SECTION DATA INITIALIZATION (UPDATED) ==========
function WheatHarvesting:InitializeSectionData()
	print("WheatHarvesting: Initializing CHUNK-BASED section data...")
	for i, sectionInfo in ipairs(self.WheatSections) do
		-- Find wheat chunks in the GrainCluster
		local wheatChunks = {}

		-- Look for any Models or Parts that represent wheat chunks
		for _, child in pairs(sectionInfo.grainCluster:GetChildren()) do
			if (child:IsA("Model") or child:IsA("BasePart")) and 
				(child.Name:find("Chunk") or child.Name:find("Part") or child.Name:find("Wheat")) then
				table.insert(wheatChunks, child)
			end
		end

		-- If no specific chunks found, use all Models and Parts
		if #wheatChunks == 0 then
			for _, child in pairs(sectionInfo.grainCluster:GetChildren()) do
				if child:IsA("Model") or child:IsA("BasePart") then
					table.insert(wheatChunks, child)
				end
			end
		end

		self.SectionData[i] = {
			section = sectionInfo.section,
			grainCluster = sectionInfo.grainCluster,
			wheatChunks = wheatChunks,
			availableChunks = #wheatChunks,
			totalChunks = #wheatChunks,
			respawnTime = 0,
			sectionNumber = sectionInfo.sectionNumber
		}

		print("WheatHarvesting: Section " .. i .. " has " .. #wheatChunks .. " wheat chunks")
	end

	print("WheatHarvesting: ✅ CHUNK-BASED section data initialized")
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
		message = "Click to swing your scythe and harvest wheat chunks!"
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
-- ========== SCYTHE SWING HANDLING (UPDATED FOR CHUNKS) ==========
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

	-- Find closest chunk to harvest
	local harvestedChunk = self:HarvestClosestChunk(player)

	if harvestedChunk then
		-- Give wheat to player - UPDATED amount per chunk
		if self.GameCore and self.GameCore.AddItemToInventory then
			local wheatAmount = HARVESTING_CONFIG.WHEAT_PER_CHUNK
			local success = self.GameCore:AddItemToInventory(player, "farming", "wheat", wheatAmount)

			if success then
				if self.GameCore.SendNotification then
					self.GameCore:SendNotification(player, "🌾 Wheat Harvested", 
						"Harvested " .. wheatAmount .. " wheat from chunk!", "success")
				end

				-- Update player stats
				local playerData = self.GameCore:GetPlayerData(player)
				if playerData then
					playerData.stats = playerData.stats or {}
					playerData.stats.wheatHarvested = (playerData.stats.wheatHarvested or 0) + wheatAmount
					playerData.stats.wheatChunksHarvested = (playerData.stats.wheatChunksHarvested or 0) + 1
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
			self.GameCore:SendNotification(player, "No Wheat Nearby", "Move closer to wheat chunks to harvest them!", "warning")
		end
	end
end
-- ========== CHUNK HARVESTING (NEW) ==========
function WheatHarvesting:HarvestClosestChunk(player)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return nil
	end
	local playerPos = character.HumanoidRootPart.Position
	local closestChunk = nil
	local closestDistance = HARVESTING_CONFIG.MAX_HARVEST_DISTANCE
	local closestSectionIndex = nil

	-- Find closest harvestable chunk
	for sectionIndex, sectionData in pairs(self.SectionData) do
		if sectionData.availableChunks > 0 then
			for i, wheatChunk in pairs(sectionData.wheatChunks) do
				if wheatChunk and wheatChunk.Parent then -- Check if chunk still exists
					-- Get chunk position
					local chunkPos
					if wheatChunk:IsA("Model") then
						chunkPos = wheatChunk:GetModelCFrame().Position
					else
						chunkPos = wheatChunk.Position
					end

					local distance = (chunkPos - playerPos).Magnitude
					if distance < closestDistance then
						closestChunk = wheatChunk
						closestDistance = distance
						closestSectionIndex = sectionIndex
					end
				end
			end
		end
	end

	-- Harvest the closest chunk
	if closestChunk and closestSectionIndex then
		self:RemoveChunk(closestSectionIndex, closestChunk)
		return closestChunk
	end

	return nil
end
function WheatHarvesting:RemoveChunk(sectionIndex, wheatChunk)
	local sectionData = self.SectionData[sectionIndex]
	if not sectionData then return end
	-- Create harvest effect at chunk position
	local chunkPos
	if wheatChunk:IsA("Model") then
		chunkPos = wheatChunk:GetModelCFrame().Position
	else
		chunkPos = wheatChunk.Position
	end

	self:CreateChunkHarvestEffect(chunkPos)

	-- Remove the wheat chunk
	wheatChunk:Destroy()

	-- Update section data
	for i, chunk in pairs(sectionData.wheatChunks) do
		if chunk == wheatChunk then
			table.remove(sectionData.wheatChunks, i)
			break
		end
	end

	sectionData.availableChunks = sectionData.availableChunks - 1

	-- If section is empty, set respawn timer
	if sectionData.availableChunks <= 0 then
		sectionData.respawnTime = tick() + HARVESTING_CONFIG.RESPAWN_TIME
		print("WheatHarvesting: Section " .. sectionIndex .. " is empty, will respawn in " .. HARVESTING_CONFIG.RESPAWN_TIME .. " seconds")
	end
end
function WheatHarvesting:CreateChunkHarvestEffect(position)
	-- Create enhanced effects for chunk harvesting
	for i = 1, 8 do -- More particles for bigger chunks
		local particle = Instance.new("Part")
		particle.Name = "WheatChunkParticle"
		particle.Size = Vector3.new(0.2, 0.2, 0.2) -- Slightly bigger particles
		particle.Material = Enum.Material.Neon
		particle.BrickColor = BrickColor.new("Bright yellow")
		particle.Anchored = false
		particle.CanCollide = false
		particle.Position = position + Vector3.new(
			math.random(-2, 2),
			math.random(0, 3),
			math.random(-2, 2)
		)
		particle.Parent = workspace
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
		bodyVelocity.Velocity = Vector3.new(
			math.random(-8, 8),
			math.random(8, 20),
			math.random(-8, 8)
		)
		bodyVelocity.Parent = particle

		game:GetService("Debris"):AddItem(particle, 3)
	end

	-- Create larger explosion effect for chunks
	local chunkEffect = Instance.new("Part")
	chunkEffect.Name = "ChunkHarvestEffect"
	chunkEffect.Size = Vector3.new(3, 3, 3)
	chunkEffect.Material = Enum.Material.Neon
	chunkEffect.BrickColor = BrickColor.new("Bright yellow")
	chunkEffect.Anchored = true
	chunkEffect.CanCollide = false
	chunkEffect.Transparency = 0.5
	chunkEffect.Shape = Enum.PartType.Ball
	chunkEffect.Position = position
	chunkEffect.Parent = workspace

	local effectTween = TweenService:Create(chunkEffect,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Transparency = 1,
			Size = Vector3.new(6, 6, 6)
		}
	)
	effectTween:Play()

	effectTween.Completed:Connect(function()
		chunkEffect:Destroy()
	end)
end
-- ========== UTILITY FUNCTIONS (UPDATED) ==========
function WheatHarvesting:PlayerHasScythe(player)
	return player.Backpack:FindFirstChild("Scythe") or
		(player.Character and player.Character:FindFirstChild("Scythe"))
end
function WheatHarvesting:GetAvailableWheatCount()
	local count = 0
	for _, sectionData in pairs(self.SectionData) do
		-- Count chunks multiplied by wheat per chunk
		count = count + (sectionData.availableChunks * HARVESTING_CONFIG.WHEAT_PER_CHUNK)
	end
	return count
end
function WheatHarvesting:GetAvailableChunkCount()
	local count = 0
	for _, sectionData in pairs(self.SectionData) do
		count = count + sectionData.availableChunks
	end
	return count
end
-- ========== RESPAWN SYSTEM (UPDATED) ==========
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
		if sectionData.availableChunks <= 0 and currentTime >= sectionData.respawnTime and sectionData.respawnTime > 0 then
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
	-- Clear old chunks array
	sectionData.wheatChunks = {}

	-- Find all chunks in the grain cluster and restore them
	for _, child in pairs(sectionData.grainCluster:GetChildren()) do
		if (child:IsA("Model") or child:IsA("BasePart")) and 
			(child.Name:find("Chunk") or child.Name:find("Part") or child.Name:find("Wheat")) then

			-- Make sure it's visible and collidable
			if child:IsA("BasePart") then
				child.Transparency = 0
				child.CanCollide = true
			elseif child:IsA("Model") then
				-- Restore all parts in the model
				for _, part in pairs(child:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = 0
						part.CanCollide = true
					end
				end
			end

			table.insert(sectionData.wheatChunks, child)
		end
	end

	-- Reset section data
	sectionData.availableChunks = #sectionData.wheatChunks
	sectionData.respawnTime = 0

	print("WheatHarvesting: Respawned section " .. sectionIndex .. " with " .. sectionData.availableChunks .. " chunks")
end
-- ========== DEBUG FUNCTIONS (UPDATED) ==========
function WheatHarvesting:DebugStatus()
	print("=== CHUNK-BASED WHEAT HARVESTING DEBUG STATUS ===")
	print("Wheat field: " .. (self.WheatField and self.WheatField.Name or "❌ Not found"))
	print("Sections: " .. #self.WheatSections .. " (reduced to 2)")
	print("Active sessions: " .. self:CountTable(self.PlayerSessions))
	print("Available wheat: " .. self:GetAvailableWheatCount())
	print("Available chunks: " .. self:GetAvailableChunkCount())
	print("")
	print("Section status:")
	for i, sectionData in pairs(self.SectionData) do
		print("  Section " .. i .. ": " .. sectionData.availableChunks .. "/" .. sectionData.totalChunks .. " chunks")
		print("    Wheat value: " .. (sectionData.availableChunks * HARVESTING_CONFIG.WHEAT_PER_CHUNK) .. " wheat")
	end

	print("")
	print("CHUNK-BASED CONFIG:")
	print("  Wheat per chunk: " .. HARVESTING_CONFIG.WHEAT_PER_CHUNK)
	print("  Max harvest distance: " .. HARVESTING_CONFIG.MAX_HARVEST_DISTANCE)
	print("  Respawn time: " .. HARVESTING_CONFIG.RESPAWN_TIME .. " seconds")
	print("==================================================")
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