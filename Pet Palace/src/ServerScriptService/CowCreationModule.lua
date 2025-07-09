--[[
    FIXED CowCreationModule.lua - Works with Existing Cow Models
    Place in: ServerScriptService/CowCreationModule.lua
    
    FIXES:
    ✅ Works with existing cow models in workspace
    ✅ No cow creation - only detection and setup
    ✅ Proper GetActiveCows method
    ✅ Player cow ownership system
    ✅ Integration with milking system
]]

local CowCreationModule = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Module State
CowCreationModule.ActiveCows = {} -- [cowId] = cowModel
CowCreationModule.PlayerCows = {} -- [userId] = {cowId1, cowId2, ...}
CowCreationModule.CowOwnership = {} -- [cowId] = userId

-- References
local GameCore = nil
local ItemConfig = nil

-- ========== INITIALIZATION ==========

function CowCreationModule:Initialize(gameCore, itemConfig)
	print("CowCreationModule: Initializing with existing cow detection...")

	GameCore = gameCore
	ItemConfig = itemConfig

	-- Find and setup existing cows
	self:DetectExistingCows()

	-- Setup player handlers
	self:SetupPlayerHandlers()

	-- Monitor for new cows that might be added
	self:StartCowMonitoring()

	print("CowCreationModule: Initialization complete!")
	return true
end

-- ========== COW DETECTION ==========

function CowCreationModule:DetectExistingCows()
	print("CowCreationModule: Detecting existing cows in workspace...")

	local cowsFound = 0

	-- Search workspace for cow models
	for _, obj in pairs(workspace:GetChildren()) do
		if self:IsCowModel(obj) then
			local cowId = self:SetupExistingCow(obj)
			if cowId then
				cowsFound = cowsFound + 1
				print("✅ Setup existing cow: " .. cowId)
			end
		end
	end

	-- Also search in folders
	for _, folder in pairs(workspace:GetChildren()) do
		if folder:IsA("Folder") or folder:IsA("Model") then
			for _, obj in pairs(folder:GetChildren()) do
				if self:IsCowModel(obj) then
					local cowId = self:SetupExistingCow(obj)
					if cowId then
						cowsFound = cowsFound + 1
						print("✅ Setup existing cow in folder: " .. cowId)
					end
				end
			end
		end
	end

	print("CowCreationModule: Found and setup " .. cowsFound .. " existing cows")
end

function CowCreationModule:IsCowModel(obj)
	-- Check if object is a cow model
	if not obj:IsA("Model") then
		return false
	end

	local name = obj.Name:lower()
	return name == "cow" or name:find("cow") or name:find("cattle")
end

function CowCreationModule:SetupExistingCow(cowModel)
	local cowId = self:GenerateCowId(cowModel)

	-- Store cow reference
	self.ActiveCows[cowId] = cowModel

	-- Set attributes
	cowModel:SetAttribute("CowId", cowId)
	cowModel:SetAttribute("IsSetup", true)
	cowModel:SetAttribute("Tier", "basic")

	-- Default cow data
	cowModel:SetAttribute("MilkAmount", 1)
	cowModel:SetAttribute("Cooldown", 60)
	cowModel:SetAttribute("LastMilkCollection", 0)

	print("CowCreationModule: Setup cow " .. cowId .. " at " .. tostring(cowModel:GetPivot().Position))

	return cowId
end

function CowCreationModule:GenerateCowId(cowModel)
	-- Generate unique ID for cow
	local position = cowModel:GetPivot().Position
	local baseId = "cow_" .. math.floor(position.X) .. "_" .. math.floor(position.Z)

	-- Ensure uniqueness
	local counter = 1
	local cowId = baseId
	while self.ActiveCows[cowId] do
		cowId = baseId .. "_" .. counter
		counter = counter + 1
	end

	return cowId
end

-- ========== COW OWNERSHIP ==========

function CowCreationModule:AssignCowToPlayer(player, cowId)
	local userId = player.UserId

	-- Initialize player cow list
	if not self.PlayerCows[userId] then
		self.PlayerCows[userId] = {}
	end

	-- Add cow to player's list
	table.insert(self.PlayerCows[userId], cowId)
	self.CowOwnership[cowId] = userId

	-- Set model attribute
	local cowModel = self.ActiveCows[cowId]
	if cowModel then
		cowModel:SetAttribute("Owner", player.Name)
		cowModel:SetAttribute("OwnerUserId", userId)
	end

	-- Update player data
	if GameCore then
		local playerData = GameCore:GetPlayerData(player)
		if playerData then
			if not playerData.livestock then
				playerData.livestock = {cows = {}}
			end
			if not playerData.livestock.cows then
				playerData.livestock.cows = {}
			end

			-- Add cow data
			playerData.livestock.cows[cowId] = {
				tier = "basic",
				milkAmount = 1,
				cooldown = 60,
				lastMilkCollection = 0,
				totalMilkProduced = 0
			}

			GameCore:SavePlayerData(player)
		end
	end

	print("CowCreationModule: Assigned cow " .. cowId .. " to " .. player.Name)
	return true
end

function CowCreationModule:GiveStarterCow(player)
	print("CowCreationModule: Giving starter cow to " .. player.Name)

	-- Check if player already has cows
	local userId = player.UserId
	if self.PlayerCows[userId] and #self.PlayerCows[userId] > 0 then
		print("CowCreationModule: Player " .. player.Name .. " already has cows")
		return false
	end

	-- Find an unowned cow
	local availableCow = self:FindUnownedCow()
	if availableCow then
		self:AssignCowToPlayer(player, availableCow)

		if GameCore then
			GameCore:SendNotification(player, "🐄 Starter Cow!", 
				"You've been given a cow! Find it near the milking area.", "success")
		end

		return true
	else
		print("CowCreationModule: No available cows for " .. player.Name)
		return false
	end
end

function CowCreationModule:ForceGiveStarterCow(player)
	-- Force give a cow even if player has one
	local availableCow = self:FindUnownedCow()
	if availableCow then
		self:AssignCowToPlayer(player, availableCow)
		return true
	end
	return false
end

function CowCreationModule:FindUnownedCow()
	-- Find a cow that doesn't belong to anyone
	for cowId, cowModel in pairs(self.ActiveCows) do
		if not self.CowOwnership[cowId] then
			return cowId
		end
	end
	return nil
end

-- ========== COW DATA MANAGEMENT ==========

function CowCreationModule:GetActiveCows()
	return self.ActiveCows
end

function CowCreationModule:GetCowModel(cowId)
	return self.ActiveCows[cowId]
end

function CowCreationModule:GetCowData(player, cowId)
	if not GameCore then return nil end

	local playerData = GameCore:GetPlayerData(player)
	if not playerData or not playerData.livestock or not playerData.livestock.cows then
		return nil
	end

	return playerData.livestock.cows[cowId]
end

function CowCreationModule:GetPlayerCows(player)
	local userId = player.UserId
	return self.PlayerCows[userId] or {}
end

function CowCreationModule:GetCowOwner(cowId)
	local userId = self.CowOwnership[cowId]
	if userId then
		return Players:GetPlayerByUserId(userId)
	end
	return nil
end

function CowCreationModule:DoesPlayerOwnCow(player, cowId)
	return self.CowOwnership[cowId] == player.UserId
end

-- ========== COW MONITORING ==========

function CowCreationModule:StartCowMonitoring()
	print("CowCreationModule: Starting cow monitoring...")

	spawn(function()
		while true do
			wait(10) -- Check every 10 seconds

			-- Check for new cows
			self:CheckForNewCows()

			-- Validate existing cows
			self:ValidateExistingCows()
		end
	end)
end

function CowCreationModule:CheckForNewCows()
	for _, obj in pairs(workspace:GetChildren()) do
		if self:IsCowModel(obj) and not obj:GetAttribute("IsSetup") then
			print("CowCreationModule: Found new cow, setting up...")
			self:SetupExistingCow(obj)
		end
	end
end

function CowCreationModule:ValidateExistingCows()
	local toRemove = {}

	for cowId, cowModel in pairs(self.ActiveCows) do
		if not cowModel or not cowModel.Parent or not cowModel:IsDescendantOf(workspace) then
			table.insert(toRemove, cowId)
		end
	end

	-- Clean up removed cows
	for _, cowId in ipairs(toRemove) do
		self:CleanupCow(cowId)
	end
end

function CowCreationModule:CleanupCow(cowId)
	print("CowCreationModule: Cleaning up cow " .. cowId)

	-- Remove from active cows
	self.ActiveCows[cowId] = nil

	-- Remove from ownership
	local userId = self.CowOwnership[cowId]
	self.CowOwnership[cowId] = nil

	-- Remove from player's cow list
	if userId and self.PlayerCows[userId] then
		for i, playerCowId in ipairs(self.PlayerCows[userId]) do
			if playerCowId == cowId then
				table.remove(self.PlayerCows[userId], i)
				break
			end
		end
	end

	-- Update player data
	if userId then
		local player = Players:GetPlayerByUserId(userId)
		if player and GameCore then
			local playerData = GameCore:GetPlayerData(player)
			if playerData and playerData.livestock and playerData.livestock.cows then
				playerData.livestock.cows[cowId] = nil
				GameCore:SavePlayerData(player)
			end
		end
	end
end

-- ========== PLAYER HANDLERS ==========

function CowCreationModule:SetupPlayerHandlers()
	print("CowCreationModule: Setting up player handlers...")

	Players.PlayerAdded:Connect(function(player)
		-- Give starter cow after delay
		spawn(function()
			wait(5)
			self:GiveStarterCow(player)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		-- Could implement cow cleanup here if needed
		-- For now, leave cows in world for other players
	end)
end

-- ========== UTILITY FUNCTIONS ==========

function CowCreationModule:CountPlayerCows(player)
	local userId = player.UserId
	return self.PlayerCows[userId] and #self.PlayerCows[userId] or 0
end

function CowCreationModule:GetCowPosition(cowId)
	local cowModel = self.ActiveCows[cowId]
	if cowModel then
		return cowModel:GetPivot().Position
	end
	return nil
end

function CowCreationModule:FindNearestPlayerCow(player, position, maxDistance)
	maxDistance = maxDistance or 50
	local userId = player.UserId
	local playerCows = self.PlayerCows[userId] or {}

	local nearestCow = nil
	local nearestDistance = math.huge

	for _, cowId in ipairs(playerCows) do
		local cowModel = self.ActiveCows[cowId]
		if cowModel then
			local cowPosition = cowModel:GetPivot().Position
			local distance = (position - cowPosition).Magnitude

			if distance < nearestDistance and distance <= maxDistance then
				nearestDistance = distance
				nearestCow = cowId
			end
		end
	end

	return nearestCow, nearestDistance
end

-- ========== DEBUG FUNCTIONS ==========

function CowCreationModule:DebugStatus()
	print("=== COW CREATION MODULE DEBUG ===")
	print("Active cows: " .. self:CountTable(self.ActiveCows))
	print("Players with cows: " .. self:CountTable(self.PlayerCows))
	print("Ownership mappings: " .. self:CountTable(self.CowOwnership))

	print("\nCow details:")
	for cowId, cowModel in pairs(self.ActiveCows) do
		local owner = cowModel:GetAttribute("Owner") or "Unowned"
		local position = cowModel:GetPivot().Position
		print("  " .. cowId .. " - Owner: " .. owner .. " - Pos: " .. tostring(position))
	end

	print("\nPlayer cow ownership:")
	for userId, cowList in pairs(self.PlayerCows) do
		local player = Players:GetPlayerByUserId(userId)
		local playerName = player and player.Name or "Unknown"
		print("  " .. playerName .. " (" .. userId .. "): " .. #cowList .. " cows")
		for _, cowId in ipairs(cowList) do
			print("    - " .. cowId)
		end
	end

	print("==================================")
end

function CowCreationModule:CountTable(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- ========== GLOBAL ACCESS ==========

_G.CowCreationModule = CowCreationModule

-- Make debug function global
_G.DebugCowCreation = function()
	CowCreationModule:DebugStatus()
end

print("CowCreationModule: ✅ FIXED MODULE LOADED!")
print("🐄 FEATURES:")
print("  📍 Detects existing cow models in workspace")
print("  👤 Player cow ownership system")
print("  🔄 Real-time cow monitoring")
print("  🎁 Starter cow assignment")
print("  📊 Comprehensive cow data management")
print("")
print("🔧 Debug Commands:")
print("  _G.DebugCowCreation() - Show cow system status")

return CowCreationModule