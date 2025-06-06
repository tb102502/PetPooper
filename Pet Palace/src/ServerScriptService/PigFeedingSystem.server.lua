--[[
    Fixed Pig Proximity System with Debug
    Replace your PigFeedingSystem.lua with this version
    
    FIXES:
    - Fixed admin command parsing (chat commands not console commands)
    - Added extensive debug logging
    - Fixed click part positioning and size
    - Better proximity detection
]]

local function WaitForGameCore(scriptName, maxWaitTime)
	maxWaitTime = maxWaitTime or 15
	local startTime = tick()

	print(scriptName .. ": Waiting for GameCore...")

	while not _G.GameCore and (tick() - startTime) < maxWaitTime do
		wait(0.5)
	end

	if not _G.GameCore then
		error(scriptName .. ": GameCore not found after " .. maxWaitTime .. " seconds!")
	end

	print(scriptName .. ": GameCore found successfully!")
	return _G.GameCore
end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for GameCore
local GameCore = WaitForGameCore("PigFeedingSystem")

print("=== FIXED PIG PROXIMITY FEEDING SYSTEM STARTING ===")

local PigFeedingSystem = {}

-- Find pig model in workspace
local pigModel = workspace:FindFirstChild("Pig")
if not pigModel then
	error("PigFeedingSystem: Pig model not found in workspace! Make sure there's a model named 'Pig' in workspace.")
end

print("PigFeedingSystem: Found pig model at:", pigModel:GetFullName())

-- Debug: List all parts in pig model
print("PigFeedingSystem: Pig model parts:")
for _, part in pairs(pigModel:GetChildren()) do
	if part:IsA("BasePart") then
		print("  - " .. part.Name .. " (" .. part.ClassName .. ")")
	end
end

-- System state with debounce
PigFeedingSystem.playersNearPig = {}
PigFeedingSystem.playerDebounce = {} -- Prevent spam notifications
PigFeedingSystem.proximityConnections = {}
PigFeedingSystem.pigClickPart = nil
PigFeedingSystem.proximityLoop = nil

-- Debounce settings
local NOTIFICATION_DEBOUNCE = 3 -- 3 seconds between notifications per player

-- Check if player is in debounce period
local function IsPlayerInDebounce(player)
	local userId = player.UserId
	local currentTime = tick()
	local lastTime = PigFeedingSystem.playerDebounce[userId] or 0
	return (currentTime - lastTime) < NOTIFICATION_DEBOUNCE
end

-- Set player debounce
local function SetPlayerDebounce(player)
	PigFeedingSystem.playerDebounce[player.UserId] = tick()
	print("PigFeedingSystem: Set debounce for " .. player.Name)
end

-- Create pig sounds
local function CreatePigSounds()
	-- Create oink sound
	local oinkSound = Instance.new("Sound")
	oinkSound.Name = "OinkSound"
	oinkSound.SoundId = "rbxasset://sounds/electronicpingshort.wav" -- Placeholder - replace with actual oink sound
	oinkSound.Volume = 0.8
	--oinkSound.Pitch = 1.2 -- Higher pitch for pig sound
	oinkSound.Parent = pigModel

	print("PigFeedingSystem: Created oink sound in", pigModel.Name)
	return oinkSound
end

-- Create remote events for pig feeding UI
local function SetupRemoteEvents()
	local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "GameRemotes"
		remoteFolder.Parent = ReplicatedStorage
		print("PigFeedingSystem: Created GameRemotes folder")
	end

	-- Create ShowPigFeedingUI event if it doesn't exist
	local showPigUIEvent = remoteFolder:FindFirstChild("ShowPigFeedingUI")
	if not showPigUIEvent then
		showPigUIEvent = Instance.new("RemoteEvent")
		showPigUIEvent.Name = "ShowPigFeedingUI"
		showPigUIEvent.Parent = remoteFolder
		print("PigFeedingSystem: Created ShowPigFeedingUI RemoteEvent")
	end

	-- Create HidePigFeedingUI event if it doesn't exist
	local hidePigUIEvent = remoteFolder:FindFirstChild("HidePigFeedingUI")
	if not hidePigUIEvent then
		hidePigUIEvent = Instance.new("RemoteEvent")
		hidePigUIEvent.Name = "HidePigFeedingUI"
		hidePigUIEvent.Parent = remoteFolder
		print("PigFeedingSystem: Created HidePigFeedingUI RemoteEvent")
	end

	-- Ensure FeedPig event exists
	local feedPigEvent = remoteFolder:FindFirstChild("FeedPig")
	if not feedPigEvent then
		feedPigEvent = Instance.new("RemoteEvent")
		feedPigEvent.Name = "FeedPig"
		feedPigEvent.Parent = remoteFolder
		print("PigFeedingSystem: Created FeedPig RemoteEvent")
	end

	print("PigFeedingSystem: All remote events verified/created")
	return showPigUIEvent, hidePigUIEvent, feedPigEvent
end

-- Initialize the pig feeding system
function PigFeedingSystem:Initialize()
	print("PigFeedingSystem: Initializing fixed pig proximity feeding system...")

	-- Setup sounds
	self.oinkSound = CreatePigSounds()

	-- Setup remote events
	self.showPigUIEvent, self.hidePigUIEvent, self.feedPigEvent = SetupRemoteEvents()

	-- Setup the visual indicator above the pig
	self:SetupPigIndicator()

	-- Create invisible click part for better interaction
	self:CreatePigClickPart()

	-- Start proximity detection
	self:StartProximityDetection()

	-- Setup feeding event handler
	self:SetupFeedingEventHandler()

	print("PigFeedingSystem: Fixed pig proximity feeding system fully initialized!")
end

-- Setup pig indicator with Billboard GUI
function PigFeedingSystem:SetupPigIndicator()
	-- Remove any existing indicator
	local existingIndicator = pigModel:FindFirstChild("PigIndicator")
	if existingIndicator then
		existingIndicator:Destroy()
	end

	-- Create the indicator above the pig
	local indicator = Instance.new("Part")
	indicator.Name = "PigIndicator"
	indicator.Size = Vector3.new(6, 0.5, 6)
	indicator.Shape = Enum.PartType.Cylinder
	indicator.Material = Enum.Material.Neon
	indicator.Color = Color3.fromRGB(255, 182, 193) -- Pink for pig
	indicator.CanCollide = false
	indicator.Anchored = true
	indicator.Transparency = 0.3

	-- Position above pig's head
	local pigHead = pigModel:FindFirstChild("Head") or pigModel:FindFirstChild("HumanoidRootPart")
	if pigHead then
		indicator.CFrame = pigHead.CFrame + Vector3.new(0, 8, 0)
		indicator.Orientation = Vector3.new(0, 0, 90) -- Rotate cylinder to be horizontal
		print("PigFeedingSystem: Positioned indicator above", pigHead.Name)
	else
		warn("PigFeedingSystem: Could not find pig head for indicator positioning")
		indicator.CFrame = CFrame.new(0, 8, 0) -- Default position
	end

	indicator.Parent = pigModel

	-- Add Billboard GUI
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(0, 180, 0, 70)
	billboardGui.StudsOffset = Vector3.new(0, 4, 0)
	billboardGui.Parent = indicator

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "🐷 WALK CLOSER TO FEED"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Parent = billboardGui

	-- Add pulsing effect
	spawn(function()
		while indicator and indicator.Parent do
			local time = tick()
			local pulse = math.sin(time * 1.5) * 0.2 + 1
			indicator.Size = Vector3.new(6 * pulse, 0.5, 6 * pulse)
			wait(0.1)
		end
	end)

	-- Store references
	self.pigIndicator = indicator
	self.pigLabel = label

	print("PigFeedingSystem: Pig indicator with Billboard GUI created")
end

-- Create invisible click part for better pig interaction
function PigFeedingSystem:CreatePigClickPart()
	-- Remove any existing click part
	local existingClickPart = pigModel:FindFirstChild("PigClickArea")
	if existingClickPart then
		existingClickPart:Destroy()
	end

	-- Create invisible clickable area around the pig
	local clickPart = Instance.new("Part")
	clickPart.Name = "PigClickArea"
	clickPart.Size = Vector3.new(10, 10, 10) -- Large clickable area
	clickPart.Transparency = 1 -- Invisible
	clickPart.CanCollide = false
	clickPart.Anchored = true

	-- Position at pig's center
	local pigRoot = pigModel:FindFirstChild("HumanoidRootPart") or pigModel:FindFirstChild("Torso") or pigModel:FindFirstChild("Head")
	if pigRoot then
		clickPart.CFrame = pigRoot.CFrame
		print("PigFeedingSystem: Positioned click area at", pigRoot.Name, "position:", pigRoot.Position)
	else
		warn("PigFeedingSystem: Could not find pig root part for click area")
		clickPart.CFrame = CFrame.new(0, 5, 0)
	end

	clickPart.Parent = pigModel

	-- Add ClickDetector for direct clicking
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 25
	clickDetector.Parent = clickPart

	print("PigFeedingSystem: Created ClickDetector with max distance", clickDetector.MaxActivationDistance)

	-- Handle clicks with detailed logging
	clickDetector.MouseClick:Connect(function(player)
		print("PigFeedingSystem: ========== CLICK DETECTED ==========")
		print("PigFeedingSystem: Player:", player.Name, "clicked pig area")
		print("PigFeedingSystem: Click part position:", clickPart.Position)
		print("PigFeedingSystem: Player position:", player.Character and player.Character.HumanoidRootPart and player.Character.HumanoidRootPart.Position or "Unknown")

		-- Force show pig UI when clicked
		if self.showPigUIEvent then
			print("PigFeedingSystem: Firing ShowPigFeedingUI to", player.Name)
			self.showPigUIEvent:FireClient(player)
		else
			print("PigFeedingSystem: ERROR - showPigUIEvent not available!")
		end

		-- Send notification
		if not IsPlayerInDebounce(player) then
			if GameCore and GameCore.SendNotification then
				GameCore:SendNotification(player, "🐷 Pig Feeding", 
					"Pig feeding interface opened! Feed it crops to help it grow!", "success")
			end
			SetPlayerDebounce(player)
		end

		print("PigFeedingSystem: ========== CLICK COMPLETE ==========")
	end)

	-- Add hover feedback
	clickDetector.MouseHoverEnter:Connect(function(player)
		print("PigFeedingSystem: Player", player.Name, "hovering over pig area")
		if self.pigLabel then
			self.pigLabel.Text = "🐷 CLICK TO FEED!"
			self.pigLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
		end
	end)

	clickDetector.MouseHoverLeave:Connect(function(player)
		print("PigFeedingSystem: Player", player.Name, "stopped hovering over pig area")
		self:UpdatePigIndicator()
	end)

	self.pigClickPart = clickPart
	self.pigClickDetector = clickDetector

	print("PigFeedingSystem: Created invisible pig click area at position:", clickPart.Position)
end

-- Start proximity detection loop
function PigFeedingSystem:StartProximityDetection()
	-- Stop existing loop if running
	if self.proximityLoop then
		self.proximityLoop = false
		wait(1) -- Wait for old loop to stop
	end

	self.proximityLoop = true

	spawn(function()
		print("PigFeedingSystem: Starting proximity detection loop")

		while self.proximityLoop and pigModel and pigModel.Parent do
			local pigPosition = pigModel:FindFirstChild("HumanoidRootPart") or pigModel:FindFirstChild("Torso") or pigModel:FindFirstChild("Head")
			if pigPosition then
				pigPosition = pigPosition.Position

				-- Check each player's distance to pig
				for _, player in pairs(Players:GetPlayers()) do
					if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
						local playerPosition = player.Character.HumanoidRootPart.Position
						local distance = (playerPosition - pigPosition).Magnitude

						local isNearPig = distance <= 15 -- 15 stud proximity range
						local wasNearPig = self.playersNearPig[player.UserId] or false

						-- Debug logging for proximity changes
						if isNearPig ~= wasNearPig then
							print("PigFeedingSystem: Player", player.Name, "proximity changed:", 
								wasNearPig and "FAR" or "NEAR", "->", isNearPig and "NEAR" or "FAR", 
								"(distance:", math.floor(distance), "studs)")
						end

						-- Player entered pig area
						if isNearPig and not wasNearPig then
							self:OnPlayerEnterPigArea(player, distance)

							-- Player left pig area
						elseif not isNearPig and wasNearPig then
							self:OnPlayerLeavePigArea(player)
						end

						-- Update proximity status
						self.playersNearPig[player.UserId] = isNearPig
					end
				end

				-- Update indicator based on nearby players
				self:UpdatePigIndicator()
			else
				warn("PigFeedingSystem: Could not find pig position for proximity detection")
			end

			wait(0.5) -- Check twice per second
		end

		print("PigFeedingSystem: Proximity detection loop ended")
	end)
end

-- Handle player entering pig area
function PigFeedingSystem:OnPlayerEnterPigArea(player, distance)
	print("PigFeedingSystem: ========== PLAYER ENTERED PIG AREA ==========")
	print("PigFeedingSystem: Player:", player.Name)
	print("PigFeedingSystem: Distance:", math.floor(distance), "studs")

	-- Show pig feeding UI to the player
	if self.showPigUIEvent then
		print("PigFeedingSystem: Firing ShowPigFeedingUI to", player.Name)
		self.showPigUIEvent:FireClient(player)
	else
		print("PigFeedingSystem: ERROR - showPigUIEvent not available!")
	end

	-- Send notification (with debounce)
	if not IsPlayerInDebounce(player) then
		if GameCore and GameCore.SendNotification then
			local message = "You're near the pig! Feeding interface is now open."
			if distance <= 8 then
				message = "Perfect distance! Feed the pig some crops!"
			end
			print("PigFeedingSystem: Sending notification to", player.Name)
			GameCore:SendNotification(player, "🐷 Pig Feeding", message, "info")
		else
			print("PigFeedingSystem: GameCore.SendNotification not available")
		end
		SetPlayerDebounce(player)
	else
		print("PigFeedingSystem: Player", player.Name, "in notification debounce")
	end

	print("PigFeedingSystem: ========== ENTER COMPLETE ==========")
end

-- Handle player leaving pig area
function PigFeedingSystem:OnPlayerLeavePigArea(player)
	print("PigFeedingSystem: ========== PLAYER LEFT PIG AREA ==========")
	print("PigFeedingSystem: Player:", player.Name)

	-- Hide pig feeding UI from the player
	if self.hidePigUIEvent then
		print("PigFeedingSystem: Firing HidePigFeedingUI to", player.Name)
		self.hidePigUIEvent:FireClient(player)
	else
		print("PigFeedingSystem: ERROR - hidePigUIEvent not available!")
	end

	-- Clear debounce when leaving
	self.playerDebounce[player.UserId] = nil
	print("PigFeedingSystem: Cleared debounce for", player.Name)

	print("PigFeedingSystem: ========== LEAVE COMPLETE ==========")
end

-- Update pig indicator based on nearby players
function PigFeedingSystem:UpdatePigIndicator()
	if not self.pigIndicator or not self.pigLabel then return end

	local anyPlayerNear = false
	local closestDistance = math.huge
	local nearbyCount = 0

	for userId, isNear in pairs(self.playersNearPig) do
		if isNear then
			anyPlayerNear = true
			nearbyCount = nearbyCount + 1
			-- Calculate closest player distance
			local player = Players:GetPlayerByUserId(userId)
			if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local pigPos = pigModel:FindFirstChild("HumanoidRootPart") or pigModel:FindFirstChild("Torso") or pigModel:FindFirstChild("Head")
				if pigPos then
					local distance = (player.Character.HumanoidRootPart.Position - pigPos.Position).Magnitude
					closestDistance = math.min(closestDistance, distance)
				end
			end
		end
	end

	if anyPlayerNear then
		-- Bright and opaque when players are near
		self.pigIndicator.Transparency = 0.1
		self.pigIndicator.Color = Color3.fromRGB(255, 105, 180) -- Brighter pink

		if closestDistance <= 8 then
			self.pigLabel.Text = "🐷 FEED ME CROPS!"
			self.pigLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- Yellow text
		else
			self.pigLabel.Text = "🐷 COME CLOSER!"
			self.pigLabel.TextColor3 = Color3.fromRGB(255, 200, 200) -- Light pink text
		end
	else
		-- Dimmer when no players near
		self.pigIndicator.Transparency = 0.5
		self.pigIndicator.Color = Color3.fromRGB(255, 182, 193) -- Normal pink
		self.pigLabel.Text = "🐷 WALK CLOSER TO FEED"
		self.pigLabel.TextColor3 = Color3.new(1, 1, 1) -- White text
	end
end

-- Setup feeding event handler
function PigFeedingSystem:SetupFeedingEventHandler()
	-- Enhanced FeedPig event handler with sound
	if self.feedPigEvent then
		self.feedPigEvent.OnServerEvent:Connect(function(player, cropId)
			print("PigFeedingSystem: " .. player.Name .. " is feeding pig with " .. cropId)

			-- Call original GameCore handler
			local success = pcall(function()
				GameCore:HandlePigFeeding(player, cropId)
			end)

			if success then
				-- Play oink sound
				self:PlayOinkSound()

				-- Create pig feeding effect
				self:CreatePigFeedingEffect()

				print("PigFeedingSystem: Pig fed successfully - oink!")
			else
				warn("PigFeedingSystem: Failed to handle pig feeding")
			end
		end)
		print("PigFeedingSystem: FeedPig event handler connected")
	else
		warn("PigFeedingSystem: Could not find FeedPig remote event")
	end
end

-- Play oink sound with variety
function PigFeedingSystem:PlayOinkSound()
	if self.oinkSound then
		-- Add slight pitch variation for realism
		self.oinkSound.Pitch = 1.0 + (math.random() * 0.4) -- Random pitch between 1.0 and 1.4

		local success, error = pcall(function()
			self.oinkSound:Play()
		end)

		if success then
			print("PigFeedingSystem: Pig oinked!")
		else
			warn("PigFeedingSystem: Failed to play oink sound:", error)
		end
	end
end

-- Create pig feeding visual effect
function PigFeedingSystem:CreatePigFeedingEffect()
	if not pigModel then return end

	local pigRoot = pigModel:FindFirstChild("HumanoidRootPart") or pigModel:FindFirstChild("Torso") or pigModel:FindFirstChild("Head")
	if not pigRoot then return end

	-- Create heart particles (pig is happy)
	for i = 1, 10 do
		local heart = Instance.new("Part")
		heart.Name = "PigHeart"
		heart.Size = Vector3.new(0.6, 0.6, 0.1)
		heart.Shape = Enum.PartType.Block
		heart.Material = Enum.Material.Neon
		heart.Color = Color3.fromRGB(255, 20, 147) -- Deep pink hearts
		heart.CanCollide = false
		heart.Anchored = true
		heart.Position = pigRoot.Position + Vector3.new(
			math.random(-3, 3),
			math.random(2, 5),
			math.random(-3, 3)
		)
		heart.Parent = workspace

		-- Create heart shape with SurfaceGui
		local surfaceGui = Instance.new("SurfaceGui")
		surfaceGui.Face = Enum.NormalId.Front
		surfaceGui.Parent = heart

		local heartLabel = Instance.new("TextLabel")
		heartLabel.Size = UDim2.new(1, 0, 1, 0)
		heartLabel.BackgroundTransparency = 1
		heartLabel.Text = "❤️"
		heartLabel.TextScaled = true
		heartLabel.Font = Enum.Font.SourceSansSemibold
		heartLabel.Parent = surfaceGui

		-- Animate heart floating upward
		local endPosition = heart.Position + Vector3.new(
			math.random(-4, 4),
			math.random(10, 18),
			math.random(-4, 4)
		)

		local tween = TweenService:Create(heart,
			TweenInfo.new(3.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = endPosition,
				Transparency = 1,
				Size = Vector3.new(0.1, 0.1, 0.1)
			}
		)
		tween:Play()
		tween.Completed:Connect(function()
			heart:Destroy()
		end)
	end

	-- Flash the pig indicator
	if self.pigIndicator then
		local originalColor = self.pigIndicator.Color
		self.pigIndicator.Color = Color3.fromRGB(255, 20, 147) -- Deep pink flash

		if self.pigLabel then
			self.pigLabel.Text = "🐷 OINK OINK! YUM!"
			self.pigLabel.TextColor3 = Color3.fromRGB(255, 20, 147)
		end

		spawn(function()
			wait(2.5)
			self.pigIndicator.Color = originalColor
			self:UpdatePigIndicator() -- Restore normal state
		end)
	end

	print("PigFeedingSystem: Created enhanced pig feeding effect with hearts and oink sound")
end

-- Handle player connections
Players.PlayerAdded:Connect(function(player)
	print("PigFeedingSystem: Player " .. player.Name .. " joined - they can feed the pig by walking close to it or clicking")
	PigFeedingSystem.playersNearPig[player.UserId] = false
	PigFeedingSystem.playerDebounce[player.UserId] = 0
end)

Players.PlayerRemoving:Connect(function(player)
	print("PigFeedingSystem: Player " .. player.Name .. " left")
	PigFeedingSystem.playersNearPig[player.UserId] = nil
	PigFeedingSystem.playerDebounce[player.UserId] = nil

	-- Hide UI if they were near pig
	if PigFeedingSystem.hidePigUIEvent then
		PigFeedingSystem.hidePigUIEvent:FireClient(player)
	end
end)

-- Admin commands for testing (FIXED - these are CHAT commands, not console commands)
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		-- Replace with your username - THESE ARE CHAT COMMANDS (type in chat, not console)
		if player.Name == "TommySalami311" then -- Replace with your username
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/testoink" then
				-- Test oink sound
				print("Admin: Testing oink sound")
				PigFeedingSystem:PlayOinkSound()

			elseif command == "/testpigfeed" then
				-- Force pig feeding effect
				print("Admin: Testing pig feeding effect")
				PigFeedingSystem:CreatePigFeedingEffect()

			elseif command == "/forcepigui" then
				-- Force show pig UI
				print("Admin: Forcing pig UI to show")
				if PigFeedingSystem.showPigUIEvent then
					PigFeedingSystem.showPigUIEvent:FireClient(player)
				end

			elseif command == "/hidepigui" then
				-- Force hide pig UI
				print("Admin: Forcing pig UI to hide")
				if PigFeedingSystem.hidePigUIEvent then
					PigFeedingSystem.hidePigUIEvent:FireClient(player)
				end

			elseif command == "/clearpigdebounce" then
				-- Clear debounce for player
				PigFeedingSystem.playerDebounce[player.UserId] = 0
				print("Admin: Cleared pig debounce for " .. player.Name)

			elseif command == "/pigstatus" then
				-- Show pig system status
				print("=== PIG SYSTEM STATUS ===")
				print("Pig model found:", pigModel ~= nil)
				print("Pig model position:", pigModel and (pigModel:FindFirstChild("HumanoidRootPart") and pigModel.HumanoidRootPart.Position or "No HumanoidRootPart") or "No pig")
				print("Pig indicator active:", PigFeedingSystem.pigIndicator ~= nil)
				print("Pig click area active:", PigFeedingSystem.pigClickPart ~= nil)
				print("Pig click detector active:", PigFeedingSystem.pigClickDetector ~= nil)
				print("Proximity loop running:", PigFeedingSystem.proximityLoop or false)
				print("Remote events created:")
				print("  ShowPigFeedingUI:", PigFeedingSystem.showPigUIEvent ~= nil)
				print("  HidePigFeedingUI:", PigFeedingSystem.hidePigUIEvent ~= nil)
				print("  FeedPig:", PigFeedingSystem.feedPigEvent ~= nil)
				print("Players near pig:")
				for userId, isNear in pairs(PigFeedingSystem.playersNearPig) do
					local p = Players:GetPlayerByUserId(userId)
					if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
						local pigPos = pigModel:FindFirstChild("HumanoidRootPart") or pigModel:FindFirstChild("Torso") or pigModel:FindFirstChild("Head")
						if pigPos then
							local distance = (p.Character.HumanoidRootPart.Position - pigPos.Position).Magnitude
							local debounceTime = PigFeedingSystem.playerDebounce[userId] or 0
							local debounceRemaining = math.max(0, NOTIFICATION_DEBOUNCE - (tick() - debounceTime))
							local debounceInfo = debounceRemaining > 0 and " [debounce:" .. math.ceil(debounceRemaining) .. "s]" or ""
							print("  " .. p.Name .. ": " .. tostring(isNear) .. " (distance: " .. math.floor(distance) .. ")" .. debounceInfo)
						end
					end
				end
				print("========================")

			elseif command == "/teleportpig" then
				-- Teleport to pig
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local pigPos = pigModel:FindFirstChild("HumanoidRootPart") or pigModel:FindFirstChild("Torso") or pigModel:FindFirstChild("Head")
					if pigPos then
						local teleportPosition = pigPos.Position + Vector3.new(0, 5, 12)
						player.Character.HumanoidRootPart.CFrame = CFrame.new(teleportPosition)
						print("Admin: Teleported " .. player.Name .. " to pig")
					end
				end

			elseif command == "/fixpig" then
				-- Reinitialize the pig system
				print("Admin: Reinitializing pig system")
				PigFeedingSystem:Cleanup()
				wait(1)
				PigFeedingSystem:Initialize()
			end
		end
	end)
end)

-- Cleanup function
function PigFeedingSystem:Cleanup()
	-- Stop proximity loop
	self.proximityLoop = false

	if self.pigIndicator then
		self.pigIndicator:Destroy()
	end

	if self.pigClickPart then
		self.pigClickPart:Destroy()
	end

	if self.oinkSound then
		self.oinkSound:Destroy()
	end

	-- Clear proximity connections
	for _, connection in pairs(self.proximityConnections) do
		if connection then
			connection:Disconnect()
		end
	end
	self.proximityConnections = {}

	print("PigFeedingSystem: Cleaned up")
end

-- Initialize the system
PigFeedingSystem:Initialize()

-- Make globally available
_G.PigFeedingSystem = PigFeedingSystem

-- Verify remote events are accessible
spawn(function()
	wait(2) -- Wait for everything to initialize
	local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	if gameRemotes then
		print("PigFeedingSystem: Verification - Remote events in GameRemotes:")
		for _, child in pairs(gameRemotes:GetChildren()) do
			if child:IsA("RemoteEvent") then
				print("  ✅ " .. child.Name)
			end
		end
	end
end)

print("=== FIXED PIG PROXIMITY FEEDING SYSTEM ACTIVE ===")
print("Features:")
print("✅ Walk within 15 studs of pig to show feeding interface")
print("✅ Click large invisible pig area for instant feeding menu")
print("✅ Billboard GUI with visual feedback")
print("✅ Extensive debug logging for troubleshooting")
print("✅ Fixed proximity detection loop")
print("✅ Enhanced click detection")
print("")
print("Interaction Methods:")
print("  🚶 Walk within 15 studs of pig")
print("  🖱️  Click anywhere near the pig (10x10x10 area)")
print("  🎯 Large invisible click area for easy interaction")
print("")
print("Admin Commands (TYPE IN CHAT, NOT CONSOLE):")
print("  /testoink - Test oink sound")
print("  /testpigfeed - Test pig feeding effect")
print("  /forcepigui - Force show pig UI")
print("  /hidepigui - Force hide pig UI")
print("  /clearpigdebounce - Clear notification debounce")
print("  /pigstatus - Show detailed pig system status")
print("  /teleportpig - Teleport to pig")
print("  /fixpig - Reinitialize pig system")
print("")
print("IMPORTANT: Admin commands are CHAT commands (type /pigstatus in chat, not console)")

return PigFeedingSystem