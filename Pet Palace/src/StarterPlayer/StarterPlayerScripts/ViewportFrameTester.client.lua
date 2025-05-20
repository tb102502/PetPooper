-- ViewportFrame Tester
-- ViewportFrame Tester
-- Place this in StarterPlayerScripts to test if the ViewportFrame is working
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Wait for player GUI to load
local playerGui = player:WaitForChild("PlayerGui")
local shopGui = playerGui:WaitForChild("ShopGui", 10)
local mainGui = playerGui:WaitForChild("MainGui", 10)


local topBarGui = playerGui:WaitForChild("TopBarGui", 5)
local topBarFrame = topBarGui:WaitForChild("TopBarFrame", 5)
local inventoryGui = playerGui:WaitForChild("InventoryGui", 10)
local inventoryFrame = inventoryGui:WaitForChild("InventoryFrame", 5)
if not inventoryFrame then
	warn("InventoryFrame not found!")
	return
end

-- Create a test ViewportFrame
local testContainer = Instance.new("Frame")
testContainer.Name = "ViewportTester"
testContainer.Size = UDim2.new(0, 200, 0, 200)
testContainer.Position = UDim2.new(0.5, -100, 0.5, -100)
testContainer.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
testContainer.BorderSizePixel = 2
testContainer.Parent = inventoryFrame

-- Create title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.Text = "ViewportFrame Test"
titleLabel.Parent = testContainer

-- Create ViewportFrame
local viewport = Instance.new("ViewportFrame")
viewport.Name = "TestViewport"
viewport.Size = UDim2.new(0, 150, 0, 150)
viewport.Position = UDim2.new(0.5, -75, 0.5, -60)
viewport.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
viewport.BorderSizePixel = 0
viewport.Parent = testContainer

-- Create camera
local camera = Instance.new("Camera")
camera.CFrame = CFrame.new(Vector3.new(0, 0, 5), Vector3.new(0, 0, 0))
camera.Parent = viewport
viewport.CurrentCamera = camera

-- Create WorldModel
local worldModel = Instance.new("WorldModel")
worldModel.Parent = viewport

-- Create a simple model
local model = Instance.new("Model")
model.Name = "TestPet"
model.Parent = worldModel

-- Create body part
local body = Instance.new("Part")
body.Shape = Enum.PartType.Ball
body.Size = Vector3.new(2, 2, 2)
body.Position = Vector3.new(0, 0, 0)
body.Color = Color3.fromRGB(255, 100, 100)
body.Anchored = true
body.CanCollide = false
body.Parent = model
model.PrimaryPart = body

-- Create eyes
local eye1 = Instance.new("Part")
eye1.Shape = Enum.PartType.Ball
eye1.Size = Vector3.new(0.4, 0.4, 0.4)
eye1.Position = Vector3.new(-0.5, 0.3, -0.8)
eye1.Color = Color3.fromRGB(0, 0, 0)
eye1.Anchored = true
eye1.CanCollide = false
eye1.Parent = model

local eye2 = Instance.new("Part")
eye2.Shape = Enum.PartType.Ball
eye2.Size = Vector3.new(0.4, 0.4, 0.4)
eye2.Position = Vector3.new(0.5, 0.3, -0.8)
eye2.Color = Color3.fromRGB(0, 0, 0)
eye2.Anchored = true
eye2.CanCollide = false
eye2.Parent = model

-- Add rotation with RenderStepped directly
-- This avoids the LocalScript Source issue
local angle = 0
-- Define the connection variable first
local connection
-- Then create the connection in a way that avoids the race condition
connection = RunService.RenderStepped:Connect(function(dt)
	-- Check if model exists and is parented
	if not model or not model.Parent then
		-- Always check if connection exists before disconnecting
		if connection then
			connection:Disconnect()
			connection = nil
		end
		return
	end

	angle = angle + dt * 1  -- Rotate based on delta time
	if model.PrimaryPart then
		model:SetPrimaryPartCFrame(CFrame.new(model.PrimaryPart.Position) * CFrame.Angles(0, angle, 0))
	end
end)

-- For a more robust solution, use this alternative approach that avoids the connection issue entirely:
local function RotatePetModel(model, speed)
	if not model or not model.Parent then return end

	-- Store rotation information on the model itself
	local rotationInfo = Instance.new("NumberValue")
	rotationInfo.Name = "RotationStartTime"
	rotationInfo.Value = tick()
	rotationInfo.Parent = model

	-- Store rotation speed
	local speedValue = Instance.new("NumberValue")
	speedValue.Name = "RotationSpeed"
	speedValue.Value = speed or 20
	speedValue.Parent = model

	-- Create a LocalScript to handle rotation
	local rotationScript = Instance.new("LocalScript")
	rotationScript.Name = "RotationController"

	-- The LocalScript's content (avoiding the Source property issue)
	-- This script will use its own RunService connection
	rotationScript.Parent = model

	-- Create a ModuleScript for the actual rotation logic
	local moduleScript = Instance.new("ModuleScript")
	moduleScript.Name = "RotationModule"
	moduleScript.Source = [[
        local RunService = game:GetService("RunService")
        
        return function(model)
            local startTime = model:FindFirstChild("RotationStartTime")
            local speedValue = model:FindFirstChild("RotationSpeed")
            
            if not startTime or not speedValue then return end
            
            local connection
            connection = RunService.RenderStepped:Connect(function()
                if not model or not model.Parent or not model:FindFirstChild("RotationStartTime") then
                    if connection then
                        connection:Disconnect()
                    end
                    return
                end
                
                if model.PrimaryPart then
                    local angle = (tick() - startTime.Value) * math.rad(speedValue.Value)
                    local pos = model.PrimaryPart.Position
                    model:SetPrimaryPartCFrame(CFrame.new(pos) * CFrame.Angles(0, angle, 0))
                end
            end)
        end
    ]]
	moduleScript.Parent = rotationScript

	-- Use a BindableEvent to start the rotation safely
	local startEvent = Instance.new("BindableEvent")
	startEvent.Name = "StartRotation"
	startEvent.Event:Connect(function()
		-- Use require in a safer way
		local success, rotationFunc = pcall(function()
			return require(moduleScript)
		end)

		if success and rotationFunc then
			rotationFunc(model)
		end
	end)
	startEvent.Parent = rotationScript

	-- Fire the event to start rotation
	spawn(function()
		if startEvent and startEvent.Parent then
			startEvent:Fire()
		end
	end)
end