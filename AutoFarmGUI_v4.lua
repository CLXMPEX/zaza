local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local old = pg:FindFirstChild("TreasureAppDebug")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "TreasureAppDebug"
gui.ResetOnSpawn = false
gui.Parent = pg

local win = Instance.new("Frame")
win.Size = UDim2.fromOffset(310, 220)
win.Position = UDim2.fromOffset(60, 120)
win.BackgroundColor3 = Color3.fromRGB(24, 27, 34)
win.BorderSizePixel = 0
win.Active = true
win.Parent = gui

local top = Instance.new("TextButton")
top.Size = UDim2.new(1, 0, 0, 28)
top.BackgroundColor3 = Color3.fromRGB(40, 46, 58)
top.Text = "App Treasure Debug"
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
findBtn.Text = "Find App"
findBtn.TextSize = 12
findBtn.Parent = win

local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.fromOffset(88, 26)
openBtn.Position = UDim2.fromOffset(104, 36)
openBtn.Text = "Open App"
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
out.Text = "Click Find App."
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
		win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)

local candidates = {}

local function isIgnored(obj)
	local full = string.lower(obj:GetFullName())
	return full:find("dialogue", 1, true)
		or full:find("markers", 1, true)
		or full:find("treasureappdebug", 1, true)
		or full:find("treasureopendebug", 1, true)
		or full:find("treasureminifinder", 1, true)
end

local function getOpenAncestor(obj)
	local cur = obj
	local best = obj

	while cur and cur ~= pg do
		if cur:IsA("GuiObject") then
			best = cur
		end

		if cur:IsA("Frame") or cur:IsA("CanvasGroup") or cur:IsA("ScrollingFrame") then
			if cur.AbsoluteSize.X > 250 and cur.AbsoluteSize.Y > 140 then
				return cur
			end
		end

		cur = cur.Parent
	end

	return best
end

local function score(obj)
	local s = 0
	local name = string.lower(obj.Name or "")

	if name:find("treasure", 1, true) then s += 30 end
	if name:find("hunt", 1, true) then s += 20 end
	if name:find("dig", 1, true) then s += 12 end
	if name:find("tier", 1, true) then s += 6 end
	if name:find("found", 1, true) then s += 6 end

	if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
		local text = string.lower(obj.Text or "")
		if text:find("treasure", 1, true) then s += 35 end
		if text:find("hunt", 1, true) then s += 24 end
		if text:find("dig", 1, true) then s += 12 end
		if text:find("tier", 1, true) then s += 6 end
		if text:find("found", 1, true) then s += 6 end
	end

	return s
end

local function findApp()
	candidates = {}

	local app = pg:FindFirstChild("app")
	if not app then
		out.Text = "No PlayerGui.app found."
		return
	end

	for _, obj in ipairs(app:GetDescendants()) do
		if not isIgnored(obj) then
			local s = score(obj)
			if s > 0 then
				local open = getOpenAncestor(obj)
				table.insert(candidates, {
					score = s,
					hit = obj:GetFullName(),
					open = open,
					openPath = open:GetFullName(),
				})
			end
		end
	end

	table.sort(candidates, function(a,b) return a.score > b.score end)

	local lines = {"App candidates:", ""}

	for i, c in ipairs(candidates) do
		if i > 20 then break end
		table.insert(lines, ("[%d] score %d"):format(i, c.score))
		table.insert(lines, "hit: " .. c.hit)
		table.insert(lines, "open: " .. c.openPath)
		table.insert(lines, "")
	end

	out.Text = #candidates > 0 and table.concat(lines, "\n") or "No app candidates."
end

local function openApp()
	if #candidates == 0 then
		findApp()
	end

	local best = candidates[1]
	if not best then return end

	local cur = best.open
	while cur and cur ~= pg do
		if cur:IsA("ScreenGui") then
			cur.Enabled = true
		elseif cur:IsA("GuiObject") then
			cur.Visible = true
			cur.Active = true
			cur.ZIndex = math.max(cur.ZIndex, 950)
		end
		cur = cur.Parent
	end

	for _, obj in ipairs(best.open:GetDescendants()) do
		if obj:IsA("GuiObject") then
			obj.Visible = true
			obj.ZIndex = math.max(obj.ZIndex, 950)
		end
	end

	out.Text = "Tried opening app candidate:\n" .. best.openPath .. "\n\nIf nothing opened, Copy this and paste here."
end

findBtn.MouseButton1Click:Connect(findApp)
openBtn.MouseButton1Click:Connect(openApp)

copyBtn.MouseButton1Click:Connect(function()
	out:CaptureFocus()
	out.CursorPosition = 1
	out.SelectionStart = #out.Text + 1
end)

close.MouseButton1Click:Connect(function()
	gui:Destroy()
end)
