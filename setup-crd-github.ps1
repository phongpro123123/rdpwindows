# --- Bước 1: Tải và Cài đặt Chrome Remote Desktop Host ---
Write-Host "Downloading and installing Chrome Remote Desktop..."
$crdInstallerUrl = "https://dl.google.com/edgedl/chrome-remote-desktop/chromeremotedesktophost.msi"
$crdInstallerPath = "$env:TEMP\chromeremotedesktophost.msi"

Invoke-WebRequest -Uri $crdInstallerUrl -OutFile $crdInstallerPath

# Cài đặt file MSI (yên lặng, không restart)
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$crdInstallerPath`" /qn /norestart" -Wait

# --- Bước 2: Khởi động Chrome Remote Desktop Host ---
Write-Host "Configuring and starting Chrome Remote Desktop Host..."

# Kiểm tra biến môi trường CRD_AUTH_CODE (được set từ workflow)
if (-not $env:CRD_AUTH_CODE) {
    Write-Error "CRD_AUTH_CODE environment variable not found. Please set it in the GitHub Actions workflow."
    exit 1
}

# Lấy đường dẫn đến file remoting_start_host.exe
$crdHostPath = "${Env:PROGRAMFILES(X86)}\Google\Chrome Remote Desktop\CurrentVersion\remoting_start_host.exe"

# Mã xác thực (lấy từ biến môi trường)
$authCode = $env:CRD_AUTH_CODE

# URL chuyển hướng cố định
$redirectUrl = "https://remotedesktop.google.com/_/oauthredirect"

# Tên máy tính
$computerName = $Env:COMPUTERNAME

# Xây dựng câu lệnh
$crdCommand = @(
  $crdHostPath,
  "--code=$authCode",
  "--redirect-url=$redirectUrl",
  "--name=$computerName"
)

# Chạy lệnh
try {
    & $crdCommand[0] @($crdCommand | Select -Skip 1)
    Write-Host "Chrome Remote Desktop Host started successfully."
} catch {
    Write-Error "Error starting Chrome Remote Desktop Host: $_"
    exit 1
}

# --- Bước 3: Tạo Scheduled Task để Duy trì Kết Nối ---
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
