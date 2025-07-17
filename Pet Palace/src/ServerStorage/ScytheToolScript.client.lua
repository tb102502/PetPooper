--[[
    ScytheToolScript.client.lua - Improved Scythe Tool Client Script
    Place in: ServerStorage/ScytheToolScript
    
    This script handles scythe tool functionality on the client side.
    It will be cloned into scythe tools when players receive them.
    
    IMPROVEMENTS:
    ✅ Better tool positioning and grip
    ✅ Improved swing animations
    ✅ Enhanced visual effects
    ✅ Better cooldown handling
]]

local tool = script.Parent
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local isSwinging = false
local swingCooldown = 0.5
local lastSwingTime = 0

-- Get remote events
local gameRemotes = ReplicatedStorage:WaitForChild("GameRemotes", 30)
local swingScythe = gameRemotes:WaitForChild("SwingScythe", 10)

-- Animation
local swingAnimation = nil
local swingAnimationTrack = nil

-- Wait for character
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")
-- Create swing animation if not exists
local function createSwingAnimation()
	if not swingAnimation then
		swingAnimation = Instance.new("Animation")
		-- Use a different animation that looks more like scythe swinging
		swingAnimation.AnimationId = "http://www.roblox.com/asset/?id=522635514"
		swingAnimationTrack = animator:LoadAnimation(swingAnimation)
		swingAnimationTrack.Priority = Enum.AnimationPriority.Action
	end
end

-- Create enhanced swing effect
local function createEnhancedSwingEffect()
	local handle = tool:FindFirstChild("Handle")
	if not handle then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Create multiple effect parts for a more dramatic swing
	local effects = {}

	-- Main swing trail
	local mainEffect = Instance.new("Part")
	mainEffect.Name = "MainSwingEffect"
	mainEffect.Size = Vector3.new(6, 0.1, 6)
	mainEffect.Material = Enum.Material.Neon
	mainEffect.BrickColor = BrickColor.new("Bright yellow")
	mainEffect.Anchored = true
	mainEffect.CanCollide = false
	mainEffect.Transparency = 0.3
	mainEffect.Parent = workspace

	-- Position effect in front of player at scythe level
	mainEffect.CFrame = rootPart.CFrame * CFrame.new(0, 0, -4) * CFrame.Angles(math.rad(90), 0, 0)

	-- Wheat particles
	for i = 1, 8 do
		local particle = Instance.new("Part")
		particle.Name = "WheatParticle"
		particle.Size = Vector3.new(0.1, 0.1, 0.1)
		particle.Material = Enum.Material.Neon
		particle.BrickColor = BrickColor.new("Bright yellow")
		particle.Anchored = false
		particle.CanCollide = false
		particle.Parent = workspace

		-- Position around the swing area
		particle.Position = mainEffect.Position + Vector3.new(
			math.random(-3, 3),
			math.random(-1, 1),
			math.random(-3, 3)
		)

		-- Add velocity
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
		bodyVelocity.Velocity = Vector3.new(
			math.random(-15, 15),
			math.random(5, 20),
			math.random(-15, 15)
		)
		bodyVelocity.Parent = particle

		table.insert(effects, particle)

		-- Clean up particle after 2 seconds
		game:GetService("Debris"):AddItem(particle, 2)
	end

	-- Animate main effect
	local tween = TweenService:Create(mainEffect,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Transparency = 1, 
			Size = Vector3.new(8, 0.1, 8),
			CFrame = mainEffect.CFrame * CFrame.new(0, 0, -2)
		}
	)
	tween:Play()

	tween.Completed:Connect(function()
		mainEffect:Destroy()
	end)

	-- Create blade trail effect
	local blade = tool:FindFirstChild("Blade")
	if blade then
		local bladeTrail = Instance.new("Part")
		bladeTrail.Name = "BladeTrail"
		bladeTrail.Size = Vector3.new(0.1, 3, 0.1)
		bladeTrail.Material = Enum.Material.Neon
		bladeTrail.BrickColor = BrickColor.new("Institutional white")
		bladeTrail.Anchored = true
		bladeTrail.CanCollide = false
		bladeTrail.Transparency = 0.5
		bladeTrail.Parent = workspace

		-- Position trail where blade would be
		bladeTrail.CFrame = blade.CFrame

		-- Animate trail
		local trailTween = TweenService:Create(bladeTrail,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Transparency = 1,
				Size = Vector3.new(0.2, 4, 0.2)
			}
		)
		trailTween:Play()

		trailTween.Completed:Connect(function()
			bladeTrail:Destroy()
		end)
	end
end

-- Handle tool activation
tool.Activated:Connect(function()
	local currentTime = tick()
	if isSwinging or (currentTime - lastSwingTime) < swingCooldown then
		return
	end

	isSwinging = true
	lastSwingTime = currentTime

	-- Play swing animation
	createSwingAnimation()
	if swingAnimationTrack then
		swingAnimationTrack:Play()
	end

	-- Create enhanced visual effect
	createEnhancedSwingEffect()

	-- Send swing to server
	if swingScythe then
		swingScythe:FireServer()
	end

	-- Reset swing state
	spawn(function()
		wait(0.4)  -- Slightly longer for more realistic swing
		isSwinging = false
	end)
end)

-- Handle tool equipped
tool.Equipped:Connect(function()
	print("Scythe equipped by " .. player.Name)

	-- Update character reference in case it changed
	character = player.Character
	if character then
		humanoid = character:WaitForChild("Humanoid")
		createSwingAnimation()
	end

	-- Add equipped effect
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
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Transparency = 1,
				Size = Vector3.new(3, 3, 3)
			}
		)
		equipTween:Play()

		equipTween.Completed:Connect(function()
			equipEffect:Destroy()
		end)
	end
end)

-- Handle tool unequipped
tool.Unequipped:Connect(function()
	print("Scythe unequipped by " .. player.Name)

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
	swingAnimation = nil
	swingAnimationTrack = nil
	isSwinging = false
end)

-- Additional input handling for better responsiveness
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- Check if tool is equipped
	if tool.Parent ~= character then return end

	-- Handle space bar as alternative activation
	if input.KeyCode == Enum.KeyCode.Space then
		tool:Activate()
	end
end)