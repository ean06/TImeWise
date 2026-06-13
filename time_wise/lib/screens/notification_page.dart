import 'package:flutter/material.dart';
import 'package:time_wise/services/notification_history_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final data = await NotificationHistoryService.getHistory();

    await NotificationHistoryService.markAllAsRead();

    if (mounted) {
      setState(() {
        _history = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEntry(String timestamp) async {
    await NotificationHistoryService.deleteEntry(timestamp);
    _loadHistory();
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Semua Notifikasi'),
        content: const Text('Yakin ingin menghapus semua riwayat notifikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Color(0xFFE91E63))),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await NotificationHistoryService.clearAll();
    _loadHistory();
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'tugas':
        return Icons.check_box_outlined;
      case 'jadwal':
        return Icons.calendar_month_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'tugas':
        return const Color(0xFFFF9800);
      case 'jadwal':
        return const Color(0xFF2EAD65);
      default:
        return const Color(0xFF2196F3);
    }
  }

  String _formatTimestamp(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari yang lalu';

    const bulan = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${bulan[dt.month]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_sweep_outlined,
                  color: Colors.black54),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF2EAD65),
        onRefresh: _loadHistory,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2EAD65),
                  strokeWidth: 2.5,
                ),
              )
            : _history.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: 140),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.notifications_off_outlined,
                                size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada notifikasi',
                              style:
                                  TextStyle(color: Colors.black38, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Pengingat jadwal & tugas akan\nmuncul di sini',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: Colors.black26, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    itemCount: _history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final item = _history[i];
                      final type = (item['type'] ?? '').toString();
                      final title = (item['title'] ?? '').toString();
                      final body = (item['body'] ?? '').toString();
                      final timestamp = (item['timestamp'] ?? '').toString();
                      final color = _colorForType(type);

                      return Dismissible(
                        key: ValueKey(timestamp),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE91E63),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteEntry(timestamp),
                        child: Container(
                          padding: const EdgeInsets.all(14),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(_iconForType(type),
                                    color: color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      body,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _formatTimestamp(timestamp),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}