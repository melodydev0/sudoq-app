# SudoQ — iOS Sorunlar ve Çözümler

> Hazırlanma tarihi: Nisan 2026  
> Kapsam: Giriş (Auth) + Ödeme (IAP) + Reklam (AdMob) + Altyapı

---

## Hızlı Özet

| # | Sorun | Öncelik | Kim Yapar |
|---|-------|---------|-----------|
| 1 | `APPLE_SHARED_SECRET` Firebase'e eklenmemiş | 🔴 KRİTİK | Android geliştirici |
| 2 | `GoogleService-Info.plist` repo'da yok | 🔴 KRİTİK | iOS geliştirici |
| 3 | Bundle ID uyumsuzluğu (`com.sudoq.app` vs `com.sudoq.puzzle`) | 🔴 KRİTİK | iOS geliştirici |
| 4 | iOS proje dosyaları eksik (`Podfile`, `xcodeproj` vb.) | 🔴 KRİTİK | iOS geliştirici |
| 5 | `checkExpiredSubscriptions` iOS aboneliğini yenilemiyor | 🟠 YÜKSEK | Android geliştirici |
| 6 | App Store Server Notifications yok | 🟠 YÜKSEK | Android geliştirici |
| 7 | iOS AdMob App ID yanlış (Android ID kullanıyor) | 🟠 YÜKSEK | Android geliştirici |
| 8 | iOS reklam unit ID'leri ayrı tanımlanmamış | 🟠 YÜKSEK | Android geliştirici |
| 9 | iOS paywall'da introductory price gösterilmiyor | 🟡 ORTA | Android geliştirici |
| 10 | `CFBundleDisplayName` = "Sudoku App" (SudoQ olmalı) | 🟡 ORTA | iOS geliştirici |
| 11 | `appVersion` sabiti eski (1.0.3 vs pubspec 1.0.4+25) | 🟢 DÜŞÜK | Android geliştirici |
| 12 | `sudoq_premium_monthly` Cloud Function'da var, AppConstants'ta yok | 🟢 DÜŞÜK | Android geliştirici |

---

## SORUN 1 — `APPLE_SHARED_SECRET` Firebase'e Eklenmemiş 🔴

### Açıklama
`functions/index.js` içindeki `verifyAppleSubscription` fonksiyonu,
Apple'ın `/verifyReceipt` API'sine istek atarken `password` alanında
bu secret'ı kullanıyor. Secret eksikse fonksiyon anında hata fırlatıyor:
`Error: missing_apple_shared_secret`. Bu durumda `purchase_claims`
dökümanı `status: "error"` olarak kapanıyor ve Flutter tarafı
"Purchase could not be verified. Please try Restore Purchases." gösteriyor.

### Neden Oluyor
`verifyPurchaseClaim` Cloud Function doğru şekilde iOS'u handle ediyor
(`receiptData` alıp `verifyAppleSubscription` çağırıyor) ama
`APPLE_SHARED_SECRET` environment variable hiç set edilmemiş.
`functions/.env` dosyası ya yok ya da bu satırı içermiyor.

### Çözüm
`APPLE_SHARED_SECRET_SETUP.md` dosyasındaki adımları uygula.
Kısaca:

**Adım 1 — App Store Connect'ten secret al (iOS geliştirici)**
1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → Users and Access → Integrations
2. In-App Purchase → App-Specific Shared Secrets → SudoQ uygulaması → Generate
3. 32 karakterlik hex değeri kopyala, güvenli kanaldan ilet

**Adım 2 — `functions/.env` dosyasına ekle**
```
APPLE_SHARED_SECRET=buraya_32_karakterli_secret
```

**Adım 3 — Deploy et**
```bash
firebase deploy --only functions:verifyPurchaseClaim
```

### Doğrulama
Sandbox satın alması sonrası Firebase Logs'ta:
```
[verifyAppleSubscription] receipt verified
state: "ACTIVE"
productId: "sudoq_premium_weekly"
```
görünmeli. `admin.sudoq.app → Payments` sayfasında 🍎 ikonlu `verified` kayıt çıkmalı.

---

## SORUN 2 — `GoogleService-Info.plist` Repo'da Yok 🔴

### Açıklama
iOS'ta Firebase Auth (anonim, Google, Apple girişleri), AdMob başlatması
ve Remote Config `GoogleService-Info.plist` olmadan çalışmaz.
Şu an `ios/Runner/` klasöründe sadece `Info.plist` mevcut.

### Neden Oluyor
`GoogleService-Info.plist` genellikle güvenlik nedeniyle `.gitignore`'a eklenir.
Ancak iOS build yapabilmek için bu dosyanın `ios/Runner/` içinde bulunması zorunlu.

### Çözüm — iOS Geliştirici Yapacak
```bash
# Firebase projesine iOS uygulaması zaten ekli (firebase_options.dart'ta tanımlı)
# Sadece plist dosyasını çekmen yeterli:
flutterfire configure \
  --project=sudoq-online \
  --platforms=ios \
  --bundle-id=<doğru_bundle_id>   # ← Sorun 3'ü önce çöz!
```

Veya Firebase Console → Project Settings → iOS app → `GoogleService-Info.plist` indir,
`ios/Runner/` klasörüne koy, Xcode'da `Runner` target'ına ekle.

> ⚠️ Bu dosyayı repoya commit edebilirsin (içinde API key var ama Firebase
> Security Rules ve App Check ile korunuyor). Veya `ios-dev` branch'inde tut.

---

## SORUN 3 — Bundle ID Uyumsuzluğu 🔴 ✅ Düzeltildi

### Açıklama
Firebase Console'daki kayıtlı değerler:
- **Android Package Name:** `com.sudoq.puzzle` → App ID: `1:777088106689:android:633e3e979eba04f79fd440`
- **iOS Bundle ID:** `com.melodyyazilim.sudoq` → App ID: `1:777088106689:ios:58cf8d82b77371019fd440`

`firebase_options.dart` iki platformda da yanlış App ID ve Bundle ID kullanıyordu:

| Alan | Eski (Yanlış) | Yeni (Doğru) |
|------|--------------|--------------|
| `android.appId` | `...1e8432c...` (`com.sudoq.app`'in ID'si) | `...633e3e...` (`com.sudoq.puzzle`) |
| `ios.appId` | `...cc76a0e...` (eski ID) | `...58cf8d8...` |
| `ios.iosBundleId` | `com.sudoq.app` | `com.melodyyazilim.sudoq` |

### Durum
✅ `firebase_options.dart` güncellendi.

iOS geliştirici Xcode'da Bundle Identifier'ın `com.melodyyazilim.sudoq` olduğunu doğrulamalı.

---

## SORUN 4 — iOS Proje Dosyaları Eksik 🔴

### Açıklama
`ios/` klasöründe şu dosyalar bulunmuyor:

- `Podfile` — CocoaPods bağımlılık yönetimi
- `Runner.xcodeproj` — Xcode proje dosyası
- `Runner.xcworkspace` — CocoaPods sonrası kullanılan workspace
- `Runner/AppDelegate.swift` — iOS app entry point
- `Runner/Assets.xcassets` — App icon ve splash
- `Runner/GoogleService-Info.plist` — Firebase config

Bu dosyalar olmadan iOS build alınamaz.

### Çözüm
```bash
# 1. ios-dev branch'ine geç
git checkout ios-dev

# 2. Bağımlılıkları kur
cd ios && pod install && cd ..

# 3. Workspace'i aç (.xcworkspace, .xcodeproj değil!)
open ios/Runner.xcworkspace
```

`ios-dev` branch'i yoksa Flutter, projeyi yeniden iskelet oluşturabilir:
```bash
flutter create --platforms=ios .
# Sonra ios/ altındaki gereksiz dosyaları temizle,
# mevcut lib/ ve assets/ kodunu koru.
```

---

## SORUN 5 — `checkExpiredSubscriptions` iOS Aboneliğini Yenilemiyor 🟠

### Açıklama
`functions/index.js` içindeki `checkExpiredSubscriptions` Cloud Function
her saat çalışarak süresi dolan `entitlements` dökümanlarını kontrol ediyor.
Ancak **sadece Google Play** aboneliklerini yenilemeye çalışıyor:

```javascript
// functions/index.js — satır 1130
if (purchaseToken && data.source === "google_play") {
  // Google Play'i yeniden doğrula → yenilendiyse premium=true tut
}
// App Store için bu blok YOK → her iOS aboneliği expire'da revoke ediliyor!
```

Sonuç: iOS kullanıcısı premium satın aldı, abonelik yenilendi ama bir hafta/yıl
sonra `premium: false` yapılıyor. Kullanıcı premium özelliklerine erişemez hale geliyor.

### Çözüm — `functions/index.js` Değişikliği

`checkExpiredSubscriptions` içine iOS re-verify eklenecek:

```javascript
// Mevcut kod (satır ~1130):
if (purchaseToken && data.source === "google_play") {
  // ... Google Play verify
}

// Eklenecek blok:
else if (data.source === "app_store") {
  // proof = original_transaction_id veya receipt (purchase_tokens'da saklanıyor)
  const tokenDoc = tokenHash
    ? await db.collection("purchase_tokens").doc(tokenHash).get()
    : null;
  const receiptData = tokenDoc?.exists ? tokenDoc.data()?.proof : null;

  if (receiptData) {
    try {
      const freshStatus = await verifyAppleSubscription(receiptData);
      if (freshStatus.premium) {
        await doc.ref.set({
          premium: true,
          state: freshStatus.state,
          expiresAt: freshStatus.expiresAt,
          autoRenewing: freshStatus.autoRenewing,
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
        renewed++;
        continue;
      }
    } catch (err) {
      logger.warn("iOS re-verify failed, revoking", { uid: doc.id, error: String(err) });
    }
  }
}
```

> ⚠️ `purchase_tokens` dökümanında iOS için `proof` = `original_transaction_id`
> saklanıyor (index.js satır 346). Apple'ın legacy `/verifyReceipt` API'si
> `original_transaction_id` ile değil, **tam receipt base64** ile çalışır.
> Bu nedenle `proof` alanına original receipt'i saklamak daha doğru olur.
> Detaylar için Sorun 6'ya bak.

---

## SORUN 6 — App Store Server Notifications Yok 🟠

### Açıklama
Google Play için `playBillingRTDN` Cloud Function var:
→ Abonelik iptal, yenileme, iade gerçek zamanlı Firestore'a yansıyor.

iOS için eşdeğeri yok:
→ Kullanıcı aboneliği iptal etse bile `entitlements.premium = true` kalıyor
(ta ki `checkExpiredSubscriptions` çalışana kadar — o da yukarıdaki sorun nedeniyle düzgün çalışmıyor).

### Çözüm

**Kısa vadeli (hemen yapılabilir):**
App Store Server Notifications v2 endpoint'i Cloud Function olarak ekle.

```javascript
// functions/index.js'e eklenecek
const { onRequest } = require("firebase-functions/v2/https");

exports.appStoreNotifications = onRequest(
  { secrets: ["APPLE_SHARED_SECRET"] },
  async (req, res) => {
    // Apple'ın gönderdiği JWT payload'ı decode et
    // notificationType'a göre entitlements'ı güncelle
    // Detaylı implementasyon için Apple docs:
    // https://developer.apple.com/documentation/appstoreservernotifications
    res.status(200).send("OK");
  }
);
```

**App Store Connect'te yapılacak (iOS geliştirici):**
App Store Connect → Uygulama → App Information → App Store Server Notifications
→ Production Server URL: `https://us-central1-sudoq-online.cloudfunctions.net/appStoreNotifications`

> Bu kısa vadede %100 doğruluk sağlamaz ama iptal/iade durumları
> gerçek zamanlı yansımaya başlar.

---

## SORUN 7 — iOS AdMob App ID Yanlış 🟠

### Açıklama
`AdsService.init()` platform ayırt etmeden `AppConstants.admobAppId` kullanıyor:

```dart
// ads_service.dart — satır 51
await MobileAds.instance.initialize();
```

`MobileAds.instance.initialize()` çağrısı, `Info.plist`'teki
`GADApplicationIdentifier` değerini kullanır (iOS'ta Dart kodu değil,
native taraf okur). Sorun şu ki:

| Kaynak | App ID |
|--------|--------|
| `Info.plist → GADApplicationIdentifier` | `ca-app-pub-4679569583423185~1236339471` (iOS) |
| `AppConstants.admobAppId` | `ca-app-pub-4679569583423185~4086488817` (Android) |

`Info.plist`'teki değer zaten doğru iOS App ID'si. Dart `AppConstants`'taki
değer iOS'ta kullanılmıyor. **Sorun şu:** `AppConstants.isUsingTestAdMobIds`
kontrolü release build'de yanlış sonuç verebilir.

### Çözüm — `app_constants.dart` Güncellenmeli

```dart
// lib/core/constants/app_constants.dart

// iOS AdMob App ID (Info.plist'teki ile aynı olmalı)
static const String iosAdmobAppId = 'ca-app-pub-4679569583423185~1236339471';

// Android AdMob App ID (google-services.json'daki ile aynı olmalı)
static const String androidAdmobAppId = 'ca-app-pub-4679569583423185~4086488817';

// Geriye dönük uyumluluk için (mevcut admobAppId Android'i referans alıyor)
static const String admobAppId = androidAdmobAppId;
```

`AdsService.init()` içinde platform kontrolü eklenmeli:
```dart
// ads_service.dart — validasyon için
static String get _effectiveAdmobAppId =>
    defaultTargetPlatform == TargetPlatform.iOS
        ? AppConstants.iosAdmobAppId
        : AppConstants.androidAdmobAppId;
```

> Not: iOS'ta `MobileAds.initialize()` App ID'yi `Info.plist`'ten okuduğu için
> Dart'ta bunu geçirmek mümkün değil. Bu kontrol sadece loglama/doğrulama amaçlı.

---

## SORUN 8 — iOS Reklam Unit ID'leri Tanımlanmamış 🟠

### Açıklama
`AppConstants` sadece Android reklam unit ID'lerini içeriyor.
`AdsService` platform kontrolü yapmadan bu ID'leri kullanıyor.
iOS'ta Android reklam unit ID'leri ile reklam yüklenemez.

```dart
// Mevcut durum — ads_service.dart satır 29-37
static String get _bannerAdUnitId => kDebugMode
    ? 'ca-app-pub-3940256099942544/6300978111'   // Test ID (OK)
    : AppConstants.bannerAdUnitId;               // ← Android ID, iOS'ta çalışmaz!
```

### Çözüm

**1. `app_constants.dart`'a iOS ID'lerini ekle:**

```dart
// lib/core/constants/app_constants.dart

// iOS Ad Unit IDs (AdMob'da iOS için ayrı unit oluştur)
static const String iosBannerAdUnitId = String.fromEnvironment(
  'IOS_ADMOB_BANNER_AD_UNIT_ID',
  defaultValue: 'ca-app-pub-XXXX/YYYY',  // ← iOS banner unit ID'yi buraya yaz
);
static const String iosInterstitialAdUnitId = String.fromEnvironment(
  'IOS_ADMOB_INTERSTITIAL_AD_UNIT_ID',
  defaultValue: 'ca-app-pub-XXXX/YYYY',
);
static const String iosRewardedAdUnitId = String.fromEnvironment(
  'IOS_ADMOB_REWARDED_AD_UNIT_ID',
  defaultValue: 'ca-app-pub-XXXX/YYYY',
);
```

**2. `ads_service.dart`'ta platform seçimi ekle:**

```dart
// ads_service.dart
static String get _bannerAdUnitId {
  if (kDebugMode) return 'ca-app-pub-3940256099942544/6300978111';
  return defaultTargetPlatform == TargetPlatform.iOS
      ? AppConstants.iosBannerAdUnitId
      : AppConstants.bannerAdUnitId;
}

static String get _interstitialAdUnitId {
  if (kDebugMode) return 'ca-app-pub-3940256099942544/1033173712';
  return defaultTargetPlatform == TargetPlatform.iOS
      ? AppConstants.iosInterstitialAdUnitId
      : AppConstants.interstitialAdUnitId;
}

static String get _rewardedAdUnitId {
  if (kDebugMode) return 'ca-app-pub-3940256099942544/5224354917';
  return defaultTargetPlatform == TargetPlatform.iOS
      ? AppConstants.iosRewardedAdUnitId
      : AppConstants.rewardedAdUnitId;
}
```

**3. iOS ad unit'lerini AdMob'da oluştur (iOS geliştirici):**

[apps.admob.com](https://apps.admob.com) → iOS uygulaması seç →
Ad Units → 3 adet yeni unit ekle (Banner, Interstitial, Rewarded).
ID'leri yukarıdaki `defaultValue` alanlarına yaz.

---

## SORUN 9 — iOS Paywall'da Introductory Price Gösterilmiyor 🟡

### Açıklama
`_parseIOSProducts()` sadece regular price alıyor:

```dart
// purchase_service.dart satır 280-287
static void _parseIOSProducts() {
  for (final product in _products) {
    final plan = _iosProductIdToPlan(product.id);
    if (plan == null) continue;
    _planPricing[plan] = PlanPricing(
      plan: plan,
      offerToken: '',
      regularPrice: product.price,        // ← Sadece regular price
      regularPriceMicros: (product.rawPrice * 1000000).round(),
      currencyCode: product.currencyCode,
      // hasIntroOffer: false (varsayılan) — hiç kontrol edilmiyor
    );
  }
}
```

App Store Connect'te tanımlasan bile introductory price (ilk ay indirimli gibi)
paywall'da gösterilmeyecek.

### Çözüm

`in_app_purchase_storekit` paketi zaten projede mevcut. `SKProductDetails`'tan
intro price okunabilir:

```dart
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

static void _parseIOSProducts() {
  for (final product in _products) {
    final plan = _iosProductIdToPlan(product.id);
    if (plan == null) continue;

    String? introPrice;
    int? introPriceMicros;
    bool hasIntro = false;

    if (product is AppStoreProductDetails) {
      final skProduct = product.skProduct;
      final discount = skProduct.introductoryPrice;
      if (discount != null) {
        introPrice = discount.localizedPrice;
        introPriceMicros = (discount.price.toDouble() * 1000000).round();
        hasIntro = true;
      }
    }

    _planPricing[plan] = PlanPricing(
      plan: plan,
      offerToken: '',
      regularPrice: product.price,
      regularPriceMicros: (product.rawPrice * 1000000).round(),
      currencyCode: product.currencyCode,
      introPrice: introPrice,
      introPriceMicros: introPriceMicros,
      hasIntroOffer: hasIntro,
    );
  }
}
```

---

## SORUN 10 — `CFBundleDisplayName` Yanlış 🟡

### Açıklama
`ios/Runner/Info.plist` içinde:
```xml
<key>CFBundleDisplayName</key>
<string>Sudoku App</string>   <!-- ← Yanlış! -->
```

iOS home screen'de, App Store'da ve Settings'de "Sudoku App" görünüyor.
Olması gereken: **SudoQ**

### Çözüm — iOS Geliştirici
`ios/Runner/Info.plist` içinde değiştir:
```xml
<key>CFBundleDisplayName</key>
<string>SudoQ</string>
```

---

## SORUN 11 — `appVersion` Sabiti Eski 🟢

### Açıklama
```dart
// lib/core/constants/app_constants.dart satır 7
static const String appVersion = '1.0.3';  // ← Eski
```
`pubspec.yaml` → `version: 1.0.4+25`

### Çözüm
```dart
static const String appVersion = '1.0.4';
```

---

## SORUN 12 — `sudoq_premium_monthly` Cloud Function'da Var, Kodda Yok 🟢

### Açıklama
`functions/index.js` satır 26:
```javascript
const SUPPORTED_SUBSCRIPTIONS = new Set([
  "sudoq_premium",
  "sudoq_premium_weekly",
  "sudoq_premium_monthly",   // ← AppConstants'ta yok!
  "sudoq_premium_yearly",
]);
```

`AppConstants.subscriptionIds` ve `AppConstants.iosSubscriptionIds`'de
`sudoq_premium_monthly` yok. Bu ürünü App Store'a ekleyeceksen AppConstants'a
da eklemen gerekiyor. Eklemeyeceksen Cloud Function'dan çıkarılmalı.

### Çözüm
Eğer monthly plan planlanmıyorsa `index.js`'te temizle:
```javascript
const SUPPORTED_SUBSCRIPTIONS = new Set([
  "sudoq_premium",
  "sudoq_premium_weekly",
  "sudoq_premium_yearly",
]);
```

---

## Senden Beklenenler (Yanıt Gerekenler)

Aşağıdaki bilgiler olmadan bazı sorunları çözemeyiz. Lütfen kontrol et:

### 1. ✅ Doğru Bundle ID netleşti
Firebase Console'da kayıtlı: **`com.melodyyazilim.sudoq`**
`firebase_options.dart` güncellenmesi gerekiyor (Sorun 3'e bak).

### 2. `functions/.env` dosyasında neler var?
```bash
# Bu komutu çalıştır ve çıktıyı paylaş (secret değerlerini gizle)
type "c:\Users\AYGIR\OneDrive\Desktop\sudoq-app-main\sudoku_app\functions\.env"
```
`APPLE_SHARED_SECRET` var mı?

### 3. iOS AdMob unit ID'leri oluşturuldu mu?
AdMob'da iOS uygulaması için Banner, Interstitial, Rewarded unit'leri var mı?
Varsa ID'lerini paylaş.

### 4. App Store Connect'te ürünler tanımlı mı?
`sudoq_premium_weekly` ve `sudoq_premium_yearly` product ID'leri
"Ready to Submit" veya "Approved" durumunda mı?

---

## Düzeltme Sırası (Öneri)

```
1. Bundle ID'yi netleştir (Sorun 3) — diğer her şey buna bağlı
2. GoogleService-Info.plist ekle (Sorun 2)
3. iOS proje dosyalarını hazırla / ios-dev branch'ine geç (Sorun 4)
4. APPLE_SHARED_SECRET Firebase'e ekle + deploy (Sorun 1)
5. iOS AdMob unit ID'lerini AppConstants'a ekle (Sorun 8)
6. checkExpiredSubscriptions iOS desteği ekle (Sorun 5)
7. CFBundleDisplayName düzelt (Sorun 10) — basit, hemen yapılabilir
8. appVersion güncelle (Sorun 11) — basit
9. iOS intro price desteği ekle (Sorun 9)
10. App Store Server Notifications (Sorun 6) — uzun vadeli
```

---

*Bu döküman kod incelemesi ile hazırlanmıştır. Değişiklik yapmadan önce her maddeyi iOS geliştiriciyle koordineli şekilde uygulayın.*
