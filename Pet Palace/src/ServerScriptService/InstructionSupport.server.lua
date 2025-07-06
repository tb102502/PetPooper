-- InstructionSupport.server.lua
-- Place in: ServerScriptService/InstructionSupport.server.lua
-- Optional server-side support for the instruction system

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for GameCore if available
local GameCore = _G.GameCore

-- Create RemoteEvents for instruction system
local instructionEvents = Instance.new("Folder")
instructionEvents.Name = "InstructionEvents"
instructionEvents.Parent = ReplicatedStorage

local markInstructionsRead = Instance.new("RemoteEvent")
markInstructionsRead.Name = "MarkInstructionsRead"
markInstructionsRead.Parent = instructionEvents

local getInstructionStatus = Instance.new("RemoteFunction")
getInstructionStatus.Name = "GetInstructionStatus"
getInstructionStatus.Parent = instructionEvents

-- Track instruction completion
local instructionTracker = {}

print("=== INSTRUCTION SUPPORT SYSTEM LOADING ===")

-- Function to mark instructions as completed for a player
local function markPlayerInstructionsRead(player)
	instructionTracker[player.UserId] = {
		hasSeenInstructions = true,
		completedTime = os.time(),
		playerName = player.Name
	}

	-- Save to GameCore if available
	if GameCore and GameCore.SavePlayerData then
		pcall(function()
			local playerData = GameCore:GetPlayerData(player) or {}
			playerData.hasSeenInstructions = true
			playerData.instructionCompletedTime = os.time()
			GameCore:SavePlayerData(player, playerData)
		end)
	end

	print("InstructionSupport: " .. player.Name .. " completed instructions")

	-- Give new player bonus

end

-- Function to check if player has seen instructions
local function hasPlayerSeenInstructions(player)
	-- Check local tracker first
	if instructionTracker[player.UserId] then
		return instructionTracker[player.UserId].hasSeenInstructions
	end

	-- Check GameCore save data
	if GameCore and GameCore.GetPlayerData then
		local success, playerData = pcall(function()
			return GameCore:GetPlayerData(player)
		end)

		if success and playerData and playerData.hasSeenInstructions then
			-- Update local tracker
			instructionTracker[player.UserId] = {
				hasSeenInstructions = true,
				completedTime = playerData.instructionCompletedTime or 0,
				playerName = player.Name
			}
			return true
		end
	end

	return false
end

-- Remote event handlers
markInstructionsRead.OnServerEvent:Connect(function(player)
	markPlayerInstructionsRead(player)
end)

getInstructionStatus.OnServerInvoke = function(player)
	return hasPlayerSeenInstructions(player)
end

-- Player joined handler
Players.PlayerAdded:Connect(function(player)
	-- Small delay to let other systems load
	wait(1)

	local hasSeenInstructions = hasPlayerSeenInstructions(player)

	if hasSeenInstructions then
		print("InstructionSupport: " .. player.Name .. " has seen instructions before")
	else
		print("InstructionSupport: " .. player.Name .. " is a new player")

		-- Fire welcome event to client if needed
		pcall(function()
			local welcomeEvent = ReplicatedStorage:FindFirstChild("WelcomeNewPlayer")
			if welcomeEvent then
				welcomeEvent:FireClient(player, {
					isNewPlayer = true,
					welcomeMessage = "Welcome to Farm Defense!"
				})
			end
		end)
	end
end)

-- Player leaving cleanup
Players.PlayerRemoving:Connect(function(player)
	if instructionTracker[player.UserId] then
		instructionTracker[player.UserId] = nil
	end
end)

-- Admin commands for instruction management
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		-- Replace with your admin username
		if player.Name == "TommySalami311" then
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/resetinstructions" then
				local targetPlayerName = args[2]
				if targetPlayerName then
					local targetPlayer = Players:FindFirstChild(targetPlayerName)
					if targetPlayer then
						-- Reset their instruction status
						instructionTracker[targetPlayer.UserId] = nil

						if GameCore then
							pcall(function()
								local playerData = GameCore:GetPlayerData(targetPlayer) or {}
								playerData.hasSeenInstructions = false
								playerData.instructionCompletedTime = nil
								GameCore:SavePlayerData(targetPlayer, playerData)
							end)
						end

						print("Admin: Reset instruction status for " .. targetPlayer.Name)
					else
						print("Admin: Player " .. targetPlayerName .. " not found")
					end
				else
					print("Admin: Usage: /resetinstructions [playername]")
				end

			elseif command == "/instructionstats" then
				print("=== INSTRUCTION STATISTICS ===")
				local totalPlayers = 0
				local completedPlayers = 0

				for _, plr in pairs(Players:GetPlayers()) do
					totalPlayers = totalPlayers + 1
					if hasPlayerSeenInstructions(plr) then
						completedPlayers = completedPlayers + 1
						print("✅ " .. plr.Name .. " - Completed")
					else
						print("❌ " .. plr.Name .. " - Not completed")
					end
				end

				print("Total: " .. completedPlayers .. "/" .. totalPlayers .. " completed")
				print("===============================")

			elseif command == "/forceinstructions" then
				local targetPlayerName = args[2]
				if targetPlayerName then
					local targetPlayer = Players:FindFirstChild(targetPlayerName)
					if targetPlayer then
						-- Force show instructions
						local showEvent = ReplicatedStorage:FindFirstChild("ForceShowInstructions")
						if not showEvent then
							showEvent = Instance.new("RemoteEvent")
							showEvent.Name = "ForceShowInstructions"
							showEvent.Parent = ReplicatedStorage
						end
						showEvent:FireClient(targetPlayer)
						print("Admin: Forced instructions for " .. targetPlayer.Name)
					end
				else
					print("Admin: Usage: /forceinstructions [playername]")
				end
			end
		end
	end)
end)

print("=== INSTRUCTION SUPPORT SYSTEM READY ===")
print("Features:")
print("✅ Tracks instruction completion per player")
print("✅ Integrates with GameCore save system")
print("✅ Admin commands for management")
print("")
print("Admin Commands:")
print("  /resetinstructions [player] - Reset instruction status")
print("  /instructionstats - Show completion statistics")
print("  /forceinstructions [player] - Force show instructions")
print("")
print("  🎉 Welcome notification")