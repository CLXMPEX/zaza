-- === Find Dig Remote (debug) ===

local RS = game:GetService("ReplicatedStorage")

-- Method 1: Search ALL descendants for anything named "dig"
print("=== ALL INSTANCES NAMED 'dig' ===")
for _, desc in pairs(RS:GetDescendants()) do
    if desc.Name == "dig" then
        print("FOUND: " .. desc:GetFullName() .. " | " .. desc.ClassName)
    end
end

-- Method 2: Walk the path step by step
print("\n=== PATH WALK ===")
local step = RS
local pathParts = {"rbxts_include", "node_modules", "@rbxts", "remo", "src", "container", "treasureHunt", "dig"}
for _, part in ipairs(pathParts) do
    if step then
        step = step:FindFirstChild(part)
        print(part .. " -> " .. (step and step.ClassName or "NIL"))
    else
        print(part .. " -> PARENT WAS NIL")
    end
end

-- Method 3: List children of container
print("\n=== CONTAINER CHILDREN ===")
local container
for _, desc in pairs(RS:GetDescendants()) do
    if desc.Name == "container" and desc:GetFullName():find("remo") then
        container = desc
        break
    end
end
if container then
    for _, child in pairs(container:GetChildren()) do
        if child.Name:lower():find("treasure") then
            print("Found: " .. child.Name .. " | " .. child.ClassName)
            for _, sub in pairs(child:GetChildren()) do
                print("  " .. sub.Name .. " | " .. sub.ClassName)
            end
        end
    end
end
