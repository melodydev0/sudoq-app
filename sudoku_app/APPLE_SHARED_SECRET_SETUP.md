# iOS Ödeme Doğrulamasını Aktif Etme

Bu rehber **Apple Shared Secret** alınıp Firebase'e eklenerek
iOS satın almalarının sunucu tarafında doğrulanmasını aktif eder.

---

## Genel Bakış

```
iPhone (Kullanıcı satın alır)
    → App Store receipt Flutter'a döner
        → Flutter → Firestore'a purchase_claim yazar
            → Firebase Cloud Function receipt'i Apple'a doğrulatır
                → APPLE_SHARED_SECRET olmadan bu adım hata verir!
```

---

## Adım 1 — App Store Connect'ten Shared Secret Al (Ortak yapar)

1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) giriş yap

2. **Users and Access** → sol menüden **Integrations** sekmesini aç

3. **In-App Purchase** bölümünde → **App-Specific Shared Secrets**

4. SudoQ uygulamasının yanındaki **Generate** veya **Manage** butonuna bas

5. Oluşan secret şuna benzer:
   ```
   a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2
   ```
   (32 karakter, hex formatında)

6. Bu değeri **güvenli bir şekilde** (şifreli mesaj ile) paylaş.
   Bu secret gizli tutulmalı, repoya commit edilmemeli!

> **Not:** "Generate" yerine "App-Specific" değil "Master Shared Secret"
> de oluşturabilirsin. İkisi de çalışır. App-Specific daha güvenlidir.

---

## Adım 2 — Firebase Functions'a Secret Ekle (Sen yaparsın)

### Yöntem A — .env dosyasıyla (Önerilen - basit)

`functions/.env` dosyasını aç, sona ekle:

```
APPLE_SHARED_SECRET=a1b2c3d4e5f6...buraya_kopyala
```

Dosyanın son hali böyle görünmeli:
```
ONESIGNAL_APP_ID=ff6a85b4-2c80-4fec-bb70-075ccf869d27
ONESIGNAL_REST_API_KEY=os_v2_app_...
APPLE_SHARED_SECRET=a1b2c3d4...buraya_ortagin_gonderdigi_deger
```

> ⚠️ `functions/.env` zaten `.gitignore`'da var, repoya gitmez. Güvenli.

---

### Yöntem B — Firebase Secret Manager (Daha güvenli, opsiyonel)

```bash
firebase login  # oturum açık değilse
firebase functions:secrets:set APPLE_SHARED_SECRET
# Terminal sorar: "Enter a value for APPLE_SHARED_SECRET:"
# Secret'ı yapıştır, Enter
```

Sonra `functions/index.js` başına secret referansı eklemek gerekir:
```js
// (Bu değişiklik Yöntem B için gerekli, A için gerekmez)
const { defineSecret } = require("firebase-functions/params");
const appleSecret = defineSecret("APPLE_SHARED_SECRET");
```

**Yöntem A daha kolay** — büyük ihtimalle yeterli.

---

## Adım 3 — Cloud Function'ı Deploy Et

```bash
cd c:\cursor_projects\sudoku_app

firebase deploy --only functions:verifyPurchaseClaim
```

Deploy başarılı olunca terminalde şunu görürsün:
```
✔  functions[verifyPurchaseClaim] Successful update operation.
```

---

## Adım 4 — Doğrulama Logu Aç (Firebase Console)

Deploy'dan sonra test alımı yapılmadan önce logları hazır et:

1. [console.firebase.google.com](https://console.firebase.google.com) → `sudoq-online` projesi
2. Sol menü → **Functions** → **Logs**
3. Filtre kutusuna `verifyAppleSubscription` yaz

---

## Adım 5 — Test Satın Alması (Ortak yapar)

Ortak TestFlight veya gerçek cihazda sandbox test hesabıyla satın alma yapsın.

Satın alma sonrası Firebase Logs'ta şunlardan birini görmelisin:

**✅ Başarılı:**
```
[verifyAppleSubscription] receipt verified
state: "ACTIVE"
productId: "sudoq_premium_weekly"
basePlanId: "weekly"
```

**❌ Secret Eksik:**
```
Error: missing_apple_shared_secret
```
→ `.env` dosyasına eklemeyi ve deploy etmeyi kontrol et.

**❌ Geçersiz Receipt:**
```
Error: apple_receipt_invalid_21003
```
→ Receipt bozuk gelmiş, ortağa haber ver, yeniden denesin.

**❌ Unsupported Product:**
```
status: "rejected"
error: "unsupported_product"
```
→ App Store Connect'teki Product ID tam olarak
  `sudoq_premium_weekly` veya `sudoq_premium_yearly` değil.
  Ortak kontrol etmeli.

---

## Adım 6 — Admin Panelde Kontrol Et

1. [admin.sudoq.app](https://admin.sudoq.app) giriş yap
2. **Payments** sayfasına git
3. iOS ödemesi geldi mi kontrol et:
   - Platform sütununda 🍎 görünmeli
   - Status: `verified`
   - Plan: `Weekly` veya `Yearly`
   - Fiyat: App Store'da tanımlı fiyat

4. **Users** sayfasında kullanıcıyı bul:
   - Plan badge: `Premium Weekly` / `Premium Yearly` görünmeli

---

## Hata Durumları Hızlı Referans

| Hata | Nedeni | Çözüm |
|---|---|---|
| `missing_apple_shared_secret` | `.env`'e eklenmemiş | Adım 2'yi tekrar yap |
| `apple_receipt_invalid_21007` | Prod receipt sandbox'ta | Otomatik retry var, sorun değil |
| `apple_receipt_invalid_21003` | Receipt bozuk | Ortak yeniden satın alsın |
| `unsupported_product` | Yanlış Product ID | App Store Connect'te kontrol et |
| `invalid_claim_payload` | `receiptData` boş gelmiş | Flutter tarafı sorunu, ortağa bildir |

---

## Özet Kontrol Listesi

- [ ] Ortak App Store Connect'ten Shared Secret aldı
- [ ] Shared Secret güvenli kanaldan sana iletildi
- [ ] `functions/.env`'e `APPLE_SHARED_SECRET=...` eklendi
- [ ] `firebase deploy --only functions:verifyPurchaseClaim` çalıştırıldı
- [ ] Ortak TestFlight'ta sandbox satın alması yaptı
- [ ] Firebase Logs'ta `verifyAppleSubscription` başarılı görüntülendi
- [ ] Admin panelde 🍎 platformlu `verified` ödeme göründü
- [ ] Kullanıcı profili `Premium` olarak güncellendi

---

*Hazırlayan: SudoQ Android Geliştirici*
*Son güncelleme: Nisan 2026*
