--[[
    ChairMilkingGUI.client.lua - Chair Milking GUI System
    Place in: StarterPlayer/StarterPlayerScripts/ChairMilkingGUI.client.lua
    
    Features:
    ✅ Proximity prompts for chairs
    ✅ Active milking session GUI
    ✅ Instructions and feedback
    ✅ Mobile-friendly design
    ✅ Smooth animations
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
	connections = {}
}

-- Configuration
ChairMilkingGUI.Config = {
	proximityFadeTime = 0.3,
	milkingFadeTime = 0.5,
	pulseSpeed = 2,
	mobileScaling = 1.2
}

-- ========== INITIALIZATION ==========

function ChairMilkingGUI:Initialize()
	print("ChairMilkingGUI: Initializing client-side chair GUI system...")

	-- Setup remote connections
	self:SetupRemoteConnections()

	-- Setup input handling
	self:SetupInputHandling()

	print("ChairMilkingGUI: Client GUI system initialized!")
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

-- ========== GUI CREATION ==========

function ChairMilkingGUI:ShowPrompt(promptType, data)
	-- Hide existing GUI first
	if self.State.currentGUI then
		self:HidePrompt()
		wait(0.1)
	end

	self.State.guiType = promptType

	if promptType == "proximity" then
		self:CreateProximityGUI(data)
	elseif promptType == "milking" then
		self:CreateMilkingGUI(data)
	end

	self.State.isVisible = true
end

function ChairMilkingGUI:CreateProximityGUI(data)
	print("ChairMilkingGUI: Creating proximity GUI")

	-- Create main GUI
	local gui = Instance.new("ScreenGui")
	gui.Name = "ChairProximityGUI"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = PlayerGui

	-- Main container
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 350, 0, 150)
	container.Position = UDim2.new(0.5, -175, 0.8, -75)
	container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	container.BackgroundTransparency = 0.1
	container.BorderSizePixel = 0
	container.Parent = gui

	-- Corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = container

	-- Gradient background
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 60)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 40))
	}
	gradient.Rotation = 90
	gradient.Parent = container

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.4, 0)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = data.title or "🪑 Milking Chair"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.TextStrokeTransparency = 0
	title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	title.Parent = container

	-- Subtitle
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

	-- Instruction
	local instruction = Instance.new("TextLabel")
	instruction.Name = "Instruction"
	instruction.Size = UDim2.new(1, 0, 0.3, 0)
	instruction.Position = UDim2.new(0, 0, 0.7, 0)
	instruction.BackgroundTransparency = 1
	instruction.Text = data.instruction or "Walk up to the chair and sit down"
	instruction.TextColor3 = Color3.fromRGB(200, 200, 200)
	instruction.TextScaled = true
	instruction.Font = Enum.Font.Gotham
	instruction.Parent = container

	-- Pulse animation for proximity GUI
	self:StartPulseAnimation(container)

	-- Fade in animation
	container.Position = UDim2.new(0.5, -175, 1, 0)
	container.BackgroundTransparency = 1

	local tween = TweenService:Create(container,
		TweenInfo.new(self.Config.proximityFadeTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			Position = UDim2.new(0.5, -175, 0.8, -75),
			BackgroundTransparency = 0.1
		}
	)
	tween:Play()

	self.State.currentGUI = gui
	print("ChairMilkingGUI: Proximity GUI created")
end

function ChairMilkingGUI:CreateMilkingGUI(data)
	print("ChairMilkingGUI: Creating milking session GUI")

	-- Create main GUI
	local gui = Instance.new("ScreenGui")
	gui.Name = "ChairMilkingGUI"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = PlayerGui

	-- Main container
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 400, 0, 200)
	container.Position = UDim2.new(0.5, -200, 0.1, 0)
	container.BackgroundColor3 = Color3.fromRGB(50, 70, 50)
	container.BackgroundTransparency = 0.1
	container.BorderSizePixel = 0
	container.Parent = gui

	-- Corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 15)
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
	glow.Thickness = 2
	glow.Transparency = 0.5
	glow.Parent = container

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0.25, 0)
	titleBar.Position = UDim2.new(0, 0, 0, 0)
	titleBar.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = container

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 15)
	titleCorner.Parent = titleBar

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.8, 0, 1, 0)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = data.title or "🥛 Chair Milking Active"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.TextStrokeTransparency = 0
	title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	title.Parent = titleBar

	-- Stop button
	local stopButton = Instance.new("TextButton")
	stopButton.Name = "StopButton"
	stopButton.Size = UDim2.new(0.15, 0, 0.8, 0)
	stopButton.Position = UDim2.new(0.83, 0, 0.1, 0)
	stopButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	stopButton.BorderSizePixel = 0
	stopButton.Text = "✕"
	stopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	stopButton.TextScaled = true
	stopButton.Font = Enum.Font.GothamBold
	stopButton.Parent = titleBar

	local stopCorner = Instance.new("UICorner")
	stopCorner.CornerRadius = UDim.new(0, 8)
	stopCorner.Parent = stopButton

	stopButton.MouseButton1Click:Connect(function()
		self:RequestStopMilking()
	end)

	-- Content area
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -20, 0.75, -10)
	content.Position = UDim2.new(0, 10, 0.25, 5)
	content.BackgroundTransparency = 1
	content.Parent = container

	-- Subtitle
	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(1, 0, 0.3, 0)
	subtitle.Position = UDim2.new(0, 0, 0, 0)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = data.subtitle or "Click to collect milk!"
	subtitle.TextColor3 = Color3.fromRGB(255, 255, 100)
	subtitle.TextScaled = true
	subtitle.Font = Enum.Font.GothamBold
	subtitle.Parent = content

	-- Instructions
	local instructionText = data.instruction or "Stay seated to continue milking.\nLeave chair to stop.\n\nESC key = Stop milking"
	local instruction = Instance.new("TextLabel")
	instruction.Name = "Instruction"
	instruction.Size = UDim2.new(1, 0, 0.5, 0)
	instruction.Position = UDim2.new(0, 0, 0.3, 0)
	instruction.BackgroundTransparency = 1
	instruction.Text = instructionText
	instruction.TextColor3 = Color3.fromRGB(200, 255, 200)
	instruction.TextScaled = true
	instruction.Font = Enum.Font.Gotham
	instruction.TextWrapped = true
	instruction.Parent = content

	-- Click prompt animation
	local clickPrompt = Instance.new("TextLabel")
	clickPrompt.Name = "ClickPrompt"
	clickPrompt.Size = UDim2.new(1, 0, 0.2, 0)
	clickPrompt.Position = UDim2.new(0, 0, 0.8, 0)
	clickPrompt.BackgroundTransparency = 1
	clickPrompt.Text = "🖱️ CLICK ANYWHERE TO COLLECT MILK!"
	clickPrompt.TextColor3 = Color3.fromRGB(100, 255, 100)
	clickPrompt.TextScaled = true
	clickPrompt.Font = Enum.Font.GothamBold
	clickPrompt.Parent = content

	-- Animate click prompt
	self:StartClickPromptAnimation(clickPrompt)

	-- Fade in animation
	container.Position = UDim2.new(0.5, -200, -0.3, 0)
	container.BackgroundTransparency = 1

	local tween = TweenService:Create(container,
		TweenInfo.new(self.Config.milkingFadeTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			Position = UDim2.new(0.5, -200, 0.1, 0),
			BackgroundTransparency = 0.1
		}
	)
	tween:Play()

	self.State.currentGUI = gui
	print("ChairMilkingGUI: Milking session GUI created")
end

-- ========== ANIMATIONS ==========

function ChairMilkingGUI:StartPulseAnimation(element)
	spawn(function()
		while element and element.Parent and self.State.guiType == "proximity" do
			local pulse = TweenService:Create(element,
				TweenInfo.new(self.Config.pulseSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Size = element.Size + UDim2.new(0, 10, 0, 5)}
			)
			pulse:Play()
			pulse.Completed:Wait()

			if not element or not element.Parent then break end

			local pulseBack = TweenService:Create(element,
				TweenInfo.new(self.Config.pulseSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Size = element.Size - UDim2.new(0, 10, 0, 5)}
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
		local fadeOut = TweenService:Create(container,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{
				Position = container.Position + UDim2.new(0, 0, 0.1, 0),
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

-- ========== MOBILE SUPPORT ==========

function ChairMilkingGUI:IsMobile()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

function ChairMilkingGUI:AdjustForMobile(gui)
	if not self:IsMobile() then return end

	local container = gui:FindFirstChild("Container")
	if container then
		-- Scale up for mobile
		local currentSize = container.Size
		container.Size = UDim2.new(
			currentSize.X.Scale * self.Config.mobileScaling,
			currentSize.X.Offset * self.Config.mobileScaling,
			currentSize.Y.Scale * self.Config.mobileScaling,
			currentSize.Y.Offset * self.Config.mobileScaling
		)

		-- Adjust position to keep centered
		container.Position = UDim2.new(0.5, -container.AbsoluteSize.X/2, container.Position.Y.Scale, container.Position.Y.Offset)
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
	print("=== CHAIR MILKING GUI DEBUG ===")
	print("Current GUI exists:", self.State.currentGUI ~= nil)
	print("GUI Type:", self.State.guiType or "none")
	print("Is Visible:", self.State.isVisible)
	print("Active connections:", #self.State.connections)
	print("Is Mobile:", self:IsMobile())
	print("==============================")
end

-- Make debug function global
_G.DebugChairGUI = function()
	ChairMilkingGUI:DebugStatus()
end

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

print("ChairMilkingGUI: ✅ Client-side chair GUI system loaded!")
print("🎨 GUI FEATURES:")
print("  🪑 Proximity prompts when near chairs")
print("  🥛 Active milking session interface")
print("  📱 Mobile-friendly responsive design")
print("  ✨ Smooth animations and transitions")
print("  🎯 Click-to-stop functionality")
print("  ⌨️ ESC key support")
print("")
print("🔧 Debug Command:")
print("  _G.DebugChairGUI() - Show GUI debug info")