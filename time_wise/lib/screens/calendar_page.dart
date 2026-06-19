import 'package:flutter/material.dart';
import 'package:time_wise/services/session_service.dart';
import 'package:time_wise/services/api_service.dart';
import 'jadwal_page.dart';
import 'tugas_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  int _idAkun = 0;
  bool _isLoading = false;

  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _allJadwal = [];
  List<Map<String, dynamic>> _allTugas = [];

  final Set<String> _markedDates = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _idAkun = await SessionService.getIdAkun();
    await _fetchData();
  }

  Future<void> _fetchData() async {
    if (_idAkun == 0) return;
    setState(() => _isLoading = true);

    final jadwal = await ApiService.getJadwal(_idAkun);

    List<Map<String, dynamic>> tugas = [];
    try {
      tugas = await ApiService.getTugas(_idAkun);
    } catch (_) {
      tugas = [];
    }

    final marks = <String>{};
    for (final j in jadwal) {
      final tgl = (j['tanggal'] ?? '').toString();
      if (tgl.length >= 10) marks.add(tgl.substring(0, 10));
    }
    for (final t in tugas) {
      final tgl = (t['deadline'] ?? '').toString();
      if (tgl.length >= 10) marks.add(tgl.substring(0, 10));
    }

    if (mounted) {
      setState(() {
        _allJadwal = jadwal;
        _allTugas = tugas;
        _markedDates.addAll(marks);
        _isLoading = false;
      });
    }
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<Map<String, dynamic>> get _jadwalSelected {
    final key = _dateKey(_selectedDate);
    return _allJadwal.where((j) {
      final tgl = (j['tanggal'] ?? '').toString();
      return tgl.length >= 10 && tgl.substring(0, 10) == key;
    }).toList()
      ..sort((a, b) {
        final wa = (a['waktu_mulai'] ?? '00:00').toString();
        final wb = (b['waktu_mulai'] ?? '00:00').toString();
        return wa.compareTo(wb);
      });
  }

  List<Map<String, dynamic>> get _tugasSelected {
    final key = _dateKey(_selectedDate);
    final list = _allTugas.where((t) {
      final tgl = (t['deadline'] ?? '').toString();
      return tgl.length >= 10 && tgl.substring(0, 10) == key;
    }).toList();

    const urutanPrioritas = {'tinggi': 0, 'sedang': 1, 'rendah': 2};
    list.sort((a, b) {
      final pa = urutanPrioritas[(a['prioritas'] ?? 'sedang').toString().toLowerCase()] ?? 1;
      final pb = urutanPrioritas[(b['prioritas'] ?? 'sedang').toString().toLowerCase()] ?? 1;
      return pa.compareTo(pb);
    });
    return list;
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  String _monthLabel(DateTime d) {
    const bulan = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${bulan[d.month]} ${d.year}';
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'tinggi':
        return const Color(0xFFE91E63);
      case 'sedang':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF2EAD65);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;

    final leadingEmpty = (firstDayOfMonth.weekday - 1) % 7;

    const namaHariSingkat = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF2EAD65),
          onRefresh: _fetchData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kalender',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Lihat jadwal dan tugasmu per tanggal',
                  style: TextStyle(fontSize: 12, color: Colors.black45),
                ),
                const SizedBox(height: 20),

                // ── Header bulan ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _prevMonth,
                        icon: const Icon(Icons.chevron_left,
                            color: Color(0xFF2EAD65)),
                      ),
                      Text(
                        _monthLabel(_focusedMonth),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        onPressed: _nextMonth,
                        icon: const Icon(Icons.chevron_right,
                            color: Color(0xFF2EAD65)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Label hari ──
                Row(
                  children: namaHariSingkat
                      .map((h) => Expanded(
                            child: Center(
                              child: Text(
                                h,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black45,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),

                // ── Grid tanggal ──
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: leadingEmpty + daysInMonth,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    if (index < leadingEmpty) {
                      return const SizedBox.shrink();
                    }

                    final day = index - leadingEmpty + 1;
                    final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
                    final key = _dateKey(date);

                    final isToday = key == _dateKey(today);
                    final isSelected = key == _dateKey(_selectedDate);
                    final hasMark = _markedDates.contains(key);

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDate = date),
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2EAD65)
                              : isToday
                                  ? const Color(0xFF2EAD65).withOpacity(0.12)
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2EAD65)
                                : Colors.grey.withOpacity(0.08),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    isToday || isSelected ? FontWeight.w800 : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : isToday
                                        ? const Color(0xFF2EAD65)
                                        : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 3),
                            if (hasMark)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFFFF9800),
                                ),
                              )
                            else
                              const SizedBox(height: 6),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // ── Detail tanggal terpilih ──
                Text(
                  _selectedDateLabel(_selectedDate),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2EAD65),
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                else if (_jadwalSelected.isEmpty && _tugasSelected.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.event_busy_outlined, size: 40, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        const Text(
                          'Tidak ada jadwal atau tugas',
                          style: TextStyle(color: Colors.black38, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_jadwalSelected.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Jadwal',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        ..._jadwalSelected.map((j) => _buildJadwalItem(j)),
                        const SizedBox(height: 16),
                      ],
                      if (_tugasSelected.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Tugas (deadline ${_tugasSelected.length})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        ..._tugasSelected.map((t) => _buildTugasItem(t)),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _selectedDateLabel(DateTime d) {
    const hari = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const bulan = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${hari[d.weekday % 7]}, ${d.day} ${bulan[d.month]} ${d.year}';
  }

  Widget _buildJadwalItem(Map<String, dynamic> item) {
    final nama = (item['nama_jadwal'] ?? item['namaJadwal'] ?? '').toString();
    final prioritas = (item['prioritas'] ?? '').toString().toLowerCase();
    final color = _priorityColor(prioritas);
    final waktu = (item['waktu_mulai'] ?? '').toString();
    final waktuSelesai = (item['waktu_selesai'] ?? '').toString();
    final waktuDisplay = waktu.length >= 5 ? waktu.substring(0, 5) : waktu;
    final waktuSelesaiDisplay =
        waktuSelesai.length >= 5 ? waktuSelesai.substring(0, 5) : waktuSelesai;
    final isTimeless = waktuDisplay.isEmpty && waktuSelesaiDisplay.isEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isTimeless ? 'Sepanjang hari' : '$waktuDisplay WIB',
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTugasItem(Map<String, dynamic> item) {
    final nama = (item['judul'] ?? '').toString();
    final prioritas = (item['prioritas'] ?? 'sedang').toString().toLowerCase();
    final color = _priorityColor(prioritas);
    final status = (item['status'] ?? 'pending').toString().toLowerCase();
    final persen = (item['persentaseSelesai'] ?? 0);
    final isSelesai = status == 'selesai';
    final isTerlambat = status == 'terlambat';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: (isTerlambat ? const Color(0xFFE91E63) : color)
                .withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: isTerlambat ? const Color(0xFFE91E63) : color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isSelesai ? Colors.black38 : Colors.black87,
                    decoration:
                        isSelesai ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        prioritas[0].toUpperCase() + prioritas.substring(1),
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isTerlambat ? 'Terlambat' : '$persen% selesai',
                      style: TextStyle(
                        fontSize: 10,
                        color: isTerlambat
                            ? const Color(0xFFE91E63)
                            : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}