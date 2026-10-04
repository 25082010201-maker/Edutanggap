# Edutanggap
Belajar siap, tetap tenang.

## Informasi Tim
Nama Kelompok: [the powerpuff]
Anggota dan pembagian tugas:
1. Arya Tri Wicaksono (25082010230) - Captain
   Memimpin dan mengoordinasikan tim, mengatur jadwal pengerjaan, serta memastikan hasil sesuai desain dan ketentuan tugas.
2. Joy Heaty Yesika Tabuni (25082010201) - Hacker
   Mengimplementasikan UI slicing ke dalam kode program (autentikasi, CRUD master data, dan halaman profil), mengelola repositori GitHub, serta mengumpulkan tugas.
3. Amelia Zabrina (25082010210) - Hipster
   Merancang dan menyempurnakan desain antarmuka, meliputi pemilihan warna, tipografi, aset visual, dan konsistensi tampilan.
4. Putri Maulidina Salsabila (25082010229) - Hustler
   Menyusun alur proses bisnis, menyiapkan konten (materi, soal kuis, dan data contoh), serta menulis dokumentasi aplikasi.

## Deskripsi Aplikasi
EduTanggap adalah aplikasi pembelajaran untuk siswa dan guru sekolah dasar yang berfokus pada edukasi kesiapsiagaan bencana. Siswa dapat belajar mengenali risiko bencana dan cara menghadapinya melalui materi bacaan, video pembelajaran, dan kuis. Guru dapat mengelola konten pembelajaran dan memantau perkembangan kelasnya.
Aplikasi ini dirancang agar tetap dapat digunakan di daerah dengan koneksi internet yang terbatas. Aktivitas belajar, seperti hasil kuis, disimpan lebih dahulu di perangkat dan akan disinkronkan secara otomatis ketika perangkat kembali terhubung ke internet.

### Tujuan
- Menanamkan pengetahuan kesiapsiagaan bencana sejak dini.
- Menyediakan media belajar yang sederhana dan mudah dipahami anak-anak.
- Membantu guru menyampaikan materi dan memantau capaian siswa.
- Menjaga proses belajar tetap berjalan meskipun koneksi internet tidak stabil.

### Proses Bisnis
Proses bisnis yang diangkat adalah proses pembelajaran, dengan alur sebagai berikut:
1. Guru menyiapkan mata pelajaran, materi, video, dan kuis.
2. Siswa mempelajari materi dan video, lalu mengerjakan kuis.
3. Sistem menghitung skor dan menyimpan hasilnya, kemudian menyinkronkannya saat terhubung ke internet.
4. Guru memantau progres, aktivitas terbaru, dan kehadiran siswa melalui dashboard.

## Fitur
### 1. Autentikasi
- Registrasi: pengguna baru memilih peran (siswa atau guru) dan sekolah, mengisi NISN 10 digit, serta membuat kata sandi minimal 8 karakter.
- Login: pengguna masuk dengan memilih peran, sekolah, NISN, dan kata sandi. Tersedia tombol untuk menampilkan atau menyembunyikan kata sandi.
- Logout: pengguna keluar dari akun dan kembali ke halaman login.

### 2. Dashboard Siswa
- Sapaan sesuai nama siswa yang sedang login.
- Progres belajar dalam bentuk persentase dan bilah progres.
- Akses cepat ke Lanjutkan Materi, Kuis Singkat, Materi Tersimpan, dan Video Pembelajaran.
- Informasi bahwa aplikasi tetap dapat digunakan tanpa internet.

### 3. Dashboard Guru
- Identitas kelas yang diampu, misalnya SDN 02 Cilangkap, Kelas 5A.
- Statistik kelas: jumlah siswa aktif, materi, kuis, dan persentase kehadiran.
- Daftar aktivitas terbaru siswa.
- Progres pembelajaran per mata pelajaran.
- Aksi cepat untuk menambah materi, membuat kuis, dan menambah video.

### 4. CRUD Master Data
Master data pada proses pembelajaran terdiri dari:
- Mata pelajaran: tambah, lihat daftar, ubah nama atau deskripsi, dan hapus.
- Materi: tambah materi per mata pelajaran, lihat daftar dan detail, ubah isi, dan hapus.
- Video pembelajaran: tambah video (judul, durasi, sumber), lihat dan putar, ubah informasi, dan hapus.
- Kuis: buat kuis dan soal pilihan ganda, lihat daftar kuis dan soal, ubah soal beserta kunci jawaban, dan hapus.

### 5. Pembelajaran Siswa
- Melihat daftar mata pelajaran beserta jumlah materi dan progresnya.
- Membaca materi dan menonton video pembelajaran.
- Mengerjakan kuis pilihan ganda dengan indikator nomor soal serta tombol Sebelumnya dan Selanjutnya.
- Melihat hasil kuis berupa skor, jumlah jawaban benar dan salah, waktu pengerjaan, serta pembahasan.

### 6. Sinkronisasi Aplikasi
- Menampilkan jumlah item yang menunggu untuk disinkronkan.
- Tersedia tombol sinkronisasi manual saat koneksi tersedia.
- Menampilkan daftar aktivitas beserta statusnya, yaitu Menunggu Koneksi atau Berhasil Terkirim.
- Menampilkan keterangan bahwa data tetap tersimpan aman di perangkat selama belum terkirim.

### 7. Profil Pengguna
Halaman profil menampilkan foto, nama lengkap, kelas, dan nomor induk siswa, serta tombol untuk kembali ke beranda.
## Hak Akses Pengguna
Siswa dapat:
- Registrasi, login, dan logout.
- Membuka materi dan video pembelajaran.
- Mengerjakan kuis dan melihat hasilnya.
- Melihat progres belajar dan profil sendiri.
- Melakukan sinkronisasi data.

Guru dapat:
- Registrasi, login, dan logout.
- Mengelola mata pelajaran, materi, video, dan kuis.
- Memantau progres, aktivitas, dan kehadiran siswa di kelasnya.
- Melakukan sinkronisasi data.
- Melihat profil sendiri.

## Daftar Halaman
1. Splash screen
2. Login
3. Registrasi
4. Dashboard siswa
5. Mata pelajaran
6. Detail materi dan video
7. Dashboard guru
8. Kuis
9. Hasil kuis
10. Sinkronisasi aplikasi
11. Dashboard kelas
12. Profil pengguna

## Desain Antarmuka
- Warna utama hijau tua dengan aksen oranye dan biru, serta latar putih atau krem agar nyaman dibaca.
- Tipografi sans-serif yang bersih dan mudah dibaca anak-anak.
- Komponen berupa kartu, bilah progres, tombol aksi yang jelas, ikon sederhana, dan sidebar navigasi.
- Ilustrasi bergaya ramah anak dengan suasana kelas dan kesiapsiagaan bencana.

## Cara Menjalankan
```bash
git clone [ISI LINK GITHUB]
cd EduTanggap
```
