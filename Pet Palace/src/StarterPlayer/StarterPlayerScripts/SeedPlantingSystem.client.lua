--[[
    Client-Side Planting System
    Add these functions to your GameClient.lua or create as a separate client script
]]

-- CLIENT-SIDE: Planting Interface for GameClient.lua

-- Enhanced farming interface with seed selection and planting
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Define LocalPlayer
local LocalPlayer = Players.LocalPlayer

-- Get or create GameClient
local GameClient
if ReplicatedStorage:FindFirstChild("GameClient") then
	GameClient = require(ReplicatedStorage:WaitForChild("GameClient"))
else
	-- Create a basic GameClient if it doesn't exist
	GameClient = {}
	GameClient.UI = {}
	GameClient.RemoteEvents = {}

	-- Basic functions that might be called
	function GameClient:GetPlayerData()
		return nil -- Return nil if no data system exists
	end

	function GameClient:ShowNotification(title, message, type)
		print("[" .. title .. "] " .. message)
	end
end

-- Safely require ItemConfig with error handling
local ItemConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("ItemConfig"))
-- If ItemConfig doesn't exist, create a basic fallback
if not ItemConfig then
	ItemConfig = {
		Seeds = {
			carrot_seeds = {name = "Carrot Seeds", growTime = 300},
			corn_seeds = {name = "Corn Seeds", growTime = 600},
			strawberry_seeds = {name = "Strawberry Seeds", growTime = 450},
			golden_seeds = {name = "Golden Seeds", growTime = 900}
		}
	}
	warn("ItemConfig not found, using fallback configuration")
end

function GameClient:SetupFarmingInterface()
	-- Farming state
	self.FarmingState = {
		selectedSeed = nil,
		isPlantingMode = false,
		seedInventory = {}
	}

	-- Initialize UI table if it doesn't exist
	if not self.UI then
		self.UI = {}
	end

	-- Create farming UI
	self:CreateFarmingUI()

	-- Setup input handling for planting
	self:SetupFarmingInputs()

	print("GameClient: Farming interface setup complete")
end

-- Create farming inventory and planting UI
function GameClient:CreateFarmingUI()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	-- Remove existing farming UI
	local existingUI = playerGui:FindFirstChild("FarmingUI")
	if existingUI then
		existingUI:Destroy()
	end

	-- Main farming UI
	local farmingUI = Instance.new("ScreenGui")
	farmingUI.Name = "FarmingUI"
	farmingUI.ResetOnSpawn = false
	farmingUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	farmingUI.Parent = playerGui

	-- Farming toggle button
	local farmButton = Instance.new("TextButton")
	farmButton.Name = "FarmingButton"
	farmButton.Size = UDim2.new(0, 120, 0, 50)
	farmButton.Position = UDim2.new(0, 20, 0.25, 0)
	farmButton.BackgroundColor3 = Color3.fromRGB(80, 120, 60)
	farmButton.BorderSizePixel = 0
	farmButton.Text = "🌾 Farming"
	farmButton.TextColor3 = Color3.new(1, 1, 1)
	farmButton.TextScaled = true
	farmButton.Font = Enum.Font.GothamBold
	farmButton.Parent = farmingUI

	local farmCorner = Instance.new("UICorner")
	farmCorner.CornerRadius = UDim.new(0.1, 0)
	farmCorner.Parent = farmButton

	-- Seed inventory panel
	local inventoryPanel = Instance.new("Frame")
	inventoryPanel.Name = "SeedInventory"
	inventoryPanel.Size = UDim2.new(0, 300, 0, 400)
	inventoryPanel.Position = UDim2.new(0, 150, 0.5, -200)
	inventoryPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	inventoryPanel.BorderSizePixel = 0
	inventoryPanel.Visible = false
	inventoryPanel.Parent = farmingUI

	local inventoryCorner = Instance.new("UICorner")
	inventoryCorner.CornerRadius = UDim.new(0.02, 0)
	inventoryCorner.Parent = inventoryPanel

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 50)
	titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = inventoryPanel

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0.02, 0)
	titleCorner.Parent = titleBar

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.8, 0, 1, 0)
	title.Position = UDim2.new(0.1, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🌱 Seed Inventory"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = titleBar

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -45, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = titleBar

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0.5, 0)
	closeCorner.Parent = closeButton

	-- Instructions
	local instructions = Instance.new("TextLabel")
	instructions.Size = UDim2.new(1, -20, 0, 60)
	instructions.Position = UDim2.new(0, 10, 0, 60)
	instructions.BackgroundTransparency = 1
	instructions.Text = "Select a seed, then click on your farm plots to plant!\nClick on ready crops to harvest them."
	instructions.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	instructions.TextScaled = true
	instructions.TextWrapped = true
	instructions.Font = Enum.Font.Gotham
	instructions.Parent = inventoryPanel

	-- Seeds container
	local seedsContainer = Instance.new("ScrollingFrame")
	seedsContainer.Name = "SeedsContainer"
	seedsContainer.Size = UDim2.new(1, -20, 1, -130)
	seedsContainer.Position = UDim2.new(0, 10, 0, 120)
	seedsContainer.BackgroundTransparency = 1
	seedsContainer.ScrollBarThickness = 6
	seedsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	seedsContainer.Parent = inventoryPanel

	local seedsLayout = Instance.new("UIListLayout")
	seedsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	seedsLayout.Padding = UDim.new(0, 5)
	seedsLayout.Parent = seedsContainer

	seedsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		seedsContainer.CanvasSize = UDim2.new(0, 0, 0, seedsLayout.AbsoluteContentSize.Y + 10)
	end)

	-- Store references
	self.UI.FarmingUI = farmingUI
	self.UI.FarmButton = farmButton
	self.UI.SeedInventory = inventoryPanel
	self.UI.SeedsContainer = seedsContainer

	-- Connect events
	farmButton.MouseButton1Click:Connect(function()
		self:ToggleFarmingUI()
	end)

	closeButton.MouseButton1Click:Connect(function()
		inventoryPanel.Visible = false
		self.FarmingState.isPlantingMode = false
		self:UpdatePlantingModeDisplay()
	end)
end

-- Toggle farming UI visibility
function GameClient:ToggleFarmingUI()
	if not self.UI.SeedInventory then return end

	local isVisible = self.UI.SeedInventory.Visible
	if isVisible then
		self.UI.SeedInventory.Visible = false
		self.FarmingState.isPlantingMode = false
		self:UpdatePlantingModeDisplay()
	else
		self:UpdateSeedInventory()
		self.UI.SeedInventory.Visible = true
	end
end

-- Update seed inventory display
function GameClient:UpdateSeedInventory()
	if not self.UI.SeedsContainer then return end

	-- Clear existing items
	for _, child in pairs(self.UI.SeedsContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local playerData = self:GetPlayerData()
	if not playerData or not playerData.farming or not playerData.farming.inventory then
		local noSeedsLabel = Instance.new("TextLabel")
		noSeedsLabel.Size = UDim2.new(1, 0, 0, 60)
		noSeedsLabel.BackgroundTransparency = 1
		noSeedsLabel.Text = "No seeds available!\nBuy seeds from the shop first."
		noSeedsLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
		noSeedsLabel.TextScaled = true
		noSeedsLabel.Font = Enum.Font.Gotham
		noSeedsLabel.Parent = self.UI.SeedsContainer
		return
	end

	local inventory = playerData.farming.inventory
	local hasSeed = false

	-- Create seed items
	for seedId, quantity in pairs(inventory) do
		if seedId:find("_seeds") and quantity > 0 then
			hasSeed = true
			self:CreateSeedItem(seedId, quantity)
		end
	end

	if not hasSeed then
		local noSeedsLabel = Instance.new("TextLabel")
		noSeedsLabel.Size = UDim2.new(1, 0, 0, 60)
		noSeedsLabel.BackgroundTransparency = 1
		noSeedsLabel.Text = "No seeds in inventory!\nBuy seeds from the shop."
		noSeedsLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
		noSeedsLabel.TextScaled = true
		noSeedsLabel.Font = Enum.Font.Gotham
		noSeedsLabel.Parent = self.UI.SeedsContainer
	end
end

-- Create individual seed item in inventory
function GameClient:CreateSeedItem(seedId, quantity)
	local seedConfig = ItemConfig and ItemConfig.Seeds and ItemConfig.Seeds[seedId]
	local seedName = seedConfig and seedConfig.name or seedId
	local growTime = seedConfig and seedConfig.growTime or 60

	local seedItem = Instance.new("Frame")
	seedItem.Name = seedId .. "_Item"
	seedItem.Size = UDim2.new(1, 0, 0, 80)
	seedItem.BackgroundColor3 = self.FarmingState.selectedSeed == seedId and Color3.fromRGB(100, 140, 80) or Color3.fromRGB(60, 60, 70)
	seedItem.BorderSizePixel = 0
	seedItem.Parent = self.UI.SeedsContainer

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0.05, 0)
	itemCorner.Parent = seedItem

	-- Seed icon
	local seedIcon = Instance.new("TextLabel")
	seedIcon.Size = UDim2.new(0, 60, 0, 60)
	seedIcon.Position = UDim2.new(0, 10, 0, 10)
	seedIcon.BackgroundColor3 = Color3.fromRGB(80, 100, 60)
	seedIcon.BorderSizePixel = 0
	seedIcon.Text = self:GetSeedEmoji(seedId)
	seedIcon.TextScaled = true
	seedIcon.Font = Enum.Font.SourceSansSemibold
	seedIcon.Parent = seedItem

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0.1, 0)
	iconCorner.Parent = seedIcon

	-- Seed info
	local seedLabel = Instance.new("TextLabel")
	seedLabel.Size = UDim2.new(0.5, 0, 0.4, 0)
	seedLabel.Position = UDim2.new(0, 80, 0, 5)
	seedLabel.BackgroundTransparency = 1
	seedLabel.Text = seedName .. " x" .. quantity
	seedLabel.TextColor3 = Color3.new(1, 1, 1)
	seedLabel.TextScaled = true
	seedLabel.Font = Enum.Font.GothamBold
	seedLabel.TextXAlignment = Enum.TextXAlignment.Left
	seedLabel.Parent = seedItem

	local growthInfo = Instance.new("TextLabel")
	growthInfo.Size = UDim2.new(0.5, 0, 0.3, 0)
	growthInfo.Position = UDim2.new(0, 80, 0, 35)
	growthInfo.BackgroundTransparency = 1
	growthInfo.Text = "Grows in " .. math.floor(growTime / 60) .. " min"
	growthInfo.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	growthInfo.TextScaled = true
	growthInfo.Font = Enum.Font.Gotham
	growthInfo.TextXAlignment = Enum.TextXAlignment.Left
	growthInfo.Parent = seedItem

	-- Select button
	local selectButton = Instance.new("TextButton")
	selectButton.Size = UDim2.new(0, 80, 0, 60)
	selectButton.Position = UDim2.new(1, -90, 0, 10)
	selectButton.BackgroundColor3 = self.FarmingState.selectedSeed == seedId and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(80, 120, 80)
	selectButton.BorderSizePixel = 0
	selectButton.Text = self.FarmingState.selectedSeed == seedId and "✓ Selected" or "Select"
	selectButton.TextColor3 = Color3.new(1, 1, 1)
	selectButton.TextScaled = true
	selectButton.Font = Enum.Font.GothamBold
	selectButton.Parent = seedItem

	local selectCorner = Instance.new("UICorner")
	selectCorner.CornerRadius = UDim.new(0.1, 0)
	selectCorner.Parent = selectButton

	-- Connect select button
	selectButton.MouseButton1Click:Connect(function()
		if self.FarmingState.selectedSeed == seedId then
			self.FarmingState.selectedSeed = nil
			self.FarmingState.isPlantingMode = false
		else
			self.FarmingState.selectedSeed = seedId
			self.FarmingState.isPlantingMode = true
		end

		self:UpdateSeedInventory()
		self:UpdatePlantingModeDisplay()

		if self.FarmingState.selectedSeed then
			self:ShowNotification("Seed Selected", 
				"Selected " .. seedName .. "! Click on your farm plots to plant.", "info")
		end
	end)
end

-- Get emoji for seed type
function GameClient:GetSeedEmoji(seedId)
	local emojiMap = {
		carrot_seeds = "🥕",
		corn_seeds = "🌽", 
		strawberry_seeds = "🍓",
		golden_seeds = "✨"
	}
	return emojiMap[seedId] or "🌱"
end

-- Update planting mode display
function GameClient:UpdatePlantingModeDisplay()
	if not self.UI.FarmButton then return end

	if self.FarmingState.isPlantingMode and self.FarmingState.selectedSeed then
		local seedConfig = ItemConfig and ItemConfig.Seeds and ItemConfig.Seeds[self.FarmingState.selectedSeed]
		local seedName = seedConfig and seedConfig.name or "Seed"

		self.UI.FarmButton.Text = "🌱 " .. seedName
		self.UI.FarmButton.BackgroundColor3 = Color3.fromRGB(100, 160, 80)

		-- Show planting cursor hint
		self:ShowPlantingHint(true)
	else
		self.UI.FarmButton.Text = "🌾 Farming"
		self.UI.FarmButton.BackgroundColor3 = Color3.fromRGB(80, 120, 60)

		-- Hide planting cursor hint
		self:ShowPlantingHint(false)
	end
end

-- Show/hide planting mode hint
function GameClient:ShowPlantingHint(show)
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	local existingHint = playerGui:FindFirstChild("PlantingHint")
	if existingHint then
		existingHint:Destroy()
	end

	if not show then return end

	local hintGui = Instance.new("ScreenGui")
	hintGui.Name = "PlantingHint"
	hintGui.Parent = playerGui

	local hintLabel = Instance.new("TextLabel")
	hintLabel.Size = UDim2.new(0, 300, 0, 50)
	hintLabel.Position = UDim2.new(0.5, -150, 0.1, 0)
	hintLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	hintLabel.BorderSizePixel = 0
	hintLabel.Text = "🌱 Click on your farm plots to plant!"
	hintLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	hintLabel.TextScaled = true
	hintLabel.Font = Enum.Font.GothamBold
	hintLabel.Parent = hintGui

	local hintCorner = Instance.new("UICorner")
	hintCorner.CornerRadius = UDim.new(0.1, 0)
	hintCorner.Parent = hintLabel

	-- Pulsing effect
	local pulseTween = TweenService:Create(hintLabel,
		TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{BackgroundColor3 = Color3.fromRGB(60, 80, 40)}
	)
	pulseTween:Play()
end

-- Setup input handling for planting
function GameClient:SetupFarmingInputs()
	local mouse = LocalPlayer:GetMouse()

	-- Handle farm plot clicking
	mouse.Button1Down:Connect(function()
		if not self.FarmingState.isPlantingMode then return end

		local target = mouse.Target
		if not target then return end

		-- Check if clicking on a farm plot
		local plotModel = self:GetFarmPlotFromPart(target)
		if plotModel then
			self:HandlePlotClick(plotModel)
		end
	end)

	-- Keyboard shortcuts
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.F then
			self:ToggleFarmingUI()
		elseif input.KeyCode == Enum.KeyCode.Escape and self.FarmingState.isPlantingMode then
			self.FarmingState.isPlantingMode = false
			self.FarmingState.selectedSeed = nil
			self:UpdatePlantingModeDisplay()
		end
	end)
end

-- Get farm plot model from clicked part
function GameClient:GetFarmPlotFromPart(part)
	local model = part.Parent

	-- Check if this is a farm plot
	while model and model ~= workspace do
		if model:IsA("Model") and model.Name:find("FarmPlot") then
			-- Verify it's owned by the player
			local owner = model:GetAttribute("Owner")
			if owner == LocalPlayer.Name then
				return model
			end
		end
		model = model.Parent
	end

	return nil
end

-- Handle farm plot click (plant or harvest)
function GameClient:HandlePlotClick(plotModel)
	local isPlanted = plotModel:GetAttribute("IsPlanted")

	if isPlanted then
		-- Try to harvest
		local growthStage = plotModel:GetAttribute("GrowthStage") or 0
		if growthStage >= 4 then
			self:HarvestPlot(plotModel)
		else
			local progress = math.floor((growthStage / 4) * 100)
			local plantType = plotModel:GetAttribute("PlantType") or "crop"
			self:ShowNotification("Still Growing", 
				plantType:gsub("_seeds", "") .. " is " .. progress .. "% grown", "info")
		end
	else
		-- Try to plant
		if self.FarmingState.selectedSeed then
			self:PlantSeedInPlot(plotModel, self.FarmingState.selectedSeed)
		else
			self:ShowNotification("No Seed Selected", 
				"Select a seed from your farming inventory first!", "warning")
		end
	end
end

-- Plant seed in plot
function GameClient:PlantSeedInPlot(plotModel, seedType)
	if not self.RemoteEvents or not self.RemoteEvents.PlantSeed then
		warn("GameClient: PlantSeed remote event not found")
		return
	end

	-- Fire server event
	self.RemoteEvents.PlantSeed:FireServer(plotModel, seedType)

	-- Visual feedback
	self:CreatePlantingEffect(plotModel)

	-- Update inventory display
	spawn(function()
		wait(0.5) -- Wait for server response
		self:UpdateSeedInventory()
	end)
end

-- Harvest crop from plot
function GameClient:HarvestPlot(plotModel)
	if not self.RemoteEvents or not self.RemoteEvents.HarvestCrop then
		warn("GameClient: HarvestCrop remote event not found")
		return
	end

	-- Fire server event
	self.RemoteEvents.HarvestCrop:FireServer(plotModel)

	-- Visual feedback
	self:CreateHarvestEffect(plotModel)
end

-- Create planting visual effect
function GameClient:CreatePlantingEffect(plotModel)
	if not plotModel.PrimaryPart then return end

	local plotCenter = plotModel.PrimaryPart.Position

	-- Create sparkle effect around the plot
	for i = 1, 8 do
		local sparkle = Instance.new("Part")
		sparkle.Name = "PlantingSparkle"
		sparkle.Size = Vector3.new(0.2, 0.2, 0.2)
		sparkle.Shape = Enum.PartType.Ball
		sparkle.Material = Enum.Material.Neon
		sparkle.Color = Color3.fromRGB(100, 255, 100)
		sparkle.CanCollide = false
		sparkle.Anchored = true
		sparkle.Position = plotCenter + Vector3.new(
			math.random(-4, 4),
			math.random(1, 3),
			math.random(-4, 4)
		)
		sparkle.Parent = workspace

		-- Animate sparkle
		local tween = TweenService:Create(sparkle,
			TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = sparkle.Position + Vector3.new(0, 3, 0),
				Transparency = 1,
				Size = Vector3.new(0.05, 0.05, 0.05)
			}
		)
		tween:Play()
		tween.Completed:Connect(function()
			sparkle:Destroy()
		end)
	end

	-- Play planting sound
	self:PlayFarmingSound("plant")
end

-- Create harvest visual effect
function GameClient:CreateHarvestEffect(plotModel)
	if not plotModel.PrimaryPart then return end

	local plotCenter = plotModel.PrimaryPart.Position

	-- Create golden sparkles for harvest
	for i = 1, 12 do
		local sparkle = Instance.new("Part")
		sparkle.Name = "HarvestSparkle"
		sparkle.Size = Vector3.new(0.3, 0.3, 0.3)
		sparkle.Shape = Enum.PartType.Ball
		sparkle.Material = Enum.Material.Neon
		sparkle.Color = Color3.fromRGB(255, 215, 0)
		sparkle.CanCollide = false
		sparkle.Anchored = true
		sparkle.Position = plotCenter + Vector3.new(
			math.random(-3, 3),
			math.random(1, 4),
			math.random(-3, 3)
		)
		sparkle.Parent = workspace

		-- Animate sparkle
		local tween = TweenService:Create(sparkle,
			TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = sparkle.Position + Vector3.new(0, 5, 0),
				Transparency = 1,
				Size = Vector3.new(0.1, 0.1, 0.1)
			}
		)
		tween:Play()
		tween.Completed:Connect(function()
			sparkle:Destroy()
		end)
	end

	-- Play harvest sound
	self:PlayFarmingSound("harvest")
end

-- Play farming sounds
function GameClient:PlayFarmingSound(soundType)
	local character = LocalPlayer.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	local sound = Instance.new("Sound")

	if soundType == "plant" then
		sound.SoundId = "rbxasset://sounds/impact_water.mp3"
		sound.Volume = 0.3
		--	sound.Pitch = 1.2
	elseif soundType == "harvest" then
		sound.SoundId = "rbxasset://sounds/electronicpingsharp.wav"
		sound.Volume = 0.5
		--	sound.Pitch = 0.8
	end

	sound.Parent = character.HumanoidRootPart

	pcall(function()
		sound:Play()
	end)

	game:GetService("Debris"):AddItem(sound, 2)
end

-- Initialize farming system when player joins
function GameClient:InitializeFarmingSystem()
	-- Initialize required tables
	if not self.FarmingState then
		self.FarmingState = {}
	end
	if not self.UI then
		self.UI = {}
	end
	if not self.RemoteEvents then
		self.RemoteEvents = {}
	end

	-- Wait for character and game to load
	spawn(function()
		wait(3)
		self:SetupFarmingInterface()

		-- Check if player has farm plots and show tutorial
		local playerData = self:GetPlayerData()
		if playerData and playerData.purchaseHistory and playerData.purchaseHistory.farm_plot_starter then
			self:ShowNotification("Farming Available", 
				"Press F to open your farming interface! Plant seeds and harvest crops.", "info")
		end
	end)
end

-- Initialize the farming system
if GameClient then
	GameClient:InitializeFarmingSystem()
end

-- Make farming system available for other scripts
_G.FarmingClient = {
	GetSelectedSeed = function() 
		return GameClient.FarmingState and GameClient.FarmingState.selectedSeed or nil
	end,
	IsPlantingMode = function() 
		return GameClient.FarmingState and GameClient.FarmingState.isPlantingMode or false
	end,
	OpenFarmingUI = function() 
		if GameClient.ToggleFarmingUI then
			return GameClient:ToggleFarmingUI() 
		end
	end
}