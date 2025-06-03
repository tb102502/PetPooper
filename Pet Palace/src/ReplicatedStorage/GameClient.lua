--[[
    GameClient.lua - FIXED VERSION - CLIENT SYSTEM
    Place in: ReplicatedStorage/GameClient.lua
]]

local GameClient = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Load ItemConfig safely
local ItemConfig = nil
local function loadItemConfig()
	local success, result = pcall(function()
		return require(ReplicatedStorage:WaitForChild("ItemConfig"))
	end)
	if success then
		ItemConfig = result
	else
		warn("GameClient: Could not load ItemConfig: " .. tostring(result))
	end
end

-- Load ItemConfig on initialization
loadItemConfig()


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

-- FIXED: Initialize the entire client system with proper error handling
function GameClient:Initialize()
	print("GameClient: Starting initialization...")

	local success, errorMsg = pcall(function()
		-- Load ItemConfig first
		loadItemConfig()

		-- Initialize systems in order
		self:SetupRemoteConnections()
		self:SetupUI()
		self:SetupInputHandling()
		self:SetupProximityCollection()
		self:SetupEffects()
		self:RequestInitialData()
		self:InitializeFarmingSystem()
	end)

	if not success then
		error("GameClient initialization failed: " .. tostring(errorMsg))
	end

	print("GameClient: Initialization complete!")
	return true
end

function GameClient:SetupFarmingInterface()
	local UserInputService = game:GetService("UserInputService")
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer

	-- Initialize farming state
	self.FarmingState = {
		selectedSeed = nil,
		isPlantingMode = false,
		seedInventory = {}
	}

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

	-- FIXED: Request fresh player data
	local playerData = self:GetPlayerData()
	if not playerData then
		-- Try to get fresh data from server
		if self.RemoteFunctions.GetPlayerData then
			local success, freshData = pcall(function()
				return self.RemoteFunctions.GetPlayerData:InvokeServer()
			end)
			if success and freshData then
				self.PlayerData = freshData
				playerData = freshData
			end
		end
	end

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

	-- FIXED: Create seed items with proper data
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

	print("GameClient: Updated seed inventory - Found " .. (hasSeed and "seeds" or "no seeds"))
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
	local pulseTween = game:GetService("TweenService"):Create(hintLabel,
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
	local UserInputService = game:GetService("UserInputService")
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
		if model:IsA("Model") and (model.Name:find("FarmPlot") or model.Name:find("_Farm")) then
			-- Verify it's owned by the player
			local owner = model:GetAttribute("Owner")
			if owner == LocalPlayer.Name then
				return model
			end
		end
		model = model.Parent
	end

	-- Alternative: check if we clicked on soil directly
	if part.Name == "Soil" and part.Parent:IsA("Model") then
		local plotModel = part.Parent
		local owner = plotModel:GetAttribute("Owner")
		if owner == LocalPlayer.Name then
			return plotModel
		end
	end

	return nil
end

-- FIXED: Enhanced plot clicking with better feedback
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
			local timeLeft = self:CalculateTimeRemaining(plotModel)

			self:ShowNotification("Still Growing", 
				plantType:gsub("_seeds", "") .. " is " .. progress .. "% grown" .. 
					(timeLeft and (" (" .. timeLeft .. " remaining)") or ""), "info")
		end
	else
		-- Try to plant
		if self.FarmingState.selectedSeed then
			print("GameClient: Attempting to plant " .. self.FarmingState.selectedSeed .. " in plot")
			self:PlantSeedInPlot(plotModel, self.FarmingState.selectedSeed)
		else
			self:ShowNotification("No Seed Selected", 
				"Select a seed from your farming inventory first!", "warning")
			-- Auto-open farming UI if not visible
			if self.UI.SeedInventory and not self.UI.SeedInventory.Visible then
				self:ToggleFarmingUI()
			end
		end
	end
end

-- NEW: Calculate time remaining for crop growth
function GameClient:CalculateTimeRemaining(plotModel)
	local plantTime = plotModel:GetAttribute("PlantTime")
	local timeToGrow = plotModel:GetAttribute("TimeToGrow")

	if not plantTime or not timeToGrow then return nil end

	local elapsed = os.time() - plantTime
	local remaining = timeToGrow - elapsed

	if remaining <= 0 then return "Ready!" end

	local minutes = math.floor(remaining / 60)
	local seconds = remaining % 60

	if minutes > 0 then
		return minutes .. "m " .. seconds .. "s"
	else
		return seconds .. "s"
	end
end

-- FIXED: Enhanced planting with proper error handling
function GameClient:PlantSeedInPlot(plotModel, seedType)
	-- Ensure remote events exist
	if not self.RemoteEvents.PlantSeed then
		-- Try to find it
		local gameRemotes = game:GetService("ReplicatedStorage"):FindFirstChild("GameRemotes")
		if gameRemotes then
			self.RemoteEvents.PlantSeed = gameRemotes:FindFirstChild("PlantSeed")
		end

		if not self.RemoteEvents.PlantSeed then
			warn("GameClient: PlantSeed remote event not found")
			self:ShowNotification("Error", "Planting system not available", "error")
			return
		end
	end

	print("GameClient: Firing PlantSeed event with:", plotModel.Name, seedType)

	-- Fire server event
	local success, errorMsg = pcall(function()
		self.RemoteEvents.PlantSeed:FireServer(plotModel, seedType)
	end)

	if not success then
		warn("GameClient: Failed to fire PlantSeed event:", errorMsg)
		self:ShowNotification("Error", "Failed to plant seed", "error")
		return
	end

	-- Visual feedback
	self:CreatePlantingEffect(plotModel)

	-- Update inventory display after a delay
	spawn(function()
		wait(1) -- Wait for server response
		if self.UI.SeedInventory and self.UI.SeedInventory.Visible then
			self:UpdateSeedInventory()
		end
	end)

	print("GameClient: Planting request sent successfully")
end

function GameClient:EnsureFarmingRemotes()
	local gameRemotes = game:GetService("ReplicatedStorage"):WaitForChild("GameRemotes", 10)
	if not gameRemotes then
		warn("GameClient: GameRemotes not found")
		return false
	end

	-- Get planting remotes
	self.RemoteEvents.PlantSeed = gameRemotes:FindFirstChild("PlantSeed")
	self.RemoteEvents.HarvestCrop = gameRemotes:FindFirstChild("HarvestCrop")

	if not self.RemoteEvents.PlantSeed then
		warn("GameClient: PlantSeed remote not found")
	end

	if not self.RemoteEvents.HarvestCrop then
		warn("GameClient: HarvestCrop remote not found")
	end

	return self.RemoteEvents.PlantSeed and self.RemoteEvents.HarvestCrop
end

-- Harvest crop from plot
function GameClient:HarvestPlot(plotModel)
	if not self.RemoteEvents.HarvestCrop then
		warn("GameClient: HarvestCrop remote event not found")
		return
	end

	-- Fire server event
	self.RemoteEvents.HarvestCrop:FireServer(plotModel)

	-- Visual feedback
	self:CreateHarvestEffect(plotModel)
end
-- Enhanced planting spot management
GameClient.PlantingSpots = {
	activeSpots = {},
	glowTweens = {},
	selectedSpot = nil
}

-- Setup planting spot interactions
function GameClient:SetupPlantingSpotInteractions()
	print("GameClient: Setting up planting spot interactions...")

	-- Listen for farming mode changes
	spawn(function()
		while true do
			wait(0.1)
			self:UpdatePlantingSpotVisuals()
		end
	end)
end

-- Update planting spot visuals based on farming state
function GameClient:UpdatePlantingSpotVisuals()
	if not self.FarmingState then return end

	local isPlantingMode = self.FarmingState.isPlantingMode
	local selectedSeed = self.FarmingState.selectedSeed

	-- Find all planting spots in the workspace
	local playerName = game:GetService("Players").LocalPlayer.Name
	local areas = workspace:FindFirstChild("Areas")
	if not areas then return end

	local starterMeadow = areas:FindFirstChild("Starter Meadow")
	if not starterMeadow then return end

	local farmArea = starterMeadow:FindFirstChild("Farm")
	if not farmArea then return end

	local playerFarm = farmArea:FindFirstChild(playerName .. "_Farm")
	if not playerFarm then return end

	-- Update all planting spots
	for _, plotModel in pairs(playerFarm:GetChildren()) do
		if plotModel:IsA("Model") and plotModel.Name:find("FarmPlot") then
			local plantingSpotsFolder = plotModel:FindFirstChild("PlantingSpots")
			if plantingSpotsFolder then
				for _, spotModel in pairs(plantingSpotsFolder:GetChildren()) do
					if spotModel:IsA("Model") and spotModel.Name:find("PlantingSpot") then
						self:UpdateSingleSpotVisual(spotModel, isPlantingMode, selectedSeed)
					end
				end
			end
		end
	end
end

-- Update individual spot visual
function GameClient:UpdateSingleSpotVisual(spotModel, isPlantingMode, selectedSeed)
	local glowBorder = spotModel:FindFirstChild("GlowBorder")
	if not glowBorder then return end

	local spotNumber = spotModel:GetAttribute("SpotNumber") or 1
	local isEmpty = spotModel:GetAttribute("IsEmpty") ~= false
	local plantType = spotModel:GetAttribute("PlantType") or ""
	local growthStage = spotModel:GetAttribute("GrowthStage") or 0

	-- Determine visual state
	local targetColor, targetTransparency, shouldPulse

	if isEmpty and isPlantingMode and selectedSeed then
		-- Empty spot, ready for planting
		targetColor = Color3.fromRGB(100, 255, 100) -- Bright green
		targetTransparency = 0.3
		shouldPulse = true
	elseif isEmpty then
		-- Empty spot, not in planting mode
		targetColor = Color3.fromRGB(150, 150, 150) -- Gray
		targetTransparency = 0.8
		shouldPulse = false
	elseif plantType ~= "" and growthStage >= 4 then
		-- Ready to harvest
		targetColor = Color3.fromRGB(255, 215, 0) -- Gold
		targetTransparency = 0.4
		shouldPulse = true
	elseif plantType ~= "" then
		-- Growing crop
		local growthPercent = growthStage / 4
		targetColor = Color3.fromRGB(
			100 + (155 * growthPercent), -- Red component increases
			255 - (100 * growthPercent), -- Green decreases slightly
			100 -- Blue stays low
		)
		targetTransparency = 0.6
		shouldPulse = false
	else
		-- Default state
		targetColor = Color3.fromRGB(100, 100, 100)
		targetTransparency = 0.9
		shouldPulse = false
	end

	-- Apply visual changes
	glowBorder.Color = targetColor
	glowBorder.Transparency = targetTransparency

	-- Update corners
	for i = 1, 4 do
		local corner = spotModel:FindFirstChild("Corner" .. i)
		if corner then
			corner.Color = targetColor
			corner.Transparency = targetTransparency + 0.2
		end
	end

	-- Handle pulsing animation
	local spotId = tostring(spotModel)
	if shouldPulse and not self.PlantingSpots.glowTweens[spotId] then
		-- Start pulsing
		local pulseInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		local pulseTween = game:GetService("TweenService"):Create(glowBorder, pulseInfo, {
			Transparency = math.min(targetTransparency + 0.3, 1)
		})
		pulseTween:Play()
		self.PlantingSpots.glowTweens[spotId] = pulseTween

	elseif not shouldPulse and self.PlantingSpots.glowTweens[spotId] then
		-- Stop pulsing
		self.PlantingSpots.glowTweens[spotId]:Cancel()
		self.PlantingSpots.glowTweens[spotId] = nil
	end
end

-- Handle planting spot clicks
function GameClient:HandlePlantingSpotClick(spotModel, plotModel)
	if not self.FarmingState or not self.FarmingState.isPlantingMode then
		self:ShowNotification("Not in Planting Mode", "Select a seed first to enter planting mode!", "warning")
		return
	end

	local selectedSeed = self.FarmingState.selectedSeed
	if not selectedSeed then
		self:ShowNotification("No Seed Selected", "Select a seed from your farming inventory!", "warning")
		return
	end

	local spotNumber = spotModel:GetAttribute("SpotNumber")
	local isEmpty = spotModel:GetAttribute("IsEmpty") ~= false

	if not isEmpty then
		local plantType = spotModel:GetAttribute("PlantType") or ""
		local growthStage = spotModel:GetAttribute("GrowthStage") or 0

		if growthStage >= 4 then
			-- Ready to harvest
			self:HarvestFromSpot(spotModel, plotModel, spotNumber)
		else
			local progress = math.floor((growthStage / 4) * 100)
			self:ShowNotification("Still Growing", 
				plantType:gsub("_seeds", "") .. " is " .. progress .. "% grown", "info")
		end
	else
		-- Plant seed in this spot
		self:PlantSeedInSpot(spotModel, plotModel, spotNumber, selectedSeed)
	end
end

-- Plant seed in specific spot
function GameClient:PlantSeedInSpot(spotModel, plotModel, spotNumber, seedType)
	if not self.RemoteEvents.PlantSeed then
		warn("GameClient: PlantSeed remote event not found")
		return
	end

	-- Fire server event with spot information
	self.RemoteEvents.PlantSeed:FireServer(plotModel, seedType, spotNumber)

	-- Immediate visual feedback
	spotModel:SetAttribute("IsEmpty", false)
	spotModel:SetAttribute("PlantType", seedType)
	spotModel:SetAttribute("GrowthStage", 1)

	-- Create planting effect at spot
	self:CreateSpotPlantingEffect(spotModel)

	print("GameClient: Planted " .. seedType .. " in spot " .. spotNumber)
end

-- Create planting effect for specific spot
function GameClient:CreateSpotPlantingEffect(spotModel)
	local plantingArea = spotModel:FindFirstChild("PlantingArea")
	if not plantingArea then return end

	local spotCenter = plantingArea.Position

	-- Create sparkles at the spot
	for i = 1, 6 do
		local sparkle = Instance.new("Part")
		sparkle.Name = "PlantingSparkle"
		sparkle.Size = Vector3.new(0.2, 0.2, 0.2)
		sparkle.Shape = Enum.PartType.Ball
		sparkle.Material = Enum.Material.Neon
		sparkle.Color = Color3.fromRGB(100, 255, 100)
		sparkle.CanCollide = false
		sparkle.Anchored = true
		sparkle.Position = spotCenter + Vector3.new(
			math.random(-1, 1),
			math.random(0, 2),
			math.random(-1, 1)
		)
		sparkle.Parent = workspace

		-- Animate sparkle
		local tween = game:GetService("TweenService"):Create(sparkle,
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
end

-- Initialize planting spots when farming system starts
function GameClient:InitializePlantingSpots()
	spawn(function()
		wait(1) -- Wait for farm plots to load
		self:SetupPlantingSpotInteractions()

		-- Connect click detectors
		local playerName = game:GetService("Players").LocalPlayer.Name
		self:ConnectPlantingSpotClicks(playerName)
	end)
end

-- Connect click detectors for all planting spots
function GameClient:ConnectPlantingSpotClicks(playerName)
	local areas = workspace:FindFirstChild("Areas")
	if not areas then return end

	local starterMeadow = areas:FindFirstChild("Starter Meadow")
	if not starterMeadow then return end

	local farmArea = starterMeadow:FindFirstChild("Farm")
	if not farmArea then return end

	local playerFarm = farmArea:FindFirstChild(playerName .. "_Farm")
	if not playerFarm then return end

	-- Connect clicks for all planting spots
	for _, plotModel in pairs(playerFarm:GetChildren()) do
		if plotModel:IsA("Model") and plotModel.Name:find("FarmPlot") then
			local plantingSpotsFolder = plotModel:FindFirstChild("PlantingSpots")
			if plantingSpotsFolder then
				for _, spotModel in pairs(plantingSpotsFolder:GetChildren()) do
					if spotModel:IsA("Model") and spotModel.Name:find("PlantingSpot") then
						local plantingArea = spotModel:FindFirstChild("PlantingArea")
						if plantingArea then
							local clickDetector = plantingArea:FindFirstChild("ClickDetector")
							if clickDetector then
								clickDetector.MouseClick:Connect(function(player)
									if player == game:GetService("Players").LocalPlayer then
										self:HandlePlantingSpotClick(spotModel, plotModel)
									end
								end)
							end
						end
					end
				end
			end
		end
	end

	print("GameClient: Connected click detectors for all planting spots")
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
		local tween = game:GetService("TweenService"):Create(sparkle,
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
		local tween = game:GetService("TweenService"):Create(sparkle,
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
		--sound.Pitch = 1.2
	elseif soundType == "harvest" then
		sound.SoundId = "rbxasset://sounds/electronicpingsharp.wav"
		sound.Volume = 0.5
		--sound.Pitch = 0.8
	end

	sound.Parent = character.HumanoidRootPart

	pcall(function()
		sound:Play()
	end)

	game:GetService("Debris"):AddItem(sound, 2)
end

-- Initialize farming system when player joins
function GameClient:InitializeFarmingSystem()
	spawn(function()
		wait(3)
		self:SetupFarmingInterface()
		self:InitializePlantingSpots() -- Add this line

		local playerData = self:GetPlayerData()
		if playerData and playerData.purchaseHistory and playerData.purchaseHistory.farm_plot_starter then
			self:ShowNotification("Farming Available", 
				"Press F to open your farming interface! Click on glowing spots to plant seeds.", "info")
		end
	end)
end


-- Call this in your main GameClient initialization
-- Add this line to your GameClient:Initialize() function:
-- self:InitializeFarmingSystem()

-- Make farming system available for other scripts

-- Setup Remote Connections
-- FIXED: Setup Remote Connections with better error handling
function GameClient:SetupRemoteConnections()
	local remoteFolder = ReplicatedStorage:WaitForChild("GameRemotes", 10)
	if not remoteFolder then
		warn("GameClient: Could not find GameRemotes folder")
		return
	end

	-- Get all remote events
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
		-- FIXED: Declare targetPart as local
		local targetPart = nil
		-- Find any BasePart in the model
		for _, part in pairs(pet:GetDescendants()) do
			if part:IsA("BasePart") then
				targetPart = part
				break
			end
		end

		if targetPart then
			petPosition = targetPart.Position
		end
	end

	if not petPosition then return end

	local distance = (playerPosition - petPosition).Magnitude

	-- Check if within glow range
	if distance <= self.ProximitySystem.glowRadius and not pet:GetAttribute("HasGlow") then
		self:AddPetGlow(pet)
	elseif distance > self.ProximitySystem.glowRadius and pet:GetAttribute("HasGlow") then
		self:RemovePetGlow(pet)
	end

	-- Check if within collection range
	if distance <= self.ProximitySystem.collectRadius then
		-- Auto-collect or trigger collection
		spawn(function()
			self:HandleWildPetCollection(Players.LocalPlayer, pet)
		end)
	end
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
	local success, errorMsg = pcall(function()
		local sound = Instance.new("Sound")

		-- Try multiple sound options as fallbacks
		local soundOptions = {
			"rbxasset://sounds/electronicpingsharp.wav",
			"rbxasset://sounds/button_click.wav",
			"rbxasset://sounds/impact_water.mp3"
		}

		local soundWorked = false
		for _, soundId in ipairs(soundOptions) do
			sound.SoundId = soundId
			sound.Volume = 0.5
			sound.Parent = workspace

			local playSuccess = pcall(function()
				sound:Play()
				soundWorked = true
			end)

			if playSuccess and soundWorked then
				break
			end
		end

		if not soundWorked then
			print("GameClient: Sound not available, using visual feedback only")
		end

		-- Clean up sound
		spawn(function()
			wait(2)
			if sound and sound.Parent then
				sound:Destroy()
			end
		end)
	end)

	if not success then
		print("GameClient: Collection sound failed: " .. tostring(errorMsg))
	end
end

-- Pet selling system
function GameClient:ToggleSellingMode()
	self.SellingMode.isActive = not self.SellingMode.isActive
	self.SellingMode.selectedPets = {}
	self.SellingMode.totalValue = 0

	self:RefreshPetsMenu()
	self:UpdateSellingUI()
end

-- FIXED: Calculate correct pet sell values
function GameClient:CalculatePetSellValue(petData)
	-- Add validation
	if not petData or type(petData) ~= "table" then
		return 25 -- Default common pet value
	end

	-- Load ItemConfig safely
	local config = loadItemConfig()
	if config and config.Pets and petData.type then
		local petConfig = config.Pets[petData.type]
		if petConfig and petConfig.sellValue then
			local baseValue = petConfig.sellValue
			local level = tonumber(petData.level) or 1
			local levelMultiplier = 1 + ((level - 1) * 0.1)
			return math.floor(baseValue * levelMultiplier)
		end
	end

	-- Fallback to hardcoded values
	local baseValues = {
		Common = 25,
		Uncommon = 75,
		Rare = 150,
		Epic = 300,
		Legendary = 750
	}

	local rarity = petData.rarity or "Common"
	local baseValue = baseValues[rarity] or baseValues.Common
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
	elseif self.UIState.CurrentPage == "Farm" then
		self:RefreshFarmMenu()
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

	-- FIXED: Show appropriate message - no coins for collecting
	if coinsAwarded > 0 then
		self:ShowNotification("Pet Collected!", 
			petData.name .. " (+" .. coinsAwarded .. " coins)", "success")
	else
		self:ShowNotification("Pet Collected!", 
			petData.name .. " (Sell in Pets menu for coins)", "success")
	end

	print("GameClient: Collected " .. petData.name .. " (coins awarded: " .. coinsAwarded .. ")")
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

	-- FIXED: Request updated player data immediately after purchase
	if self.RemoteFunctions.GetPlayerData then
		spawn(function()
			wait(0.5) -- Small delay for server processing
			local success, updatedData = pcall(function()
				return self.RemoteFunctions.GetPlayerData:InvokeServer()
			end)

			if success and updatedData then
				self.PlayerData = updatedData

				-- Update all UIs
				if self.RemoteEvents.PlayerDataUpdated then
					self.RemoteEvents.PlayerDataUpdated:FireClient(Players.LocalPlayer, updatedData)
				end

				-- Refresh farming inventory if visible
				if self.UI.SeedInventory and self.UI.SeedInventory.Visible then
					self:UpdateSeedInventory()
				end

				-- Refresh shop if visible
				if self.UIState.CurrentPage == "Shop" then
					self:RefreshShopMenu()
				end
			end
		end)
	end

	-- Special success message for farm items
	if itemId == "farm_plot_starter" then
		self:ShowNotification("🌾 Farm Plot Created!", 
			"Your farm plot has been created in Starter Meadow! Check it out and start planting!", "success")
	elseif itemId:find("_seeds") then
		self:ShowNotification("Seeds Added!", 
			"Added " .. quantity .. "x " .. itemName .. " to your farming inventory!", "success")
	else
		self:ShowNotification("Purchase Successful!", 
			"Bought " .. (quantity > 1 and (quantity .. "x ") or "") .. itemName .. " for " .. cost .. " " .. currency, 
			"success")
	end

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

-- FIXED: Menu Content Management - Prevent Duplication
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

-- Pets Menu
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

	-- Clear existing content
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
				-- Create fallback card if pet card creation fails
				local fallbackCard = Instance.new("Frame")
				fallbackCard.Name = "FallbackPetCard_" .. i
				fallbackCard.BackgroundColor3 = Color3.fromRGB(100, 50, 50)
				fallbackCard.BorderSizePixel = 0
				fallbackCard.LayoutOrder = i
				fallbackCard.Parent = contentArea

				local errorLabel = Instance.new("TextLabel")
				errorLabel.Size = UDim2.new(1, 0, 1, 0)
				errorLabel.BackgroundTransparency = 1
				errorLabel.Text = "Pet Error\n" .. (petData.name or "Unknown")
				errorLabel.TextColor3 = Color3.new(1, 1, 1)
				errorLabel.TextScaled = true
				errorLabel.Font = Enum.Font.SourceSans
				errorLabel.Parent = fallbackCard

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
end


-- Add glow effect to pet
function GameClient:AddPetGlow(pet)
	if not pet or pet:GetAttribute("HasGlow") then return end

	-- FIXED: Declare targetPart as local
	local targetPart = nil
	if pet:IsA("Model") and pet.PrimaryPart then
		targetPart = pet.PrimaryPart
	elseif pet:IsA("BasePart") then
		targetPart = pet
	else
		-- Find any BasePart in the model
		for _, part in pairs(pet:GetDescendants()) do
			if part:IsA("BasePart") then
				targetPart = part
				break
			end
		end
	end

	if not targetPart then return end

	-- FIXED: Declare glowEffect as local
	local glowEffect = Instance.new("Part")
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


function GameClient:RefreshShopMenu()
	local menu = self.UI.Menus.Shop
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	-- FIXED: Only clear the content, not the scrolling frame itself
	for _, child in ipairs(contentArea:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "ContentArea" then
			child:Destroy()
		elseif child:IsA("UIGridLayout") or child:IsA("UIListLayout") then
			-- Don't destroy layouts, just clear them
		end
	end

	-- Load shop items from server
	if self.RemoteFunctions.GetShopItems then
		local success, shopItems = pcall(function()
			return self.RemoteFunctions.GetShopItems:InvokeServer()
		end)

		if success and shopItems then
			self.Cache.ShopItems = shopItems

			-- FIXED: Ensure layout exists
			local layout = contentArea:FindFirstChild("UIListLayout")
			if not layout then
				layout = Instance.new("UIListLayout")
				layout.SortOrder = Enum.SortOrder.LayoutOrder
				layout.Padding = UDim.new(0, 10)
				layout.Parent = contentArea
			end

			-- Check if player has farm plot
			local playerData = self:GetPlayerData()
			local hasFarmPlot = playerData and playerData.purchaseHistory and playerData.purchaseHistory.farm_plot_starter

			-- Create shop categories
			local categories = {
				{name = "🌾 Farming System", items = {}, priority = 1},
				{name = "💰 Upgrades", items = {}, priority = 2},
				{name = "🌱 Seeds & Tools", items = {}, priority = 3},
				{name = "📦 Seed Packs", items = {}, priority = 4}
			}

			-- Sort items into categories
			for itemId, item in pairs(shopItems) do
				if itemId == "farm_plot_starter" then
					if not hasFarmPlot then
						table.insert(categories[1].items, {id = itemId, data = item})
					end
				elseif itemId == "farm_plot_upgrade" then
					if hasFarmPlot then
						table.insert(categories[1].items, {id = itemId, data = item})
					end
				elseif item.type == "upgrade" and not item.requiresFarmPlot then
					table.insert(categories[2].items, {id = itemId, data = item})
				elseif item.type == "seed" then
					if hasFarmPlot then
						table.insert(categories[3].items, {id = itemId, data = item})
					end
				elseif item.type == "egg" then
					if hasFarmPlot then
						table.insert(categories[4].items, {id = itemId, data = item})
					end
				else
					table.insert(categories[2].items, {id = itemId, data = item})
				end
			end

			-- Create UI for each category that has items
			for i, category in ipairs(categories) do
				if #category.items > 0 then
					self:CreateShopCategory(contentArea, category.name, category.items, i)
				end
			end

			-- Add helpful message if no farm plot
			if not hasFarmPlot then
				self:CreateFarmPlotPromotion(contentArea)
			end

			-- FIXED: Update canvas size properly
			spawn(function()
				wait(0.1)
				if layout and layout.Parent then
					contentArea.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
				end
			end)

		else
			-- Show error message
			local errorLabel = Instance.new("TextLabel")
			errorLabel.Size = UDim2.new(0.8, 0, 0.2, 0)
			errorLabel.Position = UDim2.new(0.5, 0, 0.4, 0)
			errorLabel.AnchorPoint = Vector2.new(0.5, 0.5)
			errorLabel.BackgroundTransparency = 1
			errorLabel.Text = "Failed to load shop items\nPlease try again later"
			errorLabel.TextColor3 = Color3.new(0.8, 0.3, 0.3)
			errorLabel.TextScaled = true
			errorLabel.Font = Enum.Font.SourceSansSemibold
			errorLabel.Parent = contentArea
		end
	end
end
-- Create shop category
function GameClient:CreateShopCategory(parent, categoryName, items, layoutOrder)
	local categoryFrame = Instance.new("Frame")
	categoryFrame.Name = categoryName .. "_Category"
	categoryFrame.Size = UDim2.new(1, 0, 0, 60 + (#items * 80))
	categoryFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	categoryFrame.BorderSizePixel = 0
	categoryFrame.LayoutOrder = layoutOrder
	categoryFrame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.02, 0)
	corner.Parent = categoryFrame

	-- Category title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	title.BorderSizePixel = 0
	title.Text = categoryName
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = categoryFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0.02, 0)
	titleCorner.Parent = title

	-- Items container
	local itemsContainer = Instance.new("Frame")
	itemsContainer.Size = UDim2.new(1, -20, 1, -50)
	itemsContainer.Position = UDim2.new(0, 10, 0, 45)
	itemsContainer.BackgroundTransparency = 1
	itemsContainer.Parent = categoryFrame

	local itemsLayout = Instance.new("UIListLayout")
	itemsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	itemsLayout.Padding = UDim.new(0, 5)
	itemsLayout.Parent = itemsContainer

	-- Add items
	for i, itemInfo in ipairs(items) do
		self:CreateShopItem(itemsContainer, itemInfo.id, itemInfo.data, i)
	end
end

-- Create shop item
function GameClient:CreateShopItem(parent, itemId, itemData, layoutOrder)
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = itemId .. "_Item"
	itemFrame.Size = UDim2.new(1, 0, 0, 70)
	itemFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	itemFrame.BorderSizePixel = 0
	itemFrame.LayoutOrder = layoutOrder
	itemFrame.Parent = parent

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0.05, 0)
	itemCorner.Parent = itemFrame

	-- Item name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.4, 0, 0.5, 0)
	nameLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = itemData.name or itemId
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = itemFrame

	-- Item description
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.4, 0, 0.4, 0)
	descLabel.Position = UDim2.new(0.05, 0, 0.55, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = itemData.description or "No description"
	descLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	descLabel.TextScaled = true
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextWrapped = true
	descLabel.Parent = itemFrame

	-- Price label
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(0.2, 0, 0.4, 0)
	priceLabel.Position = UDim2.new(0.5, 0, 0.3, 0)
	priceLabel.BackgroundTransparency = 1
	local currencyIcon = (itemData.currency == "gems") and "💎" or "💰"
	priceLabel.Text = (itemData.price or 0) .. " " .. currencyIcon
	priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	priceLabel.TextScaled = true
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.Parent = itemFrame

	-- Buy button
	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(0.2, 0, 0.6, 0)
	buyButton.Position = UDim2.new(0.75, 0, 0.2, 0)
	buyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	buyButton.BorderSizePixel = 0
	buyButton.Text = "Buy"
	buyButton.TextColor3 = Color3.new(1, 1, 1)
	buyButton.TextScaled = true
	buyButton.Font = Enum.Font.GothamBold
	buyButton.Parent = itemFrame

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0.1, 0)
	buyCorner.Parent = buyButton

	-- Check if player can afford
	local playerData = self.PlayerData
	if playerData then
		local currency = (itemData.currency or "coins"):lower()
		local playerCurrency = playerData[currency] or 0
		local canAfford = playerCurrency >= (itemData.price or 0)

		if not canAfford then
			buyButton.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
			buyButton.Text = "Can't Afford"
			buyButton.Active = false
		end
	end

	-- Buy button click
	buyButton.MouseButton1Click:Connect(function()
		if self.RemoteEvents.PurchaseItem then
			self.RemoteEvents.PurchaseItem:FireServer(itemId, 1)
		end
	end)
end

-- FIXED: Farm Menu - Prevent Duplication
function GameClient:RefreshFarmMenu()
	local menu = self.UI.Menus.Farm
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	-- FIXED: Clear existing content to prevent duplication
	for _, child in ipairs(contentArea:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Safe creation with error handling
	local success, errorMsg = pcall(function()
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

	-- Status section
	local statusSection = Instance.new("Frame")
	statusSection.Name = "StatusSection"
	statusSection.Size = UDim2.new(1, 0, 0.7, 0)
	statusSection.Position = UDim2.new(0, 0, 0.3, 0)
	statusSection.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	statusSection.BorderSizePixel = 0
	statusSection.Parent = contentArea

	local statusCorner = Instance.new("UICorner")
	statusCorner.CornerRadius = UDim.new(0.02, 0)
	statusCorner.Parent = statusSection

	local statusTitle = Instance.new("TextLabel")
	statusTitle.Size = UDim2.new(1, 0, 0.2, 0)
	statusTitle.BackgroundTransparency = 1
	statusTitle.Text = "📈 Farm Status"
	statusTitle.TextColor3 = Color3.new(1, 1, 1)
	statusTitle.TextScaled = true
	statusTitle.Font = Enum.Font.SourceSansSemibold
	statusTitle.Parent = statusSection

	local statusText = Instance.new("TextLabel")
	statusText.Size = UDim2.new(0.9, 0, 0.8, 0)
	statusText.Position = UDim2.new(0.05, 0, 0.2, 0)
	statusText.BackgroundTransparency = 1
	statusText.Text = "Farm plots: 3\nSeeds available: Check your inventory\nPig status: Fed 0 times, Size: 1.0x\n\nVisit the farming area in the game world to plant seeds and harvest crops!"
	statusText.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	statusText.TextScaled = true
	statusText.TextWrapped = true
	statusText.Font = Enum.Font.SourceSans
	statusText.Parent = statusSection
	end)

	if not success then
		warn("GameClient: Error creating farm menu: " .. tostring(errorMsg))

		-- Create fallback error display
		local errorLabel = Instance.new("TextLabel")
		errorLabel.Size = UDim2.new(0.8, 0, 0.2, 0)
		errorLabel.Position = UDim2.new(0.5, 0, 0.4, 0)
		errorLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		errorLabel.BackgroundTransparency = 1
		errorLabel.Text = "Farm menu temporarily unavailable\nPlease try again later"
		errorLabel.TextColor3 = Color3.new(0.8, 0.3, 0.3)
		errorLabel.TextScaled = true
		errorLabel.Font = Enum.Font.SourceSansSemibold
		errorLabel.Parent = contentArea
	end
end
-- Settings Menu
function GameClient:RefreshSettingsMenu()
	local menu = self.UI.Menus.Settings
	if not menu then return end

	local contentArea = menu:FindFirstChild("ContentArea")
	if not contentArea then return end

	-- FIXED: Clear existing content to prevent duplication
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

	-- Controls Section
	local controlsSection = Instance.new("Frame")
	controlsSection.Name = "ControlsSection"
	controlsSection.Size = UDim2.new(1, 0, 0.35, 0)
	controlsSection.Position = UDim2.new(0, 0, 0.35, 0)
	controlsSection.BackgroundColor3 = Color3.fromRGB(50, 40, 50)
	controlsSection.BorderSizePixel = 0
	controlsSection.Parent = contentArea

	local controlsCorner = Instance.new("UICorner")
	controlsCorner.CornerRadius = UDim.new(0.02, 0)
	controlsCorner.Parent = controlsSection

	local controlsTitle = Instance.new("TextLabel")
	controlsTitle.Size = UDim2.new(1, 0, 0.3, 0)
	controlsTitle.BackgroundTransparency = 1
	controlsTitle.Text = "🎮 Controls"
	controlsTitle.TextColor3 = Color3.new(1, 1, 1)
	controlsTitle.TextScaled = true
	controlsTitle.Font = Enum.Font.SourceSansSemibold
	controlsTitle.Parent = controlsSection

	local controlsText = Instance.new("TextLabel")
	controlsText.Size = UDim2.new(0.9, 0, 0.7, 0)
	controlsText.Position = UDim2.new(0.05, 0, 0.3, 0)
	controlsText.BackgroundTransparency = 1
	controlsText.Text = "• Walk near pets to collect them\n• Use navigation bar to open menus\n• ESC to close menus\n• SHIFT to sprint (if upgraded)"
	controlsText.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	controlsText.TextScaled = true
	controlsText.TextWrapped = true
	controlsText.Font = Enum.Font.SourceSans
	controlsText.TextXAlignment = Enum.TextXAlignment.Left
	controlsText.Parent = controlsSection

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
	infoText.Text = "Pet Palace v1.0\nWalk near pets to collect them!\nSell pets for coins in the Pets menu.\nBuy upgrades in the Shop menu.\n\nMade with ❤️"
	infoText.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	infoText.TextScaled = true
	infoText.TextWrapped = true
	infoText.Font = Enum.Font.SourceSans
	infoText.Parent = infoSection
end

-- Enhanced Pet Card Creation (SAFE VERSION)
function GameClient:CreatePetCard(petData, parent, index)
	-- Enhanced validation
	if not petData then
		error("CreatePetCard: petData is nil")
	end
	if not parent then
		error("CreatePetCard: parent is nil")
	end
	if type(petData) ~= "table" then
		error("CreatePetCard: petData must be a table, got " .. type(petData))
	end

	-- Safe pet data with defaults and validation
	local safePetData = {
		id = petData.id or "unknown_" .. math.random(1000, 9999),
		name = petData.name or petData.displayName or petData.type or "Unknown Pet",
		type = petData.type or "unknown",
		rarity = petData.rarity or "Common",
		level = tonumber(petData.level) or 1
	}

	-- Validate required fields
	if not safePetData.id or safePetData.id == "" then
		safePetData.id = "unknown_" .. tick()
	end

	index = tonumber(index) or 1

	-- Create card container
	local card = Instance.new("Frame")
	card.Name = "PetCard_" .. safePetData.id
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
	emoji.Text = self:GetPetEmoji(safePetData.type)
	emoji.TextScaled = true
	emoji.Font = Enum.Font.SourceSansSemibold
	emoji.Parent = image

	-- Pet name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.9, 0, 0.12, 0)
	nameLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	nameLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = safePetData.name
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
	rarityLabel.Text = safePetData.rarity:upper()
	rarityLabel.TextColor3 = self:GetRarityColor(safePetData.rarity)
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.SourceSansSemibold
	rarityLabel.Parent = card

	-- FIXED: Sell value display - Use correct calculation
	local sellValue = self:CalculatePetSellValue(safePetData)
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
		pcall(function()
			self:SellPet(safePetData)
		end)
	end)

	return card
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

function GameClient:UpdateSellingUI()
	-- Placeholder for selling UI updates
	print("GameClient: Updated selling UI")
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
_G.FarmingClient = {
	GetSelectedSeed = function() 
		if _G.GameClient and _G.GameClient.FarmingState then
			return _G.GameClient.FarmingState.selectedSeed 
		end
		return nil
	end,
	IsPlantingMode = function() 
		if _G.GameClient and _G.GameClient.FarmingState then
			return _G.GameClient.FarmingState.isPlantingMode 
		end
		return false
	end,
	OpenFarmingUI = function() 
		if _G.GameClient and _G.GameClient.ToggleFarmingUI then
			return _G.GameClient:ToggleFarmingUI() 
		end
		return nil
	end
}


_G.GameClient = GameClient

-- Make farming system available for other scripts with proper references
_G.FarmingClient = {
	GetSelectedSeed = function() 
		return _G.GameClient and _G.GameClient.FarmingState and _G.GameClient.FarmingState.selectedSeed or nil
	end,
	IsPlantingMode = function() 
		return _G.GameClient and _G.GameClient.FarmingState and _G.GameClient.FarmingState.isPlantingMode or false
	end,
	OpenFarmingUI = function() 
		if _G.GameClient and _G.GameClient.ToggleFarmingUI then
			return _G.GameClient:ToggleFarmingUI() 
		end
		return nil
	end
}

return GameClient