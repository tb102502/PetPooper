-- Put this in ClientScript.client.lua or a new ModuleScript

local EffectsModule = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Sound effects - create these once and reuse
local sounds = {
	common = {
		id = "rbxassetid://9125684553",  -- Change to your sound ID
		volume = 0.5,
		pitch = 1.0
	},
	rare = {
		id = "rbxassetid://6156456968",  -- Change to your sound ID
		volume = 0.6,
		pitch = 1.1
	},
	epic = {
		id = "rbxassetid://9114397785",  -- Change to your sound ID
		volume = 0.7,
		pitch = 0.9
	},
	legendary = {
		id = "rbxassetid://5153734608",  -- Change to your sound ID
		volume = 0.8,
		pitch = 0.8
	}
}

-- Cache sound instances
local soundInstances = {}

-- Function to initialize all sounds
function EffectsModule.InitializeSounds()
	for rarity, soundInfo in pairs(sounds) do
		local sound = Instance.new("Sound")
		sound.SoundId = soundInfo.id
		sound.Volume = soundInfo.volume
		sound.PlaybackSpeed = soundInfo.pitch
		sound.Parent = player.PlayerGui
		soundInstances[rarity] = sound
	end

	print("Sound effects initialized")
end

-- Collection animation with fancy particles and sounds
function EffectsModule.PlayCollectionEffect(petModel, petType)
	-- If petType is a string, convert it to minimum required data
	if type(petType) == "string" then
		petType = {
			name = petType,
			rarity = "Common",
			collectValue = 1
		}
	end

	-- Make sure we have the correct data
	if not petType then
		warn("Missing pet type data for collection effect")
		return
	end

	-- Default rarity if missing
	local rarity = petType.rarity or "Common"
	local value = petType.collectValue or 1

	-- Get character reference
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	-- Get the position of the pet
	local petPosition
	if typeof(petModel) == "Instance" then
		if petModel:IsA("BasePart") then
			petPosition = petModel.Position
		elseif petModel:IsA("Model") and petModel.PrimaryPart then
			petPosition = petModel.PrimaryPart.Position
		else
			-- Try to find any part
			for _, part in pairs(petModel:GetDescendants()) do
				if part:IsA("BasePart") then
					petPosition = part.Position
					break
				end
			end
		end
	end

	-- If we couldn't get a position, use the character's position
	if not petPosition then
		petPosition = humanoidRootPart.Position + Vector3.new(0, 0, -3)
	end

	-- Player position reference
	local playerPosition = humanoidRootPart.Position

	-- Play appropriate sound based on rarity
	local raritySound = rarity:lower()
	if soundInstances[raritySound] then
		-- Clone and play to allow overlapping sounds
		local soundClone = soundInstances[raritySound]:Clone()
		soundClone.Parent = player.PlayerGui
		soundClone:Play()

		-- Auto-cleanup
		delay(5, function()
			if soundClone then
				soundClone:Destroy()
			end
		end)
	end

	-- Setup color and particle count based on rarity
	local particleColor, particleCount, particleSize, particleSpeed

	if rarity == "Common" then
		particleColor = Color3.fromRGB(220, 220, 220) -- Light gray
		particleCount = 15
		particleSize = 0.5
		particleSpeed = 20
	elseif rarity == "Rare" then
		particleColor = Color3.fromRGB(30, 150, 255) -- Bright blue
		particleCount = 25
		particleSize = 0.6
		particleSpeed = 25
	elseif rarity == "Epic" then
		particleColor = Color3.fromRGB(150, 70, 255) -- Bright purple
		particleCount = 35
		particleSize = 0.7
		particleSpeed = 30
	elseif rarity == "Legendary" then
		particleColor = Color3.fromRGB(255, 215, 0) -- Gold
		particleCount = 50
		particleSize = 0.8
		particleSpeed = 35
	end

	-- Create a "collect" animation on the pet
	if typeof(petModel) == "Instance" and petModel:IsA("Model") and petModel.PrimaryPart then
		-- Animate the pet floating up and fading
		spawn(function()
			local originalCFrame = petModel:GetPrimaryPartCFrame()
			local startTime = tick()
			local duration = 0.8

			-- Make parts transparent gradually
			for _, part in pairs(petModel:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end

			-- Move up and fade out
			while tick() - startTime < duration do
				if not petModel or not petModel.Parent then break end

				local alpha = (tick() - startTime) / duration
				local newPos = originalCFrame.Position + Vector3.new(0, alpha * 5, 0)
				petModel:SetPrimaryPartCFrame(CFrame.new(newPos))

				-- Fade out parts
				for _, part in pairs(petModel:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = math.min(0.9, part.Transparency + (alpha * 0.7))
					end
				end

				RunService.Heartbeat:Wait()
			end
		end)
	end

	-- Create particle effects
	local particleContainer = Instance.new("Folder")
	particleContainer.Name = "CollectionEffect"
	particleContainer.Parent = workspace.CurrentCamera

	-- Create a radial burst effect at pet position
	spawn(function()
		-- Create a radial burst of particles
		for i = 1, 12 do
			local angle = (i / 12) * math.pi * 2
			local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))

			local part = Instance.new("Part")
			part.Name = "BurstParticle"
			part.Size = Vector3.new(0.3, 0.3, 0.3)
			part.Shape = Enum.PartType.Ball
			part.Material = Enum.Material.Neon
			part.Color = particleColor
			part.CanCollide = false
			part.Anchored = true
			part.Position = petPosition
			part.Parent = particleContainer

			-- Create a trail for the burst
			local attachment1 = Instance.new("Attachment")
			attachment1.Position = Vector3.new(-0.15, 0, 0)
			attachment1.Parent = part

			local attachment2 = Instance.new("Attachment")
			attachment2.Position = Vector3.new(0.15, 0, 0)
			attachment2.Parent = part

			local trail = Instance.new("Trail")
			trail.Attachment0 = attachment1
			trail.Attachment1 = attachment2
			trail.Color = ColorSequence.new(particleColor)
			trail.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1)
			})
			trail.Lifetime = 0.2
			trail.Parent = part

			-- Animate it outwards
			spawn(function()
				local startTime = tick()
				local duration = 0.5

				while tick() - startTime < duration do
					local alpha = (tick() - startTime) / duration

					-- Move outward and upward
					part.Position = petPosition + (dir * alpha * 5) + Vector3.new(0, alpha * 4, 0)

					-- Fade out
					part.Transparency = alpha

					RunService.Heartbeat:Wait()
				end

				part:Destroy()
			end)
		end
	end)

	-- Create the main collection particles
	for i = 1, particleCount do
		spawn(function()
			-- Create a particle
			local particle = Instance.new("Part")
			particle.Size = Vector3.new(particleSize, particleSize, particleSize)
			particle.Shape = Enum.PartType.Ball
			particle.Material = Enum.Material.Neon
			particle.Color = particleColor
			particle.CanCollide = false
			particle.Anchored = true
			particle.Transparency = 0.1

			-- Add a light effect for higher rarity pets
			if rarity == "Epic" or rarity == "Legendary" then
				local light = Instance.new("PointLight")
				light.Color = particleColor
				light.Range = 2
				light.Brightness = 1
				light.Parent = particle
			end

			-- Add trail effect
			local attachment1 = Instance.new("Attachment")
			attachment1.Position = Vector3.new(-0.2, 0, 0)
			attachment1.Parent = particle

			local attachment2 = Instance.new("Attachment")
			attachment2.Position = Vector3.new(0.2, 0, 0)
			attachment2.Parent = particle

			local trail = Instance.new("Trail")
			trail.Attachment0 = attachment1
			trail.Attachment1 = attachment2
			trail.Lifetime = 0.2
			trail.MinLength = 0.05
			trail.MaxLength = 5
			trail.WidthScale = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0.1)
			})
			trail.Color = ColorSequence.new(particleColor)
			trail.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.3),
				NumberSequenceKeypoint.new(1, 1)
			})
			trail.Parent = particle

			-- Make particles more dramatic for higher rarities
			local effectDelay = i / particleCount * 0.3
			delay(effectDelay, function()
				particle.Parent = particleContainer

				-- Position at random spot around pet
				local offset = Vector3.new(
					math.random(-2, 2),
					math.random(-2, 2),
					math.random(-2, 2)
				)
				particle.Position = petPosition + offset

				-- Create a curved path to player with easing
				local startTime = tick()
				local journeyTime = 0.6 + math.random() * 0.4 -- 0.6-1 second duration

				-- Random bezier curve control point for more organic movement
				local controlPoint = petPosition + Vector3.new(
					math.random(-5, 5),
					math.random(2, 8),
					math.random(-5, 5)
				)

				-- Animate particle along path
				while tick() - startTime < journeyTime do
					-- Bezier curve formula: B(t) = (1-t)^2 * P0 + 2(1-t)t * P1 + t^2 * P2
					-- Where P0 is start, P1 is control point, P2 is end point
					local t = (tick() - startTime) / journeyTime

					-- Apply easing for more dynamic motion
					local easedT = -(math.cos(math.pi * t) - 1) / 2 -- Ease in-out sine

					local oneMinusT = 1 - easedT

					particle.Position = 
						(oneMinusT^2 * petPosition) + 
						(2 * oneMinusT * easedT * controlPoint) + 
						(easedT^2 * playerPosition)

					-- Shrink as it approaches player
					particle.Size = Vector3.new(particleSize, particleSize, particleSize) * (1 - easedT*0.7)

					-- Fade out near the end
					if easedT > 0.7 then
						particle.Transparency = 0.3 + (easedT - 0.7) * 3.33 -- Fade from 0.3 to 1 in last 30% of journey

						if particle:FindFirstChildOfClass("PointLight") then
							particle:FindFirstChildOfClass("PointLight").Brightness = 1 - ((easedT - 0.7) * 3.33)
						end
					end

					RunService.Heartbeat:Wait()
				end

				particle:Destroy()
			end)
		end)
	end


	-- Create a pulsing light effect at player
	if rarity == "Epic" or rarity == "Legendary" then
		local pulseLight = Instance.new("PointLight")
		pulseLight.Color = particleColor
		pulseLight.Range = 0
		pulseLight.Brightness = 1
		pulseLight.Parent = humanoidRootPart

		-- Animate the light
		spawn(function()
			local startTime = tick()
			local duration = 1

			while tick() - startTime < duration do
				local t = (tick() - startTime) / duration

				-- Expand and fade
				pulseLight.Range = t * 15
				pulseLight.Brightness = 1 - t

				RunService.Heartbeat:Wait()
			end

			pulseLight:Destroy()
		end)
	end

	-- Cleanup after effects are done
	delay(3, function()
		if particleContainer and particleContainer.Parent then
			particleContainer:Destroy()
		end
	end)
end

-- Initialize sounds when this module loads
EffectsModule.InitializeSounds()

return EffectsModule