-- === Page Store Dive v6 ===

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
win.Size = UDim2.new(0, 440, 0, 540)
win.Position = UDim2.new(0.5, -220, 0.5, -270)
win.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
win.BorderSizePixel = 0
win.Active = true
win.Draggable = true
win.ClipsDescendants = true
win.Parent = sg
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 8)

local bar = Instance.new("TextLabel")
bar.Size = UDim2.new(1, 0, 0, 36)
bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
bar.BorderSizePixel = 0
bar.Text = "  Page Dive v6 — Scanning..."
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

local btnBar = Instance.new("Frame")
btnBar.Size = UDim2.new(1, 0, 0, 56)
btnBar.Position = UDim2.new(0, 0, 1, -56)
btnBar.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
btnBar.BorderSizePixel = 0
btnBar.ZIndex = 5
btnBar.Parent = win

local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection = Enum.FillDirection.Horizontal
btnLayout.Padding = UDim.new(0, 8)
btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
btnLayout.Parent = btnBar

local function makeBtn(name, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 125, 0, 38)
    b.BackgroundColor3 = color
    b.Text = name
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 15
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
scroll.Size = UDim2.new(1, -16, 1, -98)
scroll.Position = UDim2.new(0, 8, 0, 40)
scroll.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
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

local logText = ""
local function log(msg)
    logText = logText .. msg .. "\n"
    output.Text = logText
end

copyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(logText)
        bar.Text = "  Page Dive v6 — Copied!"
        task.delay(2, function() if bar then bar.Text = "  Page Dive v6 — Ready" end end)
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
            if count > 15 then table.insert(parts, "...+" .. (count) .. " more") break end
            table.insert(parts, tostring(k2) .. "=" .. safeStr(v2, depth + 1))
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    return typeof(v) .. ":" .. tostring(v)
end

local function runScan()
    logText = ""
    output.Text = ""
    bar.Text = "  Page Dive v6 — Scanning..."

    -- Find the pages module (runtime location)
    log("====== FINDING PAGES MODULE ======")
    local pagesModule = nil
    local pagesQueueModule = nil
    local usePageModule = nil

    -- Check PlayerScripts (runtime clone of StarterPlayer)
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

    -- Fallback: check StarterPlayer
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

    -- 1) pages store
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
                        if ok2 then
                            valStr = "fn() -> " .. safeStr(val)
                        else
                            valStr = "fn(err: " .. tostring(val):sub(1, 80) .. ")"
                        end
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

    -- 2) pages-queue
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

    -- 3) use-page
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

    -- 4) Also find charm module to see how atoms work
    log("\n====== CHARM LIB ======")
    local charmMod = nil
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

    -- 5) List ALL module scripts under app/common/store
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

    log("\n====== SCAN COMPLETE ======")
    bar.Text = "  Page Dive v6 — Done! Hit COPY"
end

rescanBtn.MouseButton1Click:Connect(function() runScan() end)
runScan()
