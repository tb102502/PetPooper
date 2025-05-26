-- PetChallenges.lua
-- Mini-challenges for pet collection
-- Author: tb102502

local PetChallenges = {}

-- Challenge types
PetChallenges.Types = {
	CHAIN = "Chain Collection", -- Collect multiple pets in quick succession
	SPECIFIC = "Specific Pet", -- Collect specific pets
	TIMED = "Timed Collection", -- Collect certain number in time limit
	AREA = "Area Collection", -- Collect from specific area
	RARE = "Rare Find" -- Find pets of specific rarity
}

-- Define challenges
PetChallenges.Challenges = {
	-- Chain challenges
	{
		id = "chain_3",
		name = "Quick Collector",
		type = PetChallenges.Types.CHAIN,
		description = "Collect 3 pets within 3 seconds",
		requirement = 3,
		timeLimit = 3,
		reward = 50,
		rewardType = "Coins"
	},
	{
		id = "chain_5",
		name = "Speed Collector",
		type = PetChallenges.Types.CHAIN,
		description = "Collect 5 pets within 5 seconds",
		requirement = 5,
		timeLimit = 5,
		reward = 100,
		rewardType = "Coins"
	},
	{
		id = "chain_10",
		name = "Lightning Collector",
		type = PetChallenges.Types.CHAIN,
		description = "Collect 10 pets within 10 seconds",
		requirement = 10,
		timeLimit = 10,
		reward = 250,
		rewardType = "Coins"
	},

	-- Specific pet challenges
	{
		id = "specific_bunny",
		name = "Bunny Hunter",
		type = PetChallenges.Types.SPECIFIC,
		description = "Collect 5 Bunnies",
		targetPet = "Common Bunny",
		requirement = 5,
		reward = 75,
		rewardType = "Coins"
	},
	{
		id = "specific_fox",
		name = "Fox Finder",
		type = PetChallenges.Types.SPECIFIC,
		description = "Collect 3 Foxes",
		targetPet = "Rare Fox",
		requirement = 3,
		reward = 150,
		rewardType = "Coins"
	},

	-- Timed challenges
	{
		id = "timed_30",
		name = "Rush Hour",
		type = PetChallenges.Types.TIMED,
		description = "Collect 10 pets in 30 seconds",
		requirement = 10,
		timeLimit = 30,
		reward = 200,
		rewardType = "Coins"
	},

	-- Area challenges
	{
		id = "area_starter",
		name = "Home Ground",
		type = PetChallenges.Types.AREA,
		description = "Collect 15 pets from the Starter Area",
		targetArea = "StarterArea",
		requirement = 15,
		reward = 100,
		rewardType = "Coins"
	},
	{
		id = "area_mystic",
		name = "Mystical Hunter",
		type = PetChallenges.Types.AREA,
		description = "Collect 10 pets from the Mystic Forest",
		targetArea = "MysticForest",
		requirement = 10,
		reward = 200,
		rewardType = "Coins"
	},

	-- Rarity challenges
	{
		id = "rare_find",
		name = "Rare Finder",
		type = PetChallenges.Types.RARE,
		description = "Find 3 Rare pets",
		targetRarity = "Rare",
		requirement = 3,
		reward = 150,
		rewardType = "Coins"
	},
	{
		id = "epic_find",
		name = "Epic Hunter",
		type = PetChallenges.Types.RARE,
		description = "Find 2 Epic pets",
		targetRarity = "Epic",
		requirement = 2,
		reward = 300,
		rewardType = "Coins"
	},
	{
		id = "legendary_find",
		name = "Legend Seeker",
		type = PetChallenges.Types.RARE,
		description = "Find 1 Legendary pet",
		targetRarity = "Legendary",
		requirement = 1,
		reward = 500,
		rewardType = "Coins"
	}
}

-- Get a random challenge based on player level
function PetChallenges.GetRandomChallenge(playerLevel)
	local availableChallenges = {}

	for _, challenge in ipairs(PetChallenges.Challenges) do
		-- Filter challenges based on player level
		if not challenge.minLevel or playerLevel >= challenge.minLevel then
			table.insert(availableChallenges, challenge)
		end
	end

	if #availableChallenges > 0 then
		return availableChallenges[math.random(1, #availableChallenges)]
	end

	-- Fallback to first challenge if none available
	return PetChallenges.Challenges[1]
end

-- Get challenges by type
function PetChallenges.GetChallengesByType(challengeType)
	local filteredChallenges = {}

	for _, challenge in ipairs(PetChallenges.Challenges) do
		if challenge.type == challengeType then
			table.insert(filteredChallenges, challenge)
		end
	end

	return filteredChallenges
end

-- Check if a challenge is completed
function PetChallenges.CheckChallengeCompletion(challenge, progress)
	if not challenge or not progress then return false end

	-- Different check logic based on challenge type
	if challenge.type == PetChallenges.Types.CHAIN then
		-- Check if enough pets were collected within time limit
		return progress.count >= challenge.requirement and
			progress.timeElapsed <= challenge.timeLimit
	elseif challenge.type == PetChallenges.Types.SPECIFIC then
		-- Check if enough of specific pet was collected
		return (progress.petCounts[challenge.targetPet] or 0) >= challenge.requirement
	elseif challenge.type == PetChallenges.Types.TIMED then
		-- Check if enough pets were collected within time limit
		return progress.count >= challenge.requirement and
			progress.timeElapsed <= challenge.timeLimit
	elseif challenge.type == PetChallenges.Types.AREA then
		-- Check if enough pets from target area were collected
		return (progress.areaCounts[challenge.targetArea] or 0) >= challenge.requirement
	elseif challenge.type == PetChallenges.Types.RARE then
		-- Check if enough pets of target rarity were collected
		return (progress.rarityCounts[challenge.targetRarity] or 0) >= challenge.requirement
	end

	return false
end

return PetChallenges