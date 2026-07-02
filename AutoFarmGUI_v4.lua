-- ============================================================
--  SUNSHINE LAKE AUTO FARM  (v12)  — Sunshine Lake ONLY
--  Features:
--   * Instant raid start via the bossRaids.create remote
--     (no teleport, no raid page).
--   * v5 auto-attack (swing + teleport-onto-enemy, no-walk fix).
--   * Auto-restart a fresh raid after each victory.
--   * Webhook on raid completion (with drops + run #).
--   * Auto dig (treasure hunt) with its own log window.
--   * Auto equip weapon (reads equipped state, no spam).
--  No invasion code anywhere.
-- ============================================================

local Players           = game:GetService("Players")
local UIS               = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local HttpService       = game:GetService("HttpService")

local player = Players.LocalPlayer
local pgui   = player:WaitForChild("PlayerGui", 10)

local RAID_Y_MIN = 5000
local HIT_RANGE  = 700   -- only attack enemies within this many studs

-- ============================================================
--  REMOTES  (flat dotted names — confirmed by diagnostics)
-- ============================================================
local remoBase
do
    local ok = pcall(function()
        remoBase = ReplicatedStorage:WaitForChild("rbxts_include", 5)
            :WaitForChild("node_modules", 5):WaitForChild("@rbxts", 5)
            :WaitForChild("remo", 5):WaitForChild("src", 5):WaitForChild("container", 5)
    end)
    if not ok or not remoBase then
        warn("[SL] remote container not found")
        remoBase = nil
    end
end

local function getRemote(dotted)
    if not remoBase then return nil end
    local r = remoBase:FindFirstChild(dotted)
    if r then return r end
    for _, d in ipairs(remoBase:GetDescendants()) do
        if d.Name == dotted then return d end
    end
    return nil
end

local R = {
    createRaid     = getRemote("bossRaids.create"),
    leaveRaid      = getRemote("bossRaids.leaveRaid"),
    weaponActivate = getRemote("weapons.activate"),
    sendAndRetreat = getRemote("enemies.sendAndRetreat"),
    toolbarEquip   = getRemote("toolbar.equip"),
    lobbyStart     = getRemote("lobbies.start"),
    achievementClaim      = getRemote("achievements.claim"),
    achievementClaimGroup = getRemote("achievements.claimGroup"),
}
do
    local n = 0
    for _, v in pairs(R) do if v then n = n + 1 end end
    print("[SL v12] remotes resolved: " .. n)
end

-- ============================================================
--  SUNSHINE LAKE CONFIG  (boss raid)
-- ============================================================
local RAID = {
    name    = "Sunshine Raid",              -- id passed to bossRaids.create
    display = "Sunshine Lake",
    bossPos = CFrame.new(4982.6, 6007.8, -50.4),
}

-- ============================================================
--  STATE  (persists across re-exec)
-- ============================================================
getgenv().SLState = getgenv().SLState or {}
local State = getgenv().SLState

local defaults = {
    autoEquipWeapon = false,
    autoFarm        = false,       -- attack enemies
    autoStartRaid   = false,       -- instant-start + auto-restart
    autoDig         = false,
    friendOnly      = false,
    webhookEnabled  = false,
    webhookUrl      = "",
    webhookRewards  = true,
    guiVisible      = true,
    running         = true,
    inRaid          = false,
    startingRaid    = false,
    startingRaidAt  = 0,
    weaponEquipped  = false,
    runCount        = 0,
    freezeUntil     = 0,
}
for k, v in pairs(defaults) do
    if State[k] == nil then State[k] = v end
end
State.guiVisible = true   -- always show on fresh load

-- ============================================================
--  HELPERS
-- ============================================================
local function getChar()
    local c = player.Character
    if not c then return nil, nil end
    return c, c:FindFirstChild("HumanoidRootPart")
end

local function getEnemyFolder()
    local w = Workspace:FindFirstChild("World")
    return w and w:FindFirstChild("Enemies")
end

local function getWarriorUUIDs()
    local uuids = {}
    local w = Workspace:FindFirstChild("World")
    local f = w and w:FindFirstChild("Warriors")
    if not f then return uuids end
    for _, m in ipairs(f:GetChildren()) do
        if m:IsA("Model") then table.insert(uuids, m.Name) end
    end
    return uuids
end

local function isInRaidArea()
    local _, hrp = getChar()
    if not hrp then return false end
    return hrp.Position.Y > RAID_Y_MIN
end

-- enemy is alive unless dead == true (nil/false both count as alive)
local function getAliveEnemies()
    local enemies = {}
    local folder = getEnemyFolder()
    if not folder then return enemies end
    for _, e in ipairs(folder:GetChildren()) do
        if not e:IsA("Model") then continue end
        if e:GetAttribute("dead") == true then continue end
        local hrp = e:FindFirstChild("HumanoidRootPart") or e:FindFirstChild("Root")
        if not hrp then continue end
        if hrp.Position.Y < RAID_Y_MIN then continue end
        local hum = e:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then continue end
        table.insert(enemies, { model = e, uuid = e.Name, hrp = hrp })
    end
    return enemies
end

-- ============================================================
--  COMBAT  (v5 attack)
-- ============================================================
local function swingWeapon()
    if not R.weaponActivate then return end
    local _, hrp = getChar()
    if not hrp then return end
    pcall(function() R.weaponActivate:FireServer(tick(), hrp.CFrame) end)
end

local function hitEnemy(uuid)
    if not R.sendAndRetreat then return end
    local warriors = getWarriorUUIDs()
    if #warriors == 0 then return end
    pcall(function() R.sendAndRetreat:FireServer(uuid, warriors) end)
end

local function isWeaponEquipped()
    local char = player.Character
    if not char then return false end
    if char:FindFirstChildOfClass("Tool") then return true end
    local attr = char:GetAttribute("equippedTool")
        or char:GetAttribute("EquippedTool")
        or char:GetAttribute("weaponEquipped")
    return attr ~= nil and attr ~= false and attr ~= ""
end

local function equipWeapon()
    if not R.toolbarEquip then return end
    if isWeaponEquipped() then State.weaponEquipped = true; return end
    pcall(function() R.toolbarEquip:FireServer("weapon") end)
    task.wait(0.1)
    State.weaponEquipped = isWeaponEquipped()
end

-- teleport onto enemy (1 stud), swing, hit, swing
local function attackTarget(target)
    local _, hrp = getChar()
    if hrp and target.hrp then
        hrp.CFrame = target.hrp.CFrame * CFrame.new(0, 0, 1)
    end
    task.wait(0.05); swingWeapon()
    task.wait(0.05); hitEnemy(target.uuid)
    task.wait(0.05); swingWeapon()
end

local function claimAchievements()
    if R.achievementClaim then pcall(function() R.achievementClaim:FireServer() end) end
    if R.achievementClaimGroup then pcall(function() R.achievementClaimGroup:FireServer() end) end
end

print("[SL v12] foundation + combat loaded")

-- ============================================================
--  INSTANT RAID START  (bossRaids.create — no teleport, no page)
-- ============================================================
local function startRaidInstant()
    if not R.createRaid then
        warn("[SL] bossRaids.create missing — cannot start")
        return false
    end
    if isInRaidArea() then return true end

    State.startingRaid = true
    State.startingRaidAt = tick()

    print("[SL] Starting Sunshine Lake via remote...")
    for attempt = 1, 5 do
        if isInRaidArea() then
            State.startingRaid = false
            print("[SL] In raid (instant start worked)")
            return true
        end
        pcall(function()
            R.createRaid:InvokeServer(RAID.name, { friendsOnly = State.friendOnly, spawnNormal = true })
        end)
        pcall(function()
            R.createRaid:InvokeServer(RAID.name, { friendsOnly = State.friendOnly })
        end)
        print("[SL] Fired bossRaids.create (attempt " .. attempt .. ")")
        for _ = 1, 10 do
            if isInRaidArea() then break end
            task.wait(0.5)
        end
    end

    State.startingRaid = false
    return isInRaidArea()
end

local function leaveRaid()
    if R.leaveRaid then pcall(function() R.leaveRaid:FireServer() end) end
end

-- click helpers (for the Continue button after a win)
local function fireConns(btn)
    if not btn then return false end
    local fired = false
    for _, ev in ipairs({ "Activated", "MouseButton1Click", "MouseButton1Down" }) do
        pcall(function()
            for _, c in pairs(getconnections(btn[ev])) do c:Fire(); fired = true end
        end)
    end
    return fired
end

local function clickByText(searchText)
    searchText = string.lower(searchText)
    local afGui = pgui:FindFirstChild("SunshineGUI")
    for _, obj in ipairs(pgui:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Visible then
            if afGui and obj:IsDescendantOf(afGui) then continue end
            if string.find(string.lower(obj.Text), searchText, 1, true) then
                local cur = obj.Parent
                for _ = 1, 8 do
                    if not cur or cur == pgui then break end
                    if cur.Name == "inner" then
                        local tb = cur:FindFirstChildOfClass("TextButton")
                            or cur:FindFirstChildOfClass("ImageButton")
                        if tb and fireConns(tb) then return true end
                    end
                    cur = cur.Parent
                end
            end
        end
    end
    return false
end

local function clickExact(exactText)
    local afGui = pgui:FindFirstChild("SunshineGUI")
    for _, obj in ipairs(pgui:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Visible and obj.Text == exactText then
            if afGui and obj:IsDescendantOf(afGui) then continue end
            local cur = obj.Parent
            for _ = 1, 8 do
                if not cur then break end
                if cur.Name == "inner" then
                    local tb = cur:FindFirstChildOfClass("TextButton")
                    if tb and fireConns(tb) then return true end
                    break
                end
                cur = cur.Parent
            end
        end
    end
    return false
end

-- press the green in-raid Start button (Leave / Start / Kick bar) so waves begin
local function pressInRaidStart()
    print("[SL] Pressing in-raid Start...")
    for attempt = 1, 12 do
        if #getAliveEnemies() > 0 then
            print("[SL] Waves started (enemies present)")
            return true
        end
        clickExact("Start")
        clickByText("start")
        if R.lobbyStart then pcall(function() R.lobbyStart:FireServer() end) end
        task.wait(1)
    end
    return #getAliveEnemies() > 0
end

-- ============================================================
--  WEBHOOK  (on raid completion, with drops + run #)
-- ============================================================
local function getRequestFunction()
    return (syn and syn.request) or (http and http.request) or http_request or request
end
local function trimText(s) return (tostring(s):gsub("^%s+",""):gsub("%s+$","")) end

local function getVictoryDrops()
    local afGui = pgui:FindFirstChild("SunshineGUI")
    local drops, seen = {}, {}
    local function consider(text)
        text = trimText(text)
        if text == "" or #text > 40 then return end
        local low = string.lower(text)
        if low == "rewards" or low == "reward" or low == "victory"
           or low == "continue" or low == "drops"
           or string.find(low, "you got", 1, true) or string.find(low, "tap", 1, true) then return end
        if not seen[text] then seen[text] = true; table.insert(drops, text) end
    end
    for _, obj in ipairs(pgui:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Visible then
            if afGui and obj:IsDescendantOf(afGui) then continue end
            local low = string.lower(trimText(obj.Text))
            if low == "rewards" or low == "reward" or string.find(low, "drops", 1, true)
               or string.find(low, "you got", 1, true) or string.find(low, "you received", 1, true) then
                local panel = obj.Parent
                for _ = 1, 3 do
                    if panel and panel.Parent and panel.Parent ~= pgui then panel = panel.Parent end
                end
                if panel then
                    for _, d in ipairs(panel:GetDescendants()) do
                        if d:IsA("TextLabel") and d.Visible then consider(d.Text) end
                    end
                end
            end
        end
    end
    if #drops == 0 then return "No drops detected" end
    if #drops > 15 then
        local t = {}
        for i = 1, 15 do t[i] = drops[i] end
        table.insert(t, "...and more")
        drops = t
    end
    return table.concat(drops, "\n")
end

local function sendWebhook(title, description, color, extraFields)
    if not State.webhookEnabled then return end
    local url = trimText(State.webhookUrl)
    if url == "" then return end
    local req = getRequestFunction()
    if not req then warn("[SL] no HTTP request function"); return end
    local fields = {
        { name = "Raid",   value = RAID.display, inline = true },
        { name = "Run #",  value = tostring(State.runCount or 0), inline = true },
        { name = "Player", value = player.Name, inline = true },
    }
    if extraFields then for _, f in ipairs(extraFields) do table.insert(fields, f) end end
    local payload = {
        username = "Sunshine Farm",
        embeds = {{
            title = title, description = description, color = color or 5763719,
            fields = fields, footer = { text = "Sunshine v12" },
            timestamp = DateTime.now():ToIsoDate(),
        }},
    }
    task.spawn(function()
        pcall(function()
            req({ Url = url, Method = "POST",
                  Headers = { ["Content-Type"] = "application/json" },
                  Body = HttpService:JSONEncode(payload) })
        end)
    end)
end

print("[SL v12] start + webhook loaded")

-- ============================================================
--  FARM LOOP  (v5 attack, 700-stud range, freeze window)
-- ============================================================
local function farmLoop()
    while State.running do
        if State.startingRaid then
            repeat task.wait(0.1) until (not State.startingRaid) or (not State.running)
        end
        task.wait(0.15)
        if not State.autoFarm then task.wait(0.5); continue end
        if not isInRaidArea() then task.wait(1); continue end
        if tick() < (State.freezeUntil or 0) then task.wait(0.2); continue end

        if State.autoEquipWeapon then equipWeapon() end

        local enemies = getAliveEnemies()
        if #enemies > 0 then
            -- teleport to the CLOSEST enemy at ANY distance (v5 behaviour).
            local _, myHRP = getChar()
            if myHRP then
                table.sort(enemies, function(a, b)
                    return (myHRP.Position - a.hrp.Position).Magnitude
                         < (myHRP.Position - b.hrp.Position).Magnitude
                end)
            end
            attackTarget(enemies[1])
        else
            -- no enemies: sweep the boss area and keep swinging (chases boss too)
            local bossPos = RAID.bossPos
            local _, myHRP = getChar()
            if bossPos and myHRP then
                if (myHRP.Position - bossPos.Position).Magnitude > 15 then
                    myHRP.CFrame = bossPos
                    task.wait(0.1)
                end
            end
            swingWeapon(); task.wait(0.1); swingWeapon()
        end
    end
end

-- ============================================================
--  RAID CYCLE  (instant start when in lobby)
-- ============================================================
local function raidCycleLoop()
    while State.running do
        task.wait(3)
        if State.startingRaid and (tick() - (State.startingRaidAt or 0)) > 40 then
            State.startingRaid = false
        end
        if not State.autoStartRaid then continue end

        if isInRaidArea() then
            State.inRaid = true
            continue
        end

        -- stale flag: in lobby but inRaid still true
        if State.inRaid and not isInRaidArea()
           and tick() >= (State.freezeUntil or 0) and not State.startingRaid then
            State.inRaid = false
        end

        if not isInRaidArea() and not State.inRaid and not State.startingRaid then
            if startRaidInstant() then
                -- press the green Start button so the raid actually begins
                pressInRaidStart()
                if State.autoEquipWeapon then equipWeapon() end
                State.inRaid = true
                State.freezeUntil = tick() + 3
                print("[SL] Raid started!")
            end
        end
    end
end

-- ============================================================
--  VICTORY LOOP  (webhook + continue + auto-restart)
-- ============================================================
local function victoryLoop()
    while State.running do
        if State.startingRaid then
            repeat task.wait(0.1) until (not State.startingRaid) or (not State.running)
        end
        task.wait(1)
        if not State.autoFarm and not State.autoStartRaid then continue end

        local afGui = pgui:FindFirstChild("SunshineGUI")
        local foundVictory = false
        for _, obj in ipairs(pgui:GetDescendants()) do
            if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Visible then
                if afGui and obj:IsDescendantOf(afGui) then continue end
                if string.find(string.lower(obj.Text), "victory", 1, true) then
                    foundVictory = true; break
                end
            end
        end

        if foundVictory then
            State.runCount = (State.runCount or 0) + 1
            print("[SL] Victory! Run #" .. State.runCount)
            task.wait(3)

            local dropsText = State.webhookRewards and getVictoryDrops() or "Rewards hidden"
            sendWebhook(
                "Raid Complete - Run #" .. State.runCount,
                "**" .. RAID.display .. "** finished!",
                5763719,
                { { name = "Drops", value = dropsText, inline = false } }
            )

            -- leave + Continue back to lobby, then a fresh raid starts
            State.freezeUntil = tick() + 6
            leaveRaid()
            task.wait(2)
            local tries = 0
            while isInRaidArea() and tries < 8 do
                clickExact("Continue")
                clickByText("continue")
                leaveRaid()
                task.wait(1)
                tries = tries + 1
            end

            State.inRaid = false
            State.freezeUntil = 0
            print("[SL] Back in lobby; auto-restart will begin a new raid.")
        end
    end
end

-- ============================================================
--  UTILITY  (weapon upkeep + achievements)
-- ============================================================
local function utilityLoop()
    while State.running do
        if State.startingRaid then
            repeat task.wait(0.1) until (not State.startingRaid) or (not State.running)
        end
        task.wait(3)
        if State.autoEquipWeapon then equipWeapon() end
        pcall(claimAchievements)
    end
end

print("[SL v12] loops loaded")

-- ============================================================
--  AUTO DIGGER  (treasure hunt) — own log window, toggled by autoDig
-- ============================================================
do
    local oldDig = pgui:FindFirstChild("SL_Digger")
    if oldDig then oldDig:Destroy() end

    local dsg = Instance.new("ScreenGui")
    dsg.Name = "SL_Digger"; dsg.ResetOnSpawn = false; dsg.DisplayOrder = 9998
    dsg.Parent = pgui

    local statusBtn = Instance.new("TextButton")
    statusBtn.Size = UDim2.new(0, 130, 0, 26)
    statusBtn.Position = UDim2.new(0, 10, 0, 6)
    statusBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    statusBtn.Text = "Digger off"; statusBtn.TextColor3 = Color3.new(1,1,1)
    statusBtn.TextSize = 11; statusBtn.Font = Enum.Font.GothamBold
    statusBtn.BorderSizePixel = 0; statusBtn.Active = false; statusBtn.ZIndex = 100
    statusBtn.Parent = dsg
    Instance.new("UICorner", statusBtn).CornerRadius = UDim.new(0, 6)

    local win = Instance.new("Frame")
    win.Size = UDim2.new(0, 250, 0, 190)
    win.Position = UDim2.new(0, 10, 0, 38)
    win.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    win.BackgroundTransparency = 0.05; win.BorderSizePixel = 0
    win.ClipsDescendants = true; win.ZIndex = 99; win.Parent = dsg
    Instance.new("UICorner", win).CornerRadius = UDim.new(0, 8)
    local dstroke = Instance.new("UIStroke", win)
    dstroke.Color = Color3.fromRGB(0, 170, 80); dstroke.Thickness = 1

    local closeD = Instance.new("TextButton")
    closeD.Size = UDim2.new(0, 24, 0, 24); closeD.Position = UDim2.new(1, -26, 0, 2)
    closeD.BackgroundColor3 = Color3.fromRGB(200, 50, 50); closeD.Text = "X"
    closeD.TextColor3 = Color3.new(1,1,1); closeD.TextSize = 12
    closeD.Font = Enum.Font.GothamBold; closeD.ZIndex = 101; closeD.Parent = win
    Instance.new("UICorner", closeD).CornerRadius = UDim.new(0, 6)
    closeD.MouseButton1Click:Connect(function() win.Visible = false end)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -8, 1, -8); scroll.Position = UDim2.new(0, 4, 0, 4)
    scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4; scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 170, 80)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ZIndex = 99; scroll.Parent = win

    local dout = Instance.new("TextLabel")
    dout.Size = UDim2.new(1, -8, 0, 0); dout.Position = UDim2.new(0, 4, 0, 0)
    dout.AutomaticSize = Enum.AutomaticSize.Y; dout.BackgroundTransparency = 1
    dout.Text = ""; dout.TextColor3 = Color3.fromRGB(0, 255, 120)
    dout.TextSize = 10; dout.Font = Enum.Font.Code
    dout.TextXAlignment = Enum.TextXAlignment.Left; dout.TextYAlignment = Enum.TextYAlignment.Top
    dout.TextWrapped = true; dout.ZIndex = 99; dout.Parent = scroll

    local logText = ""
    local function dlog(msg)
        logText = logText .. msg .. "\n"
        if #logText > 7000 then logText = logText:sub(#logText - 5000) end
        dout.Text = logText
    end

    local function safeStr(v, depth)
        depth = depth or 0
        if depth > 3 then return "..." end
        if typeof(v) == "string" then return '"'..v..'"' end
        if typeof(v) == "number" or typeof(v) == "boolean" then return tostring(v) end
        if v == nil then return "nil" end
        if typeof(v) == "table" then
            local parts, count = {}, 0
            for k2, v2 in pairs(v) do
                count = count + 1
                if count > 12 then table.insert(parts, "..."); break end
                table.insert(parts, tostring(k2).."="..safeStr(v2, depth+1))
            end
            return "{"..table.concat(parts, ", ").."}"
        end
        return typeof(v)
    end

    task.spawn(function()
        local RS = game:GetService("ReplicatedStorage")
        local digRemote
        for _, d in pairs(RS:GetDescendants()) do
            if d.Name == "treasureHunt.dig" then digRemote = d; break end
        end
        local atoms
        for _, d in pairs(RS:GetDescendants()) do
            if d:IsA("ModuleScript") and d.Name == "atoms"
               and d:GetFullName():find("common.store.atoms") then
                pcall(function() atoms = require(d) end); break
            end
        end
        if not digRemote or not atoms then
            dlog("=== DIGGER setup failed ===")
            if not digRemote then dlog("  no treasureHunt.dig") end
            if not atoms then dlog("  no atoms module") end
            statusBtn.Text = "Digger: no setup"
            statusBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            return
        end

        local function getData()
            local atomTable = atoms.atoms or atoms
            if typeof(atomTable.datastore) ~= "function" then return nil end
            local ok, ds = pcall(atomTable.datastore)
            if not ok or typeof(ds) ~= "table" then return nil end
            return ds[tostring(player.UserId)] or ds[player.UserId]
        end

        dlog("=== AUTO DIGGER ready (toggle in GUI) ===")
        local totalDug = 0

        while dsg.Parent do
            if not State.autoDig then
                statusBtn.Text = "Digger off"
                statusBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
                task.wait(1); continue
            end
            local pdata = getData()
            if not pdata then task.wait(3); continue end

            local shovels = 0
            if pdata.items and pdata.items.Shovel then shovels = pdata.items.Shovel.amount or 0 end

            local dugTiles, currentTier = {}, 0
            if pdata.treasureHunt then
                currentTier = pdata.treasureHunt.currentTier or 0
                if pdata.treasureHunt.dug then
                    for _, tile in pairs(pdata.treasureHunt.dug) do
                        if tile.index then dugTiles[tile.index] = true end
                    end
                end
            end

            if shovels > 0 then
                local undug = {}
                for i = 1, 49 do if not dugTiles[i] then table.insert(undug, i) end end
                if #undug == 0 then
                    statusBtn.Text = "Tier "..currentTier.." done!"
                    statusBtn.BackgroundColor3 = Color3.fromRGB(200, 160, 0)
                    task.wait(5); continue
                end
                dlog("Shovels: "..shovels.." | Undug: "..#undug)
                statusBtn.Text = "DIGGING "..shovels
                statusBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 0)

                for _, tileIdx in ipairs(undug) do
                    if not dsg.Parent or not State.autoDig then break end
                    local fresh = getData()
                    local fShov = 0
                    if fresh and fresh.items and fresh.items.Shovel then fShov = fresh.items.Shovel.amount or 0 end
                    if fShov <= 0 then dlog("  out of shovels"); break end
                    local ok, result = pcall(function() return digRemote:InvokeServer(tileIdx) end)
                    if ok and typeof(result) == "table" then
                        if result.reason then
                            dlog("  Tile "..tileIdx..": SKIP ("..tostring(result.reason)..")")
                        elseif result.revealed then
                            totalDug = totalDug + 1
                            local rewardStr = ""
                            for _, rev in pairs(result.revealed) do
                                if rev.reward then
                                    rewardStr = tostring(rev.reward.id or "").." x"..tostring(rev.reward.amount or "")
                                end
                            end
                            dlog("  Tile "..tileIdx..": "..rewardStr.." (left: "..tostring(result.shovels or "?")..")")
                            statusBtn.Text = "Dug "..totalDug
                        else
                            dlog("  Tile "..tileIdx..": "..safeStr(result))
                        end
                    elseif not ok then
                        dlog("  Tile "..tileIdx.." ERR: "..tostring(result):sub(1,40))
                    end
                    task.wait(0.3)
                end
                dlog("  batch done")
            else
                statusBtn.Text = "Waiting (dug "..totalDug..")"
                statusBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end
            task.wait(3)
        end
    end)
end

print("[SL v12] digger loaded")

-- ============================================================
--  GUI
-- ============================================================
local oldGui = pgui:FindFirstChild("SunshineGUI")
if oldGui then oldGui:Destroy() end

print("[SL v12] building GUI...")

local sg = Instance.new("ScreenGui")
sg.Name = "SunshineGUI"; sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.IgnoreGuiInset = true; sg.DisplayOrder = 9999; sg.Parent = pgui

local C = {
    bg = Color3.fromRGB(18, 18, 24), card = Color3.fromRGB(30, 30, 42),
    border = Color3.fromRGB(48, 48, 66), text = Color3.fromRGB(225, 225, 235),
    textDim = Color3.fromRGB(110, 110, 135), textMid = Color3.fromRGB(160, 160, 180),
    sun = Color3.fromRGB(255, 200, 60), green = Color3.fromRGB(50, 205, 110),
    blue = Color3.fromRGB(80, 160, 255), pink = Color3.fromRGB(255, 90, 140),
    toggleOff = Color3.fromRGB(50, 50, 65),
}

-- floating button
local floatBtn = Instance.new("TextButton", sg)
floatBtn.Size = UDim2.new(0, 44, 0, 44); floatBtn.Position = UDim2.new(0, 8, 0.4, 0)
floatBtn.BackgroundColor3 = C.sun; floatBtn.Text = "SL"
floatBtn.TextColor3 = Color3.fromRGB(40, 30, 0); floatBtn.TextSize = 15
floatBtn.Font = Enum.Font.GothamBold; floatBtn.BorderSizePixel = 0; floatBtn.ZIndex = 100
Instance.new("UICorner", floatBtn).CornerRadius = UDim.new(0, 12)

local mainFrame = Instance.new("Frame", sg)
mainFrame.Size = UDim2.new(0, 300, 0, 350)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -175)
mainFrame.BackgroundColor3 = C.bg; mainFrame.BorderSizePixel = 0; mainFrame.ZIndex = 50
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)
local mStroke = Instance.new("UIStroke", mainFrame)
mStroke.Color = C.sun; mStroke.Thickness = 1; mStroke.Transparency = 0.4
mainFrame.Visible = State.guiVisible

local titleBar = Instance.new("Frame", mainFrame)
titleBar.Size = UDim2.new(1, 0, 0, 40); titleBar.BackgroundColor3 = Color3.fromRGB(28, 24, 14)
titleBar.BorderSizePixel = 0; titleBar.ZIndex = 51
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)

local tt = Instance.new("TextLabel", titleBar)
tt.Size = UDim2.new(0, 200, 1, 0); tt.Position = UDim2.new(0, 14, 0, 0)
tt.BackgroundTransparency = 1; tt.Text = "Sunshine Lake"; tt.TextColor3 = C.sun
tt.TextSize = 15; tt.Font = Enum.Font.GothamBold
tt.TextXAlignment = Enum.TextXAlignment.Left; tt.ZIndex = 52

local verBadge = Instance.new("TextLabel", titleBar)
verBadge.Size = UDim2.new(0, 28, 0, 16); verBadge.Position = UDim2.new(0, 118, 0.5, -8)
verBadge.BackgroundColor3 = C.sun; verBadge.BackgroundTransparency = 0.7
verBadge.Text = "v12"; verBadge.TextColor3 = C.sun; verBadge.TextSize = 10
verBadge.Font = Enum.Font.GothamBold; verBadge.BorderSizePixel = 0; verBadge.ZIndex = 53
Instance.new("UICorner", verBadge).CornerRadius = UDim.new(0, 4)

local closeB = Instance.new("TextButton", titleBar)
closeB.Size = UDim2.new(0, 28, 0, 28); closeB.Position = UDim2.new(1, -36, 0, 6)
closeB.BackgroundColor3 = Color3.fromRGB(60, 30, 40); closeB.Text = "X"
closeB.TextColor3 = C.pink; closeB.TextSize = 13; closeB.Font = Enum.Font.GothamBold
closeB.BorderSizePixel = 0; closeB.ZIndex = 54
Instance.new("UICorner", closeB).CornerRadius = UDim.new(0, 8)
closeB.MouseButton1Click:Connect(function()
    State.guiVisible = false; mainFrame.Visible = false
end)

floatBtn.MouseButton1Click:Connect(function()
    State.guiVisible = not State.guiVisible
    mainFrame.Visible = State.guiVisible
end)

-- scroll body
local body = Instance.new("ScrollingFrame", mainFrame)
body.Size = UDim2.new(1, -10, 1, -48); body.Position = UDim2.new(0, 6, 0, 44)
body.BackgroundTransparency = 1; body.BorderSizePixel = 0
body.ScrollBarThickness = 3; body.ScrollBarImageColor3 = C.sun
body.CanvasSize = UDim2.new(0, 0, 0, 0); body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.ZIndex = 51
local lay = Instance.new("UIListLayout", body)
lay.Padding = UDim.new(0, 6)
local pad = Instance.new("UIPadding", body)
pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 6)
pad.PaddingTop = UDim.new(0, 4); pad.PaddingBottom = UDim.new(0, 8)

local orderN = 0
local function nextOrder() orderN = orderN + 1; return orderN end

local function sec(title, color)
    local f = Instance.new("Frame", body)
    f.Size = UDim2.new(1, 0, 0, 20); f.BackgroundTransparency = 1
    f.LayoutOrder = nextOrder(); f.ZIndex = 51
    local dot = Instance.new("Frame", f)
    dot.Size = UDim2.new(0, 6, 0, 6); dot.Position = UDim2.new(0, 2, 0.5, -3)
    dot.BackgroundColor3 = color; dot.BorderSizePixel = 0; dot.ZIndex = 52
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1, -14, 1, 0); l.Position = UDim2.new(0, 12, 0, 0)
    l.BackgroundTransparency = 1; l.Text = string.upper(title); l.TextColor3 = color
    l.TextSize = 9; l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left; l.ZIndex = 52
end

local function tog(label, stateKey, color)
    local h = Instance.new("Frame", body)
    h.Size = UDim2.new(1, 0, 0, 34); h.BackgroundColor3 = C.card
    h.BorderSizePixel = 0; h.LayoutOrder = nextOrder(); h.ZIndex = 51
    Instance.new("UICorner", h).CornerRadius = UDim.new(0, 8)
    local hs = Instance.new("UIStroke", h); hs.Color = C.border; hs.Transparency = 0.6
    local l = Instance.new("TextLabel", h)
    l.Size = UDim2.new(1, -54, 1, 0); l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1; l.Text = label; l.TextColor3 = C.textMid
    l.TextSize = 12; l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left; l.ZIndex = 52
    local tr = Instance.new("Frame", h)
    tr.Size = UDim2.new(0, 38, 0, 22); tr.Position = UDim2.new(1, -46, 0.5, -11)
    tr.BackgroundColor3 = C.toggleOff; tr.BorderSizePixel = 0; tr.ZIndex = 52
    Instance.new("UICorner", tr).CornerRadius = UDim.new(1, 0)
    local kn = Instance.new("Frame", tr)
    kn.Size = UDim2.new(0, 18, 0, 18); kn.Position = UDim2.new(0, 2, 0, 2)
    kn.BackgroundColor3 = Color3.fromRGB(120, 120, 135); kn.BorderSizePixel = 0; kn.ZIndex = 53
    Instance.new("UICorner", kn).CornerRadius = UDim.new(1, 0)
    local b = Instance.new("TextButton", h)
    b.Size = UDim2.new(1, 0, 1, 0); b.BackgroundTransparency = 1; b.Text = ""; b.ZIndex = 54
    local function upd()
        local on = State[stateKey]
        tr.BackgroundColor3 = on and color or C.toggleOff
        kn.Position = on and UDim2.new(0, 18, 0, 2) or UDim2.new(0, 2, 0, 2)
        kn.BackgroundColor3 = on and Color3.new(1,1,1) or Color3.fromRGB(120,120,135)
        l.TextColor3 = on and C.text or C.textMid
        hs.Color = on and color or C.border
    end
    b.MouseButton1Click:Connect(function() State[stateKey] = not State[stateKey]; upd() end)
    upd()
end

local function textbox(label, getVal, onChanged)
    local h = Instance.new("Frame", body)
    h.Size = UDim2.new(1, 0, 0, 48); h.BackgroundColor3 = C.card
    h.BorderSizePixel = 0; h.LayoutOrder = nextOrder(); h.ZIndex = 51
    Instance.new("UICorner", h).CornerRadius = UDim.new(0, 8)
    local hs = Instance.new("UIStroke", h); hs.Color = C.border; hs.Transparency = 0.5
    local l = Instance.new("TextLabel", h)
    l.Size = UDim2.new(1, -14, 0, 12); l.Position = UDim2.new(0, 10, 0, 5)
    l.BackgroundTransparency = 1; l.Text = label; l.TextColor3 = C.textDim
    l.TextSize = 9; l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left; l.ZIndex = 52
    local bf = Instance.new("Frame", h)
    bf.Size = UDim2.new(1, -16, 0, 24); bf.Position = UDim2.new(0, 8, 0, 19)
    bf.BackgroundColor3 = Color3.fromRGB(40, 40, 56); bf.BorderSizePixel = 0; bf.ZIndex = 52
    Instance.new("UICorner", bf).CornerRadius = UDim.new(0, 6)
    local tb = Instance.new("TextBox", bf)
    tb.Size = UDim2.new(1, -12, 1, 0); tb.Position = UDim2.new(0, 6, 0, 0)
    tb.BackgroundTransparency = 1; tb.Text = getVal() or ""; tb.PlaceholderText = "paste here..."
    tb.PlaceholderColor3 = C.textDim; tb.TextColor3 = C.text; tb.TextSize = 10
    tb.Font = Enum.Font.Gotham; tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.ClearTextOnFocus = false; tb.ZIndex = 53
    tb.FocusLost:Connect(function() if onChanged then onChanged(tb.Text) end end)
end

-- layout
sec("Raid", C.sun)
tog("Auto start raid", "autoStartRaid", C.sun)
tog("Auto attack", "autoFarm", C.green)
tog("Auto equip weapon", "autoEquipWeapon", C.blue)

sec("Treasure", C.sun)
tog("Auto dig", "autoDig", C.sun)

sec("Webhook", C.pink)
tog("Webhook enabled", "webhookEnabled", C.pink)
tog("Include drops", "webhookRewards", C.pink)
textbox("Webhook URL", function() return State.webhookUrl end, function(v)
    State.webhookUrl = v; print("[SL] webhook URL set (" .. #v .. " chars)")
end)

-- status bar
local statusHolder = Instance.new("Frame", body)
statusHolder.Size = UDim2.new(1, 0, 0, 26); statusHolder.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
statusHolder.BorderSizePixel = 0; statusHolder.LayoutOrder = 999; statusHolder.ZIndex = 51
Instance.new("UICorner", statusHolder).CornerRadius = UDim.new(0, 8)
local statusDot = Instance.new("Frame", statusHolder)
statusDot.Size = UDim2.new(0, 6, 0, 6); statusDot.Position = UDim2.new(0, 10, 0.5, -3)
statusDot.BackgroundColor3 = C.textDim; statusDot.BorderSizePixel = 0; statusDot.ZIndex = 52
Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)
local statusBar = Instance.new("TextLabel", statusHolder)
statusBar.Size = UDim2.new(1, -24, 1, 0); statusBar.Position = UDim2.new(0, 22, 0, 0)
statusBar.BackgroundTransparency = 1; statusBar.Text = "Idle"; statusBar.TextColor3 = C.textDim
statusBar.TextSize = 10; statusBar.Font = Enum.Font.Gotham
statusBar.TextXAlignment = Enum.TextXAlignment.Left; statusBar.ZIndex = 52

-- ============================================================
--  START LOOPS
-- ============================================================
task.spawn(farmLoop)
task.spawn(raidCycleLoop)
task.spawn(victoryLoop)
task.spawn(utilityLoop)

task.spawn(function()
    while State.running do
        if State.startingRaid then
            statusBar.Text = "Starting raid..."
            statusBar.TextColor3 = C.sun; statusDot.BackgroundColor3 = C.sun
            repeat task.wait(0.1) until (not State.startingRaid) or (not State.running)
        end
        task.wait(1)
        if State.startingRaid then continue end
        if State.autoFarm or State.autoStartRaid then
            local enemies = getAliveEnemies()
            if isInRaidArea() then
                if #enemies > 0 then
                    statusBar.Text = "Fighting " .. #enemies .. "  •  Run " .. (State.runCount or 0)
                    statusBar.TextColor3 = C.green; statusDot.BackgroundColor3 = C.green
                else
                    statusBar.Text = "Boss area  •  Run " .. (State.runCount or 0)
                    statusBar.TextColor3 = C.sun; statusDot.BackgroundColor3 = C.sun
                end
            else
                statusBar.Text = "Lobby  •  Runs: " .. (State.runCount or 0)
                statusBar.TextColor3 = C.blue; statusDot.BackgroundColor3 = C.blue
            end
        else
            statusBar.Text = "Idle"
            statusBar.TextColor3 = C.textDim; statusDot.BackgroundColor3 = C.textDim
        end
    end
end)

player.CharacterAdded:Connect(function()
    task.wait(2)
    if State.autoEquipWeapon then equipWeapon() end
end)

print("===========================================")
print("  Sunshine Lake Auto Farm v12 loaded!")
print("  Instant start, v5 attack, dig, webhook")
print("===========================================")
