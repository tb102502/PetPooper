--[[
    MilkingSystemDebug.server.lua - Debug script for milking system issues
    Place in: ServerScriptService/MilkingSystemDebug.server.lua
    
    This script helps debug why the milking GUI isn't showing and chairs aren't working
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for systems to load
local function WaitForSystems()
	local maxWait = 30
	local startTime = tick()

	print("🔍 MilkingDebug: Waiting for systems to load...")

	while (tick() - startTime) < maxWait do
		if _G.GameCore and _G.CowMilkingModule and _G.CowCreationModule then
			print("✅ MilkingDebug: All systems loaded!")
			return true
		end
		wait(0.5)
	end

	warn("❌ MilkingDebug: Systems failed to load within " .. maxWait .. " seconds")
	return false
end

-- Debug remote events
local function DebugRemoteEvents()
	print("\n🔍 === REMOTE EVENTS DEBUG ===")

	local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not remoteFolder then
		warn("❌ GameRemotes folder not found!")
		return false
	end

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
		local event = remoteFolder:FindFirstChild(eventName)
		if event then
			print("✅ " .. eventName .. " - Found")
		else
			warn("❌ " .. eventName .. " - Missing")
		end
	end

	print("=========================\n")
	return true
end

-- Debug chairs
local function DebugChairs()
	print("\n🔍 === CHAIR DEBUG ===")

	local chairsFound = 0
	local chairName = "MilkingChair"

	-- Check workspace
	for _, obj in pairs(workspace:GetChildren()) do
		if obj.Name == chairName then
			chairsFound = chairsFound + 1
			print("✅ Found chair: " .. obj.Name .. " (Type: " .. obj.ClassName .. ")")

			-- Check for seat
			local seat = nil
			if obj:IsA("Seat") then
				seat = obj
			else
				for _, child in pairs(obj:GetDescendants()) do
					if child:IsA("Seat") then
						seat = child
						break
					end
				end
			end

			if seat then
				print("  ✅ Seat found: " .. seat.Name)
				print("  📍 Position: " .. tostring(seat.Position))
			else
				warn("  ❌ No seat found in chair!")
			end
		end
	end

	print("Total chairs found: " .. chairsFound)

	if chairsFound == 0 then
		warn("❌ No chairs found! Make sure your chair is named exactly '" .. chairName .. "'")
	end

	print("=====================\n")
end

-- Debug player cows
local function DebugPlayerCows(player)
	print("\n🔍 === COW DEBUG FOR " .. player.Name .. " ===")

	if not _G.GameCore then
		warn("❌ GameCore not available")
		return
	end

	local playerData = _G.GameCore:GetPlayerData(player)
	if not playerData then
		warn("❌ No player data found")
		return
	end

	print("✅ Player data found")

	-- Check livestock data
	if playerData.livestock and playerData.livestock.cows then
		local cowCount = 0
		print("🐄 Cows in player data:")
		for cowId, cowData in pairs(playerData.livestock.cows) do
			cowCount = cowCount + 1
			print("  " .. cowCount .. ". " .. cowId .. " (tier: " .. (cowData.tier or "unknown") .. ")")
		end
		print("Total cows: " .. cowCount)
	else
		warn("❌ No livestock.cows data found")
	end

	-- Check workspace cows
	print("🐄 Cows in workspace owned by " .. player.Name .. ":")
	local workspaceCows = 0
	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("Model") and (obj.Name == "cow" or obj.Name:find("cow_")) then
			local owner = obj:GetAttribute("Owner")
			if owner == player.Name then
				workspaceCows = workspaceCows + 1
				print("  " .. workspaceCows .. ". " .. obj.Name .. " at " .. tostring(obj:GetPivot().Position))
			end
		end
	end

	if workspaceCows == 0 then
		warn("❌ No cows found in workspace for " .. player.Name)
	end

	print("==============================\n")
end

-- Test milking system manually
local function TestMilkingSystem(player)
	print("\n🔍 === MILKING SYSTEM TEST FOR " .. player.Name .. " ===")

	if not _G.CowMilkingModule then
		warn("❌ CowMilkingModule not available")
		return
	end

	-- Find player's first cow
	local playerData = _G.GameCore and _G.GameCore:GetPlayerData(player)
	if not playerData or not playerData.livestock or not playerData.livestock.cows then
		warn("❌ Player has no cows to test with")
		return
	end

	local testCowId = nil
	for cowId, _ in pairs(playerData.livestock.cows) do
		testCowId = cowId
		break
	end

	if not testCowId then
		warn("❌ No cow ID found for testing")
		return
	end

	print("🧪 Testing milking session with cow: " .. testCowId)

	-- Test starting milking session
	local success = _G.CowMilkingModule:HandleStartMilkingSession(player, testCowId)
	print("Test result: " .. tostring(success))

	if success then
		print("✅ Milking session started successfully!")

		-- Wait a moment then test clicking
		wait(1)
		print("🧪 Testing milk collection...")
		local clickSuccess = _G.CowMilkingModule:HandleContinueMilking(player)
		print("Click test result: " .. tostring(clickSuccess))

		-- Stop the session
		wait(1)
		print("🧪 Testing session stop...")
		_G.CowMilkingModule:HandleStopMilkingSession(player)
		print("✅ Test complete!")
	else
		warn("❌ Failed to start milking session")
	end

	print("===================================\n")
end

-- Main debug function
local function RunFullDebug(player)
	print("\n🚀 === FULL MILKING SYSTEM DEBUG ===")
	print("Player: " .. player.Name)
	print("Time: " .. os.date())
	print("====================================")

	DebugRemoteEvents()
	DebugChairs()
	DebugPlayerCows(player)
	TestMilkingSystem(player)

	print("🏁 === DEBUG COMPLETE ===\n")
end

-- Wait for systems then setup debug commands
if WaitForSystems() then
	print("✅ MilkingDebug: Systems loaded, setting up debug commands...")

	-- Setup chat commands
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			local command = message:lower()

			if command == "/debugmilking" then
				RunFullDebug(player)
			elseif command == "/testremotes" then
				DebugRemoteEvents()
			elseif command == "/testchairs" then
				DebugChairs()
			elseif command == "/testcows" then
				DebugPlayerCows(player)
			elseif command == "/testmilking" then
				TestMilkingSystem(player)
			elseif command == "/givecow" then
				-- Force give a starter cow
				if _G.CowCreationModule and _G.CowCreationModule.ForceGiveStarterCow then
					local success = _G.CowCreationModule:ForceGiveStarterCow(player)
					print("Force starter cow result: " .. tostring(success))
				else
					warn("ForceGiveStarterCow not available")
				end
			elseif command == "/testgui" then
				-- Test sending GUI directly
				local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
				if remoteFolder and remoteFolder:FindFirstChild("ShowChairPrompt") then
					print("Testing GUI send to " .. player.Name)
					remoteFolder.ShowChairPrompt:FireClient(player, "milking", {
						title = "🧪 Test GUI",
						subtitle = "This is a test GUI",
						instruction = "If you see this, the GUI system works!"
					})
				else
					warn("ShowChairPrompt remote not found")
				end
			end
		end)
	end)

	-- Auto-debug for existing players
	for _, player in pairs(Players:GetPlayers()) do
		spawn(function()
			wait(2) -- Give time for player to load
			player.Chatted:Connect(function(message)
				local command = message:lower()

				if command == "/debugmilking" then
					RunFullDebug(player)
				elseif command == "/testremotes" then
					DebugRemoteEvents()
				elseif command == "/testchairs" then
					DebugChairs()
				elseif command == "/testcows" then
					DebugPlayerCows(player)
				elseif command == "/testmilking" then
					TestMilkingSystem(player)
				elseif command == "/givecow" then
					if _G.CowCreationModule and _G.CowCreationModule.ForceGiveStarterCow then
						local success = _G.CowCreationModule:ForceGiveStarterCow(player)
						print("Force starter cow result: " .. tostring(success))
					else
						warn("ForceGiveStarterCow not available")
					end
				elseif command == "/testgui" then
					local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
					if remoteFolder and remoteFolder:FindFirstChild("ShowChairPrompt") then
						print("Testing GUI send to " .. player.Name)
						remoteFolder.ShowChairPrompt:FireClient(player, "milking", {
							title = "🧪 Test GUI",
							subtitle = "This is a test GUI",
							instruction = "If you see this, the GUI system works!"
						})
					else
						warn("ShowChairPrompt remote not found")
					end
				end
			end)
		end)
	end

else
	warn("❌ MilkingDebug: Failed to initialize - systems not loaded")
end

print("🔧 MilkingSystemDebug loaded!")
print("💬 Available Commands:")
print("  /debugmilking - Run full system debug")
print("  /testremotes - Test remote events")
print("  /testchairs - Test chair detection")
print("  /testcows - Test cow detection")
print("  /testmilking - Test milking system")
print("  /testgui - Test GUI system")
print("  /givecow - Force give starter cow")