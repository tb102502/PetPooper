-- ShopManager.lua (ModuleScript)
-- Handles shop GUI logic and coordination between different shop implementations
-- Place in StarterGui/MainGui/GuiModules/Utility/ShopManager.lua

local ShopManager = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- References
local player = Players.LocalPlayer
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local OpenShop = RemoteEvents:WaitForChild("OpenShop")

-- Shop GUI references
local shopGuis = {}

-- Initialize the shop manager
function ShopManager.Initialize()
	-- Find existing shop GUIs
	local playerGui = player:WaitForChild("PlayerGui")

	-- Look for ShopGUI (from ShopGUI.client.lua)
	local shopGUI = playerGui:FindFirstChild("ShopGUI")
	if shopGUI then
		shopGuis["legacy"] = shopGUI
	end

	-- Look for ShopGui (from ShopGui folder structure)
	local shopGui = playerGui:FindFirstChild("ShopGui")
	if shopGui then
		shopGuis["modular"] = shopGui
	end

	-- Listen for server open shop events
	OpenShop.OnClientEvent:Connect(function(shopType)
		ShopManager.OpenShop(shopType)
	end)

	print("ShopManager initialized")
end

-- Open shop with specified type
function ShopManager.OpenShop(shopType)
	shopType = shopType or "Shop"

	-- Try to use the modular shop first
	if shopGuis["modular"] then
		local contentFrame = shopGuis["modular"]:FindFirstChild("ContentFrame")
		if contentFrame then
			contentFrame.Visible = true
			print("Opened modular shop")
			return
		end
	end

	-- Fall back to legacy shop
	if shopGuis["legacy"] then
		shopGuis["legacy"].Enabled = true
		print("Opened legacy shop")
		return
	end

	-- No shop GUI found
	warn("ShopManager: No shop GUI found to open")
end

-- Close all shop GUIs
function ShopManager.CloseShop()
	for _, shopGui in pairs(shopGuis) do
		if shopGui.ClassName == "ScreenGui" then
			shopGui.Enabled = false
		elseif shopGui:FindFirstChild("ContentFrame") then
			shopGui.ContentFrame.Visible = false
		end
	end
end

-- Check if any shop is open
function ShopManager.IsShopOpen()
	for _, shopGui in pairs(shopGuis) do
		if shopGui.ClassName == "ScreenGui" and shopGui.Enabled then
			return true
		elseif shopGui:FindFirstChild("ContentFrame") and shopGui.ContentFrame.Visible then
			return true
		end
	end
	return false
end

return ShopManager