# AI Agent Prompt — Implementasi Oryza Vision ke Flutter

Bertindaklah sebagai **Senior Flutter Developer dan Mobile Machine Learning Engineer**.

Implementasikan fitur **Oryza Vision**, yaitu sistem identifikasi penyakit dan hama tanaman padi berbasis image classification, ke dalam project Flutter Oryza Smart yang sudah ada.

Kerjakan implementasi secara langsung, bukan hanya membuat dokumentasi atau rencana.

## 1. Analisis Project

Sebelum coding:

- Analisis struktur project Flutter, routing, state management, theme, dan arsitektur yang digunakan.
- Periksa `pubspec.yaml` dan dependency yang sudah tersedia.
- Baca seluruh file di `docs/oryza-vision/`.
- Gunakan pola arsitektur dan komponen UI yang sudah diterapkan pada project.
- Jangan membuat ulang project Flutter atau mengubah modul IoT yang sudah berjalan.

## 2. Model Machine Learning

Seluruh model tersedia di:

```text
docs/oryza-vision/
├── disease_model.tflite
├── disease_labels.json
├── disease_preprocessing.json
├── pest_model.tflite
├── pest_labels.json
├── pest_preprocessing.json
└── conversion_report.json
```

Model yang digunakan:

| Fitur | Model |
|---|---|
| Klasifikasi penyakit | MobileNetV3-Large |
| Klasifikasi hama | EfficientNet-B0 |

Kedua model dilatih secara terpisah dan harus dijalankan menggunakan interpreter yang independen.

Validasi `conversion_report.json` terlebih dahulu. Jika file model atau metadata tidak tersedia atau status konversi belum valid, hentikan integrasi model terkait dan laporkan masalahnya. Jangan membuat model dummy.

Salin file TFLite dan metadata yang diperlukan ke `assets/models/oryza-vision/`, kemudian daftarkan pada `pubspec.yaml`.

## 3. Teknologi

Gunakan:

- Flutter / Dart.
- `tflite_flutter` untuk on-device inference.
- `image_picker` untuk kamera dan galeri.
- Package `image` untuk preprocessing.
- State management yang sudah digunakan project.
- Penyimpanan lokal yang sudah digunakan project, jika diperlukan.

Utamakan inferensi offline. Jangan menggunakan Python API atau backend untuk menjalankan model.

## 4. Fitur Oryza Vision

Buat dua fitur utama:

**Scan Penyakit Padi**
- Menggunakan `disease_model.tflite`.
- Lima kelas berdasarkan `disease_labels.json`.
- Foto dari kamera atau galeri.
- Menampilkan prediksi, confidence, dan informasi penyakit.

**Scan Hama Padi**
- Menggunakan `pest_model.tflite`.
- Tiga kelas berdasarkan `pest_labels.json`.
- Foto dari kamera atau galeri.
- Menampilkan prediksi, confidence, dan informasi hama.

Jangan menggabungkan kedua model atau mencampur label penyakit dan hama.

## 5. Image Preprocessing

Baca masing-masing file preprocessing JSON dan implementasikan preprocessing yang sama persis dengan training dan export:

1. Decode gambar dan perbaiki orientasi EXIF.
2. Konversi ke RGB.
3. Resize sisi terpendek sesuai metadata.
4. Center crop sesuai ukuran input.
5. Normalisasi menggunakan mean dan standard deviation dari metadata.
6. Bentuk tensor Float32 dengan layout NHWC sesuai model.
7. Jalankan inference dan konversi logits menjadi probabilitas menggunakan softmax.

Periksa `inputShape`, `outputShape`, dan `tensorType` dari interpreter. Jangan mengasumsikan format tensor tanpa validasi.

Pastikan urutan label sesuai file JSON.

## 6. Arsitektur Implementasi

Ikuti arsitektur project. Jika belum ada pola khusus, gunakan struktur feature-based:

```text
lib/
└── features/
    └── oryza_vision/
        ├── data/
        │   ├── models/
        │   ├── repositories/
        │   └── services/
        │       ├── vision_model_service.dart
        │       └── image_preprocessing_service.dart
        ├── domain/
        │   └── entities/
        └── presentation/
            ├── screens/
            │   ├── vision_screen.dart
            │   ├── scan_screen.dart
            │   └── result_screen.dart
            └── widgets/
```

Implementasikan reusable service agar kedua model dapat menggunakan pipeline inference yang sama tetapi dengan konfigurasi terpisah.

## 7. UI/UX

Buat UI profesional, modern, clean, dan responsive yang konsisten dengan desain Oryza Smart.

Alur pengguna:

```text
Dashboard Oryza Smart
        ↓
     Oryza Vision
        ↓
 ┌───────────────┐
 │               │
Scan Penyakit  Scan Hama
 │               │
 └───────┬───────┘
         ↓
   Kamera / Galeri
         ↓
     Processing
         ↓
   Hasil Identifikasi
```

Halaman hasil harus menampilkan:

- Preview gambar.
- Nama penyakit atau hama.
- Confidence score.
- Deskripsi singkat.
- Rekomendasi pemeriksaan atau tindakan awal.
- Tombol scan ulang.

Gunakan bahasa Indonesia untuk konten aplikasi.

Jika confidence rendah, tampilkan status **"Hasil belum meyakinkan"**. Ambang confidence harus configurable dan bukan dianggap sebagai jaminan pendeteksian gambar di luar kelas.

Gunakan sumber pengetahuan yang dapat dipertanggungjawabkan untuk deskripsi dan rekomendasi penanganan. Jangan mengarang diagnosis atau dosis pestisida.

## 8. Optimasi Performa

Prioritaskan aplikasi Android yang ringan dan stabil.

- Gunakan lazy loading interpreter.
- Jangan memuat dua model secara bersamaan jika tidak diperlukan.
- Dispose interpreter saat sudah tidak digunakan.
- Jalankan preprocessing dan inference di luar UI thread menggunakan mekanisme yang kompatibel dengan `tflite_flutter`.
- Batasi resolusi gambar yang diproses.
- Hindari penyimpanan gambar berukuran besar dalam state.
- Tangani error kamera, model, dan input tidak valid.
- Pastikan proses inference tidak menyebabkan UI freeze.
- Jangan melakukan kuantisasi ulang pada model dari dalam Flutter.

## 9. Integrasi Backend

Oryza Vision merupakan bagian dari Oryza Smart yang memiliki backend Laravel REST API.

Integrasikan riwayat scan dengan backend **hanya jika endpoint dan mekanisme autentikasinya sudah tersedia**.

Jika belum tersedia, jangan membuat endpoint palsu. Siapkan repository interface agar integrasi backend dapat dilakukan kemudian.

Seluruh proses klasifikasi tetap berjalan offline.

## 10. Testing dan Validasi

Lakukan:

- Unit test preprocessing.
- Pengujian pemetaan kelas penyakit dan hama.
- Pengujian loading kedua model.
- Pengujian hasil inference.
- Pengujian penanganan error.
- Pengujian alur kamera dan galeri.
- Validasi konsistensi hasil menggunakan gambar referensi apabila tersedia.

Jalankan:

```bash
flutter pub get
flutter analyze
flutter test
```

Perbaiki error yang ditemukan.

## 11. Deliverables

Implementasikan seluruh fitur secara langsung ke codebase.

Setelah selesai, laporkan:

1. Daftar file yang dibuat dan diubah.
2. Dependency yang ditambahkan.
3. Integrasi routing/navigation.
4. Mekanisme inference kedua model.
5. Hasil `flutter analyze` dan `flutter test`.
6. Kendala yang belum terselesaikan.
7. Langkah pengujian pada HP Android.

**Acceptance Criteria:**

- Pengguna dapat membuka Oryza Vision dari aplikasi.
- Scan penyakit menggunakan model penyakit.
- Scan hama menggunakan model hama.
- Kedua model dapat melakukan inference secara offline.
- Preprocessing identik dengan konfigurasi model.
- Hasil klasifikasi ditampilkan dengan benar.
- Aplikasi tidak mengalami UI freeze akibat inference.
- Fitur monitoring IoT yang sudah ada tetap berjalan.

Mulai dengan inspeksi project dan `docs/oryza-vision/`, kemudian implementasikan fitur secara bertahap sampai selesai. Jangan berhenti pada pembuatan PRD atau dokumentasi saja.