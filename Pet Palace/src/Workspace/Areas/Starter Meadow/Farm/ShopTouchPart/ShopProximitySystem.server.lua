--[[
    Shop Proximity System - Stable Version
    Replace your ShopTouchPart.server.lua with this version
    
    FIXES:
    - Fixed shop opening/closing by itself
    - Better state management to prevent flickering
    - Improved debounce system
    - Stable proximity detection
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

print("=== STABLE SHOP PROXIMITY SYSTEM STARTING ===")

local ShopProximitySystem = {}

-- Get the shop touch part
local shopTouchPart = script.Parent
if not shopTouchPart or not shopTouchPart:IsA("BasePart") then
	error("ShopProximitySystem: Script must be placed inside a Part (ShopTouchPart)")
end

print("ShopProximitySystem: Found shop touch part:", shopTouchPart.Name)

-- System state with improved stability
ShopProximitySystem.playersNearShop = {}
ShopProximitySystem.playerShopStatus = {} -- Track if shop is open for each player
ShopProximitySystem.playerDebounce = {}
ShopProximitySystem.shopIndicator = nil
ShopProximitySystem.shopLabel = nil
ShopProximitySystem.touchConnection = nil
ShopProximitySystem.proximityLoop = nil

-- Debounce and stability settings
local NOTIFICATION_DEBOUNCE = 5 -- 5 seconds between notifications per player
local SHOP_TOGGLE_DEBOUNCE = 3  -- 3 seconds between shop open/close per player
local PROXIMITY_THRESHOLD = 20  -- Distance to be "near" shop
local SHOP_OPEN_THRESHOLD = 8   -- Distance to auto-open shop
local STATE_CHANGE_DELAY = 1    -- Delay before processing state changes

-- Create or get remote events
local function SetupRemoteEvents()
	local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not gameRemotes then
		gameRemotes = Instance.new("Folder")
		gameRemotes.Name = "GameRemotes"
		gameRemotes.Parent = ReplicatedStorage
	end

	-- Create shop remote events if they don't exist
	local openShopEvent = gameRemotes:FindFirstChild("OpenShop")
	if not openShopEvent then
		openShopEvent = Instance.new("RemoteEvent")
		openShopEvent.Name = "OpenShop"
		openShopEvent.Parent = gameRemotes
	end

	local closeShopEvent = gameRemotes:FindFirstChild("CloseShop")
	if not closeShopEvent then
		closeShopEvent = Instance.new("RemoteEvent")
		closeShopEvent.Name = "CloseShop"
		closeShopEvent.Parent = gameRemotes
	end

	print("ShopProximitySystem: Remote events setup complete")
	return openShopEvent, closeShopEvent
end

-- Check if player is in debounce period
local function IsPlayerInDebounce(player, debounceType)
	local userId = player.UserId
	local currentTime = tick()

	if not ShopProximitySystem.playerDebounce[userId] then
		ShopProximitySystem.playerDebounce[userId] = {}
	end

	local lastTime = ShopProximitySystem.playerDebounce[userId][debounceType] or 0
	local debounceTime = (debounceType == "notification") and NOTIFICATION_DEBOUNCE or SHOP_TOGGLE_DEBOUNCE

	return (currentTime - lastTime) < debounceTime
end

-- Set player debounce
local function SetPlayerDebounce(player, debounceType)
	local userId = player.UserId
	if not ShopProximitySystem.playerDebounce[userId] then
		ShopProximitySystem.playerDebounce[userId] = {}
	end
	ShopProximitySystem.playerDebounce[userId][debounceType] = tick()
end

-- Initialize the shop proximity system
function ShopProximitySystem:Initialize()
	print("ShopProximitySystem: Initializing stable shop proximity system...")

	-- Setup remote events
	self.openShopEvent, self.closeShopEvent = SetupRemoteEvents()

	-- Setup shop indicator
	self:SetupShopIndicator()

	-- Start proximity detection
	self:StartProximityDetection()

	-- Setup touch detection as backup
	self:SetupTouchDetection()

	print("ShopProximitySystem: Stable shop proximity system fully initialized!")
end

-- Setup shop indicator
function ShopProximitySystem:SetupShopIndicator()
	-- Remove any existing indicator
	local existingIndicator = shopTouchPart:FindFirstChild("ShopIndicator")
	if existingIndicator then
		existingIndicator:Destroy()
	end

	-- Create the indicator above the shop
	local indicator = Instance.new("Part")
	indicator.Name = "ShopIndicator"
	indicator.Size = Vector3.new(8, 0.5, 8)
	indicator.Shape = Enum.PartType.Cylinder
	indicator.Material = Enum.Material.Neon
	indicator.Color = Color3.fromRGB(0, 170, 255) -- Blue for shop
	indicator.CanCollide = false
	indicator.Anchored = true
	indicator.Transparency = 0.3

	-- Position above shop
	indicator.CFrame = shopTouchPart.CFrame + Vector3.new(0, shopTouchPart.Size.Y/2 + 5, 0)
	indicator.Orientation = Vector3.new(0, 0, 90) -- Rotate cylinder to be horizontal

	indicator.Parent = shopTouchPart

	-- Add Billboard GUI
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(0, 150, 0, 60)
	billboardGui.StudsOffset = Vector3.new(0, 3, 0)
	billboardGui.Parent = indicator

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "🛒 WALK CLOSER TO SHOP"
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
			local pulse = math.sin(time * 1.5) * 0.15 + 1 -- Gentle pulse
			indicator.Size = Vector3.new(8 * pulse, 0.5, 8 * pulse)
			wait(0.1)
		end
	end)

	-- Store references
	self.shopIndicator = indicator
	self.shopLabel = label

	print("ShopProximitySystem: Shop indicator with billboard GUI created")
end

-- Start proximity detection loop (improved stability)
function ShopProximitySystem:StartProximityDetection()
	-- Stop existing loop if running
	if self.proximityLoop then
		self.proximityLoop = false
		wait(1) -- Wait for old loop to stop
	end

	self.proximityLoop = true

	spawn(function()
		print("ShopProximitySystem: Starting stable proximity detection loop")

		while self.proximityLoop and shopTouchPart and shopTouchPart.Parent do
			local shopPosition = shopTouchPart.Position

			-- Check each player's distance to shop
			for _, player in pairs(Players:GetPlayers()) do
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local playerPosition = player.Character.HumanoidRootPart.Position
					local distance = (playerPosition - shopPosition).Magnitude

					-- Current states
					local isNearShop = distance <= PROXIMITY_THRESHOLD
					local isCloseToShop = distance <= SHOP_OPEN_THRESHOLD
					local wasNearShop = self.playersNearShop[player.UserId] or false
					local shopCurrentlyOpen = self.playerShopStatus[player.UserId] or false

					-- Handle proximity changes with stability
					if isNearShop and not wasNearShop then
						-- Player entered shop area
						self:OnPlayerEnterShopArea(player, distance)
					elseif not isNearShop and wasNearShop then
						-- Player left shop area
						self:OnPlayerLeaveShopArea(player)
					end

					-- Handle shop opening/closing with debounce
					if isCloseToShop and not shopCurrentlyOpen and not IsPlayerInDebounce(player, "shop_toggle") then
						-- Close enough to open shop
						self:OpenShopForPlayer(player)
						SetPlayerDebounce(player, "shop_toggle")
					elseif not isNearShop and shopCurrentlyOpen and not IsPlayerInDebounce(player, "shop_toggle") then
						-- Far enough to close shop
						self:CloseShopForPlayer(player)
						SetPlayerDebounce(player, "shop_toggle")
					end

					-- Update proximity status
					self.playersNearShop[player.UserId] = isNearShop
				end
			end

			-- Update indicator based on nearby players
			self:UpdateShopIndicator()

			wait(1) -- Check every second for stability (reduced frequency)
		end

		print("ShopProximitySystem: Proximity detection loop ended")
	end)
end

-- Handle player entering shop area
function ShopProximitySystem:OnPlayerEnterShopArea(player, distance)
	print("ShopProximitySystem: " .. player.Name .. " entered shop area (distance: " .. math.floor(distance) .. " studs)")

	-- Only send notification if not in debounce
	if not IsPlayerInDebounce(player, "notification") then
		local message = "Walk closer to the shop building to browse items!"
		if distance <= SHOP_OPEN_THRESHOLD then
			message = "You're close enough! Shop will open automatically."
		end

		self:SendShopNotification(player, "🛒 Shop Nearby", message, "info")
		SetPlayerDebounce(player, "notification")
	end
end

-- Handle player leaving shop area
function ShopProximitySystem:OnPlayerLeaveShopArea(player)
	print("ShopProximitySystem: " .. player.Name .. " left shop area")

	-- Close shop for the player
	self:CloseShopForPlayer(player)

	-- Clear some debounces when player leaves (but keep shop toggle debounce)
	if self.playerDebounce[player.UserId] then
		self.playerDebounce[player.UserId].notification = nil
	end

	-- Send goodbye notification (no debounce needed for this)
	self:SendShopNotification(player, "👋 Thanks for visiting!", 
		"Come back anytime to buy seeds and upgrades!", "info")
end

-- Open shop for specific player
function ShopProximitySystem:OpenShopForPlayer(player)
	-- Check if shop is already open for this player
	if self.playerShopStatus[player.UserId] then
		return -- Already open, don't spam
	end

	print("ShopProximitySystem: Opening shop for " .. player.Name)

	-- Fire the open shop event
	if self.openShopEvent then
		self.openShopEvent:FireClient(player)
		self.playerShopStatus[player.UserId] = true -- Track that shop is open
	end

	-- Send welcome notification (no debounce needed for shop opening message)
	self:SendShopNotification(player, "🛒 Welcome to the Shop!", 
		"Browse seeds, upgrades, and farming supplies!", "success")
end

-- Close shop for specific player
function ShopProximitySystem:CloseShopForPlayer(player)
	-- Check if shop is already closed for this player
	if not self.playerShopStatus[player.UserId] then
		return -- Already closed, don't spam
	end

	print("ShopProximitySystem: Closing shop for " .. player.Name)

	-- Fire the close shop event
	if self.closeShopEvent then
		self.closeShopEvent:FireClient(player)
		self.playerShopStatus[player.UserId] = false -- Track that shop is closed
	end
end

-- Update shop indicator based on nearby players
function ShopProximitySystem:UpdateShopIndicator()
	if not self.shopIndicator or not self.shopLabel then return end

	local nearbyPlayerCount = 0
	local closestDistance = math.huge

	for userId, isNear in pairs(self.playersNearShop) do
		if isNear then
			nearbyPlayerCount = nearbyPlayerCount + 1

			-- Calculate closest player distance
			local player = Players:GetPlayerByUserId(userId)
			if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local distance = (player.Character.HumanoidRootPart.Position - shopTouchPart.Position).Magnitude
				closestDistance = math.min(closestDistance, distance)
			end
		end
	end

	if nearbyPlayerCount > 0 then
		-- Players are near - make indicator bright and welcoming
		self.shopIndicator.Transparency = 0.1
		self.shopIndicator.Color = Color3.fromRGB(50, 255, 50) -- Green when accessible

		if closestDistance <= SHOP_OPEN_THRESHOLD then
			self.shopLabel.Text = "🛒 SHOP IS OPEN!"
			self.shopLabel.TextColor3 = Color3.fromRGB(50, 255, 50) -- Green text
		else
			self.shopLabel.Text = "🛒 WALK CLOSER TO SHOP"
			self.shopLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- Yellow text
		end
	else
		-- No players near - dimmer indicator
		self.shopIndicator.Transparency = 0.5
		self.shopIndicator.Color = Color3.fromRGB(0, 170, 255) -- Blue when not accessible
		self.shopLabel.Text = "🛒 WALK CLOSER TO SHOP"
		self.shopLabel.TextColor3 = Color3.new(1, 1, 1) -- White text
	end
end

-- Setup touch detection as backup
function ShopProximitySystem:SetupTouchDetection()
	-- Disconnect existing touch connection if it exists
	if self.touchConnection then
		self.touchConnection:Disconnect()
		self.touchConnection = nil
	end

	-- Function to handle when a player touches the part
	local function onTouched(hit)
		local character = hit.Parent
		if character and character:FindFirstChild("Humanoid") then
			local player = Players:GetPlayerFromCharacter(character)
			if player and not IsPlayerInDebounce(player, "shop_toggle") then
				print("ShopProximitySystem: " .. player.Name .. " touched shop building")
				self:OpenShopForPlayer(player)
				SetPlayerDebounce(player, "shop_toggle")
			end
		end
	end

	-- Connect the touched event and store the connection
	self.touchConnection = shopTouchPart.Touched:Connect(onTouched)

	print("ShopProximitySystem: Touch detection setup as backup with debounce")
end

-- Send notifications to players (fallback if GameCore not available)
function ShopProximitySystem:SendShopNotification(player, title, message, notificationType)
	-- Try to use GameCore first
	if _G.GameCore and _G.GameCore.SendNotification then
		_G.GameCore:SendNotification(player, title, message, notificationType)
	else
		-- Fallback to basic notification
		local success, error = pcall(function()
			game.StarterGui:SetCore("SendNotification", {
				Title = title,
				Text = message,
				Duration = 3
			})
		end)

		if not success then
			print("ShopProximitySystem: " .. player.Name .. " - " .. title .. ": " .. message)
		end
	end
end

-- Handle player connections
Players.PlayerAdded:Connect(function(player)
	print("ShopProximitySystem: Player " .. player.Name .. " joined")
	ShopProximitySystem.playersNearShop[player.UserId] = false
	ShopProximitySystem.playerShopStatus[player.UserId] = false
	ShopProximitySystem.playerDebounce[player.UserId] = {}

	-- Send welcome message after a delay
	spawn(function()
		wait(8) -- Wait for player to get oriented
		if player and player.Parent then
			ShopProximitySystem:SendShopNotification(player, "🏪 Shop Available", 
				"Walk up to the shop building to browse items and upgrades!", "info")
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	print("ShopProximitySystem: Player " .. player.Name .. " left")
	ShopProximitySystem.playersNearShop[player.UserId] = nil
	ShopProximitySystem.playerShopStatus[player.UserId] = nil
	ShopProximitySystem.playerDebounce[player.UserId] = nil
end)

-- Cleanup function
function ShopProximitySystem:Cleanup()
	-- Stop proximity loop
	self.proximityLoop = false

	if self.shopIndicator then
		self.shopIndicator:Destroy()
	end

	if self.touchConnection then
		self.touchConnection:Disconnect()
		self.touchConnection = nil
	end

	print("ShopProximitySystem: Cleaned up")
end

-- Admin commands for testing (CHAT COMMANDS)
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		-- Replace with your username
		if player.Name == "TommySalami311" then -- Replace with your username
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/testshop" then
				-- Force open shop (bypass debounce)
				print("Admin: Force opening shop for " .. player.Name)
				ShopProximitySystem:OpenShopForPlayer(player)

			elseif command == "/closeshop" then
				-- Force close shop
				print("Admin: Force closing shop for " .. player.Name)
				ShopProximitySystem:CloseShopForPlayer(player)

			elseif command == "/cleardebounce" then
				-- Clear debounces for player
				ShopProximitySystem.playerDebounce[player.UserId] = {}
				ShopProximitySystem.playerShopStatus[player.UserId] = false
				print("Admin: Cleared all debounces for " .. player.Name)

			elseif command == "/shopstatus" then
				-- Show shop system status
				print("=== SHOP SYSTEM STATUS ===")
				print("Shop touch part found:", shopTouchPart ~= nil)
				print("Shop indicator active:", ShopProximitySystem.shopIndicator ~= nil)
				print("Touch connection active:", ShopProximitySystem.touchConnection ~= nil)
				print("Proximity loop running:", ShopProximitySystem.proximityLoop or false)
				print("Players near shop:")
				for userId, isNear in pairs(ShopProximitySystem.playersNearShop) do
					local p = Players:GetPlayerByUserId(userId)
					if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
						local distance = (p.Character.HumanoidRootPart.Position - shopTouchPart.Position).Magnitude
						local shopOpen = ShopProximitySystem.playerShopStatus[userId] or false
						local debounceInfo = ""
						if ShopProximitySystem.playerDebounce[userId] then
							for debounceType, time in pairs(ShopProximitySystem.playerDebounce[userId]) do
								local remaining = math.max(0, (debounceType == "notification" and NOTIFICATION_DEBOUNCE or SHOP_TOGGLE_DEBOUNCE) - (tick() - time))
								if remaining > 0 then
									debounceInfo = debounceInfo .. " [" .. debounceType .. ":" .. math.ceil(remaining) .. "s]"
								end
							end
						end
						print("  " .. p.Name .. ": near=" .. tostring(isNear) .. " shopOpen=" .. tostring(shopOpen) .. " (distance: " .. math.floor(distance) .. ")" .. debounceInfo)
					end
				end
				print("=========================")

			elseif command == "/teleportshop" then
				-- Teleport to shop
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local teleportPosition = shopTouchPart.Position + Vector3.new(0, 5, 10)
					player.Character.HumanoidRootPart.CFrame = CFrame.new(teleportPosition)
					print("Admin: Teleported " .. player.Name .. " to shop")
				end

			elseif command == "/fixshop" then
				-- Reinitialize the shop system
				print("Admin: Reinitializing shop system")
				ShopProximitySystem:Cleanup()
				wait(1)
				ShopProximitySystem:Initialize()
			end
		end
	end)
end)

-- Initialize the system
ShopProximitySystem:Initialize()

-- Make globally available
_G.ShopProximitySystem = ShopProximitySystem

print("=== STABLE SHOP PROXIMITY SYSTEM ACTIVE ===")
print("Features:")
print("✅ Stable proximity detection (no flickering)")
print("✅ Smart debounce prevents shop opening/closing spam")
print("✅ State tracking prevents duplicate events")
print("✅ Billboard GUI with visual feedback")
print("✅ Touch shop building as backup activation")
print("")
print("Distance Settings:")
print("  📏 Proximity range: " .. PROXIMITY_THRESHOLD .. " studs")
print("  🛒 Auto-open range: " .. SHOP_OPEN_THRESHOLD .. " studs")
print("")
print("Debounce Settings:")
print("  📢 Notifications: " .. NOTIFICATION_DEBOUNCE .. " seconds")
print("  🛒 Shop Toggle: " .. SHOP_TOGGLE_DEBOUNCE .. " seconds")
print("")
print("Admin Commands (TYPE IN CHAT):")
print("  /testshop - Force open shop")
print("  /closeshop - Force close shop")
print("  /cleardebounce - Clear all debounces")
print("  /shopstatus - Show detailed shop system status")
print("  /teleportshop - Teleport to shop")
print("  /fixshop - Reinitialize shop system")

return ShopProximitySystem