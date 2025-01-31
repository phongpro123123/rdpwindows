# Cài đặt ngrok
$ngrokUrl = "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip"
$ngrokZipPath = "ngrok.zip"
$ngrokExtractPath = "ngrok"

Invoke-WebRequest -Uri $ngrokUrl -OutFile $ngrokZipPath
Expand-Archive -Path $ngrokZipPath -DestinationPath $ngrokExtractPath

# Lấy ngrok token từ GitHub Secrets
$ngrokToken = $env:NGROK_AUTH_TOKEN  # Đảm bảo đã lưu token ngrok trong GitHub Secrets

# Cấu hình ngrok với token
& ".\ngrok\ngrok.exe" authtoken $ngrokToken

# Cài đặt RDP (Nếu chưa được cài sẵn trên máy Windows)
Write-Host "Cài đặt RDP..."
$rdp = Get-WindowsFeature -Name Remote-Desktop-Services
if (-not $rdp.Installed) {
    Install-WindowsFeature -Name Remote-Desktop-Services
}

# Mở cổng RDP (3389) trong tường lửa
Write-Host "Mở cổng 3389 trong tường lửa..."
New-NetFirewallRule -DisplayName "Open RDP Port" -Enabled True -Protocol TCP -Action Allow -Direction Inbound -LocalPort 3389

# Khởi động RDP
Write-Host "Bắt đầu dịch vụ RDP..."
Start-Service -Name TermService

# Tạo tài khoản người dùng mới (ví dụ: username là 'rdpuser' và mật khẩu là 'password123')
$userName = "rdpuser"
$password = "password123"
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
New-LocalUser -Name $userName -Password $securePassword -FullName "RDP User" -Description "User for RDP Access"
Add-LocalGroupMember -Group "Administrators" -Member $userName

Write-Host "Tạo tài khoản người dùng $userName với mật khẩu $password."

# Chạy ngrok để chia sẻ kết nối RDP
Write-Host "Khởi động ngrok cho RDP..."
Start-Process -FilePath ".\ngrok\ngrok.exe" -ArgumentList "tcp", "3389"

# Giữ kết nối RDP trong 6 giờ
Write-Host "Giữ kết nối RDP trong 6 giờ..."
Start-Sleep -Seconds 21600  # 6 giờ = 21600 giây

Write-Host "Kết thúc 6 giờ. Ngrok đã dừng lại và phiên RDP không còn hoạt động."
