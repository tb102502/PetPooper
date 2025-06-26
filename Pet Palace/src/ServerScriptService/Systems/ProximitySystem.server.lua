--[[
    ProximitySystem.server.lua - Touch Part Detection System
    Place in: ServerScriptService/Systems/ProximitySystem.server.lua
    
    FEATURES:
    ✅ Shop touch part detection
    ✅ Automatic remote event triggering
    ✅ Player proximity tracking
    ✅ Integration with GameCore and ShopSystem
]]

local ProximitySystem = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Module references
local GameCore = require(script.Parent.Parent.Core:WaitForChild("GameCore"))

-- System state
ProximitySystem.ActiveProximities = {} -- [userId] = {shopActive = false, etc}
ProximitySystem.RemoteEvents = {}
ProximitySystem.TouchParts = {}

-- ========== INITIALIZATION ==========

function ProximitySystem:Initialize()
	print("ProximitySystem: Initializing proximity detection system...")

	-- Get remote events
	local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if remoteFolder then
		self.RemoteEvents.OpenShop = remoteFolder:FindFirstChild("OpenShop")
		self.RemoteEvents.CloseShop = remoteFolder:FindFirstChild("CloseShop")
		self.RemoteEvents.ShowPigFeedingUI = remoteFolder:FindFirstChild("ShowPigFeedingUI")
		self.RemoteEvents.HidePigFeedingUI = remoteFolder:FindFirstChild("HidePigFeedingUI")
	end

	-- Find and setup touch parts
	self:FindAndSetupTouchParts()

	-- Setup player cleanup
	Players.PlayerRemoving:Connect(function(player)
		self.ActiveProximities[player.UserId] = nil
	end)

	print("ProximitySystem: ✅ Initialization complete")
	return true
end

-- ========== TOUCH PART DETECTION ==========

function ProximitySystem:FindAndSetupTouchParts()
	print("ProximitySystem: Finding touch parts in workspace...")

	-- Find shop touch part
	local shopTouchPart = self:FindTouchPart("ShopTouchPart", "shop")
	if shopTouchPart then
		self:SetupShopTouchPart(shopTouchPart)
	else
		warn("ProximitySystem: ShopTouchPart not found! Creating fallback...")
		self:CreateFallbackShopTouchPart()
	end

	-- Find pig touch part (if exists)
	local pigTouchPart = self:FindTouchPart("PigTouchPart", "pig")
	if pigTouchPart then
		self:SetupPigTouchPart(pigTouchPart)
	end

	print("ProximitySystem: Touch part setup complete")
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

function ProximitySystem:CreateFallbackShopTouchPart()
	print("ProximitySystem: Creating fallback shop touch part...")

	-- Create a visible touch part at spawn for testing
	local shopPart = Instance.new("Part")
	shopPart.Name = "ShopTouchPart"
	shopPart.Size = Vector3.new(10, 1, 10)
	shopPart.Position = Vector3.new(0, 0.5, -20) -- In front of spawn
	shopPart.BrickColor = BrickColor.new("Bright green")
	shopPart.Material = Enum.Material.Neon
	shopPart.Anchored = true
	shopPart.CanCollide = false
	shopPart.Transparency = 0.5
	shopPart.Parent = workspace

	-- Add label
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Top
	surfaceGui.Parent = shopPart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "🛒 SHOP\nStep here to open shop"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Parent = surfaceGui

	self:SetupShopTouchPart(shopPart)
	print("ProximitySystem: ✅ Fallback shop touch part created at spawn")
end

-- ========== SHOP TOUCH PART SETUP ==========

function ProximitySystem:SetupShopTouchPart(touchPart)
	print("ProximitySystem: Setting up shop touch part: " .. touchPart.Name)

	-- Store reference
	self.TouchParts.shop = touchPart

	-- Touch detection
	touchPart.Touched:Connect(function(hit)
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid then
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player then
				self:HandleShopTouch(player, true)
			end
		end
	end)

	-- Touch ended detection
	touchPart.TouchEnded:Connect(function(hit)
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid then
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player then
				self:HandleShopTouch(player, false)
			end
		end
	end)

	print("ProximitySystem: ✅ Shop touch part configured")
end

function ProximitySystem:HandleShopTouch(player, isTouching)
	local userId = player.UserId

	-- Initialize proximity state
	if not self.ActiveProximities[userId] then
		self.ActiveProximities[userId] = {}
	end

	local proximityState = self.ActiveProximities[userId]

	if isTouching and not proximityState.shopActive then
		-- Player entered shop area
		proximityState.shopActive = true
		print("ProximitySystem: " .. player.Name .. " entered shop area")

		-- Fire OpenShop event to client
		if self.RemoteEvents.OpenShop then
			self.RemoteEvents.OpenShop:FireClient(player)
			print("ProximitySystem: Sent OpenShop event to " .. player.Name)
		else
			warn("ProximitySystem: OpenShop remote event not found!")
		end

		-- Send notification
		if GameCore and GameCore.SendNotification then
			GameCore:SendNotification(player, "🛒 Shop Available", "Press Enter or click to open shop!", "info")
		end

	elseif not isTouching and proximityState.shopActive then
		-- Player left shop area
		proximityState.shopActive = false
		print("ProximitySystem: " .. player.Name .. " left shop area")

		-- Fire CloseShop event to client
		if self.RemoteEvents.CloseShop then
			self.RemoteEvents.CloseShop:FireClient(player)
			print("ProximitySystem: Sent CloseShop event to " .. player.Name)
		end
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
	print("=== PROXIMITY SYSTEM DEBUG ===")

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

	print("==============================")
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
				ProximitySystem:CreateFallbackShopTouchPart()

			elseif command == "/testshop" then
				-- Test shop remote directly
				if ProximitySystem.RemoteEvents.OpenShop then
					ProximitySystem.RemoteEvents.OpenShop:FireClient(player)
					print("Fired OpenShop event for " .. player.Name)
				else
					print("OpenShop remote not found!")
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

print("ProximitySystem: ✅ Proximity detection system loaded!")
print("🎯 FEATURES:")
print("  🛒 Shop touch part detection with automatic fallback")
print("  🐷 Pig feeding area detection")
print("  📡 Remote event triggering")
print("  🔧 Comprehensive debugging tools")
print("")
print("🔧 Admin Commands:")
print("  /debugproximity - Show system status")
print("  /forceshop - Manually open shop")
print("  /recreateshop - Recreate shop touch part")
print("  /testshop - Test shop remote event")

return ProximitySystem