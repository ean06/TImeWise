SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

-- Table structure for table `akun`

CREATE TABLE `akun` (
  `id_akun` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `status_notif` enum('y','n','','') DEFAULT NULL,
  `waktu_notif` int(5) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `last_active_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table `akun`

INSERT INTO `akun` (`id_akun`, `username`, `password`, `status_notif`, `waktu_notif`, `created_at`, `last_active_at`) VALUES
(1, 'karim', '87654321', 'y', 30, '2026-06-11 10:04:07', NULL),
(3, 'test', '12345678', 'y', NULL, '2026-06-12 04:24:14', NULL),
(4, 'Harald Arkan', '12345678', 'y', NULL, '2026-06-17 23:56:41', NULL),
(5, 'Arkan', '12345678', 'y', 30, '2026-06-18 08:34:41', NULL);

-- --------------------------------------------------------

-- Table structure for table `checklist`

CREATE TABLE `checklist` (
  `id_checklist` int(11) NOT NULL,
  `id_tugas` int(11) NOT NULL,
  `isi` varchar(200) NOT NULL,
  `selesai` enum('y','n','','') NOT NULL,
  `waktu_selesai` timestamp NULL DEFAULT NULL,
  `tgl_selesai` date DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table `checklist`

INSERT INTO `checklist` (`id_checklist`, `id_tugas`, `isi`, `selesai`, `waktu_selesai`, `tgl_selesai`, `created_at`) VALUES
(1, 1, 'Cari contoh struk belanja yang valid', 'y', '2026-06-19 15:45:48', '2026-06-19', '2026-06-19 15:45:48'),
(2, 1, 'Transformasi ke bentuk 1NF dan 2NF', 'n', NULL, NULL, '2026-06-19 15:45:48'),
(3, 1, 'Finalisasi ke bentuk 3NF & Gambar ERD', 'n', NULL, NULL, '2026-06-19 15:45:48'),
(4, 2, 'Datang ke bengkel resmi jam 8 pagi', 'n', NULL, NULL, '2026-06-19 15:45:48'),
(5, 2, 'Ambil nota & cek hasil filter udara', 'n', NULL, NULL, '2026-06-19 15:45:48'),
(6, 3, 'Download jurnal terakreditasi sinta', 'y', '2026-06-19 15:45:48', '2026-06-19', '2026-06-19 15:45:48'),
(7, 3, 'Tulis poin penting latar belakang', 'n', NULL, NULL, '2026-06-19 15:45:48'),
(8, 4, 'Setup skema database token blacklist', 'n', NULL, NULL, '2026-06-19 15:45:48'),
(9, 4, 'Bikin middleware verifyToken', 'n', NULL, NULL, '2026-06-19 15:45:48'),
(10, 4, 'Testing login & logout via Postman', 'n', NULL, NULL, '2026-06-19 15:45:48'),
(11, 5, 'Membuat Diagram Use Case', 'n', NULL, NULL, '2026-06-19 15:45:48'),
(12, 5, 'Menyusun Bab 1 Pendahuluan', 'n', NULL, NULL, '2026-06-19 15:45:48');

-- --------------------------------------------------------

-- Table structure for table `jadwal`

CREATE TABLE `jadwal` (
  `id_jadwal` int(11) NOT NULL,
  `id_akun` int(11) NOT NULL,
  `id_kategori` int(11) DEFAULT NULL,
  `nama_jadwal` varchar(100) NOT NULL,
  `waktu_mulai` time DEFAULT NULL,
  `waktu_selesai` time DEFAULT NULL,
  `tanggal` date DEFAULT NULL,
  `timeless` enum('y','n','','') DEFAULT NULL,
  `prioritas` enum('rendah','sedang','tinggi') NOT NULL DEFAULT 'sedang',
  `status` enum('pending','selesai','terlewat') NOT NULL DEFAULT 'pending',
  `deadline` date DEFAULT NULL,
  `catatan` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table `jadwal`

INSERT INTO `jadwal` (`id_jadwal`, `id_akun`, `id_kategori`, `nama_jadwal`, `waktu_mulai`, `waktu_selesai`, `tanggal`, `timeless`, `prioritas`, `status`, `deadline`, `catatan`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 'Kuliah Basis Data', '08:00:00', '10:00:00', '2026-06-20', 'n', 'tinggi', 'pending', '2026-06-20', 'Ruang Lab 2', '2026-06-19 15:45:48', '2026-06-19 15:45:48'),
(2, 1, 3, 'Olahraga Pagi', '06:00:00', '07:00:00', '2026-06-22', 'n', 'rendah', 'pending', '2026-06-22', 'Jogging di lapangan', '2026-06-19 15:45:48', '2026-06-19 15:45:48'),
(3, 1, 1, 'Beli Bahan Makanan', NULL, NULL, '2026-06-24', 'y', 'sedang', 'pending', '2026-06-24', 'Stok bulanan minimarket', '2026-06-19 15:45:48', '2026-06-19 15:45:48'),
(4, 3, 4, 'Asistensi Praktikum', '13:00:00', '15:00:00', '2026-06-21', 'n', 'tinggi', 'pending', '2026-06-21', 'Online via Zoom', '2026-06-19 15:45:48', '2026-06-19 15:45:48'),
(5, 3, 5, 'Review Progress Project', NULL, NULL, '2026-06-25', 'y', 'sedang', 'pending', '2026-06-26', 'Cek modul auth', '2026-06-19 15:45:48', '2026-06-19 15:45:48'),
(6, 4, 6, 'Daily Standup Meeting', '09:00:00', '09:30:00', '2026-06-20', 'n', 'tinggi', 'pending', '2026-06-20', 'Bahas backlog sprint baru', '2026-06-19 15:45:48', '2026-06-19 15:45:48'),
(7, 4, 7, 'Meeting Client', '14:00:00', '16:00:00', '2026-06-23', 'n', 'tinggi', 'pending', '2026-06-23', 'Presentasi mockup UI', '2026-06-19 15:45:48', '2026-06-19 15:45:48'),
(8, 4, 6, 'Refactoring Codebase', NULL, NULL, '2026-06-27', 'y', 'sedang', 'pending', '2026-06-29', 'Rapikan fungsi utility', '2026-06-19 15:45:48', '2026-06-19 15:45:48'),
(9, 5, 8, 'Ujian Tengah Semester', '10:00:00', '12:00:00', '2026-06-21', 'n', 'tinggi', 'pending', '2026-06-21', 'Jangan terlambat!', '2026-06-19 15:45:48', '2026-06-19 15:45:48'),
(10, 5, 9, 'Sesi Gym Push Day', '16:30:00', '18:00:00', '2026-06-23', 'n', 'rendah', 'pending', '2026-06-23', 'Fokus ke dada dan bahu', '2026-06-19 15:45:48', '2026-06-19 15:45:48'),
(11, 5, 8, 'Bimbingan Akademik', '11:00:00', '12:00:00', '2026-06-28', 'n', 'sedang', 'pending', '2026-06-28', 'Bawa transkrip nilai', '2026-06-19 15:45:48', '2026-06-19 15:45:48');

-- --------------------------------------------------------

-- Table structure for table `kategori`

CREATE TABLE `kategori` (
  `id_kategori` int(11) NOT NULL,
  `id_akun` int(11) NOT NULL,
  `nama` varchar(50) NOT NULL,
  `warna` varchar(7) NOT NULL DEFAULT '#6C63FF',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table `kategori`

INSERT INTO `kategori` (`id_kategori`, `id_akun`, `nama`, `warna`, `created_at`) VALUES
(1, 1, 'Kuliah', '#6C63FF', '2026-06-19 15:45:48'),
(2, 1, 'Tugas', '#FF6584', '2026-06-19 15:45:48'),
(3, 1, 'Personal', '#43B89C', '2026-06-19 15:45:48'),
(4, 3, 'Kuliah', '#6C63FF', '2026-06-19 15:45:48'),
(5, 3, 'Tugas', '#FF6584', '2026-06-19 15:45:48'),
(6, 4, 'Kerja', '#2196F3', '2026-06-19 15:45:48'),
(7, 4, 'Project', '#9C27B0', '2026-06-19 15:45:48'),
(8, 5, 'Kuliah', '#6C63FF', '2026-06-19 15:45:48'),
(9, 5, 'Olahraga', '#4CAF50', '2026-06-19 15:45:48');

-- --------------------------------------------------------

-- Table structure for table `tugas`

CREATE TABLE `tugas` (
  `id_tugas` int(11) NOT NULL,
  `id_akun` int(11) NOT NULL,
  `id_kategori` int(11) DEFAULT NULL,
  `judul` varchar(150) NOT NULL,
  `deskripsi` text DEFAULT NULL,
  `tanggal_mulai` date NOT NULL,
  `deadline` date NOT NULL,
  `prioritas` enum('rendah','sedang','tinggi') NOT NULL DEFAULT 'sedang',
  `status` enum('pending','selesai','terlambat') NOT NULL DEFAULT 'pending',
  `persentase_selesai` int(5) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table `tugas`

INSERT INTO `tugas` (`id_tugas`, `id_akun`, `id_kategori`, `judul`, `deskripsi`, `tanggal_mulai`, `deadline`, `prioritas`, `status`, `persentase_selesai`, `created_at`, `updated_at`) VALUES
(1, 1, 2, 'Tugas Mandiri Basis Data', 'Normalisasi database relasional dari struk belanja', '2026-06-19', '2026-06-22', 'tinggi', 'pending', 33, '2026-06-19 15:45:48', '2026-06-19 15:45:48'),
(2, 1, 3, 'Service Motor Bulanan', 'Ganti oli dan cek kelistrikan', '2026-06-19', '2026-06-24', 'sedang', 'pending', 0, '2026-06-19 15:45:48', '2026-06-19 15:45:48'),
(3, 3, 5, 'Resume Jurnal IMK', 'Resume minimal 3 halaman PDF bertema UX', '2026-06-19', '2026-06-23', 'rendah', 'pending', 50, '2026-06-19 15:45:48', '2026-06-19 15:45:48'),
(4, 4, 7, 'Integrasi JWT Token Auth', 'Selesaikan skema backend token blacklisting', '2026-06-19', '2026-06-26', 'tinggi', 'pending', 0, '2026-06-19 15:45:48', '2026-06-19 15:45:48'),
(5, 5, 8, 'Tugas Besar Impal', 'Membuat dokumentasi SRS dan perancangan perangkat lunak', '2026-06-19', '2026-06-29', 'tinggi', 'pending', 0, '2026-06-19 15:45:48', '2026-06-19 15:45:48');

-- Indexes for dumped tables

-- Indexes for table `akun`
ALTER TABLE `akun`
  ADD PRIMARY KEY (`id_akun`),
  ADD UNIQUE KEY `username` (`username`),
  ADD KEY `idx_akun_username` (`username`);

-- Indexes for table `checklist`
ALTER TABLE `checklist`
  ADD PRIMARY KEY (`id_checklist`),
  ADD KEY `idx_checklist_tugas` (`id_tugas`);

-- Indexes for table `jadwal`
ALTER TABLE `jadwal`
  ADD PRIMARY KEY (`id_jadwal`),
  ADD KEY `fk_jadwal_kategori` (`id_kategori`),
  ADD KEY `idx_jadwal_akun` (`id_akun`),
  ADD KEY `idx_jadwal_status` (`status`);

-- Indexes for table `kategori`
ALTER TABLE `kategori`
  ADD PRIMARY KEY (`id_kategori`),
  ADD KEY `idx_kategori_akun` (`id_akun`);

-- Indexes for table `tugas`
ALTER TABLE `tugas`
  ADD PRIMARY KEY (`id_tugas`),
  ADD KEY `fk_tugas_kategori` (`id_kategori`),
  ADD KEY `idx_tugas_akun` (`id_akun`),
  ADD KEY `idx_tugas_deadline` (`deadline`),
  ADD KEY `idx_tugas_status` (`status`);
  
-- AUTO_INCREMENT for dumped tables

-- AUTO_INCREMENT for table `akun`
ALTER TABLE `akun`
  MODIFY `id_akun` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

-- AUTO_INCREMENT for table `checklist`
ALTER TABLE `checklist`
  MODIFY `id_checklist` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

-- AUTO_INCREMENT for table `jadwal`
ALTER TABLE `jadwal`
  MODIFY `id_jadwal` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

-- AUTO_INCREMENT for table `kategori`
ALTER TABLE `kategori`
  MODIFY `id_kategori` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

-- AUTO_INCREMENT for table `tugas`
ALTER TABLE `tugas`
  MODIFY `id_tugas` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

-- Constraints for table `checklist`
ALTER TABLE `checklist`
  ADD CONSTRAINT `fk_checklist_tugas` FOREIGN KEY (`id_tugas`) REFERENCES `tugas` (`id_tugas`) ON DELETE CASCADE ON UPDATE CASCADE;

-- Constraints for table `jadwal`
ALTER TABLE `jadwal`
  ADD CONSTRAINT `fk_jadwal_akun` FOREIGN KEY (`id_akun`) REFERENCES `akun` (`id_akun`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_jadwal_kategori` FOREIGN KEY (`id_kategori`) REFERENCES `kategori` (`id_kategori`) ON DELETE SET NULL ON UPDATE CASCADE;

-- Constraints for table `kategori`
ALTER TABLE `kategori`
  ADD CONSTRAINT `fk_kategori_akun` FOREIGN KEY (`id_akun`) REFERENCES `akun` (`id_akun`) ON DELETE CASCADE ON UPDATE CASCADE;

-- Constraints for table `tugas`
ALTER TABLE `tugas`
  ADD CONSTRAINT `fk_tugas_akun` FOREIGN KEY (`id_akun`) REFERENCES `akun` (`id_akun`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_tugas_kategori` FOREIGN KEY (`id_kategori`) REFERENCES `kategori` (`id_kategori`) ON DELETE SET NULL ON UPDATE CASCADE;
COMMIT