# Install Chrome Remote Desktop
Write-Host "Downloading and installing Chrome Remote Desktop..."
$crdInstallerUrl = "https://dl.google.com/edgedl/chrome-remote-desktop/chromeremotedesktophost.msi"
$crdInstallerPath = "$env:TEMP\chromeremotedesktophost.msi"

Invoke-WebRequest -Uri $crdInstallerUrl -OutFile $crdInstallerPath

# Install the MSI package silently
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$crdInstallerPath`" /qn /norestart" -Wait

# --- Get Authorization Code (Manual Step Required) ---
Write-Host "-------------------------------------------------------------------------"
Write-Host "IMPORTANT: You need to get an authorization code from Google."
Write-Host "1. Go to: https://remotedesktop.google.com/access (on your local machine)"
Write-Host "2. Click 'Set up remote access'"
Write-Host "3. Click the blue 'Generate Code' button"
Write-Host "4. Copy the generated code (it will look like: 4/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)"
Write-Host "5. Paste the code into an environment variable named CRD_AUTH_CODE in your GitHub Actions workflow."
Write-Host "-------------------------------------------------------------------------"

# Wait for the user to provide the authorization code (or retrieve it from secrets)
# $authCode = $env:CRD_AUTH_CODE # Commented out as the code is now passed by command
if (-not $env:CRD_COMMAND) {
  Write-Error "CRD_COMMAND environment variable not found. Ensure auth code is provided in workflow."
  exit 1
}

# --- Configure and Start Chrome Remote Desktop Host ---
Write-Host "Configuring and starting Chrome Remote Desktop Host..."
$crdCommand = $env:CRD_COMMAND

try {
  Invoke-Expression $crdCommand
  Write-Host "Chrome Remote Desktop Host started successfully."
} catch {
  Write-Error "Error starting Chrome Remote Desktop Host: $_"
  exit 1
}

# --- Keep-Alive Task ---
Write-Host "Creating scheduled task to maintain connection..."

# Define the task action (using PowerShell to simulate input)
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command `"Write-Host 'Keep-alive'; Start-Sleep -Seconds 5`""

# Define the task trigger (run every 5 minutes)
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Hours 6)

# Define the task settings
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DontStopOnIdleEnd

# Register the scheduled task
Register-ScheduledTask -TaskName "CRDKeepAlive" -Action $action -Trigger $trigger -Settings $settings -User "SYSTEM" -RunLevel Highest -Force

Write-Host "Chrome Remote Desktop setup complete. Connection should be maintained for approximately 6 hours."
