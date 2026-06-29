-- === TH Full Auto Digger ===

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
bar.Text = "  Auto Digger — Starting..."
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
    b.Size = UDim2.new(0, 135, 0, 28)
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
        bar.Text = "  Auto Digger — Copied!"
        task.delay(2, function() if bar then bar.Text = "  Auto Digger — Done" end end)
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
            if count > 15 then table.insert(parts, "...") break end
            table.insert(parts, tostring(k2) .. "=" .. safeStr(v2, depth + 1))
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    return typeof(v) .. ":" .. tostring(v)
end

-- ====== AUTO RUN ======
task.spawn(function()
    log("=== TREASURE HUNT AUTO DIGGER ===\n")

    -- 1) Find dig remote by walking the path directly
    log("[1] Finding dig remote...")
    local digRemote
    local RS = game:GetService("ReplicatedStorage")

    -- Walk the known path
    local path = RS
        :FindFirstChild("rbxts_include")
    if path then path = path:FindFirstChild("node_modules") end
    if path then path = path:FindFirstChild("@rbxts") end
    if path then path = path:FindFirstChild("remo") end
    if path then path = path:FindFirstChild("src") end
    if path then path = path:FindFirstChild("container") end
    if path then path = path:FindFirstChild("treasureHunt") end
    if path then digRemote = path:FindFirstChild("dig") end

    -- Fallback: brute search
    if not digRemote then
        log("  Path walk failed, brute searching...")
        for _, desc in pairs(RS:GetDescendants()) do
            if (desc:IsA("RemoteFunction") or desc:IsA("RemoteEvent")) and desc:GetFullName():find("treasureHunt") and desc:GetFullName():find("dig") then
                digRemote = desc
                break
            end
        end
    end

    if not digRemote then
        log("  ERROR: Could not find dig remote!")
        log("  Dumping treasureHunt folder contents...")
        local thFolder
        for _, desc in pairs(RS:GetDescendants()) do
            if desc.Name == "treasureHunt" then
                thFolder = desc
                break
            end
        end
        if thFolder then
            for _, child in pairs(thFolder:GetChildren()) do
                log("    " .. child.Name .. " | " .. child.ClassName)
            end
        end
        bar.Text = "  Auto Digger — FAILED"
        return
    end

    log("  Found: " .. digRemote:GetFullName())
    log("  Type: " .. digRemote.ClassName)

    -- 2) Load atoms for player data
    log("\n[2] Loading player data...")
    local atoms
    for _, desc in pairs(RS:GetDescendants()) do
        if desc:IsA("ModuleScript") and desc.Name == "atoms" and desc:GetFullName():find("common.store.atoms") then
            pcall(function() atoms = require(desc) end)
            break
        end
    end

    local function getPlayerData()
        if not atoms then return nil end
        local atomTable = atoms.atoms or atoms
        if not atomTable.datastore then return nil end
        local ok, ds = pcall(atomTable.datastore)
        if not ok then return nil end
        return ds[tostring(player.UserId)] or ds[player.UserId]
    end

    local pdata = getPlayerData()
    if not pdata then
        log("  ERROR: Could not load player data")
        bar.Text = "  Auto Digger — FAILED"
        return
    end

    -- 3) Get treasure hunt state
    local thData = pdata.treasureHunt
    if not thData then
        log("  No treasure hunt data found")
        bar.Text = "  Auto Digger — No TH data"
        return
    end

    local shovels = 0
    if pdata.items and pdata.items.Shovel then
        shovels = pdata.items.Shovel.amount or 0
    end

    local dugTiles = {}
    if thData.dug then
        for _, tile in pairs(thData.dug) do
            if tile.index then
                dugTiles[tile.index] = true
            end
        end
    end

    local dugCount = 0
    for _ in pairs(dugTiles) do dugCount = dugCount + 1 end

    log("  Tier: " .. tostring(thData.currentTier))
    log("  Shovels: " .. shovels)
    log("  Already dug: " .. dugCount .. " tiles")
    log("  Dug indices: " .. safeStr(dugTiles))

    if shovels <= 0 then
        log("\n  NO SHOVELS! Can't dig.")
        bar.Text = "  Auto Digger — No shovels"
        return
    end

    -- 4) Find undug tiles
    local undug = {}
    for i = 0, 48 do -- 7x7 = 49 tiles, 0-indexed
        if not dugTiles[i] then
            table.insert(undug, i)
        end
    end

    -- Also try 1-indexed
    local undug1 = {}
    for i = 1, 49 do
        if not dugTiles[i] then
            table.insert(undug1, i)
        end
    end

    log("  Undug (0-idx): " .. #undug .. " tiles")
    log("  Undug (1-idx): " .. #undug1 .. " tiles")

    -- 5) Start digging
    log("\n[3] Starting auto-dig...\n")

    local digsLeft = shovels
    local totalDug = 0

    -- Figure out the right argument format by testing
    log("Testing argument format...")

    -- Try tile index 0-based first
    local testTile = undug[1]
    local ok1, r1 = pcall(function() return digRemote:InvokeServer(testTile) end)
    log("  InvokeServer(" .. testTile .. "): " .. (ok1 and safeStr(r1) or "ERR: " .. tostring(r1):sub(1, 60)))

    if ok1 and r1 ~= nil and r1 ~= false then
        log("  Format: single index (0-based) WORKS!")
        totalDug = totalDug + 1
        digsLeft = digsLeft - 1
        table.remove(undug, 1)

        -- Dig remaining
        for i, tile in ipairs(undug) do
            if digsLeft <= 0 then break end
            bar.Text = "  Digging tile " .. tile .. " (" .. digsLeft .. " left)"
            task.wait(0.3)

            local ok, result = pcall(function() return digRemote:InvokeServer(tile) end)
            if ok then
                log("  Tile " .. tile .. ": " .. safeStr(result))
                totalDug = totalDug + 1
                digsLeft = digsLeft - 1
            else
                log("  Tile " .. tile .. " ERROR: " .. tostring(result):sub(1, 50))
                break
            end
        end
    else
        -- Try 1-based
        testTile = undug1[1]
        local ok2, r2 = pcall(function() return digRemote:InvokeServer(testTile) end)
        log("  InvokeServer(" .. testTile .. "): " .. (ok2 and safeStr(r2) or "ERR: " .. tostring(r2):sub(1, 60)))

        if ok2 and r2 ~= nil and r2 ~= false then
            log("  Format: single index (1-based) WORKS!")
            totalDug = totalDug + 1
            digsLeft = digsLeft - 1
            table.remove(undug1, 1)

            for i, tile in ipairs(undug1) do
                if digsLeft <= 0 then break end
                bar.Text = "  Digging tile " .. tile .. " (" .. digsLeft .. " left)"
                task.wait(0.3)

                local ok, result = pcall(function() return digRemote:InvokeServer(tile) end)
                if ok then
                    log("  Tile " .. tile .. ": " .. safeStr(result))
                    totalDug = totalDug + 1
                    digsLeft = digsLeft - 1
                else
                    log("  Tile " .. tile .. " ERROR: " .. tostring(result):sub(1, 50))
                    break
                end
            end
        else
            -- Try other formats
            log("\n  Trying other formats...")
            local formats = {
                {"row,col 0-based", function() return digRemote:InvokeServer(0, 0) end},
                {"row,col 1-based", function() return digRemote:InvokeServer(1, 1) end},
                {"{tile=0}", function() return digRemote:InvokeServer({tile = 0}) end},
                {"{index=0}", function() return digRemote:InvokeServer({index = 0}) end},
                {"{row=0,col=0}", function() return digRemote:InvokeServer({row = 0, column = 0}) end},
                {"no args", function() return digRemote:InvokeServer() end},
                {"tier + tile", function() return digRemote:InvokeServer(thData.currentTier, 0) end},
            }

            for _, fmt in pairs(formats) do
                local ok, result = pcall(fmt[2])
                log("  " .. fmt[1] .. ": " .. (ok and safeStr(result) or "ERR: " .. tostring(result):sub(1, 50)))
                if ok and result ~= nil and result ~= false then
                    log("  THIS FORMAT WORKS! ^^")
                    break
                end
                task.wait(0.2)
            end
        end
    end

    log("\n=== DONE ===")
    log("Total dug this session: " .. totalDug)
    log("Shovels remaining: " .. digsLeft)
    bar.Text = "  Auto Digger — Done! " .. totalDug .. " dug"
end)
