--[[
    FIXED ProximitySystem.server.lua - Stable Shop Detection
    Place in: ServerScriptService/Systems/ProximitySystem.server.lua
    
    FIXES:
    ✅ Increased shop touch part size for better detection
    ✅ Longer delays to prevent premature closing
    ✅ Better collision detection with continuous monitoring
    ✅ Reduced sensitivity to brief disconnections
    ✅ Enhanced debugging for troubleshooting
]]

local ProximitySystem = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- System state
ProximitySystem.ActiveProximities = {} -- [userId] = {shopActive = false, etc}
ProximitySystem.RemoteEvents = {}
ProximitySystem.TouchParts = {}
ProximitySystem.ShopEffects = {} -- Store shop area effects

-- FIXED: Enhanced proximity settings
ProximitySystem.Settings = {
	SHOP_TOUCH_DELAY = 2.0,           -- Increased from 0.5s to 2s
	SHOP_STAY_TIME = 3.0,             -- Increased from 1s to 3s  
	SHOP_PART_SIZE = Vector3.new(20, 2, 20), -- Increased from 12x1x12
	PROXIMITY_CHECK_INTERVAL = 0.5,   -- Check every 0.5s instead of 1s
	MAX_SHOP_DISTANCE = 25,           -- Maximum distance from shop center
	DEBUG_MODE = true                 -- Enable detailed logging
}

-- ========== INITIALIZATION ==========

function ProximitySystem:Initialize()
	print("ProximitySystem: Initializing FIXED stable proximity detection system...")

	-- Get remote events
	local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "GameRemotes"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Ensure remote events exist
	self:EnsureRemoteEvents(remoteFolder)

	-- Get remote event references
	self.RemoteEvents.OpenShop = remoteFolder:FindFirstChild("OpenShop")
	self.RemoteEvents.CloseShop = remoteFolder:FindFirstChild("CloseShop")
	self.RemoteEvents.ShowNotification = remoteFolder:FindFirstChild("ShowNotification")
	self.RemoteEvents.ShowPigFeedingUI = remoteFolder:FindFirstChild("ShowPigFeedingUI")
	self.RemoteEvents.HidePigFeedingUI = remoteFolder:FindFirstChild("HidePigFeedingUI")

	-- Find and setup touch parts with enhanced fallbacks
	self:FindAndSetupTouchPartsEnhanced()

	-- Setup player cleanup
	Players.PlayerRemoving:Connect(function(player)
		self.ActiveProximities[player.UserId] = nil
	end)

	-- Start IMPROVED proximity update loop
	self:StartImprovedProximityLoop()

	print("ProximitySystem: ✅ FIXED stable initialization complete")
	return true
end

function ProximitySystem:EnsureRemoteEvents(remoteFolder)
	local requiredEvents = {
		"OpenShop", "CloseShop", "ShowNotification", 
		"ShowPigFeedingUI", "HidePigFeedingUI"
	}

	for _, eventName in ipairs(requiredEvents) do
		if not remoteFolder:FindFirstChild(eventName) then
			local remoteEvent = Instance.new("RemoteEvent")
			remoteEvent.Name = eventName
			remoteEvent.Parent = remoteFolder
			print("ProximitySystem: Created missing RemoteEvent: " .. eventName)
		end
	end
end

-- ========== ENHANCED TOUCH PART DETECTION ==========

function ProximitySystem:FindAndSetupTouchPartsEnhanced()
	print("ProximitySystem: Finding touch parts with FIXED detection...")

	-- Try multiple strategies to find or create shop touch part
	local shopTouchPart = self:FindShopTouchPartMultiStrategy()

	if shopTouchPart then
		self:SetupStableShopTouchPart(shopTouchPart)
	else
		warn("ProximitySystem: No shop touch part found, creating STABLE fallback...")
		self:CreateStableShopTouchPart()
	end

	-- Find pig touch part (if exists)
	local pigTouchPart = self:FindTouchPart("PigTouchPart", "pig")
	if pigTouchPart then
		self:SetupPigTouchPart(pigTouchPart)
	end

	print("ProximitySystem: FIXED touch part setup complete")
end

function ProximitySystem:FindShopTouchPartMultiStrategy()
	print("ProximitySystem: Using multi-strategy shop touch part detection...")

	-- Strategy 1: Look for specifically named parts
	local namedParts = {"ShopTouchPart", "ShopArea", "Shop_Touch", "TouchPart_Shop", "EnhancedShopTouchPart"}
	for _, partName in ipairs(namedParts) do
		local part = self:FindTouchPart(partName, "shop")
		if part then
			print("ProximitySystem: Found shop part via name: " .. partName)
			return part
		end
	end

	-- Strategy 2: Look for parts with shop-related properties
	local searchLocations = {
		workspace,
		workspace:FindFirstChild("TouchParts"),
		workspace:FindFirstChild("Areas"),
		workspace:FindFirstChild("Shop"),
		workspace:FindFirstChild("Buildings"),
		workspace:FindFirstChild("Game")
	}

	for _, location in ipairs(searchLocations) do
		if location then
			-- Look for green neon parts (typical shop indicators)
			for _, child in pairs(location:GetDescendants()) do
				if child:IsA("BasePart") and 
					child.BrickColor == BrickColor.new("Bright green") and 
					child.Material == Enum.Material.Neon then
					print("ProximitySystem: Found shop part via green neon detection: " .. child.Name)
					return child
				end
			end

			-- Look for parts with "shop" in their name
			for _, child in pairs(location:GetDescendants()) do
				if child:IsA("BasePart") and child.Name:lower():find("shop") then
					print("ProximitySystem: Found shop part via name search: " .. child.Name)
					return child
				end
			end
		end
	end

	print("ProximitySystem: No existing shop touch part found")
	return nil
end

function ProximitySystem:FindTouchPart(partName, systemType)
	local searchLocations = {
		workspace,
		workspace:FindFirstChild("TouchParts"),
		workspace:FindFirstChild("Areas"),
		workspace:FindFirstChild("Shop"),
		workspace:FindFirstChild("Buildings")
	}

	for _, location in ipairs(searchLocations) do
		if location then
			local part = location:FindFirstChild(partName)
			if part and part:IsA("BasePart") then
				print("ProximitySystem: Found " .. partName .. " in " .. location.Name)
				return part
			end

			-- Search recursively
			for _, child in pairs(location:GetDescendants()) do
				if child.Name:lower():find(systemType) and child:IsA("BasePart") then
					print("ProximitySystem: Found " .. systemType .. " part: " .. child.Name)
					return child
				end
			end
		end
	end

	return nil
end

-- ========== STABLE SHOP TOUCH PART CREATION ==========

function ProximitySystem:CreateStableShopTouchPart()
	print("ProximitySystem: Creating STABLE shop touch part...")

	-- Try multiple strategic locations
	local spawnPositions = {
		Vector3.new(0, 1, -25),       -- In front of spawn (further out)
		Vector3.new(-25, 1, 0),       -- Left of spawn  
		Vector3.new(25, 1, 0),        -- Right of spawn
		Vector3.new(0, 1, -35),       -- Much further from spawn
		Vector3.new(-15, 1, -20),     -- Diagonal from spawn
	}

	local bestPosition = spawnPositions[1] -- Default

	-- Try to find the best position (avoid obstacles)
	for _, position in ipairs(spawnPositions) do
		if self:IsPositionClear(position, self.Settings.SHOP_PART_SIZE) then
			bestPosition = position
			break
		end
	end

	-- Create LARGER, more stable shop part
	local shopPart = Instance.new("Part")
	shopPart.Name = "StableShopTouchPart"
	shopPart.Size = self.Settings.SHOP_PART_SIZE -- Much larger: 20x2x20
	shopPart.Position = bestPosition
	shopPart.BrickColor = BrickColor.new("Bright green")
	shopPart.Material = Enum.Material.Neon
	shopPart.Anchored = true
	shopPart.CanCollide = false
	shopPart.Transparency = 0.2 -- Less transparent for better visibility
	shopPart.Parent = workspace

	-- Add enhanced visual effects
	self:AddEnhancedShopEffects(shopPart)

	-- Add informative label
	self:CreateShopLabel(shopPart)

	-- Setup the STABLE touch part
	self:SetupStableShopTouchPart(shopPart)

	print("ProximitySystem: ✅ STABLE shop touch part created at " .. tostring(bestPosition))
	print("ProximitySystem: Size: " .. tostring(self.Settings.SHOP_PART_SIZE))
end

function ProximitySystem:IsPositionClear(position, size)
	-- Simple check - just verify position is reasonable
	return position.Y > -50 and position.Y < 100 -- Basic bounds check
end

function ProximitySystem:AddEnhancedShopEffects(shopPart)
	-- Store effects for cleanup
	self.ShopEffects = {}

	-- Pulsing glow effect
	spawn(function()
		while shopPart and shopPart.Parent do
			local pulseUp = TweenService:Create(shopPart,
				TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Transparency = 0.1}
			)
			local pulseDown = TweenService:Create(shopPart,
				TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Transparency = 0.4}
			)

			pulseUp:Play()
			pulseUp.Completed:Wait()
			pulseDown:Play()
			pulseDown.Completed:Wait()
		end
	end)

	-- Floating particles effect
	spawn(function()
		while shopPart and shopPart.Parent do
			for i = 1, 3 do
				local particle = Instance.new("Part")
				particle.Size = Vector3.new(0.5, 0.5, 0.5)
				particle.Shape = Enum.PartType.Ball
				particle.Material = Enum.Material.Neon
				particle.Color = Color3.fromRGB(100, 255, 100)
				particle.CanCollide = false
				particle.Anchored = true
				particle.Position = shopPart.Position + Vector3.new(
					math.random(-8, 8),  -- Increased range for larger part
					1,
					math.random(-8, 8)
				)
				particle.Parent = workspace

				table.insert(self.ShopEffects, particle)

				local floatTween = TweenService:Create(particle,
					TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						Position = particle.Position + Vector3.new(0, 8, 0),
						Transparency = 1,
						Size = Vector3.new(0.1, 0.1, 0.1)
					}
				)
				floatTween:Play()
				floatTween.Completed:Connect(function()
					particle:Destroy()
				end)
			end
			wait(math.random(2, 4))
		end
	end)

	-- Rotating ring effect (larger)
	local ring = Instance.new("Part")
	ring.Name = "ShopRing"
	ring.Size = Vector3.new(25, 0.3, 25) -- Larger ring
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 255, 100)
	ring.CanCollide = false
	ring.Anchored = true
	ring.Position = shopPart.Position + Vector3.new(0, 1, 0)
	ring.Orientation = Vector3.new(0, 0, 90)
	ring.Transparency = 0.6
	ring.Parent = workspace

	table.insert(self.ShopEffects, ring)

	-- Rotate the ring
	spawn(function()
		while ring and ring.Parent do
			local rotation = TweenService:Create(ring,
				TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
				{Orientation = Vector3.new(0, 360, 90)}
			)
			rotation:Play()
			rotation.Completed:Wait()
		end
	end)
end

function ProximitySystem:CreateShopLabel(shopPart)
	-- Create billboard GUI for visibility
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(10, 0, 4, 0) -- Larger billboard
	billboardGui.StudsOffset = Vector3.new(0, 6, 0) -- Higher up
	billboardGui.Parent = shopPart

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.2 -- Less transparent
	frame.BorderSizePixel = 0
	frame.Parent = billboardGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.1, 0)
	corner.Parent = frame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -10, 1, -10)
	label.Position = UDim2.new(0, 5, 0, 5)
	label.BackgroundTransparency = 1
	label.Text = "🛒 STABLE SHOP\n\nLarge touch area!\nStay inside to browse\n\n📦 Pet Palace Market"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Parent = frame

	-- Pulsing text effect
	spawn(function()
		while label and label.Parent do
			local pulse = TweenService:Create(label,
				TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{TextTransparency = 0.2}
			)
			local unpulse = TweenService:Create(label,
				TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{TextTransparency = 0}
			)

			pulse:Play()
			pulse.Completed:Wait()
			unpulse:Play()
			unpulse.Completed:Wait()
		end
	end)
end

-- ========== STABLE SHOP TOUCH PART SETUP ==========

function ProximitySystem:SetupStableShopTouchPart(touchPart)
	print("ProximitySystem: Setting up STABLE shop touch part: " .. touchPart.Name)

	-- Store reference
	self.TouchParts.shop = touchPart

	-- FIXED: More stable touch detection
	local touchConnection = touchPart.Touched:Connect(function(hit)
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid then
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player then
				self:HandleStableShopTouch(player, true)
			end
		end
	end)

	-- FIXED: Much longer delay for touch ended + additional validation
	local touchEndedConnection = touchPart.TouchEnded:Connect(function(hit)
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid then
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player then
				-- FIXED: Longer delay + distance check
				spawn(function()
					wait(self.Settings.SHOP_TOUCH_DELAY) -- 2 seconds instead of 0.5

					-- Double-check if player is actually far from shop
					if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
						local playerPos = player.Character.HumanoidRootPart.Position
						local shopPos = touchPart.Position
						local distance = (playerPos - shopPos).Magnitude

						-- Only close if player is truly far away
						if distance > self.Settings.MAX_SHOP_DISTANCE then
							self:HandleStableShopTouch(player, false)
							if self.Settings.DEBUG_MODE then
								print("ProximitySystem: [DEBUG] Player " .. player.Name .. " is " .. distance .. " studs away, closing shop")
							end
						else
							if self.Settings.DEBUG_MODE then
								print("ProximitySystem: [DEBUG] Player " .. player.Name .. " is only " .. distance .. " studs away, keeping shop open")
							end
						end
					else
						-- No character, safe to close
						self:HandleStableShopTouch(player, false)
					end
				end)
			end
		end
	end)

	print("ProximitySystem: ✅ STABLE shop touch part configured with enhanced detection")
	print("ProximitySystem: Touch delay: " .. self.Settings.SHOP_TOUCH_DELAY .. "s")
	print("ProximitySystem: Stay time required: " .. self.Settings.SHOP_STAY_TIME .. "s")
	print("ProximitySystem: Max distance: " .. self.Settings.MAX_SHOP_DISTANCE .. " studs")
end

function ProximitySystem:HandleStableShopTouch(player, isTouching)
	local userId = player.UserId

	-- Initialize proximity state
	if not self.ActiveProximities[userId] then
		self.ActiveProximities[userId] = {}
	end

	local proximityState = self.ActiveProximities[userId]

	if isTouching and not proximityState.shopActive then
		-- Player entered shop area
		proximityState.shopActive = true
		proximityState.shopEnterTime = tick()

		if self.Settings.DEBUG_MODE then
			print("ProximitySystem: [DEBUG] " .. player.Name .. " entered STABLE shop area")
		end

		-- Fire OpenShop event to client
		if self.RemoteEvents.OpenShop then
			self.RemoteEvents.OpenShop:FireClient(player)
			print("ProximitySystem: Sent OpenShop event to " .. player.Name)
		else
			warn("ProximitySystem: OpenShop remote event not found!")
		end

		-- Send enhanced notification
		self:SendNotificationToPlayer(player, "🛒 Shop Opened", "Welcome! Large touch area - stay inside to browse safely.", "success")

		-- Create enter effect
		self:CreateShopEnterEffect(player)

	elseif not isTouching and proximityState.shopActive then
		-- FIXED: Much longer time requirement + better validation
		local timeInArea = tick() - (proximityState.shopEnterTime or 0)
		if timeInArea > self.Settings.SHOP_STAY_TIME then -- 3 seconds instead of 1
			-- Double-check player is really far away
			local shouldClose = true

			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and self.TouchParts.shop then
				local playerPos = player.Character.HumanoidRootPart.Position
				local shopPos = self.TouchParts.shop.Position
				local distance = (playerPos - shopPos).Magnitude

				if distance <= self.Settings.MAX_SHOP_DISTANCE then
					shouldClose = false -- Still close enough, don't close
					if self.Settings.DEBUG_MODE then
						print("ProximitySystem: [DEBUG] " .. player.Name .. " still close (" .. distance .. " studs), not closing")
					end
				end
			end

			if shouldClose then
				-- Player left shop area
				proximityState.shopActive = false

				if self.Settings.DEBUG_MODE then
					print("ProximitySystem: [DEBUG] " .. player.Name .. " left STABLE shop area after " .. timeInArea .. "s")
				end

				-- Fire CloseShop event to client
				if self.RemoteEvents.CloseShop then
					self.RemoteEvents.CloseShop:FireClient(player)
					print("ProximitySystem: Sent CloseShop event to " .. player.Name)
				end

				-- Send farewell notification
				self:SendNotificationToPlayer(player, "👋 Shop Closed", "Thanks for visiting! Come back anytime.", "info")
			end
		else
			if self.Settings.DEBUG_MODE then
				print("ProximitySystem: [DEBUG] " .. player.Name .. " hasn't been in shop long enough (" .. timeInArea .. "s < " .. self.Settings.SHOP_STAY_TIME .. "s)")
			end
		end
	end
end

function ProximitySystem:SendNotificationToPlayer(player, title, message, notificationType)
	-- Send notification directly without GameCore dependency
	if self.RemoteEvents.ShowNotification then
		self.RemoteEvents.ShowNotification:FireClient(player, title, message, notificationType or "info")
	else
		-- Fallback to printing if no notification system
		print("NOTIFICATION for " .. player.Name .. ": [" .. (notificationType or "INFO"):upper() .. "] " .. title .. " - " .. message)
	end
end

function ProximitySystem:CreateShopEnterEffect(player)
	-- Create special effect when player enters shop area
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	-- Golden sparkle effect around player
	for i = 1, 12 do -- More sparkles for better effect
		local sparkle = Instance.new("Part")
		sparkle.Size = Vector3.new(0.4, 0.4, 0.4)
		sparkle.Shape = Enum.PartType.Ball
		sparkle.Material = Enum.Material.Neon
		sparkle.Color = Color3.fromRGB(255, 215, 0)
		sparkle.CanCollide = false
		sparkle.Anchored = true
		sparkle.Position = humanoidRootPart.Position + Vector3.new(
			math.random(-4, 4),
			math.random(0, 5),
			math.random(-4, 4)
		)
		sparkle.Parent = workspace

		local tween = TweenService:Create(sparkle,
			TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = sparkle.Position + Vector3.new(0, 8, 0),
				Transparency = 1,
				Size = Vector3.new(0.1, 0.1, 0.1)
			}
		)
		tween:Play()
		tween.Completed:Connect(function()
			sparkle:Destroy()
		end)
	end
end

-- ========== IMPROVED PROXIMITY UPDATE LOOP ==========

function ProximitySystem:StartImprovedProximityLoop()
	-- FIXED: More frequent, smarter update loop
	spawn(function()
		while true do
			wait(self.Settings.PROXIMITY_CHECK_INTERVAL) -- Check every 0.5s

			for _, player in pairs(Players:GetPlayers()) do
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					self:UpdatePlayerProximityImproved(player)
				end
			end
		end
	end)

	print("ProximitySystem: Started improved proximity loop (interval: " .. self.Settings.PROXIMITY_CHECK_INTERVAL .. "s)")
end

function ProximitySystem:UpdatePlayerProximityImproved(player)
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	local userId = player.UserId
	local playerPosition = humanoidRootPart.Position

	-- Check shop proximity with improved logic
	if self.TouchParts.shop then
		local shopPosition = self.TouchParts.shop.Position
		local distance = (playerPosition - shopPosition).Magnitude

		local proximityState = self.ActiveProximities[userId] or {}

		-- FIXED: Better proximity hints without interfering with active shop
		local isNearShop = distance < (self.Settings.MAX_SHOP_DISTANCE + 10) -- Hint range
		local isInShop = distance < self.Settings.MAX_SHOP_DISTANCE          -- Active range

		if isNearShop and not isInShop and not proximityState.shopActive then
			-- Player is near but not in shop - show hint (less frequently)
			if not proximityState.hintShown or (tick() - (proximityState.lastHintTime or 0)) > 10 then
				proximityState.hintShown = true
				proximityState.lastHintTime = tick()
				self:SendNotificationToPlayer(player, "🛒 Shop Nearby", "Step on the large green glowing area to open the shop!", "info")

				if self.Settings.DEBUG_MODE then
					print("ProximitySystem: [DEBUG] Sent proximity hint to " .. player.Name .. " (distance: " .. distance .. ")")
				end
			end
		elseif not isNearShop then
			-- Reset hint when player moves away
			if proximityState.hintShown then
				proximityState.hintShown = false
				proximityState.lastHintTime = nil
			end
		end

		-- FIXED: If player is in shop range but shop isn't active, something might be wrong
		if isInShop and not proximityState.shopActive then
			if self.Settings.DEBUG_MODE then
				print("ProximitySystem: [DEBUG] " .. player.Name .. " is in shop range (" .. distance .. ") but shop not active - triggering touch")
			end
			-- Trigger touch manually
			self:HandleStableShopTouch(player, true)
		end

		self.ActiveProximities[userId] = proximityState
	end
end

-- ========== PIG TOUCH PART SETUP ==========

function ProximitySystem:SetupPigTouchPart(touchPart)
	print("ProximitySystem: Setting up pig touch part: " .. touchPart.Name)

	-- Store reference
	self.TouchParts.pig = touchPart

	-- Touch detection for pig feeding
	touchPart.Touched:Connect(function(hit)
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid then
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player then
				self:HandlePigTouch(player, true)
			end
		end
	end)

	touchPart.TouchEnded:Connect(function(hit)
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid then
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player then
				self:HandlePigTouch(player, false)
			end
		end
	end)

	print("ProximitySystem: ✅ Pig touch part configured")
end

function ProximitySystem:HandlePigTouch(player, isTouching)
	local userId = player.UserId

	if not self.ActiveProximities[userId] then
		self.ActiveProximities[userId] = {}
	end

	local proximityState = self.ActiveProximities[userId]

	if isTouching and not proximityState.pigActive then
		proximityState.pigActive = true

		if self.RemoteEvents.ShowPigFeedingUI then
			self.RemoteEvents.ShowPigFeedingUI:FireClient(player)
		end

	elseif not isTouching and proximityState.pigActive then
		proximityState.pigActive = false

		if self.RemoteEvents.HidePigFeedingUI then
			self.RemoteEvents.HidePigFeedingUI:FireClient(player)
		end
	end
end

-- ========== MANUAL SHOP ACTIVATION ==========

function ProximitySystem:ForceOpenShopForPlayer(player)
	print("ProximitySystem: Force opening shop for " .. player.Name)

	if self.RemoteEvents.OpenShop then
		self.RemoteEvents.OpenShop:FireClient(player)

		-- Mark as active
		local userId = player.UserId
		if not self.ActiveProximities[userId] then
			self.ActiveProximities[userId] = {}
		end
		self.ActiveProximities[userId].shopActive = true
		self.ActiveProximities[userId].shopEnterTime = tick()

		return true
	else
		warn("ProximitySystem: OpenShop remote event not available")
		return false
	end
end

-- ========== DEBUG FUNCTIONS ==========

function ProximitySystem:DebugProximitySystem()
	print("=== STABLE PROXIMITY SYSTEM DEBUG ===")

	print("Settings:")
	for key, value in pairs(self.Settings) do
		print("  " .. key .. ": " .. tostring(value))
	end

	print("Touch Parts:")
	for system, part in pairs(self.TouchParts) do
		if part and part.Parent then
			print("  " .. system .. ": " .. part.Name .. " (Position: " .. tostring(part.Position) .. ", Size: " .. tostring(part.Size) .. ")")
		else
			print("  " .. system .. ": Missing or destroyed")
		end
	end

	print("Active Proximities:")
	for userId, proximities in pairs(self.ActiveProximities) do
		local player = Players:GetPlayerByUserId(userId)
		local playerName = player and player.Name or "Unknown"
		print("  " .. playerName .. " (" .. userId .. "):")
		for system, data in pairs(proximities) do
			if type(data) == "table" then
				print("    " .. system .. ": [table]")
			else
				print("    " .. system .. ": " .. tostring(data))
			end
		end

		-- Show distance if player exists and shop exists
		if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and self.TouchParts.shop then
			local distance = (player.Character.HumanoidRootPart.Position - self.TouchParts.shop.Position).Magnitude
			print("    current_distance: " .. distance .. " studs")
		end
	end

	print("Remote Events:")
	for name, remote in pairs(self.RemoteEvents) do
		print("  " .. name .. ": " .. (remote and "✅" or "❌"))
	end

	print("Shop Effects Count: " .. #self.ShopEffects)

	print("========================================")
end

-- ========== ADMIN COMMANDS ==========

game:GetService("Players").PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.Name == "TommySalami311" then -- Replace with your username
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/debugproximity" then
				ProximitySystem:DebugProximitySystem()

			elseif command == "/forceshop" then
				ProximitySystem:ForceOpenShopForPlayer(player)

			elseif command == "/recreateshop" then
				-- Destroy and recreate shop touch part
				if ProximitySystem.TouchParts.shop then
					ProximitySystem.TouchParts.shop:Destroy()
				end
				-- Clean up effects
				for _, effect in pairs(ProximitySystem.ShopEffects) do
					if effect and effect.Parent then
						effect:Destroy()
					end
				end
				ProximitySystem.ShopEffects = {}

				ProximitySystem:CreateStableShopTouchPart()

			elseif command == "/testshop" then
				-- Test shop remote directly
				if ProximitySystem.RemoteEvents.OpenShop then
					ProximitySystem.RemoteEvents.OpenShop:FireClient(player)
					print("Fired OpenShop event for " .. player.Name)
				else
					print("OpenShop remote not found!")
				end

			elseif command == "/shophere" then
				-- Create shop at player's location
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local playerPos = player.Character.HumanoidRootPart.Position
					local shopPos = playerPos + Vector3.new(0, -1, -10) -- In front of player

					-- Destroy existing shop
					if ProximitySystem.TouchParts.shop then
						ProximitySystem.TouchParts.shop:Destroy()
					end

					-- Create shop at new location
					local shopPart = Instance.new("Part")
					shopPart.Name = "AdminPlacedStableShopTouchPart"
					shopPart.Size = ProximitySystem.Settings.SHOP_PART_SIZE
					shopPart.Position = shopPos
					shopPart.BrickColor = BrickColor.new("Bright green")
					shopPart.Material = Enum.Material.Neon
					shopPart.Anchored = true
					shopPart.CanCollide = false
					shopPart.Transparency = 0.2
					shopPart.Parent = workspace

					ProximitySystem:AddEnhancedShopEffects(shopPart)
					ProximitySystem:CreateShopLabel(shopPart)
					ProximitySystem:SetupStableShopTouchPart(shopPart)

					print("Created stable shop at player location: " .. tostring(shopPos))
				end

			elseif command == "/toggledebug" then
				ProximitySystem.Settings.DEBUG_MODE = not ProximitySystem.Settings.DEBUG_MODE
				print("Debug mode: " .. (ProximitySystem.Settings.DEBUG_MODE and "ON" or "OFF"))

			elseif command == "/shopstats" then
				-- Show shop statistics
				local activeShops = 0
				for _, proximities in pairs(ProximitySystem.ActiveProximities) do
					if proximities.shopActive then
						activeShops = activeShops + 1
					end
				end

				print("=== SHOP STATS ===")
				print("Active shops: " .. activeShops)
				print("Touch part size: " .. tostring(ProximitySystem.Settings.SHOP_PART_SIZE))
				print("Touch delay: " .. ProximitySystem.Settings.SHOP_TOUCH_DELAY .. "s")
				print("Stay time required: " .. ProximitySystem.Settings.SHOP_STAY_TIME .. "s")
				print("Max distance: " .. ProximitySystem.Settings.MAX_SHOP_DISTANCE .. " studs")
				print("================")
			end
		end
	end)
end)

-- ========== AUTO-INITIALIZATION ==========

-- Initialize when required
spawn(function()
	wait(2) -- Wait for other systems to load
	ProximitySystem:Initialize()
end)

-- Make globally available
_G.ProximitySystem = ProximitySystem

print("ProximitySystem: ✅ STABLE proximity detection system loaded!")
print("🎯 STABILITY FIXES:")
print("  ✅ Increased touch part size to 20x2x20 (was 12x1x12)")
print("  ✅ Extended touch delay to 2.0s (was 0.5s)")
print("  ✅ Extended required stay time to 3.0s (was 1.0s)")
print("  ✅ Added distance validation before closing shop")
print("  ✅ Enhanced debugging and monitoring")
print("  ✅ Improved proximity loop timing (0.5s intervals)")
print("  ✅ Better visual feedback and notifications")
print("")
print("🔧 Enhanced Admin Commands:")
print("  /debugproximity - Show detailed system status")
print("  /forceshop - Manually open shop")
print("  /recreateshop - Recreate shop touch part")
print("  /testshop - Test shop remote event")
print("  /shophere - Create shop at your current location")
print("  /toggledebug - Toggle debug mode on/off")
print("  /shopstats - Show shop statistics and settings")

return ProximitySystem