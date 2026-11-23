-- =====================================================================
-- Database Foundation: EduTanggap (Aplikasi Pembelajaran Offline-First)
-- Kelompok 6
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. DATABASE
-- ---------------------------------------------------------------------
DROP DATABASE IF EXISTS db_edutanggap;
CREATE DATABASE db_edutanggap
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE db_edutanggap;

-- ---------------------------------------------------------------------
-- 2. DDL - STRUKTUR TABEL
-- ---------------------------------------------------------------------

-- Tabel master: sekolah
CREATE TABLE sekolah (
    id_sekolah INT AUTO_INCREMENT PRIMARY KEY,
    nama_sekolah VARCHAR(100) NOT NULL UNIQUE
);

-- Tabel master: kelas (setiap kelas milik satu sekolah)
CREATE TABLE kelas (
    id_kelas INT AUTO_INCREMENT PRIMARY KEY,
    id_sekolah INT NOT NULL,
    nama_kelas VARCHAR(20) NOT NULL,
    CONSTRAINT uq_kelas UNIQUE (id_sekolah, nama_kelas),
    CONSTRAINT fk_kelas_sekolah FOREIGN KEY (id_sekolah)
        REFERENCES sekolah (id_sekolah)
);

-- Tabel akun pengguna (siswa dan guru)
CREATE TABLE user (
    id_user INT AUTO_INCREMENT PRIMARY KEY,
    nisn_nuptk VARCHAR(16) NOT NULL UNIQUE,
    nama_lengkap VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('siswa','guru') NOT NULL,
    id_sekolah INT NOT NULL,
    is_logged_in_lokal TINYINT(1) NOT NULL DEFAULT 0,
    CONSTRAINT fk_user_sekolah FOREIGN KEY (id_sekolah)
        REFERENCES sekolah (id_sekolah)
);

-- Profil siswa (1 user siswa = 1 baris)
CREATE TABLE siswa (
    id_siswa INT AUTO_INCREMENT PRIMARY KEY,
    id_user INT NOT NULL UNIQUE,
    id_kelas INT NOT NULL,
    CONSTRAINT fk_siswa_user FOREIGN KEY (id_user) REFERENCES user (id_user),
    CONSTRAINT fk_siswa_kelas FOREIGN KEY (id_kelas) REFERENCES kelas (id_kelas)
);

-- Profil guru (1 user guru = 1 baris)
CREATE TABLE guru (
    id_guru INT AUTO_INCREMENT PRIMARY KEY,
    id_user INT NOT NULL UNIQUE,
    CONSTRAINT fk_guru_user FOREIGN KEY (id_user) REFERENCES user (id_user)
);

-- Tabel master: mata pelajaran
CREATE TABLE mata_pelajaran (
    id_mapel INT AUTO_INCREMENT PRIMARY KEY,
    nama_mapel VARCHAR(50) NOT NULL UNIQUE
);

-- Materi pembelajaran
CREATE TABLE materi (
    id_materi INT AUTO_INCREMENT PRIMARY KEY,
    judul_materi VARCHAR(150) NOT NULL,
    id_mapel INT NOT NULL,
    id_kelas INT NOT NULL,
    id_guru INT NOT NULL,
    tipe_materi ENUM('pdf','video','link') NOT NULL DEFAULT 'pdf',
    ukuran_file_mb DECIMAL(6,2) NOT NULL DEFAULT 0.00,
    is_downloaded TINYINT(1) NOT NULL DEFAULT 0,
    CONSTRAINT fk_materi_mapel FOREIGN KEY (id_mapel) REFERENCES mata_pelajaran (id_mapel),
    CONSTRAINT fk_materi_kelas FOREIGN KEY (id_kelas) REFERENCES kelas (id_kelas),
    CONSTRAINT fk_materi_guru FOREIGN KEY (id_guru) REFERENCES guru (id_guru)
);

-- Lokasi berkas materi lokal
CREATE TABLE media_lokal (
    id_media INT AUTO_INCREMENT PRIMARY KEY,
    id_materi INT NOT NULL UNIQUE,
    file_path_lokal VARCHAR(255) NOT NULL,
    CONSTRAINT fk_media_materi FOREIGN KEY (id_materi) REFERENCES materi (id_materi)
);

-- Progres belajar siswa per materi
CREATE TABLE progres_belajar (
    id_siswa INT NOT NULL,
    id_materi INT NOT NULL,
    status_selesai TINYINT(1) NOT NULL DEFAULT 0,
    persentase_progres TINYINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (id_siswa, id_materi),
    CONSTRAINT chk_progres CHECK (persentase_progres BETWEEN 0 AND 100),
    CONSTRAINT fk_progres_siswa FOREIGN KEY (id_siswa) REFERENCES siswa (id_siswa),
    CONSTRAINT fk_progres_materi FOREIGN KEY (id_materi) REFERENCES materi (id_materi)
);

-- Kuis
CREATE TABLE kuis (
    id_kuis INT AUTO_INCREMENT PRIMARY KEY,
    judul_kuis VARCHAR(150) NOT NULL,
    id_mapel INT NOT NULL,
    id_kelas INT NOT NULL,
    id_guru INT NOT NULL,
    durasi_menit SMALLINT UNSIGNED NOT NULL DEFAULT 30,
    batas_waktu DATETIME NULL,
    CONSTRAINT fk_kuis_mapel FOREIGN KEY (id_mapel) REFERENCES mata_pelajaran (id_mapel),
    CONSTRAINT fk_kuis_kelas FOREIGN KEY (id_kelas) REFERENCES kelas (id_kelas),
    CONSTRAINT fk_kuis_guru FOREIGN KEY (id_guru) REFERENCES guru (id_guru)
);

-- Soal kuis
CREATE TABLE soal (
    id_soal INT AUTO_INCREMENT PRIMARY KEY,
    id_kuis INT NOT NULL,
    pertanyaan TEXT NOT NULL,
    opsi_a VARCHAR(255) NOT NULL,
    opsi_b VARCHAR(255) NOT NULL,
    opsi_c VARCHAR(255) NOT NULL,
    opsi_d VARCHAR(255) NOT NULL,
    kunci ENUM('A','B','C','D') NOT NULL,
    pembahasan TEXT NULL,
    CONSTRAINT fk_soal_kuis FOREIGN KEY (id_kuis) REFERENCES kuis (id_kuis)
);

-- Hasil pengerjaan kuis
CREATE TABLE hasil_kuis_lokal (
    id_hasil INT AUTO_INCREMENT PRIMARY KEY,
    id_kuis INT NOT NULL,
    id_siswa INT NOT NULL,
    skor TINYINT UNSIGNED NOT NULL DEFAULT 0,
    jumlah_benar SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    jumlah_salah SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    waktu_pengerjaan TIME NOT NULL,
    status_sync ENUM('Pending','Synced') NOT NULL DEFAULT 'Pending',
    CONSTRAINT chk_skor CHECK (skor BETWEEN 0 AND 100),
    CONSTRAINT fk_hasil_kuis FOREIGN KEY (id_kuis) REFERENCES kuis (id_kuis),
    CONSTRAINT fk_hasil_siswa FOREIGN KEY (id_siswa) REFERENCES siswa (id_siswa)
);

-- Detail jawaban siswa per soal
CREATE TABLE detail_jawaban (
    id_detail INT AUTO_INCREMENT PRIMARY KEY,
    id_hasil INT NOT NULL,
    id_soal INT NOT NULL,
    jawaban_dipilih ENUM('A','B','C','D') NULL,
    is_benar TINYINT(1) NOT NULL DEFAULT 0,
    CONSTRAINT uq_detail UNIQUE (id_hasil, id_soal),
    CONSTRAINT fk_detail_hasil FOREIGN KEY (id_hasil) REFERENCES hasil_kuis_lokal (id_hasil),
    CONSTRAINT fk_detail_soal FOREIGN KEY (id_soal) REFERENCES soal (id_soal)
);

-- Antrean sinkronisasi ke server pusat
CREATE TABLE antrean_sync (
    id_antrean INT AUTO_INCREMENT PRIMARY KEY,
    id_user INT NOT NULL,
    tipe_aktivitas VARCHAR(50) NOT NULL,
    payload_data_json JSON NOT NULL,
    status_antrean ENUM('Pending','Synced','Failed') NOT NULL DEFAULT 'Pending',
    waktu_dibuat DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    waktu_sync DATETIME NULL,
    CONSTRAINT fk_antrean_user FOREIGN KEY (id_user) REFERENCES user (id_user)
);

-- Kehadiran siswa per kelas
CREATE TABLE kehadiran (
    id_siswa INT NOT NULL,
    id_kelas INT NOT NULL,
    persentase_kehadiran DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    PRIMARY KEY (id_siswa, id_kelas),
    CONSTRAINT chk_hadir CHECK (persentase_kehadiran BETWEEN 0 AND 100),
    CONSTRAINT fk_hadir_siswa FOREIGN KEY (id_siswa) REFERENCES siswa (id_siswa),
    CONSTRAINT fk_hadir_kelas FOREIGN KEY (id_kelas) REFERENCES kelas (id_kelas)
);

-- ---------------------------------------------------------------------
-- 3. DML - PENGISIAN DATA
-- ---------------------------------------------------------------------

INSERT INTO sekolah (nama_sekolah) VALUES
    ('SD Negeri Harapan 01'),
    ('SDN 02 Cilangkap');

INSERT INTO kelas (id_sekolah, nama_kelas) VALUES
    (1, '5A'),
    (2, '5A');

INSERT INTO mata_pelajaran (nama_mapel) VALUES
    ('Bahasa Indonesia'),
    ('Bahasa Inggris'),
    ('Matematika'),
    ('IPA'),
    ('IPS');

INSERT INTO user (nisn_nuptk, nama_lengkap, email, password_hash, role, id_sekolah) VALUES
    ('1234567890', 'Ayu Lestari', 'ayu@example.com', 'HASH_CONTOH_AYU', 'siswa', 1),
    ('1234567891', 'Budi Santoso', 'budi@example.com', 'HASH_CONTOH_BUDI', 'siswa', 1),
    ('1234567892', 'Citra Dewi', 'citra@example.com', 'HASH_CONTOH_CITRA', 'siswa', 1),
    ('1234567890123456', 'Dewi Putri', 'dewi@example.com', 'HASH_CONTOH_DEWI', 'guru', 1);

INSERT INTO siswa (id_user, id_kelas) VALUES
    (1, 1),
    (2, 1),
    (3, 1);

INSERT INTO guru (id_user) VALUES (4);

INSERT INTO materi (judul_materi, id_mapel, id_kelas, id_guru, tipe_materi, ukuran_file_mb, is_downloaded) VALUES
    ('Struktur Kalimat', 1, 1, 1, 'pdf', 2.50, 1),
    ('Mengenal Siklus Air', 4, 1, 1, 'video', 48.00, 1),
    ('Pecahan Dasar', 3, 1, 1, 'pdf', 3.10, 0),
    ('Tata Surya', 4, 1, 1, 'pdf', 4.20, 0);

INSERT INTO media_lokal (id_materi, file_path_lokal) VALUES
    (1, 'downloads/materi/struktur_kalimat.pdf'),
    (2, 'downloads/materi/siklus_air.mp4');

INSERT INTO progres_belajar (id_siswa, id_materi, status_selesai, persentase_progres) VALUES
    (1, 1, 1, 100),
    (1, 2, 1, 100),
    (1, 3, 0, 40),
    (2, 1, 1, 100),
    (2, 2, 0, 60),
    (3, 1, 0, 25);

INSERT INTO kuis (judul_kuis, id_mapel, id_kelas, id_guru, durasi_menit, batas_waktu) VALUES
    ('Kuis Sistem Tata Surya', 4, 1, 1, 30, '2026-10-22 23:59:00'),
    ('Kuis Struktur Kalimat', 1, 1, 1, 20, '2026-10-25 23:59:00');

INSERT INTO soal (id_kuis, pertanyaan, opsi_a, opsi_b, opsi_c, opsi_d, kunci, pembahasan) VALUES
    (1, 'Planet manakah yang dikenal sebagai Planet Merah?', 'Venus', 'Mars', 'Jupiter', 'Saturnus', 'B', 'Mars tampak merah karena kandungan besi oksida.'),
    (1, 'Pusat tata surya adalah ...', 'Bumi', 'Bulan', 'Matahari', 'Mars', 'C', 'Matahari adalah bintang pusat tata surya.'),
    (1, 'Planet terbesar di tata surya adalah ...', 'Jupiter', 'Bumi', 'Venus', 'Merkurius', 'A', 'Jupiter adalah planet terbesar.'),
    (1, 'Berapa jumlah planet di tata surya?', '7', '8', '9', '10', 'B', 'Ada delapan planet.'),
    (1, 'Planet terdekat dengan Matahari adalah ...', 'Venus', 'Bumi', 'Merkurius', 'Mars', 'C', 'Merkurius paling dekat dengan Matahari.');

INSERT INTO hasil_kuis_lokal (id_kuis, id_siswa, skor, jumlah_benar, jumlah_salah, waktu_pengerjaan, status_sync) VALUES
    (1, 1, 80, 4, 1, '00:12:30', 'Pending'),
    (1, 2, 60, 3, 2, '00:15:10', 'Synced');

INSERT INTO detail_jawaban (id_hasil, id_soal, jawaban_dipilih, is_benar) VALUES
    (1, 1, 'B', 1),
    (1, 2, 'C', 1),
    (1, 3, 'A', 1),
    (1, 4, 'B', 1),
    (1, 5, 'A', 0),
    (2, 1, 'B', 1),
    (2, 2, 'C', 1),
    (2, 3, 'B', 0),
    (2, 4, 'B', 1),
    (2, 5, 'A', 0);

INSERT INTO antrean_sync (id_user, tipe_aktivitas, payload_data_json, status_antrean, waktu_dibuat, waktu_sync) VALUES
    (1, 'hasil_kuis', JSON_OBJECT('id_hasil', 1, 'skor', 80), 'Pending', '2026-10-20 10:05:00', NULL),
    (2, 'hasil_kuis', JSON_OBJECT('id_hasil', 2, 'skor', 60), 'Synced', '2026-10-20 10:20:00', '2026-10-20 18:00:00'),
    (1, 'progres', JSON_OBJECT('id_materi', 3, 'progres', 40), 'Pending', '2026-10-21 08:30:00', NULL);

INSERT INTO kehadiran (id_siswa, id_kelas, persentase_kehadiran) VALUES
    (1, 1, 92.50),
    (2, 1, 88.00),
    (3, 1, 81.25);

-- ---------------------------------------------------------------------
-- 4. VIEW - TRANSAKSI UTAMA HASIL KUIS
-- ---------------------------------------------------------------------
CREATE VIEW vw_detail_hasil_kuis AS
SELECT
    h.id_hasil,
    u.nama_lengkap AS nama_siswa,
    k.nama_kelas,
    mp.nama_mapel,
    q.judul_kuis,
    s.id_soal,
    s.pertanyaan,
    d.jawaban_dipilih,
    s.kunci AS kunci_jawaban,
    CASE WHEN d.is_benar = 1 THEN 'Benar' ELSE 'Salah' END AS status_jawaban,
    h.skor,
    h.status_sync
FROM hasil_kuis_lokal AS h
JOIN siswa AS sw ON sw.id_siswa = h.id_siswa
JOIN user AS u ON u.id_user = sw.id_user
JOIN kelas AS k ON k.id_kelas = sw.id_kelas
JOIN kuis AS q ON q.id_kuis = h.id_kuis
JOIN mata_pelajaran AS mp ON mp.id_mapel = q.id_mapel
JOIN detail_jawaban AS d ON d.id_hasil = h.id_hasil
JOIN soal AS s ON s.id_soal = d.id_soal;

SELECT * FROM vw_detail_hasil_kuis ORDER BY id_hasil, id_soal;

-- ---------------------------------------------------------------------
-- 5. USER DATABASE & HAK AKSES
-- ---------------------------------------------------------------------
CREATE USER IF NOT EXISTS 'edu_app'@'localhost' IDENTIFIED BY 'GANTI_PASSWORD_APP';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_edutanggap.* TO 'edu_app'@'localhost';

CREATE USER IF NOT EXISTS 'edu_reader'@'localhost' IDENTIFIED BY 'GANTI_PASSWORD_READER';
GRANT SELECT ON db_edutanggap.vw_detail_hasil_kuis TO 'edu_reader'@'localhost';

CREATE USER IF NOT EXISTS 'edu_sync'@'localhost' IDENTIFIED BY 'GANTI_PASSWORD_SYNC';
GRANT SELECT, INSERT, UPDATE ON db_edutanggap.antrean_sync TO 'edu_sync'@'localhost';
GRANT SELECT, UPDATE ON db_edutanggap.hasil_kuis_lokal TO 'edu_sync'@'localhost';

FLUSH PRIVILEGES;

SHOW GRANTS FOR 'edu_app'@'localhost';
SHOW GRANTS FOR 'edu_reader'@'localhost';
SHOW GRANTS FOR 'edu_sync'@'localhost';