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

-- Instead of creating the module, expect it to already exist
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

	warn("UIControllerLoader: UIController module not found in ReplicatedStorage after waiting")

	-- Check if we have a template to clone
	local templateModule = script:FindFirstChild("UIControllerTemplate")
	if templateModule and templateModule:IsA("ModuleScript") then
		print("UIControllerLoader: Found UIControllerTemplate, cloning to ReplicatedStorage")
		local clone = templateModule:Clone()
		clone.Name = "UIController"
		clone.Parent = ReplicatedStorage
		return clone
	end

	return nil
end

-- Wait for dependencies (PetSystemClient and ShopSystemClient)
-- Update the dependency waiting part of UIControllerLoader.client.lua

-- Wait for dependencies (PetSystemClient and ShopSystemClient)
local function waitForDependencies()
	local startTime = tick()
	local timeout = 20 -- Wait up to 20 seconds

	print("UIControllerLoader: Waiting for dependencies...")

	-- Try to find a bindable event from PetSystemClientLoader
	local function checkPetSystemReady()
		local petLoader = Players.LocalPlayer.PlayerScripts:FindFirstChild("PetSystemClientLoader")
		if petLoader and petLoader:FindFirstChild("PetSystemReadyEvent") then
			return true
		end
		return _G.PetSystemClient ~= nil
	end

	-- Try to find a bindable event from ShopSystemClientLoader
	local function checkShopSystemReady()
		local shopLoader = Players.LocalPlayer.PlayerScripts:FindFirstChild("ShopSystemClientLoader")
		if shopLoader and shopLoader:FindFirstChild("ShopSystemReadyEvent") then
			return true
		end
		return _G.ShopSystemClient ~= nil
	end

	while tick() - startTime < timeout do
		-- Check if systems are ready
		local petReady = checkPetSystemReady()
		local shopReady = checkShopSystemReady()

		if petReady and shopReady then
			print("UIControllerLoader: Dependencies loaded")
			return true
		elseif petReady then
			print("UIControllerLoader: Pet system ready, waiting for shop system")
		elseif shopReady then
			print("UIControllerLoader: Shop system ready, waiting for pet system")
		end

		wait(0.5)
	end

	warn("UIControllerLoader: Dependencies not found after timeout")
	return false
end

-- Wait for the UIController module
local uiControllerModule = waitForUIController()

if not uiControllerModule then
	warn("UIControllerLoader: Cannot continue without UIController module")
	warn("UIControllerLoader: Please manually create a ModuleScript named 'UIController' in ReplicatedStorage")
	return
end

-- Wait for dependencies
local dependenciesLoaded = waitForDependencies()
if not dependenciesLoaded then
	warn("UIControllerLoader: Failed to load dependencies, attempting to proceed anyway")
end

-- Load and initialize the UI Controller
local success, UIController = pcall(function()
	return require(uiControllerModule)
end)

if not success then
	warn("UIControllerLoader: Failed to require UIController: " .. tostring(UIController))
	return
end

-- Initialize the UI Controller
if UIController and typeof(UIController) == "table" and typeof(UIController.Initialize) == "function" then
	spawn(function()
		-- Add a delay to ensure everything else is ready
		wait(1)

		local initSuccess, errorMsg = pcall(function()
			UIController:Initialize()
		end)

		if initSuccess then
			print("UIController successfully initialized")
			-- Make the UI Controller available to other scripts
			_G.UIController = UIController
		else
			warn("UIControllerLoader: Failed to initialize UIController: " .. tostring(errorMsg))
		end
	end)
else
	warn("UIControllerLoader: UIController module doesn't have proper structure")
end