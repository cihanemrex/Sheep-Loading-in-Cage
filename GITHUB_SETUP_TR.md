# Windows'tan GitHub Actions ile iOS derleme ve TestFlight

Bu paket GitHub'a yüklenebilir kaynak dosyalarını ve iki Actions iş akışını içerir.
Bir GitHub hesabında repository oluşturulmadı; gerçek GitHub/macOS derlemesi ve Apple yüklemesi
henüz çalıştırılmadı. Yerel Mac zorunlu değildir: derleme GitHub'ın macOS runner'ında yapılır.

## 1. Önce Apple anahtarı olmadan derlemeyi deneyin

1. GitHub'da yeni, **Private** bir repository oluşturun. Örnek ad: `sheep-crate-ios`.
2. Repository'yi boş oluşturun: GitHub'ın README, license ve .gitignore seçeneklerini eklemeyin.
3. Bu ZIP'i Windows'ta açın. Proje klasöründe `.github`, `ci`, `tools`, `SheepCrate`,
   `SheepCrate.xcodeproj` ve bu kılavuz birlikte bulunmalıdır.
4. Git for Windows kurulu değilse https://git-scm.com/downloads/win adresinden kurun.
5. Windows PowerShell'i proje klasöründe açın. Aşağıdaki örnekte kendi adresinizi kullanın:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\upload-github.ps1 -RepositoryUrl 'https://github.com/KULLANICI/sheep-crate-ios.git'
```

Bu komut yalnızca bu işlemdeki PowerShell süreci için script çalıştırma seçeneğini kullanır;
Windows'un kalıcı politikasını değiştirmez. GitHub oturum açma penceresi açılırsa kendi hesabınızla giriş yapın.
Git kullanıcı adı/e-posta isterse `git config --global user.name "Ad Soyad"` ve
`git config --global user.email "EPOSTANIZ"` ile ayarlayın, ardından normal Git commit/push işlemini tamamlayın.

ZIP'i tek dosya olarak repository'ye yüklemeyin. `.github/workflows` repository kökünde olmalıdır.
Web arayüzünden klasör sürükleme gizli `.github` klasörünü atlayabildiği için Git yöntemini öneriyoruz.

6. GitHub > repository > **Actions > iOS - Build check** ekranını açın.
   İlk push otomatik çalıştırır; **Run workflow** ile elle de başlatabilirsiniz.
7. Başarılı sonuç simülatör hedefinin derlendiğini gösterir; fiziksel iPhone kurulumu veya UI testi değildir.
   Hata varsa çalıştırmanın sonundaki `simulator-build-log` dosyasını inceleyin.

GitHub hesabında Actions etkin ve macOS çalışma kotası/harcama ayarları uygun olmalıdır.
Ücretsiz kullanım miktarı ve ücretlendirme hesabınızın planına bağlıdır; süre başlatmadan kontrol edin.

## 2. TestFlight için Apple tarafını hazırlayın

- Aktif Apple Developer Program üyeliği.
- App Store Connect > Apps bölümünde bu uygulama için bir kayıt.
- Explicit Bundle ID: `com.cihanemre.SheepCrate3D`.
- Apple Team ID: Apple Developer üyelik bilgilerindeki 10 karakterli değer.
  Bundle ID veya App Store Connect Issuer ID ile karıştırmayın.
- **Apple Distribution** sertifikası ve ona ait özel anahtarı içeren `.p12`.
- Aynı sertifikayı ve aynı Bundle ID'yi kullanan **App Store Connect distribution** `.mobileprovision` profili.
- Yalnızca yükleme için App Store Connect **Team API key**: Key ID, Issuer ID ve `.p8` dosyası.
  Bu akış Individual API key kullanmaz. Uygulama yüklemeye yetkili bir rol seçin; Developer veya uygun üst rol.

App Store Connect kayıt ekranında platform iOS, ad Crate 3D, Bundle ID yukarıdaki değer,
SKU örneğin `sheepcrate3d001` olabilir. İsim kullanılmıyorsa başka bir görünür ad seçin.
Capability eklemeniz gerekmez. Sözleşme ve üyelik adımları Apple hesabınızda tamamlanmış olmalıdır.

### Windows'ta sertifika hazırlama (mevcut P12 yoksa)

Sertifika/özel anahtar dosyalarını repository dışında, yalnızca sizin eriştiğiniz bir klasörde tutun.
Git Bash içindeki `openssl version` çalışıyorsa aşağıdaki araç kullanılabilir:

```bash
bash tools/create-csr.sh
```

Araç özel anahtarı ve CSR'yi seçtiğiniz klasörde oluşturur. CSR sorularında ülke, ad ve e-posta gibi
bilgilerinizi girin; Common Name için adınızı kullanabilirsiniz. Challenge password alanını boş bırakabilirsiniz.
Apple Developer > Certificates > + > **Apple Distribution** seçip yalnızca `.certSigningRequest` dosyasını yükleyin.
Oluşturulan `.cer` sertifikasını özel klasörünüze indirin.

Git Bash'te o özel klasöre geçin ve indirilen sertifika dosyasının adını kullanarak:

```bash
openssl x509 -inform DER -in distribution.cer -out distribution.pem
openssl pkcs12 -export -inkey distribution.key -in distribution.pem -out distribution.p12 -name 'Apple Distribution' -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1
```

P12 için güçlü bir export parolası belirleyin; GitHub'daki `P12_PASSWORD` bu paroladır.
Bu yol Mac'teki Keychain Access ile CSR/P12 oluşturmanın Windows/OpenSSL alternatifidir.
OpenSSL aracınız yoksa güvenilir dağıtımını kurmanız gerekir; bu pakette bir OpenSSL kurulumu yoktur.
Özel anahtarı hiçbir yere kaynak dosyası olarak yüklemeyin.

Apple Developer > Profiles > + > Distribution > **App Store Connect** bölümünden aynı App ID ve
aynı Apple Distribution sertifikasını seçerek profil üretip indirin. Development/Ad Hoc/Enterprise profili seçmeyin.
CI, Team ID, Bundle ID, profil türü, profil süresi ve P12 ile sertifika eşleşmesini kontrol eder.

## 3. GitHub ayarları: bir Variable ve yedi Secret

Repository > **Settings > Secrets and variables > Actions** ekranını açın.

**Variables > New repository variable:**

| Name | Value |
|---|---|
| `APPLE_TEAM_ID` | Apple Developer Team ID, 10 karakter |

**Secrets > New repository secret:**

| Name | Value |
|---|---|
| `BUILD_CERTIFICATE_BASE64` | Apple Distribution `.p12` dosyasının Base64 içeriği |
| `P12_PASSWORD` | P12 oluştururken verdiğiniz export parolası |
| `BUILD_PROVISION_PROFILE_BASE64` | `.mobileprovision` dosyasının Base64 içeriği |
| `KEYCHAIN_PASSWORD` | CI'ın geçici keychain'i için oluşturduğunuz yeni, güçlü bir parola; Apple parolanız değil |
| `ASC_KEY_ID` | App Store Connect Team API key'in Key ID değeri |
| `ASC_ISSUER_ID` | Aynı Team API key'in Issuer ID değeri |
| `ASC_PRIVATE_KEY_BASE64` | `AuthKey_....p8` dosyasının Base64 içeriği |

Son üç Secret yalnızca TestFlight yüklemesini seçtiğinizde gerekir. İmzalı IPA oluşturmak için ilk dört yeterlidir.
`.p8` anahtarını App Store Connect > Users and Access > Integrations > App Store Connect API bölümünden
yetkili hesabınızla oluşturun. Apple özel anahtarı yalnızca bir kez indirmenize izin verir; güvenli saklayın.

Base64'ü PowerShell ile konsola yazdırmadan panoya almak için:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\file-to-base64.ps1 -Path 'C:\OZEL_KLASOR\distribution.p12'
```

Aynı aracı profil ve P8 için de kullanın. Panodaki değeri doğru GitHub Secret alanına yapıştırın.
Base64 şifreleme değildir. Sertifika, özel anahtar ve parolaları sohbet, issue, commit veya loglara eklemeyin.

## 4. İmzalı IPA oluşturun, ardından TestFlight'a gönderin

1. **Actions > iOS - Signed IPA and TestFlight > Run workflow** ekranına gidin.
2. Repository'nin varsayılan branch'ini (`main`) seçin.
3. İlk denemede `upload_to_testflight` işaretli olmasın. **Run workflow** deyin.
4. Başarılı olduğunda Artifacts bölümündeki `SheepCrate-signed-...` paketini indirin.
   İçinde imzalı IPA ve debug sembolleri bulunur. App Store IPA, iPhone'a dosya tıklamasıyla kurulmaz.
5. Yüklemeye hazır olduğunuzda aynı akışı tekrar çalıştırın ve `upload_to_testflight` seçeneğini işaretleyin.
6. GitHub, App Store Connect'e yükler. Apple işlemesi bitince App Store Connect > uygulama > TestFlight ekranında görünür.
   Apple ek uyumluluk/şifreleme bilgisi isterse uygulamanızın gerçek kullanımına göre yanıtlayın.
7. Test kullanıcınızı tanımlayın ve iPhone'da TestFlight ile kurun. Harici testler için Apple beta incelemesi gerekebilir.

Bu akış App Store'da otomatik yayın veya App Review başvurusu yapmaz. Yükleme kabulü ve TestFlight işleme
durumu Apple tarafından belirlenir. Anahtarlar iş sonunda runner'dan kaldırılır; IPA ve loglar GitHub'da 7 gün tutulur.
İmzalı akış yalnızca elle ve varsayılan branch'te çalışır; pull request iş akışı Apple Secret'larını kullanmaz.
Her release çalıştırmasında `run_number.run_attempt.0` biçiminde farklı build numarası kullanılır.
Mevcut App Store kaydında daha yüksek bir build numarası varsa `ci/archive.sh` içindeki stratejiyi buna göre güncelleyin.

## Sık karşılaşılan hatalar

| Mesaj / Durum | Kontrol |
|---|---|
| Actions menüsünde akışlar yok | `.github/workflows` kökte mi, dosyalar branch'e işlendi mi? |
| Secret / setting missing | Adlar yukarıdaki büyük/küçük harflerle aynı mı? |
| Profile mismatch | Bundle ID, Team ID ve Apple Distribution sertifikası aynı mı? |
| No valid signing identity | P12 özel anahtarı içeriyor mu, geçerli mi, profil aynı sertifikayı mı kullanıyor? Apple intermediate chain gerekirse P12'ye ekleyin. |
| Profile expired / incorrect type | Yeni App Store Connect distribution profili oluşturun. |
| No stable Xcode 26+ | İki YAML dosyasındaki macOS runner etiketini güncel desteklenen görüntüye alın. |
| 401 / invalid API key | Team key, Key ID, Issuer ID ve P8 eşleşmesini kontrol edin. |
| Duplicate build number | Tekrar çalıştırma kullanın veya mevcut daha yüksek build'e göre numaralandırmayı güncelleyin. |
| IPA indirildi ama iPhone'da açılmıyor | App Store IPA için TestFlight dağıtımını tamamlayın. |

## Doğrulama sınırı

Bu pakette workflow YAML, shell sözdizimi, Python profil doğrulaması ve proje dosya yapısı yerel olarak
kontrol edildi. Gerçek macOS/Xcode derlemesi, Apple imzası ve Apple'a yükleme çalıştırılmadı.
İlk GitHub derlemesi olası Swift/SDK hatalarını gösterecektir; hata logunu paylaşabilirsiniz,
ancak Secret değerlerini ve özel anahtar dosyalarını paylaşmayın.

## Resmî kaynaklar

- https://docs.github.com/actions/deployment/deploying-xcode-applications/installing-an-apple-certificate-on-macos-runners-for-xcode-development
- https://github.com/actions/runner-images
- https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/
- https://developer.apple.com/help/account/provisioning-profiles/create-an-app-store-provisioning-profile
- https://developer.apple.com/documentation/AppStoreConnectAPI/creating-api-keys-for-app-store-connect-api
