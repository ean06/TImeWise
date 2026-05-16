import 'package:flutter/material.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Harian', 'Mingguan', 'Bulanan'];

  final Map<String, List<Map<String, dynamic>>> _data = {
    'Harian': [
      {'label': 'Senin', 'value': 0.8, 'tasks': 8},
      {'label': 'Selasa', 'value': 0.5, 'tasks': 5},
      {'label': 'Rabu', 'value': 0.9, 'tasks': 9},
      {'label': 'Kamis', 'value': 0.4, 'tasks': 4},
      {'label': 'Jumat', 'value': 0.7, 'tasks': 7},
      {'label': 'Sabtu', 'value': 0.3, 'tasks': 3},
      {'label': 'Minggu', 'value': 0.6, 'tasks': 6},
    ],
    'Mingguan': [
      {'label': 'Mgg 1', 'value': 0.6, 'tasks': 30},
      {'label': 'Mgg 2', 'value': 0.8, 'tasks': 40},
      {'label': 'Mgg 3', 'value': 0.5, 'tasks': 25},
      {'label': 'Mgg 4', 'value': 0.9, 'tasks': 45},
    ],
    'Bulanan': [
      {'label': 'Jan', 'value': 0.7, 'tasks': 120},
      {'label': 'Feb', 'value': 0.5, 'tasks': 90},
      {'label': 'Mar', 'value': 0.8, 'tasks': 150},
      {'label': 'Apr', 'value': 0.6, 'tasks': 110},
      {'label': 'Mei', 'value': 0.9, 'tasks': 160},
    ],
  };

  List<Map<String, dynamic>> get _currentData =>
      _data[_tabs[_selectedTab]]!;

  @override
  Widget build(BuildContext context) {
    final total = _currentData.fold<int>(0, (s, e) => s + (e['tasks'] as int));
    final avg = (_currentData.fold<double>(
              0,
              (s, e) => s + (e['value'] as double),
            ) /
            _currentData.length *
            100)
        .toStringAsFixed(0);

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
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Laporan',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Summary cards
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Tugas',
                        '$total',
                        Icons.task_alt_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Rata-rata',
                        '$avg%',
                        Icons.trending_up,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Chart area
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
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
                      // Tab
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F2F5),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: List.generate(_tabs.length, (i) {
                            final isActive = _selectedTab == i;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedTab = i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(26),
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

                      const SizedBox(height: 24),

                      // Bar chart
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: _currentData.map((item) {
                            return _buildBar(
                              label: item['label'],
                              value: item['value'],
                              tasks: item['tasks'],
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

  Widget _buildSummaryCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar({
    required String label,
    required double value,
    required int tasks,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$tasks',
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black45,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 28,
          height: 160 * value,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5EE09A), Color(0xFF2EAD65)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.black45),
        ),
      ],
    );
  }
}