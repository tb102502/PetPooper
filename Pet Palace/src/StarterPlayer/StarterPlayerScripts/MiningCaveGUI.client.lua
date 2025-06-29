--[[
    MiningCaveGUI.client.lua
    Place in: StarterPlayer/StarterPlayerScripts/MiningCaveGUI.client.lua
    
    Creates a GUI with buttons to teleport to/from mining caves
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

-- ========== CREATE GUI ==========

-- Main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MiningCaveGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MiningFrame"
mainFrame.Size = UDim2.new(0.227, 0,0.652, 0)
mainFrame.Position = UDim2.new(0.021, 0, 0.149, 0) -- Right side of screen
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Frame corner
local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = mainFrame

-- Frame stroke
local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(60, 60, 80)
frameStroke.Thickness = 2
frameStroke.Parent = mainFrame

-- Title Label
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0.179, 0)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
titleLabel.BorderSizePixel = 0
titleLabel.Text = "⛏️ MINING CAVES"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

-- Title corner
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleLabel

-- Cave Button
local caveButton = Instance.new("TextButton")
caveButton.Name = "CaveButton"
caveButton.Size = UDim2.new(0.9, 0, 0.214, 0)
caveButton.Position = UDim2.new(0.05, 0, 0.25, 0)
caveButton.BackgroundColor3 = Color3.fromRGB(100, 60, 20)
caveButton.BorderSizePixel = 0
caveButton.Text = "🕳️ ENTER CAVE"
caveButton.TextColor3 = Color3.new(1, 1, 1)
caveButton.TextScaled = true
caveButton.Font = Enum.Font.GothamBold
caveButton.Parent = mainFrame

-- Cave button corner
local caveButtonCorner = Instance.new("UICorner")
caveButtonCorner.CornerRadius = UDim.new(0, 8)
caveButtonCorner.Parent = caveButton

-- Cave button stroke
local caveButtonStroke = Instance.new("UIStroke")
caveButtonStroke.Color = Color3.fromRGB(150, 90, 30)
caveButtonStroke.Thickness = 2
caveButtonStroke.Parent = caveButton

-- Surface Button
local surfaceButton = Instance.new("TextButton")
surfaceButton.Name = "SurfaceButton"
surfaceButton.Size = UDim2.new(0.9, 0, 0.214, 0)
surfaceButton.Position = UDim2.new(0.05, 0, 0.5, 0)
surfaceButton.BackgroundColor3 = Color3.fromRGB(20, 100, 60)
surfaceButton.BorderSizePixel = 0
surfaceButton.Text = "🌞 RETURN TO SURFACE"
surfaceButton.TextColor3 = Color3.new(1, 1, 1)
surfaceButton.TextScaled = true
surfaceButton.Font = Enum.Font.GothamBold
surfaceButton.Parent = mainFrame

-- Surface button corner
local surfaceButtonCorner = Instance.new("UICorner")
surfaceButtonCorner.CornerRadius = UDim.new(0, 8)
surfaceButtonCorner.Parent = surfaceButton

-- Surface button stroke
local surfaceButtonStroke = Instance.new("UIStroke")
surfaceButtonStroke.Color = Color3.fromRGB(30, 150, 90)
surfaceButtonStroke.Thickness = 2
surfaceButtonStroke.Parent = surfaceButton

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(0.9, 0, 0.143, 0)
statusLabel.Position = UDim2.new(0.05, 0, 0.75, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Ready to mine!"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.Gotham
statusLabel.Parent = mainFrame

-- Toggle Button (minimize/maximize)
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0.136, 0, 0.107, 0)
toggleButton.Position = UDim2.new(0.841, 0, 0.018, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
toggleButton.BorderSizePixel = 0
toggleButton.Text = "−"
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.TextScaled = true
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Parent = mainFrame

-- Toggle button corner
local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0.5, 0)
toggleCorner.Parent = toggleButton

-- ========== BUTTON FUNCTIONS ==========

local isMinimized = false
local isCooldown = false

-- Button hover effects
local function addHoverEffect(button, hoverColor, normalColor)
	button.MouseEnter:Connect(function()
		if not isCooldown then
			local tween = TweenService:Create(button, 
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{BackgroundColor3 = hoverColor}
			)
			tween:Play()
		end
	end)

	button.MouseLeave:Connect(function()
		if not isCooldown then
			local tween = TweenService:Create(button, 
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{BackgroundColor3 = normalColor}
			)
			tween:Play()
		end
	end)
end

-- Add hover effects
addHoverEffect(caveButton, Color3.fromRGB(120, 80, 40), Color3.fromRGB(100, 60, 20))
addHoverEffect(surfaceButton, Color3.fromRGB(40, 120, 80), Color3.fromRGB(20, 100, 60))
addHoverEffect(toggleButton, Color3.fromRGB(80, 80, 100), Color3.fromRGB(60, 60, 80))

-- Update status message
local function updateStatus(message, color)
	statusLabel.Text = message
	statusLabel.TextColor3 = color or Color3.fromRGB(200, 200, 200)

	-- Fade effect
	statusLabel.TextTransparency = 0.5
	local tween = TweenService:Create(statusLabel, 
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{TextTransparency = 0}
	)
	tween:Play()
end

-- Button cooldown function
local function startCooldown(duration)
	isCooldown = true
	caveButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	surfaceButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

	spawn(function()
		wait(duration)
		isCooldown = false
		caveButton.BackgroundColor3 = Color3.fromRGB(100, 60, 20)
		surfaceButton.BackgroundColor3 = Color3.fromRGB(20, 100, 60)
	end)
end

-- ========== BUTTON CLICK HANDLERS ==========

-- Cave Button Click
caveButton.MouseButton1Click:Connect(function()
	if isCooldown then
		updateStatus("⏳ Please wait...", Color3.fromRGB(255, 200, 100))
		return
	end

	updateStatus("🕳️ Teleporting to cave...", Color3.fromRGB(100, 200, 255))
	startCooldown(3)

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

	-- Fire remote event
	local success, errorMessage = pcall(function()
		TeleportToSurfaceEvent:FireServer()
	end)

	if not success then
		updateStatus("❌ Teleport failed!", Color3.fromRGB(255, 100, 100))
		print("Surface teleport error:", errorMessage)
	end
end)

-- Toggle Button Click (Minimize/Maximize)
toggleButton.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized

	if isMinimized then
		-- Minimize
		toggleButton.Text = "+"
		local tween = TweenService:Create(mainFrame,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = UDim2.new(0, 220, 0, 50)}
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
			{Size = UDim2.new(0, 220, 0, 280)}
		)
		tween:Play()

		-- Show buttons
		caveButton.Visible = true
		surfaceButton.Visible = true
		statusLabel.Visible = true
	end
end)

-- ========== KEYBOARD SHORTCUTS ==========

-- Optional keyboard shortcuts
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

-- ========== INITIALIZATION ==========

-- Initial status
updateStatus("⛏️ Ready to mine!")

-- Animate GUI entrance
mainFrame.Position = UDim2.new(1, 0, 0.5, -140)
local entranceTween = TweenService:Create(mainFrame,
	TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	{Position = UDim2.new(1, -240, 0.5, -140)}
)
entranceTween:Play()

print("✅ Mining Cave GUI loaded!")
print("📋 Controls:")
print("   🕳️ Cave Button - Teleport to your mining cave")
print("   🌞 Surface Button - Return to surface")
print("   ⌨️ Keyboard: M = Cave, N = Surface")
print("   📌 Toggle button (−/+) to minimize/maximize")