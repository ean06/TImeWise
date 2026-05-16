import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8080';

  // ── Auth ─────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      return jsonDecode(response.body);
    } catch (_) {
      return {'status': 'error'};
    }
  }

  static Future<String> register(
      String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      final data = jsonDecode(response.body);
      return data['status'] ?? 'error';
    } catch (_) {
      return 'error';
    }
  }

  // ── Jadwal ───────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getJadwal(
      int idAkun) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/jadwal/$idAkun'),
      );
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> tambahJadwal(Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tambah-jadwal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      return data['status'] == 'success';
    } catch (_) {
      return false;
    }
  }

  static Future<bool> updateJadwal(
      int idJadwal, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/update-jadwal/$idJadwal'),
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
      final response = await http.delete(
        Uri.parse('$baseUrl/delete-jadwal/$idJadwal'),
      );
      final data = jsonDecode(response.body);
      return data['status'] == 'success';
    } catch (_) {
      return false;
    }
  }
}