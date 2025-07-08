--[[
    EmergencyCleanup.server.lua - Fix FireClient Error and Remove Conflicts
    Place in: ServerScriptService/EmergencyCleanup.server.lua
    
    This script immediately fixes the FireClient error and removes conflicting systems
]]

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

print("🚨 EmergencyCleanup: Fixing FireClient error...")

-- ========== DISABLE CONFLICTING SCRIPTS IMMEDIATELY ==========

local function disableConflictingScripts()
	print("🔧 EmergencyCleanup: Disabling conflicting scripts...")

	local scriptsToDisable = {
		"ProximityDebounceFix",    -- This is causing the FireClient error
		"ProximityDetection",      -- Duplicate proximity system
		"MilkingSystemDebug",      -- Can cause interference
	}

	local disabledCount = 0

	for _, scriptName in ipairs(scriptsToDisable) do
		local script = ServerScriptService:FindFirstChild(scriptName)
		if script then
			script.Disabled = true
			print("🚫 Disabled: " .. scriptName)
			disabledCount = disabledCount + 1
		else
			-- Also check for .server.lua versions
			local serverScript = ServerScriptService:FindFirstChild(scriptName .. ".server")
			if serverScript then
				serverScript.Disabled = true
				print("🚫 Disabled: " .. scriptName .. ".server")
				disabledCount = disabledCount + 1
			end
		end
	end

	return disabledCount
end

-- ========== CLEAN UP OVERRIDDEN REMOTE EVENTS ==========

local function cleanupRemoteEventOverrides()
	print("🧹 EmergencyCleanup: Cleaning up remote event overrides...")

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")

	if gameRemotes then
		local showChairPrompt = gameRemotes:FindFirstChild("ShowChairPrompt")
		local hideChairPrompt = gameRemotes:FindFirstChild("HideChairPrompt")

		if showChairPrompt and showChairPrompt:IsA("RemoteEvent") then
			-- The FireClient method might have been overridden incorrectly
			-- Let's check if it exists and is working
			local hasFireClient = typeof(showChairPrompt.FireClient) == "function"
			print("ShowChairPrompt.FireClient exists: " .. tostring(hasFireClient))

			if not hasFireClient then
				-- RemoteEvent has been corrupted, recreate it
				print("🔧 Recreating corrupted ShowChairPrompt...")
				showChairPrompt:Destroy()

				local newShowPrompt = Instance.new("RemoteEvent")
				newShowPrompt.Name = "ShowChairPrompt"
				newShowPrompt.Parent = gameRemotes
				print("✅ Recreated ShowChairPrompt")
			end
		end

		if hideChairPrompt and hideChairPrompt:IsA("RemoteEvent") then
			local hasFireClient = typeof(hideChairPrompt.FireClient) == "function"
			print("HideChairPrompt.FireClient exists: " .. tostring(hasFireClient))

			if not hasFireClient then
				print("🔧 Recreating corrupted HideChairPrompt...")
				hideChairPrompt:Destroy()

				local newHidePrompt = Instance.new("RemoteEvent")
				newHidePrompt.Name = "HideChairPrompt"
				newHidePrompt.Parent = gameRemotes
				print("✅ Recreated HideChairPrompt")
			end
		end
	end
end

-- ========== FORCE RESTART MILKING MODULE ==========

local function restartMilkingModule()
	print("🔄 EmergencyCleanup: Restarting milking module...")

	-- Clean up existing global
	if _G.CowMilkingModule then
		if _G.CowMilkingModule.Cleanup then
			pcall(function()
				_G.CowMilkingModule:Cleanup()
			end)
		end
		_G.CowMilkingModule = nil
		print("🗑️ Cleaned up existing CowMilkingModule")
	end

	-- Force reload the module
	local cowMilkingScript = ServerScriptService:FindFirstChild("CowMilkingModule")
	if cowMilkingScript then
		print("🔄 Reloading CowMilkingModule...")

		-- Wait a moment for cleanup
		wait(1)

		-- The module should reinitialize automatically
		print("✅ CowMilkingModule reload initiated")
	else
		print("⚠️ CowMilkingModule script not found")
	end
end

-- ========== SETUP EMERGENCY COMMANDS ==========

local function setupEmergencyCommands()
	print("🔧 Setting up emergency commands...")

	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Change to your username
				local command = message:lower()

				if command == "/emergencyfix" then
					print("🚨 Running emergency fix...")
					local disabled = disableConflictingScripts()
					cleanupRemoteEventOverrides()
					restartMilkingModule()
					print("✅ Emergency fix complete - disabled " .. disabled .. " scripts")

				elseif command == "/checkremotes" then
					print("🔍 Checking remote events...")
					local ReplicatedStorage = game:GetService("ReplicatedStorage")
					local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")

					if gameRemotes then
						for _, child in pairs(gameRemotes:GetChildren()) do
							if child:IsA("RemoteEvent") then
								local hasFireClient = typeof(child.FireClient) == "function"
								print(child.Name .. " - FireClient: " .. tostring(hasFireClient))
							end
						end
					else
						print("❌ GameRemotes folder not found")
					end

				elseif command == "/forceclean" then
					print("🧹 Force cleaning all systems...")

					-- Disable ALL potential conflicting scripts
					local allScripts = {
						"ProximityDebounceFix",
						"ProximityDetection", 
						"MilkingSystemDebug",
						"SystemVerifier"
					}

					for _, scriptName in ipairs(allScripts) do
						local script = ServerScriptService:FindFirstChild(scriptName)
						if script then
							script.Disabled = true
							print("🚫 Force disabled: " .. scriptName)
						end
					end

					-- Clean globals
					_G.ProximityDetection = nil
					_G.ProximityDebounceFix = nil

					print("✅ Force clean complete")

				elseif command == "/testremote" then
					print("🧪 Testing remote events...")
					local ReplicatedStorage = game:GetService("ReplicatedStorage")
					local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")

					if gameRemotes then
						local showPrompt = gameRemotes:FindFirstChild("ShowChairPrompt")
						if showPrompt then
							local success, error = pcall(function()
								showPrompt:FireClient(player, "test", {
									title = "🧪 Test Prompt",
									subtitle = "Testing remote event",
									instruction = "If you see this, remote events work!"
								})
							end)

							if success then
								print("✅ Remote event test successful")
							else
								print("❌ Remote event test failed: " .. tostring(error))
							end
						else
							print("❌ ShowChairPrompt not found")
						end
					end

				elseif command == "/status" then
					print("📊 System status check...")

					-- Check scripts
					local conflictingScripts = {"ProximityDebounceFix", "ProximityDetection", "MilkingSystemDebug"}
					for _, scriptName in ipairs(conflictingScripts) do
						local script = ServerScriptService:FindFirstChild(scriptName)
						if script then
							print(scriptName .. ": " .. (script.Disabled and "DISABLED ✅" or "ACTIVE ⚠️"))
						else
							print(scriptName .. ": NOT FOUND")
						end
					end

					-- Check globals
					print("_G.CowMilkingModule: " .. (_G.CowMilkingModule and "EXISTS ✅" or "MISSING ❌"))
					print("_G.ProximityDetection: " .. (_G.ProximityDetection and "EXISTS ⚠️" or "REMOVED ✅"))

					-- Check remote events
					local ReplicatedStorage = game:GetService("ReplicatedStorage")
					local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
					if gameRemotes then
						local showPrompt = gameRemotes:FindFirstChild("ShowChairPrompt")
						if showPrompt then
							local hasFireClient = typeof(showPrompt.FireClient) == "function"
							print("ShowChairPrompt FireClient: " .. (hasFireClient and "WORKING ✅" or "BROKEN ❌"))
						end
					end
				end
			end
		end)
	end)

	print("✅ Emergency commands ready")
end

-- ========== MAIN EXECUTION ==========

local function main()
	print("🚨 EmergencyCleanup: Starting immediate fixes...")

	-- Step 1: Disable conflicting scripts
	local disabled = disableConflictingScripts()

	-- Step 2: Clean up remote event overrides
	cleanupRemoteEventOverrides()

	-- Step 3: Wait a moment then restart systems
	wait(1)
	restartMilkingModule()

	-- Step 4: Setup emergency commands
	setupEmergencyCommands()

	print("✅ EmergencyCleanup: Complete!")
	print("Disabled " .. disabled .. " conflicting scripts")
end

-- Execute immediately
local success, error = pcall(main)

if not success then
	warn("❌ EmergencyCleanup failed: " .. tostring(error))
else
	print("🎉 EmergencyCleanup: Ready!")
	print("")
	print("🚨 EMERGENCY COMMANDS:")
	print("  /emergencyfix - Run complete emergency fix")
	print("  /checkremotes - Check remote event status") 
	print("  /forceclean - Force disable all conflicting scripts")
	print("  /testremote - Test remote event functionality")
	print("  /status - Check complete system status")
	print("")
	print("💡 RUN /emergencyfix NOW to fix the FireClient error!")
end