-- PetDebugScript.server.lua
-- Place this in ServerScriptService temporarily to debug pet visibility issues
-- Remove after fixing the problem

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

print("=== PET DEBUG SCRIPT ACTIVE ===")

-- Function to analyze pet models in ReplicatedStorage
local function analyzeReplicatedStorageModels()
	print("\n--- ANALYZING REPLICATED STORAGE PET MODELS ---")

	local petModelsFolder = game:GetService("ReplicatedStorage"):FindFirstChild("PetModels")
	if not petModelsFolder then
		warn("PetModels folder not found in ReplicatedStorage!")
		return
	end

	for _, model in pairs(petModelsFolder:GetChildren()) do
		if model:IsA("Model") then
			print("\nModel: " .. model.Name)
			print("  PrimaryPart: " .. (model.PrimaryPart and model.PrimaryPart.Name or "NONE"))

			local partCount = 0
			local transparentParts = 0
			local anchoredParts = 0

			for _, part in pairs(model:GetDescendants()) do
				if part:IsA("BasePart") then
					partCount = partCount + 1
					if part.Transparency >= 1 then
						transparentParts = transparentParts + 1
					end
					if part.Anchored then
						anchoredParts = anchoredParts + 1
					end

					-- Print each part's details
					print("    Part: " .. part.Name .. 
						" | Size: " .. tostring(part.Size) .. 
						" | Transparency: " .. part.Transparency .. 
						" | Anchored: " .. tostring(part.Anchored) .. 
						" | CanCollide: " .. tostring(part.CanCollide))
				end
			end

			print("  Total Parts: " .. partCount)
			print("  Transparent Parts: " .. transparentParts)
			print("  Anchored Parts: " .. anchoredParts)

			if transparentParts == partCount then
				warn("  WARNING: ALL PARTS ARE INVISIBLE!")
			end
		end
	end
end

-- Function to monitor spawned pets in workspace
local function monitorWorkspacePets()
	print("\n--- MONITORING WORKSPACE PETS ---")

	local areasFolder = workspace:FindFirstChild("Areas")
	if not areasFolder then
		print("No Areas folder found in workspace")
		return
	end

	local totalPets = 0

	for _, area in pairs(areasFolder:GetChildren()) do
		local petsFolder = area:FindFirstChild("Pets")
		if petsFolder then
			local areaPetCount = #petsFolder:GetChildren()
			totalPets = totalPets + areaPetCount

			if areaPetCount > 0 then
				print("\nArea: " .. area.Name .. " has " .. areaPetCount .. " pets")

				for _, pet in pairs(petsFolder:GetChildren()) do
					print("  Pet: " .. pet.Name)
					print("    Type: " .. pet.ClassName)
					print("    Position: " .. (pet:IsA("Model") and pet.PrimaryPart and tostring(pet.PrimaryPart.Position) or "Unknown"))
					print("    PetType Attribute: " .. (pet:GetAttribute("PetType") or "None"))

					if pet:IsA("Model") then
						local visibleParts = 0
						local totalParts = 0

						for _, part in pairs(pet:GetDescendants()) do
							if part:IsA("BasePart") then
								totalParts = totalParts + 1
								if part.Transparency < 1 then
									visibleParts = visibleParts + 1
								end
							end
						end

						print("    Parts: " .. totalParts .. " total, " .. visibleParts .. " visible")

						if visibleParts == 0 and totalParts > 0 then
							warn("    WARNING: PET HAS NO VISIBLE PARTS!")
						end
					end
				end
			end
		end
	end

	print("\nTotal pets in workspace: " .. totalPets)
end

-- Function to force fix invisible pets
local function fixInvisiblePets()
	print("\n--- ATTEMPTING TO FIX INVISIBLE PETS ---")

	local areasFolder = workspace:FindFirstChild("Areas")
	if not areasFolder then return end

	local fixedCount = 0

	for _, area in pairs(areasFolder:GetChildren()) do
		local petsFolder = area:FindFirstChild("Pets")
		if petsFolder then
			for _, pet in pairs(petsFolder:GetChildren()) do
				if pet:IsA("Model") then
					local hasVisibleParts = false
					local totalParts = 0

					-- Check if any parts are visible
					for _, part in pairs(pet:GetDescendants()) do
						if part:IsA("BasePart") then
							totalParts = totalParts + 1
							if part.Transparency < 1 then
								hasVisibleParts = true
							end
						end
					end

					-- If no visible parts but has parts, make them visible
					if not hasVisibleParts and totalParts > 0 then
						print("Fixing invisible pet: " .. pet.Name)

						for _, part in pairs(pet:GetDescendants()) do
							if part:IsA("BasePart") then
								part.Transparency = 0.2  -- Make semi-transparent for debugging
								part.Anchored = true
								part.CanCollide = false

								-- Give it a bright color for testing
								if part.Name == "Head" then
									part.Color = Color3.fromRGB(255, 0, 0)  -- Red head
									part.Material = Enum.Material.Neon
								elseif part.Name == "Torso" then
									part.Color = Color3.fromRGB(0, 255, 0)  -- Green body
									part.Material = Enum.Material.Neon
								else
									part.Color = Color3.fromRGB(0, 0, 255)  -- Blue other parts
									part.Material = Enum.Material.Neon
								end
							end
						end

						fixedCount = fixedCount + 1
					end
				end
			end
		end
	end

	print("Fixed " .. fixedCount .. " invisible pets")
end

-- Admin command to manually spawn a test pet
local function createTestPet(player)
	print("Creating test pet for debugging...")

	local testPet = Instance.new("Model")
	testPet.Name = "DEBUG_PET_" .. player.Name

	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.Transparency = 0.5
	rootPart.Color = Color3.fromRGB(255, 255, 0)  -- Bright yellow
	rootPart.Material = Enum.Material.Neon
	rootPart.Anchored = true
	rootPart.CanCollide = false
	rootPart.Parent = testPet

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 2, 2)
	head.Shape = Enum.PartType.Ball
	head.Color = Color3.fromRGB(255, 0, 255)  -- Bright magenta
	head.Material = Enum.Material.Neon
	head.Anchored = true
	head.CanCollide = false
	head.Parent = testPet

	testPet.PrimaryPart = rootPart

	-- Position near player
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local playerPos = player.Character.HumanoidRootPart.Position
		testPet:PivotTo()(CFrame.new(playerPos + Vector3.new(5, 5, 0)))
		head.CFrame = CFrame.new(playerPos + Vector3.new(5, 7, 0))
	end

	-- Set attributes
	testPet:SetAttribute("PetType", "DEBUG")
	testPet:SetAttribute("Rarity", "Test")
	testPet:SetAttribute("Value", 999)

	-- Parent to workspace
	testPet.Parent = workspace

	print("Test pet created at position: " .. tostring(rootPart.Position))
	return testPet
end

-- Run initial analysis
analyzeReplicatedStorageModels()
monitorWorkspacePets()

-- Monitor continuously
spawn(function()
	while true do
		wait(10)  -- Check every 10 seconds
		monitorWorkspacePets()
	end
end)

-- Chat commands for debugging
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.Name == "YOUR_USERNAME_HERE" then  -- Replace with your username
			local args = string.split(message:lower(), " ")

			if args[1] == "/debugpets" then
				analyzeReplicatedStorageModels()
				monitorWorkspacePets()

			elseif args[1] == "/fixpets" then
				fixInvisiblePets()

			elseif args[1] == "/testpet" then
				createTestPet(player)

			elseif args[1] == "/clearpets" then
				local areasFolder = workspace:FindFirstChild("Areas")
				if areasFolder then
					for _, area in pairs(areasFolder:GetChildren()) do
						local petsFolder = area:FindFirstChild("Pets")
						if petsFolder then
							petsFolder:ClearAllChildren()
						end
					end
				end
				print("Cleared all pets from workspace")
			end
		end
	end)
end)

print("Debug commands available (replace YOUR_USERNAME_HERE with your username):")
print("  /debugpets - Analyze pet models and workspace")
print("  /fixpets - Attempt to fix invisible pets")
print("  /testpet - Create a visible test pet")
print("  /clearpets - Clear all pets from workspace")
print("=======================================")