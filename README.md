# Opel Insignia Vites Asistanı & OBD2 Telemetri Kokpiti

Bu proje, **Opel Insignia** (1.4T, 1.6T ve 2.0 CDTI) araçlar için geliştirilmiş, ELM327 Bluetooth adaptörü üzerinden CAN-bus hattını dinleyerek çalışan akıllı bir dijital vites asistanı ve telemetri uygulamasıdır.

---

## 🚀 Temel Özellikler

1. **Matematiksel Vites Tespiti:**
   - Manuel şanzımanlı Opel Insignia'larda vites konum sensörü bulunmadığı için anlık motor devri ($RPM$) ve araç hızı ($km/h$) oranını ($Oran = RPM / Hız$) hesaplayarak aktif vitesi (1, 2, 3, 4, 5, 6 veya Boş/Debriyaj için **N**) %99 doğrulukla tespit eder.

2. **Dinamik Sürüş Modları ve Vites Tavsiyesi:**
   - **Eko Modu:** Şehir içi yakıt tasarrufu için düşük devirlerde (~2000-2200 RPM) vites büyütme önerisi.
   - **Konfor Modu:** Dengeli günlük sürüş (2500-3200 RPM aralığı).
   - **Sport / Peak Power Modu:** Tam gazda Insignia 1.6T (A16LET / B16SHT) tork ve güç eğrisinin zirvesi olan 5800–6200 RPM aralığında kırmızı görsel ve sesli **Shift Light (Vites Değiştir)** ikazı.
   - **Alt Devir Koruması:** Motor devri 1350 RPM altına düştüğünde vuruntu ve boğulmayı önleyen vites küçültme uyarısı.

3. **Canlı Telemetri Paneli:**
   - Analog-dijital spor takometre kadranı.
   - Motor Soğutma Suyu Sıcaklığı (°C).
   - Gaz Kelebeği Açıklığı (TPS %).
   - Motor Yükü (%) ve Emme Manifoldu Basıncı (Boost / MAP).

4. **Dahili Sürüş Simülatörü (Demo Modu):**
   - Araca veya ELM327 adaptörüne bağlı olmadan evde tüm vites geçişlerini, devir yükselişini ve Shift Light ikazını test etmeyi sağlayan canlı simülasyon modu.

---

## ⚙️ Şanzıman ve Dişli Oranları Referansı

| Vites | M32 Manuel (1.4T / 1.6T Benzinli) | F40 Manuel (2.0 CDTI Dizel) |
| :--- | :--- | :--- |
| **1. Vites** | 3.818 | 3.917 |
| **2. Vites** | 2.158 | 2.040 |
| **3. Vites** | 1.475 | 1.321 |
| **4. Vites** | 1.067 | 0.954 |
| **5. Vites** | 0.875 | 0.755 |
| **6. Vites** | 0.744 | 0.623 |
| **Son Dişli (Final Drive)** | 4.176 | 3.895 |
| **Standart Lastik Ebadı** | 245/45 R18 | 225/55 R17 |

---

## 🛠️ GitHub Actions ile Otomatik APK Derleme

GitHub deponuzda yaşanan derleme hatalarını gidermek için `.github/workflows/build_apk.yml` dosyası Java 17, Gradle 8.x ve modern Flutter 3.24+ standartlarına tam uyumlu olarak yapılandırılmıştır.

Depoya commit atıldığında GitHub Actions otomatik olarak çalışır ve Release APK dosyasını **Artifacts** bölümünde indirmeye hazır hale getirir.

### Manuel Derleme:
```bash
flutter pub get
flutter build apk --release --no-tree-shake-icons
```
Çıktı konumu: `build/app/outputs/flutter-apk/app-release.apk`
