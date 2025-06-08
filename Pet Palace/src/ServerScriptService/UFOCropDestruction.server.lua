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
--[[
    UFO System Updates - Chicken Integration
    
    ADD THESE FUNCTIONS TO YOUR EXISTING UFOCropDestruction.server.lua file:
    
    Updates the UFO attack system to:
    1. Scatter chickens during attacks
    2. Create chicken panic effects
    3. Reduce chicken effectiveness temporarily
    4. Show protection from chicken coops
]]

-- ========== ADD TO UFO ATTACK EVENT LOOP ==========

-- Replace your existing UFO attack loop with this enhanced version:

spawn(function()
	print("UFO System: Starting enhanced UFO attack system with chicken integration")

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

		-- NEW: Warn chickens before attack
		if _G.ChickenSystem then
			warnChickensOfAttack()
		end

		-- 1. Sky darkens and tornado siren plays
		ufoAttackEvent:FireAllClients("START", totalCrops)

		-- 2. Wait a few seconds for effect buildup
		wait(3)

		-- NEW: Scatter chickens during attack
		if _G.ChickenSystem then
			scatterChickensFromUFO()
		end

		-- 3. Simulate UFO beam moving through plots and destroying crops
		local ufoPathRegion = Region3.new(Vector3.new(-450, -5, 50), Vector3.new(-300, 15, 200))
		local destroyedCount, protectedCount = destroyCropsInPath(ufoPathRegion)

		print("UFO System: UFO attack complete! Destroyed " .. destroyedCount .. " crops, " .. protectedCount .. " crops protected")

		-- 4. Notify clients beam is done (include protection info)
		ufoAttackEvent:FireAllClients("END", destroyedCount, protectedCount)

		-- NEW: Restore chicken behavior after attack
		if _G.ChickenSystem then
			spawn(function()
				wait(10) -- Wait 10 seconds for chickens to recover
				restoreChickenBehavior()
			end)
		end

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

-- ========== NEW CHICKEN INTEGRATION FUNCTIONS ==========

-- Warn chickens of incoming UFO attack
function warnChickensOfAttack()
	print("UFO System: Warning chickens of incoming attack")

	-- Better safety checks for ChickenSystem
	if not _G.ChickenSystem then 
		print("UFO System: ChickenSystem not available")
		return 
	end

	if not _G.ChickenSystem.PlayerChickens then
		print("UFO System: ChickenSystem.PlayerChickens not initialized")
		return
	end

	-- Check if PlayerChickens is empty
	local hasChickens = false
	for _ in pairs(_G.ChickenSystem.PlayerChickens) do
		hasChickens = true
		break
	end

	if not hasChickens then
		print("UFO System: No chickens found in the system")
		return
	end

	-- Find all Guinea Fowl (they have alarm systems)
	for playerId, chickens in pairs(_G.ChickenSystem.PlayerChickens) do
		if chickens then -- Additional safety check
			for chickenId, chicken in pairs(chickens) do
				if chicken and chicken.type == "guinea_fowl" then
					-- Guinea fowl detect the UFO and sound alarm
					local player = game.Players:GetPlayerByUserId(playerId)
					if player and _G.GameCore and _G.GameCore.SendNotification then
						_G.GameCore:SendNotification(player, "🚨 Guinea Fowl Alert!", 
							"Your guinea fowl detected the incoming UFO attack!", "warning")
					end

					-- Create alarm effect (with safety check)
					pcall(function()
						createGuineaFowlAlarmEffect(chicken)
					end)
				end
			end
		end
	end
end
-- Scatter chickens when UFO attacks

function scatterChickensFromUFO()
	print("UFO System: Scattering chickens from UFO attack")

	-- Safety checks
	if not _G.ChickenSystem then 
		print("UFO System: ChickenSystem not available for scattering")
		return 
	end

	if not _G.ChickenSystem.PlayerChickens then
		print("UFO System: ChickenSystem.PlayerChickens not initialized for scattering")
		return
	end

	local scatteredCount = 0

	-- Scatter all chickens to safe locations
	for playerId, chickens in pairs(_G.ChickenSystem.PlayerChickens) do
		if chickens then -- Additional safety check
			for chickenId, chicken in pairs(chickens) do
				if chicken then -- Check chicken exists
					-- Store original position for later restoration
					if not chicken.originalPosition then
						chicken.originalPosition = chicken.position or chicken.homePosition or Vector3.new(0, 0, 0)
					end

					-- Move chicken to random safe location (away from farm area)
					local homePos = chicken.homePosition or chicken.position or Vector3.new(0, 0, 0)
					local safePosition = homePos + Vector3.new(
						math.random(-50, 50),
						0,
						math.random(-50, 50)
					)

					-- Make sure it's not too far from home
					local maxDistance = 100
					local homeDistance = (safePosition - homePos).Magnitude
					if homeDistance > maxDistance then
						safePosition = homePos + (safePosition - homePos).Unit * maxDistance
					end

					-- Move chicken with safety check
					if _G.ChickenSystem.MoveChickenTo then
						pcall(function()
							_G.ChickenSystem:MoveChickenTo(chicken, safePosition)
						end)
					else
						-- Fallback: manually update position
						chicken.position = safePosition
					end

					-- Mark chicken as panicked
					chicken.isPanicked = true
					chicken.panicStartTime = os.time()

					-- Interrupt any current hunting
					if chicken.isHunting then
						chicken.isHunting = false
						if _G.ChickenSystem.ChickenAssignments then
							_G.ChickenSystem.ChickenAssignments[chickenId] = nil
						end
					end

					scatteredCount = scatteredCount + 1

					-- Create panic visual effect (with safety)
					pcall(function()
						createChickenPanicEffect(chicken)
					end)
				end
			end
		end
	end
end
-- Restore chicken behavior after UFO attack
function restoreChickenBehavior()
	print("UFO System: Restoring chicken behavior after UFO attack")

	-- Safety checks
	if not _G.ChickenSystem then 
		print("UFO System: ChickenSystem not available for restoration")
		return 
	end

	if not _G.ChickenSystem.PlayerChickens then
		print("UFO System: ChickenSystem.PlayerChickens not initialized for restoration")
		return
	end

	local restoredCount = 0

	for playerId, chickens in pairs(_G.ChickenSystem.PlayerChickens) do
		if chickens then -- Additional safety check
			for chickenId, chicken in pairs(chickens) do
				if chicken and chicken.isPanicked then
					-- Remove panic state
					chicken.isPanicked = false
					chicken.panicStartTime = nil

					-- Move chicken back towards home (but not exactly to original position)
					local homePos = chicken.homePosition or chicken.originalPosition or Vector3.new(0, 0, 0)
					local returnPosition = homePos + Vector3.new(
						math.random(-10, 10),
						0,
						math.random(-10, 10)
					)

					-- Move chicken with safety check
					if _G.ChickenSystem.MoveChickenTo then
						pcall(function()
							_G.ChickenSystem:MoveChickenTo(chicken, returnPosition)
						end)
					else
						-- Fallback: manually update position
						chicken.position = returnPosition
					end

					-- Reduce chicken effectiveness temporarily (they're still scared)
					chicken.postUFOStress = os.time()

					restoredCount = restoredCount + 1

					-- Create recovery visual effect (with safety)
					pcall(function()
						createChickenRecoveryEffect(chicken)
					end)

					-- Notify player
					local player = game.Players:GetPlayerByUserId(playerId)
					if player and _G.GameCore and _G.GameCore.SendNotification then
						_G.GameCore:SendNotification(player, "🐔 Chickens Returning", 
							"Your chickens are returning to their posts after the UFO attack.", "info")
					end
				end
			end
		end
	end

	if restoredCount > 0 then
		print("UFO System: Restored " .. restoredCount .. " chickens to normal behavior")
	else
		print("UFO System: No chickens needed restoration")
	end
end

-- ========== VISUAL EFFECTS FOR CHICKEN INTERACTIONS ==========

-- Create alarm effect for Guinea Fowl
function createGuineaFowlAlarmEffect(chicken)
	-- Safety checks
	if not chicken or not chicken.id then return end
	if not _G.ChickenSystem or not _G.ChickenSystem.ChickenVisuals then return end

	local chickenVisual = _G.ChickenSystem.ChickenVisuals[chicken.id]
	if not chickenVisual or not chickenVisual.PrimaryPart then return end

	-- Create alarm visual with error protection
	for i = 1, 5 do
		local success, err = pcall(function()
			local alarm = Instance.new("Part")
			alarm.Name = "AlarmEffect"
			alarm.Size = Vector3.new(2, 0.1, 2)
			alarm.Shape = Enum.PartType.Cylinder
			alarm.Material = Enum.Material.Neon
			alarm.Color = Color3.fromRGB(255, 255, 0) -- Bright yellow
			alarm.CanCollide = false
			alarm.Anchored = true
			alarm.CFrame = chickenVisual.PrimaryPart.CFrame + Vector3.new(0, 3 + i, 0)
			alarm.Parent = chickenVisual

			-- Animate alarm expanding
			game:GetService("TweenService"):Create(alarm,
				TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Size = Vector3.new(10, 0.1, 10),
					Transparency = 1
				}
			):Play()

			-- Remove after animation
			game:GetService("Debris"):AddItem(alarm, 1)
		end)

		if not success then
			warn("UFO System: Failed to create guinea fowl alarm effect: " .. tostring(err))
			break
		end

		wait(0.2)
	end
end

-- Create panic effect for scattered chickens
function createChickenPanicEffect(chicken)
	-- Safety checks
	if not chicken or not chicken.id then return end
	if not _G.ChickenSystem or not _G.ChickenSystem.ChickenVisuals then return end

	local chickenVisual = _G.ChickenSystem.ChickenVisuals[chicken.id]
	if not chickenVisual or not chickenVisual.PrimaryPart then return end

	-- Create panic particles with error protection
	pcall(function()
		for i = 1, 8 do
			local panic = Instance.new("Part")
			panic.Name = "PanicEffect"
			panic.Size = Vector3.new(0.3, 0.3, 0.3)
			panic.Shape = Enum.PartType.Ball
			panic.Material = Enum.Material.Neon
			panic.Color = Color3.fromRGB(255, 100, 100) -- Red panic
			panic.CanCollide = false
			panic.Anchored = true
			panic.CFrame = chickenVisual.PrimaryPart.CFrame + Vector3.new(
				math.random(-2, 2),
				math.random(1, 3),
				math.random(-2, 2)
			)
			panic.Parent = workspace

			-- Animate panic particle
			game:GetService("TweenService"):Create(panic,
				TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = panic.Position + Vector3.new(
						math.random(-5, 5),
						math.random(3, 8),
						math.random(-5, 5)
					),
					Transparency = 1,
					Size = Vector3.new(0.1, 0.1, 0.1)
				}
			):Play()

			game:GetService("Debris"):AddItem(panic, 2)
		end

		-- Change chicken visual to show panic
		if chickenVisual.PrimaryPart then
			chickenVisual.PrimaryPart.Color = chickenVisual.PrimaryPart.Color:lerp(Color3.fromRGB(255, 200, 200), 0.5)
		end
	end)
end

-- Create recovery effect for chickens
function createChickenRecoveryEffect(chicken)
	local chickenVisual = _G.ChickenSystem.ChickenVisuals[chicken.id]
	if not chickenVisual or not chickenVisual.PrimaryPart then return end

	-- Create calming particles
	for i = 1, 6 do
		local calm = Instance.new("Part")
		calm.Name = "CalmEffect"
		calm.Size = Vector3.new(0.4, 0.4, 0.4)
		calm.Shape = Enum.PartType.Ball
		calm.Material = Enum.Material.Neon
		calm.Color = Color3.fromRGB(100, 255, 100) -- Green calm
		calm.CanCollide = false
		calm.Anchored = true
		calm.CFrame = chickenVisual.PrimaryPart.CFrame + Vector3.new(
			math.random(-1, 1),
			math.random(0, 2),
			math.random(-1, 1)
		)
		calm.Parent = workspace

		-- Animate calm particle
		game:GetService("TweenService"):Create(calm,
			TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{
				Position = calm.Position + Vector3.new(0, 3, 0),
				Transparency = 1,
				Size = Vector3.new(0.1, 0.1, 0.1)
			}
		):Play()

		game:GetService("Debris"):AddItem(calm, 1.5)
	end

	-- Restore chicken visual color
	if chickenVisual.PrimaryPart then
		local chickenType = chicken.type
		local originalColor = _G.ChickenSystem:GetChickenColor(chickenType)

		game:GetService("TweenService"):Create(chickenVisual.PrimaryPart,
			TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Color = originalColor}
		):Play()
	end
end

-- ========== ENHANCED CROP PROTECTION CHECKING ==========

-- Update the existing checkCropProtection function to include chicken protection:

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

	-- Check roof protection first
	local hasRoofProtection = _G.GameCore:IsPlotProtected(player, plotNumber)
	if hasRoofProtection then
		return true -- Roof protection is absolute
	end

	-- NEW: Check for chicken protection
	local hasChickenProtection = checkChickenProtection(crop, playerName)
	if hasChickenProtection then
		return true
	end

	return false
end

-- NEW: Check if chickens provide protection for this crop
function checkChickenProtection(crop, playerName)
	-- Safety checks
	if not _G.ChickenSystem then return false end
	if not _G.ChickenSystem.PlayerChickens then return false end

	local player = game.Players:FindFirstChild(playerName)
	if not player then return false end

	local playerChickens = _G.ChickenSystem.PlayerChickens[player.UserId]
	if not playerChickens then return false end

	-- Check if any chickens are protecting this area
	for chickenId, chicken in pairs(playerChickens) do
		if chicken and chicken.position then -- Ensure chicken and position exist
			-- Skip panicked chickens (they can't protect during UFO attacks)
			if not chicken.isPanicked then
				local distance = (chicken.position - crop.Position).Magnitude

				-- Check if chicken is close enough and can provide protection
				local huntRange = 10 -- Default range

				-- Try to get chicken data safely
				local chickenData = nil
				if game:GetService("ReplicatedStorage"):FindFirstChild("ItemConfig") then
					local success, result = pcall(function()
						return require(game:GetService("ReplicatedStorage").ItemConfig)
					end)
					if success and result and result.ChickenSystem and result.ChickenSystem.chickenTypes then
						chickenData = result.ChickenSystem.chickenTypes[chicken.type]
					end
				end

				if chickenData and chickenData.huntRange then
					huntRange = chickenData.huntRange
				end

				if distance <= huntRange then
					-- Roosters provide extra protection due to intimidation
					if chicken.type == "rooster" then
						return true -- Roosters always provide protection in their range
					elseif math.random() < 0.7 then -- 70% chance for other chickens to protect
						return true
					end
				end
			end
		end
	end

	return false
end


-- ========== ADMIN COMMANDS UPDATE ==========

-- Add these new admin commands to your existing admin command section:

game.Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		-- Replace with your username
		if player.Name == "TommySalami311" then
			local args = string.split(message:lower(), " ")
			local command = args[1]

			-- ... existing admin commands ...

			if command == "/scatterchickens" then
				-- Test chicken scattering
				print("Admin: Testing chicken scattering")
				if _G.ChickenSystem then
					scatterChickensFromUFO()
				else
					print("Admin: ChickenSystem not available")
				end

			elseif command == "/restorechickens" then
				-- Test chicken restoration
				print("Admin: Testing chicken restoration")
				if _G.ChickenSystem then
					restoreChickenBehavior()
				else
					print("Admin: ChickenSystem not available")
				end

			elseif command == "/ufowitchchickens" then
				-- Full UFO attack with chicken interaction
				print("Admin: Triggering UFO attack with chicken integration")
				if _G.ChickenSystem then
					warnChickensOfAttack()
					wait(2)
					scatterChickensFromUFO()
					wait(5)
					restoreChickenBehavior()
				end

			elseif command == "/checkchickenprotection" then
				-- Check chicken protection status
				print("Admin: Checking chicken protection for " .. player.Name)
				if _G.ChickenSystem then
					local playerChickens = _G.ChickenSystem.PlayerChickens[player.UserId] or {}
					local chickenCount = 0
					local protectingCount = 0

					for chickenId, chicken in pairs(playerChickens) do
						chickenCount = chickenCount + 1
						if not chicken.isPanicked then
							protectingCount = protectingCount + 1
						end
					end

					print("Admin: " .. player.Name .. " has " .. chickenCount .. " chickens, " .. protectingCount .. " currently protecting")
				else
					print("Admin: ChickenSystem not available")
				end
			end
		end
	end)
end)

print("UFO System: Enhanced with chicken integration!")
print("New Features:")
print("  ✅ Guinea fowl early warning system")
print("  ✅ Chicken scattering during UFO attacks")
print("  ✅ Chicken panic and recovery effects")
print("  ✅ Chicken-based crop protection")
print("  ✅ Post-attack chicken stress mechanics")
print("")
print("New Admin Commands:")
print("  /scatterchickens - Test chicken scattering")
print("  /restorechickens - Test chicken restoration")
print("  /ufowitchchickens - Full UFO attack with chicken effects")
print("  /checkchickenprotection - Check chicken protection status")

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
-- ========== FIX #7: Disable Chicken Integration Temporarily ==========
-- If you want to disable chicken integration entirely until ChickenSystem is ready:

-- REPLACE the UFO attack loop section with this version that can work without chickens:

spawn(function()
	print("UFO System: Starting UFO attack system (chicken integration optional)")

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

		-- SAFE: Warn chickens before attack (with error protection)
		local chickenWarningSuccess = pcall(function()
			if _G.ChickenSystem and _G.ChickenSystem.PlayerChickens then
				warnChickensOfAttack()
			else
				print("UFO System: Skipping chicken warning (ChickenSystem not ready)")
			end
		end)

		if not chickenWarningSuccess then
			print("UFO System: Chicken warning failed, continuing without chickens")
		end

		-- 1. Sky darkens and tornado siren plays
		ufoAttackEvent:FireAllClients("START", totalCrops)

		-- 2. Wait a few seconds for effect buildup
		wait(3)

		-- SAFE: Scatter chickens during attack (with error protection)
		local chickenScatterSuccess = pcall(function()
			if _G.ChickenSystem and _G.ChickenSystem.PlayerChickens then
				scatterChickensFromUFO()
			else
				print("UFO System: Skipping chicken scattering (ChickenSystem not ready)")
			end
		end)

		if not chickenScatterSuccess then
			print("UFO System: Chicken scattering failed, continuing without chickens")
		end

		-- 3. Simulate UFO beam moving through plots and destroying crops
		local ufoPathRegion = Region3.new(Vector3.new(-450, -5, 50), Vector3.new(-300, 15, 200))
		local destroyedCount, protectedCount = destroyCropsInPath(ufoPathRegion)

		print("UFO System: UFO attack complete! Destroyed " .. destroyedCount .. " crops, " .. protectedCount .. " crops protected")

		-- 4. Notify clients beam is done (include protection info)
		ufoAttackEvent:FireAllClients("END", destroyedCount, protectedCount)

		-- SAFE: Restore chicken behavior after attack (with error protection)
		spawn(function()
			wait(10) -- Wait 10 seconds for chickens to recover
			local chickenRestoreSuccess = pcall(function()
				if _G.ChickenSystem and _G.ChickenSystem.PlayerChickens then
					restoreChickenBehavior()
				else
					print("UFO System: Skipping chicken restoration (ChickenSystem not ready)")
				end
			end)

			if not chickenRestoreSuccess then
				print("UFO System: Chicken restoration failed")
			end
		end)

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

print("UFO System: Loaded with " .. CURRENT_UFO_INTERVAL .. " second intervals")
print("Admin commands: /ufo (immediate attack), /ufospeed [fast/normal/slow], /cropcount, /testregion")