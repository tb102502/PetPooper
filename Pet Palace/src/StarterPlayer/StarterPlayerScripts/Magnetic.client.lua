
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

print("Magnetic: Starting magnetic pet system...")

-- Wait for GameClient with timeout
local function waitForGameClient(timeout)
	timeout = timeout or 30
	local start = tick()

	while tick() - start < timeout do
		if _G.GameClient then
			return _G.GameClient
		end
		wait(1)
	end

	return nil
end

-- Try to get GameClient
local GameClient = waitForGameClient(30)

if GameClient then
	print("Magnetic: Connected to GameClient successfully")

	-- Your magnetic pet collection code here
	-- This would integrate with GameClient's proximity system

else
	warn("Magnetic: GameClient not available after 30 seconds")
	print("Magnetic: Running in fallback mode without GameClient integration")

	-- Create basic magnetic collection without GameClient
	local magneticConnection = RunService.Heartbeat:Connect(function()
		local character = LocalPlayer.Character
		if not character or not character:FindFirstChild("HumanoidRootPart") then
			return
		end

		local playerPosition = character.HumanoidRootPart.Position

		-- Basic pet detection without GameClient
		local areas = workspace:FindFirstChild("Areas")
		if areas then
			for _, area in pairs(areas:GetChildren()) do
				local pets = area:FindFirstChild("Pets")
				if pets then
					for _, pet in pairs(pets:GetChildren()) do
						if pet:IsA("Model") and pet.PrimaryPart then
							local distance = (pet.PrimaryPart.Position - playerPosition).Magnitude

							-- Simple magnetic collection
							if distance < 8 then -- 8 stud collection range
								print("Magnetic: Collected " .. pet.Name)
								pet:Destroy()
							end
						end
					end
				end
			end
		end
	end)

	print("Magnetic: Fallback magnetic system active")
end
