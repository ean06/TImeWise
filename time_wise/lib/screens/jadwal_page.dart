import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';
import 'kategori_page.dart';

class JadwalPage extends StatefulWidget {
  final DateTime? initialDate;

  const JadwalPage({super.key, this.initialDate});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  late DateTime _selectedDate;
  List<Map<String, dynamic>> _allJadwal = [];
  bool _isLoading = false;
  int _idAkun = 0;
  String? _filterPrioritas;
  final ScrollController _calendarScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final today = DateTime.now();
      final todayKey = today.toString().substring(0, 10);
      final selectedKey = _selectedDate.toString().substring(0, 10);
      final diff = DateTime.parse(todayKey)
          .difference(DateTime.parse(selectedKey))
          .inDays;
      final targetIndex = 10 - diff;
      const double itemWidth = 60;
      final double offset =
          (targetIndex * itemWidth).clamp(0.0, double.infinity);
      _calendarScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _calendarScrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _idAkun = await SessionService.getIdAkun();
    _fetchJadwal();
  }

  Future<void> _fetchJadwal() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getJadwal(_idAkun);
    setState(() {
      _allJadwal = data;
      _isLoading = false;
    });
  }

  String _tanggalKey(Map<String, dynamic> item) {
    final raw = item['tanggal'] ?? '';
    final s = raw.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  int _idJadwal(Map<String, dynamic> item) {
    final raw = item['id_jadwal'] ?? item['idJadwal'] ?? 0;
    return raw is int ? raw : int.tryParse(raw.toString()) ?? 0;
  }

  String get _selectedKey => _selectedDate.toString().substring(0, 10);

  List<Map<String, dynamic>> get _selectedJadwal => _allJadwal
      .where((j) =>
          _tanggalKey(j) == _selectedKey &&
          (_filterPrioritas == null ||
              _capitalize((j['prioritas'] ?? '').toString()) ==
                  _filterPrioritas))
      .toList();

  Color _priorityColor(String p) {
    switch (p) {
      case 'Tinggi':
        return const Color(0xFFE91E63);
      case 'Sedang':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF2EAD65);
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'selesai':
        return const Color(0xFF2EAD65);
      case 'terlewat':
        return const Color(0xFFE91E63);
      default:
        return const Color(0xFFFF9800);
    }
  }

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'selesai':
        return 'Selesai';
      case 'terlewat':
        return 'Terlewat';
      default:
        return 'Pending';
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  // ── Toggle status jadwal ──────────────────────────────────────────────
  Future<void> _toggleStatus(Map<String, dynamic> item) async {
    final localContext = context;
    final currentStatus = (item['status'] ?? 'pending').toString().toLowerCase();

    // Jika sudah terlewat, tidak bisa diubah via checklist
    if (currentStatus == 'terlewat') {
      if (localContext.mounted) {
        ScaffoldMessenger.of(localContext).showSnackBar(
          const SnackBar(
            content: Text('Jadwal sudah terlewat, tidak dapat diubah'),
            backgroundColor: Color(0xFFE91E63),
          ),
        );
      }
      return;
    }

    final newStatus = currentStatus == 'selesai' ? 'pending' : 'selesai';

    final success = await ApiService.updateJadwal(
      _idJadwal(item),
      {'status': newStatus},
    );

    if (success) {
      _fetchJadwal();
      if (localContext.mounted) {
        ScaffoldMessenger.of(localContext).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'selesai'
                ? 'Jadwal ditandai selesai ✓'
                : 'Jadwal dikembalikan ke pending'),
            backgroundColor: const Color(0xFF2EAD65),
          ),
        );
      }
    }
  }

  // ── Form dialog tambah / edit ─────────────────────────────────────────
  void _showFormDialog({Map<String, dynamic>? existing}) async {
    final localContext = context;
    // Load kategori dari backend
    final kategoriList = await ApiService.getKategori(_idAkun);

    if (!localContext.mounted) return;

    final namaController = TextEditingController(
        text: existing?['nama_jadwal'] ?? existing?['namaJadwal'] ?? '');

    final rawTanggal = (existing?['tanggal'] ?? _selectedKey).toString();
    final tanggalController = TextEditingController(
        text: rawTanggal.length >= 10
            ? rawTanggal.substring(0, 10)
            : rawTanggal);

    final rawWaktu = (existing?['waktu_mulai'] ?? '').toString();
    final waktuController = TextEditingController(
        text: rawWaktu.length >= 5 ? rawWaktu.substring(0, 5) : rawWaktu);

    final rawWaktuSelesai = (existing?['waktu_selesai'] ?? '').toString();
    final waktuSelesaiController = TextEditingController(
        text: rawWaktuSelesai.length >= 5
            ? rawWaktuSelesai.substring(0, 5)
            : rawWaktuSelesai);

    final rawDeadline = (existing?['deadline'] ?? '').toString();
    final deadlineController = TextEditingController(
        text: rawDeadline.length >= 10
            ? rawDeadline.substring(0, 10)
            : rawDeadline);

    final catatanController =
        TextEditingController(text: existing?['catatan'] ?? '');

    String selectedPrioritas = existing?['prioritas'] != null
        ? _capitalize(existing!['prioritas'].toString())
        : 'Sedang';

    bool isTimeless = existing != null &&
        (existing['waktu_mulai'] == null ||
            existing['waktu_mulai'].toString().isEmpty) &&
        (existing['waktu_selesai'] == null ||
            existing['waktu_selesai'].toString().isEmpty);

    int? selectedKategoriId = existing?['id_kategori'] as int?;

    showModalBottomSheet(
      context: localContext,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  existing != null ? 'Edit Jadwal' : 'Tambah Jadwal',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),

                // ── Nama kegiatan ──
                _buildInput(
                    controller: namaController,
                    hint: 'Nama Kegiatan',
                    icon: Icons.event_outlined),
                const SizedBox(height: 10),

                // ── Tanggal kegiatan ──
                _buildInput(
                  controller: tanggalController,
                  hint: 'Tanggal Kegiatan (Klik untuk memilih)',
                  icon: Icons.calendar_today_outlined,
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: tanggalController.text.isNotEmpty
                          ? DateTime.parse(tanggalController.text)
                          : DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      final String formattedDate =
                          '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
                      setModal(() {
                        tanggalController.text = formattedDate;
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),

                // ── Timeless toggle ──
                GestureDetector(
                  onTap: () => setModal(() {
                    isTimeless = !isTimeless;
                    if (isTimeless) {
                      waktuController.clear();
                      waktuSelesaiController.clear();
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isTimeless
                          ? const Color(0xFF2EAD65).withValues(alpha: 0.08)
                          : const Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isTimeless
                            ? const Color(0xFF2EAD65)
                            : const Color(0xFFE8E8E8),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.all_inclusive_rounded,
                          size: 18,
                          color: isTimeless
                              ? const Color(0xFF2EAD65)
                              : Colors.grey[400],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Timeless',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isTimeless
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isTimeless
                                ? const Color(0xFF2EAD65)
                                : Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 10),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isTimeless
                                ? const Color(0xFF2EAD65)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isTimeless
                                  ? const Color(0xFF2EAD65)
                                  : Colors.grey.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: isTimeless
                              ? const Icon(Icons.check,
                                  size: 13, color: Colors.white)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Waktu mulai ──
                _buildInput(
                  controller: waktuController,
                  hint: 'Waktu Mulai (Klik untuk memilih)',
                  icon: Icons.access_time,
                  readOnly: true,
                  enabled: !isTimeless,
                  onTap: () async {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: waktuController.text.isNotEmpty
                          ? TimeOfDay(
                              hour: int.parse(
                                  waktuController.text.split(':')[0]),
                              minute: int.parse(
                                  waktuController.text.split(':')[1]),
                            )
                          : TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      final String formattedTime =
                          '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
                      setModal(() {
                        waktuController.text = formattedTime;
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),

                // ── Waktu selesai ──
                _buildInput(
                  controller: waktuSelesaiController,
                  hint: 'Waktu Selesai (Klik untuk memilih)',
                  icon: Icons.access_time_filled,
                  readOnly: true,
                  enabled: !isTimeless,
                  onTap: () async {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: waktuSelesaiController.text.isNotEmpty
                          ? TimeOfDay(
                              hour: int.parse(
                                  waktuSelesaiController.text.split(':')[0]),
                              minute: int.parse(
                                  waktuSelesaiController.text.split(':')[1]),
                            )
                          : TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      final String formattedTime =
                          '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
                      setModal(() {
                        waktuSelesaiController.text = formattedTime;
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),

                // ── Deadline ──
                _buildInput(
                  controller: deadlineController,
                  hint: 'Deadline (Klik untuk memilih)',
                  icon: Icons.flag_outlined,
                  readOnly: true,
                  onTap: () async {
                    final firstDate = tanggalController.text.isNotEmpty
                        ? DateTime.parse(tanggalController.text)
                        : _selectedDate;
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: deadlineController.text.isNotEmpty
                          ? DateTime.parse(deadlineController.text)
                          : firstDate,
                      firstDate: firstDate,
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      final String formattedDate =
                          '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
                      setModal(() {
                        deadlineController.text = formattedDate;
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),

                // ── Catatan ──
                _buildInput(
                  controller: catatanController,
                  hint: 'Catatan (opsional)',
                  icon: Icons.notes_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 14),

                // ── Kategori dropdown ──
                if (kategoriList.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Kategori',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const KategoriPage(),
                            ),
                          );
                          final updatedKategori =
                              await ApiService.getKategori(_idAkun);
                          setModal(() {
                            kategoriList
                              ..clear()
                              ..addAll(updatedKategori);
                          });
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_circle_outline,
                                size: 14, color: Color(0xFF2EAD65)),
                            SizedBox(width: 4),
                            Text(
                              'Kelola Kategori',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2EAD65),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Option "Tanpa Kategori"
                        GestureDetector(
                          onTap: () =>
                              setModal(() => selectedKategoriId = null),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selectedKategoriId == null
                                  ? const Color(0xFF2EAD65)
                                  : const Color(0xFFF0F2F5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selectedKategoriId == null
                                    ? const Color(0xFF2EAD65)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              'Tanpa',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: selectedKategoriId == null
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selectedKategoriId == null
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        ...kategoriList.map((k) {
                          final kId = k['id_kategori'] as int;
                          final kNama = k['nama'] ?? '';
                          final kWarna = k['warna'] ?? '#6C63FF';
                          final color = _hexToColor(kWarna);
                          final isSelected = selectedKategoriId == kId;
                          return GestureDetector(
                            onTap: () =>
                                setModal(() => selectedKategoriId = kId),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withValues(alpha: 0.15)
                                    : const Color(0xFFF0F2F5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      isSelected ? color : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    kNama,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected ? color : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ] else ...[
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const KategoriPage(),
                        ),
                      );
                      final updatedKategori =
                          await ApiService.getKategori(_idAkun);
                      setModal(() {
                        kategoriList
                          ..clear()
                          ..addAll(updatedKategori);
                      });
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle_outline,
                            size: 14, color: Color(0xFF2EAD65)),
                        SizedBox(width: 4),
                        Text(
                          'Tambah Kategori',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2EAD65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // ── Prioritas ──
                const Text('Prioritas',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: ['Tinggi', 'Sedang', 'Rendah'].map((p) {
                    final isSelected = selectedPrioritas == p;
                    final color = _priorityColor(p);
                    return GestureDetector(
                      onTap: () => setModal(() => selectedPrioritas = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.12)
                              : const Color(0xFFF0F2F5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isSelected ? color : Colors.transparent,
                              width: 1.5),
                        ),
                        child: Text(p,
                            style: TextStyle(
                                fontSize: 13,
                                color: isSelected ? color : Colors.grey,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // ── Tombol simpan ──
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Validasi nama kegiatan
                      if (namaController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Nama kegiatan tidak boleh kosong'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      // Validasi tanggal kegiatan
                      if (tanggalController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Tanggal kegiatan tidak boleh kosong'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      // Validasi waktu: selesai harus setelah mulai
                      if (waktuController.text.isNotEmpty &&
                          waktuSelesaiController.text.isNotEmpty) {
                        final mulaiParts =
                            waktuController.text.split(':');
                        final selesaiParts =
                            waktuSelesaiController.text.split(':');
                        final mulaiMinutes =
                            int.parse(mulaiParts[0]) * 60 +
                                int.parse(mulaiParts[1]);
                        final selesaiMinutes =
                            int.parse(selesaiParts[0]) * 60 +
                                int.parse(selesaiParts[1]);

                        if (selesaiMinutes <= mulaiMinutes) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Waktu selesai harus setelah waktu mulai'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                      }

                      // Validasi deadline: harus >= tanggal jadwal
                      if (deadlineController.text.isNotEmpty &&
                          tanggalController.text.isNotEmpty) {
                        final deadlineDate =
                            DateTime.parse(deadlineController.text);
                        final jadwalDate =
                            DateTime.parse(tanggalController.text);
                        if (deadlineDate.isBefore(jadwalDate)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Deadline tidak boleh sebelum tanggal jadwal'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                      }

                      final waktuMulai = waktuController.text.isEmpty
                          ? null
                          : '${waktuController.text.trim()}:00';
                      final waktuSelesai =
                          waktuSelesaiController.text.isEmpty
                              ? null
                              : '${waktuSelesaiController.text.trim()}:00';
                      final deadline = deadlineController.text.isEmpty
                          ? null
                          : deadlineController.text.trim();
                      final catatan = catatanController.text.trim().isEmpty
                          ? null
                          : catatanController.text.trim();

                      final body = <String, dynamic>{
                        'namaJadwal': namaController.text.trim(),
                        'tanggal': tanggalController.text.trim(),
                        'waktuMulai': waktuMulai,
                        'waktuSelesai': waktuSelesai,
                        'prioritas': selectedPrioritas.toLowerCase(),
                        'timeless': waktuMulai == null ? 'y' : 'n',
                        'deadline': deadline,
                        'catatan': catatan,
                        'idAkun': _idAkun,
                      };

                      if (selectedKategoriId != null) {
                        body['idKategori'] = selectedKategoriId;
                      }

                      if (existing != null) {
                        final success = await ApiService.updateJadwal(
                            _idJadwal(existing), body);

                        if (!localContext.mounted) return;
                        if (success) {
                          Navigator.pop(localContext);
                          _fetchJadwal();

                          // Reschedule notification
                          if (waktuMulai != null) {
                            NotificationService.scheduleJadwal(
                              idJadwal: _idJadwal(existing),
                              namaJadwal: namaController.text.trim(),
                              tanggal: tanggalController.text.trim(),
                              waktu: waktuMulai,
                            );
                          }

                          ScaffoldMessenger.of(localContext).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Jadwal berhasil diperbarui'),
                              backgroundColor: Color(0xFF2EAD65),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(localContext).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Gagal memperbarui jadwal'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      } else {
                        final result =
                            await ApiService.tambahJadwal(body);

                        if (!localContext.mounted) return;
                        if (result['status'] == 'success') {
                          Navigator.pop(localContext);
                          _fetchJadwal();

                          // Schedule notification untuk jadwal baru
                          if (waktuMulai != null) {
                            // Gunakan timestamp sementara sebagai ID
                            NotificationService.scheduleJadwal(
                              idJadwal:
                                  DateTime.now().millisecondsSinceEpoch %
                                      100000,
                              namaJadwal: namaController.text.trim(),
                              tanggal: tanggalController.text.trim(),
                              waktu: waktuMulai,
                            );
                          }

                          ScaffoldMessenger.of(localContext).showSnackBar(
                            SnackBar(
                              content: Text(result['displaced'] != null
                                  ? 'Jadwal ditambahkan (menggantikan "${result['displaced']}")'
                                  : 'Jadwal berhasil ditambahkan'),
                              backgroundColor:
                                  const Color(0xFF2EAD65),
                            ),
                          );
                        } else if (result['status'] == 'conflict') {
                          ScaffoldMessenger.of(localContext).showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ??
                                  'Jadwal bertabrakan dengan jadwal lain'),
                              backgroundColor: Colors.orange,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(localContext).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Gagal menyimpan jadwal'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2EAD65),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    child: Text(
                      existing != null
                          ? 'Simpan Perubahan'
                          : 'Tambah Jadwal',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Hapus jadwal ──────────────────────────────────────────────────────
  Future<void> _deleteJadwal(int idJadwal) async {
    final localContext = context;
    final confirm = await showDialog<bool>(
      context: localContext,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Jadwal'),
        content: const Text('Yakin ingin menghapus jadwal ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(localContext, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(localContext, true),
              child: const Text('Hapus',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true) {
      final success = await ApiService.deleteJadwal(idJadwal);
      if (success) {
        // Cancel scheduled notification
        NotificationService.cancelJadwal(idJadwal);
        _fetchJadwal();
        if (localContext.mounted) {
          ScaffoldMessenger.of(localContext).showSnackBar(
            const SnackBar(
              content: Text('Jadwal dihapus'),
              backgroundColor: Color(0xFF2EAD65),
            ),
          );
        }
      } else if (localContext.mounted) {
        ScaffoldMessenger.of(localContext).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus jadwal'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5EE09A), Color(0xFF2EAD65)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Jadwal',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    Row(
                      children: [
                        Text('${_allJadwal.length} total',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _fetchJadwal,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.refresh,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Kalender horizontal ──
              SizedBox(
                height: 80,
                child: ListView.builder(
                  controller: _calendarScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 30,
                  itemBuilder: (_, i) {
                    final date =
                        DateTime.now().subtract(Duration(days: 10 - i));
                    final dateKey = date.toString().substring(0, 10);
                    final isSelected = dateKey == _selectedKey;
                    final hasEvent =
                        _allJadwal.any((j) => _tanggalKey(j) == dateKey);

                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedDate = date),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin:
                            const EdgeInsets.symmetric(horizontal: 4),
                        width: 52,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              days[date.weekday % 7],
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected
                                      ? const Color(0xFF2EAD65)
                                      : Colors.white,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? const Color(0xFF2EAD65)
                                      : Colors.white),
                            ),
                            if (hasEvent)
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF2EAD65)
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ── List Jadwal ──
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_selectedKey,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54)),
                          Text(
                              '${_selectedJadwal.length} kegiatan',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black38)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Filter Prioritas ──
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            null,
                            'Tinggi',
                            'Sedang',
                            'Rendah'
                          ].map((p) {
                            final isAll = p == null;
                            final isSelected = _filterPrioritas == p;
                            final color = isAll
                                ? const Color(0xFF2EAD65)
                                : _priorityColor(p);
                            return GestureDetector(
                              onTap: () => setState(
                                  () => _filterPrioritas = p),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 200),
                                margin:
                                    const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? color
                                      : const Color(0xFFF0F2F5),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? color
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  isAll ? 'Semua' : p,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Expanded(
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFF2EAD65)))
                            : _selectedJadwal.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                            Icons
                                                .calendar_today_outlined,
                                            size: 52,
                                            color: Colors.grey[300]),
                                        const SizedBox(height: 12),
                                        const Text(
                                            'Tidak ada jadwal',
                                            style: TextStyle(
                                                color: Colors.black38,
                                                fontSize: 14)),
                                        const SizedBox(height: 4),
                                        const Text(
                                            'Tap + untuk menambahkan',
                                            style: TextStyle(
                                                color: Colors.black26,
                                                fontSize: 12)),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount:
                                        _selectedJadwal.length,
                                    separatorBuilder: (_, index) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (_, i) {
                                      final item =
                                          _selectedJadwal[i];
                                      return _buildJadwalCard(item);
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        backgroundColor: const Color(0xFF2EAD65),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ── Jadwal card widget ────────────────────────────────────────────────
  Widget _buildJadwalCard(Map<String, dynamic> item) {
    final namaJadwal =
        item['nama_jadwal'] ?? item['namaJadwal'] ?? '';
    final prioritasRaw = (item['prioritas'] ?? '').toString();
    final prioritas = _capitalize(prioritasRaw);
    final color = _priorityColor(prioritas);
    final waktu = (item['waktu_mulai'] ?? '').toString();
    final waktuSelesai = (item['waktu_selesai'] ?? '').toString();
    final waktuDisplay = waktu.isEmpty
        ? 'Sepanjang hari'
        : (waktu.length >= 5 ? waktu.substring(0, 5) : waktu);
    final waktuSelesaiDisplay = waktuSelesai.isNotEmpty && waktuSelesai.length >= 5
        ? ' - ${waktuSelesai.substring(0, 5)}'
        : '';
    final deadline = (item['deadline'] ?? '').toString();
    final catatan = (item['catatan'] ?? '').toString();
    final statusRaw = (item['status'] ?? 'pending').toString();
    final namaKategori = (item['nama_kategori'] ?? '').toString();
    final warnaKategori = (item['warna_kategori'] ?? '').toString();
    final idJadwal = _idJadwal(item);
    final isSelesai = statusRaw.toLowerCase() == 'selesai';
    final isTerlewat = statusRaw.toLowerCase() == 'terlewat';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTerlewat
            ? const Color(0xFFE91E63).withValues(alpha: 0.04)
            : isSelesai
                ? Colors.grey.withValues(alpha: 0.06)
                : color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isTerlewat
                ? const Color(0xFFE91E63).withValues(alpha: 0.2)
                : isSelesai
                    ? Colors.grey.withValues(alpha: 0.2)
                    : color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Status toggle — nonaktif jika terlewat
          GestureDetector(
            onTap: isTerlewat ? null : () => _toggleStatus(item),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelesai
                    ? const Color(0xFF2EAD65)
                    : isTerlewat
                        ? const Color(0xFFE91E63).withValues(alpha: 0.15)
                        : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelesai
                      ? const Color(0xFF2EAD65)
                      : isTerlewat
                          ? const Color(0xFFE91E63).withValues(alpha: 0.4)
                          : Colors.grey.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: isSelesai
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : isTerlewat
                      ? const Icon(Icons.close, size: 14,
                          color: Color(0xFFE91E63))
                      : null,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 4,
            height: 52,
            decoration: BoxDecoration(
              color: isTerlewat
                  ? const Color(0xFFE91E63).withValues(alpha: 0.5)
                  : isSelesai
                      ? Colors.grey
                      : color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaJadwal,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    decoration: isSelesai || isTerlewat
                        ? TextDecoration.lineThrough
                        : null,
                    color: isTerlewat
                        ? const Color(0xFFE91E63).withValues(alpha: 0.7)
                        : isSelesai
                            ? Colors.grey
                            : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 12,
                        color: isTerlewat
                            ? const Color(0xFFE91E63).withValues(alpha: 0.5)
                            : isSelesai
                                ? Colors.grey
                                : Colors.black38),
                    const SizedBox(width: 4),
                    Text('$waktuDisplay$waktuSelesaiDisplay',
                        style: TextStyle(
                            fontSize: 12,
                            color: isTerlewat
                                ? const Color(0xFFE91E63).withValues(alpha: 0.5)
                                : isSelesai
                                    ? Colors.grey
                                    : Colors.black45)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isTerlewat || isSelesai
                            ? Colors.grey.withValues(alpha: 0.12)
                            : color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        prioritas,
                        style: TextStyle(
                            fontSize: 10,
                            color: isTerlewat || isSelesai ? Colors.grey : color,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusColor(statusRaw)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusLabel(statusRaw),
                        style: TextStyle(
                            fontSize: 10,
                            color: _statusColor(statusRaw),
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                // Kategori badge
                if (namaKategori.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        if (warnaKategori.isNotEmpty)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: _hexToColor(warnaKategori),
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          namaKategori,
                          style: TextStyle(
                              fontSize: 11,
                              color: isSelesai
                                  ? Colors.grey
                                  : Colors.black45,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                // Deadline
                if (deadline.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.flag_outlined,
                            size: 12,
                            color: isSelesai
                                ? Colors.grey
                                : Colors.black38),
                        const SizedBox(width: 4),
                        Text(
                          'Deadline: ${deadline.length >= 10 ? deadline.substring(0, 10) : deadline}',
                          style: TextStyle(
                              fontSize: 11,
                              color: isSelesai
                                  ? Colors.grey
                                  : Colors.black38),
                        ),
                      ],
                    ),
                  ),
                // Catatan
                if (catatan.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.notes_outlined,
                            size: 12,
                            color: isSelesai
                                ? Colors.grey
                                : Colors.black38),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            catatan,
                            style: TextStyle(
                                fontSize: 11,
                                color: isSelesai
                                    ? Colors.grey
                                    : Colors.black38),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () =>
                    _showFormDialog(existing: item),
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: Colors.black38),
              ),
              IconButton(
                onPressed: () =>
                    _deleteJadwal(idJadwal),
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Colors.redAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFF5F6FA) : const Color(0xFFE0E0E0).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(maxLines > 1 ? 16 : 30),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly || !enabled,
        onTap: enabled ? onTap : null,
        maxLines: maxLines,
        enabled: enabled,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(color: enabled ? Colors.grey[400] : Colors.grey[500], fontSize: 14),
          prefixIcon:
              Icon(icon, color: enabled ? Colors.grey[400] : Colors.grey[500], size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}