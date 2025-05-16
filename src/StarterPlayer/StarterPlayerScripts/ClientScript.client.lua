-- Pet Collection Simulator
-- Client Script (LocalScript in StarterPlayerScripts)

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Get the local player
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Create RemoteEvents folder if needed
if not ReplicatedStorage:FindFirstChild("RemoteEvents") then
	local remoteEvents = Instance.new("Folder")
	remoteEvents.Name = "RemoteEvents"
	remoteEvents.Parent = ReplicatedStorage
end

if not ReplicatedStorage:FindFirstChild("RemoteFunctions") then
	local remoteFunctions = Instance.new("Folder")
	remoteFunctions.Name = "RemoteFunctions"
	remoteFunctions.Parent = ReplicatedStorage
end

-- Reference remote events and functions
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

-- Ensure required remote events exist
local function ensureRemoteEventExists(name)
	if not RemoteEvents:FindFirstChild(name) then
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = RemoteEvents
		return event
	end
	return RemoteEvents:WaitForChild(name)
end

local function ensureRemoteFunctionExists(name)
	if not RemoteFunctions:FindFirstChild(name) then
		local func = Instance.new("RemoteFunction")
		func.Name = name
		func.Parent = RemoteFunctions
		return func
	end
	return RemoteFunctions:WaitForChild(name)
end

-- Create or reference the required RemoteEvents
local CollectPet = ensureRemoteEventExists("CollectPet")
local BuyUpgrade = ensureRemoteEventExists("BuyUpgrade")
local UnlockArea = ensureRemoteEventExists("UnlockArea")
local UpdatePlayerStats = ensureRemoteEventExists("UpdatePlayerStats")

-- Create or reference the required RemoteFunctions
local GetPlayerData = ensureRemoteFunctionExists("GetPlayerData")

-- Get player data
local playerData
local success, result = pcall(function()
	return GetPlayerData:InvokeServer()
end)

if success and result then
	playerData = result
	print("Successfully loaded player data")
else
	warn("Failed to get player data: " .. tostring(result))
	-- Create default player data
	playerData = {
		coins = 0,
		gems = 0,
		pets = {},
		unlockedAreas = {"Starter Meadow"},
		upgrades = {
			["Collection Speed"] = 1,
			["Pet Capacity"] = 1,
			["Collection Value"] = 1
		}
	}
end

-- Debug function to print player data
local function printPlayerData()
	print("Player Data:")
	print("- Coins: " .. playerData.coins)
	print("- Gems: " .. playerData.gems)
	print("- Pets: " .. #playerData.pets)
	for i, pet in ipairs(playerData.pets) do
		print("  - " .. i .. ": " .. pet.name .. " (" .. pet.rarity .. ")")
	end
	print("- Unlocked Areas: " .. table.concat(playerData.unlockedAreas, ", "))
end

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
		-- Set a fallback sound ID if available
		pcall(function()
			sound.SoundId = "rbxassetid://4612375502" -- Default click sound
		end)
	end

	sound.Volume = volume
	sound.Parent = player.PlayerGui
	return sound
end

local collectSound = createSound("rbxassetid://9125684553", 0.5) or createSound("rbxassetid://4612375502", 0.5)
local rarePetSound = createSound("rbxassetid://6156456968", 0.7) or createSound("rbxassetid://5852311527", 0.7)

-- Create particle effects for pet collection
local function createCollectionEffects(petModel, character)
	if not petModel or not character then return end

	-- Get the position of the pet
	local petPos
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
	local rarity = petModel:GetAttribute("Rarity") or "Common"
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
	end

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
				-- Bezier curve formula: B(t) = (1-t)^2 * P0 + 2(1-t)t * P1 + t^2 * P2
				-- Where P0 is start, P1 is control point, P2 is end point
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
					particle.Transparency = 0.3 + (t - 0.7) * 3.33 -- Fade from 0.3 to 1 in last 30% of journey
				end

				RunService.Heartbeat:Wait()
			end

			-- Remove particle
			particle:Destroy()
		end)
	end
end


-- Handle pet collection
CollectPet.OnClientEvent:Connect(function(petModel, petTypeData)
	if not petModel or not petTypeData then return end

	print("Collected pet: " .. petTypeData.name .. " (" .. petTypeData.rarity .. ")")

	-- Play collection sound
	if collectSound then
		collectSound:Play()
	end

	-- Create collection visual effects
	createCollectionEffects(petModel, character)

	-- The server should update the player data and send it back via UpdatePlayerStats
	-- We don't modify playerData here directly
end)

-- Custom pet click detection
local function setupPetClickDetection()
	-- Mouse click detection
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.UserInputType == Enum.UserInputType.MouseButton1 or
			input.UserInputType == Enum.UserInputType.Touch then
			-- Cast a ray from the mouse position
			local mousePos = input.Position
			local camera = workspace.CurrentCamera

			local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
			raycastParams.FilterDescendantsInstances = {character}

			local result = workspace:Raycast(ray.Origin, ray.Direction * 100, raycastParams)

			if result and result.Instance then
				-- Find parent model
				local model = result.Instance
				while model and model.Parent and model.Parent ~= workspace and model.Parent.Name ~= "Pets" do
					model = model.Parent
				end

				-- Check if it's a pet model
				if model and model:IsA("Model") and model:GetAttribute("PetType") then
					print("Clicked on pet: " .. model:GetAttribute("PetType"))

					-- Find the pet type data
					local petType = model:GetAttribute("PetType")
					local petValue = model:GetAttribute("Value") or 1
					local petRarity = model:GetAttribute("Rarity") or "Common"

					-- Create pet type data
					local petTypeData = {
						name = petType,
						rarity = petRarity,
						collectValue = petValue
					}

					-- Enhanced debug info
					print("CLIENT DEBUG: Attempting to fire CollectPet event to server")
					print("CLIENT DEBUG: Type of petModel:", typeof(model))
					print("CLIENT DEBUG: Pet model class:", model.ClassName)
					print("CLIENT DEBUG: Pet model name:", model.Name)
					print("CLIENT DEBUG: Pet attributes:", 
						model:GetAttribute("PetType"),
						model:GetAttribute("Rarity"),
						model:GetAttribute("Value"))

					-- Make sure we're using the correct RemoteEvent
					local CollectPet = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("CollectPet")
					print("CLIENT DEBUG: Found CollectPet RemoteEvent:", CollectPet and "Yes" or "No")

					-- Fire server event to collect the pet
					CollectPet:FireServer(model, "TestPetCollection")
				end
			end
		end
	end)
end

-- Update player data from server
UpdatePlayerStats.OnClientEvent:Connect(function(newData)
	print("CLIENT_DEBUG: Received player data update")

	if not newData then
		warn("CLIENT_DEBUG: ERROR - Received nil data")
		return
	end

	print("CLIENT_DEBUG: Pet count in received data:", #newData.pets)
	for i, pet in ipairs(newData.pets) do
		print("CLIENT_DEBUG: Pet", i, "-", pet.name, "(", pet.rarity, ")")
	end

	playerData = newData

	-- Debug print
	printPlayerData()

	-- Update UI (this function would be defined in your GUI script)
	-- You would call functions like UpdateStats(), UpdateInventory(), etc.

	-- If you have a main GUI script that handles the UI, you can fire a local event to it
	-- For example:
	if script.Parent:FindFirstChild("UpdateUIEvent") then
		script.Parent.UpdateUIEvent:Fire(playerData)
	else
		local updateEvent = Instance.new("BindableEvent")
		updateEvent.Name = "UpdateUIEvent"
		updateEvent.Parent = script.Parent
		updateEvent:Fire(playerData)
	end
end)

-- Listen for character respawns
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	-- Wait for humanoid root part
	if not character:FindFirstChild("HumanoidRootPart") then
		character:WaitForChild("HumanoidRootPart", 5)
	end
end)

-- Test function for collection
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.T then
		print("CLIENT DEBUG: Test collection initiated with key T")

		-- Create a simple test pet data and send it directly
		local testPet = {
			name = "Test Corgi",
			rarity = "Legendary",
			value = 100,
			modelName = "Corgi"
		}

		print("CLIENT DEBUG: Firing direct test collection event")
		CollectPet:FireServer("TestPet", testPet)
	end
end)

-- Setup pet click detection
setupPetClickDetection()

-- Check if inventory GUI exists and create UpdateUIEvent
local function setupUIConnections()
	-- Wait for PlayerGui
	local playerGui = player:WaitForChild("PlayerGui")

	-- Wait for MainGui (adjust name if needed)
	local mainGui = playerGui:WaitForChild("MainGui", 10)
	if not mainGui then
		warn("MainGui not found in PlayerGui")
		return
	end

	-- Create or get UpdateUIEvent
	local updateEvent = script.Parent:FindFirstChild("UpdateUIEvent")
	if not updateEvent then
		updateEvent = Instance.new("BindableEvent")
		updateEvent.Name = "UpdateUIEvent"
		updateEvent.Parent = script.Parent
	end

	-- Try to find GUI script
	local guiScript = mainGui:FindFirstChild("GUI")
	if guiScript and guiScript:IsA("LocalScript") then
		print("Found GUI script, setting up connections")

		-- Fire initial update
		updateEvent:Fire(playerData)
	else
		warn("GUI script not found in MainGui")
	end
end

-- Setup UI connections
spawn(setupUIConnections)

print("Pet Collection Client loaded!")