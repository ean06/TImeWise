import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://127.0.0.1:8080";
    } else if (Platform.isAndroid) {
      return "http://192.168.0.101:8080";
    } else {
      return "http://10.0.2.2:8080";
    }
  }

  // ── Auth ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> register(
      String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      debugPrint('[register] status=${response.statusCode} body=${response.body}');
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    } catch (e) {
      debugPrint('[register] ERROR: $e');
      return {'status': 'error', 'message': 'Koneksi gagal. Periksa server.'};
    }
  }

  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    } catch (e) {
      return {'status': 'error', 'message': 'Koneksi gagal. Periksa server.'};
    }
  }

  // ── Kategori ─────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getKategori(int idAkun) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/kategori/$idAkun'));
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> tambahKategori(Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/kategori'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      return data['status'] == 'success';
    } catch (_) {
      return false;
    }
  }

  static Future<bool> updateKategori(
      int idKategori, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/kategori/$idKategori'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      return data['status'] == 'success';
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hapusKategori(int idKategori) async {
    try {
      final response =
          await http.delete(Uri.parse('$baseUrl/kategori/$idKategori'));
      final data = jsonDecode(response.body);
      return data['status'] == 'success';
    } catch (_) {
      return false;
    }
  }

  // ── Jadwal ────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getJadwal(int idAkun) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/jadwal/$idAkun'));
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> tambahJadwal(
      Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tambah-jadwal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    } catch (_) {
      return {'status': 'error', 'message': 'Koneksi gagal'};
    }
  }

  static Future<bool> updateJadwal(
      int idJadwal, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/jadwal/$idJadwal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      return data['status'] == 'success';
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteJadwal(int idJadwal) async {
    try {
      final response =
          await http.delete(Uri.parse('$baseUrl/jadwal/$idJadwal'));
      final data = jsonDecode(response.body);
      return data['status'] == 'success';
    } catch (_) {
      return false;
    }
  }

  // ── Laporan & Rekomendasi ────────────────────────────────────────────

  static Future<Map<String, dynamic>> getLaporan(int idAkun) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/laporan/$idAkun'));
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } catch (_) {
      return {};
    }
  }

  static Future<List<Map<String, dynamic>>> getRekomendasi(int idAkun) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/rekomendasi/$idAkun'));
      final data = jsonDecode(response.body);
      final List list = data['rekomendasi'] ?? [];
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  // ── Tugas ─────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getTugas(int idAkun) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/tugas?idAkun=$idAkun'));
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getTugasById(int idTugas) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/tugas/$idTugas'));
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> tambahTugas(
      int idAkun, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/tugas?idAkun=$idAkun'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      debugPrint('[tambahTugas] status=${response.statusCode} body=${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('[tambahTugas] ERROR: $e');
      return null;
    }
  }

  /// Update tugas. Mengembalikan Map data tugas jika sukses.
  /// Jika backend menolak (mis. status 400 karena checklist belum lengkap),
  /// hasil berisi {'error': true, 'message': '...'} agar pesan dari server
  /// bisa ditampilkan ke pengguna.
  static Future<Map<String, dynamic>?> updateTugas(
      int idTugas, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/tugas/$idTugas'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      debugPrint('[updateTugas] status=${response.statusCode} body=${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }

      if (response.statusCode == 400) {
        String message = 'Permintaan tidak valid';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['message'] != null) {
            message = decoded['message'].toString();
          }
        } catch (_) {}
        return {'error': true, 'message': message};
      }

      return null;
    } catch (e) {
      debugPrint('[updateTugas] ERROR: $e');
      return null;
    }
  }

  static Future<bool> deleteTugas(int idTugas) async {
    try {
      final response =
          await http.delete(Uri.parse('$baseUrl/api/tugas/$idTugas'));
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Checklist ─────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getChecklist(int idTugas) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/tugas/$idTugas/checklist'));
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> tambahChecklist(
      int idTugas, String isi) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/tugas/$idTugas/checklist'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'isi': isi}),
      );
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateChecklist(
      int idChecklist, String selesai) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/tugas/checklist/$idChecklist'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'selesai': selesai}),
      );
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } catch (_) {
      return null;
    }
  }

  // Update isi (teks) checklist tanpa mengubah status selesai
  static Future<Map<String, dynamic>?> updateChecklistIsi(
      int idChecklist, String isi) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/tugas/checklist/$idChecklist/isi'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'isi': isi}),
      );
      debugPrint('[updateChecklistIsi] status=${response.statusCode} body=${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('[updateChecklistIsi] ERROR: $e');
      return null;
    }
  }

  static Future<bool> deleteChecklist(int idChecklist) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/api/tugas/checklist/$idChecklist'));
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Profile ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getAkun(int idAkun) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/akun/$idAkun'),
      );
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    } catch (_) {
      return {'status': 'error', 'message': 'Koneksi gagal. Periksa server.'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile(
      int idAkun, String username) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/akun/$idAkun/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    } catch (_) {
      return {'status': 'error', 'message': 'Koneksi gagal. Periksa server.'};
    }
  }

  static Future<Map<String, dynamic>> changePassword(
      int idAkun, String oldPassword, String newPassword) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/akun/$idAkun/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    } catch (_) {
      return {'status': 'error', 'message': 'Koneksi gagal. Periksa server.'};
    }
  }

  static Future<Map<String, dynamic>> updateNotification(
      int idAkun, bool statusNotif, int waktuNotif) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/akun/$idAkun/notification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'statusNotif': statusNotif,
          'waktuNotif': waktuNotif,
        }),
      );
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    } catch (_) {
      return {'status': 'error', 'message': 'Koneksi gagal. Periksa server.'};
    }
  }
}