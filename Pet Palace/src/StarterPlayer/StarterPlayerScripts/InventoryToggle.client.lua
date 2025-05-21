-- InventoryToggle.client.lua
-- Place this in StarterPlayer/StarterPlayerScripts
-- This script connects the TopBar button to your inventory GUI

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for both GUIs to load
local topBarGui = playerGui:WaitForChild("TopBarGui")
local inventoryGui = playerGui:WaitForChild("InventoryGui")

-- Get the toggle button from TopBar
local topBarFrame = topBarGui:WaitForChild("TopBar")
local toggleButton = topBarFrame:WaitForChild("InventoryButton") -- Make sure this exists in your TopBar

-- Get the inventory frame
local upgradesFrame = inventoryGui:WaitForChild("UpgradesFrame")

-- Track inventory state
local isInventoryOpen = false

-- Animation settings
local tweenInfo = TweenInfo.new(
	0.3,                -- Duration
	Enum.EasingStyle.Back, -- Easing style
	Enum.EasingDirection.Out -- Easing direction
)

-- Function to toggle inventory visibility with animation
local function toggleInventory()
	isInventoryOpen = not isInventoryOpen

	-- First make sure the GUI is visible
	inventoryGui.Enabled = true

	if isInventoryOpen then
		-- Opening animation
		upgradesFrame.Size = UDim2.new(0, 0, 0, 0)
		upgradesFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		upgradesFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		upgradesFrame.Visible = true

		-- Create and play tween
		local openTween = TweenService:Create(
			upgradesFrame,
			tweenInfo,
			{
				Size = UDim2.new(0.8, 0, 0.8, 0),
				Position = UDim2.new(0.5, 0, 0.5, 0)
			}
		)
		openTween:Play()

		-- Update button appearance
		toggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255) -- Highlighted color
	else
		-- Closing animation
		local closeTween = TweenService:Create(
			upgradesFrame,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{
				Size = UDim2.new(0, 0, 0, 0),
				Position = UDim2.new(0.5, 0, 0.5, 0)
			}
		)

		closeTween:Play()

		-- Hide the frame when tween completes
		closeTween.Completed:Connect(function()
			upgradesFrame.Visible = false
		end)

		-- Update button appearance
		toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215) -- Normal color
	end
end

-- Create the inventory button if it doesn't exist
if not toggleButton then
	print("Creating inventory button in TopBar")
	toggleButton = Instance.new("TextButton")
	toggleButton.Name = "InventoryButton"
	toggleButton.Size = UDim2.new(0, 40, 0, 40)
	toggleButton.Position = UDim2.new(1, -50, 0.5, -20)
	toggleButton.Text = "🎒" -- Backpack emoji
	toggleButton.TextSize = 24
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
	toggleButton.BorderSizePixel = 0
	toggleButton.Parent = topBarFrame

	-- Add rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.2, 0)
	corner.Parent = toggleButton
end

-- Connect the button click event
toggleButton.MouseButton1Click:Connect(toggleInventory)

-- Optional: Add keyboard shortcut (e.g., 'I' key for Inventory)
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.I then
		toggleInventory()
	end
end)

-- Make sure the inventory is initially hidden
upgradesFrame.Visible = false

print("Inventory toggle system initialized!")