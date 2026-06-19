import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import 'kategori_page.dart';
import 'checklist_page.dart';

class TugasPage extends StatefulWidget {
  const TugasPage({super.key});

  @override
  State<TugasPage> createState() => _TugasPageState();
}

class _TugasPageState extends State<TugasPage> {
  List<Map<String, dynamic>> _allTugas = [];
  bool _isLoading = false;
  int _idAkun = 0;
  String? _filterPrioritas;
  String? _filterStatus;

  late DateTime _selectedDate;
  bool _filterByDate = true; 
  final ScrollController _calendarScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      const double itemWidth = 60;
      const double offset = 10 * itemWidth;
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
    _fetchTugas();
  }

  Future<void> _fetchTugas() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getTugas(_idAkun);
    setState(() {
      _allTugas = data;
      _isLoading = false;
    });
  }

  String _deadlineKey(Map<String, dynamic> item) {
    final raw = (item['deadline'] ?? '').toString();
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }

  String get _selectedKey => _selectedDate.toString().substring(0, 10);

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  List<Map<String, dynamic>> get _filteredTugas => _allTugas.where((t) {
        final prioritas = _capitalize((t['prioritas'] ?? '').toString());
        final status = (t['status'] ?? '').toString().toLowerCase();
        final matchPrioritas =
            _filterPrioritas == null || prioritas == _filterPrioritas;
        final matchStatus = _filterStatus == null || status == _filterStatus;
        final matchTanggal =
            !_filterByDate || _deadlineKey(t) == _selectedKey;
        return matchPrioritas && matchStatus && matchTanggal;
      }).toList();

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
      case 'terlambat':
        return const Color(0xFFE91E63);
      default:
        return const Color(0xFFFF9800);
    }
  }

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'selesai':
        return 'Selesai';
      case 'terlambat':
        return 'Terlambat';
      default:
        return 'Pending';
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return const Color(0xFF6C63FF);
    }
  }

  // ── Toggle status tugas ──────────────────────────
  Future<void> _toggleStatus(Map<String, dynamic> item) async {
    final localContext = context;
    final currentStatus = (item['status'] ?? 'pending').toString().toLowerCase();

    if (currentStatus == 'terlambat') {
      ScaffoldMessenger.of(localContext).showSnackBar(
        const SnackBar(
          content: Text('Tugas sudah terlambat, tidak dapat diubah'),
          backgroundColor: Color(0xFFE91E63),
        ),
      );
      return;
    }

    final newStatus = currentStatus == 'selesai' ? 'pending' : 'selesai';
    final result = await ApiService.updateTugas(
      item['idTugas'],
      {'status': newStatus},
    );

    if (result != null) {
      _fetchTugas();
      if (localContext.mounted) {
        ScaffoldMessenger.of(localContext).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'selesai'
                ? 'Tugas ditandai selesai ✓'
                : 'Tugas dikembalikan ke pending'),
            backgroundColor: const Color(0xFF2EAD65),
          ),
        );
      }
    } else if (localContext.mounted) {
      ScaffoldMessenger.of(localContext).showSnackBar(
        const SnackBar(
          content: Text('Gagal memperbarui status tugas'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ── Hapus tugas ──────────────────────────────────────────────────────
  Future<void> _deleteTugas(int idTugas) async {
    final localContext = context;
    final confirm = await showDialog<bool>(
      context: localContext,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Tugas',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Tugas dan semua checklist di dalamnya akan dihapus permanen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus',
                style: TextStyle(color: Color(0xFFE91E63))),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ApiService.deleteTugas(idTugas);
      if (!localContext.mounted) return;
      if (success) {
        _fetchTugas();
        ScaffoldMessenger.of(localContext).showSnackBar(
          const SnackBar(
            content: Text('Tugas berhasil dihapus'),
            backgroundColor: Color(0xFF2EAD65),
          ),
        );
      } else {
        ScaffoldMessenger.of(localContext).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus tugas'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // ── Form dialog tambah / edit tugas ────────────────────────────────────
  void _showFormDialog({Map<String, dynamic>? existing}) async {
    final localContext = context;
    final kategoriList = await ApiService.getKategori(_idAkun);
    if (!localContext.mounted) return;

    final judulController =
        TextEditingController(text: existing?['judul'] ?? '');
    final deskripsiController =
        TextEditingController(text: existing?['deskripsi'] ?? '');

    final rawMulai = (existing?['tanggalMulai'] ?? '').toString();
    final tanggalMulaiController = TextEditingController(
        text: rawMulai.length >= 10 ? rawMulai.substring(0, 10) : rawMulai);

    final rawDeadline = (existing?['deadline'] ?? '').toString();
    final deadlineController = TextEditingController(
        text: rawDeadline.length >= 10
            ? rawDeadline.substring(0, 10)
            : rawDeadline);

    String selectedPrioritas = existing?['prioritas'] != null
        ? _capitalize(existing!['prioritas'].toString())
        : 'Sedang';

    int? selectedKategoriId = existing?['idKategori'] as int?;
    String? formError;

    showModalBottomSheet(
      context: localContext,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
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
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  existing != null ? 'Edit Tugas' : 'Tambah Tugas',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),

                _buildInput(
                    controller: judulController,
                    hint: 'Judul Tugas',
                    icon: Icons.task_outlined),
                const SizedBox(height: 10),

                _buildInput(
                    controller: deskripsiController,
                    hint: 'Deskripsi (opsional)',
                    icon: Icons.notes_outlined,
                    maxLines: 3),
                const SizedBox(height: 10),

                _buildInput(
                  controller: tanggalMulaiController,
                  hint: 'Tanggal Mulai (Klik untuk memilih)',
                  icon: Icons.calendar_today_outlined,
                  readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: tanggalMulaiController.text.isNotEmpty
                          ? DateTime.parse(tanggalMulaiController.text)
                          : DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null) {
                      setModal(() {
                        tanggalMulaiController.text =
                            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),

                _buildInput(
                  controller: deadlineController,
                  hint: 'Deadline (Klik untuk memilih)',
                  icon: Icons.flag_outlined,
                  readOnly: true,
                  onTap: () async {
                    final firstDate = tanggalMulaiController.text.isNotEmpty
                        ? DateTime.parse(tanggalMulaiController.text)
                        : DateTime.now();
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: deadlineController.text.isNotEmpty
                          ? DateTime.parse(deadlineController.text)
                          : firstDate,
                      firstDate: firstDate,
                      lastDate: DateTime(2101),
                    );
                    if (picked != null) {
                      setModal(() {
                        deadlineController.text =
                            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),

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
                              ctx,
                              MaterialPageRoute(
                                  builder: (_) => const KategoriPage()));
                          final updated = await ApiService.getKategori(_idAkun);
                          setModal(() {
                            kategoriList
                              ..clear()
                              ..addAll(updated);
                          });
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_circle_outline,
                                size: 14, color: Color(0xFF2EAD65)),
                            SizedBox(width: 4),
                            Text('Kelola Kategori',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2EAD65))),
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
                            child: Text('Tanpa',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: selectedKategoriId == null
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selectedKategoriId == null
                                      ? Colors.white
                                      : Colors.grey,
                                )),
                          ),
                        ),
                        ...kategoriList.map((k) {
                          final kId = k['idKategori'] ?? k['id_kategori'];
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
                                  color: isSelected ? color : Colors.transparent,
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
                                        color: color, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(kNama,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected ? color : Colors.grey,
                                      )),
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
                      await Navigator.push(ctx,
                          MaterialPageRoute(builder: (_) => const KategoriPage()));
                      final updated = await ApiService.getKategori(_idAkun);
                      setModal(() {
                        kategoriList
                          ..clear()
                          ..addAll(updated);
                      });
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle_outline,
                            size: 14, color: Color(0xFF2EAD65)),
                        SizedBox(width: 4),
                        Text('Tambah Kategori',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2EAD65))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

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

                // ── Pesan error inline ──
                if (formError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.redAccent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            formError!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      setModal(() => formError = null);

                      if (judulController.text.trim().isEmpty) {
                        setModal(() =>
                            formError = 'Judul tugas tidak boleh kosong');
                        return;
                      }
                      if (tanggalMulaiController.text.trim().isEmpty) {
                        setModal(() =>
                            formError = 'Tanggal mulai tidak boleh kosong');
                        return;
                      }
                      if (deadlineController.text.trim().isEmpty) {
                        setModal(
                            () => formError = 'Deadline tidak boleh kosong');
                        return;
                      }

                      final mulaiDate =
                          DateTime.parse(tanggalMulaiController.text.trim());
                      final deadlineDate =
                          DateTime.parse(deadlineController.text.trim());
                      if (deadlineDate.isBefore(mulaiDate)) {
                        setModal(() => formError =
                            'Deadline tidak boleh sebelum tanggal mulai');
                        return;
                      }

                      final body = <String, dynamic>{
                        'judul': judulController.text.trim(),
                        'deskripsi': deskripsiController.text.trim(),
                        'tanggalMulai': tanggalMulaiController.text.trim(),
                        'deadline': deadlineController.text.trim(),
                        'prioritas': selectedPrioritas.toLowerCase(),
                      };
                      if (selectedKategoriId != null) {
                        body['idKategori'] = selectedKategoriId;
                      }

                      if (existing != null) {
                        final result = await ApiService.updateTugas(
                            existing['idTugas'], body);
                        if (!ctx.mounted) return;
                        if (result != null) {
                          Navigator.pop(ctx);
                          _fetchTugas();
                          ScaffoldMessenger.of(localContext).showSnackBar(
                            const SnackBar(
                              content: Text('Tugas berhasil diperbarui'),
                              backgroundColor: Color(0xFF2EAD65),
                            ),
                          );
                        } else {
                          setModal(
                              () => formError = 'Gagal memperbarui tugas');
                        }
                      } else {
                        final result =
                            await ApiService.tambahTugas(_idAkun, body);
                        if (!ctx.mounted) return;
                        if (result != null) {
                          Navigator.pop(ctx);
                          _fetchTugas();
                          ScaffoldMessenger.of(localContext).showSnackBar(
                            const SnackBar(
                              content: Text('Tugas berhasil ditambahkan'),
                              backgroundColor: Color(0xFF2EAD65),
                            ),
                          );
                        } else {
                          setModal(
                              () => formError = 'Gagal menambahkan tugas');
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
                      existing != null ? 'Simpan Perubahan' : 'Tambah Tugas',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
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

  void _openChecklist(Map<String, dynamic> tugas) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChecklistPage(tugas: tugas)),
    );
    _fetchTugas(); 
  }

  @override
  Widget build(BuildContext context) {
    final totalSelesai =
        _allTugas.where((t) => (t['status'] ?? '') == 'selesai').length;

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
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tugas',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    Row(
                      children: [
                        Text('$totalSelesai/${_allTugas.length} selesai',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _fetchTugas,
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
                    final isSelected = _filterByDate && dateKey == _selectedKey;
                    final hasDeadline =
                        _allTugas.any((t) => _deadlineKey(t) == dateKey);
                    final days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedDate = date;
                        _filterByDate = true;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
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
                            if (hasDeadline)
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
              const SizedBox(height: 16),

              // ── Progress bar total tugas selesai ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _allTugas.isEmpty
                        ? 0
                        : totalSelesai / _allTugas.length,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── List Tugas ──
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
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
                      // ── Label tanggal terpilih + toggle "lihat semua" ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _filterByDate
                                ? 'Deadline: $_selectedKey'
                                : 'Semua Tugas',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54),
                          ),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _filterByDate = !_filterByDate),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _filterByDate
                                    ? const Color(0xFFF0F2F5)
                                    : const Color(0xFF2EAD65)
                                        .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _filterByDate ? 'Lihat Semua' : 'Per Tanggal',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _filterByDate
                                        ? Colors.grey
                                        : const Color(0xFF2EAD65)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Filter bar ──
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _filterChip(
                                label: 'Semua',
                                active: _filterPrioritas == null &&
                                    _filterStatus == null,
                                onTap: () => setState(() {
                                      _filterPrioritas = null;
                                      _filterStatus = null;
                                    })),
                            _filterChip(
                                label: 'Tinggi',
                                color: const Color(0xFFE91E63),
                                active: _filterPrioritas == 'Tinggi',
                                onTap: () => setState(() {
                                      _filterPrioritas =
                                          _filterPrioritas == 'Tinggi'
                                              ? null
                                              : 'Tinggi';
                                      _filterStatus = null;
                                    })),
                            _filterChip(
                                label: 'Sedang',
                                color: const Color(0xFFFF9800),
                                active: _filterPrioritas == 'Sedang',
                                onTap: () => setState(() {
                                      _filterPrioritas =
                                          _filterPrioritas == 'Sedang'
                                              ? null
                                              : 'Sedang';
                                      _filterStatus = null;
                                    })),
                            _filterChip(
                                label: 'Rendah',
                                color: const Color(0xFF2EAD65),
                                active: _filterPrioritas == 'Rendah',
                                onTap: () => setState(() {
                                      _filterPrioritas =
                                          _filterPrioritas == 'Rendah'
                                              ? null
                                              : 'Rendah';
                                      _filterStatus = null;
                                    })),
                            _filterChip(
                                label: 'Selesai',
                                color: const Color(0xFF2EAD65),
                                active: _filterStatus == 'selesai',
                                onTap: () => setState(() {
                                      _filterStatus =
                                          _filterStatus == 'selesai'
                                              ? null
                                              : 'selesai';
                                      _filterPrioritas = null;
                                    })),
                            _filterChip(
                                label: 'Pending',
                                color: const Color(0xFFFF9800),
                                active: _filterStatus == 'pending',
                                onTap: () => setState(() {
                                      _filterStatus =
                                          _filterStatus == 'pending'
                                              ? null
                                              : 'pending';
                                      _filterPrioritas = null;
                                    })),
                            _filterChip(
                                label: 'Terlambat',
                                color: const Color(0xFFE91E63),
                                active: _filterStatus == 'terlambat',
                                onTap: () => setState(() {
                                      _filterStatus =
                                          _filterStatus == 'terlambat'
                                              ? null
                                              : 'terlambat';
                                      _filterPrioritas = null;
                                    })),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── List ──
                      Expanded(
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFF2EAD65)))
                            : _filteredTugas.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.checklist_rounded,
                                            size: 56,
                                            color: Colors.grey[300]),
                                        const SizedBox(height: 12),
                                        Text('Belum ada tugas',
                                            style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 14)),
                                        if (_filterByDate) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                              'dengan deadline $_selectedKey',
                                              style: TextStyle(
                                                  color: Colors.grey[350],
                                                  fontSize: 12)),
                                        ],
                                      ],
                                    ),
                                  )
                                : RefreshIndicator(
                                    color: const Color(0xFF2EAD65),
                                    onRefresh: _fetchTugas,
                                    child: ListView.separated(
                                      padding:
                                          const EdgeInsets.only(bottom: 100),
                                      itemCount: _filteredTugas.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 12),
                                      itemBuilder: (_, i) =>
                                          _buildTugasCard(_filteredTugas[i]),
                                    ),
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

  Widget _filterChip({
    required String label,
    required bool active,
    Color color = const Color(0xFF2EAD65),
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.12) : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? color : Colors.transparent, width: 1.5),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: active ? color : Colors.grey,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
      ),
    );
  }

  Widget _buildTugasCard(Map<String, dynamic> item) {
    final idTugas = item['idTugas'] ?? 0;
    final judul = item['judul'] ?? '';
    final deskripsi = item['deskripsi'] ?? '';
    final prioritas = _capitalize((item['prioritas'] ?? 'sedang').toString());
    final statusRaw = (item['status'] ?? 'pending').toString();
    final status = statusRaw.toLowerCase();
    final tanggalMulai = (item['tanggalMulai'] ?? '').toString();
    final deadline = (item['deadline'] ?? '').toString();
    final persen = (item['persentaseSelesai'] ?? 0) as num;
    final namaKategori = item['namaKategori'] ?? '';
    final warnaKategori = item['warnaKategori'] ?? '';

    final isSelesai = status == 'selesai';
    final isTerlambat = status == 'terlambat';
    final color = _priorityColor(prioritas);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelesai ? const Color(0xFFF5F6FA) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _toggleStatus(item),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: isSelesai ? const Color(0xFF2EAD65) : Colors.white,
                    border: Border.all(
                      color: isSelesai
                          ? const Color(0xFF2EAD65)
                          : (isTerlambat
                              ? const Color(0xFFE91E63).withValues(alpha: 0.4)
                              : Colors.grey.shade300),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isSelesai
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(judul,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: isSelesai || isTerlambat
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: isTerlambat
                              ? const Color(0xFFE91E63).withValues(alpha: 0.7)
                              : isSelesai
                                  ? Colors.black38
                                  : Colors.black87,
                        )),
                    if (deskripsi.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(deskripsi,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              color: isSelesai
                                  ? Colors.grey[350]
                                  : Colors.black45)),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isTerlambat || isSelesai
                                    ? Colors.grey
                                    : color)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(prioritas,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isTerlambat || isSelesai
                                      ? Colors.grey
                                      : color,
                                  fontWeight: FontWeight.w500)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _statusColor(statusRaw)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_statusLabel(statusRaw),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: _statusColor(statusRaw),
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                    if (namaKategori.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
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
                            Text(namaKategori,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: isSelesai
                                        ? Colors.grey
                                        : Colors.black45,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          if (tanggalMulai.isNotEmpty) ...[
                            Icon(Icons.play_circle_outline,
                                size: 12,
                                color: isSelesai
                                    ? Colors.grey
                                    : Colors.black38),
                            const SizedBox(width: 4),
                            Text(
                                tanggalMulai.length >= 10
                                    ? tanggalMulai.substring(0, 10)
                                    : tanggalMulai,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: isSelesai
                                        ? Colors.grey
                                        : Colors.black38)),
                            const SizedBox(width: 10),
                          ],
                          if (deadline.isNotEmpty) ...[
                            Icon(Icons.flag_outlined,
                                size: 12,
                                color: isTerlambat
                                    ? const Color(0xFFE91E63)
                                    : isSelesai
                                        ? Colors.grey
                                        : Colors.black38),
                            const SizedBox(width: 4),
                            Text(
                                deadline.length >= 10
                                    ? deadline.substring(0, 10)
                                    : deadline,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: isTerlambat
                                        ? const Color(0xFFE91E63)
                                        : isSelesai
                                            ? Colors.grey
                                            : Colors.black38)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    onPressed: () => _showFormDialog(existing: item),
                    icon: const Icon(Icons.edit_outlined,
                        size: 18, color: Colors.black38),
                  ),
                  IconButton(
                    onPressed: () => _deleteTugas(idTugas),
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Colors.redAccent),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Progress bar checklist ──
          GestureDetector(
            onTap: () => _openChecklist(item),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: persen / 100.0,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE8E8E8),
                      color: isSelesai ? Colors.grey : const Color(0xFF2EAD65),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${persen.toInt()}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color:
                            isSelesai ? Colors.grey : const Color(0xFF2EAD65))),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right,
                    size: 16,
                    color: isSelesai ? Colors.grey : const Color(0xFF2EAD65)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(maxLines > 1 ? 16 : 30),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.grey[400], size: 18),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}