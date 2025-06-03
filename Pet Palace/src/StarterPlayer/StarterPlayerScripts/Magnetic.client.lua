--[[
    Magnetic.client.lua - FIXED VERSION
    Place in: StarterPlayerScripts/Magnetic.client.lua
    
    FIXES:
    1. ✅ Better GameClient waiting system
    2. ✅ Proper error handling
    3. ✅ Fallback behavior if GameClient fails
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

print("Magnetic: Starting initialization...")

-- FIXED: Enhanced GameClient waiting system
local function WaitForGameClient()
	print("Magnetic: Waiting for GameClient...")

	-- Method 1: Check if already available
	if _G.GameClient then
		print("Magnetic: GameClient found immediately")
		return _G.GameClient
	end

	-- Method 2: Wait for ready event
	local clientReady = ReplicatedStorage:FindFirstChild("GameClientReady")
	if clientReady then
		print("Magnetic: Waiting for GameClientReady event...")
		local success, gameClient = pcall(function()
			return clientReady.Event:Wait()
		end)
		if success and gameClient then
			print("Magnetic: GameClient received from ready event")
			return gameClient
		end
	end

	-- Method 3: Poll for global availability
	print("Magnetic: Polling for global GameClient...")
	for i = 1, 30 do -- Wait up to 30 seconds
		if _G.GameClient then
			print("Magnetic: GameClient found after " .. i .. " seconds")
			return _G.GameClient
		end
		wait(1)
	end

	error("Magnetic: GameClient not available after 30 seconds")
end

-- FIXED: Try to get GameClient with better error handling
local GameClient = nil
local success, errorMsg = pcall(function()
	GameClient = WaitForGameClient()
end)

if not success then
	warn("Magnetic: Failed to get GameClient: " .. tostring(errorMsg))
	warn("Magnetic: Running in fallback mode without GameClient integration")

	-- Create a basic fallback GameClient
	GameClient = {
		GetPlayerData = function() return nil end,
		ShowNotification = function(title, message, type)
			print("Notification [" .. (type or "info") .. "]: " .. title .. " - " .. message)
		end
	}
end

local CollectionSystem = {}

-- Configuration
CollectionSystem.Settings = {
	baseCollectionRadius = 5,    -- Base collection range
	baseMagnetRange = 8,         -- Base magnet range
	visualUpdateInterval = 0.1,  -- How often to update visuals
	magnetPullForce = 0.3,      -- How strong the magnet pull is
	showVisualRanges = true,     -- Whether to show range indicators
	magnetEnabled = true         -- Whether magnet is enabled
}

-- Current stats
CollectionSystem.CurrentStats = {
	collectionRadius = 5,
	magnetRange = 8,
	magnetStrength = 1.0
}

-- Visual elements
CollectionSystem.Visuals = {
	collectionRangeIndicator = nil,
	magnetRangeIndicator = nil,
	attractedPets = {},
	activeTweens = {}
}

-- State tracking
CollectionSystem.State = {
	lastUpdate = 0,
	rangeVisualToggle = false
}

-- Get remote events
CollectionSystem.RemoteEvents = {
	CollectWildPet = nil,
	PlayerDataUpdated = nil
}

-- Initialize the system
function CollectionSystem:Initialize()
	print("CollectionSystem: Starting initialization...")

	-- Get remote events
	local gameRemotes = ReplicatedStorage:WaitForChild("GameRemotes", 10)
	if gameRemotes then
		self.RemoteEvents.CollectWildPet = gameRemotes:FindFirstChild("CollectWildPet")
		self.RemoteEvents.PlayerDataUpdated = gameRemotes:FindFirstChild("PlayerDataUpdated")
	else
		warn("CollectionSystem: GameRemotes not found, creating fallback")
		-- Create fallback remote events
		local fallbackFolder = Instance.new("Folder")
		fallbackFolder.Name = "FallbackRemotes"

		local fallbackCollect = Instance.new("RemoteEvent")
		fallbackCollect.Name = "CollectWildPet"
		fallbackCollect.Parent = fallbackFolder

		self.RemoteEvents.CollectWildPet = fallbackCollect
	end

	-- Setup visual indicators
	self:CreateVisualIndicatorsAlt()

	-- Connect to player data updates
	self:ConnectToDataUpdates()

	-- Setup input handlers
	self:SetupInputHandlers()

	-- Start main update loop
	self:StartUpdateLoop()

	-- Initial stats update
	self:UpdateStatsFromPlayerData()

	print("CollectionSystem: Initialized with enhanced pet collection and magnet system")
end


-- FIXED: Update stats from player data with fallback
function CollectionSystem:UpdateStatsFromPlayerData()
	if not GameClient or not GameClient.GetPlayerData then
		-- Use default values if GameClient isn't available
		print("CollectionSystem: Using default stats (GameClient not available)")
		return
	end

	local success, playerData = pcall(function()
		return GameClient:GetPlayerData()
	end)

	if not success or not playerData or not playerData.upgrades then 
		print("CollectionSystem: Using default stats (no player data)")
		return 
	end

	local upgrades = playerData.upgrades

	-- Calculate collection radius
	local collectionLevel = upgrades.collection_radius_upgrade or 0
	self.CurrentStats.collectionRadius = self.Settings.baseCollectionRadius + collectionLevel

	-- Calculate magnet range and strength
	local magnetLevel = upgrades.pet_magnet_upgrade or 0
	self.CurrentStats.magnetRange = self.Settings.baseMagnetRange + (magnetLevel * 2)
	self.CurrentStats.magnetStrength = 1.0 + (magnetLevel * 0.3)

	-- Update visual indicators
	self:UpdateVisualIndicators()

	print("CollectionSystem: Updated stats - Collection:", self.CurrentStats.collectionRadius, "Magnet:", self.CurrentStats.magnetRange)
end

-- Continue with the rest of your CollectionSystem methods...
-- (Include all the other methods from your original Magnetic script)

-- Clear visual indicators

function CollectionSystem:ClearVisualIndicators()
	if self.Visuals.collectionRangeIndicator then
		self.Visuals.collectionRangeIndicator:Destroy()
		self.Visuals.collectionRangeIndicator = nil
	end

	if self.Visuals.magnetRangeIndicator then
		if self.Visuals.activeTweens[self.Visuals.magnetRangeIndicator] then
			self.Visuals.activeTweens[self.Visuals.magnetRangeIndicator]:Cancel()
			self.Visuals.activeTweens[self.Visuals.magnetRangeIndicator] = nil
		end
		self.Visuals.magnetRangeIndicator:Destroy()
		self.Visuals.magnetRangeIndicator = nil
	end

	-- Clean up container if using alternative method
	if self.Visuals.indicatorContainer then
		self.Visuals.indicatorContainer:Destroy()
		self.Visuals.indicatorContainer = nil
	end

	-- Clear all active tweens
	for object, tween in pairs(self.Visuals.activeTweens) do
		if tween then
			tween:Cancel()
		end
	end
	self.Visuals.activeTweens = {}
end


-- Basic implementation of other required methods
function CollectionSystem:CreateMagnetPulseAnimation(magnetIndicator)
-- Simple pulsing animation
if not magnetIndicator or not magnetIndicator.Parent then return end

-- Cancel existing tween for this indicator
if self.Visuals.activeTweens[magnetIndicator] then
	self.Visuals.activeTweens[magnetIndicator]:Cancel()
end

local pulseInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local pulseTween = TweenService:Create(magnetIndicator, pulseInfo, {Transparency = 0.7})
pulseTween:Play()
self.Visuals.activeTweens[magnetIndicator] = pulseTween

-- Clean up tween when part is destroyed
magnetIndicator.AncestryChanged:Connect(function()
	if not magnetIndicator.Parent then
		if self.Visuals.activeTweens[magnetIndicator] then
			self.Visuals.activeTweens[magnetIndicator]:Cancel()
			self.Visuals.activeTweens[magnetIndicator] = nil
		end
	end
end)
end

function CollectionSystem:ConnectToDataUpdates()
	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated.OnClientEvent:Connect(function()
			self:UpdateStatsFromPlayerData()
		end)
	end

	LocalPlayer.CharacterAdded:Connect(function()
		wait(2)
		self:CreateVisualIndicatorsAlt()
		self:UpdateStatsFromPlayerData()
	end)
end

function CollectionSystem:SetupInputHandlers()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.R then
			self:ToggleRangeVisuals()
		elseif input.KeyCode == Enum.KeyCode.M then
			self:ToggleMagnet()
		end
	end)
end

function CollectionSystem:ToggleRangeVisuals()
	self.State.rangeVisualToggle = not self.State.rangeVisualToggle

	-- FIXED: Use transparency instead of visible property
	if self.Visuals.collectionRangeIndicator then
		self.Visuals.collectionRangeIndicator.Transparency = self.State.rangeVisualToggle and 0.8 or 1
	end

	if self.Visuals.magnetRangeIndicator then
		self.Visuals.magnetRangeIndicator.Transparency = self.State.rangeVisualToggle and 0.9 or 1
	end

	if GameClient and GameClient.ShowNotification then
		GameClient:ShowNotification("Range Visuals", 
			"Range indicators " .. (self.State.rangeVisualToggle and "shown" or "hidden"), "info")
	end
end

function CollectionSystem:ToggleMagnet()
	self.Settings.magnetEnabled = not self.Settings.magnetEnabled

	if GameClient and GameClient.ShowNotification then
		GameClient:ShowNotification("Pet Magnet", 
			"Pet magnet " .. (self.Settings.magnetEnabled and "enabled" or "disabled"), "info")
	end
end

function CollectionSystem:UpdateVisualIndicators()
	-- Basic implementation for updating visual positions
	local character = LocalPlayer.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	local rootPart = character.HumanoidRootPart

	if self.Visuals.collectionRangeIndicator then
		local newSize = Vector3.new(self.CurrentStats.collectionRadius * 2, 0.5, self.CurrentStats.collectionRadius * 2)
		self.Visuals.collectionRangeIndicator.Size = newSize
		self.Visuals.collectionRangeIndicator.CFrame = rootPart.CFrame * CFrame.new(0, -2, 0)

		-- FIXED: Maintain transparency state instead of using visible
		self.Visuals.collectionRangeIndicator.Transparency = self.State.rangeVisualToggle and 0.8 or 1
	end

	if self.Visuals.magnetRangeIndicator then
		local newSize = Vector3.new(self.CurrentStats.magnetRange * 2, 0.3, self.CurrentStats.magnetRange * 2)
		self.Visuals.magnetRangeIndicator.Size = newSize
		self.Visuals.magnetRangeIndicator.CFrame = rootPart.CFrame * CFrame.new(0, -1.5, 0)

		-- FIXED: Maintain transparency state instead of using visible
		self.Visuals.magnetRangeIndicator.Transparency = self.State.rangeVisualToggle and 0.9 or 1
	end
end

function CollectionSystem:CreateVisualIndicatorsAlt()
	local character = LocalPlayer.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		LocalPlayer.CharacterAdded:Connect(function(newCharacter)
			wait(1)
			self:CreateVisualIndicatorsAlt()
		end)
		return
	end

	local success, errorMsg = pcall(function()
		local rootPart = character.HumanoidRootPart

		-- Remove existing indicators
		self:ClearVisualIndicators()

		-- Create a container for indicators
		local indicatorContainer = Instance.new("Folder")
		indicatorContainer.Name = "RangeIndicators"
		indicatorContainer.Parent = workspace

		-- Collection radius indicator
		local collectionIndicator = Instance.new("Part")
		collectionIndicator.Name = "CollectionRangeIndicator"
		collectionIndicator.Size = Vector3.new(self.CurrentStats.collectionRadius * 2, 0.5, self.CurrentStats.collectionRadius * 2)
		collectionIndicator.Shape = Enum.PartType.Cylinder
		collectionIndicator.Material = Enum.Material.ForceField
		collectionIndicator.Color = Color3.fromRGB(100, 255, 100)
		collectionIndicator.Transparency = 0.8
		collectionIndicator.CanCollide = false
		collectionIndicator.Anchored = true
		collectionIndicator.CFrame = rootPart.CFrame * CFrame.new(0, -2, 0)
		-- FIXED: Use Parent property to show/hide
		collectionIndicator.Parent = self.State.rangeVisualToggle and indicatorContainer or nil

		-- Magnet range indicator
		local magnetIndicator = Instance.new("Part")
		magnetIndicator.Name = "MagnetRangeIndicator"
		magnetIndicator.Size = Vector3.new(self.CurrentStats.magnetRange * 2, 0.3, self.CurrentStats.magnetRange * 2)
		magnetIndicator.Shape = Enum.PartType.Cylinder
		magnetIndicator.Material = Enum.Material.Neon
		magnetIndicator.Color = Color3.fromRGB(255, 100, 255)
		magnetIndicator.Transparency = 0.9
		magnetIndicator.CanCollide = false
		magnetIndicator.Anchored = true
		magnetIndicator.CFrame = rootPart.CFrame * CFrame.new(0, -1.5, 0)
		-- FIXED: Use Parent property to show/hide
		magnetIndicator.Parent = self.State.rangeVisualToggle and indicatorContainer or nil

		-- Store references
		self.Visuals.collectionRangeIndicator = collectionIndicator
		self.Visuals.magnetRangeIndicator = magnetIndicator
		self.Visuals.indicatorContainer = indicatorContainer

		-- Create pulsing animation for magnet indicator
		if magnetIndicator.Parent then
			self:CreateMagnetPulseAnimation(magnetIndicator)
		end
	end)

	if not success then
		warn("CollectionSystem: Failed to create visual indicators: " .. tostring(errorMsg))
	end
end

-- Alternative toggle function using Parent property:
function CollectionSystem:ToggleRangeVisualsAlt()
	self.State.rangeVisualToggle = not self.State.rangeVisualToggle

	-- FIXED: Use Parent property instead of visible
	if self.Visuals.collectionRangeIndicator then
		self.Visuals.collectionRangeIndicator.Parent = self.State.rangeVisualToggle and (self.Visuals.indicatorContainer or workspace) or nil
	end

	if self.Visuals.magnetRangeIndicator then
		self.Visuals.magnetRangeIndicator.Parent = self.State.rangeVisualToggle and (self.Visuals.indicatorContainer or workspace) or nil

		-- Restart animation if showing
		if self.State.rangeVisualToggle and self.Visuals.magnetRangeIndicator.Parent then
			self:CreateMagnetPulseAnimation(self.Visuals.magnetRangeIndicator)
		end
	end

	if GameClient and GameClient.ShowNotification then
		GameClient:ShowNotification("Range Visuals", 
			"Range indicators " .. (self.State.rangeVisualToggle and "shown" or "hidden"), "info")
	end
end

function CollectionSystem:StartUpdateLoop()
	RunService.Heartbeat:Connect(function()
		local currentTime = tick()

		if currentTime - self.State.lastUpdate >= self.Settings.visualUpdateInterval then
			self.State.lastUpdate = currentTime

			-- Update visual positions
			self:UpdateVisualIndicators()

			-- Process pet detection and collection
			self:ProcessPetDetection()
		end
	end)
end

function CollectionSystem:ProcessPetDetection()
	local character = LocalPlayer.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	local rootPart = character.HumanoidRootPart
	local playerPosition = rootPart.Position

	-- Find all areas and check for pets
	local areasFolder = workspace:FindFirstChild("Areas")
	if not areasFolder then return end

	for _, area in pairs(areasFolder:GetChildren()) do
		local petsFolder = area:FindFirstChild("Pets")
		if not petsFolder then continue end

		for _, pet in pairs(petsFolder:GetChildren()) do
			self:ProcessSinglePet(pet, playerPosition)
		end
	end
end

function CollectionSystem:ProcessSinglePet(pet, playerPosition)
	if not pet or not pet.Parent then return end

	-- Get pet position
	local petPosition = self:GetPetPosition(pet)
	if not petPosition then return end

	local distance = (playerPosition - petPosition).Magnitude

	-- Collection check (highest priority)
	if distance <= self.CurrentStats.collectionRadius then
		self:CollectPet(pet)
		return
	end

	-- Basic magnet effect (simplified for fallback mode)
	if self.Settings.magnetEnabled and distance <= self.CurrentStats.magnetRange then
		-- Simple attraction without complex tweening
		self:ApplyBasicMagnetEffect(pet, playerPosition, petPosition)
	end
end

function CollectionSystem:GetPetPosition(pet)
	if pet:IsA("Model") and pet.PrimaryPart then
		return pet.PrimaryPart.Position
	elseif pet:IsA("BasePart") then
		return pet.Position
	else
		-- Find any BasePart in the model
		for _, part in pairs(pet:GetDescendants()) do
			if part:IsA("BasePart") then
				return part.Position
			end
		end
	end
	return nil
end

function CollectionSystem:ApplyBasicMagnetEffect(pet, playerPosition, petPosition)
	-- Simplified magnet effect
	local targetPart = self:GetPetMainPart(pet)
	if not targetPart then return end

	-- Calculate direction toward player
	local direction = (playerPosition - petPosition).Unit
	local targetPosition = playerPosition - (direction * (self.CurrentStats.collectionRadius + 1))

	-- Simple position update without complex tweening
	if targetPart.Anchored then
		targetPart.Position = targetPosition
	else
		-- Use BodyPosition for unanchored parts
		local bodyPosition = targetPart:FindFirstChild("MagnetBodyPosition")
		if not bodyPosition then
			bodyPosition = Instance.new("BodyPosition")
			bodyPosition.Name = "MagnetBodyPosition"
			bodyPosition.MaxForce = Vector3.new(4000, 0, 4000)
			bodyPosition.Parent = targetPart
		end
		bodyPosition.Position = targetPosition

		-- Clean up after a short time
		game:GetService("Debris"):AddItem(bodyPosition, 2)
	end
end

function CollectionSystem:GetPetMainPart(pet)
	if pet:IsA("Model") and pet.PrimaryPart then
		return pet.PrimaryPart
	elseif pet:IsA("BasePart") then
		return pet
	else
		-- Find HumanoidRootPart or any BasePart
		local rootPart = pet:FindFirstChild("HumanoidRootPart")
		if rootPart then return rootPart end

		for _, part in pairs(pet:GetDescendants()) do
			if part:IsA("BasePart") then
				return part
			end
		end
	end
	return nil
end

function CollectionSystem:CollectPet(pet)
	if not self.RemoteEvents.CollectWildPet then 
		print("CollectionSystem: No remote event available for collection")
		return 
	end

	-- Prevent duplicate collection attempts
	local petId = tostring(pet)
	if pet:GetAttribute("CollectionAttempted") then return end

	pet:SetAttribute("CollectionAttempted", true)

	-- Fire server event
	local success, errorMsg = pcall(function()
		self.RemoteEvents.CollectWildPet:FireServer(pet)
	end)

	if not success then
		warn("CollectionSystem: Failed to collect pet: " .. tostring(errorMsg))
		pet:SetAttribute("CollectionAttempted", false)
		return
	end

	-- Create collection effect
	self:CreateCollectionEffect(pet)

	-- Reset collection attempt flag after delay
	spawn(function()
		wait(2)
		if pet and pet.Parent then
			pet:SetAttribute("CollectionAttempted", false)
		end
	end)
end

function CollectionSystem:CreateCollectionEffect(pet)
	local petPosition = self:GetPetPosition(pet)
	if not petPosition then return end

	-- Create simple sparkle effect
	for i = 1, 6 do
		local sparkle = Instance.new("Part")
		sparkle.Name = "CollectionSparkle"
		sparkle.Size = Vector3.new(0.3, 0.3, 0.3)
		sparkle.Shape = Enum.PartType.Ball
		sparkle.Material = Enum.Material.Neon
		sparkle.Color = Color3.fromRGB(255, 255, 0)
		sparkle.CanCollide = false
		sparkle.Anchored = true
		sparkle.Position = petPosition + Vector3.new(
			math.random(-2, 2),
			math.random(0, 3),
			math.random(-2, 2)
		)
		sparkle.Parent = workspace

		-- Simple animation
		local tween = TweenService:Create(sparkle,
			TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = sparkle.Position + Vector3.new(0, 5, 0),
				Transparency = 1,
				Size = Vector3.new(0.05, 0.05, 0.05)
			}
		)

		tween:Play()
		tween.Completed:Connect(function()
			sparkle:Destroy()
		end)
	end

	-- Play collection sound
	self:PlayCollectionSound()
end

function CollectionSystem:PlayCollectionSound()
	local character = LocalPlayer.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	local success, errorMsg = pcall(function()
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxasset://sounds/electronicpingsharp.wav"
		sound.Volume = 0.6
		sound.Parent = character.HumanoidRootPart
		sound:Play()

		game:GetService("Debris"):AddItem(sound, 2)
	end)

	if not success then
		print("CollectionSystem: Sound playback failed: " .. tostring(errorMsg))
	end
end

-- Cleanup function
function CollectionSystem:Cleanup()
	self:ClearVisualIndicators()
	print("CollectionSystem: Cleaned up")
end

-- Make globally available
_G.CollectionSystem = CollectionSystem

-- Initialize the system
local initSuccess, initError = pcall(function()
	CollectionSystem:Initialize()
end)

if not initSuccess then
	warn("CollectionSystem: Initialization failed: " .. tostring(initError))
	warn("CollectionSystem: Running in minimal mode")
else
	print("=== PET COLLECTION & MAGNET SYSTEM ACTIVE ===")
	print("Controls:")
	print("  R - Toggle range visual indicators")
	print("  M - Toggle pet magnet on/off")
	print("")
	print("Features:")
	print("  • Enhanced collection radius based on upgrades")
	print("  • Pet magnet pulls nearby pets toward you") 
	print("  • Visual range indicators (press R to show)")
	print("  • No need to walk directly into pets!")
end

-- Setup cleanup on character removing
LocalPlayer.CharacterRemoving:Connect(function()
	CollectionSystem:Cleanup()
end)

return CollectionSystem