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
sirenSound.SoundId = "rbxasset://sounds/impact_water.mp3" -- Fallback sound
sirenSound.Volume = 0.5

local darkenTween

ufoAttackEvent.OnClientEvent:Connect(function(action, destroyedCount)
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

	elseif action == "END" then
		print("UFO Attack ended! Crops destroyed:", destroyedCount or 0)

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

		-- Show notification
		local notificationSuccess, _ = pcall(function()
			local player = Players.LocalPlayer
			if player then
				game.StarterGui:SetCore("SendNotification", {
					Title = "UFO Attack Complete!",
					Text = (destroyedCount or 0) .. " crops destroyed!",
					Duration = 5
				})
			end
		end)

		if not notificationSuccess then
			print("UFO: Destroyed " .. (destroyedCount or 0) .. " crops!")
		end
	end
end)

print("UFO System: Client loaded successfully")
