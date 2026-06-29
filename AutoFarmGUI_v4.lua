-- === Deep Treasure Hunt UI + State Scanner ===

local player = game.Players.LocalPlayer
local pgui = player:WaitForChild("PlayerGui")

local sg = pgui:FindFirstChild("TH_Explorer")
local output = sg and sg.Window.ScrollingFrame.Output
local logText = ""
local function log(msg)
    logText = logText .. msg .. "\n"
    if output then output.Text = logText end
end

-- 1) Deep scan inside "app" and "popups" for treasure hunt UI
log("====== DEEP GUI SCAN (app + popups) ======")
for _, guiName in pairs({"app", "popups", "absolute"}) do
    local g = pgui:FindFirstChild(guiName)
    if g then
        for _, desc in pairs(g:GetDescendants()) do
            local n = desc.Name:lower()
            if n:find("treasure") or n:find("hunt") or n:find("dig") or n:find("shovel") or n:find("board") or n:find("tile") or n:find("grid") then
                local vis = "N/A"
                pcall(function() vis = tostring(desc.Visible) end)
                log("[" .. guiName .. "] " .. desc:GetFullName())
                log("  Class: " .. desc.ClassName .. " | Visible: " .. vis)
            end
        end
    end
end

-- 2) Scan ALL client ModuleScripts for treasure hunt references
log("\n====== CLIENT MODULES (treasure/hunt/dig) ======")
local searchRoots = {
    game:GetService("ReplicatedStorage"),
    game:GetService("StarterPlayer"),
}
for _, root in pairs(searchRoots) do
    for _, desc in pairs(root:GetDescendants()) do
        if desc:IsA("ModuleScript") then
            local n = desc.Name:lower()
            if n:find("treasure") or n:find("hunt") or n:find("dig") or n:find("shovel") then
                log(desc:GetFullName() .. " | " .. desc.ClassName)
            end
        end
    end
end

-- 3) Look for Charm atoms / stores
log("\n====== CHARM STATE SEARCH ======")
for _, desc in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
    local n = desc.Name:lower()
    if n:find("atom") or n:find("store") or n:find("state") or n:find("charm") then
        log(desc:GetFullName() .. " | " .. desc.ClassName)
    end
end

-- 4) Check if there's a "page" or "tab" or "panel" system in app
log("\n====== PAGE/TAB/PANEL SYSTEM ======")
local appGui = pgui:FindFirstChild("app")
if appGui then
    for _, desc in pairs(appGui:GetDescendants()) do
        local n = desc.Name:lower()
        if n:find("page") or n:find("panel") or n:find("tab") or n:find("screen") or n:find("modal") or n:find("overlay") then
            if desc:IsA("Frame") or desc:IsA("ScreenGui") or desc:IsA("ScrollingFrame") then
                local vis = "N/A"
                pcall(function() vis = tostring(desc.Visible) end)
                log(desc.Name .. " | " .. desc.ClassName .. " | Vis: " .. vis)
                log("  " .. desc:GetFullName())
            end
        end
    end
end

-- 5) Try to find the require path for treasure hunt module
log("\n====== REQUIRE SEARCH (node_modules) ======")
local remoContainer = game:GetService("ReplicatedStorage"):FindFirstChild("rbxts_include", true)
if remoContainer then
    for _, desc in pairs(remoContainer:GetDescendants()) do
        if desc:IsA("ModuleScript") then
            local n = desc.Name:lower()
            if n:find("treasure") or n:find("hunt") then
                log(desc:GetFullName())
            end
        end
    end
end

log("\n====== DONE ======")

if setclipboard then
    setclipboard(logText)
    log("\n[Auto-copied to clipboard]")
end
