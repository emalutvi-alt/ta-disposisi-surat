# eDispo — Aplikasi Mobile Disposisi Surat

Aplikasi mobile berbasis Flutter untuk pengelolaan disposisi surat masuk dan surat keluar di lingkungan sekolah. Dibangun sebagai Tugas Akhir (TA) program keahlian Rekayasa Perangkat Lunak (RPL).

---

## Teknologi

- **Flutter** — framework utama (Dart)
- **Go (Golang)** — backend REST API
- **MySQL** — database
- **Dio** — HTTP client & download file
- **image_gallery_saver** — simpan lampiran ke galeri HP

---

## Struktur Project

```
ta_mobile_disposisi_surat/
├── android/                          # Konfigurasi platform Android
├── ios/                              # Konfigurasi platform iOS
├── assets/                           # Aset statis aplikasi
├── lib/                              # Source code utama Flutter ⭐
├── disposisi-backend/                # Backend Go (REST API) ⭐
├── test/                             # Unit test
├── pubspec.yaml                      # Konfigurasi project & dependencies ⭐
└── README.md
```

---

## Penjelasan Folder & File

### ⭐ `lib/` — Source Code Utama

> Ini adalah folder paling penting dalam project Flutter. Semua logika, tampilan, dan fitur aplikasi ada di sini.

#### ⭐ `lib/main.dart`
> **Entry point aplikasi.** File pertama yang dijalankan saat app dibuka. Berisi inisialisasi Flutter dan pemanggilan `MyApp`. Tanpa file ini, aplikasi tidak bisa berjalan.

#### `lib/app.dart`
Konfigurasi root aplikasi. Mengatur tema, nama aplikasi, dan routing awal (halaman pertama yang ditampilkan).

---

### ⭐ `lib/core/` — Inti & Utilitas Global

> Berisi kode yang digunakan di **seluruh** bagian aplikasi — bukan milik satu fitur tertentu. Perubahan di sini berdampak ke semua halaman.

#### `lib/core/constants/`
| File | Fungsi |
|---|---|
| ⭐ `app_color.dart` | **Definisi semua warna aplikasi.** Semua warna yang tampil di UI diambil dari sini |
| ⭐ `role.dart` | **Definisi role pengguna.** Menentukan hak akses Kepala Sekolah, Tata Usaha, dan User |

#### `lib/core/helpers/`
| File | Fungsi |
|---|---|
| `navigation_helper.dart` | Fungsi bantuan untuk navigasi antar halaman secara global |

#### `lib/core/utils/`
| File | Fungsi |
|---|---|
| ⭐ `full-imges-viewer.dart` | **Widget full screen viewer + download lampiran.** Dipakai di semua role untuk melihat dan mengunduh lampiran surat ke galeri HP |

---

### ⭐ `lib/features/` — Fitur Berdasarkan Role

> Setiap role pengguna punya folder sendiri. Ini adalah struktur **feature-based** — memudahkan pengembangan dan pemeliharaan kode per fitur.

#### ⭐ `lib/features/kepsek/pages/` — Halaman Kepala Sekolah
| File | Fungsi |
|---|---|
| ⭐ `menu_kepsek_page.dart` | **Dashboard utama Kepsek.** Menampilkan daftar surat masuk yang perlu didisposisi |
| ⭐ `disposisi_suratmasuk.dart` | **Form disposisi surat masuk.** Kepsek mengisi catatan, instruksi, dan tujuan disposisi — ini inti dari fitur disposisi |
| `history_kepsek_page.dart` | Riwayat disposisi yang sudah dilakukan Kepala Sekolah |
| `pengajuan_suratkeluar.dart` | Detail surat keluar yang diajukan, untuk ditinjau Kepsek |

#### ⭐ `lib/features/tata usaha/pages/` — Halaman Tata Usaha
| File | Fungsi |
|---|---|
| ⭐ `menuTU.dart` | **Dashboard utama Tata Usaha.** Menampilkan surat masuk dan keluar yang dikelola TU |
| ⭐ `hasil_disposisi_surat_masuk_page.dart` | **Hasil disposisi dari Kepsek.** TU melihat instruksi disposisi yang sudah diisi Kepsek |
| `hasil_pengajuan_surat_keluar_page.dart` | Hasil pengajuan surat keluar yang sudah disetujui atau ditolak |
| `history_tu.dart` | Riwayat semua aktivitas surat yang dikelola Tata Usaha |

#### ⭐ `lib/features/users/pages/` — Halaman User / Staff
| File | Fungsi |
|---|---|
| ⭐ `menu_user_page.dart` | **Dashboard utama User.** Menampilkan surat yang diteruskan kepadanya |
| ⭐ `detail_surat_page.dart` | **Detail surat + lampiran.** User bisa melihat dan mengunduh lampiran surat ke galeri |
| `history_user_page.dart` | Riwayat surat yang sudah diterima atau dikonfirmasi user |

---

### ⭐ `lib/shared/` — Komponen & Halaman yang Digunakan Semua Role

> Kode di sini bersifat **reusable** — dipakai bersama oleh semua role tanpa duplikasi.

#### ⭐ `lib/shared/auth/` — Autentikasi
| File | Fungsi |
|---|---|
| ⭐ `login_page.dart` | **Halaman login.** Gerbang utama aplikasi — input email & password, validasi role |
| `profile_page.dart` | Halaman profil — menampilkan data akun yang sedang login |
| `change_password_page.dart` | Halaman ganti password untuk pengguna yang sudah login |

#### `lib/shared/auth/pages/`
| File | Fungsi |
|---|---|
| ⭐ `splash_screen.dart` | **Splash screen.** Halaman pertama yang muncul saat app dibuka |
| ⭐ `home.dart` | **Penentu redirect role.** Mengarahkan pengguna ke dashboard yang sesuai setelah login berhasil |

#### `lib/shared/auth/reset kata sandi/` — Alur Reset Password
| File | Fungsi |
|---|---|
| `input_email_page.dart` | Input email untuk memulai proses reset password |
| `otp_verification_page.dart` | Verifikasi kode OTP yang dikirim ke email |
| `new_password_page.dart` | Input password baru setelah OTP berhasil diverifikasi |

#### ⭐ `lib/shared/widgets/` — Widget Reusable
| File | Fungsi |
|---|---|
| ⭐ `custom_navbar.dart` | **Bottom navigation bar.** Dipakai di semua role — Menu, History, Profile |
| ⭐ `surat_card.dart` | **Card surat.** Komponen utama untuk menampilkan item surat dalam list |
| `filter_date.dart` | Widget filter tanggal untuk menyaring riwayat surat |
| `notification_page.dart` | Halaman notifikasi surat baru |
| `dummy.dart` | Data dummy untuk testing UI tanpa koneksi API |

---

### `assets/` — Aset Statis

#### `assets/images/`
| File | Keterangan |
|---|---|
| ⭐ `logo.png` | **Logo aplikasi eDispo** |
| `logosmk.jpg` | Logo sekolah |
| `undangan.png` | Contoh gambar surat untuk testing |

#### `assets/icons/`
| File | Keterangan |
|---|---|
| ⭐ `ic_home.svg` | Ikon menu Home di navbar |
| ⭐ `ic_history.svg` | Ikon menu History di navbar |
| ⭐ `ic_profile.svg` | Ikon menu Profile di navbar |
| `ic_inmail.svg` | Ikon surat masuk |
| `ic_outmail.svg` | Ikon surat keluar |

---

### ⭐ `disposisi-backend/` — Backend REST API (Go)

> Backend terpisah yang menyediakan API untuk aplikasi mobile. Aplikasi Flutter tidak bisa mengambil atau mengirim data tanpa backend ini berjalan.

| File/Folder | Fungsi |
|---|---|
| ⭐ `main.go` | **Entry point backend.** Menjalankan server Go — file pertama yang dieksekusi |
| `go.mod` & `go.sum` | Konfigurasi dan lock file dependencies Go |
| ⭐ `config/db.go` | **Koneksi database MySQL.** Tanpa ini backend tidak bisa terhubung ke database |
| `models/user.go` | Struktur data (model) untuk tabel user di database |
| ⭐ `controllers/auth.go` | **Logic autentikasi.** Menangani login, validasi token, dan keamanan akses |
| ⭐ `routes/auth.go` | **Endpoint API autentikasi.** Mendefinisikan URL yang bisa diakses aplikasi mobile |

---

### ⭐ `android/` — Konfigurasi Android

| File/Folder | Fungsi |
|---|---|
| ⭐ `app/src/main/AndroidManifest.xml` | **Konfigurasi utama Android.** Nama app, permission storage/internet, activity |
| `app/src/main/kotlin/.../MainActivity.kt` | Entry point Android native |
| `app/src/main/res/mipmap-*/ic_launcher.png` | Icon aplikasi dalam berbagai resolusi layar |
| `app/src/main/res/values/styles.xml` | Tema splash screen Android |
| ⭐ `build.gradle.kts` | **Konfigurasi build Android.** Versi SDK minimum, target SDK, dan dependencies native |
| `gradle.properties` | Properti build Gradle |

---

### ⭐ `ios/` — Konfigurasi iOS

| File/Folder | Fungsi |
|---|---|
| ⭐ `Runner/Info.plist` | **Konfigurasi utama iOS.** Nama app, permission galeri foto, orientasi layar |
| `Runner/AppDelegate.swift` | Entry point iOS native |
| `Runner/Assets.xcassets/AppIcon.appiconset/` | Icon aplikasi dalam berbagai ukuran untuk iOS |
| `Runner.xcodeproj/` | File project Xcode |
| `Runner.xcworkspace/` | Workspace Xcode untuk build iOS |

---

### ⭐ File di Root Project

| File | Fungsi |
|---|---|
| ⭐ `pubspec.yaml` | **Konfigurasi utama Flutter.** Nama app, versi, semua package/dependencies, dan daftar assets |
| `pubspec.lock` | Lock file otomatis — mencatat versi exact semua package yang terinstall |
| `analysis_options.yaml` | Aturan linting Dart — standar penulisan kode |
| `README.md` | Dokumentasi project ini |

---

### `test/`
| File | Fungsi |
|---|---|
| `widget_test.dart` | File test bawaan Flutter — bisa diisi dengan unit test widget |

---

### `web/` *(tidak digunakan)*
Folder bawaan Flutter saat project dibuat. Tidak digunakan karena aplikasi ini hanya untuk platform Android dan iOS.

---

## Alur Penggunaan Aplikasi

```
Buka App
   └── Splash Screen
         └── Login
               ├── Kepala Sekolah → Dashboard Kepsek
               │     ├── Lihat surat masuk → Isi disposisi → Teruskan
               │     └── Lihat riwayat disposisi
               ├── Tata Usaha → Dashboard TU
               │     ├── Lihat hasil disposisi dari Kepsek
               │     └── Kelola surat keluar
               └── User/Staff → Dashboard User
                     ├── Lihat surat yang diteruskan
                     ├── Lihat & unduh lampiran → Galeri HP
                     └── Konfirmasi penerimaan surat
```

---

## Cara Menjalankan Project

### Prasyarat
- Flutter SDK `^3.10.0`
- Go `^1.21`
- MySQL
- Android Studio / VS Code

### Install dependencies
```bash
flutter pub get
```

### Jalankan aplikasi
```bash
flutter run
```

### Jalankan backend
```bash
cd disposisi-backend
go run main.go
```

---

## Developer

| Nama | Role |
|---|---|
| *(nama kamu)* | Flutter Mobile Developer |

*Tugas Akhir — Program Keahlian Rekayasa Perangkat Lunak (RPL)*