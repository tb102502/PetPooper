-- DebugVisualizer script - Shows test elements in the inventory
local script = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.TopBar.InventoryFrame.DebugVisualizer
local frame = script.Parent

-- Wait for everything to load
wait(2)

-- Create a test element
local testFrame = Instance.new("Frame")
testFrame.Name = "DebugPet"
testFrame.Size = UDim2.new(0, 100, 0, 100)
testFrame.Position = UDim2.new(0, 50, 0, 50)
testFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Bright red
testFrame.BorderSizePixel = 2
testFrame.Parent = frame

-- Add a label
local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 0.5, 0)
label.Text = "Debug Pet"
label.BackgroundTransparency = 0.5
label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Parent = testFrame

print("Debug visualizer created test elements in inventory")

-- Also print info about the inventory frame
print("Inventory frame properties:")
print("- Name:", frame.Name)
print("- Size:", frame.Size)
print("- Position:", frame.Position)
print("- Visible:", frame.Visible)
print("- Parent:", frame.Parent.Name)
print("- BackgroundTransparency:", frame.BackgroundTransparency)

-- Check for PetTemplate
local template = frame:FindFirstChild("PetTemplate")
if template then
	print("PetTemplate found!")
	print("- Visible:", template.Visible)
	print("- Size:", template.Size)
else
	print("PetTemplate NOT found!")

	-- Create a test template
	local newTemplate = Instance.new("Frame")
	newTemplate.Name = "PetTemplate"
	newTemplate.Size = UDim2.new(0, 120, 0, 140)
	newTemplate.Position = UDim2.new(0, 200, 0, 50)
	newTemplate.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Green
	newTemplate.Visible = false
	newTemplate.Parent = frame

	-- Add required labels
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.3, 0)
	nameLabel.Text = "Name Label"
	nameLabel.Parent = newTemplate

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Size = UDim2.new(1, 0, 0.3, 0)
	rarityLabel.Position = UDim2.new(0, 0, 0.3, 0)
	rarityLabel.Text = "Rarity Label"
	rarityLabel.Parent = newTemplate

	local levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "LevelLabel"
	levelLabel.Size = UDim2.new(1, 0, 0.3, 0)
	levelLabel.Position = UDim2.new(0, 0, 0.6, 0)
	levelLabel.Text = "Level Label"
	levelLabel.Parent = newTemplate

	print("Created emergency PetTemplate")
end