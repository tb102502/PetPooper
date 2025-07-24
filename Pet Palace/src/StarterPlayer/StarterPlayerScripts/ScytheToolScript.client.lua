--[[
    ScytheToolScript.client.lua - Fixed Scythe Tool Client Script
    Place in: ServerStorage/ScytheToolScript.client.lua
    
    This script will be cloned into scythe tools when players receive them.
    
    FIXES:
    ✅ Proper wheat harvesting integration
    ✅ Better swing detection and cooldown
    ✅ Enhanced visual effects
    ✅ Proper tool reference handling
    ✅ Better error checking
]]

-- Wait for script to be properly parented to a tool
local tool = script.Parent
while not tool:IsA("Tool") do
	tool = tool.Parent
	if not tool or tool == game then
		error("ScytheToolScript must be inside a Tool!")
	end
end
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local isSwinging = false
local swingCooldown = 0.5
local lastSwingTime = 0

-- Get remote events
local gameRemotes = ReplicatedStorage:WaitForChild("GameRemotes", 30)
local swingScythe = nil

-- Wait for SwingScythe remote event
spawn(function()
	swingScythe = gameRemotes:WaitForChild("SwingScythe", 10)
	if swingScythe then
		print("ScytheTool: Connected to SwingScythe remote event")
	else
		warn("ScytheTool: Failed to find SwingScythe remote event")
	end
end)

-- Animation
local swingAnimation = nil
local swingAnimationTrack = nil

-- Character references
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")

-- Create swing animation
local function createSwingAnimation()
	if not swingAnimation then
		swingAnimation = Instance.new("Animation")
		-- Use a farming/tool swing animation
		swingAnimation.AnimationId = "rbxasset://animations/toolslash.anim"
		swingAnimationTrack = animator:LoadAnimation(swingAnimation)
		swingAnimationTrack.Priority = Enum.AnimationPriority.Action
	end
end

-- Create enhanced swing effect for wheat harvesting
local function createWheatHarvestingEffect()
	local handle = tool:FindFirstChild("Handle")
	if not handle then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Create scythe swing arc effect
	local swingArc = Instance.new("Part")
	swingArc.Name = "ScytheSwingArc"
	swingArc.Size = Vector3.new(8, 0.2, 8)
	swingArc.Material = Enum.Material.Neon
	swingArc.BrickColor = BrickColor.new("Bright yellow")
	swingArc.Anchored = true
	swingArc.CanCollide = false
	swingArc.Transparency = 0.5
	swingArc.Parent = workspace

	-- Position arc in front of player
	swingArc.CFrame = rootPart.CFrame * CFrame.new(0, 0, -4) * CFrame.Angles(math.rad(90), 0, 0)

	-- Create wheat debris particles
	for i = 1, 6 do
		local debris = Instance.new("Part")
		debris.Name = "WheatDebris"
		debris.Size = Vector3.new(0.15, 0.15, 0.15)
		debris.Material = Enum.Material.Neon
		debris.BrickColor = BrickColor.new("Bright yellow")
		debris.Anchored = false
		debris.CanCollide = false
		debris.Parent = workspace

		-- Position around swing area
		debris.Position = swingArc.Position + Vector3.new(
			math.random(-4, 4),
			math.random(-1, 2),
			math.random(-4, 4)
		)

		-- Add realistic physics
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(2000, 2000, 2000)
		bodyVelocity.Velocity = Vector3.new(
			math.random(-12, 12),
			math.random(8, 18),
			math.random(-12, 12)
		)
		bodyVelocity.Parent = debris

		-- Add slight rotation
		local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
		bodyAngularVelocity.AngularVelocity = Vector3.new(
			math.random(-10, 10),
			math.random(-10, 10),
			math.random(-10, 10)
		)
		bodyAngularVelocity.MaxTorque = Vector3.new(500, 500, 500)
		bodyAngularVelocity.Parent = debris

		-- Clean up after 3 seconds
		game:GetService("Debris"):AddItem(debris, 3)
	end

	-- Animate swing arc
	local tween = TweenService:Create(swingArc,
		TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Transparency = 1,
			Size = Vector3.new(12, 0.2, 12)
		}
	)
	tween:Play()

	tween.Completed:Connect(function()
		swingArc:Destroy()
	end)

	-- Create blade trail effect
	local blade = tool:FindFirstChild("Blade")
	if blade then
		local trail = Instance.new("Part")
		trail.Name = "BladeTrail"
		trail.Size = Vector3.new(0.1, 3, 0.1)
		trail.Material = Enum.Material.Neon
		trail.BrickColor = BrickColor.new("Institutional white")
		trail.Anchored = true
		trail.CanCollide = false
		trail.Transparency = 0.3
		trail.Parent = workspace

		trail.CFrame = blade.CFrame

		local trailTween = TweenService:Create(trail,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Transparency = 1,
				Size = Vector3.new(0.2, 4, 0.2)
			}
		)
		trailTween:Play()

		trailTween.Completed:Connect(function()
			trail:Destroy()
		end)
	end
end

-- Create swing sound effect
local function createSwingSound()
	local swingSound = Instance.new("Sound")
	swingSound.Name = "ScytheSwingSound"
	swingSound.SoundId = "rbxasset://sounds/impact_water.mp3"
	swingSound.Volume = 0.5
	--swingSound.Pitch = 1.2
	swingSound.Parent = tool:FindFirstChild("Handle") or tool

	swingSound:Play()

	-- Clean up sound after playing
	swingSound.Ended:Connect(function()
		swingSound:Destroy()
	end)
end

-- Handle tool activation (clicking)
tool.Activated:Connect(function()
	local currentTime = tick()

	-- Check if we can swing (cooldown)
	if isSwinging or (currentTime - lastSwingTime) < swingCooldown then
		return
	end

	-- Check if we're in a wheat harvesting session
	local isInWheatField = false
	if _G.WheatHarvestingGUI and _G.WheatHarvestingGUI.State then
		isInWheatField = _G.WheatHarvestingGUI.State.guiType == "harvesting"
	end

	isSwinging = true
	lastSwingTime = currentTime

	print("ScytheTool: Scythe swing activated by " .. player.Name)

	-- Play swing animation
	createSwingAnimation()
	if swingAnimationTrack then
		swingAnimationTrack:Play()
	end

	-- Create visual and sound effects
	createWheatHarvestingEffect()
	createSwingSound()

	-- Send swing to server (this will handle wheat harvesting)
	if swingScythe then
		swingScythe:FireServer()
	else
		warn("ScytheTool: SwingScythe remote event not available")
	end

	-- Reset swing state after cooldown
	spawn(function()
		wait(swingCooldown)
		isSwinging = false
	end)
end)

-- Handle tool equipped
tool.Equipped:Connect(function()
	print("ScytheTool: Scythe equipped by " .. player.Name)

	-- Update character references
	character = player.Character
	if character then
		humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			animator = humanoid:FindFirstChild("Animator")
			createSwingAnimation()
		end
	end

	-- Create equip effect
	local handle = tool:FindFirstChild("Handle")
	if handle then
		local equipEffect = Instance.new("Part")
		equipEffect.Name = "EquipEffect"
		equipEffect.Size = Vector3.new(1, 1, 1)
		equipEffect.Material = Enum.Material.Neon
		equipEffect.BrickColor = BrickColor.new("Bright yellow")
		equipEffect.Anchored = true
		equipEffect.CanCollide = false
		equipEffect.Transparency = 0.5
		equipEffect.Parent = workspace

		equipEffect.CFrame = handle.CFrame

		-- Animate equip effect
		local equipTween = TweenService:Create(equipEffect,
			TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Transparency = 1,
				Size = Vector3.new(4, 4, 4)
			}
		)
		equipTween:Play()

		equipTween.Completed:Connect(function()
			equipEffect:Destroy()
		end)

		-- Play equip sound
		local equipSound = Instance.new("Sound")
		equipSound.SoundId = "rbxasset://sounds/metal_impact.ogg"
		equipSound.Volume = 0.3
		equipSound.Parent = handle
		equipSound:Play()

		equipSound.Ended:Connect(function()
			equipSound:Destroy()
		end)
	end

	-- Show usage hint
	if _G.UIManager and _G.UIManager.ShowNotification then
		_G.UIManager:ShowNotification("🌾 Scythe Equipped", 
			"Approach the wheat field and click to harvest wheat!", "info")
	end
end)

-- Handle tool unequipped
tool.Unequipped:Connect(function()
	print("ScytheTool: Scythe unequipped by " .. player.Name)

	-- Stop any playing animation
	if swingAnimationTrack then
		swingAnimationTrack:Stop()
	end

	-- Reset swing state
	isSwinging = false
end)

-- Handle character respawn
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	animator = humanoid:WaitForChild("Animator")

	-- Reset animation references
	swingAnimation = nil
	swingAnimationTrack = nil
	isSwinging = false

	print("ScytheTool: Character respawned, references updated")
end)

-- Enhanced input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- Check if tool is equipped
	if tool.Parent ~= character then return end

	-- Handle alternative activation keys
	if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.E then
		-- Activate the tool
		tool:Activate()
	end
end)

-- Handle mobile/touch input
UserInputService.TouchTapInWorld:Connect(function(position, processedByUI)
	if processedByUI then return end

	-- Check if tool is equipped
	if tool.Parent ~= character then return end

	-- Activate tool on screen tap
	tool:Activate()
end)

print("ScytheTool: ✅ Scythe tool script loaded and ready for " .. player.Name)