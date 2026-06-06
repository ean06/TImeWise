import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import 'jadwal_page.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Harian', 'Mingguan', 'Bulanan'];
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
    _fetchData();
  }

  Future<void> _fetchData() async {
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

  List<Map<String, dynamic>> get _harianData {
    final today = DateTime.now();
    return List.generate(7, (i) {
      final date = today.subtract(Duration(days: 6 - i));
      final key = date.toString().substring(0, 10);
      final count =
          _allJadwal.where((j) => _tanggalKey(j) == key).length;
      final dayNames = [
        'Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'
      ];
      return {
        'label': dayNames[date.weekday % 7],
        'sublabel': '${date.day}/${date.month}',
        'count': count,
        'isToday': key == today.toString().substring(0, 10),
        'date': date,
      };
    });
  }

  List<Map<String, dynamic>> get _mingguanData {
    final today = DateTime.now();
    return List.generate(4, (i) {
      final weekStart = today
          .subtract(Duration(days: today.weekday - 1 + (3 - i) * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final count = _allJadwal.where((j) {
        final key = _tanggalKey(j);
        if (key.isEmpty) return false;
        try {
          final d = DateTime.parse(key);
          return !d.isBefore(weekStart) && !d.isAfter(weekEnd);
        } catch (_) {
          return false;
        }
      }).length;
      return {
        'label': 'Mgg ${i + 1}',
        'sublabel': '${weekStart.day}/${weekStart.month}',
        'count': count,
        'isToday': false,
        'date': null,
      };
    });
  }

  List<Map<String, dynamic>> get _bulananData {
    final today = DateTime.now();
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return List.generate(6, (i) {
      final month =
          DateTime(today.year, today.month - (5 - i), 1);
      final count = _allJadwal.where((j) {
        final key = _tanggalKey(j);
        if (key.isEmpty) return false;
        try {
          final d = DateTime.parse(key);
          return d.year == month.year && d.month == month.month;
        } catch (_) {
          return false;
        }
      }).length;
      return {
        'label': monthNames[month.month - 1],
        'sublabel': '${month.year}',
        'count': count,
        'isToday':
            month.year == today.year && month.month == today.month,
        'date': null,
      };
    });
  }

  List<Map<String, dynamic>> get _currentData {
    switch (_selectedTab) {
      case 0:
        return _harianData;
      case 1:
        return _mingguanData;
      case 2:
        return _bulananData;
      default:
        return _harianData;
    }
  }

  int get _totalJadwal => _allJadwal.length;

  int get _maxCount {
    final counts =
        _currentData.map((e) => e['count'] as int).toList();
    if (counts.isEmpty) return 1;
    final max = counts.reduce((a, b) => a > b ? a : b);
    return max == 0 ? 1 : max;
  }

  @override
  Widget build(BuildContext context) {
    final currentData = _currentData;
    final total =
        currentData.fold<int>(0, (s, e) => s + (e['count'] as int));
    final avg = currentData.isEmpty
        ? '0'
        : (total / currentData.length).toStringAsFixed(1);

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
                    const Text(
                      'Laporan',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: _fetchData,
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
              ),

              const SizedBox(height: 20),

              // ── Summary Cards ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Jadwal',
                        '$_totalJadwal',
                        Icons.calendar_month_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Rata-rata',
                        '$avg / periode',
                        Icons.trending_up,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Chart Area ──
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.fromLTRB(24, 28, 24, 24),
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
                      // ── Tab ──
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F2F5),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children:
                              List.generate(_tabs.length, (i) {
                            final isActive = _selectedTab == i;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _selectedTab = i),
                                child: AnimatedContainer(
                                  duration: const Duration(
                                      milliseconds: 200),
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius:
                                        BorderRadius.circular(26),
                                    boxShadow: isActive
                                        ? [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.08),
                                              blurRadius: 6,
                                            ),
                                          ]
                                        : [],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _tabs[i],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isActive
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                      color: isActive
                                          ? Colors.black87
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ── Chart label ──
                      Row(
                        children: [
                          Text(
                            _selectedTab == 0
                                ? '7 Hari Terakhir'
                                : _selectedTab == 1
                                    ? '4 Minggu Terakhir'
                                    : '6 Bulan Terakhir',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black38,
                            ),
                          ),
                          if (_selectedTab == 0) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.touch_app_outlined,
                              size: 12,
                              color: Colors.black26,
                            ),
                            const SizedBox(width: 2),
                            const Text(
                              'Tap bar untuk lihat detail',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black26,
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── Bar Chart ──
                      Expanded(
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFF2EAD65)))
                            : currentData.every(
                                    (e) => (e['count'] as int) == 0)
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                            Icons
                                                .bar_chart_outlined,
                                            size: 52,
                                            color: Colors.grey[300]),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Belum ada data jadwal',
                                          style: TextStyle(
                                              color: Colors.black38,
                                              fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  )
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: currentData
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final item = entry.value;
                                      final date =
                                          item['date'] as DateTime?;

                                      return _buildBar(
                                        label: item['label'],
                                        sublabel: item['sublabel'],
                                        count: item['count'],
                                        isHighlight: item['isToday'],
                                        onTap: _selectedTab == 0 &&
                                                date != null
                                            ? () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        JadwalPage(
                                                      initialDate:
                                                          date,
                                                    ),
                                                  ),
                                                );
                                              }
                                            : null,
                                      );
                                    }).toList(),
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
    );
  }

  Widget _buildSummaryCard(
      String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar({
    required String label,
    required String sublabel,
    required int count,
    required bool isHighlight,
    VoidCallback? onTap,
  }) {
    const double maxBarHeight = 160;
    final double barHeight =
        count == 0 ? 8 : (count / _maxCount) * maxBarHeight;
    final bool tappable = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              count > 0 ? '$count' : '',
              key: ValueKey('$label$count'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isHighlight
                    ? const Color(0xFF2EAD65)
                    : Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Bar dengan ripple effect jika tappable
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            width: 36,
            height: barHeight,
            decoration: BoxDecoration(
              gradient: isHighlight
                  ? const LinearGradient(
                      colors: [Color(0xFF5EE09A), Color(0xFF2EAD65)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : LinearGradient(
                      colors: [
                        const Color(0xFF2EAD65).withOpacity(0.25),
                        const Color(0xFF2EAD65).withOpacity(0.15),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
              borderRadius: BorderRadius.circular(12),
              border: tappable
                  ? Border.all(
                      color: const Color(0xFF2EAD65).withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isHighlight
                  ? FontWeight.w700
                  : FontWeight.w400,
              color: isHighlight
                  ? const Color(0xFF2EAD65)
                  : Colors.black45,
            ),
          ),
          Text(
            sublabel,
            style: const TextStyle(
                fontSize: 9, color: Colors.black26),
          ),
        ],
      ),
    );
  }
}