--[[
    ChairDiagnostic.server.lua - Immediate Chair Detection and Fix
    Place in: ServerScriptService/ChairDiagnostic.server.lua
    
    This script helps diagnose and immediately fix chair detection issues
]]

local Players = game:GetService("Players")

wait(2) -- Wait for systems to load

print("🔍 ChairDiagnostic: Starting immediate chair analysis...")

-- ========== IMMEDIATE CHAIR FIX ==========

local function forceFixChairs()
	print("🔧 ChairDiagnostic: Force fixing all MilkingChair objects...")

	local chairsFixed = 0

	-- Find all MilkingChair objects in workspace
	for _, obj in pairs(workspace:GetChildren()) do
		if obj.Name == "MilkingChair" then
			print("🪑 Found MilkingChair: " .. obj.Name .. " (" .. obj.ClassName .. ")")

			-- Ensure it has the right attributes
			obj:SetAttribute("IsMilkingChair", true)

			local chairId = obj:GetAttribute("ChairId")
			if not chairId then
				chairId = "fixed_chair_" .. tick() .. "_" .. math.random(1000, 9999)
				obj:SetAttribute("ChairId", chairId)
			end

			-- If it's a model, find the seat part
			if obj:IsA("Model") then
				for _, child in pairs(obj:GetDescendants()) do
					if child:IsA("Seat") then
						child:SetAttribute("IsMilkingChair", true)
						child:SetAttribute("ChairId", chairId)
						child:SetAttribute("ParentModel", obj.Name)
						print("  ✅ Fixed seat in model: " .. child.Name)
						chairsFixed = chairsFixed + 1
						break
					end
				end
			elseif obj:IsA("Seat") then
				-- It's already a seat, just ensure attributes
				obj:SetAttribute("ChairId", chairId)
				print("  ✅ Fixed direct seat: " .. obj.Name)
				chairsFixed = chairsFixed + 1
			end

			print("  📍 Position: " .. tostring(obj:GetPivot().Position))
		end
	end

	return chairsFixed
end

-- ========== WORKSPACE ANALYSIS ==========

local function analyzeWorkspace()
	print("\n🌍 ChairDiagnostic: Analyzing workspace...")

	local totalObjects = 0
	local chairObjects = 0
	local cowObjects = 0
	local seatObjects = 0

	for _, obj in pairs(workspace:GetChildren()) do
		totalObjects = totalObjects + 1

		if obj.Name == "MilkingChair" then
			chairObjects = chairObjects + 1
			print("🪑 MilkingChair found: " .. obj.Name .. " (" .. obj.ClassName .. ") at " .. tostring(obj:GetPivot().Position))

			-- Check attributes
			local isMilkingChair = obj:GetAttribute("IsMilkingChair")
			local chairId = obj:GetAttribute("ChairId")
			print("  IsMilkingChair: " .. tostring(isMilkingChair))
			print("  ChairId: " .. tostring(chairId))

			-- If it's a model, check for seats inside
			if obj:IsA("Model") then
				for _, child in pairs(obj:GetDescendants()) do
					if child:IsA("Seat") then
						print("  📍 Contains seat: " .. child.Name)
						local seatChairId = child:GetAttribute("ChairId")
						local seatIsMilking = child:GetAttribute("IsMilkingChair")
						print("    Seat ChairId: " .. tostring(seatChairId))
						print("    Seat IsMilkingChair: " .. tostring(seatIsMilking))
					end
				end
			end
		end

		if obj.Name == "cow" or obj.Name:find("cow_") then
			cowObjects = cowObjects + 1
			local owner = obj:GetAttribute("Owner")
			print("🐄 Cow found: " .. obj.Name .. " (owner: " .. tostring(owner) .. ") at " .. tostring(obj:GetPivot().Position))
		end

		if obj:IsA("Seat") then
			seatObjects = seatObjects + 1
			if obj.Name ~= "MilkingChair" then
				print("🪑 Other seat found: " .. obj.Name .. " at " .. tostring(obj.Position))
			end
		end
	end

	print("\n📊 Workspace Summary:")
	print("  Total objects: " .. totalObjects)
	print("  MilkingChair objects: " .. chairObjects)
	print("  Cow objects: " .. cowObjects)
	print("  Seat objects: " .. seatObjects)
end

-- ========== SYSTEM CHECK ==========

local function checkMilkingSystem()
	print("\n🔍 ChairDiagnostic: Checking milking system...")

	if _G.CowMilkingModule then
		print("✅ CowMilkingModule found")

		if _G.CowMilkingModule.MilkingChairs then
			local registeredChairs = 0
			for chairId, chair in pairs(_G.CowMilkingModule.MilkingChairs) do
				registeredChairs = registeredChairs + 1
				if chair and chair.Parent then
					print("  Registered chair: " .. chairId .. " at " .. tostring(chair.Position))
				else
					print("  ⚠️ Invalid registered chair: " .. chairId)
				end
			end
			print("Total registered chairs: " .. registeredChairs)

			-- Force rescan if available
			if _G.CowMilkingModule.ForceRescanChairs then
				print("🔄 Force rescanning chairs...")
				local rescannedCount = _G.CowMilkingModule:ForceRescanChairs()
				print("✅ Rescanned - found: " .. rescannedCount .. " chairs")
			end

			-- Debug chairs if available
			if _G.CowMilkingModule.DebugChairs then
				_G.CowMilkingModule:DebugChairs()
			end
		else
			print("❌ CowMilkingModule.MilkingChairs not found")
		end
	else
		print("❌ CowMilkingModule not found")
	end
end

-- ========== DEBUG COMMANDS ==========

local function setupDiagnosticCommands()
	print("🔧 Setting up diagnostic commands...")

	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Change to your username
				local command = message:lower()

				if command == "/fixchairs" then
					print("🔧 Force fixing chairs...")
					local fixed = forceFixChairs()
					print("✅ Fixed " .. fixed .. " chairs")

					-- Force rescan in milking system
					if _G.CowMilkingModule and _G.CowMilkingModule.ForceRescanChairs then
						local rescanned = _G.CowMilkingModule:ForceRescanChairs()
						print("✅ Rescanned - total: " .. rescanned .. " chairs")
					end

				elseif command == "/analyzeworkspace" then
					analyzeWorkspace()

				elseif command == "/checksystem" then
					checkMilkingSystem()

				elseif command == "/fulldiag" then
					print("🔍 Running full diagnostic...")
					analyzeWorkspace()
					checkMilkingSystem()
					local fixed = forceFixChairs()
					print("✅ Diagnostic complete - fixed " .. fixed .. " chairs")

				elseif command == "/debugproximity" then
					print("🔍 Debug proximity for " .. player.Name)
					if _G.CowMilkingModule and _G.CowMilkingModule.DebugPlayerProximity then
						_G.CowMilkingModule:DebugPlayerProximity(player)
					end

				elseif command == "/resetproximity" then
					print("🔄 Reset proximity for " .. player.Name)
					if _G.CowMilkingModule and _G.CowMilkingModule.ResetPlayerProximity then
						_G.CowMilkingModule:ResetPlayerProximity(player)
					end

				elseif command == "/testchair" then
					print("🧪 Testing chair detection for " .. player.Name)
					if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
						local playerPos = player.Character.HumanoidRootPart.Position

						-- Find nearest chair
						local nearestChair = nil
						local nearestDistance = math.huge

						for _, obj in pairs(workspace:GetChildren()) do
							if obj.Name == "MilkingChair" then
								local distance = (playerPos - obj:GetPivot().Position).Magnitude
								if distance < nearestDistance then
									nearestDistance = distance
									nearestChair = obj
								end
							end
						end

						if nearestChair then
							print("Nearest chair: " .. nearestChair.Name .. " at distance " .. math.floor(nearestDistance))
							print("Chair attributes:")
							print("  IsMilkingChair: " .. tostring(nearestChair:GetAttribute("IsMilkingChair")))
							print("  ChairId: " .. tostring(nearestChair:GetAttribute("ChairId")))
						else
							print("❌ No chairs found")
						end
					end
				end
			end
		end)
	end)

	print("✅ Diagnostic commands ready")
end

-- ========== MAIN EXECUTION ==========

local function main()
	-- Run immediate analysis
	analyzeWorkspace()

	-- Force fix chairs
	local fixed = forceFixChairs()
	print("🔧 Force fixed " .. fixed .. " chairs")

	-- Check system
	checkMilkingSystem()

	-- Setup commands
	setupDiagnosticCommands()

	print("✅ ChairDiagnostic: Ready!")
end

-- Execute
local success, error = pcall(main)

if not success then
	warn("❌ ChairDiagnostic failed: " .. tostring(error))
else
	print("🎉 ChairDiagnostic: Complete!")
	print("")
	print("🎮 Commands Available:")
	print("  /fixchairs - Force fix chair attributes and rescan")
	print("  /analyzeworkspace - Analyze all objects in workspace")
	print("  /checksystem - Check milking system status")
	print("  /fulldiag - Run complete diagnostic")
	print("  /debugproximity - Debug proximity detection")
	print("  /resetproximity - Reset proximity state")
	print("  /testchair - Test chair detection near you")
	print("")
	print("🔧 The system should now properly detect your MilkingChair!")
end