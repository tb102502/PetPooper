--[[
    MilkingClickFix.server.lua - Fix Milking Click and Session Issues
    Place in: ServerScriptService/MilkingClickFix.server.lua
    
    This script fixes milking session clicking issues and ensures proper client-server communication
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

print("🥛 MilkingClickFix: Starting milking click system repair...")

-- ========== NOTE: CLIENT-SIDE SCRIPT NEEDED ==========
-- The client-side click handler needs to be created separately as a LocalScript
-- See the companion MilkingClickHandler.client.lua script

-- ========== SERVER-SIDE CLICK HANDLING IMPROVEMENTS ==========

local function enhanceServerClickHandling()
	print("🔧 Enhancing server-side click handling...")

	if not _G.CowMilkingModule then
		warn("❌ CowMilkingModule not available")
		return false
	end

	-- Enhanced HandleContinueMilking function
	local originalHandleContinueMilking = _G.CowMilkingModule.HandleContinueMilking

	_G.CowMilkingModule.HandleContinueMilking = function(self, player)
		print("🖱️ Server received milking click from " .. player.Name)

		local userId = player.UserId
		local session = self.ActiveSessions[userId]

		if not session then 
			print("❌ No active session for " .. player.Name)
			return 
		end

		if not session.isActive then
			print("❌ Session not active for " .. player.Name)
			return
		end

		print("✅ Processing milking click for " .. player.Name)

		-- Check if player is still seated
		local character = player.Character
		if not character then
			print("❌ No character for " .. player.Name)
			self:HandleStopMilkingSession(player)
			return
		end

		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid then
			print("❌ No humanoid for " .. player.Name)
			self:HandleStopMilkingSession(player)
			return
		end

		local isSeated = false
		local success = pcall(function()
			isSeated = humanoid.Sit
		end)

		if not success or not isSeated then
			print("❌ Player " .. player.Name .. " not seated - ending session")
			self:HandleStopMilkingSession(player)
			return
		end

		-- Collect milk
		local milkCollected = self.Config.milkPerClick
		session.milkCollected = session.milkCollected + milkCollected
		session.lastClickTime = os.time()

		print("🥛 " .. player.Name .. " collected " .. milkCollected .. " milk (total: " .. session.milkCollected .. "/" .. session.maxMilk .. ")")

		-- Send feedback to client
		if self.RemoteEvents and self.RemoteEvents.MilkingSessionUpdate then
			pcall(function()
				self.RemoteEvents.MilkingSessionUpdate:FireClient(player, {
					milkCollected = session.milkCollected,
					maxMilk = session.maxMilk,
					lastClick = milkCollected
				})
			end)
		end

		-- Visual feedback
		if _G.GameCore and _G.GameCore.SendNotification then
			_G.GameCore:SendNotification(player, "🥛 +" .. milkCollected .. " Milk", 
				"Total: " .. session.milkCollected .. "/" .. session.maxMilk, "info")
		end

		-- Check limits
		if session.milkCollected >= session.maxMilk then
			self:SendNotification(player, "🥛 Cow Empty!", 
				"This cow has no more milk! Session ending.", "info")
			self:HandleStopMilkingSession(player)
			return
		end
	end

	print("✅ Enhanced server-side click handling")
	return true
end

-- ========== REMOTE EVENT VERIFICATION ==========

local function verifyRemoteEvents()
	print("📡 Verifying remote events...")

	local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not gameRemotes then
		warn("❌ GameRemotes folder not found")
		return false
	end

	local requiredEvents = {
		"ShowChairPrompt",
		"HideChairPrompt",
		"StartMilkingSession", 
		"StopMilkingSession",
		"ContinueMilking",
		"MilkingSessionUpdate"
	}

	local missingEvents = {}
	local workingEvents = {}

	for _, eventName in ipairs(requiredEvents) do
		local event = gameRemotes:FindFirstChild(eventName)
		if event and event:IsA("RemoteEvent") then
			-- Test if FireClient works
			local hasFireClient = typeof(event.FireClient) == "function"
			if hasFireClient then
				table.insert(workingEvents, eventName)
			else
				table.insert(missingEvents, eventName .. " (broken FireClient)")
			end
		else
			table.insert(missingEvents, eventName)
		end
	end

	print("✅ Working remote events: " .. table.concat(workingEvents, ", "))
	if #missingEvents > 0 then
		print("❌ Missing/broken remote events: " .. table.concat(missingEvents, ", "))

		-- Try to recreate missing events
		for _, eventName in ipairs(requiredEvents) do
			local event = gameRemotes:FindFirstChild(eventName)
			if not event then
				local newEvent = Instance.new("RemoteEvent")
				newEvent.Name = eventName
				newEvent.Parent = gameRemotes
				print("✅ Created missing remote event: " .. eventName)
			end
		end
	end

	return #missingEvents == 0
end

-- ========== MILKING SESSION DEBUG ==========

local function createMilkingSessionDebugger()
	print("🔍 Creating milking session debugger...")

	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			local command = message:lower()

			if command == "/debugmilking" then
				print("🔍 Debugging milking system for " .. player.Name .. "...")

				if _G.CowMilkingModule then
					local session = _G.CowMilkingModule.ActiveSessions[player.UserId]

					if session then
						print("✅ Active milking session:")
						print("  Cow ID: " .. session.cowId)
						print("  Milk collected: " .. session.milkCollected .. "/" .. session.maxMilk)
						print("  Is active: " .. tostring(session.isActive))
						print("  Start time: " .. session.startTime)
						print("  Last click: " .. session.lastClickTime)
					else
						print("❌ No active milking session")
					end

					-- Check if player is seated
					if player.Character and player.Character:FindFirstChild("Humanoid") then
						local humanoid = player.Character.Humanoid
						local isSeated = false
						local seatPart = nil

						pcall(function()
							isSeated = humanoid.Sit
							seatPart = humanoid.SeatPart
						end)

						print("Player seated: " .. tostring(isSeated))
						if seatPart then
							print("Seat: " .. seatPart.Name)
							print("Is milking chair: " .. tostring(seatPart:GetAttribute("IsMilkingChair")))
						end
					end
				else
					print("❌ CowMilkingModule not available")
				end

			elseif command == "/testmilkclick" then
				print("🧪 Testing milking click for " .. player.Name .. "...")

				if _G.CowMilkingModule and _G.CowMilkingModule.HandleContinueMilking then
					_G.CowMilkingModule:HandleContinueMilking(player)
					print("📡 Manual click test sent")
				else
					print("❌ HandleContinueMilking not available")
				end

			elseif command == "/forcemilkstart" then
				print("🔧 Force starting milking session for " .. player.Name .. "...")

				-- Find player's cow
				local playerCowId = nil
				if _G.GameCore then
					local playerData = _G.GameCore:GetPlayerData(player)
					if playerData and playerData.livestock and playerData.livestock.cows then
						for cowId, _ in pairs(playerData.livestock.cows) do
							playerCowId = cowId
							break
						end
					end
				end

				if playerCowId and _G.CowMilkingModule and _G.CowMilkingModule.HandleStartMilkingSession then
					_G.CowMilkingModule:HandleStartMilkingSession(player, playerCowId)
					print("📡 Force start session sent for cow: " .. playerCowId)
				else
					print("❌ Could not find cow or start session")
				end

			elseif command == "/checkremotemilk" then
				print("📡 Checking remote events for milking...")

				local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
				if gameRemotes then
					local continueEvent = gameRemotes:FindFirstChild("ContinueMilking")
					if continueEvent then
						print("✅ ContinueMilking event exists")
						print("  Type: " .. continueEvent.ClassName)
						print("  FireClient available: " .. tostring(typeof(continueEvent.FireClient) == "function"))
					else
						print("❌ ContinueMilking event not found")
					end
				else
					print("❌ GameRemotes folder not found")
				end
			end
		end)
	end)

	print("✅ Milking session debugger ready")
end

-- ========== MAIN EXECUTION ==========

local function main()
	-- Verify and fix remote events
	local remoteEventsWorking = verifyRemoteEvents()

	-- Enhance server-side handling
	wait(1) -- Give CowMilkingModule time to load
	local serverEnhanced = enhanceServerClickHandling()

	-- Create debugging tools
	createMilkingSessionDebugger()

	print("✅ MilkingClickFix: Setup complete!")
	print("  Remote events: " .. (remoteEventsWorking and "✅" or "⚠️"))
	print("  Server enhanced: " .. (serverEnhanced and "✅" or "⚠️"))
	print("  ⚠️ NOTE: You need to create the client-side MilkingClickHandler.client.lua script separately")
end

-- Execute with delay
wait(3)

local success, error = pcall(main)

if not success then
	warn("❌ MilkingClickFix failed: " .. tostring(error))
else
	print("🎉 MilkingClickFix: Server-side setup complete!")
	print("")
	print("🚨 IMPORTANT: You must also add the client-side script!")
	print("📝 Create: StarterPlayer/StarterPlayerScripts/MilkingClickHandler.client.lua")
	print("📋 Copy the MilkingClickHandler.client.lua code to that file")
	print("")
	print("🥛 SERVER-SIDE MILKING FIXES APPLIED:")
	print("  ✅ Enhanced server-side handling")  
	print("  ✅ Remote event verification")
	print("  ✅ Debug tools available")
	print("")
	print("🎮 DEBUG COMMANDS:")
	print("  /debugmilking - Debug milking session")
	print("  /testmilkclick - Test milking click")
	print("  /forcemilkstart - Force start milking session")
	print("  /checkremotemilk - Check remote events")
	print("")
	print("⚠️ After adding the client script, milking clicks should work!")
end