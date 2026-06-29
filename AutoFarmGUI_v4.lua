param(
    [string]$Path = ".",
    [string[]]$ExtraTerms = @()
)

$terms = @(
    "Treasure", "TreasureHunt", "Treasure Hunt", "Hunt",
    "Dig", "Shovel", "Water Goddess", "Goddess",
    "Tier", "Found", "Reward", "Clam"
) + $ExtraTerms

$extensions = @(".lua", ".luau", ".json", ".rbxlx", ".rbxmx", ".txt")

function Score-File($file, $text) {
    $score = 0
    $matches = @()

    foreach ($term in $terms) {
        if ($file.Name -match [regex]::Escape($term)) {
            $score += 6
            $matches += "name:$term"
        }

        $count = ([regex]::Matches($text, [regex]::Escape($term), "IgnoreCase")).Count
        if ($count -gt 0) {
            $score += [Math]::Min(12, $count * 2)
            $matches += "$term x$count"
        }
    }

    if ($text -match "ProximityPrompt|ClickDetector|InputBegan") { $score += 4; $matches += "interaction hook" }
    if ($text -match "FireServer|InvokeServer|OnServerEvent|OnClientEvent") { $score += 4; $matches += "remote call" }
    if ($text -match "Visible\s*=|Enabled\s*=|ScreenGui|Frame") { $score += 3; $matches += "UI open/close" }
    if ($text -match "Dialogue|Dialog|Quest|NPC") { $score += 3; $matches += "NPC/dialogue" }

    [pscustomobject]@{
        Score = $score
        Matches = ($matches | Select-Object -Unique) -join ", "
    }
}

$files = Get-ChildItem -LiteralPath $Path -Recurse -File |
    Where-Object {
        $extensions -contains $_.Extension.ToLowerInvariant() -or
        $_.Name.ToLowerInvariant().EndsWith(".client.lua") -or
        $_.Name.ToLowerInvariant().EndsWith(".server.lua") -or
        $_.Name.ToLowerInvariant().EndsWith(".module.lua")
    }

$results = foreach ($file in $files) {
    if ($file.Length -gt 10MB) { continue }

    try {
        $text = Get-Content -LiteralPath $file.FullName -Raw
        $score = Score-File $file $text

        if ($score.Score -gt 0) {
            [pscustomobject]@{
                Score = $score.Score
                File = $file.FullName
                Matches = $score.Matches
            }
        }
    } catch {}
}

$results |
    Sort-Object Score -Descending |
    Select-Object -First 25 |
    Format-Table -AutoSize
