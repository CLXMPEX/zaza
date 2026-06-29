-- === Find Dig Remote (debug) ===

local player = game.Players.LocalPlayer
local pgui = player:WaitForChild("PlayerGui")

if pgui:FindFirstChild("TH_Explorer") then
    pgui.TH_Explorer:Destroy()
end

local sg = Instance.new("ScreenGui")
sg.Name = "TH_Explorer"
sg.ResetOnSpawn = false
sg.DisplayOrder = 999
sg.Parent = pgui

local win = Instance.new("Frame")
win.Size = UDim2.new(0, 300, 0, 300)
win.Position = UDim2.new(0, 10, 0, 10)
win.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
win.BorderSizePixel = 0
win.Active = true
win.Draggable = true
win.ClipsDescendants = true
win.Parent = sg
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 8)

local bar = Instance.new("TextLabel")
bar.Size = UDim2.new(1, 0, 0, 28)
bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
bar.BorderSizePixel = 0
bar.Text = "  Dig Finder — Running..."
bar.TextColor3 = Color3.fromRGB(255, 255, 255)
bar.TextSize = 12
bar.Font = Enum.Font.GothamBold
bar.TextXAlignment = Enum.TextXAlignment.Left
bar.Parent = win
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 8)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -28, 0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = bar
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

local btnBar = Instance.new("Frame")
btnBar.Size = UDim2.new(1, 0, 0, 40)
btnBar.Position = UDim2.new(0, 0, 1, -40)
btnBar.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
btnBar.BorderSizePixel = 0
btnBar.ZIndex = 5
btnBar.Parent = win

local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection = Enum.FillDirection.Horizontal
btnLayout.Padding = UDim.new(0, 6)
btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
btnLayout.Parent = btnBar

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(0, 135, 0, 28)
copyBtn.BackgroundColor3 = Color3.fromRGB(80, 160, 50)
copyBtn.Text = "COPY"
copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyBtn.TextSize = 12
copyBtn.Font = Enum.Font.GothamBold
copyBtn.BorderSizePixel = 0
copyBtn.ZIndex = 6
copyBtn.Parent = btnBar
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 6)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -12, 1, -72)
scroll.Position = UDim2.new(0, 6, 0, 30)
scroll.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = win
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)

local output = Instance.new("TextLabel")
output.Name = "Output"
output.Size = UDim2.new(1, -8, 0, 0)
output.Position = UDim2.new(0, 4, 0, 0)
output.AutomaticSize = Enum.AutomaticSize.Y
output.BackgroundTransparency = 1
output.Text = ""
output.TextColor3 = Color3.fromRGB(0, 255, 100)
output.TextSize = 10
output.Font = Enum.Font.Code
output.TextXAlignment = Enum.TextXAlignment.Left
output.TextYAlignment = Enum.TextYAlignment.Top
output.TextWrapped = true
output.RichText = true
output.Parent = scroll

local logText = ""
local function log(msg)
    logText = logText .. msg .. "\n"
    output.Text = logText
end

copyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(logText)
        bar.Text = "  Dig Finder — Copied!"
    end
end)

-- === AUTO RUN ===
local RS = game:GetService("ReplicatedStorage")

-- 1) Every instance named "dig"
log("=== ALL 'dig' INSTANCES ===")
local found = 0
for _, desc in pairs(RS:GetDescendants()) do
    if desc.Name == "dig" then
        found = found + 1
        log(desc.ClassName .. ": " .. desc:GetFullName())
    end
end
if found == 0 then log("NONE FOUND") end

-- 2) Walk path step by step
log("\n=== PATH WALK ===")
local step = RS
local parts = {"rbxts_include", "node_modules", "@rbxts", "remo", "src", "container", "treasureHunt", "dig"}
for _, part in ipairs(parts) do
    if step then
        step = step:FindFirstChild(part)
        log(part .. " -> " .. (step and step.ClassName or "NIL"))
    else
        log(part .. " -> PARENT NIL")
    end
end

-- 3) List treasureHunt folder children
log("\n=== TREASURE HUNT FOLDER ===")
for _, desc in pairs(RS:GetDescendants()) do
    if desc.Name == "treasureHunt" then
        log("Found: " .. desc:GetFullName() .. " | " .. desc.ClassName)
        for _, child in pairs(desc:GetChildren()) do
            log("  " .. child.Name .. " | " .. child.ClassName)
        end
    end
end

-- 4) Any RemoteFunction anywhere
log("\n=== ALL REMOTE FUNCTIONS ===")
for _, desc in pairs(RS:GetDescendants()) do
    if desc:IsA("RemoteFunction") then
        log(desc.Name .. " | " .. desc:GetFullName())
    end
end

log("\n=== DONE ===")
bar.Text = "  Dig Finder — Done! Hit COPY"
