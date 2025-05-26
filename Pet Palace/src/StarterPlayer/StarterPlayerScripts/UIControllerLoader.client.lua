--[[
    UIControllerLoader.client.lua
    Client-side loader for the UI Controller system
    Created: 2025-05-24
    Author: GitHub Copilot for tb102502
    
    IMPORTANT: Place this script in StarterPlayerScripts
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("UIControllerLoader: Starting...")

-- Wait for player to load
local player = Players.LocalPlayer
if not player.Character then
	player.CharacterAdded:Wait()
end

-- Function to wait for UIController module
local function waitForUIController()
	local maxWaitTime = 10 -- Wait up to 10 seconds
	local startTime = tick()

	print("UIControllerLoader: Waiting for UIController module...")

	while tick() - startTime < maxWaitTime do
		local uiController = ReplicatedStorage:FindFirstChild("UIController")
		if uiController and uiController:IsA("ModuleScript") then
			print("UIControllerLoader: Found UIController module")
			return uiController
		end
		wait(0.5)
	end

	warn("UIControllerLoader: UIController module not found in ReplicatedStorage")
	return nil
end

-- Enhanced dependency waiting with multiple strategies
local function waitForDependencies()
	local startTime = tick()
	local timeout = 30 -- Increased timeout to 30 seconds
	local checkInterval = 0.5

	print("UIControllerLoader: Waiting for dependencies...")

	while tick() - startTime < timeout do
		local petSystemReady = false
		local shopSystemReady = false

		-- Strategy 1: Check global variables
		if _G.PetSystemClient then
			petSystemReady = true
		end

		if _G.ShopSystemClient then
			shopSystemReady = true
		end

		-- Strategy 2: Check for ready events in ReplicatedStorage
		if not petSystemReady then
			local petReadyEvent = ReplicatedStorage:FindFirstChild("PetSystemReady")
			if petReadyEvent then
				petSystemReady = true
			end
		end

		if not shopSystemReady then
			local shopReadyEvent = ReplicatedStorage:FindFirstChild("ShopSystemReady")
			if shopReadyEvent then
				shopSystemReady = true
			end
		end

		-- Strategy 3: Check SystemsReady tracker
		if not petSystemReady and _G.SystemsReady and _G.SystemsReady.PetSystem then
			petSystemReady = true
		end

		if not shopSystemReady and _G.SystemsReady and _G.SystemsReady.ShopSystem then
			shopSystemReady = true
		end

		-- If both systems are ready, we're good to go
		if petSystemReady and shopSystemReady then
			print("UIControllerLoader: All dependencies loaded successfully")
			return true
		end

		-- Provide status updates
		local elapsed = tick() - startTime
		if elapsed % 5 < checkInterval then -- Log every 5 seconds
			local petStatus = petSystemReady and "✓" or "✗"
			local shopStatus = shopSystemReady and "✓" or "✗"
			print(string.format("UIControllerLoader: Dependency status - Pet: %s, Shop: %s (%.1fs elapsed)", 
				petStatus, shopStatus, elapsed))
		end

		wait(checkInterval)
	end

	-- Final check with detailed logging
	local petSystemReady = _G.PetSystemClient ~= nil
	local shopSystemReady = _G.ShopSystemClient ~= nil

	if not petSystemReady then
		warn("UIControllerLoader: PetSystemClient not found in _G")
	end

	if not shopSystemReady then
		warn("UIControllerLoader: ShopSystemClient not found in _G")
	end

	return false
end

-- Wait for the UIController module
local uiControllerModule = waitForUIController()

if not uiControllerModule then
	warn("UIControllerLoader: Cannot continue without UIController module")
	warn("UIControllerLoader: Please manually create a ModuleScript named 'UIController' in ReplicatedStorage")
	return
end

-- Wait for dependencies with better error handling
local dependenciesLoaded = waitForDependencies()

if not dependenciesLoaded then
	warn("UIControllerLoader: Some dependencies failed to load, but attempting to proceed")
	warn("UIControllerLoader: UI functionality may be limited")
end

-- Load and initialize the UI Controller
local success, UIController = pcall(function()
	return require(uiControllerModule)
end)

if not success then
	warn("UIControllerLoader: Failed to require UIController: " .. tostring(UIController))
	return
end

-- Validate UIController structure
if not UIController or typeof(UIController) ~= "table" or typeof(UIController.Initialize) ~= "function" then
	warn("UIControllerLoader: UIController module doesn't have proper structure")
	return
end

-- Initialize the UI Controller
spawn(function()
	-- Add a delay to ensure everything else is ready
	wait(1)

	local initSuccess, errorMsg = pcall(function()
		return UIController:Initialize()
	end)

	if initSuccess then
		print("UIController successfully initialized")

		-- Make the UI Controller available to other scripts
		_G.UIController = UIController

		-- Create ready signal
		local readyEvent = Instance.new("BindableEvent")
		readyEvent.Name = "UIControllerReady"
		readyEvent.Parent = ReplicatedStorage
		readyEvent:Fire(UIController)

		-- Update global ready tracker
		if not _G.SystemsReady then
			_G.SystemsReady = {}
		end
		_G.SystemsReady.UIController = true

		print("UIController: Ready signal sent")
	else
		warn("UIControllerLoader: Failed to initialize UIController: " .. tostring(errorMsg))
	end
end)