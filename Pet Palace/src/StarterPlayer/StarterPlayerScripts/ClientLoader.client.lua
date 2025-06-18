--[[
    FIXED ClientLoader.client.lua - Complete Working Version
    Eliminates all circular dependencies and function scope issues
    
    FINAL WORKING VERSION:
    1. ✅ All functions properly defined and scoped
    2. ✅ Clean modules with no external dependencies
    3. ✅ Proper initialization order
    4. ✅ No circular dependency issues
    5. ✅ Comprehensive error handling
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

print("=== PET PALACE FIXED CLIENT LOADER STARTING ===")

-- Wait for character to load
if not LocalPlayer.Character then
	LocalPlayer.CharacterAdded:Wait()
end

print("ClientLoader: Character loaded, initializing fixed systems...")

-- ========== UTILITY FUNCTIONS ==========

-- Helper function to show loading progress
local function ShowLoadingProgress(step, total, message)
	local percentage = math.floor((step / total) * 100)
	print(string.format("ClientLoader: [%d/%d] (%d%%) %s", step, total, percentage, message))
end

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

-- ========== MODULE LOADING FUNCTIONS ==========

-- Load Clean UIManager module (no external dependencies)
local function LoadCleanUIManager()
	print("ClientLoader: Loading clean UIManager module...")

	-- Wait for UIManager module
	local uiManagerModule = ReplicatedStorage:WaitForChild("UIManager", 30)
	if not uiManagerModule then
		error("ClientLoader: UIManager module not found in ReplicatedStorage")
	end

	if not uiManagerModule:IsA("ModuleScript") then
		error("ClientLoader: UIManager is not a ModuleScript, it's a " .. uiManagerModule.ClassName)
	end

	-- Require the module with error handling
	local success, UIManager = pcall(function()
		return require(uiManagerModule)
	end)

	if not success then
		error("ClientLoader: Failed to require UIManager module: " .. tostring(UIManager))
	end

	-- Enhanced validation
	if not UIManager then
		error("ClientLoader: UIManager module returned nil")
	end

	if type(UIManager) ~= "table" then
		error("ClientLoader: UIManager must be a table, got " .. type(UIManager))
	end

	-- Check for required methods
	local requiredMethods = {"Initialize", "OpenMenu", "CloseActiveMenus", "ShowNotification"}
	for _, methodName in ipairs(requiredMethods) do
		if type(UIManager[methodName]) ~= "function" then
			error("ClientLoader: UIManager is missing required method: " .. methodName)
		end
	end

	print("ClientLoader: Clean UIManager module loaded and validated successfully")
	return UIManager
end

-- Load Clean GameClient module (no external dependencies)
local function LoadCleanGameClient()
	print("ClientLoader: Loading clean GameClient module...")

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

	-- Check for required methods (UPDATED for clean architecture)
	local requiredMethods = {"Initialize", "SetupRemoteConnections", "RequestInitialData", "GetPlayerData"}
	for _, methodName in ipairs(requiredMethods) do
		if type(GameClient[methodName]) ~= "function" then
			error("ClientLoader: GameClient is missing required method: " .. methodName)
		end
	end

	print("ClientLoader: Clean GameClient module loaded and validated successfully")
	return GameClient
end

-- ========== INITIALIZATION FUNCTIONS ==========

-- Initialize clean modular architecture
local function InitializeCleanClient()
	print("ClientLoader: Starting clean modular client initialization...")

	-- Wait for server readiness
	WaitForServerReady()

	-- Load UIManager first (clean version - no dependencies)
	local UIManager = LoadCleanUIManager()

	-- Initialize UIManager first (standalone initialization)
	local uiInitSuccess, uiErrorMsg = pcall(function()
		return UIManager:Initialize() -- Clean UIManager doesn't need GameClient during init
	end)

	if not uiInitSuccess then
		error("ClientLoader: Clean UIManager initialization failed: " .. tostring(uiErrorMsg))
	end

	-- Load GameClient module (clean version - no dependencies)
	local GameClient = LoadCleanGameClient()

	-- Initialize GameClient (pass UIManager as parameter)
	local initSuccess, errorMsg = pcall(function()
		return GameClient:Initialize(UIManager)
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

	-- Make both modules globally available
	_G.GameClient = GameClient
	_G.UIManager = UIManager

	-- Validate global availability
	if not _G.GameClient then
		error("ClientLoader: Failed to make GameClient globally available")
	end

	if not _G.UIManager then
		error("ClientLoader: Failed to make UIManager globally available")
	end

	print("ClientLoader: Both clean modules initialized and available globally")
	return GameClient, UIManager
end

-- ========== MONITORING FUNCTIONS ==========

-- Setup error handling and monitoring for clean modular system
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

	-- Monitor both modules health
	spawn(function()
		while true do
			wait(30) -- Check every 30 seconds

			if not _G.GameClient then
				warn("ClientLoader: GameClient lost from global scope!")
			elseif type(_G.GameClient) ~= "table" then
				warn("ClientLoader: GameClient corrupted in global scope!")
			end

			if not _G.UIManager then
				warn("ClientLoader: UIManager lost from global scope!")
			elseif type(_G.UIManager) ~= "table" then
				warn("ClientLoader: UIManager corrupted in global scope!")
			end
		end
	end)
end

-- Setup development tools (studio only) - UPDATED for new architecture
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
			-- Show UIManager debug
			if _G.UIManager and _G.UIManager.GetState then
				local state = _G.UIManager:GetState()
				print("=== UIMANAGER DEBUG STATUS ===")
				print("MainUI exists:", state.MainUI ~= nil)
				print("Layers count:", state.Layers and #state.Layers or 0)
				print("Active menus:", state.ActiveMenus and #state.ActiveMenus or 0)
				print("Current page:", state.CurrentPage or "None")
				print("Is transitioning:", state.IsTransitioning or false)
				print("===============================")
			else
				print("UIManager debug not available")
			end
		elseif input.KeyCode == Enum.KeyCode.F11 then
			-- Test farm menu
			if _G.GameClient and _G.GameClient.OpenMenu then
				_G.GameClient:OpenMenu("Farm")
			else
				print("Farm menu test not available")
			end
		elseif input.KeyCode == Enum.KeyCode.F12 then
			-- Test notification
			if _G.UIManager and _G.UIManager.ShowNotification then
				_G.UIManager:ShowNotification("🧪 Test", "This is a test notification from F12!", "info")
			else
				print("Notification test not available")
			end
		end
	end)

	print("ClientLoader: Dev tools active:")
	print("  F9  = GameClient Debug")
	print("  F10 = UIManager Debug") 
	print("  F11 = Test Farm Menu")
	print("  F12 = Test Notification")
end

-- Create helpful UI for new players - UPDATED for new architecture
local function CreateWelcomeSystem()
	spawn(function()
		wait(3) -- Wait for everything to load

		local success, error = pcall(function()
			if _G.UIManager and _G.UIManager.ShowNotification then
				_G.UIManager:ShowNotification(
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

-- ========== MAIN EXECUTION ==========

-- Main execution with comprehensive error handling - UPDATED
local function Main()
	print("ClientLoader: Starting fixed main execution...")

	local success, result = pcall(function()
		-- Initialize all systems with progress tracking
		ShowLoadingProgress(1, 5, "Loading clean modules...")
		local GameClient, UIManager = InitializeCleanClient()

		ShowLoadingProgress(2, 5, "Setting up error handling...")
		SetupErrorHandling()

		ShowLoadingProgress(3, 5, "Setting up development tools...")
		SetupDevTools()

		ShowLoadingProgress(4, 5, "Creating welcome system...")
		CreateWelcomeSystem()

		ShowLoadingProgress(5, 5, "Finalizing initialization...")

		print("=== PET PALACE FIXED CLIENT LOADER COMPLETE ===")
		print("✅ Clean GameClient loaded and initialized")
		print("✅ Clean UIManager loaded and initialized")
		print("✅ Error handling and monitoring active")
		print("✅ Development tools available")
		print("")
		print("Client is ready!")
		print("  GameClient available as _G.GameClient")
		print("  UIManager available as _G.UIManager")
		print("  🚫 NO circular dependencies")
		print("  ✨ Clean modular architecture")
		print("  🔧 All function scopes fixed")

		return GameClient, UIManager
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
		errorLabel.Size = UDim2.new(0.9, 0, 0.6, 0)
		errorLabel.Position = UDim2.new(0.05, 0, 0.1, 0)
		errorLabel.BackgroundTransparency = 1
		errorLabel.Text = "❌ Game Loading Error\n\nThere was a problem loading the fixed clean game systems.\nPlease try rejoining the game."
		errorLabel.TextColor3 = Color3.new(1, 1, 1)
		errorLabel.TextScaled = true
		errorLabel.TextWrapped = true
		errorLabel.Font = Enum.Font.GothamBold
		errorLabel.Parent = errorFrame

		-- Error details (smaller text)
		local errorDetails = Instance.new("TextLabel")
		errorDetails.Size = UDim2.new(0.9, 0, 0.25, 0)
		errorDetails.Position = UDim2.new(0.05, 0, 0.7, 0)
		errorDetails.BackgroundTransparency = 1
		errorDetails.Text = "Technical Details: " .. tostring(result)
		errorDetails.TextColor3 = Color3.fromRGB(200, 200, 200)
		errorDetails.TextScaled = true
		errorDetails.TextWrapped = true
		errorDetails.Font = Enum.Font.Gotham
		errorDetails.Parent = errorFrame

		-- Auto-hide after 15 seconds
		spawn(function()
			wait(15)
			if errorGui and errorGui.Parent then
				errorGui:Destroy()
			end
		end)

		error("CRITICAL CLIENT FAILURE: " .. tostring(result))
	else
		print("ClientLoader: All fixed clean modular systems operational and ready!")
	end
end

-- Execute main function
Main()