--[[
    CurrencyDisplay.lua
    Manages the currency display in the top corner of the screen
    Created: 2025-05-24
    Author: GitHub Copilot for tb102502
]]

local CurrencyDisplay = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- Initialize the currency display
function CurrencyDisplay:Initialize(parent)
	print("CurrencyDisplay: Initializing...")

	-- Create the main container
	local container = Instance.new("Frame")
	container.Name = "CurrencyDisplay"
	container.Size = UDim2.new(0.25, 0, 0.08, 0)
	container.Position = UDim2.new(0.99, 0, 0.02, 0)
	container.AnchorPoint = Vector2.new(1, 0)
	container.BackgroundTransparency = 1
	container.Parent = parent

	-- Store the container
	self.Container = container

	-- Create currency items
	self:CreateCurrencyItems()

	-- Connect to ShopSystemClient for updates
	self:ConnectToShopSystem()

	print("CurrencyDisplay: Initialized")
	return true
end

-- Create the currency items
function CurrencyDisplay:CreateCurrencyItems()
	-- Clear any existing items
	for _, child in ipairs(self.Container:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Create containers for each currency type
	local currencies = {
		{name = "Coins", icon = "rbxassetid://6031086173", value = 0, color = Color3.fromRGB(255, 215, 0)},
		{name = "Gems", icon = "rbxassetid://6029251113", value = 0, color = Color3.fromRGB(0, 200, 255)}
	}

	-- Position variables
	local height = 0.5
	local spacing = 1.1

	for i, currency in ipairs(currencies) do
		-- Create container
		local frame = Instance.new("Frame")
		frame.Name = currency.name
		frame.Size = UDim2.new(1, 0, height, 0)
		frame.Position = UDim2.new(0, 0, (i-1) * height * spacing, 0)
		frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
		frame.BorderSizePixel = 0
		frame.Parent = self.Container

		-- Add corner rounding
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.2, 0)
		corner.Parent = frame

		-- Add icon
		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.Size = UDim2.new(0.2, 0, 0.8, 0)
		icon.Position = UDim2.new(0.05, 0, 0.5, 0)
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.BackgroundTransparency = 1
		icon.Image = currency.icon
		icon.ImageColor3 = currency.color
		icon.Parent = frame

		-- Add label
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.new(0.25, 0, 0.8, 0)
		label.Position = UDim2.new(0.3, 0, 0.5, 0)
		label.AnchorPoint = Vector2.new(0, 0.5)
		label.BackgroundTransparency = 1
		label.Text = currency.name
		label.TextColor3 = currency.color
		label.TextScaled = true
		label.Font = Enum.Font.SourceSansSemibold
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = frame

		-- Add value
		local value = Instance.new("TextLabel")
		value.Name = "Value"
		value.Size = UDim2.new(0.4, 0, 0.8, 0)
		value.Position = UDim2.new(0.95, 0, 0.5, 0)
		value.AnchorPoint = Vector2.new(1, 0.5)
		value.BackgroundTransparency = 1
		value.Text = tostring(currency.value)
		value.TextColor3 = Color3.new(1, 1, 1)
		value.TextScaled = true
		value.Font = Enum.Font.SourceSansSemibold
		value.TextXAlignment = Enum.TextXAlignment.Right
		value.Parent = frame
	end
end

-- Connect to the Shop System for currency updates
function CurrencyDisplay:ConnectToShopSystem()
	-- Get the shop system client
	local shopSystem = _G.ShopSystemClient

	if not shopSystem then
		warn("CurrencyDisplay: ShopSystemClient not found in _G")
		return
	end

	-- Connect to currency updated event
	if shopSystem.OnCurrencyUpdated then
		shopSystem.OnCurrencyUpdated:Connect(function(currencyData)
			self:UpdateDisplay(currencyData)
		end)
	end

	-- Request current currency data
	if typeof(shopSystem.GetPlayerCurrency) == "function" then
		local currencyData = shopSystem:GetPlayerCurrency()
		self:UpdateDisplay(currencyData)
	end
end

-- Update the display with new currency values
function CurrencyDisplay:UpdateDisplay(currencyData)
	if not currencyData then return end

	for currencyName, currencyValue in pairs(currencyData) do
		local currencyFrame = self.Container:FindFirstChild(currencyName)

		if currencyFrame then
			local valueLabel = currencyFrame:FindFirstChild("Value")

			if valueLabel then
				-- Animate value change
				self:AnimateValueChange(valueLabel, tonumber(valueLabel.Text) or 0, currencyValue)
			end
		end
	end
end

-- Animate value change with a counting effect
-- Replace the AnimateValueChange function with this fixed version
function CurrencyDisplay:AnimateValueChange(label, oldValue, newValue)
	-- Store animation data in a table owned by this module instead of on the label
	if not self.Animations then
		self.Animations = {}
	end

	-- Generate a unique ID for this animation
	local animId = label:GetFullName()

	-- Cancel existing animation
	if self.Animations[animId] then
		self.Animations[animId].Cancelled = true
		self.Animations[animId] = nil
	end

	-- Create new animation
	local duration = 0.5
	local startTime = tick()

	-- Calculate step size based on the difference
	local difference = newValue - oldValue
	local isLargeChange = math.abs(difference) > 100

	-- Store animation reference
	self.Animations[animId] = {
		Cancel = function() 
			if self.Animations[animId] then
				self.Animations[animId].Cancelled = true
			end
		end,
		Cancelled = false
	}

	local animation = self.Animations[animId]

	-- Run animation
	spawn(function()
		local elapsed = 0

		-- Flash text green for increase, red for decrease
		if difference > 0 then
			label.TextColor3 = Color3.fromRGB(50, 255, 50)
		elseif difference < 0 then
			label.TextColor3 = Color3.fromRGB(255, 50, 50)
		end

		while elapsed < duration and animation and not animation.Cancelled do
			elapsed = tick() - startTime
			local alpha = math.min(elapsed / duration, 1)

			-- Use easing function
			alpha = 1 - (1 - alpha) * (1 - alpha)

			-- Calculate current value
			local currentValue
			if isLargeChange then
				-- Round to nearest integer for large changes
				currentValue = math.floor(oldValue + difference * alpha)
			else
				-- Show decimals for small changes
				currentValue = oldValue + difference * alpha
				currentValue = math.floor(currentValue * 10) / 10
			end

			-- Format value with commas for thousands
			local formattedValue = tostring(currentValue)
			if currentValue >= 1000 then
				local formatted = tostring(math.floor(currentValue))
				formattedValue = string.gsub(formatted, "(%d)(%d%d%d)$", "%1,%2")
				formattedValue = string.gsub(formattedValue, "(%d)(%d%d%d),", "%1,%2,")
			end

			-- Update label
			label.Text = formattedValue

			wait()
		end

		if animation and not animation.Cancelled then
			-- Format final value with commas for thousands
			local formattedValue = tostring(newValue)
			if newValue >= 1000 then
				local formatted = tostring(math.floor(newValue))
				formattedValue = string.gsub(formatted, "(%d)(%d%d%d)$", "%1,%2")
				formattedValue = string.gsub(formattedValue, "(%d)(%d%d%d),", "%1,%2,")
			end

			-- Set final value
			label.Text = formattedValue

			-- Reset color
			label.TextColor3 = Color3.new(1, 1, 1)

			-- Clear animation reference
			self.Animations[animId] = nil
		end
	end)
end
return CurrencyDisplay