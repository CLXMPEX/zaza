local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local TERMS = {
	"treasure","treasurehunt","treasure hunt","hunt","dig","shovel",
	"water goddess","goddess","tier","reward","clam","found"
}

local SEARCH_ROOTS = {
	player:WaitForChild("PlayerGui"),
	ReplicatedStorage,
	Workspace,
}

local function matchesTerm(text, extra)
	text = string.lower(text or "")

	for _, term in ipairs(TERMS) do
		if string.find(text, term, 1, true) then
			return true, term
		end
	end

	for term in string.gmatch(extra or "", "[^,]+") do
		term = string.lower(term:gsub("^%s+", ""):gsub("%s+$", ""))
		if term ~= "" and string.find(text, term, 1, true) then
			return true, term
		end
	end

	return false
end

local function scoreObject(obj, extra)
	local score = 0
	local hits = {}

	local function add(points, label)
		score += points
		table.insert(hits, label)
	end

	local okName, nameHit = matchesTerm(obj.Name, extra)
	if okName then add(8, "name:" .. nameHit) end

	if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
		local okText, textHit = matchesTerm(obj.Text, extra)
		if okText then add(10, "text:" .. textHit) end
	end

	if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then add(6, obj.ClassName) end
	if obj:IsA("ScreenGui") or obj:IsA("Frame") or obj:IsA("ImageButton") or obj:IsA("TextButton") then add(4, "GUI") end
	if obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then add(6, "interaction") end
	if obj:IsA("Model") and okName then add(3, "model") end

	if score <= 0 then return nil end

	return {
		score = score,
		path = obj:GetFullName(),
		className = obj.ClassName,
		hits = table.concat(hits, ", "),
	}
end

local gui = Instance.new("ScreenGui")
gui.Name = "TreasureHuntFinderGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(430, 315)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(28, 31, 38)
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 34)
titleBar.BackgroundColor3 = Color3.fromRGB(38, 43, 53)
titleBar.Parent = frame

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(10, 0)
title.Size = UDim2.new(1, -20, 1, 0)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = Color3.new(1, 1, 1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Treasure Finder"
title.Parent = titleBar

local extraBox = Instance.new("TextBox")
extraBox.Position = UDim2.fromOffset(10, 44)
extraBox.Size = UDim2.new(1, -170, 0, 28)
extraBox.ClearTextOnFocus = false
extraBox.PlaceholderText = "extra words"
extraBox.Text = ""
extraBox.TextSize = 12
extraBox.Parent = frame

local scanButton = Instance.new("TextButton")
scanButton.Position = UDim2.new(1, -150, 0, 44)
scanButton.Size = UDim2.fromOffset(66, 28)
scanButton.Text = "Scan"
scanButton.TextSize = 12
scanButton.Parent = frame

local copyButton = Instance.new("TextButton")
copyButton.Position = UDim2.new(1, -76, 0, 44)
copyButton.Size = UDim2.fromOffset(66, 28)
copyButton.Text = "Copy"
copyButton.TextSize = 12
copyButton.Parent = frame

local output = Instance.new("TextBox")
output.Position = UDim2.fromOffset(10, 82)
output.Size = UDim2.new(1, -20, 1, -92)
output.MultiLine = true
output.ClearTextOnFocus = false
output.TextEditable = true
output.TextWrapped = false
output.TextXAlignment = Enum.TextXAlignment.Left
output.TextYAlignment = Enum.TextYAlignment.Top
output.Font = Enum.Font.Code
output.TextSize = 11
output.TextColor3 = Color3.fromRGB(235, 235, 235)
output.BackgroundColor3 = Color3.fromRGB(18, 21, 27)
output.Text = "Press Scan."
output.Parent = frame

-- drag window
local dragging = false
local dragStart
local startPos

titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)

titleBar.InputEnded:Connect(function(input)
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

scanButton.MouseButton1Click:Connect(function()
	local results = {}

	for _, root in ipairs(SEARCH_ROOTS) do
		for _, obj in ipairs(root:GetDescendants()) do
			local result = scoreObject(obj, extraBox.Text)
			if result then table.insert(results, result) end
		end
	end

	table.sort(results, function(a, b)
		return a.score > b.score
	end)

	local lines = {"Treasure Finder Results", ""}

	if #results == 0 then
		table.insert(lines, "No matches found.")
	else
		for i, result in ipairs(results) do
			if i > 35 then break end
			table.insert(lines, ("[%d] %d | %s"):format(i, result.score, result.className))
			table.insert(lines, result.path)
			table.insert(lines, "Hits: " .. result.hits)
			table.insert(lines, "")
		end
	end

	output.Text = table.concat(lines, "\n")
end)

copyButton.MouseButton1Click:Connect(function()
	output:CaptureFocus()
	output.CursorPosition = 1
	output.SelectionStart = #output.Text + 1
end)
