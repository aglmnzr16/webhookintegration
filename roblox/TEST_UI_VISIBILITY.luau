-- TEST_UI_VISIBILITY.luau
-- Script untuk test apakah UI bisa menampilkan elements
-- Letakkan di StarterPlayerScripts untuk testing

local Players = game:GetService("Players")
local player = Players.LocalPlayer

task.wait(3) -- Wait for UI to load

print("=== TESTING UI VISIBILITY ===")

-- Test SaweriaBoard di Workspace
local saweriaBoard = workspace:WaitForChild("SaweriaBoard", 5)
if not saweriaBoard then
	warn("❌ SaweriaBoard not found in workspace!")
	return
end

print("✅ Found SaweriaBoard in workspace")

-- Test Top Board
local topBoard = saweriaBoard:WaitForChild("SaweriaBoard", 5)
if not topBoard then
	warn("❌ SaweriaBoard Frame not found!")
	return
end

local board = topBoard:WaitForChild("Board")
local container = board:WaitForChild("Container")
local canvas = container:WaitForChild("Canvas")
local body = canvas:WaitForChild("Body")
local content = body:WaitForChild("Content")

print("✅ Found content:", content:GetFullName())
print("  - ClassName:", content.ClassName)
print("  - Size:", content.Size)
print("  - Position:", content.Position)
print("  - Visible:", content.Visible)
print("  - AbsoluteSize:", content.AbsoluteSize)

-- Create test entry
print("\n📝 Creating test entry...")

local testEntry = Instance.new("Frame")
testEntry.Name = "TestEntry"
testEntry.Size = UDim2.new(1, 0, 0, 70)
testEntry.Position = UDim2.new(0, 0, 0, 0)
testEntry.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Bright red
testEntry.BorderSizePixel = 2
testEntry.BorderColor3 = Color3.fromRGB(0, 255, 0) -- Green border
testEntry.Parent = content

print("✅ Test entry created!")
print("  - Entry Name:", testEntry.Name)
print("  - Entry Size:", testEntry.Size)
print("  - Entry Position:", testEntry.Position)
print("  - Entry Visible:", testEntry.Visible)
print("  - Entry Parent:", testEntry.Parent:GetFullName())

-- Add text label to make it obvious
local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1
label.Text = "TEST ENTRY - If you see this, UI works!"
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextSize = 20
label.Font = Enum.Font.GothamBold
label.Parent = testEntry

print("✅ Test label added")

-- Check if entry is in content children
task.wait(1)
local found = false
for _, child in ipairs(content:GetChildren()) do
	print("  - Child:", child.Name, "| ClassName:", child.ClassName)
	if child == testEntry then
		found = true
	end
end

if found then
	print("✅ Test entry found in content children")
else
	warn("❌ Test entry NOT found in content children!")
end

print("\n=== TEST COMPLETED ===")
print("Check the SurfaceGui in workspace - you should see a RED frame with green border and white text")
