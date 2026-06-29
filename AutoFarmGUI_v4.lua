-- === TH Auto-Digger ===

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
bar.Text = "  TH Digger — Ready"
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
local digBtn = makeBtn("DIG!", Color3.fromRGB(200, 120, 0))

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
        bar.Text = "  TH Digger — Copied!"
        task.delay(2, function() if bar then bar.Text = "  TH Digger — Ready" end end)
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
local thContent, atoms, digRemote

for _, desc in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
    if desc:IsA("ModuleScript") and desc.Name == "treasure-hunt" and desc:GetFullName():find("content") then
        pcall(function() thContent = require(desc) end)
    end
    if desc:IsA("ModuleScript") and desc.Name == "atoms" and desc:GetFullName():find("common.store.atoms") then
        pcall(function() atoms = require(desc) end)
    end
    if desc:IsA("RemoteFunction") and desc.Name == "dig" and desc:GetFullName():find("treasureHunt") then
        digRemote = desc
    end
end

-- Initial info dump
local function showInfo()
    logText = ""
    output.Text = ""

    log("====== TREASURE HUNT INFO ======")

    if thContent then
        log("Grid size: " .. tostring(thContent.TREASURE_HUNT_GRID))
        log("Tile count: " .. tostring(thContent.TREASURE_HUNT_TILE_COUNT))
        log("Shovel ID: " .. tostring(thContent.TREASURE_HUNT_SHOVEL_ID))
        log("Tiers: " .. safeStr(thContent.TREASURE_HUNT_TIERS))
    else
        log("ERROR: treasure-hunt content not loaded")
    end

    if digRemote then
        log("\nDig remote: " .. digRemote:GetFullName())
    else
        log("\nERROR: dig remote not found!")
    end

    -- Get player datastore for revealed tiles
    log("\n====== YOUR TREASURE HUNT STATE ======")
    if atoms then
        local atomTable = atoms.atoms or atoms
        if atomTable.datastore and typeof(atomTable.datastore) == "function" then
            local ok, ds = pcall(atomTable.datastore)
            if ok and typeof(ds) == "table" then
                local pdata = ds[tostring(player.UserId)] or ds[player.UserId]
                if pdata then
                    for k, v in pairs(pdata) do
                        local kl = tostring(k):lower()
                        if kl:find("treasure") or kl:find("hunt") or kl:find("dig") or kl:find("shovel") or kl:find("tile") then
                            log("  " .. tostring(k) .. " = " .. safeStr(v))
                        end
                    end

                    -- Check for shovels in inventory
                    if thContent and thContent.TREASURE_HUNT_SHOVEL_ID then
                        local items = pdata.items or pdata.inventory
                        if items and typeof(items) == "table" then
                            for id, item in pairs(items) do
                                if tostring(id):find(thContent.TREASURE_HUNT_SHOVEL_ID) or (typeof(item) == "table" and tostring(item.id or ""):find("shovel")) then
                                    log("  SHOVEL FOUND: " .. tostring(id) .. " = " .. safeStr(item))
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Try getRevealedTiles
    if thContent and thContent.getRevealedTiles then
        log("\n====== REVEALED TILES ======")
        local ok, revealed = pcall(function()
            -- It might need the player data
            if atoms then
                local atomTable = atoms.atoms or atoms
                local ok2, ds = pcall(atomTable.datastore)
                if ok2 then
                    local pdata = ds[tostring(player.UserId)] or ds[player.UserId]
                    if pdata then
                        return thContent.getRevealedTiles(pdata)
                    end
                end
            end
            return thContent.getRevealedTiles()
        end)
        if ok then
            log("Revealed: " .. safeStr(revealed))
        else
            log("Error: " .. tostring(revealed):sub(1, 80))
        end
    end

    log("\n====== READY ======")
    log("Press DIG! to dig one random undug tile")
    bar.Text = "  TH Digger — Ready"
end

-- Dig function
local function doDig()
    if not digRemote then
        log("\nERROR: No dig remote!")
        return
    end

    bar.Text = "  TH Digger — Digging..."

    -- Try multiple argument formats
    local grid = thContent and thContent.TREASURE_HUNT_GRID or 7
    local totalTiles = grid * grid

    log("\n====== ATTEMPTING DIG ======")

    -- Try 1: just a tile index (0-based)
    for tile = 0, totalTiles - 1 do
        log("Trying tile index: " .. tile)
        local ok, result = pcall(function()
            return digRemote:InvokeServer(tile)
        end)
        if ok then
            log("  Result: " .. safeStr(result))
            if result ~= nil and result ~= false then
                log("  SUCCESS! Tile " .. tile .. " dug!")
                bar.Text = "  TH Digger — Dug tile " .. tile .. "!"
                return
            end
        else
            log("  Error: " .. tostring(result):sub(1, 60))
            -- If first attempt errors, try other formats
            if tile == 0 then
                -- Try 1-based index
                log("\nTrying 1-based index: 1")
                local ok2, r2 = pcall(function() return digRemote:InvokeServer(1) end)
                log("  Result: " .. (ok2 and safeStr(r2) or tostring(r2):sub(1, 60)))

                -- Try row, column
                log("Trying row,col: 1,1")
                local ok3, r3 = pcall(function() return digRemote:InvokeServer(1, 1) end)
                log("  Result: " .. (ok3 and safeStr(r3) or tostring(r3):sub(1, 60)))

                -- Try row, column 0-based
                log("Trying row,col: 0,0")
                local ok4, r4 = pcall(function() return digRemote:InvokeServer(0, 0) end)
                log("  Result: " .. (ok4 and safeStr(r4) or tostring(r4):sub(1, 60)))

                -- Try table arg
                log("Trying table: {tile=1}")
                local ok5, r5 = pcall(function() return digRemote:InvokeServer({tile = 1}) end)
                log("  Result: " .. (ok5 and safeStr(r5) or tostring(r5):sub(1, 60)))

                log("Trying table: {row=1, column=1}")
                local ok6, r6 = pcall(function() return digRemote:InvokeServer({row = 1, column = 1}) end)
                log("  Result: " .. (ok6 and safeStr(r6) or tostring(r6):sub(1, 60)))
            end
            break
        end
    end

    bar.Text = "  TH Digger — Done! Hit COPY"
end

digBtn.MouseButton1Click:Connect(function() doDig() end)
showInfo()
