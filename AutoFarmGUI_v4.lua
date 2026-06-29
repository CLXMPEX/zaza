local ReplicatedStorage = game:GetService("ReplicatedStorage")

local words = {
	"treasure", "hunt", "dig", "event", "open", "start",
	"dialogue", "dialog", "npc", "goddess"
}

local results = {}

for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
	if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then
		local path = obj:GetFullName()
		local lower = path:lower()

		for _, word in ipairs(words) do
			if lower:find(word, 1, true) then
				table.insert(results, obj.ClassName .. " | " .. path)
				break
			end
		end
	end
end

table.sort(results)

print("=== TREASURE / NPC REMOTES ===")
for i, line in ipairs(results) do
	print("[" .. i .. "] " .. line)
end
print("=== END ===")
