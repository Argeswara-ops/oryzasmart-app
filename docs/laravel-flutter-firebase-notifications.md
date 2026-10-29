# Konfigurasi Notifikasi Firebase: Flutter dan Laravel

Panduan ini menjelaskan konfigurasi Firebase Cloud Messaging (FCM) untuk
aplikasi Flutter ORYZA SMART dan backend Laravel pada repository ini. Flutter
mengambil FCM registration token perangkat dan mengirimkannya ke Laravel setelah
login atau pemulihan sesi.

## Alur integrasi

1. Flutter meminta izin notifikasi dan mengambil FCM registration token.
2. Setelah login, Flutter mengirim token ke `POST /api/user/fcm-token` dengan
   bearer token Sanctum.
3. Laravel menyimpan token pada kolom `users.fcm_token` untuk user yang login.
4. Laravel mengirim push notification ke FCM HTTP v1 menggunakan service
   account.
5. Saat logout, Flutter meminta Laravel menghapus token user melalui
   `DELETE /api/user/fcm-token`.

FCM registration token berbeda dari token autentikasi Sanctum. Sanctum
mengautentikasi request API; FCM token menentukan perangkat tujuan notifikasi.
Backend saat ini menyimpan satu FCM token per user, sehingga login dari
perangkat lain menggantikan token sebelumnya.

## Konfigurasi Firebase dan Flutter

### Firebase Android

1. Buat atau pilih Firebase project.
2. Tambahkan Android app dengan package name yang sama dengan `applicationId`
   pada `android/app/build.gradle.kts` (`com.example.padiapps` saat ini).
3. Unduh `google-services.json` dari Firebase Console dan simpan di:

   ```text
   android/app/google-services.json
   ```

4. Pastikan Google Services Gradle plugin dan Firebase dependencies tetap
   dikonfigurasi melalui `android/settings.gradle.kts`,
   `android/app/build.gradle.kts`, dan `pubspec.yaml`.
5. Pastikan `lib/firebase_options.dart` menunjuk ke Firebase project yang sama.
   Jika project berubah, regenerasi options dengan FlutterFire CLI; jangan
   menyalin values dari project lain.

`google-services.json` adalah konfigurasi aplikasi klien. Jangan pernah
menaruh service-account JSON atau private key server di Flutter, file tersebut,
atau repository.

Untuk iOS, daftarkan iOS bundle ID di Firebase, tambahkan konfigurasi iOS yang
sesuai, dan hubungkan APNs authentication key pada Firebase Console.

### URL Laravel

Atur `API_BASE_URL` pada `.env` di root aplikasi Flutter. Contoh untuk emulator
Android:

```dotenv
API_BASE_URL=http://10.0.2.2:8000/api
```

Pilih URL sesuai target:

| Target | Base URL |
| --- | --- |
| Android emulator | `http://10.0.2.2:8000/api` |
| iOS Simulator | `http://127.0.0.1:8000/api` |
| Perangkat fisik | `http://<IP-LAN-komputer>:8000/api` |
| Production | URL HTTPS backend Laravel |

Komputer dan perangkat fisik harus berada pada jaringan yang dapat saling
mengakses. Jalankan backend lokal agar dapat diakses perangkat:

```bash
php artisan serve --host=0.0.0.0 --port=8000
```

Jalankan Flutter:

```bash
flutter pub get
flutter run
```

Kode aplikasi menginisialisasi Firebase melalui `firebase_core` dan
`lib/firebase_options.dart`, mengambil token melalui `firebase_messaging`, dan
menampilkan notifikasi foreground melalui `flutter_local_notifications`.
Android 13 atau versi lebih baru memerlukan izin notifikasi. Di iOS, pengguna
harus memberikan izin dan APNs harus dikonfigurasi.

## Konfigurasi Laravel

Backend ini mengirim pesan menggunakan Firebase Cloud Messaging HTTP v1 dan
OAuth service-account JWT pada `app/Services/FirebaseService.php`. Tidak
diperlukan instalasi Kreait atau tabel `fcm_tokens` terpisah.

### Kredensial server

Letakkan file service account Firebase di:

```text
storage/app/firebase-credentials.json
```

File harus dapat dibaca oleh proses PHP dan memuat `client_email`, `private_key`,
serta `project_id`. Aktifkan Firebase Cloud Messaging API untuk Google Cloud
project yang sesuai. Jangan commit service-account JSON atau mengirimkannya ke
Flutter. Simpan file tersebut dengan permission terbatas pada server.

### Database dan endpoint

Jalankan migration di backend:

```bash
php artisan migrate
```

Migration menambahkan kolom nullable `users.fcm_token`. Endpoint berikut
memerlukan bearer token Sanctum:

| Method | Endpoint | Fungsi |
| --- | --- | --- |
| `POST` | `/api/user/fcm-token` | Simpan atau perbarui token untuk user login |
| `DELETE` | `/api/user/fcm-token` | Hapus token user login |
| `POST` | `/api/notifications/test` | Kirim notifikasi tes ke token user login |

Flutter mengirim request pendaftaran setelah login atau memulihkan sesi:

```http
POST /api/user/fcm-token
Authorization: Bearer <SANCTUM_TOKEN>
Accept: application/json
Content-Type: application/json
```

```json
{
  "fcm_token": "<FCM_REGISTRATION_TOKEN>"
}
```

Flutter juga mendaftarkan token baru dari stream `onTokenRefresh`. Request
tersebut hanya dikirim saat ada sesi Sanctum aktif. Saat logout, aplikasi
memanggil `DELETE /api/user/fcm-token` sebelum membersihkan sesi lokal.

> Karena backend menyimpan satu token per user, menghapus token saat logout
> pada satu perangkat juga memengaruhi perangkat lain yang memakai akun sama.
> Dukungan multi-perangkat memerlukan perubahan skema dan API tersendiri.

## Menguji pengiriman

Login melalui `POST /api/login`, ambil `data.token`, lalu pastikan aplikasi
Flutter sudah mendaftarkan FCM token-nya. Kirim notifikasi tes menggunakan
token Sanctum yang sama:

```http
POST /api/notifications/test
Authorization: Bearer <SANCTUM_TOKEN>
Accept: application/json
Content-Type: application/json
```

Body bersifat opsional. Contoh:

```json
{
  "title": "Tes ORYZA SMART",
  "body": "Notifikasi dari Laravel berhasil."
}
```

Endpoint tes hanya menargetkan token user yang login. Respons sukses
menandakan FCM menerima pesan untuk diproses; periksa perangkat untuk
memastikan notifikasi terlihat. Uji saat aplikasi foreground, background, dan
ditutup. Di Android, handler foreground menggunakan local notification.

Saat backend membuat alert perangkat atau kamera offline baru, Laravel juga
mencoba mengirim notifikasi ke semua user yang memiliki token terdaftar.

## Troubleshooting

| Gejala | Pemeriksaan |
| --- | --- |
| `401 Unauthorized` | Pastikan request memakai bearer token Sanctum yang valid. |
| Respons `422`, token tidak ditemukan | Login, ambil FCM registration token, lalu panggil `POST /api/user/fcm-token`. |
| API tidak dapat diakses dari emulator | Gunakan `10.0.2.2` untuk Android emulator, bukan `localhost`. |
| API tidak dapat diakses dari perangkat fisik | Gunakan IP LAN komputer dan periksa jaringan serta firewall. |
| OAuth atau Firebase menolak pengiriman | Periksa service-account JSON, akses file, `project_id`, dan status FCM HTTP v1 API. |
| Pesan tidak terlihat saat app foreground | Periksa `FirebaseMessaging.onMessage` dan konfigurasi local notifications. |
| iOS tidak menerima notifikasi | Periksa izin pengguna, konfigurasi APNs, dan Firebase project. |

Periksa `storage/logs/laravel.log` untuk error backend. Jangan menulis atau
membagikan service-account private key, Sanctum token, atau FCM registration
token ke log publik maupun issue.
