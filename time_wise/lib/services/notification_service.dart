import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _keyStatus   = 'notif_status';   // bool
  static const _keyReminder = 'notif_reminder';  // int (menit)

  // ── INISIALISASI ─────────────────────────────────────────────────────────────
  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings);

    // Minta permission notifikasi (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ── SIMPAN SETTING ───────────────────────────────────────────────────────────
  static Future<void> saveSetting({
    required bool status,
    required int reminderMenit,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStatus, status);
    await prefs.setInt(_keyReminder, reminderMenit);
  }

  // ── LOAD SETTING ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'status':   prefs.getBool(_keyStatus)   ?? true,
      'reminder': prefs.getInt(_keyReminder)  ?? 30,
    };
  }

  // ── JADWALKAN NOTIFIKASI UNTUK SATU JADWAL ───────────────────────────────────
  static Future<void> scheduleJadwal({
    required int idJadwal,
    required String namaJadwal,
    required String tanggal,   // "yyyy-MM-dd"
    required String waktu,     // "HH:mm:ss"
  }) async {
    final setting = await loadSetting();
    final bool aktif = setting['status'] as bool;
    if (!aktif) return;

    final int reminderMenit = setting['reminder'] as int;

    // Parse tanggal dan waktu jadwal
    final parts = waktu.split(':');
    final jadwalTime = DateTime(
      int.parse(tanggal.split('-')[0]),
      int.parse(tanggal.split('-')[1]),
      int.parse(tanggal.split('-')[2]),
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    // Waktu notifikasi = waktu jadwal - menit reminder
    final notifTime = jadwalTime.subtract(Duration(minutes: reminderMenit));

    // Jangan jadwalkan kalau waktunya sudah lewat
    if (notifTime.isBefore(DateTime.now())) return;

    final tzNotifTime = tz.TZDateTime.from(notifTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'timewise_channel',
      'TimeWise Reminder',
      channelDescription: 'Pengingat jadwal TimeWise',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    await _plugin.zonedSchedule(
      idJadwal,
      'Pengingat Jadwal',
      '$namaJadwal dimulai dalam $reminderMenit menit',
      tzNotifTime,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── BATALKAN NOTIFIKASI SATU JADWAL ──────────────────────────────────────────
  static Future<void> cancelJadwal(int idJadwal) async {
    await _plugin.cancel(idJadwal);
  }

  // ── RESCHEDULE SEMUA JADWAL (dipanggil saat login) ───────────────────────────
  static Future<void> rescheduleAll(List<dynamic> jadwalList) async {
    await _plugin.cancelAll();
    for (final j in jadwalList) {
      if (j['tanggal'] != null && j['waktu'] != null) {
        await scheduleJadwal(
          idJadwal:    j['id_jadwal'] as int,
          namaJadwal:  j['nama_jadwal'] as String,
          tanggal:     j['tanggal'] as String,
          waktu:       j['waktu'] as String,
        );
      }
    }
  }
}
