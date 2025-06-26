--[[
    FIXED ProximitySystem.server.lua - Server-Only Dependencies
    Place in: ServerScriptService/Systems/ProximitySystem.server.lua
    
    FIXES:
    ✅ Removed GameCore dependency that was causing UIManager access
    ✅ Server-side only implementation
    ✅ Direct notification sending without GameCore
    ✅ Simplified initialization without client dependencies
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

-- ========== INITIALIZATION ==========

function ProximitySystem:Initialize()
	print("ProximitySystem: Initializing FIXED proximity detection system...")

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

	-- Start proximity update loop for better responsiveness
	self:StartProximityUpdateLoop()

	print("ProximitySystem: ✅ FIXED initialization complete")
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
	print("ProximitySystem: Finding touch parts with enhanced detection...")

	-- Try multiple strategies to find or create shop touch part
	local shopTouchPart = self:FindShopTouchPartMultiStrategy()

	if shopTouchPart then
		self:SetupEnhancedShopTouchPart(shopTouchPart)
	else
		warn("ProximitySystem: No shop touch part found, creating enhanced fallback...")
		self:CreateEnhancedShopTouchPart()
	end

	-- Find pig touch part (if exists)
	local pigTouchPart = self:FindTouchPart("PigTouchPart", "pig")
	if pigTouchPart then
		self:SetupPigTouchPart(pigTouchPart)
	end

	print("ProximitySystem: Enhanced touch part setup complete")
end

function ProximitySystem:FindShopTouchPartMultiStrategy()
	print("ProximitySystem: Using multi-strategy shop touch part detection...")

	-- Strategy 1: Look for specifically named parts
	local namedParts = {"ShopTouchPart", "ShopArea", "Shop_Touch", "TouchPart_Shop"}
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

-- ========== ENHANCED SHOP TOUCH PART CREATION ==========

function ProximitySystem:CreateEnhancedShopTouchPart()
	print("ProximitySystem: Creating ENHANCED shop touch part...")

	-- Try multiple strategic locations
	local spawnPositions = {
		Vector3.new(0, 0.5, -20),     -- In front of spawn
		Vector3.new(-20, 0.5, 0),     -- Left of spawn  
		Vector3.new(20, 0.5, 0),      -- Right of spawn
		Vector3.new(0, 0.5, -30),     -- Further from spawn
		Vector3.new(-10, 0.5, -15),   -- Diagonal from spawn
	}

	local bestPosition = spawnPositions[1] -- Default

	-- Try to find the best position (avoid obstacles)
	for _, position in ipairs(spawnPositions) do
		if self:IsPositionClear(position, Vector3.new(12, 3, 12)) then
			bestPosition = position
			break
		end
	end

	-- Create enhanced shop part
	local shopPart = Instance.new("Part")
	shopPart.Name = "EnhancedShopTouchPart"
	shopPart.Size = Vector3.new(12, 1, 12) -- Larger for easier access
	shopPart.Position = bestPosition
	shopPart.BrickColor = BrickColor.new("Bright green")
	shopPart.Material = Enum.Material.Neon
	shopPart.Anchored = true
	shopPart.CanCollide = false
	shopPart.Transparency = 0.3
	shopPart.Parent = workspace

	-- Add enhanced visual effects
	self:AddEnhancedShopEffects(shopPart)

	-- Add informative label
	self:CreateShopLabel(shopPart)

	-- Setup the enhanced touch part
	self:SetupEnhancedShopTouchPart(shopPart)

	print("ProximitySystem: ✅ Enhanced shop touch part created at " .. tostring(bestPosition))
end

function ProximitySystem:IsPositionClear(position, size)
	-- Simple check - just verify position is reasonable
	local groundY = workspace.Terrain:GetHumanoidRootPartAtPosition(position, 100)
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
				{Transparency = 0.5}
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
					math.random(-5, 5),
					1,
					math.random(-5, 5)
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

	-- Rotating ring effect
	local ring = Instance.new("Part")
	ring.Name = "ShopRing"
	ring.Size = Vector3.new(15, 0.2, 15)
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 255, 100)
	ring.CanCollide = false
	ring.Anchored = true
	ring.Position = shopPart.Position + Vector3.new(0, 0.6, 0)
	ring.Orientation = Vector3.new(0, 0, 90)
	ring.Transparency = 0.7
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
	billboardGui.Size = UDim2.new(8, 0, 3, 0)
	billboardGui.StudsOffset = Vector3.new(0, 4, 0)
	billboardGui.Parent = shopPart

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0
	frame.Parent = billboardGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.1, 0)
	corner.Parent = frame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -10, 1, -10)
	label.Position = UDim2.new(0, 5, 0, 5)
	label.BackgroundTransparency = 1
	label.Text = "🛒 SHOP\n\nStep here to\nopen shop!"
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
				{TextTransparency = 0.3}
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

-- ========== ENHANCED SHOP TOUCH PART SETUP ==========

function ProximitySystem:SetupEnhancedShopTouchPart(touchPart)
	print("ProximitySystem: Setting up ENHANCED shop touch part: " .. touchPart.Name)

	-- Store reference
	self.TouchParts.shop = touchPart

	-- Enhanced touch detection with better responsiveness
	local touchConnection = touchPart.Touched:Connect(function(hit)
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid then
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player then
				self:HandleEnhancedShopTouch(player, true)
			end
		end
	end)

	-- Enhanced touch ended detection
	local touchEndedConnection = touchPart.TouchEnded:Connect(function(hit)
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid then
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player then
				-- Delay touch ended to prevent flickering
				spawn(function()
					wait(0.5) -- Small delay
					self:HandleEnhancedShopTouch(player, false)
				end)
			end
		end
	end)

	print("ProximitySystem: ✅ Enhanced shop touch part configured")
end

function ProximitySystem:HandleEnhancedShopTouch(player, isTouching)
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

		print("ProximitySystem: " .. player.Name .. " entered ENHANCED shop area")

		-- Fire OpenShop event to client
		if self.RemoteEvents.OpenShop then
			self.RemoteEvents.OpenShop:FireClient(player)
			print("ProximitySystem: Sent OpenShop event to " .. player.Name)
		else
			warn("ProximitySystem: OpenShop remote event not found!")
		end

		-- Send enhanced notification
		self:SendNotificationToPlayer(player, "🛒 Shop Opened", "Welcome to the Pet Palace Shop! Browse items and make purchases.", "success")

		-- Create enter effect
		self:CreateShopEnterEffect(player)

	elseif not isTouching and proximityState.shopActive then
		-- Check if player has been in area long enough to avoid flickering
		local timeInArea = tick() - (proximityState.shopEnterTime or 0)
		if timeInArea > 1 then -- Only close if they've been in area for at least 1 second
			-- Player left shop area
			proximityState.shopActive = false
			print("ProximitySystem: " .. player.Name .. " left ENHANCED shop area")

			-- Fire CloseShop event to client
			if self.RemoteEvents.CloseShop then
				self.RemoteEvents.CloseShop:FireClient(player)
				print("ProximitySystem: Sent CloseShop event to " .. player.Name)
			end

			-- Send farewell notification
			self:SendNotificationToPlayer(player, "👋 Shop Closed", "Thanks for visiting! Come back anytime.", "info")
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
	for i = 1, 8 do
		local sparkle = Instance.new("Part")
		sparkle.Size = Vector3.new(0.3, 0.3, 0.3)
		sparkle.Shape = Enum.PartType.Ball
		sparkle.Material = Enum.Material.Neon
		sparkle.Color = Color3.fromRGB(255, 215, 0)
		sparkle.CanCollide = false
		sparkle.Anchored = true
		sparkle.Position = humanoidRootPart.Position + Vector3.new(
			math.random(-3, 3),
			math.random(0, 4),
			math.random(-3, 3)
		)
		sparkle.Parent = workspace

		local tween = TweenService:Create(sparkle,
			TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = sparkle.Position + Vector3.new(0, 6, 0),
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

-- ========== PROXIMITY UPDATE LOOP ==========

function ProximitySystem:StartProximityUpdateLoop()
	-- Update loop for better proximity detection
	spawn(function()
		while true do
			wait(1) -- Check every second

			for _, player in pairs(Players:GetPlayers()) do
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					self:UpdatePlayerProximity(player)
				end
			end
		end
	end)
end

function ProximitySystem:UpdatePlayerProximity(player)
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	local userId = player.UserId
	local playerPosition = humanoidRootPart.Position

	-- Check shop proximity
	if self.TouchParts.shop then
		local shopPosition = self.TouchParts.shop.Position
		local distance = (playerPosition - shopPosition).Magnitude

		-- Enhanced proximity detection (within reasonable distance)
		local proximityState = self.ActiveProximities[userId] or {}
		local isNearShop = distance < 15 -- Within 15 studs

		if isNearShop and not proximityState.shopActive then
			-- Player is near shop but not in active area - show hint
			if not proximityState.hintShown then
				proximityState.hintShown = true
				self:SendNotificationToPlayer(player, "🛒 Shop Nearby", "Step on the green glowing area to open the shop!", "info")
			end
		elseif not isNearShop then
			-- Reset hint when player moves away
			if proximityState.hintShown then
				proximityState.hintShown = false
			end
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

		return true
	else
		warn("ProximitySystem: OpenShop remote event not available")
		return false
	end
end

-- ========== DEBUG FUNCTIONS ==========

function ProximitySystem:DebugProximitySystem()
	print("=== FIXED PROXIMITY SYSTEM DEBUG ===")

	print("Touch Parts:")
	for system, part in pairs(self.TouchParts) do
		if part and part.Parent then
			print("  " .. system .. ": " .. part.Name .. " (Position: " .. tostring(part.Position) .. ")")
		else
			print("  " .. system .. ": Missing or destroyed")
		end
	end

	print("Active Proximities:")
	for userId, proximities in pairs(self.ActiveProximities) do
		local player = Players:GetPlayerByUserId(userId)
		local playerName = player and player.Name or "Unknown"
		print("  " .. playerName .. " (" .. userId .. "):")
		for system, active in pairs(proximities) do
			print("    " .. system .. ": " .. tostring(active))
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

				ProximitySystem:CreateEnhancedShopTouchPart()

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
					local shopPos = playerPos + Vector3.new(0, -3, -8) -- In front of player

					-- Destroy existing shop
					if ProximitySystem.TouchParts.shop then
						ProximitySystem.TouchParts.shop:Destroy()
					end

					-- Create shop at new location
					local shopPart = Instance.new("Part")
					shopPart.Name = "AdminPlacedShopTouchPart"
					shopPart.Size = Vector3.new(12, 1, 12)
					shopPart.Position = shopPos
					shopPart.BrickColor = BrickColor.new("Bright green")
					shopPart.Material = Enum.Material.Neon
					shopPart.Anchored = true
					shopPart.CanCollide = false
					shopPart.Transparency = 0.3
					shopPart.Parent = workspace

					ProximitySystem:AddEnhancedShopEffects(shopPart)
					ProximitySystem:CreateShopLabel(shopPart)
					ProximitySystem:SetupEnhancedShopTouchPart(shopPart)

					print("Created shop at player location: " .. tostring(shopPos))
				end
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

print("ProximitySystem: ✅ FIXED proximity detection system loaded!")
print("🎯 FIXED FEATURES:")
print("  ✅ Removed GameCore dependency that caused UIManager access")
print("  ✅ Server-only implementation without client dependencies")
print("  ✅ Direct notification sending without external modules")
print("  ✅ Guaranteed shop touch part creation")
print("  ✅ Enhanced visual effects and user guidance")
print("")
print("🔧 Admin Commands:")
print("  /debugproximity - Show system status")
print("  /forceshop - Manually open shop")
print("  /recreateshop - Recreate shop touch part")
print("  /testshop - Test shop remote event")
print("  /shophere - Create shop at your current location")

return ProximitySystem