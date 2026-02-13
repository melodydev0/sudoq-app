# Widget Test Rehberi – SudoQ

Bu dokümanda projede widget testlerinin nasıl yazılacağı özetleniyor.

## Temel yapı

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Açıklama', (WidgetTester tester) async {
    // 1. Widget'ı yerleştir
    await tester.pumpWidget(MyWidget());
    // 2. Bir frame ilerlet (gerekirse)
    await tester.pump();
    // 3. Beklentileri yaz
    expect(find.byType(MyWidget), findsOneWidget);
  });
}
```

- **testWidgets**: Her test bir `WidgetTester` alır; `pumpWidget`, `pump`, `tap`, `enterText` vb. ile etkileşim yapılır.
- **find**: Ağaçta widget/metin bulmak için: `find.byType(Widget)`, `find.text('Metin')`, `find.byKey(Key('key'))`.
- **expect + findsOneWidget / findsWidgets / findsNothing**: Bulunan sayıyı doğrular.

## Bu projede dikkat edilecekler

### 1. StorageService (SharedPreferences)

Birçok ekran `StorageService` kullanıyor. Testte önce mock değerlerle başlatın:

```dart
setUpAll(() async {
  SharedPreferences.setMockInitialValues({});
  await StorageService.init();
});
```

### 2. Riverpod (ProviderScope)

`ConsumerWidget` / `ConsumerStatefulWidget` kullanan ekranlar `ProviderScope` içinde olmalı:

```dart
await tester.pumpWidget(
  const ProviderScope(
    child: MaterialApp(home: HomeScreen()),
  ),
);
```

### 3. Lokalizasyon (AppLocalizations.of(context))

`AppLocalizations.of(context)` kullanan ekranlar için `MaterialApp`'e delegate ve locale verin:

```dart
await tester.pumpWidget(
  const ProviderScope(
    child: MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
      locale: Locale('en'),
      home: HomeScreen(),
    ),
  ),
);
```

### 4. Zamanlayıcılar (Timer / Future.delayed)

Test sonunda "pending timer" hatası almamak için süreleri ilerletin:

```dart
await tester.pump(const Duration(milliseconds: 2500));
// veya birkaç frame: await tester.pump(); await tester.pump();
```

Navigasyon sonrası açılan ekranda da timer varsa, onu da `pump(duration)` ile geçirin.

### 5. Ekran boyutu (overflow)

Küçük test yüzeyinde layout taşması oluyorsa yüzeyi büyütün; test bitince sıfırlayın:

```dart
await tester.binding.setSurfaceSize(const Size(400, 800));
addTearDown(() => tester.binding.setSurfaceSize(null));
```

## Sık kullanılan find / expect

| Amaç | Kod |
|------|-----|
| Belirli tipte widget | `find.byType(MyScreen)` |
| Metin | `find.text('Merhaba')` |
| Key ile | `find.byKey(Key('my_key'))` |
| İkon | `find.byIcon(Icons.add)` |
| Bir tane bulundu | `expect(..., findsOneWidget)` |
| En az bir tane | `expect(..., findsWidgets)` |
| Hiç yok | `expect(..., findsNothing)` |

## Etkileşim

```dart
await tester.tap(find.byIcon(Icons.play));
await tester.pump(); // veya pumpAndSettle() animasyon bitene kadar

await tester.enterText(find.byType(TextField), '123');
await tester.pump();
```

## Çalıştırma

```bash
# Tüm testler
flutter test

# Sadece widget testleri
flutter test test/widget_test.dart

# Belirli bir test (pattern)
flutter test test/widget_test.dart --name "HomeScreen"
```

## Örnek: Yeni bir ekran testi

```dart
testWidgets('SettingsScreen builds', (WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: supportedLocales,
        locale: Locale('en'),
        home: SettingsScreen(),
      ),
    ),
  );
  await tester.pump();
  expect(find.byType(SettingsScreen), findsOneWidget);
});
```

Mevcut örnekler için `test/widget_test.dart` dosyasına bakın.
