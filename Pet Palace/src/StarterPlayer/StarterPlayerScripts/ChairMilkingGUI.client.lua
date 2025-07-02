--[[
    ChairMilkingGUI.client.lua - Responsive Chair Milking GUI System
    Place in: StarterPlayer/StarterPlayerScripts/ChairMilkingGUI.client.lua
    
    UPDATED FEATURES:
    ✅ Scale-based sizing for all devices
    ✅ Device-aware scaling and positioning
    ✅ Mobile-optimized touch controls
    ✅ Responsive proximity prompts
    ✅ Adaptive text sizing
]]

local ChairMilkingGUI = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Local player
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- State
ChairMilkingGUI.State = {
	currentGUI = nil,
	guiType = nil, -- "proximity" or "milking"
	isVisible = false,
	connections = {},
	deviceType = "Desktop"
}

-- Configuration
ChairMilkingGUI.Config = {
	proximityFadeTime = 0.3,
	milkingFadeTime = 0.5,
	pulseSpeed = 2,
	-- Device scaling
	scaling = {
		Mobile = 1.3,
		Tablet = 1.15,
		Desktop = 1.0
	},
	-- Responsive positioning
	positioning = {
		Mobile = {
			proximity = {size = UDim2.new(0.8, 0, 0.2, 0), position = UDim2.new(0.1, 0, 0.75, 0)},
			milking = {size = UDim2.new(0.9, 0, 0.25, 0), position = UDim2.new(0.05, 0, 0.1, 0)}
		},
		Tablet = {
			proximity = {size = UDim2.new(0.6, 0, 0.18, 0), position = UDim2.new(0.2, 0, 0.78, 0)},
			milking = {size = UDim2.new(0.7, 0, 0.22, 0), position = UDim2.new(0.15, 0, 0.12, 0)}
		},
		Desktop = {
			proximity = {size = UDim2.new(0.35, 0, 0.15, 0), position = UDim2.new(0.325, 0, 0.8, 0)},
			milking = {size = UDim2.new(0.4, 0, 0.2, 0), position = UDim2.new(0.3, 0, 0.15, 0)}
		}
	}
}

-- ========== DEVICE DETECTION ==========

function ChairMilkingGUI:DetectDeviceType()
	local camera = workspace.CurrentCamera
	local viewportSize = camera.ViewportSize

	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		-- Touch device
		if math.min(viewportSize.X, viewportSize.Y) < 500 then
			self.State.deviceType = "Mobile"
		else
			self.State.deviceType = "Tablet"
		end
	else
		-- Desktop
		self.State.deviceType = "Desktop"
	end

	print("ChairMilkingGUI: Detected device type: " .. self.State.deviceType)
end

function ChairMilkingGUI:GetScaleFactor()
	return self.Config.scaling[self.State.deviceType] or 1.0
end

function ChairMilkingGUI:GetResponsiveConfig(guiType)
	return self.Config.positioning[self.State.deviceType][guiType]
end

-- ========== INITIALIZATION ==========

function ChairMilkingGUI:Initialize()
	print("ChairMilkingGUI: Initializing responsive chair GUI system...")

	-- Detect device type
	self:DetectDeviceType()

	-- Setup remote connections
	self:SetupRemoteConnections()

	-- Setup input handling
	self:SetupInputHandling()

	print("ChairMilkingGUI: Responsive client GUI system initialized!")
end

function ChairMilkingGUI:SetupRemoteConnections()
	local remoteFolder = ReplicatedStorage:WaitForChild("GameRemotes", 10)
	if not remoteFolder then
		warn("ChairMilkingGUI: GameRemotes folder not found!")
		return
	end

	-- Show chair prompt
	local showPrompt = remoteFolder:WaitForChild("ShowChairPrompt", 5)
	if showPrompt then
		showPrompt.OnClientEvent:Connect(function(promptType, data)
			pcall(function()
				self:ShowPrompt(promptType, data)
			end)
		end)
	end

	-- Hide chair prompt
	local hidePrompt = remoteFolder:WaitForChild("HideChairPrompt", 5)
	if hidePrompt then
		hidePrompt.OnClientEvent:Connect(function()
			pcall(function()
				self:HidePrompt()
			end)
		end)
	end

	print("ChairMilkingGUI: Remote connections established")
end

function ChairMilkingGUI:SetupInputHandling()
	-- ESC key to stop milking
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.Escape then
			if self.State.guiType == "milking" then
				self:RequestStopMilking()
			end
		end
	end)
end

-- ========== RESPONSIVE GUI CREATION ==========

function ChairMilkingGUI:ShowPrompt(promptType, data)
	-- Hide existing GUI first
	if self.State.currentGUI then
		self:HidePrompt()
		wait(0.1)
	end

	self.State.guiType = promptType

	if promptType == "proximity" then
		self:CreateResponsiveProximityGUI(data)
	elseif promptType == "milking" then
		self:CreateResponsiveMilkingGUI(data)
	end

	self.State.isVisible = true
end

function ChairMilkingGUI:CreateResponsiveProximityGUI(data)
	print("ChairMilkingGUI: Creating responsive proximity GUI for " .. self.State.deviceType)

	-- Get responsive configuration
	local config = self:GetResponsiveConfig("proximity")
	local scaleFactor = self:GetScaleFactor()

	-- Create main GUI
	local gui = Instance.new("ScreenGui")
	gui.Name = "ChairProximityGUI"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = PlayerGui

	-- Main container with responsive sizing
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = config.size
	container.Position = config.position
	container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	container.BackgroundTransparency = 0.1
	container.BorderSizePixel = 0
	container.Parent = gui

	-- Corner rounding (responsive)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.08, 0) -- Scale-based corner radius
	corner.Parent = container

	-- Gradient background
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 60)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 40))
	}
	gradient.Rotation = 90
	gradient.Parent = container

	-- Title (responsive positioning)
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.35, 0)
	title.Position = UDim2.new(0, 0, 0.05, 0)
	title.BackgroundTransparency = 1
	title.Text = data.title or "🪑 Milking Chair"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.TextStrokeTransparency = 0
	title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	title.Parent = container

	-- Subtitle (responsive)
	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(1, 0, 0.3, 0)
	subtitle.Position = UDim2.new(0, 0, 0.4, 0)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = data.subtitle or "Sit down to start milking!"
	subtitle.TextColor3 = data.canUse and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 200, 100)
	subtitle.TextScaled = true
	subtitle.Font = Enum.Font.Gotham
	subtitle.Parent = container

	-- Instruction (responsive)
	local instruction = Instance.new("TextLabel")
	instruction.Name = "Instruction"
	instruction.Size = UDim2.new(1, 0, 0.25, 0)
	instruction.Position = UDim2.new(0, 0, 0.7, 0)
	instruction.BackgroundTransparency = 1

	-- Device-specific instruction text
	local instructionText = data.instruction or self:GetDeviceSpecificInstruction()
	instruction.Text = instructionText
	instruction.TextColor3 = Color3.fromRGB(200, 200, 200)
	instruction.TextScaled = true
	instruction.Font = Enum.Font.Gotham
	instruction.Parent = container

	-- Pulse animation for proximity GUI
	self:StartPulseAnimation(container)

	-- Responsive fade in animation
	local startPosition = UDim2.new(config.position.X.Scale, 0, 1.2, 0)
	container.Position = startPosition
	container.BackgroundTransparency = 1

	local tween = TweenService:Create(container,
		TweenInfo.new(self.Config.proximityFadeTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			Position = config.position,
			BackgroundTransparency = 0.1
		}
	)
	tween:Play()

	self.State.currentGUI = gui
	print("ChairMilkingGUI: Responsive proximity GUI created for " .. self.State.deviceType)
end

function ChairMilkingGUI:CreateResponsiveMilkingGUI(data)
	print("ChairMilkingGUI: Creating responsive milking session GUI for " .. self.State.deviceType)

	-- Get responsive configuration
	local config = self:GetResponsiveConfig("milking")
	local scaleFactor = self:GetScaleFactor()

	-- Create main GUI
	local gui = Instance.new("ScreenGui")
	gui.Name = "ChairMilkingGUI"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = PlayerGui

	-- Main container with responsive sizing
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = config.size
	container.Position = config.position
	container.BackgroundColor3 = Color3.fromRGB(50, 70, 50)
	container.BackgroundTransparency = 0.1
	container.BorderSizePixel = 0
	container.Parent = gui

	-- Corner rounding (responsive)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.06, 0)
	corner.Parent = container

	-- Gradient background
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 100, 70)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 70, 50))
	}
	gradient.Rotation = 90
	gradient.Parent = container

	-- Border glow effect
	local glow = Instance.new("UIStroke")
	glow.Color = Color3.fromRGB(100, 255, 100)
	glow.Thickness = math.max(1, 2 * scaleFactor)
	glow.Transparency = 0.5
	glow.Parent = container

	-- Title bar (responsive)
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0.22, 0)
	titleBar.Position = UDim2.new(0, 0, 0, 0)
	titleBar.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = container

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0.06, 0)
	titleCorner.Parent = titleBar

	-- Title (responsive)
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.75, 0, 1, 0)
	title.Position = UDim2.new(0.02, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = data.title or "🥛 Chair Milking Active"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.TextStrokeTransparency = 0
	title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	title.Parent = titleBar

	-- Responsive stop button
	local stopButtonSize = self.State.deviceType == "Mobile" and UDim2.new(0.2, 0, 0.8, 0) or UDim2.new(0.15, 0, 0.8, 0)
	local stopButton = Instance.new("TextButton")
	stopButton.Name = "StopButton"
	stopButton.Size = stopButtonSize
	stopButton.Position = UDim2.new(0.98 - stopButtonSize.X.Scale, 0, 0.1, 0)
	stopButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	stopButton.BorderSizePixel = 0
	stopButton.Text = "✕"
	stopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	stopButton.TextScaled = true
	stopButton.Font = Enum.Font.GothamBold
	stopButton.Parent = titleBar

	local stopCorner = Instance.new("UICorner")
	stopCorner.CornerRadius = UDim.new(0.3, 0)
	stopCorner.Parent = stopButton

	stopButton.MouseButton1Click:Connect(function()
		self:RequestStopMilking()
	end)

	-- Content area (responsive)
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(0.95, 0, 0.75, 0)
	content.Position = UDim2.new(0.025, 0, 0.23, 0)
	content.BackgroundTransparency = 1
	content.Parent = container

	-- Subtitle (responsive)
	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(1, 0, 0.25, 0)
	subtitle.Position = UDim2.new(0, 0, 0, 0)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = data.subtitle or self:GetDeviceSpecificMilkingSubtitle()
	subtitle.TextColor3 = Color3.fromRGB(255, 255, 100)
	subtitle.TextScaled = true
	subtitle.Font = Enum.Font.GothamBold
	subtitle.Parent = content

	-- Instructions (responsive)
	local instructionText = data.instruction or self:GetDeviceSpecificMilkingInstructions()
	local instruction = Instance.new("TextLabel")
	instruction.Name = "Instruction"
	instruction.Size = UDim2.new(1, 0, 0.5, 0)
	instruction.Position = UDim2.new(0, 0, 0.25, 0)
	instruction.BackgroundTransparency = 1
	instruction.Text = instructionText
	instruction.TextColor3 = Color3.fromRGB(200, 255, 200)
	instruction.TextScaled = true
	instruction.Font = Enum.Font.Gotham
	instruction.TextWrapped = true
	instruction.Parent = content

	-- Click prompt animation (responsive)
	local clickPrompt = Instance.new("TextLabel")
	clickPrompt.Name = "ClickPrompt"
	clickPrompt.Size = UDim2.new(1, 0, 0.25, 0)
	clickPrompt.Position = UDim2.new(0, 0, 0.75, 0)
	clickPrompt.BackgroundTransparency = 1
	clickPrompt.Text = self:GetDeviceSpecificClickPrompt()
	clickPrompt.TextColor3 = Color3.fromRGB(100, 255, 100)
	clickPrompt.TextScaled = true
	clickPrompt.Font = Enum.Font.GothamBold
	clickPrompt.Parent = content

	-- Animate click prompt
	self:StartClickPromptAnimation(clickPrompt)

	-- Responsive fade in animation
	local startPosition = UDim2.new(config.position.X.Scale, 0, -0.5, 0)
	container.Position = startPosition
	container.BackgroundTransparency = 1

	local tween = TweenService:Create(container,
		TweenInfo.new(self.Config.milkingFadeTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			Position = config.position,
			BackgroundTransparency = 0.1
		}
	)
	tween:Play()

	self.State.currentGUI = gui
	print("ChairMilkingGUI: Responsive milking session GUI created for " .. self.State.deviceType)
end

-- ========== DEVICE-SPECIFIC TEXT ==========

function ChairMilkingGUI:GetDeviceSpecificInstruction()
	if self.State.deviceType == "Mobile" then
		return "📱 Tap the chair to sit down"
	elseif self.State.deviceType == "Tablet" then
		return "📱 Tap the chair to sit down"
	else
		return "🖱️ Walk up to the chair and sit down"
	end
end

function ChairMilkingGUI:GetDeviceSpecificMilkingSubtitle()
	if self.State.deviceType == "Mobile" then
		return "Tap to collect milk!"
	elseif self.State.deviceType == "Tablet" then
		return "Tap to collect milk!"
	else
		return "Click to collect milk!"
	end
end

function ChairMilkingGUI:GetDeviceSpecificMilkingInstructions()
	if self.State.deviceType == "Mobile" then
		return "Stay seated to continue milking.\nLeave chair to stop.\n\nTap the ✕ button to stop milking"
	elseif self.State.deviceType == "Tablet" then
		return "Stay seated to continue milking.\nLeave chair to stop.\n\nTap ✕ button or ESC key to stop"
	else
		return "Stay seated to continue milking.\nLeave chair to stop.\n\nESC key = Stop milking"
	end
end

function ChairMilkingGUI:GetDeviceSpecificClickPrompt()
	if self.State.deviceType == "Mobile" then
		return "📱 TAP ANYWHERE TO COLLECT MILK!"
	elseif self.State.deviceType == "Tablet" then
		return "📱 TAP ANYWHERE TO COLLECT MILK!"
	else
		return "🖱️ CLICK ANYWHERE TO COLLECT MILK!"
	end
end

-- ========== ANIMATIONS ==========

function ChairMilkingGUI:StartPulseAnimation(element)
	spawn(function()
		while element and element.Parent and self.State.guiType == "proximity" do
			local scaleFactor = self:GetScaleFactor()
			local pulseAmount = UDim2.new(0.02 * scaleFactor, 0, 0.02 * scaleFactor, 0)

			local pulse = TweenService:Create(element,
				TweenInfo.new(self.Config.pulseSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Size = element.Size + pulseAmount}
			)
			pulse:Play()
			pulse.Completed:Wait()

			if not element or not element.Parent then break end

			local pulseBack = TweenService:Create(element,
				TweenInfo.new(self.Config.pulseSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Size = element.Size - pulseAmount}
			)
			pulseBack:Play()
			pulseBack.Completed:Wait()
		end
	end)
end

function ChairMilkingGUI:StartClickPromptAnimation(element)
	spawn(function()
		while element and element.Parent and self.State.guiType == "milking" do
			local flash = TweenService:Create(element,
				TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{TextTransparency = 0.3}
			)
			flash:Play()
			flash.Completed:Wait()

			if not element or not element.Parent then break end

			local flashBack = TweenService:Create(element,
				TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{TextTransparency = 0}
			)
			flashBack:Play()
			flashBack.Completed:Wait()
		end
	end)
end

-- ========== GUI MANAGEMENT ==========

function ChairMilkingGUI:HidePrompt()
	if not self.State.currentGUI then
		return
	end

	print("ChairMilkingGUI: Hiding prompt GUI")

	local gui = self.State.currentGUI
	local container = gui:FindFirstChild("Container")

	if container then
		local config = self:GetResponsiveConfig(self.State.guiType or "proximity")
		local fadeOut = TweenService:Create(container,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{
				Position = UDim2.new(config.position.X.Scale, 0, 1.2, 0),
				BackgroundTransparency = 1
			}
		)
		fadeOut:Play()
		fadeOut.Completed:Connect(function()
			gui:Destroy()
		end)
	else
		gui:Destroy()
	end

	self.State.currentGUI = nil
	self.State.guiType = nil
	self.State.isVisible = false
end

function ChairMilkingGUI:RequestStopMilking()
	print("ChairMilkingGUI: Requesting to stop milking")

	local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if remoteFolder and remoteFolder:FindFirstChild("StopChairMilking") then
		remoteFolder.StopChairMilking:FireServer()
	end
end

-- ========== RESPONSIVE UTILITIES ==========

function ChairMilkingGUI:OnViewportSizeChanged()
	-- Handle viewport changes (orientation changes, window resize)
	local oldDeviceType = self.State.deviceType
	self:DetectDeviceType()

	if oldDeviceType ~= self.State.deviceType then
		print("ChairMilkingGUI: Device type changed from " .. oldDeviceType .. " to " .. self.State.deviceType)

		-- Recreate GUI if visible
		if self.State.currentGUI and self.State.guiType then
			local guiType = self.State.guiType
			local isVisible = self.State.isVisible

			if isVisible then
				self:HidePrompt()
				wait(0.1)
				-- Note: Would need to store the data to recreate properly
				-- For now, just hide - server will need to resend
			end
		end
	end
end

-- ========== ERROR HANDLING ==========

function ChairMilkingGUI:HandleError(errorMsg)
	warn("ChairMilkingGUI: Error - " .. tostring(errorMsg))

	-- Clean up any broken GUI
	if self.State.currentGUI then
		pcall(function()
			self.State.currentGUI:Destroy()
		end)
		self.State.currentGUI = nil
		self.State.guiType = nil
		self.State.isVisible = false
	end
end

-- ========== CLEANUP ==========

function ChairMilkingGUI:Cleanup()
	-- Disconnect all connections
	for _, connection in pairs(self.State.connections) do
		if connection and connection.Connected then
			connection:Disconnect()
		end
	end
	self.State.connections = {}

	-- Destroy GUI
	if self.State.currentGUI then
		self.State.currentGUI:Destroy()
		self.State.currentGUI = nil
	end

	self.State.guiType = nil
	self.State.isVisible = false

	print("ChairMilkingGUI: Cleaned up")
end

-- ========== DEBUG FUNCTIONS ==========

function ChairMilkingGUI:DebugStatus()
	print("=== RESPONSIVE CHAIR MILKING GUI DEBUG ===")
	print("Device Type:", self.State.deviceType)
	print("Scale Factor:", self:GetScaleFactor())
	print("Current GUI exists:", self.State.currentGUI ~= nil)
	print("GUI Type:", self.State.guiType or "none")
	print("Is Visible:", self.State.isVisible)
	print("Active connections:", #self.State.connections)
	print("Touch Enabled:", UserInputService.TouchEnabled)
	print("Keyboard Enabled:", UserInputService.KeyboardEnabled)

	if workspace.CurrentCamera then
		local viewport = workspace.CurrentCamera.ViewportSize
		print("Viewport Size:", viewport.X .. "x" .. viewport.Y)
	end

	print("==========================================")
end

-- Make debug function global
_G.DebugChairGUI = function()
	ChairMilkingGUI:DebugStatus()
end

-- ========== VIEWPORT MONITORING ==========

-- Monitor viewport changes
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	ChairMilkingGUI:OnViewportSizeChanged()
end)

-- ========== INITIALIZATION ==========

-- Handle player leaving
game:GetService("Players").PlayerRemoving:Connect(function(player)
	if player == LocalPlayer then
		ChairMilkingGUI:Cleanup()
	end
end)

-- Initialize the system
ChairMilkingGUI:Initialize()
_G.ChairMilkingGUI = ChairMilkingGUI

print("ChairMilkingGUI: ✅ RESPONSIVE chair GUI system loaded!")
print("📱 RESPONSIVE FEATURES:")
print("  📏 Scale-based sizing for all devices")
print("  📊 Device-specific scaling: Mobile(1.3x), Tablet(1.15x), Desktop(1.0x)")
print("  📱 Touch-optimized controls and text")
print("  🔄 Dynamic viewport size monitoring")
print("  📐 Adaptive positioning based on device")
print("  🎯 Device-specific interaction prompts")
print("")
print("🎮 Device Adaptations:")
print("  📱 Mobile: Large touch targets, simplified text")
print("  📱 Tablet: Medium sizing, hybrid controls")
print("  🖥️ Desktop: Standard sizing, full features")
print("")
print("🔧 Debug Command:")
print("  _G.DebugChairGUI() - Show responsive GUI debug info")