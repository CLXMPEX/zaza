local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local old = pg:FindFirstChild("RemoteScanGui")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "RemoteScanGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.Parent = pg

local win = Instance.new("Frame")
win.Size = UDim2.fromOffset(310, 220)
win.Position = UDim2.fromOffset(70, 140)
win.BackgroundColor3 = Color3.fromRGB(24, 27, 34)
win.BorderSizePixel = 0
win.Active = true
win.Parent = gui

local top = Instance.new("TextButton")
top.Size = UDim2.new(1, 0, 0, 28)
top.BackgroundColor3 = Color3.fromRGB(40, 46, 58)
top.Text = "Remote Scanner"
top.TextColor3 = Color3.new(1, 1, 1)
top.TextSize = 13
top.Parent = win

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(24, 24)
close.Position = UDim2.new(1, -26, 0, 2)
close.Text = "X"
close.TextSize = 12
close.BackgroundColor3 = Color3.fromRGB(220, 70, 80)
close.Parent = win

local scan = Instance.new("TextButton")
scan.Size = UDim2.fromOffset(92, 26)
scan.Position = UDim2.fromOffset(8, 36)
scan.Text = "Scan"
scan.TextSize = 12
scan.Parent = win

local copy = Instance.new("TextButton")
copy.Size = UDim2.fromOffset(92, 26)
copy.Position = UDim2.fromOffset(108, 36)
copy.Text = "Copy"
copy.TextSize = 12
copy.Parent = win

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
out.Text = "Click Scan."
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

local words = {
	"treasure", "hunt", "dig", "event", "open", "start",
	"dialogue", "dialog", "npc", "goddess", "interact"
}

scan.MouseButton1Click:Connect(function()
	local results = {}

	for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
		if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then
			local path = obj:GetFullName()
			local lower = path:lower()

			for _, word in ipairs(words) do
				if lower:find(word, 1, true) then
					table.insert(results, obj.ClassName .. " | " .. path)
					break
				end
			end
		end
	end

	table.sort(results)

	if #results == 0 then
		out.Text = "No matching remotes found."
	else
		local lines = {"Remote scan results:", ""}
		for i, line in ipairs(results) do
			table.insert(lines, "[" .. i .. "] " .. line)
		end
		out.Text = table.concat(lines, "\n")
	end
end)

copy.MouseButton1Click:Connect(function()
	out:CaptureFocus()
	out.CursorPosition = 1
	out.SelectionStart = #out.Text + 1
end)

close.MouseButton1Click:Connect(function()
	gui:Destroy()
end)
