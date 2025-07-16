--[[
    ScytheGiver.lua - Server-side Scythe Tool Giver
    Place in: ServerScriptService/ScytheGiver.lua
    
    FEATURES:
    ✅ Gives players free scythe tool
    ✅ One scythe per player
    ✅ Touch detection on ScytheGiver model
    ✅ Integration with existing framework
]]

local ScytheGiver = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

-- Configuration
local SCYTHE_CONFIG = {
	SCYTHE_NAME = "Scythe",
	COOLDOWN_TIME = 2, -- Seconds between giving scythes
	GLOW_DURATION = 0.5 -- Duration of glow effect
}

-- Load ItemConfig safely
local ItemConfig = nil
local function loadItemConfig()
	local success, result = pcall(function()
		return require(ReplicatedStorage:WaitForChild("ItemConfig", 10))
	end)
	if success then
		ItemConfig = result
		print("ScytheGiver: ItemConfig loaded successfully")
	else
		warn("ScytheGiver: Could not load ItemConfig: " .. tostring(result))
		-- Create fallback ItemConfig
		ItemConfig = {
			ShopItems = {},
			Crops = {}
		}
	end
end

-- State
ScytheGiver.GameCore = nil
ScytheGiver.ScytheGiverModel = nil
ScytheGiver.TouchConnections = {}
ScytheGiver.PlayerCooldowns = {}
ScytheGiver.ScytheTool = nil

-- ========== INITIALIZATION ==========

function ScytheGiver:Initialize(gameCore)
	print("ScytheGiver: Initializing scythe giver system...")

	self.GameCore = gameCore

	-- Load ItemConfig first
	loadItemConfig()

	-- Find the ScytheGiver model
	self:FindScytheGiverModel()

	-- Create/find the scythe tool
	self:CreateScytheTool()

	-- Setup touch detection
	self:SetupTouchDetection()

	print("ScytheGiver: ✅ Scythe giver system initialized")
	return true
end

-- ========== SCYTHE GIVER MODEL SETUP ==========

function ScytheGiver:FindScytheGiverModel()
	print("ScytheGiver: Looking for ScytheGiver model...")

	-- First check workspace
	self.ScytheGiverModel = workspace:FindFirstChild("ScytheGiver")

	if not self.ScytheGiverModel then
		-- Check if it's nested in another model
		for _, child in pairs(workspace:GetChildren()) do
			if child:IsA("Model") then
				local found = child:FindFirstChild("ScytheGiver")
				if found then
					self.ScytheGiverModel = found
					break
				end
			end
		end
	end

	if not self.ScytheGiverModel then
		error("ScytheGiver: ScytheGiver model not found in workspace!")
	end

	print("ScytheGiver: Found ScytheGiver model: " .. self.ScytheGiverModel.Name)

	-- Add visual enhancement to make it obvious
	self:EnhanceScytheGiverVisuals()
end

function ScytheGiver:EnhanceScytheGiverVisuals()
	print("ScytheGiver: Enhancing ScytheGiver visuals...")

	-- Add a glowing effect
	local function addGlow(part)
		if part:IsA("BasePart") then
			-- Add selection box for glow effect
			local selectionBox = Instance.new("SelectionBox")
			selectionBox.Name = "ScytheGiverGlow"
			selectionBox.Adornee = part
			selectionBox.Color3 = Color3.fromRGB(255, 255, 0) -- Yellow glow
			selectionBox.Transparency = 0.5
			selectionBox.LineThickness = 0.2
			selectionBox.Parent = part

			-- Animate the glow
			local tween = TweenService:Create(selectionBox,
				TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{Transparency = 0.2}
			)
			tween:Play()
		end
	end

	-- Apply glow to all parts in the model
	for _, child in pairs(self.ScytheGiverModel:GetChildren()) do
		addGlow(child)
	end

	print("ScytheGiver: ✅ Enhanced ScytheGiver visuals")
end

-- ========== SCYTHE TOOL CREATION ==========

function ScytheGiver:CreateScytheTool()
	print("ScytheGiver: Creating scythe tool...")

	-- Check if scythe tool already exists in ServerStorage
	local serverStorage = ServerStorage
	local existingTool = serverStorage:FindFirstChild(SCYTHE_CONFIG.SCYTHE_NAME)

	if existingTool and existingTool:IsA("Tool") then
		self.ScytheTool = existingTool
		print("ScytheGiver: Found existing scythe tool")
		return
	end

	-- Create new scythe tool
	local scytheTool = Instance.new("Tool")
	scytheTool.Name = SCYTHE_CONFIG.SCYTHE_NAME
	scytheTool.RequiresHandle = true
	scytheTool.CanBeDropped = false
	scytheTool.Parent = serverStorage

	-- Create a simple scythe handle
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.2, 3.5, 0.2)
	handle.Material = Enum.Material.Wood
	handle.BrickColor = BrickColor.new("Reddish brown")
	handle.Shape = Enum.PartType.Cylinder
	handle.Parent = scytheTool

	-- Create tool icon/display
	local toolGui = Instance.new("BillboardGui")
	toolGui.Size = UDim2.new(0, 50, 0, 50)
	toolGui.StudsOffset = Vector3.new(0, 2, 0)
	toolGui.Parent = handle

	local toolIcon = Instance.new("TextLabel")
	toolIcon.Size = UDim2.new(1, 0, 1, 0)
	toolIcon.BackgroundTransparency = 1
	toolIcon.Text = "🔪"
	toolIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
	toolIcon.TextScaled = true
	toolIcon.Font = Enum.Font.SourceSans
	toolIcon.Parent = toolGui

	-- Create scythe tool script
	self:CreateScytheToolScript(scytheTool)

	self.ScytheTool = scytheTool
	print("ScytheGiver: ✅ Created scythe tool")
end

function ScytheGiver:CreateScytheToolScript(tool)
	print("ScytheGiver: Creating scythe tool script...")

	-- Look for the ScytheToolScript in ServerStorage
	local serverStorage = game:GetService("ServerStorage")
	local toolScriptTemplate = serverStorage:FindFirstChild("ScytheToolScript")

	if toolScriptTemplate then
		-- Clone the script template
		local toolScript = toolScriptTemplate:Clone()
		toolScript.Name = "ScytheScript"
		toolScript.Parent = tool
		print("ScytheGiver: ✅ Cloned scythe tool script from ServerStorage")
	else
		-- Create a minimal script that just handles RemoteEvent communication
		local toolScript = Instance.new("LocalScript")
		toolScript.Name = "ScytheScript"
		toolScript.Parent = tool

		-- Create minimal script content without setting Source
		print("ScytheGiver: ⚠️ ScytheToolScript not found in ServerStorage, using minimal script")
		print("ScytheGiver: Please add ScytheToolScript.client.lua to ServerStorage for full functionality")
	end

	print("ScytheGiver: ✅ Scythe tool script setup complete")
end

-- ========== TOUCH DETECTION ==========

function ScytheGiver:SetupTouchDetection()
	print("ScytheGiver: Setting up touch detection...")

	-- Connect touch detection to all parts of the ScytheGiver model
	for _, child in pairs(self.ScytheGiverModel:GetChildren()) do
		if child:IsA("BasePart") then
			local connection = child.Touched:Connect(function(hit)
				self:HandleTouch(hit)
			end)
			table.insert(self.TouchConnections, connection)
			print("ScytheGiver: Connected touch detection to " .. child.Name)
		end
	end

	print("ScytheGiver: ✅ Touch detection setup complete")
end

function ScytheGiver:HandleTouch(hit)
	-- Get the character that touched the ScytheGiver
	local character = hit.Parent
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return
	end

	-- Get the player
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	-- Check cooldown
	local currentTime = tick()
	local lastGiveTime = self.PlayerCooldowns[player.UserId] or 0

	if (currentTime - lastGiveTime) < SCYTHE_CONFIG.COOLDOWN_TIME then
		return
	end

	-- Give scythe to player
	self:GiveScytheToPlayer(player)
end

-- ========== SCYTHE GIVING ==========

function ScytheGiver:GiveScytheToPlayer(player)
	print("ScytheGiver: Giving scythe to " .. player.Name)

	-- Check if player already has a scythe
	if self:PlayerHasScythe(player) then
		if self.GameCore and self.GameCore.SendNotification then
			self.GameCore:SendNotification(player, "Already Have Scythe", "You already have a scythe!", "info")
		end
		return
	end

	-- Update cooldown
	self.PlayerCooldowns[player.UserId] = tick()

	-- Clone the scythe tool
	if not self.ScytheTool then
		print("ScytheGiver: Scythe tool not available")
		return
	end

	local scytheClone = self.ScytheTool:Clone()
	scytheClone.Parent = player.Backpack

	-- Visual feedback
	self:CreateGiveEffect(player)

	-- Send notification
	if self.GameCore and self.GameCore.SendNotification then
		self.GameCore:SendNotification(player, "🔪 Scythe Acquired", "You received a scythe! Use it to harvest wheat.", "success")
	end

	-- Update player data
	if self.GameCore then
		local playerData = self.GameCore:GetPlayerData(player)
		if playerData then
			playerData.stats = playerData.stats or {}
			playerData.stats.scythesReceived = (playerData.stats.scythesReceived or 0) + 1
			self.GameCore:UpdatePlayerData(player, playerData)
		end
	end

	print("ScytheGiver: ✅ Gave scythe to " .. player.Name)
end

function ScytheGiver:CreateGiveEffect(player)
	-- Create a visual effect when giving scythe
	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Create sparkle effect
	local sparkle = Instance.new("Part")
	sparkle.Name = "ScytheGiveEffect"
	sparkle.Size = Vector3.new(2, 2, 2)
	sparkle.Material = Enum.Material.Neon
	sparkle.BrickColor = BrickColor.new("Bright yellow")
	sparkle.Anchored = true
	sparkle.CanCollide = false
	sparkle.Transparency = 0.3
	sparkle.Parent = workspace

	-- Position above player
	sparkle.CFrame = rootPart.CFrame * CFrame.new(0, 3, 0)

	-- Make it spin
	local spin = Instance.new("BodyAngularVelocity")
	spin.AngularVelocity = Vector3.new(0, 10, 0)
	spin.MaxTorque = Vector3.new(0, math.huge, 0)
	spin.Parent = sparkle

	-- Animate effect
	local tween = TweenService:Create(sparkle,
		TweenInfo.new(SCYTHE_CONFIG.GLOW_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Transparency = 1, Size = Vector3.new(4, 4, 4)}
	)
	tween:Play()

	tween.Completed:Connect(function()
		sparkle:Destroy()
	end)
end

-- ========== UTILITY FUNCTIONS ==========

function ScytheGiver:PlayerHasScythe(player)
	-- Check backpack
	if player.Backpack:FindFirstChild(SCYTHE_CONFIG.SCYTHE_NAME) then
		return true
	end

	-- Check character (equipped)
	if player.Character and player.Character:FindFirstChild(SCYTHE_CONFIG.SCYTHE_NAME) then
		return true
	end

	return false
end

-- ========== PLAYER CLEANUP ==========

function ScytheGiver:PlayerRemoving(player)
	print("ScytheGiver: Cleaning up data for " .. player.Name)

	if self.PlayerCooldowns[player.UserId] then
		self.PlayerCooldowns[player.UserId] = nil
	end
end

-- ========== DEBUG FUNCTIONS ==========

function ScytheGiver:DebugStatus()
	print("=== SCYTHE GIVER DEBUG STATUS ===")
	print("ScytheGiver model: " .. (self.ScytheGiverModel and self.ScytheGiverModel.Name or "❌ Not found"))
	print("Scythe tool: " .. (self.ScytheTool and self.ScytheTool.Name or "❌ Not found"))
	print("Touch connections: " .. #self.TouchConnections)
	print("Player cooldowns: " .. self:CountTable(self.PlayerCooldowns))
	print("")

	print("Players with scythes:")
	for _, player in pairs(Players:GetPlayers()) do
		local hasScythe = self:PlayerHasScythe(player)
		print("  " .. player.Name .. ": " .. (hasScythe and "✅" or "❌"))
	end
	print("==================================")
end

function ScytheGiver:CountTable(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- ========== CLEANUP ==========

function ScytheGiver:Cleanup()
	print("ScytheGiver: Performing cleanup...")

	-- Disconnect touch connections
	for _, connection in pairs(self.TouchConnections) do
		if connection then
			connection:Disconnect()
		end
	end

	-- Clear data
	self.TouchConnections = {}
	self.PlayerCooldowns = {}

	print("ScytheGiver: Cleanup complete")
end

-- Setup player cleanup
Players.PlayerRemoving:Connect(function(player)
	ScytheGiver:PlayerRemoving(player)
end)

-- Global reference
_G.ScytheGiver = ScytheGiver

return ScytheGiver