--[[
    MilkingClickHandler.client.lua - Client-Side Click Detection for Milking
    Place in: StarterPlayer/StarterPlayerScripts/MilkingClickHandler.client.lua
    
    This script handles mouse and keyboard clicks during milking sessions
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

print("🖱️ MilkingClickHandler: Client script loaded for " .. player.Name)

-- ========== REMOTE EVENTS SETUP ==========

local function getRemoteEvents()
	local gameRemotes = ReplicatedStorage:WaitForChild("GameRemotes", 10)
	if gameRemotes then
		return {
			ShowChairPrompt = gameRemotes:WaitForChild("ShowChairPrompt", 5),
			HideChairPrompt = gameRemotes:WaitForChild("HideChairPrompt", 5),
			ContinueMilking = gameRemotes:WaitForChild("ContinueMilking", 5),
			StartMilkingSession = gameRemotes:WaitForChild("StartMilkingSession", 5),
			StopMilkingSession = gameRemotes:WaitForChild("StopMilkingSession", 5),
			MilkingSessionUpdate = gameRemotes:WaitForChild("MilkingSessionUpdate", 5)
		}
	end
	return nil
end

local remoteEvents = getRemoteEvents()
if not remoteEvents then
	warn("❌ MilkingClickHandler: Could not find remote events")
	return
end

print("✅ MilkingClickHandler: Remote events found")

-- ========== MILKING SESSION STATE ==========

local milkingSessionActive = false
local currentCowId = nil
local sessionData = {}

-- ========== SESSION EVENT HANDLERS ==========

-- Listen for milking session start
local function onShowChairPrompt(promptType, promptData)
	if promptType == "milking" then
		milkingSessionActive = true
		currentCowId = promptData.cowId or "unknown"
		sessionData = promptData or {}

		print("🥛 Milking session started - clicking enabled")
		print("  Cow ID: " .. currentCowId)
		print("  Max milk: " .. tostring(sessionData.maxMilk or "unknown"))

		-- Show click instruction
		if _G.UIManager and _G.UIManager.ShowNotification then
			_G.UIManager:ShowNotification("🖱️ Click to Milk!", 
				"Click anywhere or press SPACE to collect milk", "info")
		end
	else
		-- Non-milking prompt, ensure milking is disabled
		milkingSessionActive = false
		currentCowId = nil
	end
end

-- Listen for milking session end
local function onHideChairPrompt()
	if milkingSessionActive then
		print("🛑 Milking session ended - clicking disabled")
	end

	milkingSessionActive = false
	currentCowId = nil
	sessionData = {}
end

-- Listen for session updates
local function onMilkingSessionUpdate(updateData)
	if updateData and milkingSessionActive then
		sessionData = updateData

		-- Show progress feedback
		if updateData.milkCollected and updateData.maxMilk then
			print("📊 Session update: " .. updateData.milkCollected .. "/" .. updateData.maxMilk .. " milk")
		end

		if updateData.lastClick then
			print("✅ Collected " .. updateData.lastClick .. " milk!")
		end
	end
end

-- ========== CONNECT TO REMOTE EVENTS ==========

if remoteEvents.ShowChairPrompt then
	remoteEvents.ShowChairPrompt.OnClientEvent:Connect(onShowChairPrompt)
end

if remoteEvents.HideChairPrompt then
	remoteEvents.HideChairPrompt.OnClientEvent:Connect(onHideChairPrompt)
end

if remoteEvents.MilkingSessionUpdate then
	remoteEvents.MilkingSessionUpdate.OnClientEvent:Connect(onMilkingSessionUpdate)
end

-- ========== CLICK DETECTION ==========

-- Mouse click handler
mouse.Button1Down:Connect(function()
	if milkingSessionActive and currentCowId then
		print("🖱️ Mouse click detected during milking session")

		if remoteEvents.ContinueMilking then
			remoteEvents.ContinueMilking:FireServer()
			print("📡 ContinueMilking fired to server")

			-- Visual feedback
			if _G.UIManager and _G.UIManager.ShowNotification then
				_G.UIManager:ShowNotification("🥛 Milking...", "Collecting milk", "info")
			end
		else
			warn("❌ ContinueMilking remote not available")
		end
	end
end)

-- Touch handler for mobile
if UserInputService.TouchEnabled then
	UserInputService.TouchStarted:Connect(function(touch, gameProcessed)
		if gameProcessed then return end

		if milkingSessionActive and currentCowId then
			print("📱 Touch detected during milking session")

			if remoteEvents.ContinueMilking then
				remoteEvents.ContinueMilking:FireServer()
				print("📡 ContinueMilking fired to server (touch)")
			end
		end
	end)
end

-- Keyboard click handler (space bar as backup)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.Space and milkingSessionActive and currentCowId then
		print("⌨️ SPACE key detected during milking session")

		if remoteEvents.ContinueMilking then
			remoteEvents.ContinueMilking:FireServer()
			print("📡 ContinueMilking fired to server (keyboard)")
		end
	end
end)

-- ========== DEBUG COMMANDS ==========

local function setupDebugCommands()
	player.Chatted:Connect(function(message)
		local command = message:lower()

		if command == "/testclick" then
			print("🧪 Testing click system...")
			print("  Milking active: " .. tostring(milkingSessionActive))
			print("  Current cow: " .. tostring(currentCowId))
			print("  ContinueMilking available: " .. tostring(remoteEvents.ContinueMilking ~= nil))
			print("  Touch enabled: " .. tostring(UserInputService.TouchEnabled))
			print("  Keyboard enabled: " .. tostring(UserInputService.KeyboardEnabled))

		elseif command == "/forceclick" then
			print("🔧 Force sending milking click...")
			if remoteEvents.ContinueMilking then
				remoteEvents.ContinueMilking:FireServer()
				print("📡 Force click sent to server")
			end

		elseif command == "/startsession" then
			print("🔧 Force starting milking session...")
			if remoteEvents.StartMilkingSession then
				-- Try to find a cow ID
				local testCowId = "cow_" .. player.UserId .. "_1"
				remoteEvents.StartMilkingSession:FireServer(testCowId)
				print("📡 StartMilkingSession sent: " .. testCowId)
			end

		elseif command == "/stopsession" then
			print("🔧 Force stopping milking session...")
			if remoteEvents.StopMilkingSession then
				remoteEvents.StopMilkingSession:FireServer()
				print("📡 StopMilkingSession sent")
			end

		elseif command == "/sessionstatus" then
			print("📊 Milking session status:")
			print("  Active: " .. tostring(milkingSessionActive))
			print("  Cow ID: " .. tostring(currentCowId))
			if sessionData.milkCollected and sessionData.maxMilk then
				print("  Progress: " .. sessionData.milkCollected .. "/" .. sessionData.maxMilk)
			end
		end
	end)
end

setupDebugCommands()

-- ========== IMPROVED CLICK FEEDBACK ==========

-- Visual click feedback
local function createClickEffect()
	if not player.PlayerGui then return end

	-- Create a brief visual effect when clicking during milking
	local screenGui = player.PlayerGui:FindFirstChild("MilkingClickEffect")
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "MilkingClickEffect"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = player.PlayerGui
	end

	-- Create click ripple effect
	local ripple = Instance.new("Frame")
	ripple.Size = UDim2.new(0, 100, 0, 100)
	ripple.Position = UDim2.new(0.5, -50, 0.5, -50)
	ripple.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
	ripple.BackgroundTransparency = 0.3
	ripple.BorderSizePixel = 0
	ripple.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = ripple

	-- Animate the ripple
	local TweenService = game:GetService("TweenService")
	local expandTween = TweenService:Create(ripple,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = UDim2.new(0, 200, 0, 200),
			Position = UDim2.new(0.5, -100, 0.5, -100),
			BackgroundTransparency = 1
		}
	)

	expandTween:Play()
	expandTween.Completed:Connect(function()
		ripple:Destroy()
	end)
end

-- Enhanced mouse click with visual feedback
local originalMouseHandler = mouse.Button1Down
mouse.Button1Down:Connect(function()
	if milkingSessionActive and currentCowId then
		createClickEffect()
	end
end)

print("✅ MilkingClickHandler: Client setup complete")
print("🖱️ CLICK METHODS AVAILABLE:")
print("  🖱️ Mouse clicks")
print("  📱 Touch (mobile)")
print("  ⌨️ SPACE key (backup)")
print("")
print("🎮 DEBUG COMMANDS:")
print("  /testclick - Test click system")
print("  /forceclick - Force send click")
print("  /startsession - Force start session")
print("  /stopsession - Force stop session")
print("  /sessionstatus - Check session status")