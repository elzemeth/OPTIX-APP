# User Stories - Giriş ve Kayıt İşlemleri

## 1. Uygulama Başlatma
**As a** kullanıcı  
**I want** uygulamayı açtığımda splash ekranı görmek  
**So that** uygulamanın yüklendiğini anlayayım

- Splash ekranı 2 saniye gösterilir
- Giriş durumu kontrol edilir
- Giriş yapılmışsa → Ana sayfa
- Giriş yapılmamışsa → Login ekranı

---

## 2. Kullanıcı Girişi
**As a** kayıtlı kullanıcı  
**I want** kullanıcı adı ve şifremle giriş yapmak  
**So that** hesabıma erişebileyim

- Kullanıcı adı ve şifre girilir
- Şifre SHA-256 ile hashlenir
- Supabase'de kullanıcı kontrolü yapılır
- Başarılıysa → Ana sayfa
- Başarısızsa → Hata mesajı gösterilir

---

## 3. Kayıt Olma (Sign Up Butonu)
**As a** yeni kullanıcı  
**I want** Login ekranındaki "Sign Up" butonuna tıklamak  
**So that** kayıt işlemini başlatabileyim

- Login ekranında "Sign Up" butonuna tıklanır
- BLE cihaz bağlantı ekranına yönlendirilir (`signupPreferred: true`)
- Önce cihaz bağlantısı yapılır, sonra kayıt formu gösterilir

---

## 4. BLE Cihaz Tarama
**As a** kullanıcı  
**I want** OPTIX gözlüklerimi bulmak için tarama yapmak  
**So that** cihazıma bağlanabileyim

- "Search Devices" butonuna tıklanır
- BLE tarama başlatılır
- OPTIX cihazları listelenir
- Cihaz seçilir ve bağlantı kurulur

---

## 5. Cihaz Bağlantısı ve Serial Number
**As a** kullanıcı  
**I want** OPTIX cihazıma bağlanmak  
**So that** cihazımı hesabıma bağlayabileyim

- Bağlantı denemesi tek seferde yapılır (paralel deneme engeli)
- Bağlanmadan önce tarama durdurulur (iOS pairing popupları azalır)
- Serial number cihazdan alınır ve yerelde saklanır
- Cihaz ID kontrolü yapılır (bir cihaz sadece bir hesaba bağlanabilir)

---

## 6. WiFi Bilgileri Gönderme
**As a** kullanıcı  
**I want** WiFi bilgilerimi gözlüğe göndermek  
**So that** gözlük internete bağlanabilsin

- BLE bağlantısı sonrası WiFi bilgileri sorulur
- SSID ve şifre girilir
- Önce SFTP ile `/home/optix/wifi_credentials_temp.json` yüklenir
- Ardından sudo ile `/tmp/wifi_credentials.json` hedefine taşınır (arka planda, kullanıcı görmez)
- SFTP başarısızsa doğrudan sudo ile yazılır (base64 + heredoc fallback)
- Pi'deki watcher dosyayı görüp WiFi'yi yapılandırır

---

## 7. Otomatik Yönlendirme (Cihaz Bağlantısı Sonrası)
**As a** kullanıcı  
**I want** cihaz bağlantısı sonrası doğru ekrana yönlendirilmek  
**So that** işleme devam edebileyim

**Senaryo A: Sign Up Intent (signupPreferred: true)**
- Cihaz bağlandıktan sonra → Sign Up ekranına yönlendirilir

**Senaryo B: Otomatik Yönlendirme (signupPreferred: false)**
- Serial number ile kullanıcı kontrolü yapılır
- Kullanıcı varsa → Login ekranı
- Kullanıcı yoksa → Sign Up ekranı

---

## 8. Kullanıcı Kaydı
**As a** yeni kullanıcı  
**I want** kullanıcı bilgilerimi girerek hesap oluşturmak  
**So that** uygulamayı kullanmaya başlayabileyim

- Kullanıcı adı, email, şifre ve şifre tekrarı girilir
- Form validasyonu yapılır:
  - Tüm alanlar dolu olmalı
  - Şifreler eşleşmeli
  - Şifre en az 4 karakter olmalı
- Şifre SHA-256 ile hashlenir
- Supabase'de kullanıcı oluşturulur (RLS dev modda kapalı)
- Serial number (daha önce kaydedilmiş) kullanıcıya bağlanır
- Başarılıysa → Ana sayfa
- Başarısızsa → Hata mesajı gösterilir

---

## 9. Cihaz-Hesap Bağlantı Kısıtı
**As a** sistem  
**I want** bir cihazın sadece bir hesaba bağlanmasını sağlamak  
**So that** cihaz çakışmaları önlenir

- Kayıt sırasında cihaz ID kontrolü yapılır
- Cihaz başka bir hesaba bağlıysa → Hata gösterilir
- Cihaz serbestse → Kullanıcıya bağlanır

---

## 10. Giriş Durumu Kontrolü
**As a** kullanıcı  
**I want** uygulamayı her açtığımda giriş durumumun kontrol edilmesini  
**So that** otomatik olarak doğru ekrana yönlendirileyim

- SharedPreferences'da login durumu kontrol edilir
- Giriş yapılmışsa → Ana sayfa
- Giriş yapılmamışsa → Login ekranı

---

## Teknik Detaylar

### BLE İşlemleri
- Cihaz adı "OPTIX" ile başlamalı
- Serial number BLE servisinden alınır
- WiFi bilgileri BLE yerine SSH ile gönderilir (iPhone kısıtı)

### Güvenlik
- Şifreler SHA-256 ile hashlenir
- Serial number hash olarak saklanır
- Cihaz ID kontrolü ile çoklu bağlantı önlenir

### Veri Akışı
1. Splash → Login kontrolü
2. Login → Giriş veya Sign Up butonu
3. Sign Up butonu → BLE cihaz bağlantı ekranı
4. BLE bağlantı → Serial number alınır, WiFi bilgileri gönderilir
5. Sign Up ekranı → Kullanıcı bilgileri ile kayıt
6. Başarılı kayıt → Ana sayfa

