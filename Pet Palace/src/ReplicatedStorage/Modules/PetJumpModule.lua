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

	-- Store settings on the pet as attributes
	for key, value in pairs(settings) do
		pet:SetAttribute("jump_" .. key, value)
	end

	-- Reference to the template script
	local ServerScriptService = game:GetService("ServerScriptService")
	local templatesFolder = ServerScriptService:FindFirstChild("PetTemplates")
	if not templatesFolder then
		warn("PetTemplates folder not found!")
		return pet
	end

	-- Find the jump script template
	local jumpTemplate = templatesFolder:FindFirstChild("JumpScript")
	if not jumpTemplate then
		warn("JumpScript template not found!")
		return pet
	end

	-- Clone the template script and add to pet
	local newScript = jumpTemplate:Clone()
	newScript.Name = "PetJump"
	newScript.Enabled = true
	newScript.Parent = pet

	return pet
end
-- Paste the original JumpScript code here
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