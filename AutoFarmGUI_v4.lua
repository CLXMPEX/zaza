local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "RemoteScannerVisible"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local ok = pcall(function()
	gui.Parent = game:GetService("CoreGui")
end)

if not ok or not gui.Parent then
	gui.Parent = player:WaitForChild("PlayerGui")
end

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(360, 260)
frame.Position = UDim2.fromOffset(30, 90)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
frame.BorderSizePixel = 0
frame.ZIndex = 999999
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -36, 0, 28)
title.Position = UDim2.fromOffset(8, 0)
title.BackgroundTransparency = 1
title.Text = "Remote Scanner"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 999999
title.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(26, 24)
close.Position = UDim2.new(1, -30, 0, 2)
close.Text = "X"
close.TextSize = 12
close.ZIndex = 999999
close.Parent = frame

local scan = Instance.new("TextButton")
scan.Size = UDim2.fromOffset(80, 26)
scan.Position = UDim2.fromOffset(8, 34)
scan.Text = "Scan"
scan.TextSize = 12
scan.ZIndex = 999999
scan.Parent = frame

local copy = Instance.new("TextButton")
copy.Size = UDim2.fromOffset(80, 26)
copy.Position = UDim2.fromOffset(96, 34)
copy.Text = "Copy"
copy.TextSize = 12
copy.ZIndex = 999999
copy.Parent = frame

local out = Instance.new("TextBox")
out.Size = UDim2.new(1, -16, 1, -72)
out.Position = UDim2.fromOffset(8, 66)
out.MultiLine = true
out.ClearTextOnFocus = false
out.TextEditable = true
out.TextWrapped = false
out.TextXAlignment = Enum.TextXAlignment.Left
out.TextYAlignment = Enum.TextYAlignment.Top
out.Font = Enum.Font.Code
out.TextSize = 10
out.Text = "Click Scan."
out.ZIndex = 999999
out.Parent = frame

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
