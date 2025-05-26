-- MagneticPetCollection.client.lua
-- Fixed version with proper error handling and optimizations
-- Author: tb102502
-- Date: 2025-05-23 20:55:00

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Get player and character
local player = Players.LocalPlayer
local character = player.Character
local humanoid = character and character:FindFirstChildOfClass("Humanoid")
local rootPart = character and character:FindFirstChild("HumanoidRootPart")

-- Remote events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local CollectPet = RemoteEvents:WaitForChild("CollectPet")

-- Settings
local MAGNET_RANGE = 30 -- Base magnetic range
local PULSE_INTERVAL = 0.5 -- Seconds between magnetic pulses
local COLLECTION_RANGE = 5 -- Range to auto-collect pets

-- State
local isMagnetActive = false
local pulseTime = 0
local magnetField = nil
local attractedPets = {}
local activePetTweens = {}
local upgradedMagnetRange = MAGNET_RANGE

-- Sound effects
local collectSound = Instance.new("Sound")
collectSound.SoundId = "rbxassetid://6026984224" -- Default collect sound
collectSound.Volume = 0.8
collectSound.Parent = rootPart or workspace

local magnetActivateSound = Instance.new("Sound")
magnetActivateSound.SoundId = "rbxassetid://6026984224" -- Default activate sound
magnetActivateSound.Volume = 0.6
magnetActivateSound.Parent = rootPart or workspace

local comboSound = Instance.new("Sound")
comboSound.SoundId = "rbxassetid://6026984224" -- Default combo sound
comboSound.Volume = 0.7
comboSound.Parent = rootPart or workspace

local legendarySound = Instance.new("Sound")
legendarySound.SoundId = "rbxassetid://6026984224" -- Default legendary sound
legendarySound.Volume = 1
legendarySound.Parent = rootPart or workspace

-- Function to create visual magnetic field
local function createMagnetField()
	-- Remove existing field if it exists
	if magnetField then
		magnetField:Destroy()
		magnetField = nil
	end

	-- Create new field
	magnetField = Instance.new("Part")
	magnetField.Name = "MagnetField"
	magnetField.Shape = Enum.PartType.Ball
	magnetField.Size = Vector3.new(1, 1, 1) -- Will be scaled via CFrame
	magnetField.Transparency = 0.85
	magnetField.Material = Enum.Material.ForceField
	magnetField.Color = Color3.fromRGB(30, 200, 255)
	magnetField.CanCollide = false
	magnetField.Anchored = true
	magnetField.Parent = workspace.CurrentCamera -- Parent to camera to avoid replication

	-- Make it unselectable
	local noSelect = Instance.new("SelectionBox")
	noSelect.Adornee = magnetField
	noSelect.Visible = false
	noSelect.Parent = magnetField

	-- Add surfaceGui for pulse effect
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.Adornee = magnetField
	surfaceGui.Parent = magnetField

	local pulseFrame = Instance.new("Frame")
	pulseFrame.Size = UDim2.new(1, 0, 1, 0)
	pulseFrame.BackgroundTransparency = 1
	pulseFrame.BorderSizePixel = 0
	pulseFrame.Parent = surfaceGui

	local pulseCircle = Instance.new("ImageLabel")
	pulseCircle.Image = "rbxassetid://200182847" -- Circle image
	pulseCircle.Size = UDim2.new(1, 0, 1, 0)
	pulseCircle.Position = UDim2.new(0, 0, 0, 0)
	pulseCircle.BackgroundTransparency = 1
	pulseCircle.ImageTransparency = 0.5
	pulseCircle.ImageColor3 = Color3.fromRGB(30, 200, 255)
	pulseCircle.Parent = pulseFrame

	return magnetField
end

-- Function to pulse the magnet field
local function pulseMagnetField()
	if not magnetField or not magnetField.Parent then return end

	-- Create a pulse effect
	local pulseEffect = magnetField:Clone()
	pulseEffect.Name = "MagnetPulse"
	pulseEffect.Transparency = 0.7
	pulseEffect.Parent = workspace.CurrentCamera

	-- Tween the pulse effect
	local tweenInfo = TweenInfo.new(
		0.5, -- Duration
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out,
		0, -- RepeatCount (0 = don't repeat)
		false, -- Reverses
		0 -- DelayTime
	)

	local goal = {}
	goal.Size = Vector3.new(upgradedMagnetRange * 2, upgradedMagnetRange * 2, upgradedMagnetRange * 2)
	goal.Transparency = 1

	local tween = TweenService:Create(pulseEffect, tweenInfo, goal)
	tween:Play()

	-- Clean up after tween
	tween.Completed:Connect(function()
		pulseEffect:Destroy()
	end)

	-- Play activation sound
	magnetActivateSound:Play()
end

-- Function to attract a pet
local function attractPet(pet)
	if not rootPart or not pet or not pet.Parent then return end

	-- Don't attract the same pet twice
	local petId = tostring(pet)
	if attractedPets[petId] then return end

	-- Mark this pet as being attracted
	attractedPets[petId] = true

	-- Find the main part of the pet
	local petPart
	if pet:IsA("Model") and pet.PrimaryPart then
		petPart = pet.PrimaryPart
	else
		for _, part in pairs(pet:GetDescendants()) do
			if part:IsA("BasePart") then
				petPart = part
				break
			end
		end
	end

	if not petPart then 
		attractedPets[petId] = nil
		return 
	end

	-- Create a tween to move the pet toward the player
	local tweenInfo = TweenInfo.new(
		0.5, -- Duration
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.In,
		0, -- RepeatCount
		false, -- Reverses
		0 -- DelayTime
	)

	local goal = {}
	goal.Position = rootPart.Position + Vector3.new(0, 0, 2) -- Slightly in front of player

	local tween
	pcall(function()
		tween = TweenService:Create(petPart, tweenInfo, goal)
		tween:Play()

		-- Store the tween
		activePetTweens[petId] = tween

		-- Clean up when done
		tween.Completed:Connect(function()
			activePetTweens[petId] = nil

			-- If pet is close enough, collect it
			if pet and pet.Parent and rootPart and 
				(petPart.Position - rootPart.Position).Magnitude < COLLECTION_RANGE then

				-- Fire server event to collect
				CollectPet:FireServer(pet)
			else
				-- Not collected, remove from tracking
				attractedPets[petId] = nil
			end
		end)
	end)
end

-- Function to update magnet range based on player upgrades
local function updateMagnetRange()
	-- Default to base range
	upgradedMagnetRange = MAGNET_RANGE

	-- Try to get player data
	pcall(function()
		-- Check if RemoteFunctions exist
		local RemoteFunctions = ReplicatedStorage:FindFirstChild("RemoteFunctions")
		if not RemoteFunctions then return end

		-- Look for a GetPlayerData function
		local GetPlayerData = RemoteFunctions:FindFirstChild("GetPlayerData")
		if not GetPlayerData then return end

		-- Invoke it to get player data
		local playerData = GetPlayerData:InvokeServer()

		-- Check for collect range upgrade
		if playerData and playerData.upgrades and playerData.upgrades["collectRange"] then
			local upgradeLevel = playerData.upgrades["collectRange"]

			-- Calculate upgraded range (increase by 20% per level)
			upgradedMagnetRange = MAGNET_RANGE * (1 + (upgradeLevel * 0.2))
		end
	end)

	-- Update magnet field size
	if magnetField then
		magnetField.Size = Vector3.new(
			upgradedMagnetRange * 2, 
			upgradedMagnetRange * 2, 
			upgradedMagnetRange * 2
		)
	end
end

-- Function to handle pet collection
local function onCollectPet(pet, petData)
	-- Play sound based on rarity
	if petData and petData.rarity then
		if petData.rarity == "Legendary" then
			legendarySound:Play()
		elseif petData.rarity == "Epic" or petData.rarity == "Rare" then
			comboSound:Play()
		else
			collectSound:Play()
		end
	else
		collectSound:Play()
	end

	-- Clear from tracking
	local petId = tostring(pet)
	attractedPets[petId] = nil

	-- Cancel any active tween
	if activePetTweens[petId] then
		activePetTweens[petId]:Cancel()
		activePetTweens[petId] = nil
	end
end

-- Main update function
local function onHeartbeat(deltaTime)
	-- Make sure player exists
	if not player or not character or not rootPart then return end

	-- Position magnetic field at player
	if magnetField then
		magnetField.CFrame = CFrame.new(rootPart.Position)
	end

	-- Check if we should pulse
	pulseTime = pulseTime + deltaTime
	if pulseTime >= PULSE_INTERVAL then
		pulseTime = 0

		if isMagnetActive then
			pulseMagnetField()

			-- Find pets in range
			local areasFolder = workspace:FindFirstChild("Areas")
			if not areasFolder then return end

			-- Check each area for pets
			for _, area in pairs(areasFolder:GetChildren()) do
				local petsFolder = area:FindFirstChild("Pets")
				if not petsFolder then continue end

				for _, pet in pairs(petsFolder:GetChildren()) do
					-- Find pet position
					local petPosition

					if pet:IsA("Model") and pet.PrimaryPart then
						petPosition = pet.PrimaryPart.Position
					else
						for _, part in pairs(pet:GetDescendants()) do
							if part:IsA("BasePart") then
								petPosition = part.Position
								break
							end
						end
					end

					-- Check if in range
					if petPosition and (petPosition - rootPart.Position).Magnitude <= upgradedMagnetRange then
						-- Attract the pet
						attractPet(pet)
					end
				end
			end
		end
	end
end

-- Toggle magnetic field on keypress
local function onInputBegan(input, gameProcessed)
	if gameProcessed then return end

	-- F key to toggle magnetic field
	if input.KeyCode == Enum.KeyCode.F then
		isMagnetActive = not isMagnetActive

		if isMagnetActive then
			-- Show the field
			if not magnetField or not magnetField.Parent then
				magnetField = createMagnetField()
			end

			-- Update size
			updateMagnetRange()

			-- Set transparency
			magnetField.Transparency = 0.85

			-- Play activate sound
			magnetActivateSound:Play()
		else
			-- Hide the field
			if magnetField then
				magnetField.Transparency = 1
			end
		end
	end
end

-- Initialize the collection system
local function initialize()
	-- Create magnetic field
	createMagnetField()

	-- Update magnet range
	updateMagnetRange()

	-- Connect heartbeat
	RunService.Heartbeat:Connect(onHeartbeat)

	-- Connect input
	game:GetService("UserInputService").InputBegan:Connect(onInputBegan)

	-- Connect to collection event
	CollectPet.OnClientEvent:Connect(onCollectPet)

	-- Set up character added
	player.CharacterAdded:Connect(function(newCharacter)
		character = newCharacter
		humanoid = character:WaitForChild("Humanoid")
		rootPart = character:WaitForChild("HumanoidRootPart")

		-- Reset field
		createMagnetField()

		-- Re-create sounds with new parent
		collectSound.Parent = rootPart
		magnetActivateSound.Parent = rootPart
		comboSound.Parent = rootPart
		legendarySound.Parent = rootPart

		-- Reset state
		isMagnetActive = false
		pulseTime = 0
		attractedPets = {}
		activePetTweens = {}
	end)

	print("Magnetic pet collection system initialized")
end

-- Start the system
initialize()