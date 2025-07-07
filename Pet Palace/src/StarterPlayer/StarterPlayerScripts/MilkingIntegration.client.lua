--[[
    MilkingIntegration.client.lua - Connects ChairMilkingGUI to GameCore system
    Place in: StarterPlayer/StarterPlayerScripts/MilkingIntegration.client.lua
    
    This script ensures the ChairMilkingGUI connects properly to your GameCore system
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

print("🔗 MilkingIntegration: Starting integration...")

-- Wait for ChairMilkingGUI to load
local function waitForGUI()
	local maxWait = 30
	local startTime = tick()

	while (tick() - startTime) < maxWait do
		if _G.ChairMilkingGUI then
			print("✅ MilkingIntegration: ChairMilkingGUI found!")
			return _G.ChairMilkingGUI
		end
		wait(0.1)
	end

	warn("❌ MilkingIntegration: ChairMilkingGUI not found after " .. maxWait .. " seconds")
	return nil
end

-- Wait for GameRemotes
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

-- Main integration function
local function integrateSystem()
	print("🔗 MilkingIntegration: Connecting systems...")

	local chairGUI = waitForGUI()
	local gameRemotes = waitForRemotes()

	if not chairGUI then
		warn("❌ MilkingIntegration: Cannot integrate without ChairMilkingGUI")
		return false
	end

	if not gameRemotes then
		warn("❌ MilkingIntegration: Cannot integrate without GameRemotes")
		return false
	end

	-- Test remote event connection
	local showChairPrompt = gameRemotes:WaitForChild("ShowChairPrompt", 10)
	if showChairPrompt then
		print("✅ MilkingIntegration: ShowChairPrompt remote found")

		-- Test the connection
		showChairPrompt.OnClientEvent:Connect(function(promptType, data)
			print("📡 MilkingIntegration: Received " .. tostring(promptType) .. " prompt")
			print("📊 Data: " .. tostring(data and "Present" or "Missing"))
		end)
	else
		warn("❌ MilkingIntegration: ShowChairPrompt remote not found")
	end

	-- Test milking controls
	local continueMilking = gameRemotes:WaitForChild("ContinueMilking", 10)
	if continueMilking then
		print("✅ MilkingIntegration: ContinueMilking remote found")
	else
		warn("❌ MilkingIntegration: ContinueMilking remote not found")
	end

	-- Enhanced click detection for better responsiveness
	local UserInputService = game:GetService("UserInputService")

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		-- Check if we're in a milking session
		if chairGUI.State.guiType == "milking" and chairGUI.State.isVisible then
			local isClick = (input.UserInputType == Enum.UserInputType.MouseButton1) or 
				(input.UserInputType == Enum.UserInputType.Touch)

			if isClick then
				print("🖱️ MilkingIntegration: Detected milking click")
				if continueMilking then
					continueMilking:FireServer()
					print("📡 MilkingIntegration: Sent ContinueMilking to server")
				end
			end
		end
	end)

	print("✅ MilkingIntegration: System integration complete!")
	return true
end

-- Enhanced debugging
local function addDebugCommands()
	local function handleChatCommand(message)
		local command = message:lower()

		if command == "/testmilkinggui" then
			print("🧪 Testing milking GUI connection...")

			if _G.ChairMilkingGUI then
				print("✅ ChairMilkingGUI available")
				_G.ChairMilkingGUI:DebugStatus()

				-- Test GUI manually
				_G.ChairMilkingGUI:ShowPrompt("milking", {
					title = "🧪 Integration Test",
					subtitle = "Testing from integration script",
					instruction = "If you see this, the integration works!"
				})

				-- Hide after 5 seconds
				spawn(function()
					wait(5)
					_G.ChairMilkingGUI:HidePrompt()
				end)
			else
				warn("❌ ChairMilkingGUI not available")
			end

		elseif command == "/checkremotes" then
			print("🔍 Checking remote events...")

			local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
			if gameRemotes then
				print("✅ GameRemotes found:")
				for _, child in pairs(gameRemotes:GetChildren()) do
					print("  " .. child.Name .. " (" .. child.ClassName .. ")")
				end
			else
				warn("❌ GameRemotes not found")
			end

		elseif command == "/testclicks" then
			print("🖱️ Testing click detection...")
			print("Current GUI state:")
			if _G.ChairMilkingGUI then
				print("  GUI Type: " .. tostring(_G.ChairMilkingGUI.State.guiType))
				print("  Is Visible: " .. tostring(_G.ChairMilkingGUI.State.isVisible))
				print("  Device Type: " .. tostring(_G.ChairMilkingGUI.State.deviceType))
			end

		elseif command == "/forcemilkinggui" then
			print("🔧 Force showing milking GUI...")
			if _G.ChairMilkingGUI then
				_G.ChairMilkingGUI:ShowPrompt("milking", {
					title = "🔧 Force Test",
					subtitle = "Manually triggered GUI",
					instruction = "This was triggered by /forcemilkinggui command"
				})
			end
		end
	end

	-- Connect to player chat
	LocalPlayer.Chatted:Connect(handleChatCommand)

	print("🎮 MilkingIntegration: Debug commands available:")
	print("  /testmilkinggui - Test the GUI system")
	print("  /checkremotes - Check remote events")
	print("  /testclicks - Test click detection")
	print("  /forcemilkinggui - Force show milking GUI")
end

-- Run integration
spawn(function()
	wait(2) -- Give everything time to load

	local success = integrateSystem()
	if success then
		addDebugCommands()
		print("🎉 MilkingIntegration: Ready!")
	else
		warn("❌ MilkingIntegration: Failed to integrate systems")
	end
end)

-- Monitor system status
spawn(function()
	while true do
		wait(10) -- Check every 10 seconds

		if _G.ChairMilkingGUI and _G.ChairMilkingGUI.State.isVisible then
			print("📊 MilkingIntegration: GUI is active (" .. tostring(_G.ChairMilkingGUI.State.guiType) .. ")")
		end
	end
end)

print("🔗 MilkingIntegration: Integration script loaded!")