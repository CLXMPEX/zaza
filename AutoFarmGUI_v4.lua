local Players = game:GetService("Players")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "TinyTestGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Size = UDim2.fromOffset(120, 40)
button.Position = UDim2.fromOffset(40, 120)
button.Text = "GUI works"
button.Parent = gui
