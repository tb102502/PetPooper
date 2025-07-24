--[[
    Wheat System Debug Commands
    Place in: ServerScriptService (as a Script)
    
    This script provides debug commands for testing the wheat harvesting system.
    Use these commands in chat to test and troubleshoot the system.
]]

local Players = game:GetService("Players")

-- Debug command handler
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.Name == "TommySalami311" then -- Updated to your username
			local command = message:lower()

			if command == "/wheatdebug" then
				print("=== WHEAT SYSTEM DEBUG INFO ===")

				-- Check WheatField structure
				local wheatField = workspace:FindFirstChild("WheatField")
				if wheatField then
					print("✅ WheatField found: " .. wheatField.Name)

					-- Check sections
					for i = 1, 6 do
						local section = wheatField:FindFirstChild("Section" .. i)
						if section then
							local grainCluster = section:FindFirstChild("GrainCluster" .. i)
							if grainCluster then
								local partCount = 0
								for _, child in pairs(grainCluster:GetChildren()) do
									if child:IsA("BasePart") and child.Name == "Part" then
										partCount = partCount + 1
									end
								end
								print("✅ Section" .. i .. "/GrainCluster" .. i .. " has " .. partCount .. " Parts")
							else
								print("❌ GrainCluster" .. i .. " not found in Section" .. i)
							end
						else
							print("❌ Section" .. i .. " not found")
						end
					end
				else
					print("❌ WheatField not found in workspace")
				end

				-- Check ScytheGiver
				local scytheGiver = workspace:FindFirstChild("ScytheGiver")
				if scytheGiver then
					print("✅ ScytheGiver found: " .. scytheGiver.Name)
				else
					print("❌ ScytheGiver not found in workspace")
				end

				-- Check WheatHarvesting system
				if _G.WheatHarvesting then
					print("✅ WheatHarvesting system loaded")
					_G.WheatHarvesting:DebugStatus()
				else
					print("❌ WheatHarvesting system not loaded")
				end

				-- Check ScytheGiver system
				if _G.ScytheGiver then
					print("✅ ScytheGiver system loaded")
				else
					print("❌ ScytheGiver system not loaded")
				end

				print("===============================")
--[[
    Animation Testing Commands
    Add these to your WheatDebugCommands.lua for testing animations
]]

				-- Add these commands to your existing debug script:

			elseif command == "/testanimation" then
				local character = player.Character
				if character and character:FindFirstChild("Scythe") then
					local scythe = character:FindFirstChild("Scythe")
					local localScript = scythe:FindFirstChildOfClass("LocalScript")

					if localScript then
						print("✅ Testing scythe animation...")
						print("  Character: " .. character.Name)
						print("  Scythe equipped: ✅")
						print("  LocalScript found: ✅")

						-- Simulate tool activation
						scythe:Activate()
						print("  Animation triggered!")
					else
						print("❌ No LocalScript found in scythe")
					end
				else
					print("❌ Player doesn't have scythe equipped")
					print("   Use /givescythe first")
				end

			elseif command == "/animationstatus" then
				print("=== ANIMATION SYSTEM STATUS ===")

				local character = player.Character
				if character then
					print("Character: ✅ " .. character.Name)

					-- Check character type
					local torso = character:FindFirstChild("Torso")
					local upperTorso = character:FindFirstChild("UpperTorso")

					if torso then
						print("Character Type: R6")
					elseif upperTorso then
						print("Character Type: R15")
					else
						print("Character Type: Unknown ❌")
					end

					-- Check humanoid and animator
					local humanoid = character:FindFirstChild("Humanoid")
					if humanoid then
						print("Humanoid: ✅")

						local animator = humanoid:FindFirstChild("Animator")
						if animator then
							print("Animator: ✅")
						else
							print("Animator: ❌ Missing")
						end
					else
						print("Humanoid: ❌ Missing")
					end

					-- Check for scythe
					local scythe = character:FindFirstChild("Scythe")
					if scythe then
						print("Scythe Equipped: ✅")

						local localScript = scythe:FindFirstChildOfClass("LocalScript")
						if localScript then
							print("Animation Script: ✅ " .. localScript.Name)
						else
							print("Animation Script: ❌ Missing")
						end
					else
						print("Scythe Equipped: ❌")

						-- Check backpack
						local backpackScythe = player.Backpack:FindFirstChild("Scythe")
						if backpackScythe then
							print("Scythe in Backpack: ✅ (not equipped)")
						else
							print("Scythe in Backpack: ❌")
						end
					end
				else
					print("Character: ❌ Not loaded")
				end
				print("==============================")

			elseif command == "/forceswing" then
				-- Force trigger scythe swing regardless of cooldowns
				local character = player.Character
				if character and character:FindFirstChild("Scythe") then
					local scythe = character:FindFirstChild("Scythe")

					-- Fire the remote directly
					local gameRemotes = game:GetService("ReplicatedStorage"):FindFirstChild("GameRemotes")
					if gameRemotes then
						local swingRemote = gameRemotes:FindFirstChild("SwingScythe")
						if swingRemote then
							swingRemote:FireServer()
							print("✅ Forced scythe swing sent to server")
						else
							print("❌ SwingScythe remote not found")
						end
					else
						print("❌ GameRemotes not found")
					end
				else
					print("❌ Scythe not equipped")
				end

			elseif command == "/listanimations" then
				print("=== AVAILABLE ANIMATION IDS ===")
				print("These are the fallback Roblox animations:")
				print("1. rbxassetid://522635514 - Sword slash")
				print("2. rbxassetid://218504594 - Tool swing") 
				print("3. rbxassetid://507768375 - Axe chop")
				print("4. rbxassetid://522625313 - Combat swing")
				print("5. rbxassetid://507766388 - Tool use")
				print("")
				print("Custom procedural animations:")
				print("1. Horizontal Swing (side to side)")
				print("2. Overhead Swing (up then down)")
				print("3. Diagonal Swing (curved arc)")
				print("==============================")

				-- Update the help command to include animation testing
			elseif command == "/wheathelp" then
				print("🌾 WHEAT SYSTEM DEBUG COMMANDS:")
				print("  /wheatdebug - Show complete system status")
				print("  /givescythe - Give yourself a scythe")
				print("  /checkscythe - Check scythe tool setup")
				print("  /testanimation - Test scythe swing animation")
				print("  /animationstatus - Check animation system status")
				print("  /forceswing - Force trigger scythe swing")
				print("  /listanimations - Show available animations")
				print("  /wheatcount - Show available wheat count")
				print("  /resetwheat - Reset all wheat sections")
				print("  /checkstructure - Show wheat field structure")
				print("  /testproximity - Test proximity detection")
				print("  /wheathelp - Show this help")
				print("")
				print("🎬 ANIMATION TESTING WORKFLOW:")
				print("  1. /givescythe - Get a scythe")
				print("  2. /animationstatus - Check system is ready")
				print("  3. /testanimation - Test the swing")
				print("  4. Click scythe normally to see variations")
				print("")
				print("🔧 SETUP CHECKLIST:")
				print("  1. Scythe tool in ServerStorage named 'Scythe'")
				print("  2. Scythe has Handle part and LocalScript")
				print("  3. LocalScript contains animation code")
				print("  4. Character has Humanoid and Animator")
				print("  5. WheatField model in workspace")
				print("  6. ScytheGiver model in workspace")
			elseif command == "/givescythe" then
				if _G.ScytheGiver then
					_G.ScytheGiver:GiveScytheToPlayer(player)
					print("✅ Gave and equipped scythe to " .. player.Name)
				else
					print("❌ ScytheGiver system not available")
				end

			elseif command == "/checkscythe" then
				if _G.ScytheGiver then
					print("=== SCYTHE TOOL CHECK ===")
					local serverStorage = game:GetService("ServerStorage")
					local scythe = serverStorage:FindFirstChild("Scythe")

					if scythe and scythe:IsA("Tool") then
						print("✅ Scythe tool found in ServerStorage")
						print("  Name: " .. scythe.Name)
						print("  Class: " .. scythe.ClassName)

						-- Check Handle
						local handle = scythe:FindFirstChild("Handle")
						print("  Handle: " .. (handle and "✅ Found" or "❌ Missing"))

						-- Check LocalScript
						local hasScript = false
						for _, child in pairs(scythe:GetChildren()) do
							if child:IsA("LocalScript") then
								hasScript = true
								print("  LocalScript: ✅ Found (" .. child.Name .. ")")
								break
							end
						end
						if not hasScript then
							print("  LocalScript: ❌ Missing")
						end

						-- Check properties
						print("  RequiresHandle: " .. tostring(scythe.RequiresHandle))
						print("  CanBeDropped: " .. tostring(scythe.CanBeDropped))
					else
						print("❌ Scythe tool not found in ServerStorage")
						print("   Make sure your tool is:")
						print("   1. Named exactly 'Scythe'")
						print("   2. Located in ServerStorage") 
						print("   3. Is a Tool object (not Model)")
					end
					print("========================")
				else
					print("❌ ScytheGiver system not available")
				end

			elseif command == "/wheatcount" then
				if _G.WheatHarvesting then
					local availableWheat = _G.WheatHarvesting:GetAvailableWheatCount()
					print("🌾 Available wheat: " .. availableWheat)
				else
					print("❌ WheatHarvesting system not available")
				end

			elseif command == "/resetwheat" then
				if _G.WheatHarvesting then
					-- Reset all sections
					for i, sectionData in pairs(_G.WheatHarvesting.SectionData) do
						if sectionData.grainCluster then
							-- Restore all Parts in the grain cluster
							for _, child in pairs(sectionData.grainCluster:GetChildren()) do
								if child:IsA("BasePart") and child.Name == "Part" then
									child.Transparency = 0
									child.CanCollide = true
								end
							end
						end

						-- Reset section data
						sectionData.availableGrains = sectionData.totalGrains
						sectionData.respawnTime = 0
					end
					print("✅ Reset all wheat sections")
				else
					print("❌ WheatHarvesting system not available")
				end

			elseif command == "/checkstructure" then
				print("=== WHEAT FIELD STRUCTURE CHECK ===")
				local wheatField = workspace:FindFirstChild("WheatField")
				if wheatField then
					print("WheatField structure:")

					local function printChildren(parent, indent)
						for _, child in pairs(parent:GetChildren()) do
							local childType = child.ClassName
							local extraInfo = ""

							if child:IsA("BasePart") then
								extraInfo = " (Size: " .. tostring(child.Size) .. ")"
							elseif child:IsA("Model") then
								local partCount = 0
								for _, descendant in pairs(child:GetChildren()) do
									if descendant:IsA("BasePart") and descendant.Name == "Part" then
										partCount = partCount + 1
									end
								end
								if partCount > 0 then
									extraInfo = " (" .. partCount .. " Parts)"
								end
							end

							print(indent .. child.Name .. " (" .. childType .. ")" .. extraInfo)

							if child:IsA("Model") and #indent < 8 then -- Limit depth
								printChildren(child, indent .. "  ")
							end
						end
					end

					printChildren(wheatField, "  ")
				else
					print("❌ WheatField not found")
				end
				print("===================================")

			elseif command == "/testproximity" then
				if _G.WheatHarvesting then
					-- Force proximity check
					local character = player.Character
					if character and character:FindFirstChild("HumanoidRootPart") then
						_G.WheatHarvesting:PlayerEnteredWheatProximity(player)
						print("✅ Triggered proximity check for " .. player.Name)
					else
						print("❌ Player character not found")
					end
				else
					print("❌ WheatHarvesting system not available")
				end

			elseif command == "/wheathelp" then
				print("🌾 WHEAT SYSTEM DEBUG COMMANDS:")
				print("  /wheatdebug - Show complete system status")
				print("  /givescythe - Give yourself a scythe")
				print("  /checkscythe - Check scythe tool setup")
				print("  /wheatcount - Show available wheat count")
				print("  /resetwheat - Reset all wheat sections")
				print("  /checkstructure - Show wheat field structure")
				print("  /testproximity - Test proximity detection")
				print("  /wheathelp - Show this help")
				print("")
				print("🔧 SETUP CHECKLIST:")
				print("  1. Scythe tool in ServerStorage named 'Scythe'")
				print("  2. Scythe has Handle part and LocalScript")
				print("  3. WheatField model in workspace")
				print("  4. Section1-6 inside WheatField")
				print("  5. GrainCluster1-6 inside each Section")
				print("  6. Multiple Parts inside each GrainCluster")
				print("  7. ScytheGiver model in workspace")
			end
		end
	end)
end)

print("🌾 Wheat System Debug Commands loaded!")
print("Change 'YourUsernameHere' to your username to use commands.")
print("Use /wheathelp to see available commands.")