--[[
    UPDATED GameClient.lua - Tabbed Shop Support
    Place in: ReplicatedStorage/GameClient.lua
    
    CHANGES:
    ✅ Enhanced shop menu opening for tabbed system
    ✅ Support for tab-specific item filtering
    ✅ Better shop state management
    ✅ Enhanced purchase confirmations for categories
]]

local GameClient = {}

-- Services ONLY - no external module requires
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ServerScriptService = game:GetService("ServerScriptService")

-- Load ItemConfig safely
local ItemConfig = nil
local function loadItemConfig()
	local success, result = pcall(function()
		return require(ReplicatedStorage:WaitForChild("ItemConfig"))
	end)
	if success then
		ItemConfig = result
		print("GameClient: ItemConfig loaded successfully")
	else
		warn("GameClient: Could not load ItemConfig: " .. tostring(result))
	end
end

-- Player and Game State
local LocalPlayer = Players.LocalPlayer
GameClient.PlayerData = {}
GameClient.RemoteEvents = {}
GameClient.RemoteFunctions = {}
GameClient.ActiveConnections = {}

-- References to UIManager (injected during initialization)
GameClient.UIManager = nil

-- Game State
GameClient.FarmingState = {
	selectedSeed = nil,
	isPlantingMode = false,
	selectedCrop = nil,
	seedInventory = {},
	activeBoosters = {},
	rarityPreview = nil
}

GameClient.Cache = {
	ShopItems = {},
	CowCooldown = 0,
	ShopTabCache = {},
	LastShopRefresh = 0
}

-- ========== INITIALIZATION ==========

function GameClient:Initialize(uiManager)
	print("GameClient: Starting enhanced core initialization with tabbed shop support...")

	self.UIManager = uiManager

	local success, errorMsg

	-- Step 1: Load ItemConfig
	success, errorMsg = pcall(function()
		loadItemConfig()
	end)
	if not success then
		error("GameClient initialization failed at step 'ItemConfig': " .. tostring(errorMsg))
	end
	print("GameClient: ✅ ItemConfig initialized")

	-- Step 2: Setup Remote Connections
	success, errorMsg = pcall(function()
		self:SetupRemoteConnections()
	end)
	if not success then
		error("GameClient initialization failed at step 'RemoteConnections': " .. tostring(errorMsg))
	end
	print("GameClient: ✅ RemoteConnections initialized")

	-- Step 3: Establish UIManager connection
	if self.UIManager then
		self.UIManager:SetGameClient(self)
		print("GameClient: ✅ UIManager reference established")
	else
		error("GameClient: UIManager not provided during initialization")
	end

	-- Step 4: Setup Input Handling
	success, errorMsg = pcall(function()
		self:SetupInputHandling()
	end)
	if not success then
		error("GameClient initialization failed at step 'InputHandling': " .. tostring(errorMsg))
	end
	print("GameClient: ✅ InputHandling initialized")

	-- Step 5: Setup Proximity System Handlers
	success, errorMsg = pcall(function()
		self:SetupProximitySystemHandlers()
	end)
	if not success then
		error("GameClient initialization failed at step 'ProximitySystemHandlers': " .. tostring(errorMsg))
	end
	print("GameClient: ✅ ProximitySystemHandlers initialized")

	-- Step 6: Setup Farming System Logic
	success, errorMsg = pcall(function()
		self:SetupFarmingSystemLogic()
	end)
	if not success then
		error("GameClient initialization failed at step 'FarmingSystemLogic': " .. tostring(errorMsg))
	end
	print("GameClient: ✅ FarmingSystemLogic initialized")

	-- Step 7: Request Initial Data
	success, errorMsg = pcall(function()
		self:RequestInitialData()
	end)
	if not success then
		error("GameClient initialization failed at step 'InitialData': " .. tostring(errorMsg))
	end
	print("GameClient: ✅ InitialData initialized")

	print("GameClient: 🎉 Enhanced initialization complete with tabbed shop support!")
	return true
end
-- ========== CLICKER MILKING UI SYSTEM ==========

function GameClient:InitializeClickerMilkingUI()
	print("GameClient: Initializing clicker milking UI system...")

	-- Initialize milking UI state
	self.MilkingUI = {
		isActive = false,
		currentSession = nil,
		progressUI = nil,
		clickFeedback = {},
		lastClickTime = 0,
		clickCooldown = 0.1 -- Prevent spam clicking
	}

	-- Setup milking remote handlers
	self:SetupMilkingRemoteHandlers()
	self:InitializeEnhancedMilking()
	print("GameClient: ✅ Enhanced with milking UI system!")
	print("GameClient: Clicker milking UI system initialized!")
end

function GameClient:SetupMilkingRemoteHandlers()
	-- Handle milking session updates from server
	if self.RemoteEvents.MilkingSessionUpdate then
		self.RemoteEvents.MilkingSessionUpdate.OnClientEvent:Connect(function(updateType, data)
			pcall(function()
				self:HandleMilkingSessionUpdate(updateType, data)
			end)
		end)
		print("✅ Connected MilkingSessionUpdate handler")
	end
end

-- ========== MILKING SESSION UI MANAGEMENT ==========

function GameClient:HandleMilkingSessionUpdate(updateType, data)
	print("🥛 GameClient: Received milking session update: " .. updateType)

	if updateType == "started" then
		self:StartMilkingUI(data)
	elseif updateType == "progress" then
		self:UpdateMilkingProgress(data)
	elseif updateType == "ended" then
		self:EndMilkingUI()
	end
end

--[[
    GameClient.lua - FIXED CLICK-BASED UI UPDATES
    Replace these methods in your existing GameClient.lua
    
    FIXES:
    ✅ UI reflects 1 click = 1 milk system
    ✅ Clear instructions for click-based milking
    ✅ Proper click feedback for each milk collection
    ✅ Updated progress tracking
]]

-- REPLACE these methods in your existing GameClient.lua:

-- ========== FIXED MILKING UI CREATION ==========

function GameClient:CreateMilkingProgressUI(sessionData)
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	-- Remove existing milking UI
	local existingUI = playerGui:FindFirstChild("MilkingProgressUI")
	if existingUI then existingUI:Destroy() end

	-- Create new milking UI
	local milkingUI = Instance.new("ScreenGui")
	milkingUI.Name = "MilkingProgressUI"
	milkingUI.ResetOnSpawn = false
	milkingUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	milkingUI.Parent = playerGui

	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 450, 0, 220)
	mainFrame.Position = UDim2.new(0.5, -225, 0, 100)
	mainFrame.BackgroundColor3 = Color3.fromRGB(40, 60, 40)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = milkingUI

	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame

	-- Add subtle shadow
	local shadow = Instance.new("Frame")
	shadow.Size = UDim2.new(1, 6, 1, 6)
	shadow.Position = UDim2.new(0, -3, 0, 3)
	shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	shadow.BackgroundTransparency = 0.8
	shadow.ZIndex = mainFrame.ZIndex - 1
	shadow.Parent = mainFrame

	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius = UDim.new(0, 12)
	shadowCorner.Parent = shadow

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
	title.BorderSizePixel = 0
	title.Text = "🥛 CLICK-TO-MILK SESSION"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 12)
	titleCorner.Parent = title

	-- Progress info container
	local progressContainer = Instance.new("Frame")
	progressContainer.Name = "ProgressContainer"
	progressContainer.Size = UDim2.new(1, -20, 1, -60)
	progressContainer.Position = UDim2.new(0, 10, 0, 50)
	progressContainer.BackgroundTransparency = 1
	progressContainer.Parent = mainFrame

	-- Milk collected counter (larger, more prominent)
	local milkCounter = Instance.new("TextLabel")
	milkCounter.Name = "MilkCounter"
	milkCounter.Size = UDim2.new(1, 0, 0.35, 0)
	milkCounter.Position = UDim2.new(0, 0, 0, 0)
	milkCounter.BackgroundTransparency = 1
	milkCounter.Text = "🥛 Milk Collected: 0"
	milkCounter.TextColor3 = Color3.fromRGB(255, 255, 100)
	milkCounter.TextScaled = true
	milkCounter.Font = Enum.Font.GothamBold
	milkCounter.Parent = progressContainer

	-- Click counter
	local clickCounter = Instance.new("TextLabel")
	clickCounter.Name = "ClickCounter"
	clickCounter.Size = UDim2.new(1, 0, 0.25, 0)
	clickCounter.Position = UDim2.new(0, 0, 0.35, 0)
	clickCounter.BackgroundTransparency = 1
	clickCounter.Text = "👆 Total Clicks: 0"
	clickCounter.TextColor3 = Color3.fromRGB(200, 255, 200)
	clickCounter.TextScaled = true
	clickCounter.Font = Enum.Font.Gotham
	clickCounter.Parent = progressContainer

	-- Session timer
	local timer = Instance.new("TextLabel")
	timer.Name = "Timer"
	timer.Size = UDim2.new(0.5, 0, 0.2, 0)
	timer.Position = UDim2.new(0, 0, 0.6, 0)
	timer.BackgroundTransparency = 1
	timer.Text = "⏱️ Session: 0s"
	timer.TextColor3 = Color3.fromRGB(200, 200, 255)
	timer.TextScaled = true
	timer.Font = Enum.Font.Gotham
	timer.Parent = progressContainer

	-- Last click timer
	local lastClickTimer = Instance.new("TextLabel")
	lastClickTimer.Name = "LastClickTimer"
	lastClickTimer.Size = UDim2.new(0.5, 0, 0.2, 0)
	lastClickTimer.Position = UDim2.new(0.5, 0, 0.6, 0)
	lastClickTimer.BackgroundTransparency = 1
	lastClickTimer.Text = "🖱️ Last Click: Now"
	lastClickTimer.TextColor3 = Color3.fromRGB(255, 200, 100)
	lastClickTimer.TextScaled = true
	lastClickTimer.Font = Enum.Font.Gotham
	lastClickTimer.Parent = progressContainer

	-- FIXED: Click instruction for 1-click-1-milk system
	local instruction = Instance.new("TextLabel")
	instruction.Name = "Instruction"
	instruction.Size = UDim2.new(1, 0, 0.2, 0)
	instruction.Position = UDim2.new(0, 0, 0.8, 0)
	instruction.BackgroundTransparency = 1
	instruction.Text = "🖱️ EACH CLICK = 1 MILK! Session ends after 3 seconds of no clicks."
	instruction.TextColor3 = Color3.fromRGB(100, 255, 100)
	instruction.TextScaled = true
	instruction.Font = Enum.Font.GothamBold
	instruction.Parent = progressContainer

	-- Stop button
	local stopButton = Instance.new("TextButton")
	stopButton.Name = "StopButton"
	stopButton.Size = UDim2.new(0, 100, 0, 30)
	stopButton.Position = UDim2.new(1, -110, 1, -40)
	stopButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	stopButton.BorderSizePixel = 0
	stopButton.Text = "STOP MILKING"
	stopButton.TextColor3 = Color3.new(1, 1, 1)
	stopButton.TextScaled = true
	stopButton.Font = Enum.Font.Gotham
	stopButton.Parent = mainFrame

	local stopCorner = Instance.new("UICorner")
	stopCorner.CornerRadius = UDim.new(0, 8)
	stopCorner.Parent = stopButton

	-- Stop button functionality
	stopButton.MouseButton1Click:Connect(function()
		self:StopMilkingSession()
	end)

	-- Store UI reference
	self.MilkingUI.progressUI = milkingUI

	-- Start UI update loop
	self:StartMilkingUIUpdateLoop()

	print("🥛 GameClient: FIXED milking progress UI created")
end

-- ========== FIXED PROGRESS UPDATE ==========

function GameClient:UpdateMilkingProgress(progressData)
	print("📊 GameClient: FIXED updating milking progress")

	if not self.MilkingUI.progressUI then return end

	local progressContainer = self.MilkingUI.progressUI:FindFirstChild("MainFrame"):FindFirstChild("ProgressContainer")

	local milkCounter = progressContainer:FindFirstChild("MilkCounter")
	local clickCounter = progressContainer:FindFirstChild("ClickCounter")
	local timer = progressContainer:FindFirstChild("Timer")
	local lastClickTimer = progressContainer:FindFirstChild("LastClickTimer")

	-- Update milk counter with exciting animation
	if milkCounter then
		milkCounter.Text = "🥛 Milk Collected: " .. (progressData.milkCollected or 0)

		-- Flash effect for new milk
		local flash = game:GetService("TweenService"):Create(milkCounter,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				TextColor3 = Color3.fromRGB(100, 255, 100),
				TextStrokeTransparency = 0,
				TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
			}
		)
		flash:Play()
		flash.Completed:Connect(function()
			local restore = game:GetService("TweenService"):Create(milkCounter,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					TextColor3 = Color3.fromRGB(255, 255, 100),
					TextStrokeTransparency = 1
				}
			)
			restore:Play()
		end)
	end

	-- Update click counter (same as milk count in 1:1 system)
	if clickCounter then
		clickCounter.Text = "👆 Total Clicks: " .. (progressData.milkCollected or 0)

		-- Quick flash for click feedback
		local clickFlash = game:GetService("TweenService"):Create(clickCounter,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad),
			{TextColor3 = Color3.fromRGB(255, 255, 255)}
		)
		clickFlash:Play()
		clickFlash.Completed:Connect(function()
			local restore = game:GetService("TweenService"):Create(clickCounter,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad),
				{TextColor3 = Color3.fromRGB(200, 255, 200)}
			)
			restore:Play()
		end)
	end

	-- Update session timer
	if timer then
		timer.Text = "⏱️ Session: " .. (progressData.sessionDuration or 0) .. "s"
	end

	-- Update last click timer
	if lastClickTimer then
		lastClickTimer.Text = "🖱️ Last Click: Now"
		lastClickTimer.TextColor3 = Color3.fromRGB(100, 255, 100)

		-- Start countdown to show when session will timeout
		spawn(function()
			for i = 1, 3 do
				wait(1)
				if lastClickTimer and lastClickTimer.Parent then
					local timeLeft = 3 - i
					if timeLeft > 0 then
						lastClickTimer.Text = "🖱️ Timeout in: " .. timeLeft .. "s"
						lastClickTimer.TextColor3 = Color3.fromRGB(255, 200 - (i * 50), 100)
					else
						lastClickTimer.Text = "🖱️ Timing out..."
						lastClickTimer.TextColor3 = Color3.fromRGB(255, 100, 100)
					end
				else
					break
				end
			end
		end)
	end

	-- Create enhanced visual feedback for each click
	self:CreateEnhancedMilkCollectionFeedback()
end

-- ========== ENHANCED CLICK FEEDBACK ==========

function GameClient:CreateEnhancedMilkCollectionFeedback()
	print("✨ GameClient: Creating ENHANCED milk collection feedback")

	-- Create multiple floating milk icons for more satisfying feedback
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	for i = 1, 3 do
		local feedback = Instance.new("ScreenGui")
		feedback.Name = "MilkFeedback"
		feedback.Parent = playerGui

		local milkIcon = Instance.new("TextLabel")
		milkIcon.Size = UDim2.new(0, 80, 0, 80)
		milkIcon.Position = UDim2.new(0.5, math.random(-150, 150), 0.5, math.random(-100, 50))
		milkIcon.BackgroundTransparency = 1
		milkIcon.Text = "🥛+1"
		milkIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
		milkIcon.TextScaled = true
		milkIcon.Font = Enum.Font.GothamBold
		milkIcon.TextStrokeTransparency = 0
		milkIcon.TextStrokeColor3 = Color3.fromRGB(100, 255, 100)
		milkIcon.Parent = feedback

		-- Different animation for each icon
		local animationVariations = {
			-- Bounce up
			function()
				return game:GetService("TweenService"):Create(milkIcon,
					TweenInfo.new(1.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
					{
						Position = milkIcon.Position + UDim2.new(0, 0, 0, -150),
						TextTransparency = 1,
						TextStrokeTransparency = 1,
						Rotation = math.random(-30, 30)
					}
				)
			end,
			-- Float up smoothly
			function()
				return game:GetService("TweenService"):Create(milkIcon,
					TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						Position = milkIcon.Position + UDim2.new(0, 0, 0, -120),
						TextTransparency = 1,
						TextStrokeTransparency = 1
					}
				)
			end,
			-- Arc motion
			function()
				local tween1 = game:GetService("TweenService"):Create(milkIcon,
					TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{Position = milkIcon.Position + UDim2.new(0, math.random(-50, 50), 0, -80)}
				)
				local tween2 = game:GetService("TweenService"):Create(milkIcon,
					TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{
						Position = milkIcon.Position + UDim2.new(0, math.random(-100, 100), 0, -160),
						TextTransparency = 1,
						TextStrokeTransparency = 1
					}
				)
				tween1:Play()
				tween1.Completed:Connect(function() tween2:Play() end)
				return tween2
			end
		}

		local tween = animationVariations[i]()
		tween.Completed:Connect(function()
			feedback:Destroy()
		end)

		wait(0.1) -- Small delay between each feedback element
	end
end

-- ========== FIXED START MILKING UI ==========

function GameClient:StartMilkingUI(sessionData)
	print("🥛 GameClient: Starting FIXED milking UI")

	self.MilkingUI.isActive = true
	self.MilkingUI.currentSession = sessionData

	-- Create milking progress UI
	self:CreateMilkingProgressUI(sessionData)

	-- Don't start click monitoring loop (we handle clicks individually)

	-- Show initial instruction for click-based system
	if self.UIManager then
		self.UIManager:ShowNotification("🥛 Milking Started!", 
			"Click the cow for each milk!\n1 Click = 1 Milk\nSession ends after 3 seconds of no clicks.", "success")
	end
end

-- ========== FIXED CLICK HANDLING ==========

function GameClient:HandleCowClick(cowModel)
	print("🐄 GameClient: FIXED handling cow click for milking system")

	-- If currently milking, this is a milk collection click
	if self.MilkingUI.isActive then
		-- Send continue signal (which gives 1 milk)
		if self.RemoteEvents.ContinueMilking then
			self.RemoteEvents.ContinueMilking:FireServer()
		end

		-- Create enhanced click feedback
		local mouse = game:GetService("Players").LocalPlayer:GetMouse()
		self:CreateClickFeedback(Vector2.new(mouse.X, mouse.Y))

		-- Play click sound for satisfaction
		self:PlayClickSound()

		return
	end

	-- Otherwise, start new milking session
	local cowId = cowModel.Name
	if self.RemoteEvents.StartMilkingSession then
		self.RemoteEvents.StartMilkingSession:FireServer(cowId)
	end
end

-- ========== CLICK SOUND FEEDBACK ==========

function GameClient:PlayClickSound()
	-- Create satisfying click sound
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://131961136" -- Default click sound, replace with better one
	sound.Volume = 0.3
	--sound.Pitch = 1.2 + math.random(-20, 20) / 100 -- Slight pitch variation
	sound.Parent = workspace
	sound:Play()

	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

-- ========== ENHANCED CLICK FEEDBACK ==========

function GameClient:CreateClickFeedback(clickPosition)
	print("👆 GameClient: Creating ENHANCED click feedback")

	local currentTime = tick()

	-- Create enhanced click ripple effect
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	local clickFeedback = Instance.new("ScreenGui")
	clickFeedback.Name = "ClickFeedback"
	clickFeedback.Parent = playerGui

	-- Multiple ripple rings for more impact
	for i = 1, 3 do
		local ripple = Instance.new("Frame")
		ripple.Size = UDim2.new(0, 20, 0, 20)
		ripple.Position = UDim2.new(0, clickPosition.X - 10, 0, clickPosition.Y - 10)
		ripple.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
		ripple.BackgroundTransparency = 0.3 + (i * 0.1)
		ripple.BorderSizePixel = 0
		ripple.Parent = clickFeedback

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = ripple

		-- Delayed expansion for layered effect
		spawn(function()
			wait((i - 1) * 0.05)

			local expand = game:GetService("TweenService"):Create(ripple,
				TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Size = UDim2.new(0, 80 + (i * 10), 0, 80 + (i * 10)),
					Position = UDim2.new(0, clickPosition.X - (40 + (i * 5)), 0, clickPosition.Y - (40 + (i * 5))),
					BackgroundTransparency = 1
				}
			)
			expand:Play()
		end)
	end

	-- Clean up after animation
	spawn(function()
		wait(1)
		clickFeedback:Destroy()
	end)
end

-- ========== FIXED UI UPDATE LOOP ==========

function GameClient:StartMilkingUIUpdateLoop()
	spawn(function()
		local startTime = tick()

		while self.MilkingUI.isActive and self.MilkingUI.progressUI do
			wait(0.1)

			-- Update timer display
			local elapsed = math.floor(tick() - startTime)
			local timer = self.MilkingUI.progressUI:FindFirstChild("MainFrame"):FindFirstChild("ProgressContainer"):FindFirstChild("Timer")

			if timer then
				timer.Text = "⏱️ Session: " .. elapsed .. "s"
			end

			-- Animate instruction text to encourage clicking
			local instruction = self.MilkingUI.progressUI:FindFirstChild("MainFrame"):FindFirstChild("ProgressContainer"):FindFirstChild("Instruction")
			if instruction then
				local pulse = game:GetService("TweenService"):Create(instruction,
					TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
					{TextTransparency = 0.3}
				)
				pulse:Play()
			end
		end
	end)
end

print("GameClient: ✅ FIXED CLICK-BASED UI SYSTEM!")
print("🔧 KEY FIXES:")
print("  🖱️ UI shows 1 click = 1 milk clearly")
print("  📊 Enhanced progress tracking and feedback")
print("  ✨ Multiple visual feedback elements per click")
print("  🔊 Click sound feedback for satisfaction")
print("  ⏱️ Timeout countdown display")
print("  📱 Better mobile touch feedback")

function GameClient:StartClickMonitoring()
	print("🖱️ GameClient: Starting click monitoring for milking")

	-- Enable enhanced click detection
	self.MilkingUI.clickMonitoring = true

	-- Monitor for clicks to send continue signals
	spawn(function()
		while self.MilkingUI.isActive and self.MilkingUI.clickMonitoring do
			wait(0.5) -- Check every 0.5 seconds

			-- Send continue signal to maintain session
			if self.RemoteEvents.ContinueMilking then
				self.RemoteEvents.ContinueMilking:FireServer()
			end
		end
	end)
end

function GameClient:CreateMilkCollectionFeedback()
	print("✨ GameClient: Creating milk collection feedback")

	-- Create floating milk icon
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	local feedback = Instance.new("ScreenGui")
	feedback.Name = "MilkFeedback"
	feedback.Parent = playerGui

	local milkIcon = Instance.new("TextLabel")
	milkIcon.Size = UDim2.new(0, 60, 0, 60)
	milkIcon.Position = UDim2.new(0.5, math.random(-100, 100), 0.5, math.random(-50, 50))
	milkIcon.BackgroundTransparency = 1
	milkIcon.Text = "🥛+1"
	milkIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
	milkIcon.TextScaled = true
	milkIcon.Font = Enum.Font.GothamBold
	milkIcon.TextStrokeTransparency = 0
	milkIcon.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	milkIcon.Parent = feedback

	-- Animate feedback
	local tween = game:GetService("TweenService"):Create(milkIcon,
		TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Position = milkIcon.Position + UDim2.new(0, 0, 0, -100),
			TextTransparency = 1,
			TextStrokeTransparency = 1
		}
	)
	tween:Play()
	tween.Completed:Connect(function()
		feedback:Destroy()
	end)
end

function GameClient:EndMilkingUI()
	print("🥛 GameClient: Ending milking UI")

	self.MilkingUI.isActive = false
	self.MilkingUI.clickMonitoring = false
	self.MilkingUI.currentSession = nil

	-- Remove progress UI with animation
	if self.MilkingUI.progressUI then
		local mainFrame = self.MilkingUI.progressUI:FindFirstChild("MainFrame")
		if mainFrame then
			local fadeOut = game:GetService("TweenService"):Create(mainFrame,
				TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = mainFrame.Position + UDim2.new(0, 0, 0, -100),
					Transparency = 1
				}
			)
			fadeOut:Play()
			fadeOut.Completed:Connect(function()
				self.MilkingUI.progressUI:Destroy()
				self.MilkingUI.progressUI = nil
			end)
		else
			self.MilkingUI.progressUI:Destroy()
			self.MilkingUI.progressUI = nil
		end
	end

	-- Show completion message
	if self.UIManager then
		self.UIManager:ShowNotification("🥛 Milking Complete!", 
			"Milking session ended. Check your inventory for collected milk!", "success")
	end
end

function GameClient:StopMilkingSession()
	print("🛑 GameClient: Player manually stopping milking session")

	-- Send stop signal to server
	if self.RemoteEvents.StopMilkingSession then
		self.RemoteEvents.StopMilkingSession:FireServer()
	end

	-- End UI immediately
	self:EndMilkingUI()
end

-- ========== KEYBOARD SHORTCUTS ==========

function GameClient:SetupMilkingKeyboardShortcuts()
	local UserInputService = game:GetService("UserInputService")

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		-- Stop milking with Escape
		if input.KeyCode == Enum.KeyCode.Escape and self.MilkingUI.isActive then
			self:StopMilkingSession()
		end

		-- Continue milking with Spacebar (alternative to clicking)
		if input.KeyCode == Enum.KeyCode.Space and self.MilkingUI.isActive then
			if self.RemoteEvents.ContinueMilking then
				self.RemoteEvents.ContinueMilking:FireServer()
			end

			-- Show spacebar feedback
			local screenCenter = Vector2.new(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2)
			self:CreateClickFeedback(screenCenter)
		end
	end)
end

-- ========== MOBILE TOUCH SUPPORT ==========

function GameClient:SetupMobileMilkingSupport()
	local UserInputService = game:GetService("UserInputService")

	-- Handle touch input for mobile milking
	UserInputService.TouchTapInWorld:Connect(function(position, gameProcessedEvent)
		if gameProcessedEvent then return end

		if self.MilkingUI.isActive then
			-- Convert touch to continue milking
			if self.RemoteEvents.ContinueMilking then
				self.RemoteEvents.ContinueMilking:FireServer()
			end

			-- Create touch feedback
			local camera = workspace.CurrentCamera
			local screenPoint = camera:WorldToScreenPoint(position)
			self:CreateClickFeedback(Vector2.new(screenPoint.X, screenPoint.Y))
		end
	end)
end

-- ========== INITIALIZATION UPDATES ==========

-- ADD these to your existing GameClient:Initialize() method:
function GameClient:InitializeEnhancedMilking()
	-- Initialize clicker milking UI
	self:InitializeClickerMilkingUI()

	-- Setup keyboard shortcuts
	self:SetupMilkingKeyboardShortcuts()

	-- Setup mobile support
	self:SetupMobileMilkingSupport()

	print("GameClient: Enhanced milking system initialized!")
end

-- ========== ERROR HANDLING ==========

function GameClient:HandleMilkingError(errorMsg)
	warn("GameClient: Milking error - " .. tostring(errorMsg))

	-- Clean up UI on error
	if self.MilkingUI.isActive then
		self:EndMilkingUI()
	end

	-- Show error notification
	if self.UIManager then
		self.UIManager:ShowNotification("Milking Error", 
			"Milking session encountered an error and was stopped.", "error")
	end
end

-- ========== DEBUG COMMANDS ==========

function GameClient:DebugMilkingUI()
	print("=== MILKING UI DEBUG ===")
	print("UI Active:", self.MilkingUI.isActive)
	print("Current Session:", self.MilkingUI.currentSession ~= nil)
	print("Progress UI exists:", self.MilkingUI.progressUI ~= nil)
	print("Click Monitoring:", self.MilkingUI.clickMonitoring)
	print("Last Click Time:", self.MilkingUI.lastClickTime)
	print("========================")
end

-- Make debug function global
_G.DebugMilkingUI = function()
	if _G.GameClient and _G.GameClient.DebugMilkingUI then
		_G.GameClient:DebugMilkingUI()
	end
end

-- ========== CLEANUP ==========

function GameClient:CleanupMilkingUI()
	-- Clean up milking UI when player leaves or resets
	if self.MilkingUI.progressUI then
		self.MilkingUI.progressUI:Destroy()
	end

	self.MilkingUI.isActive = false
	self.MilkingUI.clickMonitoring = false
	self.MilkingUI.currentSession = nil
	self.MilkingUI.progressUI = nil

	print("GameClient: Milking UI cleaned up")
end

-- Add cleanup to existing cleanup method
-- ADD this to your existing GameClient:Cleanup() method:
-- self:CleanupMilkingUI()

print("GameClient: ✅ CLICKER MILKING UI LOADED!")
print("🥛 NEW UI FEATURES:")
print("  📊 Real-time milking progress display")
print("  🖱️ Click feedback and visual effects")
print("  ⏱️ Session timer and milk counter")
print("  📱 Mobile touch support")
print("  ⌨️ Keyboard shortcuts (ESC to stop, SPACE to continue)")
print("  ✨ Floating milk collection feedback")
print("  🎨 Smooth animations and transitions")
print("")
print("🔧 Debug Command:")
print("  _G.DebugMilkingUI() - Show milking UI debug info")
-- ========== INPUT HANDLING ==========

function GameClient:SetupInputHandling()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.Escape then
			if self.UIManager then
				self.UIManager:CloseActiveMenus()
			end
		elseif input.KeyCode == Enum.KeyCode.F then
			self:OpenMenu("Farm")
		elseif input.KeyCode == Enum.KeyCode.M then
			self:OpenMenu("Mining")
		elseif input.KeyCode == Enum.KeyCode.C then
			self:OpenMenu("Crafting")
		elseif input.KeyCode == Enum.KeyCode.H then
			self:RequestHarvestAll()
		end
	end)

	print("GameClient: Input handling setup complete (shop hotkey removed)")
	print("  Available hotkeys: F=Farm, M=Mining, C=Crafting, H=Harvest All, ESC=Close")
	print("  Shop access: Proximity only via ShopTouchPart")
end

-- ========== FARMING SYSTEM LOGIC ==========

function GameClient:SetupFarmingSystemLogic()
	self.FarmingState = {
		selectedSeed = nil,
		isPlantingMode = false,
		selectedCrop = nil,
		seedInventory = {},
		activeBoosters = {},
		rarityPreview = nil
	}

	print("GameClient: Farming system logic setup complete")
end

-- ========== MENU AND ACTION METHODS ==========

function GameClient:OpenMenu(menuName)
	if menuName == "Shop" then
		print("GameClient: Shop menu opening blocked - use proximity system")
		if self.UIManager then
			self.UIManager:ShowNotification("Shop Access", "Step on the shop area to access the shop!", "info")
		end
		return false
	end

	if self.UIManager then
		return self.UIManager:OpenMenu(menuName)
	end
	return false
end

function GameClient:CloseMenus()
	if self.UIManager then
		self.UIManager:CloseActiveMenus()
	end
end

function GameClient:RequestHarvestAll()
	if not self.RemoteEvents.HarvestAllCrops then
		if self.UIManager then
			self.UIManager:ShowNotification("System Error", "Harvest All system not available!", "error")
		end
		return
	end

	if self.UIManager then
		self.UIManager:ShowNotification("🌾 Harvesting...", "Checking all crops for harvest...", "info")
	end
	self.RemoteEvents.HarvestAllCrops:FireServer()
	print("GameClient: Sent harvest all request to server")
end

-- ========== REMOTE CONNECTIONS ==========

function GameClient:SetupRemoteConnections()
	print("GameClient: Setting up enhanced remote connections...")

	local remotes = ReplicatedStorage:WaitForChild("GameRemotes", 10)
	if not remotes then
		error("GameClient: GameRemotes folder not found after 10 seconds!")
	end

	self.RemoteEvents = {}
	self.RemoteFunctions = {}

	local requiredRemoteEvents = {
		-- Core game events
		"CollectMilk", "PlayerDataUpdated", "ShowNotification",
		"PlantSeed", "HarvestCrop", "HarvestAllCrops",


		-- Shop events (enhanced for tabbed system)
		"PurchaseItem", "ItemPurchased", "SellItem", "ItemSold", "CurrencyUpdated",

		-- Proximity events
		"OpenShop", "CloseShop"
	}

	local requiredRemoteFunctions = {
		-- Core functions
		"GetPlayerData", "GetFarmingData",

		-- Shop functions (enhanced for tabbed system)
		"GetShopItems", "GetSellableItems" -- REMOVED GetShopItemsByCategory
	}

	-- Load remote events
	for _, eventName in ipairs(requiredRemoteEvents) do
		local remote = remotes:FindFirstChild(eventName)
		if remote and remote:IsA("RemoteEvent") then
			self.RemoteEvents[eventName] = remote
			print("GameClient: ✅ Connected RemoteEvent: " .. eventName)
		else
			warn("GameClient: ⚠️  Missing RemoteEvent: " .. eventName)
		end
	end

	-- Load remote functions
	for _, funcName in ipairs(requiredRemoteFunctions) do
		local remote = remotes:FindFirstChild(funcName)
		if remote and remote:IsA("RemoteFunction") then
			self.RemoteFunctions[funcName] = remote
			print("GameClient: ✅ Connected RemoteFunction: " .. funcName)
		else
			warn("GameClient: ⚠️  Missing RemoteFunction: " .. funcName)
		end
	end

	self:SetupAllEventHandlers()

	print("GameClient: Enhanced remote connections established")
	print("  RemoteEvents: " .. self:CountTable(self.RemoteEvents))
	print("  RemoteFunctions: " .. self:CountTable(self.RemoteFunctions))
end

function GameClient:SetupAllEventHandlers()
	print("GameClient: Setting up all event handlers...")

	if self.ActiveConnections then
		for _, connection in pairs(self.ActiveConnections) do
			if connection and connection.Connected then
				connection:Disconnect()
			end
		end
	end
	self.ActiveConnections = {}

	local eventHandlers = {
		-- Player Data Updates
		PlayerDataUpdated = function(newData)
			pcall(function() self:HandlePlayerDataUpdate(newData) end)
		end,

		-- Farming System
		PlantSeed = function(plotModel)
			pcall(function()
				print("GameClient: Received plot click, showing seed selection for", plotModel.Name)
				self:ShowSeedSelectionForPlot(plotModel)
			end)
		end,

		-- Enhanced Shop System Events
		ItemPurchased = function(itemId, quantity, cost, currency)
			pcall(function() self:HandleEnhancedItemPurchased(itemId, quantity, cost, currency) end)
		end,

		ItemSold = function(itemId, quantity, earnings, currency)
			pcall(function() self:HandleItemSold(itemId, quantity, earnings, currency) end)
		end,

		CurrencyUpdated = function(currencyData)
			pcall(function() self:HandleCurrencyUpdate(currencyData) end)
		end,

		-- Notification Handler
		ShowNotification = function(title, message, notificationType)
			pcall(function() 
				if self.UIManager then
					self.UIManager:ShowNotification(title, message, notificationType) 
				end
			end)
		end,

	}

	-- Connect all handlers
	for eventName, handler in pairs(eventHandlers) do
		if self.RemoteEvents[eventName] then
			local connection = self.RemoteEvents[eventName].OnClientEvent:Connect(handler)
			table.insert(self.ActiveConnections, connection)
			print("GameClient: ✅ Connected " .. eventName)
		else
			warn("GameClient: ❌ Missing remote event: " .. eventName)
		end
	end
end

-- ========== PROXIMITY SYSTEM HANDLERS ==========

function GameClient:SetupProximitySystemHandlers()
	print("GameClient: Setting up proximity system handlers...")

	if self.RemoteEvents.OpenShop then
		self.RemoteEvents.OpenShop.OnClientEvent:Connect(function()
			print("GameClient: Proximity shop triggered - opening tabbed shop menu")
			self:OpenShopProximity()
		end)
	end

	if self.RemoteEvents.CloseShop then
		self.RemoteEvents.CloseShop.OnClientEvent:Connect(function()
			print("GameClient: Proximity shop close triggered")
			if self.UIManager and self.UIManager:GetCurrentPage() == "Shop" then
				self.UIManager:CloseActiveMenus()
			end
		end)
	end

	print("GameClient: Proximity system handlers setup complete")
end

-- ========== EVENT HANDLERS ==========

function GameClient:HandlePlayerDataUpdate(newData)
	if not newData then return end

	local oldData = self.PlayerData
	self.PlayerData = newData

	-- Update currency display through UIManager
	if self.UIManager then
		self.UIManager:UpdateCurrencyDisplay(newData)
	end

	-- Update current page if needed
	local currentPage = self.UIManager and self.UIManager:GetCurrentPage()
	if currentPage == "Shop" then
		-- Refresh the active shop tab if shop is open
		if self.UIManager then 
			self.UIManager:RefreshMenuContent("Shop") 
		end
	elseif currentPage == "Farm" then
		if self.UIManager then self.UIManager:RefreshMenuContent("Farm") end
	elseif currentPage == "Mining" then
		if self.UIManager then self.UIManager:RefreshMenuContent("Mining") end
	elseif currentPage == "Crafting" then
		if self.UIManager then self.UIManager:RefreshMenuContent("Crafting") end
	end

	-- FIXED: Smart planting mode seed check
	if self.FarmingState.isPlantingMode and self.FarmingState.selectedSeed then
		local currentSeeds = newData.farming and newData.farming.inventory or {}
		local newSeedCount = currentSeeds[self.FarmingState.selectedSeed] or 0

		-- Get old seed count for comparison
		local oldSeeds = oldData and oldData.farming and oldData.farming.inventory or {}
		local oldSeedCount = oldSeeds[self.FarmingState.selectedSeed] or 0

		-- Only show "out of seeds" if:
		-- 1. We have 0 seeds now, AND
		-- 2. We had 0 seeds before (meaning no successful planting just happened)
		-- This prevents the error when successfully planting the last seed
		if newSeedCount <= 0 then
			if oldSeedCount <= 0 then
				-- We already had no seeds and still have no seeds - this is a real "no seeds" situation
				self:ExitPlantingMode()
				if self.UIManager then
					self.UIManager:ShowNotification("Out of Seeds", 
						"You don't have any " .. (self.FarmingState.selectedSeed or ""):gsub("_", " ") .. " to plant!", "warning")
				end
			else
				-- We had seeds before but now have 0 - this means we just planted our last seed successfully
				-- Don't show error, but do exit planting mode
				self:ExitPlantingMode()
				if self.UIManager then
					self.UIManager:ShowNotification("Last Seed Planted", 
						"You planted your last " .. (self.FarmingState.selectedSeed or ""):gsub("_", " ") .. "! Buy more seeds to continue planting.", "info")
				end
			end
		end
	end
end

-- ENHANCED: Shop event handlers for tabbed system
function GameClient:HandleEnhancedItemPurchased(itemId, quantity, cost, currency)
	print("🎉 CLIENT: Received enhanced purchase confirmation!")
	print("    Item: " .. tostring(itemId))
	print("    Quantity: " .. tostring(quantity))

	-- Update local data
	if self.PlayerData then
		print("💳 CLIENT: Updating local currency data")
		local safeCost = cost or 0
		local safeCurrency = currency or "coins"
		local oldAmount = self.PlayerData[safeCurrency] or 0
		self.PlayerData[safeCurrency] = math.max(0, oldAmount - safeCost)

		if self.UIManager then
			self.UIManager:UpdateCurrencyDisplay(self.PlayerData)
		end
	end

	-- Enhanced category-aware notifications
	local categoryEmoji = self:GetCategoryEmoji(itemId)
	local itemCategory = self:GetItemCategory(itemId)

	if itemId:find("_seeds") then
		if self.UIManager then
			self.UIManager:ShowNotification(categoryEmoji .. " Seeds Purchased!", 
				"Added " .. tostring(quantity) .. "x " .. itemId:gsub("_", " ") .. " to your farming inventory!", "success")
		end
	elseif itemId == "farm_plot_starter" then
		if self.UIManager then
			self.UIManager:ShowNotification("🌾 Farm Plot Created!", 
				"Your farm plot is ready! Press F to start farming.", "success")
		end
	elseif itemCategory == "defense" then
		if self.UIManager then
			self.UIManager:ShowNotification("🛡️ Defense Purchase!", 
				"Added " .. itemId:gsub("_", " ") .. " to your defense arsenal!", "success")
		end
	elseif itemCategory == "mining" then
		if self.UIManager then
			self.UIManager:ShowNotification("⛏️ Mining Equipment!", 
				"Added " .. itemId:gsub("_", " ") .. " to your mining tools!", "success")
		end
	elseif itemCategory == "crafting" then
		if self.UIManager then
			self.UIManager:ShowNotification("🔨 Crafting Station!", 
				"Built " .. itemId:gsub("_", " ") .. " for your workshop!", "success")
		end
	elseif itemCategory == "premium" then
		if self.UIManager then
			self.UIManager:ShowNotification("✨ Premium Purchase!", 
				"Unlocked premium " .. itemId:gsub("_", " ") .. "!", "success")
		end
	else
		if self.UIManager then
			self.UIManager:ShowNotification("🛒 Purchase Complete!", 
				"Purchased " .. itemId, "success")
		end
	end

	-- Refresh shop if open (specific to active tab)
	if self.UIManager and self.UIManager:GetCurrentPage() == "Shop" then
		spawn(function()
			wait(0.5) -- Wait for server data update
			self.UIManager:RefreshMenuContent("Shop")
		end)
	end

	print("✅ CLIENT: Enhanced purchase handling completed")
end

function GameClient:HandleItemSold(itemId, quantity, earnings, currency)
	print("💰 CLIENT: Received sell confirmation!")
	print("    Item: " .. tostring(itemId))
	print("    Quantity: " .. tostring(quantity))
	print("    Earnings: " .. tostring(earnings))

	if self.PlayerData then
		local safeCurrency = currency or "coins"
		local safeEarnings = earnings or 0
		self.PlayerData[safeCurrency] = (self.PlayerData[safeCurrency] or 0) + safeEarnings

		if self.UIManager then
			self.UIManager:UpdateCurrencyDisplay(self.PlayerData)
		end
	end

	if self.UIManager then
		local itemName = self:GetItemDisplayName(itemId)
		local totalValue = quantity * (earnings / quantity) -- Calculate per-item price

		self.UIManager:ShowNotification("💰 Item Sold!", 
			"Sold " .. tostring(quantity) .. "x " .. itemName .. " for " .. tostring(earnings) .. " " .. currency .. "!", "success")
	end

	-- Refresh sell tab if shop is open and sell tab is active
	if self.UIManager and self.UIManager:GetCurrentPage() == "Shop" then
		if self.State.ActiveShopTab == "sell" then
			spawn(function()
				wait(0.5) -- Wait for server data update
				if self.UIManager then
					self.UIManager:PopulateShopTabContent("sell")
				end
			end)
		end
	end
end

function GameClient:RefreshMenuContent(menuName)
	if self.State.CurrentPage ~= menuName then return end

	print("GameClient: Refreshing content for " .. menuName)

	if menuName == "Shop" then
		-- Refresh current shop tab (including sell tab)
		local activeTab = self.State.ShopTabs and self.State.ShopTabs[self.State.ActiveShopTab]
		if activeTab then
			activeTab.populated = false
			if self.UIManager then
				self.UIManager:PopulateShopTabContent(self.State.ActiveShopTab)
			end
		end
	else
		local currentMenus = self.State.ActiveMenus
		self:CloseMenus()

		spawn(function()
			wait(0.1)
			self:OpenMenu(menuName)
		end)
	end
end

function GameClient:HandleCurrencyUpdate(currencyData)
	if currencyData and self.PlayerData then
		for currency, amount in pairs(currencyData) do
			self.PlayerData[currency] = amount
		end
		if self.UIManager then
			self.UIManager:UpdateCurrencyDisplay(self.PlayerData)
		end
	end
end

function GameClient:ShowSeedSelectionForPlot(plotModel)
	local playerData = self:GetPlayerData()
	if not playerData or not playerData.farming or not playerData.farming.inventory then
		if self.UIManager then
			self.UIManager:ShowNotification("No Seeds", "You need to buy seeds from the shop first!", "warning")
		end
		return
	end

	local availableSeeds = {}
	for itemId, quantity in pairs(playerData.farming.inventory) do
		if itemId:find("_seeds") and quantity > 0 then
			table.insert(availableSeeds, {id = itemId, quantity = quantity})
		end
	end

	if #availableSeeds == 0 then
		if self.UIManager then
			self.UIManager:ShowNotification("No Seeds", "You don't have any seeds to plant! Buy some from the shop.", "warning")
		end
		return
	end

	self:CreateSimpleSeedSelectionUI(plotModel, availableSeeds)
end

-- ========== FARMING MODE FUNCTIONS ==========

function GameClient:StartPlantingMode(seedId)
	print("GameClient: Starting planting mode with seed:", seedId)
	self.FarmingState.selectedSeed = seedId
	self.FarmingState.isPlantingMode = true
	if self.UIManager then
		self.UIManager:ShowNotification("🌱 Planting Mode", "Go to your farm and click on plots to plant seeds!", "success")
	end
end

function GameClient:ExitPlantingMode()
	print("GameClient: Exiting planting mode")
	self.FarmingState.selectedSeed = nil
	self.FarmingState.isPlantingMode = false
	if self.UIManager then
		self.UIManager:ShowNotification("🌱 Planting Mode", "Planting mode deactivated", "info")
	end
end

-- ========== DATA MANAGEMENT ==========

function GameClient:RequestInitialData()
	print("GameClient: Requesting initial data from server...")

	if self.RemoteFunctions.GetPlayerData then
		spawn(function()
			local success, data = pcall(function()
				return self.RemoteFunctions.GetPlayerData:InvokeServer()
			end)

			if success and data then
				print("GameClient: Received initial data from server")
				self:HandlePlayerDataUpdate(data)
			else
				warn("GameClient: Failed to get initial data: " .. tostring(data))
				self:HandlePlayerDataUpdate({
					coins = 0,
					farmTokens = 0,
					upgrades = {},
					purchaseHistory = {},
					farming = {
						plots = 0,
						inventory = {}

					}
				})
			end
		end)
	else
		warn("GameClient: GetPlayerData remote function not available")
	end
end

function GameClient:GetPlayerData()
	return self.PlayerData
end

-- ========== ENHANCED SHOP SYSTEM METHODS ==========

function GameClient:GetShopItems()
	print("🛒 CLIENT: Requesting shop items for tabbed system...")

	-- Try to get from cache first
	local currentTime = tick()
	if self.Cache.ShopItems and #self.Cache.ShopItems > 0 and 
		(currentTime - self.Cache.LastShopRefresh) < 30 then
		print("🛒 CLIENT: Using cached shop items")
		return self.Cache.ShopItems
	end

	-- Request fresh data from server
	if self.RemoteFunctions and self.RemoteFunctions.GetShopItems then
		print("🛒 CLIENT: Using ShopSystem RemoteFunction")
		local success, items = pcall(function()
			return self.RemoteFunctions.GetShopItems:InvokeServer()
		end)

		if success and items and type(items) == "table" then
			print("🛒 CLIENT: Received " .. #items .. " items from ShopSystem")

			local validItems = {}
			for _, item in ipairs(items) do
				if item.id and item.name and item.price and item.currency and item.category then
					table.insert(validItems, item)
				else
					warn("🛒 CLIENT: Invalid item received: " .. tostring(item.id))
				end
			end

			print("🛒 CLIENT: " .. #validItems .. " valid items after validation")
			if #validItems > 0 then
				-- Cache the results
				self.Cache.ShopItems = validItems
				self.Cache.LastShopRefresh = currentTime
				return validItems
			end
		else
			warn("🛒 CLIENT: ShopSystem RemoteFunction failed: " .. tostring(items))
		end
	else
		warn("🛒 CLIENT: GetShopItems RemoteFunction not available")
	end

	return {}
end

function GameClient:GetShopItemsByCategory(category)
	print("🛒 CLIENT: Requesting items for category: " .. category)

	-- Check if we have cached data for this category
	if self.Cache.ShopTabCache[category] then
		local cacheData = self.Cache.ShopTabCache[category]
		local currentTime = tick()

		if (currentTime - cacheData.timestamp) < 30 then
			print("🛒 CLIENT: Using cached data for " .. category)
			return cacheData.items
		end
	end

	-- Get all items and filter by category
	local allItems = self:GetShopItems()
	local categoryItems = {}

	for _, item in ipairs(allItems) do
		if item.category == category then
			table.insert(categoryItems, item)
		end
	end

	-- Sort by purchase order within category
	table.sort(categoryItems, function(a, b)
		local orderA = a.purchaseOrder or 999
		local orderB = b.purchaseOrder or 999

		if orderA == orderB then
			return a.price < b.price
		end

		return orderA < orderB
	end)

	-- Cache the filtered results
	self.Cache.ShopTabCache[category] = {
		items = categoryItems,
		timestamp = tick()
	}

	print("🛒 CLIENT: Filtered " .. #categoryItems .. " items for " .. category .. " category")
	return categoryItems
end
function GameClient:GetSellableItems()
	print("💰 CLIENT: Requesting sellable items...")

	-- Request sellable items from server
	if self.RemoteFunctions and self.RemoteFunctions.GetSellableItems then
		print("💰 CLIENT: Using GetSellableItems RemoteFunction")
		local success, items = pcall(function()
			return self.RemoteFunctions.GetSellableItems:InvokeServer()
		end)

		if success and items and type(items) == "table" then
			print("💰 CLIENT: Received " .. #items .. " sellable items")
			return items
		else
			warn("💰 CLIENT: GetSellableItems RemoteFunction failed: " .. tostring(items))
		end
	else
		warn("💰 CLIENT: GetSellableItems RemoteFunction not available")
	end

	return {}
end

function GameClient:PurchaseItem(item)
	if not self:CanAffordItem(item) then
		if self.UIManager then
			self.UIManager:ShowNotification("Insufficient Funds", "You don't have enough " .. item.currency .. "!", "error")
		end
		return
	end

	if self.RemoteEvents.PurchaseItem then
		print("GameClient: Purchasing item via ShopSystem:", item.id, "for", item.price, item.currency)
		self.RemoteEvents.PurchaseItem:FireServer(item.id, 1)

		-- Clear relevant cache after purchase
		self:ClearShopCache(item.category)
	else
		warn("GameClient: PurchaseItem remote event not available")
		if self.UIManager then
			self.UIManager:ShowNotification("Shop Error", "Purchase system unavailable!", "error")
		end
	end
end


function GameClient:SellItem(itemId, quantity)
	if not self.RemoteEvents.SellItem then
		if self.UIManager then
			self.UIManager:ShowNotification("Sell Error", "Sell system not available!", "error")
		end
		return false
	end

	print("💰 CLIENT: Selling " .. quantity .. "x " .. itemId)
	self.RemoteEvents.SellItem:FireServer(itemId, quantity)
	return true
end

function GameClient:CanAffordItem(item)
	if not item or not item.price or not item.currency then
		return false
	end

	local playerData = self:GetPlayerData()
	if not playerData then 
		return false 
	end

	local playerCurrency = playerData[item.currency] or 0
	return playerCurrency >= item.price
end

function GameClient:ClearShopCache(category)
	if category then
		self.Cache.ShopTabCache[category] = nil
		print("🛒 CLIENT: Cleared cache for " .. category .. " category")
	else
		self.Cache.ShopItems = {}
		self.Cache.ShopTabCache = {}
		self.Cache.LastShopRefresh = 0
		print("🛒 CLIENT: Cleared all shop cache")
	end
end

-- ========== CATEGORY HELPER FUNCTIONS ==========

function GameClient:GetCategoryEmoji(itemId)
	local categoryEmojis = {
		seeds = "🌱",
		farm = "🌾",
		defense = "🛡️",
		mining = "⛏️",
		crafting = "🔨",
		premium = "✨"
	}

	local category = self:GetItemCategory(itemId)
	return categoryEmojis[category] or "📦"
end

function GameClient:GetItemCategory(itemId)
	if not ItemConfig or not ItemConfig.ShopItems then
		return "unknown"
	end

	local item = ItemConfig.ShopItems[itemId]
	return item and item.category or "unknown"
end

-- ========== FARMING SYSTEM ==========

function GameClient:CreateSimpleSeedSelectionUI(plotModel, availableSeeds)
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	local existingUI = playerGui:FindFirstChild("SeedSelectionUI")
	if existingUI then existingUI:Destroy() end

	local seedUI = Instance.new("ScreenGui")
	seedUI.Name = "SeedSelectionUI"
	seedUI.ResetOnSpawn = false
	seedUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	seedUI.Parent = playerGui

	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 300, 0, 200)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = Color3.fromRGB(40, 60, 40)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = seedUI

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.02, 0)
	corner.Parent = mainFrame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
	title.BorderSizePixel = 0
	title.Text = "🌱 Select Seed to Plant"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 80, 0, 30)
	closeButton.Position = UDim2.new(0.5, -40, 1, -40)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "Cancel"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.Gotham
	closeButton.Parent = mainFrame

	closeButton.MouseButton1Click:Connect(function()
		seedUI:Destroy()
	end)

	for i, seedData in ipairs(availableSeeds) do
		local seedButton = Instance.new("TextButton")
		seedButton.Size = UDim2.new(1, -20, 0, 30)
		seedButton.Position = UDim2.new(0, 10, 0, 40 + (i * 35))
		seedButton.BackgroundColor3 = Color3.fromRGB(80, 120, 80)
		seedButton.BorderSizePixel = 0
		seedButton.Text = seedData.id:gsub("_", " ") .. " (x" .. seedData.quantity .. ")"
		seedButton.TextColor3 = Color3.new(1, 1, 1)
		seedButton.TextScaled = true
		seedButton.Font = Enum.Font.Gotham
		seedButton.Parent = mainFrame

		seedButton.MouseButton1Click:Connect(function()
			print("GameClient: Player selected seed:", seedData.id)
			self:PlantSelectedSeed(plotModel, seedData.id)
			seedUI:Destroy()
		end)
	end
end

function GameClient:PlantSelectedSeed(plotModel, seedId)
	print("GameClient: Attempting to plant", seedId, "on plot", plotModel.Name)

	if self.RemoteEvents.PlantSeed then
		self.RemoteEvents.PlantSeed:FireServer(plotModel, seedId)
		if self.UIManager then
			self.UIManager:ShowNotification("🌱 Planting...", "Attempting to plant " .. seedId:gsub("_", " ") .. "!", "info")
		end
	else
		warn("GameClient: PlantSeed remote event not available")
		if self.UIManager then
			self.UIManager:ShowNotification("Error", "Planting system not available!", "error")
		end
	end
end


function GameClient:GetCropDisplayName(cropId)
	local displayNames = {
		carrot = "🥕 Carrot",
		corn = "🌽 Corn", 
		strawberry = "🍓 Strawberry",
		golden_fruit = "✨ Golden Fruit",
		wheat = "🌾 Wheat",
		potato = "🥔 Potato",
		tomato = "🍅 Tomato",
		cabbage = "🥬 Cabbage",
		radish = "🌶️ Radish",
		broccoli = "🥦 Broccoli",
		glorious_sunflower = "🌻 Glorious Sunflower",
		milk = "🥛 Fresh Milk",
		fresh_milk = "🥛 Fresh Milk",
		copper_ore = "🟫 Copper Ore",
		bronze_ore = "🟤 Bronze Ore",
		silver_ore = "⚪ Silver Ore",
		gold_ore = "🟡 Gold Ore",
		platinum_ore = "⚫ Platinum Ore",
		obsidian_ore = "⬛ Obsidian Ore"
	}

	return displayNames[cropId] or cropId:gsub("_", " "):gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
end

function GameClient:GetItemDisplayName(itemId)
	local names = {
		-- Seeds
		carrot_seeds = "Carrot Seeds",
		corn_seeds = "Corn Seeds",
		strawberry_seeds = "Strawberry Seeds",
		golden_seeds = "Golden Seeds",
		wheat_seeds = "Wheat Seeds",
		potato_seeds = "Potato Seeds",
		cabbage_seeds = "Cabbage Seeds",
		radish_seeds = "Radish Seeds",
		broccoli_seeds = "Broccoli Seeds",
		tomato_seeds = "Tomato Seeds",
		glorious_sunflower_seeds = "Glorious Sunflower Seeds",

		-- Crops
		carrot = "Carrots",
		corn = "Corn",
		strawberry = "Strawberries",
		golden_fruit = "Golden Fruit",
		wheat = "Wheat",
		potato = "Potatoes",
		cabbage = "Cabbage",
		radish = "Radishes",
		broccoli = "Broccoli",
		tomato = "Tomatoes",
		glorious_sunflower = "Glorious Sunflower",

		-- Animal products
		milk = "Fresh Milk",
		fresh_milk = "Fresh Milk",

		-- Mining tools
		basic_pickaxe = "Basic Pickaxe",
		stone_pickaxe = "Stone Pickaxe",
		iron_pickaxe = "Iron Pickaxe",
		diamond_pickaxe = "Diamond Pickaxe",
		obsidian_pickaxe = "Obsidian Pickaxe",
		cave_access_pass = "Cave Access Pass",

		-- Crafting items
		basic_workbench = "Basic Workbench",
		forge = "Advanced Forge",
		mystical_altar = "Mystical Altar",

		-- Premium items
		auto_harvester = "Auto Harvester",
		rarity_booster = "Rarity Booster",

		-- Cow system
		milk_efficiency_1 = "Enhanced Milking I",
		milk_efficiency_2 = "Enhanced Milking II",
		milk_efficiency_3 = "Enhanced Milking III",
		milk_value_boost = "Premium Milk Quality",

		-- Ores
		copper_ore = "Copper Ore",
		bronze_ore = "Bronze Ore",
		silver_ore = "Silver Ore",
		gold_ore = "Gold Ore",
		platinum_ore = "Platinum Ore",
		obsidian_ore = "Obsidian Ore"
	}

	if names[itemId] then
		return names[itemId]
	else
		return itemId:gsub("_", " "):gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
	end
end

-- ========== PROXIMITY SHOP METHOD ==========

function GameClient:OpenShopProximity()
	print("GameClient: Opening tabbed shop via proximity system")
	if self.UIManager then
		return self.UIManager:OpenMenu("Shop")
	end
	return false
end

-- ========== UTILITY FUNCTIONS ==========

function GameClient:CountTable(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- ========== ERROR RECOVERY ==========

function GameClient:RecoverFromError(errorMsg)
	warn("GameClient: Attempting recovery from error: " .. tostring(errorMsg))

	self.FarmingState = {
		selectedSeed = nil,
		isPlantingMode = false,
		selectedCrop = nil,
		seedInventory = {},
		activeBoosters = {},
		rarityPreview = nil
	}

	-- Clear shop cache on error
	self:ClearShopCache()

	local success, error = pcall(function()
		self:SetupRemoteConnections()
	end)

	if success then
		print("GameClient: Recovery successful")
		return true
	else
		warn("GameClient: Recovery failed: " .. tostring(error))
		return false
	end
end

-- ========== DEBUG FUNCTIONS ==========

function GameClient:DebugStatus()
	print("=== ENHANCED GAMECLIENT DEBUG STATUS ===")
	print("PlayerData exists:", self.PlayerData ~= nil)
	if self.PlayerData then
		print("  Coins:", self.PlayerData.coins or "N/A")
		print("  Farm Tokens:", self.PlayerData.farmTokens or "N/A") 
		print("  Farming data exists:", self.PlayerData.farming ~= nil)
	end
	print("UIManager exists:", self.UIManager ~= nil)
	if self.UIManager then
		print("  UIManager state exists:", self.UIManager.State ~= nil)
		print("  Current page:", self.UIManager:GetCurrentPage() or "None")
		if self.UIManager.State and self.UIManager.State.ShopTabs then
			print("  Active shop tab:", self.UIManager.State.ActiveShopTab or "None")
		end
	end
	print("RemoteEvents count:", self.RemoteEvents and self:CountTable(self.RemoteEvents) or 0)
	print("RemoteFunctions count:", self.RemoteFunctions and self:CountTable(self.RemoteFunctions) or 0)
	print("Shop cache status:")
	print("  Cached items:", self.Cache.ShopItems and #self.Cache.ShopItems or 0)
	print("  Cached tabs:", self.Cache.ShopTabCache and self:CountTable(self.Cache.ShopTabCache) or 0)
	print("Shop access: PROXIMITY ONLY")
	print("Available hotkeys: F=Farm, M=Mining, C=Crafting, H=Harvest All")
	print("=====================================")
end

function GameClient:DebugShopCache()
	print("=== ENHANCED SHOP CACHE DEBUG ===")
	print("Total cached items:", self.Cache.ShopItems and #self.Cache.ShopItems or 0)
	print("Last refresh:", self.Cache.LastShopRefresh or 0)
	print("Tab cache:")
	for category, data in pairs(self.Cache.ShopTabCache or {}) do
		print("  " .. category .. ": " .. #data.items .. " items (age: " .. (tick() - data.timestamp) .. "s)")
	end

	-- Test sellable items
	if self.GetSellableItems then
		local sellableItems = self:GetSellableItems()
		print("Current sellable items: " .. #sellableItems)
		for i, item in ipairs(sellableItems) do
			print("  " .. item.name .. ": " .. item.stock .. " in stock (value: " .. item.totalValue .. " coins)")
		end
	end
	print("========================")
end

-- ========== CLEANUP ==========

function GameClient:Cleanup()
	if self.ActiveConnections then
		for _, connection in pairs(self.ActiveConnections) do
			if connection and connection.Connected then
				connection:Disconnect()
			end
		end
	end

	if self.UIManager then
		self.UIManager:Cleanup()
	end

	self.PlayerData = {}
	self.ActiveConnections = {}
	self.FarmingState = {
		selectedSeed = nil,
		isPlantingMode = false,
		selectedCrop = nil,
		seedInventory = {},
		activeBoosters = {},
		rarityPreview = nil
	}
	self.Cache = {
		ShopItems = {},
		CowCooldown = 0,
		ShopTabCache = {},
		LastShopRefresh = 0
	}
	self:CleanupMilkingUI()

	print("GameClient: Cleaned up")
end

-- ========== GLOBAL REGISTRATION ==========

_G.GameClient = GameClient

_G.GetGameClient = function()
	return _G.GameClient
end

_G.DebugGameClient = function()
	if _G.GameClient and _G.GameClient.DebugStatus then
		_G.GameClient:DebugStatus()
	end
end

_G.DebugShopCache = function()
	if _G.GameClient and _G.GameClient.DebugShopCache then
		_G.GameClient:DebugShopCache()
	end
end

_G.TestFarm = function()
	if _G.GameClient then
		_G.GameClient:OpenMenu("Farm")
	end
end
function GameClient:DebugModularSystem()
	print("=== MODULAR SYSTEM CLIENT DEBUG ===")
	print("Requesting server module status...")

	-- You could add a new remote function to check server module status
	if self.RemoteFunctions.GetModuleStatus then
		local success, moduleStatus = pcall(function()
			return self.RemoteFunctions.GetModuleStatus:InvokeServer()
		end)

		if success and moduleStatus then
			print("Server Module Status:")
			print("  CropCreation: " .. (moduleStatus.CropCreation and "✅ LOADED" or "❌ FAILED"))
			print("  CropVisual: " .. (moduleStatus.CropVisual and "✅ LOADED" or "❌ FAILED"))
			print("  FarmPlot: " .. (moduleStatus.FarmPlot and "✅ LOADED" or "❌ FAILED"))
			print("  MutationSystem: " .. (moduleStatus.MutationSystem and "✅ LOADED" or "ℹ️ OPTIONAL"))
		else
			print("❌ Could not get module status from server")
		end
	else
		print("ℹ️ Module status checking not available")
	end
	print("==================================")
end

-- Global debug function
_G.DebugModularSystem = function()
	if _G.GameClient and _G.GameClient.DebugModularSystem then
		_G.GameClient:DebugModularSystem()
	end
end
print("GameClient: ✅ Enhanced for tabbed shop system!")
print("🎯 Changes Made:")
print("  🛒 Enhanced shop system with tab support")
print("  📦 Smart caching for better performance")
print("  🏷️ Category-aware purchase notifications")
print("  🔄 Tab-specific cache management")
print("  📊 Enhanced debugging tools")
print("")
print("🔧 Available Features:")
print("  🛒 Shop: Tabbed interface via proximity")
print("  🌾 Farming: F key or button")
print("  ⛏️ Mining: M key or button")
print("  🔨 Crafting: C key or button")
print("  🌾 Harvest All: H key")
print("")
print("🔧 Debug Commands:")
print("  _G.TestFarm() - Open farm menu")
print("  _G.DebugGameClient() - Show system status")
print("  _G.DebugShopCache() - Show shop cache status")

return GameClient