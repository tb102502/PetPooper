--[[
    UPDATED ChairMilkingGUI.client.lua - 10-Click Progress System
    Place in: StarterPlayer/StarterPlayerScripts/ChairMilkingGUI.client.lua
    
    UPDATED FEATURES:
    ✅ Progress bar for 10-click system
    ✅ Visual feedback for each click
    ✅ Progress percentage display
    ✅ Enhanced mobile support
    ✅ Real-time progress updates
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
	deviceType = "Desktop",
	-- NEW: Progress tracking
	currentProgress = 0,
	clicksPerMilk = 10,
	progressElements = {}
}

-- Configuration
ChairMilkingGUI.Config = {
	proximityFadeTime = 0.3,
	milkingFadeTime = 0.5,
	pulseSpeed = 2,
	-- Progress animation config
	progressAnimationSpeed = 0.3,
	clickFeedbackDuration = 0.5,
	-- Device scaling
	scaling = {
		Mobile = 1.3,
		Tablet = 1.15,
		Desktop = 1.0
	},
	-- Responsive positioning
	positioning = {
		Mobile = {
			proximity = {size = UDim2.new(0.7, 0, 0.15, 0), position = UDim2.new(0.15, 0, 0.8, 0)},
			milking = {size = UDim2.new(0.85, 0, 0.25, 0), position = UDim2.new(0.075, 0, 0.001, 0)} -- Very top edge
		},
		Tablet = {
			proximity = {size = UDim2.new(0.5, 0, 0.12, 0), position = UDim2.new(0.25, 0, 0.82, 0)},
			milking = {size = UDim2.new(0.6, 0, 0.2, 0), position = UDim2.new(0.2, 0, 0.001, 0)} -- Very top edge
		},
		Desktop = {
			proximity = {size = UDim2.new(0.3, 0, 0.1, 0), position = UDim2.new(0.35, 0, 0.85, 0)},
			milking = {size = UDim2.new(0.4, 0, 0.15, 0), position = UDim2.new(0.3, 0, 0.001, 0)} -- Very top edge
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
	print("ChairMilkingGUI: Initializing 10-click progress GUI system...")

	-- Detect device type
	self:DetectDeviceType()

	-- Setup remote connections
	self:SetupRemoteConnections()

	-- Setup input handling
	self:SetupInputHandling()

	print("ChairMilkingGUI: 10-click progress GUI system initialized!")
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

	-- NEW: Handle milking session updates for progress
	local sessionUpdate = remoteFolder:WaitForChild("MilkingSessionUpdate", 5)
	if sessionUpdate then
		sessionUpdate.OnClientEvent:Connect(function(updateType, data)
			pcall(function()
				self:HandleSessionUpdate(updateType, data)
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

-- ========== NEW: SESSION UPDATE HANDLING ==========

function ChairMilkingGUI:HandleSessionUpdate(updateType, data)
	if updateType == "progress" and self.State.guiType == "milking" then
		-- Update progress display
		self.State.currentProgress = data.clickProgress or 0
		self.State.clicksPerMilk = data.clicksPerMilk or 10

		print("📊 Progress update: " .. self.State.currentProgress .. "/" .. self.State.clicksPerMilk .. " clicks")

		-- Update visual elements
		self:UpdateProgressDisplay(data)

		-- Create click feedback
		self:CreateProgressClickFeedback(data)
	end
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
		-- NEW: Initialize progress state
		self.State.currentProgress = data.currentProgress or 0
		self.State.clicksPerMilk = data.clicksPerMilk or 10
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
	corner.CornerRadius = UDim.new(0.08, 0)
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
	instruction.Text = data.instruction or self:GetDeviceSpecificInstruction()
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
	print("ChairMilkingGUI: Creating responsive 10-click milking GUI for " .. self.State.deviceType)

	-- Get responsive configuration
	local config = self:GetResponsiveConfig("milking")
	local scaleFactor = self:GetScaleFactor()

	-- Create main GUI
	local gui = Instance.new("ScreenGui")
	gui.Name = "ChairMilkingGUI"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = PlayerGui

	-- Main container with responsive sizing (larger for progress bar)
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = config.size
	container.Position = config.position
	container.BackgroundColor3 = Color3.fromRGB(20, 30, 20) -- Darker
	container.BackgroundTransparency = 0.4 -- Much more transparent (was 0.1)
	container.BorderSizePixel = 0
	container.Parent = gui

	-- Corner rounding (responsive)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.06, 0)
	corner.Parent = container

	-- Gradient background
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 50, 30)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 30, 20))
	}
	gradient.Rotation = 90
	gradient.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.4), -- More transparent gradient
		NumberSequenceKeypoint.new(1, 0.6)
	}
	gradient.Parent = container

	-- Border glow effect
	local glow = Instance.new("UIStroke")
	glow.Color = Color3.fromRGB(100, 255, 100)
	glow.Thickness = math.max(1, 1 * scaleFactor) -- Thinner border
	glow.Transparency = 0.7 -- More transparent border (was 0.5)
	glow.Parent = container

	-- Title bar (responsive)
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0.18, 0)
	titleBar.Position = UDim2.new(0, 0, 0, 0)
	titleBar.BackgroundColor3 = Color3.fromRGB(25, 40, 25) -- Darker
	titleBar.BackgroundTransparency = 0.3 -- More transparent (was 0)
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
	title.Text = data.title or "🥛 10-Click Milking Active"
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
	content.Size = UDim2.new(0.95, 0, 0.8, 0)
	content.Position = UDim2.new(0.025, 0, 0.19, 0)
	content.BackgroundTransparency = 1
	content.Parent = container

	-- NEW: Progress section (takes more space)
	local progressSection = Instance.new("Frame")
	progressSection.Name = "ProgressSection"
	progressSection.Size = UDim2.new(1, 0, 0.4, 0)
	progressSection.Position = UDim2.new(0, 0, 0, 0)
	progressSection.BackgroundTransparency = 1
	progressSection.Parent = content

	-- Progress title
	local progressTitle = Instance.new("TextLabel")
	progressTitle.Name = "ProgressTitle"
	progressTitle.Size = UDim2.new(1, 0, 0.35, 0)
	progressTitle.Position = UDim2.new(0, 0, 0, 0)
	progressTitle.BackgroundTransparency = 1
	progressTitle.Text = "Progress: " .. self.State.currentProgress .. "/" .. self.State.clicksPerMilk .. " clicks"
	progressTitle.TextColor3 = Color3.fromRGB(255, 255, 100)
	progressTitle.TextScaled = true
	progressTitle.Font = Enum.Font.GothamBold
	progressTitle.Parent = progressSection

	-- Progress bar background
	local progressBarBG = Instance.new("Frame")
	progressBarBG.Name = "ProgressBarBG"
	progressBarBG.Size = UDim2.new(1, 0, 0.25, 0) -- Slightly thinner progress bar
	progressBarBG.Position = UDim2.new(0, 0, 0.35, 0)
	progressBarBG.BackgroundColor3 = Color3.fromRGB(15, 15, 15) -- Much darker
	progressBarBG.BackgroundTransparency = 0.3 -- More transparent (was 0)
	progressBarBG.BorderSizePixel = 0
	progressBarBG.Parent = progressSection

	local progressBGCorner = Instance.new("UICorner")
	progressBGCorner.CornerRadius = UDim.new(0.3, 0)
	progressBGCorner.Parent = progressBarBG

	-- Progress bar fill
	local progressBarFill = Instance.new("Frame")
	progressBarFill.Name = "ProgressBarFill"
	progressBarFill.Size = UDim2.new(self.State.currentProgress / self.State.clicksPerMilk, 0, 1, 0)
	progressBarFill.Position = UDim2.new(0, 0, 0, 0)
	progressBarFill.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
	progressBarFill.BorderSizePixel = 0
	progressBarFill.Parent = progressBarBG

	local progressFillCorner = Instance.new("UICorner")
	progressFillCorner.CornerRadius = UDim.new(0.3, 0)
	progressFillCorner.Parent = progressBarFill

	-- Progress percentage
	local progressPercentage = Instance.new("TextLabel")
	progressPercentage.Name = "ProgressPercentage"
	progressPercentage.Size = UDim2.new(1, 0, 0.35, 0)
	progressPercentage.Position = UDim2.new(0, 0, 0.65, 0)
	progressPercentage.BackgroundTransparency = 1
	progressPercentage.Text = math.floor((self.State.currentProgress / self.State.clicksPerMilk) * 100) .. "% complete"
	progressPercentage.TextColor3 = Color3.fromRGB(200, 255, 200)
	progressPercentage.TextScaled = true
	progressPercentage.Font = Enum.Font.Gotham
	progressPercentage.Parent = progressSection

	-- Store progress elements for updates
	self.State.progressElements = {
		title = progressTitle,
		fill = progressBarFill,
		percentage = progressPercentage
	}

	-- Milk counter section
	local milkSection = Instance.new("Frame")
	milkSection.Name = "MilkSection"
	milkSection.Size = UDim2.new(1, 0, 0.25, 0)
	milkSection.Position = UDim2.new(0, 0, 0.42, 0)
	milkSection.BackgroundTransparency = 1
	milkSection.Parent = content

	local milkCounter = Instance.new("TextLabel")
	milkCounter.Name = "MilkCounter"
	milkCounter.Size = UDim2.new(1, 0, 1, 0)
	milkCounter.Position = UDim2.new(0, 0, 0, 0)
	milkCounter.BackgroundTransparency = 1
	milkCounter.Text = "🥛 Milk Collected: 0"
	milkCounter.TextColor3 = Color3.fromRGB(255, 255, 100)
	milkCounter.TextScaled = true
	milkCounter.Font = Enum.Font.GothamBold
	milkCounter.Parent = milkSection

	-- Instructions section
	local instructionSection = Instance.new("Frame")
	instructionSection.Name = "InstructionSection"
	instructionSection.Size = UDim2.new(1, 0, 0.33, 0)
	instructionSection.Position = UDim2.new(0, 0, 0.67, 0)
	instructionSection.BackgroundTransparency = 1
	instructionSection.Parent = content

	local instruction = Instance.new("TextLabel")
	instruction.Name = "Instruction"
	instruction.Size = UDim2.new(1, 0, 0.6, 0)
	instruction.Position = UDim2.new(0, 0, 0, 0)
	instruction.BackgroundTransparency = 1
	instruction.Text = self:GetDeviceSpecificMilkingInstructions()
	instruction.TextColor3 = Color3.fromRGB(200, 255, 200)
	instruction.TextScaled = true
	instruction.Font = Enum.Font.Gotham
	instruction.TextWrapped = true
	instruction.Parent = instructionSection

	-- Click prompt animation (responsive)
	local clickPrompt = Instance.new("TextLabel")
	clickPrompt.Name = "ClickPrompt"
	clickPrompt.Size = UDim2.new(1, 0, 0.4, 0)
	clickPrompt.Position = UDim2.new(0, 0, 0.6, 0)
	clickPrompt.BackgroundTransparency = 1
	clickPrompt.Text = self:GetDeviceSpecificClickPrompt()
	clickPrompt.TextColor3 = Color3.fromRGB(100, 255, 100)
	clickPrompt.TextScaled = true
	clickPrompt.Font = Enum.Font.GothamBold
	clickPrompt.Parent = instructionSection

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
	print("ChairMilkingGUI: Responsive 10-click milking GUI created for " .. self.State.deviceType)
end

-- ========== NEW: PROGRESS UPDATE FUNCTIONS ==========

function ChairMilkingGUI:UpdateProgressDisplay(data)
	if not self.State.progressElements then return end

	local progressTitle = self.State.progressElements.title
	local progressFill = self.State.progressElements.fill
	local progressPercentage = self.State.progressElements.percentage

	if progressTitle then
		progressTitle.Text = "Progress: " .. self.State.currentProgress .. "/" .. self.State.clicksPerMilk .. " clicks"
	end

	if progressFill then
		local fillPercentage = self.State.currentProgress / self.State.clicksPerMilk
		local tween = TweenService:Create(progressFill,
			TweenInfo.new(self.Config.progressAnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = UDim2.new(fillPercentage, 0, 1, 0)}
		)
		tween:Play()

		-- Color changes as progress increases
		local fillColor = Color3.fromRGB(
			math.floor(100 + (155 * fillPercentage)), -- Red component increases
			255, -- Keep green high
			math.floor(100 * (1 - fillPercentage)) -- Blue decreases
		)
		progressFill.BackgroundColor3 = fillColor
	end

	if progressPercentage then
		local percentage = math.floor((self.State.currentProgress / self.State.clicksPerMilk) * 100)
		progressPercentage.Text = percentage .. "% complete"
	end

	-- Update milk counter if available
	if data.milkCollected then
		local gui = self.State.currentGUI
		if gui then
			local milkCounter = gui:FindFirstChild("Container", true) and 
				gui.Container:FindFirstChild("Content", true) and
				gui.Container.Content:FindFirstChild("MilkSection", true) and
				gui.Container.Content.MilkSection:FindFirstChild("MilkCounter", true)

			if milkCounter then
				milkCounter.Text = "🥛 Milk Collected: " .. data.milkCollected

				-- Flash effect when milk is collected
				if data.milkCollected > 0 and self.State.currentProgress == 0 then
					local flash = TweenService:Create(milkCounter,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true),
						{TextColor3 = Color3.fromRGB(100, 255, 100)}
					)
					flash:Play()
				end
			end
		end
	end
end

function ChairMilkingGUI:CreateProgressClickFeedback(data)
	-- Create visual feedback at click location
	local mouse = LocalPlayer:GetMouse()
	local clickPos = Vector2.new(mouse.X, mouse.Y)

	-- Create feedback GUI
	local feedbackGui = Instance.new("ScreenGui")
	feedbackGui.Name = "ClickFeedback"
	feedbackGui.Parent = PlayerGui

	-- Create +1 click indicator
	local clickText = Instance.new("TextLabel")
	clickText.Size = UDim2.new(0, 60, 0, 30)
	clickText.Position = UDim2.new(0, clickPos.X - 30, 0, clickPos.Y - 15)
	clickText.BackgroundTransparency = 1
	clickText.Text = "+1 (" .. self.State.currentProgress .. "/" .. self.State.clicksPerMilk .. ")"
	clickText.TextColor3 = Color3.fromRGB(100, 255, 100)
	clickText.TextScaled = true
	clickText.Font = Enum.Font.GothamBold
	clickText.TextStrokeTransparency = 0
	clickText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	clickText.Parent = feedbackGui

	-- Animate text floating up
	local floatUp = TweenService:Create(clickText,
		TweenInfo.new(self.Config.clickFeedbackDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Position = clickText.Position + UDim2.new(0, 0, 0, -40),
			TextTransparency = 1,
			TextStrokeTransparency = 1
		}
	)
	floatUp:Play()

	floatUp.Completed:Connect(function()
		feedbackGui:Destroy()
	end)

	-- If progress completed (reached 10), show milk completion effect
	if self.State.currentProgress == 0 and data.milkCollected and data.milkCollected > 0 then
		self:CreateMilkCompletionEffect()
	end
end

function ChairMilkingGUI:CreateMilkCompletionEffect()
	-- Create milk completion celebration
	local celebrationGui = Instance.new("ScreenGui")
	celebrationGui.Name = "MilkCelebration"
	celebrationGui.Parent = PlayerGui

	local milkIcon = Instance.new("TextLabel")
	milkIcon.Size = UDim2.new(0, 100, 0, 100)
	milkIcon.Position = UDim2.new(0.5, -50, 0.5, -50)
	milkIcon.BackgroundTransparency = 1
	milkIcon.Text = "🥛"
	milkIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
	milkIcon.TextScaled = true
	milkIcon.Font = Enum.Font.GothamBold
	milkIcon.Parent = celebrationGui

	-- Create celebration text
	local celebrationText = Instance.new("TextLabel")
	celebrationText.Size = UDim2.new(0, 200, 0, 50)
	celebrationText.Position = UDim2.new(0.5, -100, 0.5, 60)
	celebrationText.BackgroundTransparency = 1
	celebrationText.Text = "MILK COLLECTED!"
	celebrationText.TextColor3 = Color3.fromRGB(255, 255, 100)
	celebrationText.TextScaled = true
	celebrationText.Font = Enum.Font.GothamBold
	celebrationText.TextStrokeTransparency = 0
	celebrationText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	celebrationText.Parent = celebrationGui

	-- Animate celebration
	local celebrate = TweenService:Create(milkIcon,
		TweenInfo.new(1, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
		{
			Size = UDim2.new(0, 150, 0, 150),
			Position = UDim2.new(0.5, -75, 0.5, -75)
		}
	)
	celebrate:Play()

	local textCelebrate = TweenService:Create(celebrationText,
		TweenInfo.new(1, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
		{
			Size = UDim2.new(0, 250, 0, 60),
			Position = UDim2.new(0.5, -125, 0.5, 80)
		}
	)
	textCelebrate:Play()

	-- Clean up after animation - FIX: Fade out individual elements instead of ScreenGui
	spawn(function()
		wait(1.5)

		-- Fade out the milk icon
		local fadeOutIcon = TweenService:Create(milkIcon,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				TextTransparency = 1
			}
		)

		-- Fade out the celebration text
		local fadeOutText = TweenService:Create(celebrationText,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				TextTransparency = 1,
				TextStrokeTransparency = 1
			}
		)

		-- Play both fade animations
		fadeOutIcon:Play()
		fadeOutText:Play()

		-- Clean up when icon fade completes
		fadeOutIcon.Completed:Connect(function()
			celebrationGui:Destroy()
		end)
	end)
end
-- ========== DEVICE-SPECIFIC TEXT ==========

function ChairMilkingGUI:GetDeviceSpecificInstruction()
	if self.State.deviceType == "Mobile" then
		return "📱 Tap the MilkingChair to sit down"
	elseif self.State.deviceType == "Tablet" then
		return "📱 Tap the MilkingChair to sit down"
	else
		return "🖱️ Walk up to the MilkingChair and sit down"
	end
end

function ChairMilkingGUI:GetDeviceSpecificMilkingInstructions()
	if self.State.deviceType == "Mobile" then
		return "Stay seated to continue milking.\nLeave chair to stop.\n\n" .. self.State.clicksPerMilk .. " taps = 1 milk!"
	elseif self.State.deviceType == "Tablet" then
		return "Stay seated to continue milking.\nLeave chair to stop.\n\n" .. self.State.clicksPerMilk .. " taps = 1 milk!"
	else
		return "Stay seated to continue milking.\nLeave chair to stop.\n\n" .. self.State.clicksPerMilk .. " clicks = 1 milk!"
	end
end

function ChairMilkingGUI:GetDeviceSpecificClickPrompt()
	if self.State.deviceType == "Mobile" then
		return "📱 TAP " .. self.State.clicksPerMilk .. " TIMES FOR 1 MILK!"
	elseif self.State.deviceType == "Tablet" then
		return "📱 TAP " .. self.State.clicksPerMilk .. " TIMES FOR 1 MILK!"
	else
		return "🖱️ CLICK " .. self.State.clicksPerMilk .. " TIMES FOR 1 MILK!"
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
	self.State.progressElements = {}
end

function ChairMilkingGUI:RequestStopMilking()
	print("ChairMilkingGUI: Requesting to stop milking")

	local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if remoteFolder and remoteFolder:FindFirstChild("StopMilkingSession") then
		remoteFolder.StopMilkingSession:FireServer()
	end
end

-- ========== DEBUG FUNCTIONS ==========

function ChairMilkingGUI:DebugStatus()
	print("=== 10-CLICK CHAIR MILKING GUI DEBUG ===")
	print("Device Type:", self.State.deviceType)
	print("Scale Factor:", self:GetScaleFactor())
	print("Current GUI exists:", self.State.currentGUI ~= nil)
	print("GUI Type:", self.State.guiType or "none")
	print("Is Visible:", self.State.isVisible)
	print("Current Progress:", self.State.currentProgress .. "/" .. self.State.clicksPerMilk)
	print("Progress Elements:", self.State.progressElements and "Available" or "None")

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

-- ========== INITIALIZATION ==========

-- Initialize the system
ChairMilkingGUI:Initialize()
_G.ChairMilkingGUI = ChairMilkingGUI

print("ChairMilkingGUI: ✅ 10-CLICK PROGRESS GUI SYSTEM LOADED!")
print("📊 NEW FEATURES:")
print("  📈 Progress bar (0-10 clicks)")
print("  🎯 Visual progress percentage")
print("  ✨ Click feedback with progress")
print("  🥛 Milk completion celebration")
print("  📱 Mobile-optimized progress display")
print("")
print("🎮 Progress Features:")
print("  📊 Real-time progress bar")
print("  🖱️ Visual click feedback")
print("  🎉 Milk collection celebration")
print("  📈 Percentage completion display")
print("")
print("🔧 Debug Command:")
print("  _G.DebugChairGUI() - Show 10-click GUI debug info")