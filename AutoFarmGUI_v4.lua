-- === Auto-Scan Treasure Hunt Explorer v2 ===

local player = game.Players.LocalPlayer
local pgui = player:WaitForChild("PlayerGui")

if pgui:FindFirstChild("TH_Explorer") then
    pgui.TH_Explorer:Destroy()
end

-- GUI setup
local sg = Instance.new("ScreenGui")
sg.Name = "TH_Explorer"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = pgui

local win = Instance.new("Frame")
win.Size = UDim2.new(0, 440, 0, 520)
win.Position = UDim2.new(0.5, -220, 0.5, -260)
win.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
win.BorderSizePixel = 0
win.Active = true
win.Draggable = true
win.Parent = sg
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 8)

local bar = Instance.new("TextLabel")
bar.Size = UDim2.new(1, 0, 0, 36)
bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
bar.BorderSizePixel = 0
bar.Text = "  TH Explorer v2 — Scanning..."
bar.TextColor3 = Color3.fromRGB(255, 255, 255)
bar.TextSize = 15
bar.Font = Enum.Font.GothamBold
bar.TextXAlignment = Enum.TextXAlignment.Left
bar.Parent = win
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 8)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -36, 0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
closeBtn.TextSize = 18
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = bar
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -16, 1, -95)
scroll.Position = UDim2.new(0, 8, 0, 40)
scroll.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = win
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)

local output = Instance.new("TextLabel")
output.Name = "Output"
output.Size = UDim2.new(1, -10, 0, 0)
output.Position = UDim2.new(0, 5, 0, 0)
output.AutomaticSize = Enum.AutomaticSize.Y
output.BackgroundTransparency = 1
output.Text = ""
output.TextColor3 = Color3.fromRGB(0, 255, 100)
output.TextSize = 12
output.Font = Enum.Font.Code
output.TextXAlignment = Enum.TextXAlignment.Left
output.TextYAlignment = Enum.TextYAlignment.Top
output.TextWrapped = true
output.RichText = true
output.Parent = scroll

-- Buttons
local btnRow = Instance.new("Frame")
btnRow.Size = UDim2.new(1, -16, 0, 40)
btnRow.Position = UDim2.new(0, 8, 1, -48)
btnRow.BackgroundTransparency = 1
btnRow.Parent = win

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.Padding = UDim.new(0, 8)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = btnRow

local function makeBtn(name, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 130, 0, 36)
    b.BackgroundColor3 = color
    b.Text = name
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 15
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.Parent = btnRow
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local copyBtn = makeBtn("COPY", Color3.fromRGB(80, 160, 50))
local clearBtn = makeBtn("CLEAR", Color3.fromRGB(180, 50, 50))
local rescanBtn = makeBtn("RE-SCAN", Color3.fromRGB(0, 120, 215))

-- Log system
local logText = ""
local function log(msg)
    logText = logText .. msg .. "\n"
    output.Text = logText
end

copyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(logText)
        bar.Text = "  TH Explorer v2 — Copied!"
        task.delay(2, function()
            if bar then bar.Text = "  TH Explorer v2 — Ready" end
        end)
    else
        bar.Text = "  TH Explorer v2 — No clipboard access"
    end
end)

clearBtn.MouseButton1Click:Connect(function()
    logText = ""
    output.Text = "Cleared."
end)

-- === THE FULL SCAN ===
local function runScan()
    logText = ""
    output.Text = ""
    bar.Text = "  TH Explorer v2 — Scanning..."

    -- 1) All ScreenGuis
    log("====== SCREENGUI LIST ======")
    for _, s in pairs(pgui:GetChildren()) do
        if s:IsA("ScreenGui") then
            log(s.Name .. " | Enabled: " .. tostring(s.Enabled))
        end
    end

    -- 2) Keyword search across entire PlayerGui
    log("\n====== KEYWORD SEARCH (Full PlayerGui) ======")
    local keywords = {"treasure", "dig", "hunt", "shovel", "goddess", "board", "water", "tile", "grid", "npc"}
    for _, desc in pairs(pgui:GetDescendants()) do
        local n = desc.Name:lower()
        for _, kw in pairs(keywords) do
            if n:find(kw) then
                local vis = "N/A"
                pcall(function() vis = tostring(desc.Visible) end)
                log(desc:GetFullName())
                log("  Class: " .. desc.ClassName .. " | Vis: " .. vis)
                break
            end
        end
    end

    -- 3) Deep scan app + popups + absolute for pages/panels/modals
    log("\n====== PAGE/PANEL/MODAL SYSTEM ======")
    for _, guiName in pairs({"app", "popups", "absolute", "top-layer"}) do
        local g = pgui:FindFirstChild(guiName)
        if g then
            for _, desc in pairs(g:GetDescendants()) do
                local n = desc.Name:lower()
                if n:find("page") or n:find("panel") or n:find("tab") or n:find("screen") or n:find("modal") or n:find("overlay") or n:find("popup") or n:find("menu") or n:find("window") then
                    if desc:IsA("Frame") or desc:IsA("ScrollingFrame") or desc:IsA("CanvasGroup") then
                        local vis = "N/A"
                        pcall(function() vis = tostring(desc.Visible) end)
                        log("[" .. guiName .. "] " .. desc.Name .. " | " .. desc.ClassName .. " | Vis: " .. vis)
                        log("  " .. desc:GetFullName())
                    end
                end
            end
        end
    end

    -- 4) Direct children of app (top-level frames = likely pages)
    log("\n====== APP TOP-LEVEL CHILDREN ======")
    local appGui = pgui:FindFirstChild("app")
    if appGui then
        for _, child in pairs(appGui:GetChildren()) do
            local vis = "N/A"
            pcall(function() vis = tostring(child.Visible) end)
            log(child.Name .. " | " .. child.ClassName .. " | Vis: " .. vis)
        end
    end

    -- 5) Direct children of popups
    log("\n====== POPUPS TOP-LEVEL CHILDREN ======")
    local popGui = pgui:FindFirstChild("popups")
    if popGui then
        for _, child in pairs(popGui:GetChildren()) do
            local vis = "N/A"
            pcall(function() vis = tostring(child.Visible) end)
            log(child.Name .. " | " .. child.ClassName .. " | Vis: " .. vis)
        end
    end

    -- 6) Keyword remotes
    log("\n====== KEYWORD REMOTES ======")
    local roots = {game:GetService("ReplicatedStorage"), workspace}
    for _, root in pairs(roots) do
        for _, desc in pairs(root:GetDescendants()) do
            if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") or desc:IsA("BindableEvent") or desc:IsA("BindableFunction") then
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

    -- 7) All remotes
    log("\n====== ALL REMOTES ======")
    for _, desc in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
            log(desc.Name .. " -> " .. desc:GetFullName())
        end
    end

    -- 8) Module scripts with treasure/hunt
    log("\n====== MODULES (treasure/hunt/dig) ======")
    for _, root in pairs({game:GetService("ReplicatedStorage"), game:GetService("StarterPlayer")}) do
        for _, desc in pairs(root:GetDescendants()) do
            if desc:IsA("ModuleScript") then
                local n = desc.Name:lower()
                if n:find("treasure") or n:find("hunt") or n:find("dig") or n:find("shovel") then
                    log(desc:GetFullName())
                end
            end
        end
    end

    -- 9) Charm / state atoms
    log("\n====== CHARM / STATE ======")
    for _, desc in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        local n = desc.Name:lower()
        if n:find("atom") or n:find("store") or n:find("state") or n:find("charm") then
            log(desc:GetFullName() .. " | " .. desc.ClassName)
        end
    end

    log("\n====== SCAN COMPLETE ======")
    bar.Text = "  TH Explorer v2 — Done! Press COPY"
end

rescanBtn.MouseButton1Click:Connect(function() runScan() end)

-- Auto-run on paste
runScan()
