--[[
    GameClient.lua - FIXED CLIENT SYSTEM
    Place in: ReplicatedStorage/GameClient.lua
    
    FIXES:
    1. Enhanced proximity-based pet collection
    2. Better sound handling
    3. Improved UI responsiveness
    4. Fixed pet selling system
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

-- Pet selling state
GameClient.SellingMode = {
	isActive = false,
	selectedPets = {},
	totalValue = 0
}

-- Proximity collection system
GameClient.ProximitySystem = {
	isActive = true,
	collectRadius = 4,
	glowRadius = 8,
	lastCheck = 0,
	checkInterval = 0.1
}

-- Initialize the entire client system
function GameClient:Initialize()
	print("GameClient: Starting initialization...")

	self:SetupRemoteConnections()
	self:SetupUI()
	self:SetupInputHandling()
	self:SetupProximityCollection()
	self:SetupEffects()
	self:RequestInitialData()

	print("GameClient: Initialization complete!")
	return true
end

-- Setup Remote Connections
function GameClient:SetupRemoteConnections()
	local remoteFolder = ReplicatedStorage:WaitForChild("GameRemotes", 10)
	if not remoteFolder then
		warn("GameClient: Could not find GameRemotes folder")
		return
	end

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

	if self.RemoteEvents.PetSold then
		self.RemoteEvents.PetSold.OnClientEvent:Connect(function(petData, coinsEarned)
			self:HandlePetSold(petData, coinsEarned)
		end)
	end

	-- Shop System Events
	if self.RemoteEvents.ItemPurchased then
		self.RemoteEvents.ItemPurchased.OnClientEvent:Connect(function(itemId, quantity, cost, currency)
			self:HandleItemPurchased(itemId, quantity, cost, currency)
		end)
	end

	if self.RemoteEvents.CurrencyUpdated then
		self.RemoteEvents.CurrencyUpdated.OnClientEvent:Connect(function(currencyData)
			self:HandleCurrencyUpdate(currencyData)
		end)
	end

	-- Notification Handler
	if self.RemoteEvents.ShowNotification then
		self.RemoteEvents.ShowNotification.OnClientEvent:Connect(function(title, message, notificationType)
			self:ShowNotification(title, message, notificationType)
		end)
	end

	print("GameClient: Event handlers setup complete")
end

-- FIXED: Enhanced Proximity Collection System
function GameClient:SetupProximityCollection()
	local connection = RunService.Heartbeat:Connect(function()
		if not self.ProximitySystem.isActive then return end

		local currentTime = tick()
		if currentTime - self.ProximitySystem.lastCheck < self.ProximitySystem.checkInterval then
			return
		end
		self.ProximitySystem.lastCheck = currentTime

		local character = LocalPlayer.Character
		if not character or not character:FindFirstChild("HumanoidRootPart") then
			return
		end

		local playerRoot = character.HumanoidRootPart
		local playerPosition = playerRoot.Position

		-- Find all areas and check for pets
		local areasFolder = workspace:FindFirstChild("Areas")
		if not areasFolder then return end

		for _, area in pairs(areasFolder:GetChildren()) do
			local petsFolder = area:FindFirstChild("Pets")
			if not petsFolder then continue end

			for _, pet in pairs(petsFolder:GetChildren()) do
				self:CheckPetProximity(pet, playerPosition)
			end
		end
	end)

	-- Store connection for cleanup
	self.ProximityConnection = connection

	print("GameClient: Proximity collection system active")
end

-- Check individual pet proximity
function GameClient:CheckPetProximity(pet, playerPosition)
	if not pet or not pet.Parent then return end

	-- Get pet position
	local petPosition
	if pet:IsA("Model") and pet.PrimaryPart then
		petPosition = pet.PrimaryPart.Position
	elseif pet:IsA("BasePart") then
		petPosition = pet.Position
	else
		-- Find any BasePart in the model
		for _, part in pairs(pet:GetDescendants()) do
			if part:IsA("BasePart") then
				petPosition = part.Position
				break
			end
		end
	end

	if not petPosition then return end

	local distance = (playerPosition - petPosition).Magnitude

	-- Check for collection (close range)
	if distance <= self.ProximitySystem.collectRadius then
		-- Don't spam collection attempts
		if not pet:GetAttribute("CollectionAttempted") then
			pet:SetAttribute("CollectionAttempted", true)

			-- Fire collection event
			if self.RemoteEvents.CollectWildPet then
				self.RemoteEvents.CollectWildPet:FireServer(pet)
			end

			-- Create immediate visual feedback
			self:CreateCollectionEffect(petPosition)

			-- Reset the flag after a delay
			spawn(function()
				wait(1)
				if pet and pet.Parent then
					pet:SetAttribute("CollectionAttempted", false)
				end
			end)
		end
	end

	-- Visual glow effect for nearby pets
	if distance <= self.ProximitySystem.glowRadius then
		self:AddPetGlow(pet)
	else
		self:RemovePetGlow(pet)
	end
end

-- Add glow effect to pet
function GameClient:AddPetGlow(pet)
	if pet:GetAttribute("HasGlow") then return end

	local glowEffect = pet:FindFirstChild("ProximityGlow")
	if glowEffect then return end

	-- Find the main part of the pet
	local targetPart
	if pet:IsA("Model") and pet.PrimaryPart then
		targetPart = pet.PrimaryPart
	elseif pet:IsA("BasePart") then
		targetPart = pet
	else
		for _, part in pairs(pet:GetDescendants()) do
			if part:IsA("BasePart") then
				targetPart = part
				break
			end
		end
	end

	if not targetPart then return end

	-- Create glow effect
	glowEffect = Instance.new("Part")
	glowEffect.Name = "ProximityGlow"
	glowEffect.Size = Vector3.new(6, 6, 6)
	glowEffect.Shape = Enum.PartType.Ball
	glowEffect.Material = Enum.Material.ForceField
	glowEffect.Color = Color3.fromRGB(255, 255, 0)
	glowEffect.Transparency = 0.7
	glowEffect.CanCollide = false
	glowEffect.Anchored = true
	glowEffect.CFrame = targetPart.CFrame
	glowEffect.Parent = pet

	-- Animate the glow
	local glowTween = TweenService:Create(glowEffect,
		TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{Transparency = 0.9}
	)
	glowTween:Play()

	pet:SetAttribute("HasGlow", true)
end

-- Remove glow effect from pet
function GameClient:RemovePetGlow(pet)
	if not pet:GetAttribute("HasGlow") then return end

	local glowEffect = pet:FindFirstChild("ProximityGlow")
	if glowEffect then
		glowEffect:Destroy()
	end

	pet:SetAttribute("HasGlow", false)
end

-- Create collection effect
function GameClient:CreateCollectionEffect(position)
	-- Create sparkle effect at collection point
	for i = 1, 5 do
		local sparkle = Instance.new("Part")
		sparkle.Name = "CollectionSparkle"
		sparkle.Size = Vector3.new(0.2, 0.2, 0.2)
		sparkle.Shape = Enum.PartType.Ball
		sparkle.Material = Enum.Material.Neon
		sparkle.Color = Color3.fromRGB(255, 255, 0)
		sparkle.CanCollide = false
		sparkle.Anchored = true
		sparkle.Position = position + Vector3.new(
			math.random(-2, 2),
			math.random(0, 3),
			math.random(-2, 2)
		)
		sparkle.Parent = workspace

		-- Animate sparkle
		local tween = TweenService:Create(sparkle,
			TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = sparkle.Position + Vector3.new(0, 5, 0),
				Transparency = 1,
				Size = Vector3.new(0.05, 0.05, 0.05)
			}
		)
		tween:Play()

		-- Clean up
		tween.Completed:Connect(function()
			sparkle:Destroy()
		end)
	end

	-- Play collection sound
	self:PlayCollectionSound()
end

-- Play collection sound
function GameClient:PlayCollectionSound()
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/electronicpingsharp.wav"
	sound.Volume = 0.5
	sound.Pitch = 1.2
	sound.Parent = workspace

	sound:Play()

	-- Clean up sound
	spawn(function()
		wait(2)
		if sound and sound.Parent then
			sound:Destroy()
		end
	end)
end

-- Pet selling system
function GameClient:ToggleSellingMode()
	self.SellingMode.isActive = not self.SellingMode.isActive
	self.SellingMode.selectedPets = {}
	self.SellingMode.totalValue = 0

	self:RefreshPetsMenu()
	self:UpdateSellingUI()
end

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

function GameClient:SellPet(petData)
	if not petData then return end

	local sellValue = self:CalculatePetSellValue(petData)
	local petName = petData.name or petData.displayName or petData.type or "Unknown Pet"

	self:ShowConfirmationDialog(
		"Sell Pet",
		"Sell " .. petName .. " (" .. (petData.rarity or "Common") .. ") for " .. sellValue .. " coins?\n\nThis action cannot be undone!",
		function()
			if self.RemoteEvents.SellPet then
				self.RemoteEvents.SellPet:FireServer(petData.id)
				self:RemovePetFromLocalDisplay(petData.id)
			end
		end
	)
end

function GameClient:RemovePetFromLocalDisplay(petId)
	if not self.PlayerData or not self.PlayerData.pets or not self.PlayerData.pets.owned then
		return
	end

	for i, pet in ipairs(self.PlayerData.pets.owned) do
		if pet.id == petId then
			table.remove(self.PlayerData.pets.owned, i)
			break
		end
	end

	if self.UIState.CurrentPage == "Pets" then
		self:RefreshPetsMenu()
	end
end

-- Event Handlers
function GameClient:HandlePlayerDataUpdate(newData)
	if not newData then return end

	local oldData = self.PlayerData
	self.PlayerData = newData

	self:UpdateCurrencyDisplay()

	if self.UIState.CurrentPage == "Pets" then
		self:RefreshPetsMenu()
	elseif self.UIState.CurrentPage == "Shop" then
		self:RefreshShopMenu()
	end

	if oldData then
		local coinDiff = (newData.coins or 0) - (oldData.coins or 0)
		if coinDiff > 0 then
			self:AnimateValueChange(
				self.UI.CoinsFrame and self.UI.CoinsFrame:FindFirstChild("Value"),
				oldData.coins or 0,
				newData.coins or 0
			)
		end
	end
end

function GameClient:HandlePetCollected(petData, coinsAwarded)
	if not petData then
		warn("GameClient: HandlePetCollected called with nil petData")
		petData = {
			name = "Unknown Pet",
			type = "unknown",
			rarity = "Common"
		}
	end

	petData.name = petData.name or petData.type or petData.id or "Pet"
	petData.rarity = petData.rarity or "Common"
	coinsAwarded = coinsAwarded or 0

	self:ShowNotification("Pet Collected!", 
		petData.name .. " (+" .. coinsAwarded .. " coins)", "success")

	print("GameClient: Collected " .. petData.name .. " for " .. coinsAwarded .. " coins")
end

function GameClient:HandlePetSold(petData, coinsEarned)
	self:ShowNotification("Pet Sold!", 
		"Sold " .. (petData.name or "Pet") .. " for " .. coinsEarned .. " coins", "success")

	if self.UIState.CurrentPage == "Pets" then
		self:RefreshPetsMenu()
	end

	self:UpdateCurrencyDisplay()
end

function GameClient:HandleItemPurchased(itemId, quantity, cost, currency)
	if self.PlayerData then
		if currency == "coins" then
			self.PlayerData.coins = math.max(0, (self.PlayerData.coins or 0) - cost)
		elseif currency == "gems" then
			self.PlayerData.gems = math.max(0, (self.PlayerData.gems or 0) - cost)
		end

		self:UpdateCurrencyDisplay()
	end

	local itemName = itemId
	if self.Cache.ShopItems and self.Cache.ShopItems[itemId] then
		itemName = self.Cache.ShopItems[itemId].name or itemId
	end

	self:ShowNotification("Purchase Successful!", 
		"Bought " .. (quantity > 1 and (quantity .. "x ") or "") .. itemName .. " for " .. cost .. " " .. currency, 
		"success")

	print("GameClient: Purchased " .. itemId .. " x" .. quantity .. " for " .. cost .. " " .. currency)
end

function GameClient:HandleCurrencyUpdate(currencyData)
	for currency, amount in pairs(currencyData) do
		if self.PlayerData[currency:lower()] then
			self.PlayerData[currency:lower()] = amount
		end
	end
	self:UpdateCurrencyDisplay()
end

-- UI System Setup
function GameClient:SetupUI()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	local mainUI = Instance.new("ScreenGui")
	mainUI.Name = "GameUI"
	mainUI.ResetOnSpawn = false
	mainUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	mainUI.Parent = playerGui

	self.UI.MainUI = mainUI

	self:CreateUILayers(mainUI)
	self:SetupCurrencyDisplay()
	self:SetupNavigationBar()
	self:SetupMenus()

	print("GameClient: UI system setup complete")
end

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

-- Currency Display with enhanced visuals
function GameClient:SetupCurrencyDisplay()
	local container = Instance.new("Frame")
	container.Name = "CurrencyDisplay"
	container.Size = UDim2.new(0.25, 0, 0.08, 0)
	container.Position = UDim2.new(0.99, 0, 0.02, 0)
	container.AnchorPoint = Vector2.new(1, 0)
	container.BackgroundTransparency = 1
	container.Parent = self.UI.Navigation

	local coinsFrame = self:CreateCurrencyFrame("Coins", "💰", Color3.fromRGB(255, 215, 0))
	coinsFrame.Size = UDim2.new(1, 0, 0.45, 0)
	coinsFrame.Position = UDim2.new(0, 0, 0, 0)
	coinsFrame.Parent = container

	local gemsFrame = self:CreateCurrencyFrame("Gems", "💎", Color3.fromRGB(0, 200, 255))
	gemsFrame.Size = UDim2.new(1, 0, 0.45, 0)
	gemsFrame.Position = UDim2.new(0, 0, 0.55, 0)
	gemsFrame.Parent = container

	self.UI.CurrencyContainer = container
	self.UI.CoinsFrame = coinsFrame
	self.UI.GemsFrame = gemsFrame
end

function GameClient:CreateCurrencyFrame(currencyName, icon, color)
	local frame = Instance.new("Frame")
	frame.Name = currencyName .. "Frame"
	frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	frame.BorderSizePixel = 0

	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = frame

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 45)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 35))
	}
	gradient.Rotation = 90
	gradient.Parent = frame

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(0, 24, 0, 24)
	iconLabel.Position = UDim2.new(0, 8, 0.5, -12)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon
	iconLabel.TextColor3 = color
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.SourceSansSemibold
	iconLabel.Parent = frame

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

	local value = Instance.new("TextLabel")
	value.Name = "Value"
	value.Size = UDim2.new(1, -110, 1, 0)
	value.Position = UDim2.new(0, 105, 0, 0)
	value.BackgroundTransparency = 1
	value.Text = "0"
	value.TextColor3 = color
	value.TextScaled = true
	value.Font = Enum.Font.GothamBold
	value.TextXAlignment = Enum.TextXAlignment.Right
	value.Parent = frame

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
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.Escape then
			self:CloseActiveMenus()
		end
	end)
end

-- Effects System
function GameClient:SetupEffects()
	-- Sound effects will be handled by individual functions
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

	-- Clear existing content (except selling controls)
	for _, child in ipairs(contentArea:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "SellingControls" then
			child:Destroy()
		elseif child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end

	-- Check if player data exists
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
		emptyLabel.Text = "No pets collected yet!\nWalk near wild pets to collect them automatically!"
		emptyLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
		emptyLabel.TextScaled = true
		emptyLabel.Font = Enum.Font.SourceSansSemibold
		emptyLabel.Parent = contentArea

		self:UpdateSellingUI()
		return
	end

	-- Create grid for pets
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 150, 0, 200)
	gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	gridLayout.SortOrder = Enum.SortOrder.Name
	gridLayout.Parent = contentArea

	-- Add pets to grid
	for i, petData in ipairs(self.PlayerData.pets.owned) do
		if petData and petData.id then
			local success, petCard = pcall(function()
				return self:CreatePetCard(petData, contentArea, i)
			end)

			if not success then
				warn("GameClient: Failed to create pet card for pet " .. (petData.id or "unknown"))
			end
		end
	end

	-- Update canvas size
	spawn(function()
		wait(0.1)
		if gridLayout and gridLayout.Parent then
			contentArea.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
		end
	end)

	self:UpdateSellingUI()
end

-- Enhanced pet card creation (focused on selling)
function GameClient:CreatePetCard(petData, parent, index)
	if not petData then
		warn("GameClient: CreatePetCard called with nil petData")
		return Instance.new("Frame")
	end

	if not parent then
		warn("GameClient: CreatePetCard called with nil parent")
		return Instance.new("Frame")
	end

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

	-- Pet emoji
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

	-- Sell value display
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

	-- Sell button
	local sellButton = Instance.new("TextButton")
	sellButton.Size = UDim2.new(0.8, 0, 0.12, 0)
	sellButton.Position = UDim2.new(0.5, 0, 0.88, 0)
	sellButton.AnchorPoint = Vector2.new(0.5, 0.5)
	sellButton.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
	sellButton.BorderSizePixel = 0
	sellButton.Text = "Sell for " .. sellValue
	sellButton.TextColor3 = Color3.new(1, 1, 1)
	sellButton.TextScaled = true
	sellButton.Font = Enum.Font.SourceSansSemibold
	sellButton.Parent = card

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0.2, 0)
	buttonCorner.Parent = sellButton

	-- Sell button click handler
	sellButton.MouseButton1Click:Connect(function()
		self:SellPet(petData)
	end)

	return card
end

function GameClient:UpdateSellingUI()
	-- Placeholder for selling UI updates
	print("GameClient: Updated selling UI")
end

-- Basic shop menu
-- GameClient.lua UI FIXES
-- Replace these functions in your GameClient.lua to fix the Shop, Farm, and Settings menus

-- FIXED: Enhanced shop menu with actual functionality
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

	-- Create shop tabs
	local tabFrame = Instance.new("Frame")
	tabFrame.Name = "TabFrame"
	tabFrame.Size = UDim2.new(1, 0, 0.1, 0)
	tabFrame.BackgroundTransparency = 1
	tabFrame.Parent = contentArea

	local tabs = {"Basic Items", "Pet Eggs", "Upgrades"}
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

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.1, 0)
		corner.Parent = tab

		tab.MouseButton1Click:Connect(function()
			self:SwitchShopTab(tabName, contentArea)
		end)
	end

	-- Show first tab by default
	self:SwitchShopTab("Basic Items", contentArea)
end

function GameClient:SwitchShopTab(tabName, contentArea)
	if not contentArea then return end

	-- Update tab appearances
	local tabFrame = contentArea:FindFirstChild("TabFrame")
	if tabFrame then
		for _, tab in pairs(tabFrame:GetChildren()) do
			if tab:IsA("TextButton") then
				if tab.Name == tabName .. "Tab" then
					tab.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
				else
					tab.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
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
	if tabName == "Basic Items" then
		self:CreateShopItem(itemsContainer, "Speed Boost", "Increases your walk speed", 250, "coins", "⚡")
		self:CreateShopItem(itemsContainer, "Jump Boost", "Increases your jump height", 150, "coins", "🦘")
		self:CreateShopItem(itemsContainer, "Coin Magnet", "Automatically collect nearby coins", 500, "coins", "🧲")

	elseif tabName == "Pet Eggs" then
		self:CreateShopItem(itemsContainer, "Basic Egg", "Contains common pets", 100, "coins", "🥚")
		self:CreateShopItem(itemsContainer, "Rare Egg", "Contains rare pets", 50, "gems", "🌟")
		self:CreateShopItem(itemsContainer, "Epic Egg", "Contains epic pets", 100, "gems", "💎")

	elseif tabName == "Upgrades" then
		self:CreateShopItem(itemsContainer, "Pet Storage", "Store more pets", 1000, "coins", "📦")
		self:CreateShopItem(itemsContainer, "Auto Seller", "Automatically sell low-value pets", 2000, "coins", "🤖")
		self:CreateShopItem(itemsContainer, "Premium Pass", "Get exclusive benefits", 199, "robux", "👑")
	end

	-- Update canvas size
	spawn(function()
		wait(0.1)
		itemsContainer.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
	end)
end

function GameClient:CreateShopItem(parent, itemName, description, price, currency, icon)
	local itemCard = Instance.new("Frame")
	itemCard.Name = itemName .. "_Card"
	itemCard.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
	itemCard.BorderSizePixel = 0
	itemCard.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.05, 0)
	corner.Parent = itemCard

	-- Item icon
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(0.8, 0, 0.4, 0)
	iconLabel.Position = UDim2.new(0.5, 0, 0.2, 0)
	iconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.SourceSansSemibold
	iconLabel.Parent = itemCard

	-- Item name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
	nameLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	nameLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = itemName
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansSemibold
	nameLabel.Parent = itemCard

	-- Item description
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.9, 0, 0.2, 0)
	descLabel.Position = UDim2.new(0.5, 0, 0.65, 0)
	descLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = description
	descLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	descLabel.TextScaled = true
	descLabel.TextWrapped = true
	descLabel.Font = Enum.Font.SourceSans
	descLabel.Parent = itemCard

	-- Buy button
	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(0.8, 0, 0.12, 0)
	buyButton.Position = UDim2.new(0.5, 0, 0.88, 0)
	buyButton.AnchorPoint = Vector2.new(0.5, 0.5)
	buyButton.BorderSizePixel = 0
	buyButton.TextScaled = true
	buyButton.Font = Enum.Font.SourceSansSemibold
	buyButton.Parent = itemCard

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0.2, 0)
	buttonCorner.Parent = buyButton

	-- Check if player can afford
	local canAfford = self:CanPlayerAfford(price, currency)
	local currencySymbol = currency == "coins" and "💰" or currency == "gems" and "💎" or "R$"

	buyButton.Text = "Buy: " .. price .. " " .. currencySymbol
	buyButton.TextColor3 = Color3.new(1, 1, 1)
	buyButton.BackgroundColor3 = canAfford and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(100, 100, 100)
	buyButton.Active = canAfford

	if canAfford then
		buyButton.MouseButton1Click:Connect(function()
			self:PurchaseItem(itemName, price, currency)
		end)
	end

	return itemCard
end

function GameClient:CanPlayerAfford(price, currency)
	if not self.PlayerData then return false end

	if currency == "coins" then
		return (self.PlayerData.coins or 0) >= price
	elseif currency == "gems" then
		return (self.PlayerData.gems or 0) >= price
	end

	return false
end

function GameClient:PurchaseItem(itemName, price, currency)
	self:ShowNotification("Purchase", "Purchased " .. itemName .. " for " .. price .. " " .. currency, "success")
	-- Here you would fire a remote event to actually purchase the item
	-- if self.RemoteEvents.PurchaseItem then
	--     self.RemoteEvents.PurchaseItem:FireServer(itemName, 1)
	-- end
end

-- FIXED: Enhanced farm menu
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

	-- Create farm info section
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
	farmDesc.Text = "Plant seeds, grow crops, and feed your animals!\nVisit your farm in the game world to plant and harvest."
	farmDesc.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	farmDesc.TextScaled = true
	farmDesc.TextWrapped = true
	farmDesc.Font = Enum.Font.SourceSans
	farmDesc.Parent = farmInfo

	-- Seeds section
	local seedsSection = Instance.new("Frame")
	seedsSection.Name = "SeedsSection"
	seedsSection.Size = UDim2.new(1, 0, 0.35, 0)
	seedsSection.Position = UDim2.new(0, 0, 0.35, 0)
	seedsSection.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	seedsSection.BorderSizePixel = 0
	seedsSection.Parent = contentArea

	local seedsCorner = Instance.new("UICorner")
	seedsCorner.CornerRadius = UDim.new(0.02, 0)
	seedsCorner.Parent = seedsSection

	local seedsTitle = Instance.new("TextLabel")
	seedsTitle.Size = UDim2.new(1, 0, 0.2, 0)
	seedsTitle.BackgroundTransparency = 1
	seedsTitle.Text = "🌱 Available Seeds"
	seedsTitle.TextColor3 = Color3.new(1, 1, 1)
	seedsTitle.TextScaled = true
	seedsTitle.Font = Enum.Font.SourceSansSemibold
	seedsTitle.Parent = seedsSection

	-- Create seed items
	local seeds = {
		{name = "Carrot Seeds", price = 20, icon = "🥕"},
		{name = "Corn Seeds", price = 50, icon = "🌽"},
		{name = "Strawberry Seeds", price = 100, icon = "🍓"}
	}

	for i, seed in ipairs(seeds) do
		local seedFrame = Instance.new("Frame")
		seedFrame.Size = UDim2.new(0.9, 0, 0.2, 0)
		seedFrame.Position = UDim2.new(0.05, 0, 0.2 + (i * 0.2), 0)
		seedFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
		seedFrame.BorderSizePixel = 0
		seedFrame.Parent = seedsSection

		local seedCorner = Instance.new("UICorner")
		seedCorner.CornerRadius = UDim.new(0.1, 0)
		seedCorner.Parent = seedFrame

		local seedIcon = Instance.new("TextLabel")
		seedIcon.Size = UDim2.new(0.1, 0, 1, 0)
		seedIcon.Position = UDim2.new(0.05, 0, 0, 0)
		seedIcon.BackgroundTransparency = 1
		seedIcon.Text = seed.icon
		seedIcon.TextScaled = true
		seedIcon.Font = Enum.Font.SourceSansSemibold
		seedIcon.Parent = seedFrame

		local seedLabel = Instance.new("TextLabel")
		seedLabel.Size = UDim2.new(0.6, 0, 1, 0)
		seedLabel.Position = UDim2.new(0.2, 0, 0, 0)
		seedLabel.BackgroundTransparency = 1
		seedLabel.Text = seed.name
		seedLabel.TextColor3 = Color3.new(1, 1, 1)
		seedLabel.TextScaled = true
		seedLabel.TextXAlignment = Enum.TextXAlignment.Left
		seedLabel.Font = Enum.Font.SourceSans
		seedLabel.Parent = seedFrame

		local buyButton = Instance.new("TextButton")
		buyButton.Size = UDim2.new(0.15, 0, 0.8, 0)
		buyButton.Position = UDim2.new(0.8, 0, 0.1, 0)
		buyButton.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
		buyButton.Text = seed.price .. "💰"
		buyButton.TextColor3 = Color3.new(1, 1, 1)
		buyButton.TextScaled = true
		buyButton.Font = Enum.Font.SourceSansSemibold
		buyButton.BorderSizePixel = 0
		buyButton.Parent = seedFrame

		local buyCorner = Instance.new("UICorner")
		buyCorner.CornerRadius = UDim.new(0.2, 0)
		buyCorner.Parent = buyButton

		buyButton.MouseButton1Click:Connect(function()
			self:ShowNotification("Purchase", "Bought " .. seed.name .. " for " .. seed.price .. " coins", "success")
		end)
	end

	-- Inventory section
	local inventorySection = Instance.new("Frame")
	inventorySection.Name = "InventorySection"
	inventorySection.Size = UDim2.new(1, 0, 0.3, 0)
	inventorySection.Position = UDim2.new(0, 0, 0.7, 0)
	inventorySection.BackgroundColor3 = Color3.fromRGB(60, 40, 40)
	inventorySection.BorderSizePixel = 0
	inventorySection.Parent = contentArea

	local invCorner = Instance.new("UICorner")
	invCorner.CornerRadius = UDim.new(0.02, 0)
	invCorner.Parent = inventorySection

	local invTitle = Instance.new("TextLabel")
	invTitle.Size = UDim2.new(1, 0, 0.3, 0)
	invTitle.BackgroundTransparency = 1
	invTitle.Text = "📦 Your Inventory"
	invTitle.TextColor3 = Color3.new(1, 1, 1)
	invTitle.TextScaled = true
	invTitle.Font = Enum.Font.SourceSansSemibold
	invTitle.Parent = inventorySection

	local invDesc = Instance.new("TextLabel")
	invDesc.Size = UDim2.new(0.9, 0, 0.7, 0)
	invDesc.Position = UDim2.new(0.05, 0, 0.3, 0)
	invDesc.BackgroundTransparency = 1
	invDesc.Text = "Seeds: 5x Carrot, 3x Corn\nCrops: 2x Carrot, 1x Corn\n\n🐷 Pig Status: Fed 0 times, Size: 1.0x"
	invDesc.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	invDesc.TextScaled = true
	invDesc.TextWrapped = true
	invDesc.Font = Enum.Font.SourceSans
	invDesc.Parent = inventorySection
end

-- FIXED: Enhanced settings menu
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

	-- Audio Settings
	local audioSection = Instance.new("Frame")
	audioSection.Name = "AudioSection"
	audioSection.Size = UDim2.new(1, 0, 0.3, 0)
	audioSection.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	audioSection.BorderSizePixel = 0
	audioSection.Parent = contentArea

	local audioCorner = Instance.new("UICorner")
	audioCorner.CornerRadius = UDim.new(0.02, 0)
	audioCorner.Parent = audioSection

	local audioTitle = Instance.new("TextLabel")
	audioTitle.Size = UDim2.new(1, 0, 0.3, 0)
	audioTitle.BackgroundTransparency = 1
	audioTitle.Text = "🔊 Audio Settings"
	audioTitle.TextColor3 = Color3.new(1, 1, 1)
	audioTitle.TextScaled = true
	audioTitle.Font = Enum.Font.SourceSansSemibold
	audioTitle.Parent = audioSection

	-- Sound toggle
	local soundToggle = Instance.new("TextButton")
	soundToggle.Size = UDim2.new(0.8, 0, 0.4, 0)
	soundToggle.Position = UDim2.new(0.1, 0, 0.4, 0)
	soundToggle.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
	soundToggle.Text = "🔊 Sound Effects: ON"
	soundToggle.TextColor3 = Color3.new(1, 1, 1)
	soundToggle.TextScaled = true
	soundToggle.Font = Enum.Font.SourceSansSemibold
	soundToggle.BorderSizePixel = 0
	soundToggle.Parent = audioSection

	local soundCorner = Instance.new("UICorner")
	soundCorner.CornerRadius = UDim.new(0.1, 0)
	soundCorner.Parent = soundToggle

	local soundEnabled = true
	soundToggle.MouseButton1Click:Connect(function()
		soundEnabled = not soundEnabled
		if soundEnabled then
			soundToggle.Text = "🔊 Sound Effects: ON"
			soundToggle.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
		else
			soundToggle.Text = "🔇 Sound Effects: OFF"
			soundToggle.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
		end
		self:ShowNotification("Settings", "Sound effects " .. (soundEnabled and "enabled" or "disabled"), "info")
	end)

	-- Graphics Settings
	local graphicsSection = Instance.new("Frame")
	graphicsSection.Name = "GraphicsSection"
	graphicsSection.Size = UDim2.new(1, 0, 0.3, 0)
	graphicsSection.Position = UDim2.new(0, 0, 0.35, 0)
	graphicsSection.BackgroundColor3 = Color3.fromRGB(50, 40, 50)
	graphicsSection.BorderSizePixel = 0
	graphicsSection.Parent = contentArea

	local gfxCorner = Instance.new("UICorner")
	gfxCorner.CornerRadius = UDim.new(0.02, 0)
	gfxCorner.Parent = graphicsSection

	local gfxTitle = Instance.new("TextLabel")
	gfxTitle.Size = UDim2.new(1, 0, 0.3, 0)
	gfxTitle.BackgroundTransparency = 1
	gfxTitle.Text = "🎨 Graphics Settings"
	gfxTitle.TextColor3 = Color3.new(1, 1, 1)
	gfxTitle.TextScaled = true
	gfxTitle.Font = Enum.Font.SourceSansSemibold
	gfxTitle.Parent = graphicsSection

	-- Quality toggle
	local qualityToggle = Instance.new("TextButton")
	qualityToggle.Size = UDim2.new(0.8, 0, 0.4, 0)
	qualityToggle.Position = UDim2.new(0.1, 0, 0.4, 0)
	qualityToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
	qualityToggle.Text = "⚡ Performance Mode: OFF"
	qualityToggle.TextColor3 = Color3.new(1, 1, 1)
	qualityToggle.TextScaled = true
	qualityToggle.Font = Enum.Font.SourceSansSemibold
	qualityToggle.BorderSizePixel = 0
	qualityToggle.Parent = graphicsSection

	local qualityCorner = Instance.new("UICorner")
	qualityCorner.CornerRadius = UDim.new(0.1, 0)
	qualityCorner.Parent = qualityToggle

	local performanceMode = false
	qualityToggle.MouseButton1Click:Connect(function()
		performanceMode = not performanceMode
		if performanceMode then
			qualityToggle.Text = "⚡ Performance Mode: ON"
			qualityToggle.BackgroundColor3 = Color3.fromRGB(120, 120, 60)
		else
			qualityToggle.Text = "⚡ Performance Mode: OFF"
			qualityToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
		end
		self:ShowNotification("Settings", "Performance mode " .. (performanceMode and "enabled" or "disabled"), "info")
	end)

	-- Game Info Section
	local infoSection = Instance.new("Frame")
	infoSection.Name = "InfoSection"
	infoSection.Size = UDim2.new(1, 0, 0.3, 0)
	infoSection.Position = UDim2.new(0, 0, 0.7, 0)
	infoSection.BackgroundColor3 = Color3.fromRGB(40, 50, 40)
	infoSection.BorderSizePixel = 0
	infoSection.Parent = contentArea

	local infoCorner = Instance.new("UICorner")
	infoCorner.CornerRadius = UDim.new(0.02, 0)
	infoCorner.Parent = infoSection

	local infoTitle = Instance.new("TextLabel")
	infoTitle.Size = UDim2.new(1, 0, 0.3, 0)
	infoTitle.BackgroundTransparency = 1
	infoTitle.Text = "ℹ️ Game Information"
	infoTitle.TextColor3 = Color3.new(1, 1, 1)
	infoTitle.TextScaled = true
	infoTitle.Font = Enum.Font.SourceSansSemibold
	infoTitle.Parent = infoSection

	local infoText = Instance.new("TextLabel")
	infoText.Size = UDim2.new(0.9, 0, 0.7, 0)
	infoText.Position = UDim2.new(0.05, 0, 0.3, 0)
	infoText.BackgroundTransparency = 1
	infoText.Text = "Pet Palace v1.0\nWalk near pets to collect them!\nSell pets for coins in the Pets menu.\n\nMade with ❤️"
	infoText.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	infoText.TextScaled = true
	infoText.TextWrapped = true
	infoText.Font = Enum.Font.SourceSans
	infoText.Parent = infoSection
end
-- Utility Methods
function GameClient:ShowNotification(title, message, type)
	if not title or not message then return end

	print("Notification [" .. (type or "info"):upper() .. "]: " .. title .. " - " .. message)

	-- Create notification UI
	local notificationFrame = Instance.new("Frame")
	notificationFrame.Size = UDim2.new(0, 300, 0, 80)
	notificationFrame.Position = UDim2.new(1, -320, 0, 20)
	notificationFrame.BackgroundColor3 = self:GetNotificationColor(type or "info")
	notificationFrame.BorderSizePixel = 0
	notificationFrame.Parent = self.UI.Notifications

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
	notificationFrame.Position = UDim2.new(1, 0, 0, 20)
	local slideIn = TweenService:Create(notificationFrame, 
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(1, -320, 0, 20)}
	)
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

	-- Cancel button
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

	-- Confirm button
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

-- Currency display updates
function GameClient:UpdateCurrencyDisplay()
	if not self.PlayerData then return end

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

	local steps = math.min(20, math.abs(toValue - fromValue))
	local stepSize = (toValue - fromValue) / steps

	spawn(function()
		for i = 1, steps do
			local currentValue = math.floor(fromValue + (stepSize * i))
			textLabel.Text = self:FormatNumber(currentValue)
			wait(0.02)
		end
		textLabel.Text = self:FormatNumber(toValue)
	end)

	-- Scale animation for visual feedback
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

-- Helper functions
function GameClient:GetPetEmoji(petType)
	local petEmojiMap = {
		Corgi = "🐶", 
		Cat = "🐱",
		Hamster = "🐹",
		RedPanda = "🐾",
		bunny = "🐰",
		cat = "🐱", 
		dog = "🐶",
		bird = "🐦",
		fish = "🐠",
		dragon = "🐉",
		unicorn = "🦄"
	}

	return petEmojiMap[petType] or "🐾"
end

function GameClient:GetRarityColor(rarity)
	local rarityColors = {
		Common = Color3.fromRGB(200, 200, 200),
		Uncommon = Color3.fromRGB(100, 255, 100),
		Rare = Color3.fromRGB(100, 150, 255),
		Epic = Color3.fromRGB(200, 100, 255),
		Legendary = Color3.fromRGB(255, 215, 0),
		Mythic = Color3.fromRGB(255, 100, 100)
	}

	return rarityColors[rarity] or rarityColors.Common
end

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

-- Cleanup
function GameClient:Cleanup()
	if self.ProximityConnection then
		self.ProximityConnection:Disconnect()
		self.ProximityConnection = nil
	end
end

-- Make globally available
_G.GameClient = GameClient

return GameClient