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
    FOREIGN KEY (id_akun) REFERENCES akun (id_akun)
);

CREATE TABLE laporan (
    id_laporan INT AUTO_INCREMENT PRIMARY KEY,
    jenis VARCHAR(50),
    id_jadwal INT,
    FOREIGN KEY (id_jadwal) REFERENCES jadwal (id_jadwal)
);

CREATE TABLE notifikasi (
    id_notifikasi INT AUTO_INCREMENT PRIMARY KEY,
    jenis VARCHAR(50),
    id_jadwal INT,
    FOREIGN KEY (id_jadwal) REFERENCES jadwal (id_jadwal)
);

INSERT INTO
    akun
VALUES (1, 'admin', 'admin123'),
    (2, 'user1', 'pass1'),
    (3, 'user2', 'pass2'),
    (4, 'user3', 'pass3'),
    (5, 'user4', 'pass4');

INSERT INTO
    jadwal
VALUES (
        1,
        'Meeting',
        '2026-04-10',
        '09:00:00',
        'Tinggi',
        '2026-04-11',
        1
    ),
    (
        2,
        'Kuliah PBO',
        '2026-04-11',
        '10:00:00',
        'Sedang',
        '2026-04-12',
        2
    ),
    (
        3,
        'Belajar SQL',
        '2026-04-12',
        '13:00:00',
        'Rendah',
        '2026-04-13',
        3
    ),
    (
        4,
        'Olahraga',
        '2026-04-13',
        '16:00:00',
        'Sedang',
        '2026-04-14',
        4
    ),
    (
        5,
        'Kerja Proyek',
        '2026-04-14',
        '20:00:00',
        'Tinggi',
        '2026-04-15',
        5
    );

INSERT INTO
    laporan
VALUES (1, 'Harian', 1),
    (2, 'Mingguan', 2),
    (3, 'Bulanan', 3),
    (4, 'Harian', 4),
    (5, 'Tahunan', 5);

INSERT INTO
    notifikasi
VALUES (1, 'Reminder', 1),
    (2, 'Alert', 2),
    (3, 'Reminder', 3),
    (4, 'Alert', 4),
    (5, 'Reminder', 5);