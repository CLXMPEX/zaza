local Players = game:GetService("Players")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local function findTreasureLabel()
	local app = pg:FindFirstChild("app")
	if not app then return nil end

	for _, obj in ipairs(app:GetDescendants()) do
		if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
			local text = string.lower(obj.Text or "")
			if text:find("treasure", 1, true) then
				return obj
			end
		end
	end
end

local label = findTreasureLabel()
if not label then
	warn("Could not find Treasure label")
	return
end

print("Treasure label:", label:GetFullName())

local panel = label.Parent
print("Opening panel:", panel:GetFullName())

local current = panel
while current and current ~= pg do
	if current:IsA("ScreenGui") then
		current.Enabled = true
	elseif current:IsA("GuiObject") then
		current.Visible = true
		current.Active = true
	end
	current = current.Parent
end

if panel:IsA("GuiObject") then
	panel.Visible = true
	panel.Active = true
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.ZIndex = 999

	for _, obj in ipairs(panel:GetDescendants()) do
		if obj:IsA("GuiObject") then
			obj.Visible = true
			obj.ZIndex = math.max(obj.ZIndex, 999)
		end
	end
end

local dialogue = pg:FindFirstChild("dialogue")
if dialogue then
	dialogue.Enabled = false
end
