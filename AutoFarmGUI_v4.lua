local Players = game:GetService("Players")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local app = pg:WaitForChild("app")
local panel = app:WaitForChild("Frame"):WaitForChild("Frame"):WaitForChild("Frame")

local function openTreasure()
	local cur = panel

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

	for _, obj in ipairs(panel:GetDescendants()) do
		if obj:IsA("GuiObject") then
			obj.Visible = true
			obj.ZIndex = math.max(obj.ZIndex, 900)
		end
	end

	local dialogue = pg:FindFirstChild("dialogue")
	if dialogue then
		dialogue.Enabled = false
	end
end

openTreasure()
