-- StarterGui/ShopGui/ShopOpenClient.lua

-- Services
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")

-- Local shortcuts
local player   = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local shopGui  = playerGui:WaitForChild("ShopGui")         -- ScreenGui
local ContentFrame = shopGui:WaitForChild("ContentFrame")
local mainGui = playerGui:WaitForChild("MainGui") 
local topBar    = mainGui:WaitForChild("TopBar")           -- Frame or Folder with the toggle button
local toggleBtn = topBar:WaitForChild("ToggleButton")      -- The old toggle button

-- Remotes
local reFolder      = ReplicatedStorage:WaitForChild("RemoteEvents")
local openShopEvent = reFolder:WaitForChild("OpenShop")

-- Start hidden
ContentFrame.Visible = false
toggleBtn.Visible = true

-- Open shop when server tells us to
openShopEvent.OnClientEvent:Connect(function()
	ContentFrame.Visible = true
end)

-- (Optional) Close shop on ESC key
UserInputService.InputBegan:Connect(function(input, gp)
	if not gp and input.KeyCode == Enum.KeyCode.Escape then
		ContentFrame.Visible = false
	end
end)
