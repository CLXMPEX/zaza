-- ============================================================
--  START INVASION SPY v2 — ON-SCREEN OUTPUT
--  No clipboard needed. Findings show in a scrollable box you can
--  READ directly (and screenshot or type back to me).
--
--  HOW TO USE:
--   1) Run this script. A panel appears.
--   2) Talk to Bald Hero -> Lead me -> get the "Start Invasion 1x"
--      popup on screen.
--   3) TAP the green "Start Invasion 1x" button with your finger.
--   4) Tap the yellow SCAN button.
--   5) READ the output box. Screenshot it, or type me the lines under
--      "FINGER" and "MATCH 'start invasion'".
--
--  The panel is draggable (drag the top bar) and you can SHRINK/GROW
--  the output box with the +/- buttons if it covers the game UI.
-- ============================================================

local player = game.Players.LocalPlayer
local pgui = player:WaitForChild("PlayerGui", 10)
local UIS = game:GetService("UserInputService")

local lines = {}             -- on-screen log (most recent first)
local maxLines = 200
local count = 0
local running = true

local outputLabel            -- forward declare

local function refresh()
    if outputLabel then
        outputLabel.Text = table.concat(lines, "\n")
    end
end

-- newest entries on TOP so you don't have to scroll to the bottom
local function add(s)
    table.insert(lines, 1, s)
    while #lines > maxLines do table.remove(lines) end
    refresh()
end

-- ---- helpers --------------------------------------------------

local function safeText(o)
    local t = ""
    pcall(function() t = o.Text end)
    return t or ""
end

local function connInfo(o)
    local a, c, d, ib = 0, 0, 0, 0
    pcall(function() a = #getconnections(o.Activated) end)
    pcall(function() c = #getconnections(o.MouseButton1Click) end)
    pcall(function() d = #getconnections(o.MouseButton1Down) end)
    pcall(function() ib = #getconnections(o.InputBegan) end)
    return string.format("Act=%d Click=%d Down=%d IB=%d", a, c, d, ib)
end

local function parentChain(o, depth)
    local s = ""
    local p = o.Parent
    for i = 1, (depth or 6) do
        if not p or p == game then break end
        s = s .. " < " .. p.Name .. "(" .. p.ClassName .. ")"
        p = p.Parent
    end
    return s
end

local function describe(o, tag)
    local okPos, pos = pcall(function() return o.AbsolutePosition end)
    local okSize, size = pcall(function() return o.AbsoluteSize end)
    local vis = "?"
    pcall(function() vis = tostring(o.Visible) end)
    local posStr = (okPos and pos) and (math.floor(pos.X) .. "," .. math.floor(pos.Y)) or "?"
    local sizeStr = (okSize and size) and (math.floor(size.X) .. "x" .. math.floor(size.Y)) or "?"

    add(tag .. " " .. o.ClassName .. " '" .. safeText(o) .. "' " .. posStr .. " " .. sizeStr .. " vis=" .. vis)
    add("   conns: " .. connInfo(o))
    add("   chain:" .. parentChain(o))
end

-- ---- 1) hook taps on every gui button ------------------------

task.spawn(function()
    local hooked = {}
    local function hookGui(obj)
        if hooked[obj] then return end
        if not obj:IsA("GuiButton") then return end
        local g = obj:FindFirstAncestorOfClass("ScreenGui")
        if g and g.Name == "StartInvasionSpy2" then return end
        hooked[obj] = true
        pcall(function()
            obj.Activated:Connect(function()
                if not running then return end
                count = count + 1
                describe(obj, "[TAP-Act #" .. count .. "]")
            end)
        end)
        pcall(function()
            obj.MouseButton1Click:Connect(function()
                if not running then return end
                count = count + 1
                describe(obj, "[TAP-Click #" .. count .. "]")
            end)
        end)
    end
    for _, d in ipairs(pgui:GetDescendants()) do pcall(function() hookGui(d) end) end
    pgui.DescendantAdded:Connect(function(d)
        task.wait(0.05); pcall(function() hookGui(d) end)
    end)
end)

-- ---- 2) what is under the finger -----------------------------

UIS.InputBegan:Connect(function(input)
    if not running then return end
    if input.UserInputType ~= Enum.UserInputType.Touch
    and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local pos = input.Position
    count = count + 1
    add("[FINGER #" .. count .. "] " .. math.floor(pos.X) .. "," .. math.floor(pos.Y))
    local guis = {}
    pcall(function() guis = pgui:GetGuiObjectsAtPosition(pos.X, pos.Y) end)
    if #guis == 0 then add("   (GetGuiObjectsAtPosition returned nothing)") end
    for i, gobj in ipairs(guis) do
        if i > 6 then break end
        local g = gobj:FindFirstAncestorOfClass("ScreenGui")
        if g and g.Name == "StartInvasionSpy2" then continue end
        add("   [" .. i .. "] " .. gobj.ClassName .. " '" .. safeText(gobj) .. "' " .. connInfo(gobj))
        add("       " .. gobj.Name .. parentChain(gobj, 4))
    end
end)

-- ---- 3) SCAN ------------------------------------------------

local function scanNow()
    add("===== SCAN START =====")
    local keywords = {"start invasion", "invasion", "yes"}
    for _, o in ipairs(pgui:GetDescendants()) do
        if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("ImageButton") then
            local g = o:FindFirstAncestorOfClass("ScreenGui")
            if g and g.Name == "StartInvasionSpy2" then continue end
            local low = string.lower(safeText(o))
            if low ~= "" then
                for _, kw in ipairs(keywords) do
                    if string.find(low, kw, 1, true) then
                        describe(o, "[MATCH '" .. kw .. "']")
                        break
                    end
                end
            end
        end
    end
    -- visible buttons with no text too
    local n = 0
    for _, o in ipairs(pgui:GetDescendants()) do
        if o:IsA("GuiButton") and o.Visible then
            local g = o:FindFirstAncestorOfClass("ScreenGui")
            if g and g.Name == "StartInvasionSpy2" then continue end
            local okS, size = pcall(function() return o.AbsoluteSize end)
            if okS and size and size.X > 30 and size.Y > 15 then
                n = n + 1
                if n <= 25 then describe(o, "[BTN " .. n .. "]") end
            end
        end
    end
    add("visible buttons: " .. n)
    add("===== SCAN END (read above) =====")
end

-- ---- GUI panel ----------------------------------------------

local sg = Instance.new("ScreenGui", pgui)
sg.Name = "StartInvasionSpy2"
sg.ResetOnSpawn = false
sg.DisplayOrder = 99999
sg.IgnoreGuiInset = true

local panel = Instance.new("Frame", sg)
panel.Size = UDim2.new(0, 360, 0, 320)
panel.Position = UDim2.new(0, 20, 0, 60)
panel.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
panel.BackgroundTransparency = 0.1
panel.BorderSizePixel = 0
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", panel)
stroke.Color = Color3.fromRGB(255, 210, 50); stroke.Thickness = 1

-- top bar (drag handle + buttons)
local top = Instance.new("Frame", panel)
top.Size = UDim2.new(1, 0, 0, 34)
top.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
top.BorderSizePixel = 0
Instance.new("UICorner", top).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel", top)
title.Size = UDim2.new(0, 90, 1, 0)
title.Position = UDim2.new(0, 8, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 210, 50)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "INV SPY"

local function mkBtn(txt, color, posX, w)
    local b = Instance.new("TextButton", top)
    b.Size = UDim2.new(0, w, 0, 24)
    b.Position = UDim2.new(0, posX, 0, 5)
    b.BackgroundColor3 = color
    b.Text = txt
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local scanBtn  = mkBtn("SCAN", Color3.fromRGB(230, 170, 40), 96, 56)
local clrBtn   = mkBtn("CLR",  Color3.fromRGB(90, 90, 110),  156, 42)
local minusBtn = mkBtn("-",    Color3.fromRGB(60, 90, 150),  202, 26)
local plusBtn  = mkBtn("+",    Color3.fromRGB(60, 90, 150),  232, 26)
local copyBtn  = mkBtn("COPY", Color3.fromRGB(70, 130, 210), 262, 46)
local stopBtn  = mkBtn("X",    Color3.fromRGB(200, 55, 55),  312, 26)

-- scrolling output
local scroll = Instance.new("ScrollingFrame", panel)
scroll.Size = UDim2.new(1, -8, 1, -40)
scroll.Position = UDim2.new(0, 4, 0, 37)
scroll.BackgroundColor3 = Color3.fromRGB(6, 6, 10)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 210, 50)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)

outputLabel = Instance.new("TextLabel", scroll)
outputLabel.Size = UDim2.new(1, -8, 0, 0)
outputLabel.Position = UDim2.new(0, 4, 0, 2)
outputLabel.AutomaticSize = Enum.AutomaticSize.Y
outputLabel.BackgroundTransparency = 1
outputLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
outputLabel.Font = Enum.Font.Code
outputLabel.TextSize = 11
outputLabel.TextXAlignment = Enum.TextXAlignment.Left
outputLabel.TextYAlignment = Enum.TextYAlignment.Top
outputLabel.TextWrapped = true
outputLabel.Text = ""

-- buttons behavior
scanBtn.MouseButton1Click:Connect(function()
    scanNow()
    scanBtn.Text = "DONE"; task.wait(0.7); scanBtn.Text = "SCAN"
end)
clrBtn.MouseButton1Click:Connect(function()
    lines = {}; refresh()
end)
copyBtn.MouseButton1Click:Connect(function()
    local out = table.concat(lines, "\n")
    local ok = pcall(function() setclipboard(out) end)
    copyBtn.Text = ok and "OK" or "FAIL"; task.wait(1); copyBtn.Text = "COPY"
end)
stopBtn.MouseButton1Click:Connect(function()
    running = false; sg:Destroy()
end)

local textSize = 11
minusBtn.MouseButton1Click:Connect(function()
    textSize = math.max(7, textSize - 1); outputLabel.TextSize = textSize
end)
plusBtn.MouseButton1Click:Connect(function()
    textSize = math.min(18, textSize + 1); outputLabel.TextSize = textSize
end)

-- drag the panel by the top bar
local dragging, dragStart, startPos = false, nil, nil
top.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = i.Position; startPos = panel.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
        local d = i.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- capability check up front
local vim = nil
pcall(function() vim = game:GetService("VirtualInputManager") end)
add("setclipboard=" .. tostring(setclipboard ~= nil)
    .. " getconns=" .. tostring(getconnections ~= nil)
    .. " VIM=" .. tostring(vim ~= nil))
if vim then
    local hasTouch = pcall(function() return vim.SendTouchEvent end)
    local hasMouse = pcall(function() return vim.SendMouseButtonEvent end)
    add("VIM.SendTouchEvent=" .. tostring(hasTouch) .. " VIM.SendMouseButtonEvent=" .. tostring(hasMouse))
end
add(">> Open Start Invasion popup, TAP green button, then tap SCAN. Read below.")
add("================================")
