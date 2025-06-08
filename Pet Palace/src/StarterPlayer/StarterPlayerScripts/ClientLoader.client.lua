--[[
    FIXED ClientLoader.client.lua
    Replace your existing ClientLoader with this version
    
    FIXES:
    1. ✅ Better error handling for GameClient loading
    2. ✅ More robust initialization process
    3. ✅ Fallback mechanisms for errors
    4. ✅ Better validation of GameClient module
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

print("=== FIXED PET PALACE CLIENT LOADER STARTING ===")

-- Wait for character to load
if not LocalPlayer.Character then
	LocalPlayer.CharacterAdded:Wait()
end

print("ClientLoader: Character loaded, initializing systems...")

-- Enhanced wait for server ready
local function WaitForServerReady()
	local maxWaitTime = 30
	local startTime = tick()

	print("ClientLoader: Waiting for server systems...")

	while tick() - startTime < maxWaitTime do
		-- Check for GameRemotes folder with sufficient content
		local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
		if gameRemotes then
			local remoteCount = 0
			for _, child in pairs(gameRemotes:GetChildren()) do
				if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
					remoteCount = remoteCount + 1
				end
			end

			if remoteCount >= 5 then -- Need at least 5 remotes for basic functionality
				print("ClientLoader: Server ready - found " .. remoteCount .. " remotes")
				return true
			end
		end

		wait(0.5)
	end

	warn("ClientLoader: Server systems not fully ready after " .. maxWaitTime .. " seconds, continuing anyway...")
	return false
end

-- Enhanced GameClient loading with validation
local function LoadGameClient()
	print("ClientLoader: Loading GameClient module...")

	-- Wait for GameClient module
	local gameClientModule = ReplicatedStorage:WaitForChild("GameClient", 30)
	if not gameClientModule then
		error("ClientLoader: GameClient module not found in ReplicatedStorage")
	end

	if not gameClientModule:IsA("ModuleScript") then
		error("ClientLoader: GameClient is not a ModuleScript, it's a " .. gameClientModule.ClassName)
	end

	-- Require the module with error handling
	local success, GameClient = pcall(function()
		return require(gameClientModule)
	end)

	if not success then
		error("ClientLoader: Failed to require GameClient module: " .. tostring(GameClient))
	end

	-- Enhanced validation
	if not GameClient then
		error("ClientLoader: GameClient module returned nil")
	end

	if type(GameClient) ~= "table" then
		error("ClientLoader: GameClient must be a table, got " .. type(GameClient))
	end

	-- Check for required methods
	local requiredMethods = {"Initialize", "SetupRemoteConnections", "SetupUI", "RequestInitialData"}
	for _, methodName in ipairs(requiredMethods) do
		if type(GameClient[methodName]) ~= "function" then
			error("ClientLoader: GameClient is missing required method: " .. methodName)
		end
	end

	print("ClientLoader: GameClient module loaded and validated successfully")
	return GameClient
end

-- Enhanced initialization with recovery
local function InitializeClient()
	print("ClientLoader: Starting client initialization...")

	-- Wait for server readiness
	WaitForServerReady()

	-- Load GameClient module
	local GameClient = LoadGameClient()

	-- Initialize with enhanced error handling
	local initSuccess, errorMsg = pcall(function()
		return GameClient:Initialize()
	end)

	if not initSuccess then
		warn("ClientLoader: GameClient initialization failed: " .. tostring(errorMsg))

		-- Attempt recovery
		print("ClientLoader: Attempting recovery...")
		local recoverySuccess = false

		if GameClient.RecoverFromError then
			recoverySuccess = pcall(function()
				return GameClient:RecoverFromError(errorMsg)
			end)
		end

		if not recoverySuccess then
			error("ClientLoader: GameClient initialization and recovery both failed: " .. tostring(errorMsg))
		else
			print("ClientLoader: Recovery successful, continuing...")
		end
	end

	-- Make GameClient globally available
	_G.GameClient = GameClient

	-- Validate global availability
	if not _G.GameClient then
		error("ClientLoader: Failed to make GameClient globally available")
	end

	print("ClientLoader: GameClient initialized and available globally")
	return GameClient
end

-- Setup error handling and monitoring
local function SetupErrorHandling()
	-- Handle character respawning
	LocalPlayer.CharacterAdded:Connect(function(character)
		print("ClientLoader: Character respawned")
		if _G.GameClient and _G.GameClient.HandleCharacterRespawn then
			pcall(function()
				_G.GameClient:HandleCharacterRespawn(character)
			end)
		end
	end)

	-- Monitor GameClient health
	spawn(function()
		while true do
			wait(30) -- Check every 30 seconds

			if not _G.GameClient then
				warn("ClientLoader: GameClient lost from global scope!")
			elseif type(_G.GameClient) ~= "table" then
				warn("ClientLoader: GameClient corrupted in global scope!")
			end
		end
	end)
end

-- Setup development tools (studio only)
local function SetupDevTools()
	if not RunService:IsStudio() then return end

	print("ClientLoader: Setting up development tools...")

	local UserInputService = game:GetService("UserInputService")

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		-- Debug keybinds
		if input.KeyCode == Enum.KeyCode.F9 then
			-- Show debug info
			if _G.GameClient and _G.GameClient.DebugStatus then
				_G.GameClient:DebugStatus()
			else
				print("GameClient debug not available")
			end
		elseif input.KeyCode == Enum.KeyCode.F10 then
			-- Show farming debug
			if _G.DebugFarming then
				_G.DebugFarming()
			else
				print("Farming debug not available")
			end
		end
	end)

	print("ClientLoader: Dev tools active (F9=GameClient Debug, F10=Farming Debug)")
end

-- Create helpful UI for new players
local function CreateWelcomeSystem()
	spawn(function()
		wait(3) -- Wait for everything to load

		local success, error = pcall(function()
			if _G.GameClient and _G.GameClient.ShowNotification then
				_G.GameClient:ShowNotification(
					"🎉 Welcome to Pet Palace!", 
					"Walk to the shop building to buy seeds, then use the Farm menu (F) to plant them!", 
					"success"
				)
			end
		end)

		if not success then
			print("ClientLoader: Could not show welcome message: " .. tostring(error))
		end
	end)
end

-- Main execution with comprehensive error handling
local function Main()
	print("ClientLoader: Starting main execution...")

	local success, result = pcall(function()
		-- Initialize all systems
		local GameClient = InitializeClient()

		-- Setup additional systems
		SetupErrorHandling()
		SetupDevTools()
		CreateWelcomeSystem()

		print("=== PET PALACE CLIENT LOADER COMPLETE ===")
		print("✅ GameClient loaded and initialized")
		print("✅ Error handling and monitoring active")
		print("✅ Development tools available")
		print("")
		print("Client is ready! GameClient available as _G.GameClient")

		return GameClient
	end)

	if not success then
		-- Create emergency error UI
		warn("=== CRITICAL CLIENT FAILURE ===")
		warn("Error: " .. tostring(result))

		local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
		local errorGui = Instance.new("ScreenGui")
		errorGui.Name = "ClientErrorGui"
		errorGui.Parent = PlayerGui

		local errorFrame = Instance.new("Frame")
		errorFrame.Size = UDim2.new(0.6, 0, 0.4, 0)
		errorFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		errorFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		errorFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		errorFrame.BorderSizePixel = 0
		errorFrame.Parent = errorGui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.02, 0)
		corner.Parent = errorFrame

		local errorLabel = Instance.new("TextLabel")
		errorLabel.Size = UDim2.new(0.9, 0, 0.8, 0)
		errorLabel.Position = UDim2.new(0.05, 0, 0.1, 0)
		errorLabel.BackgroundTransparency = 1
		errorLabel.Text = "❌ Game Loading Error\n\nThere was a problem loading the game.\nPlease try rejoining the game.\n\n" .. tostring(result)
		errorLabel.TextColor3 = Color3.new(1, 1, 1)
		errorLabel.TextScaled = true
		errorLabel.TextWrapped = true
		errorLabel.Font = Enum.Font.Gotham
		errorLabel.Parent = errorFrame

		-- Auto-hide after 10 seconds
		spawn(function()
			wait(10)
			errorGui:Destroy()
		end)

		error("CRITICAL CLIENT FAILURE: " .. tostring(result))
	else
		print("ClientLoader: All systems operational and ready!")
	end
end

-- Execute main function
Main()