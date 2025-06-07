-- UFOCropDestruction.server.lua
-- Place in ServerScriptService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- RemoteEvent for UFO attack visuals and sound
local ufoAttackEvent = Instance.new("RemoteEvent")
ufoAttackEvent.Name = "UFOAttack"
ufoAttackEvent.Parent = ReplicatedStorage
-- FIXED: Much Faster UFO Attack Timing
-- Replace the UFO timing in your UFOCropDestruction.server.lua

local CROP_FOLDER_NAME = "Crops"
local UFO_INTERVAL = 120 -- REDUCED from 600 to 120 seconds (2 minutes instead of 10 minutes)

-- You can also add multiple timing options:

-- Different UFO attack intervals for testing
local UFO_INTERVALS = {
	VERY_FAST = 30,    -- 30 seconds for rapid testing
	FAST = 60,         -- 1 minute  
	NORMAL = 120,      -- 2 minutes
	SLOW = 300,        -- 5 minutes
	VERY_SLOW = 600    -- 10 minutes (original)
}

-- Set the current interval (change this to test different speeds)
local CURRENT_UFO_INTERVAL = UFO_INTERVALS.FAST -- Using 1 minute intervals

-- ENHANCED: UFO Attack with randomized timing
local function getRandomUFOInterval()
	-- Add some randomness to make attacks less predictable
	local baseInterval = CURRENT_UFO_INTERVAL
	local randomVariation = math.random(-20, 20) -- ±20 second variation
	return math.max(30, baseInterval + randomVariation) -- Minimum 30 seconds
end

-- ENHANCED: UFO Event Loop with better feedback
spawn(function()
	print("UFO System: Starting UFO attack system with " .. CURRENT_UFO_INTERVAL .. " second intervals")

	while true do
		local nextAttackTime = getRandomUFOInterval()
		print("UFO System: Next UFO attack in " .. nextAttackTime .. " seconds")

		wait(nextAttackTime)

		-- Check if there are actually crops to destroy
		local totalCrops = 0
		local allCrops = getAllCrops()
		totalCrops = #allCrops

		if totalCrops == 0 then
			print("UFO System: No crops found, skipping UFO attack")
			continue -- Skip this attack if no crops exist
		end

		print("UFO System: UFO attack starting! Found " .. totalCrops .. " crops to potentially destroy")

		-- 1. Sky darkens and tornado siren plays
		ufoAttackEvent:FireAllClients("START", totalCrops)

		-- 2. Wait a few seconds for effect buildup
		wait(3)

		-- 3. Simulate UFO beam moving through plots and destroying crops
		local ufoPathRegion = Region3.new(Vector3.new(-450, -5, 50), Vector3.new(-300, 15, 200))
		local destroyedCount, protectedCount = destroyCropsInPath(ufoPathRegion)

		print("UFO System: UFO attack complete! Destroyed " .. destroyedCount .. " crops, " .. protectedCount .. " crops protected")

		-- 4. Notify clients beam is done (include protection info)
		ufoAttackEvent:FireAllClients("END", destroyedCount, protectedCount)

		-- 5. Show server-side statistics with protection info
		if destroyedCount > 0 then
			print("UFO System: UFO attack destroyed " .. destroyedCount .. " unprotected crops!")
		else
			print("UFO System: UFO attack found no unprotected crops!")
		end

		if protectedCount > 0 then
			print("UFO System: " .. protectedCount .. " crops were protected by roofs!")
		end
	end
end)

-- ENHANCED: Better crop detection function
function getAllCrops()
	local crops = {}

	-- Check standard crop locations
	local farmFolder = workspace:FindFirstChild("FarmPlots") or workspace
	for _, plot in ipairs(farmFolder:GetChildren()) do
		local cropFolder = plot:FindFirstChild(CROP_FOLDER_NAME)
		if cropFolder then
			for _, crop in ipairs(cropFolder:GetChildren()) do
				if crop:IsA("Model") or crop:IsA("Part") then
					table.insert(crops, crop)
				end
			end
		end
	end

	-- Also check Areas > Starter Meadow > Farm for player farms
	local areas = workspace:FindFirstChild("Areas")
	if areas then
		local starterMeadow = areas:FindFirstChild("Starter Meadow")
		if starterMeadow then
			local farmArea = starterMeadow:FindFirstChild("Farm")
			if farmArea then
				for _, playerFarm in pairs(farmArea:GetChildren()) do
					if playerFarm:IsA("Folder") and playerFarm.Name:find("_Farm") then
						for _, plot in pairs(playerFarm:GetChildren()) do
							if plot:IsA("Model") and plot.Name:find("FarmPlot") then
								-- Check for crops in planting spots
								local plantingSpots = plot:FindFirstChild("PlantingSpots")
								if plantingSpots then
									for _, spot in pairs(plantingSpots:GetChildren()) do
										local cropModel = spot:FindFirstChild("CropModel")
										if cropModel then
											local crop = cropModel:FindFirstChild("Crop")
											if crop then
												table.insert(crops, crop)
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end

	return crops
end

-- ENHANCED: More accurate crop destruction
-- ENHANCED: More accurate crop destruction with roof protection
function destroyCropsInPath(pathRegion)
	local destroyed = 0
	local protected = 0
	local allCrops = getAllCrops()

	for _, crop in ipairs(allCrops) do
		if crop and crop.Parent then
			local cropPosition = crop.Position

			-- Check if crop is within the UFO destruction path
			local minPoint = pathRegion.MinPoint
			local maxPoint = pathRegion.MaxPoint

			if cropPosition.X >= minPoint.X and cropPosition.X <= maxPoint.X and
				cropPosition.Y >= minPoint.Y and cropPosition.Y <= maxPoint.Y and
				cropPosition.Z >= minPoint.Z and cropPosition.Z <= maxPoint.Z then

				-- Check if this crop is protected by a roof
				local isProtected = checkCropProtection(crop)

				if isProtected then
					-- Crop is protected - create protection effect
					createProtectionEffect(crop)
					protected = protected + 1
					print("UFO System: Crop at", cropPosition, "protected by roof!")
				else
					-- Destroy the crop
					print("UFO System: Destroying unprotected crop at position", cropPosition)

					-- If it's part of a planting spot, reset the spot
					local spotModel = crop.Parent.Parent
					if spotModel and spotModel:IsA("Model") and spotModel.Name:find("PlantingSpot") then
						spotModel:SetAttribute("IsEmpty", true)
						spotModel:SetAttribute("PlantType", "")
						spotModel:SetAttribute("GrowthStage", 0)
						crop.Parent:Destroy() -- Destroy the entire CropModel
					else
						crop:Destroy() -- Destroy just the crop part
					end

					destroyed = destroyed + 1
				end
			end
		end
	end

	print("UFO System: Destroyed " .. destroyed .. " crops, " .. protected .. " crops protected by roofs")
	return destroyed, protected
end

-- NEW FUNCTION: Check if a crop is protected by roof
function checkCropProtection(crop)
	-- Find which player's farm this crop belongs to
	local playerName = getCropOwner(crop)
	if not playerName then return false end

	-- Get the player object
	local player = game.Players:FindFirstChild(playerName)
	if not player then return false end

	-- Get plot number for this crop
	local plotNumber = getCropPlotNumber(crop)
	if not plotNumber then return false end

	-- Check if GameCore is available
	if not _G.GameCore then return false end

	-- Use GameCore to check protection
	return _G.GameCore:IsPlotProtected(player, plotNumber)
end

-- NEW FUNCTION: Get the owner of a crop
function getCropOwner(crop)
	-- Navigate up the parent hierarchy to find player farm
	local parent = crop.Parent
	local attempts = 0

	while parent and attempts < 10 do
		attempts = attempts + 1

		if parent.Name:find("_Farm") then
			return parent.Name:gsub("_Farm", "")
		end

		parent = parent.Parent
	end

	return nil
end

-- NEW FUNCTION: Get plot number for a crop
function getCropPlotNumber(crop)
	-- Navigate up to find the farm plot
	local parent = crop.Parent
	local attempts = 0

	while parent and attempts < 10 do
		attempts = attempts + 1

		if parent.Name:find("FarmPlot_") then
			local plotNumber = parent.Name:match("FarmPlot_(%d+)")
			return tonumber(plotNumber)
		end

		parent = parent.Parent
	end

	return nil
end

-- NEW FUNCTION: Create visual effect when crop is protected
function createProtectionEffect(crop)
	if not crop or not crop.Parent then return end

	-- Create shield effect
	local shield = Instance.new("Part")
	shield.Name = "ProtectionShield"
	shield.Size = Vector3.new(6, 6, 6)
	shield.Shape = Enum.PartType.Ball
	shield.Material = Enum.Material.Neon
	shield.Color = Color3.fromRGB(0, 255, 0) -- Green protection
	shield.Transparency = 0.5
	shield.Anchored = true
	shield.CanCollide = false
	shield.CFrame = CFrame.new(crop.Position + Vector3.new(0, 3, 0))
	shield.Parent = workspace

	-- Create sparkle effects
	for i = 1, 8 do
		local sparkle = Instance.new("Part")
		sparkle.Name = "ProtectionSparkle"
		sparkle.Size = Vector3.new(0.5, 0.5, 0.5)
		sparkle.Shape = Enum.PartType.Ball
		sparkle.Material = Enum.Material.Neon
		sparkle.Color = Color3.fromRGB(255, 255, 0) -- Yellow sparkles
		sparkle.Anchored = true
		sparkle.CanCollide = false
		sparkle.CFrame = CFrame.new(crop.Position + Vector3.new(
			math.random(-3, 3),
			math.random(1, 5),
			math.random(-3, 3)
			))
		sparkle.Parent = workspace

		-- Animate sparkle
		game:GetService("TweenService"):Create(sparkle,
			TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = sparkle.Position + Vector3.new(0, 8, 0),
				Transparency = 1,
				Size = Vector3.new(0.1, 0.1, 0.1)
			}
		):Play()

		-- Remove sparkle after animation
		game:GetService("Debris"):AddItem(sparkle, 2)
	end

	-- Animate shield
	game:GetService("TweenService"):Create(shield,
		TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = Vector3.new(10, 10, 10),
			Transparency = 1
		}
	):Play()

	-- Remove shield after animation
	game:GetService("Debris"):AddItem(shield, 1.5)
end

-- ADMIN COMMANDS: Add these to test different UFO timings
game.Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		-- Replace with your username
		if player.Name == "TommySalami311" then
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/ufo" then
				-- Trigger immediate UFO attack
				print("Admin: Triggering immediate UFO attack")
				ufoAttackEvent:FireAllClients("START", 0)
				wait(3)
				local destroyedCount = destroyCropsInPath(Region3.new(Vector3.new(-450, -5, 50), Vector3.new(-300, 15, 200)))
				ufoAttackEvent:FireAllClients("END", destroyedCount)

			elseif command == "/ufospeed" then
				local speed = args[2]
				if speed == "fast" then
					CURRENT_UFO_INTERVAL = UFO_INTERVALS.VERY_FAST
					print("Admin: UFO speed set to VERY_FAST (30 seconds)")
				elseif speed == "normal" then
					CURRENT_UFO_INTERVAL = UFO_INTERVALS.NORMAL
					print("Admin: UFO speed set to NORMAL (2 minutes)")
				elseif speed == "slow" then
					CURRENT_UFO_INTERVAL = UFO_INTERVALS.SLOW
					print("Admin: UFO speed set to SLOW (5 minutes)")
				else
					print("Admin: UFO speeds available: fast, normal, slow")
				end

			elseif command == "/cropcount" then
				local crops = getAllCrops()
				print("Admin: Found " .. #crops .. " crops in the game")

			elseif command == "/testregion" then
				-- Test if the UFO destruction region is positioned correctly
				local region = Region3.new(Vector3.new(-450, -5, 50), Vector3.new(-300, 15, 200))
				print("Admin: UFO destruction region spans from", region.MinPoint, "to", region.MaxPoint)
			end
		end
	end)
end)

print("UFO System: Loaded with " .. CURRENT_UFO_INTERVAL .. " second intervals")
print("Admin commands: /ufo (immediate attack), /ufospeed [fast/normal/slow], /cropcount, /testregion")