# Install ngrok (Corrected path handling)
$ngrokUrl = "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip"
$ngrokZipPath = "ngrok.zip"
$ngrokExtractPath = "$PSScriptRoot\ngrok"  # Extract to a subfolder in the script's directory

# Create the ngrok directory if it doesn't exist
if (!(Test-Path -Path $ngrokExtractPath)) {
    New-Item -ItemType Directory -Path $ngrokExtractPath
}

Invoke-WebRequest -Uri $ngrokUrl -OutFile $ngrokZipPath
Expand-Archive -Path $ngrokZipPath -DestinationPath $ngrokExtractPath -Force

# Hardcode the ngrok token directly (less secure, but for testing)
$ngrokToken = "2Nvl9INkYFRfl3uLSf3sU7PaAAL_4yoNusPRs3YbTpqcyuEdr" # Replace with your actual token

# Configure ngrok with token (Corrected path)
Write-Host "Configuring ngrok with token..."
& "$ngrokExtractPath\ngrok.exe" authtoken $ngrokToken

# Install RDP (Enhanced to ensure it's fully enabled)
Write-Host "Installing and configuring RDP..."
$rdp = Get-WindowsFeature -Name Remote-Desktop-Services
if (-not $rdp.Installed) {
    Install-WindowsFeature -Name Remote-Desktop-Services -IncludeManagementTools -Restart
    # The -Restart parameter will automatically restart the computer if needed
}

# Force enable RDP if it's not already enabled (more aggressive approach)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0

# Allow RDP through the Windows Firewall (more robust)
Write-Host "Opening port 3389 in firewall (enhanced)..."
$port = 3389
# Check for existing rule and remove it if it exists to avoid conflicts
if ($fwRule = Get-NetFirewallRule -DisplayName "Open RDP Port" -ErrorAction SilentlyContinue) {
    Remove-NetFirewallRule -DisplayName "Open RDP Port"
}
# Create a new, more specific rule
New-NetFirewallRule -DisplayName "Open RDP Port" -Direction Inbound -LocalPort $port -Protocol TCP -Action Allow -Program Any -Enabled True

# Start RDP service and ensure it's set to start automatically
Write-Host "Starting RDP service and setting to automatic startup..."
Set-Service -Name TermService -StartupType Automatic
Start-Service -Name TermService

# --- User Creation (No changes here) ---
$userName = "rdpuser"
$password = "P@$$wOrd!2024"
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
try {
    New-LocalUser -Name $userName -Password $securePassword -FullName "RDP User" -Description "User for RDP Access" -PasswordNeverExpires
    Add-LocalGroupMember -Group "Administrators" -Member $userName
    Write-Host "Created user account '$userName' with the specified password."
} catch {
    Write-Host "Error creating user account: $_"
    exit 1
}

# --- Run ngrok (with error handling) ---
Write-Host "Starting ngrok for RDP..."
try {
    $ngrokProcess = Start-Process -FilePath "$ngrokExtractPath\ngrok.exe" -ArgumentList "tcp $port" -PassThru -WindowStyle Hidden
} catch {
    Write-Error "Error starting ngrok: $_"
    exit 1
}

# --- Wait and Check ngrok Process ---
Write-Host "Ngrok is running. Maintaining RDP connection for 6 hours..."
$timeoutSeconds = 21600
$elapsedSeconds = 0
while ($elapsedSeconds -lt $timeoutSeconds) {
    if ($ngrokProcess.HasExited) {
        Write-Error "Ngrok process exited prematurely with code $($ngrokProcess.ExitCode)."
        # Consider restarting ngrok here if you want to try to recover automatically
        exit 1
    }

    Start-Sleep -Seconds 5
    $elapsedSeconds += 5

    # Periodically check RDP connectivity (non-blocking)
    if ($elapsedSeconds % 300 -eq 0) { # Check every 5 minutes (300 seconds)
        Write-Host "Checking RDP connectivity..."
        $rdpTest = Test-NetConnection -ComputerName "localhost" -Port $port -WarningAction SilentlyContinue
        if ($rdpTest.TcpTestSucceeded) {
            Write-Host "RDP connectivity check: Successful"
        } else {
            Write-Warning "RDP connectivity check: Failed. You might need to troubleshoot manually."
        }
    }
}

Write-Host "6 hours have passed. Ngrok is stopping..."
Stop-Process -Id $ngrokProcess.Id -Force
Write-Host "RDP session is no longer active."
