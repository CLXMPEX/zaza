-- ============================================================
--  AIMBOT + ESP  (players)
--   * FOV circle at your crosshair — aimbot locks the camera onto
--     the closest player INSIDE the circle.
--   * Adjustable circle size (slider in GUI).
--   * ESP: a box around every player.
--   * GUI toggles: Aimbot, ESP, FOV Circle, and the size slider.
-- ============================================================

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local Workspace   = game:GetService("Workspace")

local LP     = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local pgui   = LP:WaitForChild("PlayerGui", 10)

-- ============================================================
--  SETTINGS (persist across re-exec)
-- ============================================================
getgenv().AimState = getgenv().AimState or {}
local S = getgenv().AimState
local defaults = {
    aimbot      = false,
    esp         = false,
    showFov     = true,
    fovRadius   = 120,       -- circle radius in pixels
    teamCheck   = false,     -- if true, ignore same-team players
    smoothness  = 0.35,      -- 0 = instant snap, 1 = very slow
    aimPart     = "Head",    -- Head or HumanoidRootPart
    guiVisible  = true,
}
for k, v in pairs(defaults) do if S[k] == nil then S[k] = v end end
S.guiVisible = true

-- ============================================================
--  HELPERS
-- ============================================================
local function getChar(plr)
    local c = plr.Character
    if not c then return nil end
    return c
end
local function alive(plr)
    local c = getChar(plr)
    if not c then return false end
    local hum = c:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end
local function getPart(plr, partName)
    local c = getChar(plr)
    if not c then return nil end
    return c:FindFirstChild(partName) or c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Head")
end
local function isEnemy(plr)
    if plr == LP then return false end
    if S.teamCheck and plr.Team == LP.Team and plr.Team ~= nil then return false end
    return true
end

-- distance from screen center-ish (the crosshair = viewport center)
local function screenCenter()
    local vp = Camera.ViewportSize
    return Vector2.new(vp.X / 2, vp.Y / 2)
end

-- find closest player whose on-screen position is inside the FOV circle
local function getTarget()
    local center = screenCenter()
    local best, bestDist = nil, S.fovRadius
    for _, plr in ipairs(Players:GetPlayers()) do
        if isEnemy(plr) and alive(plr) then
            local part = getPart(plr, S.aimPart)
            if part then
                local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < bestDist then
                        best, bestDist = plr, d
                    end
                end
            end
        end
    end
    return best
end

-- ============================================================
--  FOV CIRCLE  (drawn with a Frame ring)
-- ============================================================
local fovGui = Instance.new("ScreenGui")
fovGui.Name = "AimFOV"; fovGui.ResetOnSpawn = false; fovGui.DisplayOrder = 9997
fovGui.IgnoreGuiInset = true; fovGui.Parent = pgui

local fovCircle = Instance.new("Frame", fovGui)
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.BorderSizePixel = 0
local fovStroke = Instance.new("UIStroke", fovCircle)
fovStroke.Color = Color3.fromRGB(255, 255, 255)
fovStroke.Thickness = 1.5
fovStroke.Transparency = 0.3
local fovCorner = Instance.new("UICorner", fovCircle)
fovCorner.CornerRadius = UDim.new(1, 0)

local function updateFovCircle()
    local center = screenCenter()
    local r = S.fovRadius
    fovCircle.Size = UDim2.new(0, r * 2, 0, r * 2)
    fovCircle.Position = UDim2.new(0, center.X, 0, center.Y)
    fovCircle.Visible = S.showFov
end

-- ============================================================
--  ESP  (a box per player, updated each frame)
-- ============================================================
local espGui = Instance.new("ScreenGui")
espGui.Name = "AimESP"; espGui.ResetOnSpawn = false; espGui.DisplayOrder = 9996
espGui.IgnoreGuiInset = true; espGui.Parent = pgui

local espBoxes = {}   -- [player] = {box=Frame, name=TextLabel}

local function makeBox()
    local box = Instance.new("Frame", espGui)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    local st = Instance.new("UIStroke", box)
    st.Color = Color3.fromRGB(255, 60, 90); st.Thickness = 1.5
    local nm = Instance.new("TextLabel", box)
    nm.Size = UDim2.new(1, 0, 0, 14); nm.Position = UDim2.new(0, 0, 0, -16)
    nm.BackgroundTransparency = 1; nm.TextColor3 = Color3.fromRGB(255, 255, 255)
    nm.Font = Enum.Font.GothamBold; nm.TextSize = 12
    nm.TextStrokeTransparency = 0.4
    return { box = box, name = nm, stroke = st }
end

local function clearBox(plr)
    local e = espBoxes[plr]
    if e then e.box:Destroy(); espBoxes[plr] = nil end
end

local function updateESP()
    if not S.esp then
        for plr in pairs(espBoxes) do clearBox(plr) end
        return
    end
    -- update / create boxes for valid players
    local seen = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if isEnemy(plr) and alive(plr) then
            local hrp = getPart(plr, "HumanoidRootPart")
            local head = getPart(plr, "Head")
            if hrp then
                local topPos = (head and head.Position or hrp.Position) + Vector3.new(0, 2, 0)
                local botPos = hrp.Position - Vector3.new(0, 3, 0)
                local topS, onTop = Camera:WorldToViewportPoint(topPos)
                local botS = Camera:WorldToViewportPoint(botPos)
                if onTop and topS.Z > 0 then
                    seen[plr] = true
                    local e = espBoxes[plr]
                    if not e then e = makeBox(); espBoxes[plr] = e end
                    local h = math.abs(botS.Y - topS.Y)
                    local w = h * 0.55
                    e.box.Size = UDim2.new(0, w, 0, h)
                    e.box.Position = UDim2.new(0, (topS.X + botS.X)/2 - w/2, 0, math.min(topS.Y, botS.Y))
                    e.box.Visible = true
                    e.name.Text = plr.Name
                    e.name.Visible = true
                end
            end
        end
    end
    -- remove boxes for players no longer valid/visible
    for plr in pairs(espBoxes) do
        if not seen[plr] then clearBox(plr) end
    end
end

-- ============================================================
--  AIMBOT  (lock camera to target's aim part)
-- ============================================================
local locked = nil
local function doAimbot()
    if not S.aimbot then locked = nil; return end
    -- (re)acquire the closest target inside the circle each frame
    locked = getTarget()
    if not locked then return end
    local part = getPart(locked, S.aimPart)
    if not part then return end

    local targetCF = CFrame.new(Camera.CFrame.Position, part.Position)
    if S.smoothness <= 0 then
        Camera.CFrame = targetCF
    else
        -- smooth interpolate toward the target
        Camera.CFrame = Camera.CFrame:Lerp(targetCF, 1 - S.smoothness)
    end
end

-- ============================================================
--  MAIN RENDER LOOP
-- ============================================================
RunService.RenderStepped:Connect(function()
    pcall(updateFovCircle)
    pcall(updateESP)
    pcall(doAimbot)
end)

Players.PlayerRemoving:Connect(function(plr) clearBox(plr) end)

print("[AIM] aimbot + esp loaded")

-- ============================================================
--  GUI  (toggles + FOV slider, draggable)
-- ============================================================
local oldGui = pgui:FindFirstChild("AimGUI")
if oldGui then oldGui:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = "AimGUI"; sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.IgnoreGuiInset = true; sg.DisplayOrder = 9999; sg.Parent = pgui

local C = {
    bg = Color3.fromRGB(18,18,24), card = Color3.fromRGB(30,30,42),
    border = Color3.fromRGB(48,48,66), text = Color3.fromRGB(225,225,235),
    textDim = Color3.fromRGB(110,110,135), textMid = Color3.fromRGB(160,160,180),
    red = Color3.fromRGB(255,60,90), green = Color3.fromRGB(50,205,110),
    blue = Color3.fromRGB(80,160,255), toggleOff = Color3.fromRGB(50,50,65),
}

local floatBtn = Instance.new("TextButton", sg)
floatBtn.Size = UDim2.new(0,44,0,44); floatBtn.Position = UDim2.new(0,8,0.35,0)
floatBtn.BackgroundColor3 = C.red; floatBtn.Text = "AIM"
floatBtn.TextColor3 = Color3.new(1,1,1); floatBtn.TextSize = 13
floatBtn.Font = Enum.Font.GothamBold; floatBtn.BorderSizePixel = 0; floatBtn.ZIndex = 100
Instance.new("UICorner", floatBtn).CornerRadius = UDim.new(0,12)

local mainFrame = Instance.new("Frame", sg)
mainFrame.Size = UDim2.new(0,250,0,290); mainFrame.Position = UDim2.new(0.5,-125,0.5,-145)
mainFrame.BackgroundColor3 = C.bg; mainFrame.BorderSizePixel = 0; mainFrame.ZIndex = 50
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,14)
local mStroke = Instance.new("UIStroke", mainFrame); mStroke.Color = C.red; mStroke.Thickness = 1; mStroke.Transparency = 0.4
mainFrame.Visible = S.guiVisible

local titleBar = Instance.new("Frame", mainFrame)
titleBar.Size = UDim2.new(1,0,0,38); titleBar.BackgroundColor3 = Color3.fromRGB(28,16,20)
titleBar.BorderSizePixel = 0; titleBar.ZIndex = 51
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0,14)
local tt = Instance.new("TextLabel", titleBar)
tt.Size = UDim2.new(0,180,1,0); tt.Position = UDim2.new(0,12,0,0)
tt.BackgroundTransparency = 1; tt.Text = "Aimbot + ESP"; tt.TextColor3 = C.red
tt.TextSize = 14; tt.Font = Enum.Font.GothamBold
tt.TextXAlignment = Enum.TextXAlignment.Left; tt.ZIndex = 52
local closeB = Instance.new("TextButton", titleBar)
closeB.Size = UDim2.new(0,26,0,26); closeB.Position = UDim2.new(1,-32,0,6)
closeB.BackgroundColor3 = Color3.fromRGB(60,30,40); closeB.Text = "X"
closeB.TextColor3 = C.red; closeB.TextSize = 12; closeB.Font = Enum.Font.GothamBold
closeB.BorderSizePixel = 0; closeB.ZIndex = 54
Instance.new("UICorner", closeB).CornerRadius = UDim.new(0,8)
closeB.MouseButton1Click:Connect(function() S.guiVisible = false; mainFrame.Visible = false end)
floatBtn.MouseButton1Click:Connect(function()
    S.guiVisible = not S.guiVisible; mainFrame.Visible = S.guiVisible
end)

-- drag
local dragB = Instance.new("TextButton", titleBar)
dragB.Size = UDim2.new(1,-40,1,0); dragB.BackgroundTransparency = 1; dragB.Text = ""; dragB.ZIndex = 52
local mDrag = { on = false }
dragB.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        mDrag.on = true; mDrag.s = i.Position; mDrag.p = mainFrame.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if mDrag.on and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
        local d = i.Position - mDrag.s
        mainFrame.Position = UDim2.new(mDrag.p.X.Scale, mDrag.p.X.Offset+d.X, mDrag.p.Y.Scale, mDrag.p.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        mDrag.on = false
    end
end)

local body = Instance.new("Frame", mainFrame)
body.Size = UDim2.new(1,-16,1,-46); body.Position = UDim2.new(0,8,0,42)
body.BackgroundTransparency = 1; body.ZIndex = 51
local lay = Instance.new("UIListLayout", body); lay.Padding = UDim.new(0,6)

local function tog(label, key, color)
    local h = Instance.new("Frame", body)
    h.Size = UDim2.new(1,0,0,34); h.BackgroundColor3 = C.card; h.BorderSizePixel = 0; h.ZIndex = 51
    Instance.new("UICorner", h).CornerRadius = UDim.new(0,8)
    local hs = Instance.new("UIStroke", h); hs.Color = C.border; hs.Transparency = 0.6
    local l = Instance.new("TextLabel", h)
    l.Size = UDim2.new(1,-54,1,0); l.Position = UDim2.new(0,10,0,0)
    l.BackgroundTransparency = 1; l.Text = label; l.TextColor3 = C.textMid
    l.TextSize = 12; l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left; l.ZIndex = 52
    local tr = Instance.new("Frame", h)
    tr.Size = UDim2.new(0,38,0,22); tr.Position = UDim2.new(1,-46,0.5,-11)
    tr.BackgroundColor3 = C.toggleOff; tr.BorderSizePixel = 0; tr.ZIndex = 52
    Instance.new("UICorner", tr).CornerRadius = UDim.new(1,0)
    local kn = Instance.new("Frame", tr)
    kn.Size = UDim2.new(0,18,0,18); kn.Position = UDim2.new(0,2,0,2)
    kn.BackgroundColor3 = Color3.fromRGB(120,120,135); kn.BorderSizePixel = 0; kn.ZIndex = 53
    Instance.new("UICorner", kn).CornerRadius = UDim.new(1,0)
    local b = Instance.new("TextButton", h)
    b.Size = UDim2.new(1,0,1,0); b.BackgroundTransparency = 1; b.Text = ""; b.ZIndex = 54
    local function upd()
        local on = S[key]
        tr.BackgroundColor3 = on and color or C.toggleOff
        kn.Position = on and UDim2.new(0,18,0,2) or UDim2.new(0,2,0,2)
        kn.BackgroundColor3 = on and Color3.new(1,1,1) or Color3.fromRGB(120,120,135)
        l.TextColor3 = on and C.text or C.textMid
        hs.Color = on and color or C.border
    end
    b.MouseButton1Click:Connect(function() S[key] = not S[key]; upd() end)
    upd()
end

-- FOV slider
local function slider(label, key, minV, maxV)
    local h = Instance.new("Frame", body)
    h.Size = UDim2.new(1,0,0,48); h.BackgroundColor3 = C.card; h.BorderSizePixel = 0; h.ZIndex = 51
    Instance.new("UICorner", h).CornerRadius = UDim.new(0,8)
    local hs = Instance.new("UIStroke", h); hs.Color = C.border; hs.Transparency = 0.6
    local l = Instance.new("TextLabel", h)
    l.Size = UDim2.new(1,-14,0,14); l.Position = UDim2.new(0,10,0,4)
    l.BackgroundTransparency = 1; l.TextColor3 = C.textDim
    l.TextSize = 10; l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left; l.ZIndex = 52
    local track = Instance.new("Frame", h)
    track.Size = UDim2.new(1,-20,0,6); track.Position = UDim2.new(0,10,0,30)
    track.BackgroundColor3 = C.toggleOff; track.BorderSizePixel = 0; track.ZIndex = 52
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)
    local fill = Instance.new("Frame", track)
    fill.BackgroundColor3 = C.blue; fill.BorderSizePixel = 0; fill.ZIndex = 53
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0,14,0,14); knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.BackgroundColor3 = Color3.new(1,1,1); knob.BorderSizePixel = 0; knob.ZIndex = 54
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
    local function redraw()
        local pct = (S[key]-minV)/(maxV-minV)
        pct = math.clamp(pct, 0, 1)
        fill.Size = UDim2.new(pct,0,1,0)
        knob.Position = UDim2.new(pct,0,0.5,0)
        l.Text = label .. ": " .. math.floor(S[key])
    end
    local hit = Instance.new("TextButton", track)
    hit.Size = UDim2.new(1,0,3,0); hit.Position = UDim2.new(0,0,-1,0)
    hit.BackgroundTransparency = 1; hit.Text = ""; hit.ZIndex = 55
    local dragging = false
    local function setFromX(px)
        local rel = math.clamp((px - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0, 1)
        S[key] = minV + rel*(maxV-minV)
        redraw()
    end
    hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; setFromX(i.Position.X)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
            setFromX(i.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    redraw()
end

tog("Aimbot", "aimbot", C.red)
tog("ESP boxes", "esp", C.green)
tog("Show FOV circle", "showFov", C.blue)
tog("Team check", "teamCheck", C.textMid)
slider("FOV circle size", "fovRadius", 40, 400)

print("=========================================")
print("  Aimbot + ESP loaded")
print("  Toggle in the AIM panel")
print("=========================================")
