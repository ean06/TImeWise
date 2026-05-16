import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _allJadwal = [];
  bool _isLoading = false;
  int _idAkun = 0;

  @override
  void initState() {
    super.initState();
    _init();
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

  String get _selectedKey =>
      _selectedDate.toString().substring(0, 10);

  List<Map<String, dynamic>> get _selectedJadwal => _allJadwal
      .where((j) =>
          (j['tanggal'] ?? '').toString().substring(0, 10) ==
          _selectedKey)
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

  void _showFormDialog({Map<String, dynamic>? existing}) {
    final namaController =
        TextEditingController(text: existing?['namaJadwal'] ?? '');
    final waktuController = TextEditingController(
        text: existing != null
            ? (existing['waktu'] ?? '').toString().substring(0, 5)
            : '');
    final deadlineController = TextEditingController(
        text: existing != null
            ? (existing['deadline'] ?? '').toString().substring(0, 10)
            : '');
    String selectedPrioritas = existing?['prioritas'] ?? 'Sedang';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24,
              MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existing != null ? 'Edit Jadwal' : 'Tambah Jadwal',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _buildInput(
                  controller: namaController,
                  hint: 'Nama Kegiatan',
                  icon: Icons.event_outlined),
              const SizedBox(height: 10),
              _buildInput(
                  controller: waktuController,
                  hint: 'Waktu (cth: 09:00)',
                  icon: Icons.access_time),
              const SizedBox(height: 10),
              _buildInput(
                  controller: deadlineController,
                  hint: 'Deadline (cth: 2025-12-31)',
                  icon: Icons.flag_outlined),
              const SizedBox(height: 12),
              const Text('Prioritas',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: ['Tinggi', 'Sedang', 'Rendah'].map((p) {
                  final isSelected = selectedPrioritas == p;
                  final color = _priorityColor(p);
                  return GestureDetector(
                    onTap: () =>
                        setModal(() => selectedPrioritas = p),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.15)
                            : const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isSelected
                                ? color
                                : Colors.transparent),
                      ),
                      child: Text(p,
                          style: TextStyle(
                              fontSize: 13,
                              color: isSelected ? color : Colors.grey,
                              fontWeight: FontWeight.w500)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (namaController.text.isEmpty) return;

                    final waktu = waktuController.text.isEmpty
                        ? '00:00:00'
                        : '${waktuController.text}:00';
                    final deadline = deadlineController.text.isEmpty
                        ? _selectedKey
                        : deadlineController.text;

                    final body = {
                      'namaJadwal': namaController.text,
                      'tanggal': _selectedKey,
                      'waktu': waktu,
                      'prioritas': selectedPrioritas,
                      'deadline': deadline,
                      'idAkun': _idAkun,
                    };

                    bool success;
                    if (existing != null) {
                      success = await ApiService.updateJadwal(
                          existing['idJadwal'], body);
                    } else {
                      success = await ApiService.tambahJadwal(body);
                    }

                    if (success && mounted) {
                      Navigator.pop(context);
                      _fetchJadwal();
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gagal menyimpan jadwal'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2EAD65),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: const Text('Simpan',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteJadwal(int idJadwal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Jadwal'),
        content: const Text('Yakin ingin menghapus jadwal ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true) {
      final success = await ApiService.deleteJadwal(idJadwal);
      if (success) {
        _fetchJadwal();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus jadwal'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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
              // Header
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
                              color: Colors.white.withOpacity(0.2),
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

              // Kalender horizontal
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 30,
                  itemBuilder: (_, i) {
                    final date = DateTime.now()
                        .subtract(Duration(days: 10 - i));
                    final dateKey =
                        date.toString().substring(0, 10);
                    final isSelected = dateKey == _selectedKey;
                    final hasEvent = _allJadwal.any((j) =>
                        (j['tanggal'] ?? '')
                            .toString()
                            .substring(0, 10) ==
                        dateKey);

                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedDate = date),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 4),
                        width: 52,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
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
                                margin:
                                    const EdgeInsets.only(top: 2),
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

              // List jadwal
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.fromLTRB(24, 28, 24, 0),
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
                      const SizedBox(height: 16),
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
                                            size: 48,
                                            color: Colors.grey[300]),
                                        const SizedBox(height: 12),
                                        const Text(
                                            'Tidak ada jadwal',
                                            style: TextStyle(
                                                color:
                                                    Colors.black38)),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount:
                                        _selectedJadwal.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (_, i) {
                                      final item =
                                          _selectedJadwal[i];
                                      final prioritas =
                                          item['prioritas'] ?? '';
                                      final color =
                                          _priorityColor(prioritas);
                                      final waktu = (item['waktu'] ??
                                              '')
                                          .toString();
                                      final waktuDisplay = waktu
                                              .length >= 5
                                          ? waktu.substring(0, 5)
                                          : waktu;

                                      return Container(
                                        padding:
                                            const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: color
                                              .withOpacity(0.06),
                                          borderRadius:
                                              BorderRadius.circular(
                                                  16),
                                          border: Border.all(
                                              color: color
                                                  .withOpacity(0.2)),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 4,
                                              height: 52,
                                              decoration:
                                                  BoxDecoration(
                                                color: color,
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(4),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                children: [
                                                  Text(
                                                    item['namaJadwal'] ??
                                                        '',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight
                                                                .w600,
                                                        fontSize: 14),
                                                  ),
                                                  const SizedBox(
                                                      height: 6),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                          Icons
                                                              .access_time,
                                                          size: 12,
                                                          color: Colors
                                                              .black38),
                                                      const SizedBox(
                                                          width: 4),
                                                      Text(
                                                          waktuDisplay,
                                                          style: const TextStyle(
                                                              fontSize:
                                                                  12,
                                                              color: Colors
                                                                  .black45)),
                                                      const SizedBox(
                                                          width: 8),
                                                      Container(
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                            horizontal:
                                                                8,
                                                            vertical:
                                                                2),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: color
                                                              .withOpacity(
                                                                  0.12),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8),
                                                        ),
                                                        child: Text(
                                                          prioritas,
                                                          style: TextStyle(
                                                              fontSize:
                                                                  10,
                                                              color:
                                                                  color,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if ((item['deadline'] ??
                                                          '')
                                                      .toString()
                                                      .isNotEmpty)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets
                                                              .only(
                                                              top: 4),
                                                      child: Row(
                                                        children: [
                                                          const Icon(
                                                              Icons
                                                                  .flag_outlined,
                                                              size:
                                                                  12,
                                                              color: Colors
                                                                  .black38),
                                                          const SizedBox(
                                                              width:
                                                                  4),
                                                          Text(
                                                            'Deadline: ${(item['deadline'] ?? '').toString().substring(0, 10)}',
                                                            style: const TextStyle(
                                                                fontSize:
                                                                    11,
                                                                color: Colors
                                                                    .black38),
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
                                                      _showFormDialog(
                                                          existing:
                                                              item),
                                                  icon: const Icon(
                                                      Icons
                                                          .edit_outlined,
                                                      size: 18,
                                                      color: Colors
                                                          .black38),
                                                ),
                                                IconButton(
                                                  onPressed: () =>
                                                      _deleteJadwal(
                                                          item['idJadwal']),
                                                  icon: const Icon(
                                                      Icons
                                                          .delete_outline,
                                                      size: 18,
                                                      color: Colors
                                                          .redAccent),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
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

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.grey[400], size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}