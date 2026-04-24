# SudoQ iOS — Geliştirici Rehberi

Bu döküman, SudoQ uygulamasının iOS sürümünü sıfırdan yayına almak için
gereken tüm adımları içerir. Sırayla yapılması önerilir.

---

## 1. Ön Gereksinimler

### Gerekli araçlar

| Araç | Versiyon | Not |
|---|---|---|
| macOS | Ventura veya üzeri | Zorunlu |
| Xcode | 15+ | App Store'dan indir |
| Flutter SDK | 3.x | flutter.dev |
| CocoaPods | 1.14+ | `sudo gem install cocoapods` |
| Firebase CLI | Son sürüm | `npm install -g firebase-tools` |
| FlutterFire CLI | Son sürüm | `dart pub global activate flutterfire_cli` |

### Gerekli hesaplar

- **Apple Developer Program** ($99/yıl) — developer.apple.com
- **GitHub** hesabı (repo erişimi için ekleneceksiniz)
- **Firebase Console** erişimi (davet gelecek)
- **Google AdMob** hesabı (mevcut hesaba bağlanacak)

---

## 2. Projeyi Klonla

```bash
git clone https://github.com/melodydev0/sudoq-app.git
cd sudoq-app
git checkout ios-dev       # iOS geliştirme branch'i
flutter pub get
```

---

## 3. Firebase iOS Kurulumu

### 3.1 Firebase projesine iOS app ekle

Firebase Console'da davet kabul et, ardından:

```bash
# Proje kök dizininde çalıştır
flutterfire configure
```

Komut sorgularında:
- **Project:** `sudoq-online` seç
- **Platforms:** `iOS` işaretle (Android zaten var, onu da işaretle ki bozulmasın)
- **Bundle ID:** `com.sudoq.puzzle`

Bu komut sonucunda:
- `ios/Runner/GoogleService-Info.plist` dosyası oluşur ✅
- `lib/firebase_options.dart` güncellenir ✅

> **Önemli:** `GoogleService-Info.plist` dosyasını mutlaka `git commit` ile repoya ekle.
> Bu dosya olmadan uygulama çalışmaz.

---

## 4. Xcode Kurulumu

### 4.1 CocoaPods bağımlılıklarını yükle

```bash
cd ios
pod install
cd ..
```

### 4.2 Xcode'da projeyi aç

```bash
open ios/Runner.xcworkspace
```

> ⚠️ `.xcworkspace` aç, `.xcodeproj` değil!

### 4.3 Bundle ID ve Signing ayarla

Xcode'da:
1. Sol panelde `Runner` seç
2. `Signing & Capabilities` sekmesi
3. **Team:** Apple Developer hesabını seç
4. **Bundle Identifier:** `com.sudoq.puzzle`
5. "Automatically manage signing" işaretle

### 4.4 Deployment Target

`Runner → General → Minimum Deployments`: **iOS 13.0** (mevcut kod bunu destekler)

---

## 5. Google Sign-In iOS Ayarı

### 5.1 URL Scheme ekle

1. `GoogleService-Info.plist` dosyasını aç
2. `REVERSED_CLIENT_ID` değerini kopyala
   (örn: `com.googleusercontent.apps.123456789-abcdef...`)

3. Xcode'da `Runner → Info → URL Types → +` butonuna bas:
   - **URL Schemes:** `REVERSED_CLIENT_ID` değerini yapıştır
   - **Identifier:** `GoogleSignIn`

### 5.2 Info.plist ek ayarlar

`ios/Runner/Info.plist` dosyasına şunları ekle:

```xml
<!-- Google Sign-In -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>BURAYA_REVERSED_CLIENT_ID_YAZ</string>
    </array>
  </dict>
</array>

<!-- Sign in with Apple (önceden entegre, sadece capability lazım) -->
```

### 5.3 Sign in with Apple Capability

Xcode → `Runner → Signing & Capabilities → +` → **Sign in with Apple** ekle.

---

## 6. AdMob iOS Kurulumu

### 6.1 AdMob'da iOS app oluştur

1. [apps.admob.com](https://apps.admob.com) → Apps → Add App
2. Platform: **iOS**
3. App Store'da yayında mı: **Hayır** (henüz yayında değil)
4. App adı: `SudoQ`
5. Oluşan **iOS AdMob App ID**'yi kaydet (`ca-app-pub-xxxx~yyyy` formatında)

### 6.2 iOS Ad Unit'leri oluştur

AdMob'da aynı hesapta iOS için 3 ad unit oluştur:

| Tür | Ad | Not |
|---|---|---|
| Banner | SudoQ iOS Banner | Oyun ekranı altı |
| Interstitial | SudoQ iOS Interstitial | Oyun arası |
| Rewarded | SudoQ iOS Rewarded | Günlük XP bonusu |

Her birinin ID'sini kaydet (`ca-app-pub-xxxx/yyyy` formatında).

### 6.3 Info.plist'e AdMob App ID ekle

`ios/Runner/Info.plist` içine:

```xml
<key>GADApplicationIdentifier</key>
<string>BURAYA_IOS_ADMOB_APP_ID_YAZ</string>

<!-- iOS 14+ ATT için (reklam izin popup) -->
<key>NSUserTrackingUsageDescription</key>
<string>We use this to show you relevant ads and support the free version of SudoQ.</string>
```

### 6.4 app_constants.dart'a iOS Ad Unit ID'leri ekle

`lib/core/constants/app_constants.dart` dosyasında iOS için yeni sabitler ekle:

```dart
// iOS AdMob IDs (ios-dev branch'inde bu değerleri doldur)
static const String iosAdmobAppId        = 'ca-app-pub-XXXX~YYYY';
static const String iosBannerAdUnitId    = 'ca-app-pub-XXXX/YYYY';
static const String iosInterstitialAdUnitId = 'ca-app-pub-XXXX/YYYY';
static const String iosRewardedAdUnitId  = 'ca-app-pub-XXXX/YYYY';
```

`ads_service.dart` içinde platform kontrolü zaten mevcut — sadece bu ID'leri doğru tanımlamak yeterli.

---

## 7. In-App Purchase (Abonelik) Kurulumu

### 7.1 App Store Connect'te app oluştur

1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. My Apps → **+** → New App
   - Platform: iOS
   - Name: `SudoQ — Zen Sudoku Puzzle`
   - Bundle ID: `com.sudoq.puzzle`
   - SKU: `sudoq-ios`
   - Primary Language: English

### 7.2 Subscription Group oluştur

App Store Connect → Uygulaman → Subscriptions:

1. **Create Subscription Group**
   - Reference Name: `SudoQ Premium`

2. **Weekly Subscription** ekle:
   - Reference Name: `SudoQ Premium Weekly`
   - Product ID: **`sudoq_premium_weekly`** ← bu tam olmalı, kod bunu bekliyor
   - Duration: 1 Week
   - Fiyat: bölgeye göre ayarla

3. **Yearly Subscription** ekle:
   - Reference Name: `SudoQ Premium Yearly`
   - Product ID: **`sudoq_premium_yearly`** ← bu tam olmalı
   - Duration: 1 Year
   - Fiyat: bölgeye göre ayarla

> ⚠️ Product ID'ler tam olarak `sudoq_premium_weekly` ve `sudoq_premium_yearly`
> olmalı — kod `app_constants.dart`'ta bu değerleri bekliyor.

### 7.3 StoreKit Capability ekle

Xcode → `Runner → Signing & Capabilities → +` → **In-App Purchase** ekle.

### 7.4 iOS Satın alma akışı (kod hazır)

`purchase_service.dart` iOS'u destekliyor:
- `_parseIOSProducts()` fonksiyonu zaten var
- `AppConstants.iosSubscriptionIds` = `{'sudoq_premium_weekly', 'sudoq_premium_yearly'}`
- Sadece App Store Connect'te ürünleri oluşturman yeterli

### 7.5 Server-side doğrulama — Firebase Function

Android için sunucu doğrulaması var (`verifyGooglePlaySubscription`).
iOS için şu an aktif doğrulama yok — geçici olarak client-side çalışır.

İleride eklenecek olan iOS doğrulaması için benden (Android geliştirici)
`verifyAppleSubscription` fonksiyonunu eklememi iste.

---

## 8. Push Notification (OneSignal)

Projede `onesignal_flutter` paketi var.

### 8.1 OneSignal'de iOS app oluştur

1. [onesignal.com](https://onesignal.com) → yeni app
2. Platform: **Apple iOS**
3. APNs sertifikası ya da Auth Key gerekiyor

### 8.2 APNs Key oluştur

Apple Developer → Certificates, Identifiers & Profiles → Keys:
1. **+** → Apple Push Notification service (APNs) seç
2. Key'i indir (`.p8` dosyası) — **bir kez indirilir, yedekle!**
3. Key ID ve Team ID'yi kaydet

### 8.3 OneSignal'e APNs ekle

OneSignal app settings → Apple iOS:
- `.p8` dosyasını, Key ID ve Team ID'yi gir

### 8.4 OneSignal App ID'yi koda ekle

`lib/core/services/notification_service.dart` veya `main.dart` içindeki
OneSignal App ID'yi iOS için güncelle (veya mevcut ID hem Android hem iOS'u
kapsıyorsa aynı kalır).

---

## 9. Kamera / Konum İzinleri (Info.plist)

Uygulama konum kullanıyor (`geolocator` paketi var). iOS'ta zorunlu açıklama:

`ios/Runner/Info.plist` içine ekle:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>SudoQ uses your location to show regional leaderboards.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>SudoQ uses your location to show regional leaderboards.</string>
```

---

## 10. Splash Screen ve App Icon

### 10.1 App Icon

`assets/icon/app_icon.png` mevcut (1024×1024 px). 

```bash
# flutter_launcher_icons paketi varsa
flutter pub run flutter_launcher_icons
```

Yoksa Xcode'da `Runner → Assets.xcassets → AppIcon` içine manuel ekle.

### 10.2 Splash Screen

`flutter_native_splash` paketi konfigüre edilmişse:

```bash
dart run flutter_native_splash:create
```

---

## 11. Uygulama Test Etme

### 11.1 Simülatörde çalıştır

```bash
flutter run -d iPhone     # simülatör
flutter run -d <device_id>  # gerçek cihaz
```

> ⚠️ In-App Purchase **simülatörde çalışmaz**, gerçek cihaz gerekir.

### 11.2 IAP test hesabı oluştur

App Store Connect → Users and Access → **Sandbox Testers** → yeni test hesabı
Gerçek cihazda `Settings → App Store` üzerinden bu test hesabıyla giriş yap.

### 11.3 Test edilecekler (checklist)

- [ ] Uygulama açılıyor, Firebase bağlanıyor
- [ ] Google Sign-In çalışıyor
- [ ] Sign in with Apple çalışıyor
- [ ] Anonim giriş çalışıyor
- [ ] Oyun oynanabiliyor
- [ ] Duel / matchmaking çalışıyor
- [ ] Günlük challenge çalışıyor
- [ ] Abonelik ekranı açılıyor, fiyatlar görünüyor
- [ ] Weekly satın alma tamamlanıyor (sandbox)
- [ ] Yearly satın alma tamamlanıyor (sandbox)
- [ ] Premium özellikler aktif oluyor
- [ ] Reklamlar görünüyor (non-premium)
- [ ] Reklamlar gizleniyor (premium)

---

## 12. TestFlight'a Yükle

### 12.1 Build al

```bash
flutter build ipa --release
```

Sonuç: `build/ios/ipa/sudoku_app.ipa`

### 12.2 Xcode Organizer ile yükle

1. Xcode → Window → **Organizer**
2. Oluşan archive'ı bul
3. **Distribute App → App Store Connect → Upload**

Veya `xcrun altool` ile komut satırından yükleyebilirsin.

### 12.3 TestFlight'ta test et

App Store Connect → TestFlight:
- Internal testers (ekip üyeleri) ekle
- Onlara invite gönder
- 1-2 gün içinde Apple review'dan geçer (ilk build biraz uzun sürebilir)

---

## 13. App Store Submission

### 13.1 App Store Connect — App bilgileri

- **App Name:** SudoQ — Zen Sudoku Puzzle
- **Subtitle:** Daily Puzzles & 1v1 Duels
- **Privacy Policy URL:** `https://sudoq.app/privacy-policy.html`
- **Support URL:** `https://sudoq.app`
- **Marketing URL:** `https://sudoq.app`
- **Category:** Games → Puzzle

### 13.2 Description (İngilizce)

```
SudoQ: Zen Sudoku Puzzle — the ultimate Sudoku experience combining 
classic number puzzles with competitive real-time battles.

CLASSIC SUDOKU, BEAUTIFULLY CRAFTED
4 difficulty levels: Easy, Medium, Hard, Expert. Clean, minimal design 
to help you focus. Smart tools: Undo, Erase, Notes, Fast Notes, Hints.

REAL-TIME 1v1 DUELS
Challenge players worldwide. Climb ELO rankings through Bronze, Silver, 
Gold, Platinum, Diamond, Master, Grandmaster and Champion divisions.

DAILY CHALLENGES
A fresh puzzle every day. Earn monthly trophies and badges.

50+ ACHIEVEMENTS
Level up, earn XP, unlock cosmetic rewards.

11 LANGUAGES SUPPORTED
```

### 13.3 Keywords (100 karakter)

```
sudoku,puzzle,zen,daily,duel,brain,logic,number,challenge,ELO,rank
```

### 13.4 Screenshots

Her iPhone boyutu için gerekli:
- iPhone 6.9" (1320×2868)
- iPhone 6.5" (1242×2688)
- iPad 12.9" (2048×2732)

Android'deki screenshot template'leri referans al, iOS için yeniden render et.

### 13.5 Age Rating

App Store Connect → Age Rating:
- Gambling: No
- In-App Purchases: Yes (abonelik var)
- → **4+** çıkmalı

### 13.6 Privacy Nutrition Labels

App Store Connect → App Privacy:
- **Data Not Linked to You:** Crash data, Usage data
- **Data Linked to You:** User ID, Name, Email (Google Sign-In kullanıcıları için)

### 13.7 Submit for Review

Tüm bilgiler dolunca **Submit for Review** — Apple 24-48 saat içinde
inceler (yeni uygulamalarda 5-7 gün sürebilir).

---

## 14. Bağımlılık Özeti

Aşağıdaki Flutter paketleri iOS'ta özel yapılandırma gerektirir:

| Paket | Yapılandırma |
|---|---|
| `firebase_core` | `GoogleService-Info.plist` |
| `google_sign_in` | URL Scheme (REVERSED_CLIENT_ID) |
| `sign_in_with_apple` | Sign in with Apple Capability |
| `in_app_purchase` | In-App Purchase Capability, App Store Connect products |
| `google_mobile_ads` | `GADApplicationIdentifier` in Info.plist |
| `onesignal_flutter` | APNs key, OneSignal iOS app |
| `geolocator` | Location usage descriptions in Info.plist |

---

## 15. Sorular / Sorunlar

Android geliştirici ile koordinasyon gereken konular:

- iOS satın alma server-side doğrulaması (`verifyAppleSubscription` Cloud Function)
- Firebase Remote Config — iOS'a özel feature flag lazımsa
- App Store'da yayınlandıktan sonra `sudoq.app` landing page'ine iOS App Store linki eklenmesi

---

*Hazırlayan: SudoQ Android Geliştirici*
*Son güncelleme: Nisan 2026*
