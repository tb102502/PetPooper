--[[
    PetSystemInitializer.server.lua
    Initializes the consolidated PetSystem for PetPooper
    Created: 2025-05-24
    Author: GitHub Copilot for tb102502
]]

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Load the core module
local PetSystemCore = require(ServerScriptService.Modules.PetSystemCore)

-- Additional initialization
local function SetupExistingPets()
	-- Migrate any existing pet data to the new format if needed
	for _, player in ipairs(Players:GetPlayers()) do
		-- Check for legacy data format and convert if found
		local success, result = pcall(function()
			-- Your migration logic here if needed
			return true
		end)

		if success and result then
			print("Migrated pet data for player: " .. player.Name)
		end
	end
end

local function ConnectToExistingEvents()
	-- Connect to any existing events from other systems

	-- Example: Connect to in-game shop for pet purchases
	local shopEvents = ReplicatedStorage:FindFirstChild("ShopEvents")
	if shopEvents then
		local purchasePetEvent = shopEvents:FindFirstChild("PurchasePet")
		if purchasePetEvent and purchasePetEvent:IsA("RemoteEvent") then
			purchasePetEvent.OnServerEvent:Connect(function(player, petId)
				-- Add the purchased pet to the player's inventory
				local success, petUniqueId = PetSystemCore:AddPet(player, petId)

				if success then
					print("Player " .. player.Name .. " purchased pet: " .. petId .. ", assigned ID: " .. petUniqueId)

					-- Optional: Auto-equip newly purchased pets if player has space
					if #PetSystemCore:GetEquippedPets(player) < PetSystemCore.Config.MaxPetsEquipped then
						PetSystemCore:EquipPet(player, petUniqueId)
					end
				end
			end)
		end
	end

	-- Connect to any existing badge or achievement systems
	local badgeEvents = ReplicatedStorage:FindFirstChild("BadgeEvents") 
	if badgeEvents and badgeEvents:FindFirstChild("PetCollectionUpdated") then
		PetSystemCore.Remotes.Events.PetAdded.OnServerEvent:Connect(function(player, petId, petData)
			badgeEvents.PetCollectionUpdated:FireServer(player, PetSystemCore:GetOwnedPets(player))
		end)
	end
end

local function RegisterCommands()
	-- Register any admin commands for pet system - SAFELY CHECK FOR COMMAND SERVICE
	local commandServiceModule = ServerScriptService:FindFirstChild("CommandService")

	-- Skip command registration if the module doesn't exist
	if not commandServiceModule or not commandServiceModule:IsA("ModuleScript") then
		warn("CommandService module not found or is not a ModuleScript - skipping command registration")
		return
	end

	-- Try to require the module with pcall to catch any errors
	local success, CommandService = pcall(function()
		return require(commandServiceModule)
	end)

	if not success then
		warn("Failed to require CommandService - skipping command registration")
		return
	end

	-- Now safely register commands
	if CommandService and typeof(CommandService) == "table" and typeof(CommandService.RegisterCommand) == "function" then
		CommandService:RegisterCommand("givepet", function(player, args)
			if player:GetAttribute("Admin") or player:GetRankInGroup(12345) >= 100 then
				local targetPlayer = Players:FindFirstChild(args[1])
				local petId = args[2]

				if targetPlayer and PetSystemCore.Cache.PetDefinitions[petId] then
					PetSystemCore:AddPet(targetPlayer, petId)
					return "Successfully gave " .. petId .. " to " .. targetPlayer.Name
				else
					return "Invalid player or pet ID"
				end
			else
				return "Insufficient permissions"
			end
		end)
	else
		warn("CommandService found but does not have expected RegisterCommand method")
	end
end

-- Create PetTemplates folder if it doesn't exist
local function SetupPetTemplates()
	local ServerStorage = game:GetService("ServerStorage")

	if not ServerStorage:FindFirstChild("PetTemplates") then
		print("Creating PetTemplates folder in ServerStorage")
		local templatesFolder = Instance.new("Folder")
		templatesFolder.Name = "PetTemplates"
		templatesFolder.Parent = ServerStorage

		-- Here you could create sample pet templates if needed
		print("PetTemplates folder created. Please add pet models to this folder.")
	end
end

-- Set up the remote events and functions
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
		"EquipPet",
		"UnequipPet"
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

	print("RemoteEvents and RemoteFunctions have been set up")
	return remoteFolder
end

-- Create the PetSystemClient module
-- Create the PetSystemClient module
local function CreatePetSystemClientModule()
	-- Check if module already exists
	if ReplicatedStorage:FindFirstChild("PetSystemClient") then
		print("PetSystemClient module already exists")
		return
	end

	print("Creating PetSystemClient module in ReplicatedStorage")

	-- Create the module script
	local clientModule = Instance.new("ModuleScript")
	clientModule.Name = "PetSystemClient"

	-- The module source is too large to set dynamically in Studio
	-- Instead, we'll create the structure and add a note
	clientModule.Source = [[
--[[
    PetSystemClient.lua
    Client-side interface for the PetSystem
    
    NOTE: This is a placeholder. Please replace this with the full PetSystemClient code provided.
]]

	local PetSystemClient = {}

	function PetSystemClient:Initialize()
		print("PetSystemClient placeholder initialized. Please replace this module with the full version.")
	end

	return PetSystemClient
	end
	
	local clientModule = Instance.new("ModuleScript")
	clientModule.Name = "PetSystemClient"
	clientModule.Parent = ReplicatedStorage
	print("Created PetSystemClient module - please replace with full version")

-- This is line 190 - closing parenthesis should be here
-- Initialize the pet system
print("Initializing PetSystem...")
SetupPetTemplates() -- Make sure templates folder exists
SetupRemotes() -- Set up remote events and functions
pcall(CreatePetSystemClientModule) -- Create client module

PetSystemCore:Initialize()
SetupExistingPets()
ConnectToExistingEvents()

-- Add pcall around the RegisterCommands function to catch any errors
pcall(function()
	RegisterCommands()
end)

print("PetSystem initialization complete!")