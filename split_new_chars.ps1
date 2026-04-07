Add-Type -AssemblyName System.Drawing

$srcPath = Join-Path $PSScriptRoot "new_chars_raw.jpg"
if (-not (Test-Path $srcPath)) {
    Write-Host "Error: $srcPath not found."
    exit
}

$bmp = [System.Drawing.Bitmap]::new($srcPath)
$w = $bmp.Width
$h = $bmp.Height
Write-Host "Image size: ${w}x${h}"

# The image has 4 characters. We can simply split it into 4 equal segments. 
$colWidth = [int]($w / 4)

$names = @("npc_chancellor", "npc_inn", "npc_ai", "npc_princess")

function MakeTransparent([System.Drawing.Bitmap]$crop) {
    [int]$cropW = $crop.Width
    [int]$cropH = $crop.Height
    $transparent = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
    
    $visited = New-Object 'bool[,]' $cropW, $cropH
    $queue = New-Object System.Collections.Generic.Queue[string]
    
    $checkAndEnqueue = {
        param([int]$x, [int]$y)
        if (-not $visited[$x, $y]) {
            $px = $crop.GetPixel($x, $y)
            $isBg = $false
            if ($px.A -lt 30) {
                $isBg = $true
            } else {
                # Identify the checkerboard (light gray to white with low saturation)
                # It can also have slight color artifacting due to JPEG.
                if ($px.R -gt 110 -and $px.G -gt 110 -and $px.B -gt 110) {
                    $max = [Math]::Max([Math]::Max($px.R, $px.G), $px.B)
                    $min = [Math]::Min([Math]::Min($px.R, $px.G), $px.B)
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
    
    # Optional morphological pass: we'll leave it out unless we see artifacts.
}

for ($i = 0; $i -lt 4; $i++) {
    [int]$startX = $i * $colWidth
    [int]$cropW = $colWidth
    if ($i -eq 3) { $cropW = $w - $startX }
    
    $rect = [System.Drawing.Rectangle]::new($startX, 0, $cropW, $h)
    $crop = $bmp.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    MakeTransparent $crop
    $fileName = Join-Path $PSScriptRoot "$($names[$i]).png"
    $crop.Save($fileName, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host "Saved: $($names[$i]).png ($cropW x $h)"
    $crop.Dispose()
}

$bmp.Dispose()
Write-Host "Finished processing new characters."
