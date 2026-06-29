local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function openTreasureUi()
	local app = playerGui:FindFirstChild("app")
	if not app then
		warn("No PlayerGui.app found")
		return
	end

	local target

	for _, obj in ipairs(app:GetDescendants()) do
		if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
			if string.find(string.lower(obj.Text or ""), "treasure", 1, true) then
				target = obj
				break
			end
		end
	end

	if not target then
		warn("Could not find Treasure Hunt UI text")
		return
	end

	print("Found treasure UI text:", target:GetFullName())

	local current = target
	while current and current ~= playerGui do
		if current:IsA("ScreenGui") then
			current.Enabled = true
		elseif current:IsA("GuiObject") then
			current.Visible = true
		end

		current = current.Parent
	end
end

openTreasureUi()
