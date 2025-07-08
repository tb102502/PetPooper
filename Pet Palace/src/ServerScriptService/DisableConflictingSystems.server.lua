--[[
    DisableConflictingSystems.server.lua - Disable Conflicting Proximity Systems
    Place in: ServerScriptService/DisableConflictingSystems.server.lua
    
    This script disables the duplicate proximity detection systems that are causing
    the constant GUI pop-ups. Run this BEFORE the fixed CowMilkingModule loads.
]]

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

print("🔧 DisableConflictingSystems: Starting system cleanup...")

-- ========== DISABLE CONFLICTING SCRIPTS ==========

local function disableScript(scriptName, reason)
	local script = ServerScriptService:FindFirstChild(scriptName)
	if script then
		script.Disabled = true
		print("🚫 Disabled: " .. scriptName .. " - " .. reason)
		return true
	else
		print("ℹ️ Script not found: " .. scriptName)
		return false
	end
end

-- Disable the conflicting proximity detection systems
local disabledScripts = {
	{"ProximityDetection", "Duplicate proximity system - consolidated into CowMilkingModule"},
	{"ProximityDebounceFix", "No longer needed - debouncing built into CowMilkingModule"},
	{"MilkingSystemDebug", "Debug script causing interference"},
}

for _, scriptInfo in ipairs(disabledScripts) do
	local scriptName, reason = scriptInfo[1], scriptInfo[2]
	disableScript(scriptName, reason)
end

-- ========== CLEAN UP GLOBAL VARIABLES ==========

local function cleanupGlobals()
	print("🧹 Cleaning up conflicting global variables...")

	-- Remove conflicting proximity systems
	if _G.ProximityDetection then
		if _G.ProximityDetection.Cleanup then
			pcall(function()
				_G.ProximityDetection:Cleanup()
			end)
		end
		_G.ProximityDetection = nil
		print("🗑️ Removed _G.ProximityDetection")
	end

	if _G.ProximityDebounceFix then
		_G.ProximityDebounceFix = nil
		print("🗑️ Removed _G.ProximityDebounceFix")
	end

	print("✅ Global cleanup complete")
end

-- ========== SETUP DEBUG COMMANDS ==========

local function setupCleanupCommands()
	print("🔧 Setting up cleanup debug commands...")

	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Change to your username
				local command = message:lower()

				if command == "/cleanupstatus" then
					print("=== CLEANUP STATUS ===")

					-- Check which scripts are disabled
					local scriptsToCheck = {"ProximityDetection", "ProximityDebounceFix", "MilkingSystemDebug"}
					for _, scriptName in ipairs(scriptsToCheck) do
						local script = ServerScriptService:FindFirstChild(scriptName)
						if script then
							print(scriptName .. ": " .. (script.Disabled and "DISABLED ✅" or "ACTIVE ⚠️"))
						else
							print(scriptName .. ": NOT FOUND")
						end
					end

					-- Check global variables
					print("Global variables:")
					print("  _G.ProximityDetection: " .. (_G.ProximityDetection and "EXISTS ⚠️" or "REMOVED ✅"))
					print("  _G.ProximityDebounceFix: " .. (_G.ProximityDebounceFix and "EXISTS ⚠️" or "REMOVED ✅"))
					print("  _G.CowMilkingModule: " .. (_G.CowMilkingModule and "EXISTS ✅" or "MISSING ❌"))

					print("======================")

				elseif command == "/forcecleanup" then
					print("🔧 Force cleanup...")
					cleanupGlobals()

					-- Force disable scripts
					for _, scriptInfo in ipairs(disabledScripts) do
						local scriptName = scriptInfo[1]
						disableScript(scriptName, "Force disabled")
					end

				elseif command == "/resetproximity" then
					print("🔄 Resetting proximity state for " .. player.Name)
					if _G.CowMilkingModule and _G.CowMilkingModule.ResetPlayerProximity then
						_G.CowMilkingModule:ResetPlayerProximity(player)
					else
						print("❌ CowMilkingModule.ResetPlayerProximity not available")
					end

				elseif command == "/debugmilking" then
					print("🔍 Debug milking system for " .. player.Name)
					if _G.CowMilkingModule and _G.CowMilkingModule.DebugPlayerProximity then
						_G.CowMilkingModule:DebugPlayerProximity(player)
					else
						print("❌ CowMilkingModule.DebugPlayerProximity not available")
					end

				elseif command == "/systemstatus" then
					print("🔍 Complete system status:")
					if _G.CowMilkingModule and _G.CowMilkingModule.GetSystemStatus then
						local status = _G.CowMilkingModule:GetSystemStatus()
						print("Active milking sessions: " .. status.activeSessions.count)
						print("Available chairs: " .. status.chairs.count)
						if status.proximityStates then
							print("Proximity states: " .. status.proximityStates.count)
						end
					else
						print("❌ CowMilkingModule not available or missing GetSystemStatus")
					end
				end
			end
		end)
	end)

	print("✅ Cleanup commands ready")
end

-- ========== MAIN EXECUTION ==========

wait(1) -- Give other scripts time to load

print("🔧 DisableConflictingSystems: Executing cleanup...")

-- Clean up first
cleanupGlobals()

-- Wait a moment
wait(0.5)

-- Set up debug commands
setupCleanupCommands()

print("✅ DisableConflictingSystems: Cleanup complete!")
print("")
print("🎮 Debug Commands Available:")
print("  /cleanupstatus - Check cleanup status")
print("  /forcecleanup - Force cleanup conflicting systems")
print("  /resetproximity - Reset proximity state")
print("  /debugmilking - Debug milking system")
print("  /systemstatus - Show complete system status")
print("")
print("🔧 NEXT STEPS:")
print("1. The fixed CowMilkingModule should now work without conflicts")
print("2. Use /debugmilking to check cow ownership issues")
print("3. Use /resetproximity if GUI gets stuck")
print("4. Use /systemstatus to monitor the system")