--[[
    CowOwnershipFix.server.lua - Fix Cow Ownership Issues
    Place in: ServerScriptService/CowOwnershipFix.server.lua
    
    This script fixes cow ownership attribution problems that prevent milking
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

print("🐄 CowOwnershipFix: Starting cow ownership repair...")

-- ========== COW OWNERSHIP REPAIR ==========

local function repairCowOwnership()
	print("🔧 CowOwnershipFix: Scanning and repairing cow ownership...")

	local repairedCount = 0

	-- Find all cow models in workspace
	for _, obj in pairs(workspace:GetChildren()) do
		local isCow = false
		local cowId = nil

		-- Check if it's a cow
		if obj.Name == "cow" then
			isCow = true
			cowId = "cow" -- Original cow
		elseif obj.Name:find("cow_") then
			isCow = true
			cowId = obj.Name
		elseif obj:GetAttribute("CowId") then
			isCow = true
			cowId = obj:GetAttribute("CowId")
		end

		if isCow and cowId then
			local currentOwner = obj:GetAttribute("Owner")

			if not currentOwner then
				-- Try to determine owner from cow ID
				local ownerId = nil
				local ownerName = nil

				-- Extract user ID from cow ID (format: cow_userId_number)
				local userIdMatch = cowId:match("cow_(%d+)_")
				if userIdMatch then
					ownerId = tonumber(userIdMatch)
					local player = Players:GetPlayerByUserId(ownerId)
					if player then
						ownerName = player.Name
					end
				end

				-- If no ID found, check if any player is nearby
				if not ownerName then
					for _, player in pairs(Players:GetPlayers()) do
						if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
							local playerPos = player.Character.HumanoidRootPart.Position
							local cowPos = obj:GetPivot().Position
							local distance = (playerPos - cowPos).Magnitude

							-- If player is very close, assume ownership
							if distance < 20 then
								ownerName = player.Name
								ownerId = player.UserId
								print("🔍 Inferred ownership: " .. cowId .. " -> " .. ownerName .. " (proximity)")
								break
							end
						end
					end
				end

				-- Set ownership if found
				if ownerName then
					obj:SetAttribute("Owner", ownerName)
					obj:SetAttribute("OwnerId", ownerId)
					obj:SetAttribute("CowId", cowId) -- Ensure cow ID is set
					repairedCount = repairedCount + 1
					print("✅ Repaired ownership: " .. cowId .. " -> " .. ownerName)
				else
					print("⚠️ Could not determine owner for: " .. cowId)
				end
			else
				-- Verify existing ownership
				local player = Players:FindFirstChild(currentOwner)
				if player then
					-- Ensure all attributes are set
					obj:SetAttribute("Owner", currentOwner)
					obj:SetAttribute("OwnerId", player.UserId)
					obj:SetAttribute("CowId", cowId)
					print("✅ Verified ownership: " .. cowId .. " -> " .. currentOwner)
				else
					print("⚠️ Owner not found for cow: " .. cowId .. " (owner: " .. currentOwner .. ")")
				end
			end
		end
	end

	print("🐄 CowOwnershipFix: Repaired " .. repairedCount .. " cow ownership issues")
	return repairedCount
end

-- ========== PLAYER DATA REPAIR ==========

local function repairPlayerCowData()
	print("🔧 CowOwnershipFix: Repairing player cow data...")

	if not _G.GameCore then
		print("⚠️ GameCore not available for data repair")
		return
	end

	local repairedPlayers = 0

	for _, player in pairs(Players:GetPlayers()) do
		local playerData = _G.GameCore:GetPlayerData(player)
		if playerData then
			-- Ensure livestock structure exists
			if not playerData.livestock then
				playerData.livestock = {cows = {}}
				print("🔧 Created livestock structure for " .. player.Name)
			end
			if not playerData.livestock.cows then
				playerData.livestock.cows = {}
				print("🔧 Created cows structure for " .. player.Name)
			end

			-- Check if player has cows in data
			local cowCount = 0
			for _ in pairs(playerData.livestock.cows) do
				cowCount = cowCount + 1
			end

			if cowCount == 0 then
				-- Player has no cows in data - check if they have cows in workspace
				local workspaceCows = {}
				for _, obj in pairs(workspace:GetChildren()) do
					local owner = obj:GetAttribute("Owner")
					if owner == player.Name and (obj.Name == "cow" or obj.Name:find("cow_")) then
						table.insert(workspaceCows, obj)
					end
				end

				if #workspaceCows > 0 then
					print("🔧 Found " .. #workspaceCows .. " workspace cows for " .. player.Name .. " without data")

					-- Create data for workspace cows
					for i, cowModel in ipairs(workspaceCows) do
						local cowId = cowModel:GetAttribute("CowId") or cowModel.Name
						local tier = cowModel:GetAttribute("Tier") or "basic"

						playerData.livestock.cows[cowId] = {
							cowId = cowId,
							tier = tier,
							milkAmount = 1,
							cooldown = 60,
							position = cowModel:GetPivot().Position,
							lastMilkCollection = 0,
							totalMilkProduced = 0,
							purchaseTime = os.time(),
							visualEffects = {},
							repairedOwnership = true
						}

						print("✅ Created data for cow: " .. cowId .. " (tier: " .. tier .. ")")
					end

					-- Save the data
					if _G.GameCore.SavePlayerData then
						_G.GameCore:SavePlayerData(player)
					end

					repairedPlayers = repairedPlayers + 1
				end
			else
				print("ℹ️ " .. player.Name .. " has " .. cowCount .. " cows in data")
			end
		end
	end

	print("🐄 CowOwnershipFix: Repaired data for " .. repairedPlayers .. " players")
end

-- ========== STARTER COW VERIFICATION ==========

local function ensureStarterCows()
	print("🐄 CowOwnershipFix: Ensuring all players have starter cows...")

	if not _G.CowCreationModule then
		print("⚠️ CowCreationModule not available")
		return
	end

	for _, player in pairs(Players:GetPlayers()) do
		if _G.CowCreationModule.CheckPlayerNeedsStarterCow then
			local needsCow = _G.CowCreationModule:CheckPlayerNeedsStarterCow(player)
			if needsCow then
				print("🐄 " .. player.Name .. " needs a starter cow")
				if _G.CowCreationModule.ForceGiveStarterCow then
					local success = _G.CowCreationModule:ForceGiveStarterCow(player)
					if success then
						print("✅ Gave starter cow to " .. player.Name)
					else
						print("❌ Failed to give starter cow to " .. player.Name)
					end
				end
			else
				print("ℹ️ " .. player.Name .. " already has cows")
			end
		end
	end
end

-- ========== DEBUG COMMANDS ==========

local function setupOwnershipCommands()
	print("🔧 Setting up ownership debug commands...")

	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Change to your username
				local command = message:lower()

				if command == "/fixownership" then
					print("🔧 Manual ownership repair for " .. player.Name .. "...")

					-- Find player's cows and fix ownership
					for _, obj in pairs(workspace:GetChildren()) do
						if obj.Name == "cow" or obj.Name:find("cow_") then
							local owner = obj:GetAttribute("Owner")
							if not owner or owner == "" then
								-- Check if player is nearby
								if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
									local playerPos = player.Character.HumanoidRootPart.Position
									local cowPos = obj:GetPivot().Position
									local distance = (playerPos - cowPos).Magnitude

									if distance < 30 then
										obj:SetAttribute("Owner", player.Name)
										obj:SetAttribute("OwnerId", player.UserId)
										obj:SetAttribute("CowId", obj.Name)
										print("✅ Fixed ownership: " .. obj.Name .. " -> " .. player.Name)
									end
								end
							end
						end
					end

				elseif command == "/checkcows" then
					print("🐄 Checking cows for " .. player.Name .. ":")

					-- Check workspace cows
					local workspaceCows = 0
					for _, obj in pairs(workspace:GetChildren()) do
						local owner = obj:GetAttribute("Owner")
						if owner == player.Name and (obj.Name == "cow" or obj.Name:find("cow_")) then
							workspaceCows = workspaceCows + 1
							print("  Workspace: " .. obj.Name .. " at " .. tostring(obj:GetPivot().Position))
						end
					end

					-- Check data cows
					local dataCows = 0
					if _G.GameCore then
						local playerData = _G.GameCore:GetPlayerData(player)
						if playerData and playerData.livestock and playerData.livestock.cows then
							for cowId, cowData in pairs(playerData.livestock.cows) do
								dataCows = dataCows + 1
								print("  Data: " .. cowId .. " (tier: " .. (cowData.tier or "unknown") .. ")")
							end
						end
					end

					print("Total - Workspace: " .. workspaceCows .. ", Data: " .. dataCows)

				elseif command == "/repairall" then
					print("🔧 Running complete ownership repair...")
					repairCowOwnership()
					repairPlayerCowData()
					ensureStarterCows()
					print("✅ Complete repair finished")

				elseif command == "/newcow" then
					print("🐄 Giving new cow to " .. player.Name .. "...")
					if _G.CowCreationModule and _G.CowCreationModule.ForceGiveStarterCow then
						local success = _G.CowCreationModule:ForceGiveStarterCow(player)
						print("Result: " .. tostring(success))
					else
						print("❌ CowCreationModule not available")
					end
				end
			end
		end)
	end)

	print("✅ Ownership commands ready")
end

-- ========== CONTINUOUS MONITORING ==========

local function startOwnershipMonitoring()
	print("👁️ Starting ownership monitoring...")

	spawn(function()
		while true do
			wait(30) -- Check every 30 seconds

			-- Quick ownership check
			for _, obj in pairs(workspace:GetChildren()) do
				if (obj.Name == "cow" or obj.Name:find("cow_")) and not obj:GetAttribute("Owner") then
					print("⚠️ Found cow without owner: " .. obj.Name)

					-- Try to assign to nearest player
					local nearestPlayer = nil
					local nearestDistance = math.huge

					for _, player in pairs(Players:GetPlayers()) do
						if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
							local distance = (player.Character.HumanoidRootPart.Position - obj:GetPivot().Position).Magnitude
							if distance < nearestDistance and distance < 50 then
								nearestDistance = distance
								nearestPlayer = player
							end
						end
					end

					if nearestPlayer then
						obj:SetAttribute("Owner", nearestPlayer.Name)
						obj:SetAttribute("OwnerId", nearestPlayer.UserId)
						print("✅ Auto-assigned cow " .. obj.Name .. " to " .. nearestPlayer.Name)
					end
				end
			end
		end
	end)
end

-- ========== MAIN EXECUTION ==========

wait(3) -- Wait for other systems to load

local function main()
	print("🐄 CowOwnershipFix: Starting main execution...")

	-- Run initial repairs
	repairCowOwnership()
	wait(1)
	repairPlayerCowData()
	wait(1)
	ensureStarterCows()

	-- Setup monitoring and commands
	setupOwnershipCommands()
	startOwnershipMonitoring()

	print("✅ CowOwnershipFix: System ready!")
end

-- Execute with error protection
local success, error = pcall(main)

if not success then
	warn("❌ CowOwnershipFix failed: " .. tostring(error))
else
	print("🎉 CowOwnershipFix: Ready!")
	print("")
	print("🎮 Commands Available:")
	print("  /fixownership - Fix ownership for nearby cows")
	print("  /checkcows - Check your cows in workspace and data")
	print("  /repairall - Run complete ownership repair")
	print("  /newcow - Get a new starter cow")
	print("")
	print("🔧 The system will automatically monitor and fix ownership issues!")
end