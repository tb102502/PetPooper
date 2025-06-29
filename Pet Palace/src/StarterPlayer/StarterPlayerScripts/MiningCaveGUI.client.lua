--[[
    MiningCaveGUI.client.lua - Responsive Design
    Place in: StarterPlayer/StarterPlayerScripts/MiningCaveGUI.client.lua
    
    UPDATED FEATURES:
    ✅ Scale-based sizing for all devices
    ✅ Device-aware positioning and scaling
    ✅ Mobile-optimized touch controls
    ✅ Responsive button layouts
    ✅ Adaptive text sizing
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
			size = UDim2.new(0.45, 0, 0.35, 0),
			position = UDim2.new(0.52, 0, 0.2, 0),
			buttonHeight = 0.22,
			buttonSpacing = 0.05,
			minimizedSize = UDim2.new(0.4, 0, 0.08, 0)
		}
	elseif deviceType == "Tablet" then
		return {
			size = UDim2.new(0.35, 0, 0.4, 0),
			position = UDim2.new(0.63, 0, 0.18, 0),
			buttonHeight = 0.2,
			buttonSpacing = 0.04,
			minimizedSize = UDim2.new(0.3, 0, 0.07, 0)
		}
	else
		return {
			size = UDim2.new(0.25, 0, 0.45, 0),
			position = UDim2.new(0.73, 0, 0.15, 0),
			buttonHeight = 0.18,
			buttonSpacing = 0.03,
			minimizedSize = UDim2.new(0.22, 0, 0.06, 0)
		}
	end
end

-- ========== CREATE RESPONSIVE GUI ==========

local deviceType = getDeviceType()
local scaleFactor = getScaleFactor()
local config = getResponsiveConfig()

print("✅ Creating responsive Mining Cave GUI for " .. deviceType .. " (scale: " .. scaleFactor .. ")")

-- Main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MiningCaveGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Frame (responsive sizing)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MiningFrame"
mainFrame.Size = config.size
mainFrame.Position = config.position
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Frame corner (responsive)
local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0.08, 0)
frameCorner.Parent = mainFrame

-- Frame stroke (responsive thickness)
local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(60, 60, 80)
frameStroke.Thickness = math.max(1, 2 * scaleFactor)
frameStroke.Parent = mainFrame

-- Title Label (responsive)
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0.18, 0)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
titleLabel.BorderSizePixel = 0
titleLabel.Text = "⛏️ MINING CAVES"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

-- Title corner (responsive)
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0.15, 0)
titleCorner.Parent = titleLabel

-- Cave Button (responsive)
local caveButton = Instance.new("TextButton")
caveButton.Name = "CaveButton"
caveButton.Size = UDim2.new(0.9, 0, config.buttonHeight, 0)
caveButton.Position = UDim2.new(0.05, 0, 0.25, 0)
caveButton.BackgroundColor3 = Color3.fromRGB(100, 60, 20)
caveButton.BorderSizePixel = 0
caveButton.Text = deviceType == "Mobile" and "🕳️ ENTER\nCAVE" or "🕳️ ENTER CAVE"
caveButton.TextColor3 = Color3.new(1, 1, 1)
caveButton.TextScaled = true
caveButton.Font = Enum.Font.GothamBold
caveButton.Parent = mainFrame

-- Cave button corner (responsive)
local caveButtonCorner = Instance.new("UICorner")
caveButtonCorner.CornerRadius = UDim.new(0.12, 0)
caveButtonCorner.Parent = caveButton

-- Cave button stroke (responsive)
local caveButtonStroke = Instance.new("UIStroke")
caveButtonStroke.Color = Color3.fromRGB(150, 90, 30)
caveButtonStroke.Thickness = math.max(1, 2 * scaleFactor)
caveButtonStroke.Parent = caveButton

-- Surface Button (responsive positioning)
local surfaceButton = Instance.new("TextButton")
surfaceButton.Name = "SurfaceButton"
surfaceButton.Size = UDim2.new(0.9, 0, config.buttonHeight, 0)
surfaceButton.Position = UDim2.new(0.05, 0, 0.25 + config.buttonHeight + config.buttonSpacing, 0)
surfaceButton.BackgroundColor3 = Color3.fromRGB(20, 100, 60)
surfaceButton.BorderSizePixel = 0
surfaceButton.Text = deviceType == "Mobile" and "🌞 RETURN\nSURFACE" or "🌞 RETURN TO SURFACE"
surfaceButton.TextColor3 = Color3.new(1, 1, 1)
surfaceButton.TextScaled = true
surfaceButton.Font = Enum.Font.GothamBold
surfaceButton.Parent = mainFrame

-- Surface button corner (responsive)
local surfaceButtonCorner = Instance.new("UICorner")
surfaceButtonCorner.CornerRadius = UDim.new(0.12, 0)
surfaceButtonCorner.Parent = surfaceButton

-- Surface button stroke (responsive)
local surfaceButtonStroke = Instance.new("UIStroke")
surfaceButtonStroke.Color = Color3.fromRGB(30, 150, 90)
surfaceButtonStroke.Thickness = math.max(1, 2 * scaleFactor)
surfaceButtonStroke.Parent = surfaceButton

-- Status Label (responsive positioning)
local statusYPosition = 0.25 + (config.buttonHeight + config.buttonSpacing) * 2
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
statusLabel.Position = UDim2.new(0.05, 0, statusYPosition, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Ready to mine!"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.Gotham
statusLabel.Parent = mainFrame

-- Toggle Button (responsive sizing)
local toggleButtonSize = deviceType == "Mobile" and UDim2.new(0.2, 0, 0.12, 0) or UDim2.new(0.15, 0, 0.1, 0)
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = toggleButtonSize
toggleButton.Position = UDim2.new(0.98 - toggleButtonSize.X.Scale, 0, 0.02, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
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

-- Add hover effects
addHoverEffect(caveButton, Color3.fromRGB(120, 80, 40), Color3.fromRGB(100, 60, 20))
addHoverEffect(surfaceButton, Color3.fromRGB(40, 120, 80), Color3.fromRGB(20, 100, 60))
addHoverEffect(toggleButton, Color3.fromRGB(80, 80, 100), Color3.fromRGB(60, 60, 80))

-- Update status message with responsive text effects
local function updateStatus(message, color)
	statusLabel.Text = message
	statusLabel.TextColor3 = color or Color3.fromRGB(200, 200, 200)

	-- Enhanced fade effect for mobile
	local fadeAmount = deviceType == "Mobile" and 0.3 or 0.5
	statusLabel.TextTransparency = fadeAmount
	local tween = TweenService:Create(statusLabel, 
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{TextTransparency = 0}
	)
	tween:Play()
end

-- Button cooldown function with responsive feedback
local function startCooldown(duration)
	isCooldown = true
	caveButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	surfaceButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

	-- Add visual feedback for mobile users
	if deviceType == "Mobile" then
		caveButton.Text = "⏳ WAIT..."
		surfaceButton.Text = "⏳ WAIT..."
	end

	spawn(function()
		wait(duration)
		isCooldown = false
		caveButton.BackgroundColor3 = Color3.fromRGB(100, 60, 20)
		surfaceButton.BackgroundColor3 = Color3.fromRGB(20, 100, 60)

		-- Restore original text
		caveButton.Text = deviceType == "Mobile" and "🕳️ ENTER\nCAVE" or "🕳️ ENTER CAVE"
		surfaceButton.Text = deviceType == "Mobile" and "🌞 RETURN\nSURFACE" or "🌞 RETURN TO SURFACE"
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

-- Toggle Button Click (Minimize/Maximize) - Responsive
toggleButton.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized

	if isMinimized then
		-- Minimize
		toggleButton.Text = "+"
		local tween = TweenService:Create(mainFrame,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = config.minimizedSize}
		)
		tween:Play()

		-- Hide buttons
		caveButton.Visible = false
		surfaceButton.Visible = false
		statusLabel.Visible = false

	else
		-- Maximize
		toggleButton.Text = "−"
		local tween = TweenService:Create(mainFrame,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = config.size}
		)
		tween:Play()

		-- Show buttons
		caveButton.Visible = true
		surfaceButton.Visible = true
		statusLabel.Visible = true
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

-- ========== RESPONSIVE INITIALIZATION ==========

-- Initial status
updateStatus("⛏️ Ready to mine!")

-- Responsive animate GUI entrance
local startPosition = UDim2.new(1.2, 0, config.position.Y.Scale, 0)
mainFrame.Position = startPosition

local entranceTween = TweenService:Create(mainFrame,
	TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	{Position = config.position}
)
entranceTween:Play()

-- ========== VIEWPORT MONITORING ==========

-- Handle viewport changes for responsive design
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	local newDeviceType = getDeviceType()
	if newDeviceType ~= deviceType then
		print("Mining GUI: Device type changed from " .. deviceType .. " to " .. newDeviceType)

		-- Update device type and config
		deviceType = newDeviceType
		scaleFactor = getScaleFactor()
		config = getResponsiveConfig()

		-- Update GUI sizing and positioning
		mainFrame.Size = isMinimized and config.minimizedSize or config.size
		mainFrame.Position = config.position

		-- Update button text for new device type
		if not isMinimized then
			caveButton.Text = deviceType == "Mobile" and "🕳️ ENTER\nCAVE" or "🕳️ ENTER CAVE"
			surfaceButton.Text = deviceType == "Mobile" and "🌞 RETURN\nSURFACE" or "🌞 RETURN TO SURFACE"
		end

		-- Update stroke thickness
		frameStroke.Thickness = math.max(1, 2 * scaleFactor)
		caveButtonStroke.Thickness = math.max(1, 2 * scaleFactor)
		surfaceButtonStroke.Thickness = math.max(1, 2 * scaleFactor)
	end
end)

-- ========== DEBUG FUNCTIONS ==========

local function debugMiningGUI()
	print("=== RESPONSIVE MINING GUI DEBUG ===")
	print("Device Type:", deviceType)
	print("Scale Factor:", scaleFactor)
	print("GUI Size:", config.size)
	print("GUI Position:", config.position)
	print("Is Minimized:", isMinimized)
	print("Is Cooldown:", isCooldown)
	print("Touch Enabled:", UserInputService.TouchEnabled)
	print("Keyboard Enabled:", UserInputService.KeyboardEnabled)

	if workspace.CurrentCamera then
		local viewport = workspace.CurrentCamera.ViewportSize
		print("Viewport Size:", viewport.X .. "x" .. viewport.Y)
	end

	print("=====================================")
end

-- Make debug function global
_G.DebugMiningGUI = function()
	debugMiningGUI()
end

print("✅ RESPONSIVE Mining Cave GUI loaded!")
print("📱 RESPONSIVE FEATURES:")
print("  📏 Scale-based sizing: " .. deviceType .. " (" .. scaleFactor .. "x)")
print("  📐 Device-adaptive positioning and button sizes")
print("  📱 Touch-optimized controls and feedback")
print("  🔄 Dynamic viewport monitoring")
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
print("   🕳️ Cave Button - Teleport to your mining cave")
print("   🌞 Surface Button - Return to surface")
print("   📌 Toggle button (−/+) to minimize/maximize")
print("")
print("🔧 Debug Command:")
print("  _G.DebugMiningGUI() - Show responsive GUI debug info")