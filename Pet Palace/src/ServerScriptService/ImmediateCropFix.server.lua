-- ADD this immediate fix script to ServerScriptService
-- Place as: ServerScriptService/ImmediateCropFix.server.lua

print("=== IMMEDIATE CROP FIX SCRIPT ACTIVE ===")

-- Function to fix all stuck crops immediately
local function FixAllStuckCrops()
	print("🚑 EMERGENCY CROP FIX - Scanning all crops...")

	local garden = workspace:FindFirstChild("Garden")
	if not garden then
		print("❌ Garden not found")
		return
	end

	local totalCrops = 0
	local stuckCrops = 0
	local fixedCrops = 0

	-- Scan all garden regions
	for _, region in pairs(garden:GetChildren()) do
		if region:IsA("Model") and region.Name:find("_GardenRegion") then
			local playerName = region.Name:gsub("_GardenRegion", "")
			local plantingSpots = region:FindFirstChild("PlantingSpots")

			if plantingSpots then
				print("🔍 Checking " .. playerName .. "'s garden...")

				for _, spot in pairs(plantingSpots:GetChildren()) do
					if spot:IsA("Model") and spot.Name:find("PlantingSpot") then
						local isEmpty = spot:GetAttribute("IsEmpty")

						if not isEmpty then
							totalCrops = totalCrops + 1

							-- Get crop info
							local cropType = spot:GetAttribute("PlantType") or "unknown"
							local seedType = spot:GetAttribute("SeedType") or "unknown"
							local growthStage = spot:GetAttribute("GrowthStage") or 0
							local plantedTime = spot:GetAttribute("PlantedTime") or 0
							local rarity = spot:GetAttribute("Rarity") or "common"

							local age = os.time() - plantedTime

							-- Get expected grow time from ItemConfig
							local expectedGrowTime = 300 -- default
							if _G.ItemConfig and _G.ItemConfig.ShopItems[seedType] then
								local seedData = _G.ItemConfig.ShopItems[seedType]
								if seedData.farmingData and seedData.farmingData.growTime then
									expectedGrowTime = seedData.farmingData.growTime
								end
							end

							-- Check if crop should be ready but isn't
							if age >= expectedGrowTime and growthStage < 4 then
								stuckCrops = stuckCrops + 1

								print("🚑 FIXING STUCK CROP:")
								print("  Player: " .. playerName)
								print("  Spot: " .. spot.Name)
								print("  Crop: " .. cropType .. " (" .. seedType .. ")")
								print("  Age: " .. age .. "s (expected: " .. expectedGrowTime .. "s)")
								print("  Current Stage: " .. growthStage .. " (should be 4)")

								-- Fix the crop
								spot:SetAttribute("GrowthStage", 4)

								-- Clean up any stuck timers
								if _G.CropCreation and _G.CropCreation.GrowthTimers then
									local spotId = spot:GetDebugId() or tostring(spot)
									if _G.CropCreation.GrowthTimers[spotId] then
										_G.CropCreation.GrowthTimers[spotId]:Disconnect()
										_G.CropCreation.GrowthTimers[spotId] = nil
									end
								end

								-- Update visual to ready state
								if _G.CropVisual then
									local success = pcall(function()
										return _G.CropVisual:UpdateCropStage(spot, cropType, rarity, "ready", 4)
									end)

									if not success then
										-- Fallback: Add basic ready indicator
										local cropModel = spot:FindFirstChild("CropModel")
										if cropModel and cropModel.PrimaryPart then
											-- Remove existing lights
											for _, obj in pairs(cropModel.PrimaryPart:GetChildren()) do
												if obj:IsA("PointLight") then
													obj:Destroy()
												end
											end

											-- Add ready glow
											local readyGlow = Instance.new("PointLight")
											readyGlow.Name = "FixedReadyGlow"
											readyGlow.Color = Color3.fromRGB(255, 215, 0)
											readyGlow.Brightness = 2
											readyGlow.Range = 10
											readyGlow.Parent = cropModel.PrimaryPart
										end
									end
								end

								fixedCrops = fixedCrops + 1
								print("  ✅ FIXED!")
							end
						end
					end
				end
			end
		end
	end

	print("\n🚑 EMERGENCY FIX COMPLETE!")
	print("📊 Results:")
	print("  Total crops found: " .. totalCrops)
	print("  Stuck crops found: " .. stuckCrops) 
	print("  Crops fixed: " .. fixedCrops)
	print("  Working crops: " .. (totalCrops - stuckCrops))

	if fixedCrops > 0 then
		print("\n✅ " .. fixedCrops .. " crops have been fixed and should now be harvestable!")
		print("Try harvesting them now or use /forceharvest to test.")
	else
		print("\n✅ No stuck crops found - all crops are growing normally!")
	end
end

-- Auto-run the fix when script loads
spawn(function()
	wait(5) -- Wait for everything to load
	FixAllStuckCrops()
end)

-- Make it available globally
_G.FixAllStuckCrops = FixAllStuckCrops

-- Create an admin command for manual fixes
game.Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.Name == "TommySalami311" then -- Replace with your username
			local command = message:lower()

			if command == "/fixallcrops" then
				FixAllStuckCrops()
			elseif command == "/emergencyfix" then
				print("🚑 EMERGENCY FIX ACTIVATED BY " .. player.Name)
				FixAllStuckCrops()
			end
		end
	end)
end)

print("🚑 Immediate Crop Fix loaded!")
print("Commands: /fixallcrops, /emergencyfix")
print("Global function: _G.FixAllStuckCrops()")