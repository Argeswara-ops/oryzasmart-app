# API Endpoints untuk Integrasi Flutter

Dokumen ini adalah kontrak awal Flutter dengan backend Laravel Smart Rice Nursery. Untuk development tanpa ESP32 dan Vision Python, jalankan simulator backend agar API mengembalikan data seperti sistem real.

## Base URL

Development lokal:

```text
http://127.0.0.1:8000/api
```

Android emulator biasanya memakai:

```text
http://10.0.2.2:8000/api
```

## Auth

Semua endpoint selain login dan Vision callback memakai bearer token Sanctum. Endpoint prediksi padi dari Flutter juga wajib memakai bearer token.

Header:

```text
Authorization: Bearer {token}
Accept: application/json
Content-Type: application/json
```

Untuk upload gambar gunakan `multipart/form-data`, bukan JSON.

Login default dari seeder/simulator:

```text
email: operator@padibackend.test
password: password
```

## Simulator Backend

Gunakan ini sebelum IoT ESP32 dan Python Vision tersedia:

```bash
php artisan nursery:simulate
php artisan nursery:simulate --count=10 --scenario=mixed
php artisan nursery:simulate --sensor --count=5 --scenario=warning
php artisan nursery:simulate --detection --count=3 --scenario=critical
```

Untuk simulasi MQTT seperti perangkat ESP32/Wokwi:

```bash
php artisan mqtt:simulate-device --device=ESP32-01 --scenario=mixed --count=10 --interval=1
php artisan mqtt:simulate-device --device=ESP32-01 --scenario=critical --count=10 --interval=1 --fan-status=ON
```

Listener MQTT:

```bash
php artisan mqtt:listen
```

Scenario:

```text
normal   -> sensor normal, detection HEALTHY
warning  -> sensor melewati threshold, detection PEST confidence sedang
critical -> sensor abnormal berat, detection DISEASE confidence tinggi
mixed    -> bergantian normal, warning, critical
```

## Response Format

Success:

```json
{
  "success": true,
  "message": "Message",
  "data": {}
}
```

Error:

```json
{
  "success": false,
  "message": "Message",
  "errors": {}
}
```

## Endpoint Auth

### POST `/login`

Request:

```json
{
  "email": "operator@padibackend.test",
  "password": "password"
}
```

Response data penting:

```json
{
  "token": "plain-text-token",
  "user": {
    "id": 1,
    "name": "Operator Pembibitan",
    "email": "operator@padibackend.test",
    "role": "operator"
  }
}
```

### GET `/user`

Mengambil user aktif berdasarkan bearer token.

### POST `/logout`

Menghapus token aktif.

## Endpoint Dashboard

### GET `/dashboard`

Dipakai untuk halaman utama Flutter.

Response data:

```json
{
  "system_status": "WARNING",
  "device_status": "ONLINE",
  "sensors": {
    "temperature": 32.4,
    "humidity": 88,
    "nitrogen": 26,
    "phosphorus": 25,
    "potassium": 35,
    "light": 650,
    "light_percent": 65,
    "uv_index": 2.1,
    "ultrasonic": 18,
    "distance_cm": 18,
    "level_percent": 64,
    "fan_state": "OFF",
    "fan_mode": "MANUAL",
    "recorded_at": "2026-09-24T11:40:21.000000Z"
  },
  "latest_detection": {
    "detection_type": "PEST",
    "class_name": "wereng",
    "confidence": 0.78
  },
  "fan": {
    "status": "OFF",
    "mode": "MANUAL"
  },
  "unread_alerts": 1
}
```

## Endpoint Sensor

### GET `/sensors/latest`

Mengambil data sensor terakhir.

Response `data`:

```json
{
  "temperature": 27.2,
  "humidity": 76,
  "nitrogen": 45,
  "phosphorus": 25,
  "potassium": 35,
  "light": 650,
  "light_percent": 65,
  "uv_index": 2.1,
  "ultrasonic": 18,
  "distance_cm": 18,
  "level_percent": 64,
  "fan_state": "OFF",
  "fan_mode": "MANUAL",
  "recorded_at": "2026-09-24T11:40:21.000000Z"
}
```

### GET `/sensors/history?range=today`

Range yang tersedia:

```text
today
7days
30days
```

Response data berisi:

```text
range
summary
series
```

`series[]` berisi field sensor yang sama seperti `/sensors/latest`, ditambah `recorded_at`.

## Endpoint Threshold

### GET `/thresholds`

Mengambil batas minimum dan maksimum sensor.

### PUT `/thresholds/{sensorType}`

Butuh role `operator`.

Contoh:

```http
PUT /api/thresholds/temperature
```

Request:

```json
{
  "min_value": 20,
  "max_value": 30
}
```

Sensor type:

```text
temperature
humidity
nitrogen
phosphorus
potassium
light
ultrasonic
```

## Endpoint Device

### GET `/devices`

List perangkat IoT.

### GET `/devices/{id}`

Detail perangkat.

### GET `/devices/{id}/status`

Status perangkat.

## Endpoint Camera

### GET `/cameras`

List kamera.

### GET `/cameras/{id}`

Detail kamera.

### GET `/cameras/{id}/status`

Status kamera.

## Endpoint Detection

### GET `/detections`

List hasil vision.

Filter:

```text
/detections?type=pest
/detections?type=disease
/detections?camera=CAM-01
```

### GET `/detections/latest`

Hasil vision terbaru.

### GET `/detections/{id}`

Detail detection.

## Endpoint Prediksi Padi

Endpoint ini dipakai Flutter untuk upload gambar ke Laravel. Laravel akan meneruskan gambar ke Oryza Vision API sebagai multipart field `file` dengan header internal `X-API-Key`.

### POST `/paddy/predict`

Header:

```text
Authorization: Bearer {token}
Accept: application/json
Content-Type: multipart/form-data
```

Body multipart:

```text
image: file JPG/JPEG/PNG, max 10 MB
```

Response sukses:

```json
{
  "success": true,
  "prediction": {
    "class_id": 3,
    "class": "blast",
    "display_name": "Blast",
    "confidence": 92.74,
    "status": "high_confidence"
  }
}
```

Jika Oryza Vision API gagal, Laravel mengembalikan status code dari service tersebut:

```json
{
  "success": false,
  "message": "Vision prediction failed",
  "error": {
    "success": false,
    "message": "Invalid image"
  }
}
```

### POST `/paddy/predict/realtime`

Dipakai untuk snapshot kamera berkala. Jangan kirim 30 FPS; gunakan interval sekitar 2 detik.

Header:

```text
Authorization: Bearer {token}
Accept: application/json
Content-Type: multipart/form-data
```

Body multipart:

```text
image: snapshot kamera JPG/JPEG/PNG, max 10 MB
stream_id: string optional, gunakan ID tetap selama halaman kamera aktif
```

Response mengikuti response dari Oryza Vision API. Contoh:

```json
{
  "success": true,
  "prediction": {
    "class": "blast",
    "confidence": 88.5,
    "status": "medium_confidence"
  },
  "stable_prediction": null
}
```

Jika `stable_prediction` masih `null`, Flutter boleh menampilkan `prediction` sebagai indikasi sementara dan memberi status menunggu stabil.

## Endpoint Vision Service

Endpoint ini untuk Python Vision Service, bukan Flutter. Jangan panggil endpoint ini dari aplikasi mobile.

### POST `/vision/detections`

Header:

```text
X-Vision-Key: {VISION_API_KEY}
```

Request:

```json
{
  "camera_id": "CAM-01",
  "detection_type": "DISEASE",
  "class_name": "rice_blast",
  "confidence": 0.92,
  "image_path": "detections/cam01-001.jpg",
  "detected_at": "2026-09-24 11:40:21"
}
```

Allowed `detection_type`:

```text
PEST
DISEASE
HEALTHY
UNKNOWN
```

## Endpoint Alert

### GET `/alerts`

List alert terbaru.

### GET `/alerts/{id}`

Detail alert.

### POST `/alerts/{id}/read`

Menandai alert sebagai terbaca.

## Endpoint Recommendation

### GET `/recommendations`

List rekomendasi.

### GET `/recommendations/latest`

Rekomendasi terbaru.

### GET `/recommendations/{id}`

Detail rekomendasi.

## Endpoint Actuator Kipas

### GET `/actuators/fan/status`

Mengambil status kipas.

### POST `/actuators/fan/control`

Butuh role `operator`.

Request:

```json
{
  "device_id": "ESP32-01",
  "command": "ON",
  "mode": "MANUAL"
}
```

Allowed value:

```text
command: ON, OFF, AUTO
mode: AUTO, MANUAL
```

### GET `/actuators/logs`

Mengambil histori kontrol kipas.

## Status Code Penting

```text
200 OK
201 Created
401 Unauthorized
403 Forbidden
404 Not Found
422 Validation Error
429 Too Many Requests
500 Server Error
```

## Flow Integrasi Flutter

1. Jalankan migration dan seeder:

```bash
php artisan migrate --seed
```

2. Buat data simulasi:

```bash
php artisan nursery:simulate --count=10 --scenario=mixed
```

3. Jalankan backend:

```bash
php artisan serve
```

4. Flutter login ke `/api/login`.
5. Simpan token dari `data.token`.
6. Kirim token di header `Authorization` untuk semua request berikutnya.
7. Halaman dashboard cukup memanggil `/api/dashboard`.
8. Halaman prediksi penyakit/hama mengirim gambar ke `/api/paddy/predict`.
9. Halaman kamera realtime mengirim snapshot berkala ke `/api/paddy/predict/realtime`.

## Catatan Saat IoT dan Vision Real Sudah Ada

Flutter tidak perlu mengganti endpoint untuk dashboard, sensor, detection, alert, dan rekomendasi. ESP32 dan Vision Python hanya mengganti sumber data yang masuk ke Laravel:

```text
ESP32 -> MQTT -> Laravel -> Database -> Flutter API
Python Vision -> REST API -> Laravel -> Database -> Flutter API
```

Untuk prediksi gambar langsung dari aplikasi:

```text
Flutter -> Laravel API -> Oryza Vision API
```
