-- ============================================================
--  ESCORT PROBE  (input-safe: no hooks, no metatable, no input conns)
--
--  Finds what we need to auto-start the Elf Mage escort:
--   1) the escort "create/start" remote (flat dotted name)
--   2) your Holy Key counts per tier (T1..T5) from the data store
--   3) any escort config so we learn the exact start argument
--
--  Reads only. Does not touch your taps/chat/screen.
--  Tap SCAN, then COPY (or screenshot) and send to Claude.
-- ============================================================

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local player  = Players.LocalPlayer
local pgui    = player:WaitForChild("PlayerGui", 10)

local lines = {}
local outLabel
local function render() if outLabel then outLabel.Text = table.concat(lines, "\n") end end
local function log(s) lines[#lines+1] = s; render() end
local function clear() lines = {}; render() end

local function short(v, d)
    d = d or 0
    local t = typeof(v)
    if t == "string" then return (#v > 46 and v:sub(1,46).."~" or v) end
    if t == "number" or t == "boolean" then return tostring(v) end
    if t == "table" then
        if d > 2 then return "{...}" end
        local p, n = {}, 0
        for k, vv in pairs(v) do
            n = n + 1
            if n > 20 then p[#p+1]="..."; break end
            p[#p+1] = tostring(k).."="..short(vv, d+1)
        end
        return "{"..table.concat(p, ", ").."}"
    end
    return t
end

-- remo container (dotted-name remotes)
local remoBase
pcall(function()
    remoBase = RS:WaitForChild("rbxts_include",5):WaitForChild("node_modules",5)
        :WaitForChild("@rbxts",5):WaitForChild("remo",5):WaitForChild("src",5)
        :WaitForChild("container",5)
end)

local function scan()
    clear()
    log("===== ESCORT PROBE =====")

    -- 1) escort-ish remotes
    log("== remotes matching escort/journey/mission/key ==")
    local words = {"escort","journey","mission","holykey","holy","key"}
    local hits = 0
    if remoBase then
        for _, d in ipairs(remoBase:GetDescendants()) do
            if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
                local nm = string.lower(d.Name)
                for _, w in ipairs(words) do
                    if string.find(nm, w, 1, true) then
                        hits = hits + 1
                        log("  "..(d:IsA("RemoteFunction") and "RF" or "RE").."  "..d.Name)
                        break
                    end
                end
            end
        end
    else
        log("  (remo container not found)")
    end
    if hits == 0 then
        log("  none matched — dumping ALL '*.create' / '*.start' remotes:")
        if remoBase then
            for _, d in ipairs(remoBase:GetDescendants()) do
                if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
                    local nm = string.lower(d.Name)
                    if string.find(nm,"create",1,true) or string.find(nm,"start",1,true) then
                        log("    "..d.Name)
                    end
                end
            end
        end
    end

    -- 2) Holy Key inventory from atoms datastore
    log("")
    log("== Holy Key inventory (T1..T5) ==")
    local atoms
    for _, d in ipairs(RS:GetDescendants()) do
        if d:IsA("ModuleScript") and d.Name == "atoms"
           and d:GetFullName():find("common.store.atoms") then
            pcall(function() atoms = require(d) end); break
        end
    end
    if atoms then
        local atomTable = atoms.atoms or atoms
        local ok, ds = pcall(function() return atomTable.datastore() end)
        if ok and typeof(ds) == "table" then
            local pdata = ds[tostring(player.UserId)] or ds[player.UserId]
            if pdata and pdata.items then
                local found = 0
                for itemName, itemData in pairs(pdata.items) do
                    local low = string.lower(itemName)
                    if string.find(low,"key",1,true) or string.find(low,"holy",1,true) then
                        found = found + 1
                        local amt = (typeof(itemData)=="table" and itemData.amount) or itemData
                        log("  "..itemName.." = "..tostring(amt))
                    end
                end
                if found == 0 then
                    log("  no key-named items. All item names:")
                    local n = 0
                    for itemName, itemData in pairs(pdata.items) do
                        n = n + 1
                        if n <= 40 then
                            local amt = (typeof(itemData)=="table" and itemData.amount) or itemData
                            log("    "..itemName.." = "..tostring(amt))
                        end
                    end
                end
            else
                log("  no items table in player data")
            end
        else
            log("  datastore() call failed")
        end
    else
        log("  atoms module not found")
    end

    -- 3) escort config modules (to learn start arg shape)
    log("")
    log("== escort config modules ==")
    local cfgN = 0
    for _, d in ipairs(RS:GetDescendants()) do
        if d:IsA("ModuleScript") then
            local nm = string.lower(d.Name)
            if string.find(nm,"escort",1,true) or string.find(nm,"journey",1,true)
               or string.find(nm,"key",1,true) then
                cfgN = cfgN + 1
                if cfgN <= 6 then
                    local ok, m = pcall(require, d)
                    log("  MODULE "..d.Name..(ok and "" or " (require failed)"))
                    if ok and typeof(m) == "table" then
                        local kk = 0
                        for k, v in pairs(m) do
                            kk = kk + 1
                            if kk <= 12 then log("     "..tostring(k).." = "..short(v)) end
                        end
                    end
                end
            end
        end
    end
    if cfgN == 0 then log("  none found") end

    log("")
    log("===== END — COPY/screenshot to Claude =====")
end

-- GUI (no input conns / hooks / drag)
local nm = "EscortProbe"
local old = pgui:FindFirstChild(nm)
if old then old:Destroy() end
local sg = Instance.new("ScreenGui")
sg.Name = nm; sg.ResetOnSpawn = false; sg.DisplayOrder = 99999
sg.IgnoreGuiInset = true; sg.Parent = pgui

local panel = Instance.new("Frame", sg)
panel.Size = UDim2.new(0, 400, 0, 380); panel.Position = UDim2.new(0, 12, 0, 60)
panel.BackgroundColor3 = Color3.fromRGB(16, 18, 22); panel.BorderSizePixel = 0
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
local strk = Instance.new("UIStroke", panel)
strk.Color = Color3.fromRGB(120, 200, 255); strk.Thickness = 1

local title = Instance.new("TextLabel", panel)
title.Size = UDim2.new(1, -12, 0, 26); title.Position = UDim2.new(0, 10, 0, 6)
title.BackgroundTransparency = 1; title.TextColor3 = Color3.fromRGB(130, 205, 255)
title.Font = Enum.Font.GothamBold; title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left; title.Text = "ESCORT PROBE (safe)"

local function mkBtn(txt, color, x, w)
    local b = Instance.new("TextButton", panel)
    b.Size = UDim2.new(0, w, 0, 30); b.Position = UDim2.new(0, x, 0, 34)
    b.BackgroundColor3 = color; b.Text = txt; b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold; b.TextSize = 12; b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end
local scanBtn  = mkBtn("SCAN",  Color3.fromRGB(60, 170, 110), 10,  110)
local copyBtn  = mkBtn("COPY",  Color3.fromRGB(70, 130, 210), 128, 110)
local closeBtn = mkBtn("CLOSE", Color3.fromRGB(200, 55, 55),  246, 120)

local scroll = Instance.new("ScrollingFrame", panel)
scroll.Size = UDim2.new(1, -12, 1, -76); scroll.Position = UDim2.new(0, 6, 0, 70)
scroll.BackgroundColor3 = Color3.fromRGB(8, 10, 12); scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6; scroll.ScrollBarImageColor3 = Color3.fromRGB(120, 200, 255)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)

outLabel = Instance.new("TextLabel", scroll)
outLabel.Size = UDim2.new(1, -10, 0, 0); outLabel.Position = UDim2.new(0, 5, 0, 3)
outLabel.AutomaticSize = Enum.AutomaticSize.Y; outLabel.BackgroundTransparency = 1
outLabel.TextColor3 = Color3.fromRGB(225, 230, 215); outLabel.Font = Enum.Font.Code
outLabel.TextSize = 11; outLabel.TextXAlignment = Enum.TextXAlignment.Left
outLabel.TextYAlignment = Enum.TextYAlignment.Top; outLabel.TextWrapped = true
outLabel.Text = ""

scanBtn.MouseButton1Click:Connect(function()
    scanBtn.Text = "..."
    task.spawn(function() pcall(scan); scanBtn.Text = "SCAN" end)
end)
copyBtn.MouseButton1Click:Connect(function()
    local text = table.concat(lines, "\n")
    local clip = setclipboard or toclipboard or set_clipboard or (syn and syn.write_clipboard)
    local ok = clip and pcall(function() clip(text) end)
    copyBtn.Text = ok and "COPIED!" or "NO CLIP"
    task.wait(1.2); copyBtn.Text = "COPY"
end)
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

task.spawn(function() pcall(scan) end)
