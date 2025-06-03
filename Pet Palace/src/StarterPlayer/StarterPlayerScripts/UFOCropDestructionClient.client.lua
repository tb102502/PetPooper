-- UFOCropDestructionClient.lua
-- Place in StarterPlayerScripts

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local ufoAttackEvent = ReplicatedStorage:WaitForChild("UFOAttack")

local sirenSound = Instance.new("Sound", SoundService)
sirenSound.SoundId = "rbxassetid://9118828566" -- Tornado siren asset ID; replace if needed
sirenSound.Volume = 1

local originalSky = Lighting:FindFirstChildOfClass("Sky")
local darkenTween

ufoAttackEvent.OnClientEvent:Connect(function(action, destroyedCount)
	if action == "START" then
		-- Sky darken
		darkenTween = TweenService:Create(Lighting, TweenInfo.new(2), {Brightness = 0.1, OutdoorAmbient = Color3.fromRGB(0, 64, 0)})
		darkenTween:Play()
		-- Siren
		sirenSound:Play()
		-- TODO: Animate UFO beam (can use a Part + Tween or particle)
		-- Example: create a green cylinder and tween its position through the plots
	elseif action == "END" then
		-- Restore sky
		if darkenTween then darkenTween:Cancel() end
		Lighting.Brightness = 2
		Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
		sirenSound:Stop()
		-- Show notification
		local player = Players.LocalPlayer
		game.StarterGui:SetCore("SendNotification", {
			Title = "UFO Attack!",
			Text = destroyedCount .. " crops destroyed!",
			Duration = 5
		})
		-- Remove/tween out beam if present
	end
end)