--[[
    Enhanced PetSystemInitializer.server.lua
    Fixed version with proper remote event handling
    Created: 2025-05-24
]]

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Load the core module
local PetSystemCore = require(ServerScriptService.Modules.PetSystemCore)

-- Set up the remote events and functions with proper handlers
local function SetupRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("PetSystem")

	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "PetSystem"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Create remote events
	local events = {
		"PetEquipped",
		"PetUnequipped", 
		"PetAdded",
		"PetRemoved",
		"PetsUpdated",
		"PetLevelUp",
		"EquipPet",      -- Client -> Server
		"UnequipPet"     -- Client -> Server
	}

	for _, eventName in ipairs(events) do
		if not remoteFolder:FindFirstChild(eventName) then
			local event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = remoteFolder
			print("Created remote event: " .. eventName)
		end
	end

	-- Create remote functions
	local functions = {
		"GetEquippedPets",
		"GetOwnedPets", 
		"GetPetData"
	}

	for _, funcName in ipairs(functions) do
		if not remoteFolder:FindFirstChild(funcName) then
			local func = Instance.new("RemoteFunction")
			func.Name = funcName
			func.Parent = remoteFolder
			print("Created remote function: " .. funcName)
		end
	end

	-- Set up event handlers for client requests
	local equipPetEvent = remoteFolder:FindFirstChild("EquipPet")
	if equipPetEvent then
		equipPetEvent.OnServerEvent:Connect(function(player, petId)
			print("Server: Player " .. player.Name .. " requesting to equip pet: " .. tostring(petId))
			local success, errorMsg = PetSystemCore:EquipPet(player, petId)
			if not success then
				warn("Failed to equip pet for " .. player.Name .. ": " .. tostring(errorMsg))
			end
		end)
	end

	local unequipPetEvent = remoteFolder:FindFirstChild("UnequipPet")
	if unequipPetEvent then
		unequipPetEvent.OnServerEvent:Connect(function(player, petId)
			print("Server: Player " .. player.Name .. " requesting to unequip pet: " .. tostring(petId))
			local success, errorMsg = PetSystemCore:UnequipPet(player, petId)
			if not success then
				warn("Failed to unequip pet for " .. player.Name .. ": " .. tostring(errorMsg))
			end
		end)
	end

	print("RemoteEvents and RemoteFunctions have been set up with handlers")
	return remoteFolder
end

-- Create PetTemplates folder if it doesn't exist
local function SetupPetTemplates()
	local ServerStorage = game:GetService("ServerStorage")

	if not ServerStorage:FindFirstChild("PetTemplates") then
		print("Creating PetTemplates folder in ServerStorage")
		local templatesFolder = Instance.new("Folder")
		templatesFolder.Name = "PetTemplates"
		templatesFolder.Parent = ServerStorage
		print("PetTemplates folder created. Please add pet models to this folder.")
	end
end

-- Add some test pets for players
local function AddTestPets()
	-- Wait a moment for players to load
	wait(5)

	for _, player in pairs(Players:GetPlayers()) do
		-- Add some test pets to each player
		local testPets = {"Corgi", "Cat", "RedPanda"}

		for _, petType in ipairs(testPets) do
			-- Create test pet data
			local petData = {
				name = petType,
				rarity = "common",
				level = 1,
				experience = 0,
				stats = {
					speed = 16,
					collectRadius = 15
				},
				image = "rbxassetid://6031302950"
			}

			local success, petId = PetSystemCore:AddPet(player, petType, petData)
			if success then
				print("Added test pet " .. petType .. " to " .. player.Name .. " with ID: " .. petId)
			end
		end
	end
end

-- Enhanced connection to existing events
local function ConnectToExistingEvents()
	-- Connect to shop purchases
	local shopEvents = ReplicatedStorage:FindFirstChild("ShopEvents")
	if shopEvents then
		local purchasePetEvent = shopEvents:FindFirstChild("PurchasePet")
		if purchasePetEvent and purchasePetEvent:IsA("RemoteEvent") then
			purchasePetEvent.OnServerEvent:Connect(function(player, petId)
				local success, petUniqueId = PetSystemCore:AddPet(player, petId)

				if success then
					print("Player " .. player.Name .. " purchased pet: " .. petId .. ", assigned ID: " .. petUniqueId)

					-- Auto-equip if player has space
					if #PetSystemCore:GetEquippedPets(player) < PetSystemCore.Config.MaxPetsEquipped then
						PetSystemCore:EquipPet(player, petUniqueId)
					end
				end
			end)
		end
	end
end

-- Safe command registration
local function RegisterCommands()
	local commandServiceModule = ServerScriptService:FindFirstChild("CommandService")

	if not commandServiceModule or not commandServiceModule:IsA("ModuleScript") then
		print("CommandService not found - skipping command registration")
		return
	end

	local success, CommandService = pcall(function()
		return require(commandServiceModule)
	end)

	if not success then
		warn("Failed to require CommandService")
		return
	end

	if CommandService and typeof(CommandService.RegisterCommand) == "function" then
		CommandService:RegisterCommand("givepet", function(player, args)
			if player:GetAttribute("Admin") then
				local targetPlayer = Players:FindFirstChild(args[1])
				local petId = args[2]

				if targetPlayer then
					local success, uniqueId = PetSystemCore:AddPet(targetPlayer, petId)
					if success then
						return "Successfully gave " .. petId .. " to " .. targetPlayer.Name
					else
						return "Failed to give pet"
					end
				else
					return "Player not found"
				end
			else
				return "Insufficient permissions"
			end
		end)
	end
end

-- Main initialization
print("Initializing Enhanced PetSystem...")

-- Setup in correct order
SetupPetTemplates()
local remoteFolder = SetupRemotes()

-- Initialize the core system
PetSystemCore:Initialize()

-- Connect to existing events
ConnectToExistingEvents()

-- Register commands safely
pcall(RegisterCommands)

-- Add test pets for debugging (remove in production)
spawn(AddTestPets)

print("Enhanced PetSystem initialization complete!")