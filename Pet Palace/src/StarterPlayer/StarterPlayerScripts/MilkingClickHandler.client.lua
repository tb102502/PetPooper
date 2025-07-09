--[[
    MilkingClickHandler.client.lua - Client-Side Milking Click Detection
    Place in: StarterPlayer/StarterPlayerScripts/MilkingClickHandler.client.lua
    
    This script handles the client-side clicking for the milking system
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

print("🖱️ MilkingClickHandler: Initializing client-side milking system...")

-- State
local MilkingState = {
	isActive = false,
	currentGUI = nil,
	sessionData = {},
	clickCooldown = 0.1,
	lastClickTime = 0
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

-- ========== GUI CREATION ==========

local function CreateMilkingGUI()
	print("🎨 Creating milking GUI...")

	-- Remove existing GUI
	local existingGUI = PlayerGui:FindFirstChild("MilkingGUI")
	if existingGUI then
		existingGUI:Destroy()
	end

	-- Create main ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MilkingGUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = PlayerGui

	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 400, 0, 200)
	mainFrame.Position = UDim2.new(0.5, -200, 0, 100)
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
	title.Text = "🥛 MILKING SESSION"
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

	-- Milk counter
	local milkCounter = Instance.new("TextLabel")
	milkCounter.Name = "MilkCounter"
	milkCounter.Size = UDim2.new(1, 0, 0.4, 0)
	milkCounter.Position = UDim2.new(0, 0, 0, 0)
	milkCounter.BackgroundTransparency = 1
	milkCounter.Text = "🥛 Milk Collected: 0"
	milkCounter.TextColor3 = Color3.fromRGB(255, 255, 100)
	milkCounter.TextScaled = true
	milkCounter.Font = Enum.Font.GothamBold
	milkCounter.Parent = contentFrame

	-- Instruction
	local instruction = Instance.new("TextLabel")
	instruction.Name = "Instruction"
	instruction.Size = UDim2.new(1, 0, 0.3, 0)
	instruction.Position = UDim2.new(0, 0, 0.4, 0)
	instruction.BackgroundTransparency = 1
	instruction.Text = "🖱️ CLICK ANYWHERE TO COLLECT MILK!"
	instruction.TextColor3 = Color3.fromRGB(100, 255, 100)
	instruction.TextScaled = true
	instruction.Font = Enum.Font.GothamBold
	instruction.Parent = contentFrame

	-- Session timer
	local timer = Instance.new("TextLabel")
	timer.Name = "Timer"
	timer.Size = UDim2.new(1, 0, 0.3, 0)
	timer.Position = UDim2.new(0, 0, 0.7, 0)
	timer.BackgroundTransparency = 1
	timer.Text = "⏱️ Session: 0s"
	timer.TextColor3 = Color3.fromRGB(200, 200, 255)
	timer.TextScaled = true
	timer.Font = Enum.Font.Gotham
	timer.Parent = contentFrame

	return screenGui
end

local function CreateProximityGUI(promptData)
	print("📢 Creating proximity GUI...")

	-- Remove existing proximity GUI
	local existingGUI = PlayerGui:FindFirstChild("ProximityGUI")
	if existingGUI then
		existingGUI:Destroy()
	end

	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ProximityGUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = PlayerGui

	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 350, 0, 120)
	mainFrame.Position = UDim2.new(0.5, -175, 0.8, -60)
	mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	-- Corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = mainFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.4, 0)
	title.BackgroundTransparency = 1
	title.Text = promptData.title or "🐄 Cow Nearby"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame

	-- Subtitle
	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, 0, 0.3, 0)
	subtitle.Position = UDim2.new(0, 0, 0.4, 0)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = promptData.subtitle or "Status unknown"
	subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
	subtitle.TextScaled = true
	subtitle.Font = Enum.Font.Gotham
	subtitle.Parent = mainFrame

	-- Instruction
	local instruction = Instance.new("TextLabel")
	instruction.Size = UDim2.new(1, 0, 0.3, 0)
	instruction.Position = UDim2.new(0, 0, 0.7, 0)
	instruction.BackgroundTransparency = 1
	instruction.Text = promptData.instruction or "Check your setup"
	instruction.TextColor3 = Color3.fromRGB(150, 255, 150)
	instruction.TextScaled = true
	instruction.Font = Enum.Font.Gotham
	instruction.Parent = mainFrame

	return screenGui
end

-- ========== CLICK HANDLING ==========
local function CreateClickFeedback()
	local mouse = LocalPlayer:GetMouse()
	local clickPos = Vector2.new(mouse.X, mouse.Y)

	-- Create feedback GUI
	local feedbackGui = Instance.new("ScreenGui")
	feedbackGui.Name = "ClickFeedback"
	feedbackGui.Parent = PlayerGui

	-- Create ripple effect
	local ripple = Instance.new("Frame")
	ripple.Size = UDim2.new(0, 20, 0, 20)
	ripple.Position = UDim2.new(0, clickPos.X - 10, 0, clickPos.Y - 10)
	ripple.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
	ripple.BackgroundTransparency = 0.3
	ripple.BorderSizePixel = 0
	ripple.Parent = feedbackGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = ripple

	-- Animate ripple
	local expand = TweenService:Create(ripple,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = UDim2.new(0, 60, 0, 60),
			Position = UDim2.new(0, clickPos.X - 30, 0, clickPos.Y - 30),
			BackgroundTransparency = 1
		}
	)
	expand:Play()

	expand.Completed:Connect(function()
		feedbackGui:Destroy()
	end)

	-- Create +1 milk text
	local milkText = Instance.new("TextLabel")
	milkText.Size = UDim2.new(0, 80, 0, 40)
	milkText.Position = UDim2.new(0, clickPos.X - 40, 0, clickPos.Y - 20)
	milkText.BackgroundTransparency = 1
	milkText.Text = "🥛 +1"
	milkText.TextColor3 = Color3.fromRGB(255, 255, 255)
	milkText.TextScaled = true
	milkText.Font = Enum.Font.GothamBold
	milkText.TextStrokeTransparency = 0
	milkText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	milkText.Parent = feedbackGui

	-- Animate text
	local floatUp = TweenService:Create(milkText,
		TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Position = milkText.Position + UDim2.new(0, 0, 0, -50),
			TextTransparency = 1,
			TextStrokeTransparency = 1
		}
	)
	floatUp:Play()
end

local function HandleMilkingClick()
	local currentTime = tick()

	-- Check cooldown
	if (currentTime - MilkingState.lastClickTime) < MilkingState.clickCooldown then
		return
	end

	print("🖱️ Player clicked for milk")
	MilkingState.lastClickTime = currentTime

	-- Send click to server
	if RemoteEvents.ContinueMilking then
		RemoteEvents.ContinueMilking:FireServer()
	end

	-- Create visual feedback
	CreateClickFeedback()
end


-- ========== INPUT SETUP ==========

local function SetupClickDetection()
	print("🖱️ Setting up click detection...")

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

	print("✅ Click detection setup complete")
end

-- ========== REMOTE EVENT HANDLERS ==========

local function SetupRemoteHandlers()
	print("📡 Setting up remote event handlers...")

	-- Handle proximity prompts
	if RemoteEvents.ShowChairPrompt then
		RemoteEvents.ShowChairPrompt.OnClientEvent:Connect(function(promptType, promptData)
			print("📢 Received prompt: " .. promptType)

			if promptType == "milking" then
				-- Start milking session
				MilkingState.isActive = true
				MilkingState.sessionData = promptData
				MilkingState.currentGUI = CreateMilkingGUI()

				print("🥛 Milking session started")

			elseif promptType == "proximity" then
				-- Show proximity prompt
				CreateProximityGUI(promptData)

			end
		end)
	end

	-- Handle hide prompts
	if RemoteEvents.HideChairPrompt then
		RemoteEvents.HideChairPrompt.OnClientEvent:Connect(function()
			print("🚫 Hiding prompts")

			-- Hide proximity GUI
			local proximityGUI = PlayerGui:FindFirstChild("ProximityGUI")
			if proximityGUI then
				proximityGUI:Destroy()
			end

			-- Stop milking session
			if MilkingState.isActive then
				MilkingState.isActive = false
				MilkingState.sessionData = {}

				if MilkingState.currentGUI then
					MilkingState.currentGUI:Destroy()
					MilkingState.currentGUI = nil
				end

				print("🛑 Milking session ended")
			end
		end)
	end

	-- Handle session updates
	if RemoteEvents.MilkingSessionUpdate then
		RemoteEvents.MilkingSessionUpdate.OnClientEvent:Connect(function(updateType, updateData)
			if updateType == "progress" and MilkingState.currentGUI then
				-- Update the milking GUI
				local mainFrame = MilkingState.currentGUI:FindFirstChild("MainFrame")
				if mainFrame then
					local contentFrame = mainFrame:FindFirstChild("ContentFrame")
					if contentFrame then
						local milkCounter = contentFrame:FindFirstChild("MilkCounter")
						if milkCounter then
							milkCounter.Text = "🥛 Milk Collected: " .. (updateData.milkCollected or 0) .. "/" .. (updateData.maxMilk or 20)

							-- Flash effect
							local flash = TweenService:Create(milkCounter,
								TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true),
								{TextColor3 = Color3.fromRGB(100, 255, 100)}
							)
							flash:Play()
						end

						local timer = contentFrame:FindFirstChild("Timer")
						if timer then
							timer.Text = "⏱️ Session: " .. (updateData.sessionDuration or 0) .. "s"
						end
					end
				end
			end
		end)
	end

	print("✅ Remote handlers setup complete")
end

-- ========== INITIALIZATION ==========

local function Initialize()
	print("🚀 Initializing milking click handler...")

	SetupClickDetection()
	SetupRemoteHandlers()

	print("✅ Milking click handler ready!")
	print("")
	print("🎮 CONTROLS:")
	print("  🖱️ Left Click - Collect milk (during milking)")
	print("  📱 Tap Screen - Collect milk (mobile)")
	print("  ⌨️ Spacebar - Collect milk (keyboard)")
	print("  🚪 Escape - Stop milking session")
end

-- Start initialization
Initialize()

-- ========== DEBUG COMMANDS ==========

-- Add debug functionality
local function SetupDebugCommands()
	LocalPlayer.Chatted:Connect(function(message)
		local command = message:lower()

		if command == "/testclick" then
			print("🧪 Testing click feedback...")
			CreateClickFeedback()

		elseif command == "/testgui" then
			print("🧪 Testing milking GUI...")
			MilkingState.currentGUI = CreateMilkingGUI()

		elseif command == "/hidegui" then
			print("🚫 Hiding all GUIs...")
			local proximityGUI = PlayerGui:FindFirstChild("ProximityGUI")
			if proximityGUI then proximityGUI:Destroy() end

			if MilkingState.currentGUI then
				MilkingState.currentGUI:Destroy()
				MilkingState.currentGUI = nil
			end

		elseif command == "/clickstate" then
			print("🔍 Click state:")
			print("  Active: " .. tostring(MilkingState.isActive))
			print("  GUI exists: " .. tostring(MilkingState.currentGUI ~= nil))
			print("  Last click: " .. MilkingState.lastClickTime)
		end
	end)
end

SetupDebugCommands()

print("🖱️ MilkingClickHandler: Ready for action!")
print("💬 Debug commands: /testclick, /testgui, /hidegui, /clickstate")