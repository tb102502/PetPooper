-- Pet Collection Simulator
-- Pet Selling System (Script in ServerScriptService)
-- PetSelling.server.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Get MainGameModule
local MainGameModule = require(ServerScriptService:WaitForChild("MainGameModule"))

-- Get RemoteEvents
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- Make sure all required remote events exist
local function ensureRemoteEventExists(name)
	if not RemoteEvents:FindFirstChild(name) then
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = RemoteEvents
		print("Created missing RemoteEvent: " .. name)
	end
	return RemoteEvents:FindFirstChild(name)
end

-- Ensure selling remote events exist
local SellPet = ensureRemoteEventExists("SellPet")
local SellPetGroup = ensureRemoteEventExists("SellPetGroup")
local SellAllPets = ensureRemoteEventExists("SellAllPets")
local SendNotification = ensureRemoteEventExists("SendNotification")

-- Handler for selling a single pet
SellPet.OnServerEvent:Connect(function(player, petId)
	if not player or not petId then return end

	print("SERVER: Player " .. player.Name .. " attempting to sell pet: " .. tostring(petId))

	local success, coinsEarned = MainGameModule.SellPet(player, petId)

	if success then
		print("SERVER: Successfully sold pet. Player earned " .. coinsEarned .. " coins.")

		-- Send notification to client
		SendNotification:FireClient(
			player,
			"Pet Sold!",
			"You earned " .. coinsEarned .. " coins.",
			"sell" -- Icon name
		)
	else
		print("SERVER: Failed to sell pet.")

		-- Send error notification to client
		SendNotification:FireClient(
			player,
			"Error",
			"Failed to sell pet.",
			"error" -- Icon name
		)
	end
end)

-- Handler for selling a group of pets
SellPetGroup.OnServerEvent:Connect(function(player, petName, petRarity)
	if not player or not petName or not petRarity then return end

	print("SERVER: Player " .. player.Name .. " attempting to sell all " .. petRarity .. " " .. petName .. "s")

	local success, coinsEarned = MainGameModule.SellPetGroup(player, petName, petRarity)

	if success then
		print("SERVER: Successfully sold pet group. Player earned " .. coinsEarned .. " coins.")

		-- Send notification to client
		SendNotification:FireClient(
			player,
			"Pets Sold!",
			"You earned " .. coinsEarned .. " coins from selling " .. petRarity .. " " .. petName .. "s.",
			"sell" -- Icon name
		)
	else
		print("SERVER: Failed to sell pet group.")

		-- Send error notification to client
		SendNotification:FireClient(
			player,
			"Error",
			"Failed to sell pets.",
			"error" -- Icon name
		)
	end
end)

-- Handler for selling all pets
SellAllPets.OnServerEvent:Connect(function(player)
	if not player then return end

	print("SERVER: Player " .. player.Name .. " attempting to sell all pets")

	local success, coinsEarned = MainGameModule.SellAllPets(player)

	if success then
		print("SERVER: Successfully sold all pets. Player earned " .. coinsEarned .. " coins.")

		-- Send notification to client
		SendNotification:FireClient(
			player,
			"All Pets Sold!",
			"You earned " .. coinsEarned .. " coins from selling all your pets.",
			"sell" -- Icon name
		)
	else
		print("SERVER: Failed to sell all pets.")

		-- Send error notification to client
		SendNotification:FireClient(
			player,
			"Error",
			"Failed to sell pets.",
			"error" -- Icon name
		)
	end
end)

print("Pet Selling system initialized!")