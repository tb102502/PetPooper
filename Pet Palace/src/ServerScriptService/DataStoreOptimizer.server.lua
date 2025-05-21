-- Place in ServerScriptService
-- This script helps optimize DataStore usage by:
-- 1. Debouncing frequent save requests
-- 2. Ensuring saves happen before player leaves
-- 3. Spreading out auto-saves to avoid queue filling

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Try to load your existing PlayerDataService
local PlayerDataService
pcall(function()
	PlayerDataService = require(ServerStorage:WaitForChild("Modules"):WaitForChild("PlayerDataService"))
end)

if not PlayerDataService then
	warn("PlayerDataService module not found!")
	return
end

-- Player save debounce times (key = player.UserId, value = last save time)
local lastSaveTimes = {}
local SAVE_COOLDOWN = 20 -- Minimum seconds between saves for a player
local AUTOSAVE_INTERVAL = 180 -- Seconds between automatic saves
local AUTOSAVE_STAGGER = 15 -- Seconds to stagger autosaves between players

-- Function to save player data with debounce
local function savePlayerDataWithDebounce(player)
	if not player or not player.UserId then return end

	local currentTime = os.time()
	local lastSaveTime = lastSaveTimes[player.UserId] or 0

	if currentTime - lastSaveTime >= SAVE_COOLDOWN then
		-- Enough time has passed, save the data
		local success = pcall(function()
			PlayerDataService.SavePlayerData(player)
		end)

		if success then
			lastSaveTimes[player.UserId] = currentTime
			print("Saved data for " .. player.Name)
		else
			warn("Failed to save data for " .. player.Name)
		end
	else
		-- Too soon, skip this save
		print("Skipping save for " .. player.Name .. " (too soon)")
	end
end

-- Handle player leaving (priority save)
Players.PlayerRemoving:Connect(function(player)
	-- Always save when player leaves, regardless of cooldown
	local success = pcall(function()
		PlayerDataService.SavePlayerData(player)
	end)

	if success then
		print("Final save completed for " .. player.Name)
	else
		warn("Final save FAILED for " .. player.Name)
	end

	-- Clean up last save time
	lastSaveTimes[player.UserId] = nil
end)

-- Set up staggered auto-save for each player
local function setupAutoSaveForPlayer(player, index)
	-- Stagger save times to avoid all players saving at once
	local staggerTime = (index - 1) * AUTOSAVE_STAGGER
	local initialDelay = 30 + staggerTime

	spawn(function()
		wait(initialDelay) -- Initial delay with stagger

		while player and player.Parent == Players do
			savePlayerDataWithDebounce(player)
			wait(AUTOSAVE_INTERVAL)
		end
	end)

	print("Auto-save initialized for " .. player.Name .. " (stagger: " .. staggerTime .. "s)")
end

-- Set up auto-save for existing players
for index, player in ipairs(Players:GetPlayers()) do
	setupAutoSaveForPlayer(player, index)
end

-- Set up auto-save for new players
Players.PlayerAdded:Connect(function(player)
	-- Get count of players for staggering
	local playerCount = #Players:GetPlayers()
	setupAutoSaveForPlayer(player, playerCount)
end)

-- Hook into game close to save all data
game:BindToClose(function()
	for _, player in pairs(Players:GetPlayers()) do
		pcall(function()
			PlayerDataService.SavePlayerData(player)
		end)
	end

	-- Give time for saves to complete
	wait(5)
end)

print("DataStore optimizer loaded - managing save frequency")