-- Pet Collection Simulator
-- Auto-Collect Script (LocalScript in StarterPlayerScripts)

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local autoCollectEnabled = false
local collectRadius = 15 -- How far the auto-collect will reach

-- Create necessary RemoteEvents if they don't exist (for development testing)
local function ensureRemoteEventsExist()
	-- Create RemoteEvents folder if it doesn't exist
	if not ReplicatedStorage:FindFirstChild("RemoteEvents") then
		local folder = Instance.new("Folder")
		folder.Name = "RemoteEvents"
		folder.Parent = ReplicatedStorage
		print("Created RemoteEvents folder")
	end

	-- Create RemoteFunctions folder if it doesn't exist
	if not ReplicatedStorage:FindFirstChild("RemoteFunctions") then
		local folder = Instance.new("Folder")
		folder.Name = "RemoteFunctions"
		folder.Parent = ReplicatedStorage
		print("Created RemoteFunctions folder")
	end

	-- Ensure EnableAutoCollect exists
	if not ReplicatedStorage.RemoteEvents:FindFirstChild("EnableAutoCollect") then
		local event = Instance.new("RemoteEvent")
		event.Name = "EnableAutoCollect"
		event.Parent = ReplicatedStorage.RemoteEvents
		print("Created EnableAutoCollect event")
	end

	-- Ensure CollectPet exists
	if not ReplicatedStorage.RemoteEvents:FindFirstChild("CollectPet") then
		local event = Instance.new("RemoteEvent")
		event.Name = "CollectPet"
		event.Parent = ReplicatedStorage.RemoteEvents
		print("Created CollectPet event")
	end

	-- Ensure CheckGamePassOwnership exists
	if not ReplicatedStorage.RemoteFunctions:FindFirstChild("CheckGamePassOwnership") then
		local func = Instance.new("RemoteFunction")
		func.Name = "CheckGamePassOwnership"
		func.Parent = ReplicatedStorage.RemoteFunctions
		print("Created CheckGamePassOwnership function")
	end
end

-- Call this at the start of the script to ensure required objects exist
ensureRemoteEventsExist()

-- Get remote events and functions (with error handling)
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not RemoteEvents then
	warn("Failed to get RemoteEvents folder after 10 seconds. Auto-Collect functionality will be limited.")
	RemoteEvents = Instance.new("Folder") -- Create dummy folder to prevent errors
end

local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions", 10)
if not RemoteFunctions then
	warn("Failed to get RemoteFunctions folder after 10 seconds. Auto-Collect functionality will be limited.")
	RemoteFunctions = Instance.new("Folder") -- Create dummy folder to prevent errors
end

-- Get specific remotes with safe fallbacks
local function safeGetRemote(parent, name, createIfMissing, isFunction)
	local remote = parent:FindFirstChild(name)

	if not remote and createIfMissing then
		if isFunction then
			remote = Instance.new("RemoteFunction")
		else
			remote = Instance.new("RemoteEvent")
		end
		remote.Name = name
		remote.Parent = parent
		print("Created missing remote: " .. name)
	end

	return remote
end

local CollectPet = safeGetRemote(RemoteEvents, "CollectPet", true, false)
local EnableAutoCollect = safeGetRemote(RemoteEvents, "EnableAutoCollect", true, false)
local CheckGamePassOwnership = safeGetRemote(RemoteFunctions, "CheckGamePassOwnership", true, true)

-- Function to enable auto collection
local function EnableAutoCollection()
	autoCollectEnabled = true
	print("Auto-collect enabled")

	-- Make sure character exists
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		warn("Cannot create auto-collect visual - character or HumanoidRootPart missing")
		return
	end

	-- Remove existing visual if there is one
	if character.HumanoidRootPart:FindFirstChild("CollectRadiusVisual") then
		character.HumanoidRootPart.CollectRadiusVisual:Destroy()
	end

	-- Create a visual effect to show the collection radius
	local collectRadiusVisual = Instance.new("Part")
	collectRadiusVisual.Name = "CollectRadiusVisual"
	collectRadiusVisual.Shape = Enum.PartType.Ball
	collectRadiusVisual.Size = Vector3.new(collectRadius * 2, collectRadius * 2, collectRadius * 2)
	collectRadiusVisual.Transparency = 0.8
	collectRadiusVisual.Color = Color3.fromRGB(0, 255, 255)
	collectRadiusVisual.Material = Enum.Material.ForceField
	collectRadiusVisual.CanCollide = false
	collectRadiusVisual.Anchored = true

	-- Position at character's center
	collectRadiusVisual.CFrame = character.HumanoidRootPart.CFrame
	collectRadiusVisual.Parent = character.HumanoidRootPart

	-- Create weld constraint to keep it positioned at the character
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = collectRadiusVisual
	weld.Part1 = character.HumanoidRootPart
	weld.Parent = collectRadiusVisual
end

-- Check if player already owns the Auto-Collect pass
local function InitializeAutoCollect()
	if not CheckGamePassOwnership then
		warn("CheckGamePassOwnership is nil. Cannot check for Auto-Collect game pass.")
		return
	end

	local success, result = pcall(function()
		return CheckGamePassOwnership:InvokeServer("Auto-Collect")
	end)

	if success and result then
		EnableAutoCollection()
	else
		if not success then
			warn("Error checking Auto-Collect game pass: " .. tostring(result))
		end
	end
end

-- Function to auto-collect nearby pets
local function CollectNearbyPets()
	if not autoCollectEnabled or not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end

	if not CollectPet then
		warn("CollectPet RemoteEvent is nil. Cannot collect pets.")
		return
	end

	local rootPart = character.HumanoidRootPart
	local collectCount = 0 -- Limit how many pets we collect per tick

	-- Check all areas for pets
	for _, areaModel in pairs(workspace:FindFirstChild("Areas", true):GetChildren()) do
		if areaModel:IsA("Model") and areaModel:FindFirstChild("Pets") then
			local petsFolder = areaModel.Pets

			-- Check each pet in the area
			for _, pet in pairs(petsFolder:GetChildren()) do
				if pet:IsA("BasePart") or (pet:IsA("Model") and pet:FindFirstChild("PrimaryPart")) then
					-- Calculate distance
					local petPosition = pet:IsA("BasePart") and pet.Position or pet.PrimaryPart.Position
					local distance = (rootPart.Position - petPosition).Magnitude

					-- If within radius, collect
					if distance <= collectRadius then
						-- Limit collection to avoid overloading the server
						collectCount = collectCount + 1
						if collectCount > 3 then break end

						-- Animate the pet collection
						local targetPosition = rootPart.Position + Vector3.new(0, 5, 0)

						-- Use a coroutine to animate the pet moving up
						coroutine.wrap(function()
							-- Calculate properties based on pet type
							local startPosition
							local tweenPart

							if pet:IsA("BasePart") then
								startPosition = pet.Position
								tweenPart = pet
							elseif pet:IsA("Model") and pet:FindFirstChild("PrimaryPart") then
								startPosition = pet.PrimaryPart.Position
								tweenPart = pet.PrimaryPart
							else
								return -- Skip if we can't identify the pet
							end

							-- Create a simple animation by moving the pet towards the player
							local startTime = tick()
							local duration = 0.5

							-- Animate for 0.5 seconds
							while tick() - startTime < duration and pet:IsDescendantOf(game) do
								local alpha = (tick() - startTime) / duration
								local newPosition = startPosition:Lerp(targetPosition, alpha)

								if pet:IsA("BasePart") then
									pet.Position = newPosition
									pet.Transparency = alpha -- Fade out
								elseif pet:IsA("Model") and pet:FindFirstChild("PrimaryPart") then
									pet:SetPrimaryPartCFrame(CFrame.new(newPosition))

									-- Gradually make all parts transparent
									for _, part in pairs(pet:GetDescendants()) do
										if part:IsA("BasePart") then
											part.Transparency = alpha -- Fade out
										end
									end
								end

								RunService.Heartbeat:Wait()
							end

							-- Fire the server event to collect the pet
							local success, err = pcall(function()
								CollectPet:FireServer(pet.Name)
							end)

							if not success then
								warn("Failed to collect pet: " .. tostring(err))
							end

							-- Remove the pet
							if pet:IsDescendantOf(game) then
								pet:Destroy()
							end
						end)()
					end
				end
			end

			if collectCount > 3 then break end -- Limit total collection per tick
		end
	end
end

-- Listen for character respawns
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter

	-- Wait for humanoid root part
	if not character:FindFirstChild("HumanoidRootPart") then
		character:WaitForChild("HumanoidRootPart", 5)
	end

	-- If auto-collect was enabled, re-enable it for the new character
	if autoCollectEnabled then
		EnableAutoCollection()
	end
end)

-- Listen for EnableAutoCollect event
if EnableAutoCollect then
	local success, err = pcall(function()
		EnableAutoCollect.OnClientEvent:Connect(function()
			EnableAutoCollection()
		end)
	end)

	if not success then
		warn("Failed to connect to EnableAutoCollect event: " .. tostring(err))
	end
end

-- Setup heartbeat to check for nearby pets regularly
RunService.Heartbeat:Connect(function()
	-- Only check every 0.5 seconds to reduce performance impact
	if tick() % 0.5 < 0.01 then
		CollectNearbyPets()
	end
end)

-- Initialize auto-collect system
spawn(function()
	-- Wait a moment for everything to load
	wait(2)
	InitializeAutoCollect()
end)

print("Auto-collect script loaded!")