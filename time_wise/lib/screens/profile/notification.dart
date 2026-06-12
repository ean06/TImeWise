import 'package:flutter/material.dart';
import '../../services/session_service.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _isLoading = true;
  bool _notifAktif = true;
  final TextEditingController _menitCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSetting();
  }

  @override
  void dispose() {
    _menitCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSetting() async {
    try {
      final idAkun = await SessionService.getIdAkun();
      final res = await ApiService.getAkun(idAkun);
      if (res['status'] == 'success') {
        setState(() {
          _notifAktif = res['status_notif'] == 'y';
          _menitCtrl.text = (res['waktu_notif'] ?? 30).toString();
          _isLoading = false;
        });
        // Sync ke local storage untuk keperluan local scheduling
        await NotificationService.saveSetting(
          status: _notifAktif,
          reminderMenit: res['waktu_notif'] as int? ?? 30,
        );
        return;
      }
    } catch (_) {}

    // Fallback ke local storage jika request API gagal
    final setting = await NotificationService.loadSetting();
    setState(() {
      _notifAktif = setting['status'] as bool;
      _menitCtrl.text = (setting['reminder'] as int).toString();
      _isLoading = false;
    });
  }

  Future<void> _simpan() async {
    final menit = int.tryParse(_menitCtrl.text.trim());
    if (menit == null || menit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan jumlah menit yang valid (angka > 0)'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final idAkun = await SessionService.getIdAkun();
    final result = await ApiService.updateNotification(idAkun, _notifAktif, menit);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['status'] == 'success') {
      // Sync ke local storage jika update di backend berhasil
      await NotificationService.saveSetting(
        status: _notifAktif,
        reminderMenit: menit,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan notifikasi disimpan'),
          backgroundColor: Color(0xFF2EAD65),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal menyimpan pengaturan ke database'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2EAD65)))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // ── Toggle notifikasi ────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SwitchListTile(
                      value: _notifAktif,
                      onChanged: (val) => setState(() => _notifAktif = val),
                      title: const Text(
                        'Aktifkan Notifikasi',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        _notifAktif
                            ? 'Notifikasi jadwal aktif'
                            : 'Tidak ada notifikasi untuk semua jadwal',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.black45),
                      ),
                      activeColor: const Color(0xFF2EAD65),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Input menit reminder ─────────────────────────────────────
                  AnimatedOpacity(
                    opacity: _notifAktif ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ingatkan saya sebelum jadwal',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Notifikasi akan muncul beberapa menit sebelum jadwal dimulai',
                            style: TextStyle(
                                fontSize: 12, color: Colors.black45),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F6FA),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: const Color(0xFFE8E8E8)),
                                  ),
                                  child: TextField(
                                    controller: _menitCtrl,
                                    enabled: _notifAktif,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2EAD65),
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: 12),
                                      hintText: '30',
                                      hintStyle: TextStyle(
                                          color: Colors.black26, fontSize: 22),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'menit\nsebelum',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Shortcut pilihan cepat
                          Wrap(
                            spacing: 8,
                            children: [15, 30, 60, 120].map((menit) {
                              final label = menit < 60
                                  ? '$menit mnt'
                                  : '${menit ~/ 60} jam';
                              return GestureDetector(
                                onTap: _notifAktif
                                    ? () => setState(
                                        () => _menitCtrl.text = '$menit')
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _menitCtrl.text == '$menit'
                                        ? const Color(0xFF2EAD65)
                                        : const Color(0xFFF0F2F5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _menitCtrl.text == '$menit'
                                          ? Colors.white
                                          : Colors.black54,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Tombol simpan ─────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _simpan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2EAD65),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Simpan Pengaturan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
