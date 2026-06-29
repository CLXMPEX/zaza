-- === TH Auto Digger (Fixed) ===

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

-- === AUTO RUN ===
task.spawn(function()
    log("=== AUTO DIGGER ===\n")

    local RS = game:GetService("ReplicatedStorage")

    -- The remote name has a DOT in it: "treasureHunt.dig"
    log("[1] Finding remote...")
    local digRemote
    for _, desc in pairs(RS:GetDescendants()) do
        if desc.Name == "treasureHunt.dig" then
            digRemote = desc
            break
        end
    end

    if not digRemote then
        log("  FAILED")
        return
    end
    log("  Found: " .. digRemote.ClassName)

    -- Load player data
    log("\n[2] Loading data...")
    local atoms
    for _, desc in pairs(RS:GetDescendants()) do
        if desc:IsA("ModuleScript") and desc.Name == "atoms" and desc:GetFullName():find("common.store.atoms") then
            pcall(function() atoms = require(desc) end)
            break
        end
    end

    local dugTiles = {}
    local shovels = 0
    local currentTier = 0

    if atoms then
        local atomTable = atoms.atoms or atoms
        if atomTable.datastore and typeof(atomTable.datastore) == "function" then
            local ok, ds = pcall(atomTable.datastore)
            if ok and typeof(ds) == "table" then
                local pdata = ds[tostring(player.UserId)] or ds[player.UserId]
                if pdata then
                    if pdata.treasureHunt then
                        currentTier = pdata.treasureHunt.currentTier or 0
                        if pdata.treasureHunt.dug then
                            for _, tile in pairs(pdata.treasureHunt.dug) do
                                if tile.index then
                                    dugTiles[tile.index] = true
                                end
                            end
                        end
                    end
                    if pdata.items and pdata.items.Shovel then
                        shovels = pdata.items.Shovel.amount or 0
                    end
                end
            end
        end
    end

    local dugCount = 0
    for _ in pairs(dugTiles) do dugCount = dugCount + 1 end

    log("  Tier: " .. currentTier)
    log("  Shovels: " .. shovels)
    log("  Dug: " .. dugCount .. "/49")

    if shovels <= 0 then
        log("\n  NO SHOVELS!")
        return
    end

    -- Build list of undug tiles
    local undug = {}
    for i = 0, 48 do
        if not dugTiles[i] then
            table.insert(undug, i)
        end
    end
    log("  Undug tiles: " .. #undug)

    -- Test which argument format works
    log("\n[3] Testing formats...")
    local workingFormat = nil
    local firstTile = undug[1]

    local tests = {
        {"index", function(t) return digRemote:InvokeServer(t) end},
        {"{index}", function(t) return digRemote:InvokeServer({index = t}) end},
        {"{tile}", function(t) return digRemote:InvokeServer({tile = t}) end},
        {"tier,index", function(t) return digRemote:InvokeServer(currentTier, t) end},
        {"no args", function(t) return digRemote:InvokeServer() end},
    }

    for _, test in pairs(tests) do
        log("  " .. test[1] .. "(" .. firstTile .. ")...")
        local ok, result = pcall(function() return test[2](firstTile) end)
        log("    -> " .. (ok and safeStr(result) or "ERR: " .. tostring(result):sub(1, 60)))

        if ok and result ~= nil and result ~= false then
            workingFormat = test
            log("    WORKS!")
            table.remove(undug, 1)
            shovels = shovels - 1
            break
        end
        task.wait(0.3)
    end

    if not workingFormat then
        -- Also try 1-indexed
        log("\n  Trying 1-indexed...")
        local undug1 = {}
        for i = 1, 49 do
            if not dugTiles[i] then
                table.insert(undug1, i)
            end
        end

        local tile1 = undug1[1]
        for _, test in pairs(tests) do
            log("  " .. test[1] .. "(" .. tile1 .. ")...")
            local ok, result = pcall(function() return test[2](tile1) end)
            log("    -> " .. (ok and safeStr(result) or "ERR: " .. tostring(result):sub(1, 60)))

            if ok and result ~= nil and result ~= false then
                workingFormat = test
                undug = undug1
                table.remove(undug, 1)
                shovels = shovels - 1
                log("    WORKS (1-indexed)!")
                break
            end
            task.wait(0.3)
        end
    end

    if not workingFormat then
        log("\n  No format worked!")
        return
    end

    -- Dig all remaining
    log("\n[4] Digging all tiles...")
    local totalDug = 1

    for _, tileIdx in ipairs(undug) do
        if shovels <= 0 then
            log("  Out of shovels!")
            break
        end

        task.wait(0.3)
        local ok, result = pcall(function()
            return workingFormat[2](tileIdx)
        end)

        if ok then
            totalDug = totalDug + 1
            shovels = shovels - 1
            log("  Tile " .. tileIdx .. ": " .. safeStr(result))
        else
            log("  Tile " .. tileIdx .. " ERR: " .. tostring(result):sub(1, 50))
        end
    end

    log("\n=== DONE ===")
    log("Dug: " .. totalDug .. " tiles")
    log("Shovels left: " .. shovels)
end)
