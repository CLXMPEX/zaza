-- === Page Store Dive v6 (Compact) ===

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
win.Size = UDim2.new(0, 300, 0, 350)
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
bar.Text = "  TH v6 — Scanning..."
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

local function makeBtn(name, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 85, 0, 28)
    b.BackgroundColor3 = color
    b.Text = name
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 12
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.ZIndex = 6
    b.Parent = btnBar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local copyBtn = makeBtn("COPY", Color3.fromRGB(80, 160, 50))
local clearBtn = makeBtn("CLEAR", Color3.fromRGB(180, 50, 50))
local rescanBtn = makeBtn("RE-SCAN", Color3.fromRGB(0, 120, 215))

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
        bar.Text = "  TH v6 — Copied!"
        task.delay(2, function() if bar then bar.Text = "  TH v6 — Ready" end end)
    end
end)

clearBtn.MouseButton1Click:Connect(function()
    logText = ""
    output.Text = "Cleared."
end)

local function safeStr(v, depth)
    depth = depth or 0
    if depth > 2 then return "..." end
    if typeof(v) == "string" then return '"' .. v .. '"' end
    if typeof(v) == "number" or typeof(v) == "boolean" then return tostring(v) end
    if v == nil then return "nil" end
    if typeof(v) == "table" then
        local parts = {}
        local count = 0
        for k2, v2 in pairs(v) do
            count = count + 1
            if count > 15 then table.insert(parts, "...") break end
            table.insert(parts, tostring(k2) .. "=" .. safeStr(v2, depth + 1))
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    return typeof(v) .. ":" .. tostring(v)
end

local function runScan()
    logText = ""
    output.Text = ""
    bar.Text = "  TH v6 — Scanning..."

    log("====== FINDING PAGES MODULE ======")
    local pagesModule, pagesQueueModule, usePageModule

    local playerScripts = player:FindFirstChild("PlayerScripts")
    if playerScripts then
        for _, desc in pairs(playerScripts:GetDescendants()) do
            if desc:IsA("ModuleScript") then
                if desc.Name == "pages" and desc:GetFullName():find("store") then
                    pagesModule = desc
                elseif desc.Name == "pages-queue" then
                    pagesQueueModule = desc
                elseif desc.Name == "use-page" then
                    usePageModule = desc
                end
            end
        end
    end

    if not pagesModule then
        for _, desc in pairs(game:GetService("StarterPlayer"):GetDescendants()) do
            if desc:IsA("ModuleScript") then
                if desc.Name == "pages" and desc:GetFullName():find("store") then
                    pagesModule = desc
                elseif desc.Name == "pages-queue" then
                    pagesQueueModule = desc
                elseif desc.Name == "use-page" then
                    usePageModule = desc
                end
            end
        end
    end

    log("\n====== PAGES STORE ======")
    if pagesModule then
        log("Found: " .. pagesModule:GetFullName())
        local ok, result = pcall(function() return require(pagesModule) end)
        if ok then
            log("Type: " .. typeof(result))
            if typeof(result) == "table" then
                for k, v in pairs(result) do
                    local valStr = typeof(v)
                    if typeof(v) == "function" then
                        local ok2, val = pcall(v)
                        if ok2 then valStr = "fn() -> " .. safeStr(val) else valStr = "fn(err: " .. tostring(val):sub(1, 60) .. ")" end
                    elseif typeof(v) == "table" then
                        valStr = safeStr(v)
                    else
                        valStr = safeStr(v)
                    end
                    log("  " .. tostring(k) .. " = " .. valStr)
                end
            end
        else
            log("Require failed: " .. tostring(result))
        end
    else
        log("NOT FOUND")
    end

    log("\n====== PAGES QUEUE ======")
    if pagesQueueModule then
        log("Found: " .. pagesQueueModule:GetFullName())
        local ok, result = pcall(function() return require(pagesQueueModule) end)
        if ok and typeof(result) == "table" then
            for k, v in pairs(result) do
                local valStr = typeof(v)
                if typeof(v) == "function" then
                    local ok2, val = pcall(v)
                    if ok2 then valStr = "fn() -> " .. safeStr(val) else valStr = "fn(err)" end
                end
                log("  " .. tostring(k) .. " = " .. valStr)
            end
        else
            log("Failed: " .. tostring(result))
        end
    else
        log("NOT FOUND")
    end

    log("\n====== USE-PAGE ======")
    if usePageModule then
        log("Found: " .. usePageModule:GetFullName())
        local ok, result = pcall(function() return require(usePageModule) end)
        if ok and typeof(result) == "table" then
            for k, v in pairs(result) do
                log("  " .. tostring(k) .. " = " .. typeof(v))
            end
        elseif ok and typeof(result) == "function" then
            log("  Exported as single function")
        else
            log("Failed: " .. tostring(result))
        end
    else
        log("NOT FOUND")
    end

    log("\n====== CHARM LIB ======")
    local charmMod
    for _, desc in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if desc:IsA("ModuleScript") and desc.Name == "charm" and not desc:GetFullName():find("sync") and not desc:GetFullName():find("payload") and not desc:GetFullName():find("vide") then
            charmMod = desc
            break
        end
    end
    if charmMod then
        log("Found: " .. charmMod:GetFullName())
        local ok, charm = pcall(function() return require(charmMod) end)
        if ok and typeof(charm) == "table" then
            for k, v in pairs(charm) do
                log("  " .. tostring(k) .. " = " .. typeof(v))
            end
        end
    end

    log("\n====== ALL STORE MODULES ======")
    local roots2 = {playerScripts, game:GetService("StarterPlayer")}
    for _, root in pairs(roots2) do
        if root then
            for _, desc in pairs(root:GetDescendants()) do
                if desc:IsA("ModuleScript") and desc:GetFullName():find("store") then
                    log(desc:GetFullName())
                end
            end
        end
    end

    log("\n====== DONE ======")
    bar.Text = "  TH v6 — Done! Hit COPY"
end

rescanBtn.MouseButton1Click:Connect(function() runScan() end)
runScan()
