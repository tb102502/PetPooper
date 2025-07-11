--[[
    COMPLETE CowAdminPanel.server.lua - With Full GUI Implementation
    Place in: ServerScriptService/Admin/CowAdminPanel.server.lua
    
    COMPLETE FEATURES:
    ✅ Full working admin GUI with buttons
    ✅ F9 toggle key support
    ✅ All cow management functions
    ✅ System monitoring and fixes
    ✅ Currency management
    ✅ Player data reset options
]]

local CowAdminPanel = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Configuration
local ADMIN_USERS = {"TommySalami311"} -- UPDATE WITH YOUR USERNAME
local PANEL_KEY = Enum.KeyCode.F9

-- State
CowAdminPanel.AdminGUIs = {}
CowAdminPanel.MonitoringActive = false

-- ========== COMPLETE GUI CREATION ==========

function CowAdminPanel:SetupAdminGUI(player)
	print("CowAdminPanel: Creating full admin GUI for " .. player.Name)

	local playerGui = player:WaitForChild("PlayerGui")

	-- Remove existing GUI if it exists
	local existingGUI = playerGui:FindFirstChild("CowAdminPanel")
	if existingGUI then
		existingGUI:Destroy()
	end

	-- Create main ScreenGui
	local adminGUI = Instance.new("ScreenGui")
	adminGUI.Name = "CowAdminPanel"
	adminGUI.ResetOnSpawn = false
	adminGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	adminGUI.Parent = playerGui

	-- Create toggle button (always visible)
	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "ToggleButton"
	toggleButton.Size = UDim2.new(0, 120, 0, 40)
	toggleButton.Position = UDim2.new(0, 10, 0, 100) -- Top-left area
	toggleButton.BackgroundColor3 = Color3.fromRGB(60, 120, 180)
	toggleButton.BorderSizePixel = 0
	toggleButton.Text = "🐄 Admin Panel"
	toggleButton.TextColor3 = Color3.new(1, 1, 1)
	toggleButton.TextScaled = true
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.ZIndex = 100
	toggleButton.Parent = adminGUI

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0.2, 0)
	toggleCorner.Parent = toggleButton

	-- Create main panel (initially hidden)
	local mainPanel = Instance.new("Frame")
	mainPanel.Name = "MainPanel"
	mainPanel.Size = UDim2.new(0, 600, 0, 500)
	mainPanel.Position = UDim2.new(0.5, -300, 0.5, -250)
	mainPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	mainPanel.BorderSizePixel = 0
	mainPanel.Visible = false
	mainPanel.ZIndex = 50
	mainPanel.Parent = adminGUI

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0.02, 0)
	mainCorner.Parent = mainPanel

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 50)
	titleBar.Position = UDim2.new(0, 0, 0, 0)
	titleBar.BackgroundColor3 = Color3.fromRGB(60, 120, 180)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = mainPanel

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0.02, 0)
	titleCorner.Parent = titleBar

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(0.8, 0, 1, 0)
	titleLabel.Position = UDim2.new(0, 10, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "🐄 Cow Admin Panel"
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 40, 0, 30)
	closeButton.Position = UDim2.new(1, -45, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = titleBar

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0.2, 0)
	closeCorner.Parent = closeButton

	-- Content area
	local contentFrame = Instance.new("ScrollingFrame")
	contentFrame.Name = "ContentFrame"
	contentFrame.Size = UDim2.new(1, -20, 1, -70)
	contentFrame.Position = UDim2.new(0, 10, 0, 60)
	contentFrame.BackgroundTransparency = 1
	contentFrame.BorderSizePixel = 0
	contentFrame.ScrollBarThickness = 8
	contentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, 800)
	contentFrame.Parent = mainPanel

	-- Create button sections
	self:CreateButtonSection(contentFrame, "🐄 Cow Management", {
		{text = "Spawn Basic Cow", color = Color3.fromRGB(100, 200, 100), action = function() self:SpawnCow(player, "basic") end},
		{text = "Spawn Silver Cow", color = Color3.fromRGB(150, 150, 150), action = function() self:SpawnCow(player, "silver") end},
		{text = "Spawn Gold Cow", color = Color3.fromRGB(255, 215, 0), action = function() self:SpawnCow(player, "gold") end},
		{text = "Test Basic Effects", color = Color3.fromRGB(120, 180, 120), action = function() self:TestEffectsOnPlayerCows(player, "basic") end},
		{text = "Test Gold Effects", color = Color3.fromRGB(200, 160, 60), action = function() self:TestEffectsOnPlayerCows(player, "gold") end},
		{text = "Remove All Cows", color = Color3.fromRGB(200, 100, 100), action = function() self:RemoveAllPlayerCows(player) end}
	}, 0)

	self:CreateButtonSection(contentFrame, "🥛 Milking System", {
		{text = "Test Milking", color = Color3.fromRGB(100, 150, 255), action = function() self:TestMilkCollection(player) end},
		{text = "Force Milking GUI", color = Color3.fromRGB(120, 120, 200), action = function() self:ForceShowMilkingGUI(player) end},
		{text = "Clear Milking Session", color = Color3.fromRGB(180, 100, 100), action = function() self:ClearMilkingSession(player) end}
	}, 200)

	self:CreateButtonSection(contentFrame, "💰 Currency & Upgrades", {
		{text = "Give 1000 Coins", color = Color3.fromRGB(255, 215, 0), action = function() self:GiveCurrency(player, "coins", 1000) end},
		{text = "Give 100 Farm Tokens", color = Color3.fromRGB(100, 255, 100), action = function() self:GiveCurrency(player, "farmTokens", 100) end},
		{text = "All Pasture Expansions", color = Color3.fromRGB(139, 90, 43), action = function() self:GiveAllPastureExpansions(player) end},
		{text = "Give Auto Milker", color = Color3.fromRGB(180, 120, 255), action = function() self:GiveAutoMilker(player) end}
	}, 400)

	self:CreateButtonSection(contentFrame, "🔧 System Tools", {
		{text = "Show System Status", color = Color3.fromRGB(100, 150, 200), action = function() self:ShowSystemStatus(player) end},
		{text = "Fix Orphaned Cows", color = Color3.fromRGB(255, 165, 0), action = function() self:FixOrphanedCows(player) end},
		{text = "Reset Player Data", color = Color3.fromRGB(200, 50, 50), action = function() self:ConfirmResetPlayerData(player) end},
		{text = "Refresh Systems", color = Color3.fromRGB(120, 200, 120), action = function() self:RefreshSystems(player) end}
	}, 600)

	-- Store GUI reference
	self.AdminGUIs[player.UserId] = {
		gui = adminGUI,
		mainPanel = mainPanel,
		toggleButton = toggleButton,
		isVisible = false
	}

	-- Connect events
	toggleButton.MouseButton1Click:Connect(function()
		self:ToggleMainPanel(player)
	end)

	closeButton.MouseButton1Click:Connect(function()
		self:HideMainPanel(player)
	end)

	-- Setup F9 key detection
	self:SetupKeyDetection(player)

	print("CowAdminPanel: ✅ Complete GUI created for " .. player.Name)
end

function CowAdminPanel:CreateButtonSection(parent, title, buttons, yOffset)
	-- Section title
	local sectionTitle = Instance.new("TextLabel")
	sectionTitle.Name = title .. "_Title"
	sectionTitle.Size = UDim2.new(1, -20, 0, 30)
	sectionTitle.Position = UDim2.new(0, 10, 0, yOffset)
	sectionTitle.BackgroundTransparency = 1
	sectionTitle.Text = title
	sectionTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
	sectionTitle.TextScaled = true
	sectionTitle.Font = Enum.Font.GothamBold
	sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
	sectionTitle.Parent = parent

	-- Create buttons
	for i, buttonData in ipairs(buttons) do
		local button = Instance.new("TextButton")
		button.Name = buttonData.text:gsub(" ", "") .. "Button"
		button.Size = UDim2.new(0.48, 0, 0, 35)
		button.Position = UDim2.new(((i - 1) % 2) * 0.51, 0, 0, yOffset + 40 + (math.floor((i - 1) / 2) * 45))
		button.BackgroundColor3 = buttonData.color
		button.BorderSizePixel = 0
		button.Text = buttonData.text
		button.TextColor3 = Color3.new(1, 1, 1)
		button.TextScaled = true
		button.Font = Enum.Font.Gotham
		button.Parent = parent

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0.1, 0)
		buttonCorner.Parent = button

		-- Connect action
		button.MouseButton1Click:Connect(buttonData.action)

		-- Hover effect
		button.MouseEnter:Connect(function()
			local hoverTween = TweenService:Create(button,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad),
				{BackgroundColor3 = self:LightenColor(buttonData.color, 0.2)}
			)
			hoverTween:Play()
		end)

		button.MouseLeave:Connect(function()
			local leaveTween = TweenService:Create(button,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad),
				{BackgroundColor3 = buttonData.color}
			)
			leaveTween:Play()
		end)
	end
end

function CowAdminPanel:LightenColor(color, amount)
	return Color3.new(
		math.min(1, color.R + amount),
		math.min(1, color.G + amount),
		math.min(1, color.B + amount)
	)
end

-- ========== COMPLETE PANEL MANAGEMENT ==========

function CowAdminPanel:ToggleMainPanel(player)
	print("CowAdminPanel: Toggling main panel for " .. player.Name)

	local adminGUI = self.AdminGUIs[player.UserId]
	if not adminGUI then
		warn("CowAdminPanel: No GUI found for " .. player.Name)
		return
	end

	if adminGUI.isVisible then
		self:HideMainPanel(player)
	else
		self:ShowMainPanel(player)
	end
end

function CowAdminPanel:ShowMainPanel(player)
	local adminGUI = self.AdminGUIs[player.UserId]
	if not adminGUI then return end

	adminGUI.mainPanel.Visible = true
	adminGUI.isVisible = true

	-- Animate in
	adminGUI.mainPanel.Size = UDim2.new(0, 0, 0, 0)
	adminGUI.mainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)

	local showTween = TweenService:Create(adminGUI.mainPanel,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			Size = UDim2.new(0, 600, 0, 500),
			Position = UDim2.new(0.5, -300, 0.5, -250)
		}
	)
	showTween:Play()

	print("CowAdminPanel: ✅ Panel shown for " .. player.Name)
end

function CowAdminPanel:HideMainPanel(player)
	local adminGUI = self.AdminGUIs[player.UserId]
	if not adminGUI then return end

	adminGUI.isVisible = false

	-- Animate out
	local hideTween = TweenService:Create(adminGUI.mainPanel,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			Size = UDim2.new(0, 0, 0, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0)
		}
	)
	hideTween:Play()

	hideTween.Completed:Connect(function()
		adminGUI.mainPanel.Visible = false
	end)

	print("CowAdminPanel: ✅ Panel hidden for " .. player.Name)
end

function CowAdminPanel:SetupKeyDetection(player)
	-- Create RemoteEvent for F9 key detection
	local remotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "GameRemotes"
		remotes.Parent = ReplicatedStorage
	end

	local adminKeyEvent = remotes:FindFirstChild("AdminKeyPressed")
	if not adminKeyEvent then
		adminKeyEvent = Instance.new("RemoteEvent")
		adminKeyEvent.Name = "AdminKeyPressed"
		adminKeyEvent.Parent = remotes
	end

	-- Connect key event
	adminKeyEvent.OnServerEvent:Connect(function(playerWhoPressed, keyCode)
		if playerWhoPressed == player and keyCode == PANEL_KEY.Name and self:IsAdmin(player) then
			self:ToggleMainPanel(player)
		end
	end)

	-- Send client script to player
	local clientScript = [[
		local UserInputService = game:GetService("UserInputService")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local Players = game:GetService("Players")
		local LocalPlayer = Players.LocalPlayer

		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			
			if input.KeyCode == Enum.KeyCode.F9 then
				local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
				if gameRemotes then
					local adminKeyEvent = gameRemotes:FindFirstChild("AdminKeyPressed")
					if adminKeyEvent then
						adminKeyEvent:FireServer("F9")
					end
				end
			end
		end)
	]]

	-- Execute client script
	local clientRemote = remotes:FindFirstChild("ExecuteClientScript")
	if not clientRemote then
		clientRemote = Instance.new("RemoteEvent")
		clientRemote.Name = "ExecuteClientScript"
		clientRemote.Parent = remotes
	end

	clientRemote:FireClient(player, clientScript)
end

-- ========== ENHANCED SYSTEM FUNCTIONS ==========

function CowAdminPanel:ShowSystemStatus(player)
	local status = self:GetSystemStatus()
	print("=== SYSTEM STATUS FOR " .. player.Name .. " ===")
	print(status)
	print("===============================================")

	self:NotifyPlayer(player, "📊 System status logged to console")
end

function CowAdminPanel:FixOrphanedCows(player)
	print("CowAdminPanel: Fixing orphaned cows...")

	local fixed = 0
	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("Model") and obj.Name:find("cow_") then
			local owner = obj:GetAttribute("Owner")
			if not owner or not Players:FindFirstChild(owner) then
				obj:Destroy()
				fixed = fixed + 1
			end
		end
	end

	self:NotifyPlayer(player, "🔧 Fixed " .. fixed .. " orphaned cows!")
end

function CowAdminPanel:ForceShowMilkingGUI(player)
	print("CowAdminPanel: Force showing milking GUI for " .. player.Name)

	local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	if gameRemotes then
		local showPrompt = gameRemotes:FindFirstChild("ShowChairPrompt")
		if showPrompt then
			showPrompt:FireClient(player, "milking", {
				title = "🧪 Admin Test",
				subtitle = "Testing milking system",
				instruction = "Click or press space to test milking"
			})
			self:NotifyPlayer(player, "🧪 Force-showed milking GUI!")
		else
			self:NotifyPlayer(player, "❌ ShowChairPrompt event not found!")
		end
	else
		self:NotifyPlayer(player, "❌ GameRemotes not found!")
	end
end

function CowAdminPanel:ClearMilkingSession(player)
	print("CowAdminPanel: Clearing milking session for " .. player.Name)

	if _G.CowMilkingModule and _G.CowMilkingModule.ForceStopMilkingSession then
		local success = pcall(function()
			return _G.CowMilkingModule:ForceStopMilkingSession(player)
		end)

		if success then
			self:NotifyPlayer(player, "✅ Cleared milking session!")
		else
			self:NotifyPlayer(player, "❌ Failed to clear milking session!")
		end
	else
		-- Fallback: Hide GUI
		local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
		if gameRemotes then
			local hidePrompt = gameRemotes:FindFirstChild("HideChairPrompt")
			if hidePrompt then
				hidePrompt:FireClient(player)
				self:NotifyPlayer(player, "✅ Hid milking GUI!")
			end
		end
	end
end

function CowAdminPanel:ConfirmResetPlayerData(player)
	print("CowAdminPanel: Requesting confirmation for player data reset...")

	-- Create confirmation dialog
	local adminGUI = self.AdminGUIs[player.UserId]
	if not adminGUI then return end

	local confirmDialog = Instance.new("Frame")
	confirmDialog.Name = "ConfirmDialog"
	confirmDialog.Size = UDim2.new(0, 300, 0, 150)
	confirmDialog.Position = UDim2.new(0.5, -150, 0.5, -75)
	confirmDialog.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	confirmDialog.BorderSizePixel = 0
	confirmDialog.ZIndex = 200
	confirmDialog.Parent = adminGUI.gui

	local dialogCorner = Instance.new("UICorner")
	dialogCorner.CornerRadius = UDim.new(0.05, 0)
	dialogCorner.Parent = confirmDialog

	local warningLabel = Instance.new("TextLabel")
	warningLabel.Size = UDim2.new(1, -20, 0.6, 0)
	warningLabel.Position = UDim2.new(0, 10, 0, 10)
	warningLabel.BackgroundTransparency = 1
	warningLabel.Text = "⚠️ RESET PLAYER DATA?\n\nThis will delete ALL progress!"
	warningLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	warningLabel.TextScaled = true
	warningLabel.Font = Enum.Font.GothamBold
	warningLabel.Parent = confirmDialog

	local confirmButton = Instance.new("TextButton")
	confirmButton.Size = UDim2.new(0.4, 0, 0.25, 0)
	confirmButton.Position = UDim2.new(0.05, 0, 0.7, 0)
	confirmButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	confirmButton.BorderSizePixel = 0
	confirmButton.Text = "RESET"
	confirmButton.TextColor3 = Color3.new(1, 1, 1)
	confirmButton.TextScaled = true
	confirmButton.Font = Enum.Font.GothamBold
	confirmButton.Parent = confirmDialog

	local cancelButton = Instance.new("TextButton")
	cancelButton.Size = UDim2.new(0.4, 0, 0.25, 0)
	cancelButton.Position = UDim2.new(0.55, 0, 0.7, 0)
	cancelButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	cancelButton.BorderSizePixel = 0
	cancelButton.Text = "CANCEL"
	cancelButton.TextColor3 = Color3.new(1, 1, 1)
	cancelButton.TextScaled = true
	cancelButton.Font = Enum.Font.GothamBold
	cancelButton.Parent = confirmDialog

	confirmButton.MouseButton1Click:Connect(function()
		self:ResetPlayerData(player)
		confirmDialog:Destroy()
	end)

	cancelButton.MouseButton1Click:Connect(function()
		confirmDialog:Destroy()
		self:NotifyPlayer(player, "✅ Reset cancelled")
	end)
end

function CowAdminPanel:RefreshSystems(player)
	print("CowAdminPanel: Refreshing systems...")

	local refreshed = 0

	-- Refresh CowCreationModule
	if _G.CowCreationModule and _G.CowCreationModule.DetectExistingCows then
		pcall(function()
			_G.CowCreationModule:DetectExistingCows()
			refreshed = refreshed + 1
		end)
	end

	-- Refresh CowMilkingModule
	if _G.CowMilkingModule and _G.CowMilkingModule.DetectExistingChairs then
		pcall(function()
			_G.CowMilkingModule:DetectExistingChairs()
			refreshed = refreshed + 1
		end)
	end

	self:NotifyPlayer(player, "🔄 Refreshed " .. refreshed .. " systems!")
end

-- ========== EXISTING SYSTEM STATUS CHECKING ==========

function CowAdminPanel:GetSystemStatus()
	local status = "🔧 COW SYSTEM STATUS\n\n"

	-- Check GameCore
	if _G.GameCore then
		status = status .. "✅ GameCore: Online\n"
		local playerCount = #Players:GetPlayers()
		status = status .. "👥 Players: " .. playerCount .. "\n"
	else
		status = status .. "❌ GameCore: Offline\n"
	end

	-- Check CowCreationModule
	if _G.CowCreationModule then
		status = status .. "✅ CowCreationModule: Online\n"
		if _G.CowCreationModule.GetActiveCows then
			local activeCows = _G.CowCreationModule:GetActiveCows()
			local cowCount = 0
			for _ in pairs(activeCows) do
				cowCount = cowCount + 1
			end
			status = status .. "🐄 Active Cows: " .. cowCount .. "\n"
		end
	else
		status = status .. "❌ CowCreationModule: Offline\n"
	end

	-- Check CowMilkingModule
	if _G.CowMilkingModule then
		status = status .. "✅ CowMilkingModule: Online\n"
		if _G.CowMilkingModule.GetSystemStatus then
			local sysStatus = _G.CowMilkingModule:GetSystemStatus()
			if sysStatus then
				status = status .. "🎯 Active Sessions: " .. (sysStatus.activeSessions.clicker + sysStatus.activeSessions.chair) .. "\n"
				status = status .. "🥛 Cows Being Milked: " .. sysStatus.cowsBeingMilked .. "\n"
			end
		end
	else
		status = status .. "❌ CowMilkingModule: Offline\n"
	end

	-- Memory usage
	local memUsage = gcinfo()
	status = status .. "💾 Memory Usage: " .. math.floor(memUsage) .. " KB\n"

	-- Check for GameRemotes
	local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	if gameRemotes then
		local remoteCount = #gameRemotes:GetChildren()
		status = status .. "📡 Remote Events: " .. remoteCount .. "\n"
	else
		status = status .. "❌ GameRemotes: Missing\n"
	end

	return status
end

function CowAdminPanel:CheckForIssues()
	local issues = {}

	if not _G.GameCore then
		table.insert(issues, "GameCore not running")
	end

	if not _G.CowCreationModule then
		table.insert(issues, "CowCreationModule not running")
	end

	if not _G.CowMilkingModule then
		table.insert(issues, "CowMilkingModule not running")
	end

	-- Check for orphaned cows
	local orphanedCows = 0
	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("Model") and obj.Name:find("cow_") then
			local owner = obj:GetAttribute("Owner")
			if not owner or not Players:FindFirstChild(owner) then
				orphanedCows = orphanedCows + 1
			end
		end
	end

	if orphanedCows > 0 then
		table.insert(issues, orphanedCows .. " orphaned cow models found")
	end

	local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not gameRemotes then
		table.insert(issues, "GameRemotes folder missing")
	end

	return issues
end

-- ========== KEEP ALL EXISTING FUNCTIONS (cow management, etc.) ==========

function CowAdminPanel:SpawnCow(player, tier)
	print("CowAdminPanel: Spawning " .. tier .. " cow for " .. player.Name)

	-- Method 1: Try through GameCore
	if _G.GameCore and _G.GameCore.PurchaseCow then
		local success = pcall(function()
			return _G.GameCore:PurchaseCow(player, tier .. "_cow", nil)
		end)

		if success then
			self:NotifyPlayer(player, "✅ Spawned " .. tier .. " cow via GameCore!")
			return true
		else
			print("CowAdminPanel: GameCore method failed, trying CowCreationModule...")
		end
	end

	-- Method 2: Try through CowCreationModule directly
	if _G.CowCreationModule and _G.CowCreationModule.ForceGiveStarterCow then
		local success = pcall(function()
			return _G.CowCreationModule:ForceGiveStarterCow(player)
		end)

		if success then
			self:NotifyPlayer(player, "✅ Spawned starter cow!")
			return true
		end
	end

	-- Method 3: Manual cow creation
	if _G.CowCreationModule and _G.CowCreationModule.CreateNewCow then
		local success = pcall(function()
			local cowConfig = {
				tier = tier,
				milkAmount = tier == "basic" and 1 or 2,
				cooldown = 60,
				visualEffects = {}
			}
			return _G.CowCreationModule:CreateNewCow(player, tier .. "_cow", cowConfig)
		end)

		if success then
			self:NotifyPlayer(player, "✅ Manually created " .. tier .. " cow!")
			return true
		end
	end

	self:NotifyPlayer(player, "❌ Failed to spawn cow - no methods available!")
	return false
end

function CowAdminPanel:TestEffectsOnPlayerCows(player, tier)
	print("CowAdminPanel: Testing " .. tier .. " effects for " .. player.Name)

	local effectsApplied = 0

	-- Method 1: Through CowCreationModule
	if _G.CowCreationModule and _G.CowCreationModule.GetActiveCows then
		local activeCows = _G.CowCreationModule:GetActiveCows()

		for cowId, cowModel in pairs(activeCows) do
			if cowModel and cowModel.Parent then
				local owner = cowModel:GetAttribute("Owner")
				if owner == player.Name then
					if _G.CowCreationModule.ApplyTierEffects then
						local success = pcall(function()
							_G.CowCreationModule:ApplyTierEffects(cowModel, tier)
						end)

						if success then
							cowModel:SetAttribute("Tier", tier)
							effectsApplied = effectsApplied + 1
						end
					end
				end
			end
		end
	end

	-- Method 2: Through CowMilkingModule if available
	if effectsApplied == 0 and _G.CowMilkingModule and _G.CowMilkingModule.ApplyTierEffects then
		for _, obj in pairs(workspace:GetChildren()) do
			if obj:IsA("Model") and obj.Name:find("cow_") then
				local owner = obj:GetAttribute("Owner")
				if owner == player.Name then
					local success = pcall(function()
						_G.CowMilkingModule:ApplyTierEffects(obj, tier)
					end)

					if success then
						obj:SetAttribute("Tier", tier)
						effectsApplied = effectsApplied + 1
					end
				end
			end
		end
	end

	if effectsApplied > 0 then
		self:NotifyPlayer(player, "✅ Applied " .. tier .. " effects to " .. effectsApplied .. " cows!")
	else
		self:NotifyPlayer(player, "❌ No cows found or effects failed!")
	end

	return effectsApplied > 0
end

function CowAdminPanel:RemoveAllPlayerCows(player)
	print("CowAdminPanel: Removing all cows for " .. player.Name)

	local removedCount = 0

	-- Method 1: Through CowCreationModule
	if _G.CowCreationModule and _G.CowCreationModule.GetActiveCows then
		local activeCows = _G.CowCreationModule:GetActiveCows()

		for cowId, cowModel in pairs(activeCows) do
			if cowModel and cowModel.Parent then
				local owner = cowModel:GetAttribute("Owner")
				if owner == player.Name then
					if _G.CowCreationModule.DeleteCow then
						local success = pcall(function()
							return _G.CowCreationModule:DeleteCow(player, cowId)
						end)

						if success then
							removedCount = removedCount + 1
						end
					else
						cowModel:Destroy()
						removedCount = removedCount + 1
					end
				end
			end
		end
	end

	-- Method 2: Manual workspace cleanup
	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("Model") and obj.Name:find("cow") then
			local owner = obj:GetAttribute("Owner")
			if owner == player.Name then
				obj:Destroy()
				removedCount = removedCount + 1
			end
		end
	end

	-- Method 3: Clean player data
	if _G.GameCore and _G.GameCore.GetPlayerData then
		local playerData = _G.GameCore:GetPlayerData(player)
		if playerData and playerData.livestock and playerData.livestock.cows then
			playerData.livestock.cows = {}

			if _G.GameCore.SavePlayerData then
				_G.GameCore:SavePlayerData(player)
			end
		end
	end

	if removedCount > 0 then
		self:NotifyPlayer(player, "✅ Removed " .. removedCount .. " cow(s)!")
	else
		self:NotifyPlayer(player, "ℹ️ No cows found to remove!")
	end

	return removedCount > 0
end

function CowAdminPanel:TestMilkCollection(player)
	print("CowAdminPanel: Testing milk collection for " .. player.Name)

	-- Method 1: Test through CowMilkingModule
	if _G.CowMilkingModule and _G.CowMilkingModule.ForceStartMilkingForDebug then
		local success = pcall(function()
			return _G.CowMilkingModule:ForceStartMilkingForDebug(player, "debug_cow_" .. player.UserId)
		end)

		if success then
			self:NotifyPlayer(player, "🧪 Started debug milking session!")

			spawn(function()
				wait(2)
				if _G.CowMilkingModule.HandleContinueMilking then
					local clickSuccess = pcall(function()
						return _G.CowMilkingModule:HandleContinueMilking(player)
					end)

					if clickSuccess then
						self:NotifyPlayer(player, "🥛 Test click successful!")
					end
				end
			end)

			return true
		end
	end

	-- Method 2: Manual GUI test
	local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	if gameRemotes then
		local showPrompt = gameRemotes:FindFirstChild("ShowChairPrompt")
		if showPrompt then
			showPrompt:FireClient(player, "milking", {
				title = "🧪 Milking Test",
				subtitle = "Testing milking system",
				instruction = "This is a test of the milking GUI"
			})

			self:NotifyPlayer(player, "🧪 Sent test milking GUI!")
			return true
		end
	end

	self:NotifyPlayer(player, "❌ No milking test methods available!")
	return false
end

function CowAdminPanel:GiveCurrency(player, currencyType, amount)
	print("CowAdminPanel: Giving " .. amount .. " " .. currencyType .. " to " .. player.Name)

	if not _G.GameCore then
		self:NotifyPlayer(player, "❌ GameCore not available!")
		return false
	end

	local playerData = _G.GameCore:GetPlayerData(player)
	if playerData then
		playerData[currencyType] = (playerData[currencyType] or 0) + amount

		if _G.GameCore.SavePlayerData then
			_G.GameCore:SavePlayerData(player)
		end

		self:NotifyPlayer(player, "✅ Added " .. amount .. " " .. currencyType .. "!")
		return true
	else
		self:NotifyPlayer(player, "❌ Player data not found!")
		return false
	end
end

function CowAdminPanel:GiveAllPastureExpansions(player)
	print("CowAdminPanel: Giving all pasture expansions to " .. player.Name)

	if not _G.GameCore then
		self:NotifyPlayer(player, "❌ GameCore not available!")
		return false
	end

	local playerData = _G.GameCore:GetPlayerData(player)
	if not playerData then
		self:NotifyPlayer(player, "❌ Player data not available!")
		return false
	end

	playerData.upgrades = playerData.upgrades or {}

	local expansions = {
		"pasture_expansion_1",
		"pasture_expansion_2", 
		"mega_pasture"
	}

	for _, expansion in ipairs(expansions) do
		playerData.upgrades[expansion] = true
		print("CowAdminPanel: Granted " .. expansion .. " to " .. player.Name)
	end

	_G.GameCore:SavePlayerData(player)
	self:NotifyPlayer(player, "✅ All pasture expansions granted!")
	return true
end

function CowAdminPanel:GiveAutoMilker(player)
	print("CowAdminPanel: Giving auto milker to " .. player.Name)

	if not _G.GameCore then
		self:NotifyPlayer(player, "❌ GameCore not available!")
		return false
	end

	local playerData = _G.GameCore:GetPlayerData(player)
	if not playerData then
		self:NotifyPlayer(player, "❌ Player data not available!")
		return false
	end

	playerData.upgrades = playerData.upgrades or {}
	playerData.upgrades.auto_milker = true

	_G.GameCore:SavePlayerData(player)
	self:NotifyPlayer(player, "✅ Auto milker granted!")
	return true
end

function CowAdminPanel:ResetPlayerData(player)
	print("CowAdminPanel: Resetting player data for " .. player.Name)

	if not _G.GameCore then
		self:NotifyPlayer(player, "❌ GameCore not available!")
		return false
	end

	self:RemoveAllPlayerCows(player)

	local success = pcall(function()
		if _G.GameCore.ResetPlayerData then
			return _G.GameCore:ResetPlayerData(player)
		else
			local playerData = _G.GameCore:GetPlayerData(player)
			if playerData then
				playerData.coins = 1000
				playerData.farmTokens = 0
				playerData.farming = nil
				playerData.livestock = nil
				playerData.defense = nil
				playerData.upgrades = nil
				playerData.purchaseHistory = nil

				_G.GameCore:SavePlayerData(player)
				return true
			end
			return false
		end
	end)

	if success then
		self:NotifyPlayer(player, "✅ Player data reset successfully!")
		print("CowAdminPanel: Successfully reset data for " .. player.Name)
	else
		self:NotifyPlayer(player, "❌ Failed to reset player data!")
		warn("CowAdminPanel: Failed to reset data for " .. player.Name)
	end

	return success
end

-- ========== INITIALIZATION ==========

function CowAdminPanel:Initialize()
	print("CowAdminPanel: Initializing COMPLETE admin management system...")
	print("CowAdminPanel: Looking for systems:")
	print("  GameCore: " .. (_G.GameCore and "✅" or "❌"))
	print("  CowCreationModule: " .. (_G.CowCreationModule and "✅" or "❌"))
	print("  CowMilkingModule: " .. (_G.CowMilkingModule and "✅" or "❌"))

	self:SetupAdminSystem()
	self:StartSystemMonitoring()

	print("CowAdminPanel: ✅ COMPLETE admin system ready!")
end

function CowAdminPanel:SetupAdminSystem()
	Players.PlayerAdded:Connect(function(player)
		if self:IsAdmin(player) then
			print("CowAdminPanel: Admin user detected: " .. player.Name)

			player.CharacterAdded:Connect(function()
				wait(2)
				self:SetupAdminGUI(player)
				self:SetupAdminCommands(player)
				self:SendAdminWelcome(player)
			end)
		end
	end)

	-- Handle existing players
	for _, player in pairs(Players:GetPlayers()) do
		if self:IsAdmin(player) and player.Character then
			self:SetupAdminGUI(player)
			self:SetupAdminCommands(player)
		end
	end
end

function CowAdminPanel:IsAdmin(player)
	for _, adminName in ipairs(ADMIN_USERS) do
		if player.Name == adminName then
			return true
		end
	end
	return false
end

function CowAdminPanel:NotifyPlayer(player, message)
	if _G.GameCore and _G.GameCore.SendNotification then
		_G.GameCore:SendNotification(player, "Admin Panel", message, "info")
	else
		print("ADMIN NOTIFICATION for " .. player.Name .. ": " .. message)
	end
end

function CowAdminPanel:SetupAdminCommands(player)
	player.Chatted:Connect(function(message)
		local args = string.split(message:lower(), " ")
		local command = args[1]

		if command == "/cowadmin" then
			self:ToggleMainPanel(player)
		elseif command == "/cowstatus" then
			local status = self:GetSystemStatus()
			print("=== COW SYSTEM STATUS FOR " .. player.Name .. " ===")
			print(status)
			print("==============================================")
		elseif command == "/fixcows" then
			print("CowAdminPanel: Running quick cow system fix...")
			local fixed = 0

			for _, obj in pairs(workspace:GetChildren()) do
				if obj:IsA("Model") and obj.Name:find("cow_") then
					local owner = obj:GetAttribute("Owner")
					if not owner or not Players:FindFirstChild(owner) then
						obj:Destroy()
						fixed = fixed + 1
					end
				end
			end

			self:NotifyPlayer(player, "🔧 Fixed " .. fixed .. " orphaned cows!")
		elseif command == "/spawnbasic" then
			self:SpawnCow(player, "basic")
		elseif command == "/spawngold" then
			self:SpawnCow(player, "gold")
		elseif command == "/testmilking" then
			self:TestMilkCollection(player)
		elseif command == "/clearcows" then
			self:RemoveAllPlayerCows(player)
		end
	end)
end

function CowAdminPanel:SendAdminWelcome(player)
	spawn(function()
		wait(1)
		self:NotifyPlayer(player, "🐄 Admin Panel ready! Press F9 or type /cowadmin")
	end)
end

function CowAdminPanel:StartSystemMonitoring()
	if self.MonitoringActive then return end
	self.MonitoringActive = true

	spawn(function()
		while self.MonitoringActive do
			wait(30)

			local issues = self:CheckForIssues()
			if #issues > 0 then
				print("CowAdminPanel: System issues detected:")
				for _, issue in ipairs(issues) do
					print("  ⚠️ " .. issue)
				end
			end
		end
	end)
end

-- Initialize with proper error handling
local function SafeInitialize()
	local success, error = pcall(function()
		CowAdminPanel:Initialize()
	end)

	if not success then
		warn("CowAdminPanel: Failed to initialize: " .. tostring(error))
		print("CowAdminPanel: Will retry in 5 seconds...")

		spawn(function()
			wait(5)
			SafeInitialize()
		end)
	end
end

SafeInitialize()
_G.CowAdminPanel = CowAdminPanel

print("🎮 CowAdminPanel: ✅ COMPLETE SYSTEM LOADED!")
print("🎯 FEATURES:")
print("  ✅ Full GUI with toggle button (top-left)")
print("  ✅ F9 hotkey support")
print("  ✅ Complete cow management")
print("  ✅ System monitoring and fixes")
print("  ✅ Currency and upgrade management")
print("  ✅ Player data reset with confirmation")
print("")
print("🎮 CONTROLS:")
print("  🖱️ Click toggle button in top-left")
print("  ⌨️ Press F9 to toggle panel")
print("  💬 Type /cowadmin to toggle panel")
print("")
print("👑 Configured for admin: " .. table.concat(ADMIN_USERS, ", "))