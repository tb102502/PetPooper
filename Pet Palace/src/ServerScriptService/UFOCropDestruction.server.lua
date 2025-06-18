-- Enhanced UFOCropDestruction.server.lua with UFO Animation System
-- Place in ServerScriptService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- RemoteEvent for UFO attack visuals and sound
local ufoAttackEvent = Instance.new("RemoteEvent")
ufoAttackEvent.Name = "UFOAttack"
ufoAttackEvent.Parent = ReplicatedStorage

-- UFO Configuration
local UFO_CONFIG = {
	INTERVAL = 120, -- 2 minutes between attacks
	HOVER_HEIGHT = 100, -- How high UFO hovers above ground
	DESCENT_HEIGHT = 50, -- How low UFO comes down
	BEAM_RADIUS = 30, -- Radius of destruction beam
	ANIMATION_DURATION = 15, -- Total animation time
	UFO_MODEL_NAME = "UFO", -- Name of UFO model in workspace
}

-- UFO Animation State
local ufoState = {
	isActive = false,
	currentUFO = nil,
	destructionBeam = nil,
	hoveredCrops = {},
}

print("=== ENHANCED UFO ATTACK SYSTEM WITH ANIMATION ===")

-- ========== REGION3 UTILITIES (FIXED) ==========

-- Create region data with proper min/max tracking
local function createRegionData(minPoint, maxPoint)
	return {
		minPoint = minPoint,
		maxPoint = maxPoint,
		region3 = Region3.new(minPoint, maxPoint)
	}
end

-- Calculate UFO destruction region (FIXED VERSION)
local function calculateUFODestructionRegion(farmPlots)
	if #farmPlots == 0 then
		print("UFO System: No farm plots found, using default destruction region")
		return createRegionData(
			Vector3.new(-450, -10, 50), 
			Vector3.new(-300, 20, 200)
		)
	end

	-- Calculate bounding box of all farm plots
	local minX, maxX = math.huge, -math.huge
	local minY, maxY = math.huge, -math.huge  
	local minZ, maxZ = math.huge, -math.huge

	for _, plot in ipairs(farmPlots) do
		if plot.PrimaryPart then
			local pos = plot.PrimaryPart.Position
			minX = math.min(minX, pos.X - 20)
			maxX = math.max(maxX, pos.X + 20)
			minY = math.min(minY, pos.Y - 5)
			maxY = math.max(maxY, pos.Y + 15)
			minZ = math.min(minZ, pos.Z - 20)
			maxZ = math.max(maxZ, pos.Z + 20)
		end
	end

	-- Create region with some padding
	local minPoint = Vector3.new(minX - 10, minY, minZ - 10)
	local maxPoint = Vector3.new(maxX + 10, maxY, maxZ + 10)

	local regionData = createRegionData(minPoint, maxPoint)

	print("UFO System: Calculated destruction region from " .. tostring(regionData.minPoint) .. " to " .. tostring(regionData.maxPoint))
	return regionData
end

-- ========== UFO MODEL MANAGEMENT ==========

-- Find or create UFO model
local function getUFOModel()
	local ufo = workspace:FindFirstChild(UFO_CONFIG.UFO_MODEL_NAME)

	if not ufo then
		print("UFO System: Creating UFO model...")
		ufo = createDefaultUFOModel()
	else
		print("UFO System: Found existing UFO model")

		-- Ensure existing UFO has a PrimaryPart
		if not ufo.PrimaryPart then
			print("UFO System: Existing UFO missing PrimaryPart, setting one...")
			local body = ufo:FindFirstChild("Body") or ufo:FindFirstChild("Hull") or ufo:FindFirstChildOfClass("Part")
			if body then
				ufo.PrimaryPart = body
				print("UFO System: Set PrimaryPart to", body.Name)
			else
				warn("UFO System: Could not find suitable PrimaryPart for existing UFO")
				return nil
			end
		end

		-- Ensure all parts are anchored
		for _, part in pairs(ufo:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
		end
	end

	-- Final validation
	if not ufo or not ufo.PrimaryPart then
		warn("UFO System: Failed to get valid UFO model")
		return nil
	end

	print("UFO System: UFO model ready with PrimaryPart:", ufo.PrimaryPart.Name)
	return ufo
end

-- Create default UFO model if none exists
function createDefaultUFOModel()
	local ufoModel = Instance.new("Model")
	ufoModel.Name = UFO_CONFIG.UFO_MODEL_NAME

	-- Position UFO high in the sky initially (will be moved by animation)
	local initialPosition = Vector3.new(0, 200, 0)

	-- Main UFO body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(12, 3, 12)
	body.Shape = Enum.PartType.Cylinder
	body.Material = Enum.Material.Neon
	body.Color = Color3.fromRGB(150, 150, 200) -- Silver-blue
	body.CanCollide = false
	body.Anchored = true
	body.CFrame = CFrame.new(initialPosition)
	body.Parent = ufoModel

	-- UFO dome
	local dome = Instance.new("Part")
	dome.Name = "Dome"
	dome.Size = Vector3.new(6, 6, 6)
	dome.Shape = Enum.PartType.Ball
	dome.Material = Enum.Material.Glass
	dome.Color = Color3.fromRGB(100, 200, 255) -- Light blue
	dome.Transparency = 0.3
	dome.CanCollide = false
	dome.Anchored = true
	dome.Parent = ufoModel

	-- Position dome on top of body
	dome.CFrame = body.CFrame * CFrame.new(0, 3, 0)

	-- UFO lights
	for i = 1, 8 do
		local light = Instance.new("Part")
		light.Name = "Light" .. i
		light.Size = Vector3.new(0.8, 0.8, 0.8)
		light.Shape = Enum.PartType.Ball
		light.Material = Enum.Material.Neon
		light.Color = Color3.fromRGB(255, 255, 0) -- Yellow
		light.CanCollide = false
		light.Anchored = true
		light.Parent = ufoModel

		-- Position lights around the edge
		local angle = (i - 1) * (math.pi * 2 / 8)
		local x = math.cos(angle) * 5
		local z = math.sin(angle) * 5
		light.CFrame = body.CFrame * CFrame.new(x, 0, z)
	end

	-- Set primary part FIRST
	ufoModel.PrimaryPart = body

	-- Parent the model AFTER setting PrimaryPart
	ufoModel.Parent = workspace

	print("UFO System: Created default UFO model with PrimaryPart:", body.Name)
	return ufoModel
end

-- ========== UFO ANIMATION SYSTEM ==========

-- Start UFO attack animation sequence
local function startUFOAnimation(regionData)
	if ufoState.isActive then
		print("UFO System: UFO animation already active, skipping")
		return
	end

	print("UFO System: Starting UFO attack animation...")
	ufoState.isActive = true

	-- Get UFO model
	local ufo = getUFOModel()
	if not ufo then
		warn("UFO System: Failed to get UFO model, aborting animation")
		ufoState.isActive = false
		return
	end

	ufoState.currentUFO = ufo

	-- Calculate center of destruction area
	local centerX = (regionData.minPoint.X + regionData.maxPoint.X) / 2
	local centerZ = (regionData.minPoint.Z + regionData.maxPoint.Z) / 2
	local centerY = regionData.maxPoint.Y + UFO_CONFIG.HOVER_HEIGHT

	local startPosition = Vector3.new(centerX, centerY + 50, centerZ) -- Start higher
	local hoverPosition = Vector3.new(centerX, centerY, centerZ)
	local attackPosition = Vector3.new(centerX, regionData.maxPoint.Y + UFO_CONFIG.DESCENT_HEIGHT, centerZ)

	-- Phase 1: UFO appears and descends to hover position
	animateUFOAppearance(ufo, startPosition, hoverPosition, function()
		-- Phase 2: UFO hovers and scans
		animateUFOScanning(ufo, hoverPosition, function()
			-- Phase 3: UFO descends for attack
			animateUFOAttack(ufo, attackPosition, regionData, function()
				-- Phase 4: UFO retreats
				animateUFORetreat(ufo, startPosition, function()
					-- Animation complete
					completeUFOAnimation()
				end)
			end)
		end)
	end)
end

-- Phase 1: UFO appearance
function animateUFOAppearance(ufo, startPosition, hoverPosition, callback)
	print("UFO System: Phase 1 - UFO appearing...")

	-- Validate UFO model
	if not ufo or not ufo.Parent or not ufo.PrimaryPart then
		warn("UFO System: Invalid UFO model in animateUFOAppearance")
		if callback then callback() end
		return
	end

	-- Position UFO at start
	pcall(function()
		ufo:SetPrimaryPartCFrame(CFrame.new(startPosition))
	end)

	-- Make UFO visible with fade-in effect
	for _, part in pairs(ufo:GetChildren()) do
		if part:IsA("BasePart") then
			part.Transparency = 1
		end
	end

	-- Animate all parts fading in
	for _, part in pairs(ufo:GetChildren()) do
		if part:IsA("BasePart") then
			local targetTransparency = 0
			if part.Name == "Dome" then
				targetTransparency = 0.3
			end

			pcall(function()
				TweenService:Create(part,
					TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{Transparency = targetTransparency}
				):Play()
			end)
		end
	end

	-- Descend to hover position (with error protection)
	local descentTween = nil
	pcall(function()
		descentTween = TweenService:Create(ufo.PrimaryPart,
			TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{CFrame = CFrame.new(hoverPosition)}
		)

		descentTween:Play()
		descentTween.Completed:Connect(function()
			if callback then callback() end
		end)
	end)

	-- Fallback if tween failed
	if not descentTween then
		warn("UFO System: Failed to create descent tween, using fallback")
		spawn(function()
			wait(3) -- Wait the same duration
			if callback then callback() end
		end)
	end

	-- Start UFO rotation
	startUFORotation(ufo)

	-- Notify clients
	ufoAttackEvent:FireAllClients("UFO_APPEAR", hoverPosition)
end

-- Phase 2: UFO scanning
function animateUFOScanning(ufo, hoverPosition, callback)
	print("UFO System: Phase 2 - UFO scanning area...")

	-- Create scanning beam effect
	createScanningBeam(ufo, function()
		if callback then callback() end
	end)

	-- Notify clients
	ufoAttackEvent:FireAllClients("UFO_SCAN")
end

-- Phase 3: UFO attack
function animateUFOAttack(ufo, attackPosition, regionData, callback)
	print("UFO System: Phase 3 - UFO attacking!")

	-- Validate UFO model
	if not ufo or not ufo.Parent or not ufo.PrimaryPart then
		warn("UFO System: Invalid UFO model in animateUFOAttack")
		if callback then callback() end
		return
	end

	-- Descend to attack position (with error protection)
	local attackTween = nil
	pcall(function()
		attackTween = TweenService:Create(ufo.PrimaryPart,
			TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{CFrame = CFrame.new(attackPosition)}
		)

		attackTween:Play()
		attackTween.Completed:Connect(function()
			-- Create destruction beam
			createDestructionBeam(ufo, regionData, function()
				if callback then callback() end
			end)
		end)
	end)

	-- Fallback if tween failed
	if not attackTween then
		warn("UFO System: Failed to create attack tween, using fallback")
		spawn(function()
			wait(2) -- Wait the same duration
			createDestructionBeam(ufo, regionData, function()
				if callback then callback() end
			end)
		end)
	end

	-- Notify clients
	ufoAttackEvent:FireAllClients("UFO_ATTACK", attackPosition)
end

-- Phase 4: UFO retreat
function animateUFORetreat(ufo, startPosition, callback)
	print("UFO System: Phase 4 - UFO retreating...")

	-- Validate UFO model
	if not ufo or not ufo.Parent or not ufo.PrimaryPart then
		warn("UFO System: Invalid UFO model in animateUFORetreat")
		if callback then callback() end
		return
	end

	-- Ascend quickly (with error protection)
	local retreatTween = nil
	pcall(function()
		retreatTween = TweenService:Create(ufo.PrimaryPart,
			TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{CFrame = CFrame.new(startPosition + Vector3.new(0, 100, 0))}
		)

		retreatTween:Play()
		retreatTween.Completed:Connect(function()
			if callback then callback() end
		end)
	end)

	-- Fallback if tween failed
	if not retreatTween then
		warn("UFO System: Failed to create retreat tween, using fallback")
		spawn(function()
			wait(3) -- Wait the same duration
			if callback then callback() end
		end)
	end

	-- Fade out
	spawn(function()
		wait(1) -- Start fading after 1 second of retreat
		for _, part in pairs(ufo:GetChildren()) do
			if part:IsA("BasePart") then
				pcall(function()
					TweenService:Create(part,
						TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{Transparency = 1}
					):Play()
				end)
			end
		end
	end)

	-- Notify clients
	ufoAttackEvent:FireAllClients("UFO_RETREAT")
end

-- ========== UFO EFFECTS ==========

-- Start UFO rotation animation
function startUFORotation(ufo)
	if not ufo or not ufo.PrimaryPart then return end

	spawn(function()
		local rotationConnection
		rotationConnection = RunService.Heartbeat:Connect(function()
			if ufo and ufo.Parent and ufo.PrimaryPart then
				local currentCFrame = ufo.PrimaryPart.CFrame
				ufo:SetPrimaryPartCFrame(currentCFrame * CFrame.Angles(0, math.rad(2), 0))
			else
				rotationConnection:Disconnect()
			end
		end)

		-- Store connection for cleanup
		ufoState.rotationConnection = rotationConnection
	end)
end

-- Create scanning beam effect
function createScanningBeam(ufo, callback)
	if not ufo or not ufo.PrimaryPart then 
		if callback then callback() end
		return 
	end

	local beam = Instance.new("Part")
	beam.Name = "ScanningBeam"
	beam.Size = Vector3.new(2, 50, 2)
	beam.Material = Enum.Material.Neon
	beam.Color = Color3.fromRGB(0, 255, 100) -- Green
	beam.Transparency = 0.3
	beam.CanCollide = false
	beam.Anchored = true
	beam.Shape = Enum.PartType.Cylinder
	beam.Parent = workspace

	-- Position beam below UFO (vertical orientation)
	local ufoPosition = ufo.PrimaryPart.Position
	beam.CFrame = CFrame.new(ufoPosition.X, ufoPosition.Y - 25, ufoPosition.Z) * 
		CFrame.Angles(0, 0, math.rad(90))

	-- Animate beam scanning (changing size and intensity)
	spawn(function()
		for i = 1, 20 do
			local intensity = math.sin(i * 0.5) * 0.5 + 0.5
			beam.Transparency = 0.2 + (intensity * 0.3)
			beam.Size = Vector3.new(2 + intensity, 50, 2 + intensity)
			wait(0.2)
		end

		-- Clean up scanning beam
		beam:Destroy()
		if callback then callback() end
	end)

	print("UFO System: Scanning beam created")
end

-- Create destruction beam effect
function createDestructionBeam(ufo, regionData, callback)
	if not ufo or not ufo.PrimaryPart then 
		if callback then callback() end
		return 
	end

	print("UFO System: Creating destruction beam...")

	local ufoPosition = ufo.PrimaryPart.Position
	local beamHeight = ufoPosition.Y - regionData.maxPoint.Y + 5

	-- Main destruction beam
	local beam = Instance.new("Part")
	beam.Name = "DestructionBeam"
	beam.Size = Vector3.new(UFO_CONFIG.BEAM_RADIUS * 2, beamHeight, UFO_CONFIG.BEAM_RADIUS * 2)
	beam.Material = Enum.Material.Neon
	beam.Color = Color3.fromRGB(0, 255, 0) -- Bright green
	beam.Transparency = 0.2
	beam.CanCollide = false
	beam.Anchored = true
	beam.Shape = Enum.PartType.Cylinder
	beam.Parent = workspace

	-- Position beam vertically (cylinder rotated 90 degrees around Z-axis to be vertical)
	beam.CFrame = CFrame.new(ufoPosition.X, ufoPosition.Y - (beamHeight/2), ufoPosition.Z) * 
		CFrame.Angles(0, 0, math.rad(90))

	ufoState.destructionBeam = beam

	-- Create beam effects
	createBeamParticles(beam)

	-- Animate beam intensity
	spawn(function()
		for i = 1, 30 do
			local intensity = math.sin(i * 0.3) * 0.4 + 0.6
			beam.Transparency = 0.1 + (1 - intensity) * 0.3
			beam.Color = Color3.fromRGB(0, math.floor(255 * intensity), 0)
			wait(0.1)
		end

		-- Destroy crops in beam area
		destroyCropsInBeam(regionData)

		-- Clean up beam
		spawn(function()
			wait(2)
			TweenService:Create(beam,
				TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Transparency = 1}
			):Play()

			Debris:AddItem(beam, 1)
			ufoState.destructionBeam = nil
		end)

		if callback then callback() end
	end)
end

-- Create particles around destruction beam
function createBeamParticles(beam)
	if not beam then return end

	spawn(function()
		for i = 1, 50 do
			local particle = Instance.new("Part")
			particle.Name = "BeamParticle"
			particle.Size = Vector3.new(0.5, 0.5, 0.5)
			particle.Material = Enum.Material.Neon
			particle.Color = Color3.fromRGB(0, 255, 100)
			particle.CanCollide = false
			particle.Anchored = true
			particle.Shape = Enum.PartType.Ball
			particle.Parent = workspace

			-- Random position around beam
			local beamPos = beam.Position
			local randomOffset = Vector3.new(
				math.random(-UFO_CONFIG.BEAM_RADIUS, UFO_CONFIG.BEAM_RADIUS),
				math.random(-beam.Size.Y/2, beam.Size.Y/2),
				math.random(-UFO_CONFIG.BEAM_RADIUS, UFO_CONFIG.BEAM_RADIUS)
			)
			particle.Position = beamPos + randomOffset

			-- Animate particle
			TweenService:Create(particle,
				TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = particle.Position + Vector3.new(
						math.random(-10, 10),
						math.random(-20, 5),
						math.random(-10, 10)
					),
					Transparency = 1,
					Size = Vector3.new(0.1, 0.1, 0.1)
				}
			):Play()

			Debris:AddItem(particle, 2)
			wait(0.1)
		end
	end)
end

-- ========== CROP DESTRUCTION INTEGRATION ==========

-- Get all crops (existing function, keeping it the same)
function getAllCrops()
	local crops = {}
	local farmPlots = {}

	print("UFO System: Scanning for crops...")

	-- Check Areas > Starter Meadow > Farm for player farms
	local areas = workspace:FindFirstChild("Areas")
	if areas then
		local starterMeadow = areas:FindFirstChild("Starter Meadow")
		if starterMeadow then
			local farmArea = starterMeadow:FindFirstChild("Farm")
			if farmArea then
				print("UFO System: Found farm area, checking player farms...")

				for _, playerFarm in pairs(farmArea:GetChildren()) do
					if playerFarm:IsA("Folder") and playerFarm.Name:find("_Farm") then
						local playerName = playerFarm.Name:gsub("_Farm", "")
						print("UFO System: Checking " .. playerName .. "'s farm...")

						for _, plot in pairs(playerFarm:GetChildren()) do
							if plot:IsA("Model") and plot.Name:find("FarmPlot") then
								table.insert(farmPlots, plot)

								local plantingSpots = plot:FindFirstChild("PlantingSpots")
								if plantingSpots then
									for _, spot in pairs(plantingSpots:GetChildren()) do
										if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
											local isEmpty = spot:GetAttribute("IsEmpty")
											if not isEmpty then
												local cropModel = spot:FindFirstChild("CropModel")
												if cropModel then
													local crop = cropModel:FindFirstChild("Crop")
													if crop then
														table.insert(crops, {
															crop = crop,
															spot = spot,
															plot = plot,
															playerName = playerName
														})
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
		end
	end

	print("UFO System: Found " .. #crops .. " total crops across " .. #farmPlots .. " farm plots")
	return crops, farmPlots
end

-- Destroy crops in beam area (enhanced version)
function destroyCropsInBeam(regionData)
	print("UFO System: Destroying crops in beam area...")

	local destroyed = 0
	local protected = 0
	local allCrops, _ = getAllCrops()

	for _, cropData in ipairs(allCrops) do
		local crop = cropData.crop
		local spot = cropData.spot
		local plot = cropData.plot
		local playerName = cropData.playerName

		if crop and crop.Parent then
			local cropPosition = crop.Position

			-- Check if crop is within the beam area
			local minPoint = regionData.minPoint
			local maxPoint = regionData.maxPoint

			if cropPosition.X >= minPoint.X and cropPosition.X <= maxPoint.X and
				cropPosition.Y >= minPoint.Y and cropPosition.Y <= maxPoint.Y and
				cropPosition.Z >= minPoint.Z and cropPosition.Z <= maxPoint.Z then

				-- Check protection (roof protection)
				local isProtected = checkCropProtection(cropData)

				if isProtected then
					protected = protected + 1
					createProtectionEffect(cropPosition)
				else
					destroyed = destroyed + 1
					destroySingleCrop(cropData)
				end
			end
		end
	end

	print("UFO System: Destroyed " .. destroyed .. " crops, protected " .. protected .. " crops")
	return destroyed, protected
end

-- Check if crop is protected (existing function)
function checkCropProtection(cropData)
	if not _G.GameCore then return false end

	local playerName = cropData.playerName
	local plot = cropData.plot

	if not playerName or not plot then return false end

	local player = game.Players:FindFirstChild(playerName)
	if not player then return false end

	local plotNumber = plot.Name:match("FarmPlot_(%d+)")
	if plotNumber then
		plotNumber = tonumber(plotNumber)
		return _G.GameCore:IsPlotProtected(player, plotNumber)
	end

	return false
end

-- Destroy single crop with effects
function destroySingleCrop(cropData)
	local crop = cropData.crop
	local spot = cropData.spot
	local position = crop.Position

	print("UFO System: Destroying crop at " .. tostring(position))

	-- Create destruction effect
	createCropDestructionEffect(position)

	-- Reset spot if it exists
	if spot then
		spot:SetAttribute("IsEmpty", true)
		spot:SetAttribute("PlantType", "")
		spot:SetAttribute("GrowthStage", 0)
		spot:SetAttribute("PlantedTime", 0)

		local cropModel = spot:FindFirstChild("CropModel")
		if cropModel then
			cropModel:Destroy()
		end

		local indicator = spot:FindFirstChild("Indicator")
		if indicator then
			indicator.Color = Color3.fromRGB(100, 255, 100)
		end
	else
		crop:Destroy()
	end
end

-- Create crop destruction effect
function createCropDestructionEffect(position)
	-- Green vaporization effect
	for i = 1, 8 do
		local vapor = Instance.new("Part")
		vapor.Name = "Vapor"
		vapor.Size = Vector3.new(0.3, 0.3, 0.3)
		vapor.Material = Enum.Material.Neon
		vapor.Color = Color3.fromRGB(0, 255, 0)
		vapor.CanCollide = false
		vapor.Anchored = true
		vapor.Shape = Enum.PartType.Ball
		vapor.Position = position + Vector3.new(
			math.random(-1, 1),
			math.random(0, 2),
			math.random(-1, 1)
		)
		vapor.Parent = workspace

		TweenService:Create(vapor,
			TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = vapor.Position + Vector3.new(0, 5, 0),
				Transparency = 1,
				Size = Vector3.new(0.1, 0.1, 0.1)
			}
		):Play()

		Debris:AddItem(vapor, 1.5)
	end

	-- Small explosion
	local explosion = Instance.new("Explosion")
	explosion.Position = position
	explosion.BlastRadius = 3
	explosion.BlastPressure = 0
	explosion.Visible = true
	explosion.Parent = workspace
end

-- Create protection effect
function createProtectionEffect(position)
	-- Blue shield effect for protected crops
	local shield = Instance.new("Part")
	shield.Name = "ProtectionShield"
	shield.Size = Vector3.new(4, 4, 4)
	shield.Shape = Enum.PartType.Ball
	shield.Material = Enum.Material.Neon
	shield.Color = Color3.fromRGB(0, 100, 255)
	shield.Transparency = 0.5
	shield.Anchored = true
	shield.CanCollide = false
	shield.Position = position + Vector3.new(0, 2, 0)
	shield.Parent = workspace

	TweenService:Create(shield,
		TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = Vector3.new(8, 8, 8),
			Transparency = 1
		}
	):Play()

	Debris:AddItem(shield, 2)
end

-- ========== CLEANUP AND COMPLETION ==========

-- Complete UFO animation and cleanup
function completeUFOAnimation()
	print("UFO System: UFO animation sequence complete")

	-- Stop rotation
	if ufoState.rotationConnection then
		ufoState.rotationConnection:Disconnect()
		ufoState.rotationConnection = nil
	end

	-- Clean up state
	ufoState.isActive = false
	ufoState.currentUFO = nil
	ufoState.destructionBeam = nil
	ufoState.hoveredCrops = {}

	-- Notify clients
	ufoAttackEvent:FireAllClients("UFO_COMPLETE")
end

-- ========== MAIN UFO ATTACK LOOP ==========

-- Main UFO attack event loop (enhanced version)
spawn(function()
	print("UFO System: Starting enhanced UFO attack system with full animation")

	while true do
		wait(UFO_CONFIG.INTERVAL)

		-- Check if there are crops to destroy
		local allCrops, farmPlots = getAllCrops()
		local totalCrops = #allCrops

		if totalCrops == 0 then
			print("UFO System: No crops found, skipping UFO attack")
			continue
		end

		if ufoState.isActive then
			print("UFO System: UFO animation already active, skipping this attack")
			continue
		end

		print("UFO System: Starting UFO attack sequence! Found " .. totalCrops .. " crops")

		-- Calculate destruction region
		local regionData = calculateUFODestructionRegion(farmPlots)

		-- Notify clients of attack start
		ufoAttackEvent:FireAllClients("ATTACK_START", totalCrops)

		-- Warn chickens if ChickenSystem exists
		if _G.ChickenSystem then
			pcall(function()
				_G.ChickenSystem:ScatterChickensFromUFO()
			end)
		end

		-- Start UFO animation sequence
		startUFOAnimation(regionData)

		-- Wait for animation to complete
		while ufoState.isActive do
			wait(1)
		end

		-- Restore chickens after attack
		if _G.ChickenSystem then
			spawn(function()
				wait(5)
				pcall(function()
					_G.ChickenSystem:ReturnChickensAfterUFO()
				end)
			end)
		end

		print("UFO System: Attack sequence completed")
	end
end)

-- ========== ADMIN COMMANDS ==========

game.Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.Name == "TommySalami311" then -- Replace with your username
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/testufo" then
				print("Admin: Testing UFO animation sequence")
				local allCrops, farmPlots = getAllCrops()
				local regionData = calculateUFODestructionRegion(farmPlots)
				startUFOAnimation(regionData)

			elseif command == "/createufo" then
				print("Admin: Creating new UFO model")
				local oldUFO = workspace:FindFirstChild(UFO_CONFIG.UFO_MODEL_NAME)
				if oldUFO then oldUFO:Destroy() end
				createDefaultUFOModel()

			elseif command == "/ufoconfig" then
				print("=== UFO CONFIGURATION ===")
				print("Interval: " .. UFO_CONFIG.INTERVAL .. " seconds")
				print("Hover Height: " .. UFO_CONFIG.HOVER_HEIGHT .. " studs")
				print("Descent Height: " .. UFO_CONFIG.DESCENT_HEIGHT .. " studs")
				print("Beam Radius: " .. UFO_CONFIG.BEAM_RADIUS .. " studs")
				print("Animation Duration: " .. UFO_CONFIG.ANIMATION_DURATION .. " seconds")
				print("========================")

			elseif command == "/ufospeed" then
				local speed = args[2]
				if speed == "fast" then
					UFO_CONFIG.INTERVAL = 30
					print("Admin: UFO interval set to 30 seconds")
				elseif speed == "normal" then
					UFO_CONFIG.INTERVAL = 120
					print("Admin: UFO interval set to 2 minutes")
				elseif speed == "slow" then
					UFO_CONFIG.INTERVAL = 300
					print("Admin: UFO interval set to 5 minutes")
				end

			elseif command == "/stopufo" then
				print("Admin: Stopping current UFO animation")
				if ufoState.isActive then
					completeUFOAnimation()
				end

			elseif command == "/checkufo" then
				print("=== UFO MODEL STATUS ===")
				local ufo = workspace:FindFirstChild(UFO_CONFIG.UFO_MODEL_NAME)
				if ufo then
					print("UFO Model: Found ✅")
					print("PrimaryPart: " .. (ufo.PrimaryPart and ufo.PrimaryPart.Name or "MISSING ❌"))
					print("Parts count: " .. #ufo:GetChildren())

					local anchoredCount = 0
					for _, part in pairs(ufo:GetDescendants()) do
						if part:IsA("BasePart") then
							if part.Anchored then
								anchoredCount = anchoredCount + 1
							end
						end
					end
					print("Anchored parts: " .. anchoredCount)

					-- Show UFO position
					if ufo.PrimaryPart then
						print("Position: " .. tostring(ufo.PrimaryPart.Position))
					end
				else
					print("UFO Model: Not found ❌")
					print("Will be created automatically on next attack")
				end
				print("========================")

			elseif command == "/fixufo" then
				print("Admin: Fixing UFO model...")
				local ufo = workspace:FindFirstChild(UFO_CONFIG.UFO_MODEL_NAME)
				if ufo then
					-- Fix PrimaryPart
					if not ufo.PrimaryPart then
						local body = ufo:FindFirstChild("Body") or ufo:FindFirstChild("Hull") or ufo:FindFirstChildOfClass("Part")
						if body then
							ufo.PrimaryPart = body
							print("Set PrimaryPart to: " .. body.Name)
						else
							print("Could not find suitable part for PrimaryPart")
						end
					end

					-- Anchor all parts
					local fixedCount = 0
					for _, part in pairs(ufo:GetDescendants()) do
						if part:IsA("BasePart") and not part.Anchored then
							part.Anchored = true
							fixedCount = fixedCount + 1
						end
					end
					print("Anchored " .. fixedCount .. " parts")

					-- Move UFO to safe position
					if ufo.PrimaryPart then
						ufo:SetPrimaryPartCFrame(CFrame.new(0, 200, 0))
						print("Moved UFO to sky position")
					end

					print("UFO model fixed!")
				else
					print("No UFO found, creating new one...")
					createDefaultUFOModel()
				end
			end
		end
	end)
end)

print("=== ENHANCED UFO SYSTEM LOADED ===")
print("Features:")
print("✅ Cinematic UFO appearance and retreat")
print("✅ Green scanning beam effects")
print("✅ Destructive green beam with particles")
print("✅ UFO rotation and lighting effects")
print("✅ Crop vaporization animations")
print("✅ Protection shield effects")
print("✅ Full integration with existing systems")
print("")
print("Admin Commands:")
print("  /testufo - Test full UFO animation")
print("  /createufo - Create new UFO model")
print("  /ufoconfig - Show UFO configuration")
print("  /ufospeed [fast/normal/slow] - Change attack frequency")
print("  /stopufo - Stop current UFO animation")