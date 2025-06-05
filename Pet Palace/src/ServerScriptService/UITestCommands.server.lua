-- UITestCommands.server.lua
-- Place this in ServerScriptService to test the UI systems
-- This helps verify the Shop, Farm, and Settings menus are working

wait(3)

local Players = game:GetService("Players")

print("=== UI TEST COMMANDS ACTIVE ===")

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		-- Replace with your username for testing
		if player.Name == "TommySalami311" then -- Your username
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/testui" then
				print("Testing UI systems for " .. player.Name)

				-- Send a test notification
				local remoteFolder = game:GetService("ReplicatedStorage"):FindFirstChild("GameRemotes")
				if remoteFolder then
					local showNotification = remoteFolder:FindFirstChild("ShowNotification")
					if showNotification then
						showNotification:FireClient(player, "UI Test", "All UI systems should be working!", "success")
					end
				end

			elseif command == "/testshop" then
				print("Testing shop functionality...")
				-- You can add shop testing logic here

			elseif command == "/testfarm" then
				print("Testing farm functionality...")
				-- You can add farm testing logic here

			elseif command == "/resetui" then
				print("Resetting UI for " .. player.Name)
				-- Force client to reinitialize
				local remoteFolder = game:GetService("ReplicatedStorage"):FindFirstChild("GameRemotes")
				if remoteFolder then
					local playerDataUpdated = remoteFolder:FindFirstChild("PlayerDataUpdated")
					if playerDataUpdated then
						-- Send fresh player data to reset UI
						local GameCore = _G.GameCore
						if GameCore then
							local playerData = GameCore:GetPlayerData(player)
							playerDataUpdated:FireClient(player, playerData)
						end
					end
				end
			end
		end
	end)
end)

print("UI Test Commands available:")
print("  /testui - Test notification system")
print("  /testshop - Test shop functionality")  
print("  /testfarm - Test farm functionality")
print("  /resetui - Reset UI for player")
print("Remember to change the username in the script!")