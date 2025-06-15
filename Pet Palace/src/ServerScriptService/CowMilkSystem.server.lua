--[[
    ROBUST Cow Milk System - Works with ANY cow model structure
    Place in: ServerScriptService/CowMilkSystem.server.lua
    
    This version:
    ✅ Automatically finds and analyzes your cow model
    ✅ Creates ClickDetectors on the best parts
    ✅ Creates backup invisible click areas
    ✅ Works with any cow model structure
    ✅ Has extensive debugging and admin commands
]]

local function WaitForGameCore(scriptName, maxWaitTime)
	maxWaitTime = maxWaitTime or 15
	local startTime = tick()

	print(scriptName .. ": Waiting for GameCore...")

	while not _G.GameCore and (tick() - startTime) < maxWaitTime do
		wait(0.5)
	end

	if not _G.GameCore then
		warn(scriptName .. ": GameCore not found after " .. maxWaitTime .. " seconds! Running in standalone mode.")
		return nil
	end

	print(scriptName .. ": GameCore found successfully!")
	return _G.GameCore
end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Try to get GameCore (but work without it if necessary)
local GameCore = WaitForGameCore("RobustCowMilkSystem")

print("=== ROBUST COW MILK SYSTEM STARTING ===")

local CowMilkSystem = {}

-- Configuration
local MILK_COOLDOWN = 60 -- seconds
local MILK_AMOUNT = 2
local MAX_CLICK_DISTANCE = 25

-- Local player cooldown tracking (backup system)
local PlayerCooldowns = {}

-- Find cow model with flexible searching
local function FindCowModel()
	-- Try exact name first
	local cow = workspace:FindFirstChild("cow")
	if cow then
		return cow
	end

	-- Try case-insensitive search
	for _, obj in pairs(workspace:GetChildren()) do
		if obj.Name:lower() == "cow" then
			return obj
		end
	end

	-- Try partial name search
	for _, obj in pairs(workspace:GetChildren()) do
		if obj.Name:lower():find("cow") then
			print("RobustCowMilkSystem: Found cow with name:", obj.Name)
			return obj
		end
	end

	return nil
end

local cowModel = FindCowModel()
if not cowModel then
	error("RobustCowMilkSystem: No cow model found in workspace! Please add a model with 'cow' in the name.")
end

print("RobustCowMilkSystem: Found cow model:", cowModel.Name)

-- Analyze cow model structure
function CowMilkSystem:AnalyzeCowModel()
	print("RobustCowMilkSystem: Analyzing cow model structure...")

	local parts = {}
	local bestParts = {}

	-- Find all BaseParts in the cow
	for _, obj in pairs(cowModel:GetDescendants()) do
		if obj:IsA("BasePart") then
			table.insert(parts, obj)
		end
	end

	print("RobustCowMilkSystem: Found " .. #parts .. " parts in cow model")

	-- Prioritize parts by name and size
	local preferredNames = {"humanoidrootpart", "torso", "head", "body", "middle", "center", "main"}

	-- First, look for preferred named parts
	for _, preferredName in ipairs(preferredNames) do
		for _, part in ipairs(parts) do
			if part.Name:lower() == preferredName then
				table.insert(bestParts, {part = part, priority = 10, reason = "preferred name"})
				print("  ⭐ Found preferred part:", part.Name)
			end
		end
	end

	-- Then add largest parts if we don't have enough
	if #bestParts < 2 then
		-- Sort by volume
		table.sort(parts, function(a, b)
			local volumeA = a.Size.X * a.Size.Y * a.Size.Z
			local volumeB = b.Size.X * b.Size.Y * b.Size.Z
			return volumeA > volumeB
		end)

		-- Add up to 3 largest parts
		for i = 1, math.min(3, #parts) do
			local part = parts[i]
			local volume = part.Size.X * part.Size.Y * part.Size.Z

			-- Check if already in bestParts
			local alreadyAdded = false
			for _, entry in ipairs(bestParts) do
				if entry.part == part then
					alreadyAdded = true
					break
				end
			end

			if not alreadyAdded then
				table.insert(bestParts, {part = part, priority = 5, reason = "large size (vol: " .. math.floor(volume) .. ")"})
				print("  📏 Added large part:", part.Name, "- Volume:", math.floor(volume))
			end
		end
	end

	self.cowParts = parts
	self.bestParts = bestParts

	print("RobustCowMilkSystem: Selected " .. #bestParts .. " parts for click detection")
	return bestParts
end

-- Initialize the system
function CowMilkSystem:Initialize()
	print("RobustCowMilkSystem: Initializing robust cow milk collection system...")

	-- Analyze cow model
	self:AnalyzeCowModel()

	-- Create sounds
	self:CreateCowSounds()

	-- Setup visual indicator
	self:SetupMilkIndicator()

	-- Setup robust click detection
	self:SetupRobustClickDetection()

	-- Create backup click area
	self:CreateBackupClickArea()

	-- Start indicator updates
	self:StartIndicatorUpdates()

	print("RobustCowMilkSystem: Initialization complete!")
end

-- Create cow sounds
function CowMilkSystem:CreateCowSounds()
	local mooSound = Instance.new("Sound")
	mooSound.Name = "MooSound"
	mooSound.SoundId = "rbxassetid://131961136" -- Cow moo
	mooSound.Volume = 0.5
	--mooSound.Pitch = 0.8
	mooSound.Parent = cowModel

	self.mooSound = mooSound
	print("RobustCowMilkSystem: Created moo sound")
end

-- Setup milk indicator above cow
function CowMilkSystem:SetupMilkIndicator()
	-- Remove existing indicator
	local existing = cowModel:FindFirstChild("MilkIndicator")
	if existing then existing:Destroy() end

	-- Find best position above cow
	local cowCenter = Vector3.new(0, 0, 0)
	local cowTop = 0

	-- Calculate center and top of cow using modern methods
	if #self.cowParts > 0 then
		local totalPos = Vector3.new(0, 0, 0)
		for _, part in ipairs(self.cowParts) do
			totalPos = totalPos + part.Position
			cowTop = math.max(cowTop, part.Position.Y + part.Size.Y/2)
		end
		cowCenter = totalPos / #self.cowParts
	else
		-- Use GetBoundingBox instead of deprecated GetModelCFrame
		local cowCFrame, cowSize = cowModel:GetBoundingBox()
		cowCenter = cowCFrame.Position
		cowTop = cowCenter.Y + cowSize.Y/2
	end

	-- Create indicator
	local indicator = Instance.new("Part")
	indicator.Name = "MilkIndicator"
	indicator.Size = Vector3.new(6, 0.5, 6)
	indicator.Shape = Enum.PartType.Cylinder
	indicator.Material = Enum.Material.Neon
	indicator.Color = Color3.fromRGB(255, 0, 0)
	indicator.CanCollide = false
	indicator.Anchored = true
	indicator.CFrame = CFrame.new(cowCenter.X, cowTop + 4, cowCenter.Z)
	indicator.Orientation = Vector3.new(0, 0, 90)
	indicator.Parent = cowModel

	-- Add text
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 200, 0, 50)
	gui.StudsOffset = Vector3.new(0, 2, 0)
	gui.Parent = indicator

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "🥛 CLICK COW TO COLLECT MILK"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Parent = gui

	self.milkIndicator = indicator
	self.milkLabel = label

	print("RobustCowMilkSystem: Created milk indicator at", indicator.Position)
end

-- Setup robust click detection on multiple parts
function CowMilkSystem:SetupRobustClickDetection()
	print("RobustCowMilkSystem: Setting up robust click detection...")

	local clickDetectorsCreated = 0

	-- Add ClickDetectors to best parts
	for _, entry in ipairs(self.bestParts) do
		local part = entry.part
		local reason = entry.reason

		-- Remove existing detector
		local existing = part:FindFirstChild("ClickDetector")
		if existing then existing:Destroy() end

		-- Create new detector
		local detector = Instance.new("ClickDetector")
		detector.MaxActivationDistance = MAX_CLICK_DISTANCE
		detector.Parent = part

		-- Handle clicks
		detector.MouseClick:Connect(function(player)
			print("🥛 RobustCowMilkSystem: Click detected on", part.Name, "by", player.Name)
			self:HandleCowClick(player, part.Name)
		end)

		-- Visual feedback
		detector.MouseHoverEnter:Connect(function(player)
			if self.milkLabel then
				self.milkLabel.Text = "🥛 CLICK NOW!"
				self.milkLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
			end
		end)

		detector.MouseHoverLeave:Connect(function(player)
			if self.milkLabel then
				self.milkLabel.Text = "🥛 CLICK COW TO COLLECT MILK"
				self.milkLabel.TextColor3 = Color3.new(1, 1, 1)
			end
		end)

		clickDetectorsCreated = clickDetectorsCreated + 1
		print("  ✅ Added ClickDetector to", part.Name, "(" .. reason .. ")")
	end

	print("RobustCowMilkSystem: Created " .. clickDetectorsCreated .. " ClickDetectors")
end

-- Create backup invisible click area
function CowMilkSystem:CreateBackupClickArea()
	print("RobustCowMilkSystem: Creating backup click area...")

	-- Calculate cow bounds using modern methods
	local cowCFrame, cowSize = cowModel:GetBoundingBox()
	local cowCenter = cowCFrame.Position

	-- Create large invisible clickable part
	local clickArea = Instance.new("Part")
	clickArea.Name = "CowBackupClickArea"
	clickArea.Size = Vector3.new(
		math.max(10, cowSize.X + 4),
		math.max(8, cowSize.Y + 2),
		math.max(10, cowSize.Z + 4)
	)
	clickArea.Transparency = 1
	clickArea.CanCollide = false
	clickArea.Anchored = true
	clickArea.CFrame = CFrame.new(cowCenter)
	clickArea.Parent = cowModel

	-- Add ClickDetector
	local detector = Instance.new("ClickDetector")
	detector.MaxActivationDistance = MAX_CLICK_DISTANCE + 5
	detector.Parent = clickArea

	detector.MouseClick:Connect(function(player)
		print("🥛 RobustCowMilkSystem: Backup click area activated by", player.Name)
		self:HandleCowClick(player, "BackupArea")
	end)

	self.backupClickArea = clickArea
	print("RobustCowMilkSystem: Created backup click area - Size:", clickArea.Size, "Position:", clickArea.Position)
end

-- Handle cow clicks
function CowMilkSystem:HandleCowClick(player, clickSource)
	print("🥛 RobustCowMilkSystem: Processing click from", player.Name, "on", clickSource or "unknown")

	-- Check local cooldown first
	local currentTime = os.time()
	local lastCollection = PlayerCooldowns[player.UserId] or 0
	local timeSinceCollection = currentTime - lastCollection

	if timeSinceCollection < MILK_COOLDOWN then
		local timeLeft = MILK_COOLDOWN - timeSinceCollection
		self:SendNotification(player, "🐄 Cow Resting", 
			"The cow needs " .. math.ceil(timeLeft) .. " more seconds to produce milk!", "warning")
		return
	end

	-- Try GameCore first, then fallback to local system
	local success = false

	if GameCore and GameCore.HandleMilkCollection then
		success = pcall(function()
			return GameCore:HandleMilkCollection(player)
		end)

		if success then
			print("🥛 RobustCowMilkSystem: GameCore handled milk collection")
		else
			print("🥛 RobustCowMilkSystem: GameCore failed, using fallback system")
		end
	end

	-- Fallback system if GameCore isn't available or failed
	if not success then
		success = self:HandleMilkCollectionLocal(player)
	end

	if success then
		-- Update local cooldown
		PlayerCooldowns[player.UserId] = currentTime

		-- Play effects
		self:PlayMooSound()
		self:CreateMilkEffect()
		self:UpdateIndicatorColor()
	end
end

-- Local milk collection fallback
function CowMilkSystem:HandleMilkCollectionLocal(player)
	print("🥛 RobustCowMilkSystem: Using local milk collection for", player.Name)

	-- Simple leaderstats update
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins then
			coins.Value = coins.Value + 10 -- Give coins directly as reward
		end
	end

	-- Send notification
	self:SendNotification(player, "🥛 Milk Collected!", 
		"Collected " .. MILK_AMOUNT .. " milk and earned 10 coins!", "success")

	return true
end

-- Send notification with multiple fallback methods
function CowMilkSystem:SendNotification(player, title, message, notificationType)
	-- Try GameCore
	if GameCore and GameCore.SendNotification then
		local success = pcall(function()
			GameCore:SendNotification(player, title, message, notificationType)
		end)
		if success then return end
	end

	-- Try remote event
	local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if remoteFolder then
		local notificationRemote = remoteFolder:FindFirstChild("ShowNotification")
		if notificationRemote then
			local success = pcall(function()
				notificationRemote:FireClient(player, title, message, notificationType)
			end)
			if success then return end
		end
	end

	-- Fallback: Chat notification
	local success = pcall(function()
		game:GetService("StarterGui"):SetCoreGuiEnabled(player, "Chat", true)
		-- This won't work from server, but we'll try anyway
	end)

	-- Final fallback: Console
	print("🔔 NOTIFICATION for " .. player.Name .. ": [" .. (notificationType or "info"):upper() .. "] " .. title .. " - " .. message)
end

-- Play moo sound
function CowMilkSystem:PlayMooSound()
	if self.mooSound then
		self.mooSound.Pitch = 0.7 + (math.random() * 0.4)
		pcall(function() self.mooSound:Play() end)
	end
end

-- Create milk collection effect
function CowMilkSystem:CreateMilkEffect()
	-- Use modern method to get cow center
	local cowCFrame, cowSize = cowModel:GetBoundingBox()
	local cowCenter = cowCFrame.Position

	-- Create milk droplets
	for i = 1, 6 do
		local droplet = Instance.new("Part")
		droplet.Name = "MilkDroplet"
		droplet.Size = Vector3.new(0.5, 0.5, 0.5)
		droplet.Shape = Enum.PartType.Ball
		droplet.Material = Enum.Material.Neon
		droplet.Color = Color3.fromRGB(255, 255, 255)
		droplet.CanCollide = false
		droplet.Anchored = true
		droplet.Position = cowCenter + Vector3.new(
			math.random(-2, 2),
			math.random(0, 3),
			math.random(-2, 2)
		)
		droplet.Parent = workspace

		-- Animate
		local tween = TweenService:Create(droplet,
			TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = droplet.Position + Vector3.new(0, 10, 0),
				Transparency = 1,
				Size = Vector3.new(0.1, 0.1, 0.1)
			}
		)
		tween:Play()
		tween.Completed:Connect(function() droplet:Destroy() end)
	end

	-- Flash indicator
	if self.milkIndicator and self.milkLabel then
		local originalColor = self.milkIndicator.Color
		self.milkIndicator.Color = Color3.fromRGB(0, 255, 0)
		self.milkLabel.Text = "🥛 MILK COLLECTED!"
		self.milkLabel.TextColor3 = Color3.fromRGB(0, 255, 0)

		spawn(function()
			wait(2)
			if self.milkIndicator and self.milkLabel then
				self.milkIndicator.Color = originalColor
				self.milkLabel.Text = "🥛 CLICK COW TO COLLECT MILK"
				self.milkLabel.TextColor3 = Color3.new(1, 1, 1)
			end
		end)
	end
end

-- Start indicator updates
function CowMilkSystem:StartIndicatorUpdates()
	spawn(function()
		while self.milkIndicator and self.milkIndicator.Parent do
			self:UpdateIndicatorColor()
			wait(2)
		end
	end)
end

-- Update indicator color
function CowMilkSystem:UpdateIndicatorColor()
	if not self.milkIndicator then return end

	local currentTime = os.time()
	local anyReady = false
	local shortestWait = math.huge

	-- Check all players
	for _, player in pairs(Players:GetPlayers()) do
		local lastCollection = PlayerCooldowns[player.UserId] or 0
		local timeLeft = MILK_COOLDOWN - (currentTime - lastCollection)

		if timeLeft <= 0 then
			anyReady = true
			break
		else
			shortestWait = math.min(shortestWait, timeLeft)
		end
	end

	if next(PlayerCooldowns) == nil then
		anyReady = true
	end

	-- Update color
	if anyReady then
		self.milkIndicator.Color = Color3.fromRGB(0, 255, 0)
		if self.milkLabel then
			self.milkLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
		end
	elseif shortestWait <= 10 then
		self.milkIndicator.Color = Color3.fromRGB(255, 255, 0)
		if self.milkLabel then
			self.milkLabel.Text = "🥛 ALMOST READY (" .. math.ceil(shortestWait) .. "s)"
			self.milkLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
		end
	else
		self.milkIndicator.Color = Color3.fromRGB(255, 0, 0)
		if self.milkLabel then
			self.milkLabel.Text = "🥛 COW RESTING (" .. math.ceil(shortestWait) .. "s)"
			self.milkLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		end
	end
end

-- Admin commands
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.Name == "TommySalami311" then -- Replace with your username
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/cowstatus" then
				print("=== COW SYSTEM STATUS ===")
				print("Cow model:", cowModel and cowModel.Name or "NOT FOUND")
				print("Cow parts found:", #(CowMilkSystem.cowParts or {}))
				print("Best parts for clicking:", #(CowMilkSystem.bestParts or {}))
				print("Backup click area:", CowMilkSystem.backupClickArea and "Active" or "Missing")
				print("Milk indicator:", CowMilkSystem.milkIndicator and "Active" or "Missing")
				print("GameCore available:", GameCore ~= nil)

				local clickDetectors = 0
				for _, part in pairs(cowModel:GetDescendants()) do
					if part:IsA("ClickDetector") then
						clickDetectors = clickDetectors + 1
					end
				end
				print("Total ClickDetectors:", clickDetectors)
				print("========================")

			elseif command == "/forcemilk" then
				print("🧪 Admin: Force milk collection")
				CowMilkSystem:HandleCowClick(player, "AdminCommand")

			elseif command == "/resetcow" then
				PlayerCooldowns[player.UserId] = 0
				print("🧪 Admin: Reset cow cooldown for", player.Name)

			elseif command == "/recreatecow" then
				print("🔧 Admin: Recreating cow click system...")
				CowMilkSystem:Initialize()
				print("✅ Cow system recreated")

			end
		end
	end)
end)

-- Initialize
CowMilkSystem:Initialize()
_G.CowMilkSystem = CowMilkSystem

print("=== ROBUST COW MILK SYSTEM ACTIVE ===")
print("✅ Works with any cow model structure")
print("✅ Multiple ClickDetectors + backup area")
print("✅ Fallback systems for all functions")
print("✅ Extensive debugging and admin commands")
print("")
print("Admin Commands:")
print("  /cowstatus - Show system status")
print("  /forcemilk - Force milk collection")
print("  /resetcow - Reset your cooldown")
print("  /recreatecow - Recreate entire system")