--[[
    ShopSystemClient.lua
    Client-side interface for the shop system
    Created: 2025-05-24
    Author: GitHub Copilot for tb102502
]]

local ShopSystemClient = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local MarketplaceService = game:GetService("MarketplaceService")

-- Cache for data received from server
ShopSystemClient.Cache = {
	ShopItems = {},
	PlayerCurrency = {},
	ActiveBoosters = {}
}

-- Remote events and functions
ShopSystemClient.Remotes = {
	Events = {},
	Functions = {}
}

-- Initialize client-side shop system
function ShopSystemClient:Initialize()
	print("ShopSystemClient: Starting initialization...")

	-- Find remote events and functions
	local remoteFolder = ReplicatedStorage:WaitForChild("ShopSystem", 10)

	if not remoteFolder then
		warn("ShopSystemClient: Could not find ShopSystem folder in ReplicatedStorage")
		return false
	end

	-- Store remote event references
	for _, instance in ipairs(remoteFolder:GetChildren()) do
		if instance:IsA("RemoteEvent") then
			self.Remotes.Events[instance.Name] = instance
		elseif instance:IsA("RemoteFunction") then
			self.Remotes.Functions[instance.Name] = instance
		end
	end

	-- Set up event handlers
	self:SetupEventHandlers()

	-- Create bindable events
	self:CreateBindableEvents()

	-- Request initial data
	self:RefreshShopData()

	print("ShopSystemClient: Initialization complete")
	return true
end

-- Create bindable events for UI components
function ShopSystemClient:CreateBindableEvents()
	-- Clean up any existing events
	for _, event in pairs(self._events or {}) do
		if event and typeof(event) == "Instance" then
			pcall(function() event:Destroy() end)
		end
	end

	-- Create new events
	local events = {
		"OnCurrencyUpdated",
		"OnItemPurchased",
		"OnPremiumPurchased",
		"OnBoosterActivated",
		"OnBoosterExpired",
		"OnShopItemsLoaded"
	}

	self._events = {}

	for _, eventName in ipairs(events) do
		local event = Instance.new("BindableEvent")
		self._events[eventName] = event
		self[eventName] = event.Event
	end
end

-- Set up client-side event handlers
function ShopSystemClient:SetupEventHandlers()
	local events = self.Remotes.Events

	-- Currency updates
	if events.CurrencyUpdated then
		events.CurrencyUpdated.OnClientEvent:Connect(function(currencyData)
			self:HandleCurrencyUpdated(currencyData)
		end)
	end

	-- Item purchase confirmation
	if events.ItemPurchased then
		events.ItemPurchased.OnClientEvent:Connect(function(item, quantity)
			self:HandleItemPurchased(item, quantity)
		end)
	end

	-- Premium purchase confirmation
	if events.PremiumPurchased then
		events.PremiumPurchased.OnClientEvent:Connect(function(currencyType, amount)
			self:HandlePremiumPurchased(currencyType, amount)
		end)
	end

	-- Booster activated
	if events.BoosterActivated then
		events.BoosterActivated.OnClientEvent:Connect(function(booster)
			self:HandleBoosterActivated(booster)
		end)
	end

	-- Booster expired
	if events.BoosterExpired then
		events.BoosterExpired.OnClientEvent:Connect(function(boosterId)
			self:HandleBoosterExpired(boosterId)
		end)
	end
end

-- Handle currency updated event
function ShopSystemClient:HandleCurrencyUpdated(currencyData)
	self.Cache.PlayerCurrency = currencyData

	if self._events and self._events.OnCurrencyUpdated then
		self._events.OnCurrencyUpdated:Fire(currencyData)
	end
end

-- Handle item purchased event
function ShopSystemClient:HandleItemPurchased(item, quantity)
	if self._events and self._events.OnItemPurchased then
		self._events.OnItemPurchased:Fire(item, quantity)
	end
end

-- Handle premium purchased event
function ShopSystemClient:HandlePremiumPurchased(currencyType, amount)
	if self._events and self._events.OnPremiumPurchased then
		self._events.OnPremiumPurchased:Fire(currencyType, amount)
	end
end

-- Handle booster activated event
function ShopSystemClient:HandleBoosterActivated(booster)
	-- Add to active boosters
	self.Cache.ActiveBoosters[booster.id] = booster

	if self._events and self._events.OnBoosterActivated then
		self._events.OnBoosterActivated:Fire(booster)
	end
end

-- Handle booster expired event
function ShopSystemClient:HandleBoosterExpired(boosterId)
	-- Remove from active boosters
	if self.Cache.ActiveBoosters[boosterId] then
		self.Cache.ActiveBoosters[boosterId] = nil
	end

	if self._events and self._events.OnBoosterExpired then
		self._events.OnBoosterExpired:Fire(boosterId)
	end
end

-- Refresh shop data from server
function ShopSystemClient:RefreshShopData()
	-- Get shop items
	self:GetShopItems()

	-- Get player currency
	self:GetPlayerCurrency()

	-- Get active boosters
	self:GetActiveBoosts()
end

-- Get shop items from server
function ShopSystemClient:GetShopItems()
	local getItemsFunc = self.Remotes.Functions.GetShopItems

	if not getItemsFunc then
		warn("ShopSystemClient: GetShopItems remote function not found")
		return {}
	end

	local success, items = pcall(function()
		return getItemsFunc:InvokeServer()
	end)

	if success and items then
		self.Cache.ShopItems = items

		if self._events and self._events.OnShopItemsLoaded then
			self._events.OnShopItemsLoaded:Fire(items)
		end

		return items
	else
		warn("ShopSystemClient: Failed to get shop items")
		return {}
	end
end

-- Get player currency from server
function ShopSystemClient:GetPlayerCurrency()
	local getCurrencyFunc = self.Remotes.Functions.GetPlayerCurrency

	if not getCurrencyFunc then
		warn("ShopSystemClient: GetPlayerCurrency remote function not found")
		return {}
	end

	local success, currency = pcall(function()
		return getCurrencyFunc:InvokeServer()
	end)

	if success and currency then
		self.Cache.PlayerCurrency = currency

		if self._events and self._events.OnCurrencyUpdated then
			self._events.OnCurrencyUpdated:Fire(currency)
		end

		return currency
	else
		warn("ShopSystemClient: Failed to get player currency")
		return {}
	end
end

-- Get active boosts from server
function ShopSystemClient:GetActiveBoosts()
	local getBoostsFunc = self.Remotes.Functions.GetActiveBoosts

	if not getBoostsFunc then
		warn("ShopSystemClient: GetActiveBoosts remote function not found")
		return {}
	end

	local success, boosters = pcall(function()
		return getBoostsFunc:InvokeServer()
	end)

	if success and boosters then
		-- Update cache
		self.Cache.ActiveBoosters = {}

		for _, booster in ipairs(boosters) do
			self.Cache.ActiveBoosters[booster.id] = booster
		end

		return boosters
	else
		warn("ShopSystemClient: Failed to get active boosters")
		return {}
	end
end

-- Purchase an item
function ShopSystemClient:PurchaseItem(itemId, quantity)
	local purchaseEvent = self.Remotes.Events.PurchaseItem

	if not purchaseEvent then
		warn("ShopSystemClient: PurchaseItem remote event not found")
		return false
	end

	quantity = quantity or 1
	purchaseEvent:FireServer(itemId, quantity)
	return true
end

-- Buy a developer product
function ShopSystemClient:BuyDeveloperProduct(productId)
	local success, result = pcall(function()
		return MarketplaceService:PromptProductPurchase(LocalPlayer, productId)
	end)

	if not success then
		warn("ShopSystemClient: Failed to prompt product purchase: " .. tostring(result))
	end

	return success
end

return ShopSystemClient