--[[
    ProximityDebounceFix.server.lua - Quick Fix for Proximity Spam
    Place in: ServerScriptService/ProximityDebounceFix.server.lua
    
    This is a quick fix to prevent the ChairMilkingGUI from firing non-stop
    by intercepting and debouncing the ShowChairPrompt remote events.
]]

print("🔧 ProximityDebounceFix: Starting debounce fix...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for the remote events
local remoteFolder = ReplicatedStorage:WaitForChild("GameRemotes", 10)
if not remoteFolder then
	warn("❌ ProximityDebounceFix: GameRemotes folder not found")
	return
end

local ShowChairPrompt = remoteFolder:WaitForChild("ShowChairPrompt", 5)
local HideChairPrompt = remoteFolder:WaitForChild("HideChairPrompt", 5)

if not ShowChairPrompt or not HideChairPrompt then
	warn("❌ ProximityDebounceFix: Required remote events not found")
	return
end

-- Debounce state for each player
local PlayerPromptState = {} -- [userId] = {lastPromptType, lastPromptTime, isVisible, debounceTime}

-- Configuration
local DEBOUNCE_TIME = 3 -- Seconds between prompt changes
local MOVEMENT_THRESHOLD = 5 -- Distance player must move to reset debounce

-- Store original events
local OriginalShowPrompt = ShowChairPrompt.FireClient
local OriginalHidePrompt = HideChairPrompt.FireClient

-- Initialize player state
local function InitializePlayerState(player)
	local userId = player.UserId
	if not PlayerPromptState[userId] then
		PlayerPromptState[userId] = {
			lastPromptType = "none",
			lastPromptTime = 0,
			isVisible = false,
			debounceTime = DEBOUNCE_TIME,
			lastPosition = Vector3.new(0, 0, 0)
		}
		print("🔧 ProximityDebounceFix: Initialized state for " .. player.Name)
	end
end

-- Clean up player state
local function CleanupPlayerState(player)
	local userId = player.UserId
	if PlayerPromptState[userId] then
		PlayerPromptState[userId] = nil
		print("🧹 ProximityDebounceFix: Cleaned up state for " .. player.Name)
	end
end

-- Check if player moved significantly
local function PlayerMovedSignificantly(player)
	local userId = player.UserId
	local state = PlayerPromptState[userId]

	if not state or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return false
	end

	local currentPos = player.Character.HumanoidRootPart.Position
	local distance = (currentPos - state.lastPosition).Magnitude

	if distance > MOVEMENT_THRESHOLD then
		state.lastPosition = currentPos
		return true
	end

	return false
end

-- Debounced ShowChairPrompt
local function DebouncedShowPrompt(self, player, promptType, promptData)
	if not player or not promptType or not promptData then
		return
	end

	local userId = player.UserId
	local currentTime = tick()

	-- Initialize state if needed
	InitializePlayerState(player)
	local state = PlayerPromptState[userId]

	-- Determine prompt identifier
	local promptId = promptData.promptType or promptType or "unknown"

	-- Check if this is the same prompt type and still within debounce time
	local timeSinceLastPrompt = currentTime - state.lastPromptTime
	local playerMoved = PlayerMovedSignificantly(player)

	if state.isVisible and state.lastPromptType == promptId and timeSinceLastPrompt < state.debounceTime and not playerMoved then
		-- Still within debounce time and same prompt type, don't show again
		print("🔇 ProximityDebounceFix: Debounced prompt for " .. player.Name .. " (" .. promptId .. ")")
		return
	end

	-- Different prompt type or enough time has passed or player moved
	if state.lastPromptType ~= promptId or playerMoved then
		print("📢 ProximityDebounceFix: Allowing prompt for " .. player.Name .. " (" .. promptId .. ")")
	else
		print("⏰ ProximityDebounceFix: Debounce expired for " .. player.Name .. " (" .. promptId .. ")")
	end

	-- Update state
	state.lastPromptType = promptId
	state.lastPromptTime = currentTime
	state.isVisible = true

	-- Update position
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		state.lastPosition = player.Character.HumanoidRootPart.Position
	end

	-- Call original function
	OriginalShowPrompt(self, player, promptType, promptData)
end

-- Debounced HideChairPrompt
local function DebouncedHidePrompt(self, player)
	if not player then
		return
	end

	local userId = player.UserId

	-- Initialize state if needed
	InitializePlayerState(player)
	local state = PlayerPromptState[userId]

	if state.isVisible then
		print("🚫 ProximityDebounceFix: Hiding prompt for " .. player.Name)
		state.isVisible = false
		state.lastPromptType = "none"

		-- Call original function
		OriginalHidePrompt(self, player)
	else
		print("🔇 ProximityDebounceFix: Hide prompt ignored for " .. player.Name .. " (not visible)")
	end
end

-- Override the remote event functions
ShowChairPrompt.FireClient = DebouncedShowPrompt
HideChairPrompt.FireClient = DebouncedHidePrompt

-- Setup player handlers
Players.PlayerAdded:Connect(function(player)
	InitializePlayerState(player)

	-- Setup chat commands for debugging
	player.Chatted:Connect(function(message)
		if player.Name == "TommySalami311" then -- Replace with your username
			local command = message:lower()

			if command == "/promptstate" then
				local userId = player.UserId
				local state = PlayerPromptState[userId]
				if state then
					print("=== PROMPT STATE FOR " .. player.Name .. " ===")
					print("Last prompt type: " .. state.lastPromptType)
					print("Last prompt time: " .. state.lastPromptTime)
					print("Is visible: " .. tostring(state.isVisible))
					print("Time since last: " .. (tick() - state.lastPromptTime))
					print("Debounce time: " .. state.debounceTime)
					print("=====================================")
				else
					print("❌ No prompt state found for " .. player.Name)
				end

			elseif command == "/resetprompt" then
				local userId = player.UserId
				if PlayerPromptState[userId] then
					PlayerPromptState[userId].lastPromptTime = 0
					PlayerPromptState[userId].isVisible = false
					PlayerPromptState[userId].lastPromptType = "none"
					print("🔄 Reset prompt state for " .. player.Name)
				end

			elseif command == "/setdebounce" then
				local userId = player.UserId
				if PlayerPromptState[userId] then
					-- Cycle through debounce times: 3, 5, 10, 15
					local current = PlayerPromptState[userId].debounceTime
					local newTime = 3
					if current == 3 then newTime = 5
					elseif current == 5 then newTime = 10
					elseif current == 10 then newTime = 15
					elseif current == 15 then newTime = 3
					end

					PlayerPromptState[userId].debounceTime = newTime
					print("🔧 Set debounce time to " .. newTime .. " seconds for " .. player.Name)
				end
			end
		end
	end)
end)

Players.PlayerRemoving:Connect(CleanupPlayerState)

-- Setup for existing players
for _, player in pairs(Players:GetPlayers()) do
	InitializePlayerState(player)
end

print("✅ ProximityDebounceFix: Debounce system active!")
print("📢 Commands available (for TommySalami311):")
print("   /promptstate - Show current prompt state")
print("   /resetprompt - Reset prompt state")
print("   /setdebounce - Cycle debounce time (3/5/10/15 seconds)")

-- Make functions globally available for debugging
_G.ProximityDebounceFix = {
	PlayerPromptState = PlayerPromptState,
	DebouncedShowPrompt = DebouncedShowPrompt,
	DebouncedHidePrompt = DebouncedHidePrompt,
	InitializePlayerState = InitializePlayerState,
	CleanupPlayerState = CleanupPlayerState
}