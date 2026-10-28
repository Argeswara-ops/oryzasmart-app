# API Oryza untuk Integrasi Flutter

Dokumen ini menjelaskan kontrak API Laravel yang aktif untuk aplikasi Flutter. Backend berfokus pada perangkat ESP32, pembacaan sensor, ketinggian air, dan kontrol kipas. API perangkat kamera dan detection sudah tidak digunakan.

## Base URL

Development lokal:

```text
http://127.0.0.1:8000/api
```

Android emulator:

```text
http://10.0.2.2:8000/api
```

## Autentikasi

Hanya `POST /login` yang dapat diakses tanpa token. Endpoint lain menggunakan bearer token Sanctum:

```text
Authorization: Bearer {token}
Accept: application/json
```

Gunakan `Content-Type: application/json` untuk request JSON dan `multipart/form-data` untuk upload gambar.

User development dari seeder:

```text
email: operator@padibackend.test
password: password
```

## Format Response

Format umum sukses:

```json
{
  "success": true,
  "message": "Message",
  "data": {}
}
```

Format umum gagal:

```json
{
  "success": false,
  "message": "Message",
  "errors": {}
}
```

## Auth

### POST `/login`

```json
{
  "email": "operator@padibackend.test",
  "password": "password"
}
```

Data response berisi `token` dan `user`.

### GET `/user`

Mengambil user berdasarkan token aktif.

### POST `/logout`

Menghapus token yang sedang digunakan.

## Dashboard

### GET `/dashboard`

Response `data`:

```json
{
  "system_status": "WARNING",
  "device_status": "ONLINE",
  "device": {
    "device_code": "ESP32-01",
    "status": "ONLINE",
    "is_online": true,
    "last_seen": "2026-10-28T05:30:00.000000Z"
  },
  "sensors": {
    "temperature": 32.4,
    "humidity": 88,
    "nitrogen": 26,
    "phosphorus": 25,
    "potassium": 35,
    "light": 65,
    "light_percent": 65,
    "uv_index": 3.2,
    "ultrasonic": 18,
    "distance_cm": 18,
    "level_percent": 72,
    "water_level_percent": 72,
    "water_level": {
      "distance_cm": 18,
      "percent": 72
    },
    "fan_state": "ON",
    "fan_mode": "AUTO",
    "recorded_at": "2026-10-28T05:30:00.000000Z"
  },
  "fan": {
    "status": "ON",
    "is_on": true,
    "mode": "AUTO"
  },
  "unread_alerts": 1
}
```

`latest_detection` tidak lagi dikembalikan.

## Perangkat ESP32

### GET `/devices`

Mengambil seluruh perangkat bertipe `esp32`, diurutkan berdasarkan heartbeat terakhir.

Contoh item `data[]`:

```json
{
  "id": 1,
  "device_code": "ESP32-01",
  "name": "ESP32 Utama",
  "type": "esp32",
  "location": "Rumah Kaca Pembibitan",
  "status": "ONLINE",
  "is_online": true,
  "last_seen": "2026-10-28T05:30:00.000000Z",
  "fan": {
    "status": "ON",
    "is_on": true,
    "mode": "AUTO"
  },
  "latest_sensor": {
    "temperature": 28.5,
    "humidity": 74,
    "nitrogen": 45,
    "phosphorus": 25,
    "potassium": 35,
    "light_percent": 65,
    "uv_index": 3.2,
    "distance_cm": 18,
    "water_level_percent": 72,
    "recorded_at": "2026-10-28T05:30:00.000000Z"
  }
}
```

### GET `/devices/{id}`

`id` dapat berupa ID database atau `device_code`, misalnya `/devices/ESP32-01`.

### GET `/devices/{id}/status`

```json
{
  "device_code": "ESP32-01",
  "status": "ONLINE",
  "is_online": true,
  "last_seen": "2026-10-28T05:30:00.000000Z",
  "fan": {
    "status": "ON",
    "is_on": true,
    "mode": "AUTO"
  }
}
```

Status device yang tersedia: `ONLINE`, `OFFLINE`, dan `ERROR`.

## Sensor

### GET `/sensors/latest`

Mengambil pembacaan sensor paling baru. Field ketinggian air tersedia dalam bentuk:

```json
{
  "distance_cm": 18,
  "level_percent": 72,
  "water_level_percent": 72,
  "water_level": {
    "distance_cm": 18,
    "percent": 72
  }
}
```

### GET `/sensors/history?range=today`

Nilai `range` yang valid:

```text
today
7days
30days
```

Response berisi `range`, `summary`, dan `series`.

## Ambang Sensor

### GET `/thresholds`

Mengambil ambang sensor yang aktif.

Sensor type yang didukung:

```text
temperature
humidity
nitrogen
phosphorus
potassium
light_percent
uv_index
water_level
```

`water_level` menggunakan satuan persen ketinggian air, bukan jarak ultrasonik dalam sentimeter.

### PUT `/thresholds/{sensorType}`

Memerlukan user dengan role `operator`.

Contoh:

```http
PUT /api/thresholds/water_level
```

```json
{
  "min_value": 20,
  "max_value": 90
}
```

`max_value` harus lebih besar atau sama dengan `min_value`. Sensor type yang tidak didukung menghasilkan `422 Unprocessable Entity`.

## Kipas

### GET `/actuators/fan/status`

Gunakan query `device_id` jika terdapat lebih dari satu ESP32:

```http
GET /api/actuators/fan/status?device_id=ESP32-01
```

```json
{
  "device_id": "ESP32-01",
  "device_online": true,
  "status": "ON",
  "is_on": true,
  "mode": "AUTO",
  "updated_at": "2026-10-28T05:30:00.000000Z"
}
```

### POST `/actuators/fan/control`

Memerlukan role `operator` dan device harus berstatus `ONLINE`.

```json
{
  "device_id": "ESP32-01",
  "command": "ON",
  "mode": "MANUAL"
}
```

Nilai yang diperbolehkan:

```text
command: ON, OFF, AUTO
mode: AUTO, MANUAL
```

Device yang tidak ditemukan menghasilkan `404`. Device offline menghasilkan `409 Conflict`. Status aktual kipas diperbarui ketika feedback MQTT diterima dari ESP32.

### GET `/actuators/logs`

Mengambil histori command kipas.

## Alert dan Rekomendasi

```text
GET  /alerts
GET  /alerts/{id}
POST /alerts/{id}/read
GET  /recommendations
GET  /recommendations/latest
GET  /recommendations/{id}
```

Alert otomatis dapat dibuat ketika sensor melewati ambang atau perangkat tidak mengirim heartbeat dalam batas waktu.

## Prediksi Gambar Oryza Vision

Fitur ini menerima gambar yang dipilih atau diambil dari aplikasi. Fitur ini tidak menggunakan API perangkat kamera backend.

### POST `/paddy/predict`

Gunakan `multipart/form-data`:

```text
image: JPG/JPEG/PNG, maksimal 10 MB
```

Laravel meneruskan file ke Oryza Vision API sebagai field multipart `file`.

### POST `/paddy/predict/realtime`

Gunakan `multipart/form-data`:

```text
image: JPG/JPEG/PNG, maksimal 10 MB
stream_id: string opsional
```

Endpoint ini dapat menerima frame berkala dari aplikasi, tetapi tidak mendaftarkan perangkat kamera di backend.

## Riwayat Scan Manual

### GET `/vision/scans`

Query opsional:

```text
scan_type: disease atau pest
page: integer mulai dari 1
per_page: integer 1 sampai 100
```

### POST `/vision/scans`

Gunakan `multipart/form-data`:

```text
client_id: required, string, max 100
scan_type: required, disease|pest
class_name: required, string, max 100
display_name: required, string, max 150
confidence: required, numeric 0..1
scanned_at: required, ISO-8601
image: required, JPG/JPEG/PNG/WEBP, max 10 MB
```

Kombinasi user dan `client_id` bersifat unik. Retry mengembalikan record lama tanpa membuat row atau file baru.

### GET `/vision/scans/{visionScan}`

Mengambil scan milik user aktif. Scan milik user lain tidak dapat diakses.

## Route yang Sudah Dihapus

Route berikut tidak tersedia dan akan mengembalikan `404`:

```text
/cameras
/cameras/{id}
/cameras/{id}/status
/detections
/detections/latest
/detections/{id}
/vision/detections
```

## Integrasi MQTT ESP32

Jalankan listener:

```bash
php artisan mqtt:subscribe
```

Topic default:

```text
oryza-smart/ESP32-01/status
oryza-smart/ESP32-01/sensors
oryza-smart/ESP32-01/actuator/fan/status
oryza-smart/ESP32-01/actuator/fan/command
```

Payload heartbeat:

```json
{"status":"ON"}
```

Payload sensor:

```json
{
  "device_id": "ESP32-01",
  "uptime_s": 120,
  "temperature": 28.5,
  "humidity": 74,
  "npk": {"n": 45, "p": 25, "k": 35},
  "light": {"percent": 65, "uv_index": 3.2},
  "ultrasonic": {"distance_cm": 18, "level_percent": 72},
  "fan": {"state": "OFF", "mode": "AUTO"}
}
```

## Simulator

Simulator sensor langsung:

```bash
php artisan nursery:simulate --count=10 --scenario=mixed
```

Simulator melalui MQTT:

```bash
php artisan mqtt:simulate-device --device=ESP32-01 --scenario=mixed --count=10 --interval=1
```

Scenario: `normal`, `warning`, `critical`, atau `mixed`.

## Status Code

```text
200 OK
201 Created
401 Unauthorized
403 Forbidden
404 Not Found
409 Conflict
422 Unprocessable Entity
429 Too Many Requests
500 Internal Server Error
```

## Flow Flutter

1. Login melalui `/login`.
2. Simpan bearer token.
3. Ambil ringkasan melalui `/dashboard`.
4. Ambil perangkat dan statusnya melalui `/devices`.
5. Ambil detail sensor melalui `/sensors/latest` atau `/sensors/history`.
6. Kontrol kipas melalui `/actuators/fan/control`.
7. Tampilkan status aktual dari `/actuators/fan/status`.
8. Gunakan `/paddy/predict` untuk prediksi gambar dan `/vision/scans` untuk riwayat scan.
