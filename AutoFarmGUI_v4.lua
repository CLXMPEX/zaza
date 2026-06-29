local TERMS = {
	"Treasure","TreasureHunt","Treasure Hunt","Hunt","Dig","Shovel",
	"Water Goddess","Goddess","Tier","Found","Reward","Clam"
}

local function addUnique(t, v)
	for _, x in ipairs(t) do if x == v then return end end
	table.insert(t, v)
end

local function countText(src, term)
	local _, n = src:lower():gsub(term:lower():gsub("([^%w])","%%%1"), "")
	return n
end

local function scoreScript(obj, extraTerms)
	local ok, src = pcall(function() return obj.Source end)
	if not ok or type(src) ~= "string" then return nil end

	local terms = table.clone(TERMS)
	for term in (extraTerms or ""):gmatch("[^,]+") do
		term = term:gsub("^%s+",""):gsub("%s+$","")
		if term ~= "" then table.insert(terms, term) end
	end

	local score, matches = 0, {}
	local name = obj.Name:lower()

	for _, term in ipairs(terms) do
		if name:find(term:lower(), 1, true) then
			score += 6
			addUnique(matches, "name:" .. term)
		end

		local n = countText(src, term)
		if n > 0 then
			score += math.min(12, n * 2)
			addUnique(matches, term .. " x" .. n)
		end
	end

	local checks = {
		{"interaction hook", "ProximityPrompt|ClickDetector|Touched|InputBegan", 4},
		{"remote call", "RemoteEvent|RemoteFunction|FireServer|InvokeServer|OnServerEvent|OnClientEvent", 4},
		{"UI open/close", "Visible%s*=|Enabled%s*=|ScreenGui|Frame", 3},
		{"NPC/dialogue", "Dialogue|Dialog|Quest|NPC", 3},
	}

	for _, c in ipairs(checks) do
		if src:find(c[2]) then
			score += c[3]
			addUnique(matches, c[1])
		end
	end

	if score <= 0 then return nil end

	local lines, lineNo = {}, 0
	for line in (src .. "\n"):gmatch("([^\n]*)\n") do
		lineNo += 1
		local l = line:lower()
		if l:find("treasure") or l:find("hunt") or l:find("dig") or l:find("shovel")
			or l:find("dialog") or l:find("npc") or l:find("fireserver")
			or l:find("visible") or l:find("enabled") then
			table.insert(lines, lineNo .. ": " .. line:gsub("^%s+",""):sub(1,140))
		end
		if #lines >= 6 then break end
	end

	return {
		score = score,
		path = obj:GetFullName(),
		matches = table.concat(matches, ", "),
		lines = lines,
	}
end

local gui = Instance.new("ScreenGui")
gui.Name = "TreasureHuntFinder"
gui.ResetOnSpawn = false
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = game.Players.LocalPlayer.PlayerGui end

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(720, 500)
frame.Position = UDim2.fromScale(.5, .5)
frame.AnchorPoint = Vector2.new(.5, .5)
frame.BackgroundColor3 = Color3.fromRGB(28,31,38)
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,-60,0,40)
title.Position = UDim2.fromOffset(16,8)
title.BackgroundTransparency = 1
title.Text = "Treasure Hunt Script Finder"
title.TextColor3 = Color3.new(1,1,1)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left

local extra = Instance.new("TextBox", frame)
extra.Position = UDim2.fromOffset(16,56)
extra.Size = UDim2.new(1,-236,0,34)
extra.PlaceholderText = "Extra words, comma separated"
extra.Text = ""
extra.ClearTextOnFocus = false
extra.TextXAlignment = Enum.TextXAlignment.Left

local scan = Instance.new("TextButton", frame)
scan.Position = UDim2.new(1,-212,0,56)
scan.Size = UDim2.fromOffset(90,34)
scan.Text = "Scan"

local copy = Instance.new("TextButton", frame)
copy.Position = UDim2.new(1,-112,0,56)
copy.Size = UDim2.fromOffset(90,34)
copy.Text = "Copy"

local out = Instance.new("TextBox", frame)
out.Position = UDim2.fromOffset(16,104)
out.Size = UDim2.new(1,-32,1,-120)
out.MultiLine = true
out.ClearTextOnFocus = false
out.TextXAlignment = Enum.TextXAlignment.Left
out.TextYAlignment = Enum.TextYAlignment.Top
out.Font = Enum.Font.Code
out.TextSize = 14
out.Text = "Press Scan."
out.BackgroundColor3 = Color3.fromRGB(18,21,27)
out.TextColor3 = Color3.fromRGB(235,235,235)

scan.MouseButton1Click:Connect(function()
	local results = {}

	for _, obj in ipairs(game:GetDescendants()) do
		if obj:IsA("LuaSourceContainer") then
			local r = scoreScript(obj, extra.Text)
			if r then table.insert(results, r) end
		end
	end

	table.sort(results, function(a,b) return a.score > b.score end)

	local text = {"Treasure Hunt Finder Results", ""}
	for i, r in ipairs(results) do
		if i > 25 then break end
		table.insert(text, ("[%d] Score %d: %s"):format(i, r.score, r.path))
		table.insert(text, "Matches: " .. r.matches)
		for _, line in ipairs(r.lines) do table.insert(text, "  " .. line) end
		table.insert(text, "")
	end

	out.Text = #results > 0 and table.concat(text, "\n") or "No likely scripts found."
end)

copy.MouseButton1Click:Connect(function()
	if typeof(setclipboard) == "function" then
		setclipboard(out.Text)
	else
		out:CaptureFocus()
		out.CursorPosition = 1
		out.SelectionStart = #out.Text + 1
	end
end)
