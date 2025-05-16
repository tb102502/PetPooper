-- ShopUIController.client.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Get remote events
local ShopEvents = ReplicatedStorage:WaitForChild("ShopEvents")
local OpenShopEvent = ShopEvents:WaitForChild("OpenShopEvent")

-- Get or wait for the main GUI
local MainGui = PlayerGui:WaitForChild("MainGui")
local ShopFrame = MainGui:WaitForChild("ShopFrame")
local InventoryFrame = MainGui:WaitForChild("InventoryFrame")
local ToggleButton = MainGui:WaitForChild("ToggleButton")

-- Cache for shop data
local shopData = {}

-- Function to initialize shop data
local function initializeShopData()
	-- Load shop data from ModuleScript
	local ShopDataModule = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ShopData")
	shopData = require(ShopDataModule)
end

-- Function to toggle shop visibility
local function toggleShop(shopType)
	-- Hide inventory if shop is being shown
	if not ShopFrame.Visible then
		if InventoryFrame.Visible then
			InventoryFrame.Visible = false
		end

		-- Show shop and set up shop-specific content
		ShopFrame.Visible = true
		ShopFrame.Title.Text = shopType .. " Shop"

		-- Load shop items based on shop type
		populateShopItems(shopType)
	else
		-- Hide shop
		ShopFrame.Visible = false
	end
end

-- Function to populate shop with items
function populateShopItems(shopType)
	local itemsData = shopData[shopType]
	if not itemsData then
		warn("No shop data found for shop type: " .. shopType)
		return
	end

	local itemContainer = ShopFrame:FindFirstChild("ItemContainer")
	if not itemContainer then 
		warn("ItemContainer not found in ShopFrame")
		return 
	end

	-- Clear existing items
	for _, child in ipairs(itemContainer:GetChildren()) do
		if child:IsA("Frame") or child:IsA("ImageLabel") then
			child:Destroy()
		end
	end

	-- Add new items
	for i, itemData in ipairs(itemsData) do
		-- Get the template from ReplicatedStorage
		local itemTemplate = ReplicatedStorage:FindFirstChild("UI"):FindFirstChild("ShopItemTemplate")
		if not itemTemplate then
			warn("ShopItemTemplate not found")
			continue
		end

		local newItem = itemTemplate:Clone()
		newItem.Parent = itemContainer

		-- Set up item display
		newItem.ItemName.Text = itemData.Name
		newItem.PriceLabel.Text = itemData.Price .. " " .. itemData.Currency
		newItem.ItemImage.Image = itemData.ImageId

		-- Position the item
		newItem.LayoutOrder = i

		-- Set up purchase button
		newItem.PurchaseButton.MouseButton1Click:Connect(function()
			purchaseItem(itemData)
		end)
	end
end

-- Function to handle purchases
function purchaseItem(itemData)
	-- Call server to validate and process the purchase
	local PurchaseEvent = ShopEvents:WaitForChild("PurchaseEvent")
	PurchaseEvent:FireServer(itemData.ID)
end

-- Connect to remote event
OpenShopEvent.OnClientEvent:Connect(toggleShop)

-- Set up close button
local closeButton = ShopFrame:FindFirstChild("CloseButton")
if closeButton then
	closeButton.MouseButton1Click:Connect(function()
		ShopFrame.Visible = false
	end)
end

-- Initialize shop data when the script starts
initializeShopData()aZ