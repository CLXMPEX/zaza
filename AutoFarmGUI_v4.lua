-- ============================================================
--  POSITION FINDER  (standalone)
--  Shows your character's live position. Use it to grab exact
--  coordinates inside the raid (or anywhere).
--
--  HOW TO USE:
--   1) Run it. A small box shows your live X, Y, Z.
--   2) Walk to the spot you want, tap GRAB to freeze that reading.
--   3) Tap COPY to copy the CFrame.new(...) line to send me.
-- ============================================================

local Players = game:GetService("Players")
local player  = Players.LocalPlayer
local pgui    = player:WaitForChild("PlayerGui", 10)

local function getHRP()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- ---------- GUI ----------
local sg = Instance.new("ScreenGui")
sg.Name = "PositionFinder"
sg.ResetOnSpawn = false
sg.DisplayOrder = 99999
sg.IgnoreGuiInset = true
sg.Parent = pgui

local box = Instance.new("Frame", sg)
box.Size = UDim2.new(0, 300, 0, 150)
box.Position = UDim2.new(0, 16, 0, 70)
box.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
box.BackgroundTransparency = 0.06
box.BorderSizePixel = 0
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
local strk = Instance.new("UIStroke", box)
strk.Color = Color3.fromRGB(90, 200, 255); strk.Thickness = 1

local title = Instance.new("TextLabel", box)
title.Size = UDim2.new(1, -12, 0, 18)
title.Position = UDim2.new(0, 8, 0, 4)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(120, 200, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "POSITION FINDER"

-- live position
local liveLbl = Instance.new("TextLabel", box)
liveLbl.Size = UDim2.new(1, -16, 0, 22)
liveLbl.Position = UDim2.new(0, 8, 0, 26)
liveLbl.BackgroundTransparency = 1
liveLbl.TextColor3 = Color3.fromRGB(230, 235, 245)
liveLbl.Font = Enum.Font.Code
liveLbl.TextSize = 13
liveLbl.TextXAlignment = Enum.TextXAlignment.Left
liveLbl.Text = "live: ..."

-- grabbed position
local grabLbl = Instance.new("TextLabel", box)
grabLbl.Size = UDim2.new(1, -16, 0, 40)
grabLbl.Position = UDim2.new(0, 8, 0, 50)
grabLbl.BackgroundTransparency = 1
grabLbl.TextColor3 = Color3.fromRGB(120, 230, 140)
grabLbl.Font = Enum.Font.Code
grabLbl.TextSize = 12
grabLbl.TextXAlignment = Enum.TextXAlignment.Left
grabLbl.TextYAlignment = Enum.TextYAlignment.Top
grabLbl.TextWrapped = true
grabLbl.Text = "grabbed: (none yet — tap GRAB)"

local grabbedText = ""

local function mkBtn(txt, color, xOff, w)
    local b = Instance.new("TextButton", box)
    b.Size = UDim2.new(0, w, 0, 28)
    b.Position = UDim2.new(0, xOff, 1, -34)
    b.BackgroundColor3 = color
    b.Text = txt
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local grabBtn  = mkBtn("GRAB",  Color3.fromRGB(60, 180, 100), 8,   80)
local copyBtn  = mkBtn("COPY",  Color3.fromRGB(70, 130, 210), 96,  80)
local closeBtn = mkBtn("CLOSE", Color3.fromRGB(200, 55, 55),  184, 80)

grabBtn.MouseButton1Click:Connect(function()
    local hrp = getHRP()
    if not hrp then
        grabLbl.Text = "grabbed: no character found"
        return
    end
    local p = hrp.Position
    grabbedText = string.format("CFrame.new(%.1f, %.1f, %.1f)", p.X, p.Y, p.Z)
    grabLbl.Text = "grabbed:\n" .. grabbedText
    grabBtn.Text = "GRABBED"
    task.wait(0.7)
    grabBtn.Text = "GRAB"
end)

copyBtn.MouseButton1Click:Connect(function()
    local hrp = getHRP()
    -- copy the grabbed one if you grabbed, otherwise the current live one
    local out = grabbedText
    if out == "" and hrp then
        local p = hrp.Position
        out = string.format("CFrame.new(%.1f, %.1f, %.1f)", p.X, p.Y, p.Z)
    end
    if out == "" then
        copyBtn.Text = "NO POS"
        task.wait(1); copyBtn.Text = "COPY"
        return
    end
    local clip = setclipboard or toclipboard or set_clipboard or (syn and syn.write_clipboard)
    local ok = clip and pcall(function() clip(out) end)
    copyBtn.Text = ok and "COPIED!" or "NO CLIP"
    task.wait(1.2); copyBtn.Text = "COPY"
end)

closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

-- live updater
task.spawn(function()
    while sg.Parent do
        local hrp = getHRP()
        if hrp then
            local p = hrp.Position
            liveLbl.Text = string.format("live: %.1f, %.1f, %.1f", p.X, p.Y, p.Z)
        else
            liveLbl.Text = "live: (no character)"
        end
        task.wait(0.2)
    end
end)
