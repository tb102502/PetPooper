local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

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
	print("StatsDisplaySystem: Connected to GameClient successfully")
	-- Your stats display code here
else
	print("StatsDisplaySystem: GameClient not available - creating minimal fallback")

	-- Create basic stats display without GameClient dependency
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	local statsGui = Instance.new("ScreenGui")
	statsGui.Name = "StatsDisplay"
	statsGui.Parent = playerGui

	local statsFrame = Instance.new("Frame")
	statsFrame.Size = UDim2.new(0, 200, 0, 100)
	statsFrame.Position = UDim2.new(0, 10, 0, 10)
	statsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	statsFrame.BackgroundTransparency = 0.3
	statsFrame.Parent = statsGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.1, 0)
	corner.Parent = statsFrame

	local statsLabel = Instance.new("TextLabel")
	statsLabel.Size = UDim2.new(1, 0, 1, 0)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Text = "Stats: Loading..."
	statsLabel.TextColor3 = Color3.new(1, 1, 1)
	statsLabel.TextScaled = true
	statsLabel.Font = Enum.Font.Gotham
	statsLabel.Parent = statsFrame

	print("StatsDisplaySystem: Minimal fallback display created")
end
