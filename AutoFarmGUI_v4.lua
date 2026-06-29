-- === Open Treasure Hunt Page ===

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
bar.Text = "  TH Opener — Running..."
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
        bar.Text = "  TH Opener — Copied!"
        task.delay(2, function() if bar then bar.Text = "  TH Opener — Ready" end end)
    end
end)

clearBtn.MouseButton1Click:Connect(function()
    logText = ""
    output.Text = "Cleared."
end)

-- Load modules
local pagesModule
for _, desc in pairs(game:GetService("StarterPlayer"):GetDescendants()) do
    if desc:IsA("ModuleScript") and desc.Name == "pages" and desc:GetFullName():find("app.common.store") then
        pagesModule = desc
        break
    end
end

local pages, openPage, togglePage, pageStore

if pagesModule then
    local ok, result = pcall(function() return require(pagesModule) end)
    if ok and typeof(result) == "table" then
        pages = result
        openPage = result.openPage
        togglePage = result.togglePage
        pageStore = result.pageStore
        log("Pages store loaded OK")
    else
        log("Failed to load pages: " .. tostring(result))
    end
else
    log("Pages module not found!")
end

-- Try different page ID formats
local function tryOpen(id)
    log("\nTrying openPage('" .. id .. "')...")
    local ok, err = pcall(function()
        openPage(id)
    end)
    if ok then
        log("  openPage OK!")
    else
        log("  Error: " .. tostring(err))
    end

    -- Check pageStore after
    if pageStore then
        local ok2, val = pcall(pageStore)
        if ok2 then
            log("  pageStore now: id=" .. tostring(val.id) .. " priority=" .. tostring(val.priority))
        end
    end
end

-- Auto-run: try common ID patterns
local function runAll()
    logText = ""
    output.Text = ""
    bar.Text = "  TH Opener — Trying..."

    if not openPage then
        log("No openPage function!")
        return
    end

    -- Try the most likely IDs
    local ids = {
        "treasure-hunt",
        "treasureHunt",
        "treasure_hunt",
        "TreasureHunt",
        "Treasure Hunt",
    }

    for _, id in pairs(ids) do
        tryOpen(id)
        -- If pageStore shows it worked, stop
        if pageStore then
            local ok, val = pcall(pageStore)
            if ok and val.id ~= "" then
                log("\nSUCCESS! Page opened with id: " .. val.id)
                bar.Text = "  TH Opener — Opened!"
                return
            end
        end
    end

    -- Also try togglePage
    log("\n\nTrying togglePage variants...")
    for _, id in pairs({"treasure-hunt", "treasureHunt"}) do
        log("togglePage('" .. id .. "')...")
        local ok, err = pcall(function() togglePage(id) end)
        if ok then
            log("  togglePage OK!")
            if pageStore then
                local ok2, val = pcall(pageStore)
                if ok2 then
                    log("  pageStore: id=" .. tostring(val.id))
                    if val.id ~= "" then
                        log("\nSUCCESS via toggle!")
                        bar.Text = "  TH Opener — Opened!"
                        return
                    end
                end
            end
        else
            log("  Error: " .. tostring(err))
        end
    end

    log("\nNone worked. Check output for clues.")
    bar.Text = "  TH Opener — Done. Hit COPY"
end

openBtn.MouseButton1Click:Connect(function() runAll() end)
runAll()
