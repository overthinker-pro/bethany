$files = @(
    "css/base.css",
    "css/main.css",
    "js/main.js",
    "js/plugins.js"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        $originalSize = (Get-Item $file).Length
        Write-Host "Minifying $file ($originalSize bytes)..."
        $content = Get-Content $file -Raw
        
        # Backup
        Copy-Item $file "$file.bak" -Force

        if ($file -like "*.css") {
            # CSS Minification
            # Remove comments
            $content = $content -replace '/\*[\s\S]*?\*/', ''
            # Collapse whitespace to single space
            $content = $content -replace '\s+', ' '
            # Remove space around delimiters
            $content = $content -replace '\s?([{:;}])\s?', '$1'
            # Remove last semicolon in block
            $content = $content -replace ';\}', '}'
        }
        elseif ($file -like "*.js") {
            # JS Safe Minification
            # Remove block comments
            $content = $content -replace '/\*[\s\S]*?\*/', ''
            
            # Split lines, trim whitespace, remove empty lines
            # logic: split by newline, trim each line, filter out empty lines, join with newline
            # This preserves line breaks (safe for ASI) but removes indentation (large saving)
            $lines = $content -split "\r?\n" 
            $newLines = @()
            foreach ($line in $lines) {
                $trimmed = $line.Trim()
                if ($trimmed.Length -gt 0) {
                    $newLines += $trimmed
                }
            }
            $content = $newLines -join "`n"
        }

        Set-Content -Path $file -Value $content -NoNewline
        $newSize = (Get-Item $file).Length
        Write-Host "Minified $file : $originalSize -> $newSize bytes"
    }
    else {
        Write-Host "File not found: $file"
    }
}
