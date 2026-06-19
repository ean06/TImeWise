import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'notification_history_service.dart';

/// Handler top-level untuk notifikasi yang ditap saat app benar-benar
/// terminated (bukan cuma background). flutter_local_notifications
/// mewajibkan fungsi ini berada di top-level atau static, bukan method
/// instance biasa.
@pragma('vm:entry-point')
void notificationBackgroundHandler(NotificationResponse response) {
  // Tidak bisa langsung memanggil SharedPreferences/async di sini
  // dengan aman pada semua kondisi isolate, jadi background tap
  // sengaja tidak mencatat riwayat. Riwayat tetap tercatat saat app
  // dibuka kembali dan fetch data berjalan (lihat home_page).
}

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

    await _plugin.initialize(
      settings,
      // Dipanggil saat notifikasi ditampilkan (foreground) atau ditap.
      // Dipakai untuk mencatat riwayat ke NotificationHistoryService,
      // supaya semua notifikasi yang benar-benar tampil ke user juga
      // tercatat di halaman Riwayat Notifikasi.
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );

    // Minta permission notifikasi (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// payload notifikasi memakai format "type|refId|title|body"
  /// agar bisa langsung dicatat ke riwayat saat notifikasi tampil/ditap.
  static Future<void> _onNotificationTapped(
      NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    final parts = payload.split('|');
    if (parts.length < 4) return;

    final type = parts[0];
    final refId = parts[1];
    final title = parts[2];
    final body = parts.sublist(3).join('|'); // body boleh mengandung '|'

    await NotificationHistoryService.addEntry(
      title: title,
      body: body,
      type: type,
      refId: refId,
    );
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

  // ── JADWALKAN NOTIFIKASI BERDASARKAN WAKTU_SELESAI (deadline reminder) ───────
  //
  // Reminder = waktu_selesai - waktuNotif (menit), bukan waktu_mulai.
  // waktuNotif diambil per-akun dari tabel akun (server), bukan dari
  // setting lokal device, supaya konsisten dengan data yang user atur
  // di halaman Profile/Settings.
  //
  // Jadwal yang timeless == 'y' (tidak punya jam) atau status != 'pending'
  // dilewati, karena tidak relevan untuk reminder waktu.
  static Future<void> scheduleJadwalByEndTime({
    required int idJadwal,
    required String namaJadwal,
    required String tanggal,       // "yyyy-MM-dd"
    String? waktuSelesai,          // "HH:mm:ss", boleh null
    String? timeless,              // "y" / "n"
    String? status,                // "pending" / "selesai" / "terlewat"
    required int waktuNotifMenit,  // dari tabel akun
  }) async {
    final setting = await loadSetting();
    final bool aktifLokal = setting['status'] as bool;
    if (!aktifLokal) return;

    // Lewati jadwal tanpa jam spesifik, atau yang sudah tidak pending
    if (timeless == 'y') return;
    if (status != null && status != 'pending') return;
    if (waktuSelesai == null || waktuSelesai.isEmpty) return;

    final tglParts = tanggal.split('-');
    final wktParts = waktuSelesai.split(':');
    if (tglParts.length < 3 || wktParts.length < 2) return;

    final DateTime waktuSelesaiDt;
    try {
      waktuSelesaiDt = DateTime(
        int.parse(tglParts[0]),
        int.parse(tglParts[1]),
        int.parse(tglParts[2]),
        int.parse(wktParts[0]),
        int.parse(wktParts[1]),
      );
    } catch (_) {
      return; // format tanggal/waktu tidak valid, lewati daripada crash
    }

    // Reminder = waktu_selesai - waktu_notif
    final notifTime =
        waktuSelesaiDt.subtract(Duration(minutes: waktuNotifMenit));

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

    final title = 'Pengingat Jadwal';
    final body = '$namaJadwal akan berakhir dalam $waktuNotifMenit menit';

    await _plugin.zonedSchedule(
      idJadwal,
      title,
      body,
      tzNotifTime,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // payload dipakai oleh _onNotificationTapped untuk mencatat riwayat
      payload: 'jadwal|$idJadwal|$title|$body',
    );
  }

  // ── RESCHEDULE SEMUA JADWAL BERDASARKAN WAKTU_SELESAI (dipanggil saat fetch) ─
  //
  // [jadwalList] = hasil ApiService.getJadwal(idAkun)
  // [waktuNotifMenit] = hasil parsing dari ApiService.getAkun(idAkun)
  static Future<void> rescheduleAllByEndTime({
    required List<dynamic> jadwalList,
    required int waktuNotifMenit,
  }) async {
    await _plugin.cancelAll();
    for (final j in jadwalList) {
      final tgl = (j['tanggal'] ?? '') as String?;
      if (tgl == null || tgl.isEmpty) continue;

      await scheduleJadwalByEndTime(
        idJadwal: (j['id_jadwal'] ?? j['idJadwal'] ?? 0) is int
            ? (j['id_jadwal'] ?? j['idJadwal'] ?? 0)
            : int.tryParse((j['id_jadwal'] ?? j['idJadwal']).toString()) ?? 0,
        namaJadwal: (j['nama_jadwal'] ?? j['namaJadwal'] ?? '').toString(),
        tanggal: tgl,
        waktuSelesai: (j['waktu_selesai'] ?? j['waktuSelesai']) as String?,
        timeless: (j['timeless'] ?? 'n').toString(),
        status: (j['status'] ?? 'pending').toString(),
        waktuNotifMenit: waktuNotifMenit,
      );
    }
  }

  // ── Ambil waktu_notif dari response ApiService.getAkun() ────────────────────
  //
  // Backend bisa mengembalikan field ini dengan penamaan berbeda
  // (waktuNotif / waktu_notif / waktunotif), jadi dicoba berurutan.
  // Default 30 menit kalau tidak ditemukan / tidak valid.
  static int parseWaktuNotif(Map<String, dynamic> akunData) {
    final raw = akunData['waktuNotif'] ??
        akunData['waktu_notif'] ??
        akunData['waktunotif'];
    if (raw == null) return 30;
    if (raw is int) return raw;
    return int.tryParse(raw.toString()) ?? 30;
  }

  // ── BATALKAN NOTIFIKASI SATU JADWAL ──────────────────────────────────────────
  static Future<void> cancelJadwal(int idJadwal) async {
    await _plugin.cancel(idJadwal);
  }

  // ── RESCHEDULE SEMUA JADWAL (dipanggil saat login) ───────────────────────────
  static Future<void> rescheduleAll(List<dynamic> jadwalList) async {
    await _plugin.cancelAll();
    for (final j in jadwalList) {
      final tgl = j['tanggal'] as String?;
      final wkt = (j['waktu_mulai'] ?? j['waktuMulai'] ?? j['waktu']) as String?;
      if (tgl != null && wkt != null) {
        await scheduleJadwal(
          idJadwal:    (j['id_jadwal'] ?? j['idJadwal'] ?? 0) as int,
          namaJadwal:  (j['nama_jadwal'] ?? j['namaJadwal'] ?? '') as String,
          tanggal:     tgl,
          waktu:       wkt,
        );
      }
    }
  }

  // ── TAMPILKAN NOTIFIKASI LANGSUNG ─────────────────────────────────────────────
  static Future<void> showImmediate({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'timewise_channel',
      'TimeWise Reminder',
      channelDescription: 'Pengingat jadwal TimeWise',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    await _plugin.show(
      0,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }
}