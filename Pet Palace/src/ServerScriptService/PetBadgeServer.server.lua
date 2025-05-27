-- PetBadges.server.lua
-- Badge rewards for pet collection achievements
-- Author: tb102502

local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Remote events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdatePlayerStats = RemoteEvents:WaitForChild("UpdatePlayerStats")
local AwardBadge = RemoteEvents:WaitForChild("AwardBadge", true) or Instance.new("RemoteEvent")
if AwardBadge.Parent ~= RemoteEvents then
	AwardBadge.Name = "AwardBadge"
	AwardBadge.Parent = RemoteEvents
end

-- Main game module
local MainGameModule = require(game:GetService("ServerScriptService"):WaitForChild("MainGameModule"))
local PetChallenges = require(ReplicatedStorage:WaitForChild("PetChallenges"))

-- Define badge IDs
-- Replace these with your actual badge IDs from your Roblox game
local BadgeIds = {
	FIRST_PET = 123456789, -- First pet collected
	TEN_PETS = 123456790, -- 10 pets collected
	FIFTY_PETS = 123456791, -- 50 pets collected
	HUNDRED_PETS = 123456792, -- 100 pets collected
	FIRST_RARE = 123456793, -- First rare pet
	FIRST_EPIC = 123456794, -- First epic pet
	FIRST_LEGENDARY = 123456795, -- First legendary pet
	COLLECTOR = 123456796, -- All pet types collected
	CHALLENGE_MASTER = 123456797 -- Complete all challenges
}

-- Define badge info
local Badges = {
	{
		id = BadgeIds.FIRST_PET,
		name = "First Pet",
		description = "Collected your first pet",
		checkFunction = function(playerData)
			return (playerData.stats and playerData.stats.totalPetsCollected or 0) >= 1
		end
	},
	{
		id = BadgeIds.TEN_PETS,
		name = "Pet Enthusiast",
		description = "Collected 10 pets",
		checkFunction = function(playerData)
			return (playerData.stats and playerData.stats.totalPetsCollected or 0) >= 10
		end
	},
	{
		id = BadgeIds.FIFTY_PETS,
		name = "Pet Collector",
		description = "Collected 50 pets",
		checkFunction = function(playerData)
			return (playerData.stats and playerData.stats.totalPetsCollected or 0) >= 50
		end
	},
	{
		id = BadgeIds.HUNDRED_PETS,
		name = "Pet Master",
		description = "Collected 100 pets",
		checkFunction = function(playerData)
			return (playerData.stats and playerData.stats.totalPetsCollected or 0) >= 100
		end
	},
	{
		id = BadgeIds.FIRST_RARE,
		name = "Rare Finder",
		description = "Found your first rare pet",
		checkFunction = function(playerData)
			return (playerData.stats and playerData.stats.rareFound or 0) >= 1
		end
	},
	{
		id = BadgeIds.FIRST_EPIC,
		name = "Epic Discovery",
		description = "Found your first epic pet",
		checkFunction = function(playerData)
			return (playerData.stats and playerData.stats.epicFound or 0) >= 1
		end
	},
	{
		id = BadgeIds.FIRST_LEGENDARY,
		name = "Legendary Achievement",
		description = "Found your first legendary pet",
		checkFunction = function(playerData)
			return (playerData.stats and playerData.stats.legendaryFound or 0) >= 1
		end
	}
}

-- Function to check and award badges based on player data
local function checkBadges(player)
	-- Get player data
	local playerData = MainGameModule.GetPlayerData(player)
	if not playerData then return end

	-- Initialize awarded badges if not exists
	if not playerData.awardedBadges then
		playerData.awardedBadges = {}
	end

	-- Check each badge
	for _, badge in ipairs(Badges) do
		-- Skip if already awarded
		if playerData.awardedBadges[badge.name] then
			continue
		end

		-- Check badge condition
		if badge.checkFunction(playerData) then
			-- Try to award badge
			local success, message = pcall(function()
				return BadgeService:AwardBadge(player.UserId, badge.id)
			end)

			if success then
				-- Mark as awarded in player data
				playerData.awardedBadges[badge.name] = true

				-- Save player data
				MainGameModule.SavePlayerData(player)

				-- Notify client
				AwardBadge:FireClient(player, badge.name, badge.description)

				print("Awarded badge:", badge.name, "to player:", player.Name)
			else
				warn("Failed to award badge:", badge.name, "to player:", player.Name, "- Error:", message)
			end
		end
	end
end

-- Handle pet collection for challenge tracking and badge awarding
local function setupChallengeSystem()
	-- Keep track of active challenges for each player
	local playerChallenges = {}

	-- Function to assign a new challenge to a player
	local function assignChallenge(player)
		local playerData = MainGameModule.GetPlayerData(player)
		if not playerData then return end

		-- Determine player level
		local playerLevel = 1
		if playerData.stats and playerData.stats.totalPetsCollected then
			playerLevel = math.floor(playerData.stats.totalPetsCollected / 10) + 1
		end

		-- Get a random challenge
		local challenge = PetChallenges.GetRandomChallenge(playerLevel)

		-- Initialize challenge data
		playerChallenges[player.UserId] = {
			challenge = challenge,
			progress = {
				count = 0,
				timeStart = os.time(),
				timeElapsed = 0,
				petCounts = {},
				areaCounts = {},
				rarityCounts = {}
			}
		}

		-- Notify player of new challenge
		RemoteEvents.SendNotification:FireClient(
			player,
			"New Challenge: " .. challenge.name,
			challenge.description,
			"challenge"
		)

		-- Send challenge data to client
		RemoteEvents.UpdateChallenge:FireClient(player, challenge, playerChallenges[player.UserId].progress)
	end

	-- Function to update challenge progress when a pet is collected
	local function updateChallengeProgress(player, petModel)
		if not player or not petModel then return end

		local userId = player.UserId

		-- Check if player has an active challenge
		if not playerChallenges[userId] then
			assignChallenge(player)
			return
		end

		local challengeData = playerChallenges[userId]
		local challenge = challengeData.challenge
		local progress = challengeData.progress

		-- Update general progress
		progress.count = progress.count + 1
		progress.timeElapsed = os.time() - progress.timeStart

		-- Update specific pet counts
		local petType = petModel:GetAttribute("PetType") or "Unknown"
		progress.petCounts[petType] = (progress.petCounts[petType] or 0) + 1

		-- Update area counts
		local areaName = petModel:GetAttribute("AreaOrigin") or "Unknown"
		progress.areaCounts[areaName] = (progress.areaCounts[areaName] or 0) + 1

		-- Update rarity counts
		local rarity = petModel:GetAttribute("Rarity") or "Common"
		progress.rarityCounts[rarity] = (progress.rarityCounts[rarity] or 0) + 1

		-- Check if challenge is completed
		if PetChallenges.CheckChallengeCompletion(challenge, progress) then
			-- Award reward
			local playerData = MainGameModule.GetPlayerData(player)
			if playerData then
				-- Add coins or other rewards
				if challenge.rewardType == "Coins" then
					playerData.coins = (playerData.coins or 0) + challenge.reward

					-- Save player data
					MainGameModule.SavePlayerData(player)

					-- Update client
					UpdatePlayerStats:FireClient(player, playerData)
				end

				-- Track completed challenges
				if not playerData.completedChallenges then
					playerData.completedChallenges = {}
				end

				playerData.completedChallenges[challenge.id] = true

				-- Save player data
				MainGameModule.SavePlayerData(player)

				-- Notify player
				RemoteEvents.SendNotification:FireClient(
					player,
					"Challenge Completed!",
					"You've completed the '" .. challenge.name .. "' challenge and earned " .. challenge.reward .. " " .. challenge.rewardType .. "!",
					"success"
				)

				-- Assign a new challenge after a delay
				task.spawn(function()
					task.wait(5)  -- Wait 5 seconds before assigning a new challenge
					assignChallenge(player)
				end)

				-- Check if all challenges completed for badge
				local allCompleted = true
				for _, challengeDef in ipairs(PetChallenges.Challenges) do
					if not playerData.completedChallenges[challengeDef.id] then
						allCompleted = false
						break
					end
				end

				if allCompleted then
					-- Try to award challenge master badge
					pcall(function()
						BadgeService:AwardBadge(player.UserId, BadgeIds.CHALLENGE_MASTER)
					end)
				end
			end
		else
			-- Update client on progress
			RemoteEvents.UpdateChallenge:FireClient(player, challenge, progress)
		end
	end

	-- Connect to pet collection event
	local CollectPet = RemoteEvents:WaitForChild("CollectPet")
	CollectPet.OnServerEvent:Connect(function(player, petModel)
		-- Update challenge progress
		updateChallengeProgress(player, petModel)

		-- Check for badges
		task.spawn(function()
			checkBadges(player)
		end)
	end)

	-- Initialize players
	for _, player in ipairs(Players:GetPlayers()) do
		assignChallenge(player)
	end

	-- Handle new players
	Players.PlayerAdded:Connect(function(player)
		-- Wait for player data to be loaded
		task.wait(2)

		-- Assign initial challenge
		assignChallenge(player)
	end)

	-- Handle players leaving
	Players.PlayerRemoving:Connect(function(player)
		-- Clean up challenge data
		playerChallenges[player.UserId] = nil
	end)
end

-- Initialize the badge and challenge systems
setupChallengeSystem()

print("Pet badge and challenge system initialized")