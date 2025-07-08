--[[
    AutomaticCowSystem.server.lua - Automatic Cow System Fixes for All Players
    Place in: ServerScriptService/AutomaticCowSystem.server.lua
    
    This script automatically fixes cow data/physical model sync issues for ALL players
    without requiring admin commands
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

print("🤖 AutomaticCowSystem: Starting automatic cow system management...")

-- ========== AUTOMATIC COW DATA SYNC ==========

local function autoSyncPlayerCows(player)
	if not _G.GameCore then return false end

	local playerData = _G.GameCore:GetPlayerData(player)
	if not playerData or not playerData.livestock or not playerData.livestock.cows then
		return false
	end

	-- Count cows in data
	local dataCowCount = 0
	local dataCows = {}
	for cowId, cowData in pairs(playerData.livestock.cows) do
		dataCowCount = dataCowCount + 1
		dataCows[cowId] = cowData
	end

	-- Count cows in workspace
	local workspaceCowCount = 0
	for _, obj in pairs(workspace:GetChildren()) do
		local owner = obj:GetAttribute("Owner")
		if owner == player.Name and (obj.Name:find("cow_") or obj.Name == "cow") then
			workspaceCowCount = workspaceCowCount + 1
		end
	end

	-- If player has data cows but no workspace cows, create them
	if dataCowCount > 0 and workspaceCowCount == 0 then
		print("🔧 Auto-fixing missing cows for " .. player.Name .. " (" .. dataCowCount .. " data cows, " .. workspaceCowCount .. " workspace cows)")

		local createdCount = 0
		for cowId, cowData in pairs(dataCows) do
			local success = createPhysicalCowForPlayer(player, cowId, cowData)
			if success then
				createdCount = createdCount + 1
			end
		end

		if createdCount > 0 then
			print("✅ Auto-created " .. createdCount .. " physical cows for " .. player.Name)

			-- Send notification to player
			if _G.GameCore and _G.GameCore.SendNotification then
				_G.GameCore:SendNotification(player, "🐄 Cows Restored", 
					"Your " .. createdCount .. " cow(s) have been restored!", "success")
			end

			return true
		end
	end

	return false
end

-- ========== CREATE PHYSICAL COW FOR PLAYER ==========

function createPhysicalCowForPlayer(player, cowId, cowData)
	-- Find the original cow template
	local originalCow = workspace:FindFirstChild("OriginalCow") or workspace:FindFirstChild("cow")
	if not originalCow then
		return false
	end

	local success, newCow = pcall(function()
		-- Clone the original cow
		local clonedCow = originalCow:Clone()
		clonedCow.Name = cowId

		-- Set position from data or spawn near player
		local position = cowData.position
		if not position then
			-- Default position or near player
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local playerPos = player.Character.HumanoidRootPart.Position
				position = playerPos + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
			else
				position = Vector3.new(-272, -2, 53) -- Default spawn
			end
		end

		-- Position the cow
		if clonedCow.PrimaryPart then
			clonedCow:PivotTo(CFrame.new(position))
		else
			-- Find main part and position it
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
		clonedCow:SetAttribute("AutoCreated", true)

		-- Remove template attributes
		clonedCow:SetAttribute("IsTemplate", nil)
		clonedCow:SetAttribute("OriginalCow", nil)
		clonedCow:SetAttribute("DoNotProcess", nil)

		-- Parent to workspace
		clonedCow.Parent = workspace

		return clonedCow
	end)

	if success and newCow then
		-- Register with CowCreationModule
		if _G.CowCreationModule and _G.CowCreationModule.ActiveCows then
			_G.CowCreationModule.ActiveCows[cowId] = newCow
		end

		-- Apply visual effects
		if _G.CowCreationModule and _G.CowCreationModule.ApplyTierEffects then
			pcall(function()
				_G.CowCreationModule:ApplyTierEffects(newCow, cowData.tier or "basic")
			end)
		end

		return true
	end

	return false
end

-- ========== AUTOMATIC STARTER COW SYSTEM ==========

local function ensurePlayerHasStarterCow(player)
	if not _G.GameCore then return false end

	local playerData = _G.GameCore:GetPlayerData(player)
	if not playerData then return false end

	-- Check if player has any cows
	local hasCowData = playerData.livestock and playerData.livestock.cows and next(playerData.livestock.cows) ~= nil
	local hasWorkspaceCows = false

	for _, obj in pairs(workspace:GetChildren()) do
		local owner = obj:GetAttribute("Owner")
		if owner == player.Name and (obj.Name:find("cow_") or obj.Name == "cow") then
			hasWorkspaceCows = true
			break
		end
	end

	-- If player has no cows at all, give starter cow
	if not hasCowData and not hasWorkspaceCows then
		print("🐄 Giving starter cow to new player: " .. player.Name)

		if _G.CowCreationModule and _G.CowCreationModule.ForceGiveStarterCow then
			local success = _G.CowCreationModule:ForceGiveStarterCow(player)
			if success then
				print("✅ Starter cow given to " .. player.Name)
				return true
			end
		end
	end

	return false
end

-- ========== PLAYER MONITORING ==========

local function monitorPlayer(player)
	spawn(function()
		-- Wait for player to load
		if not player.Character then
			player.CharacterAdded:Wait()
		end

		wait(3) -- Give systems time to load

		-- Check and fix cow system
		local autoFixed = autoSyncPlayerCows(player)
		if not autoFixed then
			-- If no auto-fix needed, ensure they have at least a starter cow
			ensurePlayerHasStarterCow(player)
		end

		-- Continue monitoring this player
		while Players:FindFirstChild(player.Name) do
			wait(60) -- Check every minute

			-- Auto-sync if needed
			autoSyncPlayerCows(player)

			-- Ensure they have cows
			ensurePlayerHasStarterCow(player)
		end
	end)
end

-- ========== SETUP PLAYER HANDLERS ==========

local function setupPlayerHandlers()
	-- Handle existing players
	for _, player in pairs(Players:GetPlayers()) do
		monitorPlayer(player)
	end

	-- Handle new players
	Players.PlayerAdded:Connect(function(player)
		print("👋 New player joined: " .. player.Name .. " - starting cow monitoring")
		monitorPlayer(player)
	end)

	print("✅ Player monitoring setup complete")
end

-- ========== PERIODIC SYSTEM CHECK ==========

local function startPeriodicSystemCheck()
	print("🔄 Starting periodic system check...")

	spawn(function()
		while true do
			wait(300) -- Check every 5 minutes

			print("🔍 Running periodic cow system check...")

			for _, player in pairs(Players:GetPlayers()) do
				if player.Character then
					-- Quick check and auto-fix
					local fixed = autoSyncPlayerCows(player)
					if fixed then
						print("🔧 Auto-fixed cow system for " .. player.Name)
					end
				end
			end
		end
	end)
end

-- ========== EMERGENCY AUTO-FIX ==========

local function emergencyAutoFix()
	print("🚨 Running emergency auto-fix for all players...")

	local fixedPlayers = 0

	for _, player in pairs(Players:GetPlayers()) do
		if player.Character then
			local fixed = autoSyncPlayerCows(player)
			if fixed then
				fixedPlayers = fixedPlayers + 1
			end
		end
	end

	print("✅ Emergency auto-fix complete - fixed " .. fixedPlayers .. " players")
	return fixedPlayers
end

-- ========== MAIN EXECUTION ==========

local function main()
	-- Setup automatic systems
	setupPlayerHandlers()
	startPeriodicSystemCheck()

	-- Run initial emergency fix
	wait(5) -- Give other systems time to load
	emergencyAutoFix()

	print("✅ AutomaticCowSystem: Fully operational!")
end

-- Execute
local success, error = pcall(main)

if not success then
	warn("❌ AutomaticCowSystem failed: " .. tostring(error))
else
	print("🎉 AutomaticCowSystem: Ready!")
	print("")
	print("🤖 AUTOMATIC FEATURES ACTIVE:")
	print("  ✅ Auto-detects missing physical cows")
	print("  ✅ Auto-creates cows from player data")
	print("  ✅ Auto-gives starter cows to new players")
	print("  ✅ Monitors all players continuously")
	print("  ✅ Runs periodic system checks")
	print("")
	print("👥 ALL PLAYERS now get automatic cow system fixes!")
end