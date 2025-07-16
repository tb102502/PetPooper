--[[
    ScytheToolScript.client.lua - Scythe Tool Client Script
    Place in: ServerStorage/ScytheToolScript
    
    This script handles scythe tool functionality on the client side.
    It will be cloned into scythe tools when players receive them.
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

-- Create swing animation if not exists
local function createSwingAnimation()
	if not swingAnimation then
		swingAnimation = Instance.new("Animation")
		swingAnimation.AnimationId = "rbxasset://animations/toolslash.rbx"
		swingAnimationTrack = humanoid:LoadAnimation(swingAnimation)
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

	-- Create visual effect
	local handle = tool:FindFirstChild("Handle")
	if handle then
		-- Create swing effect
		local effect = Instance.new("Part")
		effect.Name = "SwingEffect"
		effect.Size = Vector3.new(4, 0.1, 4)
		effect.Material = Enum.Material.Neon
		effect.BrickColor = BrickColor.new("Bright yellow")
		effect.Anchored = true
		effect.CanCollide = false
		effect.Transparency = 0.5
		effect.Parent = workspace

		-- Position effect in front of player
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			effect.CFrame = rootPart.CFrame * CFrame.new(0, 0, -3)
		end

		-- Animate effect
		local tween = TweenService:Create(effect,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Transparency = 1, Size = Vector3.new(6, 0.1, 6)}
		)
		tween:Play()

		tween.Completed:Connect(function()
			effect:Destroy()
		end)
	end

	-- Send swing to server
	if swingScythe then
		swingScythe:FireServer()
	end

	-- Reset swing state
	spawn(function()
		wait(0.3)
		isSwinging = false
	end)
end)

-- Handle tool equipped
tool.Equipped:Connect(function()
	-- Update character reference in case it changed
	character = player.Character
	if character then
		humanoid = character:WaitForChild("Humanoid")
		createSwingAnimation()
	end
end)

-- Handle tool unequipped
tool.Unequipped:Connect(function()
	if swingAnimationTrack then
		swingAnimationTrack:Stop()
	end
end)

-- Handle character respawn
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	swingAnimation = nil
	swingAnimationTrack = nil
end)