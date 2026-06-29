-- === Treasure Hunt Explorer GUI ===

local player = game.Players.LocalPlayer
local pgui = player:WaitForChild("PlayerGui")

-- Clean up old copy if re-running
if pgui:FindFirstChild("TH_Explorer") then
    pgui.TH_Explorer:Destroy()
end

-- Main ScreenGui
local sg = Instance.new("ScreenGui")
sg.Name = "TH_Explorer"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = pgui

-- Draggable window
local win = Instance.new("Frame")
win.Name = "Window"
win.Size = UDim2.new(0, 420, 0, 500)
win.Position = UDim2.new(0.5, -210, 0.5, -250)
win.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
win.BorderSizePixel = 0
win.Active = true
win.Draggable = true
win.Parent = sg

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = win

-- Title bar
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 36)
title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
title.BorderSizePixel = 0
title.Text = "  Treasure Hunt Explorer"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = win

local tc = Instance.new("UICorner")
tc.CornerRadius = UDim.new(0, 8)
tc.Parent = title

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -36, 0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
closeBtn.TextSize = 18
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = title
closeBtn.MouseButton1Click:Connect(function()
    sg:Destroy()
end)

-- Scroll frame for output
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -100)
scroll.Position = UDim2.new(0, 10, 0, 42)
scroll.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = win

local sc = Instance.new("UICorner")
sc.CornerRadius = UDim.new(0, 6)
sc.Parent = scroll

local output = Instance.new("TextLabel")
output.Name = "Output"
output.Size = UDim2.new(1, -10, 0, 0)
output.Position = UDim2.new(0, 5, 0, 0)
output.AutomaticSize = Enum.AutomaticSize.Y
output.BackgroundTransparency = 1
output.Text = "Press SCAN to start..."
output.TextColor3 = Color3.fromRGB(0, 255, 100)
output.TextSize = 13
output.Font = Enum.Font.Code
output.TextXAlignment = Enum.TextXAlignment.Left
output.TextYAlignment = Enum.TextYAlignment.Top
output.TextWrapped = true
output.RichText = true
output.Parent = scroll

-- Button row
local btnRow = Instance.new("Frame")
btnRow.Size = UDim2.new(1, -20, 0, 40)
btnRow.Position = UDim2.new(0, 10, 1, -50)
btnRow.BackgroundTransparency = 1
btnRow.Parent = win

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.Padding = UDim.new(0, 8)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = btnRow

local function makeBtn(name, color)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = UDim2.new(0, 120, 0, 36)
    b.BackgroundColor3 = color
    b.Text = name
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 15
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.Parent = btnRow
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 6)
    bc.Parent = b
    return b
end

local scanBtn = makeBtn("SCAN", Color3.fromRGB(0, 120, 215))
local copyBtn = makeBtn("COPY", Color3.fromRGB(80, 160, 50))
local clearBtn = makeBtn("CLEAR", Color3.fromRGB(180, 50, 50))

-- Log buffer
local logText = ""

local function log(msg)
    logText = logText .. msg .. "\n"
    output.Text = logText
end

-- CLEAR
clearBtn.MouseButton1Click:Connect(function()
    logText = ""
    output.Text = "Cleared. Press SCAN to run again."
end)

-- COPY
copyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(logText)
        output.Text = logText .. "\n<font color='rgb(255,255,0)'>[Copied to clipboard]</font>"
    else
        output.Text = logText .. "\n<font color='rgb(255,80,80)'>[setclipboard not available]</font>"
    end
end)

-- SCAN
scanBtn.MouseButton1Click:Connect(function()
    logText = ""
    log("====== SCREENGUI LIST ======")
    for _, s in pairs(pgui:GetChildren()) do
        if s:IsA("ScreenGui") then
            log(s.Name .. " | Enabled: " .. tostring(s.Enabled))
        end
    end

    log("\n====== KEYWORD SEARCH (GUI) ======")
    local keywords = {"treasure", "dig", "hunt", "shovel", "goddess", "board", "water"}
    for _, desc in pairs(pgui:GetDescendants()) do
        local n = desc.Name:lower()
        for _, kw in pairs(keywords) do
            if n:find(kw) then
                local vis = "N/A"
                pcall(function() vis = tostring(desc.Visible) end)
                log(desc:GetFullName() .. "\n  Class: " .. desc.ClassName .. " | Visible: " .. vis)
                break
            end
        end
    end

    log("\n====== KEYWORD REMOTES ======")
    local roots = {game:GetService("ReplicatedStorage"), workspace}
    for _, root in pairs(roots) do
        for _, desc in pairs(root:GetDescendants()) do
            if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") or desc:IsA("BindableEvent") then
                local n = desc.Name:lower()
                for _, kw in pairs(keywords) do
                    if n:find(kw) then
                        log(desc:GetFullName() .. " | " .. desc.ClassName)
                        break
                    end
                end
            end
        end
    end

    log("\n====== ALL REMOTES ======")
    for _, desc in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
            log(desc.Name .. " -> " .. desc:GetFullName())
        end
    end

    log("\n====== DONE ======")
end)
