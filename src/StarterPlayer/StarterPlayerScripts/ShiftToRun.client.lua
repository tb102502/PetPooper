-- Shift to Run Script
-- Place this in StarterPlayerScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local normalSpeed = 16       -- Default walk speed
local sprintSpeed = 24       -- Speed when sprinting
local isSprinting = false    -- Tracking if player is currently sprinting
local sprintEnabled = true   -- Can be toggled off with upgrades
local staminaMax = 100       -- Maximum stamina value
local stamina = staminaMax   -- Current stamina
local staminaDrainRate = 10  -- How fast stamina drains while sprinting (per second)
local staminaRegenRate = 15  -- How fast stamina regenerates while not sprinting (per second)
local staminaRegenDelay = 1  -- Seconds to wait before stamina starts regenerating

local lastSprintTime = 0     -- Tracks when the player last stopped sprinting

-- Create a stamina bar UI
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

-- Add corners to make it look nicer
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 4)
uiCorner.Parent = staminaFrame

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 4)
barCorner.Parent = staminaBar

-- Update the stamina bar visuals
local function updateStaminaBar()
	local staminaPercent = stamina / staminaMax
	staminaBar.Size = UDim2.new(staminaPercent, 0, 1, 0)

	-- Change color based on stamina level
	if staminaPercent > 0.6 then
		staminaBar.BackgroundColor3 = Color3.fromRGB(60, 200, 60) -- Green
	elseif staminaPercent > 0.3 then
		staminaBar.BackgroundColor3 = Color3.fromRGB(230, 160, 30) -- Orange
	else
		staminaBar.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Red
	end

	-- Show/hide the stamina bar based on whether it's full
	staminaFrame.Visible = staminaPercent < 0.99 or isSprinting
end

-- Function to start sprinting
local function startSprint()
	if not sprintEnabled or stamina <= 0 then return end

	isSprinting = true
	humanoid.WalkSpeed = sprintSpeed
end

-- Function to stop sprinting
local function stopSprint()
	isSprinting = false
	humanoid.WalkSpeed = normalSpeed
	lastSprintTime = tick()
end

-- Listen for character respawns
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = normalSpeed
	isSprinting = false
end)

-- Handle input for sprint key
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

-- Mobile support - add a sprint button
if UserInputService.TouchEnabled then
	local sprintButton = Instance.new("TextButton")
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

	-- Make it circular
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0.5, 0)
	buttonCorner.Parent = sprintButton

	-- Add button events
	sprintButton.MouseButton1Down:Connect(startSprint)
	sprintButton.MouseButton1Up:Connect(stopSprint)
	sprintButton.TouchEnded:Connect(stopSprint)
end

-- Function to upgrade sprint (can be called from other scripts)
local function upgradeSprintStats(speedIncrease, staminaIncrease, regenIncrease)
	sprintSpeed = sprintSpeed + (speedIncrease or 0)
	staminaMax = staminaMax + (staminaIncrease or 0)
	staminaRegenRate = staminaRegenRate + (regenIncrease or 0)

	-- Adjust current stamina proportionally
	local staminaRatio = stamina / staminaMax
	stamina = staminaMax * staminaRatio

	updateStaminaBar()
end

-- Update loop for stamina management
RunService.Heartbeat:Connect(function(deltaTime)
	-- Handle stamina drain during sprint
	if isSprinting and stamina > 0 then
		stamina = math.max(0, stamina - (staminaDrainRate * deltaTime))

		-- Automatically stop sprinting if stamina is depleted
		if stamina <= 0 then
			stopSprint()
		end
	elseif not isSprinting and stamina < staminaMax and (tick() - lastSprintTime) > staminaRegenDelay then
		-- Regenerate stamina when not sprinting (after a delay)
		stamina = math.min(staminaMax, stamina + (staminaRegenRate * deltaTime))
	end

	updateStaminaBar()
end)

-- Add a way for other scripts to reference this module
local sprintModule = {}
sprintModule.upgradeSprintStats = upgradeSprintStats

-- Create a shared reference for other scripts to access
_G.SprintModule = sprintModule

print("Shift to run system initialized")