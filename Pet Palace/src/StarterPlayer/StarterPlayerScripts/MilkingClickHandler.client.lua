--[[
    UPDATED MilkingClickHandler.client.lua - 10-Click Progress System
    Place in: StarterPlayer/StarterPlayerScripts/MilkingClickHandler.client.lua
    
    UPDATES:
    ✅ Handles 10-click progress system
    ✅ Enhanced click feedback
    ✅ Better mobile touch support
    ✅ Progress-aware visual effects
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

print("🖱️ MilkingClickHandler: Initializing 10-click system...")

-- State
local MilkingState = {
	isActive = false,
	currentGUI = nil,
	sessionData = {},
	clickCooldown = 0.05, -- Reduced cooldown for 10-click system
	lastClickTime = 0,
	-- NEW: Progress tracking
	currentProgress = 0,
	clicksPerMilk = 10,
	totalClicks = 0,
	milkCollected = 0
}

-- Wait for remote events
local gameRemotes = ReplicatedStorage:WaitForChild("GameRemotes", 10)
if not gameRemotes then
	warn("❌ MilkingClickHandler: GameRemotes not found")
	return
end

local RemoteEvents = {
	ShowChairPrompt = gameRemotes:WaitForChild("ShowChairPrompt", 5),
	HideChairPrompt = gameRemotes:WaitForChild("HideChairPrompt", 5),
	StartMilkingSession = gameRemotes:WaitForChild("StartMilkingSession", 5),
	StopMilkingSession = gameRemotes:WaitForChild("StopMilkingSession", 5),
	ContinueMilking = gameRemotes:WaitForChild("ContinueMilking", 5),
	MilkingSessionUpdate = gameRemotes:WaitForChild("MilkingSessionUpdate", 5)
}

-- Verify remote events
for eventName, event in pairs(RemoteEvents) do
	if event then
		print("✅ Found remote event: " .. eventName)
	else
		warn("❌ Missing remote event: " .. eventName)
	end
end

-- ========== ENHANCED CLICK HANDLING ==========

local function CreateEnhancedClickFeedback()
	local mouse = LocalPlayer:GetMouse()
	local clickPos = Vector2.new(mouse.X, mouse.Y)

	-- Create multiple feedback elements for better effect
	local feedbackGui = Instance.new("ScreenGui")
	feedbackGui.Name = "ClickFeedback"
	feedbackGui.Parent = PlayerGui

	-- Main ripple effect
	local ripple = Instance.new("Frame")
	ripple.Size = UDim2.new(0, 30, 0, 30)
	ripple.Position = UDim2.new(0, clickPos.X - 15, 0, clickPos.Y - 15)
	ripple.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
	ripple.BackgroundTransparency = 0.2
	ripple.BorderSizePixel = 0
	ripple.Parent = feedbackGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = ripple

	-- Animate ripple
	local expand = TweenService:Create(ripple,
		TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = UDim2.new(0, 80, 0, 80),
			Position = UDim2.new(0, clickPos.X - 40, 0, clickPos.Y - 40),
			BackgroundTransparency = 1
		}
	)
	expand:Play()

	-- Progress indicator text
	local progressText = Instance.new("TextLabel")
	progressText.Size = UDim2.new(0, 120, 0, 40)
	progressText.Position = UDim2.new(0, clickPos.X - 60, 0, clickPos.Y - 50)
	progressText.BackgroundTransparency = 1
	progressText.Text = "+" .. 1 .. " (" .. MilkingState.currentProgress .. "/" .. MilkingState.clicksPerMilk .. ")"
	progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
	progressText.TextScaled = true
	progressText.Font = Enum.Font.GothamBold
	progressText.TextStrokeTransparency = 0
	progressText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	progressText.Parent = feedbackGui

	-- Animate progress text
	local floatUp = TweenService:Create(progressText,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Position = progressText.Position + UDim2.new(0, 0, 0, -60),
			TextTransparency = 1,
			TextStrokeTransparency = 1
		}
	)
	floatUp:Play()

	-- Progress bar effect at click location
	if MilkingState.currentProgress > 0 then
		local progressBar = Instance.new("Frame")
		progressBar.Size = UDim2.new(0, 100, 0, 8)
		progressBar.Position = UDim2.new(0, clickPos.X - 50, 0, clickPos.Y + 30)
		progressBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		progressBar.BorderSizePixel = 0
		progressBar.Parent = feedbackGui

		local progressBarCorner = Instance.new("UICorner")
		progressBarCorner.CornerRadius = UDim.new(0.5, 0)
		progressBarCorner.Parent = progressBar

		local progressFill = Instance.new("Frame")
		progressFill.Size = UDim2.new(MilkingState.currentProgress / MilkingState.clicksPerMilk, 0, 1, 0)
		progressFill.Position = UDim2.new(0, 0, 0, 0)
		progressFill.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
		progressFill.BorderSizePixel = 0
		progressFill.Parent = progressBar

		local progressFillCorner = Instance.new("UICorner")
		progressFillCorner.CornerRadius = UDim.new(0.5, 0)
		progressFillCorner.Parent = progressFill

		-- Animate mini progress bar
		local progressTween = TweenService:Create(progressBar,
			TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = progressBar.Position + UDim2.new(0, 0, 0, -40),
				BackgroundTransparency = 1
			}
		)
		progressTween:Play()

		local fillTween = TweenService:Create(progressFill,
			TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundTransparency = 1}
		)
		fillTween:Play()
	end

	-- Clean up
	expand.Completed:Connect(function()
		feedbackGui:Destroy()
	end)
end

local function CreateMilkRewardEffect()
	-- Special effect when 10 clicks are completed and milk is awarded
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MilkReward"
	screenGui.Parent = PlayerGui

	-- Big milk icon
	local milkIcon = Instance.new("TextLabel")
	milkIcon.Size = UDim2.new(0, 80, 0, 80)
	milkIcon.Position = UDim2.new(0.5, -40, 0.3, -40)
	milkIcon.BackgroundTransparency = 1
	milkIcon.Text = "🥛"
	milkIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
	milkIcon.TextScaled = true
	milkIcon.Font = Enum.Font.GothamBold
	milkIcon.Parent = screenGui

	-- Reward text
	local rewardText = Instance.new("TextLabel")
	rewardText.Size = UDim2.new(0, 200, 0, 40)
	rewardText.Position = UDim2.new(0.5, -100, 0.3, 50)
	rewardText.BackgroundTransparency = 1
	rewardText.Text = "+1 MILK EARNED!"
	rewardText.TextColor3 = Color3.fromRGB(255, 255, 100)
	rewardText.TextScaled = true
	rewardText.Font = Enum.Font.GothamBold
	rewardText.TextStrokeTransparency = 0
	rewardText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	rewardText.Parent = screenGui

	-- Animate reward
	local bounceIn = TweenService:Create(milkIcon,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			Size = UDim2.new(0, 120, 0, 120),
			Position = UDim2.new(0.5, -60, 0.3, -60)
		}
	)
	bounceIn:Play()

	local textBounce = TweenService:Create(rewardText,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			Size = UDim2.new(0, 250, 0, 50),
			Position = UDim2.new(0.5, -125, 0.3, 70)
		}
	)
	textBounce:Play()

	-- Float away after bounce
	bounceIn.Completed:Connect(function()
		wait(0.5)

		local floatAway = TweenService:Create(screenGui,
			TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = UDim2.new(0, 0, -1, 0),
				Size = UDim2.new(1, 0, 0, 0)
			}
		)
		floatAway:Play()

		floatAway.Completed:Connect(function()
			screenGui:Destroy()
		end)
	end)
end

local function HandleMilkingClick()
	local currentTime = tick()

	-- Check cooldown
	if (currentTime - MilkingState.lastClickTime) < MilkingState.clickCooldown then
		return
	end

	print("🖱️ Player clicked for milk - Click " .. (MilkingState.totalClicks + 1))
	MilkingState.lastClickTime = currentTime

	-- Send click to server
	if RemoteEvents.ContinueMilking then
		RemoteEvents.ContinueMilking:FireServer()
	end

	-- Create enhanced visual feedback
	CreateEnhancedClickFeedback()

	-- Increment local tracking (will be corrected by server update)
	MilkingState.totalClicks = MilkingState.totalClicks + 1
end

-- ========== PROGRESS GUI CREATION ==========

local function CreateProgressMilkingGUI(data)
	print("🎨 Creating 10-click progress milking GUI...")

	-- Remove existing GUI
	local existingGUI = PlayerGui:FindFirstChild("MilkingGUI")
	if existingGUI then
		existingGUI:Destroy()
	end

	-- Use the ChairMilkingGUI if available, otherwise create basic GUI
	if _G.ChairMilkingGUI then
		-- Let ChairMilkingGUI handle the display
		return nil
	end

	-- Fallback GUI creation
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MilkingGUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = PlayerGui

	-- Main frame (larger for progress display)
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 450, 0, 280)
	mainFrame.Position = UDim2.new(0.5, -225, 0, 80)
	mainFrame.BackgroundColor3 = Color3.fromRGB(40, 60, 40)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	-- Corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
	title.BorderSizePixel = 0
	title.Text = "🥛 10-CLICK MILKING SESSION"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 12)
	titleCorner.Parent = title

	-- Content frame
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "ContentFrame"
	contentFrame.Size = UDim2.new(1, -20, 1, -60)
	contentFrame.Position = UDim2.new(0, 10, 0, 50)
	contentFrame.BackgroundTransparency = 1
	contentFrame.Parent = mainFrame

	-- Progress section
	local progressTitle = Instance.new("TextLabel")
	progressTitle.Name = "ProgressTitle"
	progressTitle.Size = UDim2.new(1, 0, 0.25, 0)
	progressTitle.Position = UDim2.new(0, 0, 0, 0)
	progressTitle.BackgroundTransparency = 1
	progressTitle.Text = "Progress: " .. MilkingState.currentProgress .. "/" .. MilkingState.clicksPerMilk .. " clicks"
	progressTitle.TextColor3 = Color3.fromRGB(255, 255, 100)
	progressTitle.TextScaled = true
	progressTitle.Font = Enum.Font.GothamBold
	progressTitle.Parent = contentFrame

	-- Progress bar
	local progressBarBG = Instance.new("Frame")
	progressBarBG.Name = "ProgressBarBG"
	progressBarBG.Size = UDim2.new(1, 0, 0.15, 0)
	progressBarBG.Position = UDim2.new(0, 0, 0.25, 0)
	progressBarBG.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	progressBarBG.BorderSizePixel = 0
	progressBarBG.Parent = contentFrame

	local progressBGCorner = Instance.new("UICorner")
	progressBGCorner.CornerRadius = UDim.new(0.3, 0)
	progressBGCorner.Parent = progressBarBG

	local progressBarFill = Instance.new("Frame")
	progressBarFill.Name = "ProgressBarFill"
	progressBarFill.Size = UDim2.new(MilkingState.currentProgress / MilkingState.clicksPerMilk, 0, 1, 0)
	progressBarFill.Position = UDim2.new(0, 0, 0, 0)
	progressBarFill.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
	progressBarFill.BorderSizePixel = 0
	progressBarFill.Parent = progressBarBG

	local progressFillCorner = Instance.new("UICorner")
	progressFillCorner.CornerRadius = UDim.new(0.3, 0)
	progressFillCorner.Parent = progressBarFill

	-- Milk counter
	local milkCounter = Instance.new("TextLabel")
	milkCounter.Name = "MilkCounter"
	milkCounter.Size = UDim2.new(1, 0, 0.2, 0)
	milkCounter.Position = UDim2.new(0, 0, 0.45, 0)
	milkCounter.BackgroundTransparency = 1
	milkCounter.Text = "🥛 Milk Collected: " .. MilkingState.milkCollected
	milkCounter.TextColor3 = Color3.fromRGB(255, 255, 100)
	milkCounter.TextScaled = true
	milkCounter.Font = Enum.Font.GothamBold
	milkCounter.Parent = contentFrame

	-- Instruction
	local instruction = Instance.new("TextLabel")
	instruction.Name = "Instruction"
	instruction.Size = UDim2.new(1, 0, 0.2, 0)
	instruction.Position = UDim2.new(0, 0, 0.65, 0)
	instruction.BackgroundTransparency = 1
	instruction.Text = "🖱️ CLICK " .. MilkingState.clicksPerMilk .. " TIMES FOR 1 MILK!"
	instruction.TextColor3 = Color3.fromRGB(100, 255, 100)
	instruction.TextScaled = true
	instruction.Font = Enum.Font.GothamBold
	instruction.Parent = contentFrame

	-- Session timer
	local timer = Instance.new("TextLabel")
	timer.Name = "Timer"
	timer.Size = UDim2.new(1, 0, 0.15, 0)
	timer.Position = UDim2.new(0, 0, 0.85, 0)
	timer.BackgroundTransparency = 1
	timer.Text = "⏱️ Session: 0s"
	timer.TextColor3 = Color3.fromRGB(200, 200, 255)
	timer.TextScaled = true
	timer.Font = Enum.Font.Gotham
	timer.Parent = contentFrame

	return screenGui
end

local function UpdateProgressGUI(data)
	-- Update fallback GUI if it exists
	local milkingGUI = PlayerGui:FindFirstChild("MilkingGUI")
	if not milkingGUI then return end

	local contentFrame = milkingGUI:FindFirstChild("MainFrame") and milkingGUI.MainFrame:FindFirstChild("ContentFrame")
	if not contentFrame then return end

	-- Update progress title
	local progressTitle = contentFrame:FindFirstChild("ProgressTitle")
	if progressTitle then
		progressTitle.Text = "Progress: " .. MilkingState.currentProgress .. "/" .. MilkingState.clicksPerMilk .. " clicks"
	end

	-- Update progress bar
	local progressBarFill = contentFrame:FindFirstChild("ProgressBarBG") and 
		contentFrame.ProgressBarBG:FindFirstChild("ProgressBarFill")
	if progressBarFill then
		local fillPercentage = MilkingState.currentProgress / MilkingState.clicksPerMilk
		local tween = TweenService:Create(progressBarFill,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = UDim2.new(fillPercentage, 0, 1, 0)}
		)
		tween:Play()
	end

	-- Update milk counter
	local milkCounter = contentFrame:FindFirstChild("MilkCounter")
	if milkCounter then
		milkCounter.Text = "🥛 Milk Collected: " .. MilkingState.milkCollected
	end
end

-- ========== INPUT SETUP ==========

local function SetupClickDetection()
	print("🖱️ Setting up 10-click detection...")

	-- Mouse click detection
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if MilkingState.isActive then
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				HandleMilkingClick()
			elseif input.UserInputType == Enum.UserInputType.Touch then
				HandleMilkingClick()
			end
		end
	end)

	-- Keyboard shortcuts
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if MilkingState.isActive then
			if input.KeyCode == Enum.KeyCode.Space then
				HandleMilkingClick()
			elseif input.KeyCode == Enum.KeyCode.Escape then
				-- Stop milking session
				if RemoteEvents.StopMilkingSession then
					RemoteEvents.StopMilkingSession:FireServer()
				end
			end
		end
	end)

	print("✅ 10-click detection setup complete")
end

-- ========== REMOTE EVENT HANDLERS ==========

local function SetupRemoteHandlers()
	print("📡 Setting up 10-click remote event handlers...")

	-- Handle proximity prompts
	if RemoteEvents.ShowChairPrompt then
		RemoteEvents.ShowChairPrompt.OnClientEvent:Connect(function(promptType, promptData)
			print("📢 Received prompt: " .. promptType)

			if promptType == "milking" then
				-- Start milking session
				MilkingState.isActive = true
				MilkingState.sessionData = promptData
				MilkingState.currentProgress = promptData.currentProgress or 0
				MilkingState.clicksPerMilk = promptData.clicksPerMilk or 10
				MilkingState.milkCollected = 0
				MilkingState.totalClicks = 0

				-- Create GUI only if ChairMilkingGUI is not available
				if not _G.ChairMilkingGUI then
					MilkingState.currentGUI = CreateProgressMilkingGUI(promptData)
				end

				print("🥛 10-click milking session started")

			elseif promptType == "proximity" then
				-- Let ChairMilkingGUI handle proximity prompts
				print("📢 Proximity prompt handled by ChairMilkingGUI")
			end
		end)
	end

	-- Handle hide prompts
	if RemoteEvents.HideChairPrompt then
		RemoteEvents.HideChairPrompt.OnClientEvent:Connect(function()
			print("🚫 Hiding prompts")

			-- Stop milking session
			if MilkingState.isActive then
				MilkingState.isActive = false
				MilkingState.sessionData = {}
				MilkingState.currentProgress = 0
				MilkingState.totalClicks = 0
				MilkingState.milkCollected = 0

				if MilkingState.currentGUI then
					MilkingState.currentGUI:Destroy()
					MilkingState.currentGUI = nil
				end

				print("🛑 10-click milking session ended")
			end
		end)
	end

	-- Handle session updates with progress
	if RemoteEvents.MilkingSessionUpdate then
		RemoteEvents.MilkingSessionUpdate.OnClientEvent:Connect(function(updateType, updateData)
			if updateType == "progress" and MilkingState.isActive then
				-- Update local progress state
				MilkingState.currentProgress = updateData.clickProgress or 0
				MilkingState.clicksPerMilk = updateData.clicksPerMilk or 10
				MilkingState.totalClicks = updateData.totalClicks or 0
				MilkingState.milkCollected = updateData.milkCollected or 0

				print("📊 Progress update: " .. MilkingState.currentProgress .. "/" .. MilkingState.clicksPerMilk .. 
					" | Total clicks: " .. MilkingState.totalClicks .. 
					" | Milk: " .. MilkingState.milkCollected)

				-- Update fallback GUI
				UpdateProgressGUI(updateData)

				-- Check if milk was just collected (progress reset to 0 and milk increased)
				if MilkingState.currentProgress == 0 and MilkingState.milkCollected > 0 then
					CreateMilkRewardEffect()
				end
			end
		end)
	end

	print("✅ 10-click remote handlers setup complete")
end

-- ========== INITIALIZATION ==========

local function Initialize()
	print("🚀 Initializing 10-click milking click handler...")

	SetupClickDetection()
	SetupRemoteHandlers()

	print("✅ 10-click milking click handler ready!")
	print("")
	print("🎮 10-CLICK CONTROLS:")
	print("  🖱️ Left Click - Add 1 click toward milk (10 clicks = 1 milk)")
	print("  📱 Tap Screen - Add 1 click toward milk (mobile)")
	print("  ⌨️ Spacebar - Add 1 click toward milk (keyboard)")
	print("  🚪 Escape - Stop milking session")
	print("")
	print("📊 PROGRESS FEATURES:")
	print("  📈 Real-time progress tracking")
	print("  🎯 Visual click feedback with progress")
	print("  🥛 Milk reward celebration")
	print("  📊 Progress bar and percentage")
end

-- Start initialization
Initialize()

-- ========== DEBUG COMMANDS ==========

local function SetupDebugCommands()
	LocalPlayer.Chatted:Connect(function(message)
		local command = message:lower()

		if command == "/testclick" then
			print("🧪 Testing 10-click feedback...")
			CreateEnhancedClickFeedback()

		elseif command == "/testmilkreward" then
			print("🧪 Testing milk reward effect...")
			CreateMilkRewardEffect()

		elseif command == "/testgui" then
			print("🧪 Testing 10-click milking GUI...")
			MilkingState.currentGUI = CreateProgressMilkingGUI({
				title = "🧪 Test GUI",
				clicksPerMilk = 10,
				currentProgress = 3
			})

		elseif command == "/hidegui" then
			print("🚫 Hiding all milking GUIs...")

			if MilkingState.currentGUI then
				MilkingState.currentGUI:Destroy()
				MilkingState.currentGUI = nil
			end

		elseif command == "/clickstate" then
			print("🔍 10-click state:")
			print("  Active: " .. tostring(MilkingState.isActive))
			print("  Progress: " .. MilkingState.currentProgress .. "/" .. MilkingState.clicksPerMilk)
			print("  Total clicks: " .. MilkingState.totalClicks)
			print("  Milk collected: " .. MilkingState.milkCollected)
			print("  GUI exists: " .. tostring(MilkingState.currentGUI ~= nil))
			print("  Last click: " .. MilkingState.lastClickTime)

		elseif command == "/simulateprogress" then
			print("🧪 Simulating click progress...")
			for i = 1, 10 do
				spawn(function()
					wait(i * 0.2)
					MilkingState.currentProgress = i
					CreateEnhancedClickFeedback()
					if i == 10 then
						wait(0.5)
						MilkingState.currentProgress = 0
						CreateMilkRewardEffect()
					end
				end)
			end
		end
	end)
end

SetupDebugCommands()

print("🖱️ MilkingClickHandler: ✅ 10-CLICK SYSTEM READY!")
print("💬 Debug commands: /testclick, /testmilkreward, /testgui, /hidegui, /clickstate, /simulateprogress")