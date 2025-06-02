local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local selectedSeed = nil

local InventoryFrame = script.Parent:WaitForChild("InventoryFrame")
local SeedButtons = InventoryFrame:WaitForChild("SeedButtons")

for _, button in pairs(SeedButtons:GetChildren()) do
	if button:IsA("TextButton") then
		button.MouseButton1Click:Connect(function()
			selectedSeed = button.Name
			-- Update UI to reflect selection
			for _, btn in pairs(SeedButtons:GetChildren()) do
				if btn:IsA("TextButton") then
					btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				end
			end
			button.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		end)
	end
end

-- Expose selectedSeed for other scripts
return {
	GetSelectedSeed = function()
		return selectedSeed
	end
}
