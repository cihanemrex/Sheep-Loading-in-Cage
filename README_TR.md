# Crate 3D — iPhone / iPad uygulama projesi

Bu paket kurulum dosyası (.ipa) değildir. Xcode'da açılabilen iOS kaynak projesidir.
Minimum hedef iOS / iPadOS 16; Xcode 16 veya daha yeni bir sürüm önerilir.
SwiftUI uygulama kabuğu ve cihazın WKWebView motoru kullanılır; model dosyaları uygulamaya gömülüdür.
Üçüncü taraf paket ve internet üzerinden yüklenen JavaScript yoktur.

## İçerik

- 300 × 225 × 100 cm kafes; 4 forklift ayağı; 30 cm naylon.
- 25 temsili koyun, göster/gizle; tek kapı animasyonu.
- PMC palet, ağ, iki yönde üçer strap, katman anahtarları.
- Dokunmatik döndürme ve iki parmakla yakınlaştırma; iPhone ve iPad düzeni.
- Türkçe / İngilizce, uygulama içinden geçiş. İlk dil cihazın diline göre seçilir.
- GLB paylaşımı: görüntüleyicideki paylaş düğmesi iOS paylaşım penceresini açar.
  Dosyalar'a kaydetme ve uygun hedeflere paylaşım cihazın sunduğu seçeneklere bağlıdır.
- Giriş gerekmez; 3D görüntüleme ve dışa aktarma çevrimdışı çalışır.
  Teknik referans bağlantıları Safari'yi açar ve internet gerektirir.
- Hesap, analitik, reklam, izleme veya kullanıcı verisi toplama eklenmedi.

## Windows + GitHub Actions ile derleme

Windows kullanıyorsanız **GITHUB_SETUP_TR.md** kılavuzunu izleyin. Paket iki Actions iş akışı içerir:
Apple anahtarı gerektirmeyen simülatör derlemesi ve elle başlatılan imzalı IPA / TestFlight yüklemesi.
Dosyalar repository köküne yüklenmelidir; ZIP tek dosya olarak yüklenmez.

## Kendi iPhone'unuza yükleme (yerel Mac seçeneği)

1. ZIP'i Mac'te açın; SheepCrate.xcodeproj dosyasını Xcode'da açın.
2. Xcode > Settings > Apple Accounts bölümünde Apple hesabınızı ekleyin.
3. SheepCrate target > Signing & Capabilities bölümünde Automatically manage signing açık kalsın;
   Team alanından kendi takımınızı seçin. Gerekiyorsa Bundle Identifier'ı benzersiz bir değerle değiştirin.
4. iPhone'u Mac'e bağlayın, cihaz eşleştirmesini tamamlayın; istendiğinde Developer Mode'u etkinleştirin.
5. Üst menüde SheepCrate şemasını ve kendi iPhone'unuzu seçin; Run düğmesine basın.
   Simülatör için cihaz yerine bir iPhone Simulator seçilebilir.

Apple hesabı ve imza yalnızca derleme/kurulum içindir; uygulamayı kullanırken ChatGPT girişi yoktur.
Geliştirme hesabıyla yapılan kurulumun kullanım koşulları Apple hesabının türüne bağlıdır.
TestFlight / App Store dağıtımı için kendi Apple Developer Program üyeliğiniz ve dağıtım işlemleri gerekir.
Bu paket App Store Connect'e yüklenmedi; Apple incelemesi veya mağaza kabulü garanti edilmez.

## Mac'te derleme kontrolü

```sh
xcodebuild -project SheepCrate.xcodeproj -scheme SheepCrate -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

Fiziksel cihaz dağıtımı: Xcode > Product > Archive, ardından Organizer üzerinden kendi hesabınızla dağıtım.

## Doğrulama durumu ve cihaz kontrolleri

Bu proje Linux ortamında hazırlandı. Swift / iOS SDK ve Xcode mevcut olmadığından
native derleme, iOS Simulator, fiziksel iPhone, iPad paylaşım penceresi veya imzalama testi yapılmadı.
Paket yapısı, proje referansları, kaynak dosyalar ve HTML JavaScript sözdizimi kontrol edildi;
mevcut web modelinin mobil düzeni daha önce tarayıcı önizlemesinde doğrulandı.

Mac'te ilk çalıştırmada kontrol edin:

- Uçak modunda uygulama açılışı; iki dil arasında geçiş.
- 25 koyun anahtarı, PMC palet ve naylon/ağ/strap katmanları.
- Ağ ve straplar kapalıyken kapının açılıp kapanması.
- Döndürme, iki parmakla yakınlaştırma, yatay/dikey yönler.
- GLB'yi Dosyalar'a kaydetme; modelin seçili katmanları içermesi.
- iPad paylaşım ekranı; referans bağlantısının Safari'de açılması.

## Tasarım sınırı

Bu görsel bir konsept modeldir. Hayvan ölçüleri temsilidir; 25 koyun onaylanmış taşıma
kapasitesi değildir. Uçak yükleme, sabitleme, dayanım, havalandırma ve hayvan refahı onayı yerine geçmez.

## Apple belgeleri

https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices
https://developer.apple.com/documentation/webkit/wkwebview/loadfileurl(_:allowingreadaccessto:)
