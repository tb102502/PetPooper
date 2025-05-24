-- PetShopSystem.lua
-- Handles pet purchases and connecting shop to actual pet models
-- Author: tb102502
-- Date: 2025-05-23 22:50:00

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetShopSystem = {}

-- Dependencies
local PetRegistry = require(ReplicatedStorage.Modules.PetRegistry)
local PlayerDataService = require(ServerStorage.Modules.PlayerDataService)

-- Error handling wrapper
local function safeCall(func, ...)
	local success, result = pcall(func, ...)
	if not success then
		warn("PetShopSystem Error: " .. tostring(result))
		return false
	end
	return success, result
end

-- Ensure pet models folder exists
local function ensurePetModelsFolder()
	local petModels = ReplicatedStorage:FindFirstChild("PetModels")
	if not petModels then
		petModels = Instance.new("Folder")
		petModels.Name = "PetModels"
		petModels.Parent = ReplicatedStorage

		-- Create basic placeholder models for testing
		local basicPetTypes = {"Bunny", "Puppy", "Cat", "Duck", "Fox", "Raccoon", "Dragon", "Unicorn", "Phoenix", "Robot"}

		for _, petType in ipairs(basicPetTypes) do
			local model = Instance.new("Model")
			model.Name = petType

			local part = Instance.new("Part")
			part.Shape = Enum.PartType.Ball
			part.Size = Vector3.new(2, 2, 2)
			part.Position = Vector3.new(0, 0, 0)
			part.Anchored = true
			part.CanCollide = false
			part.Parent = model

			model.PrimaryPart = part
			model:PivotTo(CFrame.new(0, 0, 0))
			model.Parent = petModels

			-- Add model attributes
			model:SetAttribute("PetType", petType)
		end

		print("Created placeholder pet models in ReplicatedStorage")
	end

	return petModels
end

-- Initialize shop with pets from registry
function PetShopSystem.Initialize()
	-- Ensure pet models folder exists
	local petModels = ensurePetModelsFolder()

	-- Create RemoteFunction if it doesn't exist
	local remoteFunctions = ReplicatedStorage:FindFirstChild("RemoteFunctions")
	if not remoteFunctions then
		remoteFunctions = Instance.new("Folder")
		remoteFunctions.Name = "RemoteFunctions"
		remoteFunctions.Parent = ReplicatedStorage
	end

	local buyPetFunction = remoteFunctions:FindFirstChild("BuyPet")
	if not buyPetFunction then
		buyPetFunction = Instance.new("RemoteFunction")
		buyPetFunction.Name = "BuyPet"
		buyPetFunction.Parent = remoteFunctions
	end

	-- Connect the remote function
	buyPetFunction.OnServerInvoke = function(player, petId)
		return PetShopSystem.PurchasePet(player, petId)
	end

	print("PetShopSystem initialized successfully")
	return true
end

-- Get all available pets for the shop
function PetShopSystem.GetShopPets()
	return PetRegistry.Pets
end

-- Purchase a pet
function PetShopSystem.PurchasePet(player, petId)
	-- Get pet details
	local petInfo = PetRegistry.GetPetById(petId)
	if not petInfo then
		return false, "Pet not found"
	end

	-- Get player data
	local playerData = PlayerDataService.GetPlayerData(player)
	if not playerData then
		return false, "Player data not found"
	end

	-- Check if player has enough coins
	if playerData.coins < petInfo.price then
		return false, "Not enough coins"
	end

	-- Deduct coins
	playerData.coins = playerData.coins - petInfo.price

	-- Get or create owned pets list
	playerData.ownedPets = playerData.ownedPets or {}

	-- Generate unique ID for this pet instance
	local uniquePetId = petId .. "_" .. os.time() .. "_" .. math.random(1000, 9999)

	-- Create pet data
	local newPet = {
		id = uniquePetId,
		petType = petId,
		rarity = petInfo.rarity,
		level = 1,
		experience = 0,
		equipped = false,
		dateAcquired = os.time(),
		stats = {
			coinMultiplier = petInfo.abilities.coinMultiplier or 1,
			collectRange = petInfo.abilities.collectRange or 1,
			collectSpeed = petInfo.abilities.collectSpeed or 1
		}
	}

	-- Add to player's owned pets
	table.insert(playerData.ownedPets, newPet)

	-- Save player data
	safeCall(function()
		PlayerDataService.SavePlayerData(player)
	end)

	-- Fire client notification
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local sendNotification = remoteEvents:FindFirstChild("SendNotification")
		if sendNotification then
			sendNotification:FireClient(
				player,
				"New Pet!",
				"You've purchased a " .. petInfo.displayName .. "!",
				"success"
			)
		end

		local updateInventory = remoteEvents:FindFirstChild("UpdateInventory")
		if updateInventory then
			updateInventory:FireClient(player)
		end
	end

	return true, "Successfully purchased " .. petInfo.displayName, uniquePetId
end

-- Equip a pet
function PetShopSystem.EquipPet(player, petInstanceId)
	-- Get player data
	local playerData = PlayerDataService.GetPlayerData(player)
	if not playerData then
		return false, "Player data not found"
	end

	-- Find the pet in owned pets
	local petToEquip = nil
	for _, pet in ipairs(playerData.ownedPets or {}) do
		if pet.id == petInstanceId then
			petToEquip = pet
			break
		end
	end

	if not petToEquip then
		return false, "Pet not found in your inventory"
	end

	-- Check if player has reached equipped pet limit
	local equippedCount = 0
	for _, pet in ipairs(playerData.ownedPets or {}) do
		if pet.equipped then
			equippedCount = equippedCount + 1
		end
	end

	-- Get max equipped based on upgrades
	local maxEquipped = 3
	if playerData.upgrades and playerData.upgrades.petCapacity then
		maxEquipped = 3 + playerData.upgrades.petCapacity
	end

	-- Check if at max capacity and this pet isn't already equipped
	if equippedCount >= maxEquipped and not petToEquip.equipped then
		return false, "You've reached your pet capacity limit"
	end

	-- Toggle equipped status
	petToEquip.equipped = not petToEquip.equipped

	-- Save player data
	safeCall(function()
		PlayerDataService.SavePlayerData(player)
	end)

	-- Create or remove the visual pet
	if petToEquip.equipped then
		-- Spawn the pet visually following the player
		PetShopSystem.SpawnEquippedPetForPlayer(player, petToEquip)
	else
		-- Remove the visual pet
		PetShopSystem.RemoveEquippedPetForPlayer(player, petToEquip.id)
	end

	return true, petToEquip.equipped and "Pet equipped" or "Pet unequipped"
end

-- Spawn a visual representation of an equipped pet
function PetShopSystem.SpawnEquippedPetForPlayer(player, petData)
	local success, err = safeCall(function()
		-- Get pet info from registry
		local petInfo = PetRegistry.GetPetById(petData.petType)
		if not petInfo then
			warn("Pet info not found for: " .. tostring(petData.petType))
			return
		end

		-- Get pet model
		local petModelsFolder = ReplicatedStorage:FindFirstChild("PetModels")
		if not petModelsFolder then
			warn("Pet models folder not found")
			return
		end

		-- Find the model
		local originalModel = petModelsFolder:FindFirstChild(petInfo.modelName)
		if not originalModel then
			warn("Pet model not found: " .. petInfo.modelName)
			return
				end

			-- Create a copy of the model for this player
local petModel = originalModel:Clone()
petModel.Name = "Pet_" .. petData.id

-- Set attributes
petModel:SetAttribute("PetId", petData.id)
petModel:SetAttribute("PetType", petData.petType)
petModel:SetAttribute("PetRarity", petData.rarity)
petModel:SetAttribute("PetLevel", petData.level)
petModel:SetAttribute("OwnerId", player.UserId)

-- Find the backpack or create a pets container
local backpack = player:FindFirstChild("Backpack")
if not backpack then
	backpack = Instance.new("Folder")
	backpack.Name = "Backpack"
	backpack.Parent = player
end

local petsFolder = backpack:FindFirstChild("Pets")
if not petsFolder then
	petsFolder = Instance.new("Folder")
	petsFolder.Name = "Pets"
	petsFolder.Parent = backpack
end

-- Parent the pet model
petModel.Parent = petsFolder

-- Add a script to make it follow the player
local followScript = Instance.new("Script")
followScript.Name = "FollowScript"
followScript.Source = [[
local pet = script.Parent
local player = game.Players:GetPlayerByUserId(pet:GetAttribute("OwnerId"))
if not player then script:Destroy() return end

local character = player.Character
local followOffset = Vector3.new(2, 0, 2)
local followSpeed = 10

local RunService = game:GetService("RunService")

local function getRandomOffset()
    local angle = math.random() * math.pi * 2
    local distance = math.random(2, 3)
    return Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
end

local targetOffset = getRandomOffset()
local lastOffsetChange = os.time()
local OFFSET_CHANGE_INTERVAL = 5 -- seconds

RunService.Heartbeat:Connect(function()
    if not player or not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    -- Change offset periodically
    if os.time() - lastOffsetChange > OFFSET_CHANGE_INTERVAL then
        targetOffset = getRandomOffset()
        lastOffsetChange = os.time()
    end
    
    -- Get target position
    local targetPos = character.HumanoidRootPart.Position + targetOffset
    
    -- Move the pet (if it has a primary part)
    if pet:IsA("Model") and pet.PrimaryPart then
        local currentPos = pet.PrimaryPart.Position
        local newPos = currentPos:Lerp(targetPos, 0.1)
        
        -- Keep the Y position based on the floor below
        local ray = Ray.new(Vector3.new(newPos.X, character.HumanoidRootPart.Position.Y + 5, newPos.Z), Vector3.new(0, -10, 0))
        local part, hitPos = workspace:FindPartOnRay(ray, character)
        local yPos = hitPos.Y + 1
        
        -- Set the new position
        pet:SetPrimaryPartCFrame(CFrame.new(Vector3.new(newPos.X, yPos, newPos.Z)))
        
        -- Look at the player
        local lookAt = (character.HumanoidRootPart.Position - pet.PrimaryPart.Position).unit
        pet:SetPrimaryPartCFrame(CFrame.new(pet.PrimaryPart.Position, Vector3.new(character.HumanoidRootPart.Position.X, pet.PrimaryPart.Position.Y, character.HumanoidRootPart.Position.Z)))
    end
end)
]]
followScript.Parent = petModel
followScript.Enabled = true

-- Apply custom color if specified
if petInfo.colors then
	for _, part in pairs(petModel:GetDescendants()) do
		if part:IsA("BasePart") then
			-- Apply primary color to main parts
			if part.Name:lower():find("body") or part == petModel.PrimaryPart then
				part.Color = petInfo.colors.primary
			else
				part.Color = petInfo.colors.secondary
			end
		end
	end
end

-- Apply effects based on rarity
if petInfo.rarity == "Epic" or petInfo.rarity == "Legendary" then
	for _, part in pairs(petModel:GetDescendants()) do
		if part:IsA("BasePart") then
			-- Add particle effect
			local particle = Instance.new("ParticleEmitter")
			particle.Texture = "rbxassetid://6026636509" -- Generic particle
			particle.Color = ColorSequence.new(petInfo.colors.secondary)
			particle.Size = NumberSequence.new(0.1)
			particle.Lifetime = NumberRange.new(0.5, 1)
			particle.Rate = 5
			particle.Speed = NumberRange.new(0.5)
			particle.SpreadAngle = Vector2.new(180, 180)
			particle.Parent = part

			-- Add light for legendary pets
			if petInfo.rarity == "Legendary" then
				local light = Instance.new("PointLight")
				light.Color = petInfo.colors.primary
				light.Range = 5
				light.Brightness = 0.5
				light.Parent = part
			end
		end
	end
end

print("Spawned equipped pet for " .. player.Name .. ": " .. petInfo.displayName)
end)

if not success then
	warn("Failed to spawn pet: " .. tostring(err))
end

return success
end

-- Remove a visual equipped pet
function PetShopSystem.RemoveEquippedPetForPlayer(player, petInstanceId)
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return end

	local petsFolder = backpack:FindFirstChild("Pets")
	if not petsFolder then return end

	-- Find and remove the pet
	for _, pet in pairs(petsFolder:GetChildren()) do
		if pet:GetAttribute("PetId") == petInstanceId then
			pet:Destroy()
			print("Removed equipped pet for " .. player.Name)
			break
		end
	end
end

-- Get a player's currently equipped pets
function PetShopSystem.GetEquippedPets(player)
	local playerData = PlayerDataService.GetPlayerData(player)
	if not playerData then
		return {}
	end

	local equipped = {}
	for _, pet in ipairs(playerData.ownedPets or {}) do
		if pet.equipped then
			table.insert(equipped, pet)
		end
	end

	return equipped
end

return PetShopSystem