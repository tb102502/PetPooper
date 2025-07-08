--[[
    CowDataSyncFix.server.lua - Sync Cow Data with Physical Models
    Place in: ServerScriptService/CowDataSyncFix.server.lua
    
    This script fixes the disconnect between cow data and physical cow models
]]

local Players = game:GetService("Players")

print("🔄 CowDataSyncFix: Starting cow data synchronization...")

-- ========== DATA VS WORKSPACE SYNC ==========

local function syncPlayerCows(player)
	print("\n🔄 Syncing cows for " .. player.Name .. "...")

	if not _G.GameCore then
		print("❌ GameCore not available")
		return false
	end

	local playerData = _G.GameCore:GetPlayerData(player)
	if not playerData or not playerData.livestock or not playerData.livestock.cows then
		print("❌ No cow data found for " .. player.Name)
		return false
	end

	-- Get cow data
	local dataCows = {}
	for cowId, cowData in pairs(playerData.livestock.cows) do
		table.insert(dataCows, {
			cowId = cowId,
			data = cowData
		})
	end

	print("📊 Found " .. #dataCows .. " cows in data:")
	for i, cow in ipairs(dataCows) do
		print("  " .. i .. ". " .. cow.cowId .. " (tier: " .. (cow.data.tier or "basic") .. ")")
	end

	-- Check workspace for matching cows
	local workspaceCows = {}
	for _, obj in pairs(workspace:GetChildren()) do
		local owner = obj:GetAttribute("Owner")
		local cowId = obj:GetAttribute("CowId") or obj.Name

		if owner == player.Name and (obj.Name == "cow" or obj.Name:find("cow_") or cowId:find("cow_")) then
			table.insert(workspaceCows, {
				model = obj,
				cowId = cowId,
				name = obj.Name
			})
		end
	end

	print("📊 Found " .. #workspaceCows .. " cows in workspace:")
	for i, cow in ipairs(workspaceCows) do
		print("  " .. i .. ". " .. cow.name .. " (ID: " .. cow.cowId .. ")")
	end

	-- Sync: Create missing physical cows
	local createdCows = 0
	for _, dataCow in ipairs(dataCows) do
		local foundInWorkspace = false

		for _, workspaceCow in ipairs(workspaceCows) do
			if workspaceCow.cowId == dataCow.cowId then
				foundInWorkspace = true
				print("✅ " .. dataCow.cowId .. " exists in both data and workspace")
				break
			end
		end

		if not foundInWorkspace then
			print("🔧 Creating missing physical cow: " .. dataCow.cowId)
			local success = createPhysicalCow(player, dataCow.cowId, dataCow.data)
			if success then
				createdCows = createdCows + 1
				print("✅ Created physical cow: " .. dataCow.cowId)
			else
				print("❌ Failed to create physical cow: " .. dataCow.cowId)
			end
		end
	end

	-- Clean up orphaned workspace cows (no matching data)
	local cleanedCows = 0
	for _, workspaceCow in ipairs(workspaceCows) do
		local foundInData = false

		for _, dataCow in ipairs(dataCows) do
			if dataCow.cowId == workspaceCow.cowId then
				foundInData = true
				break
			end
		end

		if not foundInData then
			print("🗑️ Removing orphaned workspace cow: " .. workspaceCow.name)
			workspaceCow.model:Destroy()
			cleanedCows = cleanedCows + 1
		end
	end

	print("✅ Sync complete - Created: " .. createdCows .. ", Cleaned: " .. cleanedCows)
	return true
end

-- ========== CREATE PHYSICAL COW ==========

function createPhysicalCow(player, cowId, cowData)
	print("🐄 Creating physical cow: " .. cowId)

	-- Find the original cow template
	local originalCow = workspace:FindFirstChild("OriginalCow") or workspace:FindFirstChild("cow")
	if not originalCow then
		print("❌ No original cow template found")
		return false
	end

	local success, newCow = pcall(function()
		-- Clone the original cow
		local clonedCow = originalCow:Clone()
		clonedCow.Name = cowId

		-- Set position from data or default
		local position = cowData.position or Vector3.new(-272, -2, 53)
		if clonedCow.PrimaryPart then
			clonedCow:PivotTo(CFrame.new(position))
		else
			-- Try to find a main part to position
			for _, part in pairs(clonedCow:GetChildren()) do
				if part:IsA("BasePart") then
					part.Position = position
					break
				end
			end
		end

		-- Set ownership attributes
		clonedCow:SetAttribute("CowId", cowId)
		clonedCow:SetAttribute("Owner", player.Name)
		clonedCow:SetAttribute("OwnerId", player.UserId)
		clonedCow:SetAttribute("Tier", cowData.tier or "basic")

		-- Remove template attributes if they exist
		clonedCow:SetAttribute("IsTemplate", nil)
		clonedCow:SetAttribute("OriginalCow", nil)
		clonedCow:SetAttribute("DoNotProcess", nil)

		-- Parent to workspace
		clonedCow.Parent = workspace

		return clonedCow
	end)

	if success and newCow then
		-- Register with CowCreationModule if available
		if _G.CowCreationModule and _G.CowCreationModule.ActiveCows then
			_G.CowCreationModule.ActiveCows[cowId] = newCow
			print("✅ Registered with CowCreationModule: " .. cowId)
		end

		-- Apply visual effects if needed
		if _G.CowCreationModule and _G.CowCreationModule.ApplyTierEffects then
			_G.CowCreationModule:ApplyTierEffects(newCow, cowData.tier or "basic")
		end

		print("✅ Successfully created physical cow: " .. cowId)
		return true
	else
		print("❌ Failed to create physical cow: " .. cowId)
		return false
	end
end

-- ========== CHAIR DETECTION FIX ==========

local function fixChairDetection()
	print("🪑 Fixing chair detection...")

	if not _G.CowMilkingModule then
		print("❌ CowMilkingModule not available")
		return false
	end

	-- Force rescan chairs
	if _G.CowMilkingModule.ForceRescanChairs then
		local chairCount = _G.CowMilkingModule:ForceRescanChairs()
		print("✅ Rescanned chairs - found: " .. chairCount)
		return chairCount > 0
	else
		print("❌ ForceRescanChairs not available")
		return false
	end
end

-- ========== PROXIMITY SYSTEM REFRESH ==========

local function refreshProximitySystem(player)
	print("📡 Refreshing proximity system for " .. player.Name .. "...")

	if _G.CowMilkingModule then
		-- Reset proximity state
		if _G.CowMilkingModule.ResetPlayerProximity then
			_G.CowMilkingModule:ResetPlayerProximity(player)
		end

		-- Force proximity update
		if _G.CowMilkingModule.UpdatePlayerProximityState then
			_G.CowMilkingModule:UpdatePlayerProximityState(player)
		end

		print("✅ Proximity system refreshed")
		return true
	else
		print("❌ CowMilkingModule not available for proximity refresh")
		return false
	end
end

-- ========== COMPLETE SYSTEM REPAIR ==========

local function completeSystemRepair(player)
	print("🔧 Running complete system repair for " .. player.Name .. "...")

	local results = {
		cowSync = false,
		chairFix = false,
		proximityRefresh = false
	}

	-- Step 1: Sync cow data with physical models
	results.cowSync = syncPlayerCows(player)

	-- Step 2: Fix chair detection
	results.chairFix = fixChairDetection()

	-- Step 3: Refresh proximity system
	wait(1) -- Give time for cows to load
	results.proximityRefresh = refreshProximitySystem(player)

	-- Step 4: Test proximity detection
	wait(2) -- Give time for systems to update
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and _G.CowMilkingModule then
		if _G.CowMilkingModule.GetVerifiedNearbyObjects then
			local nearbyObjects = _G.CowMilkingModule:GetVerifiedNearbyObjects(player, player.Character.HumanoidRootPart.Position)
			print("🧪 Test proximity result: " .. nearbyObjects.playerCowsNearby .. " cows, " .. nearbyObjects.milkingChairsNearby .. " chairs")
		end
	end

	print("✅ Complete system repair finished:")
	print("  Cow sync: " .. (results.cowSync and "✅" or "❌"))
	print("  Chair fix: " .. (results.chairFix and "✅" or "❌"))  
	print("  Proximity refresh: " .. (results.proximityRefresh and "✅" or "❌"))

	return results
end

-- ========== DEBUG COMMANDS ==========

local function setupSyncCommands()
	print("🔧 Setting up cow data sync commands...")

	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Change to your username
				local command = message:lower()

				if command == "/synccows" then
					print("🔄 Syncing cows for " .. player.Name .. "...")
					local success = syncPlayerCows(player)
					if success then
						print("✅ Cow sync complete")
					else
						print("❌ Cow sync failed")
					end

				elseif command == "/fixproximity" then
					print("📡 Fixing proximity detection for " .. player.Name .. "...")
					refreshProximitySystem(player)

				elseif command == "/fixchairs" then
					print("🪑 Fixing chair detection...")
					fixChairDetection()

				elseif command == "/fullrepair" then
					print("🔧 Running full system repair for " .. player.Name .. "...")
					completeSystemRepair(player)

				elseif command == "/testproximity" then
					print("🧪 Testing proximity detection for " .. player.Name .. "...")

					if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
						if _G.CowMilkingModule and _G.CowMilkingModule.GetVerifiedNearbyObjects then
							local nearbyObjects = _G.CowMilkingModule:GetVerifiedNearbyObjects(player, player.Character.HumanoidRootPart.Position)
							print("Current nearby: " .. nearbyObjects.playerCowsNearby .. " cows, " .. nearbyObjects.milkingChairsNearby .. " chairs")

							-- List the cows found
							for i, cow in ipairs(nearbyObjects.cows) do
								print("  Cow " .. i .. ": " .. cow.id .. " (can milk: " .. tostring(cow.canMilk) .. ")")
							end

							-- List the chairs found  
							for i, chair in ipairs(nearbyObjects.chairs) do
								print("  Chair " .. i .. ": " .. chair.id .. " (distance: " .. math.floor(chair.distance) .. ")")
							end
						else
							print("❌ CowMilkingModule.GetVerifiedNearbyObjects not available")
						end
					else
						print("❌ Player character not found")
					end

				elseif command == "/debugsync" then
					print("🔍 Debug sync status for " .. player.Name .. "...")

					-- Check player data
					if _G.GameCore then
						local playerData = _G.GameCore:GetPlayerData(player)
						if playerData and playerData.livestock and playerData.livestock.cows then
							local dataCount = 0
							for cowId, cowData in pairs(playerData.livestock.cows) do
								dataCount = dataCount + 1
								print("  Data cow " .. dataCount .. ": " .. cowId .. " (tier: " .. (cowData.tier or "basic") .. ")")
							end
						else
							print("❌ No cow data found")
						end
					end

					-- Check workspace
					local workspaceCount = 0
					for _, obj in pairs(workspace:GetChildren()) do
						local owner = obj:GetAttribute("Owner")
						if owner == player.Name and (obj.Name:find("cow_") or obj.Name == "cow") then
							workspaceCount = workspaceCount + 1
							print("  Workspace cow " .. workspaceCount .. ": " .. obj.Name .. " at " .. tostring(obj:GetPivot().Position))
						end
					end

					-- Check CowCreationModule
					if _G.CowCreationModule and _G.CowCreationModule.ActiveCows then
						local activeCount = 0
						for cowId, cowModel in pairs(_G.CowCreationModule.ActiveCows) do
							local owner = cowModel:GetAttribute("Owner")
							if owner == player.Name then
								activeCount = activeCount + 1
								print("  Active cow " .. activeCount .. ": " .. cowId)
							end
						end
					end

				elseif command == "/createcow" then
					print("🐄 Creating physical cow from data for " .. player.Name .. "...")

					if _G.GameCore then
						local playerData = _G.GameCore:GetPlayerData(player)
						if playerData and playerData.livestock and playerData.livestock.cows then
							-- Get first cow from data
							local firstCowId = nil
							local firstCowData = nil
							for cowId, cowData in pairs(playerData.livestock.cows) do
								firstCowId = cowId
								firstCowData = cowData
								break
							end

							if firstCowId then
								print("Creating physical cow: " .. firstCowId)
								local success = createPhysicalCow(player, firstCowId, firstCowData)
								if success then
									print("✅ Physical cow created successfully")
								else
									print("❌ Failed to create physical cow")
								end
							else
								print("❌ No cow data found to create from")
							end
						else
							print("❌ No cow data found")
						end
					else
						print("❌ GameCore not available")
					end
				end
			end
		end)
	end)

	print("✅ Cow data sync commands ready")
end

-- ========== MAIN EXECUTION ==========

local function main()
	setupSyncCommands()

	print("✅ CowDataSyncFix: Ready!")
end

-- Execute with delay
wait(2)

local success, error = pcall(main)

if not success then
	warn("❌ CowDataSyncFix failed: " .. tostring(error))
else
	print("🎉 CowDataSyncFix: Complete!")
	print("")
	print("🔄 COW DATA SYNC COMMANDS:")
	print("  /synccows - Sync cow data with physical models")
	print("  /fullrepair - Complete system repair ⭐ **RECOMMENDED**")
	print("  /fixproximity - Fix proximity detection")
	print("  /fixchairs - Fix chair detection")
	print("  /testproximity - Test current proximity detection")
	print("  /debugsync - Debug sync status")
	print("  /createcow - Create physical cow from data")
	print("")
	print("💡 TRY: /fullrepair to fix the 0 cows, 0 chairs issue!")
end