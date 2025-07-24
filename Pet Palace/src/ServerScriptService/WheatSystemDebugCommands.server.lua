local Players = game:GetService("Players")
-- Debug command handler
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.Name == "TommySalami311" then -- Updated to your username
			local command = message:lower()
			if command == "/wheatdebug" then
				print("=== CHUNK-BASED WHEAT SYSTEM DEBUG INFO ===")

				-- Check WheatField structure
				local wheatField = workspace:FindFirstChild("WheatField")
				if wheatField then
					print("✅ WheatField found: " .. wheatField.Name)

					-- Check sections - UPDATED for 2 sections
					for i = 1, 2 do
						local section = wheatField:FindFirstChild("Section" .. i)
						if section then
							local grainCluster = section:FindFirstChild("GrainCluster" .. i)
							if grainCluster then
								local chunkCount = 0
								for _, child in pairs(grainCluster:GetChildren()) do
									if child:IsA("BasePart") or child:IsA("Model") then
										chunkCount = chunkCount + 1
									end
								end
								print("✅ Section" .. i .. "/GrainCluster" .. i .. " has " .. chunkCount .. " chunks")
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

				print("=======================================")

			elseif command == "/chunkcount" then
				if _G.WheatHarvesting then
					local availableWheat = _G.WheatHarvesting:GetAvailableWheatCount()
					local availableChunks = _G.WheatHarvesting:GetAvailableChunkCount()
					print("🌾 Available wheat: " .. availableWheat)
					print("🌾 Available chunks: " .. availableChunks)
					print("🌾 Wheat per chunk: 5")
				else
					print("❌ WheatHarvesting system not available")
				end

			elseif command == "/resetwheat" then
				if _G.WheatHarvesting then
					-- Reset all sections - UPDATED for chunk system
					for i, sectionData in pairs(_G.WheatHarvesting.SectionData) do
						if sectionData.grainCluster then
							-- Restore all chunks in the grain cluster
							for _, child in pairs(sectionData.grainCluster:GetChildren()) do
								if child:IsA("BasePart") then
									child.Transparency = 0
									child.CanCollide = true
								elseif child:IsA("Model") then
									for _, part in pairs(child:GetDescendants()) do
										if part:IsA("BasePart") then
											part.Transparency = 0
											part.CanCollide = true
										end
									end
								end
							end
						end

						-- Reset section data
						sectionData.availableChunks = sectionData.totalChunks
						sectionData.respawnTime = 0
					end
					print("✅ Reset all wheat sections (chunk-based)")
				else
					print("❌ WheatHarvesting system not available")
				end

			elseif command == "/checkstructure" then
				print("=== CHUNK-BASED WHEAT FIELD STRUCTURE CHECK ===")
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
								local chunkCount = 0
								for _, descendant in pairs(child:GetChildren()) do
									if descendant:IsA("BasePart") or descendant:IsA("Model") then
										chunkCount = chunkCount + 1
									end
								end
								if chunkCount > 0 then
									extraInfo = " (" .. chunkCount .. " chunks)"
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
				print("=============================================")

			elseif command == "/givescythe" then
				if _G.ScytheGiver then
					_G.ScytheGiver:GiveScytheToPlayer(player)
					print("✅ Gave and equipped scythe to " .. player.Name)
				else
					print("❌ ScytheGiver system not available")
				end

			elseif command == "/testchunkharvest" then
				print("🌾 Testing chunk harvesting...")
				if _G.WheatHarvesting then
					local character = player.Character
					if character and character:FindFirstChild("HumanoidRootPart") then
						-- Simulate finding and harvesting closest chunk
						local closestChunk = _G.WheatHarvesting:HarvestClosestChunk(player)
						if closestChunk then
							print("✅ Successfully harvested a wheat chunk")
						else
							print("❌ No chunks found nearby to harvest")
						end
					else
						print("❌ Player character not found")
					end
				else
					print("❌ WheatHarvesting system not available")
				end

			elseif command == "/wheathelp" then
				print("🌾 CHUNK-BASED WHEAT SYSTEM DEBUG COMMANDS:")
				print("  /wheatdebug - Show complete system status")
				print("  /chunkcount - Show available chunks and wheat")
				print("  /resetwheat - Reset all wheat sections")
				print("  /checkstructure - Show wheat field structure")
				print("  /givescythe - Give yourself a scythe")
				print("  /testchunkharvest - Test chunk harvesting")
				print("  /wheathelp - Show this help")
				print("")
				print("🔧 CHUNK-BASED SETUP CHECKLIST:")
				print("  1. WheatField model in workspace")
				print("  2. Section1-2 inside WheatField (reduced from 6)")
				print("  3. GrainCluster1-2 inside each Section")
				print("  4. Multiple chunks/parts inside each GrainCluster")
				print("  5. Each swing harvests one chunk = 5 wheat")
				print("  6. ScytheGiver model in workspace")
				print("  7. Scythe tool in ServerStorage named 'Scythe'")
				print("")
				print("⚡ CHUNK SYSTEM BENEFITS:")
				print("  • Better performance (fewer objects)")
				print("  • Faster harvesting (5 wheat per swing)")
				print("  • More satisfying visual effects")
				print("  • Easier to manage and debug")
			end
		end
	end)
end)
print("🌾 Chunk-based Wheat System Debug Commands loaded!")
print("Updated for 2 sections instead of 6, chunk-based harvesting.")
print("Use /wheathelp to see available commands.")