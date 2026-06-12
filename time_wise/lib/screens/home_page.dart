import 'package:flutter/material.dart';
import 'package:time_wise/services/session_service.dart';
import 'package:time_wise/services/api_service.dart';
import 'package:time_wise/services/notification_service.dart';
import 'jadwal_page.dart';
import 'tugas_page.dart';
import 'timer_page.dart';
import 'laporan_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    JadwalPage(),
    LaporanPage(),
    ProfilePage(),
    TimerPage(),
    TugasPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── Bottom Navbar ──────────────────────────────────────────────────────────────

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 10),
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          color: const Color(0xFF2EAD65).withOpacity(0.2),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(
            color: const Color(0xFF2EAD65).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2EAD65).withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(index: 0, currentIndex: currentIndex, icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', onTap: onTap),
                _NavItem(index: 1, currentIndex: currentIndex, icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month, label: 'Jadwal', onTap: onTap),
                _NavItem(index: 2, currentIndex: currentIndex, icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Laporan', onTap: onTap),
                _NavItem(index: 3, currentIndex: currentIndex, icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', onTap: onTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2EAD65) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? Colors.white : const Color(0xFF2EAD65),
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? Colors.white : const Color(0xFF2EAD65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dashboard Page ─────────────────────────────────────────────────────────────

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _username = 'Pengguna';
  int _idAkun = 0;
  List<Map<String, dynamic>> _jadwalHariIni = [];
  bool _isLoadingJadwal = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final username = await SessionService.getUsername();
    final idAkun = await SessionService.getIdAkun();
    if (mounted) {
      setState(() {
        _username = username;
        _idAkun = idAkun;
      });
    }
    await _fetchJadwalHariIni(idAkun);
  }

  Future<void> _fetchJadwalHariIni(int idAkun) async {
    if (idAkun == 0) return;
    setState(() => _isLoadingJadwal = true);

    final semua = await ApiService.getJadwal(idAkun);
    final todayKey = DateTime.now().toString().substring(0, 10);

    final hariIni = semua.where((j) {
      final tgl = (j['tanggal'] ?? '').toString();
      return tgl.length >= 10 && tgl.substring(0, 10) == todayKey;
    }).toList();

    hariIni.sort((a, b) {
      final wa = (a['waktu'] ?? '00:00').toString();
      final wb = (b['waktu'] ?? '00:00').toString();
      return wa.compareTo(wb);
    });

    if (mounted) {
      setState(() {
        _jadwalHariIni = hariIni;
        _isLoadingJadwal = false;
      });
    }
  }

  // ── TRIGGER NOTIFIKASI ───────────────────────────────────────────────────────
  Future<void> _triggerNotifikasi() async {
    if (_jadwalHariIni.isEmpty) {
      await NotificationService.showImmediate(
        title: 'Tidak ada jadwal hari ini',
        body: 'Kamu bebas hari ini! Tambahkan jadwal baru.',
      );
      return;
    }

    await NotificationService.rescheduleAll(_jadwalHariIni);

    final jumlah = _jadwalHariIni.length;
    final jadwalPertama = (_jadwalHariIni.first['nama_jadwal'] ??
            _jadwalHariIni.first['namaJadwal'] ??
            '')
        .toString();
    final waktu = (_jadwalHariIni.first['waktu'] ?? '').toString();
    final waktuDisplay = waktu.length >= 5 ? waktu.substring(0, 5) : waktu;

    await NotificationService.showImmediate(
      title: 'Kamu punya $jumlah jadwal hari ini',
      body: 'Terdekat: $jadwalPertama pukul $waktuDisplay WIB',
    );
  }

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi!';
    if (hour < 15) return 'Selamat Siang!';
    if (hour < 18) return 'Selamat Sore!';
    return 'Selamat Malam!';
  }

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

  String _todayLabel() {
    const bulan = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    const hari = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final now = DateTime.now();
    return '${hari[now.weekday % 7]}, ${now.day} ${bulan[now.month]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Center(
                            child: Text(
                              _username.isNotEmpty
                                  ? _username[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2EAD65),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_greetingText()},',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.85),
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text(
                              _username,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildHeaderActionButton(
                          icon: Icons.settings_outlined,
                          onTap: () {},
                        ),
                        const SizedBox(width: 12),
                        _buildHeaderActionButton(
                          icon: Icons.notifications_outlined,
                          hasBadge: _jadwalHariIni.isNotEmpty,
                          onTap: () => _triggerNotifikasi(), // ← trigger
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Mulai tugas\nhari ini.',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── White card area ──
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Menu Utama ──
                        const Text(
                          'Menu Utama',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.4,
                          children: [
                            _buildMenuCard(
                              context,
                              icon: Icons.calendar_month_outlined,
                              label: 'Jadwal',
                              subtitle: 'Lihat agenda',
                              color: const Color(0xFFE8F8F0),
                              iconColor: const Color(0xFF2EAD65),
                              pageIndex: 1,
                            ),
                            _buildMenuCard(
                              context,
                              icon: Icons.bar_chart_outlined,
                              label: 'Laporan',
                              subtitle: 'Statistik',
                              color: const Color(0xFFFFF3E0),
                              iconColor: const Color(0xFFFF9800),
                              pageIndex: 2,
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // ── Jadwal Hari Ini ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Jadwal Hari Ini',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  _todayLabel(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black38,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _fetchJadwalHariIni(_idAkun),
                                  child: const Icon(
                                    Icons.refresh,
                                    size: 16,
                                    color: Color(0xFF2EAD65),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_isLoadingJadwal)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF2EAD65),
                                strokeWidth: 2.5,
                              ),
                            ),
                          )
                        else if (_jadwalHariIni.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 28, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.grey.withOpacity(0.1)),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.event_available_outlined,
                                    size: 40, color: Colors.grey[300]),
                                const SizedBox(height: 10),
                                const Text(
                                  'Tidak ada jadwal hari ini',
                                  style: TextStyle(
                                      color: Colors.black38, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () {
                                    // 1. Memperbaiki sintaks findAncestorStateOfType dengan tanda < > yang benar
                                    final homeState = context.findAncestorStateOfType<_HomePageState>();
                                    
                                    if (homeState != null) {
                                      // 2. Menggunakan blok { } di dalam setState, bukan tanda panah =>
                                      homeState.setState(() {
                                        homeState._currentIndex = 1; 
                                      });
                                    }
                                  },
                                  child: const Text(
                                    'Tambah jadwal →',
                                    style: TextStyle(
                                      color: Color(0xFF2EAD65),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _jadwalHariIni.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final item = _jadwalHariIni[i];
                              final nama = (item['nama_jadwal'] ??
                                      item['namaJadwal'] ??
                                      '')
                                  .toString();
                              final prioritas =
                                  (item['prioritas'] ?? '').toString();
                              final color = _priorityColor(prioritas);
                              final waktu =
                                  (item['waktu'] ?? '').toString();
                              final waktuDisplay = waktu.length >= 5
                                  ? waktu.substring(0, 5)
                                  : waktu;
                              final deadline =
                                  (item['deadline'] ?? '').toString();

                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(
                                      color: color.withOpacity(0.15)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      children: [
                                        Text(
                                          waktuDisplay,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: color,
                                          ),
                                        ),
                                        Text(
                                          'WIB',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: color.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: 1,
                                      height: 36,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      color: Colors.grey.withOpacity(0.15),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: color.withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  prioritas,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: color,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              if (deadline.length >= 10) ...[
                                                const SizedBox(width: 6),
                                                const Icon(Icons.flag_outlined,
                                                    size: 11,
                                                    color: Colors.black38),
                                                const SizedBox(width: 2),
                                                Text(
                                                  deadline.substring(0, 10),
                                                  style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.black38),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: 28),

                        const Text(
                          'Tips Hari Ini',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTipsCard(
                          '🎯 Fokus dulu, distraksi kemudian',
                          'Selesaikan 1 tugas penting sebelum membuka media sosial.',
                        ),
                        const SizedBox(height: 10),
                        _buildTipsCard(
                          '⏱️ Gunakan teknik Pomodoro',
                          'Kerja 25 menit, istirahat 5 menit. Lebih produktif!',
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    required VoidCallback onTap,
    bool hasBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF2EAD65), size: 22),
          ),
          if (hasBadge)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required Color iconColor,
    required int pageIndex,
  }) {
    return GestureDetector(
      onTap: () {
        final homeState =
            context.findAncestorStateOfType<_HomePageState>();
        homeState?.setState(() => homeState._currentIndex = pageIndex);
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.black45)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard(String title, String desc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
          const SizedBox(height: 4),
          Text(desc,
              style: const TextStyle(fontSize: 12, color: Colors.black45)),
        ],
      ),
    );
  }
}