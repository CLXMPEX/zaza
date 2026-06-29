local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local old = pg:FindFirstChild("TreasureRecorder")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "TreasureRecorder"
gui.ResetOnSpawn = false
gui.Parent = pg

local win = Instance.new("Frame")
win.Size = UDim2.fromOffset(300, 190)
win.Position = UDim2.fromOffset(70, 130)
win.BackgroundColor3 = Color3.fromRGB(24, 27, 34)
win.BorderSizePixel = 0
win.Active = true
win.Parent = gui

local top = Instance.new("TextButton")
top.Size = UDim2.new(1, 0, 0, 28)
top.Text = "Treasure Recorder"
top.TextSize = 13
top.TextColor3 = Color3.new(1,1,1)
top.BackgroundColor3 = Color3.fromRGB(40, 46, 58)
top.Parent = win

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(24, 24)
close.Position = UDim2.new(1, -26, 0, 2)
close.Text = "X"
close.Parent = win

local arm = Instance.new("TextButton")
arm.Size = UDim2.fromOffset(64, 26)
arm.Position = UDim2.fromOffset(8, 36)
arm.Text = "Arm"
arm.Parent = win

local capture = Instance.new("TextButton")
capture.Size = UDim2.fromOffset(74, 26)
capture.Position = UDim2.fromOffset(80, 36)
capture.Text = "Capture"
capture.Parent = win

local open = Instance.new("TextButton")
open.Size = UDim2.fromOffset(92, 26)
open.Position = UDim2.fromOffset(162, 36)
open.Text = "Open Saved"
open.Parent = win

local out = Instance.new("TextBox")
out.Size = UDim2.new(1, -16, 1, -72)
out.Position = UDim2.fromOffset(8, 68)
out.MultiLine = true
out.ClearTextOnFocus = false
out.TextEditable = true
out.TextWrapped = true
out.TextXAlignment = Enum.TextXAlignment.Left
out.TextYAlignment = Enum.TextYAlignment.Top
out.TextSize = 11
out.Text = "Click Arm, then use the NPC once."
out.Parent = win

local savedPanel

local function ignored(obj)
	local full = obj:GetFullName():lower()
	return full:find("dialogue", 1, true)
		or full:find("markers", 1, true)
		or full:find("treasurerecorder", 1, true)
end

local function score(obj)
	local s = 0
	local name = (obj.Name or ""):lower()

	if name:find("treasure", 1, true) then s += 30 end
	if name:find("hunt", 1, true) then s += 20 end
	if name:find("tier", 1, true) then s += 8 end
	if name:find("found", 1, true) then s += 8 end

	if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
		local text = (obj.Text or ""):lower()
		if text:find("treasure", 1, true) then s += 40 end
		if text:find("hunt", 1, true) then s += 25 end
		if text:find("tier", 1, true) then s += 10 end
		if text:find("found", 1, true) then s += 10 end
	end

	return s
end

local function bigVisibleAncestor(obj)
	local cur = obj
	local best = obj

	while cur and cur ~= pg do
		if cur:IsA("GuiObject") and cur.Visible then
			best = cur
			if cur.AbsoluteSize.X > 300 and cur.AbsoluteSize.Y > 180 then
				return cur
			end
		end
		cur = cur.Parent
	end

	return best
end

local function captureVisibleTreasure()
	local bestScore = 0
	local bestObj
	local bestPanel

	for _, obj in ipairs(pg:GetDescendants()) do
		if not ignored(obj) and obj:IsA("GuiObject") and obj.Visible then
			local s = score(obj)
			if s > bestScore then
				bestScore = s
				bestObj = obj
				bestPanel = bigVisibleAncestor(obj)
			end
		end
	end

	if bestPanel then
		savedPanel = bestPanel
		out.Text = "Saved panel:\n" .. savedPanel:GetFullName() .. "\n\nHit was:\n" .. bestObj:GetFullName()
	else
		out.Text = "Could not find visible Treasure panel. Open the hunt screen first, then press Capture."
	end
end

local function openSaved()
	if not savedPanel or not savedPanel.Parent then
		out.Text = "No saved panel yet. Arm, open NPC treasure screen once, then Capture."
		return
	end

	local cur = savedPanel
	while cur and cur ~= pg do
		if cur:IsA("ScreenGui") then
			cur.Enabled = true
		elseif cur:IsA("GuiObject") then
			cur.Visible = true
			cur.Active = true
			cur.ZIndex = math.max(cur.ZIndex, 900)
		end
		cur = cur.Parent
	end

	out.Text = "Opened saved panel:\n" .. savedPanel:GetFullName()
end

arm.MouseButton1Click:Connect(function()
	savedPanel = nil
	out.Text = "Armed. Now press the NPC option once. When the hunt screen is visible, click Capture."
end)

capture.MouseButton1Click:Connect(captureVisibleTreasure)
open.MouseButton1Click:Connect(openSaved)
close.MouseButton1Click:Connect(function() gui:Destroy() end)

local dragging, dragStart, startPos
top.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = win.Position
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local d = input.Position - dragStart
		win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)
