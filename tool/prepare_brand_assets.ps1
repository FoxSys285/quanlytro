param(
    [string]$SourcePath = (Join-Path $PSScriptRoot '../assets/branding/tropremium_master.png')
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sourceImage = [System.Drawing.Bitmap]::FromFile((Resolve-Path -LiteralPath $SourcePath).Path)
# Trim the transparent outer margin of the extracted master, including stray edge pixels.
$crop = [System.Drawing.Rectangle]::new(24, 24, $sourceImage.Width - 48, $sourceImage.Height - 48)

function New-BrandBitmap {
    param([int]$Size, [double]$Scale = 1.0, [switch]$Opaque)
    $bitmap = [System.Drawing.Bitmap]::new($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        if ($Opaque) { $graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#0B6954')) }
        else { $graphics.Clear([System.Drawing.Color]::Transparent) }
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $side = [int][Math]::Round($Size * $Scale)
        $offset = [int][Math]::Round(($Size - $side) / 2)
        $target = [System.Drawing.Rectangle]::new($offset, $offset, $side, $side)
        $graphics.DrawImage($sourceImage, $target, $crop, [System.Drawing.GraphicsUnit]::Pixel)
    } finally { $graphics.Dispose() }
    return ,$bitmap
}

function Save-BrandPng {
    param([string]$RelativePath, [int]$Size, [double]$Scale = 1.0, [switch]$Opaque)
    $destination = Join-Path $projectRoot $RelativePath
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($destination)) | Out-Null
    $bitmap = New-BrandBitmap -Size $Size -Scale $Scale -Opaque:$Opaque
    try { $bitmap.Save($destination, [System.Drawing.Imaging.ImageFormat]::Png) }
    finally { $bitmap.Dispose() }
}

try {
    Save-BrandPng 'assets/images/tropremium_logo.png' 1024
    $densities = @(
        @{ Name = 'mdpi'; Size = 48; Canvas = 108 },
        @{ Name = 'hdpi'; Size = 72; Canvas = 162 },
        @{ Name = 'xhdpi'; Size = 96; Canvas = 216 },
        @{ Name = 'xxhdpi'; Size = 144; Canvas = 324 },
        @{ Name = 'xxxhdpi'; Size = 192; Canvas = 432 }
    )
    foreach ($density in $densities) {
        Save-BrandPng "android/app/src/main/res/mipmap-$($density.Name)/ic_launcher.png" $density.Size 0.94
        # A 54dp rounded badge fits wholly inside the central 66dp safe circle.
        Save-BrandPng "android/app/src/main/res/drawable-$($density.Name)/ic_launcher_foreground.png" $density.Canvas 0.5
        Save-BrandPng "android/app/src/main/res/drawable-$($density.Name)/launch_logo.png" ($density.Size * 3)
    }
    foreach ($size in @(192, 512)) {
        Save-BrandPng "web/icons/Icon-$size.png" $size 0.94
        Save-BrandPng "web/icons/Icon-maskable-$size.png" $size 0.64 -Opaque
    }
    Save-BrandPng 'web/favicon.png' 48

    # An ICO containing PNG frames gives Windows sharp icons at every common display scale.
    $frames = @()
    foreach ($size in @(16, 24, 32, 48, 64, 128, 256)) {
        $bitmap = New-BrandBitmap -Size $size -Scale 0.94
        $stream = [System.IO.MemoryStream]::new()
        try {
            $bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
            $frames += @{ Size = $size; Data = $stream.ToArray() }
        } finally {
            $stream.Dispose()
            $bitmap.Dispose()
        }
    }
    $iconPath = Join-Path $projectRoot 'windows/runner/resources/app_icon.ico'
    $writer = [System.IO.BinaryWriter]::new([System.IO.File]::Create($iconPath))
    try {
        $writer.Write([uint16]0)
        $writer.Write([uint16]1)
        $writer.Write([uint16]$frames.Count)
        $offset = 6 + 16 * $frames.Count
        foreach ($frame in $frames) {
            $dimension = if ($frame.Size -eq 256) { 0 } else { $frame.Size }
            $writer.Write([byte]$dimension)
            $writer.Write([byte]$dimension)
            $writer.Write([byte]0)
            $writer.Write([byte]0)
            $writer.Write([uint16]1)
            $writer.Write([uint16]32)
            $writer.Write([uint32]$frame.Data.Length)
            $writer.Write([uint32]$offset)
            $offset += $frame.Data.Length
        }
        foreach ($frame in $frames) { $writer.Write([byte[]]$frame.Data) }
    } finally { $writer.Dispose() }
} finally { $sourceImage.Dispose() }
Write-Output 'Updated TroPremium logo, Android launcher/splash, web icons, and Windows icon.'
