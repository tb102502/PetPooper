--[[
    PetCollectionMagnetSystem.client.lua - ENHANCED COLLECTION SYSTEM
    Place in: StarterPlayerScripts/PetCollectionMagnetSystem.client.lua
    
    FEATURES:
    1. Collection radius based on upgrades
    2. Pet magnet that pulls pets toward player
    3. Upgraded proximity detection
    4. Visual effects for collection ranges
    5. No need to walk directly into pets
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- Wait for GameClient
local GameClient = _G.GameClient
if not GameClient then
	local clientReady = ReplicatedStorage:WaitForChild("GameClientReady", 10)
	if clientReady then
		clientReady.Event:Wait()
		GameClient = _G.GameClient
	end
end

if not GameClient then
	error("PetCollectionMagnetSystem: GameClient not available")
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
	-- Get remote events
	local gameRemotes = ReplicatedStorage:WaitForChild("GameRemotes", 10)
	if gameRemotes then
		self.RemoteEvents.CollectWildPet = gameRemotes:FindFirstChild("CollectWildPet")
		self.RemoteEvents.PlayerDataUpdated = gameRemotes:FindFirstChild("PlayerDataUpdated")
	end

	-- Setup visual indicators
	self:CreateVisualIndicators()

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

-- Create visual range indicators
function CollectionSystem:CreateVisualIndicators()
	local character = LocalPlayer.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		-- Wait for character to load
		LocalPlayer.CharacterAdded:Connect(function(newCharacter)
			wait(1)
			self:CreateVisualIndicators()
		end)
		return
	end

	local rootPart = character.HumanoidRootPart

	-- Remove existing indicators
	self:ClearVisualIndicators()

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
	collectionIndicator.Parent = workspace

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
	magnetIndicator.Parent = workspace

	-- Store references
	self.Visuals.collectionRangeIndicator = collectionIndicator
	self.Visuals.magnetRangeIndicator = magnetIndicator

	-- Set initial visibility
	collectionIndicator.Visible = self.State.rangeVisualToggle
	magnetIndicator.Visible = self.State.rangeVisualToggle

	-- Create pulsing animation for magnet indicator
	self:CreateMagnetPulseAnimation(magnetIndicator)
end

-- Create pulsing animation for magnet range
function CollectionSystem:CreateMagnetPulseAnimation(magnetIndicator)
	if not magnetIndicator then return end

	local pulseInfo = TweenInfo.new(
		2, -- Duration
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut,
		-1, -- Repeat infinitely
		true -- Reverse
	)

	local pulseTween = TweenService:Create(magnetIndicator, pulseInfo, {
		Transparency = 0.7
	})

	pulseTween:Play()
	self.Visuals.activeTweens[magnetIndicator] = pulseTween
end

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

	-- Clear all active tweens
	for object, tween in pairs(self.Visuals.activeTweens) do
		if tween then
			tween:Cancel()
		end
	end
	self.Visuals.activeTweens = {}
end

-- Update stats from player data
function CollectionSystem:UpdateStatsFromPlayerData()
	local playerData = GameClient:GetPlayerData()
	if not playerData or not playerData.upgrades then return end

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

-- Update visual indicator sizes and positions
function CollectionSystem:UpdateVisualIndicators()
	local character = LocalPlayer.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	local rootPart = character.HumanoidRootPart

	-- Update collection indicator
	if self.Visuals.collectionRangeIndicator then
		local newSize = Vector3.new(self.CurrentStats.collectionRadius * 2, 0.5, self.CurrentStats.collectionRadius * 2)
		self.Visuals.collectionRangeIndicator.Size = newSize
		self.Visuals.collectionRangeIndicator.CFrame = rootPart.CFrame * CFrame.new(0, -2, 0)
	end

	-- Update magnet indicator
	if self.Visuals.magnetRangeIndicator then
		local newSize = Vector3.new(self.CurrentStats.magnetRange * 2, 0.3, self.CurrentStats.magnetRange * 2)
		self.Visuals.magnetRangeIndicator.Size = newSize
		self.Visuals.magnetRangeIndicator.CFrame = rootPart.CFrame * CFrame.new(0, -1.5, 0)
	end
end

-- Connect to player data updates
function CollectionSystem:ConnectToDataUpdates()
	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated.OnClientEvent:Connect(function()
			self:UpdateStatsFromPlayerData()
		end)
	end

	-- Also listen for character respawning
	LocalPlayer.CharacterAdded:Connect(function()
		wait(2) -- Wait for character to fully load
		self:CreateVisualIndicators()
		self:UpdateStatsFromPlayerData()
	end)
end

-- Setup input handlers
function CollectionSystem:SetupInputHandlers()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		-- R key to toggle range visuals
		if input.KeyCode == Enum.KeyCode.R then
			self:ToggleRangeVisuals()
		end

		-- M key to toggle magnet
		if input.KeyCode == Enum.KeyCode.M then
			self:ToggleMagnet()
		end
	end)
end

-- Toggle range visual indicators
function CollectionSystem:ToggleRangeVisuals()
	self.State.rangeVisualToggle = not self.State.rangeVisualToggle

	if self.Visuals.collectionRangeIndicator then
		self.Visuals.collectionRangeIndicator.Visible = self.State.rangeVisualToggle
	end

	if self.Visuals.magnetRangeIndicator then
		self.Visuals.magnetRangeIndicator.Visible = self.State.rangeVisualToggle
	end

	if GameClient and GameClient.ShowNotification then
		GameClient:ShowNotification("Range Visuals", 
			"Range indicators " .. (self.State.rangeVisualToggle and "shown" or "hidden"), "info")
	end
end

-- Toggle magnet functionality
function CollectionSystem:ToggleMagnet()
	self.Settings.magnetEnabled = not self.Settings.magnetEnabled

	if GameClient and GameClient.ShowNotification then
		GameClient:ShowNotification("Pet Magnet", 
			"Pet magnet " .. (self.Settings.magnetEnabled and "enabled" or "disabled"), "info")
	end
end

-- Main update loop
function CollectionSystem:StartUpdateLoop()
	RunService.Heartbeat:Connect(function()
		local currentTime = tick()

		-- Update at specified intervals
		if currentTime - self.State.lastUpdate >= self.Settings.visualUpdateInterval then
			self.State.lastUpdate = currentTime

			-- Update visual positions
			self:UpdateVisualIndicators()

			-- Process pet detection and collection
			self:ProcessPetDetection()
		end
	end)
end

-- Process pet detection, magnetism, and collection
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

-- Process a single pet for magnetism and collection
function CollectionSystem:ProcessSinglePet(pet, playerPosition)
	if not pet or not pet.Parent then return end

	-- Get pet position
	local petPosition = self:GetPetPosition(pet)
	if not petPosition then return end

	local distance = (playerPosition - petPosition).Magnitude
	local petId = tostring(pet)

	-- Collection check (highest priority)
	if distance <= self.CurrentStats.collectionRadius then
		self:CollectPet(pet)
		return
	end

	-- Magnet effect
	if self.Settings.magnetEnabled and distance <= self.CurrentStats.magnetRange then
		self:ApplyMagnetEffect(pet, playerPosition, petPosition, petId)
	else
		-- Remove from attracted pets if outside range
		if self.Visuals.attractedPets[petId] then
			self:StopAttractingPet(petId)
		end
	end
end

-- Get pet's position (handles both models and parts)
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

-- Apply magnet effect to pull pet toward player
function CollectionSystem:ApplyMagnetEffect(pet, playerPosition, petPosition, petId)
	-- Don't attract the same pet multiple times
	if self.Visuals.attractedPets[petId] then return end

	-- Mark as attracted
	self.Visuals.attractedPets[petId] = true

	-- Get the part to move
	local targetPart = self:GetPetMainPart(pet)
	if not targetPart then
		self.Visuals.attractedPets[petId] = nil
		return
	end

	-- Calculate target position (closer to player)
	local direction = (playerPosition - petPosition).Unit
	local targetPosition = playerPosition - (direction * (self.CurrentStats.collectionRadius + 1))

	-- Create magnet pull tween
	local magnetInfo = TweenInfo.new(
		1.5, -- Duration
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out,
		0, -- No repeat
		false -- No reverse
	)

	local tween = TweenService:Create(targetPart, magnetInfo, {
		Position = targetPosition
	})

	-- Store the tween
	self.Visuals.activeTweens[petId] = tween

	-- Start the tween
	tween:Play()

	-- Add visual effect
	self:CreateMagnetVisualEffect(pet, targetPart)

	-- Clean up when tween completes
	tween.Completed:Connect(function()
		self:StopAttractingPet(petId)
	end)
end

-- Get the main part of a pet for movement
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

-- Create visual effect for magnet pull
function CollectionSystem:CreateMagnetVisualEffect(pet, targetPart)
	-- Create sparkle trail effect
	local effect = Instance.new("Part")
	effect.Name = "MagnetEffect"
	effect.Size = Vector3.new(0.5, 0.5, 0.5)
	effect.Shape = Enum.PartType.Ball
	effect.Material = Enum.Material.Neon
	effect.Color = Color3.fromRGB(255, 100, 255)
	effect.CanCollide = false
	effect.Anchored = false
	effect.Position = targetPart.Position
	effect.Parent = workspace

	-- Attach effect to pet
	local attachment = Instance.new("Attachment")
	attachment.Parent = targetPart

	local effectAttachment = Instance.new("Attachment")
	effectAttachment.Parent = effect

	local alignPosition = Instance.new("AlignPosition")
	alignPosition.Attachment0 = effectAttachment
	alignPosition.Attachment1 = attachment
	alignPosition.MaxForce = 50000
	alignPosition.Responsiveness = 10
	alignPosition.Parent = effect

	-- Fade out effect over time
	local fadeInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fadeTween = TweenService:Create(effect, fadeInfo, {
		Transparency = 1,
		Size = Vector3.new(0.1, 0.1, 0.1)
	})

	fadeTween:Play()
	fadeTween.Completed:Connect(function()
		effect:Destroy()
	end)

	-- Clean up after 3 seconds regardless
	game:GetService("Debris"):AddItem(effect, 3)
end

-- Stop attracting a pet
function CollectionSystem:StopAttractingPet(petId)
	-- Remove from attracted pets
	self.Visuals.attractedPets[petId] = nil

	-- Cancel any active tween
	if self.Visuals.activeTweens[petId] then
		self.Visuals.activeTweens[petId]:Cancel()
		self.Visuals.activeTweens[petId] = nil
	end
end

-- Collect a pet
function CollectionSystem:CollectPet(pet)
	if not self.RemoteEvents.CollectWildPet then return end

	-- Prevent duplicate collection attempts
	local petId = tostring(pet)
	if pet:GetAttribute("CollectionAttempted") then return end

	pet:SetAttribute("CollectionAttempted", true)

	-- Fire server event
	self.RemoteEvents.CollectWildPet:FireServer(pet)

	-- Create collection effect
	self:CreateCollectionEffect(pet)

	-- Stop attracting this pet
	self:StopAttractingPet(petId)

	-- Reset collection attempt flag after delay
	spawn(function()
		wait(2)
		if pet and pet.Parent then
			pet:SetAttribute("CollectionAttempted", false)
		end
	end)
end

-- Create collection effect
function CollectionSystem:CreateCollectionEffect(pet)
	local petPosition = self:GetPetPosition(pet)
	if not petPosition then return end

	-- Create sparkle effect
	for i = 1, 8 do
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

		-- Animate sparkle
		local sparkleInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local sparkleTween = TweenService:Create(sparkle, sparkleInfo, {
			Position = sparkle.Position + Vector3.new(0, 5, 0),
			Transparency = 1,
			Size = Vector3.new(0.05, 0.05, 0.05)
		})

		sparkleTween:Play()
		sparkleTween.Completed:Connect(function()
			sparkle:Destroy()
		end)
	end

	-- Play collection sound
	self:PlayCollectionSound()
end

-- Play collection sound
function CollectionSystem:PlayCollectionSound()
	local character = LocalPlayer.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/electronicpingsharp.wav"
	sound.Volume = 0.6
	--sound.Pitch = 1.3
	sound.Parent = character.HumanoidRootPart

	sound:Play()

	-- Clean up sound
	game:GetService("Debris"):AddItem(sound, 2)
end

-- Get current collection stats for display
function CollectionSystem:GetCurrentStats()
	return {
		collectionRadius = self.CurrentStats.collectionRadius,
		magnetRange = self.CurrentStats.magnetRange,
		magnetStrength = self.CurrentStats.magnetStrength,
		magnetEnabled = self.Settings.magnetEnabled,
		visualsEnabled = self.State.rangeVisualToggle
	}
end

-- Public API functions
function CollectionSystem:SetCollectionRadius(radius)
	self.CurrentStats.collectionRadius = math.max(1, radius)
	self:UpdateVisualIndicators()
end

function CollectionSystem:SetMagnetRange(range)
	self.CurrentStats.magnetRange = math.max(1, range)
	self:UpdateVisualIndicators()
end

function CollectionSystem:SetMagnetStrength(strength)
	self.CurrentStats.magnetStrength = math.max(0.1, strength)
end

-- Cleanup function
function CollectionSystem:Cleanup()
	-- Clear all visual elements
	self:ClearVisualIndicators()

	-- Clear attracted pets
	for petId, _ in pairs(self.Visuals.attractedPets) do
		self:StopAttractingPet(petId)
	end

	print("CollectionSystem: Cleaned up")
end

-- Make globally available
_G.CollectionSystem = CollectionSystem

-- Initialize the system
CollectionSystem:Initialize()

-- Setup cleanup on character removing
LocalPlayer.CharacterRemoving:Connect(function()
	CollectionSystem:Cleanup()
end)

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

return CollectionSystem