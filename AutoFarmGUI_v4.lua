local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local TERMS = {
	"treasure","treasurehunt","treasure hunt","hunt","dig","shovel",
	"water goddess","goddess","tier","reward","clam","found"
}

local gui = Instance.new("ScreenGui")
gui.Name = "TreasureMiniFinder"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(320, 230)
frame.Position = UDim2.fromOffset(80, 120)
frame.BackgroundColor3 = Color3.fromRGB(24, 27, 34)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 30)
top.BackgroundColor3 = Color3.fromRGB(36, 42, 52)
top.BorderSizePixel = 0
top.Active = true
top.Parent = frame

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(8, 0)
title.Size = UDim2.new(1, -42, 1, 0)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Treasure Finder"
title.Parent = top

local close = Instance.new("TextButton")
close.Position = UDim2.new(1, -28, 0, 4)
close.Size = UDim2.fromOffset(22, 22)
close.BackgroundColor3 = Color3.fromRGB(220, 70, 80)
close.Text = "X"
close.TextSize = 12
close.Font = Enum.Font.GothamBold
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.Parent = top
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 5)

local extraBox = Instance.new("TextBox")
extraBox.Position = UDim2.fromOffset(8, 38)
extraBox.Size = UDim2.new(1, -118, 0, 26)
extraBox.ClearTextOnFocus = false
extraBox.PlaceholderText = "extra words"
extraBox.Text = ""
extraBox.TextSize = 11
extraBox.Parent = frame

local scan = Instance.new("TextButton")
scan.Position = UDim2.new(1, -104, 0, 38)
scan.Size = UDim2.fromOffset(46, 26)
scan.Text = "Scan"
scan.TextSize = 11
scan.Parent = frame

local copy = Instance.new("TextButton")
copy.Position = UDim2.new(1, -54, 0, 38)
copy.Size = UDim2.fromOffset(46, 26)
copy.Text = "Copy"
copy.TextSize = 11
copy.Parent = frame

local output = Instance.new("TextBox")
output.Position = UDim2.fromOffset(8, 72)
output.Size = UDim2.new(1, -16, 1, -80)
output.MultiLine = true
output.ClearTextOnFocus = false
output.TextEditable = true
output.TextWrapped = false
output.TextXAlignment = Enum.TextXAlignment.Left
output.TextYAlignment = Enum.TextYAlignment.Top
output.Font = Enum.Font.Code
output.TextSize = 10
output.TextColor3 = Color3.fromRGB(235, 235, 235)
output.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
output.Text = "Press Scan."
output.Parent = frame

local dragging = false
local dragStart
local startPos

top.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

local function hasTerm(text, extra)
	text = string.lower(text or "")

	for _, term in ipairs(TERMS) do
		if text:find(term, 1, true) then
			return true, term
		end
	end

	for term in string.gmatch(extra or "", "[^,]+") do
		term = term:lower():gsub("^%s+", ""):gsub("%s+$", "")
		if term ~= "" and text:find(term, 1, true) then
			return true, term
		end
	end

	return false
end

local function scoreObject(obj, extra)
	local score = 0
	local hits = {}

	local okName, nameHit = hasTerm(obj.Name, extra)
	if okName then
		score += 8
		table.insert(hits, "name:" .. nameHit)
	end

	if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
		local okText, textHit = hasTerm(obj.Text, extra)
		if okText then
			score += 10
			table.insert(hits, "text:" .. textHit)
		end
	end

	if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
		score += 5
		table.insert(hits, obj.ClassName)
	end

	if obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
		score += 6
		table.insert(hits, "interaction")
	end

	if score <= 0 then return nil end

	return {
		score = score,
		className = obj.ClassName,
		path = obj:GetFullName(),
		hits = table.concat(hits, ", ")
	}
end

scan.MouseButton1Click:Connect(function()
	local results = {}
	local roots = {
		player:WaitForChild("PlayerGui"),
		ReplicatedStorage,
		Workspace,
	}

	for _, root in ipairs(roots) do
		for _, obj in ipairs(root:GetDescendants()) do
			local result = scoreObject(obj, extraBox.Text)
			if result then
				table.insert(results, result)
			end
		end
	end

	table.sort(results, function(a, b)
		return a.score > b.score
	end)

	local lines = {"Results:", ""}

	for i, r in ipairs(results) do
		if i > 25 then break end
		table.insert(lines, ("[%d] %d %s"):format(i, r.score, r.className))
		table.insert(lines, r.path)
		table.insert(lines, r.hits)
		table.insert(lines, "")
	end

	output.Text = #results > 0 and table.concat(lines, "\n") or "No matches."
end)

copy.MouseButton1Click:Connect(function()
	output:CaptureFocus()
	output.CursorPosition = 1
	output.SelectionStart = #output.Text + 1
end)

close.MouseButton1Click:Connect(function()
	gui:Destroy()
end)
