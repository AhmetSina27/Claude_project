# Odaklanma Zamanı

Telefon, tablet ve bilgisayarda çalışan, kişiselleştirilebilir bir odaklanma (Pomodoro) zamanlayıcısı.
Web: https://ahmetsina27.github.io/ODAKLANMA-ZAMANI-UYGULAMASI/

Flutter ile tek kod tabanından Android, iOS, iPadOS, Windows, macOS, Linux ve web için derlenir.

## Özellikler

| # | İstek | Nerede |
|---|-------|--------|
| 1 | Kişiselleştirilebilir | Ayarlar: süreler, uzun mola aralığı, günlük hedef, 7 tema rengi, açık/koyu tema, otomatik başlatma, ses seviyeleri |
| 2 | Odakta bildirimlerin kapanması | Android: odak süresince sistem "Rahatsız Etme" modu açılır, bitince eski haline döner. iOS/macOS/Windows: işletim sistemi izin vermediği için kullanıcıya kurulum yönergesi gösterilir |
| 3 | Arka planda doğa, orman, yağmur, ateş… | 8 sakin ses: yağmur, şömine, dere, orman, okyanus dalgaları, karlı kulübe, kahverengi gürültü, tik tak. Her biri bir görsel efekt ve hareketli sahneyle eşleşir |
| 4 | Günlük etüt ve mola sayımı | Ana ekrandaki "Bugün" kartı ve İstatistikler ekranı (son 7 gün grafiği, seri) |
| 5 | Teneffüs zili | Odak bitince ve mola bitince zil (okul zili ya da guguk) |
| 6 | Odakta seçilen moda göre ses | Odak ve mola için ayrı ses/efekt seçimi; tik tak dahil |
| 7 | Odak sonunda tebrik ekranı | Konfeti ve alkış eşliğinde günlük etüt süresi, mola sayısı/süresi, hedef ilerlemesi ve ünlü birinin motivasyon sözü |

Ayrıca: ekranın büyük kısmını kaplayan çevirmeli (flip) saat (1 saatten kısa sürelerde yalnızca dakika ve saniye kartları),
hareketli arka planlar (hazır fotoğraf/video, cihazdan fotoğraf veya video seçme, "Moda göre" otomatik eşleşme,
soldurma ve bulanıklık ayarı), Karlı kulübe modu (kar yağışı efekti), tam ekran odak görünümü (tablet yatayda masa saati gibi), görev listesi,
uygulama kapalıyken bile doğru süre tutma, arka plandayken bildirim, ekranı açık tutma,
klavye kısayolları (Boşluk, R, S, F).

## Çalıştırma

[Flutter](https://docs.flutter.dev/get-started/install) kurulu olmalı (3.50 veya üstü).

```bash
flutter pub get
flutter run            # bağlı cihazda / emülatörde
flutter test           # testler
```

Platforma göre derleme:

```bash
flutter build appbundle      # Google Play (.aab)
flutter build apk            # Android kurulum dosyası
flutter build ipa            # App Store (Mac + Xcode gerekir)
flutter build macos          # Mac
flutter build windows        # Windows (Windows bilgisayarda)
flutter build linux          # Linux
flutter build web            # Web / PWA
```

## Mağazalara yüklemeden önce yapılacaklar

1. **Uygulama kimliği**: `com.odaklanmazamani.app` olarak ayarlı. Sana ait bir alan adı varsa
   (`com.seninadin.odaklanma` gibi) Android `android/app/build.gradle.kts` içindeki `applicationId`
   ile iOS/macOS Xcode projesindeki `PRODUCT_BUNDLE_IDENTIFIER` değerlerini değiştir.
2. **Uygulama simgesi**: Şu an Flutter'ın varsayılan simgesi var. 1024×1024 bir simge hazırlayıp
   `flutter_launcher_icons` paketiyle tüm platformlara üretebilirsin.
3. **Android imzası**: `android/app/build.gradle.kts` içindeki release imzası şimdilik debug anahtarını
   kullanıyor. Play Store için kendi upload anahtarını oluştur
   (https://docs.flutter.dev/deployment/android#sign-the-app).
4. **Google Play izin beyanları**: `SCHEDULE_EXACT_ALARM` (süre bitince zamanında bildirim) ve
   `ACCESS_NOTIFICATION_POLICY` (Rahatsız Etme) izinleri için Play Console'da kullanım amacını açıkla.
5. **Gizlilik politikası**: Uygulama hiçbir veriyi cihaz dışına göndermez; ayarlar ve istatistikler
   yalnızca cihazda saklanır. Mağazalar yine de bir gizlilik politikası bağlantısı ister.
6. **iOS**: Arka planda ses çalabilmesi için `UIBackgroundModes: audio` eklendi. App Store incelemesinde
   bunun ortam sesleri için kullanıldığını belirt.

## Hareketli sahneler

`lib/scenes/` klasöründe kodla çizilen 8 hareketli sahne var: Yıldız kayması, Kuzey ışıkları, Şömine,
Dağ gölü, Sisli orman, Karlı pencere, Gün batımı ve Sakin. Varsayılan "Moda göre" seçeneğinde sahne,
seçilen ortam sesine göre değişir. Sahneler telif gerektirmez, her ekran boyutunda keskindir ve pil için
saniyede 30 kareyle çizilir.

## Hazır arka plan (fotoğraf / video) eklemek

1. Fotoğrafı `assets/backgrounds/` klasörüne koy (ör. `ates.jpg`). Hareketli olacaksa aynı sahnenin
   sessiz, döngüye uygun kısa videosunu da koy (ör. `ates.mp4`, 1080p, 10-30 sn, H.264).
2. `pubspec.yaml` içinde `assets:` altına `- assets/backgrounds/` satırını ekle.
3. `lib/data/backgrounds.dart` dosyasındaki listeye bir satır ekle:
   `BackgroundPreset('ates', 'Şömine', 'assets/backgrounds/ates.jpg', video: 'assets/backgrounds/ates.mp4', sound: AmbientSound.ates)`

Video Android, iOS, iPadOS, macOS ve web'de oynar; Windows ve Linux'ta fotoğraf yavaşça hareket ederek gösterilir.
Mağazada yayınlayacağın görsel ve videoların ticari kullanım hakkına sahip olmalısın.

## Sesler

`assets/sounds/` içindeki tüm sesler `tool/generate_sounds.py` betiğiyle kodla üretilmiştir, telif
sorunu yoktur. Daha gerçekçi kayıtlar istersen aynı adla `.mp3` dosyası koyman yeterli
(ör. freesound.org'daki CC0 lisanslı kayıtlar).

Yazı tipi: Oswald (SIL Open Font License, `assets/fonts/OFL.txt`).

## Klasör yapısı

```
lib/
  main.dart                  Uygulamanın başlangıcı
  app.dart                   Tema ve uygulama kabuğu
  state/pomodoro_controller  Zamanlayıcı, sayımlar, görevler, ayarlar (uygulamanın beyni)
  models/                    Ayarlar, görev, günlük istatistik, aşama
  data/                      Ortam sesleri listesi, motivasyon sözleri
  services/                  Kayıt, ses, bildirim, Rahatsız Etme
  screens/                   Ana ekran, tam ekran odak, tebrik, istatistik, ayarlar
  widgets/                   Flip saat, arka plan efektleri, konfeti, ses seçici
android/app/src/main/kotlin  Android Rahatsız Etme kodu (MainActivity.kt)
test/                        Zamanlayıcı mantığı testleri
```
