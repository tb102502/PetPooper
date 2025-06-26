--[[
    FIXED ClientLoader.client.lua - Proper Module Loading
    Place in: StarterPlayer/StarterPlayerScripts/ClientLoader.client.lua
    
    FIXES:
    ✅ Proper module loading and initialization
    ✅ Correct initialization order
    ✅ Error handling for missing modules
    ✅ Debug information for troubleshooting
]]

print("🚀 ClientLoader: Starting client initialization...")

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get local player
local LocalPlayer = Players.LocalPlayer

-- Wait for required modules
local function waitForModule(name, parent, timeout)
	timeout = timeout or 15
	local startTime = tick()

	while not parent:FindFirstChild(name) and (tick() - startTime) < timeout do
		wait(0.1)
	end

	if parent:FindFirstChild(name) then
		print("✅ Found module: " .. name)
		return parent:FindFirstChild(name)
	else
		error("❌ Module not found: " .. name .. " after " .. timeout .. " seconds")
	end
end

-- Step 1: Wait for UIManager
print("📱 Loading UIManager...")
local uiManagerModule = waitForModule("UIManager", ReplicatedStorage)
local UIManager = require(uiManagerModule)

-- Step 2: Wait for GameClient  
print("🎮 Loading GameClient...")
local gameClientModule = waitForModule("GameClient", ReplicatedStorage)
local GameClient = require(gameClientModule)

-- Step 3: Initialize UIManager first
print("🔧 Initializing UIManager...")
local uiSuccess, uiError = pcall(function()
	return UIManager:Initialize()
end)

if not uiSuccess then
	error("❌ UIManager initialization failed: " .. tostring(uiError))
end

print("✅ UIManager initialized successfully")

-- Step 4: Initialize GameClient with UIManager reference
print("🔧 Initializing GameClient...")
local clientSuccess, clientError = pcall(function()
	return GameClient:Initialize(UIManager)
end)

if not clientSuccess then
	error("❌ GameClient initialization failed: " .. tostring(clientError))
end

print("✅ GameClient initialized successfully")

-- Step 5: Cross-link the systems
UIManager:SetGameClient(GameClient)
print("🔗 Systems cross-linked successfully")

-- Step 6: Setup global access for debugging
_G.UIManager = UIManager
_G.GameClient = GameClient

-- Step 7: Setup debug commands
local function setupDebugCommands()
	if LocalPlayer then
		LocalPlayer.Chatted:Connect(function(message)
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/debugui" then
				print("=== UI DEBUG STATUS ===")
				print("UIManager initialized: " .. tostring(UIManager ~= nil))
				print("GameClient initialized: " .. tostring(GameClient ~= nil))
				print("UIManager has GameClient: " .. tostring(UIManager.State and UIManager.State.GameClient ~= nil))
				print("Current page: " .. (UIManager:GetCurrentPage() or "None"))

				-- Check for left-side buttons
				local leftSideUI = LocalPlayer.PlayerGui:FindFirstChild("LeftSideButtonsUI")
				print("Left-side buttons UI exists: " .. tostring(leftSideUI ~= nil))

				if leftSideUI then
					local buttonCount = 0
					for _, child in pairs(leftSideUI:GetChildren()) do
						if child:IsA("TextButton") then
							buttonCount = buttonCount + 1
						end
					end
					print("Number of left-side buttons: " .. buttonCount)
				end

				print("========================")

			elseif command == "/testshop" then
				print("Testing shop opening...")
				if UIManager and UIManager.OpenMenu then
					UIManager:OpenMenu("Shop")
				else
					print("❌ UIManager.OpenMenu not available")
				end

			elseif command == "/recreateui" then
				print("Recreating UI systems...")

				-- Cleanup existing
				if UIManager and UIManager.Cleanup then
					UIManager:Cleanup()
				end

				-- Reinitialize
				local success, error = pcall(function()
					UIManager:Initialize()
					UIManager:SetGameClient(GameClient)
				end)

				if success then
					print("✅ UI recreated successfully")
				else
					print("❌ UI recreation failed: " .. tostring(error))
				end

			elseif command == "/forceleftbuttons" then
				print("Force creating left-side buttons...")
				if UIManager and UIManager.SetupLeftSideButtons then
					local success, error = pcall(function()
						UIManager:SetupLeftSideButtons()
					end)

					if success then
						print("✅ Left-side buttons created")
					else
						print("❌ Left-side buttons failed: " .. tostring(error))
					end
				end
			end
		end)
	end
end

-- Setup debug commands
setupDebugCommands()

-- Step 8: Verify everything is working
spawn(function()
	wait(3) -- Give everything time to settle

	print("🔍 Final verification...")

	-- Check UI elements
	local mainUI = LocalPlayer.PlayerGui:FindFirstChild("MainGameUI")
	local leftSideUI = LocalPlayer.PlayerGui:FindFirstChild("LeftSideButtonsUI")

	print("Main UI exists: " .. tostring(mainUI ~= nil))
	print("Left-side UI exists: " .. tostring(leftSideUI ~= nil))

	if not leftSideUI and UIManager.SetupLeftSideButtons then
		print("⚠️ Left-side buttons missing, attempting to create...")
		local success, error = pcall(function()
			UIManager:SetupLeftSideButtons()
		end)

		if success then
			print("✅ Successfully created missing left-side buttons")
		else
			warn("❌ Failed to create left-side buttons: " .. tostring(error))
		end
	end

	-- Test proximity system connection
	if GameClient and GameClient.RemoteEvents then
		local openShopRemote = GameClient.RemoteEvents.OpenShop
		if openShopRemote then
			print("✅ OpenShop remote event connected")
		else
			warn("❌ OpenShop remote event not found")
		end
	end
end)

print("🎉 ClientLoader: Initialization complete!")
print("")
print("🔧 Debug Commands:")
print("  /debugui - Show UI system status")
print("  /testshop - Test shop opening")
print("  /recreateui - Recreate UI systems")
print("  /forceleftbuttons - Force create left-side buttons")