# PowerShell script to resize and compress images
Add-Type -AssemblyName System.Drawing

function Optimize-Image {
    param (
        [string]$FilePath,
        [int]$MaxWidth = 1920,
        [int]$Quality = 75
    )

    try {
        $image = [System.Drawing.Image]::FromFile($FilePath)
        
        # Calculate new dimensions
        $newWidth = $image.Width
        $newHeight = $image.Height

        if ($image.Width -gt $MaxWidth) {
            $newWidth = $MaxWidth
            $newHeight = [math]::Round($image.Height * ($MaxWidth / $image.Width))
        }

        # Create new bitmap
        $bitmap = New-Object System.Drawing.Bitmap($newWidth, $newHeight)
        $graph = [System.Drawing.Graphics]::FromImage($bitmap)
        $graph.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graph.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graph.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graph.DrawImage($image, 0, 0, $newWidth, $newHeight)
        
        # Encoder parameters for quality
        $encoder = [System.Drawing.Imaging.Encoder]::Quality
        $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter($encoder, $Quality)
        $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }

        # Save to temp file
        $tempFile = $FilePath + ".tmp.jpg"
        $bitmap.Save($tempFile, $codec, $encoderParams)

        # Cleanup
        $image.Dispose()
        $bitmap.Dispose()
        $graph.Dispose()

        # Compare sizes
        $origSize = (Get-Item $FilePath).Length
        $newSize = (Get-Item $tempFile).Length

        if ($newSize -lt $origSize) {
            Move-Item $tempFile $FilePath -Force
            Write-Host "Optimized: $(Split-Path $FilePath -Leaf) | OLD: $([math]::Round($origSize/1MB, 2))MB -> NEW: $([math]::Round($newSize/1MB, 2))MB"
        } else {
            Remove-Item $tempFile
            Write-Host "Skipped (No savings): $(Split-Path $FilePath -Leaf)"
        }
    }
    catch {
        Write-Host "Error processing $FilePath : $_"
    }
}

# Find and process images
$images = Get-ChildItem -Path "images" -Recurse -Include *.jpg,*.jpeg,*.png
foreach ($img in $images) {
    # Only process if file size is > 500KB to be safe and efficient
    if ($img.Length -gt 500KB) {
        Optimize-Image -FilePath $img.FullName
    }
}
