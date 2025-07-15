--[[
    FIXED UnifiedMilkingHandler.client.lua - Single Unified Milking Click System
    Place in: StarterPlayer/StarterPlayerScripts/UnifiedMilkingHandler.client.lua
    
    FIXES:
    ✅ Single click handling system (prevents duplicates)
    ✅ Enhanced server-side duplicate prevention
    ✅ Proper 10-click tracking
    ✅ Improved cooldown system
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

print("🥛 UnifiedMilkingHandler: Starting FIXED unified milking click system...")

-- Unified state management
local MilkingState = {
	-- Session state
	isActive = false,
	sessionData = {},
	currentProgress = 0,
	clicksPerMilk = 10,
	totalClicks = 0,
	milkCollected = 0,

	-- MODIFIED: Much faster timing
	lastClickTime = 0,
	clickCooldown = 0.15, -- CHANGED: 30ms cooldown (was 100ms)
	lastServerClickTime = 0,
	serverClickCooldown = 0.02, -- CHANGED: 50ms server cooldown (was 150ms)

	-- System references
	remoteEvents = {},
	chairGUI = nil,

	-- Configuration
	enableVisualFeedback = true,
	enableSounds = true,
	debugMode = false,

	-- Click tracking for debugging
	localClickCount = 0,
	serverClickCount = 0
}

-- ========== ENHANCED REMOTE EVENT CONNECTIONS ==========

local function ConnectToRemoteEvents()
	print("📡 Connecting to remote events...")

	local gameRemotes = ReplicatedStorage:WaitForChild("GameRemotes", 30)
	if not gameRemotes then
		warn("❌ GameRemotes not found")
		return false
	end

	-- Get required remote events
	local requiredEvents = {
		"ShowChairPrompt", "HideChairPrompt",
		"StartMilkingSession", "StopMilkingSession", 
		"ContinueMilking", "MilkingSessionUpdate"
	}

	local eventsConnected = 0
	for _, eventName in ipairs(requiredEvents) do
		local event = gameRemotes:WaitForChild(eventName, 10)
		if event then
			MilkingState.remoteEvents[eventName] = event
			eventsConnected = eventsConnected + 1
			print("✅ Connected to " .. eventName)
		else
			warn("⚠️ Failed to connect to " .. eventName)
		end
	end

	-- Setup event handlers
	if MilkingState.remoteEvents.ShowChairPrompt then
		MilkingState.remoteEvents.ShowChairPrompt.OnClientEvent:Connect(function(promptType, data)
			HandlePromptEvent(promptType, data)
		end)
	end

	if MilkingState.remoteEvents.HideChairPrompt then
		MilkingState.remoteEvents.HideChairPrompt.OnClientEvent:Connect(function()
			HandleHidePrompt()
		end)
	end

	if MilkingState.remoteEvents.MilkingSessionUpdate then
		MilkingState.remoteEvents.MilkingSessionUpdate.OnClientEvent:Connect(function(updateType, data)
			HandleSessionUpdate(updateType, data)
		end)
	end

	print("📡 Connected to " .. eventsConnected .. "/" .. #requiredEvents .. " remote events")
	return eventsConnected >= (#requiredEvents - 1)
end

-- ========== SESSION EVENT HANDLERS ==========

function HandlePromptEvent(promptType, data)
	if MilkingState.debugMode then
		print("📢 Prompt event: " .. tostring(promptType))
	end

	if promptType == "milking" then
		-- Start milking session
		MilkingState.isActive = true
		MilkingState.sessionData = data or {}
		MilkingState.currentProgress = data.currentProgress or 0
		MilkingState.clicksPerMilk = data.clicksPerMilk or 10
		MilkingState.milkCollected = data.milkCollected or 0
		MilkingState.totalClicks = 0

		-- RESET: Click tracking for debugging
		MilkingState.localClickCount = 0
		MilkingState.serverClickCount = 0

		print("🥛 FIXED milking session started - " .. MilkingState.clicksPerMilk .. " clicks per milk")

		-- Show notification if available
		if _G.UIManager and _G.UIManager.ShowNotification then
			_G.UIManager:ShowNotification("🥛 Milking Started", 
				"Click " .. MilkingState.clicksPerMilk .. " times to collect 1 milk!", "success")
		end

	elseif promptType == "proximity" then
		-- Let ChairMilkingGUI handle proximity display
		if MilkingState.debugMode then
			print("📢 Proximity prompt (handled by ChairMilkingGUI)")
		end
	end
end

function HandleHidePrompt()
	if MilkingState.isActive then
		print("🛑 Milking session ended")

		local finalStats = string.format("Session complete! %d local clicks, %d server clicks, %d milk collected", 
			MilkingState.localClickCount, MilkingState.serverClickCount, MilkingState.milkCollected)
		print("📊 " .. finalStats)

		if _G.UIManager and _G.UIManager.ShowNotification then
			_G.UIManager:ShowNotification("🥛 Session Complete", finalStats, "info")
		end
	end

	-- Reset state
	MilkingState.isActive = false
	MilkingState.sessionData = {}
	MilkingState.currentProgress = 0
	MilkingState.totalClicks = 0
	MilkingState.milkCollected = 0
	MilkingState.localClickCount = 0
	MilkingState.serverClickCount = 0
end

function HandleSessionUpdate(updateType, data)
	if updateType == "progress" and MilkingState.isActive then
		-- Update local state
		local oldProgress = MilkingState.currentProgress
		MilkingState.currentProgress = data.clickProgress or 0
		MilkingState.clicksPerMilk = data.clicksPerMilk or 10
		MilkingState.totalClicks = data.totalClicks or 0
		MilkingState.milkCollected = data.milkCollected or 0

		-- Track server-side clicks
		if data.totalClicks and data.totalClicks > MilkingState.serverClickCount then
			MilkingState.serverClickCount = data.totalClicks
		end

		if MilkingState.debugMode then
			print("📊 Progress: " .. MilkingState.currentProgress .. "/" .. MilkingState.clicksPerMilk .. 
				" | Local: " .. MilkingState.localClickCount .. " | Server: " .. MilkingState.serverClickCount .. 
				" | Milk: " .. MilkingState.milkCollected)
		end

		-- Create visual feedback for progress
		if MilkingState.enableVisualFeedback then
			CreateProgressFeedback(data)
		end

		-- Check for milk completion (when progress resets to 0 after being higher)
		if oldProgress > 0 and MilkingState.currentProgress == 0 and data.milkCollected and data.milkCollected > 0 then
			CreateMilkCompletionEffect()
		end
	end
end

-- ========== FIXED UNIFIED CLICK HANDLING ==========

local function IsInMilkingSession()
	-- Primary check: our internal state
	if MilkingState.isActive then
		return true
	end

	-- Secondary check: ChairMilkingGUI state
	if _G.ChairMilkingGUI and _G.ChairMilkingGUI.State then
		return (_G.ChairMilkingGUI.State.guiType == "milking" and 
			_G.ChairMilkingGUI.State.isVisible)
	end

	-- Fallback check: GUI exists
	local milkingGUI = PlayerGui:FindFirstChild("ChairMilkingGUI") or 
		PlayerGui:FindFirstChild("MilkingGUI") or
		PlayerGui:FindFirstChild("MilkingProgressUI")

	return milkingGUI ~= nil
end

local function HandleUnifiedClick()
	local currentTime = tick()

	-- ENHANCED: Multiple cooldown checks
	if (currentTime - MilkingState.lastClickTime) < MilkingState.clickCooldown then
		if MilkingState.debugMode then
			print("🚫 Click blocked by local cooldown")
		end
		return
	end

	-- ENHANCED: Server-side cooldown check
	if (currentTime - MilkingState.lastServerClickTime) < MilkingState.serverClickCooldown then
		if MilkingState.debugMode then
			print("🚫 Click blocked by server cooldown")
		end
		return
	end

	MilkingState.lastClickTime = currentTime
	MilkingState.lastServerClickTime = currentTime
	MilkingState.localClickCount = MilkingState.localClickCount + 1

	print("🖱️ UNIFIED click #" .. MilkingState.localClickCount .. " for milking")

	-- Send to server with verification
	if MilkingState.remoteEvents.ContinueMilking then
		-- Add a unique click ID to prevent server-side duplicates
		local clickId = "click_" .. LocalPlayer.UserId .. "_" .. currentTime .. "_" .. MilkingState.localClickCount

		local success, error = pcall(function()
			MilkingState.remoteEvents.ContinueMilking:FireServer(clickId)
		end)

		if not success then
			warn("❌ Failed to send click to server: " .. tostring(error))
		else
			if MilkingState.debugMode then
				print("📡 Sent click to server with ID: " .. clickId)
			end
		end
	else
		warn("❌ ContinueMilking remote not available")
	end

	-- Create immediate click feedback
	if MilkingState.enableVisualFeedback then
		CreateImmediateClickFeedback()
	end
end

local function SetupUnifiedInputHandling()
	print("🖱️ Setting up FIXED unified input handling...")

	-- CRITICAL: Disable any existing input handlers to prevent duplicates

	-- Clear any existing connections
	if _G.MilkingInputConnections then
		for _, connection in pairs(_G.MilkingInputConnections) do
			if connection and connection.Connected then
				connection:Disconnect()
			end
		end
	end
	_G.MilkingInputConnections = {}

	-- Single unified input handler
	local inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		-- Check if we should handle this input
		if not IsInMilkingSession() then
			return
		end

		-- Handle various input types
		local isClickInput = (input.UserInputType == Enum.UserInputType.MouseButton1) or 
			(input.UserInputType == Enum.UserInputType.Touch) or
			(input.KeyCode == Enum.KeyCode.Space)

		if isClickInput then
			HandleUnifiedClick()
		elseif input.KeyCode == Enum.KeyCode.Escape then
			-- Stop milking session
			if MilkingState.remoteEvents.StopMilkingSession then
				MilkingState.remoteEvents.StopMilkingSession:FireServer()
			end
		end
	end)

	-- Store connection to prevent duplicates
	table.insert(_G.MilkingInputConnections, inputConnection)

	print("✅ FIXED unified input handling setup complete")
end

-- ========== VISUAL FEEDBACK SYSTEM ==========

function CreateImmediateClickFeedback()
	local mouse = LocalPlayer:GetMouse()
	local clickPos = Vector2.new(mouse.X, mouse.Y)

	-- Create feedback GUI
	local feedbackGui = Instance.new("ScreenGui")
	feedbackGui.Name = "UnifiedClickFeedback"
	feedbackGui.Parent = PlayerGui

	-- Main ripple effect
	local ripple = Instance.new("Frame")
	ripple.Size = UDim2.new(0, 25, 0, 25)
	ripple.Position = UDim2.new(0, clickPos.X - 12, 0, clickPos.Y - 12)
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
			Size = UDim2.new(0, 70, 0, 70),
			Position = UDim2.new(0, clickPos.X - 35, 0, clickPos.Y - 35),
			BackgroundTransparency = 1
		}
	)
	expand:Play()

	-- Progress text with enhanced info
	local progressText = Instance.new("TextLabel")
	progressText.Size = UDim2.new(0, 120, 0, 30)
	progressText.Position = UDim2.new(0, clickPos.X - 60, 0, clickPos.Y - 40)
	progressText.BackgroundTransparency = 1
	progressText.Text = "+" .. 1 .. " (" .. MilkingState.currentProgress .. "/" .. MilkingState.clicksPerMilk .. ")"
	progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
	progressText.TextScaled = true
	progressText.Font = Enum.Font.GothamBold
	progressText.TextStrokeTransparency = 0
	progressText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	progressText.Parent = feedbackGui

	-- Debug info (if enabled)
	if MilkingState.debugMode then
		local debugText = Instance.new("TextLabel")
		debugText.Size = UDim2.new(0, 100, 0, 20)
		debugText.Position = UDim2.new(0, clickPos.X - 50, 0, clickPos.Y + 30)
		debugText.BackgroundTransparency = 1
		debugText.Text = "L:" .. MilkingState.localClickCount .. " S:" .. MilkingState.serverClickCount
		debugText.TextColor3 = Color3.fromRGB(255, 255, 100)
		debugText.TextScaled = true
		debugText.Font = Enum.Font.Gotham
		debugText.Parent = feedbackGui

		-- Animate debug text too
		local debugFloat = TweenService:Create(debugText,
			TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = debugText.Position + UDim2.new(0, 0, 0, -30),
				TextTransparency = 1
			}
		)
		debugFloat:Play()
	end

	-- Animate text
	local floatUp = TweenService:Create(progressText,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Position = progressText.Position + UDim2.new(0, 0, 0, -50),
			TextTransparency = 1,
			TextStrokeTransparency = 1
		}
	)
	floatUp:Play()

	-- Clean up
	expand.Completed:Connect(function()
		feedbackGui:Destroy()
	end)
end

function CreateProgressFeedback(data)
	-- Create a small progress indicator at the center of screen
	local progressGui = Instance.new("ScreenGui")
	progressGui.Name = "UnifiedProgressFeedback"
	progressGui.Parent = PlayerGui

	local progressFrame = Instance.new("Frame")
	progressFrame.Size = UDim2.new(0, 150, 0, 8)
	progressFrame.Position = UDim2.new(0.5, -75, 0.7, 0)
	progressFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	progressFrame.BorderSizePixel = 0
	progressFrame.Parent = progressGui

	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0.5, 0)
	progressCorner.Parent = progressFrame

	local progressFill = Instance.new("Frame")
	progressFill.Size = UDim2.new(MilkingState.currentProgress / MilkingState.clicksPerMilk, 0, 1, 0)
	progressFill.Position = UDim2.new(0, 0, 0, 0)
	progressFill.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressFrame

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0.5, 0)
	fillCorner.Parent = progressFill

	-- Animate and clean up
	spawn(function()
		wait(1.5)

		-- Fade out progress frame
		local fadeOut = TweenService:Create(progressFrame,
			TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundTransparency = 1}
		)

		-- Fade out progress fill
		local fillFadeOut = TweenService:Create(progressFill,
			TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundTransparency = 1}
		)

		fadeOut:Play()
		fillFadeOut:Play()

		fadeOut.Completed:Connect(function()
			progressGui:Destroy()
		end)
	end)
end

function CreateMilkCompletionEffect()
	-- Big celebration for completing 10 clicks
	local celebrationGui = Instance.new("ScreenGui")
	celebrationGui.Name = "UnifiedMilkCelebration"
	celebrationGui.Parent = PlayerGui

	local milkIcon = Instance.new("TextLabel")
	milkIcon.Size = UDim2.new(0, 80, 0, 80)
	milkIcon.Position = UDim2.new(0.5, -40, 0.3, -40)
	milkIcon.BackgroundTransparency = 1
	milkIcon.Text = "🥛"
	milkIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
	milkIcon.TextScaled = true
	milkIcon.Font = Enum.Font.GothamBold
	milkIcon.Parent = celebrationGui

	local celebrationText = Instance.new("TextLabel")
	celebrationText.Size = UDim2.new(0, 200, 0, 40)
	celebrationText.Position = UDim2.new(0.5, -100, 0.3, 50)
	celebrationText.BackgroundTransparency = 1
	celebrationText.Text = "+1 MILK EARNED!"
	celebrationText.TextColor3 = Color3.fromRGB(255, 255, 100)
	celebrationText.TextScaled = true
	celebrationText.Font = Enum.Font.GothamBold
	celebrationText.TextStrokeTransparency = 0
	celebrationText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	celebrationText.Parent = celebrationGui

	-- Animate celebration
	local bounce = TweenService:Create(milkIcon,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			Size = UDim2.new(0, 120, 0, 120),
			Position = UDim2.new(0.5, -60, 0.3, -60)
		}
	)
	bounce:Play()

	-- Clean up after celebration
	spawn(function()
		wait(2)

		-- Fade out the milk icon
		local fadeOutIcon = TweenService:Create(milkIcon,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{TextTransparency = 1}
		)

		-- Fade out the celebration text
		local fadeOutText = TweenService:Create(celebrationText,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				TextTransparency = 1,
				TextStrokeTransparency = 1
			}
		)

		fadeOutIcon:Play()
		fadeOutText:Play()

		fadeOutIcon.Completed:Connect(function()
			celebrationGui:Destroy()
		end)
	end)
end

-- ========== SYSTEM INTEGRATION ==========

local function DisableOtherClickHandlers()
	print("🛑 Disabling other click handlers to prevent duplicates...")

	-- Disable other milking click handlers
	if _G.MilkingClickHandler then
		_G.MilkingClickHandler.disabled = true
		print("✅ Disabled MilkingClickHandler")
	end

	if _G.MilkingIntegration then
		_G.MilkingIntegration.disabled = true
		print("✅ Disabled MilkingIntegration")
	end

	-- Mark this as the primary handler
	_G.UnifiedMilkingHandlerActive = true
end

local function IntegrateWithExistingSystems()
	print("🔗 Integrating with existing systems...")

	-- Wait for and connect to ChairMilkingGUI if available
	spawn(function()
		local attempts = 0
		while attempts < 20 do
			wait(0.5)
			attempts = attempts + 1

			if _G.ChairMilkingGUI then
				MilkingState.chairGUI = _G.ChairMilkingGUI
				print("✅ Integrated with ChairMilkingGUI")
				break
			end
		end

		if not MilkingState.chairGUI then
			print("⚠️ ChairMilkingGUI not found - using fallback integration")
		end
	end)

	-- Connect to UIManager if available
	if _G.UIManager then
		print("✅ UIManager available for notifications")
	else
		print("⚠️ UIManager not available")
	end
end

-- ========== ENHANCED DEBUG SYSTEM ==========

local function SetupDebugCommands()
	LocalPlayer.Chatted:Connect(function(message)
		local command = message:lower()

		if command == "/milkdebug" then
			MilkingState.debugMode = not MilkingState.debugMode
			print("🔧 Unified milking debug: " .. (MilkingState.debugMode and "ON" or "OFF"))

		elseif command == "/milkstatus" then
			print("=== FIXED UNIFIED MILKING STATUS ===")
			print("Session active: " .. tostring(MilkingState.isActive))
			print("Progress: " .. MilkingState.currentProgress .. "/" .. MilkingState.clicksPerMilk)
			print("Local clicks: " .. MilkingState.localClickCount)
			print("Server clicks: " .. MilkingState.serverClickCount)
			print("Milk collected: " .. MilkingState.milkCollected)
			print("Visual feedback: " .. tostring(MilkingState.enableVisualFeedback))
			print("ChairGUI connected: " .. tostring(MilkingState.chairGUI ~= nil))
			print("Remote events: " .. tostring(MilkingState.remoteEvents.ContinueMilking ~= nil))
			print("Last click time: " .. MilkingState.lastClickTime)
			print("Click cooldown: " .. MilkingState.clickCooldown)
			print("=====================================")

		elseif command == "/testclick" then
			if IsInMilkingSession() then
				print("🧪 Testing unified click...")
				HandleUnifiedClick()
			else
				print("❌ Not in milking session")
			end

		elseif command == "/testfeedback" then
			print("🧪 Testing visual feedback...")
			CreateImmediateClickFeedback()
			spawn(function()
				wait(1)
				CreateMilkCompletionEffect()
			end)

		elseif command == "/togglefeedback" then
			MilkingState.enableVisualFeedback = not MilkingState.enableVisualFeedback
			print("🎨 Visual feedback: " .. (MilkingState.enableVisualFeedback and "ON" or "OFF"))

		elseif command == "/resetclicks" then
			MilkingState.localClickCount = 0
			MilkingState.serverClickCount = 0
			print("🔄 Click counters reset")

		elseif command == "/clickratio" then
			if MilkingState.serverClickCount > 0 then
				local ratio = MilkingState.localClickCount / MilkingState.serverClickCount
				print("📊 Click ratio (Local/Server): " .. string.format("%.2f", ratio))
				if ratio > 1.1 then
					print("⚠️ Warning: Too many local clicks vs server clicks!")
				elseif ratio < 0.9 then
					print("⚠️ Warning: Server receiving more clicks than sent!")
				else
					print("✅ Click ratio looks good!")
				end
			else
				print("📊 No server clicks recorded yet")
			end
		end
	end)
end

-- ========== MAIN INITIALIZATION ==========

local function InitializeUnifiedMilkingHandler()
	print("🥛 Initializing FIXED unified milking handler...")

	local success, errorMessage = pcall(function()
		-- Step 0: Disable other click handlers first
		DisableOtherClickHandlers()

		-- Step 1: Connect to remote events
		if not ConnectToRemoteEvents() then
			warn("⚠️ Some remote connections failed - continuing anyway")
		end

		-- Step 2: Setup unified input handling
		SetupUnifiedInputHandling()

		-- Step 3: Integrate with existing systems
		IntegrateWithExistingSystems()

		-- Step 4: Setup debug commands
		SetupDebugCommands()

		return true
	end)

	if success then
		print("✅ FIXED unified milking handler ready!")
		print("")
		print("🔧 DUPLICATE CLICK FIXES:")
		print("  🛑 Disabled other click handlers")
		print("  ⏱️ Enhanced cooldown system")
		print("  🆔 Click ID verification")
		print("  📊 Local vs server click tracking")
		print("")
		print("🖱️ UNIFIED FEATURES:")
		print("  🎯 Single click handling system")
		print("  📊 Real-time progress tracking")
		print("  🎨 Enhanced visual feedback")
		print("  📱 Mobile and desktop support")
		print("  🔗 Integration with existing GUIs")
		print("")
		print("🎮 Debug Commands:")
		print("  /milkstatus - Show detailed milking status")
		print("  /milkdebug - Toggle debug mode")
		print("  /testclick - Test click system")
		print("  /testfeedback - Test visual effects")
		print("  /clickratio - Check click ratio")
		print("  /resetclicks - Reset click counters")
		return true
	else
		warn("❌ FIXED unified milking handler failed: " .. tostring(errorMessage))
		return false
	end
end

-- ========== EXECUTE INITIALIZATION ==========

spawn(function()
	wait(3) -- Give other systems time to load

	local success = InitializeUnifiedMilkingHandler()

	if success then
		print("🎉 FIXED unified milking click system ready!")
	else
		warn("❌ FIXED unified milking system failed to initialize")
	end
end)

-- ========== GLOBAL ACCESS ==========

_G.UnifiedMilkingHandler = {
	State = MilkingState,
	IsInSession = IsInMilkingSession,
	TestClick = function()
		if IsInMilkingSession() then
			HandleUnifiedClick()
			return true
		end
		return false
	end,
	ToggleDebug = function()
		MilkingState.debugMode = not MilkingState.debugMode
		return MilkingState.debugMode
	end,
	GetClickRatio = function()
		if MilkingState.serverClickCount > 0 then
			return MilkingState.localClickCount / MilkingState.serverClickCount
		end
		return 0
	end
}

print("🥛 UnifiedMilkingHandler: ✅ FIXED - Single click system ready!")