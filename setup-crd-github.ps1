# Cài đặt Chrome Remote Desktop Host
Write-Host "Tải và cài đặt Chrome Remote Desktop Host..."
Invoke-WebRequest -Uri "https://dl.google.com/edgedl/chrome-remote-desktop/chromeremotedesktophost.msi" -OutFile "chromeremotedesktophost.msi"
Start-Process "msiexec.exe" -ArgumentList "/i", "chromeremotedesktophost.msi", "/quiet" -Wait

# Khởi động Chrome Remote Desktop Host với mã xác nhận của bạn
$remoteCode = "4/0ASVgi3Kg4L2i4Cn9CYDCgj_NYCWFD3Wj0a1By5RIfSKq7AzyjR5oNbJy73xeKLne24sjyw"
Write-Host "Khởi động Chrome Remote Desktop Host..."
Start-Process -FilePath "${Env:PROGRAMFILES(X86)}\Google\Chrome Remote Desktop\CurrentVersion\remoting_start_host.exe" -ArgumentList "--code=$remoteCode --redirect-url=https://remotedesktop.google.com/_/oauthredirect --name=$Env:COMPUTERNAME"

# Đợi thông báo yêu cầu mã PIN và tự động nhập "123456"
Write-Host "Vui lòng nhập mã PIN tự động."
Start-Sleep -Seconds 10  # Đợi một chút để cửa sổ yêu cầu mã PIN xuất hiện (tùy chỉnh nếu cần)

# Tự động gửi mã PIN "123456"
Add-Type -AssemblyName "System.Windows.Forms"
[System.Windows.Forms.SendKeys]::SendWait("123456{ENTER}")
Write-Host "Mã PIN đã nhập tự động: 123456"

# Giữ kết nối trong 6 giờ
Write-Host "Giữ kết nối trong 6 giờ..."
Start-Sleep -Seconds (6 * 60 * 60)  # Giữ kết nối trong 6 giờ
Write-Host "Kết nối kết thúc sau 6 giờ."
