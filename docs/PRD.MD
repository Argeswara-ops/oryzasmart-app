# PRODUCT REQUIREMENTS DOCUMENT (PRD)

## Smart Rice Nursery

**Platform:** Android & iOS
**Frontend Mobile:** Flutter
**Backend:** Laravel
**IoT Communication:** MQTT
**Database:** MySQL
**Computer Vision:** Python + YOLO + OpenCV
**Versi:** MVP 1.0

---

## 1. Deskripsi Produk

Smart Rice Nursery adalah aplikasi mobile Android dan iOS berbasis Flutter untuk memantau kondisi pembibitan padi secara realtime.

Sistem mengintegrasikan:

1. **Sistem Tertanam / IoT**
2. **Computer Vision**
3. **Sistem Cerdas**
4. **Aplikasi Mobile Flutter**

Flutter menjadi antarmuka pengguna, sedangkan Laravel menjadi backend utama yang menangani API, autentikasi, database, histori, notifikasi, dan integrasi data IoT maupun computer vision.

---

# 2. Arsitektur Sistem

```text
                    SMART RICE NURSERY
                           │
          ┌────────────────┴────────────────┐
          │                                 │
          ▼                                 ▼
     SISTEM IoT                         CAMERA
        ESP32                       CCTV / Webcam
          │                                 │
          │                                 ▼
          │                       COMPUTER VISION
          │                       Python + OpenCV
          │                            + YOLO
          │                                 │
          │                                 │ REST API
          ▼                                 ▼
      MQTT BROKER ────────────────────► LARAVEL
          ▲                                 │
          │                                 │
          │                          ┌──────┴───────┐
          │                          ▼              ▼
          │                        MySQL      Sistem Cerdas
          │                          │
          │                          │
          │                     REST API
          │                          │
          │                          ▼
          └──────────────────── FLUTTER APP
                               Android + iOS
```

---

# 3. Pembagian Tanggung Jawab

## ESP32

ESP32 menangani perangkat fisik.

Sensor:

* Suhu ruangan
* Kelembapan udara
* NPK
* Cahaya / UV
* Ultrasonik

Aktuator:

* Kipas

ESP32 membaca sensor kemudian mengirim data melalui MQTT.

Contoh:

```text
Sensor
   ↓
ESP32
   ↓
MQTT Publish
   ↓
MQTT Broker
```

ESP32 juga melakukan subscribe untuk menerima perintah aktuator.

---

# 4. MQTT

MQTT digunakan sebagai komunikasi antara perangkat IoT dengan sistem.

Contoh topic:

```text
rice-nursery/sensors/temperature
rice-nursery/sensors/humidity
rice-nursery/sensors/npk
rice-nursery/sensors/light
rice-nursery/sensors/ultrasonic

rice-nursery/device/status

rice-nursery/actuator/fan/status
rice-nursery/actuator/fan/command
```

Lebih ideal untuk MVP, seluruh pembacaan sensor dapat dikirim dalam satu topic:

```text
rice-nursery/sensors
```

Payload:

```json
{
  "device_id": "ESP32-01",
  "temperature": 29.4,
  "humidity": 81,
  "nitrogen": 40,
  "phosphorus": 22,
  "potassium": 31,
  "light": 720,
  "ultrasonic": 14
}
```

---

# 5. Laravel Backend

Laravel merupakan **backend utama sistem**.

Laravel bertanggung jawab terhadap:

* Authentication
* User management
* REST API
* Database
* Data sensor
* Device management
* Histori sensor
* Histori vision
* Alert
* Notification
* Recommendation
* Kontrol aktuator
* Integrasi MQTT
* Integrasi Computer Vision

Laravel menerima data MQTT kemudian menyimpannya ke MySQL.

```text
ESP32
  ↓
MQTT
  ↓
Laravel MQTT Consumer
  ↓
Validation
  ↓
MySQL
  ↓
REST API
  ↓
Flutter
```

---

# 6. Computer Vision Service

Computer Vision tetap menggunakan Python karena model AI tidak dijalankan melalui Laravel.

Stack:

* Python
* OpenCV
* YOLO
* Ultralytics/PyTorch

Flow:

```text
Camera
   ↓
Capture Frame
   ↓
OpenCV
   ↓
YOLO
   ↓
Detection
   ↓
Hama / Penyakit
   ↓
Laravel API
   ↓
MySQL
   ↓
Flutter
```

Hasil vision:

```json
{
  "camera_id": "CAM-01",
  "type": "disease",
  "class": "rice_blast",
  "confidence": 0.92,
  "image": "detections/cam01-001.jpg"
}
```

Laravel menyimpan hasil tersebut sebagai histori detection.

---

# 7. Flutter Mobile

Flutter digunakan sebagai aplikasi monitoring dan kontrol.

Flutter **tidak berkomunikasi langsung dengan ESP32**.

Flow utama:

```text
Flutter
   ↓
Laravel API
   ↓
Database / MQTT / Vision
```

Fitur Flutter:

* Login
* Dashboard
* Sensor realtime
* Monitoring kamera
* Hasil deteksi hama
* Hasil deteksi penyakit
* Histori sensor
* Histori vision
* Alert
* Recommendation
* Kontrol kipas
* Device status
* Settings

---

# 8. Dashboard

Dashboard menampilkan kondisi terbaru pembibitan.

```text
SMART RICE NURSERY

● SYSTEM ONLINE

Kondisi Pembibitan
⚠ PERLU PERHATIAN

────────────────────

🌡 Suhu
29.4 °C
NORMAL

💧 Kelembapan
81 %
WARNING

☀ Cahaya / UV
720
NORMAL

🌱 N
40 mg/kg

🌱 P
22 mg/kg

🌱 K
31 mg/kg

🌊 Ultrasonik
14 cm

────────────────────

Latest Detection

⚠ Rice Blast
Confidence: 92%

CAM-01
```

---

# 9. Vision

Menu Vision menampilkan:

* Camera
* Snapshot
* Hasil detection
* Bounding box
* Nama hama/penyakit
* Confidence
* Timestamp

Contoh:

```text
CAMERA 01
● ONLINE

[ Camera / Detection Image ]

⚠ Rice Blast

Disease
Confidence 92%

Detected:
11:40:21
```

Kategori detection:

```text
HEALTHY
PEST
DISEASE
UNKNOWN
```

---

# 10. Sistem Cerdas

Sistem cerdas menggunakan informasi dari:

```text
        SENSOR
           │
           │
           ▼
     Laravel Backend
           ▲
           │
           │
   COMPUTER VISION
           │
           ▼
     Decision System
           │
     ┌─────┼─────┐
     ▼     ▼     ▼
   NORMAL ALERT CRITICAL
           │
           ▼
     Recommendation
```

Contoh:

```text
Status:
PERLU PERHATIAN

Penyebab:

Kelembapan udara tinggi: 88%

Computer Vision:
Rice Blast terdeteksi (92%)

Recommendation:

Periksa tanaman pada area CAM-01
dan kondisi kelembapan area pembibitan.
```

---

# 11. Kontrol Kipas

Flutter mengirim command ke Laravel:

```text
Flutter
   ↓
POST /api/actuators/fan
   ↓
Laravel
   ↓
MQTT Publish
   ↓
rice-nursery/actuator/fan/command
   ↓
ESP32
   ↓
Relay
   ↓
Kipas
```

Payload:

```json
{
  "command": "ON"
}
```

ESP32 menjalankan command kemudian publish status:

```json
{
  "device_id": "ESP32-01",
  "fan": "ON"
}
```

---

# 12. Mode Aktuator

Terdapat dua mode:

### AUTO

Kipas dikontrol berdasarkan aturan sistem.

```text
Sensor
   ↓
Sistem Cerdas
   ↓
Laravel
   ↓
MQTT
   ↓
ESP32
   ↓
Kipas
```

### MANUAL

```text
User
 ↓
Flutter
 ↓
Laravel
 ↓
MQTT
 ↓
ESP32
 ↓
Kipas
```

---

# 13. History

## Sensor History

Tampilkan histori:

* Suhu
* Kelembapan
* NPK
* Cahaya/UV
* Ultrasonik

Filter:

* Hari ini
* 7 hari
* 30 hari
* Custom

Tampilkan:

* Grafik
* Current
* Average
* Minimum
* Maximum

## Vision History

Tampilkan:

```text
24 September 2026

11:40
Rice Blast
Disease
92%
CAM-01

10:15
Brown Planthopper
Pest
87%
CAM-01
```

Filter:

* Semua
* Hama
* Penyakit
* Healthy

---

# 14. Alert

Alert dibuat ketika:

* Suhu abnormal
* Kelembapan abnormal
* NPK abnormal
* Cahaya/UV abnormal
* Level air abnormal
* Hama terdeteksi
* Penyakit terdeteksi
* ESP32 offline
* Kamera offline

Level:

```text
INFO
WARNING
CRITICAL
```

---

# 15. API Laravel

Authentication:

```text
POST /api/login
POST /api/logout
GET  /api/user
```

Dashboard:

```text
GET /api/dashboard
GET /api/system/status
```

Sensor:

```text
GET /api/sensors/latest
GET /api/sensors/history
GET /api/sensors/{sensor}
```

Vision:

```text
GET  /api/detections
GET  /api/detections/latest
GET  /api/detections/{id}

POST /api/detections
```

`POST /api/detections` digunakan Python Vision Service untuk mengirim hasil inference.

Device:

```text
GET /api/devices
GET /api/devices/{id}
GET /api/devices/{id}/status
```

Actuator:

```text
GET  /api/actuators/fan
POST /api/actuators/fan/control
POST /api/actuators/fan/mode
```

Alert:

```text
GET  /api/alerts
POST /api/alerts/{id}/read
```

Recommendation:

```text
GET /api/recommendations
GET /api/recommendations/latest
```

---

# 16. Database Utama

Tabel minimum:

```text
users

devices
├── id
├── device_code
├── name
├── type
├── status
└── last_seen

sensor_readings
├── id
├── device_id
├── temperature
├── humidity
├── nitrogen
├── phosphorus
├── potassium
├── light
├── ultrasonic
└── created_at

cameras
├── id
├── name
├── status
└── location

detections
├── id
├── camera_id
├── type
├── class_name
├── confidence
├── image
└── detected_at

actuators
├── id
├── device_id
├── type
├── mode
└── status

alerts

recommendations
```

---

# 17. Struktur Flutter

```text
lib/
├── core/
│   ├── api/
│   ├── config/
│   ├── constants/
│   ├── theme/
│   └── utils/
│
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── sensors/
│   ├── vision/
│   ├── history/
│   ├── alerts/
│   ├── devices/
│   └── settings/
│
├── shared/
│   ├── models/
│   └── widgets/
│
└── main.dart
```

---

# 18. Stack Final

```text
MOBILE
Flutter
Dart
Riverpod
Dio
FL Chart

        ↓

BACKEND
Laravel
Laravel Sanctum
REST API
MySQL

        ↕
       MQTT

IoT
ESP32
Sensor
Aktuator

        +

VISION SERVICE
Python
OpenCV
YOLO
PyTorch / Ultralytics

        +

CAMERA
CCTV / Webcam
```

---

# 19. Alur Sistem Keseluruhan

```text
SENSOR ──► ESP32 ──► MQTT ──► LARAVEL ──► MySQL
                              │
                              │
CAMERA ──► YOLO/OpenCV ───────┤
                              │
                              ▼
                       SISTEM CERDAS
                              │
                       Status + Alert
                       Recommendation
                              │
                              ▼
                           LARAVEL
                              │
                           REST API
                              │
                              ▼
                           FLUTTER
                              │
              ┌───────────────┼──────────────┐
              ▼               ▼              ▼
          Monitoring        Vision        Control
                                             │
                                             ▼
Flutter ──► Laravel ──► MQTT ──► ESP32 ──► Kipas
```

# 20. MVP

MVP wajib mencakup:

* Login Flutter
* Dashboard monitoring
* Suhu realtime
* Kelembapan realtime
* NPK
* Cahaya/UV
* Ultrasonik
* Status ESP32
* Status kamera
* Status kipas
* Kontrol kipas manual
* Mode otomatis
* MQTT communication
* Histori sensor
* Kamera/snapshot
* Deteksi hama
* Deteksi penyakit
* Confidence detection
* Histori detection
* Alert
* Recommendation
* Laravel REST API
* MySQL database
* Python Vision Service

## Prinsip Arsitektur

**ESP32 → MQTT → Laravel → Flutter**

untuk data IoT.

**Camera → Python/YOLO → Laravel → Flutter**

untuk computer vision.

**Flutter → Laravel → MQTT → ESP32**

untuk kontrol perangkat.

Dengan arsitektur ini, Flutter tidak perlu mengetahui detail ESP32, MQTT, maupun model YOLO. Semua integrasi sistem dipusatkan melalui Laravel sebagai backend utama.
