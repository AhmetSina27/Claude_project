# Odaklanma Zamanı: Yayınlama Rehberi

Bu klasörde mağazalar için gereken her şey hazır:

| Dosya / klasör | İçerik |
|---|---|
| `iphone/` | 6 ekran görüntüsü, 1320×2868 (iPhone 6.9", App Store'un zorunlu boyutu) |
| `ipad/` | 3 ekran görüntüsü, 2732×2048 (iPad 13", yatay) |
| `mac/` | 3 ekran görüntüsü, 2880×1800 (Mac App Store) |
| `magaza_metinleri.md` | Ad, alt başlık, açıklama, anahtar kelimeler (TR + EN), Google Play metinleri, reklam metinleri |
| `gizlilik_politikasi.md` | Gizlilik politikası metni (yayınlanması gerekir, aşağıya bak) |
| `../assets/icon/icon.png` | 1024×1024 uygulama simgesi (tüm platformlara uygulandı) |

---

## 1. Hazırlık (bir kez)

1. **Geliştirici hesapları**
   - Apple Developer Program: yıllık 99 USD, https://developer.apple.com/programs/ (iPhone, iPad ve Mac için tek hesap)
   - Google Play Console: tek seferlik 25 USD, https://play.google.com/console
2. **Gizlilik politikası bağlantısı**: Her iki mağaza da herkese açık bir bağlantı ister. `gizlilik_politikasi.md`
   metnine e-posta adresini ekleyip bir web sayfasında yayınla (ör. GitHub Pages, Google Sites ya da
   kendi alan adın).
3. **Uygulama kimliği**: `com.odaklanmazamani.app`. İstersen kendi alan adınla değiştir; mağazaya yükledikten
   sonra değiştirilemez.

## 2. iPhone, iPad ve Mac (App Store)

Gerekenler: bir Mac, Xcode (App Store'dan ücretsiz) ve Flutter.

```bash
flutter pub get
cd ios && pod install && cd ..
flutter build ipa --release
```

1. Xcode'da `ios/Runner.xcworkspace` dosyasını aç → Runner → Signing & Capabilities → Team olarak
   Apple Developer hesabını seç.
2. https://appstoreconnect.apple.com → Uygulamalarım → **+** → Yeni Uygulama:
   ad "Odaklanma Zamanı", birincil dil Türkçe, paket kimliği `com.odaklanmazamani.app`.
3. `build/ios/ipa/*.ipa` dosyasını **Transporter** uygulamasıyla yükle (ya da Xcode → Product → Archive →
   Distribute App).
4. App Store Connect'te `magaza_metinleri.md` içindeki metinleri ve `iphone/`, `ipad/` görsellerini ekle.
5. **Uygulama Gizliliği** bölümünde "Veri toplanmıyor" seçeneğini işaretle.
6. **İncelemeye gönder.** İnceleme notuna şunu yaz: *"Arka planda ses çalma (UIBackgroundModes: audio),
   odak sırasında seçilen ortam seslerinin (yağmur, şömine vb.) ekran kilitliyken de çalması için kullanılır."*

**Mac için** aynı App Store Connect kaydına macOS platformunu ekle, sonra:

```bash
flutter build macos --release
```

Xcode'da `macos/Runner.xcworkspace` → Product → Archive → Distribute App → App Store Connect.
Görseller: `mac/` klasörü.

## 3. Android (Google Play)

```bash
keytool -genkey -v -keystore ~/odaklanma-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

`android/key.properties` dosyasını oluştur (bu dosyayı kimseyle paylaşma, git'e ekleme):

```
storePassword=<şifren>
keyPassword=<şifren>
keyAlias=upload
storeFile=/Users/<kullanıcı>/odaklanma-upload.jks
```

Uygulama bu dosyayı bulunca yayın paketini otomatik olarak senin anahtarınla imzalar. Sonra:

```bash
flutter build appbundle --release
```

Play Console → Uygulama oluştur → `build/app/outputs/bundle/release/app-release.aab` dosyasını yükle.
Mağaza girişi için `magaza_metinleri.md` içindeki Google Play metinlerini kullan.
Telefon ekran görüntüsü olarak `iphone/` görselleri de kabul edilir (en boy oranı uygun).
**İzin beyanları:** `SCHEDULE_EXACT_ALARM` için "Kullanıcının başlattığı zamanlayıcı bitince haber vermek",
`ACCESS_NOTIFICATION_POLICY` için "Kullanıcı isterse odak süresince Rahatsız Etme modunu açmak".

## 4. Yayından önce kontrol listesi

- [ ] Gerçek bir iPhone, iPad, Android telefon ve Mac'te uygulamayı en az bir odak + mola döngüsü boyunca dene
- [ ] Ekran kilitliyken ortam sesi çalmaya devam ediyor mu?
- [ ] Süre dolunca bildirim ve zil geliyor mu?
- [ ] Android'de Rahatsız Etme izni verilince odak sırasında bildirimler susuyor mu?
- [ ] Galeriden fotoğraf ve video seçme çalışıyor mu?
- [ ] Gizlilik politikası bağlantısı herkese açık mı?
