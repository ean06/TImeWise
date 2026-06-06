import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _pushNotification = true;
  bool _taskReminder = true;
  bool _weeklyReport = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Notifikasi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: _pushNotification,
                    onChanged: (val) => setState(() => _pushNotification = val),
                    title: const Text('Izinkan Notifikasi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Dapatkan pemberitahuan langsung di perangkat anda', style: TextStyle(fontSize: 12)),
                    activeColor: const Color(0xFF2EAD65),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                  ),
                  SwitchListTile(
                    value: _taskReminder,
                    onChanged: (val) => setState(() => _taskReminder = val),
                    title: const Text('Pengingat Jadwal', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Ingatkan saya sebelum tugas atau agenda dimulai', style: TextStyle(fontSize: 12)),
                    activeColor: const Color(0xFF2EAD65),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                  ),
                  SwitchListTile(
                    value: _weeklyReport,
                    onChanged: (val) => setState(() => _weeklyReport = val),
                    title: const Text('Laporan Mingguan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Kirim rangkuman produktivitas ke email saya', style: TextStyle(fontSize: 12)),
                    activeColor: const Color(0xFF2EAD65),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}