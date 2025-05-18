-- PetCollectionClient.client.lua
-- Simplified client script for pet collection
-- Place in StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Ensure RemoteEvents folder exists
if not ReplicatedStorage:FindFirstChild("RemoteEvents") then
	local remoteEvents = Instance.new("Folder")
	remoteEvents.Name = "RemoteEvents"
	remoteEvents.Parent = ReplicatedStorage
end

-- Reference remote events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local CollectPet = RemoteEvents:WaitForChild("CollectPet")
local UpdatePlayerStats = RemoteEvents:WaitForChild("UpdatePlayerStats")

-- Sound effects
local function createSound(id, volume)
	local sound = Instance.new("Sound")
	volume = volume or 0.5

	-- Try to set the sound ID safely
	local success = pcall(function()
		sound.SoundId = id
	end)

	if not success then
		warn("Failed to load sound: " .. id)
		pcall(function()
			sound.SoundId = "rbxassetid://4612375502" -- Default click sound
		end)
	end

	sound.Volume = volume
	sound.Parent = player.PlayerGui
	return sound
end

local collectSound = createSound("rbxassetid://9125684553", 0.5)
local rarePetSound = createSound("rbxassetid://6156456968", 0.7)

-- Create particle effects for pet collection
local function createCollectionEffects(petModel, character, petType)
	if not petModel or not character then return end

	-- Get the position of the pet
	local petPos
	if typeof(petModel) == "Instance" then
		local rootPart = petModel:FindFirstChild("HumanoidRootPart")
		if rootPart then
			petPos = rootPart.Position
		else
			-- Try to find any part
			for _, part in pairs(petModel:GetDescendants()) do
				if part:IsA("BasePart") then
					petPos = part.Position
					break
				end
			end
		end
	end

	if not petPos then return end

	-- Get player position
	local playerPos
	local characterRootPart = character:FindFirstChild("HumanoidRootPart")
	if characterRootPart then
		playerPos = characterRootPart.Position
	else
		return
	end

	-- Determine the rarity of the pet
	local rarity = petType and petType.rarity or "Common"
	local particleColor
	local particleCount

	if rarity == "Common" then
		particleColor = Color3.fromRGB(200, 200, 200) -- Gray
		particleCount = 5
	elseif rarity == "Rare" then
		particleColor = Color3.fromRGB(30, 144, 255) -- Blue
		particleCount = 8
	elseif rarity == "Epic" then
		particleColor = Color3.fromRGB(138, 43, 226) -- Purple
		particleCount = 12
	elseif rarity == "Legendary" then
		particleColor = Color3.fromRGB(255, 215, 0) -- Gold
		particleCount = 15

		-- Play special sound for legendary
		rarePetSound:Play()
	else
		particleColor = Color3.fromRGB(200, 200, 200)
		particleCount = 5
	end

	-- Play collection sound
	collectSound:Play()

	-- Create particles
	for i = 1, particleCount do
		spawn(function()
			-- Create a particle
			local particle = Instance.new("Part")
			particle.Size = Vector3.new(0.5, 0.5, 0.5)
			particle.Shape = Enum.PartType.Ball
			particle.Material = Enum.Material.Neon
			particle.Color = particleColor
			particle.CanCollide = false
			particle.Anchored = true
			particle.Transparency = 0.3

			-- Add trail effect
			local attachment1 = Instance.new("Attachment")
			attachment1.Position = Vector3.new(-0.2, 0, 0)
			attachment1.Parent = particle

			local attachment2 = Instance.new("Attachment")
			attachment2.Position = Vector3.new(0.2, 0, 0)
			attachment2.Parent = particle

			local trail = Instance.new("Trail")
			trail.Attachment0 = attachment1
			trail.Attachment1 = attachment2
			trail.Lifetime = 0.2
			trail.MinLength = 0.05
			trail.MaxLength = 5
			trail.WidthScale = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0.1)
			})
			trail.Color = ColorSequence.new(particleColor)
			trail.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.3),
				NumberSequenceKeypoint.new(1, 1)
			})
			trail.Parent = particle

			-- Position at random spot around pet
			local offset = Vector3.new(
				math.random(-2, 2),
				math.random(-2, 2),
				math.random(-2, 2)
			)
			particle.Position = petPos + offset
			particle.Parent = workspace.CurrentCamera

			-- Create a curved path to player
			local startTime = tick()
			local journeyTime = 0.6 + math.random() * 0.4 -- 0.6-1 second duration

			-- Random bezier curve control point
			local controlPoint = petPos + Vector3.new(
				math.random(-5, 5),
				math.random(2, 8),
				math.random(-5, 5)
			)

			-- Animate particle along path
			while tick() - startTime < journeyTime do
				-- Bezier curve formula
				local t = (tick() - startTime) / journeyTime
				local oneMinusT = 1 - t

				particle.Position = 
					(oneMinusT^2 * petPos) + 
					(2 * oneMinusT * t * controlPoint) + 
					(t^2 * playerPos)

				-- Shrink as it approaches player
				particle.Size = Vector3.new(0.5, 0.5, 0.5) * (1 - t*0.7)

				-- Fade out near the end
				if t > 0.7 then
					particle.Transparency = 0.3 + (t - 0.7) * 3.33
				end

				RunService.Heartbeat:Wait()
			end

			-- Remove particle
			particle:Destroy()
		end)
	end
end
	

-- Handle pet collection server event
CollectPet.OnClientEvent:Connect(function(petModel, petTypeData)
	print("CLIENT: Received pet collection confirmation")

	-- Create visual effects for the collection
	createCollectionEffects(petModel, character, petTypeData)
end) -- Add this end statement to close the CollectPet.OnClientEvent:Connect function

-- Listen for character respawns
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	-- Wait for humanoid root part
	if not character:FindFirstChild("HumanoidRootPart") then
		character:WaitForChild("HumanoidRootPart", 5)
	end
end)

-- Set up click detection
local function setupPetClickDetection()
	local mouse = player:GetMouse()

	-- Mouse click detection
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.UserInputType == Enum.UserInputType.MouseButton1 or
			input.UserInputType == Enum.UserInputType.Touch then
			-- Cast a ray from the mouse position
			local target = mouse.Target
			if not target then return end

			-- Try to find parent pet model
			local petModel = target
			while petModel and petModel.Parent and not petModel:GetAttribute("PetType") do
				petModel = petModel.Parent

				-- Stop if we've gone too far up the hierarchy
				if petModel == workspace then
					petModel = nil
					break
				end
			end

			-- Check if we found a pet model
			if petModel and petModel:GetAttribute("PetType") then
				print("CLIENT: Clicked on pet:", petModel:GetAttribute("PetType"))

				-- Animate pet being collected
				local primaryPart = petModel.PrimaryPart or petModel:FindFirstChild("HumanoidRootPart")
				

				-- Tween the pet up and fade it out
				local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

				-- For each part, tween its transparency
				for _, part in pairs(petModel:GetDescendants()) do
					if part:IsA("BasePart") then
						local tween = TweenService:Create(
							part,
							tweenInfo,
							{Transparency = 1}
						)
						tween:Play()
					end
				end

				-- If there's a primary part, tween its position
				
				-- Fire server event to collect the pet
				CollectPet:FireServer(petModel)
			end
		end
	end)

	-- Debug key 'K' for collecting nearest pet
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end

		if input.KeyCode == Enum.KeyCode.K then
			print("CLIENT: Debug key pressed - collecting nearest pet")

			-- Find nearest pet
			local nearestPet = nil
			local nearestDistance = 50 -- Within 50 studs

			if character and character:FindFirstChild("HumanoidRootPart") then
				local rootPos = character.HumanoidRootPart.Position

				-- Check all areas for pets
				for _, areaModel in pairs(workspace:FindFirstChild("Areas"):GetChildren()) do
					local petsFolder = areaModel:FindFirstChild("Pets")
					if petsFolder then
						for _, pet in pairs(petsFolder:GetChildren()) do
							-- Skip if being collected or already tweening
							if pet:GetAttribute("BeingCollected") then continue end

							-- Get pet position
							local petPos
							if pet:IsA("Model") and pet.PrimaryPart then
								petPos = pet.PrimaryPart.Position
							elseif pet:IsA("BasePart") then
								petPos = pet.Position
							else
								continue
							end

							-- Calculate distance
							local distance = (rootPos - petPos).Magnitude
							if distance < nearestDistance then
								nearestPet = pet
								nearestDistance = distance
							end
						end
					end
				end

				if nearestPet then
					print("CLIENT: Found nearest pet:", nearestPet:GetAttribute("PetType"), "at distance", nearestDistance)

					-- Mark as being collected to prevent double collection
					nearestPet:SetAttribute("BeingCollected", true)

					-- Fire collection event
					CollectPet:FireServer(nearestPet)
				else
					print("CLIENT: No pets found within range")
				end
			else
				print("CLIENT: Character or HumanoidRootPart not found")
			end
		end
	end)
end

-- Set up pet click detection
setupPetClickDetection()

print("PetCollection Client script loaded!")