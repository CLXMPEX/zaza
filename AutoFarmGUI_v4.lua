-- === TH Data Check + Open v3 ===

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
bar.Text = "  TH v3 — Running..."
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
        bar.Text = "  TH v3 — Copied!"
        task.delay(2, function() if bar then bar.Text = "  TH v3 — Ready" end end)
    end
end)

clearBtn.MouseButton1Click:Connect(function()
    logText = ""
    output.Text = "Cleared."
end)

local function safeStr(v, depth)
    depth = depth or 0
    if depth > 3 then return "..." end
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

-- Load modules
local pages, pagesQueue, atoms, charm, dialogue

for _, desc in pairs(game:GetService("StarterPlayer"):GetDescendants()) do
    if desc:IsA("ModuleScript") then
        local fp = desc:GetFullName()
        if desc.Name == "pages" and fp:find("app.common.store.pages$") then
            pcall(function() pages = require(desc) end)
        elseif desc.Name == "pages-queue" then
            pcall(function() pagesQueue = require(desc) end)
        elseif desc.Name == "dialogue" and fp:find("store") then
            pcall(function() dialogue = require(desc) end)
        end
    end
end

for _, desc in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
    if desc:IsA("ModuleScript") then
        if desc.Name == "atoms" and desc:GetFullName():find("common.store.atoms") then
            pcall(function() atoms = require(desc) end)
        elseif desc.Name == "charm" and not desc:GetFullName():find("sync") and not desc:GetFullName():find("payload") and not desc:GetFullName():find("vide") then
            pcall(function() charm = require(desc) end)
        end
    end
end

local function runScan()
    logText = ""
    output.Text = ""
    bar.Text = "  TH v3 — Scanning..."

    -- 1) Check datastore for treasure hunt data
    log("====== PLAYER DATASTORE ======")
    if atoms and typeof(atoms) == "table" then
        local atomTable = atoms.atoms or atoms
        if atomTable.datastore and typeof(atomTable.datastore) == "function" then
            local ok, ds = pcall(atomTable.datastore)
            if ok and typeof(ds) == "table" then
                local pid = tostring(player.UserId)
                local pdata = ds[pid] or ds[tonumber(pid)]
                if pdata then
                    log("Player data found. Scanning for TH keys...")
                    for k, v in pairs(pdata) do
                        local kl = tostring(k):lower()
                        if kl:find("treasure") or kl:find("hunt") or kl:find("dig") or kl:find("shovel") or kl:find("tile") then
                            log("  **" .. tostring(k) .. " = " .. safeStr(v) .. "**")
                        end
                    end
                    -- Also dump ALL keys for reference
                    log("\nAll datastore keys:")
                    for k, v in pairs(pdata) do
                        local vtype = typeof(v)
                        if typeof(v) == "table" then
                            local count = 0
                            for _ in pairs(v) do count = count + 1 end
                            vtype = "table(" .. count .. ")"
                        end
                        log("  " .. tostring(k) .. " = " .. vtype)
                    end
                else
                    log("No player data for userId " .. pid)
                    log("Available keys: " .. safeStr(ds))
                end
            end
        end
    end

    -- 2) Check dialogue store
    log("\n====== DIALOGUE STORE ======")
    if dialogue and typeof(dialogue) == "table" then
        for k, v in pairs(dialogue) do
            local valStr = typeof(v)
            if typeof(v) == "function" then
                local ok2, val = pcall(v)
                if ok2 then valStr = "fn() -> " .. safeStr(val) else valStr = "fn(err)" end
            end
            log("  " .. tostring(k) .. " = " .. valStr)
        end
    else
        log("Not loaded")
    end

    -- 3) Try openPage with just the string and watch what happens
    log("\n====== OPEN PAGE (string) + MONITOR ======")
    if pages then
        pcall(pages.closePage)
        task.wait(0.2)

        -- Watch the atom
        log("Before: " .. safeStr(pcall(pages.pageStore) and select(2, pcall(pages.pageStore)) or "err"))

        local ok, err = pcall(function()
            pages.openPage("treasure-hunt")
        end)
        log("openPage('treasure-hunt'): " .. (ok and "OK" or tostring(err)))

        task.wait(0.1)
        local ok2, val = pcall(pages.pageStore)
        log("After 0.1s: " .. (ok2 and safeStr(val) or "err"))

        task.wait(0.5)
        local ok3, val2 = pcall(pages.pageStore)
        log("After 0.5s: " .. (ok3 and safeStr(val2) or "err"))
    end

    -- 4) Try queuePage
    log("\n====== QUEUE PAGE ======")
    if pagesQueue then
        pcall(pages.closePage)
        task.wait(0.2)

        for _, id in pairs({"treasure-hunt", "treasureHunt"}) do
            log("\nqueuePage('" .. id .. "')...")
            local ok, err = pcall(function()
                pagesQueue.queuePage(id)
            end)
            log("  Result: " .. (ok and "OK" or tostring(err):sub(1, 80)))
            task.wait(0.3)

            local ok2, val = pcall(pages.pageStore)
            log("  Store: " .. (ok2 and safeStr(val) or "err"))

            local ok3, q = pcall(pagesQueue.queuedPages)
            log("  Queue: " .. (ok3 and safeStr(q) or "err"))
        end
    end

    -- 5) Check GUI tree after page is "open"
    log("\n====== GUI AFTER OPEN ======")
    pcall(pages.closePage)
    task.wait(0.1)
    pcall(function() pages.openPage("treasure-hunt") end)
    task.wait(0.5)

    local appGui = pgui:FindFirstChild("app")
    if appGui then
        local idx = 0
        for _, child in pairs(appGui:GetChildren()) do
            if child:IsA("Frame") then
                idx = idx + 1
                if not child.Visible then continue end
                local descs = #child:GetDescendants()
                if descs > 5 then
                    -- Check if any descendant text mentions treasure
                    for _, d in pairs(child:GetDescendants()) do
                        if d:IsA("TextLabel") or d:IsA("TextButton") then
                            local txt = d.Text:lower()
                            if txt:find("treasure") or txt:find("hunt") or txt:find("dig") or txt:find("tier") or txt:find("shovel") then
                                log("Frame#" .. idx .. " has text: " .. d.Text:sub(1, 50))
                            end
                        end
                    end
                end
            end
        end
    end

    log("\n====== DONE ======")
    bar.Text = "  TH v3 — Done! Hit COPY"
end

openBtn.MouseButton1Click:Connect(function() runScan() end)
runScan()
