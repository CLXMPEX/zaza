-- Regular Roblox Treasure Hunt Finder
-- LocalScript for StarterPlayerScripts or StarterGui

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local TERMS = {
	"treasure",
	"treasurehunt",
	"treasure hunt",
	"hunt",
	"dig",
	"shovel",
	"water goddess",
	"goddess",
	"tier",
	"reward",
	"clam",
	"found",
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

	return false, nil
end

local function scoreObject(obj, extra)
	local score = 0
	local hits = {}

	local function add(points, label)
		score += points
		table.insert(hits, label)
	end

	local okName, nameHit = matchesTerm(obj.Name, extra)
	if okName then
		add(8, "name:" .. nameHit)
	end

	if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
		local okText, textHit = matchesTerm(obj.Text, extra)
		if okText then
			add(10, "text:" .. textHit)
		end
	end

	if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
		add(6, obj.ClassName)
	end

	if obj:IsA("ScreenGui") or obj:IsA("Frame") or obj:IsA("ImageButton") or obj:IsA("TextButton") then
		add(4, "GUI")
	end

	if obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
		add(6, "interaction")
	end

	if obj:IsA("Model") and okName then
		add(3, "model")
	end

	if score <= 0 then
		return nil
	end

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
frame.Size = UDim2.fromOffset(700, 480)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(28, 31, 38)
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(16, 10)
title.Size = UDim2.new(1, -32, 0, 30)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.new(1, 1, 1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Treasure Hunt Finder"
title.Parent = frame

local extraBox = Instance.new("TextBox")
extraBox.Position = UDim2.fromOffset(16, 52)
extraBox.Size = UDim2.new(1, -228, 0, 34)
extraBox.ClearTextOnFocus = false
extraBox.PlaceholderText = "Extra words, comma separated"
extraBox.Text = ""
extraBox.Parent = frame

local scanButton = Instance.new("TextButton")
scanButton.Position = UDim2.new(1, -204, 0, 52)
scanButton.Size = UDim2.fromOffset(88, 34)
scanButton.Text = "Scan"
scanButton.Parent = frame

local copyButton = Instance.new("TextButton")
copyButton.Position = UDim2.new(1, -108, 0, 52)
copyButton.Size = UDim2.fromOffset(92, 34)
copyButton.Text = "Copy"
copyButton.Parent = frame

local output = Instance.new("TextBox")
output.Position = UDim2.fromOffset(16, 100)
output.Size = UDim2.new(1, -32, 1, -116)
output.MultiLine = true
output.ClearTextOnFocus = false
output.TextEditable = true
output.TextWrapped = false
output.TextXAlignment = Enum.TextXAlignment.Left
output.TextYAlignment = Enum.TextYAlignment.Top
output.Font = Enum.Font.Code
output.TextSize = 14
output.TextColor3 = Color3.fromRGB(235, 235, 235)
output.BackgroundColor3 = Color3.fromRGB(18, 21, 27)
output.Text = "Press Scan. This searches PlayerGui, ReplicatedStorage, and Workspace."
output.Parent = frame

scanButton.MouseButton1Click:Connect(function()
	local results = {}

	for _, root in ipairs(SEARCH_ROOTS) do
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

	local lines = {
		"Treasure Hunt Finder Results",
		"Searches live client objects only, not script source.",
		"",
	}

	if #results == 0 then
		table.insert(lines, "No matches found.")
	else
		for i, result in ipairs(results) do
			if i > 50 then break end

			table.insert(lines, ("[%d] Score %d | %s"):format(i, result.score, result.className))
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
