param([Parameter(Mandatory=$true)][string]$ManifestPath)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$entries = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
$iconFolder = Join-Path $PSScriptRoot 'icons'
New-Item -ItemType Directory -Path $iconFolder -Force | Out-Null
$report = @()
foreach ($entry in $entries) {
    $source = [System.Drawing.Image]::FromFile($entry.source)
    $bitmap = [System.Drawing.Bitmap]::new(512, 512, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $attributes = [System.Drawing.Imaging.ImageAttributes]::new()
    try {
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $attributes.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
        $graphics.DrawImage($source, [System.Drawing.Rectangle]::new(0,0,512,512), 0,0,$source.Width,$source.Height,[System.Drawing.GraphicsUnit]::Pixel,$attributes)
        $destination = Join-Path $iconFolder $entry.file
        $bitmap.Save($destination, [System.Drawing.Imaging.ImageFormat]::Png)
        $report += [pscustomobject]@{ file=$entry.file; width=512; height=512; cornerAlpha=$bitmap.GetPixel(0,0).A; bytes=(Get-Item -LiteralPath $destination).Length }
    } finally {
        $attributes.Dispose(); $graphics.Dispose(); $bitmap.Dispose(); $source.Dispose()
    }
}
$report | ConvertTo-Json
