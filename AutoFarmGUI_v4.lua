-- =============================================
--  AUTO FARM GUI v10 — SUNSHINE + DARK MATTER
--  v10 changes (ONLY these, nothing else touched):
--   1. createRaid hardened so Sunshine never freezes on friends/yes
--   2. Invasion uses live dialogue button lookup (works every restart)
--   3. Invasion start is ONE reusable sequence (1st run == Nth run)
-- =============================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UIS               = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local HttpService       = game:GetService("HttpService")

local player = Players.LocalPlayer
local pgui   = player:WaitForChild("PlayerGui", 10)

-- =============================================
--  REMOTES (exact paths)
-- =============================================

local remoBase
local ok, err = pcall(function()
    remoBase = ReplicatedStorage:WaitForChild("rbxts_include", 5)
        :WaitForChild("node_modules", 5):WaitForChild("@rbxts", 5)
        :WaitForChild("remo", 5):WaitForChild("src", 5):WaitForChild("container", 5)
end)
if not ok or not remoBase then
    warn("[AF] Remote path not found! Game may have updated. Error: " .. tostring(err))
    remoBase = nil
end

local function getRemote(cat, name)
    if not remoBase then return nil end
    local c = remoBase:FindFirstChild(cat)
    return c and c:FindFirstChild(name)
end

local R = {
    createRaid      = getRemote("bossRaids", "create"),
    leaveRaid       = getRemote("bossRaids", "leaveRaid"),
    createInvasion  = getRemote("invasions", "create"),
    voteCard        = getRemote("invasions", "voteCard"),
    lobbyStart      = getRemote("lobbies", "start"),
    weaponActivate  = getRemote("weapons", "activate"),
    sendAndRetreat  = getRemote("enemies", "sendAndRetreat"),
    toolbarEquip    = getRemote("toolbar", "equip"),
    toolbarUnequip  = getRemote("toolbar", "unequip"),
    warriorsEquipBest = getRemote("warriors", "equipBest"),
    achievementClaim      = getRemote("achievements", "claim"),
    achievementClaimGroup = getRemote("achievements", "claimGroup"),
}

local rc = 0
for _, v in pairs(R) do if v then rc = rc + 1 end end
print("[AF] Loaded " .. rc .. " remotes")

-- =============================================
--  RAID DATA
-- =============================================

local RaidList = {
    {
        name = "Sunshine Raid",
        display = "Sunshine Lake",
        raidType = "bossRaid",
        portalPos = CFrame.new(-653.9, -1471.1, 186.3),
        bossPos = CFrame.new(4982.6, 6007.8, -50.4),
        startText = "start raid",
        working = true,
    },
    {
        name = "Dark Matter Invasion",
        display = "Dark Matter",
        raidType = "invasion",
        portalPos = CFrame.new(-1743, -1490, -745),
        bossPos = CFrame.new(4911, 6020, 161),
        startText = "start invasion",
        working = true,
    },
}

local INVASION_HOLD_POS = CFrame.new(4911, 6020, 161)
local INVASION_START_TIMEOUT = 20

local ModifierOptions = {
    "Disabled",
    "Boss Killer",
    "Overflowing Wealth",
    "Warrior Blessing",
    "Espionage",
    "Reinforcement",
    "Momentum",
}

-- =============================================
--  STATE
-- =============================================

getgenv().AFState = {
    autoEquipWeapon      = false,
    autoUseWeapon        = false,
    autoClaimAchievement = false,
    autoEquipBestPet     = false,
    autoFarm             = false,
    friendOnly           = false,
    autoCreateRaid       = false,
    guiVisible           = true,
    running              = true,
    inRaid               = false,
    selectedRaid         = RaidList[1],
    webhookEnabled       = false,
    webhookUrl           = "",
    webhookRewards       = true,
    autoPickModifiers    = false,
    invasionStartAt      = 0,
    runCount             = 0,
    lastModifierVoteAt   = 0,
    lastModifierSignature = "",
    modifierPickedForSignature = false,
    modifierPriorities   = {
        "Boss Killer",
        "Overflowing Wealth",
        "Warrior Blessing",
        "Espionage",
        "Reinforcement",
        "Momentum",
    },
}
local State = getgenv().AFState

-- =============================================
--  HELPERS
-- =============================================

local RAID_Y_MIN = 5000

local function getChar()
    local c = player.Character
    if not c then return nil, nil end
    return c, c:FindFirstChild("HumanoidRootPart")
end

local function getEnemyFolder()
    local w = Workspace:FindFirstChild("World")
    return w and w:FindFirstChild("Enemies")
end

local function getWarriorFolder()
    local w = Workspace:FindFirstChild("World")
    return w and w:FindFirstChild("Warriors")
end

local function getWarriorUUIDs()
    local uuids = {}
    local f = getWarriorFolder()
    if not f then return uuids end
    for _, w in ipairs(f:GetChildren()) do
        if w:IsA("Model") then
            table.insert(uuids, w.Name)
        end
    end
    return uuids
end

local function isInRaidArea()
    local _, hrp = getChar()
    if not hrp then return false end
    return hrp.Position.Y > RAID_Y_MIN
end

local function trimText(v)
    v = tostring(v or "")
    return (v:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function normalizeText(v)
    return string.lower(trimText(v):gsub("%s+", " "))
end

local function getRequestFunction()
    return (syn and syn.request) or http_request or request or (http and http.request)
end

local function collectVisibleText(keywords)
    local lines = {}
    local seen = {}
    for _, obj in ipairs(pgui:GetDescendants()) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Visible then
            if obj:IsDescendantOf(pgui:FindFirstChild("AutoFarmGUI")) then continue end
            local text = trimText(obj.Text)
            if text ~= "" then
                local low = string.lower(text)
                local keep = not keywords
                if keywords then
                    for _, kw in ipairs(keywords) do
                        if string.find(low, kw, 1, true) then keep = true; break end
                    end
                end
                if keep and not seen[text] then
                    seen[text] = true
                    table.insert(lines, text)
                end
            end
        end
    end
    return lines
end

-- Scrape the victory screen for the drops the player received.
-- Returns a formatted string of "item xN" lines. The victory UI
-- usually lists each drop as a label, sometimes with a quantity
-- label like "x3" or "3" next to it.
local function getVictoryDrops()
    -- Find a container whose subtree mentions "reward" or "drop" so we
    -- only scrape the victory panel, not the whole HUD.
    local candidates = {}
    for _, obj in ipairs(pgui:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Visible then
            if obj:IsDescendantOf(pgui:FindFirstChild("AutoFarmGUI")) then continue end
            local low = string.lower(trimText(obj.Text))
            if low == "rewards" or low == "reward" or string.find(low, "drops", 1, true)
               or string.find(low, "you got", 1, true) or string.find(low, "you received", 1, true) then
                -- climb a few parents to get the panel that holds the reward list
                local panel = obj.Parent
                for _ = 1, 3 do
                    if panel and panel.Parent and panel.Parent ~= pgui then
                        panel = panel.Parent
                    end
                end
                if panel then table.insert(candidates, panel) end
            end
        end
    end

    local drops = {}
    local seen = {}

    local function consider(text)
        text = trimText(text)
        if text == "" or #text > 40 then return end
        local low = string.lower(text)
        -- skip obvious non-drop words
        if low == "rewards" or low == "reward" or low == "victory"
           or low == "continue" or low == "replay" or low == "drops"
           or string.find(low, "you got", 1, true) or string.find(low, "tap", 1, true) then
            return
        end
        if not seen[text] then
            seen[text] = true
            table.insert(drops, text)
        end
    end

    if #candidates > 0 then
        for _, panel in ipairs(candidates) do
            for _, d in ipairs(panel:GetDescendants()) do
                if d:IsA("TextLabel") and d.Visible then
                    consider(d.Text)
                end
            end
        end
    end

    -- Fallback: keyword sweep of the whole GUI if no panel found
    if #drops == 0 then
        local lines = collectVisibleText({"gem", "coin", "yen", "token", "trait", "essence", "shard", "gold", "crate", "chest", "x1", "x2", "x3", "x5", "x10"})
        for _, l in ipairs(lines) do consider(l) end
    end

    if #drops == 0 then return "No drops detected" end
    -- Cap the list so the webhook embed never gets too long
    if #drops > 15 then
        local trimmed = {}
        for i = 1, 15 do trimmed[i] = drops[i] end
        table.insert(trimmed, "...and more")
        drops = trimmed
    end
    return table.concat(drops, "\n")
end

-- sendWebhook(title, description, color, extraFields)
-- extraFields is an optional array of {name=, value=, inline=} tables
-- that get appended after the default Raid/Player fields.
local function sendWebhook(title, description, color, extraFields)
    if not State.webhookEnabled then return end
    local url = trimText(State.webhookUrl)
    if url == "" then return end
    local req = getRequestFunction()
    if not req then
        warn("[AF] No HTTP request function found for webhook")
        return
    end

    local fields = {
        { name = "Raid", value = State.selectedRaid and State.selectedRaid.display or "Unknown", inline = true },
        { name = "Run #", value = tostring(State.runCount or 0), inline = true },
        { name = "Player", value = player.Name, inline = true },
    }
    if extraFields then
        for _, f in ipairs(extraFields) do
            table.insert(fields, f)
        end
    end

    local payload = {
        username = "Auto Farm GUI",
        embeds = {{
            title = title,
            description = description,
            color = color or 5763719,
            fields = fields,
            footer = { text = "Auto Farm v10" },
            timestamp = DateTime.now():ToIsoDate(),
        }}
    }

    task.spawn(function()
        local ok, err = pcall(function()
            req({
                Url = url,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode(payload),
            })
        end)
        if not ok then warn("[AF] Webhook failed: " .. tostring(err)) end
    end)
end


-- =============================================
--  UNIVERSAL ENEMY DETECTION
-- =============================================

local function getAliveEnemies()
    local enemies = {}
    local folder = getEnemyFolder()
    if not folder then return enemies end

    for _, e in ipairs(folder:GetChildren()) do
        if not e:IsA("Model") then continue end

        -- "dead" is only TRUE when the enemy is actually dead.
        -- Invasion enemies may have dead = nil before being hit,
        -- so we only skip when it is explicitly true (NOT when nil).
        local dead = e:GetAttribute("dead")
        if dead == true then continue end

        local hrp = e:FindFirstChild("HumanoidRootPart") or e:FindFirstChild("Root")
        if not hrp then continue end
        if hrp.Position.Y < RAID_Y_MIN then continue end

        -- If it has a Humanoid, it must still have health
        local hum = e:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then continue end

        local bounds = e:GetAttribute("bounds")
        local boundsX = bounds and bounds.X or 0
        table.insert(enemies, {
            model = e,
            uuid = e.Name,
            hrp = hrp,
            hasHumanoid = hum ~= nil,
            boundsX = boundsX,
            state = e:GetAttribute("_battleState") or "none",
        })
    end
    return enemies
end

-- =============================================
--  COMBAT
-- =============================================

local function teleportTo(targetHRP)
    local _, hrp = getChar()
    if not hrp or not targetHRP then return end
    hrp.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 5)
end

local function swingWeapon()
    if not R.weaponActivate then return end
    local _, hrp = getChar()
    if not hrp then return end
    pcall(function()
        R.weaponActivate:FireServer(tick(), hrp.CFrame)
    end)
end

local function hitEnemy(uuid)
    if not R.sendAndRetreat then return end
    local warriors = getWarriorUUIDs()
    if #warriors == 0 then return end
    pcall(function()
        R.sendAndRetreat:FireServer(uuid, warriors)
    end)
end

local function equipWeapon()
    if R.toolbarEquip then
        pcall(function() R.toolbarEquip:FireServer("weapon") end)
    end
end

local function attackTarget(target)
    teleportTo(target.hrp)
    task.wait(0.05)
    swingWeapon()
    task.wait(0.05)
    hitEnemy(target.uuid)
    task.wait(0.05)
    swingWeapon()
end

local function isSelectedInvasion()
    return State.selectedRaid and State.selectedRaid.raidType == "invasion"
end

local function moveToInvasionHold(reason)
    if not isSelectedInvasion() or not isInRaidArea() then return false end
    local _, hrp = getChar()
    if not hrp then return false end
    hrp.CFrame = INVASION_HOLD_POS
    print("[AF] Holding invasion position" .. (reason and (" (" .. reason .. ")") or ""))
    return true
end

local function invasionStartTimedOut()
    return isSelectedInvasion()
       and (State.invasionStartAt or 0) > 0
       and not isInRaidArea()
       and (tick() - State.invasionStartAt) >= INVASION_START_TIMEOUT
end


-- =============================================
--  RAID MANAGEMENT
-- =============================================

-- Fire all Activated connections on a button
local function fireActivated(btn)
    if not btn then return false end
    local fired = false
    pcall(function()
        for _, conn in pairs(getconnections(btn.Activated)) do
            conn:Fire()
            fired = true
        end
    end)
    return fired
end

local function clickByText(searchText)
    searchText = string.lower(searchText)

    for _, obj in ipairs(pgui:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Visible then
            if obj:IsDescendantOf(pgui:FindFirstChild("AutoFarmGUI")) then continue end
            if string.find(string.lower(obj.Text), searchText, 1, true) then

                local current = obj.Parent
                local innerFrame = nil
                for depth = 1, 8 do
                    if not current or current == pgui then break end
                    if current.Name == "inner" then
                        innerFrame = current
                        break
                    end
                    current = current.Parent
                end

                if innerFrame then
                    local textButton = innerFrame:FindFirstChildOfClass("TextButton")
                    if textButton then
                        pcall(function()
                            for _, conn in pairs(getconnections(textButton.Activated)) do
                                conn:Fire()
                            end
                        end)
                        print("[AF] Clicked '" .. searchText .. "' via inner.TextButton.Activated")
                        return true
                    end
                end

                local parent = obj.Parent
                if parent then
                    for _, desc in ipairs(parent:GetDescendants()) do
                        if desc:IsA("TextButton") then
                            pcall(function()
                                for _, conn in pairs(getconnections(desc.Activated)) do
                                    conn:Fire()
                                end
                            end)
                            print("[AF] Clicked '" .. searchText .. "' via parent descendant TextButton")
                            return true
                        end
                    end
                end

                parent = obj.Parent
                for depth = 1, 6 do
                    if not parent or parent == pgui then break end
                    for _, child in ipairs(parent:GetChildren()) do
                        if child:IsA("TextButton") then
                            pcall(function()
                                for _, conn in pairs(getconnections(child.Activated)) do
                                    conn:Fire()
                                end
                            end)
                            print("[AF] Clicked '" .. searchText .. "' via sibling TextButton")
                            return true
                        end
                    end
                    parent = parent.Parent
                end
            end
        end
    end
    print("[AF] Could not find '" .. searchText .. "'")
    return false
end

-- Click exact text match (for Continue)
local function clickExact(exactText)
    for _, obj in ipairs(pgui:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Visible and obj.Text == exactText then
            if obj:IsDescendantOf(pgui:FindFirstChild("AutoFarmGUI")) then continue end
            local current = obj.Parent
            for d = 1, 8 do
                if not current then break end
                if current.Name == "inner" then
                    local tb = current:FindFirstChildOfClass("TextButton")
                    if tb then
                        pcall(function()
                            for _, conn in pairs(getconnections(tb.Activated)) do
                                conn:Fire()
                            end
                        end)
                        print("[AF] Clicked exact '" .. exactText .. "'")
                        return true
                    end
                    break
                end
                current = current.Parent
            end
        end
    end
    return false
end

-- ============================================================
--  v10 FIX #1: createRaid hardened
--  Each click is bounded + pcall-wrapped; Yes is retried a few
--  times; the function ALWAYS returns so the loop never hangs.
-- ============================================================
local function createRaid()
    local raid = State.selectedRaid
    if not raid.working then
        print("[AF] " .. raid.display .. " not configured yet")
        return false
    end

    print("[AF] Looking for " .. raid.startText .. " button...")

    local clickedStart = false
    pcall(function() clickedStart = clickByText(raid.startText) end)

    if clickedStart then
        task.wait(1.5)

        if State.friendOnly then
            pcall(function() clickByText("friends only") end)
            task.wait(0.5)
        end

        task.wait(0.5)
        local clickedYes = false
        for attempt = 1, 4 do
            pcall(function() clickedYes = clickByText("yes") end)
            if clickedYes then break end
            task.wait(0.4)
        end
        if clickedYes then
            print("[AF] Clicked Yes!")
            return true
        end
        print("[AF] Start clicked but Yes not found, trying remote fallback")
    end

    print("[AF] Trying InvokeServer fallback...")
    if raid.raidType == "invasion" and R.createInvasion then
        local okk, e2 = pcall(function()
            R.createInvasion:InvokeServer(raid.name, { friendsOnly = State.friendOnly })
        end)
        if okk then print("[AF] Invasion InvokeServer succeeded!"); return true
        else print("[AF] Invasion InvokeServer failed: " .. tostring(e2)) end
    elseif raid.raidType == "bossRaid" and R.createRaid then
        local okk, e2 = pcall(function()
            R.createRaid:InvokeServer(raid.name, { friendsOnly = State.friendOnly, spawnNormal = false })
        end)
        if okk then print("[AF] Raid InvokeServer succeeded!"); return true
        else print("[AF] Raid InvokeServer failed: " .. tostring(e2)) end
    end

    return false
end

local function startLobby()
    if R.lobbyStart then
        pcall(function() R.lobbyStart:FireServer() end)
        print("[AF] Lobby force started")
    end
end

local function leaveRaid()
    if R.leaveRaid then
        pcall(function() R.leaveRaid:FireServer() end)
        print("[AF] Left raid")
    end
end

local function equipBestWarriors()
    if R.warriorsEquipBest then
        pcall(function() R.warriorsEquipBest:FireServer() end)
    end
end

-- Fire the ProximityPrompt "E" button via its inner TextButton
local function pressE()
    local prompts = pgui:FindFirstChild("ProximityPrompts")
    if not prompts then return false end
    for _, desc in ipairs(prompts:GetDescendants()) do
        if desc:IsA("TextButton") and desc.Parent and desc.Parent.Name == "inner" then
            pcall(function()
                for _, conn in pairs(getconnections(desc.Activated)) do
                    conn:Fire()
                end
            end)
            print("[AF] Pressed E via ProximityPrompts.inner.TextButton")
            return true
        end
    end
    return false
end

-- ============================================================
--  v10 FIX #2: clickDialog finds the LIVE button each call
--  Spy path: dialogue.BillboardGui.Frame.Frame.Frame.TextButton
--  We never rely on fixed child order, so 2nd/3rd/Nth invasion
--  all work because we re-find the active button every time.
-- ============================================================
local function clickDialog(searchText)
    searchText = string.lower(searchText)
    local dialogue = pgui:FindFirstChild("dialogue")
    if not dialogue then return false end

    -- A: TextButton whose own/sibling/descendant label matches
    for _, btn in ipairs(dialogue:GetDescendants()) do
        if btn:IsA("TextButton") then
            if btn.Text ~= "" and string.find(string.lower(btn.Text), searchText, 1, true) then
                if fireActivated(btn) then
                    print("[AF] Dialog click (own text): '" .. searchText .. "'")
                    return true
                end
            end
            local parent = btn.Parent
            if parent then
                for _, sib in ipairs(parent:GetChildren()) do
                    if sib:IsA("TextLabel") and string.find(string.lower(sib.Text), searchText, 1, true) then
                        if fireActivated(btn) then
                            print("[AF] Dialog click (sibling label): '" .. searchText .. "'")
                            return true
                        end
                    end
                end
                for _, d in ipairs(parent:GetDescendants()) do
                    if d:IsA("TextLabel") and string.find(string.lower(d.Text), searchText, 1, true) then
                        if fireActivated(btn) then
                            print("[AF] Dialog click (descendant label): '" .. searchText .. "'")
                            return true
                        end
                    end
                end
            end
        end
    end

    -- B: matching label first, then walk up to nearest TextButton
    for _, lbl in ipairs(dialogue:GetDescendants()) do
        if lbl:IsA("TextLabel") and string.find(string.lower(lbl.Text), searchText, 1, true) then
            local current = lbl
            for d = 1, 8 do
                if not current then break end
                for _, child in ipairs(current:GetChildren()) do
                    if child:IsA("TextButton") then
                        if fireActivated(child) then
                            print("[AF] Dialog click (walk up): '" .. searchText .. "'")
                            return true
                        end
                    end
                end
                current = current.Parent
            end
        end
    end

    return false
end


local function clickLeadToInvasion()
    for attempt = 1, 12 do
        if clickDialog("lead me") or clickByText("lead me to the invasion") or clickByText("lead me") then
            print("[AF] Clicked Lead me to the invasion (attempt " .. attempt .. ")")
            return true
        end
        task.wait(0.35)
    end
    return false
end

local function claimAchievements()
    if R.achievementClaim then pcall(function() R.achievementClaim:FireServer() end) end
    if R.achievementClaimGroup then pcall(function() R.achievementClaimGroup:FireServer() end) end
end

-- Re-press E near the NPC (used on retry)
local function pressEProximity()
    local _, h = getChar()
    if not h then return false end
    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            local part = desc.Parent
            if part and part:IsA("BasePart") and (h.Position - part.Position).Magnitude < 10 then
                pcall(function() fireproximityprompt(desc) end)
                return true
            end
        end
    end
    return false
end

-- Wait for the "lead me" dialog text to be visible
local function waitForLeadDialog(seconds)
    local steps = math.floor((seconds or 5) / 0.5)
    for _ = 1, steps do
        for _, obj in ipairs(pgui:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Visible then
                if string.find(string.lower(obj.Text), "lead me", 1, true) then
                    return true
                end
            end
        end
        task.wait(0.5)
    end
    return false
end

-- ============================================================
--  v10: full invasion-start as ONE reusable function.
--  Used for first start AND every restart so behaviour is
--  identical each time. Returns true if it reached createRaid.
-- ============================================================
local function doInvasionStartSequence(raid)
    -- Teleport to NPC
    local _, hrp = getChar()
    if hrp then
        hrp.CFrame = raid.portalPos
        task.wait(2)
    end

    -- Press E (proximity), fallback to GUI E button
    local pressed = pressEProximity()
    if not pressed then pressE() end

    -- Wait up to 5s for dialog
    local foundLead = waitForLeadDialog(5)

    -- If not found, press E ONE more time and wait again
    if not foundLead then
        if not pressEProximity() then pressE() end
        foundLead = waitForLeadDialog(4)
    end

    if not foundLead then
        print("[AF] Dialog didn't appear, retry whole cycle")
        return false
    end

    task.wait(0.3)
    if not clickLeadToInvasion() then
        print("[AF] Lead me click failed, retry whole cycle")
        return false
    end
    task.wait(2)

    -- Wait for Start Invasion UI
    local uiFound = false
    for _ = 1, 12 do
        for _, obj in ipairs(pgui:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Visible then
                if string.find(string.lower(obj.Text), "start invasion", 1, true) then
                    uiFound = true
                    break
                end
            end
        end
        if uiFound then break end
        task.wait(0.5)
    end

    if not uiFound then
        print("[AF] Start Invasion UI not found, retry whole cycle")
        return false
    end

    createRaid()
    task.wait(4)
    return true
end

-- =============================================
--  AUTO CARD VOTING (Invasions only)
-- =============================================

local function fireButton(button)
    if not button then return false end
    local fired = false
    pcall(function()
        for _, conn in pairs(getconnections(button.Activated)) do
            conn:Fire()
            fired = true
        end
    end)
    pcall(function()
        for _, conn in pairs(getconnections(button.MouseButton1Click)) do
            conn:Fire()
            fired = true
        end
    end)
    pcall(function()
        button:Activate()
        fired = true
    end)
    return fired
end

local function clickCardFromLabel(label, title, index)
    local current = label
    for d = 1, 12 do
        if not current or current == pgui then break end

        if current:IsA("TextButton") or current:IsA("ImageButton") then
            if fireButton(current) then return true end
        end

        for _, desc in ipairs(current:GetDescendants()) do
            if desc:IsA("TextButton") or desc:IsA("ImageButton") then
                if fireButton(desc) then return true end
            end
        end

        current = current.Parent
    end

    if R.voteCard and title then
        local guesses = { title, label.Name, index }
        for _, guess in ipairs(guesses) do
            local ok = pcall(function() R.voteCard:FireServer(guess) end)
            if ok then return true end
            ok = pcall(function() R.voteCard:InvokeServer(guess) end)
            if ok then return true end
        end
    end
    return false
end

local function modifierKeysMatch(cardKey, wantedKey)
    if string.find(cardKey, wantedKey, 1, true) or string.find(wantedKey, cardKey, 1, true) then return true end
    if string.find(cardKey, "overflowing", 1, true) and string.find(wantedKey, "overflowing", 1, true) then return true end
    if string.find(cardKey, "boss killer", 1, true) and string.find(wantedKey, "boss killer", 1, true) then return true end
    if string.find(cardKey, "blessing", 1, true) and string.find(wantedKey, "blessing", 1, true) then return true end
    return false
end

local function isKnownModifierText(low)
    if string.find(low, "overflowing", 1, true) or string.find(low, "boss killer", 1, true) then return true end
    if string.find(low, "blessing", 1, true) then return true end
    for _, opt in ipairs(ModifierOptions) do
        if opt ~= "Disabled" and string.find(low, normalizeText(opt), 1, true) then return true end
    end
    return false
end

local function getModifierTier(text)
    local low = normalizeText(text)
    local digitTier = low:match("(%d+)%s*$")
    if digitTier then return tonumber(digitTier) or 1 end

    local suffix = low:match("([il]+)%s*$")
    if suffix then return #suffix end

    suffix = low:match("([ivx]+)%s*$")
    if suffix == "iii" then return 3 end
    if suffix == "ii" then return 2 end
    if suffix == "i" then return 1 end
    return 1
end

local function getVisibleModifierCards()
    local cards = {}
    local seen = {}
    for _, obj in ipairs(pgui:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Visible then
            if obj:IsDescendantOf(pgui:FindFirstChild("AutoFarmGUI")) then continue end
            local text = trimText(obj.Text)
            if text ~= "" and #text <= 55 and not seen[text] then
                local low = normalizeText(text)
                if isKnownModifierText(low) then
                    seen[text] = true
                    table.insert(cards, {
                        label = obj,
                        title = text,
                        key = low,
                        tier = getModifierTier(text),
                        index = #cards + 1,
                    })
                end
            end
        end
    end
    return cards
end

local function getModifierSignature(cards)
    local parts = {}
    for _, card in ipairs(cards) do
        table.insert(parts, card.title .. ":" .. tostring(card.tier))
    end
    table.sort(parts)
    return table.concat(parts, "|")
end

local function autoVoteCard()
    if not State.autoPickModifiers then return false end
    local cards = getVisibleModifierCards()
    if #cards == 0 then
        State.lastModifierSignature = ""
        State.modifierPickedForSignature = false
        return false
    end

    local signature = getModifierSignature(cards)
    if signature ~= State.lastModifierSignature then
        State.lastModifierSignature = signature
        State.modifierPickedForSignature = false
    end
    if State.modifierPickedForSignature then return false end

    for _, wanted in ipairs(State.modifierPriorities or {}) do
        wanted = trimText(wanted)
        if wanted ~= "" and wanted ~= "Disabled" then
            local wantedKey = normalizeText(wanted)
            local matches = {}
            for _, card in ipairs(cards) do
                if modifierKeysMatch(card.key, wantedKey) then
                    table.insert(matches, card)
                end
            end
            table.sort(matches, function(a, b)
                if a.tier == b.tier then return a.index < b.index end
                return a.tier > b.tier
            end)
            for _, card in ipairs(matches) do
                if clickCardFromLabel(card.label, card.title, card.index) then
                    State.lastModifierVoteAt = tick()
                    State.modifierPickedForSignature = true
                    print("[AF] Voted priority modifier: " .. card.title .. " (tier " .. tostring(card.tier) .. ")")
                    return true
                end
            end
        end
    end

    if clickCardFromLabel(cards[1].label, cards[1].title, cards[1].index) then
        State.lastModifierVoteAt = tick()
        State.modifierPickedForSignature = true
        print("[AF] Voted fallback modifier: " .. cards[1].title)
        return true
    end
    return false
end

-- =============================================
--  MAIN FARM LOOP
-- =============================================

local function farmLoop()
    while State.running do
        task.wait(0.15)
        if not State.autoFarm then task.wait(0.5); continue end
        if not isInRaidArea() then task.wait(1); continue end

        if State.autoEquipWeapon then equipWeapon() end

        local enemies = getAliveEnemies()

        if #enemies > 0 then
            -- Sort by distance so we always go for the closest target first
            local _, myHRP = getChar()
            if myHRP then
                table.sort(enemies, function(a, b)
                    return (myHRP.Position - a.hrp.Position).Magnitude
                         < (myHRP.Position - b.hrp.Position).Magnitude
                end)
            end

            -- Attack the closest target: teleport ONTO it, then hit it.
            local target = enemies[1]
            local _, hrp = getChar()
            if hrp and target.hrp then
                -- Teleport right next to the enemy every loop so we never
                -- get stuck standing in one spot away from them.
                hrp.CFrame = target.hrp.CFrame * CFrame.new(0, 0, 4)
            end
            task.wait(0.05)
            swingWeapon()
            hitEnemy(target.uuid)
            task.wait(0.05)
            swingWeapon()

            -- Also fire a hit on every other nearby enemy so warriors spread out
            for i = 2, math.min(#enemies, 4) do
                hitEnemy(enemies[i].uuid)
            end
        else
            -- No alive enemies detected — could be between waves OR the boss
            -- hasn't registered yet. Sweep the boss area and keep swinging.
            local bossPos = State.selectedRaid.bossPos
            if bossPos then
                local _, hrp = getChar()
                if hrp then
                    local dist = (hrp.Position - bossPos.Position).Magnitude
                    if dist > 12 then
                        hrp.CFrame = bossPos
                        task.wait(0.1)
                    end
                end
            end
            swingWeapon()
            task.wait(0.1)
            swingWeapon()
        end
    end
end

-- =============================================
--  RAID CYCLE LOOP
-- =============================================

local function raidCycleLoop()
    while State.running do
        task.wait(3)
        if not State.autoFarm or not State.autoCreateRaid then continue end
        if not State.selectedRaid.working then continue end

        if isSelectedInvasion() and isInRaidArea() then
            State.inRaid = true
            State.invasionStartAt = 0
        end

        if not isInRaidArea() and not State.inRaid then
            local enemies = getAliveEnemies()
            if #enemies == 0 then
                local raid = State.selectedRaid
                print("[AF] In lobby, starting " .. raid.display .. "...")
                if raid.raidType == "invasion" then
                    State.invasionStartAt = tick()
                end

                if State.autoEquipBestPet then
                    equipBestWarriors()
                    task.wait(0.5)
                end
                if State.autoEquipWeapon then
                    equipWeapon()
                    task.wait(0.3)
                end

                if raid.raidType == "invasion" then
                    -- v10: single reusable sequence (1st run == Nth run)
                    local started = doInvasionStartSequence(raid)
                    if not started then continue end
                else
                    -- BOSS RAID: teleport then Start Raid -> Yes
                    local _, hrp = getChar()
                    if hrp then
                        print("[AF] Teleporting to " .. raid.display .. " portal...")
                        hrp.CFrame = raid.portalPos
                        task.wait(2)
                    end

                    local uiFound = false
                    for attempt = 1, 10 do
                        for _, obj in ipairs(pgui:GetDescendants()) do
                            if obj:IsA("TextLabel") and obj.Visible then
                                if string.find(string.lower(obj.Text), raid.startText, 1, true) then
                                    uiFound = true
                                    break
                                end
                            end
                        end
                        if uiFound then break end
                        task.wait(0.5)
                    end

                    if not uiFound then
                        print("[AF] Raid UI didn't appear, retrying...")
                        continue
                    end

                    createRaid()
                    task.wait(4)
                end

                -- Wait for teleport into raid
                local waited = 0
                while not isInRaidArea() and waited < 20 do
                    task.wait(0.5)
                    waited = waited + 0.5
                end

                if isInRaidArea() then
                    print("[AF] In raid area!")
                    task.wait(1)

                    for attempt = 1, 6 do
                        if clickByText("start") then
                            print("[AF] Clicked Start inside raid!")
                            break
                        end
                        task.wait(0.5)
                    end

                    startLobby()
                    task.wait(2)

                    if State.autoEquipWeapon then equipWeapon() end
                    State.inRaid = true
                    State.invasionStartAt = 0
                    if raid.raidType == "invasion" then moveToInvasionHold("started") end
                    print("[AF] Farming started!")
                else
                    if raid.raidType == "invasion" then
                        State.inRaid = false
                        print("[AF] Invasion did not start in 20 seconds; retrying from bald hero...")
                    else
                        print("[AF] Failed to enter raid, retrying...")
                    end
                end
            end
        end
    end
end

-- =============================================
--  VICTORY DETECTION LOOP
-- =============================================

local function victoryLoop()
    while State.running do
        task.wait(1)
        if not State.autoFarm then continue end

        if State.inRaid and State.selectedRaid.raidType == "invasion" then
            autoVoteCard()
        end

        local foundVictory = false
        for _, obj in ipairs(pgui:GetDescendants()) do
            if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Visible then
                if obj:IsDescendantOf(pgui:FindFirstChild("AutoFarmGUI")) then continue end
                local t = string.lower(obj.Text)
                if string.find(t, "victory") then
                    foundVictory = true
                    break
                end
            end
        end

        if foundVictory then
            -- Count this run
            State.runCount = (State.runCount or 0) + 1
            print("[AF] Victory detected! Run #" .. State.runCount)
            task.wait(3)

            local raid = State.selectedRaid

            -- IMPORTANT: scrape drops NOW, while the victory screen is still
            -- visible. After we click Continue the rewards panel disappears.
            local dropsText = State.webhookRewards and getVictoryDrops() or "Rewards hidden in settings"

            -- Build the extra webhook fields (drops shown full-width)
            local extra = {
                { name = "Drops", value = dropsText, inline = false },
            }

            if raid.raidType == "invasion" then
                -- Send webhook FIRST (before Continue wipes the screen)
                sendWebhook(
                    "✅ Invasion Complete — Run #" .. State.runCount,
                    "**" .. raid.display .. "** finished successfully!",
                    5763719,
                    extra
                )

                print("[AF] Clicking Continue after invasion...")
                local continued = false
                for attempt = 1, 5 do
                    if clickExact("Continue") then
                        continued = true
                        break
                    end
                    task.wait(1)
                end
                if not continued then
                    clickByText("continue")
                end

                task.wait(2)
                State.inRaid = false
                State.invasionStartAt = 0
                State.lastModifierSignature = ""
                State.modifierPickedForSignature = false
                print("[AF] Invasion continued; returning to bald hero for fresh start.")

            else
                -- Send webhook FIRST (before leaving wipes the screen)
                sendWebhook(
                    "✅ Raid Complete — Run #" .. State.runCount,
                    "**" .. raid.display .. "** finished successfully!",
                    5763719,
                    extra
                )

                leaveRaid()
                print("[AF] Called leaveRaid!")
                task.wait(3)

                if isInRaidArea() then
                    for attempt = 1, 5 do
                        clickExact("Continue")
                        task.wait(1)
                        leaveRaid()
                        if not isInRaidArea() then break end
                    end
                end

                task.wait(2)
                State.inRaid = false
            end
        end

        if State.inRaid and not isInRaidArea() then
            print("[AF] Returned to lobby (teleport detected)")
            State.inRaid = false
        end
    end
end

-- =============================================
--  UTILITY LOOP
-- =============================================

local function utilityLoop()
    while State.running do
        task.wait(3)
        if State.autoClaimAchievement then pcall(claimAchievements) end
        if State.autoEquipWeapon then equipWeapon() end
    end
end

-- =============================================
--  GUI — REDESIGNED
-- =============================================

local oldGui = pgui:FindFirstChild("AutoFarmGUI")
if oldGui then oldGui:Destroy() end

local sg = Instance.new("ScreenGui", pgui)
sg.Name = "AutoFarmGUI"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local C = {
    bg       = Color3.fromRGB(16, 16, 22),
    bgCard   = Color3.fromRGB(24, 24, 34),
    card     = Color3.fromRGB(30, 30, 42),
    cardHi   = Color3.fromRGB(38, 38, 52),
    border   = Color3.fromRGB(48, 48, 66),
    borderHi = Color3.fromRGB(70, 70, 100),
    text     = Color3.fromRGB(225, 225, 235),
    textDim  = Color3.fromRGB(100, 100, 125),
    textMid  = Color3.fromRGB(160, 160, 180),
    accent1  = Color3.fromRGB(120, 90, 255),
    accent2  = Color3.fromRGB(60, 200, 160),
    accent3  = Color3.fromRGB(255, 180, 50),
    accent4  = Color3.fromRGB(255, 80, 120),
    accent5  = Color3.fromRGB(80, 160, 255),
    green    = Color3.fromRGB(50, 205, 110),
    red      = Color3.fromRGB(220, 60, 70),
    toggleOff = Color3.fromRGB(50, 50, 65),
}

local floatBtn = Instance.new("TextButton", sg)
floatBtn.Size = UDim2.new(0, 44, 0, 44)
floatBtn.Position = UDim2.new(0, 8, 0.35, 0)
floatBtn.BackgroundColor3 = C.accent1; floatBtn.Text = ""
floatBtn.TextColor3 = Color3.new(1,1,1); floatBtn.TextSize = 14
floatBtn.Font = Enum.Font.GothamBold; floatBtn.BorderSizePixel = 0; floatBtn.ZIndex = 100
Instance.new("UICorner", floatBtn).CornerRadius = UDim.new(0, 14)
local floatStroke = Instance.new("UIStroke", floatBtn)
floatStroke.Color = Color3.fromRGB(160, 140, 255); floatStroke.Thickness = 1.5; floatStroke.Transparency = 0.4
local floatIcon = Instance.new("TextLabel", floatBtn)
floatIcon.Size = UDim2.new(1,0,1,0); floatIcon.BackgroundTransparency = 1
floatIcon.Text = "AF"; floatIcon.TextColor3 = Color3.new(1,1,1)
floatIcon.TextSize = 13; floatIcon.Font = Enum.Font.GothamBold; floatIcon.ZIndex = 101

local mainFrame
local fDrag = {on=false, s=nil, p=nil}
floatBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        fDrag.on=true; fDrag.s=i.Position; fDrag.p=floatBtn.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End and fDrag.on then
                local d = i.Position - fDrag.s
                if math.abs(d.X)+math.abs(d.Y) < 10 then
                    State.guiVisible = not State.guiVisible
                    mainFrame.Visible = State.guiVisible
                    if State.guiVisible then
                        floatBtn.BackgroundColor3 = C.accent1
                        floatIcon.Text = "AF"
                    else
                        floatBtn.BackgroundColor3 = C.accent3
                        floatIcon.Text = "AF"
                    end
                end
                fDrag.on = false
            end
        end)
    end
end)
UIS.InputChanged:Connect(function(i)
    if fDrag.on and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
        local d = i.Position - fDrag.s
        floatBtn.Position = UDim2.new(fDrag.p.X.Scale, fDrag.p.X.Offset+d.X, fDrag.p.Y.Scale, fDrag.p.Y.Offset+d.Y)
    end
end)

mainFrame = Instance.new("Frame", sg)
mainFrame.Name = "Main"; mainFrame.Size = UDim2.new(0, 260, 0, 460)
mainFrame.Position = UDim2.new(0.5, -130, 0.5, -230)
mainFrame.BackgroundColor3 = C.bg; mainFrame.BorderSizePixel = 0
mainFrame.Visible = true; mainFrame.ZIndex = 50
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)
local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = C.border; mainStroke.Thickness = 1; mainStroke.Transparency = 0.3

local titleBar = Instance.new("Frame", mainFrame)
titleBar.Size = UDim2.new(1,0,0,44); titleBar.BackgroundColor3 = Color3.fromRGB(22, 20, 35)
titleBar.BorderSizePixel = 0; titleBar.ZIndex = 51
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 16)
local titleFill = Instance.new("Frame", titleBar); titleFill.Size = UDim2.new(1,0,0,16)
titleFill.Position = UDim2.new(0,0,1,-16); titleFill.BackgroundColor3 = Color3.fromRGB(22, 20, 35)
titleFill.BorderSizePixel = 0; titleFill.ZIndex = 51
local accentLine = Instance.new("Frame", titleBar)
accentLine.Size = UDim2.new(0.6, 0, 0, 2); accentLine.Position = UDim2.new(0.02, 0, 1, -1)
accentLine.BackgroundColor3 = C.accent1; accentLine.BorderSizePixel = 0; accentLine.ZIndex = 52
Instance.new("UICorner", accentLine).CornerRadius = UDim.new(1, 0)

local tt = Instance.new("TextLabel", titleBar); tt.Size = UDim2.new(1,-50,1,0); tt.Position = UDim2.new(0,14,0,0)
tt.BackgroundTransparency = 1; tt.Text = "Auto Farm"; tt.TextColor3 = C.text
tt.TextSize = 16; tt.Font = Enum.Font.GothamBold; tt.TextXAlignment = Enum.TextXAlignment.Left; tt.ZIndex = 52
local verBadge = Instance.new("TextLabel", titleBar)
verBadge.Size = UDim2.new(0, 22, 0, 14); verBadge.Position = UDim2.new(0, 102, 0.5, -7)
verBadge.BackgroundColor3 = C.accent1; verBadge.BackgroundTransparency = 0.7
verBadge.Text = "v10"; verBadge.TextColor3 = Color3.fromRGB(180, 160, 255)
verBadge.TextSize = 9; verBadge.Font = Enum.Font.GothamBold; verBadge.BorderSizePixel = 0; verBadge.ZIndex = 53
Instance.new("UICorner", verBadge).CornerRadius = UDim.new(0, 4)

local cb = Instance.new("TextButton", titleBar); cb.Size = UDim2.new(0,28,0,28); cb.Position = UDim2.new(1,-36,0,8)
cb.BackgroundColor3 = Color3.fromRGB(60, 30, 40); cb.Text = "x"; cb.TextColor3 = C.accent4
cb.TextSize = 14; cb.Font = Enum.Font.GothamBold; cb.BorderSizePixel = 0; cb.ZIndex = 54
Instance.new("UICorner", cb).CornerRadius = UDim.new(0, 8)
cb.MouseButton1Click:Connect(function()
    State.guiVisible = false; mainFrame.Visible = false
    floatBtn.BackgroundColor3 = C.accent3
end)

local db = Instance.new("TextButton", titleBar); db.Size = UDim2.new(1,-40,1,0)
db.BackgroundTransparency = 1; db.Text = ""; db.ZIndex = 53
local mD = {on=false, s=nil, p=nil}
db.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        mD.on=true; mD.s=i.Position; mD.p=mainFrame.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if mD.on and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
        local d = i.Position - mD.s
        mainFrame.Position = UDim2.new(mD.p.X.Scale, mD.p.X.Offset+d.X, mD.p.Y.Scale, mD.p.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then mD.on = false end
end)

local sc = Instance.new("ScrollingFrame", mainFrame)
sc.Size = UDim2.new(1,-4,1,-50); sc.Position = UDim2.new(0,2,0,48)
sc.BackgroundTransparency = 1; sc.BorderSizePixel = 0; sc.ScrollBarThickness = 2
sc.ScrollBarImageColor3 = C.accent1
sc.CanvasSize = UDim2.new(0,0,0,0); sc.AutomaticCanvasSize = Enum.AutomaticSize.Y; sc.ZIndex = 51
local scLayout = Instance.new("UIListLayout", sc)
scLayout.Padding = UDim.new(0, 5); scLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
local pd = Instance.new("UIPadding", sc)
pd.PaddingLeft = UDim.new(0,6); pd.PaddingRight = UDim.new(0,6)
pd.PaddingTop = UDim.new(0,4); pd.PaddingBottom = UDim.new(0,8)

local lo = 0
local function nxt() lo=lo+1; return lo end

local function sec(title, color, icon)
    local f = Instance.new("Frame", sc); f.Size = UDim2.new(1,0,0,22); f.BackgroundTransparency = 1
    f.LayoutOrder = nxt(); f.ZIndex = 51
    local dot = Instance.new("Frame", f); dot.Size = UDim2.new(0,6,0,6)
    dot.Position = UDim2.new(0,2,0.5,-3); dot.BackgroundColor3 = color; dot.BorderSizePixel = 0; dot.ZIndex = 52
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
    local l = Instance.new("TextLabel", f); l.Size = UDim2.new(1,-14,1,0); l.Position = UDim2.new(0,12,0,0)
    l.BackgroundTransparency = 1; l.Text = string.upper(title)
    l.TextColor3 = color; l.TextSize = 9; l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left; l.ZIndex = 52
    local ln = Instance.new("Frame", f); ln.Size = UDim2.new(1,-80,0,1); ln.Position = UDim2.new(0,78,0.5,0)
    ln.BackgroundColor3 = C.border; ln.BackgroundTransparency = 0.5; ln.BorderSizePixel = 0; ln.ZIndex = 51
end

local function tog(label, stateKey, color)
    local h = Instance.new("Frame", sc); h.Size = UDim2.new(1,0,0,40); h.BackgroundColor3 = C.card
    h.BorderSizePixel = 0; h.LayoutOrder = nxt(); h.ZIndex = 51
    Instance.new("UICorner", h).CornerRadius = UDim.new(0, 10)
    local hStroke = Instance.new("UIStroke", h)
    hStroke.Color = C.border; hStroke.Thickness = 1; hStroke.Transparency = 0.6

    local l = Instance.new("TextLabel", h); l.Size = UDim2.new(1,-60,1,0); l.Position = UDim2.new(0,12,0,0)
    l.BackgroundTransparency = 1; l.Text = label; l.TextColor3 = C.textMid
    l.TextSize = 12; l.Font = Enum.Font.Gotham; l.TextXAlignment = Enum.TextXAlignment.Left; l.ZIndex = 52

    local tr = Instance.new("Frame", h); tr.Size = UDim2.new(0,42,0,24); tr.Position = UDim2.new(1,-52,0.5,-12)
    tr.BackgroundColor3 = C.toggleOff; tr.BorderSizePixel = 0; tr.ZIndex = 52
    Instance.new("UICorner", tr).CornerRadius = UDim.new(1, 0)

    local kn = Instance.new("Frame", tr); kn.Size = UDim2.new(0,20,0,20); kn.Position = UDim2.new(0,2,0,2)
    kn.BackgroundColor3 = Color3.fromRGB(120,120,135); kn.BorderSizePixel = 0; kn.ZIndex = 53
    Instance.new("UICorner", kn).CornerRadius = UDim.new(1, 0)

    local b = Instance.new("TextButton", h); b.Size = UDim2.new(1,0,1,0); b.BackgroundTransparency = 1; b.Text = ""; b.ZIndex = 54

    local function upd()
        local on = State[stateKey]
        tr.BackgroundColor3 = on and color or C.toggleOff
        kn.Position = on and UDim2.new(0,20,0,2) or UDim2.new(0,2,0,2)
        kn.BackgroundColor3 = on and Color3.new(1,1,1) or Color3.fromRGB(120,120,135)
        l.TextColor3 = on and C.text or C.textMid
        hStroke.Color = on and color or C.border
        hStroke.Transparency = on and 0.5 or 0.6
        if on then
            h.BackgroundColor3 = Color3.fromRGB(
                math.clamp(C.card.R*255*0.85 + color.R*255*0.15, 0, 255),
                math.clamp(C.card.G*255*0.85 + color.G*255*0.15, 0, 255),
                math.clamp(C.card.B*255*0.85 + color.B*255*0.15, 0, 255))
        else
            h.BackgroundColor3 = C.card
        end
    end
    b.MouseButton1Click:Connect(function() State[stateKey] = not State[stateKey]; upd() end)
    upd()
end

local function drop(label, options, default, onSelect, optColors)
    local h = Instance.new("Frame", sc); h.Size = UDim2.new(1,0,0,52); h.BackgroundColor3 = C.card
    h.BorderSizePixel = 0; h.LayoutOrder = nxt(); h.ClipsDescendants = true; h.ZIndex = 51
    Instance.new("UICorner", h).CornerRadius = UDim.new(0, 10)
    local hStroke2 = Instance.new("UIStroke", h)
    hStroke2.Color = C.border; hStroke2.Transparency = 0.5

    local l = Instance.new("TextLabel", h); l.Size = UDim2.new(1,-14,0,14); l.Position = UDim2.new(0,12,0,5)
    l.BackgroundTransparency = 1; l.Text = label; l.TextColor3 = C.textDim
    l.TextSize = 9; l.Font = Enum.Font.GothamBold; l.TextXAlignment = Enum.TextXAlignment.Left; l.ZIndex = 52

    local sf = Instance.new("Frame", h); sf.Size = UDim2.new(1,-16,0,26); sf.Position = UDim2.new(0,8,0,20)
    sf.BackgroundColor3 = Color3.fromRGB(40, 40, 56); sf.BorderSizePixel = 0; sf.ZIndex = 52
    Instance.new("UICorner", sf).CornerRadius = UDim.new(0, 7)

    local arrow = Instance.new("TextLabel", sf); arrow.Size = UDim2.new(0,20,1,0); arrow.Position = UDim2.new(1,-22,0,0)
    arrow.BackgroundTransparency = 1; arrow.Text = "v"; arrow.TextColor3 = C.textDim
    arrow.TextSize = 10; arrow.Font = Enum.Font.GothamBold; arrow.ZIndex = 53

    local st = Instance.new("TextLabel", sf); st.Size = UDim2.new(1,-28,1,0); st.Position = UDim2.new(0,10,0,0)
    st.BackgroundTransparency = 1; st.Text = default or options[1]; st.TextColor3 = C.text
    st.TextSize = 12; st.Font = Enum.Font.GothamBold; st.TextXAlignment = Enum.TextXAlignment.Left; st.ZIndex = 53

    for i, opt in ipairs(options) do
        local ob = Instance.new("TextButton", h); ob.Size = UDim2.new(1,-16,0,34)
        ob.Position = UDim2.new(0,8,0,52+(i-1)*36); ob.BackgroundColor3 = C.cardHi
        ob.Text = ""; ob.BorderSizePixel = 0; ob.ZIndex = 53
        Instance.new("UICorner", ob).CornerRadius = UDim.new(0, 8)

        local oDot = Instance.new("Frame", ob); oDot.Size = UDim2.new(0,8,0,8)
        oDot.Position = UDim2.new(0,10,0.5,-4); oDot.BorderSizePixel = 0; oDot.ZIndex = 54
        oDot.BackgroundColor3 = (optColors and optColors[i]) or C.accent5
        Instance.new("UICorner", oDot).CornerRadius = UDim.new(1,0)

        local oLbl = Instance.new("TextLabel", ob); oLbl.Size = UDim2.new(1,-30,1,0); oLbl.Position = UDim2.new(0,24,0,0)
        oLbl.BackgroundTransparency = 1; oLbl.Text = opt; oLbl.TextColor3 = C.text
        oLbl.TextSize = 12; oLbl.Font = Enum.Font.Gotham; oLbl.TextXAlignment = Enum.TextXAlignment.Left; oLbl.ZIndex = 54

        ob.MouseButton1Click:Connect(function()
            st.Text = opt; h.Size = UDim2.new(1,0,0,52); arrow.Text = "v"
            if onSelect then onSelect(i, opt) end
        end)
    end

    local ca = Instance.new("TextButton", h); ca.Size = UDim2.new(1,0,0,50)
    ca.BackgroundTransparency = 1; ca.Text = ""; ca.ZIndex = 54
    ca.MouseButton1Click:Connect(function()
        local open = h.Size.Y.Offset > 54
        h.Size = open and UDim2.new(1,0,0,52) or UDim2.new(1,0,0,54+#options*36+4)
        arrow.Text = open and "v" or "^"
    end)
end

local function textBox(label, stateKey, placeholder, color)
    local h = Instance.new("Frame", sc); h.Size = UDim2.new(1,0,0,54); h.BackgroundColor3 = C.card
    h.BorderSizePixel = 0; h.LayoutOrder = nxt(); h.ZIndex = 51
    Instance.new("UICorner", h).CornerRadius = UDim.new(0, 10)
    local hStroke = Instance.new("UIStroke", h)
    hStroke.Color = C.border; hStroke.Thickness = 1; hStroke.Transparency = 0.55

    local l = Instance.new("TextLabel", h); l.Size = UDim2.new(1,-14,0,14); l.Position = UDim2.new(0,12,0,5)
    l.BackgroundTransparency = 1; l.Text = label; l.TextColor3 = color or C.textDim
    l.TextSize = 9; l.Font = Enum.Font.GothamBold; l.TextXAlignment = Enum.TextXAlignment.Left; l.ZIndex = 52

    local b = Instance.new("TextBox", h); b.Size = UDim2.new(1,-16,0,26); b.Position = UDim2.new(0,8,0,22)
    b.BackgroundColor3 = Color3.fromRGB(40, 40, 56); b.BorderSizePixel = 0; b.ZIndex = 52
    b.Text = State[stateKey] or ""; b.PlaceholderText = placeholder or ""; b.ClearTextOnFocus = false
    b.TextColor3 = C.text; b.PlaceholderColor3 = C.textDim; b.TextSize = 11; b.Font = Enum.Font.Gotham
    b.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    b.FocusLost:Connect(function()
        State[stateKey] = trimText(b.Text)
        print("[AF] Updated " .. label)
    end)
end

local function info(lines)
    local totalH = 8 + #lines * 16
    local h = Instance.new("Frame", sc); h.Size = UDim2.new(1,0,0,totalH)
    h.BackgroundColor3 = Color3.fromRGB(22, 22, 38); h.BorderSizePixel = 0; h.LayoutOrder = nxt(); h.ZIndex = 51
    Instance.new("UICorner", h).CornerRadius = UDim.new(0, 8)
    local bar = Instance.new("Frame", h); bar.Size = UDim2.new(0,3,0.7,0); bar.Position = UDim2.new(0,0,0.15,0)
    bar.BackgroundColor3 = C.accent1; bar.BorderSizePixel = 0; bar.ZIndex = 52
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)

    for i, ln in ipairs(lines) do
        local lb = Instance.new("TextLabel", h); lb.Size = UDim2.new(1,-18,0,14)
        lb.Position = UDim2.new(0,12,0,3+(i-1)*16); lb.BackgroundTransparency = 1
        lb.Text = ln.t; lb.TextColor3 = ln.c or C.textDim; lb.TextSize = 10
        lb.Font = Enum.Font.Gotham; lb.TextXAlignment = Enum.TextXAlignment.Left; lb.TextWrapped = true; lb.ZIndex = 52
    end
end

local statusHolder = Instance.new("Frame", sc)
statusHolder.Size = UDim2.new(1,0,0,28); statusHolder.BackgroundColor3 = C.bgCard
statusHolder.BorderSizePixel = 0; statusHolder.LayoutOrder = 999; statusHolder.ZIndex = 51
Instance.new("UICorner", statusHolder).CornerRadius = UDim.new(0, 8)
local statusDot = Instance.new("Frame", statusHolder)
statusDot.Size = UDim2.new(0,6,0,6); statusDot.Position = UDim2.new(0,10,0.5,-3)
statusDot.BackgroundColor3 = C.textDim; statusDot.BorderSizePixel = 0; statusDot.ZIndex = 52
Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1,0)
local statusBar = Instance.new("TextLabel", statusHolder)
statusBar.Size = UDim2.new(1,-24,1,0); statusBar.Position = UDim2.new(0,22,0,0)
statusBar.BackgroundTransparency = 1
statusBar.Text = "Idle"; statusBar.TextColor3 = C.textDim
statusBar.TextSize = 10; statusBar.Font = Enum.Font.Gotham
statusBar.TextXAlignment = Enum.TextXAlignment.Left; statusBar.ZIndex = 52

sec("Combat", C.accent5)
tog("Auto equip weapon", "autoEquipWeapon", C.accent5)
tog("Auto use weapon", "autoUseWeapon", C.accent5)
tog("Auto claim achievement", "autoClaimAchievement", C.accent5)

sec("Raid Selection", C.accent4)

local raidNames = {}
for _, r in ipairs(RaidList) do table.insert(raidNames, r.display) end
drop("Select raid", raidNames, RaidList[1].display, function(idx)
    State.selectedRaid = RaidList[idx]
    print("[AF] Selected: " .. State.selectedRaid.display .. " (" .. State.selectedRaid.name .. ")")
end, {C.accent3, C.accent1})

info({
    {t = "Sunshine Lake — boss raid, auto leave", c = C.accent3},
    {t = "Dark Matter — invasion, continue + restart", c = C.accent1},
    {t = "Remotes loaded: " .. rc, c = C.green},
})

sec("Webhook", C.accent2)
tog("Webhook enabled", "webhookEnabled", C.accent2)
textBox("Webhook URL", "webhookUrl", "https://discord.com/api/webhooks/...", C.accent2)
tog("Include rewards", "webhookRewards", C.accent3)

sec("Modifier Priority", C.accent1)
tog("Auto pick modifiers", "autoPickModifiers", C.accent1)
for i = 1, 6 do
    local default = State.modifierPriorities[i] or ModifierOptions[1]
    drop("Priority " .. i, ModifierOptions, default, function(_, opt)
        State.modifierPriorities[i] = opt
        print("[AF] Modifier priority " .. i .. ": " .. opt)
    end, {C.textDim, C.accent4, C.accent3, C.accent1, C.accent2, C.accent5})
end
info({
    {t = "Turn Auto pick modifiers on for invasion cards", c = C.accent1},
    {t = "Priority 1 is picked first when visible", c = C.accent1},
    {t = "Add missing modifier names to ModifierOptions", c = C.textMid},
})

sec("Farm Controls", C.green)
tog("Auto farm", "autoFarm", C.green)
tog("Friend only", "friendOnly", C.accent3)
tog("Auto create raid", "autoCreateRaid", C.accent2)

sec("Warriors", C.accent2)
tog("Auto equip best", "autoEquipBestPet", C.accent2)

task.spawn(farmLoop)
task.spawn(raidCycleLoop)
task.spawn(victoryLoop)
task.spawn(utilityLoop)

task.spawn(function()
    while State.running do
        task.wait(1)
        if State.autoFarm then
            local enemies = getAliveEnemies()
            local inRaid = isInRaidArea()

            if inRaid then
                if #enemies > 0 then
                    statusBar.Text = "Killing " .. #enemies .. " enemies  •  Run " .. (State.runCount or 0)
                    statusBar.TextColor3 = C.accent4
                    statusDot.BackgroundColor3 = C.accent4
                else
                    statusBar.Text = "Boss phase — swinging  •  Run " .. (State.runCount or 0)
                    statusBar.TextColor3 = C.accent1
                    statusDot.BackgroundColor3 = C.accent1
                end
            else
                if State.autoCreateRaid then
                    statusBar.Text = "Lobby — creating " .. State.selectedRaid.display
                    statusBar.TextColor3 = C.accent2
                    statusDot.BackgroundColor3 = C.accent2
                else
                    statusBar.Text = "Lobby — waiting  •  Runs: " .. (State.runCount or 0)
                    statusBar.TextColor3 = C.textDim
                    statusDot.BackgroundColor3 = C.textDim
                end
            end
        else
            statusBar.Text = "Idle — turn on Auto Farm"
            statusBar.TextColor3 = C.textDim
            statusDot.BackgroundColor3 = C.textDim
        end
    end
end)

player.CharacterAdded:Connect(function()
    task.wait(2)
    if State.autoEquipWeapon then equipWeapon() end
    if State.autoEquipBestPet then equipBestWarriors() end
end)

print("===========================================")
print("  Auto Farm v10 loaded!")
print("  Sunshine: hardened Start->Yes (no more freeze)")
print("  Dark Matter: reliable Lead-me on every restart")
print("  Invasion start is one reusable sequence")
print("===========================================")
