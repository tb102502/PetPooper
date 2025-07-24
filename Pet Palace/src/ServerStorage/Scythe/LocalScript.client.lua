--[[
    Enhanced Scythe Tool LocalScript with Custom Animation
    Place inside: ServerStorage/Scythe/[LocalScript]
    
    FEATURES:
    ✅ Custom scythe swing animations (3 variations)
    ✅ Fallback to Roblox animations
    ✅ Wheat harvesting integration
    ✅ Enhanced visual effects
    ✅ Sound effects
    ✅ Multiple input methods
]]

local tool = script.Parent
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Ensure we have a valid tool reference
if not tool:IsA("Tool") then
	error("ScytheScript must be inside a Tool!")
end

local player = Players.LocalPlayer
local isSwinging = false
local swingCooldown = 0.5
local lastSwingTime = 0

-- Wait for remote events
local gameRemotes = ReplicatedStorage:WaitForChild("GameRemotes", 30)
local swingScythe = nil

spawn(function()
	swingScythe = gameRemotes:WaitForChild("SwingScythe", 10)
	if swingScythe then
		print("ScytheTool: Connected to SwingScythe remote")
	end
end)

-- Character references
local character = nil
local humanoid = nil
local animator = nil

-- ========== ANIMATION SYSTEM ==========

local ScytheAnimation = {}

-- Animation configuration
local SWING_CONFIG = {
	DURATION = 0.6,
	EASING_STYLE = Enum.EasingStyle.Quad,
	EASING_DIRECTION = Enum.EasingDirection.Out,
	SWING_VARIATIONS = 3
}

-- Pre-made Roblox animation IDs for scythe-like movements
local ROBLOX_ANIMATIONS = {
	"http://www.roblox.com/asset/?id=522635514" -- Sword slash (works well for scythe)

}

ScytheAnimation.isAnimating = false
ScytheAnimation.swingCount = 0

-- ========== ROBLOX ANIMATION SYSTEM ==========

function ScytheAnimation:PlayRobloxAnimation()
	if not animator then return false end

	-- Select a random animation from our list
	local animationId = ROBLOX_ANIMATIONS[math.random(1, #ROBLOX_ANIMATIONS)]

	-- Create and load animation
	local animation = Instance.new("Animation")
	animation.AnimationId = animationId

	local animationTrack = animator:LoadAnimation(animation)
	animationTrack.Priority = Enum.AnimationPriority.Action
	animationTrack:Play()

	print("ScytheAnimation: Playing Roblox animation: " .. animationId)

	-- Clean up after animation
	animationTrack.Ended:Connect(function()
		animation:Destroy()
		self.isAnimating = false
	end)

	-- Safety cleanup after max duration
	spawn(function()
		wait(2)
		if animation.Parent then
			animation:Destroy()
		end
		self.isAnimating = false
	end)

	return true
end

-- ========== PROCEDURAL ANIMATION SYSTEM ==========

function ScytheAnimation:PlayProceduralSwing()
	if self.isAnimating then return false end
	if not character then return false end

	self.isAnimating = true
	self.swingCount = (self.swingCount + 1) % SWING_CONFIG.SWING_VARIATIONS

	print("ScytheAnimation: Playing procedural swing variation " .. (self.swingCount + 1))

	-- Get character parts (support both R15 and R6)
	local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
	local rightArm = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightUpperArm")
	local leftArm = character:FindFirstChild("Left Arm") or character:FindFirstChild("LeftUpperArm")
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	if not torso or not rightArm or not leftArm or not rootPart then
		print("ScytheAnimation: Missing character parts, falling back to Roblox animation")
		self.isAnimating = false
		return self:PlayRobloxAnimation()
	end

	-- Get joints (different names for R6 vs R15)
	local rightShoulder = torso:FindFirstChild("Right Shoulder") or torso:FindFirstChild("RightShoulder")
	local leftShoulder = torso:FindFirstChild("Left Shoulder") or torso:FindFirstChild("LeftShoulder")

	if not rightShoulder or not leftShoulder then
		print("ScytheAnimation: Missing shoulder joints, falling back to Roblox animation")
		self.isAnimating = false
		return self:PlayRobloxAnimation()
	end

	-- Store original positions
	local originalRightC0 = rightShoulder.C0
	local originalLeftC0 = leftShoulder.C0
	local originalRootC0 = rootPart.CFrame

	-- Choose swing variation
	if self.swingCount == 0 then
		self:PlayHorizontalSwing(rightShoulder, leftShoulder, rootPart, originalRightC0, originalLeftC0, originalRootC0)
	elseif self.swingCount == 1 then
		self:PlayOverheadSwing(rightShoulder, leftShoulder, rootPart, originalRightC0, originalLeftC0, originalRootC0)
	else
		self:PlayDiagonalSwing(rightShoulder, leftShoulder, rootPart, originalRightC0, originalLeftC0, originalRootC0)
	end

	return true
end

function ScytheAnimation:PlayHorizontalSwing(rightShoulder, leftShoulder, rootPart, origRightC0, origLeftC0, origRootC0)
	-- Horizontal scythe swing (side to side)
	local swingRightC0 = origRightC0 * CFrame.Angles(math.rad(-20), math.rad(-45), math.rad(-90))
	local swingLeftC0 = origLeftC0 * CFrame.Angles(math.rad(-10), math.rad(20), math.rad(45))
	local swingRootCFrame = origRootC0 * CFrame.Angles(0, math.rad(-30), 0)

	-- Create swing tweens
	local rightArmTween = TweenService:Create(rightShoulder, 
		TweenInfo.new(SWING_CONFIG.DURATION * 0.7, SWING_CONFIG.EASING_STYLE, SWING_CONFIG.EASING_DIRECTION),
		{C0 = swingRightC0}
	)

	local leftArmTween = TweenService:Create(leftShoulder,
		TweenInfo.new(SWING_CONFIG.DURATION * 0.7, SWING_CONFIG.EASING_STYLE, SWING_CONFIG.EASING_DIRECTION),
		{C0 = swingLeftC0}
	)

	local bodyTween = TweenService:Create(rootPart,
		TweenInfo.new(SWING_CONFIG.DURATION * 0.5, SWING_CONFIG.EASING_STYLE, SWING_CONFIG.EASING_DIRECTION),
		{CFrame = swingRootCFrame}
	)

	-- Play swing
	rightArmTween:Play()
	leftArmTween:Play()
	bodyTween:Play()

	-- Return to original position
	rightArmTween.Completed:Connect(function()
		local returnTween = TweenService:Create(rightShoulder,
			TweenInfo.new(SWING_CONFIG.DURATION * 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{C0 = origRightC0}
		)
		returnTween:Play()

		local returnLeftTween = TweenService:Create(leftShoulder,
			TweenInfo.new(SWING_CONFIG.DURATION * 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{C0 = origLeftC0}
		)
		returnLeftTween:Play()

		local returnBodyTween = TweenService:Create(rootPart,
			TweenInfo.new(SWING_CONFIG.DURATION * 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{CFrame = origRootC0}
		)
		returnBodyTween:Play()

		returnTween.Completed:Connect(function()
			self.isAnimating = false
		end)
	end)
end

function ScytheAnimation:PlayOverheadSwing(rightShoulder, leftShoulder, rootPart, origRightC0, origLeftC0, origRootC0)
	-- Overhead swing (up then down)
	local liftRightC0 = origRightC0 * CFrame.Angles(math.rad(-120), math.rad(30), math.rad(-30))
	local liftLeftC0 = origLeftC0 * CFrame.Angles(math.rad(-100), math.rad(-20), math.rad(30))

	local swingRightC0 = origRightC0 * CFrame.Angles(math.rad(30), math.rad(0), math.rad(-20))
	local swingLeftC0 = origLeftC0 * CFrame.Angles(math.rad(20), math.rad(0), math.rad(20))

	-- Phase 1: Lift up
	local liftRightTween = TweenService:Create(rightShoulder,
		TweenInfo.new(SWING_CONFIG.DURATION * 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{C0 = liftRightC0}
	)

	local liftLeftTween = TweenService:Create(leftShoulder,
		TweenInfo.new(SWING_CONFIG.DURATION * 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{C0 = liftLeftC0}
	)

	liftRightTween:Play()
	liftLeftTween:Play()

	-- Phase 2: Swing down
	liftRightTween.Completed:Connect(function()
		local swingRightTween = TweenService:Create(rightShoulder,
			TweenInfo.new(SWING_CONFIG.DURATION * 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{C0 = swingRightC0}
		)

		local swingLeftTween = TweenService:Create(leftShoulder,
			TweenInfo.new(SWING_CONFIG.DURATION * 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{C0 = swingLeftC0}
		)

		swingRightTween:Play()
		swingLeftTween:Play()

		-- Phase 3: Return to original
		swingRightTween.Completed:Connect(function()
			local returnRightTween = TweenService:Create(rightShoulder,
				TweenInfo.new(SWING_CONFIG.DURATION * 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{C0 = origRightC0}
			)

			local returnLeftTween = TweenService:Create(leftShoulder,
				TweenInfo.new(SWING_CONFIG.DURATION * 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{C0 = origLeftC0}
			)

			returnRightTween:Play()
			returnLeftTween:Play()

			returnRightTween.Completed:Connect(function()
				self.isAnimating = false
			end)
		end)
	end)
end

function ScytheAnimation:PlayDiagonalSwing(rightShoulder, leftShoulder, rootPart, origRightC0, origLeftC0, origRootC0)
	-- Diagonal swing (top-right to bottom-left)
	local startRightC0 = origRightC0 * CFrame.Angles(math.rad(-80), math.rad(-20), math.rad(-45))
	local startLeftC0 = origLeftC0 * CFrame.Angles(math.rad(-60), math.rad(10), math.rad(25))

	local endRightC0 = origRightC0 * CFrame.Angles(math.rad(20), math.rad(40), math.rad(-10))
	local endLeftC0 = origLeftC0 * CFrame.Angles(math.rad(10), math.rad(-10), math.rad(40))

	local swingRootCFrame = origRootC0 * CFrame.Angles(0, math.rad(20), math.rad(-10))

	-- Phase 1: Move to start position
	local startRightTween = TweenService:Create(rightShoulder,
		TweenInfo.new(SWING_CONFIG.DURATION * 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{C0 = startRightC0}
	)

	local startLeftTween = TweenService:Create(leftShoulder,
		TweenInfo.new(SWING_CONFIG.DURATION * 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{C0 = startLeftC0}
	)

	startRightTween:Play()
	startLeftTween:Play()

	-- Phase 2: Diagonal swing
	startRightTween.Completed:Connect(function()
		local swingRightTween = TweenService:Create(rightShoulder,
			TweenInfo.new(SWING_CONFIG.DURATION * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
			{C0 = endRightC0}
		)

		local swingLeftTween = TweenService:Create(leftShoulder,
			TweenInfo.new(SWING_CONFIG.DURATION * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
			{C0 = endLeftC0}
		)

		local bodyTween = TweenService:Create(rootPart,
			TweenInfo.new(SWING_CONFIG.DURATION * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
			{CFrame = swingRootCFrame}
		)

		swingRightTween:Play()
		swingLeftTween:Play()
		bodyTween:Play()

		-- Phase 3: Return to original
		swingRightTween.Completed:Connect(function()
			local returnRightTween = TweenService:Create(rightShoulder,
				TweenInfo.new(SWING_CONFIG.DURATION * 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{C0 = origRightC0}
			)

			local returnLeftTween = TweenService:Create(leftShoulder,
				TweenInfo.new(SWING_CONFIG.DURATION * 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{C0 = origLeftC0}
			)

			local returnBodyTween = TweenService:Create(rootPart,
				TweenInfo.new(SWING_CONFIG.DURATION * 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{CFrame = origRootC0}
			)

			returnRightTween:Play()
			returnLeftTween:Play()
			returnBodyTween:Play()

			returnRightTween.Completed:Connect(function()
				self.isAnimating = false
			end)
		end)
	end)
end

function ScytheAnimation:PlaySwingAnimation()
	if self.isAnimating then 
		return false 
	end

	-- Try procedural animation first, fallback to Roblox animations
	local success = self:PlayProceduralSwing()

	if not success then
		print("ScytheAnimation: Procedural animation failed, using Roblox animation")
		return self:PlayRobloxAnimation()
	end

	return true
end

-- ========== CHARACTER REFERENCE MANAGEMENT ==========

local function updateCharacterReferences()
	character = player.Character
	if character then
		humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			animator = humanoid:FindFirstChild("Animator")
		end
	end
end

-- ========== VISUAL EFFECTS ==========

local function createWheatHarvestingEffect()
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	local rootPart = character.HumanoidRootPart

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

		-- Add physics
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(2000, 2000, 2000)
		bodyVelocity.Velocity = Vector3.new(
			math.random(-12, 12),
			math.random(8, 18),
			math.random(-12, 12)
		)
		bodyVelocity.Parent = debris

		-- Clean up
		game:GetService("Debris"):AddItem(debris, 3)
	end

	-- Animate swing arc
	local tween = TweenService:Create(swingArc,
		TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Transparency = 1, Size = Vector3.new(12, 0.2, 12)}
	)
	tween:Play()

	tween.Completed:Connect(function()
		swingArc:Destroy()
	end)
end

-- ========== SOUND EFFECTS ==========

local function createSwingSound()
	local handle = tool:FindFirstChild("Handle")
	if not handle then return end

	local swingSound = Instance.new("Sound")
	swingSound.Name = "ScytheSwingSound"
	swingSound.SoundId = "rbxasset://sounds/impact_water.mp3"
	swingSound.Volume = 0.5
	--swingSound.Pitch = 1.2
	swingSound.Parent = handle

	swingSound:Play()

	swingSound.Ended:Connect(function()
		swingSound:Destroy()
	end)
end

-- ========== TOOL EVENT HANDLERS ==========

-- Tool activation handler (when player clicks)
tool.Activated:Connect(function()
	local currentTime = tick()

	-- Check cooldown
	if isSwinging or (currentTime - lastSwingTime) < swingCooldown then
		return
	end

	isSwinging = true
	lastSwingTime = currentTime

	print("ScytheTool: Scythe activated by " .. player.Name)

	-- Play swing animation
	ScytheAnimation:PlaySwingAnimation()

	-- Create visual and sound effects
	createWheatHarvestingEffect()
	createSwingSound()

	-- Send swing to server for wheat harvesting
	if swingScythe then
		swingScythe:FireServer()
	else
		warn("ScytheTool: SwingScythe remote not available")
	end

	-- Reset swing state
	spawn(function()
		wait(swingCooldown)
		isSwinging = false
	end)
end)

-- Tool equipped handler
tool.Equipped:Connect(function()
	print("ScytheTool: Scythe equipped by " .. player.Name)
	updateCharacterReferences()

	-- Reset animation state
	ScytheAnimation.isAnimating = false

	-- Show notification
	if _G.UIManager and _G.UIManager.ShowNotification then
		_G.UIManager:ShowNotification("🌾 Scythe Ready", 
			"Approach the wheat field and click to harvest!", "info")
	end
end)

-- Tool unequipped handler
tool.Unequipped:Connect(function()
	print("ScytheTool: Scythe unequipped by " .. player.Name)
	isSwinging = false
	ScytheAnimation.isAnimating = false
end)

-- Handle character respawn
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = nil
	animator = nil
	isSwinging = false
	ScytheAnimation.isAnimating = false

	-- Update references after character loads
	spawn(function()
		wait(1)
		updateCharacterReferences()
	end)
end)

-- ========== ENHANCED INPUT HANDLING ==========

-- Enhanced input handling (Space bar, E key, mobile touch)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- Check if tool is equipped
	if tool.Parent ~= character then return end

	-- Handle alternative activation keys
	if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.E then
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

print("ScytheTool: ✅ Enhanced scythe script with custom animations loaded")
print("ScytheTool: Animation variations: Horizontal, Overhead, Diagonal")
print("ScytheTool: Fallback animations: " .. #ROBLOX_ANIMATIONS .. " Roblox animations available")