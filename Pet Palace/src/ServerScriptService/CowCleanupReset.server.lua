--[[
    CowCleanupReset.server.lua - Remove Duplicate Cows and Reset System
    Place in: ServerScriptService/CowCleanupReset.server.lua
    
    This script helps remove duplicate cows and reset the cow system properly
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🐄 CowCleanupReset: Starting cow cleanup system...")

-- ========== COW ANALYSIS ==========

local function analyzeCowsForPlayer(player)
	print("\n🔍 Analyzing cows for " .. player.Name .. "...")

	local workspaceCows = {}
	local dataCows = {}

	-- Find cows in workspace
	for _, obj in pairs(workspace:GetChildren()) do
		local isCow = (obj.Name == "cow" or obj.Name:find("cow_"))
		local owner = obj:GetAttribute("Owner")

		if isCow and owner == player.Name then
			table.insert(workspaceCows, {
				model = obj,
				name = obj.Name,
				position = obj:GetPivot().Position,
				cowId = obj:GetAttribute("CowId") or obj.Name,
				tier = obj:GetAttribute("Tier") or "basic"
			})
		end
	end

	-- Find cows in player data
	if _G.GameCore then
		local playerData = _G.GameCore:GetPlayerData(player)
		if playerData and playerData.livestock and playerData.livestock.cows then
			for cowId, cowData in pairs(playerData.livestock.cows) do
				table.insert(dataCows, {
					cowId = cowId,
					tier = cowData.tier or "basic",
					position = cowData.position or Vector3.new(0, 0, 0),
					milkProduced = cowData.totalMilkProduced or 0,
					purchaseTime = cowData.purchaseTime or 0,
					isStarterCow = cowData.isStarterCow or false
				})
			end
		end
	end

	print("📊 Results for " .. player.Name .. ":")
	print("  Workspace cows: " .. #workspaceCows)
	print("  Data cows: " .. #dataCows)

	-- List workspace cows
	for i, cow in ipairs(workspaceCows) do
		print("  Workspace " .. i .. ": " .. cow.name .. " (ID: " .. cow.cowId .. ", Tier: " .. cow.tier .. ")")
		print("    Position: " .. tostring(cow.position))
	end

	-- List data cows
	for i, cow in ipairs(dataCows) do
		print("  Data " .. i .. ": " .. cow.cowId .. " (Tier: " .. cow.tier .. ", Starter: " .. tostring(cow.isStarterCow) .. ")")
		print("    Milk produced: " .. cow.milkProduced .. ", Purchase time: " .. cow.purchaseTime)
	end

	return workspaceCows, dataCows
end

-- ========== COW REMOVAL ==========

local function removeAllCowsForPlayer(player)
	print("🗑️ Removing ALL cows for " .. player.Name .. "...")

	local removedWorkspace = 0
	local removedData = 0

	-- Remove from workspace
	for _, obj in pairs(workspace:GetChildren()) do
		local isCow = (obj.Name == "cow" or obj.Name:find("cow_"))
		local owner = obj:GetAttribute("Owner")

		if isCow and owner == player.Name then
			print("  Removing workspace cow: " .. obj.Name)
			obj:Destroy()
			removedWorkspace = removedWorkspace + 1
		end
	end

	-- Remove from player data
	if _G.GameCore then
		local playerData = _G.GameCore:GetPlayerData(player)
		if playerData and playerData.livestock and playerData.livestock.cows then
			for cowId, cowData in pairs(playerData.livestock.cows) do
				print("  Removing data cow: " .. cowId)
				removedData = removedData + 1
			end
			playerData.livestock.cows = {}

			-- Reset starter cow flag
			playerData.receivedStarterCow = false

			-- Save data
			if _G.GameCore.SavePlayerData then
				_G.GameCore:SavePlayerData(player)
			end
		end
	end

	-- Clean up from cow creation module
	if _G.CowCreationModule and _G.CowCreationModule.ActiveCows then
		for cowId, cowModel in pairs(_G.CowCreationModule.ActiveCows) do
			local owner = cowModel:GetAttribute("Owner")
			if owner == player.Name then
				print("  Removing from ActiveCows: " .. cowId)
				_G.CowCreationModule.ActiveCows[cowId] = nil
			end
		end
	end

	print("✅ Removed " .. removedWorkspace .. " workspace cows and " .. removedData .. " data cows")
	return removedWorkspace + removedData
end

-- ========== SMART COW CLEANUP ==========

local function smartCleanupCowsForPlayer(player)
	print("🧠 Smart cleanup for " .. player.Name .. " (keeping best cow)...")

	local workspaceCows, dataCows = analyzeCowsForPlayer(player)

	if #workspaceCows <= 1 and #dataCows <= 1 then
		print("✅ Player only has " .. #workspaceCows .. " workspace cow(s) and " .. #dataCows .. " data cow(s) - no cleanup needed")
		return 0
	end

	-- Find the best cow to keep (highest tier, most milk produced, etc.)
	local bestCow = nil
	local bestScore = -1

	-- Evaluate workspace cows
	for _, cow in ipairs(workspaceCows) do
		local score = 0

		-- Score by tier
		local tierScores = {basic = 1, silver = 2, gold = 3, diamond = 4, rainbow = 5, cosmic = 6}
		score = score + (tierScores[cow.tier] or 1) * 10

		-- Find corresponding data cow
		local correspondingData = nil
		for _, dataCow in ipairs(dataCows) do
			if dataCow.cowId == cow.cowId then
				correspondingData = dataCow
				break
			end
		end

		if correspondingData then
			-- Score by milk produced
			score = score + correspondingData.milkProduced * 0.1

			-- Bonus for older cows (established)
			local age = os.time() - correspondingData.purchaseTime
			score = score + math.min(age / 3600, 24) -- Max 24 hour bonus

			print("  Cow " .. cow.name .. " score: " .. score .. " (tier: " .. cow.tier .. ", milk: " .. correspondingData.milkProduced .. ")")
		else
			print("  Cow " .. cow.name .. " score: " .. score .. " (no data found)")
		end

		if score > bestScore then
			bestScore = score
			bestCow = cow
		end
	end

	if not bestCow then
		print("⚠️ No best cow found, removing all cows")
		return removeAllCowsForPlayer(player)
	end

	print("🏆 Best cow: " .. bestCow.name .. " (score: " .. bestScore .. ")")

	-- Remove all other cows
	local removed = 0

	-- Remove other workspace cows
	for _, cow in ipairs(workspaceCows) do
		if cow.model ~= bestCow.model then
			print("  Removing duplicate workspace cow: " .. cow.name)
			cow.model:Destroy()
			removed = removed + 1
		end
	end

	-- Clean up data cows (keep only the best one's data)
	if _G.GameCore then
		local playerData = _G.GameCore:GetPlayerData(player)
		if playerData and playerData.livestock and playerData.livestock.cows then
			local newCowData = {}

			-- Keep only the best cow's data
			local bestCowData = playerData.livestock.cows[bestCow.cowId]
			if bestCowData then
				newCowData[bestCow.cowId] = bestCowData
				print("  Kept data for: " .. bestCow.cowId)
			else
				-- Create data for best cow if missing
				newCowData[bestCow.cowId] = {
					cowId = bestCow.cowId,
					tier = bestCow.tier,
					milkAmount = 1,
					cooldown = 60,
					position = bestCow.position,
					lastMilkCollection = 0,
					totalMilkProduced = 0,
					purchaseTime = os.time(),
					visualEffects = {},
					cleanupRepair = true
				}
				print("  Created new data for: " .. bestCow.cowId)
			end

			-- Count removed data cows
			for cowId, _ in pairs(playerData.livestock.cows) do
				if cowId ~= bestCow.cowId then
					removed = removed + 1
				end
			end

			playerData.livestock.cows = newCowData

			-- Save data
			if _G.GameCore.SavePlayerData then
				_G.GameCore:SavePlayerData(player)
			end
		end
	end

	-- Clean up cow creation module
	if _G.CowCreationModule and _G.CowCreationModule.ActiveCows then
		for cowId, cowModel in pairs(_G.CowCreationModule.ActiveCows) do
			local owner = cowModel:GetAttribute("Owner")
			if owner == player.Name and cowId ~= bestCow.cowId then
				print("  Removing from ActiveCows: " .. cowId)
				_G.CowCreationModule.ActiveCows[cowId] = nil
			end
		end
	end

	print("✅ Smart cleanup complete - removed " .. removed .. " duplicate cows, kept " .. bestCow.name)
	return removed
end

-- ========== FRESH COW RESET ==========

local function freshCowReset(player)
	print("🔄 Fresh cow reset for " .. player.Name .. "...")

	-- Remove all cows
	local removed = removeAllCowsForPlayer(player)

	-- Wait a moment
	wait(1)

	-- Give fresh starter cow
	if _G.CowCreationModule and _G.CowCreationModule.ForceGiveStarterCow then
		local success = _G.CowCreationModule:ForceGiveStarterCow(player)
		if success then
			print("✅ Fresh starter cow given to " .. player.Name)
			return true
		else
			print("❌ Failed to give fresh starter cow to " .. player.Name)
			return false
		end
	else
		print("❌ CowCreationModule not available for fresh cow")
		return false
	end
end

-- ========== DEBUG COMMANDS ==========

local function setupCleanupCommands()
	print("🔧 Setting up cow cleanup commands...")

	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Change to your username
				local command = message:lower()

				if command == "/analyzecows" then
					analyzeCowsForPlayer(player)

				elseif command == "/smartcleanup" then
					print("🧠 Running smart cleanup for " .. player.Name .. "...")
					local removed = smartCleanupCowsForPlayer(player)
					print("✅ Smart cleanup complete - removed " .. removed .. " duplicates")

				elseif command == "/removeallcows" then
					print("🗑️ Removing ALL cows for " .. player.Name .. "...")
					local removed = removeAllCowsForPlayer(player)
					print("✅ Removed " .. removed .. " cows")

				elseif command == "/freshcow" then
					print("🔄 Fresh cow reset for " .. player.Name .. "...")
					local success = freshCowReset(player)
					if success then
						print("✅ Fresh cow reset complete")
					else
						print("❌ Fresh cow reset failed")
					end

				elseif command == "/cowstatus" then
					print("📊 Cow status for " .. player.Name .. ":")
					local workspaceCows, dataCows = analyzeCowsForPlayer(player)

					-- Check milking system
					if _G.CowMilkingModule then
						if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
							local nearbyObjects = _G.CowMilkingModule:GetVerifiedNearbyObjects(player, player.Character.HumanoidRootPart.Position)
							print("Current nearby: " .. nearbyObjects.playerCowsNearby .. " cows, " .. nearbyObjects.milkingChairsNearby .. " chairs")
						end
					end

					-- Check active cows
					if _G.CowCreationModule and _G.CowCreationModule.ActiveCows then
						local activeCowCount = 0
						for cowId, cowModel in pairs(_G.CowCreationModule.ActiveCows) do
							local owner = cowModel:GetAttribute("Owner")
							if owner == player.Name then
								activeCowCount = activeCowCount + 1
								print("  Active cow: " .. cowId)
							end
						end
						print("Active cows in CowCreationModule: " .. activeCowCount)
					end

				elseif command == "/fixcowsystem" then
					print("🔧 Fixing cow system for " .. player.Name .. "...")

					-- Reset proximity state
					if _G.CowMilkingModule and _G.CowMilkingModule.ResetPlayerProximity then
						_G.CowMilkingModule:ResetPlayerProximity(player)
					end

					-- Smart cleanup
					local removed = smartCleanupCowsForPlayer(player)

					-- Refresh cow creation system
					if _G.CowCreationModule and _G.CowCreationModule.MonitorCows then
						_G.CowCreationModule:MonitorCows()
					end

					print("✅ Cow system fix complete - removed " .. removed .. " duplicates")
				end
			end
		end)
	end)

	print("✅ Cow cleanup commands ready")
end

-- ========== AUTOMATIC DUPLICATE DETECTION ==========

local function startDuplicateMonitoring()
	print("👁️ Starting duplicate cow monitoring...")

	spawn(function()
		while true do
			wait(30) -- Check every 30 seconds

			for _, player in pairs(Players:GetPlayers()) do
				if player.Character then
					local workspaceCows, dataCows = analyzeCowsForPlayer(player)

					-- If player has more than 1 cow, warn about it
					if #workspaceCows > 1 then
						print("⚠️ " .. player.Name .. " has " .. #workspaceCows .. " cows in workspace!")

						-- Auto-notify the player
						if _G.GameCore and _G.GameCore.SendNotification then
							_G.GameCore:SendNotification(player, "🐄 Multiple Cows Detected", 
								"You have " .. #workspaceCows .. " cows. Use /smartcleanup to fix duplicates.", "warning")
						end
					end
				end
			end
		end
	end)
end

-- ========== MAIN EXECUTION ==========

local function main()
	setupCleanupCommands()
	startDuplicateMonitoring()

	print("✅ CowCleanupReset: Ready!")
end

-- Execute
local success, error = pcall(main)

if not success then
	warn("❌ CowCleanupReset failed: " .. tostring(error))
else
	print("🎉 CowCleanupReset: Complete!")
	print("")
	print("🐄 COW CLEANUP COMMANDS:")
	print("  /analyzecows - Analyze all your cows")
	print("  /smartcleanup - Remove duplicates (keeps best cow)")
	print("  /removeallcows - Remove ALL cows")
	print("  /freshcow - Complete reset with new starter cow")
	print("  /cowstatus - Check current cow status")
	print("  /fixcowsystem - Fix cow system and remove duplicates")
	print("")
	print("💡 RECOMMENDED: Use /smartcleanup to keep your best cow and remove duplicates!")
end