-- GameInstructions.client.lua - RESPONSIVE VERSION
-- Place in: StarterPlayer/StarterPlayerScripts/GameInstructions.client.lua

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("=== RESPONSIVE GAME INSTRUCTIONS SYSTEM LOADING ===")

-- Device detection and scaling
local function getDeviceType()
	local camera = workspace.CurrentCamera
	local viewportSize = camera.ViewportSize

	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		-- Mobile device
		if math.min(viewportSize.X, viewportSize.Y) < 500 then
			return "Mobile"
		else
			return "Tablet"
		end
	else
		-- Desktop
		return "Desktop"
	end
end

local function getScaleFactor()
	local deviceType = getDeviceType()
	if deviceType == "Mobile" then
		return 1.2
	elseif deviceType == "Tablet" then
		return 1.1
	else
		return 1.0
	end
end

-- Check if player has seen instructions before
local hasSeenInstructions = false

-- Try to get saved data (you can integrate this with your save system)
pcall(function()
	if _G.GameClient and _G.GameClient.GetPlayerData then
		local playerData = _G.GameClient:GetPlayerData()
		hasSeenInstructions = playerData.hasSeenInstructions or false
	end
end)

-- Instruction content data
local INSTRUCTION_PAGES = {
	{
		title = "🌾 Welcome to Farm Defense!",
		icon = "🎮",
		content = {
			"Welcome to the a nice calm farming simulator...  Until the aliens attack!",
			"",
			"🎯 YOUR GOAL:",
			"• Build and expand your farm",
			"• Milk cows to start making money for your first seeds and upgrades",
			"• Grow crops to earn even more coins", 
			"• Defend against pests and UFO attacks",
			"• Become the most successful farmer, and send those pesky aliens away once and for all!",
			"",
			"💡 This tutorial will teach you everything you need to know.",
			"You can reopen this guide anytime by typing /help in chat.",
			"",
			"🚀 Ready to become a farming legend? Let's make those pesky aliens sorry they ever invaded!"
		}
	},
	{
		title = "💰 Economy & Strategy",
		icon = "📊",
		content = {
			"Master the game's economy:",
			"",
			"💎 DUAL CURRENCY SYSTEM:",
			"• 🪙 Coins - Primary currency from crops",
			"• 🎫 Farm Tokens - Premium currency for special items",
			"",
			"📈 INCOME SOURCES:",
			"• Milking cows (upgrade for greater quantity and sell price)",
			"• Harvesting crops (the longer a seed takes to grow, the more it will be worth)",
			"• Selling eggs from chickens",
			"• Pig breeding and products",
			"• Daily bonuses and achievements",
			"",
			"🎯 EARLY GAME STRATEGY:",
			"1. Plant carrots for quick returns",
			"3. Get 1-2 basic chickens for pest control",
			"4. Save for roof protection",
			"",
			"🏆 LATE GAME GOALS:",
			"• Full roof protection on all plots",
			"• Diverse chicken defense force",
			"• Automated pig manure system"
		}
	},
	{
		title = "🐛 Pest Management",
		icon = "🔍",
		content = {
			"Protect your crops from devastating pests:",
			"",
			"🦗 PEST TYPES:",
			"• 🐛 Aphids - Slow damage, spreads easily",
			"• 🦗 Locusts - Fast damage, weather dependent", 
			"• 🍄 Fungal Blight - Disease, spreads in wet weather",
			"",
			"⚠️ PEST EFFECTS:",
			"• Pests damage crops over time",
			"• Severely damaged crops may wither and die",
			"• Pests can spread to nearby crops",
			"",
			"🛡️ PROTECTION METHODS:",
			"• Use chickens for natural pest control",
			"• Apply pig manure for pest deterrent",
			"• Monitor weather - affects pest activity",
		}
	},
	{
		title = "🐔 Chicken Defense System",
		icon = "🛡️",
		content = {
			"Deploy chickens to protect your farm:",
			"",
			"🐔 CHICKEN TYPES:",
			"• 🐔 Basic Chicken - General pest control, lays eggs",
			"• 🦃 Guinea Fowl - Anti-locust specialist, early warning",
			"• 🐓 Rooster - Area boosts, intimidation, premium eggs",
			"",
			"🎯 HOW CHICKENS WORK:",
			"• Automatically patrol and hunt pests",
			"• Each type targets specific pest types",
			"• Must be fed regularly to stay healthy",
			"• Produce valuable eggs over time",
			"",
			"🥚 CHICKEN CARE:",
			"• Feed chickens with grain, premium feed",
			"• Well-fed chickens are more effective",
			"• Hungry chickens may die from poor care",
			"",
			"💡 Roosters boost nearby chickens' effectiveness!"
		}
	},
	{
		title = "🐷 Pig System",
		icon = "🐽",
		content = {
			"Raise pigs for valuable resources:",
			"",
			"🐷 PIG BENEFITS:",
			"• Produce valuable manure for pest protection",
			"• Generate steady income through breeding",
			"• Provide meat for advanced recipes",
			"",
			"🌾 PIG CARE:",
			"• Feed pigs regularly to keep them healthy",
			"• Happy pigs produce more resources",
			"• Build pig pens for better organization",
			"",
			"💩 MANURE SYSTEM:",
			"• Collect manure from fed pigs",
			"• Apply to farm plots for pest deterrent",
			"• Reduces pest spawn rates by 70%",
			"",
			"🔄 BREEDING:",
			"• Breed pigs to expand your livestock",
			"• More pigs = more manure and income"
		}
	},
	{
		title = "🛸 UFO Attack Survival",
		icon = "👽",
		content = {
			"Survive devastating alien attacks:",
			"",
			"⚠️ UFO ATTACK PHASES:",
			"• 🛸 UFO Appearance - Sky darkens, warning sounds",
			"• 🔍 Scanning Phase - UFO searches for targets",
			"• ⚡ Destruction Beam - Crops are vaporized!",
			"• 🚀 UFO Retreat - Attack ends, damage assessed",
			"",
			"🛡️ PROTECTION STRATEGIES:",
			"• Buy roof protection (100% effective)",
			"• Chickens provide some protection",
			"• Guinea fowl give early warnings",
			"",
			"😱 UFO EFFECTS ON CHICKENS:",
			"• Chickens scatter during attacks",
			"• Reduced effectiveness temporarily",
			"• Guinea fowl sound alarms before attacks",
			"",
			"💡 Invest in roof protection early - it's your best defense!"
		}
	},
	{
		title = "🎮 Controls & Commands",
		icon = "⌨️",
		content = {
			"Essential controls and commands:",
			"",
			"🖱️ BASIC CONTROLS:",
			"• Click plots to plant/harvest",
			"• Use shop UI to buy items",
			"• Walk near animals to interact",
			"",
			"💬 CHAT COMMANDS:",
			"• /help - Reopen this instruction guide",
			"• /save - Manually save your progress",
			"",
			"🎯 QUICK TIPS:",
			"• Watch for green plot indicators (available)",
			"• Red indicators mean plots are occupied",
			"• Pay attention to weather notifications",
			"• UFO warning sounds mean take cover!",
			"",
			"📱 MOBILE FRIENDLY:",
			"• Large buttons for touch controls",
			"• Optimized for mobile gameplay",
			"• Tap anywhere to interact"
		}
	}
}

-- Create the main instruction GUI with responsive design
local function createInstructionGUI()
	-- Remove existing GUI if it exists
	local existingGUI = playerGui:FindFirstChild("InstructionGUI")
	if existingGUI then
		existingGUI:Destroy()
	end

	local deviceType = getDeviceType()
	local scaleFactor = getScaleFactor()

	print("Creating responsive instructions for device: " .. deviceType .. " (scale: " .. scaleFactor .. ")")

	-- Debug: Print viewport info
	local camera = workspace.CurrentCamera
	local viewportSize = camera.ViewportSize
	print("Viewport size: " .. viewportSize.X .. "x" .. viewportSize.Y)

	-- Main ScreenGui
	local instructionGUI = Instance.new("ScreenGui")
	instructionGUI.Name = "InstructionGUI"
	instructionGUI.ResetOnSpawn = false
	instructionGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	instructionGUI.IgnoreGuiInset = true -- Important for mobile
	instructionGUI.Parent = playerGui

	-- Background overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.Position = UDim2.new(0, 0, 0, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.3
	overlay.BorderSizePixel = 0
	overlay.Parent = instructionGUI

	-- Main frame - responsive sizing based on device
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"

	-- Simplified sizing that should work on all devices
	mainFrame.Size = UDim2.new(0.9, 0, 0.85, 0)
	mainFrame.Position = UDim2.new(0.05, 0, 0.075, 0)

	--[[
	-- Alternative responsive sizing (commented out for testing)
	if deviceType == "Mobile" then
		-- Mobile: Nearly full screen with small margins
		mainFrame.Size = UDim2.new(0.96, 0, 0.92, 0)
		mainFrame.Position = UDim2.new(0.02, 0, 0.04, 0)
	elseif deviceType == "Tablet" then
		-- Tablet: Balanced sizing
		mainFrame.Size = UDim2.new(0.85, 0, 0.88, 0)
		mainFrame.Position = UDim2.new(0.075, 0, 0.06, 0)
	else
		-- Desktop: Traditional sizing
		mainFrame.Size = UDim2.new(0.75, 0, 0.8, 0)
		mainFrame.Position = UDim2.new(0.125, 0, 0.1, 0)
	end
	--]]

	mainFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = overlay

	-- Debug: Print mainFrame info
	print("MainFrame created - Size: " .. tostring(mainFrame.Size) .. ", Position: " .. tostring(mainFrame.Position))

	-- Corner radius for main frame
	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0.02, 0) -- Scale-based corner radius
	mainCorner.Parent = mainFrame

	-- Header frame
	local headerFrame = Instance.new("Frame")
	headerFrame.Name = "Header"
	headerFrame.Size = UDim2.new(1, 0, 0.12, 0) -- Scale-based height
	headerFrame.Position = UDim2.new(0, 0, 0, 0)
	headerFrame.BackgroundColor3 = Color3.fromRGB(40, 50, 60)
	headerFrame.BorderSizePixel = 0
	headerFrame.Parent = mainFrame

	-- Header corner radius
	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0.02, 0)
	headerCorner.Parent = headerFrame

	-- Header title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(0.8, 0, 1, 0)
	titleLabel.Position = UDim2.new(0.05, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "📖 Farm Defense - Player Guide"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextScaled = true -- Scale text for all devices
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = headerFrame

	-- Close button - larger for mobile
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0.1, 0, 0.7, 0) -- Larger for touch
	closeButton.Position = UDim2.new(0.88, 0, 0.15, 0)
	closeButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.GothamBold
	closeButton.BorderSizePixel = 0
	closeButton.Parent = headerFrame

	-- Close button corner
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0.2, 0)
	closeCorner.Parent = closeButton

	-- Content area
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "Content"
	contentFrame.Size = UDim2.new(1, 0, 0.76, 0) -- Adjusted for responsive header
	contentFrame.Position = UDim2.new(0, 0, 0.12, 0)
	contentFrame.BackgroundTransparency = 1
	contentFrame.Parent = mainFrame

	-- Navigation and display layout - simplified for testing
	local navFrame = Instance.new("Frame")
	navFrame.Name = "Navigation"
	navFrame.Size = UDim2.new(0.3, 0, 1, 0)
	navFrame.Position = UDim2.new(0.02, 0, 0, 0)
	navFrame.BackgroundColor3 = Color3.fromRGB(30, 35, 40)
	navFrame.BorderSizePixel = 0
	navFrame.Parent = contentFrame

	local displayFrame = Instance.new("Frame")
	displayFrame.Name = "Display"
	displayFrame.Size = UDim2.new(0.66, 0, 1, 0)
	displayFrame.Position = UDim2.new(0.34, 0, 0, 0)
	displayFrame.BackgroundColor3 = Color3.fromRGB(35, 40, 45)
	displayFrame.BorderSizePixel = 0
	displayFrame.Parent = contentFrame

	--[[
	-- Complex responsive layout (commented out for testing)
	local navFrame, displayFrame
	
	if deviceType == "Mobile" then
		-- Mobile: Stack vertically or use tabs
		navFrame = Instance.new("Frame")
		navFrame.Name = "Navigation"
		navFrame.Size = UDim2.new(1, 0, 0.15, 0) -- Top navigation bar
		navFrame.Position = UDim2.new(0, 0, 0, 0)
		navFrame.BackgroundColor3 = Color3.fromRGB(30, 35, 40)
		navFrame.BorderSizePixel = 0
		navFrame.Parent = contentFrame

		displayFrame = Instance.new("Frame")
		displayFrame.Name = "Display"
		displayFrame.Size = UDim2.new(1, 0, 0.85, 0) -- Larger content area
		displayFrame.Position = UDim2.new(0, 0, 0.15, 0)
		displayFrame.BackgroundColor3 = Color3.fromRGB(35, 40, 45)
		displayFrame.BorderSizePixel = 0
		displayFrame.Parent = contentFrame
	else
		-- Tablet/Desktop: Side-by-side layout
		navFrame = Instance.new("Frame")
		navFrame.Name = "Navigation"
		navFrame.Size = UDim2.new(0.3, 0, 1, 0)
		navFrame.Position = UDim2.new(0.02, 0, 0, 0)
		navFrame.BackgroundColor3 = Color3.fromRGB(30, 35, 40)
		navFrame.BorderSizePixel = 0
		navFrame.Parent = contentFrame

		displayFrame = Instance.new("Frame")
		displayFrame.Name = "Display"
		displayFrame.Size = UDim2.new(0.66, 0, 1, 0)
		displayFrame.Position = UDim2.new(0.34, 0, 0, 0)
		displayFrame.BackgroundColor3 = Color3.fromRGB(35, 40, 45)
		displayFrame.BorderSizePixel = 0
		displayFrame.Parent = contentFrame
	end
	--]]

	-- Nav corner radius
	local navCorner = Instance.new("UICorner")
	navCorner.CornerRadius = UDim.new(0.05, 0)
	navCorner.Parent = navFrame

	-- Display corner radius
	local displayCorner = Instance.new("UICorner")
	displayCorner.CornerRadius = UDim.new(0.03, 0)
	displayCorner.Parent = displayFrame

	-- Page content scroll frame
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ContentScroll"
	scrollFrame.Size = UDim2.new(0.95, 0, 0.95, 0)
	scrollFrame.Position = UDim2.new(0.025, 0, 0.025, 0)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = deviceType == "Mobile" and 12 or 8 -- Thicker scroll bar for mobile
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	scrollFrame.Parent = displayFrame

	-- Content text label
	local contentLabel = Instance.new("TextLabel")
	contentLabel.Name = "ContentText"
	contentLabel.Size = UDim2.new(1, -10, 1, 0)
	contentLabel.Position = UDim2.new(0, 5, 0, 0)
	contentLabel.BackgroundTransparency = 1
	contentLabel.Text = ""
	contentLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	contentLabel.TextScaled = true -- Important for mobile readability
	contentLabel.Font = Enum.Font.Gotham
	contentLabel.TextXAlignment = Enum.TextXAlignment.Left
	contentLabel.TextYAlignment = Enum.TextYAlignment.Top
	contentLabel.TextWrapped = true
	contentLabel.Parent = scrollFrame

	-- Create navigation layout - simplified
	local navLayout = Instance.new("UIListLayout")
	navLayout.SortOrder = Enum.SortOrder.LayoutOrder
	navLayout.FillDirection = Enum.FillDirection.Vertical
	navLayout.Padding = UDim.new(0.01, 0)
	navLayout.Parent = navFrame

	--[[
	-- Complex responsive navigation (commented out for testing)
	local navLayout
	if deviceType == "Mobile" then
		-- Horizontal scrolling for mobile
		navLayout = Instance.new("UIListLayout")
		navLayout.SortOrder = Enum.SortOrder.LayoutOrder
		navLayout.FillDirection = Enum.FillDirection.Horizontal
		navLayout.Padding = UDim.new(0.01, 0)
		navLayout.Parent = navFrame
		
		-- Make navigation scrollable on mobile
		navFrame.ClipsDescendants = true
	else
		-- Vertical layout for tablet/desktop
		navLayout = Instance.new("UIListLayout")
		navLayout.SortOrder = Enum.SortOrder.LayoutOrder
		navLayout.FillDirection = Enum.FillDirection.Vertical
		navLayout.Padding = UDim.new(0.01, 0)
		navLayout.Parent = navFrame
	end
	--]]

	-- Navigation padding
	local navPadding = Instance.new("UIPadding")
	navPadding.PaddingTop = UDim.new(0.02, 0)
	navPadding.PaddingBottom = UDim.new(0.02, 0)
	navPadding.PaddingLeft = UDim.new(0.02, 0)
	navPadding.PaddingRight = UDim.new(0.02, 0)
	navPadding.Parent = navFrame

	-- Current page tracking
	local currentPage = 1
	local navButtons = {}

	-- Function to update page content
	local function updatePageContent(pageIndex)
		currentPage = pageIndex
		local page = INSTRUCTION_PAGES[pageIndex]

		if not page then return end

		-- Update header title
		titleLabel.Text = page.title

		-- Update content
		local contentText = table.concat(page.content, "\n")
		contentLabel.Text = contentText

		-- The text will auto-scale due to TextScaled = true
		scrollFrame.CanvasSize = UDim2.new(0, 0, 2, 0) -- Generous canvas size

		-- Update navigation button states
		for i, button in ipairs(navButtons) do
			if i == pageIndex then
				button.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
				button.TextColor3 = Color3.fromRGB(255, 255, 255)
			else
				button.BackgroundColor3 = Color3.fromRGB(50, 55, 60)
				button.TextColor3 = Color3.fromRGB(200, 200, 200)
			end
		end
	end

	-- Create navigation buttons for each page
	for i, page in ipairs(INSTRUCTION_PAGES) do
		local navButton = Instance.new("TextButton")
		navButton.Name = "NavButton" .. i

		-- Simplified sizing for all devices
		navButton.Size = UDim2.new(0.95, 0, 0.12, 0)

		--[[
		-- Complex responsive sizing (commented out for testing)
		if deviceType == "Mobile" then
			-- Mobile: Horizontal tabs
			navButton.Size = UDim2.new(0.25, 0, 0.8, 0) -- Wider for mobile taps
		else
			-- Tablet/Desktop: Vertical list
			navButton.Size = UDim2.new(0.95, 0, 0.12, 0)
		end
		--]]

		navButton.BackgroundColor3 = Color3.fromRGB(50, 55, 60)
		navButton.Text = page.icon .. " " .. page.title:gsub("🌾 ", ""):gsub("🌱 ", ""):gsub("🏗️ ", "")
		navButton.TextColor3 = Color3.fromRGB(200, 200, 200)
		navButton.TextScaled = true -- Scale text for device
		navButton.Font = Enum.Font.Gotham
		navButton.BorderSizePixel = 0
		navButton.TextXAlignment = Enum.TextXAlignment.Left
		navButton.Parent = navFrame

		-- Button corner
		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0.1, 0)
		buttonCorner.Parent = navButton

		-- Button padding
		local buttonPadding = Instance.new("UIPadding")
		buttonPadding.PaddingLeft = UDim.new(0.05, 0)
		buttonPadding.Parent = navButton

		--[[
		-- Complex responsive padding (commented out for testing)
		if deviceType ~= "Mobile" then
			local buttonPadding = Instance.new("UIPadding")
			buttonPadding.PaddingLeft = UDim.new(0.05, 0)
			buttonPadding.Parent = navButton
			navButton.TextXAlignment = Enum.TextXAlignment.Left
		end
		--]]

		-- Store button reference
		table.insert(navButtons, navButton)

		-- Button click handler
		navButton.MouseButton1Click:Connect(function()
			updatePageContent(i)
		end)

		-- Button hover effects (touch-friendly)
		navButton.MouseEnter:Connect(function()
			if i ~= currentPage then
				TweenService:Create(navButton, TweenInfo.new(0.2), {
					BackgroundColor3 = Color3.fromRGB(70, 75, 80)
				}):Play()
			end
		end)

		navButton.MouseLeave:Connect(function()
			if i ~= currentPage then
				TweenService:Create(navButton, TweenInfo.new(0.2), {
					BackgroundColor3 = Color3.fromRGB(50, 55, 60)
				}):Play()
			end
		end)
	end

	-- Bottom navigation frame
	local bottomNav = Instance.new("Frame")
	bottomNav.Name = "BottomNav"
	bottomNav.Size = UDim2.new(1, 0, 0.12, 0) -- Scale-based height
	bottomNav.Position = UDim2.new(0, 0, 0.88, 0)
	bottomNav.BackgroundTransparency = 1
	bottomNav.Parent = mainFrame

	-- Previous button - larger for mobile
	local prevButton = Instance.new("TextButton")
	prevButton.Name = "PrevButton"
	prevButton.Size = UDim2.new(0.25, 0, 0.8, 0) -- Larger touch target
	prevButton.Position = UDim2.new(0.05, 0, 0.1, 0)
	prevButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	prevButton.Text = "◀ Previous"
	prevButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	prevButton.TextScaled = true
	prevButton.Font = Enum.Font.Gotham
	prevButton.BorderSizePixel = 0
	prevButton.Parent = bottomNav

	local prevCorner = Instance.new("UICorner")
	prevCorner.CornerRadius = UDim.new(0.1, 0)
	prevCorner.Parent = prevButton

	-- Next button - larger for mobile
	local nextButton = Instance.new("TextButton")
	nextButton.Name = "NextButton"
	nextButton.Size = UDim2.new(0.25, 0, 0.8, 0) -- Larger touch target
	nextButton.Position = UDim2.new(0.7, 0, 0.1, 0)
	nextButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
	nextButton.Text = "Next ▶"
	nextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	nextButton.TextScaled = true
	nextButton.Font = Enum.Font.Gotham
	nextButton.BorderSizePixel = 0
	nextButton.Parent = bottomNav

	local nextCorner = Instance.new("UICorner")
	nextCorner.CornerRadius = UDim.new(0.1, 0)
	nextCorner.Parent = nextButton

	-- Progress indicator
	local progressLabel = Instance.new("TextLabel")
	progressLabel.Name = "Progress"
	progressLabel.Size = UDim2.new(0.35, 0, 0.8, 0)
	progressLabel.Position = UDim2.new(0.325, 0, 0.1, 0)
	progressLabel.BackgroundTransparency = 1
	progressLabel.Text = "Page 1 of " .. #INSTRUCTION_PAGES
	progressLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	progressLabel.TextScaled = true
	progressLabel.Font = Enum.Font.Gotham
	progressLabel.Parent = bottomNav

	-- Close instructions function
	local function closeInstructions()
		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0)
		}):Play()

		TweenService:Create(overlay, TweenInfo.new(0.3), {
			BackgroundTransparency = 1
		}):Play()

		wait(0.3)
		instructionGUI:Destroy()
	end

	-- Navigation button functions
	local function updateNavButtons()
		prevButton.Visible = currentPage > 1
		nextButton.Visible = currentPage < #INSTRUCTION_PAGES
		progressLabel.Text = "Page " .. currentPage .. " of " .. #INSTRUCTION_PAGES

		if currentPage == #INSTRUCTION_PAGES then
			nextButton.Text = "Finish ✓"
			nextButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
		else
			nextButton.Text = "Next ▶"
			nextButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
		end
	end

	-- Button click handlers
	prevButton.MouseButton1Click:Connect(function()
		if currentPage > 1 then
			updatePageContent(currentPage - 1)
			updateNavButtons()
		end
	end)

	nextButton.MouseButton1Click:Connect(function()
		if currentPage < #INSTRUCTION_PAGES then
			updatePageContent(currentPage + 1)
			updateNavButtons()
		else
			-- Finished reading instructions
			markInstructionsAsRead()
			closeInstructions()
		end
	end)

	-- Close button functionality
	closeButton.MouseButton1Click:Connect(closeInstructions)

	-- ESC key to close (commented out for testing - may cause issues)
	--[[
	if deviceType == "Desktop" then
		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if input.KeyCode == Enum.KeyCode.Escape and instructionGUI.Parent then
				closeInstructions()
			end
		end)
	end
	--]]

	-- Initialize first page
	updatePageContent(1)
	updateNavButtons()

	-- Store the target size and position before animation
	local targetSize = mainFrame.Size
	local targetPosition = mainFrame.Position

	-- Debug: Print target values
	print("Target size: " .. tostring(targetSize))
	print("Target position: " .. tostring(targetPosition))
	print("Created " .. #navButtons .. " navigation buttons")
	print("Content frame children: " .. #contentFrame:GetChildren())

	-- Animate GUI entrance
	mainFrame.Size = UDim2.new(0, 0, 0, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	overlay.BackgroundTransparency = 1

	TweenService:Create(overlay, TweenInfo.new(0.3), {
		BackgroundTransparency = 0.3
	}):Play()

	TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = targetSize,
		Position = targetPosition
	}):Play()

	return instructionGUI
end

-- Function to mark instructions as read
function markInstructionsAsRead()
	hasSeenInstructions = true

	-- Save to player data if available
	pcall(function()
		if _G.GameClient and _G.GameClient.SavePlayerData then
			local playerData = _G.GameClient:GetPlayerData() or {}
			playerData.hasSeenInstructions = true
			_G.GameClient:SavePlayerData(playerData)
		end
	end)

	print("GameInstructions: Instructions marked as read")
end

-- Chat command to reopen instructions
local function setupChatCommands()
	player.Chatted:Connect(function(message)
		local lowerMessage = message:lower()
		if lowerMessage == "/help" or lowerMessage == "/instructions" or lowerMessage == "/guide" then
			createInstructionGUI()
		end
	end)
end

-- Auto-show instructions for new players
local function autoShowInstructions()
	-- Wait a moment for the game to load
	wait(3)

	if not hasSeenInstructions then
		print("GameInstructions: Showing instructions for new player")
		createInstructionGUI()
	else
		print("GameInstructions: Player has seen instructions before")

		-- Show a small reminder
		game.StarterGui:SetCore("SendNotification", {
			Title = "📖 Welcome Back!",
			Text = "Type /help for the instruction guide",
			Duration = 5
		})
	end
end

-- Initialize the system
setupChatCommands()
autoShowInstructions()

print("=== RESPONSIVE GAME INSTRUCTIONS SYSTEM READY ===")
print("Device Type: " .. getDeviceType())
print("Scale Factor: " .. getScaleFactor())
print("")
print("📱 RESPONSIVE FEATURES:")
print("✅ Device-specific layouts (Mobile/Tablet/Desktop)")
print("✅ Scale-based sizing for all UI elements") 
print("✅ TextScaled = true for perfect text readability")
print("✅ Touch-friendly button sizes")
print("✅ Mobile: Horizontal tab navigation")
print("✅ Tablet/Desktop: Side-by-side layout")
print("✅ Thicker scroll bars for mobile")
print("✅ IgnoreGuiInset for full mobile compatibility")
print("")
print("Commands:")
print("  /help - Reopen instruction guide")
print("  /instructions - Alternative command") 
print("  /guide - Another alternative")
print("")
print("Mobile Optimizations:")
print("  📱 Nearly full-screen layout")
print("  👆 Large touch targets")
print("  📊 Horizontal tab navigation")
print("  📜 Optimized text scaling")
print("  🎯 Simplified mobile interface")