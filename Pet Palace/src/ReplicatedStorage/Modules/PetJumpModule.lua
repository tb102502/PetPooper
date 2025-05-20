-- PetJumpModule.lua
-- Place this in ReplicatedStorage/Modules/
-- Centralized module for pet jumping behaviors

local PetJumpModule = {}

-- Default jump settings
PetJumpModule.DefaultSettings = {
	minWaitTime = 5,
	maxWaitTime = 10,
	jumpHeight = 2
}

-- Function to initialize jumping for a pet
function PetJumpModule.initJumping(pet, settings)
	if not pet then return pet end

	-- Merge settings with defaults
	settings = settings or {}
	for key, defaultValue in pairs(PetJumpModule.DefaultSettings) do
		if settings[key] == nil then
			settings[key] = defaultValue
		end
	end

	-- Store settings on the pet
	for key, value in pairs(settings) do
		pet:SetAttribute("jump_" .. key, value)
	end

	-- Create a script that handles the pet's jumping
	local jumpScript = Instance.new("Script")
	jumpScript.Name = "PetJump"

	-- Paste the original JumpScript code here
	jumpScript.Source = [[
-- SimplifiedJumpScript.lua
-- This script only applies vertical movement for jumping
-- and lets the existing Movement script handle all animations

local pet = script.Parent
local jumpWaitTime = math.random(pet:GetAttribute("jump_minWaitTime") or 5, 
                                 pet:GetAttribute("jump_maxWaitTime") or 10)
local jumpHeight = pet:GetAttribute("jump_jumpHeight") or 2

-- Function to safely get a reference part for applying jumps
local function getJumpReference()
	if pet.PrimaryPart then
		return pet.PrimaryPart
	end

	if pet:FindFirstChild("HumanoidRootPart") then
		return pet.HumanoidRootPart
	end

	if pet:FindFirstChild("Torso") then
		return pet.Torso
	end

	-- Last resort, find any BasePart
	for _, part in pairs(pet:GetChildren()) do
		if part:IsA("BasePart") then
			return part
		end
	end

	return nil
end

-- Main jump loop
while wait(jumpWaitTime) do
	-- Reset wait time for next jump
	jumpWaitTime = math.random(pet:GetAttribute("jump_minWaitTime") or 5, 
                              pet:GetAttribute("jump_maxWaitTime") or 10)

	-- Simple flag to indicate to any other scripts that the pet is jumping
	-- Movement scripts can check this attribute if they need to coordinate
	pet:SetAttribute("IsJumping", true)

	-- Get reference part
	local referencePart = getJumpReference()
	if not referencePart then 
		pet:SetAttribute("IsJumping", false)
		continue 
	end

	-- Store original position
	local originalY = referencePart.Position.Y

	-- Apply vertical impulse force (no animation, just physics)
	if referencePart:IsA("BasePart") and not referencePart.Anchored then
		-- If parts are unanchored, use physics (velocity)
		referencePart.Velocity = Vector3.new(
			referencePart.Velocity.X,
			jumpHeight * 10, -- Convert height to appropriate velocity
			referencePart.Velocity.Z
		)
	else
		-- If parts are anchored, we need to directly modify position
		-- Let's just add a simple upward offset - no animation
		if pet.PrimaryPart then
			local currentCFrame = pet:GetPrimaryPartCFrame()
			pet:SetPrimaryPartCFrame(currentCFrame + Vector3.new(0, jumpHeight, 0))

			-- Wait a brief moment
			wait(0.2)

			-- Return to original height
			pet:SetPrimaryPartCFrame(CFrame.new(
				currentCFrame.X, 
				originalY, 
				currentCFrame.Z
				) * currentCFrame.Rotation)
		else
			-- Just move the reference part
			local originalPosition = referencePart.Position
			referencePart.Position = Vector3.new(
				originalPosition.X,
				originalPosition.Y + jumpHeight,
				originalPosition.Z
			)

			-- Wait a brief moment
			wait(0.2)

			-- Return to original height
			referencePart.Position = Vector3.new(
				originalPosition.X,
				originalY,
				originalPosition.Z
			)
		end
	end

	-- Clear jumping flag
	wait(0.3)
	pet:SetAttribute("IsJumping", false)
end
]]

	jumpScript.Parent = pet

	-- Return the pet for chaining
	return pet
end

-- Function to adjust jump settings for a pet
function PetJumpModule.adjustJumpSettings(pet, newSettings)
	if not pet then return pet end

	-- Update jump settings attributes
	for key, value in pairs(newSettings) do
		pet:SetAttribute("jump_" .. key, value)
	end

	-- Find and restart the jump script
	local jumpScript = pet:FindFirstChild("PetJump")
	if jumpScript then
		jumpScript.Disabled = true
		wait(0.1)
		jumpScript.Disabled = false
	end

	return pet
end

-- Other utility functions can be added here

return PetJumpModule