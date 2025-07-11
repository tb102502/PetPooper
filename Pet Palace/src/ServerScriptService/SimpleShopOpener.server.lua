--[[
    FIXED SimpleShopOpener.server.lua
    Place in: ServerScriptService/SimpleShopOpener.server.lua
    
    FIXES:
    ✅ Actually fires OpenShop remote event when touched
    ✅ Proper connection to GameRemotes system
    ✅ Distance-based shop closing
    ✅ Integrated with existing module system
]]

local SimpleShopOpener = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local SHOP_POSITION = Vector3.new(-309.655, -4.488, 44.075) -- Adjust this to your shop location
local SHOP_RANGE = 15 -- How close players need to be to open shop
local CLOSE_RANGE = 25 -- How far before auto-closing shop
local CHECK_INTERVAL = 1 -- Check every 1 second

-- State tracking
local playersInShop = {}
local shopTouchPart = nil
local remoteEvents = {}

-- ========== REMOTE EVENT CONNECTIONS ==========

local function connectToRemoteEvents()
	print("🔗 SimpleShopOpener: Connecting to remote events...")

	-- Wait for GameRemotes folder
	local gameRemotes = ReplicatedStorage:WaitForChild("GameRemotes", 30)
	if not gameRemotes then
		warn("❌ SimpleShopOpener: GameRemotes folder not found!")
		return false
	end

	-- Get required remote events
	local openShopEvent = gameRemotes:WaitForChild("OpenShop", 10)
	local closeShopEvent = gameRemotes:WaitForChild("CloseShop", 10)

	if openShopEvent and closeShopEvent then
		remoteEvents.OpenShop = openShopEvent
		remoteEvents.CloseShop = closeShopEvent
		print("✅ SimpleShopOpener: Connected to shop remote events")
		return true
	else
		warn("❌ SimpleShopOpener: Required remote events not found!")
		return false
	end
end

-- ========== SHOP OPENING/CLOSING FUNCTIONS ==========

local function openShopForPlayer(player)
	if playersInShop[player.UserId] then
		return -- Already in shop
	end

	print("🛒 SimpleShopOpener: Opening shop for " .. player.Name)

	-- Mark player as in shop
	playersInShop[player.UserId] = true

	-- Fire remote event to open shop on client
	if remoteEvents.OpenShop then
		remoteEvents.OpenShop:FireClient(player)
		print("📡 SimpleShopOpener: Sent OpenShop event to " .. player.Name)
	else
		warn("❌ SimpleShopOpener: OpenShop remote event not available!")
	end
end

local function closeShopForPlayer(player)
	if not playersInShop[player.UserId] then
		return -- Not in shop
	end

	print("🚪 SimpleShopOpener: Closing shop for " .. player.Name)

	-- Remove player from shop
	playersInShop[player.UserId] = nil

	-- Fire remote event to close shop on client
	if remoteEvents.CloseShop then
		remoteEvents.CloseShop:FireClient(player)
		print("📡 SimpleShopOpener: Sent CloseShop event to " .. player.Name)
	else
		warn("❌ SimpleShopOpener: CloseShop remote event not available!")
	end
end

-- ========== SHOP TOUCH PART CREATION ==========

local function createShopTouchPart()
	print("🏗️ SimpleShopOpener: Creating shop touch part...")

	-- Remove any existing shop parts
	for _, obj in pairs(workspace:GetChildren()) do
		if obj.Name:find("ShopTouchPart") then
			obj:Destroy()
		end
	end

	-- Create new touch part
	local touchPart = Instance.new("Part")
	touchPart.Name = "SimpleShopTouchPart"
	touchPart.Size = Vector3.new(20, 4, 20) -- Large touch area
	touchPart.Position = SHOP_POSITION
	touchPart.BrickColor = BrickColor.new("Bright green")
	touchPart.Material = Enum.Material.Neon
	touchPart.Anchored = true
	touchPart.CanCollide = false
	touchPart.Transparency = 0.3
	touchPart.Parent = workspace

	-- Add visual effects
	local selectionBox = Instance.new("SelectionBox")
	selectionBox.Adornee = touchPart
	selectionBox.Color3 = Color3.fromRGB(100, 255, 100)
	selectionBox.LineThickness = 0.2
	selectionBox.Transparency = 0.5
	selectionBox.Parent = touchPart

	-- Add floating text
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(8, 0, 2, 0)
	billboard.StudsOffset = Vector3.new(0, 8, 0)
	billboard.Parent = touchPart

	local shopLabel = Instance.new("TextLabel")
	shopLabel.Size = UDim2.new(1, 0, 1, 0)
	shopLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	shopLabel.BackgroundTransparency = 0.3
	shopLabel.Text = "🛒 SHOP\nStep here to browse!"
	shopLabel.TextColor3 = Color3.new(1, 1, 1)
	shopLabel.TextScaled = true
	shopLabel.Font = Enum.Font.GothamBold
	shopLabel.TextStrokeTransparency = 0
	shopLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	shopLabel.Parent = billboard

	local labelCorner = Instance.new("UICorner")
	labelCorner.CornerRadius = UDim.new(0.2, 0)
	labelCorner.Parent = shopLabel

	-- Pulsing animation
	spawn(function()
		while touchPart and touchPart.Parent do
			local tween = TweenService:Create(touchPart,
				TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{Transparency = 0.1}
			)
			tween:Play()
			wait(4)
		end
	end)

	-- FIXED: Touch detection that actually opens the shop
	touchPart.Touched:Connect(function(hit)
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid then
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player and not playersInShop[player.UserId] then
				print("🛒 SimpleShopOpener: Player " .. player.Name .. " touched shop - opening shop")
				openShopForPlayer(player)
			end
		end
	end)

	shopTouchPart = touchPart
	print("✅ SimpleShopOpener: Shop touch part created at " .. tostring(SHOP_POSITION))
	return touchPart
end

-- ========== PROXIMITY DETECTION (BACKUP & AUTO-CLOSE) ==========

local function startProximityDetection()
	print("🔍 SimpleShopOpener: Starting proximity detection...")

	spawn(function()
		while true do
			wait(CHECK_INTERVAL)

			for _, player in pairs(Players:GetPlayers()) do
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local distance = (player.Character.HumanoidRootPart.Position - SHOP_POSITION).Magnitude

					-- Open shop if close enough and not already in shop
					if distance <= SHOP_RANGE and not playersInShop[player.UserId] then
						print("🛒 SimpleShopOpener: Player " .. player.Name .. " is near shop (" .. math.floor(distance) .. " studs) - opening shop")
						openShopForPlayer(player)
					end

					-- Close shop if too far away and currently in shop
					if distance > CLOSE_RANGE and playersInShop[player.UserId] then
						print("🚪 SimpleShopOpener: Player " .. player.Name .. " too far from shop (" .. math.floor(distance) .. " studs) - closing shop")
						closeShopForPlayer(player)
					end
				end
			end
		end
	end)
end

-- ========== CHAT COMMANDS ==========

local function setupChatCommands()
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			local command = message:lower()

			if command == "/shop" or command == "/store" then
				print("🛒 SimpleShopOpener: Manual shop open command from " .. player.Name)
				openShopForPlayer(player)

			elseif command == "/closeshop" then
				print("🚪 SimpleShopOpener: Manual shop close command from " .. player.Name)
				closeShopForPlayer(player)

			elseif command == "/shopinfo" then
				print("=== SHOP INFO FOR " .. player.Name .. " ===")
				print("Shop position: " .. tostring(SHOP_POSITION))
				print("Shop range: " .. SHOP_RANGE .. " studs")
				print("Close range: " .. CLOSE_RANGE .. " studs")
				print("Player in shop: " .. tostring(playersInShop[player.UserId] == true))

				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local distance = (player.Character.HumanoidRootPart.Position - SHOP_POSITION).Magnitude
					print("Distance to shop: " .. math.floor(distance) .. " studs")
				end

				print("Touch part exists: " .. tostring(shopTouchPart ~= nil))
				print("Remote events connected: " .. tostring(remoteEvents.OpenShop ~= nil))
				print("===============================")

			elseif command == "/testshopremote" then
				print("🧪 SimpleShopOpener: Testing shop remote for " .. player.Name)
				if remoteEvents.OpenShop then
					remoteEvents.OpenShop:FireClient(player)
					print("📡 Test OpenShop event sent")
				else
					print("❌ OpenShop remote not available")
				end
			end
		end)
	end)

	-- Connect for existing players
	for _, player in pairs(Players:GetPlayers()) do
		player.Chatted:Connect(function(message)
			local command = message:lower()

			if command == "/shop" or command == "/store" then
				openShopForPlayer(player)
			elseif command == "/closeshop" then
				closeShopForPlayer(player)
			elseif command == "/shopinfo" then
				print("=== SHOP INFO FOR " .. player.Name .. " ===")
				print("Shop position: " .. tostring(SHOP_POSITION))
				print("Shop range: " .. SHOP_RANGE .. " studs")
				print("Player in shop: " .. tostring(playersInShop[player.UserId] == true))
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local distance = (player.Character.HumanoidRootPart.Position - SHOP_POSITION).Magnitude
					print("Distance to shop: " .. math.floor(distance) .. " studs")
				end
				print("Touch part exists: " .. tostring(shopTouchPart ~= nil))
				print("Remote events connected: " .. tostring(remoteEvents.OpenShop ~= nil))
				print("===============================")
			elseif command == "/testshopremote" then
				if remoteEvents.OpenShop then
					remoteEvents.OpenShop:FireClient(player)
					print("📡 Test OpenShop event sent to " .. player.Name)
				else
					print("❌ OpenShop remote not available")
				end
			end
		end)
	end
end

-- ========== PLAYER CLEANUP ==========

local function setupPlayerCleanup()
	Players.PlayerRemoving:Connect(function(player)
		playersInShop[player.UserId] = nil
		print("🧹 SimpleShopOpener: Cleaned up shop state for " .. player.Name)
	end)
end

-- ========== INITIALIZATION ==========

local function initialize()
	print("🚀 SimpleShopOpener: Starting FIXED initialization...")

	-- Wait a bit for the game to load
	wait(3) -- Increased wait time for GameCore to setup remotes

	-- Step 1: Connect to remote events first
	local remoteSuccess = connectToRemoteEvents()
	if not remoteSuccess then
		warn("❌ SimpleShopOpener: Failed to connect to remote events - retrying in 5 seconds...")
		wait(5)
		remoteSuccess = connectToRemoteEvents()
		if not remoteSuccess then
			error("❌ SimpleShopOpener: Cannot function without remote events!")
		end
	end

	-- Step 2: Setup other systems
	setupChatCommands()
	setupPlayerCleanup()
	createShopTouchPart()
	startProximityDetection()

	-- Global reference
	_G.SimpleShopOpener = SimpleShopOpener

	print("✅ SimpleShopOpener: FIXED initialization complete!")
	print("🛒 Shop available at position: " .. tostring(SHOP_POSITION))
	print("📱 Chat commands: /shop, /closeshop, /shopinfo, /testshopremote")
	print("🎯 Walk to the green glowing area to open shop automatically!")
end

-- ========== DEBUG FUNCTIONS ==========

function SimpleShopOpener:DebugStatus()
	print("=== SIMPLE SHOP OPENER DEBUG ===")
	print("Remote events connected: " .. tostring(remoteEvents.OpenShop ~= nil))
	print("Touch part exists: " .. tostring(shopTouchPart ~= nil))
	print("Players in shop: " .. (function()
		local count = 0
		for _ in pairs(playersInShop) do count = count + 1 end
		return count
	end)())
	print("Shop position: " .. tostring(SHOP_POSITION))
	print("Shop range: " .. SHOP_RANGE .. " studs")
	print("================================")
end

-- Global debug access
_G.DebugShopOpener = function()
	if _G.SimpleShopOpener then
		_G.SimpleShopOpener:DebugStatus()
	end
end

-- Start the system
initialize()

return SimpleShopOpener