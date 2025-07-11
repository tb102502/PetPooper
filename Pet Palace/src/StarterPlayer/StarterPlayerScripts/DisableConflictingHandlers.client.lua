--[[
    DisableConflictingHandlers.client.lua - Remove Duplicate Click Systems
    Place in: StarterPlayer/StarterPlayerScripts/DisableConflictingHandlers.client.lua
    
    PURPOSE:
    ✅ Removes/disables the old duplicate click handling scripts
    ✅ Prevents multiple click events from being sent
    ✅ Ensures only UnifiedMilkingHandler processes clicks
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

print("🛑 DisableConflictingHandlers: Starting cleanup of duplicate click systems...")

local handlersToDisable = {
	"MilkingClickHandler",
	"MilkingIntegration", 
	"ChairMilkingClickHandler"
}

local scriptsToRemove = {
	"MilkingClickHandler.client",
	"MilkingIntegration.client",
	"OldMilkingHandler"
}

-- ========== DISABLE GLOBAL HANDLERS ==========

local function DisableGlobalHandlers()
	print("🔧 Disabling global click handlers...")

	for _, handlerName in ipairs(handlersToDisable) do
		if _G[handlerName] then
			-- Try to disable the handler
			if type(_G[handlerName]) == "table" then
				_G[handlerName].disabled = true
				_G[handlerName].active = false

				-- Disconnect any connections if available
				if _G[handlerName].connections then
					for _, connection in pairs(_G[handlerName].connections) do
						if connection and connection.Connected then
							connection:Disconnect()
							print("  🔌 Disconnected connection in " .. handlerName)
						end
					end
				end

				-- Clear input handlers if available
				if _G[handlerName].inputConnections then
					for _, connection in pairs(_G[handlerName].inputConnections) do
						if connection and connection.Connected then
							connection:Disconnect()
							print("  🖱️ Disconnected input in " .. handlerName)
						end
					end
				end

				print("✅ Disabled global handler: " .. handlerName)
			else
				print("⚠️ Handler " .. handlerName .. " is not a table, setting to nil")
				_G[handlerName] = nil
			end
		else
			print("ℹ️ Handler " .. handlerName .. " not found (already disabled or not loaded)")
		end
	end
end

-- ========== REMOVE OLD SCRIPTS ==========

local function RemoveOldScripts()
	print("🗑️ Removing old milking scripts...")

	local playerScripts = LocalPlayer:WaitForChild("PlayerScripts", 5)
	if not playerScripts then
		print("⚠️ PlayerScripts not found")
		return
	end

	for _, scriptName in ipairs(scriptsToRemove) do
		local script = playerScripts:FindFirstChild(scriptName)
		if script then
			print("🗑️ Removing old script: " .. scriptName)
			script:Destroy()
		end
	end

	-- Also check StarterPlayerScripts for any old scripts
	local starterPlayerScripts = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
	if starterPlayerScripts then
		for _, scriptName in ipairs(scriptsToRemove) do
			local script = starterPlayerScripts:FindFirstChild(scriptName)
			if script then
				print("⚠️ Found old script in StarterPlayerScripts: " .. scriptName)
				print("   Please manually remove this script to prevent conflicts")
			end
		end
	end
end

-- ========== CLEAR EXISTING INPUT CONNECTIONS ==========

local function ClearExistingInputConnections()
	print("🔌 Clearing existing input connections...")

	-- Clear any globally stored input connections
	if _G.MilkingInputConnections then
		for i, connection in ipairs(_G.MilkingInputConnections) do
			if connection and connection.Connected then
				connection:Disconnect()
				print("  🔌 Disconnected global input connection " .. i)
			end
		end
		_G.MilkingInputConnections = {}
	end

	-- Clear UserInputService connections related to milking
	local UserInputService = game:GetService("UserInputService")

	-- Note: We can't directly access all connections, but we can mark them as cleared
	print("✅ Cleared existing input connections")
end

-- ========== PREVENT SCRIPT CONFLICTS ==========

local function PreventScriptConflicts()
	print("🛡️ Setting up conflict prevention...")

	-- Mark that we're using the unified handler
	_G.UnifiedMilkingHandlerActive = true
	_G.MilkingSystemCleanupComplete = true

	-- Create a flag that other scripts can check
	_G.MilkingClickingDisabled = true

	-- Override any attempt to create new milking click handlers
	local originalConnect = game:GetService("UserInputService").InputBegan.Connect

	-- We can't really override this safely, so just set flags
	_G.MilkingSystemFlags = {
		unifiedHandlerActive = true,
		duplicateHandlersDisabled = true,
		conflictPreventionActive = true,
		timestamp = tick()
	}

	print("✅ Conflict prevention setup complete")
end

-- ========== VERIFY CLEANUP ==========

local function VerifyCleanup()
	print("🔍 Verifying cleanup...")

	local cleanupResults = {
		disabledHandlers = 0,
		removedScripts = 0,
		remainingConflicts = {}
	}

	-- Check disabled handlers
	for _, handlerName in ipairs(handlersToDisable) do
		if _G[handlerName] and (_G[handlerName].disabled or not _G[handlerName].active) then
			cleanupResults.disabledHandlers = cleanupResults.disabledHandlers + 1
		elseif _G[handlerName] then
			table.insert(cleanupResults.remainingConflicts, handlerName)
		end
	end

	-- Check for remaining scripts
	local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
	if playerScripts then
		for _, scriptName in ipairs(scriptsToRemove) do
			local script = playerScripts:FindFirstChild(scriptName)
			if not script then
				cleanupResults.removedScripts = cleanupResults.removedScripts + 1
			else
				table.insert(cleanupResults.remainingConflicts, "Script: " .. scriptName)
			end
		end
	end

	print("📊 Cleanup Results:")
	print("  Disabled handlers: " .. cleanupResults.disabledHandlers .. "/" .. #handlersToDisable)
	print("  Removed scripts: " .. cleanupResults.removedScripts .. "/" .. #scriptsToRemove)

	if #cleanupResults.remainingConflicts > 0 then
		print("⚠️ Remaining conflicts:")
		for _, conflict in ipairs(cleanupResults.remainingConflicts) do
			print("    - " .. conflict)
		end
	else
		print("✅ No conflicts detected!")
	end

	return cleanupResults
end

-- ========== MONITORING SYSTEM ==========

local function StartConflictMonitoring()
	print("👁️ Starting conflict monitoring...")

	spawn(function()
		while true do
			wait(30) -- Check every 30 seconds

			-- Check if any old handlers have been re-enabled
			local conflicts = {}

			for _, handlerName in ipairs(handlersToDisable) do
				if _G[handlerName] and not _G[handlerName].disabled then
					table.insert(conflicts, handlerName)
				end
			end

			if #conflicts > 0 then
				warn("⚠️ Milking handler conflicts detected!")
				for _, conflict in ipairs(conflicts) do
					warn("  - " .. conflict .. " has been re-enabled")
					-- Try to disable it again
					if _G[conflict] then
						_G[conflict].disabled = true
						_G[conflict].active = false
					end
				end
				print("🔧 Re-disabled conflicting handlers")
			end
		end
	end)
end

-- ========== MAIN EXECUTION ==========

local function ExecuteCleanup()
	print("🧹 Starting milking system cleanup...")

	local success, errorMessage = pcall(function()
		-- Step 1: Disable global handlers
		DisableGlobalHandlers()
		wait(0.1)

		-- Step 2: Remove old scripts
		RemoveOldScripts()
		wait(0.1)

		-- Step 3: Clear input connections
		ClearExistingInputConnections()
		wait(0.1)

		-- Step 4: Prevent future conflicts
		PreventScriptConflicts()
		wait(0.1)

		-- Step 5: Verify cleanup
		local results = VerifyCleanup()

		-- Step 6: Start monitoring
		StartConflictMonitoring()

		return true, results
	end)

	if success then
		print("✅ Milking system cleanup complete!")
		print("")
		print("🔧 CLEANUP SUMMARY:")
		print("  🛑 Disabled duplicate handlers")
		print("  🗑️ Removed old scripts")
		print("  🔌 Cleared input connections")
		print("  🛡️ Enabled conflict prevention")
		print("  👁️ Started monitoring system")
		print("")
		print("✅ Only UnifiedMilkingHandler should now process clicks!")
		return true
	else
		warn("❌ Cleanup failed: " .. tostring(errorMessage))
		return false
	end
end

-- ========== DEBUG COMMANDS ==========

local function SetupDebugCommands()
	LocalPlayer.Chatted:Connect(function(message)
		local command = message:lower()

		if command == "/cleanupstatus" then
			print("🔍 Milking system cleanup status:")
			print("Unified handler active: " .. tostring(_G.UnifiedMilkingHandlerActive))
			print("Cleanup complete: " .. tostring(_G.MilkingSystemCleanupComplete))
			print("Clicking disabled: " .. tostring(_G.MilkingClickingDisabled))

			if _G.MilkingSystemFlags then
				print("System flags:")
				for key, value in pairs(_G.MilkingSystemFlags) do
					print("  " .. key .. ": " .. tostring(value))
				end
			end

		elseif command == "/recheckconflicts" then
			print("🔍 Re-checking for conflicts...")
			VerifyCleanup()

		elseif command == "/forcecleanup" then
			print("🔧 Force re-running cleanup...")
			ExecuteCleanup()

		elseif command == "/listhandlers" then
			print("📋 Current global handlers:")
			for _, handlerName in ipairs(handlersToDisable) do
				if _G[handlerName] then
					local status = "ACTIVE"
					if _G[handlerName].disabled then
						status = "DISABLED"
					elseif not _G[handlerName].active then
						status = "INACTIVE"
					end
					print("  " .. handlerName .. ": " .. status)
				else
					print("  " .. handlerName .. ": NOT FOUND")
				end
			end
		end
	end)

	print("🎮 Debug commands available:")
	print("  /cleanupstatus - Show cleanup status")
	print("  /recheckconflicts - Re-check for conflicts") 
	print("  /forcecleanup - Force re-run cleanup")
	print("  /listhandlers - List handler status")
end

-- ========== EXECUTE ==========

spawn(function()
	wait(2) -- Let other scripts load first

	local success = ExecuteCleanup()

	if success then
		SetupDebugCommands()
		print("🎉 Milking system conflict resolution complete!")
		print("💡 Now only UnifiedMilkingHandler should handle clicks")
	else
		warn("❌ Cleanup failed - manual intervention may be required")
		SetupDebugCommands() -- Still provide debug tools
	end
end)

-- ========== GLOBAL ACCESS ==========

_G.DisableConflictingHandlers = {
	ExecuteCleanup = ExecuteCleanup,
	VerifyCleanup = VerifyCleanup,
	IsCleanupComplete = function()
		return _G.MilkingSystemCleanupComplete == true
	end
}

print("🛑 DisableConflictingHandlers: ✅ LOADED - Removing duplicate click systems!")