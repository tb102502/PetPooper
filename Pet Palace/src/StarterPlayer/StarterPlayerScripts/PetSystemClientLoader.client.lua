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

-- Create the client module in ReplicatedStorage if it doesn't exist
if not ReplicatedStorage:FindFirstChild("PetSystemClient") then
	print("PetSystemClientLoader: Creating PetSystemClient module...")

	-- Instead of creating a ModuleScript directly (which requires higher permissions),
	-- we'll use a pre-existing template if available, or print instructions
	local moduleTemplate = script:FindFirstChild("PetSystemClientTemplate")

	if moduleTemplate and moduleTemplate:IsA("ModuleScript") then
		local clientModule = moduleTemplate:Clone()
		clientModule.Name = "PetSystemClient"
		clientModule.Parent = ReplicatedStorage
		print("PetSystemClientLoader: Created PetSystemClient from template")
	else
		warn("PetSystemClientLoader: No template found. Please manually create a ModuleScript named 'PetSystemClient' in ReplicatedStorage")
		-- You'll need to manually create this script in ReplicatedStorage
		return
	end
end

-- Try to load the module
-- Try to load the module
local PetSystemClient
local success, result = pcall(function()
	return require(ReplicatedStorage:WaitForChild("PetSystemClient", 5))
end)

if not success then
	warn("PetSystemClientLoader: Failed to require PetSystemClient module: " .. tostring(result))
	return
end

PetSystemClient = result

-- Initialize the client system
if PetSystemClient and typeof(PetSystemClient) == "table" and typeof(PetSystemClient.Initialize) == "function" then
	spawn(function()
		-- Add a delay to ensure all remotes are created
		wait(2)

		local initSuccess, errorMsg = pcall(function()
			PetSystemClient:Initialize()
		end)

		if initSuccess then
			print("PetSystemClient successfully initialized")

			-- Make the PetSystemClient available to other scripts
			_G.PetSystemClient = PetSystemClient

			-- Let other scripts know this is ready
			if not _G.SystemsReady then
				_G.SystemsReady = {}
			end
			_G.SystemsReady.PetSystem = true

			-- Fire a bindable event for modules waiting for this
			local bindableEvent = Instance.new("BindableEvent")
			bindableEvent.Name = "PetSystemReadyEvent"
			bindableEvent.Parent = script
			bindableEvent:Fire()

			-- Clean up after a moment
			delay(5, function()
				if bindableEvent then
					bindableEvent:Destroy()
				end
			end)
		else
			warn("PetSystemClientLoader: Failed to initialize PetSystemClient: " .. tostring(errorMsg))
		end
	end)
else
	warn("PetSystemClientLoader: PetSystemClient module doesn't have proper structure")
end