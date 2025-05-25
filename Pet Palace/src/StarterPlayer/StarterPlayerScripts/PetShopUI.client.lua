-- PetShopUI.client.lua
-- Handles the pet shop user interface
-- Author: tb102502
-- Date: 2025-05-23 22:55:00

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Get player and services
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Get RemoteFunction
local remoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local buyPetFunction = remoteFunctions:WaitForChild("BuyPet")

-- Get RemoteEvents
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local updateCurrency = remoteEvents:WaitForChild("UpdateCurrency")

-- Get dependencies
local PetRegistry = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetRegistry"))

-- Variables
local currentCurrency = {
	coins = 0,
	gems = 0
}

-- UI References (assuming these UI elements exist in your ScreenGui)
local shopUI = playerGui:WaitForChild("MainUI"):WaitForChild("PetShop")
local petsContainer = shopUI:WaitForChild("PetsContainer")
local selectedPetInfo = shopUI:WaitForChild("SelectedPetInfo")
local buyButton = selectedPetInfo:WaitForChild("BuyButton")
local currencyDisplay = shopUI:WaitForChild("CurrencyDisplay")
local closeButton = shopUI:WaitForChild("CloseButton")

local petItemTemplate = ReplicatedStorage:WaitForChild("UITemplates"):WaitForChild("PetShopItem")

-- Initialize UI
local function initializePetShop()
	-- Clear existing pets
	for _, child in pairs(petsContainer:GetChildren()) do
		if child:IsA("Frame") or child:IsA("ImageButton") then
			child:Destroy()
		end
	end

	-- Create pet items in shop
	for i, pet in ipairs(PetRegistry.Pets) do
		-- Create a new pet item from template
		local petItem = petItemTemplate:Clone()
		petItem.Name = pet.id
		petItem.PetName.Text = pet.displayName
		petItem.PetImage.Image = pet.thumbnail or "rbxassetid://1931529099" -- Default icon
		petItem.PetRarity.Text = pet.rarity
		petItem.PetPrice.Text = pet.price

		-- Set rarity color
		local rarityColors = {
			Common = Color3.fromRGB(150, 150, 150),
			Uncommon = Color3.fromRGB(100, 255, 100),
			Rare = Color3.fromRGB(0, 150, 255),
			Epic = Color3.fromRGB(200, 0, 255),
			Legendary = Color3.fromRGB(255, 200, 0)
		}

		petItem.PetRarity.TextColor3 = rarityColors[pet.rarity] or Color3.fromRGB(255, 255, 255)

		-- Set up selection behavior
		petItem.SelectButton.MouseButton1Click:Connect(function()
			selectPet(pet)
		end)

		-- Position in grid
		petItem.LayoutOrder = i
		petItem.Parent = petsContainer
	end

	-- Default selection
	if PetRegistry.Pets[1] then
		selectPet(PetRegistry.Pets[1])
	end

	-- Update currency display
	updateCurrencyDisplay()

	-- Connect buy button
	buyButton.MouseButton1Click:Connect(function()
		local selectedPetId = buyButton:GetAttribute("SelectedPetId")
		if selectedPetId then
			buyPet(selectedPetId)
		end
	end)

	-- Connect close button
	closeButton.MouseButton1Click:Connect(function()
		shopUI.Visible = false
	end)

	print("Pet shop UI initialized")
end

-- Select a pet to display details
function selectPet(pet)
	-- Update selected pet info
	selectedPetInfo.PetName.Text = pet.displayName
	selectedPetInfo.PetDescription.Text = pet.description
	selectedPetInfo.PetRarity.Text = pet.rarity
	selectedPetInfo.PetPrice.Text = "Price: " .. pet.price .. " Coins"

	-- Set attributes for purchase
	buyButton:SetAttribute("SelectedPetId", pet.id)

	-- Show pet abilities
	local abilitiesText = "Abilities:\n"
	for ability, value in pairs(pet.abilities) do
		local formattedName = ability:sub(1, 1):upper() .. ability:sub(2)
		formattedName = formattedName:gsub("([A-Z])", " %1"):sub(2) -- Add spaces before capitals

		-- Format the value based on type
		local formattedValue
		if type(value) == "number" then
			if value > 1 then
				formattedValue = "+" .. math.floor((value - 1) * 100) .. "%"
			else
				formattedValue = math.floor(value * 100) .. "%"
			end
		else
			formattedValue = tostring(value)
		end

		abilitiesText = abilitiesText .. "• " .. formattedName .. ": " .. formattedValue .. "\n"
	end

	selectedPetInfo.PetAbilities.Text = abilitiesText

	-- Update image
	selectedPetInfo.PetImage.Image = pet.thumbnail or "rbxassetid://1931529099"

	-- Set rarity colors
	local rarityColors = {
		Common = Color3.fromRGB(150, 150, 150),
		Uncommon = Color3.fromRGB(100, 255, 100),
		Rare = Color3.fromRGB(0, 150, 255),
		Epic = Color3.fromRGB(200, 0, 255),
		Legendary = Color3.fromRGB(255, 200, 0)
	}

	selectedPetInfo.PetRarity.TextColor3 = rarityColors[pet.rarity] or Color3.fromRGB(255, 255, 255)

	-- Update buy button based on affordability
	if currentCurrency.coins >= pet.price then
		buyButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
		buyButton.Text = "Buy Pet"
	else
		buyButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
		buyButton.Text = "Not Enough Coins"
	end

	-- Animation effect
	selectedPetInfo.Visible = false
	selectedPetInfo.Position = UDim2.new(1.1, 0, 0.5, 0)
	selectedPetInfo.Visible = true

	local tween = TweenService:Create(
		selectedPetInfo,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, 0, 0.5, 0)}
	)
	tween:Play()
end

-- Buy a pet
function buyPet(petId)
	-- Find pet info
	local petInfo = PetRegistry.GetPetById(petId)
	if not petInfo then
		print("Pet not found: " .. petId)
		return
	end

	-- Check if player can afford it
	if currentCurrency.coins < petInfo.price then
		-- Show not enough coins animation
		local originalColor = buyButton.BackgroundColor3
		local originalText = buyButton.Text

		buyButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		buyButton.Text = "Not Enough Coins!"

		wait(1)

		buyButton.BackgroundColor3 = originalColor
		buyButton.Text = originalText

		return
	end

	-- Disable button during purchase
	local originalText = buyButton.Text
	buyButton.Text = "Buying..."
	buyButton.Active = false

	-- Call server to purchase
	local success, message, newPetId = buyPetFunction:InvokeServer(petId)

	-- Re-enable button
	buyButton.Active = true

	if success then
		-- Show success animation
		buyButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		buyButton.Text = "Success!"

		-- Update local currency
		currentCurrency.coins = currentCurrency.coins - petInfo.price
		updateCurrencyDisplay()

		-- Show success message
		local notification = playerGui:WaitForChild("MainUI"):WaitForChild("Notification")
		notification.Title.Text = "New Pet!"
		notification.Message.Text = "You've purchased a " .. petInfo.displayName .. "!"
		notification.Visible = true

		-- Auto-hide notification
		spawn(function()
			wait(3)
			notification.Visible = false
		end)

		-- Reset button after delay
		wait(1)
		buyButton.Text = originalText

		-- Update button state
		if currentCurrency.coins >= petInfo.price then
			buyButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
		else
			buyButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
			buyButton.Text = "Not Enough Coins"
		end
	else
		-- Show error animation
		buyButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		buyButton.Text = message or "Error!"

		-- Reset after delay
		wait(1)
		buyButton.Text = originalText
		buyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	end
end

-- Update currency display
function updateCurrencyDisplay()
	currencyDisplay.CoinsText.Text = currentCurrency.coins
	currencyDisplay.GemsText.Text = currentCurrency.gems
end

-- Listen for currency updates
updateCurrency.OnClientEvent:Connect(function(newCurrency)
	currentCurrency = newCurrency
	updateCurrencyDisplay()

	-- Update buy button state for selected pet
	local selectedPetId = buyButton:GetAttribute("SelectedPetId")
	if selectedPetId then
		local pet = PetRegistry.GetPetById(selectedPetId)
		if pet then
			if currentCurrency.coins >= pet.price then
				buyButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
				buyButton.Text = "Buy Pet"
			else
				buyButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
				buyButton.Text = "Not Enough Coins"
			end
		end
	end
end)

-- Initialize when the shop is opened
local function onShopOpened()
	-- Fetch current currency from server
	local getCurrencyFunction = remoteFunctions:WaitForChild("GetCurrency")
	local newCurrency = getCurrencyFunction:InvokeServer()

	if newCurrency then
		currentCurrency = newCurrency
	end

	-- Refresh shop UI
	initializePetShop()
end

-- Connect to shop toggle
local shopToggleButton = playerGui:WaitForChild("MainUI"):WaitForChild("BottomButtons"):WaitForChild("PetShopButton")

shopToggleButton.MouseButton1Click:Connect(function()
	shopUI.Visible = not shopUI.Visible

	if shopUI.Visible then
		onShopOpened()
	end
end)

-- Initialize when first loaded
shopUI.Visible = false
print("Pet shop UI script loaded")