-- === PlayerGui Explorer + Remote Scanner ===

local player = game.Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

-- 1) Dump all ScreenGuis and notable Frames
print("====== SCREENGUI LIST ======")
for _, sg in pairs(gui:GetChildren()) do
    if sg:IsA("ScreenGui") then
        print(sg.Name, "| Enabled:", sg.Enabled)
    end
end

-- 2) Deep search for anything treasure/dig/hunt/shovel related
print("\n====== TREASURE KEYWORD SEARCH (GUI) ======")
local keywords = {"treasure", "dig", "hunt", "shovel", "goddess", "board"}
for _, desc in pairs(gui:GetDescendants()) do
    local n = desc.Name:lower()
    for _, kw in pairs(keywords) do
        if n:find(kw) then
            print(desc:GetFullName(), "| Class:", desc.ClassName, "| Visible:", pcall(function() return desc.Visible end) and desc.Visible or "N/A")
            break
        end
    end
end

-- 3) Scan remotes in common locations
print("\n====== REMOTE SEARCH ======")
local searchIn = {
    game:GetService("ReplicatedStorage"),
    game:GetService("Workspace"),
}
for _, root in pairs(searchIn) do
    for _, desc in pairs(root:GetDescendants()) do
        if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") or desc:IsA("BindableEvent") then
            local n = desc.Name:lower()
            for _, kw in pairs(keywords) do
                if n:find(kw) then
                    print(desc:GetFullName(), "| Class:", desc.ClassName)
                    break
                end
            end
        end
    end
end

-- 4) Dump ALL remotes (in case names are obfuscated)
print("\n====== ALL REMOTES ======")
for _, desc in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
    if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
        print(desc.Name, "->", desc:GetFullName())
    end
end

print("\n====== DONE ======")
