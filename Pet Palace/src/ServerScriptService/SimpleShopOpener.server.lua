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

local function createWorkingShop(player)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return false end

	print("🛒 Creating working shop for", player.Name)

	-- Remove old shop UI
	local oldShop = playerGui:FindFirstChild("WorkingShopUI")
	if oldShop then oldShop:Destroy() end

	-- Create new working shop
	local shopUI = Instance.new("ScreenGui")
	shopUI.Name = "WorkingShopUI"
	shopUI.Parent = playerGui

	local shopFrame = Instance.new("Frame")
	shopFrame.Size = UDim2.new(0.9, 0, 0.9, 0)
	shopFrame.Position = UDim2.new(0.05, 0, 0.05, 0)
	shopFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	shopFrame.BorderSizePixel = 0
	shopFrame.Parent = shopUI

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.02, 0)
	corner.Parent = shopFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.8, 0, 0.1, 0)
	title.Position = UDim2.new(0.1, 0, 0.02, 0)
	title.BackgroundTransparency = 1
	title.Text = "🛒 Pet Palace Market"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = shopFrame

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0.08, 0, 0.08, 0)
	closeButton.Position = UDim2.new(0.9, 0, 0.02, 0)
	closeButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.GothamBold
	closeButton.BorderSizePixel = 0
	closeButton.Parent = shopFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0.5, 0)
	closeCorner.Parent = closeButton

	-- Shop content area
	local contentArea = Instance.new("ScrollingFrame")
	contentArea.Size = UDim2.new(0.95, 0, 0.85, 0)
	contentArea.Position = UDim2.new(0.025, 0, 0.13, 0)
	contentArea.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	contentArea.BorderSizePixel = 0
	contentArea.ScrollBarThickness = 10
	contentArea.Parent = shopFrame

	local contentCorner = Instance.new("UICorner")
	contentCorner.CornerRadius = UDim.new(0.02, 0)
	contentCorner.Parent = contentArea

	-- Shop items
	local items = {
		{name = "🌱 Carrot Seeds", price = "5 💰", desc = "Plant these to grow delicious carrots", color = Color3.fromRGB(100, 200, 100)},
		{name = "🥔 Potato Seeds", price = "25 💰", desc = "Hearty potatoes for your farm", color = Color3.fromRGB(139, 90, 43)},
		{name = "🥬 Cabbage Seeds", price = "50 💰", desc = "Fresh green cabbages", color = Color3.fromRGB(100, 200, 100)},
		{name = "🌾 Farm Plot Starter", price = "100 💰", desc = "Create your first farm plot", color = Color3.fromRGB(80, 120, 60)},
		{name = "⛏️ Basic Pickaxe", price = "50 💰", desc = "Start mining with this tool", color = Color3.fromRGB(150, 150, 150)},
		{name = "🔨 Basic Workbench", price = "200 💰", desc = "Craft amazing items", color = Color3.fromRGB(200, 120, 80)},
		{name = "🐄 Basic Cow", price = "500 💰", desc = "Start your livestock collection", color = Color3.fromRGB(160, 120, 80)},
		{name = "✨ Premium Package", price = "1000 💰", desc = "Exclusive premium items bundle", color = Color3.fromRGB(255, 215, 0)}
	}

	for i, item in ipairs(items) do
		local itemFrame = Instance.new("Frame")
		itemFrame.Size = UDim2.new(1, -20, 0, 100)
		itemFrame.Position = UDim2.new(0, 10, 0, (i-1) * 110)
		itemFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
		itemFrame.BorderSizePixel = 0
		itemFrame.Parent = contentArea

		local itemCorner = Instance.new("UICorner")
		itemCorner.CornerRadius = UDim.new(0.05, 0)
		itemCorner.Parent = itemFrame

		-- Category indicator
		local indicator = Instance.new("Frame")
		indicator.Size = UDim2.new(0.02, 0, 1, 0)
		indicator.Position = UDim2.new(0, 0, 0, 0)
		indicator.BackgroundColor3 = item.color
		indicator.BorderSizePixel = 0
		indicator.Parent = itemFrame

		local indicatorCorner = Instance.new("UICorner")
		indicatorCorner.CornerRadius = UDim.new(0.5, 0)
		indicatorCorner.Parent = indicator

		-- Item name
		local itemName = Instance.new("TextLabel")
		itemName.Size = UDim2.new(0.45, 0, 0.5, 0)
		itemName.Position = UDim2.new(0.05, 0, 0.1, 0)
		itemName.BackgroundTransparency = 1
		itemName.Text = item.name
		itemName.TextColor3 = Color3.new(1, 1, 1)
		itemName.TextScaled = true
		itemName.Font = Enum.Font.GothamBold
		itemName.TextXAlignment = Enum.TextXAlignment.Left
		itemName.Parent = itemFrame

		-- Item description
		local itemDesc = Instance.new("TextLabel")
		itemDesc.Size = UDim2.new(0.45, 0, 0.4, 0)
		itemDesc.Position = UDim2.new(0.05, 0, 0.55, 0)
		itemDesc.BackgroundTransparency = 1
		itemDesc.Text = item.desc
		itemDesc.TextColor3 = Color3.fromRGB(200, 200, 200)
		itemDesc.TextScaled = true
		itemDesc.Font = Enum.Font.Gotham
		itemDesc.TextXAlignment = Enum.TextXAlignment.Left
		itemDesc.TextWrapped = true
		itemDesc.Parent = itemFrame

		-- Price
		local itemPrice = Instance.new("TextLabel")
		itemPrice.Size = UDim2.new(0.2, 0, 0.4, 0)
		itemPrice.Position = UDim2.new(0.55, 0, 0.3, 0)
		itemPrice.BackgroundTransparency = 1
		itemPrice.Text = item.price
		itemPrice.TextColor3 = Color3.fromRGB(255, 215, 0)
		itemPrice.TextScaled = true
		itemPrice.Font = Enum.Font.GothamBold
		itemPrice.Parent = itemFrame

		-- Buy button
		local buyButton = Instance.new("TextButton")
		buyButton.Size = UDim2.new(0.15, 0, 0.6, 0)
		buyButton.Position = UDim2.new(0.8, 0, 0.2, 0)
		buyButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
		buyButton.Text = "BUY"
		buyButton.TextColor3 = Color3.new(1, 1, 1)
		buyButton.TextScaled = true
		buyButton.Font = Enum.Font.GothamBold
		buyButton.BorderSizePixel = 0
		buyButton.Parent = itemFrame

		local buyCorner = Instance.new("UICorner")
		buyCorner.CornerRadius = UDim.new(0.15, 0)
		buyCorner.Parent = buyButton

		-- Purchase functionality
		buyButton.MouseButton1Click:Connect(function()
			local confirmFrame = Instance.new("Frame")
			confirmFrame.Size = UDim2.new(0.4, 0, 0.2, 0)
			confirmFrame.Position = UDim2.new(0.3, 0, 0.4, 0)
			confirmFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			confirmFrame.BorderSizePixel = 0
			confirmFrame.Parent = shopUI

			local confirmCorner = Instance.new("UICorner")
			confirmCorner.CornerRadius = UDim.new(0.05, 0)
			confirmCorner.Parent = confirmFrame

			local confirmText = Instance.new("TextLabel")
			confirmText.Size = UDim2.new(1, 0, 0.6, 0)
			confirmText.Position = UDim2.new(0, 0, 0.1, 0)
			confirmText.BackgroundTransparency = 1
			confirmText.Text = "Purchase " .. item.name .. " for " .. item.price .. "?"
			confirmText.TextColor3 = Color3.new(1, 1, 1)
			confirmText.TextScaled = true
			confirmText.Font = Enum.Font.Gotham
			confirmText.TextWrapped = true
			confirmText.Parent = confirmFrame

			local confirmYes = Instance.new("TextButton")
			confirmYes.Size = UDim2.new(0.4, 0, 0.25, 0)
			confirmYes.Position = UDim2.new(0.05, 0, 0.7, 0)
			confirmYes.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
			confirmYes.Text = "YES"
			confirmYes.TextScaled = true
			confirmYes.BorderSizePixel = 0
			confirmYes.Parent = confirmFrame

			local confirmNo = Instance.new("TextButton")
			confirmNo.Size = UDim2.new(0.4, 0, 0.25, 0)
			confirmNo.Position = UDim2.new(0.55, 0, 0.7, 0)
			confirmNo.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
			confirmNo.Text = "NO"
			confirmNo.TextScaled = true
			confirmNo.BorderSizePixel = 0
			confirmNo.Parent = confirmFrame

			confirmYes.MouseButton1Click:Connect(function()
				print("✅", player.Name, "purchased", item.name)
				confirmFrame:Destroy()

				-- Show purchase success
				local successFrame = Instance.new("Frame")
				successFrame.Size = UDim2.new(0.3, 0, 0.15, 0)
				successFrame.Position = UDim2.new(0.35, 0, 0.425, 0)
				successFrame.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
				successFrame.BorderSizePixel = 0
				successFrame.Parent = shopUI

				local successCorner = Instance.new("UICorner")
				successCorner.CornerRadius = UDim.new(0.1, 0)
				successCorner.Parent = successFrame

				local successText = Instance.new("TextLabel")
				successText.Size = UDim2.new(1, 0, 1, 0)
				successText.BackgroundTransparency = 1
				successText.Text = "✅ Purchase Successful!"
				successText.TextColor3 = Color3.new(1, 1, 1)
				successText.TextScaled = true
				successText.Font = Enum.Font.GothamBold
				successText.Parent = successFrame

				-- Auto-remove success message
				spawn(function()
					wait(2)
					if successFrame and successFrame.Parent then
						successFrame:Destroy()
					end
				end)
			end)

			confirmNo.MouseButton1Click:Connect(function()
				confirmFrame:Destroy()
			end)
		end)
	end

	-- Set canvas size
	contentArea.CanvasSize = UDim2.new(0, 0, 0, #items * 110)

	-- Close functionality
	closeButton.MouseButton1Click:Connect(function()
		shopUI:Destroy()
		playersInShop[player.UserId] = nil
		print("🚪", player.Name, "closed shop")
	end)

	-- Mark player as having shop open
	playersInShop[player.UserId] = true

	print("✅ Working shop created for", player.Name)
	return true
end

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
				createWorkingShop(player)
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
						createWorkingShop(player)
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
				createWorkingShop(player)
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
				createWorkingShop(player)
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
	_G.CreateWorkingShop = createWorkingShop

	print("✅ SimpleShopOpener: Initialization complete!")
	print("🛒 Shop available at position:", SHOP_POSITION)
	print("📱 Chat commands: /shop, /closeshop, /shopinfo")
	print("🎯 Walk to the green glowing area to open shop automatically!")
end

-- Start the system
initialize()

return SimpleShopOpener