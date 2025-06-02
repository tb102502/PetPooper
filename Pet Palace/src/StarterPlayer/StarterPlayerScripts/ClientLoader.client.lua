--[[
    ClientLoader.client.lua - FIXED VERSION
    Place in: StarterPlayerScripts/ClientLoader.client.lua
    
    FIXES:
    1. ✅ Fixed syntax error at line 283
    2. ✅ Proper function structure
    3. ✅ Better error handling
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local errorHandlingConnections = {}

print("=== Pet Palace Client Loader Starting ===")

-- FIXED: Proper error handling setup
local function SetupErrorHandling()
	-- Handle character respawning
	local charConnection = LocalPlayer.CharacterAdded:Connect(function(character)
		print("ClientLoader: Character respawned, GameClient should handle this automatically")

		-- Small delay to ensure character is fully loaded
		spawn(function()
			wait(1)
			if _G.GameClient and type(_G.GameClient) == "table" and type(_G.GameClient.HandleCharacterRespawn) == "function" then
				_G.GameClient:HandleCharacterRespawn(character)
			end
		end)
	end)

	-- Store connection for cleanup
	errorHandlingConnections.characterAdded = charConnection

	-- Handle disconnection/reconnection scenarios
	local heartbeatConnection = RunService.Heartbeat:Connect(function()
		if not _G.GameClient or type(_G.GameClient) ~= "table" then
			warn("ClientLoader: GameClient lost from global scope!")
			heartbeatConnection:Disconnect()
			errorHandlingConnections.heartbeat = nil

			-- Attempt recovery
			spawn(function()
				wait(2)
				local success = pcall(InitializeClient)
				if not success then
					error("ClientLoader: Failed to recover GameClient")
				end
			end)
		end
	end)

	-- Store connection for cleanup
	errorHandlingConnections.heartbeat = heartbeatConnection
end

-- FIXED: Add cleanup function
local function CleanupErrorHandling()
	for name, connection in pairs(errorHandlingConnections) do
		if connection then
			connection:Disconnect()
			errorHandlingConnections[name] = nil
		end
	end
end

-- Wait for character to load
if not LocalPlayer.Character then
	LocalPlayer.CharacterAdded:Wait()
end

print("ClientLoader: Character loaded, waiting for server systems...")

-- Wait for server to be ready
local function WaitForServerReady()
	local maxWaitTime = 30
	local startTime = tick()

	while tick() - startTime < maxWaitTime do
		-- Check for ready signal
		local readyEvent = ReplicatedStorage:FindFirstChild("GameCoreReady")
		if readyEvent then
			print("ClientLoader: Server ready signal found")
			return true
		end

		-- Check for GameRemotes folder
		local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
		if gameRemotes and #gameRemotes:GetChildren() > 0 then
			print("ClientLoader: GameRemotes found with " .. #gameRemotes:GetChildren() .. " remotes")
			return true
		end

		wait(0.5)
	end

	warn("ClientLoader: Server systems not ready after " .. maxWaitTime .. " seconds")
	return false
end

-- Load and initialize GameClient
local function LoadGameClient()
	print("ClientLoader: Loading GameClient module...")

	local gameClientModule = ReplicatedStorage:WaitForChild("GameClient", 30)
	if not gameClientModule then
		error("ClientLoader: GameClient module not found in ReplicatedStorage after 30 seconds")
	end

	if not gameClientModule:IsA("ModuleScript") then
		error("ClientLoader: GameClient is not a ModuleScript, it's a " .. gameClientModule.ClassName)
	end

	local success, GameClient = pcall(function()
		return require(gameClientModule)
	end)

	if not success then
		error("ClientLoader: Failed to require GameClient: " .. tostring(GameClient))
	end

	-- Enhanced validation
	if not GameClient then
		error("ClientLoader: GameClient module returned nil")
	end

	if type(GameClient) ~= "table" then
		error("ClientLoader: GameClient must be a table, got " .. type(GameClient))
	end

	if type(GameClient.Initialize) ~= "function" then
		error("ClientLoader: GameClient is missing Initialize function")
	end

	return GameClient
end

-- Initialize the client system
function InitializeClient()
	print("ClientLoader: Starting client initialization...")

	-- Wait for server to be ready
	if not WaitForServerReady() then
		warn("ClientLoader: Proceeding without server ready confirmation")
	end

	-- Load GameClient
	local GameClient = LoadGameClient()

	-- Initialize with error handling
	local initSuccess, errorMsg = pcall(function()
		return GameClient:Initialize()
	end)

	if not initSuccess then
		error("ClientLoader: GameClient initialization failed: " .. tostring(errorMsg))
	end

	-- Make GameClient globally available
	_G.GameClient = GameClient

	-- Create ready signal for other scripts
	local clientReadyEvent = Instance.new("BindableEvent")
	clientReadyEvent.Name = "GameClientReady"
	clientReadyEvent.Parent = ReplicatedStorage
	clientReadyEvent:Fire(GameClient)

	print("ClientLoader: GameClient initialized and available globally")

	return GameClient
end

-- Setup development tools (studio only)
local function SetupDevTools()
	if not RunService:IsStudio() then return end

	print("ClientLoader: Setting up development tools...")

	-- Add keybinds for testing
	local UserInputService = game:GetService("UserInputService")

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.F1 then
			-- Quick open pets menu
			if _G.GameClient and _G.GameClient.OpenPets then
				_G.GameClient:OpenPets()
			end
		elseif input.KeyCode == Enum.KeyCode.F2 then
			-- Quick open shop
			if _G.GameClient and _G.GameClient.OpenShop then
				_G.GameClient:OpenShop()
			end
		elseif input.KeyCode == Enum.KeyCode.F3 then
			-- Quick open farm
			if _G.GameClient and _G.GameClient.OpenFarm then
				_G.GameClient:OpenFarm()
			end
		elseif input.KeyCode == Enum.KeyCode.F9 then
			-- Debug info
			if _G.GameClient then
				local playerData = _G.GameClient:GetPlayerData()
				print("=== DEBUG INFO ===")
				print("Player Data:", playerData)
				print("Coins:", _G.GameClient:GetPlayerCurrency("coins"))
				print("Gems:", _G.GameClient:GetPlayerCurrency("gems"))
				if playerData and playerData.pets then
					print("Owned Pets:", #playerData.pets.owned)
					print("Equipped Pets:", #playerData.pets.equipped)
				end
				print("==================")
			end
		end
	end)

	print("ClientLoader: Dev tools active (F1=Pets, F2=Shop, F3=Farm, F9=Debug)")
end

-- Performance monitoring for client
local function SetupClientMonitoring()
	spawn(function()
		while true do
			wait(30) -- Check every 30 seconds

			local fps = workspace:GetRealPhysicsFPS()
			local ping = LocalPlayer:GetNetworkPing() * 1000 -- Convert to ms

			if fps < 30 then
				warn("ClientLoader: Low FPS detected: " .. math.floor(fps))
			end

			if ping > 200 then
				warn("ClientLoader: High ping detected: " .. math.floor(ping) .. "ms")
			end
		end
	end)
end

-- Create helpful UI hints for new players
local function CreateHelpSystem()
	spawn(function()
		wait(5) -- Wait a bit after everything loads

		if _G.GameClient and _G.GameClient.ShowNotification then
			_G.GameClient:ShowNotification(
				"Welcome to Pet Palace!", 
				"Click on wild pets to collect them, then visit the shop to buy items!", 
				"info"
			)
		end
	end)
end

-- FIXED: Main initialization function with proper structure
local function Main()
	print("ClientLoader: Starting main initialization sequence...")

	-- Initialize all systems
	local GameClient = InitializeClient()

	-- FIXED: Enhanced validation
	if not _G.GameClient then
		error("CRITICAL: GameClient not available in global scope after initialization")
	end

	if type(_G.GameClient) ~= "table" then
		error("CRITICAL: GameClient is not a table: " .. type(_G.GameClient))
	end

	-- Setup additional systems
	SetupErrorHandling()
	SetupDevTools()
	SetupClientMonitoring()
	CreateHelpSystem()

	print("=== Pet Palace Client Loader Complete ===")
	print("Client is ready! GameClient available globally as _G.GameClient")

	return GameClient
end

-- FIXED: Run with comprehensive error handling
local success, result = pcall(Main)

if not success then
	-- Create emergency UI to inform player of the error
	local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

	local errorGui = Instance.new("ScreenGui")
	errorGui.Name = "ErrorGui"
	errorGui.Parent = PlayerGui

	local errorFrame = Instance.new("Frame")
	errorFrame.Size = UDim2.new(0.6, 0, 0.4, 0)
	errorFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	errorFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	errorFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	errorFrame.Parent = errorGui

	local errorLabel = Instance.new("TextLabel")
	errorLabel.Size = UDim2.new(0.9, 0, 0.8, 0)
	errorLabel.Position = UDim2.new(0.05, 0, 0.1, 0)
	errorLabel.BackgroundTransparency = 1
	errorLabel.Text = "Game Loading Error\n\nThere was a problem loading the game.\nPlease try rejoining.\n\nError: " .. tostring(result)
	errorLabel.TextColor3 = Color3.new(1, 1, 1)
	errorLabel.TextScaled = true
	errorLabel.TextWrapped = true
	errorLabel.Font = Enum.Font.SourceSans
	errorLabel.Parent = errorFrame

	error("CRITICAL CLIENT FAILURE: " .. tostring(result))
else
	print("ClientLoader: All client systems operational")
end