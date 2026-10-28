# ORYZA SMART

ORYZA SMART adalah aplikasi Flutter untuk pemantauan pembibitan padi berbasis IoT dan analisis penyakit/hama melalui Oryza Vision. Aplikasi tetap berguna saat koneksi terputus: pengguna yang sudah masuk dapat melihat antarmuka dan data terakhir yang berhasil disinkronkan, sedangkan penyegaran dilanjutkan otomatis saat layanan kembali dapat dijangkau.

## Fitur Utama

- Autentikasi pengguna melalui Laravel Sanctum.
- Mode tamu tanpa login dengan akses terbatas hanya ke Oryza Vision.
- Inferensi penyakit dan hama secara lokal menggunakan model TensorFlow Lite.
- Dasbor kondisi pembibitan, sensor, perangkat, kamera, deteksi, rekomendasi, dan notifikasi.
- Riwayat sensor untuk periode hari ini, 7 hari, dan 30 hari.
- Kontrol kipas dalam mode manual atau otomatis.
- Penyimpanan lokal data hasil sinkronisasi terakhir untuk penggunaan offline.
- Banner status `Anda online` dan `Anda offline` tanpa menampilkan kode error jaringan.
- Sinkronisasi otomatis data dasbor dan riwayat Vision saat koneksi kembali tersedia.

## Mode Akses

### Pengguna terautentikasi

Pengguna yang berhasil login memperoleh akses ke seluruh menu: Dasbor, Device, Vision, Riwayat, dan Settings. Token dan identitas sesi disimpan secara lokal sehingga sesi dapat dipulihkan ketika aplikasi dibuka tanpa koneksi internet.

Saat offline, aplikasi mempertahankan UI dan menampilkan cache data terakhir yang berhasil diterima dari backend. Permintaan berikutnya dijalankan kembali melalui mekanisme polling ketika koneksi pulih.

### Tamu

Pengguna dapat memilih **Lanjut sebagai Tamu** tanpa memasukkan akun. Mode ini hanya membuka menu Vision. Hasil pemindaian disimpan di perangkat dan tidak dikirim ke backend sebelum pengguna masuk.

## Arsitektur

```text
Flutter App ── REST API ── Laravel ── MySQL / MQTT
     │                           └── ESP32 dan layanan IoT
     ├── SharedPreferences (cache data dan riwayat)
     ├── Secure Storage (token autentikasi)
     └── TensorFlow Lite (inferensi Vision di perangkat)
```

Komponen utama:

- Flutter dan Dart
- Riverpod untuk pengelolaan state
- Dio untuk komunikasi REST API dan deteksi status koneksi
- Shared Preferences untuk cache data terakhir
- Flutter Secure Storage untuk token autentikasi
- TensorFlow Lite untuk inferensi lokal
- FL Chart untuk visualisasi riwayat sensor
- Image Picker untuk kamera dan galeri

## Struktur Proyek

```text
lib/
  core/
    api/                    # klien API, provider, dan status koneksi
    config/                 # konfigurasi aplikasi
    theme/                  # tema visual
  features/
    auth/                   # halaman login dan mode tamu
    dashboard/              # dasbor dan polling data
    devices/                # status perangkat dan kontrol kipas
    history/                # riwayat sensor dan Vision
    oryza_vision/           # model lokal, scan, hasil, dan sinkronisasi
    settings/               # pengaturan akun
    shell/                  # navigasi utama dan banner koneksi
  shared/
    models/                 # model domain dan serialisasi cache
    repositories/           # akses API, sesi, dan cache offline
    widgets/                # komponen UI bersama
assets/models/oryza-vision/ # model dan metadata TensorFlow Lite
docs/                       # kontrak API dan dokumentasi teknis
```

## Persyaratan

- Flutter SDK yang mendukung Dart `^3.11.0`
- Android Studio atau Xcode untuk build perangkat bergerak
- Backend Laravel yang mengikuti kontrak pada `docs/API.MD`
- Model TensorFlow Lite pada `assets/models/oryza-vision/`

## Konfigurasi Lingkungan

Buat berkas `.env` pada root proyek:

```env
API_BASE_URL=http://10.0.2.2:8000/api
```

Gunakan alamat yang sesuai dengan target:

- Emulator Android: `http://10.0.2.2:8000/api`
- Desktop atau web lokal: `http://127.0.0.1:8000/api`
- Perangkat fisik: alamat IP LAN komputer backend, misalnya `http://192.168.1.10:8000/api`

Pastikan perangkat dan komputer backend berada pada jaringan yang sama serta port backend diizinkan oleh firewall.

## Menjalankan Aplikasi

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Login pengembangan bawaan backend simulator:

```text
Email    : operator@padibackend.test
Password : password
```

## Perilaku Offline dan Sinkronisasi

1. Respons dasbor, riwayat sensor, dan deteksi yang berhasil disimpan ke cache lokal.
2. Ketika API tidak dapat dijangkau, repository mengembalikan cache tersebut sehingga layar tetap dapat digunakan.
3. Banner koneksi memberi informasi bahwa aplikasi sedang offline dan menampilkan data sinkron terakhir.
4. Polling tetap berjalan. Respons API berikutnya yang berhasil mengubah status menjadi online dan mengganti cache dengan data terbaru.
5. Hasil scan Vision selalu disimpan secara lokal terlebih dahulu. Untuk pengguna login, hasil yang masih pending dikirim saat backend kembali tersedia.

Jika perangkat belum pernah melakukan sinkronisasi, aplikasi menampilkan pesan offline yang ramah tanpa kode atau detail exception teknis.

## Endpoint Backend Utama

```text
POST /api/login
POST /api/logout
GET  /api/dashboard
GET  /api/sensors/latest
GET  /api/sensors/history?range=today|7days|30days
GET  /api/detections
GET  /api/detections/latest
GET  /api/alerts
GET  /api/recommendations
GET  /api/actuators/fan/status
POST /api/actuators/fan/control
GET  /api/vision/scans
POST /api/vision/scans
```

Kontrak lengkap tersedia pada `docs/API.MD`.

## Backend Simulator

```bash
php artisan migrate --seed
php artisan nursery:simulate --count=10 --scenario=mixed
php artisan serve
```

Simulasi MQTT opsional:

```bash
php artisan mqtt:simulate-device --device=ESP32-01 --scenario=mixed --count=10 --interval=1
php artisan mqtt:listen
```

## Pemeriksaan Kualitas

Sebelum perubahan dikirim, jalankan:

```bash
flutter analyze
flutter test
```

Kondisi verifikasi terakhir:

- `flutter analyze`: tidak ditemukan masalah.
- `flutter test`: seluruh pengujian lulus; pengujian inferensi native dilewati pada Windows karena DLL TensorFlow Lite tidak tersedia dan tetap dapat dijalankan pada Android.

## Dokumentasi

- Kontrak API: `docs/API.MD`
- Kebutuhan produk: `docs/PRD.MD`
- Integrasi Vision Flutter: `docs/flutter-vision.md`
