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

# Get ngrok token from GitHub Secrets (No change here)
$ngrokToken = $env:NGROK_AUTH_TOKEN

# Configure ngrok with token (Corrected path)
Write-Host "Configuring ngrok with token..."
& "$ngrokExtractPath\ngrok.exe" authtoken $ngrokToken

# Install RDP (No change here)
Write-Host "Installing RDP..."
$rdp = Get-WindowsFeature -Name Remote-Desktop-Services
if (-not $rdp.Installed) {
    Install-WindowsFeature -Name Remote-Desktop-Services -IncludeManagementTools
}

# Open RDP port in firewall (No change here)
Write-Host "Opening port 3389 in firewall..."
if (!(Get-NetFirewallRule -DisplayName "Open RDP Port" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName "Open RDP Port" -Enabled True -Protocol TCP -Action Allow -Direction Inbound -LocalPort 3389
}

# Start RDP service (No change here)
Write-Host "Starting RDP service..."
Set-Service -Name TermService -StartupType Automatic
Start-Service -Name TermService

# Create a new user account with a strong password
$userName = "rdpuser"
$password = "P@$$wOrd!2024"  # A much stronger password!
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
try {
    New-LocalUser -Name $userName -Password $securePassword -FullName "RDP User" -Description "User for RDP Access" -PasswordNeverExpires
    Add-LocalGroupMember -Group "Administrators" -Member $userName
    Write-Host "Created user account '$userName' with the specified password."
} catch {
    Write-Host "Error creating user account: $_"
    exit 1
}

# Run ngrok to share RDP connection (Corrected path)
Write-Host "Starting ngrok for RDP..."
Start-Process -FilePath "$ngrokExtractPath\ngrok.exe" -ArgumentList "tcp", "3389"

# Wait for ngrok to open the TCP connection (No change here)
Write-Host "Ngrok is running. Maintaining RDP connection for 6 hours..."
Start-Sleep -Seconds 21600

Write-Host "6 hours have passed. Ngrok has stopped, and the RDP session is no longer active."
