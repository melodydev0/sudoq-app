# Firebase Kurulum Özeti – SudoQ

## Projede Şu An Ne Var?

### Kurulu paketler (pubspec.yaml)
- **firebase_core** – Firebase başlatma
- **firebase_auth** – Giriş (Anonymous, Google)
- **cloud_firestore** – Veritabanı (tüm veri burada)
- **google_sign_in** – Google ile giriş

**Realtime Database paketi yok** – Projede sadece **Firestore** kullanılıyor.

### Kod tarafı
- `lib/firebase_options.dart` – Android + iOS için `projectId: sudoq-online`
- `android/app/google-services.json` – Android proje bağlantısı
- `main.dart` – `Firebase.initializeApp()` (try-catch ile)
- Android: `com.google.gms.google-services` plugin uygulanmış

### Kullanılan Firestore koleksiyonları

| Koleksiyon / Yol | Nerede kullanılıyor | Amaç |
|------------------|---------------------|------|
| **users** | auth_service, user_sync_service | Profil, duelStats, ayarlar |
| **battles** | battle_service | Duel maçları (canlı durum) |
| **matchmaking** | battle_service | Eşleşme kuyruğu |
| **duel_leaderboard** | auth_service, user_sync_service, leaderboard_screen | Duel sıralaması |
| **leaderboard** | user_sync_service | Genel liderlik (XP vb.) |
| **users/{uid}/duel_history** | battle_service | Kullanıcı duel geçmişi |

Duel (eşleşme, maç, skor) zaten **tamamen Firestore** ile yazılmış; Realtime Database kullanılmıyor.

---

## Giriş yapmadan duel + sonra giriş (veri aktarımı)

**Cihaz ID kullanmıyoruz.** Firebase **Anonymous Auth** ile tek seferlik bir **UID** alıyoruz; bu UID cihazda (Firebase SDK) saklanır, uygulama silinene / veri temizlenene kadar aynı kalır.

### Akış

1. **Giriş yapmadan (misafir)**  
   - Kullanıcı "Start Duel"e basar → arka planda `signInAnonymously()` çağrılır.  
   - Firebase bir **anonymous UID** üretir (cihazda kalıcı).  
   - ELO, galibiyet/mağlubiyet **LocalDuelStatsService** ile cihazda tutulur.  
   - Firestore’da **users/** dokümanı oluşturulmaz (veri tasarrufu).

2. **Sonra Google ile giriş**  
   - `signInWithGoogle()` çağrılır.  
   - Eğer **şu anki kullanıcı anonymous ise**: Google hesabı bu anonymous hesaba **bağlanır** (`linkWithCredential`) → **UID değişmez.**  
   - Ardından ilk kez **users/{uid}** dokümanı oluşturulur ve **yerel duel verisi** `syncToCloud()` ile Firestore’a yazılır.  
   - Böylece “cihazdaki gelişim” aynı hesaba (aynı UID) taşınmış olur; ayrı bir “cihaz ID’den Google’a aktarım” adımı yok.

3. **Zaten Google ile giriş yapmış kullanıcı**  
   - `signInWithGoogle()` → normal giriş (veya link yoksa yeni UID).  
   - `syncFromCloud()` ile veri buluttan okunur.

Özet: **Cihaz ID yok; anonymous UID var. Giriş yapınca hesap bağlanıyor (link), veriler aynı UID altında buluta yazılıyor.**

---

## Eksikler (Firebase Console’da Yapılacaklar)

Console’a erişemiyorsan: Proje `sudoq-online` başka bir Google hesabıyla açılmış olabilir. Ya o hesapla giriş yapacaksın ya da kendi Firebase projeni oluşturup `google-services.json` + `firebase_options.dart` dosyalarını yeni projeye göre güncelleyeceksin.

### 1. Authentication
- **Authentication → Sign-in method** aç.
- **Anonymous** → **Enable** yap (Start Duel için gerekli).
- **Google** → **Enable** yap, gerekirse Web SDK için SHA-1 ekle (Android).
- **Apple** → **Enable** yap (Sign in with Apple için; Apple Developer hesabı + Firebase’de Apple provider ayarı gerekir).

### 2. Firestore Database
- **Build → Firestore Database**.
- **Create database** ile veritabanını oluştur.
- **Location** seç (örn. `europe-west1`); sonradan değiştirilemez.
- **Test mode** veya **Production** seç (test modda 30 gün açık kurallar).

### 3. Firestore kuralları (örnek – güvenli hale getirilebilir)

Test için kısa süre şöyle kullanılabilir (güvenlik zayıf):

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /battles/{battleId} {
      allow read, write: if request.auth != null;
    }
    match /matchmaking/{docId} {
      allow read, write: if request.auth != null;
    }
    match /duel_leaderboard/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /leaderboard/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

Koleksiyonlar ilk yazıda otomatik oluşur; sadece kuralların izin vermesi gerekir.

---

## Realtime Database vs Firestore – Birlikte Kullanım

### Farklar
- **Firestore**: Koleksiyon/döküman, güçlü sorgular, offline, canlı dinleme (`snapshots()`). Projede duel ve tüm veri burada.
- **Realtime Database**: Büyük JSON ağacı, çok hızlı anlık güncelleme, basit yapı. Projede şu an **hiç kullanılmıyor**.

### Aynı projede ikisi birlikte kullanılır mı?
- **Evet.** Aynı Firebase projesinde hem Firestore hem Realtime Database açılabilir. İkisi **ayrı** veritabanlarıdır; veri birbirine karışmaz.
- “Ortak DB” değillerdir: Farklı API’ler (Firestore: `collection().doc()` vs Realtime: `ref().child()`). İkisine de yazıp okuyabilirsin; hangi veriyi nereye yazacağını sen seçersin.

### Duel için Realtime DB’ye geçmek gerekir mi?
- **Hayır.** Duel akışı (matchmaking, battles, skor) zaten Firestore ile ve `snapshots()` ile anlık dinleniyor. Realtime DB’ye geçmek büyük kod değişikliği gerektirir; aynı işi Firestore ile yapabiliyorsun.
- Realtime DB genelde: çok sık güncellenen tek bir harita, basit oda listesi, basit sohbet gibi senaryolar için tercih edilir. SudoQ’daki duel yapısı (maç dokümanları, kullanıcı profili, liderlik) Firestore’a daha uygun.

### Öneri
- **Şu anki yapıyı koru:** Tüm veri Firestore’da kalsın (users, battles, matchmaking, leaderboard).
- Console’da sadece **Firestore** oluşturup kuralları ayarla; Realtime DB ekleme.
- İleride gerçekten “anlık tek bir obje” ihtiyacı olursa (örn. canlı skor tickeri) o kısım için Realtime DB eklenebilir; o zaman hem Firestore hem Realtime DB aynı projede kullanılır, problem yaratmaz.

---

## Hızlı kontrol listesi

- [ ] Firebase Console’da proje erişimi (sudoq-online veya yeni proje)
- [ ] Authentication → Anonymous **Enabled**
- [ ] Authentication → Google **Enabled** (isteğe bağlı)
- [ ] Firestore Database **Create database** + location
- [ ] Firestore **Rules** yukarıdaki gibi (veya daha sıkı) ayarlandı
- [ ] Uygulama içinde Start Duel / giriş tekrar test edildi

Eğer yeni bir Firebase projesi oluşturursan:
1. Flutter projesinde: `flutterfire configure` (Firebase CLI + giriş gerekir).
2. Bu komut `google-services.json` ve `lib/firebase_options.dart` dosyalarını yeni projeye göre günceller.
