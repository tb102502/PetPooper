-- NotificationManager.lua
-- Handles displaying notifications to the player
-- Place in StarterGui/MainGui/GuiModules/Utility/

local NotificationManager = {}

-- Services
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- Variables
local mainGui
local notificationQueue = {}
local isShowingNotification = false

-- Initialize the notification manager
function NotificationManager.Initialize(gui)
	mainGui = gui

	-- Remove any existing notification frames
	local existingNotification = mainGui:FindFirstChild("NotificationFrame")
	if existingNotification then
		existingNotification:Destroy()
	end

	print("NotificationManager initialized")
end

-- Function to create and display a notification
function NotificationManager.ShowNotification(title, message, iconType)
	-- Add to queue
	table.insert(notificationQueue, {
		title = title or "Notification",
		message = message or "",
		iconType = iconType
	})

	-- Start processing the queue if not already
	if not isShowingNotification then
		ProcessNotificationQueue()
	end
end

-- Private function to process the notification queue
function ProcessNotificationQueue()
	if #notificationQueue == 0 then
		isShowingNotification = false
		return
	end

	isShowingNotification = true

	-- Get the next notification
	local notification = table.remove(notificationQueue, 1)
	DisplayNotification(notification.title, notification.message, notification.iconType)
end

-- Private function to create and display the notification UI
function DisplayNotification(title, message, iconType)
	-- Remove any existing notification
	local existingNotification = mainGui:FindFirstChild("NotificationFrame")
	if existingNotification then
		existingNotification:Destroy()
	end

	-- Create notification frame
	local notificationFrame = Instance.new("Frame")
	notificationFrame.Name = "NotificationFrame"
	notificationFrame.Size = UDim2.new(0, 300, 0, 100)
	notificationFrame.Position = UDim2.new(0.5, -150, 0, -110) -- Start off-screen
	notificationFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	notificationFrame.BorderSizePixel = 0
	notificationFrame.Parent = mainGui

	-- Add rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = notificationFrame

	-- Add background shadow
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.new(1, 30, 1, 30)
	shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://1316045217" -- Shadow image
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 0.6
	shadow.ZIndex = 0
	shadow.Parent = notificationFrame

	-- Create title label
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(0.7, 0, 0, 30)
	titleLabel.Position = UDim2.new(0.15, 0, 0, 10)
	titleLabel.Text = title
	titleLabel.TextSize = 18
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Parent = notificationFrame

	-- Create message label
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "MessageLabel"
	messageLabel.Size = UDim2.new(0.9, 0, 0, 40)
	messageLabel.Position = UDim2.new(0.05, 0, 0, 50)
	messageLabel.Text = message
	messageLabel.TextSize = 16
	messageLabel.Font = Enum.Font.Gotham
	messageLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
	messageLabel.TextWrapped = true
	messageLabel.BackgroundTransparency = 1
	messageLabel.Parent = notificationFrame

	-- Create icon (if type is provided)
	if iconType then
		local iconImage = ""
		local iconColor = Color3.fromRGB(255, 255, 255)

		if iconType == "sell" then
			iconImage = "rbxassetid://6026568198" -- Money icon
			iconColor = Color3.fromRGB(255, 215, 0) -- Gold
			notificationFrame.BackgroundColor3 = Color3.fromRGB(40, 80, 40) -- Green bg
		elseif iconType == "error" then
			iconImage = "rbxassetid://6031071053" -- Warning icon
			iconColor = Color3.fromRGB(255, 80, 80) -- Red
			notificationFrame.BackgroundColor3 = Color3.fromRGB(80, 40, 40) -- Red bg
		elseif iconType == "info" then
			iconImage = "rbxassetid://6026568245" -- Info icon
			iconColor = Color3.fromRGB(80, 170, 255) -- Blue
			notificationFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 80) -- Blue bg
		elseif iconType == "success" then
			iconImage = "rbxassetid://6023426923" -- Checkmark icon
			iconColor = Color3.fromRGB(80, 255, 80) -- Green
			notificationFrame.BackgroundColor3 = Color3.fromRGB(40, 80, 40) -- Green bg
		end

		if iconImage ~= "" then
			local iconLabel = Instance.new("ImageLabel")
			iconLabel.Name = "IconLabel"
			iconLabel.Size = UDim2.new(0, 30, 0, 30)
			iconLabel.Position = UDim2.new(0, 10, 0, 10)
			iconLabel.BackgroundTransparency = 1
			iconLabel.Image = iconImage
			iconLabel.ImageColor3 = iconColor
			iconLabel.Parent = notificationFrame

			-- Adjust title position
			titleLabel.Position = UDim2.new(0.15, 20, 0, 10)
		end
	end

	-- Animate notification sliding in
	local slideInTween = TweenService:Create(
		notificationFrame,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, -150, 0, 10)}
	)

	slideInTween:Play()

	-- Auto-remove after 4 seconds
	spawn(function()
		wait(4)

		if notificationFrame and notificationFrame.Parent then
			-- Animate sliding out
			local slideOutTween = TweenService:Create(
				notificationFrame,
				TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In),
				{Position = UDim2.new(0.5, -150, 0, -110)}
			)

			slideOutTween:Play()

			slideOutTween.Completed:Connect(function()
				if notificationFrame and notificationFrame.Parent then
					notificationFrame:Destroy()
				end

				-- Process next notification if any
				ProcessNotificationQueue()
			end)
		else
			-- If notification was already removed, process next
			ProcessNotificationQueue()
		end
	end)
end

return NotificationManager