--[[
    PetSystemClientLoader.client.lua
    Client-side loader for the PetSystem
    Created: 2025-05-24
    Author: GitHub Copilot for tb102502
    
    IMPORTANT: Place this script in StarterPlayerScripts
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("PetSystemClientLoader: Starting...")

-- First, wait for PetSystem folder in ReplicatedStorage
local function waitForPetSystem()
	local maxWaitTime = 30 -- Wait up to 30 seconds
	local startTime = tick()

	print("PetSystemClientLoader: Waiting for PetSystem folder in ReplicatedStorage...")

	while tick() - startTime < maxWaitTime do
		local petSystemFolder = ReplicatedStorage:FindFirstChild("PetSystem")
		if petSystemFolder then
			print("PetSystemClientLoader: Found PetSystem folder")
			return petSystemFolder
		end
		wait(0.5)
	end

	warn("PetSystemClientLoader: Failed to find PetSystem folder after waiting")
	return nil
end

-- Create or find the PetSystemClient module
local function setupPetSystemClient()
	local existingModule = ReplicatedStorage:FindFirstChild("PetSystemClient")

	if existingModule and existingModule:IsA("ModuleScript") then
		print("PetSystemClientLoader: Found existing PetSystemClient module")
		return existingModule
	end

	-- Try to find a template in this script
	local template = script:FindFirstChild("PetSystemClientTemplate")
	if template and template:IsA("ModuleScript") then
		print("PetSystemClientLoader: Cloning PetSystemClient from template")
		local clientModule = template:Clone()
		clientModule.Name = "PetSystemClient"
		clientModule.Parent = ReplicatedStorage
		return clientModule
	end

	warn("PetSystemClientLoader: No PetSystemClient module or template found!")
	warn("Please manually create a ModuleScript named 'PetSystemClient' in ReplicatedStorage")
	return nil
end

local petSystemFolder = waitForPetSystem()
if not petSystemFolder then
	warn("PetSystemClientLoader: Cannot continue without PetSystem folder")
	return
end

-- Wait for player to load
local player = Players.LocalPlayer
if not player.Character then
	player.CharacterAdded:Wait()
end

-- Setup the client module
local clientModule = setupPetSystemClient()
if not clientModule then
	return
end

-- Try to load the module
local PetSystemClient
local success, result = pcall(function()
	return require(clientModule)
end)

if not success then
	warn("PetSystemClientLoader: Failed to require PetSystemClient module: " .. tostring(result))
	return
end

PetSystemClient = result

-- Validate module structure
if not PetSystemClient or typeof(PetSystemClient) ~= "table" or typeof(PetSystemClient.Initialize) ~= "function" then
	warn("PetSystemClientLoader: PetSystemClient module doesn't have proper structure")
	warn("Expected: table with Initialize function")
	return
end

-- Initialize the client system
spawn(function()
	-- Add a delay to ensure all remotes are created
	wait(2)

	local initSuccess, errorMsg = pcall(function()
		return PetSystemClient:Initialize()
	end)

	if initSuccess then
		print("PetSystemClient successfully initialized")

		-- Make the PetSystemClient available to other scripts
		_G.PetSystemClient = PetSystemClient

		-- Create a ready signal for other systems
		local readyEvent = Instance.new("BindableEvent")
		readyEvent.Name = "PetSystemReady"
		readyEvent.Parent = ReplicatedStorage

		-- Fire the ready event
		readyEvent:Fire(PetSystemClient)

		-- Also update global ready tracker
		if not _G.SystemsReady then
			_G.SystemsReady = {}
		end
		_G.SystemsReady.PetSystem = true

		print("PetSystemClient: Ready signal sent")
	else
		warn("PetSystemClientLoader: Failed to initialize PetSystemClient: " .. tostring(errorMsg))
	end
end)