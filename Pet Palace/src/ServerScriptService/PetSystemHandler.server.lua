-- PetSystemHandler.server.lua
-- Main handler for pet-related systems
-- Author: tb102502
-- Date: 2025-05-23 23:00:00

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Load modules
local PetShopSystem = require(script.Parent:WaitForChild("Modules"):WaitForChild("PetShopSystem"))
local PetRegistry = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetRegistry"))
local PlayerDataService = require(ServerStorage:WaitForChild("Modules"):WaitForChild("PlayerDataService"))

-- Set up RemoteFunctions
local remoteFunctions = ReplicatedStorage:FindFirstChild("RemoteFunctions") or Instance.new("Folder")
remoteFunctions.Name = "RemoteFunctions"
remoteFunctions.Parent = ReplicatedStorage

local getCurrencyFunction = remoteFunctions:FindFirstChild("GetCurrency") or Instance.new("RemoteFunction")
getCurrencyFunction.Name = "GetCurrency"
getCurrencyFunction.Parent = remoteFunctions

local equipPetFunction = remoteFunctions:FindFirstChild("EquipPet") or Instance.new("RemoteFunction")
equipPetFunction.Name = "EquipPet"
equipPetFunction.Parent = remoteFunctions

local getEquippedPetsFunction = remoteFunctions:FindFirstChild("GetEquippedPets") or Instance.new("RemoteFunction")
getEquippedPetsFunction.Name = "GetEquippedPets"
getEquippedPetsFunction.Parent = remoteFunctions

-- Set up RemoteEvents
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents") or Instance.new("Folder")
remoteEvents.Name = "RemoteEvents"
remoteEvents.Parent = ReplicatedStorage

local updateCurrency = remoteEvents:FindFirstChild("UpdateCurrency") or Instance.new("RemoteEvent")
updateCurrency.Name = "UpdateCurrency"
updateCurrency.Parent = remoteEvents

local updateInventory = remoteEvents:FindFirstChild("UpdateInventory") or Instance.new("RemoteEvent")
updateInventory.Name = "UpdateInventory"
updateInventory.Parent = remoteEvents

-- Initialize systems
local function initialize()
	print("Initializing pet systems...")

	-- Initialize the pet shop system
	PetShopSystem.Initialize()

	-- Set up remote function handlers
	getCurrencyFunction.OnServerInvoke = function(player)
		local playerData = PlayerDataService.GetPlayerData(player)
		if playerData then
			return {
				coins = playerData.coins or 0,
				gems = playerData.gems or 0
			}
		else
			return {coins = 0, gems = 0}
		end
	end

	equipPetFunction.OnServerInvoke = function(player, petId)
		return PetShopSystem.EquipPet(player, petId)
	end

	getEquippedPetsFunction.OnServerInvoke = function(player)
		return PetShopSystem.GetEquippedPets(player)
	end

	-- Set up player joined handling
	Players.PlayerAdded:Connect(function(player)
		-- Initialize player data
		local playerData = PlayerDataService.GetPlayerData(player)

		-- Give starting pets to new players
		if not playerData.ownedPets or #playerData.ownedPets == 0 then
			-- Give a free starter pet
			local starterPet = PetRegistry.GetPetById("bunny")

			if starterPet then
				-- Create pet data
				local uniquePetId = "bunny_starter_" .. player.UserId

				local newPet = {
					id = uniquePetId,
					petType = "bunny",
					rarity = starterPet.rarity,
					level = 1,
					experience = 0,
					equipped = true,
					dateAcquired = os.time(),
					stats = {
						coinMultiplier = starterPet.abilities.coinMultiplier or 1,
						collectRange = starterPet.abilities.collectRange or 1,
						collectSpeed = starterPet.abilities.collectSpeed or 1
					}
				}

				-- Add to player's owned pets
				playerData.ownedPets = playerData.ownedPets or {}
				table.insert(playerData.ownedPets, newPet)

				-- Save the data
				PlayerDataService.SavePlayerData(player)

				print("Gave starter pet to new player: " .. player.Name)
			end
		end

		-- When the character loads, spawn equipped pets
		player.CharacterAdded:Connect(function(character)
			wait(1) -- Give a short delay for things to load

			-- Get equipped pets
			local equippedPets = PetShopSystem.GetEquippedPets(player)

			-- Spawn each equipped pet
			for _, pet in ipairs(equippedPets) do
				PetShopSystem.SpawnEquippedPetForPlayer(player, pet)
			end

			-- Update currency display for the player
			local playerData = PlayerDataService.GetPlayerData(player)
			if playerData then
				updateCurrency:FireClient(player, {
					coins = playerData.coins or 0,
					gems = playerData.gems or 0
				})
			end
		end)
	end)

	print("Pet systems initialized successfully")
end

-- Start the systems
initialize()