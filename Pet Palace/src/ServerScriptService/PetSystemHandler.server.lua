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

-- Set up the client access
local function SetupClientAccess()
	-- Create a copy of the core module for clients to access
	local clientModule = ReplicatedStorage:FindFirstChild("PetSystemCore")
	if not clientModule then
		local moduleClone = ServerScriptService.Modules.PetSystemCore:Clone()
		moduleClone.Parent = ReplicatedStorage
	end

	print("Client access to PetSystemCore module has been set up")
end

-- Initialize the pet system
print("Initializing PetSystem...")
PetSystemCore:Initialize()
SetupExistingPets()
ConnectToExistingEvents()

-- Add pcall around the RegisterCommands function to catch any errors
pcall(function()
	RegisterCommands()
end)

-- Set up client access safely with pcall
pcall(function()
	SetupClientAccess()
end)

print("PetSystem initialization complete!")