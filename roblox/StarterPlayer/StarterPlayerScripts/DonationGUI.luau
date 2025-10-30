local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Load TopbarPlus
local Icon = require(ReplicatedStorage:WaitForChild("Icon"))

-- Wait for new donation system
local newDonationSystem = ReplicatedStorage:WaitForChild("NewDonationSystem")
local purchaseNewDonation = newDonationSystem:WaitForChild("PurchaseNewDonation")

-- Donation products (matching server)
local DONATION_PRODUCTS = {
	{productId = 3438213239, amount = 100},
	{productId = 3438213399, amount = 200},
	{productId = 3438213537, amount = 500},
	{productId = 3438213683, amount = 1000},
	{productId = 3438213834, amount = 2000},
	{productId = 3438213970, amount = 5000},
	{productId = 3438214109, amount = 10000},
}
-- Helper function to format numbers with commas
local function formatNumber(num)
	local formatted = tostring(num)
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then break end
	end
	return formatted
end

-- Function to get total donations from DataStore
local function getTotalDonations()
	local isStudio = RunService:IsStudio()

	local donationBoard = ReplicatedStorage:FindFirstChild("DonationBoardData")
	if not donationBoard then
		warn("[DONATION GUI] DonationBoardData not found in ReplicatedStorage")
		return 0, 0
	end

	local donations = donationBoard:FindFirstChild("Donations")
	if not donations then
		warn("[DONATION GUI] Donations folder not found")
		return 0, 0
	end

	local playerData = donations:FindFirstChild(tostring(player.UserId))
	if not playerData then
		print("[DONATION GUI] No player data found for UserId:", player.UserId)
		return 0, 0
	end

	local dailyDonate = 0
	local totalDonate = 0

	-- Get donation values
	local donatedExp = playerData:FindFirstChild("Donated - Experience")
	local expAmount = donatedExp and donatedExp.Value or 0

	local donatedStudio = playerData:FindFirstChild("Donated - Studio")
	local studioAmount = donatedStudio and donatedStudio.Value or 0

	if isStudio then
		-- ✅ Studio mode:
		-- Daily = Studio donations (donations made in Studio today)
		-- Total = Studio + Experience (all donations ever made)
		dailyDonate = studioAmount
		totalDonate = studioAmount + expAmount

		print("[DONATION GUI] Studio Mode:")
		print("  - Daily (Studio): ", dailyDonate)
		print("  - Total (Studio + Exp): ", totalDonate)
	else
		-- ✅ Experience mode:
		-- Daily = Experience donations (donations made in Experience today)
		-- Total = Experience donations (same as daily for Experience)
		dailyDonate = expAmount
		totalDonate = expAmount

		print("[DONATION GUI] Experience Mode:")
		print("  - Daily (Experience): ", dailyDonate)
		print("  - Total (Experience): ", totalDonate)
	end

	print(`[DONATION GUI] Final values - Daily: {dailyDonate}, Total: {totalDonate}`)

	return dailyDonate, totalDonate
end

-- Function to set player avatar
local function setAvatar(imageLabel, userId)
	local success, thumbnailUrl = pcall(function()
		return Players:GetUserThumbnailAsync(
			userId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size150x150
		)
	end)

	if success and thumbnailUrl then
		imageLabel.Image = thumbnailUrl
	else
		imageLabel.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	end
end

-- Create the main GUI
local function createDonationGUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "NewDonationGUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	-- Main container (centered, hidden by default)
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.Size = UDim2.new(0, 700, 0, 500)
	mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	mainFrame.BackgroundTransparency = 0.1
	mainFrame.BorderSizePixel = 0
	mainFrame.Visible = false
	mainFrame.Parent = gui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 16)
	mainCorner.Parent = mainFrame

	local mainStroke = Instance.new("UIStroke")
	mainStroke.Color = Color3.fromRGB(100, 100, 120)
	mainStroke.Thickness = 2
	mainStroke.Transparency = 0.3
	mainStroke.Parent = mainFrame

	-- Left side: Donation buttons (60% width) - WITH SCROLLING
	local leftPanel = Instance.new("ScrollingFrame")
	leftPanel.Name = "LeftPanel"
	leftPanel.Size = UDim2.new(0.58, 0, 1, 0)
	leftPanel.Position = UDim2.new(0, 0, 0, 0)
	leftPanel.BackgroundTransparency = 1
	leftPanel.BorderSizePixel = 0
	leftPanel.ScrollBarThickness = 6
	leftPanel.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 150)
	leftPanel.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will auto-size
	leftPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
	leftPanel.Parent = mainFrame

	local leftPadding = Instance.new("UIPadding")
	leftPadding.PaddingTop = UDim.new(0, 20)
	leftPadding.PaddingBottom = UDim.new(0, 20)
	leftPadding.PaddingLeft = UDim.new(0, 20)
	leftPadding.PaddingRight = UDim.new(0, 10)
	leftPadding.Parent = leftPanel

	local leftList = Instance.new("UIListLayout")
	leftList.Padding = UDim.new(0, 10)
	leftList.SortOrder = Enum.SortOrder.LayoutOrder
	leftList.Parent = leftPanel

	-- Create donation buttons (show ALL 8 options, scrollable)
	for i = 1, #DONATION_PRODUCTS do
		local product = DONATION_PRODUCTS[i]

		local button = Instance.new("TextButton")
		button.Name = "DonateButton_" .. product.amount
		button.Size = UDim2.new(1, 0, 0, 100)
		button.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
		button.BackgroundTransparency = 0.2
		button.BorderSizePixel = 0
		button.AutoButtonColor = false
		button.LayoutOrder = i
		button.Parent = leftPanel

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 12)
		btnCorner.Parent = button

		local btnStroke = Instance.new("UIStroke")
		btnStroke.Color = Color3.fromRGB(80, 80, 100)
		btnStroke.Thickness = 1
		btnStroke.Transparency = 0.5
		btnStroke.Parent = button

		-- Button content frame
		local content = Instance.new("Frame")
		content.BackgroundTransparency = 1
		content.Size = UDim2.new(1, -30, 1, -20)
		content.Position = UDim2.new(0, 15, 0, 10)
		content.Parent = button

		-- "Donate" label (top)
		local donateLabel = Instance.new("TextLabel")
		donateLabel.Size = UDim2.new(1, 0, 0.35, 0)
		donateLabel.Position = UDim2.new(0, 0, 0, 0)
		donateLabel.BackgroundTransparency = 1
		donateLabel.Text = "Donate"
		donateLabel.Font = Enum.Font.GothamBold
		donateLabel.TextSize = 18
		donateLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
		donateLabel.TextXAlignment = Enum.TextXAlignment.Left
		donateLabel.TextYAlignment = Enum.TextYAlignment.Top
		donateLabel.Parent = content

		-- Amount (left bottom)
		local amountLabel = Instance.new("TextLabel")
		amountLabel.Size = UDim2.new(0.6, 0, 0.55, 0)
		amountLabel.Position = UDim2.new(0, 0, 0.45, 0)
		amountLabel.BackgroundTransparency = 1
		amountLabel.Text = tostring(product.amount)
		amountLabel.Font = Enum.Font.GothamBold
		amountLabel.TextSize = 42
		amountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		amountLabel.TextXAlignment = Enum.TextXAlignment.Left
		amountLabel.TextYAlignment = Enum.TextYAlignment.Center
		amountLabel.Parent = content

		-- "Buy" button (right bottom)
		local buyLabel = Instance.new("TextLabel")
		buyLabel.Size = UDim2.new(0.35, 0, 0.55, 0)
		buyLabel.Position = UDim2.new(0.65, 0, 0.45, 0)
		buyLabel.BackgroundTransparency = 1
		buyLabel.Text = "Buy"
		buyLabel.Font = Enum.Font.GothamBold
		buyLabel.TextSize = 24
		buyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyLabel.TextXAlignment = Enum.TextXAlignment.Right
		buyLabel.TextYAlignment = Enum.TextYAlignment.Center
		buyLabel.Parent = content

		-- Hover effects
		button.MouseEnter:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.15), {
				BackgroundTransparency = 0.05,
				BackgroundColor3 = Color3.fromRGB(45, 45, 65)
			}):Play()
			TweenService:Create(btnStroke, TweenInfo.new(0.15), {
				Color = Color3.fromRGB(120, 120, 180),
				Transparency = 0.2
			}):Play()
		end)

		button.MouseLeave:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.15), {
				BackgroundTransparency = 0.2,
				BackgroundColor3 = Color3.fromRGB(35, 35, 50)
			}):Play()
			TweenService:Create(btnStroke, TweenInfo.new(0.15), {
				Color = Color3.fromRGB(80, 80, 100),
				Transparency = 0.5
			}):Play()
		end)

		-- Click handler
		button.MouseButton1Click:Connect(function()
			local messageFrame = gui:FindFirstChild("MessageInputFrame")
			if messageFrame then
				messageFrame.Visible = true
				messageFrame:SetAttribute("CurrentProductId", product.productId)
				messageFrame:SetAttribute("CurrentAmount", product.amount)
				local messageBox = messageFrame:FindFirstChild("MessageBox")
				if messageBox then
					messageBox.Text = ""
					messageBox:CaptureFocus()
				end
			end
		end)
	end

	-- Right side: Player info (40% width)
	local rightPanel = Instance.new("Frame")
	rightPanel.Name = "RightPanel"
	rightPanel.Size = UDim2.new(0.42, 0, 1, 0)
	rightPanel.Position = UDim2.new(0.58, 0, 0, 0)
	rightPanel.BackgroundTransparency = 1
	rightPanel.Parent = mainFrame

	local rightPadding = Instance.new("UIPadding")
	rightPadding.PaddingTop = UDim.new(0, 20)
	rightPadding.PaddingBottom = UDim.new(0, 20)
	rightPadding.PaddingLeft = UDim.new(0, 10)
	rightPadding.PaddingRight = UDim.new(0, 20)
	rightPadding.Parent = rightPanel

	-- Avatar container
	local avatarFrame = Instance.new("Frame")
	avatarFrame.Name = "AvatarFrame"
	avatarFrame.Size = UDim2.new(1, 0, 0, 140)
	avatarFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	avatarFrame.BackgroundTransparency = 0.3
	avatarFrame.BorderSizePixel = 0
	avatarFrame.Parent = rightPanel

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(0, 12)
	avatarCorner.Parent = avatarFrame

	-- Avatar image
	local avatarImage = Instance.new("ImageLabel")
	avatarImage.Name = "Avatar"
	avatarImage.AnchorPoint = Vector2.new(0.5, 0.5)
	avatarImage.Position = UDim2.new(0.5, 0, 0.5, 0)
	avatarImage.Size = UDim2.new(0, 110, 0, 110)
	avatarImage.BackgroundTransparency = 1
	avatarImage.Parent = avatarFrame

	local avatarImgCorner = Instance.new("UICorner")
	avatarImgCorner.CornerRadius = UDim.new(1, 0)
	avatarImgCorner.Parent = avatarImage

	-- Set player avatar
	setAvatar(avatarImage, player.UserId)

	-- Player info container
	local infoFrame = Instance.new("Frame")
	infoFrame.Name = "InfoFrame"
	infoFrame.Size = UDim2.new(1, 0, 1, -160)
	infoFrame.Position = UDim2.new(0, 0, 0, 160)
	infoFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	infoFrame.BackgroundTransparency = 0.3
	infoFrame.BorderSizePixel = 0
	infoFrame.Parent = rightPanel

	local infoCorner = Instance.new("UICorner")
	infoCorner.CornerRadius = UDim.new(0, 12)
	infoCorner.Parent = infoFrame

	local infoPadding = Instance.new("UIPadding")
	infoPadding.PaddingTop = UDim.new(0, 15)
	infoPadding.PaddingBottom = UDim.new(0, 15)
	infoPadding.PaddingLeft = UDim.new(0, 15)
	infoPadding.PaddingRight = UDim.new(0, 15)
	infoPadding.Parent = infoFrame

	-- Display name
	local displayName = Instance.new("TextLabel")
	displayName.Size = UDim2.new(1, 0, 0, 28)
	displayName.Position = UDim2.new(0, 0, 0, 0)
	displayName.BackgroundTransparency = 1
	displayName.Text = player.DisplayName
	displayName.Font = Enum.Font.GothamBold
	displayName.TextSize = 22
	displayName.TextColor3 = Color3.fromRGB(255, 255, 255)
	displayName.TextXAlignment = Enum.TextXAlignment.Center
	displayName.TextTruncate = Enum.TextTruncate.AtEnd
	displayName.Parent = infoFrame

	-- Username
	local username = Instance.new("TextLabel")
	username.Size = UDim2.new(1, 0, 0, 22)
	username.Position = UDim2.new(0, 0, 0, 28)
	username.BackgroundTransparency = 1
	username.Text = "@" .. player.Name
	username.Font = Enum.Font.Gotham
	username.TextSize = 16
	username.TextColor3 = Color3.fromRGB(180, 180, 200)
	username.TextXAlignment = Enum.TextXAlignment.Center
	username.Parent = infoFrame

	-- Divider line
	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.Position = UDim2.new(0, 0, 0, 60)
	divider.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
	divider.BackgroundTransparency = 0.5
	divider.BorderSizePixel = 0
	divider.Parent = infoFrame

	-- Daily donate section
	local dailyTitle = Instance.new("TextLabel")
	dailyTitle.Size = UDim2.new(1, 0, 0, 20)
	dailyTitle.Position = UDim2.new(0, 0, 0, 75)
	dailyTitle.BackgroundTransparency = 1
	dailyTitle.Text = "DailyDonate"
	dailyTitle.Font = Enum.Font.Gotham
	dailyTitle.TextSize = 14
	dailyTitle.TextColor3 = Color3.fromRGB(150, 150, 170)
	dailyTitle.TextXAlignment = Enum.TextXAlignment.Center
	dailyTitle.Parent = infoFrame

	local dailyAmount = Instance.new("TextLabel")
	dailyAmount.Name = "DailyAmount"
	dailyAmount.Size = UDim2.new(1, 0, 0, 32)
	dailyAmount.Position = UDim2.new(0, 0, 0, 95)
	dailyAmount.BackgroundTransparency = 1
	dailyAmount.Text = "0"
	dailyAmount.Font = Enum.Font.GothamBold
	dailyAmount.TextSize = 26
	dailyAmount.TextColor3 = Color3.fromRGB(100, 200, 255)
	dailyAmount.TextXAlignment = Enum.TextXAlignment.Center
	dailyAmount.Parent = infoFrame

	-- Divider line 2
	local divider2 = Instance.new("Frame")
	divider2.Size = UDim2.new(1, 0, 0, 1)
	divider2.Position = UDim2.new(0, 0, 0, 145)
	divider2.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
	divider2.BackgroundTransparency = 0.5
	divider2.BorderSizePixel = 0
	divider2.Parent = infoFrame

	-- Total donate section
	local totalTitle = Instance.new("TextLabel")
	totalTitle.Size = UDim2.new(1, 0, 0, 20)
	totalTitle.Position = UDim2.new(0, 0, 0, 160)
	totalTitle.BackgroundTransparency = 1
	totalTitle.Text = "TotalDonate"
	totalTitle.Font = Enum.Font.Gotham
	totalTitle.TextSize = 14
	totalTitle.TextColor3 = Color3.fromRGB(150, 150, 170)
	totalTitle.TextXAlignment = Enum.TextXAlignment.Center
	totalTitle.Parent = infoFrame

	local totalAmount = Instance.new("TextLabel")
	totalAmount.Name = "TotalAmount"
	totalAmount.Size = UDim2.new(1, 0, 0, 32)
	totalAmount.Position = UDim2.new(0, 0, 0, 180)
	totalAmount.BackgroundTransparency = 1
	totalAmount.Text = "0"
	totalAmount.Font = Enum.Font.GothamBold
	totalAmount.TextSize = 26
	totalAmount.TextColor3 = Color3.fromRGB(255, 180, 100)
	totalAmount.TextXAlignment = Enum.TextXAlignment.Center
	totalAmount.Parent = infoFrame

	-- Function to update donation totals
	local function updateDonationTotals()
		local daily, total = getTotalDonations()
		dailyAmount.Text = formatNumber(daily)
		totalAmount.Text = formatNumber(total)
	end

	-- Initial update and periodic updates
	task.wait(1)
	updateDonationTotals()

	spawn(function()
		while gui.Parent do
			task.wait(5)
			updateDonationTotals()
		end
	end)

	-- Create custom message input frame
	local messageInputFrame = Instance.new("Frame")
	messageInputFrame.Name = "MessageInputFrame"
	messageInputFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	messageInputFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	messageInputFrame.Size = UDim2.new(0, 500, 0, 300)
	messageInputFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	messageInputFrame.BorderSizePixel = 0
	messageInputFrame.Visible = false
	messageInputFrame.ZIndex = 10
	messageInputFrame.Parent = gui

	local msgCorner = Instance.new("UICorner")
	msgCorner.CornerRadius = UDim.new(0, 16)
	msgCorner.Parent = messageInputFrame

	local msgStroke = Instance.new("UIStroke")
	msgStroke.Color = Color3.fromRGB(150, 150, 200)
	msgStroke.Thickness = 2
	msgStroke.Parent = messageInputFrame

	local msgPadding = Instance.new("UIPadding")
	msgPadding.PaddingTop = UDim.new(0, 20)
	msgPadding.PaddingBottom = UDim.new(0, 20)
	msgPadding.PaddingLeft = UDim.new(0, 20)
	msgPadding.PaddingRight = UDim.new(0, 20)
	msgPadding.Parent = messageInputFrame

	-- Title
	local msgTitle = Instance.new("TextLabel")
	msgTitle.Size = UDim2.new(1, 0, 0, 40)
	msgTitle.BackgroundTransparency = 1
	msgTitle.Text = "Add Custom Message (Optional)"
	msgTitle.Font = Enum.Font.GothamBold
	msgTitle.TextSize = 20
	msgTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	msgTitle.TextXAlignment = Enum.TextXAlignment.Left
	msgTitle.Parent = messageInputFrame

	-- Message box
	local messageBox = Instance.new("TextBox")
	messageBox.Name = "MessageBox"
	messageBox.Position = UDim2.new(0, 0, 0, 50)
	messageBox.Size = UDim2.new(1, 0, 0, 120)
	messageBox.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	messageBox.BorderSizePixel = 0
	messageBox.Font = Enum.Font.Gotham
	messageBox.TextSize = 16
	messageBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	messageBox.PlaceholderText = "Enter your message here... (max 200 characters)"
	messageBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
	messageBox.Text = ""
	messageBox.ClearTextOnFocus = false
	messageBox.MultiLine = true
	messageBox.TextWrapped = true
	messageBox.TextXAlignment = Enum.TextXAlignment.Left
	messageBox.TextYAlignment = Enum.TextYAlignment.Top
	messageBox.Parent = messageInputFrame

	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 8)
	boxCorner.Parent = messageBox

	local boxPadding = Instance.new("UIPadding")
	boxPadding.PaddingTop = UDim.new(0, 10)
	boxPadding.PaddingBottom = UDim.new(0, 10)
	boxPadding.PaddingLeft = UDim.new(0, 10)
	boxPadding.PaddingRight = UDim.new(0, 10)
	boxPadding.Parent = messageBox

	-- Character counter
	local charCounter = Instance.new("TextLabel")
	charCounter.Name = "CharCounter"
	charCounter.Position = UDim2.new(0, 0, 0, 175)
	charCounter.Size = UDim2.new(1, 0, 0, 20)
	charCounter.BackgroundTransparency = 1
	charCounter.Text = "0 / 200"
	charCounter.Font = Enum.Font.Gotham
	charCounter.TextSize = 14
	charCounter.TextColor3 = Color3.fromRGB(150, 150, 150)
	charCounter.TextXAlignment = Enum.TextXAlignment.Right
	charCounter.Parent = messageInputFrame

	messageBox:GetPropertyChangedSignal("Text"):Connect(function()
		local text = messageBox.Text
		if #text > 200 then
			messageBox.Text = string.sub(text, 1, 200)
		end
		charCounter.Text = `{#messageBox.Text} / 200`
	end)

	-- Button container
	local buttonContainer = Instance.new("Frame")
	buttonContainer.Position = UDim2.new(0, 0, 0, 205)
	buttonContainer.Size = UDim2.new(1, 0, 0, 50)
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.Parent = messageInputFrame

	-- Cancel button
	local cancelButton = Instance.new("TextButton")
	cancelButton.Size = UDim2.new(0.48, 0, 1, 0)
	cancelButton.Position = UDim2.new(0, 0, 0, 0)
	cancelButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	cancelButton.BorderSizePixel = 0
	cancelButton.Font = Enum.Font.GothamBold
	cancelButton.TextSize = 18
	cancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	cancelButton.Text = "Cancel"
	cancelButton.Parent = buttonContainer

	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 10)
	cancelCorner.Parent = cancelButton

	-- Confirm button
	local confirmButton = Instance.new("TextButton")
	confirmButton.Size = UDim2.new(0.48, 0, 1, 0)
	confirmButton.Position = UDim2.new(0.52, 0, 0, 0)
	confirmButton.BackgroundColor3 = Color3.fromRGB(80, 150, 255)
	confirmButton.BorderSizePixel = 0
	confirmButton.Font = Enum.Font.GothamBold
	confirmButton.TextSize = 18
	confirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	confirmButton.Text = "Donate"
	confirmButton.Parent = buttonContainer

	local confirmCorner = Instance.new("UICorner")
	confirmCorner.CornerRadius = UDim.new(0, 10)
	confirmCorner.Parent = confirmButton

	-- Button handlers
	cancelButton.MouseButton1Click:Connect(function()
		messageInputFrame.Visible = false
		messageBox.Text = ""
	end)

	confirmButton.MouseButton1Click:Connect(function()
		local productId = messageInputFrame:GetAttribute("CurrentProductId")
		local amount = messageInputFrame:GetAttribute("CurrentAmount")
		local customMessage = messageBox.Text

		if productId then
			print(`[DONATION GUI] Purchasing {amount} Robux donation with message: "{customMessage}"`)
			purchaseNewDonation:FireServer(productId, customMessage)
			messageInputFrame.Visible = false
			messageBox.Text = ""
		end
	end)

	return mainFrame
end

-- Create TopbarPlus icon
local function createTopbarIcon()
	-- Wait for Icon module to fully load
	task.wait(0.5)

	-- Create the GUI first
	local mainFrame = createDonationGUI()

	-- Create TopbarPlus icon
	local donationIcon = Icon.new()
		:setLabel("Donate")
		:setImage("rbxassetid://3926305904") -- Money bag icon (you can change this)
		:setOrder(1)

	-- Toggle functionality
	donationIcon:bindEvent("selected", function()
		mainFrame.Visible = true
	end)

	donationIcon:bindEvent("deselected", function()
		mainFrame.Visible = false
	end)

	-- Also allow closing from clicking outside (optional)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end  -- Ignore if clicking UI
		
		if input.UserInputType == Enum.UserInputType.MouseButton1 and mainFrame.Visible then
			local mousePos = UserInputService:GetMouseLocation()
			local framePos = mainFrame.AbsolutePosition
			local frameSize = mainFrame.AbsoluteSize

			-- Check if click is outside the frame
			if mousePos.X < framePos.X or mousePos.X > framePos.X + frameSize.X or
				mousePos.Y < framePos.Y or mousePos.Y > framePos.Y + frameSize.Y then
				mainFrame.Visible = false
				donationIcon:deselect()
			end
		end
	end)

	print("[DONATION GUI] TopbarPlus icon created! Click 'Donate' in topbar to open.")
end

-- Initialize
task.wait(1)
createTopbarIcon()

print("[DONATION GUI] Loaded successfully with TopbarPlus!")