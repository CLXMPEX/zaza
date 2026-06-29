-- === TH Opener v2 (Compact) ===

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
bar.Text = "  TH v2 — Running..."
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
local openBtn = makeBtn("OPEN TH", Color3.fromRGB(200, 120, 0))

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
        bar.Text = "  TH v2 — Copied!"
        task.delay(2, function() if bar then bar.Text = "  TH v2 — Ready" end end)
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
            if count > 20 then table.insert(parts, "...") break end
            table.insert(parts, tostring(k2) .. "=" .. safeStr(v2, depth + 1))
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    return typeof(v) .. ":" .. tostring(v)
end

-- Load pages store
local pages
for _, desc in pairs(game:GetService("StarterPlayer"):GetDescendants()) do
    if desc:IsA("ModuleScript") and desc.Name == "pages" and desc:GetFullName():find("app.common.store.pages") then
        local ok, r = pcall(function() return require(desc) end)
        if ok then pages = r end
        break
    end
end

-- Load charm
local charm
for _, desc in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
    if desc:IsA("ModuleScript") and desc.Name == "charm" and not desc:GetFullName():find("sync") and not desc:GetFullName():find("payload") and not desc:GetFullName():find("vide") then
        local ok, r = pcall(function() return require(desc) end)
        if ok then charm = r end
        break
    end
end

local function runScan()
    logText = ""
    output.Text = ""
    bar.Text = "  TH v2 — Scanning..."

    -- 1) Look at the treasure-hunt component to find the page ID it registers
    log("====== TH COMPONENT MODULE ======")
    local thComp
    for _, desc in pairs(game:GetService("StarterPlayer"):GetDescendants()) do
        if desc:IsA("ModuleScript") and desc.Name == "treasure-hunt" and desc:GetFullName():find("pages") then
            thComp = desc
            break
        end
    end
    if thComp then
        log("Found: " .. thComp:GetFullName())
        local ok, result = pcall(function() return require(thComp) end)
        if ok then
            log("Type: " .. typeof(result))
            if typeof(result) == "table" then
                for k, v in pairs(result) do
                    log("  " .. tostring(k) .. " = " .. typeof(v))
                    if typeof(v) == "string" then
                        log("    -> " .. v)
                    end
                end
            end
        else
            log("Require err: " .. tostring(result):sub(1, 100))
        end
    end

    -- 2) Look at the pages.lua component that registers all pages
    log("\n====== PAGES COMPONENT (router) ======")
    local pagesComp
    for _, desc in pairs(game:GetService("StarterPlayer"):GetDescendants()) do
        if desc:IsA("ModuleScript") and desc.Name == "pages" and desc:GetFullName():find("components.pages.pages") then
            pagesComp = desc
            break
        end
    end
    if pagesComp then
        log("Found: " .. pagesComp:GetFullName())
        local ok, result = pcall(function() return require(pagesComp) end)
        if ok then
            log("Type: " .. typeof(result))
            if typeof(result) == "table" then
                for k, v in pairs(result) do
                    log("  " .. tostring(k) .. " = " .. typeof(v))
                    if typeof(v) == "table" then
                        log("    " .. safeStr(v))
                    end
                end
            end
        else
            log("Require err: " .. tostring(result):sub(1, 100))
        end
    end

    -- 3) Try openPage with TABLE arguments
    log("\n====== TRYING TABLE ARGS ======")
    if pages and pages.openPage then
        -- Close any open page first
        pcall(pages.closePage)
        task.wait(0.1)

        local formats = {
            {id = "treasure-hunt"},
            {id = "treasure-hunt", priority = 0, canManuallyClose = true, source = ""},
            {id = "treasure-hunt", priority = 1, canManuallyClose = true, source = "dialogue"},
            {id = "treasure-hunt", priority = 0, canManuallyClose = true, source = "npc"},
        }

        for i, args in pairs(formats) do
            pcall(pages.closePage)
            task.wait(0.1)
            log("\nTry #" .. i .. ": " .. safeStr(args))
            local ok, err = pcall(function()
                pages.openPage(args)
            end)
            log("  Result: " .. (ok and "OK" or tostring(err):sub(1, 80)))

            if pages.pageStore then
                local ok2, val = pcall(pages.pageStore)
                if ok2 then
                    log("  Store: " .. safeStr(val))
                end
            end
            task.wait(0.3)
        end

        -- 4) Also try setting the atom directly with Charm
        log("\n====== DIRECT ATOM SET ======")
        if charm and pages.pageStore then
            log("Trying direct atom set...")
            pcall(pages.closePage)
            task.wait(0.1)

            local ok, err = pcall(function()
                pages.pageStore({
                    id = "treasure-hunt",
                    priority = 0,
                    canManuallyClose = true,
                    source = ""
                })
            end)
            log("Direct set: " .. (ok and "OK" or tostring(err):sub(1, 80)))

            task.wait(0.3)
            local ok2, val = pcall(pages.pageStore)
            if ok2 then log("Store now: " .. safeStr(val)) end
        end
    else
        log("No pages store loaded!")
    end

    log("\n====== DONE ======")
    bar.Text = "  TH v2 — Done! Hit COPY"
end

openBtn.MouseButton1Click:Connect(function() runScan() end)
runScan()
