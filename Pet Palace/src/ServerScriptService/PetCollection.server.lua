-- Pet Collection Simulator
-- Server-Side Pet Collection Script (Place in ServerScriptService)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local MainGameModule = require(script.Parent:WaitForChild("MainGameModule"))

-- Make sure RemoteEvents folder exists
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not RemoteEvents then
	RemoteEvents = Instance.new("Folder")
	RemoteEvents.Name = "RemoteEvents"
	RemoteEvents.Parent = ReplicatedStorage
end

-- Make sure RemoteFunctions folder exists
local RemoteFunctions = ReplicatedStorage:FindFirstChild("RemoteFunctions")
if not RemoteFunctions then
	RemoteFunctions = Instance.new("Folder")
	RemoteFunctions.Name = "RemoteFunctions"
	RemoteFunctions.Parent = ReplicatedStorage
end

-- Create or get remote events
local function ensureRemoteExists(name, isFunction)
	local parent = isFunction and RemoteFunctions or RemoteEvents
	if not parent:FindFirstChild(name) then
		local remote = isFunction and Instance.new("RemoteFunction") or Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = parent
		return remote
	end
	return parent:FindFirstChild(name)
end

-- Create necessary remotes
local CollectPet = ensureRemoteExists("CollectPet", false)
local UpdatePlayerStats = ensureRemoteExists("UpdatePlayerStats", false)
local GetPlayerData = ensureRemoteExists("GetPlayerData", true)

-- Fetch or create PetTypes folder in ServerStorage
local PetTypesFolder = ServerStorage:FindFirstChild("PetTypes")
if not PetTypesFolder then
	PetTypesFolder = Instance.new("Folder")
	PetTypesFolder.Name = "PetTypes"
	PetTypesFolder.Parent = ServerStorage

	-- Define pet types
	local petTypes = {
		{
			name = "Common Corgi",
			rarity = "Common",
			collectValue = 1,
			modelName = "Corgi",
			chance = 70
		},
		{
			name = "Rare RedPanda",
			rarity = "Rare",
			collectValue = 5,
			modelName = "RedPanda",
			chance = 20
		},
		{
			name = "Epic Corgi",
			rarity = "Epic",
			collectValue = 20,
			modelName = "Corgi",
			chance = 8
		},
		{
			name = "Legendary RedPanda",
			rarity = "Legendary",
			collectValue = 100,
			modelName = "RedPanda",
			chance = 2
		}
	}

	-- Create pet type values
	for _, petType in ipairs(petTypes) do
		local petTypeValue = Instance.new("StringValue")
		petTypeValue.Name = petType.name
		petTypeValue:SetAttribute("Name", petType.name)
		petTypeValue:SetAttribute("Rarity", petType.rarity)
		petTypeValue:SetAttribute("CollectValue", petType.collectValue)
		petTypeValue:SetAttribute("ModelName", petType.modelName)
		petTypeValue:SetAttribute("Chance", petType.chance)
		petTypeValue.Parent = PetTypesFolder
	end
end

-- Set up the GetPlayerData remote function
GetPlayerData.OnServerInvoke = function(player)
	return MainGameModule.GetPlayerData(player)
end

-- Handle pet collection - THE CRITICAL PART THAT NEEDS FIXING
CollectPet.OnServerEvent:Connect(function(player, petModel)
	print("SERVER: CollectPet event received from", player.Name)

	if not player then
		print("SERVER: Error - no player provided")
		return
	end

	-- Debug the pet model received
	print("SERVER: petModel type:", typeof(petModel))
	if typeof(petModel) == "Instance" then
		print("SERVER: petModel class:", petModel.ClassName)
		print("SERVER: petModel name:", petModel.Name)
		print("SERVER: petModel attributes:", 
			petModel:GetAttribute("PetType"),
			petModel:GetAttribute("Rarity"),
			petModel:GetAttribute("Value"))
	elseif typeof(petModel) == "string" then
		print("SERVER: petModel is string:", petModel)
	else
		print("SERVER: petModel is unknown type")
	end

	-- Get pet information - handle different ways it might be passed
	local petTypeName, petRarity, petValue, petModelName

	if typeof(petModel) == "Instance" then
		-- Get data from model attributes
		petTypeName = petModel:GetAttribute("PetType")
		petRarity = petModel:GetAttribute("Rarity")
		petValue = petModel:GetAttribute("Value")

		-- Check if this is a valid pet
		if not petTypeName then
			warn("SERVER: Pet model has no PetType attribute")

			-- Try to infer from the model name
			if petModel.Name:find("Corgi") then
				petTypeName = "Common Corgi"
				petRarity = "Common"
				petValue = 1
				petModelName = "Corgi"
			elseif petModel.Name:find("RedPanda") then
				petTypeName = "Rare RedPanda"
				petRarity = "Rare"
				petValue = 5
				petModelName = "RedPanda"
			else
				print("SERVER: Unable to determine pet type from model")
				return
			end
		end
	elseif typeof(petModel) == "string" then
		-- Check if it's a pet type name
		if petModel:find("Corgi") then
			petTypeName = petModel:find("Epic") and "Epic Corgi" or "Common Corgi"
			petRarity = petModel:find("Epic") and "Epic" or "Common"
			petValue = petModel:find("Epic") and 20 or 1
			petModelName = "Corgi"
		elseif petModel:find("RedPanda") then
			petTypeName = petModel:find("Legendary") and "Legendary RedPanda" or "Rare RedPanda"
			petRarity = petModel:find("Legendary") and "Legendary" or "Rare"
			petValue = petModel:find("Legendary") and 100 or 5
			petModelName = "RedPanda"
		else
			-- Try to find a pet type in ServerStorage
			local petTypeValue = PetTypesFolder:FindFirstChild(petModel)
			if petTypeValue then
				petTypeName = petTypeValue:GetAttribute("Name")
				petRarity = petTypeValue:GetAttribute("Rarity")
				petValue = petTypeValue:GetAttribute("CollectValue")
				petModelName = petTypeValue:GetAttribute("ModelName")
			else
				print("SERVER: Unable to determine pet type from string:", petModel)
				return
			end
		end
	else
		print("SERVER: Unknown petModel type:", typeof(petModel))
		return
	end

	-- At this point, we should have valid pet information
	if not petTypeName or not petRarity then
		print("SERVER: Missing pet information after processing")
		return
	end

	-- If model name not set, try to infer from pet type
	if not petModelName then
		if petTypeName:find("Corgi") then
			petModelName = "Corgi"
		elseif petTypeName:find("RedPanda") then
			petModelName = "RedPanda"
		else
			petModelName = "Corgi" -- Default fallback
		end
	end

	-- If value not set, infer from rarity
	if not petValue then
		if petRarity == "Common" then
			petValue = 1
		elseif petRarity == "Rare" then
			petValue = 5
		elseif petRarity == "Epic" then
			petValue = 20
		elseif petRarity == "Legendary" then
			petValue = 100
		else
			petValue = 1 -- Default
		end
	end

	print("SERVER: Processed pet information:", petTypeName, petRarity, petValue, petModelName)

	-- Create final pet data for adding to inventory
	local petTypeData = {
		name = petTypeName,
		rarity = petRarity,
		collectValue = petValue,
		modelName = petModelName
	}

	-- Get player data from MainGameModule
	local playerData = MainGameModule.GetPlayerData(player)
	print("SERVER: Got player data with", playerData and #playerData.pets or "nil", "pets")

	-- Make sure pets table exists
	if not playerData.pets then
		print("SERVER: Creating pets table in player data")
		playerData.pets = {}
	end

	-- Add the pet to player's inventory
	local newPet = {
		id = os.time() .. "-" .. math.random(1000, 9999),
		name = petTypeData.name,
		rarity = petTypeData.rarity,
		level = 1,
		modelName = petTypeData.modelName  
	}

	print("SERVER: Adding pet to player inventory:", newPet.name, newPet.rarity, newPet.modelName)
	table.insert(playerData.pets, newPet)

	-- No longer add coins, just collect the pet
	print("SERVER: Pet collected. Player must sell it to earn coins.")

	-- Update stats
	if not playerData.stats then
		playerData.stats = {
			totalPetsCollected = 0,
			rareFound = 0,
			epicFound = 0,
			legendaryFound = 0
		}
	end

	playerData.stats.totalPetsCollected = playerData.stats.totalPetsCollected + 1

	if petTypeData.rarity == "Rare" then
		playerData.stats.rareFound = playerData.stats.rareFound + 1
	elseif petTypeData.rarity == "Epic" then
		playerData.stats.epicFound = playerData.stats.epicFound + 1
	elseif petTypeData.rarity == "Legendary" then
		playerData.stats.legendaryFound = playerData.stats.legendaryFound + 1
	end

	-- Save player data
	MainGameModule.SavePlayerData(player)

	print("SERVER: Player now has", #playerData.pets, "pets")
	for i, pet in ipairs(playerData.pets) do
		print("SERVER: Pet", i, "-", pet.name, "(", pet.rarity, ")")
	end

	-- Update leaderboard values if they exist
	if player:FindFirstChild("leaderstats") then
		local coins = player.leaderstats:FindFirstChild("Coins")
		local pets = player.leaderstats:FindFirstChild("Pets")

		if coins then
			coins.Value = playerData.coins
		end

		if pets then
			pets.Value = #playerData.pets
		end
	end

	-- Update the client with new data
	print("SERVER: Sending updated data to client with", #playerData.pets, "pets")
	UpdatePlayerStats:FireClient(player, playerData)

	-- Also fire specific collection effect event
	CollectPet:FireClient(player, petModel, petTypeData)

	print("SERVER: Collection complete for", player.Name, "-", petTypeData.name, "worth", petTypeData.collectValue, "coins (not added)")
end)

-- Player join handler
Players.PlayerAdded:Connect(function(player)
	-- Initialize player data
	local playerData = MainGameModule.GetPlayerData(player)
	print("SERVER: Player joined. Initialized data with", #playerData.pets, "pets")

	-- Create stats for leaderboard
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	-- Create Coins value
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = playerData.coins or 0
	coins.Parent = leaderstats

	-- Create Pets value
	local pets = Instance.new("IntValue")
	pets.Name = "Pets"
	pets.Value = #playerData.pets or 0
	pets.Parent = leaderstats

	-- Send initial data to client
	print("SERVER: Sending initial data to client with", #playerData.pets, "pets")
	UpdatePlayerStats:FireClient(player, playerData)
end)

-- Player leave handler
Players.PlayerRemoving:Connect(function(player)
	MainGameModule.SavePlayerData(player)
	print("SERVER: Player left. Saved data.")
end)

print("Pet Collection Server script loaded!")

local function GetPetPosition(pet)
	-- If it's a BasePart, get position directly
	if pet:IsA("BasePart") then
		return pet.Position
	end

	-- If it's a model, try to get position from primary part
	if pet:IsA("Model") then
		-- Try primary part first
		if pet.PrimaryPart then
			return pet.PrimaryPart.Position
		end

		-- Try HumanoidRootPart
		local hrp = pet:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			return hrp.Position
		end

		-- Try Head part
		local head = pet:FindFirstChild("Head")
		if head and head:IsA("BasePart") then
			return head.Position
		end

		-- Try any BasePart
		for _, child in pairs(pet:GetChildren()) do
			if child:IsA("BasePart") then
				return child.Position
			end
		end
	end

	-- If we got here, we couldn't find a position
	warn("Could not get position for pet: " .. pet.Name)
	return Vector3.new(0, 0, 0) -- Default fallback
end

-- In PetCollectionDebugger.client.lua, replace the code that checks for the nearest pet:

local function OnChatCommand(player, message)
	if message:lower() == "/debugpets" then
		print("SERVER: Debug pets command received from " .. player.Name)

		-- Count pets in each area
		for _, area in pairs(workspace.Areas:GetChildren()) do
			local petsFolder = area:FindFirstChild("Pets")
			local count = petsFolder and #petsFolder:GetChildren() or 0
			print("SERVER: " .. area.Name .. " has " .. count .. " active pets")
		end

		-- Send a test pet to the player
		-- Find a pet in any area
		local testPet = nil
		for _, area in pairs(workspace.Areas:GetChildren()) do
			local petsFolder = area:FindFirstChild("Pets")
			if petsFolder and #petsFolder:GetChildren() > 0 then
				testPet = petsFolder:GetChildren()[1]
				break
			end
		end

		if testPet then
			print("SERVER: Sending test pet to player: " .. testPet.Name)
			-- Fire the pet collection event
			local petType = {
				name = testPet:GetAttribute("PetType") or "Test Pet",
				rarity = testPet:GetAttribute("Rarity") or "Common",
				collectValue = testPet:GetAttribute("Value") or 1
			}
			CollectPet:FireClient(player, testPet, petType)
		else
			print("SERVER: No pets found to send to player")
		end

		return true
	end
end

-- Connect the chat command function to players
for _, player in pairs(game.Players:GetPlayers()) do
	player.Chatted:Connect(function(message)
		OnChatCommand(player, message)
	end)
end

game.Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		OnChatCommand(player, message)
	end)
end)

print("SERVER: Pet debug chat command (/debugpets) added")