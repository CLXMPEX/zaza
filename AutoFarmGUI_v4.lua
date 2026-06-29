local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local old = pg:FindFirstChild("TreasureOpenDebug")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "TreasureOpenDebug"
gui.ResetOnSpawn = false
gui.Parent = pg

local win = Instance.new("Frame")
win.Size = UDim2.fromOffset(300, 210)
win.Position = UDim2.fromOffset(60, 120)
win.BackgroundColor3 = Color3.fromRGB(24, 27, 34)
win.BorderSizePixel = 0
win.Active = true
win.Parent = gui

local top = Instance.new("TextButton")
top.Size = UDim2.new(1, 0, 0, 28)
top.BackgroundColor3 = Color3.fromRGB(40, 46, 58)
top.Text = "Treasure Debug"
top.TextColor3 = Color3.new(1,1,1)
top.TextSize = 13
top.Parent = win

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(24, 24)
close.Position = UDim2.new(1, -26, 0, 2)
close.Text = "X"
close.TextSize = 12
close.BackgroundColor3 = Color3.fromRGB(220, 70, 80)
close.Parent = win

local findBtn = Instance.new("TextButton")
findBtn.Size = UDim2.fromOffset(88, 26)
findBtn.Position = UDim2.fromOffset(8, 36)
findBtn.Text = "Find"
findBtn.TextSize = 12
findBtn.Parent = win

local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.fromOffset(88, 26)
openBtn.Position = UDim2.fromOffset(104, 36)
openBtn.Text = "Open Best"
openBtn.TextSize = 12
openBtn.Parent = win

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.fromOffset(88, 26)
copyBtn.Position = UDim2.fromOffset(200, 36)
copyBtn.Text = "Copy"
copyBtn.TextSize = 12
copyBtn.Parent = win

local out = Instance.new("TextBox")
out.Size = UDim2.new(1, -16, 1, -72)
out.Position = UDim2.fromOffset(8, 68)
out.MultiLine = true
out.ClearTextOnFocus = false
out.TextEditable = true
out.TextWrapped = false
out.TextXAlignment = Enum.TextXAlignment.Left
out.TextYAlignment = Enum.TextYAlignment.Top
out.Font = Enum.Font.Code
out.TextSize = 10
out.Text = "Click Find."
out.Parent = win

local dragging = false
local dragStart
local startPos

top.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = win.Position
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local d = input.Position - dragStart
		win.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + d.X,
			startPos.Y.Scale,
			startPos.Y.Offset + d.Y
		)
	end
end)

local candidates = {}

local function scoreGuiObject(obj)
	local score = 0
	local name = string.lower(obj.Name or "")

	if name:find("treasure", 1, true) then score += 20 end
	if name:find("hunt", 1, true) then score += 12 end
	if name:find("dig", 1, true) then score += 8 end
	if name:find("tier", 1, true) then score += 4 end

	if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
		local text = string.lower(obj.Text or "")
		if text:find("treasure", 1, true) then score += 25 end
		if text:find("hunt", 1, true) then score += 15 end
		if text:find("dig", 1, true) then score += 10 end
		if text:find("tier", 1, true) then score += 4 end
		if text:find("found", 1, true) then score += 4 end
	end

	return score
end

local function getBigAncestor(obj)
	local current = obj

	while current and current ~= pg do
		if current:IsA("Frame") or current:IsA("CanvasGroup") or current:IsA("ScrollingFrame") then
			if current.AbsoluteSize.X > 200 and current.AbsoluteSize.Y > 120 then
				return current
			end
		end
		current = current.Parent
	end

	return obj
end

local function findCandidates()
	candidates = {}

	for _, obj in ipairs(pg:GetDescendants()) do
		if not obj:IsDescendantOf(gui) then
			local score = scoreGuiObject(obj)
			if score > 0 then
				local open = getBigAncestor(obj)
				table.insert(candidates, {
					score = score,
					hit = obj,
					open = open,
					hitPath = obj:GetFullName(),
					openPath = open:GetFullName(),
				})
			end
		end
	end

	table.sort(candidates, function(a,b)
		return a.score > b.score
	end)

	local lines = {"Candidates:", ""}

	for i, c in ipairs(candidates) do
		if i > 15 then break end
		table.insert(lines, ("[%d] score %d"):format(i, c.score))
		table.insert(lines, "hit: " .. c.hitPath)
		table.insert(lines, "open: " .. c.openPath)
		table.insert(lines, "")
	end

	out.Text = #candidates > 0 and table.concat(lines, "\n") or "No candidates found."
end

local function openBest()
	if #candidates == 0 then
		findCandidates()
	end

	local best = candidates[1]
	if not best then
		out.Text = "No best candidate."
		return
	end

	local current = best.open
	while current and current ~= pg do
		if current:IsA("ScreenGui") then
			current.Enabled = true
		elseif current:IsA("GuiObject") then
			current.Visible = true
			current.Active = true
			current.ZIndex = math.max(current.ZIndex, 900)
		end
		current = current.Parent
	end

	for _, obj in ipairs(best.open:GetDescendants()) do
		if obj:IsA("GuiObject") then
			obj.Visible = true
			obj.ZIndex = math.max(obj.ZIndex, 900)
		end
	end

	out.Text = "Tried opening:\n" .. best.openPath .. "\n\nIf nothing opened, click Copy and paste this whole box here."
end

findBtn.MouseButton1Click:Connect(findCandidates)
openBtn.MouseButton1Click:Connect(openBest)

copyBtn.MouseButton1Click:Connect(function()
	out:CaptureFocus()
	out.CursorPosition = 1
	out.SelectionStart = #out.Text + 1
end)

close.MouseButton1Click:Connect(function()
	gui:Destroy()
end)
