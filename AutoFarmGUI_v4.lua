local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local old = pg:FindFirstChild("HuntAnywhereButton")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "HuntAnywhereButton"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.Parent = pg

local win = Instance.new("Frame")
win.Size = UDim2.fromOffset(190, 92)
win.Position = UDim2.fromOffset(80, 160)
win.BackgroundColor3 = Color3.fromRGB(24, 27, 34)
win.BorderSizePixel = 0
win.Active = true
win.Parent = gui
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 8)

local top = Instance.new("TextButton")
top.Size = UDim2.new(1, 0, 0, 26)
top.BackgroundColor3 = Color3.fromRGB(39, 45, 56)
top.Text = "Treasure Hunt"
top.TextColor3 = Color3.new(1, 1, 1)
top.TextSize = 12
top.Font = Enum.Font.GothamBold
top.Parent = win

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(22, 22)
close.Position = UDim2.new(1, -24, 0, 2)
close.Text = "X"
close.TextSize = 11
close.BackgroundColor3 = Color3.fromRGB(220, 70, 80)
close.TextColor3 = Color3.new(1, 1, 1)
close.Parent = win

local open = Instance.new("TextButton")
open.Size = UDim2.fromOffset(86, 28)
open.Position = UDim2.fromOffset(8, 34)
open.Text = "Open Hunt"
open.TextSize = 12
open.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
open.TextColor3 = Color3.new(1, 1, 1)
open.Parent = win

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -104, 0, 48)
status.Position = UDim2.fromOffset(100, 32)
status.BackgroundTransparency = 1
status.Text = "Ready"
status.TextWrapped = true
status.TextSize = 10
status.TextColor3 = Color3.fromRGB(230, 230, 230)
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = win

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

local function tryDialogueButton()
	for _, obj in ipairs(pg:GetDescendants()) do
		if obj:IsA("TextButton") or obj:IsA("TextLabel") then
			local text = string.lower(obj.Text or "")
			if text:find("dig for treasure", 1, true) or text:find("let's dig", 1, true) then
				local button = obj
				while button and not button:IsA("TextButton") and button ~= pg do
					button = button.Parent
				end

				if button and button:IsA("TextButton") then
					pcall(function() button:Activate() end)

					if getconnections then
						pcall(function()
							for _, c in ipairs(getconnections(button.MouseButton1Click)) do
								c:Fire()
							end
						end)

						pcall(function()
							for _, c in ipairs(getconnections(button.Activated)) do
								c:Fire()
							end
						end)
					end

					return true, "Pressed dialogue option"
				end
			end
		end
	end

	return false, "Dialogue option not visible"
end

local function tryPrompt()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("ProximityPrompt") then
			local full = string.lower(obj:GetFullName())
			local text = string.lower((obj.ActionText or "") .. " " .. (obj.ObjectText or ""))

			if full:find("goddess", 1, true)
				or full:find("hunt", 1, true)
				or text:find("hunt", 1, true)
				or text:find("goddess", 1, true) then

				if fireproximityprompt then
					pcall(function()
						fireproximityprompt(obj)
					end)
					return true, "Triggered prompt"
				else
					return false, "Found prompt, but cannot trigger from here"
				end
			end
		end
	end

	return false, "No hunt prompt found"
end

open.MouseButton1Click:Connect(function()
	status.Text = "Trying..."

	local ok, msg = tryDialogueButton()
	if ok then
		status.Text = msg
		return
	end

	local ok2, msg2 = tryPrompt()
	if ok2 then
		status.Text = msg2
		return
	end

	status.Text = msg .. "\n" .. msg2
end)

close.MouseButton1Click:Connect(function()
	gui:Destroy()
end)
