DROP DATABASE IF EXISTS timewise;
CREATE DATABASE timewise;
USE timewise;

CREATE TABLE akun (
    id_akun INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50),
    password VARCHAR(50)
);

CREATE TABLE jadwal (
    id_jadwal INT AUTO_INCREMENT PRIMARY KEY,
    nama_jadwal VARCHAR(100),
    tanggal DATE,
    waktu TIME,
    prioritas VARCHAR(20),
    deadline DATE,
    id_akun INT,
    FOREIGN KEY (id_akun) REFERENCES akun(id_akun)
);

CREATE TABLE laporan (
    id_laporan INT AUTO_INCREMENT PRIMARY KEY,
    jenis VARCHAR(50),
    id_jadwal INT,
    FOREIGN KEY (id_jadwal) REFERENCES jadwal(id_jadwal)
);

CREATE TABLE notifikasi (
    id_notifikasi INT AUTO_INCREMENT PRIMARY KEY,
    status BOOLEAN DEFAULT TRUE,   -- true = notifikasi aktif, false = tidak
    reminder INT DEFAULT 30,       -- menit sebelum deadline notifikasi muncul
    id_jadwal INT,
    FOREIGN KEY (id_jadwal) REFERENCES jadwal(id_jadwal)
);

-- Hanya admin sebagai dummy user
INSERT INTO akun VALUES (1, 'admin', 'admin123');

-- Dummy jadwal admin minggu ini
INSERT INTO jadwal VALUES
(1, 'Meeting Tim',      '2026-06-02', '09:00:00', 'Tinggi', '2026-06-03', 1),
(2, 'Kuliah PBO',       '2026-06-02', '13:00:00', 'Sedang', '2026-06-05', 1),
(3, 'Belajar Flutter',  '2026-06-03', '10:00:00', 'Sedang', '2026-06-06', 1),
(4, 'Kerja Proyek',     '2026-06-04', '09:00:00', 'Tinggi', '2026-06-07', 1),
(5, 'Review Tugas',     '2026-06-04', '14:00:00', 'Rendah', '2026-06-08', 1),
(6, 'Olahraga',         '2026-06-05', '07:00:00', 'Rendah', NULL,         1),
(7, 'Diskusi Kelompok', '2026-06-05', '13:00:00', 'Sedang', '2026-06-06', 1),
(8, 'Presentasi',       '2026-06-06', '09:00:00', 'Tinggi', '2026-06-06', 1);

-- Laporan
INSERT INTO laporan VALUES
(1, 'Harian',   1),
(2, 'Harian',   2),
(3, 'Harian',   3),
(4, 'Mingguan', 4),
(5, 'Mingguan', 5);

-- Notifikasi: status true = aktif, reminder = menit sebelum deadline
INSERT INTO notifikasi VALUES
(1, TRUE,  30, 1),
(2, TRUE,  30, 2),
(3, TRUE,  30, 3),
(4, TRUE,  30, 4),
(5, FALSE, 30, 5),
(6, TRUE,  30, 7),
(7, TRUE,  30, 8);
