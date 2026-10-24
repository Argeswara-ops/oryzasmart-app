# Prompt Implementasi API Riwayat Scan Manual Oryza Vision (Laravel)

Anda bertindak sebagai Senior Laravel Developer. Implementasikan API riwayat **scan manual Oryza Vision** pada backend Laravel Oryza Smart yang sudah ada. Jangan mencampurkan data ini dengan tabel/endpoint `detections`, karena `detections` adalah hasil kamera atau Python Vision Service.

## Tujuan

Flutter menjalankan klasifikasi penyakit/hama secara offline. Setiap hasil langsung disimpan di perangkat. Saat backend dapat dijangkau, Flutter mengunggah antrean hasil ke Laravel dan mengambil riwayat milik user yang sedang login.

## Endpoint

Semua endpoint memakai `auth:sanctum`:

```text
GET  /api/vision/scans
POST /api/vision/scans
GET  /api/vision/scans/{visionScan}
```

### POST `/api/vision/scans`

Gunakan `multipart/form-data` dengan field:

```text
client_id: string, required, max 100
scan_type: required, enum disease|pest
class_name: required, string, max 100
display_name: required, string, max 150
confidence: required, numeric, between 0 and 1
scanned_at: required, ISO-8601 date
image: required, image jpg/jpeg/png/webp, max 10 MB
```

`client_id` dibuat Flutter dan wajib idempotent per user. Buat unique index gabungan `user_id, client_id`. Jika request dengan `client_id` yang sama dikirim ulang, jangan membuat row atau file gambar baru; kembalikan record yang sudah ada dengan status 200. Record baru mengembalikan 201.

Response wajib memakai envelope proyek:

```json
{
  "success": true,
  "message": "Riwayat scan tersimpan.",
  "data": {
    "id": 21,
    "local_id": "1792840000000-pest",
    "scan_type": "pest",
    "class_name": "Brown_Planthopper",
    "display_name": "Wereng Batang Cokelat",
    "confidence": 0.8732,
    "scanned_at": "2026-10-24T08:20:00.000000Z",
    "image_url": "http://host/storage/vision-scans/1/scan.jpg",
    "created_at": "2026-10-24T08:20:04.000000Z"
  }
}
```

### GET `/api/vision/scans`

- Hanya kembalikan record milik user login.
- Urutkan `scanned_at` terbaru.
- Dukung pagination dan filter opsional `scan_type=disease|pest`.
- Agar kompatibel dengan Flutter saat ini, `data` boleh berupa list langsung atau object dengan key `items`/`data`.
- Setiap item harus memiliki field yang sama dengan response POST dan `image_url` absolut.

### GET `/api/vision/scans/{visionScan}`

Gunakan policy/ownership check. User tidak boleh membaca scan user lain.

## Database

Buat migration `vision_scans` minimal:

```text
id
user_id (foreign, cascade delete)
client_id string(100)
scan_type enum/string
class_name string(100)
display_name string(150)
confidence decimal(8,7)
image_path string
scanned_at timestamp
timestamps
unique(user_id, client_id)
index(user_id, scanned_at)
index(scan_type)
```

Buat model `VisionScan`, relasi `belongsTo(User::class)`, casts untuk `confidence` dan `scanned_at`, Form Request khusus validasi, API Resource, controller, policy, factory, dan feature test.

Simpan gambar pada disk `public` di folder `vision-scans/{user_id}` dengan nama aman. Pastikan `php artisan storage:link` didokumentasikan. Hapus file jika transaksi database gagal. Jangan menjalankan model ML atau mengubah hasil prediksi di backend.

## Test Wajib

- User terautentikasi dapat upload dan melihat scan miliknya.
- Request tanpa token mendapat 401.
- Validasi tipe, confidence, tanggal, dan file gambar menghasilkan 422.
- Retry dengan `client_id` sama bersifat idempotent dan jumlah row/file tetap satu.
- User A tidak dapat melihat detail atau list milik user B.
- Filter jenis scan dan pagination bekerja.
- `image_url` dapat diakses setelah `storage:link`.

Setelah implementasi, jalankan formatter dan test Laravel, lalu laporkan migration, route, request validation, resource, controller, policy, dan hasil test.
