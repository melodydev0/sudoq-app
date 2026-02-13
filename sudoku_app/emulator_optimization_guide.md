# Android Emülatör Optimizasyon Rehberi

## Cursor içinde hızlı emülatör kullanımı

Projede Cursor’dan tek tıkla emülatör ve Flutter çalıştırma ayarlandı.

### Adımlar

1. **Emülatörü başlat**  
   `Ctrl+Shift+P` → **Tasks: Run Task** → **Android: Emülatörü Başlat**  
   Emülatör penceresi açılır; 20–40 saniye içinde açılış tamamlanır.

2. **Uygulamayı çalıştır**  
   - **F5** (Run) veya yeşil oynat: **Flutter (Android)** ile Android’de çalıştırır.  
   - Veya **Tasks: Run Task** → **Flutter: Emülatörde Çalıştır**.

3. **En hızlı seçenek (emülatör kullanmadan)**  
   **F5** ile açılan listeden **Flutter (Windows - en hızlı)** seçin. Uygulama Windows’ta doğrudan çalışır, emülatörden daha hızlıdır.

### Dosyalar

- **`.vscode/tasks.json`** – Emülatör başlatma ve Flutter çalıştırma görevleri  
- **`.vscode/launch.json`** – F5 ile Android / Windows / Chrome seçenekleri  
- **`scripts/start_android_emulator.ps1`** – Emülatörü başlatan script (görev bunu kullanır)

---

## Mevcut Durum
- Emülatör: Pixel 7 API 33 (Android 13)
- Platform: x86_64
- Durum: Yavaş çalışıyor, hot reload sorunları var

## Hızlı Çözümler

### 1. Emülatör Ayarlarını Optimize Et (Android Studio AVD Manager)

**AVD Manager'da yapılacaklar:**
1. **Show Advanced Settings** → **Graphics**: `Hardware - GLES 2.0` seçin
2. **RAM**: 2048 MB (çok yüksek değil, çok düşük de değil)
3. **VM heap**: 256 MB
4. **Internal Storage**: 2048 MB
5. **SD Card**: Yok (gerekmiyorsa)
6. **Multi-Core CPU**: 2-4 core (sisteminize göre)

### 2. Windows Hypervisor Platform (WHPX) Aktif Et

**PowerShell (Admin olarak):**
```powershell
Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
```

**BIOS/UEFI'de:**
- Intel: VT-x aktif olmalı
- AMD: AMD-V aktif olmalı

### 3. Flutter Çalıştırma Optimizasyonları

**Hot Reload için:**
```bash
flutter run --no-sound-null-safety --enable-software-rendering
```

**Release modu (daha hızlı):**
```bash
flutter run --release
```

**Profile modu (debug ve release arası):**
```bash
flutter run --profile
```

### 4. Alternatif: Fiziksel Cihaz Kullan

**USB Debugging ile:**
1. Android cihazda Developer Options → USB Debugging aç
2. USB ile bağla
3. `flutter devices` ile kontrol et
4. `flutter run -d <device-id>` ile çalıştır

**Fiziksel cihaz genellikle emülatörden 2-3x daha hızlıdır!**

### 5. Daha Hafif Emülatör Oluştur

**Yeni AVD oluştur:**
- **Device**: Pixel 3 veya Pixel 4 (daha hafif)
- **System Image**: x86_64, API 30 veya 31 (API 33'ten daha hafif)
- **Graphics**: Hardware - GLES 2.0
- **RAM**: 1536 MB
- **Multi-Core**: 2 core

### 6. Genymotion (Alternatif Emülatör - Ücretli ama çok hızlı)

Genymotion ücretsiz kişisel kullanım için mevcut ve çok daha hızlı:
- İndirme: https://www.genymotion.com/
- Kurulum sonrası: `flutter devices` ile görünecek

### 7. Windows Subsystem for Android (WSA) - Windows 11

Windows 11 kullanıyorsanız:
- Microsoft Store'dan "Windows Subsystem for Android" yükleyin
- Flutter ile kullanılabilir (bazı sınırlamalar var)

## Önerilen Sıralama

1. **Önce deneyin:** Fiziksel Android cihaz (en hızlı)
2. **İkinci seçenek:** Mevcut emülatörü optimize edin (yukarıdaki ayarlar)
3. **Üçüncü seçenek:** Daha hafif bir AVD oluşturun (Pixel 3, API 30)
4. **Son çare:** Genymotion veya WSA

## Hızlı Test

Mevcut emülatörü optimize etmek için:
1. Android Studio → AVD Manager
2. Pixel_7_API_33 → Edit (kalem ikonu)
3. Show Advanced Settings
4. Graphics: Hardware - GLES 2.0
5. RAM: 2048 MB
6. Multi-Core CPU: 2
7. Save ve yeniden başlat
