Add-Type -AssemblyName System.Drawing

$srcPath = Join-Path $PSScriptRoot "characters.png"
$bmp = [System.Drawing.Bitmap]::new($srcPath)
$w = $bmp.Width
$h = $bmp.Height
Write-Host "Image size: ${w}x${h}"

# --- Step 1: Find character column ranges ---
$threshold = 30
$colIsBg = New-Object bool[] $w
for ($x = 0; $x -lt $w; $x++) {
    $bgCount = 0
    for ($y = 0; $y -lt $h; $y++) {
        $px = $bmp.GetPixel($x, $y)
        if ($px.A -lt $threshold -or ($px.R -gt 180 -and $px.G -gt 180 -and $px.B -gt 180)) {
            $bgCount++
        }
    }
    $colIsBg[$x] = ($bgCount -gt ($h * 0.7))
}

$charCols = @()
$inChar = $false; $startX = 0
for ($x = 0; $x -lt $w; $x++) {
    if (-not $colIsBg[$x] -and -not $inChar) { $inChar = $true; $startX = $x }
    elseif ($colIsBg[$x] -and $inChar) { $inChar = $false; $charCols += ,@($startX, ($x - 1)) }
}
if ($inChar) { $charCols += ,@($startX, ($w - 1)) }
Write-Host "Found $($charCols.Count) columns"

[int]$rowH = [int]($h / 2)

$topNames = @("player_front", "player_side", "player_back", "npc_scholar", "npc_demonking", "npc_priest", "npc_woman")
$bottomNames = @("npc_assassin", "npc_elf", "npc_dwarf", "npc_king", "npc_villager", "npc_mayor", "npc_soldier")

function MakeTransparent([System.Drawing.Bitmap]$crop) {
    [int]$cropW = $crop.Width
    [int]$cropH = $crop.Height
    $transparent = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
    
    $visited = New-Object 'bool[,]' $cropW, $cropH
    $queue = New-Object System.Collections.Generic.Queue[string]
    
    # helper block to check if background
    $checkAndEnqueue = {
        param([int]$x, [int]$y)
        if (-not $visited[$x, $y]) {
            $px = $crop.GetPixel($x, $y)
            $isBg = $false
            if ($px.A -lt 30) {
                $isBg = $true
            } else {
                # Checkerboard includes white, gray, and jpeg artifacts (red/blue tinges)
                if ($px.R -gt 110 -and $px.G -gt 110 -and $px.B -gt 110) {
                    $max = [Math]::Max([Math]::Max($px.R, $px.G), $px.B)
                    $min = [Math]::Min([Math]::Min($px.R, $px.G), $px.B)
                    # Low saturation implies grayscale checkerboard
                    if (($max - $min) -lt 80) {
                        $isBg = $true
                    }
                }
            }
            if ($isBg) {
                $visited[$x, $y] = $true
                $queue.Enqueue("$x,$y")
            }
        }
    }
    
    # Start flood fill from ALL boundary pixels
    for ([int]$x = 0; $x -lt $cropW; $x++) {
        & $checkAndEnqueue $x 0
        & $checkAndEnqueue $x ($cropH - 1)
    }
    for ([int]$y = 0; $y -lt $cropH; $y++) {
        & $checkAndEnqueue 0 $y
        & $checkAndEnqueue ($cropW - 1) $y
    }
    
    while ($queue.Count -gt 0) {
        $coords = $queue.Dequeue().Split(',')
        [int]$cx = $coords[0]
        [int]$cy = $coords[1]
        $crop.SetPixel($cx, $cy, $transparent)
        
        $neighbors = @(
            @(($cx - 1), $cy),
            @(($cx + 1), $cy),
            @($cx, ($cy - 1)),
            @($cx, ($cy + 1))
        )
        foreach ($n in $neighbors) {
            [int]$nx = $n[0]
            [int]$ny = $n[1]
            if ($nx -ge 0 -and $nx -lt $cropW -and $ny -ge 0 -and $ny -lt $cropH) {
                & $checkAndEnqueue $nx $ny
            }
        }
    }
}

for ($i = 0; $i -lt [Math]::Min($charCols.Count, 7); $i++) {
    [int]$cx = $charCols[$i][0]
    [int]$cw2 = $charCols[$i][1] - $charCols[$i][0] + 1

    # Top row
    $topRect = [System.Drawing.Rectangle]::new($cx, 0, $cw2, $rowH)
    $topCrop = $bmp.Clone($topRect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    MakeTransparent $topCrop
    $topFile = Join-Path $PSScriptRoot "$($topNames[$i]).png"
    $topCrop.Save($topFile, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host "Saved: $($topNames[$i]).png ($cw2 x $rowH)"
    $topCrop.Dispose()

    # Bottom row
    $botRect = [System.Drawing.Rectangle]::new($cx, $rowH, $cw2, $rowH)
    $botCrop = $bmp.Clone($botRect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    MakeTransparent $botCrop
    $botFile = Join-Path $PSScriptRoot "$($bottomNames[$i]).png"
    $botCrop.Save($botFile, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host "Saved: $($bottomNames[$i]).png ($cw2 x $rowH)"
    $botCrop.Dispose()
}

$bmp.Dispose()
Write-Host "`nDone! Advanced flood-fill transparency applied correctly."
