# Office 365 Online Kurulum Aracı (PowerShell)

Bu PowerShell scripti, Office 365, Project ve Visio kurulumlarını yönetmek, dil seçeneklerini ayarlamak ve Office temizleme araçlarını çalıştırmak için geliştirilmiştir.

## Özellikler

### 1. Dinamik Dil Desteği
- Uygulama, `Lang` klasörü altındaki `.ini` dosyalarını otomatik olarak algılar ve yükler.
- İşletim sistemi diline göre otomatik varsayılan dil seçimi yapar.
- Arayüzdeki tüm metinler (Butonlar, Başlıklar, Uyarılar) seçilen dile göre anlık olarak güncellenir.
- **Yeni Özellik:** "Okunabilir Ortam" uyarısı da dil değiştirildiğinde anında güncellenir.

### 2. Gelişmiş İkon Yönetimi
- Script çalıştığı dizinde `ico.ico` dosyası varsa, form ikonu olarak bunu kullanır.
- **Görev Çubuğu Entegrasyonu:** PowerShell'in varsayılan ikonu yerine uygulamanın kendi ikonunun görünmesi için `Win32 API` (LoadImage, SendMessage) kullanılarak ikon zorla güncellenir.
- `Win32Icon` sınıfı ile çakışmalar önlenmiştir.

### 3. Ortam Kontrolleri
- **Okunabilir Ortam (Read-Only):** Script salt okunur bir ortamda (örneğin ISO dosyası içinde) çalıştırıldığında bunu algılar.
  - "Çevrimiçi Kurulum" seçeneği devre dışı kalır.
  - Kullanıcıya bilgilendirici bir uyarı mesajı gösterilir.

### 4. Kurulum Seçenekleri
- **Ürünler:** Office 365, Visio, Project.
- **Diller:** Çoklu dil seçimi desteklenir.
- **Kanallar:** Güncel, Aylık, Yarı Yıllık vb. güncelleme kanalları seçilebilir.
- **Mimari:** x86 ve x64 desteği.

### 5. Araçlar ve Ekstralar
- **Lisans Temizleme:** Mevcut Office lisanslarını temizleme aracı.
- **Sıfırlama:** Office ayarlarını ve dosyalarını sıfırlama araçları.
- **Erişilebilirlik:** Yönetici yetkisi kontrolü ve bilgilendirmesi.

## Son Güncellemeler (v2.0)

- **Sabit Metinler Kaldırıldı:** Kod içindeki tüm İngilizce/Türkçe sabit metinler INI dosyalarına taşındı.
- **Hata Düzeltmeleri:**
  - Dil değiştirildiğinde `LinkLabel` (Hakkında, Üniversite Adı) güncellenmeme sorunu çözüldü.
  - "Okunabilir Ortam" mesajının dil değiştirmeme sorunu çözüldü.
  - `Add-Type` kaynaklı "Type already exists" hataları giderildi.
- **Performans ve Görünüm:**
  - `EnableVisualStyles` ile modern görünüm etkinleştirildi.
  - Form açılışı hızlandırıldı ve ikon yükleme mantığı optimize edildi.

## Kurulum ve Kullanım

1. `o365.ps1` dosyasını bir klasöre indirin.
2. `Lang` klasörünün ve içinde `Türkçe.ini` (veya diğer dillerin) olduğundan emin olun.
3. İsteğe bağlı olarak `ico.ico` dosyasını aynı klasöre koyun.
4. Scripti sağ tıklayıp "PowerShell ile Çalıştır" diyerek başlatın.

**Not:** Script, yönetici hakları gerektiren işlemler için onay isteyecektir.

## Geliştirici Notları

- **Dil Dosyaları:** Yeni bir dil eklemek için `Lang` klasörüne `DilAdı.ini` formatında yeni bir dosya oluşturmanız yeterlidir. Kod değişikliği gerektirmez.
- **Win32 API:** İkon işlemleri için `user32.dll` fonksiyonları P/Invoke yöntemiyle çağrılmaktadır.

---
**Geliştirici:** Abdullah ERTÜRK
**İletişim:** +90 478 211 75 75 (1264)
**Kurum:** Ardahan Üniversitesi Bilgi İşlem Daire Başkanlığı
