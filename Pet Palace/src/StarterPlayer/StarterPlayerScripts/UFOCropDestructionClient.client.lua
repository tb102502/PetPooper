local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

-- Wait for UFO event
local ufoAttackEvent = ReplicatedStorage:WaitForChild("UFOAttack", 10)
if not ufoAttackEvent then
	warn("UFOClient: UFOAttack event not found")
	return
end

-- Create siren sound with fallback
local sirenSound = Instance.new("Sound", SoundService)
-- Use a working sound ID or fallback to built-in sounds
sirenSound.SoundId = "rbxassetid://138223429" -- Fallback sound
sirenSound.Volume = 0.5

local darkenTween
ufoAttackEvent.OnClientEvent:Connect(function(action, destroyedCount, protectedCount)
	if action == "START" then
		print("UFO Attack starting!")

		-- Sky darken effect
		local success, _ = pcall(function()
			darkenTween = TweenService:Create(Lighting, TweenInfo.new(2), {
				Brightness = 0.1, 
				OutdoorAmbient = Color3.fromRGB(0, 64, 0)
			})
			darkenTween:Play()
		end)

		-- Play siren sound
		local soundSuccess, _ = pcall(function()
			sirenSound:Play()
		end)

		if not soundSuccess then
			print("UFO: Sound not available, using visual effects only")
		end

		-- Show UFO attack warning with roof protection info
		local notificationSuccess, _ = pcall(function()
			local player = Players.LocalPlayer
			if player then
				-- Check if player has roof protection
				local hasProtection = false
				if _G.GameClient and _G.GameClient.GetPlayerData then
					local playerData = _G.GameClient:GetPlayerData()
					if playerData and playerData.roofs then
						for _, roofInfo in pairs(playerData.roofs) do
							if roofInfo.installed then
								hasProtection = true
								break
							end
						end
					end
				end

				local warningText = "UFO ATTACK INCOMING!"
				if hasProtection then
					warningText = warningText .. "\n🏠 Your crops are protected by roofs!"
				else
					warningText = warningText .. "\n⚠️ Your crops are vulnerable! Buy roof protection!"
				end

				game.StarterGui:SetCore("SendNotification", {
					Title = "🛸 UFO ATTACK!",
					Text = warningText,
					Duration = 5
				})
			end
		end)

	elseif action == "END" then
		destroyedCount = destroyedCount or 0
		protectedCount = protectedCount or 0

		print("UFO Attack ended! Crops destroyed:", destroyedCount, "Crops protected:", protectedCount)

		-- Restore sky
		local success, _ = pcall(function()
			if darkenTween then 
				darkenTween:Cancel() 
			end
			Lighting.Brightness = 2
			Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
		end)

		-- Stop siren
		local soundSuccess, _ = pcall(function()
			sirenSound:Stop()
		end)

		-- Show detailed results notification
		local notificationSuccess, _ = pcall(function()
			local player = Players.LocalPlayer
			if player then
				local titleText = "UFO Attack Complete!"
				local resultText = ""

				if destroyedCount > 0 and protectedCount > 0 then
					-- Mixed results
					titleText = "🛸 UFO Attack: Mixed Results"
					resultText = "🔥 " .. destroyedCount .. " crops destroyed\n🏠 " .. protectedCount .. " crops protected by roofs!"
				elseif destroyedCount > 0 and protectedCount == 0 then
					-- All crops destroyed
					titleText = "🛸 UFO Attack: Devastating!"
					resultText = "🔥 " .. destroyedCount .. " crops destroyed!\n💡 Buy roof protection to save your crops!"
				elseif destroyedCount == 0 and protectedCount > 0 then
					-- All crops protected
					titleText = "🛸 UFO Attack: Completely Blocked!"
					resultText = "🏠 All " .. protectedCount .. " crops protected!\n✨ Your roof investment paid off!"
				else
					-- No crops found
					titleText = "🛸 UFO Attack: No Targets"
					resultText = "No crops were found in the attack zone"
				end

				game.StarterGui:SetCore("SendNotification", {
					Title = titleText,
					Text = resultText,
					Duration = 8
				})

				-- Also show GameClient notification if available
				if _G.GameClient and _G.GameClient.ShowNotification then
					if protectedCount > 0 then
						_G.GameClient:ShowNotification("🏠 Roof Protection Worked!", 
							protectedCount .. " crops saved by your roof protection!", "success")
					elseif destroyedCount > 0 then
						_G.GameClient:ShowNotification("🛸 UFO Attack!", 
							destroyedCount .. " crops destroyed! Consider buying roof protection.", "warning")
					end
				end
			end
		end)

		if not notificationSuccess then
			print("UFO: Destroyed " .. destroyedCount .. " crops, protected " .. protectedCount .. " crops!")
		end
	end
end)