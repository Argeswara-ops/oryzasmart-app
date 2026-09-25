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

Semua endpoint selain login dan Vision callback memakai bearer token Sanctum.

Header:

```text
Authorization: Bearer {token}
Accept: application/json
Content-Type: application/json
```

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
    "ultrasonic": 18
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

## Endpoint Vision Service

Endpoint ini untuk Python Vision Service, bukan Flutter.

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
command: ON, OFF
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

## Catatan Saat IoT dan Vision Real Sudah Ada

Flutter tidak perlu mengganti endpoint. ESP32 dan Vision Python hanya mengganti sumber data yang masuk ke Laravel:

```text
ESP32 -> MQTT -> Laravel -> Database -> Flutter API
Python Vision -> REST API -> Laravel -> Database -> Flutter API
```
