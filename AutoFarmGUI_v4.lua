local Players = game:GetService("Players")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local wanted = "let's dig for treasure"
local found

for _, obj in ipairs(pg:GetDescendants()) do
	if obj:IsA("TextButton") or obj:IsA("TextLabel") then
		local text = string.lower(obj.Text or "")
		if text:find(wanted, 1, true) or text:find("dig for treasure", 1, true) then
			found = obj
			break
		end
	end
end

if not found then
	warn("Could not find the treasure dialogue option. Open the NPC dialogue first.")
	return
end

print("Found option text:", found:GetFullName())

local button = found
while button and not button:IsA("TextButton") and button ~= pg do
	button = button.Parent
end

if not button or not button:IsA("TextButton") then
	warn("Found the text, but could not find a parent TextButton.")
	return
end

print("Trying button:", button:GetFullName())

pcall(function()
	button:Activate()
end)

pcall(function()
	for _, conn in ipairs(getconnections(button.MouseButton1Click)) do
		conn:Fire()
	end
end)

pcall(function()
	for _, conn in ipairs(getconnections(button.Activated)) do
		conn:Fire()
	end
end)
