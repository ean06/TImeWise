DROP DATABASE IF EXISTS timeWise;
CREATE DATABASE timeWise;
USE timeWise;

CREATE TABLE Akun (
    idAkun INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50),
    password VARCHAR(50)
);

CREATE TABLE Jadwal (
    idJadwal INT PRIMARY KEY,
    namaJadwal VARCHAR(100),
    tanggal DATE,
    waktu TIME,
    prioritas VARCHAR(20),
    deadline DATE,
    idAkun INT,
    FOREIGN KEY (idAkun) REFERENCES Akun(idAkun)
);

CREATE TABLE Laporan (
    idLaporan INT PRIMARY KEY,
    jenis VARCHAR(50),
    idJadwal INT,
    FOREIGN KEY (idJadwal) REFERENCES Jadwal(idJadwal)
);

CREATE TABLE Notifikasi (
    idNotifikasi INT PRIMARY KEY,
    jenis VARCHAR(50),
    idJadwal INT,
    FOREIGN KEY (idJadwal) REFERENCES Jadwal(idJadwal)
);

INSERT INTO Akun VALUES
(1, 'admin', 'admin123'),
(2, 'user1', 'pass1'),
(3, 'user2', 'pass2'),
(4, 'user3', 'pass3'),
(5, 'user4', 'pass4');

INSERT INTO Jadwal VALUES
(1, 'Meeting', '2026-04-10', '09:00:00', 'Tinggi', '2026-04-11', 1),
(2, 'Kuliah PBO', '2026-04-11', '10:00:00', 'Sedang', '2026-04-12', 2),
(3, 'Belajar SQL', '2026-04-12', '13:00:00', 'Rendah', '2026-04-13', 3),
(4, 'Olahraga', '2026-04-13', '16:00:00', 'Sedang', '2026-04-14', 4),
(5, 'Kerja Proyek', '2026-04-14', '20:00:00', 'Tinggi', '2026-04-15', 5);

INSERT INTO Laporan VALUES
(1, 'Harian', 1),
(2, 'Mingguan', 2),
(3, 'Bulanan', 3),
(4, 'Harian', 4),
(5, 'Tahunan', 5);

INSERT INTO Notifikasi VALUES
(1, 'Reminder', 1),
(2, 'Alert', 2),
(3, 'Reminder', 3),
(4, 'Alert', 4),
(5, 'Reminder', 5);