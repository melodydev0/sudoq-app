# GEMINI İÇİN TALİMAT: Tüm Animasyonlar – Premium Hissiyat

**Bu metni olduğu gibi Gemini’ye yapıştır.** Cursor (ve gerekirse diğer agentlar) senin çıktılarını projeye uygulayacak ve test edecek. Birlikte tüm animasyonları **premium** seviyeye getiriyoruz.

---

## Rol ve hedef

Sen Flutter/Dart animasyon uzmanısın. Bu sudoku uygulamasındaki **tüm** animasyonları “yeterli” değil **premium** hissettirecek şekilde yükseltiyorsun. Premium = kullanıcı “vay” desin, Duolingo / Clash Royale / iyi mobil oyunlardaki başarı/level up/victory anları gibi.

- **Referans his:** Duolingo kutlamaları, Clash Royale kart açılışı, premium oyunlarda “level up” / “victory”.
- **Akıcı:** 60 fps, doğru easing (`Curves.easeOut`, `elasticOut`, `easeOutCubic`), zamanlama düzgün.
- **Katmanlı:** Tek fade değil; giriş → vurgu (parıltı/pulse) → hafif settle.
- **Detay:** Gradient, blur, glow, parçacık çeşitliliği, hafif secondary motion (sallanma, overshoot).
- **Kısıt:** Public API’ler, callback’ler ve L10n **aynı kalacak**; sadece implementasyon (süre, curve, çizim) değişecek.

---

## Güncellenecek tüm dosyalar (liste)

| # | Dosya | İçerik |
|---|-------|--------|
| 1 | `lib/core/widgets/celebration_effect.dart` | CelebrationEffect, RippleEffect, SuccessCheckmark, GlowPulseEffect |
| 2 | `lib/features/battle/presentation/widgets/rank_up_celebration_overlay.dart` | Rütbe atlama: konfeti, eski→yeni geçiş, “Promoted!” |
| 3 | `lib/features/battle/presentation/screens/battle_result_screen.dart` | Victory/Defeat badge animasyonu + glow |
| 4 | `lib/features/settings/presentation/screens/animations_debug_screen.dart` | `_ResultBadgeTestPage` (aynı premium badge) |
| 5 | `lib/features/game/presentation/widgets/game_complete_dialog.dart` | Dialog girişi, ikon, istatistik stagger, butonlar |
| 6 | `lib/features/level/presentation/screens/level_progress_screen.dart` | Confetti, XP sayacı, progress bar, level-up kartı |
| 7 | `lib/features/game/presentation/widgets/sudoku_grid.dart` | **Satır/sütun/kutu tamamlama** efekti: `_createAnimationForSection`, `_CompletionEffectPainter` |

Hepsi premium his vermeli; “basit” veya “yeterli” kalmamalı.

---

## Dosya bazlı hedefler

### 1) celebration_effect.dart
- **CelebrationEffect:** Partikül çeşidi (yıldız, daire, ince çizgi), renk geçişi, burst sonrası yumuşak fade, 500–700ms.
- **RippleEffect:** 2–3 halka, gecikmeli dalga, “nefes alan” his.
- **SuccessCheckmark:** Daire “çiziliyor” hissi, check stroke kalitesi, bitişte kısa scale pulse.
- **GlowPulseEffect:** Yumuşak curve, isteğe bağlı çift katman glow. Constructor aynı kalacak.

### 2) rank_up_celebration_overlay.dart
- Konfeti: Şekil çeşitliliği, sway, farklı hızlar, “kutlama patlaması” hissi.
- Eski rütbe: Hafif slide (push) + scale + fade.
- Yeni rütbe: Glow pulse, elasticOut.
- “Promoted!”: Slide + shadow/glow. `fromRank`, `toRank`, `onDismiss`, L10n korunacak.

### 3) battle_result_screen.dart + (4) animations_debug_screen _ResultBadgeTestPage
- Badge girişi: elasticOut scale, radial gradient veya parıltı.
- Victory/Defeat ikon ve metin: premium giriş; test sayfası aynı kalitede.

### 5) game_complete_dialog.dart
- Dialog: scale (0.85→1) + fade, easeOutCubic/elasticOut.
- İkon: trophy lift veya kaybetme için hafif sallanma.
- İstatistik: stagger 50–80ms.
- Butonlar: fade-in veya slide-up. Tüm parametreler aynı.

### 6) level_progress_screen.dart
- Confetti: rank_up ile aynı seviyede zenginlik (şekil, sway).
- XP sayacı: hop veya scale pop.
- Progress bar: easeOut dolum, dolunca kısa glow/pulse.
- Level-up kartı: slide + scale, metin highlight. `SoundService().playVictory()`, L10n korunacak.

### 7) sudoku_grid.dart – Satır / sütun / kutu tamamlama
- **Şu an:** `_createAnimationForSection`: 500ms, TweenSequence (easeOutBack → easeInOut → easeIn). `_CompletionEffectPainter`: glow, fill, border, shine sweep.
- **İstenen (premium):**
  - Animasyon süresi ve curve’ler: Daha tatmin edici “pop” (örn. 550–600ms), belki hafif overshoot sonra settle.
  - Çizim: Glow daha yumuşak (blur/alpha), satır/sütun için ince “çizgi” hissi; kutu için daha belirgin altın gradient ve belki hafif iç parıltı veya ikinci bir shine geçişi.
  - Shine: Mevcut sweep’i koruyup daha akıcı veya çift geçiş (antepasyon + ana vuruş).
- **Korunacak:** `CompletedSection`, `SudokuGrid(completedSections: ...)`, grid’in davranışı; sadece `_createAnimationForSection` ve `_CompletionEffectPainter` implementasyonu değişecek.

---

## Teknik kurallar

- Flutter 3.x, null-safe Dart. Mümkünse ek paket yok; `material.dart` + `dart:math` + CustomPainter/AnimationController.
- Hiçbir widget’ın public constructor parametrelerini kaldırma/değiştirme.
- `AppLocalizations`, `ResponsiveUtils.init`, `.sp` / `.w` aynen kalsın.
- Tüm `AnimationController` dispose edilsin.

---

## Çıktı formatı (Cursor’ın uygulayabilmesi için)

- Her dosya için **tam Dart kodu** (kopyala-yapıştır) **veya** net patch (“X dosyası, Y–Z satırları şöyle olsun”).
- Değişen dosya listesini path ile özetle.
- Yeni `Duration` / `Curve` değerlerini yaz.

İlk cevabında en az **bir tam dosya** (tercihen `celebration_effect.dart` veya `sudoku_grid.dart` section effect) ver; sonra diğerlerini tek tek veya toplu verebilirsin.

---

## Ekip çalışması (Gemini + Cursor / diğer agentlar)

- **Sen (Gemini):** Tasarım + kod; premium his için curve, süre, parçacık/çizim detaylarını sen belirliyorsun.
- **Cursor:** Kodu projeye uyguluyor, `flutter analyze` ve gerekirse test çalıştırıyor. Sen yetersen veya bir efekt “şöyle olsun” diye tarif edersen, Cursor aynı talimata göre implemente edebilir veya önerdiğin kodu sadeleştirip entegre edebilir.
- **Premium bar:** “Yeterli” değil “ilk açıldığında gülümseten” seviye. Bir efekt hâlâ basit hissediyorsa, Cursor senin tarifine göre ek polish (glow, stagger, secondary motion) ekleyebilir.

---

## Cursor’a devir (Gemini cevabından sonra)

Gemini’den kodu aldıktan sonra Cursor’a şunu yaz:

- *“Gemini animasyon güncellemelerini verdi. docs/GEMINI_ANIMATION_UPGRADE_PROMPT.md’deki talimata göre dosyaları güncelle, entegre et, flutter analyze çalıştır. Eksik veya hata varsa düzelt; premium his eksik kalan yerleri de aynı dokümana göre cilala.”*

Cursor bu talimatla hem Gemini çıktısını uygulayacak hem de gerekirse premium hissi tamamlayacak.
