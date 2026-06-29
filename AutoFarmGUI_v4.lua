local Players = game:GetService("Players")
local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
local app = pg:WaitForChild("app")

for _, obj in ipairs(app:GetDescendants()) do
	if obj:IsA("TextLabel") and string.lower(obj.Text or ""):find("treasure", 1, true) then
		print("TREASURE LABEL:", obj:GetFullName())

		local current = obj
		while current and current ~= pg do
			local info = current.ClassName .. " | " .. current.Name

			if current:IsA("GuiObject") then
				info ..= " | Visible=" .. tostring(current.Visible)
				info ..= " | Size=" .. tostring(current.Size)
				info ..= " | Pos=" .. tostring(current.Position)
			elseif current:IsA("ScreenGui") then
				info ..= " | Enabled=" .. tostring(current.Enabled)
			end

			print(info)
			current = current.Parent
		end

		break
	end
end
