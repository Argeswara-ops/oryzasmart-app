# ORYZA SMART

ORYZA SMART is a Flutter mobile application for Smart Rice Nursery monitoring. The app connects to a Laravel API to display real-time nursery conditions, sensor history, alerts, recommendations, device status, fan control, and AI-assisted paddy image prediction.

## Overview

The system is designed around a centralized backend architecture. Flutter communicates only with the Laravel REST API, while Laravel integrates data from IoT devices, MQTT, database records, and the Oryza Vision service.

```text
Flutter App -> Laravel API -> MySQL / MQTT / Oryza Vision
ESP32       -> MQTT        -> Laravel API
Camera AI   -> Vision API  -> Laravel API
```

## Key Features

- Secure login with Laravel Sanctum bearer token.
- Dashboard for system status, device status, latest sensor values, latest detection, alerts, and recommendations.
- Sensor monitoring and history for temperature, humidity, NPK, light, UV, ultrasonic distance, and water level.
- Vision menu with camera/gallery image upload for paddy disease prediction.
- Multipart upload to `POST /api/paddy/predict` using field `image`.
- Vision detection history with disease, pest, healthy, and unknown categories.
- Fan actuator control with manual and automatic modes.
- Device and camera status views.
- Alert and recommendation pages for nursery operation support.

## Tech Stack

- Flutter and Dart
- Riverpod for state management
- Dio for REST API communication
- FL Chart for sensor visualization
- Image Picker for camera/gallery upload
- Laravel REST API with Sanctum authentication

## Project Structure

```text
lib/
  core/
    api/
    config/
    constants/
    theme/
  features/
    auth/
    dashboard/
    devices/
    history/
    sensors/
    settings/
    vision/
  shared/
    models/
    repositories/
    widgets/
```

## Requirements

- Flutter SDK compatible with Dart `^3.11.0`
- Android Studio or Xcode for mobile builds
- Running Laravel backend that follows `docs/API.MD`
- Valid API base URL in `.env`

## Environment Setup

Create a `.env` file in the project root:

```env
API_BASE_URL=http://10.0.2.2:8000/api
```

Common values:

- Android emulator: `http://10.0.2.2:8000/api`
- Local desktop/web testing: `http://127.0.0.1:8000/api`
- Physical device: use the local network IP of the backend machine, for example `http://192.168.1.10:8000/api`

## Installation

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Backend Integration

The API contract is documented in `docs/API.MD`.

Default development login from the backend seeder/simulator:

```text
email: operator@padibackend.test
password: password
```

Important endpoints used by the app:

```text
POST /api/login
GET  /api/dashboard
GET  /api/sensors/latest
GET  /api/sensors/history?range=today|7days|30days
GET  /api/detections
GET  /api/detections/latest
POST /api/paddy/predict
GET  /api/alerts
GET  /api/recommendations
GET  /api/actuators/fan/status
POST /api/actuators/fan/control
```

### Paddy Prediction Upload

The Vision menu sends selected images to Laravel as multipart form data:

```text
POST /api/paddy/predict
Authorization: Bearer {token}
Accept: application/json
Content-Type: multipart/form-data

image: JPG/JPEG/PNG file, max 10 MB
```

Successful response shape:

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

## Backend Simulator

For development without physical ESP32 and real Vision service, use the Laravel simulator described in `docs/API.MD`:

```bash
php artisan migrate --seed
php artisan nursery:simulate --count=10 --scenario=mixed
php artisan serve
```

Optional MQTT simulation:

```bash
php artisan mqtt:simulate-device --device=ESP32-01 --scenario=mixed --count=10 --interval=1
php artisan mqtt:listen
```

## Quality Checks

Before pushing changes, run:

```bash
flutter analyze
flutter test
```

Current app verification:

- `flutter analyze`: no issues
- `flutter test`: all tests passed

## Documentation

- API contract: `docs/API.MD`
- Product requirements: `docs/PRD.MD`

