--[[
    CaveAccessSetup.server.lua
    Place in: ServerScriptService/CaveAccessSetup.server.lua
    
    This script automatically grants cave access to all players for testing
    Remove this script in production and use your shop system instead
]]

local Players = game:GetService("Players")

-- Wait for MiningSystem to be available
local function waitForMiningSystem()
	while not _G.MiningSystem do
		wait(1)
		print("CaveAccessSetup: Waiting for MiningSystem...")
	end
	return _G.MiningSystem
end

local MiningSystem = waitForMiningSystem()
print("CaveAccessSetup: MiningSystem found!")

-- Function to grant cave access to a player
local function grantCaveAccess(player)
	local userId = player.UserId

	-- Initialize mining data if it doesn't exist
	if not MiningSystem.PlayerData[userId] then
		MiningSystem:InitializePlayerMining(player)
	end

	-- Grant cave access
	MiningSystem.PlayerData[userId].caveAccess = true

	print("CaveAccessSetup: ✅ Granted cave access to " .. player.Name)

	-- Optional: Give them a basic pickaxe too
	MiningSystem.PlayerData[userId].currentTool = "wooden_pickaxe"
	MiningSystem.PlayerData[userId].toolDurability = MiningSystem.PlayerData[userId].toolDurability or {}
	MiningSystem.PlayerData[userId].toolDurability["wooden_pickaxe"] = 50 -- 50 uses

	print("CaveAccessSetup: ✅ Gave " .. player.Name .. " a wooden pickaxe with 50 uses")

	-- Send welcome message
	if MiningSystem.SendNotification then
		MiningSystem:SendNotification(player, "🎉 Mining Unlocked!", 
			"Cave access granted! You can now teleport to your mining cave and start collecting ores!", "success")
	end
end

-- Grant access to existing players
for _, player in pairs(Players:GetPlayers()) do
	spawn(function()
		wait(2) -- Give mining system time to initialize
		grantCaveAccess(player)
	end)
end

-- Grant access to new players as they join
Players.PlayerAdded:Connect(function(player)
	spawn(function()
		wait(5) -- Give player time to load
		grantCaveAccess(player)
	end)
end)

print("CaveAccessSetup: ✅ Cave access setup script running!")
print("📋 All players will automatically get:")
print("   🕳️ Cave access (can teleport to caves)")
print("   ⛏️ Wooden pickaxe with 50 uses")
print("   💎 Ready to start mining!")
print("")
print("🚨 REMEMBER: Remove this script in production!")
print("🚨 Use your shop system to sell cave access instead!")