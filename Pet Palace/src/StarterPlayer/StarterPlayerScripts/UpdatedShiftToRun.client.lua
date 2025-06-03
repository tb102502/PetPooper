-- UpdatedShiftToRun.client.lua
-- Enhanced version that works with shop upgrades
-- Place in StarterPlayerScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Base values
local normalSpeed = 16
local baseSprint = 24
local baseStaminaMax = 100
local baseDrainRate = 10
local baseRegenRate = 15
local staminaRegenDelay = 1

-- Current values (modified by upgrades)
local sprintSpeed = baseSprint
local staminaMax = baseStaminaMax
local staminaDrainRate = baseDrainRate
local staminaRegenRate = baseRegenRate

-- State
local stamina = staminaMax
local isSprinting = false
local lastSprintTime = 0
local hasUnlimitedStamina = false

-- GUI Elements
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StaminaGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

local staminaFrame = Instance.new("Frame")
staminaFrame.Name = "StaminaFrame"
staminaFrame.Size = UDim2.new(0, 200, 0, 20)
staminaFrame.Position = UDim2.new(0.5, -100, 0.9, 0)
staminaFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
staminaFrame.BorderSizePixel = 0
staminaFrame.Parent = screenGui

local staminaBar = Instance.new("Frame")
staminaBar.Name = "StaminaBar"
staminaBar.Size = UDim2.new(1, 0, 1, 0)
staminaBar.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
staminaBar.BorderSizePixel = 0
staminaBar.Parent = staminaFrame

local staminaLabel = Instance.new("TextLabel")
staminaLabel.Name = "StaminaLabel"
staminaLabel.Size = UDim2.new(1, 0, 1, 0)
staminaLabel.BackgroundTransparency = 1
staminaLabel.Text = "STAMINA"
staminaLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
staminaLabel.Font = Enum.Font.GothamBold
staminaLabel.TextSize = 14
staminaLabel.Parent = staminaFrame

-- Add corners
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 4)
uiCorner.Parent = staminaFrame

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 4)
barCorner.Parent = staminaBar

-- Mobile sprint button for touch devices
local sprintButton
if UserInputService.TouchEnabled then
	sprintButton = Instance.new("TextButton")
	sprintButton.Name = "SprintButton"
	sprintButton.Size = UDim2.new(0, 100, 0, 100)
	sprintButton.Position = UDim2.new(0.85, 0, 0.6, 0)
	sprintButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	sprintButton.BackgroundTransparency = 0.5
	sprintButton.Text = "SPRINT"
	sprintButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	sprintButton.Font = Enum.Font.GothamBold
	sprintButton.TextSize = 18
	sprintButton.Parent = screenGui

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0.5, 0)
	buttonCorner.Parent = sprintButton
end

-- Update stamina bar visuals
local function updateStaminaBar()
	if hasUnlimitedStamina then
		staminaLabel.Text = "UNLIMITED STAMINA"
		staminaBar.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold
		staminaBar.Size = UDim2.new(1, 0, 1, 0)
		staminaFrame.Visible = isSprinting -- Only show when sprinting
		return
	end

	local staminaPercent = stamina / staminaMax
	staminaBar.Size = UDim2.new(staminaPercent, 0, 1, 0)

	-- Color based on stamina level
	if staminaPercent > 0.6 then
		staminaBar.BackgroundColor3 = Color3.fromRGB(60, 200, 60) -- Green
	elseif staminaPercent > 0.3 then
		staminaBar.BackgroundColor3 = Color3.fromRGB(230, 160, 30) -- Orange
	else
		staminaBar.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Red
	end

	staminaLabel.Text = "STAMINA"
	staminaFrame.Visible = staminaPercent < 0.99 or isSprinting
end

-- Apply upgrades from player attributes
local function applyUpgrades()
	local staminaLevel = player:GetAttribute("StaminaLevel") or 1
	local walkSpeedLevel = player:GetAttribute("WalkSpeedLevel") or 1

	-- Update stamina stats based on upgrade level
	staminaMax = baseStaminaMax + ((staminaLevel - 1) * 20) -- +20 per level
	staminaRegenRate = baseRegenRate + ((staminaLevel - 1) * 5) -- +5 regen per level

	-- Update walk speed
	normalSpeed = 16 + ((walkSpeedLevel - 1) * 2) -- +2 per level
	sprintSpeed = normalSpeed + 8 -- Sprint is always +8 from walk speed

	-- Check for unlimited stamina premium
	hasUnlimitedStamina = player:GetAttribute("UnlimitedStamina") or false

	-- If stamina was above max, adjust it
	if stamina > staminaMax then
		stamina = staminaMax
	end

	-- Update humanoid speed if not sprinting
	if character and humanoid and not isSprinting then
		humanoid.WalkSpeed = normalSpeed
	end

	updateStaminaBar()
	print("Sprint upgrades applied - Stamina Level:", staminaLevel, "Walk Speed Level:", walkSpeedLevel)
end

-- Start sprinting
local function startSprint()
	if hasUnlimitedStamina or stamina > 0 then
		isSprinting = true
		if humanoid then
			humanoid.WalkSpeed = sprintSpeed
		end
		updateStaminaBar()
	end
end

-- Stop sprinting
local function stopSprint()
	isSprinting = false
	if humanoid then
		humanoid.WalkSpeed = normalSpeed
	end
	lastSprintTime = tick()
	updateStaminaBar()
end

-- Handle character respawn
local function onCharacterAdded(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	isSprinting = false
	stamina = staminaMax

	-- Reapply upgrades
	wait(1) -- Wait for attributes to be set
	applyUpgrades()
end

-- Listen for attribute changes (when upgrades are purchased)
local function onAttributeChanged()
	applyUpgrades()
end

-- Connect events
player.AttributeChanged:Connect(onAttributeChanged)
player.CharacterAdded:Connect(onCharacterAdded)

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		startSprint()
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		stopSprint()
	end
end)

-- Mobile controls
if sprintButton then
	sprintButton.MouseButton1Down:Connect(startSprint)
	sprintButton.MouseButton1Up:Connect(stopSprint)
	sprintButton.TouchEnded:Connect(stopSprint)
end

-- Main update loop
RunService.Heartbeat:Connect(function(deltaTime)
	if hasUnlimitedStamina then
		updateStaminaBar()
		return
	end

	-- Handle stamina drain/regen
	if isSprinting and stamina > 0 then
		stamina = math.max(0, stamina - (staminaDrainRate * deltaTime))

		-- Stop sprinting if stamina depleted
		if stamina <= 0 then
			stopSprint()
		end
	elseif not isSprinting and stamina < staminaMax and (tick() - lastSprintTime) > staminaRegenDelay then
		stamina = math.min(staminaMax, stamina + (staminaRegenRate * deltaTime))
	end

	updateStaminaBar()
end)

-- Initial setup
applyUpgrades()

-- Global reference for other scripts
_G.SprintSystem = {
	applyUpgrades = applyUpgrades,
	getStamina = function() return stamina end,
	getMaxStamina = function() return staminaMax end,
	isSprinting = function() return isSprinting end,
	hasUnlimited = function() return hasUnlimitedStamina end
}

print("Enhanced Sprint System initialized!")