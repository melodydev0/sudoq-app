# Firestore Kurulum Rehberi (SudoQ)

Uygulama Duel (eşleşme, sıralama) ve kullanıcı verileri için **Cloud Firestore** kullanıyor. Aşağıdaki adımları tamamlaman gerekir.

---

## 1. Firebase Console’da veritabanını oluştur

1. [Firebase Console](https://console.firebase.google.com/) → projeni seç (**sudoq-online**).
2. Sol menüden **Build** → **Firestore Database**.
3. **“Create database”** (Veritabanı oluştur) tıkla.
4. **Konum** seç (örn. `europe-west1` – Türkiye’ye yakın). Sonra **Next**.
5. **“Start in production mode”** seç (güvenlik kurallarını aşağıda deploy edeceğiz). **Enable** ile bitir.

İlk kez oluşturuyorsan bu adım zorunlu. Zaten “Firestore Database” sayfasını açıp koleksiyonları görüyorsan veritabanı mevcut, bu adımı atlayabilirsin.

---

## 2. Anonymous Authentication’ı aç

Duel’e giriş yapmadan (misafir) girebilmek için:

1. Sol menü **Build** → **Authentication**.
2. **Sign-in method** sekmesi → **Anonymous** satırına tıkla.
3. **Enable** aç, **Save**.

---

## 3. Güvenlik kurallarını yayımla

Projede `firestore.rules` dosyası var. Kuralları ya Console’dan ya da CLI ile yayımlayabilirsin.

### Seçenek A: Firebase CLI ile (önerilen)

1. Terminalde proje kökünde (`sudoku_app` klasöründe) çalıştır:
   ```bash
   firebase login
   firebase use sudoq-online
   firebase deploy --only firestore
   ```
2. “Deploy complete” görünce kurallar canlıya alınmış demektir.

### Seçenek B: Console’dan kopyala-yapıştır

1. [Firestore → Rules](https://console.firebase.google.com/project/sudoq-online/firestore/rules) sayfasını aç.
2. Bu repodaki **`firestore.rules`** dosyasının içeriğini kopyala, Console’daki editöre yapıştır.
3. **Publish** ile kaydet.

---

## 4. Kullandığımız koleksiyonlar

| Koleksiyon            | Amaç                          |
|-----------------------|-------------------------------|
| `users`               | Profil, istatistik (Google ile giriş) |
| `matchmaking`         | Duel eşleşme kuyruğu          |
| `battles`             | Aktif duel maçları            |
| `duel_leaderboard`     | ELO sıralaması               |
| `leaderboard`         | Seviye/XP sıralaması         |

Kurallar **anonim (misafir)** kullanıcıyı da destekliyor: `request.auth != null` hem Google hem Anonymous için geçerli.

---

## 5. Hata alıyorsan kontrol listesi

- [ ] Firestore veritabanı **oluşturuldu** (Firestore sayfasında “Create database” yapıldı).
- [ ] **Anonymous** auth açık (Authentication → Sign-in method).
- [ ] **Kurallar yayımlandı** (`firebase deploy --only firestore` veya Console’da Publish).
- [ ] Uygulamada **google-services.json** / **Firebase init** doğru (proje: sudoq-online).

Hâlâ “permission-denied” veya “unavailable” alıyorsan, tam hata mesajı ve hangi ekranda (Duel, Leaderboard vb.) olduğunu not et; kuralları o path’e göre sıkılaştırıp/gevşetebiliriz.
