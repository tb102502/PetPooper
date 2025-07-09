--[[
    UPDATED MilkingIntegration.client.lua - 10-Click System Integration
    Place in: StarterPlayer/StarterPlayerScripts/MilkingIntegration.client.lua
    
    UPDATES:
    ✅ Connects 10-click progress system
    ✅ Enhanced click detection and feedback
    ✅ Better error handling and reconnection
    ✅ Debug tools for troubleshooting
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

print("🔗 MilkingIntegration: Starting 10-click integration...")

-- Integration State
local IntegrationState = {
	chairGUI = nil,
	gameRemotes = nil,
	continueMilking = nil,
	isConnected = false,
	lastClickTime = 0,
	clickCooldown = 0.05, -- Very responsive for 10-click system
	connectionRetries = 0,
	maxRetries = 10
}

-- ========== SYSTEM CONNECTION ==========

local function waitForSystem(systemName, globalVar, timeout)
	timeout = timeout or 30
	local startTime = tick()

	while (tick() - startTime) < timeout do
		if _G[globalVar] then
			print("✅ MilkingIntegration: " .. systemName .. " found!")
			return _G[globalVar]
		end
		wait(0.1)
	end

	warn("❌ MilkingIntegration: " .. systemName .. " not found after " .. timeout .. " seconds")
	return nil
end

local function waitForRemotes()
	local gameRemotes = ReplicatedStorage:WaitForChild("GameRemotes", 30)
	if gameRemotes then
		print("✅ MilkingIntegration: GameRemotes found!")
		return gameRemotes
	else
		warn("❌ MilkingIntegration: GameRemotes not found!")
		return nil
	end
end

-- ========== ENHANCED CLICK HANDLING ==========
local function createLocalClickFeedback()
	-- Create immediate local feedback for responsiveness
	local mouse = LocalPlayer:GetMouse()
	local clickPos = Vector2.new(mouse.X, mouse.Y)

	local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
	local feedbackGui = Instance.new("ScreenGui")
	feedbackGui.Name = "LocalClickFeedback"
	feedbackGui.Parent = PlayerGui

	-- Quick ripple effect
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

	-- Quick expand animation
	local expand = game:GetService("TweenService"):Create(ripple,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = UDim2.new(0, 50, 0, 50),
			Position = UDim2.new(0, clickPos.X - 25, 0, clickPos.Y - 25),
			BackgroundTransparency = 1
		}
	)
	expand:Play()

	expand.Completed:Connect(function()
		feedbackGui:Destroy()
	end)
end

local function setupEnhancedClickDetection()
	print("🖱️ Setting up enhanced 10-click detection...")

	-- Enhanced input handling for 10-click system
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		-- Check if we're in a milking session
		local isInMilkingSession = false

		-- Check ChairMilkingGUI state
		if IntegrationState.chairGUI and IntegrationState.chairGUI.State then
			isInMilkingSession = (IntegrationState.chairGUI.State.guiType == "milking" and 
				IntegrationState.chairGUI.State.isVisible)
		end

		-- Fallback: Check for milking GUI
		if not isInMilkingSession then
			local milkingGUI = LocalPlayer.PlayerGui:FindFirstChild("MilkingGUI") or 
				LocalPlayer.PlayerGui:FindFirstChild("ChairMilkingGUI")
			isInMilkingSession = milkingGUI ~= nil
		end

		if isInMilkingSession then
			local currentTime = tick()

			-- Check cooldown to prevent spam
			if (currentTime - IntegrationState.lastClickTime) < IntegrationState.clickCooldown then
				return
			end

			local isClick = (input.UserInputType == Enum.UserInputType.MouseButton1) or 
				(input.UserInputType == Enum.UserInputType.Touch) or
				(input.KeyCode == Enum.KeyCode.Space)

			if isClick then
				IntegrationState.lastClickTime = currentTime

				print("🖱️ MilkingIntegration: Enhanced click detected for 10-click system")

				if IntegrationState.continueMilking then
					IntegrationState.continueMilking:FireServer()
					print("📡 MilkingIntegration: Sent ContinueMilking to server")

					-- Create local click feedback
					createLocalClickFeedback()
				else
					warn("❌ MilkingIntegration: ContinueMilking remote not available")
				end
			end
		end
	end)

	print("✅ Enhanced 10-click detection setup complete")
end


-- ========== CONNECTION MANAGEMENT ==========

local function attemptConnection()
	print("🔗 MilkingIntegration: Attempting system connection (Attempt " .. (IntegrationState.connectionRetries + 1) .. ")...")

	IntegrationState.connectionRetries = IntegrationState.connectionRetries + 1

	local chairGUI = waitForSystem("ChairMilkingGUI", "ChairMilkingGUI", 5)
	local gameRemotes = waitForRemotes()

	if not chairGUI then
		warn("❌ MilkingIntegration: ChairMilkingGUI not available")
		return false
	end

	if not gameRemotes then
		warn("❌ MilkingIntegration: GameRemotes not available")
		return false
	end

	-- Store references
	IntegrationState.chairGUI = chairGUI
	IntegrationState.gameRemotes = gameRemotes

	-- Get continue milking remote
	local continueMilking = gameRemotes:WaitForChild("ContinueMilking", 10)
	if continueMilking then
		IntegrationState.continueMilking = continueMilking
		print("✅ MilkingIntegration: ContinueMilking remote connected")
	else
		warn("❌ MilkingIntegration: ContinueMilking remote not found")
		return false
	end

	-- Test the connection
	local showChairPrompt = gameRemotes:WaitForChild("ShowChairPrompt", 10)
	if showChairPrompt then
		print("✅ MilkingIntegration: ShowChairPrompt remote found")

		-- Monitor for milking sessions
		showChairPrompt.OnClientEvent:Connect(function(promptType, data)
			print("📡 MilkingIntegration: Received " .. tostring(promptType) .. " prompt")

			if promptType == "milking" then
				print("🥛 10-click milking session started through integration")

				if data then
					print("📊 Session data:")
					print("  Clicks per milk: " .. (data.clicksPerMilk or "unknown"))
					print("  Current progress: " .. (data.currentProgress or "unknown"))
					print("  Max milk: " .. (data.maxMilk or "unknown"))
				end
			end
		end)
	else
		warn("❌ MilkingIntegration: ShowChairPrompt remote not found")
		return false
	end

	-- Monitor session updates
	local sessionUpdate = gameRemotes:WaitForChild("MilkingSessionUpdate", 10)
	if sessionUpdate then
		sessionUpdate.OnClientEvent:Connect(function(updateType, data)
			if updateType == "progress" then
				print("📊 MilkingIntegration: Progress update - " .. 
					(data.clickProgress or 0) .. "/" .. (data.clicksPerMilk or 10) .. 
					" clicks | Milk: " .. (data.milkCollected or 0))
			end
		end)
		print("✅ MilkingIntegration: Session update monitoring connected")
	end

	IntegrationState.isConnected = true
	print("✅ MilkingIntegration: Full integration successful!")
	return true
end

-- ========== MAIN INTEGRATION ==========

local function integrateSystem()
	print("🔗 MilkingIntegration: Starting 10-click system integration...")

	local success = attemptConnection()

	if success then
		-- Setup enhanced click detection
		setupEnhancedClickDetection()

		print("✅ MilkingIntegration: 10-click system integration complete!")
		return true
	else
		if IntegrationState.connectionRetries < IntegrationState.maxRetries then
			print("🔄 MilkingIntegration: Retrying in 2 seconds...")
			wait(2)
			return integrateSystem() -- Retry
		else
			warn("❌ MilkingIntegration: Failed to integrate after " .. IntegrationState.maxRetries .. " attempts")
			return false
		end
	end
end

-- ========== DEBUGGING SYSTEM ==========

local function addEnhancedDebugCommands()
	local function handleChatCommand(message)
		local command = message:lower()

		if command == "/testintegration" then
			print("🧪 Testing 10-click integration...")

			if IntegrationState.chairGUI then
				print("✅ ChairMilkingGUI available")
				if IntegrationState.chairGUI.DebugStatus then
					IntegrationState.chairGUI:DebugStatus()
				end

				-- Test GUI manually
				IntegrationState.chairGUI:ShowPrompt("milking", {
					title = "🧪 Integration Test",
					subtitle = "Testing 10-click system",
					instruction = "Click 10 times to collect 1 milk!",
					clicksPerMilk = 10,
					currentProgress = 0
				})

				print("🧪 Test GUI should be showing - try clicking!")

				-- Hide after 10 seconds
				spawn(function()
					wait(10)
					IntegrationState.chairGUI:HidePrompt()
				end)
			else
				warn("❌ ChairMilkingGUI not available")
			end

		elseif command == "/checkconnection" then
			print("🔍 Checking integration connection...")
			print("Chair GUI: " .. (IntegrationState.chairGUI and "✅" or "❌"))
			print("Game Remotes: " .. (IntegrationState.gameRemotes and "✅" or "❌"))
			print("Continue Milking: " .. (IntegrationState.continueMilking and "✅" or "❌"))
			print("Is Connected: " .. (IntegrationState.isConnected and "✅" or "❌"))
			print("Connection Retries: " .. IntegrationState.connectionRetries)

		elseif command == "/testremotes" then
			print("🔍 Testing remote events...")

			if IntegrationState.gameRemotes then
				print("✅ GameRemotes available:")
				for _, child in pairs(IntegrationState.gameRemotes:GetChildren()) do
					print("  " .. child.Name .. " (" .. child.ClassName .. ")")
				end
			else
				warn("❌ GameRemotes not available")
			end

		elseif command == "/testclick" then
			print("🖱️ Testing click system...")

			if IntegrationState.continueMilking then
				print("📡 Sending test click to server...")
				IntegrationState.continueMilking:FireServer()
				createLocalClickFeedback()
				print("✅ Test click sent!")
			else
				warn("❌ ContinueMilking remote not available")
			end

		elseif command == "/reconnect" then
			print("🔄 Attempting to reconnect integration...")
			IntegrationState.connectionRetries = 0
			IntegrationState.isConnected = false

			local success = integrateSystem()
			if success then
				print("✅ Reconnection successful!")
			else
				print("❌ Reconnection failed!")
			end

		elseif command == "/clickstats" then
			print("📊 Click integration stats:")
			print("  Last click time: " .. IntegrationState.lastClickTime)
			print("  Click cooldown: " .. IntegrationState.clickCooldown)
			print("  Currently in session: " .. (IntegrationState.chairGUI and 
				IntegrationState.chairGUI.State and IntegrationState.chairGUI.State.guiType == "milking" and "YES" or "NO"))

		elseif command == "/forcesetup" then
			print("🔧 Force setting up enhanced click detection...")
			setupEnhancedClickDetection()
			print("✅ Enhanced click detection setup complete!")
		end
	end

	-- Connect to player chat
	LocalPlayer.Chatted:Connect(handleChatCommand)

	print("🎮 MilkingIntegration: Enhanced debug commands available:")
	print("  /testintegration - Test the integration system")
	print("  /checkconnection - Check connection status")
	print("  /testremotes - Test remote events")
	print("  /testclick - Test click system")
	print("  /reconnect - Attempt reconnection")
	print("  /clickstats - Show click statistics")
	print("  /forcesetup - Force setup click detection")
end

-- ========== CONNECTION MONITORING ==========

local function startConnectionMonitoring()
	spawn(function()
		while true do
			wait(30) -- Check every 30 seconds

			if IntegrationState.isConnected then
				-- Verify connection is still valid
				if not IntegrationState.chairGUI or not IntegrationState.continueMilking then
					warn("⚠️ MilkingIntegration: Connection lost, attempting reconnection...")
					IntegrationState.isConnected = false
					IntegrationState.connectionRetries = 0
					integrateSystem()
				end
			end
		end
	end)
end

-- ========== MAIN EXECUTION ==========

spawn(function()
	wait(3) -- Give systems time to load

	local success = integrateSystem()

	if success then
		addEnhancedDebugCommands()
		startConnectionMonitoring()
		print("🎉 MilkingIntegration: 10-click integration ready!")
		print("")
		print("🖱️ 10-CLICK FEATURES:")
		print("  📊 Real-time progress tracking")
		print("  🎯 Enhanced click feedback")
		print("  📱 Mobile touch support")
		print("  🔄 Automatic reconnection")
		print("  🐛 Debug tools for troubleshooting")
	else
		warn("❌ MilkingIntegration: Failed to integrate systems")

		-- Still add debug commands for troubleshooting
		addEnhancedDebugCommands()
		print("🔧 Debug commands available for troubleshooting")
	end
end)

-- ========== GLOBAL ACCESS ==========

_G.MilkingIntegration = {
	State = IntegrationState,
	Reconnect = function()
		IntegrationState.connectionRetries = 0
		IntegrationState.isConnected = false
		return integrateSystem()
	end,
	TestClick = function()
		if IntegrationState.continueMilking then
			IntegrationState.continueMilking:FireServer()
			createLocalClickFeedback()
			return true
		end
		return false
	end
}

print("🔗 MilkingIntegration: ✅ 10-CLICK INTEGRATION SCRIPT LOADED!")
print("📊 INTEGRATION FEATURES:")
print("  🖱️ Enhanced click detection for 10-click system")
print("  📡 Real-time server communication")
print("  🎯 Immediate visual feedback")
print("  🔄 Automatic reconnection")
print("  🔧 Comprehensive debug tools")