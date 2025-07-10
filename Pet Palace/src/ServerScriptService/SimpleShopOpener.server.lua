--[[
    SimpleShopOpener.server.lua
    Place in: ServerScriptService/SimpleShopOpener.server.lua
    
    A clean, simple shop opener that just works!
]]

local SimpleShopOpener = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Configuration
local SHOP_POSITION = Vector3.new(-309.655, -4.488, 44.075) -- Adjust this to your shop location
local SHOP_RANGE = 15 -- How close players need to be to open shop
local CHECK_INTERVAL = 1 -- Check every 1 second

-- State tracking
local playersInShop = {}
local shopTouchPart = nil

-- ========== WORKING SHOP CREATION ==========

-- ========== SHOP TOUCH PART CREATION ==========

local function createShopTouchPart()
	print("🏗️ Creating shop touch part...")

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

	-- Touch detection
	touchPart.Touched:Connect(function(hit)
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid then
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player and not playersInShop[player.UserId] then
				print("🛒 Player", player.Name, "touched shop - opening shop")
				
			end
		end
	end)

	shopTouchPart = touchPart
	print("✅ Shop touch part created at", SHOP_POSITION)
	return touchPart
end

-- ========== PROXIMITY DETECTION (BACKUP) ==========

local function startProximityDetection()
	print("🔍 Starting proximity detection...")

	spawn(function()
		while true do
			wait(CHECK_INTERVAL)

			for _, player in pairs(Players:GetPlayers()) do
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local distance = (player.Character.HumanoidRootPart.Position - SHOP_POSITION).Magnitude

					if distance <= SHOP_RANGE and not playersInShop[player.UserId] then
						print("🛒 Player", player.Name, "is near shop (", math.floor(distance), "studs) - opening shop")
						
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
			elseif command == "/closeshop" then
				local playerGui = player:FindFirstChild("PlayerGui")
				if playerGui then
					local shopUI = playerGui:FindFirstChild("WorkingShopUI")
					if shopUI then
						shopUI:Destroy()
						playersInShop[player.UserId] = nil
						print("🚪", player.Name, "closed shop via command")
					end
				end
			elseif command == "/shopinfo" then
				print("=== SHOP INFO FOR", player.Name, "===")
				print("Shop position:", SHOP_POSITION)
				print("Shop range:", SHOP_RANGE, "studs")
				print("Player in shop:", playersInShop[player.UserId] == true)
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local distance = (player.Character.HumanoidRootPart.Position - SHOP_POSITION).Magnitude
					print("Distance to shop:", math.floor(distance), "studs")
				end
				print("Touch part exists:", shopTouchPart ~= nil)
				print("===============================")
			end
		end)
	end)

	-- Connect for existing players
	for _, player in pairs(Players:GetPlayers()) do
		player.Chatted:Connect(function(message)
			local command = message:lower()

			if command == "/shop" or command == "/store" then
			elseif command == "/closeshop" then
				local playerGui = player:FindFirstChild("PlayerGui")
				if playerGui then
					local shopUI = playerGui:FindFirstChild("WorkingShopUI")
					if shopUI then
						shopUI:Destroy()
						playersInShop[player.UserId] = nil
						print("🚪", player.Name, "closed shop via command")
					end
				end
			elseif command == "/shopinfo" then
				print("=== SHOP INFO FOR", player.Name, "===")
				print("Shop position:", SHOP_POSITION)
				print("Shop range:", SHOP_RANGE, "studs")
				print("Player in shop:", playersInShop[player.UserId] == true)
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local distance = (player.Character.HumanoidRootPart.Position - SHOP_POSITION).Magnitude
					print("Distance to shop:", math.floor(distance), "studs")
				end
				print("Touch part exists:", shopTouchPart ~= nil)
				print("===============================")
			end
		end)
	end
end

-- ========== PLAYER CLEANUP ==========

local function setupPlayerCleanup()
	Players.PlayerRemoving:Connect(function(player)
		playersInShop[player.UserId] = nil
	end)
end

-- ========== INITIALIZATION ==========

local function initialize()
	print("🚀 SimpleShopOpener: Starting initialization...")

	-- Wait a bit for the game to load
	wait(2)

	-- Setup systems
	setupChatCommands()
	setupPlayerCleanup()
	createShopTouchPart()
	startProximityDetection() -- Backup proximity system

	-- Global reference
	_G.SimpleShopOpener = SimpleShopOpener


	print("✅ SimpleShopOpener: Initialization complete!")
	print("🛒 Shop available at position:", SHOP_POSITION)
	print("📱 Chat commands: /shop, /closeshop, /shopinfo")
	print("🎯 Walk to the green glowing area to open shop automatically!")
end

-- Start the system
initialize()

return SimpleShopOpener