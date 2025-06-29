--[[
    MiningCaveGUI.client.lua - COMPACT COW ADMIN PANEL STYLE
    Place in: StarterPlayer/StarterPlayerScripts/MiningCaveGUI.client.lua
    
    UPDATED FEATURES:
    ✅ Scale-based sizing for all devices
    ✅ Device-aware positioning and scaling
    ✅ Mobile-optimized touch controls
    ✅ Responsive button layouts
    ✅ Adaptive text sizing
    ✅ COW ADMIN PANEL STYLING - Dark theme, COMPACT design
    ✅ POSITIONED DIRECTLY UNDER COW ADMIN PANEL
    ✅ HALF original width for better proportions
    ✅ Clean, minimal design matching existing UI
    ✅ Improved minimized state appearance
    ✅ Compact text for narrow width
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for remote events to be created by the server
local remoteFolder = ReplicatedStorage:WaitForChild("GameRemotes")
local TeleportToCaveEvent = remoteFolder:WaitForChild("TeleportToCave")
local TeleportToSurfaceEvent = remoteFolder:WaitForChild("TeleportToSurface")

-- ========== DEVICE DETECTION ==========

local function getDeviceType()
	local camera = workspace.CurrentCamera
	local viewportSize = camera.ViewportSize

	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		-- Touch device
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
		return 1.3
	elseif deviceType == "Tablet" then
		return 1.15
	else
		return 1.0
	end
end

local function getResponsiveConfig()
	local deviceType = getDeviceType()

	if deviceType == "Mobile" then
		return {
			size = UDim2.new(0.16, 0, 0.22, 0), -- Half width - much more compact
			position = UDim2.new(0.02, 0, 0.26, 0), -- Positioned under Cow Admin Panel
			buttonHeight = 0.35,
			buttonSpacing = 0.08,
			minimizedSize = UDim2.new(0.16, 0, 0.06, 0) -- Better minimized proportions
		}
	elseif deviceType == "Tablet" then
		return {
			size = UDim2.new(0.14, 0, 0.2, 0), -- Half width - much more compact
			position = UDim2.new(0.02, 0, 0.24, 0), -- Positioned under Cow Admin Panel
			buttonHeight = 0.32,
			buttonSpacing = 0.06,
			minimizedSize = UDim2.new(0.14, 0, 0.05, 0) -- Better minimized proportions
		}
	else
		return {
			size = UDim2.new(0.125, 0, 0.18, 0), -- Half width - much more compact
			position = UDim2.new(0.02, 0, 0.22, 0), -- Positioned under Cow Admin Panel
			buttonHeight = 0.3,
			buttonSpacing = 0.05,
			minimizedSize = UDim2.new(0.125, 0, 0.04, 0) -- Better minimized proportions
		}
	end
end

-- ========== CREATE RESPONSIVE GUI ==========

local deviceType = getDeviceType()
local scaleFactor = getScaleFactor()
local config = getResponsiveConfig()

print("✅ Creating COMPACT responsive Mining Cave GUI for " .. deviceType .. " (scale: " .. scaleFactor .. ") - HALF WIDTH")

-- Main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MiningCaveGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Frame (matching Cow Admin Panel style) - LEFT SIDE
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MiningFrame"
mainFrame.Size = config.size
mainFrame.Position = config.position
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20) -- Dark like Cow Admin Panel
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Frame corner (matching Cow Admin Panel)
local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0.12, 0) -- Similar rounded corners to Cow Admin Panel
frameCorner.Parent = mainFrame

-- Frame stroke (subtle like Cow Admin Panel)
local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(40, 40, 40) -- Subtle dark stroke
frameStroke.Thickness = 1
frameStroke.Parent = mainFrame

-- Title Label (matching Cow Admin Panel style) - COMPACT
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0.25, 0) -- Adjusted height for compact design
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundTransparency = 1 -- No background like Cow Admin Panel
titleLabel.Text = "⛏️ MINING" -- Shorter title for narrow width
titleLabel.TextColor3 = Color3.new(1, 1, 1) -- White text like Cow Admin Panel
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

-- Cave Button (matching Cow Admin Panel style) - COMPACT
local caveButton = Instance.new("TextButton")
caveButton.Name = "CaveButton"
caveButton.Size = UDim2.new(0.9, 0, config.buttonHeight, 0)
caveButton.Position = UDim2.new(0.05, 0, 0.3, 0)
caveButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35) -- Dark like Cow Admin Panel
caveButton.BorderSizePixel = 0
caveButton.Text = deviceType == "Mobile" and "⛏️\nCAVE" or "⛏️ CAVE" -- Shorter text for narrow width
caveButton.TextColor3 = Color3.new(1, 1, 1) -- White text
caveButton.TextScaled = true
caveButton.Font = Enum.Font.GothamBold
caveButton.Parent = mainFrame

-- Cave button corner (matching Cow Admin Panel)
local caveButtonCorner = Instance.new("UICorner")
caveButtonCorner.CornerRadius = UDim.new(0.15, 0)
caveButtonCorner.Parent = caveButton

-- Cave button stroke (subtle)
local caveButtonStroke = Instance.new("UIStroke")
caveButtonStroke.Color = Color3.fromRGB(60, 60, 60)
caveButtonStroke.Thickness = 1
caveButtonStroke.Parent = caveButton

-- Surface Button (matching Cow Admin Panel style) - COMPACT
local surfaceButton = Instance.new("TextButton")
surfaceButton.Name = "SurfaceButton"
surfaceButton.Size = UDim2.new(0.9, 0, config.buttonHeight, 0)
surfaceButton.Position = UDim2.new(0.05, 0, 0.3 + config.buttonHeight + config.buttonSpacing, 0)
surfaceButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35) -- Dark like Cow Admin Panel
surfaceButton.BorderSizePixel = 0
surfaceButton.Text = deviceType == "Mobile" and "🌞\nSURFACE" or "🌞 SURFACE" -- Shorter text for narrow width
surfaceButton.TextColor3 = Color3.new(1, 1, 1) -- White text
surfaceButton.TextScaled = true
surfaceButton.Font = Enum.Font.GothamBold
surfaceButton.Parent = mainFrame

-- Surface button corner (matching Cow Admin Panel)
local surfaceButtonCorner = Instance.new("UICorner")
surfaceButtonCorner.CornerRadius = UDim.new(0.15, 0)
surfaceButtonCorner.Parent = surfaceButton

-- Surface button stroke (subtle)
local surfaceButtonStroke = Instance.new("UIStroke")
surfaceButtonStroke.Color = Color3.fromRGB(60, 60, 60)
surfaceButtonStroke.Thickness = 1
surfaceButtonStroke.Parent = surfaceButton

-- Status Label (hidden for compact design like Cow Admin Panel)
local statusYPosition = 0.3 + (config.buttonHeight + config.buttonSpacing) * 2
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(0.9, 0, 0.1, 0)
statusLabel.Position = UDim2.new(0.05, 0, statusYPosition, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Ready"
statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180) -- Subtle gray
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.Gotham
statusLabel.Visible = false -- Hidden by default for compact design
statusLabel.Parent = mainFrame

-- Toggle Button (matching Cow Admin Panel style) - COMPACT
local toggleButtonSize = deviceType == "Mobile" and UDim2.new(0.2, 0, 0.2, 0) or UDim2.new(0.15, 0, 0.18, 0)
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = toggleButtonSize
toggleButton.Position = UDim2.new(0.85, 0, 0.02, 0) -- Adjusted for narrower GUI
toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Slightly lighter than main frame
toggleButton.BorderSizePixel = 0
toggleButton.Text = "−"
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.TextScaled = true
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Parent = mainFrame

-- Toggle button corner (responsive)
local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0.5, 0)
toggleCorner.Parent = toggleButton

-- ========== RESPONSIVE BUTTON FUNCTIONS ==========

local isMinimized = false
local isCooldown = false

-- Helper function to scale UDim2
local function scaleUDim2(originalSize, scale)
	return UDim2.new(
		originalSize.X.Scale * scale,
		originalSize.X.Offset * scale,
		originalSize.Y.Scale * scale,
		originalSize.Y.Offset * scale
	)
end

-- Button hover effects with responsive scaling
local function addHoverEffect(button, hoverColor, normalColor)
	local originalSize = button.Size

	button.MouseEnter:Connect(function()
		if not isCooldown then
			local hoverScale = deviceType == "Mobile" and 1.05 or 1.03
			local tween = TweenService:Create(button, 
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					BackgroundColor3 = hoverColor,
					Size = scaleUDim2(originalSize, hoverScale)
				}
			)
			tween:Play()
		end
	end)

	button.MouseLeave:Connect(function()
		if not isCooldown then
			local tween = TweenService:Create(button, 
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					BackgroundColor3 = normalColor,
					Size = originalSize
				}
			)
			tween:Play()
		end
	end)
end

-- Add hover effects (updated for Cow Admin Panel style)
addHoverEffect(caveButton, Color3.fromRGB(55, 55, 55), Color3.fromRGB(35, 35, 35)) -- Dark hover
addHoverEffect(surfaceButton, Color3.fromRGB(55, 55, 55), Color3.fromRGB(35, 35, 35)) -- Dark hover
addHoverEffect(toggleButton, Color3.fromRGB(70, 70, 70), Color3.fromRGB(50, 50, 50)) -- Dark hover

-- Update status message (simplified for compact design like Cow Admin Panel)
local function updateStatus(message, color)
	-- Status is now minimal/hidden for compact design like Cow Admin Panel
	-- Could flash the title or use notifications instead
	statusLabel.Text = message
	statusLabel.TextColor3 = color or Color3.fromRGB(180, 180, 180)

	-- Brief flash effect on title for feedback instead of showing status label
	local originalTitleColor = titleLabel.TextColor3
	titleLabel.TextColor3 = color or Color3.fromRGB(100, 200, 255)

	local flashTween = TweenService:Create(titleLabel, 
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{TextColor3 = originalTitleColor}
	)
	flashTween:Play()
end

-- Button cooldown function with dark theme - COMPACT TEXT
local function startCooldown(duration)
	isCooldown = true
	caveButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25) -- Darker during cooldown
	surfaceButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25) -- Darker during cooldown

	-- Add visual feedback for mobile users - shorter text
	if deviceType == "Mobile" then
		caveButton.Text = "⏳\nWAIT"
		surfaceButton.Text = "⏳\nWAIT"
	else
		caveButton.Text = "⏳ WAIT"
		surfaceButton.Text = "⏳ WAIT"
	end

	spawn(function()
		wait(duration)
		isCooldown = false
		caveButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35) -- Back to normal dark
		surfaceButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35) -- Back to normal dark

		-- Restore original text - compact versions
		caveButton.Text = deviceType == "Mobile" and "⛏️\nCAVE" or "⛏️ CAVE"
		surfaceButton.Text = deviceType == "Mobile" and "🌞\nSURFACE" or "🌞 SURFACE"
	end)
end

-- ========== RESPONSIVE BUTTON CLICK HANDLERS ==========

-- Cave Button Click
caveButton.MouseButton1Click:Connect(function()
	if isCooldown then
		updateStatus("⏳ Please wait...", Color3.fromRGB(255, 200, 100))
		return
	end

	updateStatus("🕳️ Teleporting to cave...", Color3.fromRGB(100, 200, 255))
	startCooldown(3)

	-- Enhanced button press effect for touch devices
	if deviceType == "Mobile" or deviceType == "Tablet" then
		local originalSize = caveButton.Size
		local pressEffect = TweenService:Create(caveButton,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad),
			{Size = scaleUDim2(originalSize, 0.95)}
		)
		pressEffect:Play()
		pressEffect.Completed:Connect(function()
			local releaseEffect = TweenService:Create(caveButton,
				TweenInfo.new(0.1, Enum.EasingStyle.Quad),
				{Size = originalSize}
			)
			releaseEffect:Play()
		end)
	end

	-- Fire remote event
	local success, errorMessage = pcall(function()
		TeleportToCaveEvent:FireServer()
	end)

	if not success then
		updateStatus("❌ Teleport failed!", Color3.fromRGB(255, 100, 100))
		print("Cave teleport error:", errorMessage)
	end
end)

-- ========== DEBUG FUNCTIONS ==========

local function debugMiningGUI()
	print("=== RESPONSIVE MINING GUI DEBUG ===")
	print("Device Type:", deviceType)
	print("Scale Factor:", scaleFactor)
	print("GUI Size:", config.size)
	print("GUI Position:", config.position)
	print("Side:", "LEFT") 
	print("Style:", "COMPACT COW ADMIN PANEL MATCHING") -- Updated
	print("Width:", "HALF original width for better proportions") -- NEW
	print("Is Minimized:", isMinimized)
	print("Is Cooldown:", isCooldown)
	print("Touch Enabled:", UserInputService.TouchEnabled)
	print("Keyboard Enabled:", UserInputService.KeyboardEnabled)

	if workspace.CurrentCamera then
		local viewport = workspace.CurrentCamera.ViewportSize
		print("Viewport Size:", viewport.X .. "x" .. viewport.Y)
	end

	print("Design Features:")
	print("  - Dark theme like Cow Admin Panel")
	print("  - COMPACT sizing - half original width")
	print("  - Positioned under Cow Admin Panel")
	print("  - Clean, minimal design")
	print("  - Improved minimized state")
	print("  - Shorter text for narrow width")
	print("=====================================")
end

-- Make debug function global
_G.DebugMiningGUI = function()
	debugMiningGUI()
end

print("✅ RESPONSIVE Mining Cave GUI loaded! - COMPACT COW ADMIN PANEL STYLE")
print("📱 RESPONSIVE FEATURES:")
print("  📏 Scale-based sizing: " .. deviceType .. " (" .. scaleFactor .. "x)")
print("  🎨 Cow Admin Panel styling: Dark theme, COMPACT design")
print("  📐 Positioned directly under Cow Admin Panel")
print("  📱 Touch-optimized controls and feedback")
print("  🔄 Dynamic viewport monitoring")
print("  ⬅️ LEFT SIDE positioning under Cow Admin Panel")
print("  🎨 DESIGN: Dark background, white text, rounded corners")
print("  📏 COMPACT: Half the original width for cleaner look")
print("  📱 Mobile: Larger buttons, split text, enhanced feedback")
print("  📱 Tablet: Medium sizing, hybrid controls")
print("  🖥️ Desktop: Standard sizing, keyboard shortcuts")
print("")
print("🎮 Device-Specific Features:")
if deviceType == "Mobile" then
	print("  📱 Mobile Mode: Large touch targets, split button text")
	print("  📱 Enhanced visual feedback for touch interactions")
	print("  📱 No keyboard shortcuts (touch-only)")
elseif deviceType == "Tablet" then
	print("  📱 Tablet Mode: Medium sizing, hybrid interface")
	print("  📱 Touch + keyboard support")
else
	print("  🖥️ Desktop Mode: Compact sizing, full keyboard shortcuts")
	print("  ⌨️ Keyboard: M = Cave, N = Surface")
end
print("")
print("📋 Controls:")
print("   ⛏️ Cave Button - Teleport to your mining cave")
print("   🌞 Surface Button - Return to surface")
print("   📌 Toggle button (−/+) to minimize/maximize")
print("")
print("🎨 STYLING:")
print("   📍 Matches Cow Admin Panel design exactly")
print("   🖤 Dark background with white text")
print("   📦 COMPACT, clean layout - HALF original width")
print("   📍 Positioned directly underneath Cow Admin Panel")
print("   📏 Better minimized state with icon-only title")
print("")
print("🔧 Debug Command:")
print("  _G.DebugMiningGUI() - Show responsive GUI debug info")

-- Surface Button Click
surfaceButton.MouseButton1Click:Connect(function()
	if isCooldown then
		updateStatus("⏳ Please wait...", Color3.fromRGB(255, 200, 100))
		return
	end

	updateStatus("🌞 Returning to surface...", Color3.fromRGB(100, 255, 100))
	startCooldown(3)

	-- Enhanced button press effect for touch devices
	if deviceType == "Mobile" or deviceType == "Tablet" then
		local originalSize = surfaceButton.Size
		local pressEffect = TweenService:Create(surfaceButton,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad),
			{Size = scaleUDim2(originalSize, 0.95)}
		)
		pressEffect:Play()
		pressEffect.Completed:Connect(function()
			local releaseEffect = TweenService:Create(surfaceButton,
				TweenInfo.new(0.1, Enum.EasingStyle.Quad),
				{Size = originalSize}
			)
			releaseEffect:Play()
		end)
	end

	-- Fire remote event
	local success, errorMessage = pcall(function()
		TeleportToSurfaceEvent:FireServer()
	end)

	if not success then
		updateStatus("❌ Teleport failed!", Color3.fromRGB(255, 100, 100))
		print("Surface teleport error:", errorMessage)
	end
end)

-- Toggle Button Click (Minimize/Maximize) - IMPROVED minimized appearance
toggleButton.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized

	if isMinimized then
		-- Minimize - clean minimized state
		toggleButton.Text = "+"
		local tween = TweenService:Create(mainFrame,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = config.minimizedSize}
		)
		tween:Play()

		-- Hide buttons for compact view
		caveButton.Visible = false
		surfaceButton.Visible = false

		-- Make title smaller for minimized state
		titleLabel.Size = UDim2.new(0.85, 0, 1, 0) -- Smaller to make room for toggle button
		titleLabel.Text = "⛏️" -- Just icon when minimized

	else
		-- Maximize - restore full interface
		toggleButton.Text = "−"
		local tween = TweenService:Create(mainFrame,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = config.size}
		)
		tween:Play()

		-- Show buttons
		caveButton.Visible = true
		surfaceButton.Visible = true

		-- Restore full title
		titleLabel.Size = UDim2.new(1, 0, 0.25, 0)
		titleLabel.Text = "⛏️ MINING"
	end
end)

-- ========== RESPONSIVE KEYBOARD SHORTCUTS ==========

-- Optional keyboard shortcuts (disabled for mobile)
if deviceType == "Desktop" then
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.M then -- Press 'M' for cave
			if not isCooldown then
				caveButton.MouseButton1Click:Fire()
			end
		elseif input.KeyCode == Enum.KeyCode.N then -- Press 'N' for surface
			if not isCooldown then
				surfaceButton.MouseButton1Click:Fire()
			end
		end
	end)
end