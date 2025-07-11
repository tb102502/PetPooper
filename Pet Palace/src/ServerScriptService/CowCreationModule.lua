--[[
    UPDATED CowCreationModule.lua - Auto-Assign Workspace Cow
    Place in: ServerScriptService/CowCreationModule.lua
    
    UPDATES:
    ✅ Automatically assigns workspace cow to joining players
    ✅ Ensures every player gets the cow for milking
    ✅ Better cow detection and setup
    ✅ Improved player assignment logic
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
	print("CowCreationModule: Initializing with workspace cow auto-assignment...")

	GameCore = gameCore
	ItemConfig = itemConfig

	-- Find and setup existing cows
	self:DetectExistingCows()

	-- Setup player handlers with auto-assignment
	self:SetupPlayerHandlers()

	-- Monitor for new cows that might be added
	self:StartCowMonitoring()

	print("CowCreationModule: Initialization complete!")
	return true
end

-- ========== ENHANCED COW DETECTION ==========

function CowCreationModule:DetectExistingCows()
	print("CowCreationModule: Detecting existing cows in workspace...")

	local cowsFound = 0

	-- Search workspace for cow models
	for _, obj in pairs(workspace:GetChildren()) do
		if self:IsCowModel(obj) then
			local cowId = self:SetupExistingCow(obj)
			if cowId then
				cowsFound = cowsFound + 1
				print("✅ Setup existing cow: " .. cowId .. " at " .. tostring(obj:GetPivot().Position))
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

	-- If we found cows, assign them to any existing players
	if cowsFound > 0 then
		for _, player in pairs(Players:GetPlayers()) do
			self:EnsurePlayerHasCow(player)
		end
	end
end

function CowCreationModule:IsCowModel(obj)
	-- Check if object is a cow model
	if not obj:IsA("Model") then
		return false
	end

	local name = obj.Name:lower()
	return name == "cow" or name:find("cow") or name:find("cattle") or name:find("milk")
end

function CowCreationModule:SetupExistingCow(cowModel)
	local cowId = self:GenerateCowId(cowModel)

	-- Store cow reference
	self.ActiveCows[cowId] = cowModel

	-- Set attributes for identification
	cowModel:SetAttribute("CowId", cowId)
	cowModel:SetAttribute("IsSetup", true)
	cowModel:SetAttribute("Tier", "basic")

	-- Default cow data for milking system
	cowModel:SetAttribute("MilkAmount", 1)
	cowModel:SetAttribute("Cooldown", 60)
	cowModel:SetAttribute("LastMilkCollection", 0)

	-- Add visual indicator (optional)
	if not cowModel:FindFirstChild("NameTag") then
		local nameTag = Instance.new("BillboardGui")
		nameTag.Name = "NameTag"
		nameTag.Size = UDim2.new(0, 100, 0, 30)
		nameTag.StudsOffset = Vector3.new(0, 3, 0)
		nameTag.Parent = cowModel

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, 0, 1, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = "🐄 Cow"
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextStrokeTransparency = 0
		nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		nameLabel.Parent = nameTag
	end

	print("CowCreationModule: Setup cow " .. cowId .. " at " .. tostring(cowModel:GetPivot().Position))
	return cowId
end

function CowCreationModule:GenerateCowId(cowModel)
	-- Generate unique ID for cow based on position
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

-- ========== ENHANCED PLAYER COW ASSIGNMENT ==========

function CowCreationModule:EnsurePlayerHasCow(player)
	print("CowCreationModule: Ensuring " .. player.Name .. " has a cow...")

	local userId = player.UserId

	-- Check if player already has a cow
	if self.PlayerCows[userId] and #self.PlayerCows[userId] > 0 then
		print("CowCreationModule: " .. player.Name .. " already has " .. #self.PlayerCows[userId] .. " cow(s)")
		return true
	end

	-- Find available cow or assign existing cow to this player
	local assignedCow = self:AssignAvailableCowToPlayer(player)

	if assignedCow then
		print("CowCreationModule: ✅ " .. player.Name .. " assigned cow: " .. assignedCow)
		return true
	else
		print("CowCreationModule: ⚠️ No cows available for " .. player.Name)
		return false
	end
end

function CowCreationModule:AssignAvailableCowToPlayer(player)
	-- Strategy: If there's only one cow, everyone can use it
	-- If multiple cows, assign unowned ones first, then allow sharing

	local availableCows = {}

	-- First, look for unowned cows
	for cowId, cowModel in pairs(self.ActiveCows) do
		if not self.CowOwnership[cowId] and cowModel.Parent then
			table.insert(availableCows, cowId)
		end
	end

	-- If no unowned cows, allow sharing (common for single cow setups)
	if #availableCows == 0 then
		for cowId, cowModel in pairs(self.ActiveCows) do
			if cowModel.Parent then
				table.insert(availableCows, cowId)
			end
		end
	end

	-- Assign the first available cow
	if #availableCows > 0 then
		local cowId = availableCows[1]
		self:AssignCowToPlayer(player, cowId)
		return cowId
	end

	return nil
end

function CowCreationModule:AssignCowToPlayer(player, cowId)
	local userId = player.UserId

	-- Initialize player cow list
	if not self.PlayerCows[userId] then
		self.PlayerCows[userId] = {}
	end

	-- Add cow to player's list (allow multiple players to share cows)
	table.insert(self.PlayerCows[userId], cowId)

	-- Set primary ownership (for display purposes)
	if not self.CowOwnership[cowId] then
		self.CowOwnership[cowId] = userId
	end

	-- Set model attributes
	local cowModel = self.ActiveCows[cowId]
	if cowModel then
		-- Update name tag to show assignment
		local nameTag = cowModel:FindFirstChild("NameTag")
		if nameTag and nameTag:FindFirstChild("TextLabel") then
			nameTag.TextLabel.Text = "🐄 " .. player.Name .. "'s Cow"
		end

		-- Set owner attribute (but allow sharing)
		cowModel:SetAttribute("PrimaryOwner", player.Name)
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

-- ========== ENHANCED PLAYER HANDLERS ==========

function CowCreationModule:SetupPlayerHandlers()
	print("CowCreationModule: Setting up enhanced player handlers...")

	Players.PlayerAdded:Connect(function(player)
		print("CowCreationModule: Player " .. player.Name .. " joined, assigning cow...")

		-- Wait a moment for other systems to initialize
		spawn(function()
			wait(2)
			self:EnsurePlayerHasCow(player)

			-- Send notification if cow assigned
			if GameCore and GameCore.SendNotification then
				GameCore:SendNotification(player, "🐄 Cow Assigned!", 
					"Your cow is ready for milking! Look for the MilkingChair nearby.", "success")
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		-- Clean up player cow assignments if they were the only owner
		local userId = player.UserId
		if self.PlayerCows[userId] then
			for _, cowId in ipairs(self.PlayerCows[userId]) do
				-- Only remove ownership if this player was the primary owner
				if self.CowOwnership[cowId] == userId then
					-- Check if any other players have this cow
					local hasOtherOwners = false
					for otherUserId, cowList in pairs(self.PlayerCows) do
						if otherUserId ~= userId then
							for _, otherCowId in ipairs(cowList) do
								if otherCowId == cowId then
									hasOtherOwners = true
									-- Transfer primary ownership
									self.CowOwnership[cowId] = otherUserId
									break
								end
							end
						end
						if hasOtherOwners then break end
					end

					-- If no other owners, remove ownership
					if not hasOtherOwners then
						self.CowOwnership[cowId] = nil
						local cowModel = self.ActiveCows[cowId]
						if cowModel then
							local nameTag = cowModel:FindFirstChild("NameTag")
							if nameTag and nameTag:FindFirstChild("TextLabel") then
								nameTag.TextLabel.Text = "🐄 Available Cow"
							end
						end
					end
				end
			end

			-- Clear player's cow list
			self.PlayerCows[userId] = nil
		end
	end)
end

-- ========== COW ACCESS METHODS ==========

function CowCreationModule:GetActiveCows()
	return self.ActiveCows
end

function CowCreationModule:GetCowModel(cowId)
	return self.ActiveCows[cowId]
end

function CowCreationModule:GetPlayerCows(player)
	local userId = player.UserId
	return self.PlayerCows[userId] or {}
end

function CowCreationModule:DoesPlayerOwnCow(player, cowId)
	-- Allow any player to use any cow (for shared cow setups)
	local userId = player.UserId
	if not self.PlayerCows[userId] then
		return false
	end

	for _, playerCowId in ipairs(self.PlayerCows[userId]) do
		if playerCowId == cowId then
			return true
		end
	end

	return false
end

function CowCreationModule:GetCowData(player, cowId)
	if not GameCore then return nil end

	local playerData = GameCore:GetPlayerData(player)
	if not playerData or not playerData.livestock or not playerData.livestock.cows then
		return nil
	end

	return playerData.livestock.cows[cowId]
end

-- ========== MONITORING AND MAINTENANCE ==========

function CowCreationModule:StartCowMonitoring()
	print("CowCreationModule: Starting enhanced cow monitoring...")

	spawn(function()
		while true do
			wait(10) -- Check every 10 seconds

			-- Check for new cows
			self:CheckForNewCows()

			-- Validate existing cows
			self:ValidateExistingCows()

			-- Ensure all players have cows
			for _, player in pairs(Players:GetPlayers()) do
				if not self.PlayerCows[player.UserId] or #self.PlayerCows[player.UserId] == 0 then
					print("CowCreationModule: Re-assigning cow to " .. player.Name)
					self:EnsurePlayerHasCow(player)
				end
			end
		end
	end)
end

function CowCreationModule:CheckForNewCows()
	for _, obj in pairs(workspace:GetChildren()) do
		if self:IsCowModel(obj) and not obj:GetAttribute("IsSetup") then
			print("CowCreationModule: Found new cow, setting up...")
			local cowId = self:SetupExistingCow(obj)
			if cowId then
				-- Assign to players who don't have cows
				for _, player in pairs(Players:GetPlayers()) do
					if not self.PlayerCows[player.UserId] or #self.PlayerCows[player.UserId] == 0 then
						self:AssignCowToPlayer(player, cowId)
					end
				end
			end
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

	-- Remove from all players' cow lists
	for playerUserId, cowList in pairs(self.PlayerCows) do
		for i, playerCowId in ipairs(cowList) do
			if playerCowId == cowId then
				table.remove(cowList, i)
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

-- ========== MANUAL ASSIGNMENT METHODS ==========

function CowCreationModule:ForceAssignCowToPlayer(player, cowId)
	-- Force assign a specific cow to a player (for testing/admin use)
	if self.ActiveCows[cowId] then
		self:AssignCowToPlayer(player, cowId)
		return true
	end
	return false
end

function CowCreationModule:ReassignAllCows()
	-- Reassign all cows to current players (for admin use)
	local allPlayers = Players:GetPlayers()
	local allCows = {}

	for cowId, _ in pairs(self.ActiveCows) do
		table.insert(allCows, cowId)
	end

	-- Clear existing assignments
	self.PlayerCows = {}
	self.CowOwnership = {}

	-- Reassign
	for i, player in ipairs(allPlayers) do
		local cowIndex = ((i - 1) % #allCows) + 1
		local cowId = allCows[cowIndex]
		self:AssignCowToPlayer(player, cowId)
	end

	print("CowCreationModule: Reassigned all cows to current players")
end

-- ========== DEBUG FUNCTIONS ==========

function CowCreationModule:DebugStatus()
	print("=== ENHANCED COW CREATION DEBUG ===")
	print("Active cows: " .. self:CountTable(self.ActiveCows))
	print("Players with cows: " .. self:CountTable(self.PlayerCows))
	print("Ownership mappings: " .. self:CountTable(self.CowOwnership))

	print("\nCow details:")
	for cowId, cowModel in pairs(self.ActiveCows) do
		local primaryOwner = cowModel:GetAttribute("PrimaryOwner") or "Unowned"
		local position = cowModel:GetPivot().Position
		print("  " .. cowId .. " - Primary: " .. primaryOwner .. " - Pos: " .. tostring(position))
	end

	print("\nPlayer cow assignments:")
	for userId, cowList in pairs(self.PlayerCows) do
		local player = Players:GetPlayerByUserId(userId)
		local playerName = player and player.Name or "Unknown"
		print("  " .. playerName .. " (" .. userId .. "): " .. #cowList .. " cows")
		for _, cowId in ipairs(cowList) do
			print("    - " .. cowId)
		end
	end

	print("=====================================")
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

-- Enhanced debug functions
_G.DebugCowCreation = function()
	CowCreationModule:DebugStatus()
end

_G.ReassignAllCows = function()
	CowCreationModule:ReassignAllCows()
end

_G.EnsureAllPlayersHaveCows = function()
	for _, player in pairs(Players:GetPlayers()) do
		CowCreationModule:EnsurePlayerHasCow(player)
	end
	print("✅ Ensured all players have cows")
end

print("CowCreationModule: ✅ ENHANCED MODULE LOADED!")
print("🐄 NEW FEATURES:")
print("  🎯 Auto-assigns workspace cow to joining players")
print("  🔄 Shared cow system (multiple players can use same cow)")
print("  📍 Visual name tags show cow ownership")
print("  🔧 Enhanced monitoring and reassignment")
print("  📊 Better debugging and admin tools")
print("")
print("🔧 Debug Commands:")
print("  _G.DebugCowCreation() - Show cow system status")
print("  _G.ReassignAllCows() - Reassign all cows to players")
print("  _G.EnsureAllPlayersHaveCows() - Make sure everyone has a cow")

return CowCreationModule