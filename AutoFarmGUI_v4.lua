-- === TH Auto Digger v3 (Always On) ===

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

local statusBtn = Instance.new("TextButton")
statusBtn.Size = UDim2.new(0, 150, 0, 30)
statusBtn.Position = UDim2.new(0.5, -75, 0, 58)
statusBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
statusBtn.Text = "Starting..."
statusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
statusBtn.TextSize = 12
statusBtn.Font = Enum.Font.GothamBold
statusBtn.BorderSizePixel = 0
statusBtn.ZIndex = 100
statusBtn.Active = false
statusBtn.Parent = sg
Instance.new("UICorner", statusBtn).CornerRadius = UDim.new(0, 8)

local win = Instance.new("Frame")
win.Size = UDim2.new(0, 280, 0, 220)
win.Position = UDim2.new(0, 10, 0, 95)
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
    -- Keep log from getting too huge
    if #logText > 8000 then
        logText = logText:sub(#logText - 6000)
    end
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

task.spawn(function()
    log("=== AUTO DIGGER v3 (Always On) ===\n")

    local RS = game:GetService("ReplicatedStorage")

    -- Find remote
    log("[1] Finding remote...")
    local digRemote
    for _, desc in pairs(RS:GetDescendants()) do
        if desc.Name == "treasureHunt.dig" then
            digRemote = desc
            break
        end
    end

    if not digRemote then
        log("  FAILED - no remote")
        statusBtn.Text = "FAILED"
        statusBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        return
    end
    log("  Found!")

    -- Load atoms once
    local atoms
    for _, desc in pairs(RS:GetDescendants()) do
        if desc:IsA("ModuleScript") and desc.Name == "atoms" and desc:GetFullName():find("common.store.atoms") then
            pcall(function() atoms = require(desc) end)
            break
        end
    end

    if not atoms then
        log("  FAILED - no atoms")
        statusBtn.Text = "FAILED"
        statusBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        return
    end

    local function getData()
        local atomTable = atoms.atoms or atoms
        if not atomTable.datastore or typeof(atomTable.datastore) ~= "function" then return nil end
        local ok, ds = pcall(atomTable.datastore)
        if not ok or typeof(ds) ~= "table" then return nil end
        return ds[tostring(player.UserId)] or ds[player.UserId]
    end

    local totalDugSession = 0

    log("\n[2] Monitoring for shovels...\n")

    -- Main loop - runs forever
    while sg.Parent do
        local pdata = getData()
        if not pdata then
            task.wait(3)
            continue
        end

        -- Get current shovels
        local shovels = 0
        if pdata.items and pdata.items.Shovel then
            shovels = pdata.items.Shovel.amount or 0
        end

        -- Get dug tiles
        local dugTiles = {}
        local currentTier = 0
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

        local dugCount = 0
        for _ in pairs(dugTiles) do dugCount = dugCount + 1 end

        if shovels > 0 then
            -- Build undug list
            local undug = {}
            for i = 1, 49 do
                if not dugTiles[i] then
                    table.insert(undug, i)
                end
            end

            if #undug == 0 then
                statusBtn.Text = "Tier " .. currentTier .. " complete!"
                statusBtn.BackgroundColor3 = Color3.fromRGB(200, 160, 0)
                task.wait(5)
                continue
            end

            log("Shovels: " .. shovels .. " | Undug: " .. #undug)
            statusBtn.Text = "DIGGING... " .. shovels .. " shovels"
            statusBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 0)

            -- Dig all available
            for _, tileIdx in ipairs(undug) do
                if not sg.Parent then return end

                -- Re-check shovels from live data
                local freshData = getData()
                local freshShovels = 0
                if freshData and freshData.items and freshData.items.Shovel then
                    freshShovels = freshData.items.Shovel.amount or 0
                end

                if freshShovels <= 0 then
                    log("  Out of shovels, waiting...")
                    break
                end

                local ok, result = pcall(function()
                    return digRemote:InvokeServer(tileIdx)
                end)

                if ok and typeof(result) == "table" then
                    if result.reason then
                        log("  Tile " .. tileIdx .. ": SKIP (" .. tostring(result.reason) .. ")")
                    elseif result.revealed then
                        totalDugSession = totalDugSession + 1

                        local rewardStr = ""
                        if result.revealed then
                            for _, rev in pairs(result.revealed) do
                                if rev.reward then
                                    rewardStr = tostring(rev.reward.id or "") .. " x" .. tostring(rev.reward.amount or "")
                                end
                            end
                        end

                        local sLeft = result.shovels or "?"
                        local tierStr = result.tierComplete and " [TIER DONE!]" or ""

                        log("  Tile " .. tileIdx .. ": " .. rewardStr .. " (left: " .. tostring(sLeft) .. ")" .. tierStr)
                        statusBtn.Text = "Dug " .. totalDugSession .. " | " .. rewardStr
                    else
                        log("  Tile " .. tileIdx .. ": " .. safeStr(result))
                    end
                elseif not ok then
                    log("  Tile " .. tileIdx .. " ERR: " .. tostring(result):sub(1, 50))
                end

                task.wait(0.3)
            end

            log("  Batch done. Waiting for more shovels...\n")
        end

        -- Idle - check every 3 seconds for new shovels
        statusBtn.Text = "Waiting... (dug " .. totalDugSession .. " total)"
        statusBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        task.wait(3)
    end
end)
