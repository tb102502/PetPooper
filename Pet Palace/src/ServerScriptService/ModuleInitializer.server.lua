-- ModuleInitializer.lua
-- Place in ServerScriptService
-- This script ensures all required templates are created and available

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

-- Function to safely create a folder if it doesn't exist
local function ensureFolder(parent, name)
	if not parent:FindFirstChild(name) then
		local folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
		print("Created folder: " .. name .. " in " .. parent.Name)
		return folder
	end
	return parent:FindFirstChild(name)
end

-- Create necessary folders
local Modules = ensureFolder(ReplicatedStorage, "Modules")
local PetTemplates = ensureFolder(ServerScriptService, "PetTemplates")

-- Create the Movement script template
if not PetTemplates:FindFirstChild("MovementScript") then
	-- Create the script first
	local movementScript = Instance.new("Script")
	movementScript.Name = "MovementScript"
	movementScript.Enabled = false -- Not enabled until cloned
	movementScript.Parent = PetTemplates

	-- Print instructions to manually add the code in Studio
	print("Created MovementScript template - please manually add the movement script code in Studio")
end

-- Create the Jump script template
if not PetTemplates:FindFirstChild("JumpScript") then
	-- Create the script first
	local jumpScript = Instance.new("Script")
	jumpScript.Name = "JumpScript"
	jumpScript.Enabled = false -- Not enabled until cloned
	jumpScript.Parent = PetTemplates

	-- Print instructions to manually add the code in Studio
	print("Created JumpScript template - please manually add the jump script code in Studio")
end

-- Create the PetInitializer script
if not ServerScriptService:FindFirstChild("PetInitializer") then
	local initScript = Instance.new("ModuleScript")
	initScript.Name = "PetInitializer"
	initScript.Parent = ServerScriptService

	-- Print instructions to manually add the code in Studio
	print("Created PetInitializer - please manually add the code in Studio")
end

print("Module Initialization complete!")