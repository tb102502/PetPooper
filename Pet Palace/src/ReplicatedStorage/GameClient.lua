--[[
    GameClient.lua - CONSOLIDATED CLIENT SYSTEM (FIXED)
    Place in: ReplicatedStorage/GameClient.lua
    
    This replaces: PetSystemClient, ShopSystemClient, UIController, and all other client scripts
    Single client interface for all game systems
]]

local GameClient = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Player and Game State
local LocalPlayer = Players.LocalPlayer
GameClient.PlayerData = {}
GameClient.RemoteEvents = {}
GameClient.RemoteFunctions = {}
GameClient.UI = {}
GameClient.Cache = {
	ShopItems = {},
	ActiveBoosters = {},
	EquippedPets = {}
}

-- UI State
GameClient.UIState = {
	ActiveMenus = {},
	CurrentPage = nil,
	IsTransitioning = false
}

-- Add this new state tracking for pet selling
GameClient.SellingMode = {
	isActive = false,
	selectedPets = {},
	totalValue = 0
}



-- Calculate pet sell value (client-side estimation)
function GameClient:CalculatePetSellValue(petData)
	if not petData then return 0 end

	local baseValues = {
		Common = 25,
		Uncommon = 75,
		Rare = 200,
		Epic = 500,
		Legendary = 1500
	}

	local baseValue = baseValues[petData.rarity] or baseValues.Common
	local level = tonumber(petData.level) or 1
	local levelMultiplier = 1 + ((level - 1) * 0.1)

	return math.floor(baseValue * levelMultiplier)
end
-- Toggle selling mode
function GameClient:ToggleSellingMode()
	self.SellingMode.isActive = not self.SellingMode.isActive
	self.SellingMode.selectedPets = {}
	self.SellingMode.totalValue = 0

	-- Update all pet cards
	self:RefreshPetsMenu()

	-- Update selling UI
	self:UpdateSellingUI()
end

-- Toggle pet selection for selling
function GameClient:TogglePetSelection(petId, card)
	local selectionBox = card:FindFirstChild("SelectionBox")
	local checkmark = selectionBox and selectionBox:FindFirstChild("Checkmark")

	if not selectionBox or not checkmark then return end

	local isSelected = checkmark.Visible

	if isSelected then
		-- Deselect
		checkmark.Visible = false
		selectionBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

		-- Remove from selection
		for i, selectedId in ipairs(self.SellingMode.selectedPets) do
			if selectedId == petId then
				table.remove(self.SellingMode.selectedPets, i)
				break
			end
		end

		-- Recalculate total value
		self:RecalculateSellingTotal()
	else
		-- Select (but check if pet is equipped first)
		local petData = self:GetPetById(petId)
		if petData and self:IsPetEquipped(petId) then
			self:ShowNotification("Cannot Sell", "Unequip the pet before selling", "error")
			return
		end

		checkmark.Visible = true
		selectionBox.BackgroundColor3 = Color3.fromRGB(0, 150, 0)

		table.insert(self.SellingMode.selectedPets, petId)
		self:RecalculateSellingTotal()
	end

	self:UpdateSellingUI()
end

-- Get pet by ID
function GameClient:GetPetById(petId)
	if not self.PlayerData or not self.PlayerData.pets or not self.PlayerData.pets.owned then
		return nil
	end

	for _, pet in ipairs(self.PlayerData.pets.owned) do
		if pet.id == petId then
			return pet
		end
	end

	return nil
end

-- Recalculate total selling value
function GameClient:RecalculateSellingTotal()
	self.SellingMode.totalValue = 0

	for _, petId in ipairs(self.SellingMode.selectedPets) do
		local petData = self:GetPetById(petId)
		if petData then
			self.SellingMode.totalValue = self.SellingMode.totalValue + self:CalculatePetSellValue(petData)
		end
	end
end

-- Update pet card button based on current mode
function GameClient:UpdatePetCardButton(card, petData, isEquipped)
	local actionButton = card:FindFirstChild("TextButton")
	local selectionBox = card:FindFirstChild("SelectionBox")

	if not actionButton then return end

	-- ALWAYS show selling interface, never equipping
	if self.SellingMode and self.SellingMode.isActive then
		-- Selling mode - show selection
		actionButton.Text = "Select to Sell"
		actionButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
		actionButton.TextColor3 = Color3.new(1, 1, 1)

		if selectionBox then
			selectionBox.Visible = true
		end
	else
		-- Normal mode - show direct sell button
		local sellValue = self:CalculatePetSellValue(petData)
		actionButton.Text = "Sell for " .. sellValue
		actionButton.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
		actionButton.TextColor3 = Color3.new(1, 1, 1)

		if selectionBox then
			selectionBox.Visible = false
		end
	end
end
-- FIXED: CreatePetCard with sell-only functionality
function GameClient:CreatePetCard(petData, parent, index, isEquipped)
	-- Validate input parameters
	if not petData then
		warn("GameClient: CreatePetCard called with nil petData")
		return Instance.new("Frame")
	end

	if not parent then
		warn("GameClient: CreatePetCard called with nil parent")
		return Instance.new("Frame")
	end

	-- Ensure index is a number
	index = tonumber(index) or 1

	-- Create card container
	local card = Instance.new("Frame")
	card.Name = "PetCard_" .. (petData.id or "unknown")
	card.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
	card.BorderSizePixel = 0
	card.LayoutOrder = index
	card.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.05, 0)
	corner.Parent = card

	-- Pet image placeholder
	local image = Instance.new("Frame")
	image.Name = "Image"
	image.Size = UDim2.new(0.8, 0, 0.4, 0)
	image.Position = UDim2.new(0.5, 0, 0.2, 0)
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	image.Parent = card

	local imageCorner = Instance.new("UICorner")
	imageCorner.CornerRadius = UDim.new(0.1, 0)
	imageCorner.Parent = image

	-- Pet emoji as placeholder
	local emoji = Instance.new("TextLabel")
	emoji.Size = UDim2.new(1, 0, 1, 0)
	emoji.BackgroundTransparency = 1
	emoji.Text = self:GetPetEmoji(petData.type or "bunny")
	emoji.TextScaled = true
	emoji.Font = Enum.Font.SourceSansSemibold
	emoji.Parent = image

	-- Pet name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.9, 0, 0.12, 0)
	nameLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	nameLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = petData.name or petData.displayName or petData.type or "Unknown Pet"
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansSemibold
	nameLabel.Parent = card

	-- Pet rarity
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(0.9, 0, 0.08, 0)
	rarityLabel.Position = UDim2.new(0.5, 0, 0.62, 0)
	rarityLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = (petData.rarity or "Common"):upper()
	rarityLabel.TextColor3 = self:GetRarityColor(petData.rarity or "Common")
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.SourceSansSemibold
	rarityLabel.Parent = card

	-- Sell value label (prominent display)
	local sellValue = self:CalculatePetSellValue(petData)
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "SellValue"
	valueLabel.Size = UDim2.new(0.9, 0, 0.1, 0)
	valueLabel.Position = UDim2.new(0.5, 0, 0.72, 0)
	valueLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	valueLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	valueLabel.BackgroundTransparency = 0.3
	valueLabel.Text = "💰 SELL: " .. sellValue .. " COINS"
	valueLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	valueLabel.TextScaled = true
	valueLabel.Font = Enum.Font.SourceSansSemibold
	valueLabel.Parent = card

	local valueCorner = Instance.new("UICorner")
	valueCorner.CornerRadius = UDim.new(0.2, 0)
	valueCorner.Parent = valueLabel

	-- Selection checkbox for selling mode
	local selectionBox = Instance.new("Frame")
	selectionBox.Name = "SelectionBox"
	selectionBox.Size = UDim2.new(0.15, 0, 0.15, 0)
	selectionBox.Position = UDim2.new(0.85, 0, 0.05, 0)
	selectionBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	selectionBox.BorderSizePixel = 2
	selectionBox.BorderColor3 = Color3.fromRGB(255, 255, 255)
	selectionBox.Visible = self.SellingMode and self.SellingMode.isActive or false
	selectionBox.Parent = card

	local selectionCorner = Instance.new("UICorner")
	selectionCorner.CornerRadius = UDim.new(0.2, 0)
	selectionCorner.Parent = selectionBox

	local checkmark = Instance.new("TextLabel")
	checkmark.Name = "Checkmark"
	checkmark.Size = UDim2.new(1, 0, 1, 0)
	checkmark.BackgroundTransparency = 1
	checkmark.Text = "✓"
	checkmark.TextColor3 = Color3.fromRGB(0, 255, 0)
	checkmark.TextScaled = true
	checkmark.Font = Enum.Font.SourceSansSemibold
	checkmark.Visible = false
	checkmark.Parent = selectionBox

	-- SELL BUTTON (no equip functionality)
	local sellButton = Instance.new("TextButton")
	sellButton.Size = UDim2.new(0.8, 0, 0.12, 0)
	sellButton.Position = UDim2.new(0.5, 0, 0.88, 0)
	sellButton.AnchorPoint = Vector2.new(0.5, 0.5)
	sellButton.BorderSizePixel = 0
	sellButton.TextScaled = true
	sellButton.Font = Enum.Font.SourceSansSemibold
	sellButton.Parent = card

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0.2, 0)
	buttonCorner.Parent = sellButton

	-- Update button appearance
	self:UpdatePetCardButton(card, petData, false) -- Never pass isEquipped as true

	-- SELL CLICK HANDLERS
	sellButton.MouseButton1Click:Connect(function()
		if self.SellingMode and self.SellingMode.isActive then
			-- Multi-select mode
			self:TogglePetSelection(petData.id, card)
		else
			-- Direct sell with confirmation
			self:ShowSellConfirmation(petData)
		end
	end)

	-- Selection box click
	selectionBox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and 
			self.SellingMode and self.SellingMode.isActive then
			self:TogglePetSelection(petData.id, card)
		end
	end)

	return card
end
function GameClient:UpdateSellingUI()
	local menu = self.UI.Menus.Pets
	if not menu then return end

	-- Get or create selling controls
	local sellingControls = menu:FindFirstChild("SellingControls")
	if not sellingControls then
		sellingControls = Instance.new("Frame")
		sellingControls.Name = "SellingControls"
		sellingControls.Size = UDim2.new(1, 0, 0.15, 0)
		sellingControls.Position = UDim2.new(0, 0, 0.85, 0)
		sellingControls.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
		sellingControls.BorderSizePixel = 0
		sellingControls.Parent = menu

		local controlsCorner = Instance.new("UICorner")
		controlsCorner.CornerRadius = UDim.new(0.02, 0)
		controlsCorner.Parent = sellingControls
	end

	-- Clear existing controls
	for _, child in ipairs(sellingControls:GetChildren()) do
		if not child:IsA("UICorner") then
			child:Destroy()
		end
	end

	-- Toggle selling mode button
	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "ToggleSellingButton"
	toggleButton.Size = UDim2.new(0.25, 0, 0.6, 0)
	toggleButton.Position = UDim2.new(0.05, 0, 0.2, 0)
	toggleButton.BackgroundColor3 = self.SellingMode.isActive and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 150, 100)
	toggleButton.BorderSizePixel = 0
	toggleButton.Text = self.SellingMode.isActive and "❌ Cancel Multi-Sell" or "📦 Multi-Sell Mode"
	toggleButton.TextColor3 = Color3.new(1, 1, 1)
	toggleButton.TextScaled = true
	toggleButton.Font = Enum.Font.SourceSansSemibold
	toggleButton.Parent = sellingControls

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0.1, 0)
	toggleCorner.Parent = toggleButton

	toggleButton.MouseButton1Click:Connect(function()
		self:ToggleSellingMode()
	end)

	if self.SellingMode.isActive then
		-- Selection info
		local infoLabel = Instance.new("TextLabel")
		infoLabel.Size = UDim2.new(0.4, 0, 0.6, 0)
		infoLabel.Position = UDim2.new(0.32, 0, 0.2, 0)
		infoLabel.BackgroundTransparency = 1
		infoLabel.Text = #self.SellingMode.selectedPets .. " pets selected\n💰 Total: " .. self.SellingMode.totalValue .. " coins"
		infoLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		infoLabel.TextScaled = true
		infoLabel.Font = Enum.Font.SourceSansSemibold
		infoLabel.Parent = sellingControls

		-- Sell selected button
		local sellButton = Instance.new("TextButton")
		sellButton.Size = UDim2.new(0.2, 0, 0.6, 0)
		sellButton.Position = UDim2.new(0.75, 0, 0.2, 0)
		sellButton.BackgroundColor3 = #self.SellingMode.selectedPets > 0 and Color3.fromRGB(200, 100, 100) or Color3.fromRGB(100, 100, 100)
		sellButton.BorderSizePixel = 0
		sellButton.Text = "💸 Sell All"
		sellButton.TextColor3 = Color3.new(1, 1, 1)
		sellButton.TextScaled = true
		sellButton.Font = Enum.Font.SourceSansSemibold
		sellButton.Active = #self.SellingMode.selectedPets > 0
		sellButton.Parent = sellingControls

		local sellCorner = Instance.new("UICorner")
		sellCorner.CornerRadius = UDim.new(0.1, 0)
		sellCorner.Parent = sellButton

		if #self.SellingMode.selectedPets > 0 then
			sellButton.MouseButton1Click:Connect(function()
				self:ConfirmSellSelectedPets()
			end)
		end
	else
		-- Help text for direct selling
		local helpLabel = Instance.new("TextLabel")
		helpLabel.Size = UDim2.new(0.65, 0, 0.6, 0)
		helpLabel.Position = UDim2.new(0.32, 0, 0.2, 0)
		helpLabel.BackgroundTransparency = 1
		helpLabel.Text = "💡 Click any pet's sell button for instant sale, or use Multi-Sell for bulk sales"
		helpLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		helpLabel.TextScaled = true
		helpLabel.Font = Enum.Font.SourceSans
		helpLabel.Parent = sellingControls
	end
end

-- Show confirmation dialog
function GameClient:ShowConfirmationDialog(title, message, onConfirm)
	local overlayLayer = self.UI.Overlay

	-- Remove existing dialog
	local existingDialog = overlayLayer:FindFirstChild("ConfirmationDialog")
	if existingDialog then
		existingDialog:Destroy()
	end

	-- Create overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "ConfirmationDialog"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.Parent = overlayLayer

	-- Create dialog
	local dialog = Instance.new("Frame")
	dialog.Size = UDim2.new(0.4, 0, 0.3, 0)
	dialog.Position = UDim2.new(0.5, 0, 0.5, 0)
	dialog.AnchorPoint = Vector2.new(0.5, 0.5)
	dialog.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	dialog.BorderSizePixel = 0
	dialog.Parent = overlay

	local dialogCorner = Instance.new("UICorner")
	dialogCorner.CornerRadius = UDim.new(0.05, 0)
	dialogCorner.Parent = dialog

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0.2, 0)
	titleLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	titleLabel.BorderSizePixel = 0
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.SourceSansSemibold
	titleLabel.Parent = dialog

	-- Message
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Size = UDim2.new(0.9, 0, 0.5, 0)
	messageLabel.Position = UDim2.new(0.05, 0, 0.25, 0)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = message
	messageLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	messageLabel.TextScaled = true
	messageLabel.TextWrapped = true
	messageLabel.Font = Enum.Font.SourceSans
	messageLabel.Parent = dialog

	-- Buttons
	local cancelButton = Instance.new("TextButton")
	cancelButton.Size = UDim2.new(0.35, 0, 0.15, 0)
	cancelButton.Position = UDim2.new(0.1, 0, 0.8, 0)
	cancelButton.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
	cancelButton.BorderSizePixel = 0
	cancelButton.Text = "Cancel"
	cancelButton.TextColor3 = Color3.new(1, 1, 1)
	cancelButton.TextScaled = true
	cancelButton.Font = Enum.Font.SourceSansSemibold
	cancelButton.Parent = dialog

	local confirmButton = Instance.new("TextButton")
	confirmButton.Size = UDim2.new(0.35, 0, 0.15, 0)
	confirmButton.Position = UDim2.new(0.55, 0, 0.8, 0)
	confirmButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	confirmButton.BorderSizePixel = 0
	confirmButton.Text = "Confirm"
	confirmButton.TextColor3 = Color3.new(1, 1, 1)
	confirmButton.TextScaled = true
	confirmButton.Font = Enum.Font.SourceSansSemibold
	confirmButton.Parent = dialog

	-- Button corners
	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0.2, 0)
	cancelCorner.Parent = cancelButton

	local confirmCorner = Instance.new("UICorner")
	confirmCorner.CornerRadius = UDim.new(0.2, 0)
	confirmCorner.Parent = confirmButton

	-- Button events
	cancelButton.MouseButton1Click:Connect(function()
		overlay:Destroy()
	end)

	confirmButton.MouseButton1Click:Connect(function()
		overlay:Destroy()
		if onConfirm then
			onConfirm()
		end
	end)
end

-- Handle pet sold event
function GameClient:HandlePetSold(petData, coinsEarned)
	self:ShowNotification("Pet Sold!", 
		"Sold " .. (petData.name or "Pet") .. " for " .. coinsEarned .. " coins", "success")

	-- IMMEDIATE UI REFRESH - This is the key fix
	if self.UIState.CurrentPage == "Pets" then
		-- Immediately refresh pets menu to show the sold pet is gone
		self:RefreshPetsMenu()
	end

	-- Update currency display immediately
	self:UpdateCurrencyDisplay()
end

-- Also update the SellPet function to ensure immediate response:
function GameClient:ShowSellConfirmation(petData)
	if not petData then return end

	local sellValue = self:CalculatePetSellValue(petData)
	local petName = petData.name or petData.displayName or petData.type or "Unknown Pet"

	self:ShowConfirmationDialog(
		"Sell Pet",
		"Sell " .. petName .. " (" .. (petData.rarity or "Common") .. ") for " .. sellValue .. " coins?\n\nThis action cannot be undone!",
		function()
			-- Send sell request to server
			if self.RemoteEvents.SellPet then
				self.RemoteEvents.SellPet:FireServer(petData.id)

				-- IMMEDIATE LOCAL UPDATE - Remove from display right away
				-- This provides instant feedback while waiting for server response
				self:RemovePetFromLocalDisplay(petData.id)
			end
		end
	)
end

-- Add this new function to immediately remove pet from display:
function GameClient:RemovePetFromLocalDisplay(petId)
	if not self.PlayerData or not self.PlayerData.pets or not self.PlayerData.pets.owned then
		return
	end

	-- Remove from local data temporarily (server will send official update)
	for i, pet in ipairs(self.PlayerData.pets.owned) do
		if pet.id == petId then
			table.remove(self.PlayerData.pets.owned, i)
			break
		end
	end

	-- Immediately refresh pets menu if it's open
	if self.UIState.CurrentPage == "Pets" then
		self:RefreshPetsMenu()
	end
end

function GameClient:CleanupOldReferences()
	-- Clean up old animation references
	if self.Animations then
		for animId, animData in pairs(self.Animations) do
			if animData.Cancelled then
				self.Animations[animId] = nil
			end
		end
	end

	-- Clean up old pet references in selling mode
	if self.SellingMode.selectedPets then
		local validPets = {}
		for _, petId in ipairs(self.SellingMode.selectedPets) do
			if self:GetPetById(petId) then
				table.insert(validPets, petId)
			end
		end
		self.SellingMode.selectedPets = validPets
	end
end
-- Initialize the entire client system
function GameClient:Initialize()
	print("GameClient: Starting initialization...")

	-- Initialize selling mode
	if not self.SellingMode then
		self.SellingMode = {
			isActive = false,
			selectedPets = {},
			totalValue = 0
		}
	end

	self:SetupRemoteConnections()
	self:SetupUI()
	self:SetupInputHandling()
	self:SetupEffects()
	self:RequestInitialData()

	print("GameClient: Initialization complete!")
	return true
end


-- Setup Remote Connections
function GameClient:SetupRemoteConnections()
	-- FIXED: Use consistent remote folder
	local remoteFolder = ReplicatedStorage:WaitForChild("GameRemotes", 10)
	if not remoteFolder then
		warn("GameClient: Could not find GameRemotes folder")
		return
	end

	-- Store remote references  
	for _, child in ipairs(remoteFolder:GetChildren()) do
		if child:IsA("RemoteEvent") then
			self.RemoteEvents[child.Name] = child
		elseif child:IsA("RemoteFunction") then
			self.RemoteFunctions[child.Name] = child
		end
	end

	self:SetupEventHandlers()
	print("GameClient: Remote connections established")
end
function GameClient:HandleItemPurchased(itemId, quantity, cost, currency)
	-- Update local currency display immediately for responsiveness
	if self.PlayerData then
		if currency == "coins" then
			self.PlayerData.coins = math.max(0, (self.PlayerData.coins or 0) - cost)
		elseif currency == "gems" then
			self.PlayerData.gems = math.max(0, (self.PlayerData.gems or 0) - cost)
		end

		self:UpdateCurrencyDisplay()
	end

	-- Show purchase notification
	local itemName = itemId
	if self.Cache.ShopItems and self.Cache.ShopItems[itemId] then
		itemName = self.Cache.ShopItems[itemId].name or itemId
	end

	self:ShowNotification("Purchase Successful!", 
		"Bought " .. (quantity > 1 and (quantity .. "x ") or "") .. itemName .. " for " .. cost .. " " .. currency, 
		"success")

	print("GameClient: Purchased " .. itemId .. " x" .. quantity .. " for " .. cost .. " " .. currency)
end

-- Add the missing CanAffordItem method
function GameClient:CanAffordItem(itemData)
	if not itemData or not self.PlayerData then return false end

	local price = itemData.price or 0
	local currency = (itemData.currency or "coins"):lower()

	if currency == "coins" then
		return (self.PlayerData.coins or 0) >= price
	elseif currency == "gems" then
		return (self.PlayerData.gems or 0) >= price
	end

	return false
end

-- Add the missing GetItemEmoji method
function GameClient:GetItemEmoji(itemType)
	local emojiMap = {
		-- Seeds
		seed = "🌱",
		["carrot_seeds"] = "🥕",
		["corn_seeds"] = "🌽", 
		["wheat_seeds"] = "🌾",
		["tomato_seeds"] = "🍅",
		["potato_seeds"] = "🥔",

		-- Upgrades
		upgrade = "⬆️",
		["speed_boost"] = "💨",
		["coin_multiplier"] = "💰",
		["pet_slots"] = "🐾",
		["inventory_space"] = "🎒",

		-- Pets/Eggs
		pet = "🐾",
		egg = "🥚",
		["basic_egg"] = "🥚",
		["rare_egg"] = "🌟",
		["epic_egg"] = "💎",
		["legendary_egg"] = "👑",

		-- Tools
		tool = "🔧",
		["watering_can"] = "🚿",
		["fertilizer"] = "💩",
		["harvest_tool"] = "🛠️",

		-- Default
		item = "📦"
	}

	return emojiMap[itemType] or emojiMap["item"]
end

-- Add the missing GetPetEmoji method if it doesn't exist
function GameClient:GetPetEmoji(petType)
	local petEmojiMap = {
		Corgi = "🐶", 
		Cat = "🐱",
		Hamster = "🐾",
		RedPanda = "🐾",
		bunny = "🐰",
		cat = "🐱", 
		dog = "🐶",
		bird = "🐦",
		fish = "🐠",
		dragon = "🐉",
		unicorn = "🦄",
		lion = "🦁",
		tiger = "🐅",
		bear = "🐻",
		panda = "🐼",
		fox = "🦊",
		wolf = "🐺",
		elephant = "🐘",
		giraffe = "🦒",
		monkey = "🐵",
		pig = "🐷",
		cow = "🐄",
		sheep = "🐑",
		chicken = "🐔",
		duck = "🦆",
		penguin = "🐧",
		owl = "🦉",
		frog = "🐸",
		turtle = "🐢",
		snake = "🐍",
		lizard = "🦎",
		spider = "🕷️",
		bee = "🐝",
		butterfly = "🦋"
	}

	return petEmojiMap[petType] or "🐾"
end

-- Add the missing GetRarityColor method if it doesn't exist
function GameClient:GetRarityColor(rarity)
	local rarityColors = {
		Common = Color3.fromRGB(200, 200, 200),      -- Gray
		Uncommon = Color3.fromRGB(100, 255, 100),    -- Green  
		Rare = Color3.fromRGB(100, 150, 255),        -- Blue
		Epic = Color3.fromRGB(200, 100, 255),        -- Purple
		Legendary = Color3.fromRGB(255, 215, 0),     -- Gold
		Mythic = Color3.fromRGB(255, 100, 100)       -- Red
	}

	return rarityColors[rarity] or rarityColors.Common
end

-- Setup Event Handlers
function GameClient:SetupEventHandlers()
	-- Player Data Updates
	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated.OnClientEvent:Connect(function(newData)
			self:HandlePlayerDataUpdate(newData)
		end)
	end

	-- Pet System Events
	if self.RemoteEvents.PetCollected then
		self.RemoteEvents.PetCollected.OnClientEvent:Connect(function(petData, coinsAwarded)
			self:HandlePetCollected(petData, coinsAwarded)
		end)
	end

	if self.RemoteEvents.PetEquipped then
		self.RemoteEvents.PetEquipped.OnClientEvent:Connect(function(petId, petData)
			self:HandlePetEquipped(petId, petData)
		end)
	end

	-- Shop System Events
	if self.RemoteEvents.ItemPurchased then
		self.RemoteEvents.ItemPurchased.OnClientEvent:Connect(function(item, quantity)
			self:HandleItemPurchased(item, quantity)
		end)
	end

	if self.RemoteEvents.CurrencyUpdated then
		self.RemoteEvents.CurrencyUpdated.OnClientEvent:Connect(function(currencyData)
			self:HandleCurrencyUpdate(currencyData)
		end)
	end
	
	if self.RemoteEvents.PetSold then
		self.RemoteEvents.PetSold.OnClientEvent:Connect(function(petData, coinsEarned)
			self:HandlePetSold(petData, coinsEarned)
		end)
	end
	if self.RemoteEvents.ItemPurchased then
		self.RemoteEvents.ItemPurchased.OnClientEvent:Connect(function(itemId, quantity, cost, currency)
			self:HandleItemPurchased(itemId, quantity, cost, currency)
		end)
	end	
	-- Pet Selling Events (ADD THESE)
	if self.RemoteEvents.SellPet then
		-- Server will send confirmation, just refresh UI
		self.RemoteEvents.PlayerDataUpdated.OnClientEvent:Connect(function(newData)
			self:HandlePlayerDataUpdate(newData)
			if self.SellingMode.isActive then
				-- Reset selling mode after successful sale
				self.SellingMode.selectedPets = {}
				self.SellingMode.totalValue = 0
				self:RefreshPetsMenu()
			end
		end)
	end
	-- Pet Selling Events
	if self.RemoteEvents.PetSold then
		self.RemoteEvents.PetSold.OnClientEvent:Connect(function(petData, coinsEarned)
			self:HandlePetSold(petData, coinsEarned)
		end)
	end

	-- Player Data Update Handler
	if self.RemoteEvents.PlayerDataUpdated then
		self.RemoteEvents.PlayerDataUpdated.OnClientEvent:Connect(function(newData)
			self:HandlePlayerDataUpdate(newData)
		end)
	end

	-- Notification Handler
	if self.RemoteEvents.NotificationSent then
		self.RemoteEvents.NotificationSent.OnClientEvent:Connect(function(title, message, notificationType)
			self:ShowNotification(title, message, notificationType)
		end)
	end

	print("GameClient: Event handlers setup complete")
end

-- UI System Setup
function GameClient:SetupUI()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	-- Create main UI
	local mainUI = Instance.new("ScreenGui")
	mainUI.Name = "GameUI"
	mainUI.ResetOnSpawn = false
	mainUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	mainUI.Parent = playerGui

	self.UI.MainUI = mainUI

	-- Create UI layers
	self:CreateUILayers(mainUI)

	-- Setup specific UI components
	self:SetupCurrencyDisplay()
	self:SetupNavigationBar()
	self:SetupMenus()

	print("GameClient: UI system setup complete")
end

-- Create UI Layers
function GameClient:CreateUILayers(parent)
	local layers = {"Background", "Content", "Navigation", "Overlay", "Notifications"}

	for i, layerName in ipairs(layers) do
		local layer = Instance.new("Frame")
		layer.Name = layerName
		layer.Size = UDim2.new(1, 0, 1, 0)
		layer.BackgroundTransparency = 1
		layer.ZIndex = i
		layer.Parent = parent

		self.UI[layerName] = layer
	end
end

-- Currency Display
function GameClient:SetupCurrencyDisplay()
	local container = Instance.new("Frame")
	container.Name = "CurrencyDisplay"
	container.Size = UDim2.new(0.25, 0, 0.08, 0)
	container.Position = UDim2.new(0.99, 0, 0.02, 0)
	container.AnchorPoint = Vector2.new(1, 0)
	container.BackgroundTransparency = 1
	container.Parent = self.UI.Navigation

	-- Coins Display
	local coinsFrame = self:CreateCurrencyFrame("Coins", "rbxassetid://6031086173", Color3.fromRGB(255, 215, 0))
	coinsFrame.Size = UDim2.new(1, 0, 0.45, 0)
	coinsFrame.Position = UDim2.new(0, 0, 0, 0)
	coinsFrame.Parent = container

	-- Gems Display  
	local gemsFrame = self:CreateCurrencyFrame("Gems", "rbxassetid://6029251113", Color3.fromRGB(0, 200, 255))
	gemsFrame.Size = UDim2.new(1, 0, 0.45, 0)
	gemsFrame.Position = UDim2.new(0, 0, 0.55, 0)
	gemsFrame.Parent = container

	self.UI.CurrencyContainer = container
	self.UI.CoinsFrame = coinsFrame
	self.UI.GemsFrame = gemsFrame
end

function GameClient:CreateCurrencyFrame(currencyName, iconId, color)
	local frame = Instance.new("Frame")
	frame.Name = currencyName .. "Frame"
	frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35) -- Darker background
	frame.BorderSizePixel = 0

	-- Add stroke for better visibility
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0) -- More rounded
	corner.Parent = frame

	-- Add gradient background
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 45)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 35))
	}
	gradient.Rotation = 90
	gradient.Parent = frame

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 24, 0, 24) -- Fixed size for consistency
	icon.Position = UDim2.new(0, 8, 0.5, -12)
	icon.BackgroundTransparency = 1
	icon.Image = iconId
	icon.ImageColor3 = color
	icon.Parent = frame

	-- Add icon glow effect
	local iconShadow = icon:Clone()
	iconShadow.Name = "IconShadow"
	iconShadow.Position = UDim2.new(0, 10, 0.5, -10)
	iconShadow.ImageTransparency = 0.7
	iconShadow.ZIndex = icon.ZIndex - 1
	iconShadow.Parent = frame

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0, 60, 1, 0)
	label.Position = UDim2.new(0, 40, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = currencyName
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	-- Add text shadow for label
	local labelShadow = label:Clone()
	labelShadow.Name = "LabelShadow"
	labelShadow.Position = UDim2.new(0, 42, 0, 2)
	labelShadow.TextColor3 = Color3.fromRGB(0, 0, 0)
	labelShadow.TextTransparency = 0.5
	labelShadow.ZIndex = label.ZIndex - 1
	labelShadow.Parent = frame

	local value = Instance.new("TextLabel")
	value.Name = "Value"
	value.Size = UDim2.new(1, -110, 1, 0)
	value.Position = UDim2.new(0, 105, 0, 0)
	value.BackgroundTransparency = 1
	value.Text = "0"
	value.TextColor3 = color -- Use currency color for value
	value.TextScaled = true
	value.Font = Enum.Font.GothamBold
	value.TextXAlignment = Enum.TextXAlignment.Right
	value.Parent = frame

	-- Add text shadow for value
	local valueShadow = value:Clone()
	valueShadow.Name = "ValueShadow"
	valueShadow.Position = UDim2.new(1, -110 + 2, 0, 2)
	valueShadow.TextColor3 = Color3.fromRGB(0, 0, 0)
	valueShadow.TextTransparency = 0.5
	valueShadow.ZIndex = value.ZIndex - 1
	valueShadow.Parent = frame

	return frame
end

-- Navigation Bar
function GameClient:SetupNavigationBar()
	local navBar = Instance.new("Frame")
	navBar.Name = "NavigationBar"
	navBar.Size = UDim2.new(1, 0, 0.08, 0)
	navBar.Position = UDim2.new(0, 0, 0.92, 0)
	navBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	navBar.BorderSizePixel = 0
	navBar.Parent = self.UI.Navigation

	local buttons = {
		{name = "Pets", icon = "🐾"},
		{name = "Shop", icon = "🛒"},
		{name = "Farm", icon = "🌾"},
		{name = "Settings", icon = "⚙️"}
	}

	local buttonWidth = 1 / #buttons

	for i, buttonInfo in ipairs(buttons) do
		local button = self:CreateNavButton(buttonInfo.name, buttonInfo.icon)
		button.Size = UDim2.new(buttonWidth, 0, 1, 0)
		button.Position = UDim2.new((i-1) * buttonWidth, 0, 0, 0)
		button.Parent = navBar

		button.MouseButton1Click:Connect(function()
			self:OpenMenu(buttonInfo.name)
		end)
	end

	self.UI.NavigationBar = navBar
end

function GameClient:CreateNavButton(name, icon)
	local button = Instance.new("TextButton")
	button.Name = name .. "Button"
	button.BackgroundTransparency = 1
	button.Text = ""

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	background.BorderSizePixel = 0
	background.Parent = button

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(1, 0, 0.5, 0)
	iconLabel.Position = UDim2.new(0, 0, 0.1, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon
	iconLabel.TextColor3 = Color3.new(1, 1, 1)
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.SourceSansSemibold
	iconLabel.Parent = button

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Text"
	textLabel.Size = UDim2.new(1, 0, 0.3, 0)
	textLabel.Position = UDim2.new(0, 0, 0.65, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = name
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.SourceSansSemibold
	textLabel.Parent = button

	-- Hover effects
	button.MouseEnter:Connect(function()
		TweenService:Create(background, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(65, 65, 75)}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(background, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 55)}):Play()
	end)

	return button
end

-- Menu System
function GameClient:SetupMenus()
	-- Menus will be created dynamically when opened
	self.UI.Menus = {}
end

function GameClient:OpenMenu(menuName)
	if self.UIState.IsTransitioning then return end

	self:CloseActiveMenus()

	local menu = self:GetOrCreateMenu(menuName)
	if not menu then return end

	self.UIState.IsTransitioning = true
	self.UIState.CurrentPage = menuName
	self.UIState.ActiveMenus[menuName] = menu

	-- Show menu with animation
	menu.Visible = true
	menu.Position = UDim2.new(0.5, 0, 1.2, 0)

	local tween = TweenService:Create(menu, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0)
	})

	tween:Play()
	tween.Completed:Connect(function()
		self.UIState.IsTransitioning = false
		self:RefreshMenuContent(menuName)
	end)
end

function GameClient:CloseActiveMenus()
	for menuName, menu in pairs(self.UIState.ActiveMenus) do
		if menu and menu.Visible then
			local tween = TweenService:Create(menu, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, 0, 1.2, 0)
			})
			tween:Play()
			tween.Completed:Connect(function()
				menu.Visible = false
			end)
		end
	end

	self.UIState.ActiveMenus = {}
	self.UIState.CurrentPage = nil
end

function GameClient:GetOrCreateMenu(menuName)
	if self.UI.Menus[menuName] then
		return self.UI.Menus[menuName]
	end

	local menu = self:CreateBaseMenu(menuName)
	self.UI.Menus[menuName] = menu
	if menuName == "Pets" then
		-- Change title to reflect selling focus
		local titleLabel = menu:FindFirstChild("TitleBar") and menu.TitleBar:FindFirstChild("Title")
		if titleLabel then
			titleLabel.Text = "🐾 Pet Collection & Sales"
		end
	end
	return menu
end

function GameClient:CreateBaseMenu(menuName)
	local menu = Instance.new("Frame")
	menu.Name = menuName .. "Menu"
	menu.Size = UDim2.new(0.9, 0, 0.8, 0)
	menu.Position = UDim2.new(0.5, 0, 0.5, 0)
	menu.AnchorPoint = Vector2.new(0.5, 0.5)
	menu.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	menu.BorderSizePixel = 0
	menu.Visible = false
	menu.Parent = self.UI.Content

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.02, 0)
	corner.Parent = menu

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0.1, 0)
	titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = menu

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0.02, 0)
	titleCorner.Parent = titleBar

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.8, 0, 1, 0)
	title.Position = UDim2.new(0.1, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = menuName
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansSemibold
	title.Parent = titleBar

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0.08, 0, 0.8, 0)
	closeButton.Position = UDim2.new(0.9, 0, 0.1, 0)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.SourceSansSemibold
	closeButton.Parent = titleBar

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0.5, 0)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		self:CloseActiveMenus()
	end)

	-- Content area
	local contentArea = Instance.new("ScrollingFrame")
	contentArea.Name = "ContentArea"
	contentArea.Size = UDim2.new(0.95, 0, 0.85, 0)
	contentArea.Position = UDim2.new(0.5, 0, 0.55, 0)
	contentArea.AnchorPoint = Vector2.new(0.5, 0.5)
	contentArea.BackgroundTransparency = 1
	contentArea.ScrollBarThickness = 6
	contentArea.Parent = menu

	return menu
end

-- Input Handling
function GameClient:SetupInputHandling()
	-- Pet collection via clicking
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self:HandlePetClick(input)
		elseif input.KeyCode == Enum.KeyCode.Escape then
			self:CloseActiveMenus()
		end
	end)
end

-- Updated raycast code to replace deprecated FilterType
-- Replace the old raycast code in GameClient.lua with this:

function GameClient:HandlePetClick(input)
	local camera = workspace.CurrentCamera
	local mousePos = input.Position

	local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
	local raycastParams = RaycastParams.new()

	-- FIXED: Use modern FilterType enum
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude  -- New method
	raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}

	local result = workspace:Raycast(ray.Origin, ray.Direction * 100, raycastParams)

	if result and result.Instance then
		local model = result.Instance
		while model and model.Parent and model.Parent ~= workspace do
			model = model.Parent
		end

		if model and model:IsA("Model") and model:GetAttribute("PetType") then
			-- Found a wild pet, try to collect it
			if self.RemoteEvents.CollectWildPet then
				self.RemoteEvents.CollectWildPet:FireServer(model)
			end
		end
	end
end

-- Alternative: If you want to include only specific instances (whitelist)
-- Use this version instead:

function GameClient:HandlePetClickWhitelist(input)
	local camera = workspace.CurrentCamera
	local mousePos = input.Position

	local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
	local raycastParams = RaycastParams.new()

	-- Include only pet models (whitelist approach)
	raycastParams.FilterType = Enum.RaycastFilterType.Include

	-- Find all pet containers to include in raycast
	local petContainers = {}
	local areasFolder = workspace:FindFirstChild("Areas")
	if areasFolder then
		for _, area in pairs(areasFolder:GetChildren()) do
			local petsFolder = area:FindFirstChild("Pets")
			if petsFolder then
				table.insert(petContainers, petsFolder)
			end
		end
	end

	raycastParams.FilterDescendantsInstances = petContainers

	local result = workspace:Raycast(ray.Origin, ray.Direction * 100, raycastParams)

	if result and result.Instance then
		local model = result.Instance
		while model and model.Parent and not model:GetAttribute("PetType") do
			model = model.Parent
		end

		if model and model:IsA("Model") and model:GetAttribute("PetType") then
			-- Found a wild pet, try to collect it
			if self.RemoteEvents.CollectWildPet then
				self.RemoteEvents.CollectWildPet:FireServer(model)
			end
		end
	end
end

-- Effects System
function GameClient:SetupEffects()
	-- Sound effects
	self.Sounds = {
		collect = self:CreateSound("rbxassetid://131961136", 0.5),
		purchase = self:CreateSound("rbxassetid://131961136", 0.3),
		notification = self:CreateSound("rbxassetid://131961136", 0.4)
	}
end

function GameClient:CreateSound(soundId, volume)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.5
	sound.Parent = self.UI.MainUI
	return sound
end

-- Event Handlers
function GameClient:HandlePlayerDataUpdate(newData)
	if not newData then return end

	local oldData = self.PlayerData
	self.PlayerData = newData

	-- Update currency display
	self:UpdateCurrencyDisplay()

	-- Refresh current menu if it's pets-related
	if self.CurrentMenu == "Pets" then
		self:RefreshPetsMenu()
	elseif self.CurrentMenu == "Shop" then
		self:RefreshShopMenu()
	end

	-- Check for significant changes to show notifications
	if oldData then
		local coinDiff = (newData.coins or 0) - (oldData.coins or 0)
		local gemDiff = (newData.gems or 0) - (oldData.gems or 0)

		if coinDiff > 0 then
			-- Coin gain (from selling pets, etc.)
			self:AnimateValueChange(
				self.UI.CoinsFrame and self.UI.CoinsFrame:FindFirstChild("Value"),
				oldData.coins or 0,
				newData.coins or 0
			)
		end

		if gemDiff > 0 then
			-- Gem gain
			self:AnimateValueChange(
				self.UI.GemsFrame and self.UI.GemsFrame:FindFirstChild("Value"),
				oldData.gems or 0, 
				newData.gems or 0
			)
		end
	end
end

function GameClient:HandlePetCollected(petData, coinsAwarded)
	-- Validate data first
	if not petData then
		warn("GameClient: HandlePetCollected called with nil petData")
		petData = {
			name = "Unknown Pet",
			type = "unknown",
			rarity = "Common"
		}
	end

	-- Ensure required fields exist
	petData.name = petData.name or petData.type or petData.id or "Pet"
	petData.rarity = petData.rarity or "Common"
	coinsAwarded = coinsAwarded or 0

	self:PlayCollectionEffect(petData)

	if self.Sounds.collect then
		self.Sounds.collect:Play()
	end

	self:ShowNotification("Pet Collected!", petData.name .. " (+" .. coinsAwarded .. " coins)", "success")

	print("GameClient: Collected " .. petData.name .. " for " .. coinsAwarded .. " coins")
end


function GameClient:HandleCurrencyUpdate(currencyData)
	for currency, amount in pairs(currencyData) do
		if self.PlayerData[currency:lower()] then
			self.PlayerData[currency:lower()] = amount
		end
	end
	self:UpdateCurrencyDisplay()
end

-- UI Updates
function GameClient:UpdateCurrencyDisplay()
	if not self.PlayerData then return end

	-- Update currency frames
	local coinsValue = self.UI.CoinsFrame and self.UI.CoinsFrame:FindFirstChild("Value")
	local gemsValue = self.UI.GemsFrame and self.UI.GemsFrame:FindFirstChild("Value")

	if coinsValue then
		local newAmount = self.PlayerData.coins or 0
		self:AnimateValueChange(coinsValue, tonumber(coinsValue.Text) or 0, newAmount)
	end

	if gemsValue then
		local newAmount = self.PlayerData.gems or 0  
		self:AnimateValueChange(gemsValue, tonumber(gemsValue.Text) or 0, newAmount)
	end
end

function GameClient:AnimateValueChange(textLabel, fromValue, toValue)
	if not textLabel then return end

	fromValue = tonumber(fromValue) or 0
	toValue = tonumber(toValue) or 0

	if fromValue == toValue then
		textLabel.Text = self:FormatNumber(toValue)
		return
	end

	-- Animate the value change
	local TweenService = game:GetService("TweenService")
	local steps = math.min(20, math.abs(toValue - fromValue))
	local stepSize = (toValue - fromValue) / steps

	spawn(function()
		for i = 1, steps do
			local currentValue = math.floor(fromValue + (stepSize * i))
			textLabel.Text = self:FormatNumber(currentValue)
			wait(0.02) -- Faster animation
		end
		textLabel.Text = self:FormatNumber(toValue)
	end)

	-- Add a slight scale animation for visual feedback
	local scaleInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local scaleTween = TweenService:Create(textLabel, scaleInfo, {
		TextSize = textLabel.TextSize * 1.2
	})

	scaleTween:Play()
	scaleTween.Completed:Connect(function()
		local returnTween = TweenService:Create(textLabel, scaleInfo, {
			TextSize = textLabel.TextSize / 1.2
		})
		returnTween:Play()
	end)
end

function GameClient:FormatNumber(number)
	if number >= 1000000000 then
		return string.format("%.1fB", number / 1000000000)
	elseif number >= 1000000 then
		return string.format("%.1fM", number / 1000000)
	elseif number >= 1000 then
		return string.format("%.1fK", number / 1000)
	else
		return tostring(math.floor(number))
	end
end

-- Menu Content Management
function GameClient:RefreshMenuContent(menuName)
	if menuName == "Pets" then
		self:RefreshPetsMenu()
	elseif menuName == "Shop" then
		self:RefreshShopMenu()
	elseif menuName == "Farm" then
		self:RefreshFarmMenu()
	elseif menuName == "Settings" then
		self:RefreshSettingsMenu()
	end
end

function GameClient:RefreshPetsMenu()
	local menu = self.UI.Menus and self.UI.Menus.Pets
	if not menu then 
		warn("GameClient: Pets menu not found")
		return 
	end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then 
		warn("GameClient: ContentArea not found in pets menu")
		return 
	end

	-- Clear existing content (but keep selling controls)
	for _, child in ipairs(contentArea:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "SellingControls" then
			child:Destroy()
		elseif child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end

	-- Check if player data exists and has pets
	if not self.PlayerData then
		local waitingLabel = Instance.new("TextLabel")
		waitingLabel.Size = UDim2.new(0.8, 0, 0.2, 0)
		waitingLabel.Position = UDim2.new(0.5, 0, 0.4, 0)
		waitingLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		waitingLabel.BackgroundTransparency = 1
		waitingLabel.Text = "Loading player data..."
		waitingLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
		waitingLabel.TextScaled = true
		waitingLabel.Font = Enum.Font.SourceSansSemibold
		waitingLabel.Parent = contentArea
		return
	end

	if not self.PlayerData.pets or not self.PlayerData.pets.owned or #self.PlayerData.pets.owned == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(0.8, 0, 0.2, 0)
		emptyLabel.Position = UDim2.new(0.5, 0, 0.4, 0)
		emptyLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "No pets collected yet!\nGo explore and click on wild pets to collect them!"
		emptyLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
		emptyLabel.TextScaled = true
		emptyLabel.Font = Enum.Font.SourceSansSemibold
		emptyLabel.Parent = contentArea

		-- Still show selling controls even with no pets
		if self.SellingMode and self.SellingMode.isActive then
			self:UpdateSellingUI()
		end
		return
	end

	-- Create grid for pets
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 150, 0, 200)
	gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	gridLayout.SortOrder = Enum.SortOrder.Name
	gridLayout.Parent = contentArea

	-- Add pets to grid with proper error handling
	for i, petData in ipairs(self.PlayerData.pets.owned) do
		-- Validate pet data
		if petData and petData.id then
			local isEquipped = self:IsPetEquipped(petData.id)

			local success, petCard = pcall(function()
				return self:CreatePetCard(petData, contentArea, i, isEquipped)
			end)

			if not success then
				warn("GameClient: Failed to create pet card for pet " .. (petData.id or "unknown") .. ": " .. tostring(petCard))
			end
		else
			warn("GameClient: Invalid pet data at index " .. i)
		end
	end

	-- Update canvas size
	spawn(function()
		wait(0.1)
		if gridLayout and gridLayout.Parent then
			contentArea.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
		end
	end)
	if self.SellingMode and self.SellingMode.isActive then
		self:UpdateSellingUI()
	end
end


function GameClient:IsPetEquipped(petId)
	if not self.PlayerData or not self.PlayerData.pets or not self.PlayerData.pets.equipped then
		return false
	end

	for _, equippedPet in ipairs(self.PlayerData.pets.equipped) do
		if equippedPet.id == petId then
			return true
		end
	end

	return false
end


function GameClient:CreateShopTabs(contentArea)
	local tabFrame = Instance.new("Frame")
	tabFrame.Name = "TabFrame"
	tabFrame.Size = UDim2.new(1, 0, 0.1, 0)
	tabFrame.BackgroundTransparency = 1
	tabFrame.Parent = contentArea

	local tabs = {"Seeds", "Upgrades", "Pets", "Premium"}
	local tabWidth = 1 / #tabs

	for i, tabName in ipairs(tabs) do
		local tab = Instance.new("TextButton")
		tab.Name = tabName .. "Tab"
		tab.Size = UDim2.new(tabWidth, 0, 1, 0)
		tab.Position = UDim2.new((i-1) * tabWidth, 0, 0, 0)
		tab.BackgroundColor3 = i == 1 and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(60, 60, 70)
		tab.BorderSizePixel = 0
		tab.Text = tabName
		tab.TextColor3 = Color3.new(1, 1, 1)
		tab.TextScaled = true
		tab.Font = Enum.Font.SourceSansSemibold
		tab.Parent = tabFrame

		tab.MouseButton1Click:Connect(function()
			self:SwitchShopTab(tabName, contentArea)
		end)
	end

	-- Show first tab by default
	self:SwitchShopTab("Seeds", contentArea)
end

function GameClient:SwitchShopTab(tabName, contentArea)
	if not contentArea then return end

	-- Update tab appearances
	local tabFrame = contentArea:FindFirstChild("TabFrame")
	if tabFrame then
		for _, tab in pairs(tabFrame:GetChildren()) do
			if tab:IsA("TextButton") then
				if tab.Name == tabName .. "Tab" then
					tab.BackgroundColor3 = Color3.fromRGB(0, 170, 255) -- Active
				else
					tab.BackgroundColor3 = Color3.fromRGB(60, 60, 70) -- Inactive
				end
			end
		end
	end

	-- Clear existing shop items
	for _, child in pairs(contentArea:GetChildren()) do
		if child:IsA("ScrollingFrame") and child.Name:match("Items$") then
			child:Destroy()
		end
	end

	-- Create items container
	local itemsContainer = Instance.new("ScrollingFrame")
	itemsContainer.Name = tabName .. "Items"
	itemsContainer.Size = UDim2.new(1, 0, 0.85, 0)
	itemsContainer.Position = UDim2.new(0, 0, 0.15, 0)
	itemsContainer.BackgroundTransparency = 1
	itemsContainer.ScrollBarThickness = 6
	itemsContainer.Parent = contentArea

	-- Create grid layout
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 180, 0, 220)
	gridLayout.CellPadding = UDim2.new(0, 15, 0, 15)
	gridLayout.SortOrder = Enum.SortOrder.Name
	gridLayout.Parent = itemsContainer

	-- Populate items based on tab
	if tabName == "Seeds" then
		self:PopulateSeedsTab(itemsContainer)
	elseif tabName == "Upgrades" then
		self:PopulateUpgradesTab(itemsContainer)
	elseif tabName == "Pets" then
		self:PopulatePetsTab(itemsContainer)
	elseif tabName == "Premium" then
		self:PopulatePremiumTab(itemsContainer)
	end

	-- Update canvas size
	spawn(function()
		wait(0.1)
		itemsContainer.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
	end)
end

-- Add method to populate seeds tab
function GameClient:PopulateSeedsTab(container)
	if not self.Cache.ShopItems then return end

	-- Filter for seed items
	local seedItems = {}
	for itemId, itemData in pairs(self.Cache.ShopItems) do
		if itemData.type == "seed" or itemId:find("_seeds") then
			seedItems[itemId] = itemData
		end
	end

	-- Create seed item cards
	for itemId, itemData in pairs(seedItems) do
		local itemCard = self:CreateShopItemCard(itemId, itemData)
		itemCard.Parent = container
	end

	-- If no seeds found, show message
	if next(seedItems) == nil then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 1, 0)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "No seeds available"
		emptyLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
		emptyLabel.TextScaled = true
		emptyLabel.Font = Enum.Font.SourceSansSemibold
		emptyLabel.Parent = container
	end
end

-- Add method to populate upgrades tab
function GameClient:PopulateUpgradesTab(container)
	if not self.Cache.ShopItems then return end

	-- Filter for upgrade items
	local upgradeItems = {}
	for itemId, itemData in pairs(self.Cache.ShopItems) do
		if itemData.type == "upgrade" then
			upgradeItems[itemId] = itemData
		end
	end

	-- Create upgrade item cards
	for itemId, itemData in pairs(upgradeItems) do
		local itemCard = self:CreateShopItemCard(itemId, itemData)
		itemCard.Parent = container
	end

	-- If no upgrades found, show message
	if next(upgradeItems) == nil then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 1, 0)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "No upgrades available"
		emptyLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
		emptyLabel.TextScaled = true
		emptyLabel.Font = Enum.Font.SourceSansSemibold
		emptyLabel.Parent = container
	end
end

-- Add method to populate pets tab  
function GameClient:PopulatePetsTab(container)
	if not self.Cache.ShopItems then return end

	-- Filter for pet items
	local petItems = {}
	for itemId, itemData in pairs(self.Cache.ShopItems) do
		if itemData.type == "egg" or itemData.type == "pet" then
			petItems[itemId] = itemData
		end
	end

	-- Create pet item cards
	for itemId, itemData in pairs(petItems) do
		local itemCard = self:CreateShopItemCard(itemId, itemData)
		itemCard.Parent = container
	end

	-- If no pets found, show message
	if next(petItems) == nil then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 1, 0)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "No pets available for purchase"
		emptyLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
		emptyLabel.TextScaled = true
		emptyLabel.Font = Enum.Font.SourceSansSemibold
		emptyLabel.Parent = container
	end
end

-- Add method to populate premium tab
function GameClient:PopulatePremiumTab(container)
	-- Create premium purchase options
	local premiumOptions = {
		{
			name = "Small Gem Pack",
			description = "100 Gems for quick purchases",
			price = "R$ 50",
			gems = 100,
			productId = 1234567
		},
		{
			name = "Medium Gem Pack", 
			description = "500 Gems + 50 bonus gems",
			price = "R$ 200",
			gems = 550,
			productId = 1234568
		},
		{
			name = "Large Gem Pack",
			description = "1000 Gems + 200 bonus gems", 
			price = "R$ 400",
			gems = 1200,
			productId = 1234569
		}
	}

	for i, option in ipairs(premiumOptions) do
		local premiumCard = self:CreatePremiumCard(option)
		premiumCard.LayoutOrder = i
		premiumCard.Parent = container
	end
end

-- Add method to create premium purchase cards
function GameClient:CreatePremiumCard(option)
	local card = Instance.new("Frame")
	card.Name = option.name:gsub(" ", "")
	card.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
	card.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.05, 0)
	corner.Parent = card

	-- Gem icon
	local gemIcon = Instance.new("TextLabel")
	gemIcon.Size = UDim2.new(0.8, 0, 0.3, 0)
	gemIcon.Position = UDim2.new(0.5, 0, 0.15, 0)
	gemIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	gemIcon.BackgroundTransparency = 1
	gemIcon.Text = "💎"
	gemIcon.TextScaled = true
	gemIcon.Font = Enum.Font.SourceSansSemibold
	gemIcon.Parent = card

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.9, 0, 0.15, 0)
	title.Position = UDim2.new(0.5, 0, 0.4, 0)
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.BackgroundTransparency = 1
	title.Text = option.name
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansSemibold
	title.Parent = card

	-- Description
	local description = Instance.new("TextLabel")
	description.Size = UDim2.new(0.9, 0, 0.2, 0)
	description.Position = UDim2.new(0.5, 0, 0.6, 0)
	description.AnchorPoint = Vector2.new(0.5, 0.5)
	description.BackgroundTransparency = 1
	description.Text = option.description
	description.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	description.TextScaled = true
	description.TextWrapped = true
	description.Font = Enum.Font.SourceSans
	description.Parent = card

	-- Buy button
	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(0.8, 0, 0.15, 0)
	buyButton.Position = UDim2.new(0.5, 0, 0.85, 0)
	buyButton.AnchorPoint = Vector2.new(0.5, 0.5)
	buyButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
	buyButton.BorderSizePixel = 0
	buyButton.Text = option.price
	buyButton.TextColor3 = Color3.new(1, 1, 1)
	buyButton.TextScaled = true
	buyButton.Font = Enum.Font.SourceSansSemibold
	buyButton.Parent = card

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0.2, 0)
	buttonCorner.Parent = buyButton

	-- Connect purchase
	buyButton.MouseButton1Click:Connect(function()
		-- In a real game, this would prompt a Robux purchase
		self:ShowNotification("Premium Purchase", "This would open Robux purchase for " .. option.name, "info")
	end)

	return card
end

-- Fix the existing CreateShopItemCard method to handle missing data
function GameClient:CreateShopItemCard(itemId, itemData)
	-- Ensure itemData exists
	if not itemData then
		warn("GameClient: No item data for " .. tostring(itemId))
		return Instance.new("Frame") -- Return empty frame to prevent errors
	end

	local card = Instance.new("Frame")
	card.Name = itemId .. "_Card"
	card.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
	card.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.05, 0)
	corner.Parent = card

	-- Item icon/emoji
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0.8, 0, 0.4, 0)
	icon.Position = UDim2.new(0.5, 0, 0.2, 0)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.Text = self:GetItemEmoji(itemData.type or "item")
	icon.TextScaled = true
	icon.Font = Enum.Font.SourceSansSemibold
	icon.Parent = card

	-- Item name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
	nameLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	nameLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = itemData.name or itemId
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansSemibold
	nameLabel.Parent = card

	-- Item description
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.9, 0, 0.2, 0)
	descLabel.Position = UDim2.new(0.5, 0, 0.65, 0)
	descLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = itemData.description or ""
	descLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	descLabel.TextScaled = true
	descLabel.TextWrapped = true
	descLabel.Font = Enum.Font.SourceSans
	descLabel.Parent = card

	-- Price and buy button
	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(0.8, 0, 0.12, 0)
	buyButton.Position = UDim2.new(0.5, 0, 0.88, 0)
	buyButton.AnchorPoint = Vector2.new(0.5, 0.5)
	buyButton.BorderSizePixel = 0
	buyButton.TextScaled = true
	buyButton.Font = Enum.Font.SourceSansSemibold
	buyButton.Parent = card

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0.2, 0)
	buttonCorner.Parent = buyButton

	-- Check if player can afford
	local canAfford = self:CanAffordItem(itemData)
	local priceText = (itemData.price or 0) .. " " .. (itemData.currency or "Coins")

	buyButton.Text = "Buy: " .. priceText
	buyButton.TextColor3 = Color3.new(1, 1, 1)
	buyButton.BackgroundColor3 = canAfford and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(100, 100, 100)
	buyButton.Active = canAfford

	if canAfford then
		buyButton.MouseButton1Click:Connect(function()
			if self.RemoteEvents.PurchaseItem then
				self.RemoteEvents.PurchaseItem:FireServer(itemId, 1)
			end
		end)
	end

	return card
end

-- Fix the RefreshShopMenu method
function GameClient:RefreshShopMenu()
	local menu = self.UI.Menus.Shop
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	-- Clear existing content
	for _, child in ipairs(contentArea:GetChildren()) do
		if child:IsA("Frame") or child:IsA("ScrollingFrame") or child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end

	-- Request shop items if we don't have them
	if not self.Cache.ShopItems or next(self.Cache.ShopItems) == nil then
		if self.RemoteFunctions.GetShopItems then
			local success, items = pcall(function()
				return self.RemoteFunctions.GetShopItems:InvokeServer()
			end)
			if success and items then
				self.Cache.ShopItems = items
			end
		end
	end

	if not self.Cache.ShopItems or next(self.Cache.ShopItems) == nil then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(0.8, 0, 0.2, 0)
		emptyLabel.Position = UDim2.new(0.5, 0, 0.4, 0)
		emptyLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "Shop items loading..."
		emptyLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
		emptyLabel.TextScaled = true
		emptyLabel.Font = Enum.Font.SourceSansSemibold
		emptyLabel.Parent = contentArea
		return
	end

	-- Create shop tabs
	self:CreateShopTabs(contentArea)
end

-- Farm Menu
function GameClient:RefreshFarmMenu()
	local menu = self.UI.Menus.Farm
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	-- Clear existing content
	for _, child in ipairs(contentArea:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Create farm interface
	local farmInfo = Instance.new("Frame")
	farmInfo.Name = "FarmInfo"
	farmInfo.Size = UDim2.new(1, 0, 0.3, 0)
	farmInfo.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	farmInfo.BorderSizePixel = 0
	farmInfo.Parent = contentArea

	local infoCorner = Instance.new("UICorner")
	infoCorner.CornerRadius = UDim.new(0.02, 0)
	infoCorner.Parent = farmInfo

	local farmTitle = Instance.new("TextLabel")
	farmTitle.Size = UDim2.new(1, 0, 0.3, 0)
	farmTitle.BackgroundTransparency = 1
	farmTitle.Text = "🌾 Your Farm"
	farmTitle.TextColor3 = Color3.new(1, 1, 1)
	farmTitle.TextScaled = true
	farmTitle.Font = Enum.Font.SourceSansSemibold
	farmTitle.Parent = farmInfo

	local farmDesc = Instance.new("TextLabel")
	farmDesc.Size = UDim2.new(0.9, 0, 0.7, 0)
	farmDesc.Position = UDim2.new(0.05, 0, 0.3, 0)
	farmDesc.BackgroundTransparency = 1
	farmDesc.Text = "Plant seeds, grow crops, and feed your pig!\nVisit your farm in the game world to interact with your plots."
	farmDesc.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	farmDesc.TextScaled = true
	farmDesc.TextWrapped = true
	farmDesc.Font = Enum.Font.SourceSans
	farmDesc.Parent = farmInfo

	-- Farming inventory
	local inventoryFrame = Instance.new("Frame")
	inventoryFrame.Name = "Inventory"
	inventoryFrame.Size = UDim2.new(1, 0, 0.65, 0)
	inventoryFrame.Position = UDim2.new(0, 0, 0.35, 0)
	inventoryFrame.BackgroundTransparency = 1
	inventoryFrame.Parent = contentArea

	local inventoryTitle = Instance.new("TextLabel")
	inventoryTitle.Size = UDim2.new(1, 0, 0.1, 0)
	inventoryTitle.BackgroundTransparency = 1
	inventoryTitle.Text = "Farming Inventory"
	inventoryTitle.TextColor3 = Color3.new(1, 1, 1)
	inventoryTitle.TextScaled = true
	inventoryTitle.Font = Enum.Font.SourceSansSemibold
	inventoryTitle.Parent = inventoryFrame

	-- Show farming inventory items
	if self.PlayerData.farming and self.PlayerData.farming.inventory then
		local yOffset = 0.15
		local itemHeight = 0.08

		for itemId, quantity in pairs(self.PlayerData.farming.inventory) do
			if quantity > 0 then
				local itemFrame = Instance.new("Frame")
				itemFrame.Size = UDim2.new(0.9, 0, itemHeight, 0)
				itemFrame.Position = UDim2.new(0.05, 0, yOffset, 0)
				itemFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
				itemFrame.BorderSizePixel = 0
				itemFrame.Parent = inventoryFrame

				local itemCorner = Instance.new("UICorner")
				itemCorner.CornerRadius = UDim.new(0.1, 0)
				itemCorner.Parent = itemFrame

				local itemLabel = Instance.new("TextLabel")
				itemLabel.Size = UDim2.new(0.8, 0, 1, 0)
				itemLabel.Position = UDim2.new(0.1, 0, 0, 0)
				itemLabel.BackgroundTransparency = 1
				itemLabel.Text = itemId:gsub("_", " "):gsub("^%l", string.upper) .. " x" .. quantity
				itemLabel.TextColor3 = Color3.new(1, 1, 1)
				itemLabel.TextScaled = true
				itemLabel.TextXAlignment = Enum.TextXAlignment.Left
				itemLabel.Font = Enum.Font.SourceSans
				itemLabel.Parent = itemFrame

				yOffset = yOffset + itemHeight + 0.02
			end
		end

		-- Pig status
		if self.PlayerData.farming.pig then
			local pig = self.PlayerData.farming.pig
			local pigFrame = Instance.new("Frame")
			pigFrame.Size = UDim2.new(0.9, 0, 0.15, 0)
			pigFrame.Position = UDim2.new(0.05, 0, yOffset + 0.05, 0)
			pigFrame.BackgroundColor3 = Color3.fromRGB(180, 120, 160)
			pigFrame.BorderSizePixel = 0
			pigFrame.Parent = inventoryFrame

			local pigCorner = Instance.new("UICorner")
			pigCorner.CornerRadius = UDim.new(0.05, 0)
			pigCorner.Parent = pigFrame

			local pigTitle = Instance.new("TextLabel")
			pigTitle.Size = UDim2.new(1, 0, 0.4, 0)
			pigTitle.BackgroundTransparency = 1
			pigTitle.Text = "🐷 Your Pig"
			pigTitle.TextColor3 = Color3.new(1, 1, 1)
			pigTitle.TextScaled = true
			pigTitle.Font = Enum.Font.SourceSansSemibold
			pigTitle.Parent = pigFrame

			local pigStatus = Instance.new("TextLabel")
			pigStatus.Size = UDim2.new(0.9, 0, 0.6, 0)
			pigStatus.Position = UDim2.new(0.05, 0, 0.4, 0)
			pigStatus.BackgroundTransparency = 1
			pigStatus.Text = "Fed: " .. (pig.feedCount or 0) .. " times | Size: " .. string.format("%.1f", pig.size or 1) .. "x"
			pigStatus.TextColor3 = Color3.new(0.9, 0.9, 0.9)
			pigStatus.TextScaled = true
			pigStatus.Font = Enum.Font.SourceSans
			pigStatus.Parent = pigFrame
		end
	else
		local noItemsLabel = Instance.new("TextLabel")
		noItemsLabel.Size = UDim2.new(0.8, 0, 0.3, 0)
		noItemsLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
		noItemsLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		noItemsLabel.BackgroundTransparency = 1
		noItemsLabel.Text = "No farming items yet!\nBuy seeds from the shop to get started."
		noItemsLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
		noItemsLabel.TextScaled = true
		noItemsLabel.TextWrapped = true
		noItemsLabel.Font = Enum.Font.SourceSans
		noItemsLabel.Parent = inventoryFrame
	end
end

-- Settings Menu
function GameClient:RefreshSettingsMenu()
	local menu = self.UI.Menus.Settings
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	-- Clear existing content
	for _, child in ipairs(contentArea:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Simple settings for now
	local settingsLabel = Instance.new("TextLabel")
	settingsLabel.Size = UDim2.new(0.8, 0, 0.3, 0)
	settingsLabel.Position = UDim2.new(0.5, 0, 0.4, 0)
	settingsLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	settingsLabel.BackgroundTransparency = 1
	settingsLabel.Text = "⚙️ Settings\n\nMore settings coming soon!"
	settingsLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	settingsLabel.TextScaled = true
	settingsLabel.Font = Enum.Font.SourceSansSemibold
	settingsLabel.Parent = contentArea
end

-- Effects and Notifications
function GameClient:PlayCollectionEffect(petData)
	-- Simple collection effect
	local character = LocalPlayer.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Create floating text effect
	local effectGui = Instance.new("BillboardGui")
	effectGui.Size = UDim2.new(0, 200, 0, 100)
	effectGui.StudsOffset = Vector3.new(0, 5, 0)
	effectGui.Parent = rootPart

	local effectLabel = Instance.new("TextLabel")
	effectLabel.Size = UDim2.new(1, 0, 1, 0)
	effectLabel.BackgroundTransparency = 1

	-- Animate floating effect
	local petName = "Pet"
	if petData then
		petName = petData.name or petData.type or petData.id or "Pet"
	end
	effectLabel.Text = "+" .. petName

	effectLabel.TextColor3 = self:GetRarityColor(petData and petData.rarity or "Common")
	effectLabel.TextScaled = true
	effectLabel.Font = Enum.Font.SourceSansSemibold
	effectLabel.Parent = effectGui

	-- Animate floating effect
	local tween = TweenService:Create(effectGui, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffset = Vector3.new(0, 10, 0)
	})

	local fadeTween = TweenService:Create(effectLabel, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 1
	})

	tween:Play()
	fadeTween:Play()

	tween.Completed:Connect(function()
		effectGui:Destroy()
	end)
end
function GameClient:CreateCollectionEffect(position)
	local TweenService = game:GetService("TweenService")
	local SoundService = game:GetService("SoundService")

	-- Create sparkle effect
	local effect = Instance.new("Part")
	effect.Name = "CollectionEffect"
	effect.Size = Vector3.new(1, 1, 1)
	effect.Position = position
	effect.Shape = Enum.PartType.Ball
	effect.Material = Enum.Material.Neon
	effect.Color = Color3.fromRGB(255, 255, 0)
	effect.CanCollide = false
	effect.Anchored = true
	effect.Parent = workspace

	-- Create multiple sparkles
	for i = 1, 8 do
		local sparkle = effect:Clone()
		sparkle.Size = Vector3.new(0.2, 0.2, 0.2)
		sparkle.Color = Color3.fromRGB(
			math.random(200, 255),
			math.random(200, 255),
			math.random(100, 255)
		)
		sparkle.Parent = workspace

		-- Random direction for sparkles
		local angle = (i / 8) * math.pi * 2
		local distance = math.random(2, 5)
		local targetPos = position + Vector3.new(
			math.cos(angle) * distance,
			math.random(2, 4),
			math.sin(angle) * distance
		)

		-- Animate sparkle
		local sparkleTween = TweenService:Create(sparkle,
			TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = targetPos,
				Size = Vector3.new(0.05, 0.05, 0.05),
				Transparency = 1
			}
		)

		sparkleTween:Play()
		sparkleTween.Completed:Connect(function()
			sparkle:Destroy()
		end)
	end

	-- Main effect animation
	local mainTween = TweenService:Create(effect,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			Size = Vector3.new(3, 3, 3),
			Transparency = 1
		}
	)

	mainTween:Play()
	mainTween.Completed:Connect(function()
		effect:Destroy()
	end)

	-- FIXED: Use a working sound ID or default Roblox sound
	local sound = Instance.new("Sound")
	-- Using a default Roblox pickup sound that should work
	sound.SoundId = "rbxasset://sounds/electronicpingsharp.wav" -- Default Roblox sound
	sound.Volume = 0.3
	sound.Pitch = 1.2 -- Higher pitch for collection
	sound.Parent = workspace

	-- Try to play the sound with error handling
	local success, err = pcall(function()
		sound:Play()
	end)

	if not success then
		warn("Failed to play collection sound: " .. tostring(err))
	end

	-- Clean up sound
	spawn(function()
		wait(2)
		if sound and sound.Parent then
			sound:Destroy()
		end
	end)
end

function GameClient:ShowNotification(title, message, notificationType)
	notificationType = notificationType or "info"

	print("Notification [" .. notificationType:upper() .. "]: " .. title .. " - " .. message)

	-- Create notification UI
	local notificationFrame = Instance.new("Frame")
	notificationFrame.Size = UDim2.new(0, 300, 0, 80)
	notificationFrame.Position = UDim2.new(1, -320, 0, 20)
	notificationFrame.BackgroundColor3 = self:GetNotificationColor(notificationType)
	notificationFrame.BorderSizePixel = 0
	notificationFrame.Parent = self.UI.NotificationArea or self.UI.MainFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.1, 0)
	corner.Parent = notificationFrame

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -10, 0.4, 0)
	titleLabel.Position = UDim2.new(0, 5, 0, 5)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.SourceSansSemibold
	titleLabel.Parent = notificationFrame

	-- Message
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Size = UDim2.new(1, -10, 0.5, 0)
	messageLabel.Position = UDim2.new(0, 5, 0.4, 0)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = message
	messageLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	messageLabel.TextScaled = true
	messageLabel.TextWrapped = true
	messageLabel.Font = Enum.Font.SourceSans
	messageLabel.Parent = notificationFrame

	-- Animate in
	local TweenService = game:GetService("TweenService")
	local slideIn = TweenService:Create(notificationFrame, 
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(1, -320, 0, 20)}
	)

	notificationFrame.Position = UDim2.new(1, 0, 0, 20)
	slideIn:Play()

	-- Auto-remove after 3 seconds
	spawn(function()
		wait(3)
		local slideOut = TweenService:Create(notificationFrame,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Position = UDim2.new(1, 0, 0, 20)}
		)
		slideOut:Play()
		slideOut.Completed:Connect(function()
			notificationFrame:Destroy()
		end)
	end)
end

-- Add the missing GetNotificationColor method
function GameClient:GetNotificationColor(notificationType)
	local colors = {
		success = Color3.fromRGB(40, 167, 69),
		error = Color3.fromRGB(220, 53, 69),
		warning = Color3.fromRGB(255, 193, 7),
		info = Color3.fromRGB(23, 162, 184)
	}

	return colors[notificationType] or colors.info
end

-- Data Management
function GameClient:RequestInitialData()
	-- Request player data
	if self.RemoteFunctions.GetPlayerData then
		spawn(function()
			local success, data = pcall(function()
				return self.RemoteFunctions.GetPlayerData:InvokeServer()
			end)
			if success and data then
				self:HandlePlayerDataUpdate(data)
			end
		end)
	end

	-- Request shop items
	if self.RemoteFunctions.GetShopItems then
		spawn(function()
			local success, items = pcall(function()
				return self.RemoteFunctions.GetShopItems:InvokeServer()
			end)
			if success and items then
				self.Cache.ShopItems = items
			end
		end)
	end
end

function GameClient:UpdateActiveMenus()
	-- Refresh currently open menu
	if self.UIState.CurrentPage then
		self:RefreshMenuContent(self.UIState.CurrentPage)
	end
end

-- Public API Methods
function GameClient:OpenShop()
	self:OpenMenu("Shop")
end

function GameClient:OpenPets()
	self:OpenMenu("Pets")
end

function GameClient:OpenFarm()
	self:OpenMenu("Farm")
end

function GameClient:GetPlayerData()
	return self.PlayerData
end

function GameClient:GetPlayerCurrency(currencyType)
	if not self.PlayerData then return 0 end
	return self.PlayerData[currencyType:lower()] or 0
end

-- Make globally available
_G.GameClient = GameClient

return GameClient