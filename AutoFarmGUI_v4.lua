-- BUTTON SPY — captures every tap + remotes
-- Do the full flow: E -> Lead me -> Start Invasion -> Yes -> Copy

local player = game.Players.LocalPlayer
local pgui = player:WaitForChild("PlayerGui", 10)
local UIS = game:GetService("UserInputService")
local result = "=== BUTTON SPY ===\n"
local count = 0
local running = true

-- Remote hook (skip weapon spam)
pcall(function()
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        local ret = old(self, ...)
        if running then
            local ok, method = pcall(getnamecallmethod)
            if ok and (method == "FireServer" or method == "InvokeServer") then
                if typeof(self) == "Instance" and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
                    local path = self:GetFullName()
                    if string.find(path, "weapons.activate") then return ret end
                    if string.find(path, "syncNotification") then return ret end
                    if string.find(path, "stream.retrieve") then return ret end
                    count = count + 1
                    local args = {...}
                    local line = "\n[REMOTE " .. count .. "] " .. method .. " -> " .. path .. "\n"
                    for i, arg in ipairs(args) do
                        if typeof(arg) == "table" then
                            line = line .. "  arg" .. i .. " = {"
                            for k, v in pairs(arg) do line = line .. tostring(k) .. "=" .. tostring(v) .. ", " end
                            line = line .. "}\n"
                        else
                            line = line .. "  arg" .. i .. " = " .. tostring(arg) .. " (" .. typeof(arg) .. ")\n"
                        end
                    end
                    result = result .. line
                end
            end
        end
        return ret
    end)
    result = result .. "Remote hook: OK\n"
end)

-- Hook EVERY GuiObject for input — catches BillboardGui, dialogue, app, everything
task.spawn(function()
    local hooked = {}
    local function hookGui(obj)
        if hooked[obj] then return end
        if obj:IsA("GuiButton") or obj:IsA("TextLabel") or obj:IsA("Frame") or obj:IsA("ImageLabel") then
            -- Skip our own spy GUI
            local sg = obj:FindFirstAncestorOfClass("ScreenGui") or obj:FindFirstAncestorOfClass("BillboardGui")
            if sg and sg.Name == "ButtonSpy" then return end
            
            hooked[obj] = true
            
            -- Hook Activated (for TextButtons/ImageButtons)
            if obj:IsA("GuiButton") then
                local conns = {}
                pcall(function() conns = getconnections(obj.Activated) end)
                if #conns > 0 then
                    obj.Activated:Connect(function()
                        if not running then return end
                        count = count + 1
                        result = result .. "\n[TAP " .. count .. "] " .. obj.ClassName .. " Activated"
                        result = result .. "\n  Text: '" .. (obj.Text or "") .. "'"
                        result = result .. "\n  Path: " .. obj:GetFullName()
                        result = result .. "\n  Conns: " .. #conns .. " existing"
                        -- Show parent chain
                        local p = obj.Parent
                        for d = 1, 4 do
                            if not p then break end
                            result = result .. "\n  ^ " .. p.Name .. "(" .. p.ClassName .. ")"
                            p = p.Parent
                        end
                        result = result .. "\n"
                    end)
                end
            end
        end
    end
    
    -- Hook everything in PlayerGui (including BillboardGuis)
    for _, desc in ipairs(pgui:GetDescendants()) do
        pcall(function() hookGui(desc) end)
    end
    pgui.DescendantAdded:Connect(function(desc)
        task.wait(0.1)
        pcall(function() hookGui(desc) end)
    end)
end)

-- Also track touch position to find what's under finger
UIS.InputBegan:Connect(function(input)
    if not running then return end
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        local pos = input.Position
        -- Find all gui objects at this position
        local guis = pgui:GetGuiObjectsAtPosition(pos.X, pos.Y)
        if #guis > 0 then
            count = count + 1
            result = result .. "\n[TOUCH " .. count .. "] at " .. math.floor(pos.X) .. "," .. math.floor(pos.Y) .. "\n"
            for i, g in ipairs(guis) do
                if i > 5 then break end -- limit to top 5
                local sg = g:FindFirstAncestorOfClass("ScreenGui") or g:FindFirstAncestorOfClass("BillboardGui")
                if sg and sg.Name == "ButtonSpy" then continue end
                local txt = ""
                pcall(function() txt = g.Text end)
                result = result .. "  [" .. i .. "] " .. g.ClassName .. " '" .. txt .. "' -> " .. g:GetFullName() .. "\n"
                -- Check connections
                local clickC, actC, ibC = 0, 0, 0
                pcall(function() clickC = #getconnections(g.MouseButton1Click) end)
                pcall(function() actC = #getconnections(g.Activated) end)
                pcall(function() ibC = #getconnections(g.InputBegan) end)
                if clickC + actC + ibC > 0 then
                    result = result .. "    Click=" .. clickC .. " Act=" .. actC .. " IB=" .. ibC .. "\n"
                end
            end
        end
    end
end)

-- GUI
local sg = Instance.new("ScreenGui", pgui)
sg.Name = "ButtonSpy"; sg.ResetOnSpawn = false; sg.DisplayOrder = 999

local bar = Instance.new("Frame", sg)
bar.Size = UDim2.new(0.6, 0, 0, 36)
bar.Position = UDim2.new(0.2, 0, 0.01, 0)
bar.BackgroundColor3 = Color3.fromRGB(20, 20, 25); bar.BorderSizePixel = 0
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 10)

local status = Instance.new("TextLabel", bar)
status.Size = UDim2.new(0.5, 0, 1, 0); status.Position = UDim2.new(0, 8, 0, 0)
status.BackgroundTransparency = 1; status.TextColor3 = Color3.fromRGB(255, 210, 50)
status.TextSize = 11; status.Font = Enum.Font.GothamBold
status.TextXAlignment = Enum.TextXAlignment.Left; status.Text = "BTN SPY: 0"

local copyBtn = Instance.new("TextButton", bar)
copyBtn.Size = UDim2.new(0.22, 0, 0, 26); copyBtn.Position = UDim2.new(0.52, 0, 0, 5)
copyBtn.BackgroundColor3 = Color3.fromRGB(85, 145, 215)
copyBtn.Text = "Copy"; copyBtn.TextColor3 = Color3.new(1,1,1)
copyBtn.TextSize = 11; copyBtn.Font = Enum.Font.GothamBold; copyBtn.BorderSizePixel = 0
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 6)

local stopBtn = Instance.new("TextButton", bar)
stopBtn.Size = UDim2.new(0.22, 0, 0, 26); stopBtn.Position = UDim2.new(0.76, 0, 0, 5)
stopBtn.BackgroundColor3 = Color3.fromRGB(200, 55, 55)
stopBtn.Text = "Stop"; stopBtn.TextColor3 = Color3.new(1,1,1)
stopBtn.TextSize = 11; stopBtn.Font = Enum.Font.GothamBold; stopBtn.BorderSizePixel = 0
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 6)

copyBtn.MouseButton1Click:Connect(function()
    setclipboard(result .. "\nTotal: " .. count)
    copyBtn.Text = "Copied!"; task.wait(1); copyBtn.Text = "Copy"
end)
stopBtn.MouseButton1Click:Connect(function()
    running = false; sg:Destroy()
end)
task.spawn(function()
    while running do task.wait(0.5); status.Text = "BTN SPY: " .. count end
end)

result = result .. "\nDo: Press E -> Lead me -> Start Invasion -> Yes -> Copy\n"
