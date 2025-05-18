-- SimpleShopUI.client.lua (LocalScript)
-- Simplified shop UI that replaces the complex ShopGUI.client.lua
-- Place in StarterGui/ShopGui/ContentFrame/ShopFrame/

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- References
local player = Players.LocalPlayer
local shopFrame = script.Parent
local contentFrame = shopFrame.Parent
local shopGui = contentFrame.Parent

-- Remote events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local OpenShop = RemoteEvents:WaitForChild("OpenShop")

-- Start with shop hidden
contentFrame.Visible = false

-- Listen for server open shop events
OpenShop.OnClientEvent:Connect(function(shopType)
	print("Opening shop:", shopType or "default")
	contentFrame.Visible = true

	-- You can implement different shop layouts based on shopType here
	-- For now, just show the shop UI that's already set up in ShopUI.client.lua
end)

-- Close shop on ESC key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.Escape then
		if contentFrame.Visible then
			contentFrame.Visible = false
		end
	end
end)

-- Add close button functionality if it exists
local function findCloseButton(parent)
	for _, child in pairs(parent:GetDescendants()) do
		if child:IsA("TextButton") and (child.Name:lower():find("close") or child.Text == "X") then
			child.MouseButton1Click:Connect(function()
				contentFrame.Visible = false
			end)
		end
	end
end

findCloseButton(shopFrame)

print("Simple Shop UI loaded")