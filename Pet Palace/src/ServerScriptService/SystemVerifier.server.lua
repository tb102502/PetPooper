--[[
    SystemVerifier.server.lua - Quick System Verification
    Place in: ServerScriptService/SystemVerifier.server.lua
    
    This script helps verify that all systems are working correctly
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

wait(5) -- Wait for other systems to load

print("🔍 === SYSTEM VERIFICATION ===")

-- Check folder structure
local function CheckStructure()
	print("📁 Checking folder structure...")

	local checks = {
		{ServerScriptService, "Core", "Core folder"},
		{ServerScriptService.Core, "GameCore", "GameCore module"},
		{ReplicatedStorage, "ItemConfig", "ItemConfig module"},
		{ServerScriptService, "CowCreationModule", "CowCreationModule"},
		{ServerScriptService, "CowMilkingModule", "CowMilkingModule"},
		{ReplicatedStorage, "GameRemotes", "GameRemotes folder"}
	}

	for _, check in ipairs(checks) do
		local parent, child, name = check[1], check[2], check[3]
		if parent and parent:FindFirstChild(child) then
			print("✅ " .. name .. " - Found")
		else
			print("❌ " .. name .. " - Missing")
		end
	end
end

-- Check global variables
local function CheckGlobals()
	print("🌐 Checking global variables...")

	local globals = {
		{"_G.GameCore", _G.GameCore},
		{"_G.CowCreationModule", _G.CowCreationModule},
		{"_G.CowMilkingModule", _G.CowMilkingModule}
	}

	for _, global in ipairs(globals) do
		local name, value = global[1], global[2]
		if value then
			print("✅ " .. name .. " - Available")
		else
			print("❌ " .. name .. " - Not found")
		end
	end
end

-- Check remote events
local function CheckRemoteEvents()
	print("📡 Checking remote events...")

	local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	if gameRemotes then
		print("✅ GameRemotes folder found")

		local requiredEvents = {
			"ShowChairPrompt",
			"HideChairPrompt",
			"StartMilkingSession", 
			"StopMilkingSession",
			"ContinueMilking",
			"MilkingSessionUpdate"
		}

		for _, eventName in ipairs(requiredEvents) do
			local event = gameRemotes:FindFirstChild(eventName)
			if event then
				print("✅ " .. eventName .. " - Found (" .. event.ClassName .. ")")
			else
				print("❌ " .. eventName .. " - Missing")
			end
		end
	else
		print("❌ GameRemotes folder not found")
	end
end

-- Check milking chairs
local function CheckChairs()
	print("🪑 Checking milking chairs...")

	if _G.CowMilkingModule and _G.CowMilkingModule.MilkingChairs then
		local chairCount = 0
		for chairId, chair in pairs(_G.CowMilkingModule.MilkingChairs) do
			chairCount = chairCount + 1
			if chair and chair.Parent then
				print("✅ Chair " .. chairCount .. ": " .. chairId .. " at " .. tostring(chair.Position))
			else
				print("❌ Chair " .. chairCount .. ": " .. chairId .. " - Invalid")
			end
		end

		if chairCount == 0 then
			print("⚠️ No chairs found - they should be created automatically")
		else
			print("✅ Total chairs: " .. chairCount)
		end
	else
		print("❌ CowMilkingModule.MilkingChairs not available")
	end
end

-- Check workspace objects
local function CheckWorkspace()
	print("🌍 Checking workspace objects...")

	local cowCount = 0
	local chairCount = 0

	for _, obj in pairs(workspace:GetChildren()) do
		if obj.Name:find("cow") or obj:GetAttribute("Owner") then
			cowCount = cowCount + 1
		end

		if obj.Name == "MilkingChair" or obj:GetAttribute("IsMilkingChair") then
			chairCount = chairCount + 1
		end
	end

	print("🐄 Cows in workspace: " .. cowCount)
	print("🪑 Chairs in workspace: " .. chairCount)
end

-- Run all checks
local function RunAllChecks()
	CheckStructure()
	print("")
	CheckGlobals()
	print("")
	CheckRemoteEvents()
	print("")
	CheckChairs()
	print("")
	CheckWorkspace()
	print("")

	-- Overall status
	if _G.GameCore and _G.CowMilkingModule then
		print("✅ SYSTEM STATUS: GOOD - Core systems loaded")

		local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
		if gameRemotes and gameRemotes:FindFirstChild("ShowChairPrompt") then
			print("✅ MILKING STATUS: READY - All components available")
		else
			print("⚠️ MILKING STATUS: PARTIAL - Missing remote events")
		end
	else
		print("❌ SYSTEM STATUS: FAILED - Core systems not loaded")
	end
end

-- Set up verification command
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if message:lower() == "/verify" then
			print("🔍 Running verification for " .. player.Name .. "...")
			RunAllChecks()
		end
	end)
end)

-- Run initial verification
RunAllChecks()

print("🔍 === VERIFICATION COMPLETE ===")
print("💬 Type /verify in chat to run verification again")