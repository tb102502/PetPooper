--[[
    FIXED Enhanced Cow Milk System - Proper GameCore Integration
    Place as: ServerScriptService/EnhancedCowMilkSystem.server.lua
    
    FIXES:
    ✅ Proper integration with GameCore cow methods
    ✅ Uses GameCore:GetCowConfiguration correctly
    ✅ Coordinates with GameCore:PurchaseCow
    ✅ Enhanced visual effects integration
    ✅ Better error handling and debugging
]]

local EnhancedCowMilkSystem = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- System Configuration
EnhancedCowMilkSystem.Config = {
	AUTO_MILK_INTERVAL = 5, -- Check every 5 seconds
	MILK_INDICATOR_DISTANCE = 50,
	MAX_COWS_PER_PLAYER = 10,
	VISUAL_EFFECTS_ENABLED = true,
	DEBUG_MODE = true
}

-- System State
EnhancedCowMilkSystem.ActiveCows = {} -- [cowId] = cowModel
EnhancedCowMilkSystem.CowIndicators = {} -- [cowId] = indicatorModel
EnhancedCowMilkSystem.PlayerCowCounts = {} -- [userId] = count
EnhancedCowMilkSystem.LastMilkTimes = {} -- [cowId] = timestamp

-- References to other systems
EnhancedCowMilkSystem.GameCore = nil
EnhancedCowMilkSystem.ItemConfig = nil

-- ========== INITIALIZATION ==========

function EnhancedCowMilkSystem:Initialize()
	print("EnhancedCowMilkSystem: Starting FIXED initialization...")

	-- Wait for GameCore to be available
	self:WaitForGameCore()

	-- Wait for ItemConfig
	self:WaitForItemConfig()

	-- Start monitoring systems
	self:StartCowMonitoring()
	self:StartAutoMilkSystem()
	self:StartVisualEffectsSystem()

	-- Setup player events
	self:SetupPlayerEvents()

	print("EnhancedCowMilkSystem: ✅ FIXED initialization complete!")
end

function EnhancedCowMilkSystem:WaitForGameCore()
	print("EnhancedCowMilkSystem: Waiting for GameCore...")

	local attempts = 0
	while not _G.GameCore and attempts < 30 do
		wait(1)
		attempts = attempts + 1
	end

	if _G.GameCore then
		self.GameCore = _G.GameCore
		print("EnhancedCowMilkSystem: ✅ GameCore reference established")

		-- Verify required methods exist
		if type(self.GameCore.GetCowConfiguration) ~= "function" then
			error("EnhancedCowMilkSystem: GameCore missing GetCowConfiguration method!")
		end

		if type(self.GameCore.PurchaseCow) ~= "function" then
			error("EnhancedCowMilkSystem: GameCore missing PurchaseCow method!")
		end

		print("EnhancedCowMilkSystem: ✅ All required GameCore methods verified")
	else
		error("EnhancedCowMilkSystem: GameCore not available after 30 seconds!")
	end
end

function EnhancedCowMilkSystem:WaitForItemConfig()
	print("EnhancedCowMilkSystem: Waiting for ItemConfig...")

	local attempts = 0
	while not _G.ItemConfig and attempts < 10 do
		wait(1)
		attempts = attempts + 1
	end

	if _G.ItemConfig then
		self.ItemConfig = _G.ItemConfig
		print("EnhancedCowMilkSystem: ✅ ItemConfig reference established")
	else
		-- Try to load from ReplicatedStorage
		local success, itemConfig = pcall(function()
			return require(ReplicatedStorage:WaitForChild("ItemConfig", 5))
		end)

		if success then
			self.ItemConfig = itemConfig
			print("EnhancedCowMilkSystem: ✅ ItemConfig loaded from ReplicatedStorage")
		else
			warn("EnhancedCowMilkSystem: Could not load ItemConfig, some features may not work")
		end
	end
end

-- ========== COW REGISTRATION AND MANAGEMENT ==========

function EnhancedCowMilkSystem:RegisterCow(cowModel, owner, cowConfig)
	if not cowModel or not owner then
		warn("EnhancedCowMilkSystem: Invalid cow registration parameters")
		return false
	end

	local cowId = cowModel.Name
	local userId = owner.UserId

	print("🐄 EnhancedCowMilkSystem: Registering cow " .. cowId .. " for " .. owner.Name)

	-- Validate cow configuration
	if not cowConfig then
		local cowType = cowModel:GetAttribute("CowType") or "basic_cow"
		cowConfig = self.GameCore:GetCowConfiguration(cowType)

		if not cowConfig then
			warn("EnhancedCowMilkSystem: Could not get cow configuration for " .. cowType)
			return false
		end
	end

	-- Store cow data
	self.ActiveCows[cowId] = cowModel
	self.PlayerCowCounts[userId] = (self.PlayerCowCounts[userId] or 0) + 1
	self.LastMilkTimes[cowId] = os.time()

	-- Set cow attributes
	cowModel:SetAttribute("Owner", owner.Name)
	cowModel:SetAttribute("RegisteredTime", os.time())
	cowModel:SetAttribute("MilkAmount", cowConfig.milkAmount or 2)
	cowModel:SetAttribute("Cooldown", cowConfig.cooldown or 10)
	cowModel:SetAttribute("Tier", cowConfig.tier or "basic")

	-- Create milk indicator
	self:CreateMilkIndicator(cowModel, cowId)

	-- Apply visual effects if available
	if self.Config.VISUAL_EFFECTS_ENABLED and _G.CowVisualEffects then
		spawn(function()
			wait(0.5) -- Let model settle
			_G.CowVisualEffects:ApplyAdvancedEffects(cowModel, cowConfig.tier)
		end)
	end

	print("✅ EnhancedCowMilkSystem: Successfully registered cow " .. cowId)
	return true
end

function EnhancedCowMilkSystem:UnregisterCow(cowId)
	print("🗑️ EnhancedCowMilkSystem: Unregistering cow " .. cowId)

	local cowModel = self.ActiveCows[cowId]
	if cowModel then
		local owner = cowModel:GetAttribute("Owner")
		if owner then
			local player = Players:FindFirstChild(owner)
			if player then
				self.PlayerCowCounts[player.UserId] = math.max(0, (self.PlayerCowCounts[player.UserId] or 1) - 1)
			end
		end
	end

	-- Clean up data
	self.ActiveCows[cowId] = nil
	self.LastMilkTimes[cowId] = nil

	-- Remove visual indicator
	if self.CowIndicators[cowId] then
		self.CowIndicators[cowId]:Destroy()
		self.CowIndicators[cowId] = nil
	end

	-- Clear visual effects
	if _G.CowVisualEffects then
		_G.CowVisualEffects:ClearEffects(cowId)
	end

	print("✅ EnhancedCowMilkSystem: Cow " .. cowId .. " unregistered")
end

-- ========== MILK INDICATOR SYSTEM ==========

function EnhancedCowMilkSystem:CreateMilkIndicator(cowModel, cowId)
	if not cowModel or not cowModel.PrimaryPart then return end

	-- Remove existing indicator
	if self.CowIndicators[cowId] then
		self.CowIndicators[cowId]:Destroy()
	end

	-- Create new indicator
	local indicator = Instance.new("BillboardGui")
	indicator.Name = "MilkIndicator"
	indicator.Size = UDim2.new(0, 100, 0, 100)
	indicator.StudsOffset = Vector3.new(0, 4, 0)
	indicator.Parent = cowModel.PrimaryPart

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 1
	frame.Parent = indicator

	local milkIcon = Instance.new("TextLabel")
	milkIcon.Size = UDim2.new(1, 0, 1, 0)
	milkIcon.BackgroundTransparency = 1
	milkIcon.Text = "🥛"
	milkIcon.TextScaled = true
	milkIcon.Font = Enum.Font.GothamBold
	milkIcon.Parent = frame

	-- Store indicator
	self.CowIndicators[cowId] = indicator

	-- Start with indicator hidden
	indicator.Enabled = false

	return indicator
end

function EnhancedCowMilkSystem:UpdateMilkIndicator(cowId, readyForMilk)
	local indicator = self.CowIndicators[cowId]
	if not indicator then return end

	local cowModel = self.ActiveCows[cowId]
	if not cowModel then return end

	-- Check if any player is nearby
	local nearbyPlayer = self:GetNearbyPlayer(cowModel)

	if nearbyPlayer and readyForMilk then
		-- Show indicator
		indicator.Enabled = true

		-- Animate the indicator
		local milkIcon = indicator:FindFirstChild("Frame") and indicator.Frame:FindFirstChild("TextLabel")
		if milkIcon then
			-- Pulsing animation
			local pulse = TweenService:Create(milkIcon,
				TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{TextTransparency = 0.3}
			)
			pulse:Play()
		end
	else
		-- Hide indicator
		indicator.Enabled = false
	end
end

function EnhancedCowMilkSystem:GetNearbyPlayer(cowModel)
	if not cowModel or not cowModel.PrimaryPart then return nil end

	local cowPosition = cowModel.PrimaryPart.Position

	for _, player in pairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local playerPosition = player.Character.HumanoidRootPart.Position
			local distance = (cowPosition - playerPosition).Magnitude

			if distance <= self.Config.MILK_INDICATOR_DISTANCE then
				return player
			end
		end
	end

	return nil
end

-- ========== MONITORING SYSTEMS ==========

function EnhancedCowMilkSystem:StartCowMonitoring()
	print("EnhancedCowMilkSystem: Starting cow monitoring system...")

	spawn(function()
		while true do
			wait(5) -- Check every 5 seconds

			-- Scan for new cows
			self:ScanForExistingCows()

			-- Update existing cows
			self:UpdateAllCows()

			-- Clean up invalid cows
			self:CleanupInvalidCows()
		end
	end)
end

function EnhancedCowMilkSystem:ScanForExistingCows()
	-- Look for cow models in workspace that aren't registered
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and obj.Name:find("cow_") and obj.PrimaryPart then
			local cowId = obj.Name

			-- Check if already registered
			if not self.ActiveCows[cowId] then
				local owner = obj:GetAttribute("Owner")
				if owner then
					local player = Players:FindFirstChild(owner)
					if player then
						print("🔍 Found unregistered cow: " .. cowId .. " for " .. owner)

						-- Get cow type and configuration
						local cowType = obj:GetAttribute("CowType") or "basic_cow"
						local cowConfig = self.GameCore:GetCowConfiguration(cowType)

						if cowConfig then
							self:RegisterCow(obj, player, cowConfig)
						end
					end
				end
			end
		end
	end
end

function EnhancedCowMilkSystem:UpdateAllCows()
	for cowId, cowModel in pairs(self.ActiveCows) do
		if cowModel and cowModel.Parent then
			self:UpdateCow(cowId, cowModel)
		end
	end
end

function EnhancedCowMilkSystem:UpdateCow(cowId, cowModel)
	-- Check if cow is ready for milking
	local readyForMilk = self:IsCowReadyForMilk(cowId, cowModel)

	-- Update milk indicator
	self:UpdateMilkIndicator(cowId, readyForMilk)

	-- Update cow status attributes
	cowModel:SetAttribute("ReadyForMilk", readyForMilk)
	cowModel:SetAttribute("LastUpdate", os.time())
end

function EnhancedCowMilkSystem:IsCowReadyForMilk(cowId, cowModel)
	local currentTime = os.time()
	local lastMilkTime = self.LastMilkTimes[cowId] or 0
	local cooldown = cowModel:GetAttribute("Cooldown") or 10

	return (currentTime - lastMilkTime) >= cooldown
end

function EnhancedCowMilkSystem:CleanupInvalidCows()
	local toRemove = {}

	for cowId, cowModel in pairs(self.ActiveCows) do
		if not cowModel or not cowModel.Parent then
			table.insert(toRemove, cowId)
		end
	end

	for _, cowId in ipairs(toRemove) do
		self:UnregisterCow(cowId)
	end
end

-- ========== AUTO MILK SYSTEM ==========

function EnhancedCowMilkSystem:StartAutoMilkSystem()
	print("EnhancedCowMilkSystem: Starting auto milk system...")

	spawn(function()
		while true do
			wait(self.Config.AUTO_MILK_INTERVAL)

			for _, player in pairs(Players:GetPlayers()) do
				if self:PlayerHasAutoMilker(player) then
					self:AutoMilkPlayerCows(player)
				end
			end
		end
	end)
end

function EnhancedCowMilkSystem:PlayerHasAutoMilker(player)
	if not self.GameCore then return false end

	local playerData = self.GameCore:GetPlayerData(player)
	if not playerData or not playerData.upgrades then 
		return false
	end
		return playerData.upgrades.auto_milker == true
	end

	function EnhancedCowMilkSystem:AutoMilkPlayerCows(player)
		local milkedCount = 0

		for cowId, cowModel in pairs(self.ActiveCows) do
			local owner = cowModel:GetAttribute("Owner")
			if owner == player.Name and self:IsCowReadyForMilk(cowId, cowModel) then
				-- Use GameCore's milk collection system
				local success = self.GameCore:HandleCowMilkCollection(player, cowModel)
				if success then
					milkedCount = milkedCount + 1
					self.LastMilkTimes[cowId] = os.time()
				end
			end
		end

		if milkedCount > 0 and self.Config.DEBUG_MODE then
			print("🤖 Auto-milked " .. milkedCount .. " cows for " .. player.Name)
		end
	end

	-- ========== VISUAL EFFECTS SYSTEM ==========

	function EnhancedCowMilkSystem:StartVisualEffectsSystem()
		if not self.Config.VISUAL_EFFECTS_ENABLED then return end

		print("EnhancedCowMilkSystem: Starting visual effects system...")

		spawn(function()
			while true do
				wait(1) -- Update effects every second

				for cowId, cowModel in pairs(self.ActiveCows) do
					if cowModel and cowModel.Parent then
						self:UpdateCowVisualEffects(cowId, cowModel)
					end
				end
			end
		end)
	end

	function EnhancedCowMilkSystem:UpdateCowVisualEffects(cowId, cowModel)
		local tier = cowModel:GetAttribute("Tier") or "basic"
		local readyForMilk = cowModel:GetAttribute("ReadyForMilk") or false

		-- Add subtle effects based on cow state
		if readyForMilk and tier ~= "basic" then
			-- Add gentle glow effect for higher tier cows when ready
			if not cowModel:FindFirstChild("ReadyGlow") then
				local glow = Instance.new("PointLight")
				glow.Name = "ReadyGlow"
				glow.Color = Color3.fromRGB(255, 255, 200)
				glow.Brightness = 0.5
				glow.Range = 8
				glow.Parent = cowModel.PrimaryPart

				-- Fade in
				local fadeIn = TweenService:Create(glow,
					TweenInfo.new(2, Enum.EasingStyle.Sine),
					{Brightness = 1}
				)
				fadeIn:Play()
			end
		else
			-- Remove ready glow
			local glow = cowModel:FindFirstChild("ReadyGlow")
			if glow then
				local fadeOut = TweenService:Create(glow,
					TweenInfo.new(1, Enum.EasingStyle.Sine),
					{Brightness = 0}
				)
				fadeOut:Play()
				fadeOut.Completed:Connect(function()
					glow:Destroy()
				end)
			end
		end
	end

	-- ========== PLAYER EVENTS ==========

	function EnhancedCowMilkSystem:SetupPlayerEvents()
		Players.PlayerRemoving:Connect(function(player)
			-- Clean up player's cows
			self:CleanupPlayerCows(player)
		end)
	end

	function EnhancedCowMilkSystem:CleanupPlayerCows(player)
		print("🧹 EnhancedCowMilkSystem: Cleaning up cows for " .. player.Name)

		local toRemove = {}

		for cowId, cowModel in pairs(self.ActiveCows) do
			local owner = cowModel:GetAttribute("Owner")
			if owner == player.Name then
				table.insert(toRemove, cowId)
			end
		end

		for _, cowId in ipairs(toRemove) do
			self:UnregisterCow(cowId)
		end

		-- Reset player cow count
		self.PlayerCowCounts[player.UserId] = nil
	end

	-- ========== UTILITY AND DEBUG FUNCTIONS ==========

	function EnhancedCowMilkSystem:GetPlayerCowInfo(player)
		local info = {
			playerName = player.Name,
			totalCows = self.PlayerCowCounts[player.UserId] or 0,
			cowsByTier = {},
			activeCows = {},
			totalMilkProduced = 0,
			averageCooldown = 0,
			maxCows = self.Config.MAX_COWS_PER_PLAYER,
			hasAutoMilker = self:PlayerHasAutoMilker(player),
			lastUpdate = os.time()
		}

		local totalCooldown = 0
		local cowCount = 0

		for cowId, cowModel in pairs(self.ActiveCows) do
			local owner = cowModel:GetAttribute("Owner")
			if owner == player.Name then
				cowCount = cowCount + 1
				local tier = cowModel:GetAttribute("Tier") or "basic"
				local cooldown = cowModel:GetAttribute("Cooldown") or 10
				local milkAmount = cowModel:GetAttribute("MilkAmount") or 2

				info.cowsByTier[tier] = (info.cowsByTier[tier] or 0) + 1
				totalCooldown = totalCooldown + cooldown

				table.insert(info.activeCows, {
					id = cowId,
					tier = tier,
					cooldown = cooldown,
					milkAmount = milkAmount,
					readyForMilk = self:IsCowReadyForMilk(cowId, cowModel)
				})
			end
		end

		if cowCount > 0 then
			info.averageCooldown = totalCooldown / cowCount
		end

		return info
	end

	function EnhancedCowMilkSystem:GetPerformanceData()
		return {
			timestamp = os.time(),
			systemStatus = "running",
			totalActiveCows = self:CountTable(self.ActiveCows),
			cowsByPlayer = self.PlayerCowCounts,
			activeEffects = _G.CowVisualEffects and self:CountTable(_G.CowVisualEffects.ActiveEffects) or 0,
			playersWithCows = self:CountTable(self.PlayerCowCounts),
			playersWithAutoMilker = self:CountPlayersWithAutoMilker(),
			errors = {},
			warnings = {}
		}
	end

	function EnhancedCowMilkSystem:CountTable(t)
		local count = 0
		if t then
			for _ in pairs(t) do
				count = count + 1
			end
		end
		return count
	end

	function EnhancedCowMilkSystem:CountPlayersWithAutoMilker()
		local count = 0
		for _, player in pairs(Players:GetPlayers()) do
			if self:PlayerHasAutoMilker(player) then
				count = count + 1
			end
		end
		return count
	end

	function EnhancedCowMilkSystem:GetCowStats()
		local stats = {
			totalCows = self:CountTable(self.ActiveCows),
			cowsByTier = {},
			averageMilkProduction = 0,
			systemUptime = os.time() - (self.StartTime or os.time())
		}

		local totalMilkAmount = 0
		local cowCount = 0

		for cowId, cowModel in pairs(self.ActiveCows) do
			cowCount = cowCount + 1
			local tier = cowModel:GetAttribute("Tier") or "basic"
			local milkAmount = cowModel:GetAttribute("MilkAmount") or 2

			stats.cowsByTier[tier] = (stats.cowsByTier[tier] or 0) + 1
			totalMilkAmount = totalMilkAmount + milkAmount
		end

		if cowCount > 0 then
			stats.averageMilkProduction = totalMilkAmount / cowCount
		end

		return stats
	end

	-- ========== INTEGRATION METHODS ==========

	function EnhancedCowMilkSystem:OnCowPurchased(player, cowItemId, cowModel)
		print("🐄 EnhancedCowMilkSystem: New cow purchased by " .. player.Name .. " (" .. cowItemId .. ")")

		-- Get cow configuration from GameCore
		local cowConfig = self.GameCore:GetCowConfiguration(cowItemId)
		if not cowConfig then
			warn("EnhancedCowMilkSystem: Could not get configuration for " .. cowItemId)
			return false
		end

		-- Register the cow
		local success = self:RegisterCow(cowModel, player, cowConfig)

		if success then
			print("✅ EnhancedCowMilkSystem: Successfully integrated new cow")
		else
			warn("❌ EnhancedCowMilkSystem: Failed to integrate new cow")
		end

		return success
	end

	function EnhancedCowMilkSystem:OnCowUpgraded(player, cowModel, newTier)
		print("🔄 EnhancedCowMilkSystem: Cow upgraded to " .. newTier .. " for " .. player.Name)

		local cowId = cowModel.Name

		-- Update cow attributes
		local cowConfig = self.GameCore:GetCowConfiguration(newTier .. "_cow")
		if cowConfig then
			cowModel:SetAttribute("Tier", newTier)
			cowModel:SetAttribute("MilkAmount", cowConfig.milkAmount)
			cowModel:SetAttribute("Cooldown", cowConfig.cooldown)

			-- Apply new visual effects
			if _G.CowVisualEffects then
				_G.CowVisualEffects:ClearEffects(cowId)
				spawn(function()
					wait(0.5)
					_G.CowVisualEffects:ApplyAdvancedEffects(cowModel, newTier)
				end)
			end

			print("✅ EnhancedCowMilkSystem: Cow upgrade completed")
			return true
		else
			warn("❌ EnhancedCowMilkSystem: Could not get configuration for upgraded cow")
			return false
		end
	end

	-- ========== DEBUG COMMANDS ==========

	game:GetService("Players").PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Replace with your username
				local args = string.split(message:lower(), " ")
				local command = args[1]

				if command == "/cowstats" then
					local stats = EnhancedCowMilkSystem:GetCowStats()
					print("=== COW SYSTEM STATS ===")
					print("Total cows: " .. stats.totalCows)
					print("Cows by tier:")
					for tier, count in pairs(stats.cowsByTier) do
						print("  " .. tier .. ": " .. count)
					end
					print("Average milk production: " .. stats.averageMilkProduction)
					print("=======================")

				elseif command == "/mycows" then
					local info = EnhancedCowMilkSystem:GetPlayerCowInfo(player)
					print("=== " .. player.Name .. "'S COWS ===")
					print("Total cows: " .. info.totalCows)
					print("Has auto milker: " .. tostring(info.hasAutoMilker))
					print("Active cows:")
					for _, cow in ipairs(info.activeCows) do
						print("  " .. cow.tier .. " cow - Ready: " .. tostring(cow.readyForMilk))
					end
					print("=========================")

				elseif command == "/refreshcows" then
					EnhancedCowMilkSystem:ScanForExistingCows()
					print("🔄 Refreshed cow scan")

				elseif command == "/cleanupcows" then
					EnhancedCowMilkSystem:CleanupInvalidCows()
					print("🧹 Cleaned up invalid cows")
				end
			end
		end)
	end)

	-- ========== INITIALIZATION ==========

	-- Store start time
	EnhancedCowMilkSystem.StartTime = os.time()

	-- Initialize the system
	EnhancedCowMilkSystem:Initialize()

	-- Make globally available
	_G.EnhancedCowMilkSystem = EnhancedCowMilkSystem

	print("EnhancedCowMilkSystem: ✅ FIXED system loaded with proper GameCore integration!")
	print("🐄 FEATURES:")
	print("  ✅ Proper GameCore:GetCowConfiguration integration")
	print("  ✅ Coordinated with GameCore:PurchaseCow")
	print("  ✅ Advanced milk indicator system")
	print("  ✅ Auto-milking for upgraded players")
	print("  ✅ Visual effects coordination")
	print("  ✅ Comprehensive cow monitoring")
	print("")
	print("🔧 Debug Commands:")
	print("  /cowstats - Show system statistics")
	print("  /mycows - Show your cow information")
	print("  /refreshcows - Scan for new cows")
	print("  /cleanupcows - Clean invalid cows")