local Players = game:GetService("Players")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local app = pg:FindFirstChild("app")
if not app then
	warn("No PlayerGui.app found")
	return
end

local target

for _, obj in ipairs(app:GetDescendants()) do
	if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
		local text = string.lower(obj.Text or "")
		if text:find("treasure", 1, true) then
			target = obj
			break
		end
	end
end

if not target then
	warn("Could not find treasure text inside PlayerGui.app")
	return
end

print("Found:", target:GetFullName())

local current = target
while current and current ~= pg do
	if current:IsA("ScreenGui") then
		current.Enabled = true
	elseif current:IsA("GuiObject") then
		current.Visible = true
	end
	current = current.Parent
end

local dialogue = pg:FindFirstChild("dialogue")
if dialogue and dialogue:IsA("ScreenGui") then
	dialogue.Enabled = false
end
