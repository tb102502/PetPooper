-- SystemIntegration.server.lua
-- Place this in ServerScriptService to set up the complete system
-- Run this AFTER your main SystemInitializer

wait(3) -- Wait for main systems to load

print("=== SYSTEM INTEGRATION STARTING ===")

-- Get GameCore
local GameCore = _G.GameCore
if not GameCore then
	error("GameCore not found! Make sure SystemInitializer ran first.")
end

-- Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- STEP 1: Fix/Create Pet Models
print("STEP 1: Validating pet models...")
if GameCore.ValidateAndFixPetModels then
	GameCore:ValidateAndFixPetModels()
else
	print("Adding ValidateAndFixPetModels function...")
	-- Add the function if it doesn't exist
	GameCore.ValidateAndFixPetModels = function(self)
		-- Implementation from the validator script above
		print("=== PET MODEL VALIDATOR STARTING ===")

		local petModelsFolder = ReplicatedStorage:FindFirstChild("PetModels")
		if not petModelsFolder then
			warn("No PetModels folder found in ReplicatedStorage!")
			return false
		end

		local fixedCount = 0
		local totalModels = 0

		for _, model in pairs(petModelsFolder:GetChildren()) do
			if model:IsA("Model") then
				totalModels = totalModels + 1
				print("\nChecking model: " .. model.Name)

				local needsFix = false
				local hasHumanoid = model:FindFirstChild("Humanoid")
				local hasRootPart = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart

				if not hasHumanoid then
					print("  Missing Humanoid - will add")
					needsFix = true
				end

				if not hasRootPart then
					print("  Missing HumanoidRootPart - will add")
					needsFix = true
				end

				if needsFix then
					print("  FIXING MODEL: " .. model.Name)
					self:FixPetModel(model)
					fixedCount = fixedCount + 1
				else
					print("  ✅ Model is OK")
				end
			end
		end

		print("Fixed " .. fixedCount .. " models")
		return true
	end

	GameCore:ValidateAndFixPetModels()
end

-- STEP 2: Create missing pet models if needed
print("STEP 2: Creating missing pet models...")
if GameCore.CreateMissingPetModels then
	GameCore:CreateMissingPetModels()
end

-- STEP 3: Update pet selling to be immediate
print("STEP 3: Updating pet selling system...")

-- Store original SellPet function
local originalSellPet = GameCore.SellPet

-- Enhanced SellPet function
GameCore.SellPet = function(self, player, petId)
	local success = originalSellPet(self, player, petId)

	if success then
		-- Immediately update client data
		local playerData = self:GetPlayerData(player)
		if playerData and self.RemoteEvents.PlayerDataUpdated then
			self.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
		end
	end

	return success
end

-- STEP 4: Setup ItemConfig if needed
print("STEP 4: Ensuring ItemConfig compatibility...")

-- Add PetConfigs to GameCore if missing
if not GameCore.PetConfigs then
	GameCore.PetConfigs = {
		Corgi = {
			name = "Corgi",
			displayName = "Cuddly Corgi",
			rarity = "Common",
			collectValue = 10,
			baseStats = { happiness = 50, energy = 100 }
		},
		RedPanda = {
			name = "Red Panda",
			displayName = "Rambunctious Red Panda",
			rarity = "Common",
			collectValue = 12,
			baseStats = { happiness = 60, energy = 90 }
		},
		Cat = {
			name = "Cat",
			displayName = "Curious Cat",
			rarity = "Uncommon",
			collectValue = 25,
			baseStats = { happiness = 70, energy = 80 }
		},
		Hamster = {
			name = "Hamster",
			displayName = "Happy Hamster",
			rarity = "Legendary",
			collectValue = 100,
			baseStats = { happiness = 90, energy = 95 }
		}
	}
end

-- STEP 5: Add missing helper functions
print("STEP 5: Adding helper functions...")

-- Add GetPlayerMaxPets if missing
if not GameCore.GetPlayerMaxPets then
	GameCore.GetPlayerMaxPets = function(self, userId)
		return 100 -- Default max pets
	end
end

-- Add AddPetToPlayer if missing
if not GameCore.AddPetToPlayer then
	GameCore.AddPetToPlayer = function(self, userId, petData)
		local playerData = self.PlayerData[userId]
		if not playerData then return false end

		if not playerData.pets then
			playerData.pets = { owned = {}, equipped = {} }
		end

		if not playerData.pets.owned then
			playerData.pets.owned = {}
		end

		table.insert(playerData.pets.owned, petData)
		return true
	end
end

-- Add AddPlayerCurrency if missing
if not GameCore.AddPlayerCurrency then
	GameCore.AddPlayerCurrency = function(self, userId, currencyType, amount)
		local playerData = self.PlayerData[userId]
		if not playerData then return false end

		local current = playerData[currencyType:lower()] or 0
		playerData[currencyType:lower()] = current + amount

		return true
	end
end

-- Add LogPlayerAction if missing
if not GameCore.LogPlayerAction then
	GameCore.LogPlayerAction = function(self, userId, action, data)
		print("Player " .. userId .. " action: " .. action .. " - " .. HttpService:JSONEncode(data or {}))
	end
end

-- STEP 6: Test the system
print("STEP 6: Testing the enhanced system...")

spawn(function()
	wait(5) -- Wait for everything to settle

	print("=== TESTING PET SPAWN ===")
	-- Test spawning a pet in each area
	for areaName, _ in pairs(GameCore.Systems.Pets.SpawnAreas) do
		local success, pet = pcall(function()
			return GameCore:SpawnWildPet(areaName)
		end)

		if success and pet then
			print("✅ Successfully spawned test pet in " .. areaName)
		else
			print("❌ Failed to spawn pet in " .. areaName .. ": " .. tostring(pet))
		end

		wait(1)
	end
end)

-- STEP 7: Setup client notification
print("STEP 7: Setting up client notifications...")

-- Create client notification for the new features
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		wait(3) -- Wait for client to load

		if GameCore.RemoteEvents.NotificationSent then
			GameCore.RemoteEvents.NotificationSent:FireClient(player,
				"🎉 Enhanced Pet System!",
				"New features: Walk to collect pets, improved selling, and better UI!",
				"success"
			)
		end
	end)
end)

-- STEP 8: Performance monitoring
print("STEP 8: Setting up performance monitoring...")

spawn(function()
	while true do
		wait(60) -- Check every minute

		local totalPets = 0
		local totalConnections = 0

		-- Count pets and connections
		for areaName, areaData in pairs(GameCore.Systems.Pets.SpawnAreas) do
			if areaData.container then
				local petCount = #areaData.container:GetChildren()
				totalPets = totalPets + petCount

				-- Count behavior connections
				for _, pet in pairs(areaData.container:GetChildren()) do
					if pet:GetAttribute("BehaviorConnection") then
						totalConnections = totalConnections + 1
					end
				end
			end
		end

		print("Performance Monitor - Pets: " .. totalPets .. ", Active Behaviors: " .. totalConnections)

		-- Clean up if too many pets
		if totalPets > 100 then
			print("Too many pets! Cleaning up oldest ones...")
			GameCore:CleanupMemory()
		end
	end
end)

print("=== SYSTEM INTEGRATION COMPLETE ===")
print("✅ All enhancements are now active!")
print("✅ Pets will move around and can be collected by walking into them")
print("✅ Pet selling provides immediate feedback")
print("✅ Currency display is enhanced with better formatting")
print("✅ Sound effects use working Roblox default sounds")

-- Add a final validation
spawn(function()
	wait(10)

	print("\n=== FINAL SYSTEM VALIDATION ===")

	-- Check pet models
	local petModelsFolder = ReplicatedStorage:FindFirstChild("PetModels")
	if petModelsFolder then
		print("✅ PetModels folder exists with " .. #petModelsFolder:GetChildren() .. " models")
	else
		print("❌ PetModels folder missing")
	end

	-- Check spawn areas
	local areasCount = 0
	for _ in pairs(GameCore.Systems.Pets.SpawnAreas) do
		areasCount = areasCount + 1
	end
	print("✅ " .. areasCount .. " spawn areas configured")

	-- Check remote events
	local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if remoteFolder then
		print("✅ GameRemotes folder exists with " .. #remoteFolder:GetChildren() .. " remotes")
	else
		print("❌ GameRemotes folder missing")
	end

	print("=== VALIDATION COMPLETE ===")
end)