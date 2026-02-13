# Cursor / VS Code icin hizli Android emulator baslatma
# Kullanim: .\scripts\start_android_emulator.ps1
# veya Tasks'tan "Android: Emulatoru Baslat" calistirin, 20-30 sn sonra Flutter: Android'de Calistir

$ErrorActionPreference = "Stop"
$sdk = $env:LOCALAPPDATA + "\Android\Sdk"
$emulator = Join-Path $sdk "emulator\emulator.exe"
$adb = Join-Path $sdk "platform-tools\adb.exe"
$avd = "Pixel_7_API_33"

if (-not (Test-Path $emulator)) {
    Write-Host "Android SDK emulator bulunamadi: $emulator" -ForegroundColor Red
    exit 1
}

# Emulatoru arka planda baslat (WHPX/HAXM ile hizli)
Write-Host "Emulator baslatiliyor: $avd ..." -ForegroundColor Cyan
$p = Start-Process -FilePath $emulator -ArgumentList "-avd", $avd, "-no-snapshot-load" -PassThru -WindowStyle Normal
Write-Host "PID: $($p.Id) - Pencere acildi." -ForegroundColor Green
Write-Host "Cihaz hazir olana kadar bekleyin (~20-40 sn), sonra Cursor'dan Flutter: Android'de Calistir veya F5 kullanin." -ForegroundColor Yellow

# Opsiyonel: Cihaz cikana kadar bekle, sonra flutter run
# & $adb wait-for-device
# flutter run -d android
