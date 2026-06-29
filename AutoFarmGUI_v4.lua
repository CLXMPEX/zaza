-- === TH Auto Digger v2 (Fixed) ===

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

task.spawn(function()
    log("=== AUTO DIGGER v2 ===\n")

    local RS = game:GetService("ReplicatedStorage")

    -- Find remote (name has dot in it)
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
    log("  Found!")

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

    -- Build undug list (1-indexed, 1 to 49)
    local undug = {}
    for i = 1, 49 do
        if not dugTiles[i] then
            table.insert(undug, i)
        end
    end

    log("  Tier: " .. currentTier)
    log("  Shovels: " .. shovels)
    log("  Dug: " .. dugCount .. "/49")
    log("  Undug: " .. #undug .. " tiles")

    if shovels <= 0 then
        log("\n  NO SHOVELS!")
        return
    end

    -- Dig all undug tiles
    log("\n[3] Digging...\n")
    local totalDug = 0
    local shovelsLeft = shovels

    for _, tileIdx in ipairs(undug) do
        if shovelsLeft <= 0 then
            log("\n  Out of shovels!")
            break
        end

        local ok, result = pcall(function()
            return digRemote:InvokeServer(tileIdx)
        end)

        if ok and typeof(result) == "table" then
            -- Check if server rejected it
            if result.reason then
                log("  Tile " .. tileIdx .. ": SKIP (" .. tostring(result.reason) .. ")")
            elseif result.revealed then
                -- Successful dig
                totalDug = totalDug + 1

                -- Get reward info from response
                local rewardStr = ""
                if result.revealed then
                    for _, rev in pairs(result.revealed) do
                        if rev.reward then
                            rewardStr = tostring(rev.reward.id or "") .. " x" .. tostring(rev.reward.amount or "")
                        end
                    end
                end

                -- Use server's shovel count
                if result.shovels then
                    shovelsLeft = result.shovels
                else
                    shovelsLeft = shovelsLeft - 1
                end

                local tierStr = ""
                if result.tierComplete then
                    tierStr = " [TIER COMPLETE!]"
                end

                log("  Tile " .. tileIdx .. ": " .. rewardStr .. " (shovels: " .. shovelsLeft .. ")" .. tierStr)
            else
                log("  Tile " .. tileIdx .. ": " .. safeStr(result))
            end
        elseif not ok then
            log("  Tile " .. tileIdx .. " ERR: " .. tostring(result):sub(1, 50))
        end

        task.wait(0.3)
    end

    log("\n=== DONE ===")
    log("Dug: " .. totalDug .. " tiles")
    log("Shovels left: " .. shovelsLeft)
end)
