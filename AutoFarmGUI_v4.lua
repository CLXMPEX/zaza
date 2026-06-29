-- === Find Dig Remote ===

local player = game.Players.LocalPlayer
local pgui = player:WaitForChild("PlayerGui")

if pgui:FindFirstChild("TH_Explorer") then
    pgui.TH_Explorer:Destroy()
end

local sg = Instance.new("ScreenGui")
sg.Name = "TH_Explorer"
sg.ResetOnSpawn = false
sg.DisplayOrder = 9999
sg.Parent = pgui

-- COPY BUTTON - BIG, TOP OF SCREEN, ALWAYS VISIBLE
local bigCopy = Instance.new("TextButton")
bigCopy.Size = UDim2.new(0, 150, 0, 50)
bigCopy.Position = UDim2.new(0.5, -75, 0, 5)
bigCopy.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
bigCopy.Text = "COPY LOG"
bigCopy.TextColor3 = Color3.fromRGB(255, 255, 255)
bigCopy.TextSize = 20
bigCopy.Font = Enum.Font.GothamBold
bigCopy.BorderSizePixel = 0
bigCopy.ZIndex = 100
bigCopy.Parent = sg
Instance.new("UICorner", bigCopy).CornerRadius = UDim.new(0, 10)

-- Small log window below
local win = Instance.new("Frame")
win.Size = UDim2.new(0, 280, 0, 250)
win.Position = UDim2.new(0, 10, 0, 60)
win.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
win.BorderSizePixel = 0
win.Active = true
win.Draggable = true
win.ClipsDescendants = true
win.Parent = sg
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 8)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -28, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 10
closeBtn.Parent = win
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -8, 1, -4)
scroll.Position = UDim2.new(0, 4, 0, 2)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = win

local output = Instance.new("TextLabel")
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

bigCopy.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(logText)
        bigCopy.Text = "COPIED!"
        bigCopy.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
        task.delay(2, function()
            if bigCopy then
                bigCopy.Text = "COPY LOG"
                bigCopy.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
            end
        end)
    end
end)

-- === AUTO SCAN ===
local RS = game:GetService("ReplicatedStorage")

log("=== ALL 'dig' INSTANCES ===")
local found = 0
for _, desc in pairs(RS:GetDescendants()) do
    if desc.Name == "dig" then
        found = found + 1
        log(desc.ClassName .. ": " .. desc:GetFullName())
    end
end
if found == 0 then log("NONE FOUND") end

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

log("\n=== TREASURE HUNT FOLDER ===")
for _, desc in pairs(RS:GetDescendants()) do
    if desc.Name == "treasureHunt" then
        log("Found: " .. desc:GetFullName())
        log("Class: " .. desc.ClassName)
        for _, child in pairs(desc:GetChildren()) do
            log("  " .. child.Name .. " | " .. child.ClassName)
        end
    end
end

log("\n=== ALL REMOTE FUNCTIONS ===")
for _, desc in pairs(RS:GetDescendants()) do
    if desc:IsA("RemoteFunction") then
        log(desc.Name .. " | " .. desc:GetFullName())
    end
end

log("\n=== DONE ===")
